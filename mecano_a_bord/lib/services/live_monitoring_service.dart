// live_monitoring_service.dart — Surveillance OBD temps réel (Mode conduite).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/services/bluetooth_obd_service.dart';
import 'package:mecano_a_bord/services/obd_session_coordinator.dart';
import 'package:mecano_a_bord/services/tts_service.dart';
import 'package:mecano_a_bord/services/surveillance_auto_gate.dart';
import 'package:mecano_a_bord/services/vehicle_health_service.dart';

/// PIDs mode 01 (hex sans espace, comme le dongle ELM327).
const String kLivePidCoolant = '0105';
const String kLivePidVoltage = '0142';
const String kLivePidPressure = '010B';
const String kLivePidRpm = '010C';

/// Simulation démo / tests : `normal` | `alert_temp` | `alert_volt` | `alert_oil`.
/// En production, laisser `normal` (valeurs stables fictives en démo).
String liveMonitoringDemoScenario = 'normal';

/// Indique si la surveillance tourne (Mode conduite).
final ValueNotifier<bool> liveMonitoringRunningNotifier = ValueNotifier<bool>(false);

/// Bandeau d’alerte (null = rien). Couleur : orange / rouge selon gravité.
final ValueNotifier<LiveMonitoringBanner?> liveMonitoringBannerNotifier =
    ValueNotifier<LiveMonitoringBanner?>(null);

class LiveMonitoringBanner {
  const LiveMonitoringBanner({required this.message, required this.isCritical});

  final String message;
  /// true = rouge, false = orange.
  final bool isCritical;
}

enum _AlertKind {
  tempL1,
  tempL2,
  tempL3,
  voltOrange,
  voltRed,
  voltOrangeEv,
  oilCritical,
}

/// Boucle surveillance PID + seuils + TTS (anti-spam 2 min).
class LiveMonitoringService {
  LiveMonitoringService._();
  static final LiveMonitoringService instance = LiveMonitoringService._();

  final BluetoothObdService _obd = BluetoothObdService.instance;
  final MabRepository _repository = MabRepository.instance;

  Timer? _timerAll;

  final Map<_AlertKind, DateTime> _lastSpoken = {};

  /// Démo uniquement : annonces PID non supportés.
  bool _oilUnsupportedAnnounced = false;
  bool _tempUnsupportedAnnounced = false;
  bool _voltUnsupportedAnnounced = false;

  static const Duration _alertCooldown = Duration(minutes: 2);

  /// Sondage identique au coordinateur AUTO : une requête PID toutes les 4 s = dongle actif (LED).
  static const Duration _productionPollInterval = Duration(seconds: 4);

  /// Régime mini cohérent avec un moteur thermique au ralenti / tourne (hors coupé).
  static const double _engineRunningMinRpm = 400;

  bool get isMonitoringActive => ObdSessionCoordinator.liveMonitoringActive;

  /// Démarre la surveillance (refus si diagnostic en cours).
  /// Retourne `false` si impossible (diagnostic en cours).
  Future<bool> start() async {
    if (ObdSessionCoordinator.diagnosticRunning) {
      return false;
    }
    if (ObdSessionCoordinator.liveMonitoringActive) {
      return true;
    }
    ObdSessionCoordinator.liveMonitoringActive = true;
    liveMonitoringRunningNotifier.value = true;
    SurveillanceAutoGate.onUserOrAutoStartedMonitoring();

    final demo = await _repository.isDemoMode();

    _timerAll?.cancel();

    if (demo) {
      _oilUnsupportedAnnounced = false;
      _tempUnsupportedAnnounced = false;
      _voltUnsupportedAnnounced = false;
      unawaited(_pollDemoCycle());
      _timerAll = Timer.periodic(_productionPollInterval, (_) => unawaited(_pollDemoCycle()));
    } else {
      unawaited(_pollProduction());
      _timerAll = Timer.periodic(_productionPollInterval, (_) => unawaited(_pollProduction()));
    }

    return true;
  }

  /// [obdDisconnected] : vrai si l’arrêt vient d’une perte de lien OBD (coordinateur AUTO).
  void stop({bool obdDisconnected = false}) {
    _timerAll?.cancel();
    _timerAll = null;
    _lastSpoken.clear();
    ObdSessionCoordinator.liveMonitoringActive = false;
    liveMonitoringRunningNotifier.value = false;
    liveMonitoringBannerNotifier.value = null;
    VehicleHealthService.instance.resetLiveMonitoringWarmupState();
    if (!obdDisconnected) {
      SurveillanceAutoGate.userStoppedManually();
    }
  }

