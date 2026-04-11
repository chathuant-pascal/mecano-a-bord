// Dialogues de blocage croisé diagnostic ↔ surveillance (textes validés produit).

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';

/// Message 1 — Mode Conduite : tentative de diagnostic alors que la surveillance est active.
Future<void> showMabSurveillanceBlocksDiagnosticDialog(
  BuildContext context, {
  required VoidCallback onStopSurveillance,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: MabColors.noirMoyen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
      ),
      title: Text(
        'Surveillance en cours',
        style: MabTextStyles.titreCard.copyWith(color: MabColors.blanc),
      ),
      content: Text(
        'La surveillance vous accompagne tant que vous roulez.\n\n'
        'Le diagnostic complet utilise la même liaison avec la voiture : on ne peut pas faire les deux à la fois.\n\n'
        'Arrêtez la surveillance pour pouvoir lancer un diagnostic.',
        style: MabTextStyles.corpsNormal.copyWith(color: MabColors.grisTexte),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: MabColors.rouge,
            foregroundColor: MabColors.blanc,
            minimumSize: const Size(0, MabDimensions.boutonHauteur),
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
            onStopSurveillance();
          },
          child: Text(
            'Arrêter la surveillance',
            style: MabTextStyles.boutonPrincipal.copyWith(color: MabColors.blanc),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'Annuler',
            style: MabTextStyles.boutonSecondaire.copyWith(color: MabColors.grisTexte),
          ),
        ),
      ],
    ),
  );
}

/// Message 2 — Écran OBD : diagnostic alors que la surveillance Mode conduite est active.
Future<void> showMabDiagnosticBlockedBySurveillanceDialog(
  BuildContext context, {
  required VoidCallback onGoToModeConduite,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: MabColors.noirMoyen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
      ),
      title: Text(
        'Surveillance en cours',
        style: MabTextStyles.titreCard.copyWith(color: MabColors.blanc),
      ),
      content: Text(
        'La surveillance du Mode conduite est encore en marche.\n\n'
        'Elle utilise la même liaison que le diagnostic complet : une seule chose à la fois.\n\n'
        'Ouvrez le Mode conduite, arrêtez la surveillance, puis revenez ici pour lancer le diagnostic.',
        style: MabTextStyles.corpsNormal.copyWith(color: MabColors.grisTexte),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: MabColors.rouge,
            foregroundColor: MabColors.blanc,
            minimumSize: const Size(0, MabDimensions.boutonHauteur),
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
            onGoToModeConduite();
          },
          child: Text(
            'Aller au Mode conduite',
            style: MabTextStyles.boutonPrincipal.copyWith(color: MabColors.blanc),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'Annuler',
            style: MabTextStyles.boutonSecondaire.copyWith(color: MabColors.grisTexte),
          ),
        ),
      ],
    ),
  );
}

/// Message 3 — Mode Conduite : démarrage surveillance alors qu'un diagnostic est en cours.
Future<void> showMabSurveillanceBlockedByDiagnosticDialog(
  BuildContext context,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: MabColors.noirMoyen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
      ),
      title: Text(
        'Diagnostic en cours',
        style: MabTextStyles.titreCard.copyWith(color: MabColors.blanc),
      ),
      content: Text(
        'Un diagnostic complet lit les informations de votre véhicule.\n\n'
        'Attendez qu\'il soit terminé avant de démarrer la surveillance.\n\n'
        'Ensuite, vous pourrez l\'activer comme d\'habitude.',
        style: MabTextStyles.corpsNormal.copyWith(color: MabColors.grisTexte),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'J\'attends',
            style: MabTextStyles.boutonSecondaire.copyWith(color: MabColors.grisTexte),
          ),
        ),
      ],
    ),
  );
}

/// Confirmation avant effacement des codes défaut OBD (mode 04).
Future<bool> showMabClearDtcConfirmDialog(BuildContext context) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: MabColors.noirMoyen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
      ),
      title: Text(
        'Effacer les codes défaut ?',
        style: MabTextStyles.titreCard.copyWith(color: MabColors.blanc),
      ),
      content: Text(
        'Cette action va effacer tous les codes défaut détectés et éteindre le témoin Check Engine.\n\n'
        'À faire uniquement si la réparation a déjà été effectuée par un professionnel.\n\n'
        'Si le problème n\'est pas réparé, les codes reviendront au prochain démarrage.',
        style: MabTextStyles.corpsNormal.copyWith(color: MabColors.grisTexte),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: MabColors.rouge,
            foregroundColor: MabColors.blanc,
            minimumSize: const Size(0, MabDimensions.boutonHauteur),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            'Effacer les codes',
            style: MabTextStyles.boutonPrincipal.copyWith(color: MabColors.blanc),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Annuler',
            style: MabTextStyles.boutonSecondaire.copyWith(color: MabColors.grisTexte),
          ),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Après effacement réussi des codes OBD : rappels pédagogiques (codes permanents, voyant, cycle).
Future<void> showMabDtcClearSuccessInfoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: MabColors.noirMoyen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
      ),
      title: Text(
        'Effacement effectué',
        style: MabTextStyles.titreCard.copyWith(color: MabColors.blanc),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DtcClearInfoRow(
              icon: Icons.check_circle_rounded,
              iconColor: MabColors.diagnosticVert,
              text:
                  'Les codes mémorisés et en attente ont été effacés',
            ),
            const SizedBox(height: MabDimensions.espacementM),
            _DtcClearInfoRow(
              icon: Icons.warning_amber_rounded,
              iconColor: MabColors.diagnosticOrange,
              text:
                  'Les codes permanents ne peuvent pas être effacés manuellement. '
                  'C\'est une protection du véhicule, pas un problème de l\'application.',
            ),
            const SizedBox(height: MabDimensions.espacementM),
            _DtcClearInfoRow(
              icon: Icons.sync_rounded,
              iconColor: MabColors.grisDore,
              text:
                  'Si le voyant Check Engine se rallume après le démarrage, '
                  'le problème mécanique existe toujours. Il faut le faire réparer.',
            ),
            const SizedBox(height: MabDimensions.espacementM),
            _DtcClearInfoRow(
              icon: Icons.directions_car_rounded,
              iconColor: MabColors.grisDore,
              text:
                  'Parcourez 50 à 100 km en conditions variées pour que '
                  'le calculateur valide que tout est rentré dans l\'ordre.',
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: MabColors.rouge,
            foregroundColor: MabColors.blanc,
            minimumSize: const Size(0, MabDimensions.boutonHauteur),
          ),
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'J\'ai compris',
            style: MabTextStyles.boutonPrincipal.copyWith(color: MabColors.blanc),
          ),
        ),
      ],
    ),
  );
}

class _DtcClearInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _DtcClearInfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: MabDimensions.iconeM),
        const SizedBox(width: MabDimensions.espacementM),
        Expanded(
          child: Text(
            text,
            style: MabTextStyles.corpsNormal.copyWith(
              color: MabColors.blanc,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
