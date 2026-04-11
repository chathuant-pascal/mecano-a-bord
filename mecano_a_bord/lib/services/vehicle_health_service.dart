// vehicle_health_service.dart — Surveillance pédagogique OBD (niveaux 0 / 1 / 2, apprentissage 14 jours).

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:mecano_a_bord/data/mab_database.dart' as mab_db;
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/services/live_monitoring_service.dart';
import 'package:mecano_a_bord/services/tts_service.dart';

/// Badge onglet Santé : phase de chauffe normale (PID 0105 sous 70 °C, début de surveillance).
final ValueNotifier<bool> vehicleWarmupPhaseActiveNotifier =
    ValueNotifier<bool>(false);

/// Seuils par défaut si aucune référence constructeur ni apprentissage.
class _FallbackBands {
  static const double coolantMin = 80;
  static const double coolantMax = 105;
  static const double voltMin = 12.2;
  static const double voltMax = 14.9;
  static const double rpmIdleMin = 600;
  static const double rpmIdleMax = 1000;
}

/// Référence constructeur (champs optionnels selon réponse IA).
class ManufacturerBands {
  ManufacturerBands({
    this.coolantMin,
    this.coolantMax,
    this.voltMin,
    this.voltMax,
    this.rpmIdleMin,
    this.rpmIdleMax,
  });

  final double? coolantMin;
  final double? coolantMax;
  final double? voltMin;
  final double? voltMax;
  final double? rpmIdleMin;
  final double? rpmIdleMax;

  static ManufacturerBands? fromJsonString(String? json) {
    if (json == null || json.trim().isEmpty) return null;
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      double? read(String key) {
        final v = m[key];
        if (v == null) return null;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString());
      }

      return ManufacturerBands(
        coolantMin: read('temperature_normale_min'),
        coolantMax: read('temperature_normale_max'),
        voltMin: read('tension_batterie_min'),
        voltMax: read('tension_batterie_max'),
        rpmIdleMin: read('regime_ralenti_min'),
        rpmIdleMax: read('regime_ralenti_max'),
      );
    } catch (_) {
      return null;
    }
  }
}

class _Agg {
  _Agg();
  int n = 0;
  double sum = 0;
  double sumSq = 0;

  void add(double x) {
    n++;
    sum += x;
    sumSq += x * x;
  }

  double get mean => n == 0 ? 0 : sum / n;

  double get std {
    if (n < 2) return 0;
    final m = mean;
    return math.sqrt(math.max(0, (sumSq / n) - (m * m)));
  }

  Map<String, dynamic> toMap() => {'n': n, 'sum': sum, 'sumsq': sumSq};

  static _Agg fromMap(Map<String, dynamic>? m) {
    final a = _Agg();
    if (m == null) return a;
    a.n = (m['n'] as num?)?.toInt() ?? 0;
    a.sum = (m['sum'] as num?)?.toDouble() ?? 0;
    a.sumSq = (m['sumsq'] as num?)?.toDouble() ?? 0;
    return a;
  }
}

/// Service principal : enregistrement apprentissage + alertes graduées + bilan positif.
class VehicleHealthService {
  VehicleHealthService._();
  static final VehicleHealthService instance = VehicleHealthService._();

  final MabRepository _repo = MabRepository.instance;

  static const Duration _alertCooldown = Duration(minutes: 2);
  static const Duration _positiveBilanInterval = Duration(hours: 2);
  static const int _learningDays = 14;

  /// Nouvelle session surveillance si interruption de plus de 2 min entre deux échantillons.
  static const Duration _surveillanceSessionGapReset = Duration(minutes: 2);
  static const Duration _warmupPhaseMaxDuration = Duration(minutes: 10);

  final Map<String, DateTime> _lastSpoken = {};
  DateTime? _lastPositiveBilanLocal;

  DateTime? _lastSampleAt;
  DateTime? _surveillanceSessionStart;
  bool _warmupStartAnnounced = false;
  bool _warmupEndAnnounced = false;

