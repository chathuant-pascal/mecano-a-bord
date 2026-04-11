// surveillance_settings_body.dart — Section Surveillance (mode conduite) réutilisable.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';

/// Corps de la section Surveillance : préférences chargées / sauvegardées localement.
class SurveillanceSettingsBody extends StatefulWidget {
  const SurveillanceSettingsBody({super.key});

  @override
  State<SurveillanceSettingsBody> createState() => _SurveillanceSettingsBodyState();
}

class _SurveillanceSettingsBodyState extends State<SurveillanceSettingsBody> {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: MabDimensions.paddingCard,
      decoration: BoxDecoration(
        color: MabColors.noirMoyen,
        borderRadius: BorderRadius.circular(MabDimensions.rayonCard),
        border: Border.all(color: MabColors.grisContour),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🚗 Surveillance', style: MabTextStyles.titreCard),
          const SizedBox(height: 16),
          _SurveillanceSettingsLabel('Mode de démarrage'),
          Row(
            children: [
              Expanded(
                child: _SurveillanceChoiceChip(
                  label: 'AUTO',
                  sublabel: 'Démarre seul',
                  selected: _monitoringMode == 'AUTO',
                  onTap: () async {
                    setState(() => _monitoringMode = 'AUTO');
                    await _save((p) async => p.setString('monitoring_mode', 'AUTO'));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SurveillanceChoiceChip(
                  label: 'MANUEL',
                  sublabel: 'Vous décidez',
                  selected: _monitoringMode == 'MANUEL',
                  onTap: () async {
                    setState(() => _monitoringMode = 'MANUEL');
                    await _save((p) async => p.setString('monitoring_mode', 'MANUEL'));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SurveillanceSettingsLabel('Arrêt automatique si pas de signal OBD'),
          for (final (index, label) in [
            (0, '30 secondes'),
            (1, '60 secondes'),
            (2, '2 minutes'),
          ])
            RadioListTile<int>(
              value: index,
              groupValue: _stopDelayIndex,
              title: Text(label, style: MabTextStyles.corpsNormal),
              dense: true,
              activeColor: MabColors.rouge,
              onChanged: (v) async {
                setState(() => _stopDelayIndex = v!);
                await _save((p) async => p.setInt('stop_delay_index', v!));
              },
            ),
        ],
      ),
    );
  }
}

class _SurveillanceSettingsLabel extends StatelessWidget {
  final String text;
  const _SurveillanceSettingsLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: MabTextStyles.label),
    );
  }
}

class _SurveillanceChoiceChip extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _SurveillanceChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? MabColors.rouge : MabColors.noirClair,
          borderRadius: BorderRadius.circular(MabDimensions.rayonMoyen),
          border: Border.all(
            color: selected ? MabColors.rouge : MabColors.grisContour,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: MabTextStyles.corpsMedium.copyWith(
                color: selected ? MabColors.blanc : MabColors.blanc,
              ),
            ),
            if (sublabel != null)
              Text(
                sublabel!,
                style: MabTextStyles.label.copyWith(
                  color: selected
                      ? MabColors.blanc.withOpacity(0.85)
                      : MabColors.grisTexte,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
