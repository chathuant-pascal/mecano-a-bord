// bluetooth_obd_service.dart — Mécano à Bord
// Connexion OBD en Bluetooth classique (SPP) pour dongle iCar Pro Vgate appairé par PIN.
// Liste des appareils appairés (réglages Bluetooth), connexion SPP + ATZ via canal natif Android.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:mecano_a_bord/services/obd_session_coordinator.dart';

/// États de connexion OBD (compatibles avec l'écran d'accueil).
abstract class ObdConnectionState {
  const ObdConnectionState();
}

class ObdDisconnected extends ObdConnectionState {
  const ObdDisconnected();
}

class ObdConnecting extends ObdConnectionState {
  const ObdConnecting();
}

class ObdBluetoothDisabled extends ObdConnectionState {
  const ObdBluetoothDisabled();
}

class ObdDeviceNotFound extends ObdConnectionState {
  const ObdDeviceNotFound();
}

class ObdConnected extends ObdConnectionState {
  final String deviceName;
  const ObdConnected(this.deviceName);
}

/// Connecté au dongle mais le protocole OBD de ce véhicule (VIN) n'est pas encore connu : détection en cours ou à lancer.
class ObdConnectedNeedsProtocolDetection extends ObdConnectionState {
  final String deviceName;
  const ObdConnectedNeedsProtocolDetection(this.deviceName);
}

class ObdError extends ObdConnectionState {
  final String message;
  const ObdError(this.message);
}

/// Exception levée si le Bluetooth est indisponible ou non autorisé.
class ObdScanException implements Exception {
  final String message;
  ObdScanException(this.message);
  @override
  String toString() => message;
}

/// Message d'erreur utilisateur en cas d'échec de connexion.
const String _connectionErrorMessage =
    'Échec de connexion - Vérifiez que le dongle est branché sur la voiture et que le contact est allumé.';

/// Résultat de la lecture véhicule (0101, 03, 07, 0A).
/// [level] : "green" | "orange" | "red" | "incomplete".
/// [dtcs] : liste combinée (mémorisés + en attente + permanents), pour l’affichage existant.
class ObdVehicleResult {
  const ObdVehicleResult({
    required this.level,
    required this.message,
    required this.dtcs,
    required this.milOn,
    required this.storedDtcs,
    required this.pendingDtcs,
    required this.permanentDtcs,
  });

  final String level;
  final String message;
  /// Tous les codes (stored + pending + permanent), ordre conservé.
  final List<String> dtcs;
  /// Témoin MIL (Check Engine) d’après le PID 01 (étape 0).
  final bool milOn;
  /// Mode 03 — codes mémorisés.
  final List<String> storedDtcs;
  /// Mode 07 — codes en attente.
  final List<String> pendingDtcs;
  /// Mode 0A — codes permanents.
  final List<String> permanentDtcs;
}

/// Code d’erreur [ObdScanException] lorsque la surveillance temps réel est active.
const String kObdSurveillanceBlockedCode = 'OB_SURVEILLANCE_BLOCKED';

/// Résultat d’une lecture PID live (readLiveData natif).
class LivePidResult {
  const LivePidResult({
    required this.success,
    required this.value,
    required this.unit,
    required this.supported,
  });

  final bool success;
  final double value;
  final String unit;
  final bool supported;
}

/// Canal natif Android pour Bluetooth classique (appareils appairés + SPP).
const _channel = MethodChannel('com.example.mecano_a_bord/obd');

/// Service OBD en Bluetooth classique : appareils appairés dans les réglages du téléphone,
/// connexion SPP (Serial Port Profile) + envoi ATZ pour valider le dongle ELM327.
class BluetoothObdService {
  final _controller = StreamController<ObdConnectionState>.broadcast();

  BluetoothObdService._() {
    _controller.add(const ObdDisconnected());
    _refreshConnectionState();
  }