  /// Hors démo : lecture groupée + [VehicleHealthService] (références + apprentissage + alertes graduées).
  Future<void> _pollProduction() async {
    if (!ObdSessionCoordinator.liveMonitoringActive) return;

    final native = await _obd.readNativeConnectionState();
    if (native is! ObdConnected) {
      stop(obdDisconnected: true);
      return;
    }

    final rt = await _obd.readLivePid(kLivePidCoolant);
    final rv = await _obd.readLivePid(kLivePidVoltage);
    final rr = await _obd.readLivePid(kLivePidRpm);
    final ro = await _obd.readLivePid(kLivePidPressure);

    final ecuResponding = rt.success || rv.success || rr.success || ro.success;
    if (!ecuResponding) {
      stop(obdDisconnected: true);
      return;
    }

    final profile = await _repository.getActiveVehicleProfile();
    final isElectric = profile?.fuelType.toLowerCase().contains('électrique') ?? false;

    final engineRunning = isElectric
        ? ecuResponding
        : (rr.success &&
            rr.supported &&
            rr.value >= _engineRunningMinRpm &&
            rr.value < 12000);

    await VehicleHealthService.instance.processLiveSample(
      demo: false,
      ecuResponding: ecuResponding,
      engineRunning: engineRunning,
      coolantC: rt.value,
      coolantSupported: rt.supported,
      volt: rv.value,
      voltSupported: rv.supported,
      rpm: rr.value,
      rpmSupported: rr.supported,
      oilPressureKpa: ro.value,
      oilPressureSupported: ro.supported,
      isElectricVehicle: isElectric,
    );
  }

  // ——— Démo : ancienne logique par seuils (scénarios de test) ———

  Future<void> _pollDemoCycle() async {
    if (!ObdSessionCoordinator.liveMonitoringActive) return;
    await _pollTemp(true);
    await _pollVolt(true);
    await _pollOil(true);
  }

  double _demoTemp() {
    switch (liveMonitoringDemoScenario) {
      case 'alert_temp':
        return 102;
      case 'alert_volt':
        return 90;
      case 'alert_oil':
        return 90;
      default:
        return 90;
    }
  }

  double _demoVolt() {
    switch (liveMonitoringDemoScenario) {
      case 'alert_volt':
        return 12.0;
      case 'alert_temp':
      case 'alert_oil':
        return 14.0;
      default:
        return 14.0;
    }
  }

  double _demoKpa() {
    switch (liveMonitoringDemoScenario) {
      case 'alert_oil':
        return 50;
      default:
        return 200;
    }
  }

  Future<void> _pollTemp(bool demo) async {
    if (!ObdSessionCoordinator.liveMonitoringActive) return;
    double c;
    bool supported = true;
    if (demo) {
      c = _demoTemp();
    } else {
      final r = await _obd.readLivePid(kLivePidCoolant);
      supported = r.supported;
      c = r.value;
    }
    if (!supported) {
      if (!_tempUnsupportedAnnounced) {
        _tempUnsupportedAnnounced = true;
        liveMonitoringBannerNotifier.value = const LiveMonitoringBanner(
          message:
              'La température moteur n\'est pas accessible via la prise OBD sur ce véhicule. Reste attentif à ton témoin de température.',
          isCritical: false,
        );
      }
      return;
    }
    if (c >= 100 && c < 105) {
      await _maybeSpeak(
        _AlertKind.tempL1,
        'Attention, ta température moteur commence à monter. Surveille ton tableau de bord et réduis ta vitesse.',
        orangeBanner:
            'Température moteur un peu haute — surveille ton tableau de bord.',
      );
    } else if (c >= 105 && c <= 110) {
      await _maybeSpeak(
        _AlertKind.tempL2,
        'Ta température moteur monte trop. Range-toi dès que possible dans un endroit sûr et coupe le moteur.',
        orangeBanner: null,
        redBanner:
            'Température moteur trop élevée — range-toi dès que possible.',
      );
    } else if (c > 110) {
      await _maybeSpeak(
        _AlertKind.tempL3,
        'Arrête-toi immédiatement dans un endroit sûr et coupe le moteur. N\'ouvre pas le capot tout de suite, laisse refroidir au moins 30 minutes. Vérifie ensuite ton niveau d\'eau et que ton ventilateur fonctionne avant de redémarrer.',
        orangeBanner: null,
        redBanner: 'Surchauffe : arrête-toi et coupe le moteur.',
      );
    }
  }

