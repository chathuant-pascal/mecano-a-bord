// Onglet Boîte à gants — Santé de ma voiture (messages humains d’abord, détails techniques repliables).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/services/live_monitoring_service.dart';
import 'package:mecano_a_bord/services/vehicle_health_service.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';

/// Contenu de l’onglet « Santé de ma voiture ».
class GloveboxVehicleHealthTab extends StatefulWidget {
  const GloveboxVehicleHealthTab({super.key, required this.repository});

  final MabRepository repository;

  @override
  State<GloveboxVehicleHealthTab> createState() =>
      _GloveboxVehicleHealthTabState();
}

class _GloveboxVehicleHealthTabState extends State<GloveboxVehicleHealthTab> {
  bool _loading = true;
  List<VehicleHealthAlertItem> _alerts = [];
  String? _referenceJson;
  bool _demo = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final demo = await widget.repository.isDemoMode();
    final profile = await widget.repository.getVehicleProfile();
    final vid = profile != null ? int.tryParse(profile.id) : null;

    List<VehicleHealthAlertItem> alerts = [];
    String? refJson;

    if (!demo && vid != null && vid > 0) {
      alerts = await widget.repository.listVehicleHealthAlerts(vid);
      refJson = await widget.repository.getVehicleReferenceJson(vid);
    }

    if (mounted) {
      setState(() {
        _demo = demo;
        _alerts = alerts;
        _referenceJson = refJson;
        _loading = false;
      });
    }
  }

  List<String> _monitoredLabels() {
    final labels = <String>[];
    if (_referenceJson != null && _referenceJson!.trim().isNotEmpty) {
      try {
        final m = jsonDecode(_referenceJson!) as Map<String, dynamic>;
        if (m.containsKey('temperature_normale_min')) {
          labels.add('Température moteur (eau)');
        }
        if (m.containsKey('tension_batterie_min')) {
          labels.add('Tension batterie');
        }
        if (m.containsKey('regime_ralenti_min')) {
          labels.add('Régime au ralenti');
        }
        if (m.containsKey('temperature_huile_min')) {
          labels.add('Température huile');
        }
      } catch (_) {}
    }
    if (labels.isEmpty) {
      return [
        'Température moteur (eau)',
        'Tension batterie',
        'Régime au ralenti',
      ];
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(MabDimensions.espacementXL),
          child: CircularProgressIndicator(color: MabColors.rouge),
        ),
      );
    }

    if (_demo) {
      return _buildBody(
        child: Text(
          'En mode démo, la santé véhicule utilise des données simulées. '
          'Désactive le mode démo pour voir ton historique réel après conduite.',
          style: MabTextStyles.corpsSecondaire.copyWith(color: MabColors.grisTexte),
        ),
      );
    }

    final last = _alerts.isNotEmpty ? _alerts.first : null;
    final gaugesLevel = last?.level ?? 0;

    return RefreshIndicator(
      color: MabColors.rouge,
      onRefresh: _load,
      child: _buildBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Vue d’ensemble',
                    style: MabTextStyles.titreCard,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: vehicleWarmupPhaseActiveNotifier,
                  builder: (context, warmup, _) {
                    if (!warmup) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(left: MabDimensions.espacementS),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MabDimensions.espacementS,
                          vertical: MabDimensions.espacementXS,
                        ),
                        decoration: BoxDecoration(
                          color: MabColors.etatInfo.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(MabDimensions.rayonPetit),
                          border: Border.all(color: MabColors.etatInfo),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🔵',
                              style: MabTextStyles.label.copyWith(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Chauffe en cours',
                              style: MabTextStyles.label.copyWith(
                                color: MabColors.etatInfo,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: MabDimensions.espacementS),
            Text(
              'Les jauges indiquent l’état global récent (pas les chiffres bruts). '
              'Pendant la conduite avec la surveillance active, Mécano à Bord suit ce qui est disponible sur ta prise OBD.',
              style: MabTextStyles.corpsSecondaire,
            ),
            SizedBox(height: MabDimensions.espacementM),
            Row(
              children: [
                Expanded(
                  child: _GaugeBar(
                    label: 'Confort',
                    color: MabColors.diagnosticVert,
                    emphasized: gaugesLevel == 0,
                  ),
                ),
                SizedBox(width: MabDimensions.espacementS),
                Expanded(
                  child: _GaugeBar(
                    label: 'Surveillance',
                    color: MabColors.diagnosticOrange,
                    emphasized: gaugesLevel == 1,
                  ),
                ),
                SizedBox(width: MabDimensions.espacementS),
                Expanded(
                  child: _GaugeBar(
                    label: 'Action',
                    color: MabColors.diagnosticRouge,
                    emphasized: gaugesLevel >= 2,
                  ),
                ),
              ],
            ),
            SizedBox(height: MabDimensions.espacementM),
            Text(
              'Dernier bilan',
              style: MabTextStyles.titreCard,
            ),
            SizedBox(height: MabDimensions.espacementS),
            if (last != null)
              Text(
                '${last.createdAt.day.toString().padLeft(2, '0')}/'
                '${last.createdAt.month.toString().padLeft(2, '0')}/'
                '${last.createdAt.year} — '
                '${last.createdAt.hour.toString().padLeft(2, '0')}:'
                '${last.createdAt.minute.toString().padLeft(2, '0')}\n'
                '${last.message}',
                style: MabTextStyles.corpsNormal,
              )
            else
              Text(
                'Aucun bilan enregistré pour l’instant. Lance la surveillance '
                'depuis l’écran OBD en mode conduite pour commencer.',
                style: MabTextStyles.corpsSecondaire,
              ),
            SizedBox(height: MabDimensions.espacementL),
            Text(
              'Paramètres suivis pour ta voiture',
              style: MabTextStyles.titreCard,
            ),
            SizedBox(height: MabDimensions.espacementS),
            Text(
              'Pour ta voiture, je m’appuie sur ce qui est disponible : '
              '${_monitoredLabels().join(', ')}.',
              style: MabTextStyles.corpsNormal,
            ),
            SizedBox(height: MabDimensions.espacementM),
            ValueListenableBuilder<LiveMonitoringBanner?>(
              valueListenable: liveMonitoringBannerNotifier,
              builder: (context, banner, _) {
                if (banner == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: MabDimensions.espacementM),
                  child: Container(
                    padding: MabDimensions.paddingCard,
                    decoration: BoxDecoration(
                      color: MabColors.noirMoyen,
                      borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
                      border: Border.all(
                        color: banner.isCritical
                            ? MabColors.diagnosticRouge
                            : MabColors.diagnosticOrange,
                      ),
                    ),
                    child: Text(
                      'Sur la route : ${banner.message}',
                      style: MabTextStyles.corpsNormal,
                    ),
                  ),
                );
              },
            ),
            Text(
              'Historique des messages',
              style: MabTextStyles.titreCard,
            ),
            SizedBox(height: MabDimensions.espacementS),
            if (_alerts.isEmpty)
              Text(
                'Rien à signaler dans l’historique.',
                style: MabTextStyles.corpsSecondaire,
              )
            else
              ..._alerts.map((a) => _AlertTile(alert: a)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({required Widget child}) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: MabDimensions.paddingEcran,
      child: child,
    );
  }
}

