// mab_obd_not_responding_dialog.dart — Dialogue commun OBD (liste vide / échec connexion).

import 'package:flutter/material.dart';
import 'package:mecano_a_bord/theme/mab_theme.dart';

const String kMabObdNotRespondingMessage =
    'Votre boîtier OBD ne répond pas. Vérifiez qu\'il est bien branché sur la prise OBD de votre véhicule, qu\'il est appairé en Bluetooth dans les réglages de votre téléphone, et que votre contact est mis. Une fois ces vérifications faites, appuyez sur Relancer le diagnostic.';

/// Affiche le dialogue demandé avec [onRelancer] et [onAnnuler].
Future<void> showMabObdNotRespondingDialog(
  BuildContext context, {
  required VoidCallback onRelancer,
  required VoidCallback onAnnuler,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MabDimensions.rayonGrand),
      ),
      title: const Text('Diagnostic OBD'),
      content: const SingleChildScrollView(
        child: Text(kMabObdNotRespondingMessage),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onAnnuler();
          },
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            onRelancer();
          },
          child: const Text('Relancer le diagnostic'),
        ),
      ],
    ),
  );
}