  Future<void> _pollVolt(bool demo) async {
    if (!ObdSessionCoordinator.liveMonitoringActive) return;
    final profile = await _repository.getActiveVehicleProfile();
    final isElectric = profile?.fuelType.toLowerCase().contains('électrique') ?? false;

    double v;
    bool supported = true;
    if (demo) {
      v = _demoVolt();
    } else {
      final r = await _obd.readLivePid(kLivePidVoltage);
      supported = r.supported;
      v = r.value;
    }
    if (!supported) {
      if (!_voltUnsupportedAnnounced) {
        _voltUnsupportedAnnounced = true;
        liveMonitoringBannerNotifier.value = const LiveMonitoringBanner(
          message:
              'La tension batterie n\'est pas accessible via la prise OBD sur ce véhicule.',
          isCritical: false,
        );
      }
      return;
    }
    if (v > 13.5) {
      return;
    }
    if (v > 11.5 && v < 12.5) {
      if (isElectric) {
        await _maybeSpeak(
          _AlertKind.voltOrangeEv,
          'La tension de ta batterie auxiliaire 12V est basse. Ce n\'est pas la batterie principale de traction mais elle est importante pour ton électronique. Fais-la contrôler prochainement.',
          orangeBanner: 'Tension 12 V auxiliaire basse — fais contrôler prochainement.',
        );
      } else {
        await _maybeSpeak(
          _AlertKind.voltOrange,
          'Ta tension batterie est basse. Tu peux continuer à rouler en restant prudent. Mais pense à faire contrôler ta batterie et ton alternateur chez un professionnel prochainement.',
          orangeBanner: 'Tension batterie basse — fais contrôler bientôt.',
        );
      }
    } else if (v <= 11.5) {
      await _maybeSpeak(
        _AlertKind.voltRed,
        'Ta tension batterie chute. Tu peux continuer à rouler pour l\'instant mais ne coupe pas ton moteur. Rends-toi directement chez un garagiste ou dans un centre auto pour faire contrôler ta batterie et ton alternateur dès aujourd\'hui.',
        orangeBanner: null,
        redBanner: 'Tension batterie très basse — ne coupe pas le moteur, fais contrôler aujourd\'hui.',
      );
    }
  }

  Future<void> _pollOil(bool demo) async {
    if (!ObdSessionCoordinator.liveMonitoringActive) return;
    double kpa;
    bool supported = true;
    if (demo) {
      kpa = _demoKpa();
    } else {
      final r = await _obd.readLivePid(kLivePidPressure);
      supported = r.supported;
      kpa = r.value;
    }
    if (!supported) {
      if (!_oilUnsupportedAnnounced) {
        _oilUnsupportedAnnounced = true;
        liveMonitoringBannerNotifier.value = const LiveMonitoringBanner(
          message:
              'La pression d\'huile de ton véhicule n\'est pas accessible via la prise OBD. C\'est fréquent sur les véhicules avant 2003. Reste attentif à ton voyant de pression d\'huile sur ton tableau de bord — Mécano à Bord ne peut pas te prévenir sur ce point.',
          isCritical: false,
        );
      }
      return;
    }
    if (kpa < 100) {
      await _maybeSpeak(
        _AlertKind.oilCritical,
        'Attention, ta pression d\'huile est anormalement basse. Arrête-toi dès que possible dans un endroit sûr et coupe le moteur immédiatement. Ne redémarre pas avant d\'avoir fait vérifier ton niveau d\'huile et ta pression par un professionnel.',
        orangeBanner: null,
        redBanner: 'Pression d\'huile très basse — arrête-toi et coupe le moteur.',
      );
    }
  }

  Future<void> _maybeSpeak(
    _AlertKind kind,
    String ttsMessage, {
    String? orangeBanner,
    String? redBanner,
  }) async {
    final now = DateTime.now();
    final last = _lastSpoken[kind];
    if (last != null && now.difference(last) < _alertCooldown) {
      return;
    }
    _lastSpoken[kind] = now;
    if (redBanner != null) {
      liveMonitoringBannerNotifier.value = LiveMonitoringBanner(message: redBanner, isCritical: true);
    } else if (orangeBanner != null) {
      liveMonitoringBannerNotifier.value =
          LiveMonitoringBanner(message: orangeBanner, isCritical: false);
    }
    await TtsService.instance.speakLiveMonitoringAlert(ttsMessage);
  }
}
