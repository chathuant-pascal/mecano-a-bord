// privacy_policy_screen.dart — Mécano à Bord
// Écran intégré affichant la politique de confidentialité.

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';
import 'package:mecano_a_bord/widgets/mab_watermark_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Politique de confidentialité',
          style: MabTextStyles.titreSection,
        ),
      ),
      body: MabWatermarkBackground(
        child: SingleChildScrollView(
          padding: MabDimensions.paddingEcran,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/legal-mentions');
                },
                child: Text(
                  'Voir aussi : Mentions légales complètes →',
                  style: MabTextStyles.label.copyWith(color: MabColors.grisDore),
                ),
              ),
              const SizedBox(height: MabDimensions.espacementM),
              Text(
                'POLITIQUE DE CONFIDENTIALITÉ — MECANO À BORD',
                style: MabTextStyles.titrePrincipal.copyWith(fontSize: 20),
              ),
              const SizedBox(height: MabDimensions.espacementS),
              Text(
                'Dernière mise à jour : 15 mars 2026',
                style: MabTextStyles.corpsSecondaire,
              ),
              const SizedBox(height: MabDimensions.espacementXL),

              _Section(
                title: '1. Présentation',
                body:
                    'Mecano à Bord est une application mobile développée par Pascal Chathuant. '
                    'Cette politique explique quelles données sont collectées, comment elles sont utilisées '
                    'et vos droits en tant qu\'utilisateur.',
              ),
              _Section(
                title: '2. Données collectées',
                body: '• Profil véhicule (marque, modèle, année, kilométrage, numéro VIN)\n'
                    '• Documents ajoutés dans la boîte à gants (photos, PDF)\n'
                    '• Carnet d\'entretien\n'
                    '• Clé API personnelle (si renseignée)\n'
                    '• Données OBD lues depuis le véhicule\n'
                    '• Préférences et réglages',
              ),
              _Section(
                title: '3. Stockage des données',
                body: 'Toutes vos données sont stockées uniquement sur votre téléphone. '
                    'Aucune donnée personnelle n\'est envoyée sur nos serveurs.',
              ),
              _Section(
                title: '4. Données partagées avec des tiers',
                body: 'Si vous utilisez votre propre clé API (ChatGPT, Claude, Gemini, etc.), '
                    'vos questions sont envoyées directement au service IA concerné selon leur propre politique de confidentialité. '
                    'Aucune donnée n\'est vendue ni partagée à des fins publicitaires.',
              ),
              _Section(
                title: '5. Permissions Android utilisées',
                body: '• Bluetooth (connexion au dongle OBD)\n'
                    '• Localisation (requise par Android pour le scan Bluetooth)\n'
                    '• Caméra (prise de photo des documents)\n'
                    '• Stockage (sauvegarde des documents)',
              ),
              _Section(
                title: '6. Sécurité',
                body: 'La base de données locale est chiffrée. Votre clé API est stockée de manière chiffrée '
                    'sur votre appareil. Aucune transmission de données sans votre action explicite.',
              ),
              _Section(
                title: '7. Droits des utilisateurs RGPD',
                body: '• Droit d\'accès\n'
                    '• Droit de rectification\n'
                    '• Droit à l\'effacement en désinstallant l\'application\n'
                    '• Droit d\'opposition via les réglages Android',
              ),
              _Section(
                title: '8. Données des mineurs',
                body: 'Mecano à Bord n\'est pas destinée aux enfants de moins de 16 ans.',
              ),
              _Section(
                title: '9. Modifications',
                body: 'Cette politique peut être mise à jour. La date est indiquée en haut du document.',
              ),
              _Section(
                title: '10. Contact',
                body: 'contact@mecanoabord.fr — France.',
              ),
              const SizedBox(height: MabDimensions.espacementXXL),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MabDimensions.espacementL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: MabTextStyles.titreCard),
          const SizedBox(height: MabDimensions.espacementS),
          Text(
            body,
            style: MabTextStyles.corpsNormal.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
