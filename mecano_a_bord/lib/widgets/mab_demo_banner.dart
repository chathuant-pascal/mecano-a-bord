// mab_demo_banner.dart — Mécano à Bord
// Bannière visible en mode démo + bouton « Quitter le mode démo ».

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/data/mab_repository.dart';
import 'package:mecano_a_bord/screens/home_screen.dart';

class MabDemoBanner extends StatelessWidget {
  const MabDemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: MabDimensions.espacementS,
        horizontal: MabDimensions.espacementM,
      ),
      color: MabColors.diagnosticRouge,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.science_outlined, color: MabColors.blanc, size: 20),
            ),
            const SizedBox(width: MabDimensions.espacementS),
            Text(
              'MODE DÉMO',
              style: MabTextStyles.badge.copyWith(
                color: MabColors.blanc,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _quitDemo(context),
              style: TextButton.styleFrom(
                foregroundColor: MabColors.blanc,
                padding: const EdgeInsets.symmetric(horizontal: MabDimensions.espacementS),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Quitter le mode démo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quitDemo(BuildContext context) async {
    await MabRepository.instance.setDemoMode(false);
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}