  /// Instance unique : même flux pour accueil, OBD et surveillance (mode AUTO).
  static final BluetoothObdService instance = BluetoothObdService._();

  factory BluetoothObdService() => instance;

  Stream<ObdConnectionState> get connectionState => _controller.stream;

  /// État matériel (socket SPP), tel que [getConnectionState] côté natif.
  Future<ObdConnectionState> readNativeConnectionState() async {
    if (!Platform.isAndroid) return const ObdDisconnected();
    try {
      final state = await _channel.invokeMethod<Map<Object?, Object?>>('getConnectionState');
      if (state != null && state['connected'] == true) {
        final name = state['deviceName'] as String? ?? 'OBD';
        return ObdConnected(name);
      }
    } on PlatformException catch (_) {}
    return const ObdDisconnected();
  }

  /// Vrai si le Mode conduite a démarré la surveillance temps réel.
  bool isMonitoringActive() => ObdSessionCoordinator.liveMonitoringActive;

  /// Lecture d’un PID mode 01 (ex. 0105, 0142, 010B). Android uniquement.
  Future<LivePidResult> readLivePid(String pid) async {
    if (!Platform.isAndroid) {
      return const LivePidResult(
        success: false,
        value: 0,
        unit: '',
        supported: false,
      );
    }
    try {
      final map = await _channel.invokeMethod<Map<Object?, Object?>>('readLiveData', {
        'pid': pid.trim(),
      });
      if (map == null) {
        return const LivePidResult(
          success: false,
          value: 0,
          unit: '',
          supported: false,
        );
      }
      final success = map['success'] == true;
      final supported = map['supported'] == true;
      final value = (map['value'] as num?)?.toDouble() ?? 0.0;
      final unit = map['unit']?.toString() ?? '';
      return LivePidResult(
        success: success,
        value: value,
        unit: unit,
        supported: supported,
      );
    } on PlatformException catch (_) {
      return const LivePidResult(
        success: false,
        value: 0,
        unit: '',
        supported: false,
      );
    }
  }

  /// Efface les codes défaut stockés (OBD-II mode 04, commande « 04 »). Android uniquement.
  /// Lève [ObdScanException] si la surveillance temps réel est active.
  /// Retourne `true` si le véhicule a confirmé l’effacement (réponse 0x44).
  Future<bool> clearDtcCodes() async {
    if (!Platform.isAndroid) return false;
    if (ObdSessionCoordinator.liveMonitoringActive) {
      throw ObdScanException(kObdSurveillanceBlockedCode);
    }
    try {
      final map = await _channel.invokeMethod<Map<Object?, Object?>>('clearDtcCodes');
      return map != null && map['success'] == true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Vide les SharedPreferences Android `obd` (protocoles sauvegardés par VIN). No-op hors Android.
  static Future<void> resetObdNativePrefs() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('resetObdNativePrefs');
    } on PlatformException catch (_) {}
  }

  /// Récupère l'état de connexion actuel côté natif (ex. au démarrage de l'app).
  Future<void> _refreshConnectionState() async {
    if (!Platform.isAndroid) return;
    try {
      final state = await _channel.invokeMethod<Map<Object?, Object?>>('getConnectionState');
      if (state != null && (state['connected'] == true)) {
        final name = state['deviceName'] as String? ?? 'OBD';
        _controller.add(ObdConnected(name));
      }
    } on PlatformException catch (_) {}
  }

  /// Retourne la liste des appareils déjà appairés dans les réglages Bluetooth du téléphone.
  /// À afficher en priorité : l'utilisateur doit appairer le dongle (avec le code PIN) dans les réglages avant.
  Future<List<Map<String, String>>> getBondedDevices() async {
    if (!Platform.isAndroid) return [];
    try {
      final list = await _channel.invokeMethod<List<Object?>>('getBondedDevices');
      if (list == null) return [];
      return list.map((e) {
        final m = e as Map<Object?, Object?>;
        return <String, String>{
          'id': (m['id'] as String?) ?? '',
          'name': (m['name'] as String?) ?? 'OBD',
        };
      }).where((e) => e['id']!.isNotEmpty).toList();
    } on PlatformException catch (e) {
      if (e.code == 'GET_BONDED') throw ObdScanException(e.message ?? 'Impossible de lire les appareils appairés.');
      rethrow;
    }
  }