  /// À appeler à l’arrêt du mode conduite : badge chauffe + état interne.
  void resetLiveMonitoringWarmupState() {
    _lastSampleAt = null;
    _surveillanceSessionStart = null;
    _warmupStartAnnounced = false;
    _warmupEndAnnounced = false;
    vehicleWarmupPhaseActiveNotifier.value = false;
  }

  /// Traite une lecture temps réel (depuis [LiveMonitoringService]).
  /// [ecuResponding] : au moins une lecture PID a réussi (dongle + calculateur OK).
  /// [engineRunning] : régime moteur cohérent avec un moteur tournant (bilan positif, annonces chauffe).
  Future<void> processLiveSample({
    required bool demo,
    bool ecuResponding = true,
    bool engineRunning = true,
    double? coolantC,
    required bool coolantSupported,
    double? volt,
    required bool voltSupported,
    double? rpm,
    required bool rpmSupported,
    double? oilPressureKpa,
    required bool oilPressureSupported,
    required bool isElectricVehicle,
  }) async {
    if (demo) {
      vehicleWarmupPhaseActiveNotifier.value = false;
      await _handleDemoBanner();
      return;
    }

    if (!ecuResponding) return;

    final vid = await _activeVehicleId();
    if (vid == null) return;

    final now = DateTime.now();
    if (_lastSampleAt != null &&
        now.difference(_lastSampleAt!) > _surveillanceSessionGapReset) {
      _surveillanceSessionStart = null;
      _warmupStartAnnounced = false;
      _warmupEndAnnounced = false;
    }
    _lastSampleAt = now;
    _surveillanceSessionStart ??= now;

    final profile = await _repo.getActiveVehicleProfile();
    final vehicleLabel = profile == null
        ? 'ton véhicule'
        : 'ta ${profile.brand} ${profile.model}';

    final refJson = await _repo.getVehicleReferenceJson(vid);
    final mfg = ManufacturerBands.fromJsonString(refJson);

    var learned = await _repo.getVehicleLearnedValuesEntry(vid);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    learned ??= mab_db.VehicleLearnedValuesEntry(
      vehicleProfileId: vid,
      learningStartedMs: nowMs,
      learningCompleted: false,
      aggregatesJson: '{}',
      sampleCount: 0,
    );

    final learningEnd = DateTime.fromMillisecondsSinceEpoch(
      learned.learningStartedMs,
    ).add(const Duration(days: _learningDays));
    final learningDone =
        learned.learningCompleted || DateTime.now().isAfter(learningEnd);

    learned = await _recordLearning(
      learned: learned,
      coolantC: coolantC,
      volt: volt,
      rpm: rpm,
      nowMs: nowMs,
      learningDone: learningDone,
    );

    final aggs = _parseAggregates(learned.aggregatesJson);

    final bands = _resolveBands(
      mfg: mfg,
      aggs: aggs,
      learningComplete: learningDone || learned.sampleCount > 200,
    );

    int worst = 0;
    String? message;
    String? technical;
    bool critical = false;
    var inWarmupSuppress = false;
    var emergencyWarmupOverheat = false;

    if (coolantSupported && coolantC != null) {
      final elapsed = now.difference(_surveillanceSessionStart!);
      final inFirstTenMin = elapsed < _warmupPhaseMaxDuration;

      if (inFirstTenMin && coolantC > 105) {
        emergencyWarmupOverheat = true;
        vehicleWarmupPhaseActiveNotifier.value = false;
        worst = 2;
        message =
            'Attention, ton moteur chauffe trop vite. Arrête-toi et coupe le moteur.';
        technical =
            'Température liquide de refroidissement : ${coolantC.toStringAsFixed(0)} °C';
        critical = true;
      } else if (inFirstTenMin && coolantC < 70) {
        inWarmupSuppress = true;
        vehicleWarmupPhaseActiveNotifier.value = true;
        if (engineRunning) {
          await _ensureWarmupStartVoiceOnce();
        }
      } else {
        vehicleWarmupPhaseActiveNotifier.value = false;
        final r = _evalCoolant(coolantC, bands.coolantMin, bands.coolantMax);
        if (r.level > worst) {
          worst = r.level;
          message = r.message;
          technical = r.technical;
          critical = r.critical;
        }
      }
    } else {
      vehicleWarmupPhaseActiveNotifier.value = false;
    }

    if (!emergencyWarmupOverheat) {
      await _maybeWarmupReachedOperatingTempVoice(
        coolantC: coolantC,
        coolantSupported: coolantSupported,
        engineRunning: engineRunning,
      );
    }

    if (voltSupported && volt != null) {
      final r = _evalVoltage(
        volt,
        bands.voltMin,
        bands.voltMax,
        isElectric: isElectricVehicle,
      );
      if (r.level > worst) {
        worst = r.level;
        message = r.message;
        technical = r.technical;
        critical = r.critical;
      }
    }

    if (rpmSupported && rpm != null && rpm < 1400 && rpm > 400) {
      final r = _evalRpmIdle(rpm, bands.rpmMin, bands.rpmMax);
      if (r.level > worst) {
        worst = r.level;
        message = r.message;
        technical = r.technical;
        critical = r.critical;
      }
    }

    if (oilPressureSupported &&
        oilPressureKpa != null &&
        oilPressureKpa < 100) {
      worst = 2;
      message =
          'La pression d’huile moteur est très basse. Arrête-toi dans un endroit sûr et coupe le moteur. '
          'Ne reprends pas la route avant qu’un professionnel ait vérifié le niveau et la pression d’huile.';
      technical =
          'Pression huile (OBD) : ${oilPressureKpa.toStringAsFixed(0)} kPa';
      critical = true;
    }

    if (worst > 0 && message != null && engineRunning) {
      final key = 'L$worst-${message.hashCode}';
      final last = _lastSpoken[key];
      if (last == null || DateTime.now().difference(last) > _alertCooldown) {
        _lastSpoken[key] = DateTime.now();
        liveMonitoringBannerNotifier.value = LiveMonitoringBanner(
          message: message,
          isCritical: critical,
        );
        await TtsService.instance.speakLiveMonitoringAlert(message);
        await _repo.appendVehicleHealthAlert(
          vehicleProfileId: vid,
          level: worst,
          message: message,
          technicalDetail: technical,
        );
      }
    } else {
      liveMonitoringBannerNotifier.value = null;
      if (!inWarmupSuppress) {
        await _maybePositiveBilan(
          vehicleId: vid,
          vehicleLabel: vehicleLabel,
          learned: learned,
          worstLevel: worst,
          engineRunning: engineRunning,
        );
      }
    }
  }