class _GaugeBar extends StatelessWidget {
  const _GaugeBar({
    required this.label,
    required this.color,
    required this.emphasized,
  });

  final String label;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: MabDimensions.zoneTactileMin,
          decoration: BoxDecoration(
            color: color.withOpacity(emphasized ? 0.45 : 0.2),
            borderRadius: BorderRadius.circular(MabDimensions.rayonPetit),
            border: Border.all(
              color: color,
              width: emphasized ? 2 : 1,
            ),
          ),
        ),
        SizedBox(height: MabDimensions.espacementXS),
        Text(
          label,
          textAlign: TextAlign.center,
          style: MabTextStyles.label.copyWith(
            color: emphasized ? MabColors.blanc : MabColors.grisTexte,
          ),
        ),
      ],
    );
  }
}

class _AlertTile extends StatefulWidget {
  const _AlertTile({required this.alert});

  final VehicleHealthAlertItem alert;

  @override
  State<_AlertTile> createState() => _AlertTileState();
}

class _AlertTileState extends State<_AlertTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    return Card(
      color: MabColors.noirMoyen,
      margin: const EdgeInsets.only(bottom: MabDimensions.espacementM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
      ),
      child: ExpansionTile(
        tilePadding: MabDimensions.paddingCard,
        childrenPadding: const EdgeInsets.fromLTRB(
          MabDimensions.espacementM,
          0,
          MabDimensions.espacementM,
          MabDimensions.espacementM,
        ),
        title: Text(
          a.message,
          style: MabTextStyles.corpsNormal,
        ),
        subtitle: Text(
          '${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year} '
          '— ${_labelForLevel(a.level)}',
          style: MabTextStyles.corpsSecondaire,
        ),
        trailing: Icon(
          _open ? Icons.expand_less : Icons.expand_more,
          color: MabColors.grisTexte,
        ),
        onExpansionChanged: (v) => setState(() => _open = v),
        children: [
          if (a.technicalDetail != null && a.technicalDetail!.trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Détails techniques : ${a.technicalDetail}',
                style: MabTextStyles.corpsSecondaire.copyWith(
                  color: MabColors.grisTexte,
                ),
              ),
            )
          else
            Text(
              'Pas de détail technique enregistré pour ce message.',
              style: MabTextStyles.corpsSecondaire,
            ),
        ],
      ),
    );
  }

  String _labelForLevel(int level) {
    if (level >= 2) return 'Action';
    if (level == 1) return 'Surveillance';
    return 'Confort';
  }
}
