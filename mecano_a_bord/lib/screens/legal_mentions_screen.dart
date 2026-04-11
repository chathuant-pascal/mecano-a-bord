// legal_mentions_screen.dart — Mécano à Bord
// Mentions légales & CGU (écran dédié, même gabarit que la politique de confidentialité).

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/widgets/mab_legal_mentions_body.dart';
import 'package:mecano_a_bord/widgets/mab_watermark_background.dart';

class LegalMentionsScreen extends StatelessWidget {
  const LegalMentionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        backgroundColor: MabColors.noir,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: MabColors.blanc),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mentions légales & CGU',
          style: MabTextStyles.titreSection,
        ),
      ),
      body: MabWatermarkBackground(
        child: SingleChildScrollView(
          padding: MabDimensions.paddingEcran,
          child: const MabLegalMentionsSettingsSection(),
        ),
      ),
    );
  }
}