  Future<void> _ensureWarmupStartVoiceOnce() async {
    if (_warmupStartAnnounced) return;
    _warmupStartAnnounced = true;
    await TtsService.instance.speakLiveMonitoringAlert(
      'Ton moteur se réchauffe tranquillement. C\'est parfaitement normal. '
      'Je garde un œil pour toi.',
    );
  }

  Future<void> _maybeWarmupReachedOperatingTempVoice({
    required double? coolantC,
    required bool coolantSupported,
    required bool engineRunning,
  }) async {
    if (!engineRunning) return;
    if (!coolantSupported || coolantC == null) return;
    if (!_warmupStartAnnounced || _warmupEndAnnounced) return;
    if (coolantC >= 70 && coolantC < 110) {
      _warmupEndAnnounced = true;
      await TtsService.instance.speakLiveMonitoringAlert(
        'Ton moteur est chaud. Tout est normal, on peut y aller !',
      );
    }
  }

  Future<void> _handleDemoBanner() async {
    liveMonitoringBannerNotifier.value = null;
  }

  Future<int?> _activeVehicleId() async {
    if (await _repo.isDemoMode()) return null;
    final p = await _repo.getActiveVehicleProfile();
    if (p == null || p.id.isEmpty) return null;
    return int.tryParse(p.id);
  }

