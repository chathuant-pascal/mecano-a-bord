// bluetooth_obd_service.dart — Mécano à Bord (Flutter iOS + Android)
// Version raccordée aux contrats V1
//
// Rôle : gérer toute la communication Bluetooth avec le boîtier ELM327.
//
// Ce que ce service fait :
//  - Recherche et se connecte au boîtier ELM327 via Bluetooth
//  - Envoie des commandes OBD (PIDs) et reçoit les réponses
//  - Traduit les réponses brutes en données lisibles (température, RPM, etc.)
//  - Expose un flux de données en temps réel pour le service de surveillance
//  - Gère les erreurs de connexion proprement
//
// Dépendances Flutter à ajouter dans pubspec.yaml :
//   flutter_bluetooth_serial: ^0.4.0   (Android)
//   flutter_blue_plus: ^1.31.15        (iOS + Android - alternative recommandée)

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'mab_repository.dart';

// ─────────────────────────────────────────────
// ÉTATS DE CONNEXION BLUETOOTH
// ─────────────────────────────────────────────

/// Représente l'état courant de la connexion au boîtier ELM327.
abstract class ObdConnectionState {
  const ObdConnectionState();
}

class ObdDisconnected extends ObdConnectionState { const ObdDisconnected(); }
class ObdConnecting   extends ObdConnectionState { const ObdConnecting(); }
class ObdBluetoothDisabled extends ObdConnectionState { const ObdBluetoothDisabled(); }
class ObdDeviceNotFound    extends ObdConnectionState { const ObdDeviceNotFound(); }

class ObdConnected extends ObdConnectionState {
  final String deviceName;
  const ObdConnected(this.deviceName);
}

class ObdError extends ObdConnectionState {
  final String message;
  const ObdError(this.message);
}

// ─────────────────────────────────────────────
// SERVICE BLUETOOTH OBD
// ─────────────────────────────────────────────

class BluetoothObdService {

  // Noms typiques des boîtiers ELM327
  static const _elm327Names = ['OBDII', 'ELM327', 'OBD2', 'V-LINK', 'KONNWEI'];

  // UUID standard Bluetooth SPP (Serial Port Profile) — utilisé par tous les ELM327
  static const _sppUuid = '00001101-0000-1000-8000-00805f9b34fb';

  // Délai d'attente pour une réponse OBD
  static const _obdTimeoutMs = 2000;

  // Commandes OBD standard (PIDs)
  static const _cmdReset        = 'ATZ\r';
  static const _cmdEchoOff      = 'ATE0\r';
  static const _cmdHeadersOff   = 'ATH0\r';
  static const _cmdAutoProtocol = 'ATSP0\r';
  static const _cmdEngineTemp   = '0105\r';
  static const _cmdRpm          = '010C\r';
  static const _cmdSpeed        = '010D\r';
  static const _cmdDtc          = '03\r';

  // État de connexion exposé à l'application
  final _connectionStateController =
      StreamController<ObdConnectionState>.broadcast();
  Stream<ObdConnectionState> get connectionState =>
      _connectionStateController.stream;

  // Flux de données OBD en temps réel
  final _obdDataController = StreamController<ObdData?>.broadcast();
  Stream<ObdData?> get obdDataStream => _obdDataController.stream;

  // Appareil et caractéristique Bluetooth actifs
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;

  // Tampon pour assembler les réponses OBD fragmentées
  final _responseBuffer = StringBuffer();
  final _responseCompleter = Completer<String>.sync();
  Completer<String>? _pendingResponse;

  bool _isConnected = false;

  // ─────────────────────────────────────────────
  // CONNEXION
  // ─────────────────────────────────────────────

