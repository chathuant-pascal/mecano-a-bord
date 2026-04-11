// Mode conduite AUTO : démarre / arrête la surveillance selon la connexion OBD réelle.

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/services/bluetooth_obd_service.dart';
import 'package:mecano_a_bord/services/live_monitoring_service.dart';
import 'package:mecano_a_bord/services/obd_session_coordinator.dart';
import 'package:mecano_a_bord/services/surveillance_auto_gate.dart';
import 'package:mecano_a_bord/services/tts_service.dart';

/// PID utilisé pour vérifier que le calculateur répond avant TTS / surveillance (même logique que le mode conduite).
const String _kPingPidRpm = '010C';

/// Écoute la connexion OBD (flux + sondage) et applique le mode AUTO (SharedPreferences `monitoring_mode`).
class SurveillanceAutoCoordinator {
  SurveillanceAutoCoordinator._();
  static final SurveillanceAutoCoordinator instance = SurveillanceAutoCoordinator._();

  StreamSubscription<ObdConnectionState>? _sub;
  Timer? _poll;
  bool _prevPhysicallyConnected = false;
  bool _prevIsAuto = true;
  bool _pendingReconnectWording = false;

  void attach() {
    _sub?.cancel();
    _sub = BluetoothObdService.instance.connectionState.listen((_) {
      unawaited(_tick());
    });
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => unawaited(_tick()));
    unawaited(_tick());
  }

  void onSurveillanceStarted() {
    SurveillanceAutoGate.onUserOrAutoStartedMonitoring();
  }

  void markUserStoppedMonitoring() {
    SurveillanceAutoGate.userStoppedManually();
  }

  Future<void> _tick() async {
    if (await MabRepository.instance.isDemoMode()) return;

    final prefs = await SharedPreferences.getInstance();
    final isAuto = (prefs.getString('monitoring_mode') ?? 'AUTO') == 'AUTO';

    if (isAuto && !_prevIsAuto) {
      SurveillanceAutoGate.clearedOnPhysicalDisconnect();
    }
    _prevIsAuto = isAuto;

    final native = await BluetoothObdService.instance.readNativeConnectionState();
    final connected = native is ObdConnected;
    final was = _prevPhysicallyConnected;

    if (connected && !was) {
      await _onPhysicalConnect(isAuto);
    } else if (!connected && was) {
      await _onPhysicalDisconnect(isAuto);
    } else if (isAuto &&
        connected &&
        !ObdSessionCoordinator.diagnosticRunning &&
        !ObdSessionCoordinator.liveMonitoringActive &&
        !SurveillanceAutoGate.blockAutoResumeUntilReconnect) {
      await _resumeAutoWhileAlreadyConnected();
    }

    _prevPhysicallyConnected = connected;
  }

  Future<void> _onPhysicalConnect(bool isAuto) async {
    if (!isAuto) return;
    if (ObdSessionCoordinator.diagnosticRunning) return;
    if (ObdSessionCoordinator.liveMonitoringActive) return;

    final ecuOk = await _ecuRespondsToPing();
    if (!ecuOk) {
      // Pas de TTS : le calculateur ne répond pas encore (contact coupé, etc.). La boucle _tick réessaiera via _resumeAutoWhileAlreadyConnected.
      return;
    }

    final ok = await LiveMonitoringService.instance.start();
    if (!ok) return;

    final msg = _pendingReconnectWording
        ? 'Me revoilà ! Je reprends la surveillance.'
        : 'Je suis connecté. Je surveille ta voiture pour toi. Bonne route !';
    _pendingReconnectWording = false;
    await TtsService.instance.speakLiveMonitoringAlert(msg);
  }

  Future<void> _onPhysicalDisconnect(bool isAuto) async {
    SurveillanceAutoGate.clearedOnPhysicalDisconnect();
    if (!ObdSessionCoordinator.liveMonitoringActive) return;

    LiveMonitoringService.instance.stop(obdDisconnected: true);
    if (isAuto) {
      _pendingReconnectWording = true;
    }
    await TtsService.instance.speakLiveMonitoringAlert(
      'Je ne vois plus le boîtier. Je mets la surveillance en pause.',
    );
  }

  Future<void> _resumeAutoWhileAlreadyConnected() async {
    if (ObdSessionCoordinator.diagnosticRunning) return;

    final ecuOk = await _ecuRespondsToPing();
    if (!ecuOk) return;

    final ok = await LiveMonitoringService.instance.start();
    if (!ok) return;
    await TtsService.instance.speakLiveMonitoringAlert(
      'Je suis connecté. Je surveille ta voiture pour toi. Bonne route !',
    );
  }

  /// Une vraie requête PID vers le dongle : pas de surveillance / TTS si le calculateur ne répond pas.
  Future<bool> _ecuRespondsToPing() async {
    final r = await BluetoothObdService.instance.readLivePid(_kPingPidRpm);
    return r.success;
  }
}