  void _addAgg(Map<String, dynamic> ag, String key, double x) {
    final a = _Agg.fromMap(Map<String, dynamic>.from(ag[key] as Map? ?? {}));
    a.add(x);
    ag[key] = a.toMap();
  }

  Future<mab_db.VehicleLearnedValuesEntry> _recordLearning({
    required mab_db.VehicleLearnedValuesEntry learned,
    double? coolantC,
    double? volt,
    double? rpm,
    required int nowMs,
    required bool learningDone,
  }) async {
    final ag = _parseAggregates(learned.aggregatesJson);
    var count = learned.sampleCount;

    if (coolantC != null && coolantC >= 75 && coolantC <= 110) {
      _addAgg(ag, 'coolant', coolantC);
      count++;
    }
    if (volt != null && volt > 11 && volt < 16) {
      _addAgg(ag, 'volt', volt);
      count++;
    }
    if (rpm != null && rpm > 400 && rpm < 1400) {
      _addAgg(ag, 'rpm', rpm);
      count++;
    }

    final completed = learningDone || count > 200;
    final updated = mab_db.VehicleLearnedValuesEntry(
      vehicleProfileId: learned.vehicleProfileId,
      learningStartedMs: learned.learningStartedMs,
      lastSampleMs: nowMs,
      learningCompleted: completed,
      aggregatesJson: jsonEncode(ag),
      sampleCount: count,
      lastPositiveBilanMs: learned.lastPositiveBilanMs,
    );
    await _repo.upsertVehicleLearnedValuesEntry(updated);
    return updated;
  }

  Map<String, dynamic> _parseAggregates(String json) {
    try {
      final d = jsonDecode(json);
      if (d is Map<String, dynamic>) return Map<String, dynamic>.from(d);
    } catch (_) {}
    return {};
  }

  ({
    double coolantMin,
    double coolantMax,
    double voltMin,
    double voltMax,
    double rpmMin,
    double rpmMax,
  })
  _resolveBands({
    required ManufacturerBands? mfg,
    required Map<String, dynamic> aggs,
    required bool learningComplete,
  }) {
    double cm = mfg?.coolantMin ?? _FallbackBands.coolantMin;
    double cx = mfg?.coolantMax ?? _FallbackBands.coolantMax;
    double vm = mfg?.voltMin ?? _FallbackBands.voltMin;
    double vx = mfg?.voltMax ?? _FallbackBands.voltMax;
    double rm = mfg?.rpmIdleMin ?? _FallbackBands.rpmIdleMin;
    double rx = mfg?.rpmIdleMax ?? _FallbackBands.rpmIdleMax;

    if (learningComplete) {
      final ac = _Agg.fromMap(Map<String, dynamic>.from(aggs['coolant'] as Map? ?? {}));
      final av = _Agg.fromMap(Map<String, dynamic>.from(aggs['volt'] as Map? ?? {}));
      final ar = _Agg.fromMap(Map<String, dynamic>.from(aggs['rpm'] as Map? ?? {}));
      if (ac.n >= 5) {
        final lo = ac.mean - 1.5 * ac.std;
        final hi = ac.mean + 1.5 * ac.std;
        cm = math.min(cm, lo);
        cx = math.max(cx, hi);
      }
      if (av.n >= 5) {
        final lo = av.mean - 1.5 * av.std;
        final hi = av.mean + 1.5 * av.std;
        vm = math.min(vm, lo);
        vx = math.max(vx, hi);
      }
      if (ar.n >= 5) {
        final lo = ar.mean - 1.5 * ar.std;
        final hi = ar.mean + 1.5 * ar.std;
        rm = math.min(rm, lo);
        rx = math.max(rx, hi);
      }
    }

    return (
      coolantMin: cm,
      coolantMax: cx,
      voltMin: vm,
      voltMax: vx,
      rpmMin: rm,
      rpmMax: rx,
    );
  }