  /// Même API que précédemment : pour le Bluetooth classique, "découvrir" = lire les appareils appairés.
  Future<List<Map<String, String>>> discoverDevices({Duration scanDuration = const Duration(seconds: 15)}) async {
    return getBondedDevices();
  }

  /// Connecte le dongle [deviceId] (adresse MAC) via SPP, envoie ATZ.
  /// Si [vin] est fourni et qu'aucun protocole n'est enregistré pour ce VIN, émet [ObdConnectedNeedsProtocolDetection]
  /// pour que l'écran lance la détection (tryProtocol 0..9) avant de lire le véhicule.
  Future<void> connect(String deviceId, {String? deviceName, String? vin}) async {
    if (deviceId.isEmpty) {
      _controller.add(const ObdError('Adresse de l\'appareil requise'));
      return;
    }
    if (!Platform.isAndroid) {
      _controller.add(const ObdError('Bluetooth classique non supporté sur cette plateforme'));
      return;
    }
    _controller.add(const ObdConnecting());
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('connect', {
        'address': deviceId,
        'deviceName': deviceName,
        'vin': vin?.trim().isEmpty == true ? null : vin?.trim(),
      });
      if (result != null && result['connected'] == true) {
        final name = result['deviceName'] as String? ?? deviceName ?? 'OBD';
        final needsDetection = result['protocolDetectionNeeded'] == true;
        if (needsDetection && (vin?.trim().isNotEmpty ?? false)) {
          _controller.add(ObdConnectedNeedsProtocolDetection(name));
        } else {
          _controller.add(ObdConnected(name));
        }
      } else {
        _controller.add(const ObdError(_connectionErrorMessage));
      }
    } on PlatformException catch (e) {
      final message = switch (e.code) {
        'OFF' => 'Bluetooth désactivé. Activez-le dans les réglages.',
        'NOT_FOUND' => 'Appareil non trouvé. Vérifiez qu\'il est bien appairé.',
        'ATZ_TIMEOUT' => _connectionErrorMessage,
        _ => e.message ?? _connectionErrorMessage,
      };
      _controller.add(ObdError(message));
    } catch (e) {
      _controller.add(const ObdError(_connectionErrorMessage));
    }
  }

  /// Nombre de protocoles testés (ATSP0 à ATSP9).
  static const int protocolCount = 10;

  /// Lance la détection du protocole OBD pour ce [vin] (0..9). [onProgress] reçoit (current 1..10, total 10, message).
  /// Retourne true si un protocole a été trouvé et enregistré.
  Future<bool> runProtocolDetection({
    required String vin,
    void Function(int current, int total, String message)? onProgress,
  }) async {
    if (!Platform.isAndroid || vin.trim().isEmpty) return false;
    if (ObdSessionCoordinator.liveMonitoringActive) {
      throw ObdScanException(kObdSurveillanceBlockedCode);
    }
    ObdSessionCoordinator.diagnosticRunning = true;
    try {
      for (var i = 0; i < protocolCount; i++) {
        onProgress?.call(i + 1, protocolCount, 'Test du protocole ${i + 1}/$protocolCount en cours...');
        try {
          final result = await _channel.invokeMethod<Map<Object?, Object?>>('tryProtocol', {
            'vin': vin.trim(),
            'protocolIndex': i,
          });
          final rawResponse = result?['rawResponse']?.toString() ?? '';
          debugPrint('OBD protocole $i: réponse brute = $rawResponse');
          final success = result?['success'] == true;
          if (success) return true;
        } on PlatformException catch (_) {}
      }
      return false;
    } finally {
      ObdSessionCoordinator.diagnosticRunning = false;
    }
  }

  /// Libellés des 3 phases d'interrogation (affichés avec la barre de progression).
  static const List<String> vehicleReadPhaseLabels = [
    'Interrogation du moteur...',
    'Interrogation des freins...',
    'Interrogation de l\'électronique...',
  ];

  static List<String> _dtcListFromMap(Map<Object?, Object?> map) {
    final raw = map['dtcs'];
    if (raw is! List) return [];
    return raw
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Lit le véhicule en 4 étapes (0101, 03, 07, 0A). Délai total 30 s à 3 min.
  /// [onProgress] reçoit (stepIndex 0..3, phaseLabel, progress 0.0..1.0).
  /// Ne conclut "aucun défaut" que si au moins une étape a renvoyé une réponse valide et 0 DTC.
  Future<ObdVehicleResult> getVehicleData(void Function(int step, String phaseLabel, double progress)? onProgress) async {
    if (!Platform.isAndroid) throw ObdScanException('Non supporté sur cette plateforme');
    if (ObdSessionCoordinator.liveMonitoringActive) {
      throw ObdScanException(kObdSurveillanceBlockedCode);
    }
    ObdSessionCoordinator.diagnosticRunning = true;
    try {
      var milOn = false;
      final storedDtcs = <String>[];
      final pendingDtcs = <String>[];
      final permanentDtcs = <String>[];
      var anyStepSuccess = false;
      const labels = vehicleReadPhaseLabels;
      for (var step = 0; step < 4; step++) {
        onProgress?.call(step, labels[step.clamp(0, labels.length - 1)], (step + 1) / 4);
        try {
          final map = await _channel.invokeMethod<Map<Object?, Object?>>('readVehicleDataStep', {'step': step});
          if (map == null) continue;
          final success = map['success'] == true;
          if (success) anyStepSuccess = true;
          final list = _dtcListFromMap(map);
          switch (step) {
            case 0:
              if (success && map['milOn'] == true) milOn = true;
              break;
            case 1:
              storedDtcs.addAll(list);
              break;
            case 2:
              pendingDtcs.addAll(list);
              break;
            case 3:
              permanentDtcs.addAll(list);
              break;
          }
        } on PlatformException catch (_) {}
      }
      onProgress?.call(4, labels.last, 1.0);
      final allDtcs = <String>[
        ...storedDtcs,
        ...pendingDtcs,
        ...permanentDtcs,
      ];
      if (!anyStepSuccess) {
        return const ObdVehicleResult(
          level: 'incomplete',
          message: 'Lecture incomplète - Pas de réponse du véhicule. Vérifiez le contact et le branchement du dongle.',
          dtcs: [],
          milOn: false,
          storedDtcs: [],
          pendingDtcs: [],
          permanentDtcs: [],
        );
      }
      String level;
      String message;
      if (milOn) {
        level = 'red';
        message = 'Défauts critiques : témoin moteur allumé.';
      } else if (allDtcs.isNotEmpty) {
        level = 'orange';
        message = 'Défauts enregistrés (${allDtcs.length} code(s)).';
      } else {
        level = 'green';
        message = 'Aucun défaut détecté.';
      }
      return ObdVehicleResult(
        level: level,
        message: message,
        dtcs: allDtcs,
        milOn: milOn,
        storedDtcs: storedDtcs,
        pendingDtcs: pendingDtcs,
        permanentDtcs: permanentDtcs,
      );
    } finally {
      ObdSessionCoordinator.diagnosticRunning = false;
    }
  }

  /// Déconnecte le dongle et émet [ObdDisconnected].
  Future<void> disconnect() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disconnect');
    } on PlatformException catch (_) {}
    _controller.add(const ObdDisconnected());
  }

  void dispose() {
    // Instance partagée : ne pas fermer le flux (autres écrans écoutent encore).
  }
}
