// Ouvre l’URL de formation (navigateur externe) puis revient à l’écran précédent.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mecano_a_bord/formation_url.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';

class FormationWebLaunchScreen extends StatefulWidget {
  const FormationWebLaunchScreen({super.key});

  @override
  State<FormationWebLaunchScreen> createState() =>
      _FormationWebLaunchScreenState();
}

class _FormationWebLaunchScreenState extends State<FormationWebLaunchScreen> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openFormationUrl());
  }

  Future<void> _openFormationUrl() async {
    if (_opened) return;
    _opened = true;
    final uri = Uri.parse(kFormationUrl);
    var launched = false;
    try {
      // Ne pas se fier seul à canLaunchUrl (souvent false sur Android 11+ sans <queries>).
      launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e, st) {
      debugPrint('Formation launchUrl: $e\n$st');
    }
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ouverture du navigateur impossible. Réessaie ou vérifie ta connexion.',
          ),
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabColors.noir,
      appBar: AppBar(
        backgroundColor: MabColors.noir,
        title: const Text(
          'La méthode sans stress auto',
          style: MabTextStyles.titreSection,
        ),
      ),
      body: Center(
        child: Padding(
          padding: MabDimensions.paddingEcran,
          child: Text(
            'Ouverture de la formation dans ton navigateur…',
            style: MabTextStyles.corpsSecondaire,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