  ({
    int level,
    String message,
    String? technical,
    bool critical,
  }) _evalCoolant(double v, double minB, double maxB) {
    if (v >= 110) {
      return (
        level: 2,
        message:
            'Arrête-toi dans un endroit sûr et coupe le moteur. La température du moteur est trop élevée. '
            'Attends au moins trente minutes avant d’ouvrir le capot, puis fais vérifier le liquide de refroidissement par un professionnel.',
        technical:
            'Température liquide de refroidissement : ${v.toStringAsFixed(0)} °C',
        critical: true,
      );
    }
    if (v >= 105) {
      return (
        level: 2,
        message:
            'La température moteur est trop élevée. Ralentis, range-toi dès que tu peux en sécurité et coupe le moteur pour laisser refroidir.',
        technical:
            'Température liquide de refroidissement : ${v.toStringAsFixed(0)} °C',
        critical: true,
      );
    }
    if (v >= 100 && v < 105) {
      return (
        level: 1,
        message:
            'La température moteur monte un peu plus que d’habitude. Ralentis et surveille le voyant sur ton tableau de bord. '
            'Ce n’est pas une urgence immédiate, mais reste attentif.',
        technical:
            'Température liquide de refroidissement : ${v.toStringAsFixed(0)} °C',
        critical: false,
      );
    }

    final mid = (minB + maxB) / 2;
    if (mid <= 0) {
      return (level: 0, message: '', technical: null, critical: false);
    }
    if (v >= minB && v <= maxB) {
      return (level: 0, message: '', technical: null, critical: false);
    }

    double pct;
    if (v < minB) {
      pct = (minB - v) / minB * 100;
    } else {
      pct = (v - maxB) / maxB * 100;
    }

    if (pct > 20) {
      return (
        level: 2,
        message:
            'La température du moteur s’écarte beaucoup de ce qui est habituel pour ta voiture. '
            'Prévois un contrôle chez un professionnel dès que possible.',
        technical:
            'Température liquide de refroidissement : ${v.toStringAsFixed(0)} °C',
        critical: false,
      );
    }
    if (pct >= 10) {
      return (
        level: 1,
        message:
            'La température moteur est un peu en dehors de ses habitudes. Pas d’inquiétude immédiate, mais garde un œil sur le voyant et sur l’aiguille.',
        technical:
            'Température liquide de refroidissement : ${v.toStringAsFixed(0)} °C',
        critical: false,
      );
    }
    return (level: 0, message: '', technical: null, critical: false);
  }

  ({
    int level,
    String message,
    String? technical,
    bool critical,
  }) _evalVoltage(
    double v,
    double minB,
    double maxB, {
    required bool isElectric,
  }) {
    if (v <= 11.5) {
      return (
        level: 2,
        message: isElectric
            ? 'La batterie auxiliaire 12 V est très faible. Évite de couper le contact et fais contrôler rapidement la charge par un professionnel.'
            : 'La tension de la batterie chute fortement. Évite de couper le moteur et rends-toi chez un professionnel pour un contrôle batterie / alternateur.',
        technical: 'Tension OBD : ${v.toStringAsFixed(1)} V',
        critical: true,
      );
    }
    if (v > 11.5 && v < 12.5) {
      return (
        level: 1,
        message: isElectric
            ? 'La batterie auxiliaire 12 V est un peu basse. Prévois un contrôle prochainement.'
            : 'La tension batterie est un peu basse. Tu peux continuer, mais fais vérifier batterie et alternateur bientôt.',
        technical: 'Tension OBD : ${v.toStringAsFixed(1)} V',
        critical: false,
      );
    }
    if (v > 13.5) {
      return (level: 0, message: '', technical: null, critical: false);
    }

    final mid = (minB + maxB) / 2;
    if (mid <= 0) return (level: 0, message: '', technical: null, critical: false);
    if (v >= minB && v <= maxB) {
      return (level: 0, message: '', technical: null, critical: false);
    }

    double pct;
    if (v < minB) {
      pct = (minB - v) / minB * 100;
    } else {
      pct = (v - maxB) / maxB * 100;
    }

    if (pct > 20) {
      return (
        level: 2,
        message:
            'La tension électrique s’écarte fortement de l’habituel. Un professionnel pourra confirmer si la batterie ou la charge vont bien.',
        technical: 'Tension OBD : ${v.toStringAsFixed(1)} V',
        critical: false,
      );
    }
    if (pct >= 10) {
      return (
        level: 1,
        message:
            'La tension batterie est un peu en dehors de ses valeurs habituelles. Surveille les voyants et prévois un contrôle.',
        technical: 'Tension OBD : ${v.toStringAsFixed(1)} V',
        critical: false,
      );
    }
    return (level: 0, message: '', technical: null, critical: false);
  }

