// surveillance_only_screen.dart — Mode conduite : surveillance temps réel OBD.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/services/live_monitoring_service.dart';
import 'package:mecano_a_bord/services/obd_session_coordinator.dart';
import 'package:mecano_a_bord/widgets/mab_obd_session_dialogs.dart';
import 'package:mecano_a_bord/widgets/mab_watermark_background.dart';
import 'package:mecano_a_bord/widgets/mab_demo_banner.dart';

class SurveillanceOnlyScreen extends StatefulWidget {
  const SurveillanceOnlyScreen({super.key});

  @override
  State<SurveillanceOnlyScreen> createState() => _SurveillanceOnlyScreenState();
}

class _SurveillanceOnlyScreenState extends State<SurveillanceOnlyScreen> {
  final MabRepository _repository = MabRepository.instance;
  bool _isDemoMode = false;

  @override
  void initState() {
    super.initState();
    _repository.isDemoMode().then((v) {
      if (mounted) setState(() => _isDemoMode = v);
    });
  }

  Future<void> _openDiagnosticBlockedIfNeeded() async {
    if (LiveMonitoringService.instance.isMonitoringActive) {
      if (!mounted) return;
      await showMabSurveillanceBlocksDiagnosticDialog(
        context,
        onStopSurveillance: () {
          LiveMonitoringService.instance.stop();
          if (mounted) {
            Navigator.of(context).pushNamed('/obd-scan');
          }
        },
      );
      return;
    }
    if (mounted) Navigator.of(context).pushNamed('/obd-scan');
  }

