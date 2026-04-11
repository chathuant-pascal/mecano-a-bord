// mab_legal_mentions_body.dart — Mentions légales & CGU (Réglages).

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';

/// Bloc Réglages : titre principal + 9 sections (titres [MabColors.rouge], corps blanc).
class MabLegalMentionsSettingsSection extends StatelessWidget {
  const MabLegalMentionsSettingsSection({super.key});

  static Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: MabDimensions.espacementM),
        child: Divider(
          height: 1,
          color: MabColors.grisContour.withOpacity(0.6),
        ),
      );

  static Widget _block(String title, String body) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: MabTextStyles.titreCard.copyWith(color: MabColors.rouge),
          ),
          const SizedBox(height: MabDimensions.espacementS),
          Text(
            body,
            style: MabTextStyles.corpsNormal.copyWith(
              color: MabColors.blanc,
              height: 1.45,
            ),
          ),
        ],
      );

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
          Text(
            'Mentions légales & Conditions d\'utilisation',
            style: MabTextStyles.titreCard,
          ),
          const SizedBox(height: MabDimensions.espacementM),
          _block(
            'Éditeur',
            'Application Mécano à Bord\n'
            'Éditeur : Pascal Chathuant\n'
            'Adresse : Guadeloupe (971), France\n'
            'Contact : contact@mecanoabord.fr\n'
            'Site web : mecanoabord.systeme.io\n'
            '[SIRET : à compléter avant mise en vente]',
          ),
          _divider(),
          _block(
            'Hébergement',
            'L\'application est distribuée via Google Play Store.\n'
            'Hébergeur : Google LLC\n'
            '1600 Amphitheatre Parkway\n'
            'Mountain View, CA 94043, États-Unis',
          ),
          _divider(),
          _block(
            'Objet et limites de l\'application',
            'Mécano à Bord est une application d\'aide '
            'et d\'accompagnement à la conduite automobile.\n'
            'Elle fournit des informations éducatives, '
            'des diagnostics indicatifs via la norme OBD-II '
            'et des alertes de surveillance à titre informatif.\n\n'
            'Elle ne constitue pas un outil de diagnostic '
            'professionnel homologué et ne remplace en aucun '
            'cas l\'intervention d\'un mécanicien qualifié.',
          ),
          _divider(),
          _block(
            'Limitation de responsabilité',
            'Conformément aux articles 1240 et suivants '
            'du Code civil français, et dans les limites '
            'autorisées par la loi :\n\n'
            'L\'éditeur de Mécano à Bord ne saurait être tenu '
            'responsable :\n\n'
            '- Des dommages directs ou indirects résultant '
            'd\'un défaut d\'entretien du véhicule de l\'utilisateur.\n\n'
            '- Des dommages résultant d\'une mauvaise '
            'interprétation des informations, alertes '
            'ou diagnostics fournis par l\'application.\n\n'
            '- Des conséquences d\'une utilisation de '
            'l\'application contraire aux présentes conditions '
            'ou aux règles du Code de la route.\n\n'
            '- Des aléas mécaniques, accidents ou dommages mécaniques '
            'survenus avant, pendant ou après l\'utilisation '
            'de l\'application.\n\n'
            '- Du mauvais fonctionnement ou de l\'incompatibilité '
            'd\'un dongle OBD tiers avec le véhicule '
            'de l\'utilisateur.\n\n'
            '- Des informations fournies par les assistants '
            'IA tiers intégrés à l\'application, ces derniers '
            'étant des services indépendants soumis '
            'aux conditions de leurs éditeurs respectifs.\n\n'
            'Les alertes et informations fournies par '
            'l\'application sont de nature indicative uniquement.\n'
            'L\'utilisateur reste seul responsable de ses '
            'décisions de conduite et d\'entretien.',
          ),
          _divider(),
          _block(
            'Conditions d\'utilisation',
            'En installant et utilisant Mécano à Bord, '
            'l\'utilisateur reconnaît et accepte :\n\n'
            '- Avoir lu et compris les présentes conditions.\n\n'
            '- Que l\'application est un outil d\'aide '
            'et non un système de sécurité homologué.\n\n'
            '- Rester attentif à sa conduite en toutes '
            'circonstances, indépendamment des alertes '
            'de l\'application.\n\n'
            '- Ne pas utiliser l\'application d\'une façon '
            'qui détourne son attention de la route.\n\n'
            '- Effectuer l\'entretien de son véhicule '
            'conformément aux recommandations du constructeur, '
            'indépendamment des rappels de l\'application.\n\n'
            '- Que l\'application ne garantit pas l\'exhaustivité '
            'ni la précision des données OBD lues, '
            'celles-ci dépendant du véhicule et du dongle '
            'utilisés.',
          ),
          _divider(),
          _block(
            'Propriété intellectuelle',
            'L\'ensemble des contenus de l\'application '
            'Mécano à Bord (textes, graphiques, logos, '
            'icônes, code source) est protégé par '
            'le droit d\'auteur conformément aux articles '
            'L111-1 et suivants du Code de la propriété '
            'intellectuelle.\n\n'
            'Toute reproduction, distribution ou utilisation '
            'sans autorisation écrite préalable de l\'éditeur '
            'est strictement interdite.',
          ),
          _divider(),
          _block(
            'Données personnelles',
            'Le traitement des données personnelles '
            'est décrit dans notre Politique de '
            'confidentialité accessible dans l\'application.\n\n'
            'Conformément au Règlement Général sur la '
            'Protection des Données (RGPD - Règlement UE '
            '2016/679) et à la loi Informatique et Libertés '
            'du 6 janvier 1978 modifiée, vous disposez '
            'd\'un droit d\'accès, de rectification et '
            'de suppression de vos données.',
          ),
          _divider(),
          _block(
            'Droit applicable et litiges',
            'Les présentes conditions sont régies '
            'par le droit français.\n\n'
            'En cas de litige, une solution amiable '
            'sera recherchée en priorité via :\n'
            'contact@mecanoabord.fr\n\n'
            'À défaut d\'accord amiable, les tribunaux '
            'français compétents seront seuls habilités '
            'à connaître du litige.',
          ),
          _divider(),
          _block(
            'Mise à jour des conditions',
            'Ces mentions légales et conditions '
            'd\'utilisation peuvent être mises à jour '
            'à tout moment.\n'
            'Version en vigueur : Mars 2026\n'
            'Éditeur : Pascal Chathuant — Mécano à Bord',
          ),
        ],
      ),
    );
  }
}