  ({
    int level,
    String message,
    String? technical,
    bool critical,
  }) _evalRpmIdle(double rpm, double minB, double maxB) {
    if (rpm >= minB && rpm <= maxB) {
      return (level: 0, message: '', technical: null, critical: false);
    }
    final mid = (minB + maxB) / 2;
    if (mid <= 0) return (level: 0, message: '', technical: null, critical: false);
    double pct;
    if (rpm < minB) {
      pct = (minB - rpm) / minB * 100;
    } else {
      pct = (rpm - maxB) / maxB * 100;
    }
    if (pct > 20) {
      return (
        level: 2,
        message:
            'Le régime moteur au ralenti est très différent de l’habituel. Un professionnel pourra vérifier si tout est normal (papillon, admission, etc.).',
        technical: 'Régime moteur : ${rpm.toStringAsFixed(0)} tr/min',
        critical: false,
      );
    }
    if (pct >= 10) {
      return (
        level: 1,
        message:
            'Le ralenti est un peu inhabituel. Rien d’urgent tout seul, mais si ça dure, fais contrôler le moteur au ralenti.',
        technical: 'Régime moteur : ${rpm.toStringAsFixed(0)} tr/min',
        critical: false,
      );
    }
    return (level: 0, message: '', technical: null, critical: false);
  }

  Future<void> _maybePositiveBilan({
    required int vehicleId,
    required String vehicleLabel,
    required mab_db.VehicleLearnedValuesEntry learned,
    required int worstLevel,
    required bool engineRunning,
  }) async {
    if (worstLevel > 0) return;
    if (!engineRunning) return;

    final now = DateTime.now();
    final lastMs = learned.lastPositiveBilanMs;
    final last = lastMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastMs)
        : _lastPositiveBilanLocal;
    if (last != null && now.difference(last) < _positiveBilanInterval) {
      return;
    }

    const key = 'pos_bilan';
    final lastSp = _lastSpoken[key];
    if (lastSp != null && now.difference(lastSp) < _positiveBilanInterval) {
      return;
    }

    _lastSpoken[key] = now;
    _lastPositiveBilanLocal = now;

    final msg =
        'Tout va bien — $vehicleLabel se comporte normalement sur cette période.';

    liveMonitoringBannerNotifier.value = LiveMonitoringBanner(
      message: msg,
      isCritical: false,
    );
    await TtsService.instance.speakLiveMonitoringAlert(msg);

    await _repo.appendVehicleHealthAlert(
      vehicleProfileId: vehicleId,
      level: 0,
      message: msg,
    );

    final updated = mab_db.VehicleLearnedValuesEntry(
      vehicleProfileId: learned.vehicleProfileId,
      learningStartedMs: learned.learningStartedMs,
      lastSampleMs: learned.lastSampleMs,
      learningCompleted: learned.learningCompleted,
      aggregatesJson: learned.aggregatesJson,
      sampleCount: learned.sampleCount,
      lastPositiveBilanMs: now.millisecondsSinceEpoch,
    );
    await _repo.upsertVehicleLearnedValuesEntry(updated);
  }
}