  Future<void> _toggleSurveillance() async {
    if (LiveMonitoringService.instance.isMonitoringActive) {
      LiveMonitoringService.instance.stop();
      if (mounted) setState(() {});
      return;
    }
    if (ObdSessionCoordinator.diagnosticRunning) {
      if (!mounted) return;
      await showMabSurveillanceBlockedByDiagnosticDialog(context);
      return;
    }
    final ok = await LiveMonitoringService.instance.start();
    if (!ok && mounted) {
      await showMabSurveillanceBlockedByDiagnosticDialog(context);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        backgroundColor: MabColors.noir,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: MabColors.blanc),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/modeconduite.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 32,
                  height: 32,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Mode conduite',
                style: MabTextStyles.titreSection,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isDemoMode) const MabDemoBanner(),
          ValueListenableBuilder<LiveMonitoringBanner?>(
            valueListenable: liveMonitoringBannerNotifier,
            builder: (context, banner, _) {
              if (banner == null) return const SizedBox.shrink();
              final bg = banner.isCritical ? MabColors.diagnosticRougeClair : MabColors.diagnosticOrangeClair;
              final border = banner.isCritical ? MabColors.diagnosticRouge : MabColors.diagnosticOrange;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  MabDimensions.paddingEcran.left,
                  8,
                  MabDimensions.paddingEcran.right,
                  0,
                ),
                child: Material(
                  color: bg,
                  borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
                  child: Container(
                    padding: MabDimensions.paddingCard,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      banner.message,
                      style: MabTextStyles.label.copyWith(color: MabColors.blanc),
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: MabWatermarkBackground(
              assetPath: 'assets/images/modeconduite.png',
              watermarkOpacity: 0.55,
              watermarkWidthFraction: 0.85,
              child: ListView(
                padding: MabDimensions.paddingEcran,
                children: [
                  const _SurveillanceDrivingFloatingBody(),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<bool>(
                    valueListenable: liveMonitoringRunningNotifier,
                    builder: (context, running, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: MabDimensions.boutonHauteur,
                            child: ElevatedButton(
                              onPressed: _toggleSurveillance,
                              child: Text(
                                running ? 'Arrêter la surveillance' : 'Démarrer la surveillance',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: MabDimensions.boutonHauteur,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: MabColors.rouge, width: 2),
                                foregroundColor: MabColors.rouge,
                              ),
                              onPressed: _openDiagnosticBlockedIfNeeded,
                              child: const Text('Lancer un diagnostic véhicule'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Mécano à Bord est un outil d\'aide — restez toujours attentif à votre conduite.',
                    style: MabTextStyles.label.copyWith(color: MabColors.grisTexte),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/legal-mentions');
                    },
                    child: Text(
                      'Mentions légales →',
                      style: MabTextStyles.label.copyWith(color: MabColors.grisTexte),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Même logique que [SurveillanceSettingsBody], sans cadres — texte sur filigrane (ombres).
class _SurveillanceDrivingFloatingBody extends StatefulWidget {
  const _SurveillanceDrivingFloatingBody();

  @override
  State<_SurveillanceDrivingFloatingBody> createState() =>
      _SurveillanceDrivingFloatingBodyState();
}

class _SurveillanceDrivingFloatingBodyState
    extends State<_SurveillanceDrivingFloatingBody> {
  static const List<Shadow> _floatingTextShadows = [
    Shadow(color: Colors.black, blurRadius: 4),
  ];

  String _monitoringMode = 'AUTO';
  int _stopDelayIndex = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _monitoringMode = prefs.getString('monitoring_mode') ?? 'AUTO';
      _stopDelayIndex = prefs.getInt('stop_delay_index') ?? 1;
    });
  }

  Future<void> _save(Future<void> Function(SharedPreferences) action) async {
    final prefs = await SharedPreferences.getInstance();
    await action(prefs);
  }

  TextStyle _floatingStyle(TextStyle base, {Color? color, FontWeight? weight}) {
    return base.copyWith(
      color: color ?? MabColors.blanc,
      shadows: _floatingTextShadows,
      fontWeight: weight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🚗 Surveillance',
          style: _floatingStyle(MabTextStyles.titreCard, weight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Mode de démarrage',
            style: _floatingStyle(MabTextStyles.label),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _FloatingModeChoice(
                label: 'AUTO',
                sublabel: 'Démarre seul',
                selected: _monitoringMode == 'AUTO',
                shadows: _floatingTextShadows,
                onTap: () async {
                  setState(() => _monitoringMode = 'AUTO');
                  await _save((p) async => p.setString('monitoring_mode', 'AUTO'));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FloatingModeChoice(
                label: 'MANUEL',
                sublabel: 'Vous décidez',
                selected: _monitoringMode == 'MANUEL',
                shadows: _floatingTextShadows,
                onTap: () async {
                  setState(() => _monitoringMode = 'MANUEL');
                  await _save((p) async => p.setString('monitoring_mode', 'MANUEL'));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Arrêt automatique si pas de signal OBD',
            style: _floatingStyle(MabTextStyles.label),
          ),
        ),
        for (final (index, label) in [
          (0, '30 secondes'),
          (1, '60 secondes'),
          (2, '2 minutes'),
        ])
          RadioListTile<int>(
            value: index,
            groupValue: _stopDelayIndex,
            dense: true,
            tileColor: Colors.transparent,
            activeColor: MabColors.rouge,
            contentPadding: EdgeInsets.zero,
            title: Text(
              label,
              style: MabTextStyles.corpsNormal.copyWith(
                color: MabColors.blanc,
                shadows: _floatingTextShadows,
              ),
            ),
            onChanged: (v) async {
              setState(() => _stopDelayIndex = v!);
              await _save((p) async => p.setInt('stop_delay_index', v!));
            },
          ),
      ],
    );
  }
}

class _FloatingModeChoice extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool selected;
  final List<Shadow> shadows;
  final VoidCallback onTap;

  const _FloatingModeChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.shadows,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: MabTextStyles.corpsMedium.copyWith(
                  color: selected ? MabColors.rougeClair : MabColors.blanc,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  shadows: shadows,
                ),
              ),
              if (sublabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  sublabel!,
                  textAlign: TextAlign.center,
                  style: MabTextStyles.label.copyWith(
                    color: selected
                        ? MabColors.blanc.withValues(alpha: 0.9)
                        : MabColors.grisTexte,
                    fontSize: 11,
                    shadows: shadows,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
