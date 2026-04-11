// placeholder_screen.dart — Mécano à Bord
// Écran de remplacement pour OBD, Boîte à gants, IA, Réglages (avant implémentation complète).

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/widgets/mab_watermark_background.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        title: Text(title),
      ),
      body: MabWatermarkBackground(
        child: Padding(
          padding: MabDimensions.paddingEcran,
          child: Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: MabTextStyles.titreSection,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MabDimensions.espacementL),
              Text(
                'Cette section sera disponible prochainement.',
                style: MabTextStyles.corpsSecondaire,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MabDimensions.espacementXL),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour'),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