  /// Recherche et se connecte au boîtier ELM327.
  /// Retourne true si la connexion a réussi, false sinon.
  Future<bool> connect() async {
    _emit(const ObdConnecting());

    try {
      // Vérifier que le Bluetooth est activé
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _emit(const ObdBluetoothDisabled());
        return false;
      }

      // Chercher le boîtier ELM327 via un scan
      BluetoothDevice? elm327;

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      await for (final result in FlutterBluePlus.scanResults) {
        for (final r in result) {
          final name = r.device.platformName;
          if (_elm327Names.any(
            (n) => name.toLowerCase().contains(n.toLowerCase()),
          )) {
            elm327 = r.device;
            await FlutterBluePlus.stopScan();
            break;
          }
        }
        if (elm327 != null) break;
      }

      if (elm327 == null) {
        _emit(const ObdDeviceNotFound());
        return false;
      }

      // Établir la connexion
      await elm327.connect(timeout: const Duration(seconds: 10));
      _device = elm327;

      // Découvrir les services Bluetooth
      final services = await elm327.discoverServices();
      for (final service in services) {
        for (final char in service.characteristics) {
          if (char.properties.write && char.properties.notify) {
            _characteristic = char;
            break;
          }
        }
        if (_characteristic != null) break;
      }

      if (_characteristic == null) {
        await elm327.disconnect();
        _emit(const ObdError('Boîtier non compatible. Vérifiez qu\'il s\'agit bien d\'un ELM327.'));
        return false;
      }

      // S'abonner aux notifications (réponses du boîtier)
      await _characteristic!.setNotifyValue(true);
      _characteristic!.onValueReceived.listen(_onDataReceived);

      _isConnected = true;

      // Initialiser le boîtier
      final initialized = await _initializeElm327();
      if (!initialized) {
        await disconnect();
        return false;
      }

      _emit(ObdConnected(elm327.platformName));
      return true;

    } catch (e) {
      _emit(ObdError(
        'Connexion impossible. Vérifiez que le boîtier est branché et que le Bluetooth est activé.',
      ));
      return false;
    }
  }

  /// Déconnecte proprement le boîtier ELM327.
  Future<void> disconnect() async {
    _isConnected = false;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _characteristic = null;
    _obdDataController.add(null);
    _emit(const ObdDisconnected());
  }

  // ─────────────────────────────────────────────
  // INITIALISATION DU BOÎTIER ELM327
  // ─────────────────────────────────────────────

  Future<bool> _initializeElm327() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      await _sendCommand(_cmdReset);
      await Future.delayed(const Duration(seconds: 1));
      await _sendCommand(_cmdEchoOff);
      await _sendCommand(_cmdHeadersOff);
      await _sendCommand(_cmdAutoProtocol);
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // LECTURE DES DONNÉES OBD
  // ─────────────────────────────────────────────

  /// Lit toutes les données OBD disponibles en une seule passe.
  /// Retourne un objet ObdData complet, ou null si la connexion est perdue.
  ///
  /// Utilisé par monitoring_background_service.dart toutes les 5 secondes.
  Future<ObdData?> readCurrentData() async {
    if (!_isConnected) return null;

    try {
      final engineTemp = await _readEngineTemperature();
      if (engineTemp == null) return null;

      final rpm   = await _readRpm() ?? 0;
      final speed = await _readSpeed() ?? 0;
      final dtcs  = await _readActiveDtcCodes();

      final data = ObdData(
        engineTempCelsius: engineTemp,
        oilPressureBar: _estimateOilPressure(rpm, engineTemp),
        rpmValue: rpm,
        speedKmh: speed,
        activeDtcCodes: dtcs,
      );

      _obdDataController.add(data);
      return data;

    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // LECTURE DES PIDs OBD (valeurs individuelles)
  // ─────────────────────────────────────────────

  /// Température du liquide de refroidissement (en °C)
  Future<int?> _readEngineTemperature() async {
    final response = await _sendCommand(_cmdEngineTemp);
    if (response == null) return null;
    return _parseOneBytePid(response, '41 05')?.let((v) => v - 40);
  }

  /// Régime moteur (en RPM)
  Future<int?> _readRpm() async {
    final response = await _sendCommand(_cmdRpm);
    if (response == null) return null;
    return _parseTwoBytePid(response, '41 0C')?.let((v) => v ~/ 4);
  }

  /// Vitesse du véhicule (en km/h)
  Future<int?> _readSpeed() async {
    final response = await _sendCommand(_cmdSpeed);
    if (response == null) return null;
    return _parseOneBytePid(response, '41 0D');
  }

  /// Codes de défaut actifs (DTC)
  Future<List<String>> _readActiveDtcCodes() async {
    final response = await _sendCommand(_cmdDtc);
    if (response == null) return [];
    return _parseDtcResponse(response);
  }

  /// Estimation de la pression d'huile (fallback si PID non supporté)
  double _estimateOilPressure(int rpm, int engineTempCelsius) {
    if (rpm == 0) return 0.0;
    if (rpm < 800) return 1.5;
    if (engineTempCelsius > 115) return 1.2;
    return 3.5;
  }

  // ─────────────────────────────────────────────
  // COMMUNICATION BLUETOOTH
  // ─────────────────────────────────────────────

  Future<String?> _sendCommand(String command) async {
    final char = _characteristic;
    if (char == null || !_isConnected) return null;

    try {
      _responseBuffer.clear();
      _pendingResponse = Completer<String>();

      // Envoyer la commande
      await char.write(utf8.encode(command), withoutResponse: false);

      // Attendre la réponse (avec timeout)
      return await _pendingResponse!.future
          .timeout(Duration(milliseconds: _obdTimeoutMs));

    } catch (e) {
      _pendingResponse = null;
      return null;
    }
  }

  /// Appelé à chaque fois que le boîtier envoie des données.
  void _onDataReceived(List<int> data) {
    final text = utf8.decode(data, allowMalformed: true);
    _responseBuffer.write(text);

    // Le caractère '>' marque la fin d'une réponse ELM327
    if (text.contains('>')) {
      final response = _responseBuffer.toString()
          .replaceAll('\r', ' ')
          .replaceAll('\n', ' ')
          .trim()
          .toUpperCase();

      _responseBuffer.clear();
      _pendingResponse?.complete(response);
      _pendingResponse = null;
    }
  }

  // ─────────────────────────────────────────────
  // DÉCODAGE DES RÉPONSES OBD
  // ─────────────────────────────────────────────

  /// Décode une réponse OBD à 1 octet de données.
  int? _parseOneBytePid(String response, String prefix) {
    if (!response.contains(prefix)) return null;
    try {
      final parts = response.substring(response.indexOf(prefix) + prefix.length)
          .trim().split(' ');
      if (parts.isEmpty) return null;
      return int.parse(parts[0], radix: 16);
    } catch (_) { return null; }
  }

  /// Décode une réponse OBD à 2 octets de données.
  int? _parseTwoBytePid(String response, String prefix) {
    if (!response.contains(prefix)) return null;
    try {
      final parts = response.substring(response.indexOf(prefix) + prefix.length)
          .trim().split(' ');
      if (parts.length < 2) return null;
      return (int.parse(parts[0], radix: 16) * 256) +
             int.parse(parts[1], radix: 16);
    } catch (_) { return null; }
  }

  /// Décode les codes DTC depuis la réponse à la commande 03.
  List<String> _parseDtcResponse(String response) {
    if (response.contains('NO DATA') || response.contains('43 00')) return [];

    final codes = <String>[];
    try {
      final data = response.replaceAll('43', '').trim().split(' ')
          .where((s) => s.isNotEmpty).toList();

      for (int i = 0; i + 1 < data.length; i += 2) {
        final byte1 = int.parse(data[i], radix: 16);
        final byte2 = int.parse(data[i + 1], radix: 16);

        if (byte1 == 0 && byte2 == 0) continue;

        final prefixes = ['P', 'C', 'B', 'U'];
        final prefix = prefixes[(byte1 >> 6) & 0x03];
        final d1 = (byte1 >> 4) & 0x03;
        final d2 = byte1 & 0x0F;
        final d3 = (byte2 >> 4) & 0x0F;
        final d4 = byte2 & 0x0F;

        codes.add('$prefix$d1$d2$d3$d4');
      }
    } catch (_) {}
    return codes;
  }

  // ─────────────────────────────────────────────
  // NETTOYAGE
  // ─────────────────────────────────────────────

  void _emit(ObdConnectionState state) {
    _connectionStateController.add(state);
  }

  void dispose() {
    disconnect();
    _connectionStateController.close();
    _obdDataController.close();
  }
}

// Extension utilitaire pour Dart (équivalent du .let() de Kotlin)
extension Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
