// advice_engine.dart
// Mécano à Bord — Version Flutter/Dart (Android + iOS)
//
// Ce fichier est le "cerveau" de l'application.
// Son rôle : prendre un code erreur OBD brut (ex: "P0171")
// et le transformer en un message humain, calme et compréhensible.

// ─────────────────────────────────────────────
// MODÈLES DE DONNÉES
// ─────────────────────────────────────────────

/// Les 4 niveaux d'urgence de l'application.
/// Chaque résultat de diagnostic appartient à l'un de ces niveaux.
enum UrgenceLevel {
  vert,           // Niveau 1 — Tout va bien, tu peux rouler
  orange,         // Niveau 2 — Surveille, prends RDV prochainement
  rouge,          // Niveau 3 — Arrête-toi dès que possible
  rougeCritique,  // Niveau 3+ — Ne redémarre pas
}

/// Un conseil complet produit par l'AdviceEngine.
/// C'est ce qui sera affiché à l'utilisateur et lu par le coach vocal.
class Advice {
  final String dtcCode;             // Le code brut, ex: "P0171"
  final UrgenceLevel urgenceLevel;  // Le niveau de gravité
  final String titre;               // Titre court et rassurant
  final String messageEcran;        // Texte affiché sur l'écran résultat
  final String messageVocal;        // Texte lu par le coach vocal (plus court)
  final String questionGaragiste;   // Ce que l'utilisateur peut dire à son garagiste
  final bool peutContinuerRouler;   // Résumé : peut-il rouler ou non ?

  const Advice({
    required this.dtcCode,
    required this.urgenceLevel,
    required this.titre,
    required this.messageEcran,
    required this.messageVocal,
    required this.questionGaragiste,
    required this.peutContinuerRouler,
  });
}

/// Résultat global d'un scan OBD (peut contenir plusieurs codes).
class ScanResult {
  final List<Advice> advices;
  final UrgenceLevel urgenceGlobale; // Le niveau le plus grave de la liste
  final String resumeGlobal;         // Un message résumant tout le scan

  const ScanResult({
    required this.advices,
    required this.urgenceGlobale,
    required this.resumeGlobal,
  });
}

/// Représente une entrée du catalogue DTC.
/// (Défini dans dtc_catalog.dart — rappel uniquement)
class DtcInfo {
  final String code;            // Ex: "P0171"
  final String descriptionFr;   // Ex: "Mélange air/essence trop pauvre (banc 1)"
  final int severity;           // De 0 (sans importance) à 10 (critique)

  const DtcInfo({
    required this.code,
    required this.descriptionFr,
    required this.severity,
  });
}

// ─────────────────────────────────────────────
// INTERFACE — Ce que l'AdviceEngine sait faire
// ─────────────────────────────────────────────

abstract class AdviceEngine {
  /// Traduit un seul code DTC en conseil humain.
  Advice analyzeCode(String dtcCode);

  /// Traduit une liste de codes DTC (résultat d'un scan complet).
  ScanResult analyzeScan(List<String> dtcCodes);

  /// Retourne un conseil "tout va bien" quand aucun code n'est détecté.
  Advice adviceAllClear();
}

// Interface du catalogue DTC (référence)
abstract class DtcCatalog {
  DtcInfo? findByCode(String code);
}

// ─────────────────────────────────────────────
// IMPLÉMENTATION
// ─────────────────────────────────────────────

class AdviceEngineImpl implements AdviceEngine {
  final DtcCatalog dtcCatalog;

  AdviceEngineImpl({required this.dtcCatalog});

  @override
  Advice analyzeCode(String dtcCode) {
    // 1. On cherche le code dans le catalogue
    final dtcInfo = dtcCatalog.findByCode(dtcCode);

    // 2. Si le code est inconnu, on donne un conseil générique rassurant
    if (dtcInfo == null) {
      return _buildAdviceInconnu(dtcCode);
    }

    // 3. On détermine le niveau d'urgence
    final urgence = _mapGraviteToUrgence(dtcInfo.severity);

    // 4. On construit le conseil complet
    return Advice(
      dtcCode: dtcCode,
      urgenceLevel: urgence,
      titre: _buildTitre(urgence),
      messageEcran: _buildMessageEcran(dtcInfo.descriptionFr, urgence),
      messageVocal: _buildMessageVocal(urgence),
      questionGaragiste: _buildQuestionGaragiste(dtcInfo.descriptionFr),
      peutContinuerRouler:
          urgence == UrgenceLevel.vert || urgence == UrgenceLevel.orange,
    );
  }

  @override
  ScanResult analyzeScan(List<String> dtcCodes) {
    // Cas spécial : aucun code détecté
    if (dtcCodes.isEmpty) {
      final allClear = adviceAllClear();
      return ScanResult(
        advices: [allClear],
        urgenceGlobale: UrgenceLevel.vert,
        resumeGlobal: 'Ton véhicule ne signale aucun problème. Bonne route !',
      );
    }

    // On analyse chaque code
    final advices = dtcCodes.map(analyzeCode).toList();

    // On retient le niveau le plus grave
    final urgenceGlobale = advices
        .map((a) => a.urgenceLevel)
        .reduce((a, b) => a.index > b.index ? a : b);

    // On construit le résumé global
    final resumeGlobal = _buildResumeGlobal(urgenceGlobale, advices.length);

    return ScanResult(
      advices: advices,
      urgenceGlobale: urgenceGlobale,
      resumeGlobal: resumeGlobal,
    );
  }

  @override
  Advice adviceAllClear() {
    return const Advice(
      dtcCode: 'AUCUN',
      urgenceLevel: UrgenceLevel.vert,
      titre: 'Tout va bien !',
      messageEcran:
          'Ton véhicule ne signale aucune anomalie. '
          'Tu peux continuer à rouler en toute tranquillité.',
      messageVocal:
          'Bonne nouvelle ! Ton véhicule fonctionne normalement.',
      questionGaragiste: '',
      peutContinuerRouler: true,
    );
  }

  // ─────────────────────────────────────────────
  // FONCTIONS INTERNES (privées)
  // ─────────────────────────────────────────────

  /// Convertit la gravité technique (0-10) en niveau d'urgence utilisateur.
  UrgenceLevel _mapGraviteToUrgence(int severity) {
    if (severity <= 2) return UrgenceLevel.vert;
    if (severity <= 5) return UrgenceLevel.orange;
    if (severity <= 8) return UrgenceLevel.rouge;
    return UrgenceLevel.rougeCritique;
  }

  /// Titre court selon le niveau d'urgence.
  String _buildTitre(UrgenceLevel urgence) {
    switch (urgence) {
      case UrgenceLevel.vert:
        return 'Tout va bien';
      case UrgenceLevel.orange:
        return 'Un point à surveiller';
      case UrgenceLevel.rouge:
        return 'Ton attention est nécessaire';
      case UrgenceLevel.rougeCritique:
        return 'Action immédiate requise';
    }
  }

  /// Message affiché sur l'écran résultat.
  /// RÈGLE : aucun mot de panique autorisé.
  String _buildMessageEcran(String descriptionFr, UrgenceLevel urgence) {
    final conseil = switch (urgence) {
      UrgenceLevel.vert =>
        'Ce n\'est pas urgent. Note-le pour ton prochain entretien si cela se répète.',
      UrgenceLevel.orange =>
        'Évite de rouler trop longtemps sans vérification. '
        'Prévois un rendez-vous chez un professionnel cette semaine.',
      UrgenceLevel.rouge =>
        'Il vaut mieux t\'arrêter dès que possible et contacter un professionnel. '
        'Ne continue pas à rouler sur une longue distance.',
      UrgenceLevel.rougeCritique =>
        'Par précaution, ne redémarre pas ton véhicule. '
        'Fais appel à un professionnel ou à une assistance routière.',
    };
    return '$descriptionFr\n\n$conseil';
  }

  /// Message vocal — plus court, conçu pour être lu à voix haute.
  String _buildMessageVocal(UrgenceLevel urgence) {
    return switch (urgence) {
      UrgenceLevel.vert =>
        'Ton véhicule fonctionne normalement. Bonne route !',
      UrgenceLevel.orange =>
        'Ton véhicule signale un point à surveiller. Ce n\'est pas urgent, '
        'mais prévois un contrôle prochainement.',
      UrgenceLevel.rouge =>
        'Ton véhicule a besoin d\'attention. Arrête-toi dès que tu peux '
        'et contacte un professionnel.',
      UrgenceLevel.rougeCritique =>
        'Par précaution, ne redémarre pas ton véhicule. '
        'Contacte un professionnel ou une assistance routière.',
    };
  }

  /// Formule une question simple que l'utilisateur peut poser à son garagiste.
  String _buildQuestionGaragiste(String descriptionFr) {
    return 'Tu peux dire à ton garagiste : '
        '"J\'ai un voyant qui s\'est allumé pour : $descriptionFr. '
        'Pouvez-vous vérifier ça ?"';
  }

  /// Conseil générique pour un code inconnu (pas dans le catalogue).
  Advice _buildAdviceInconnu(String dtcCode) {
    return Advice(
      dtcCode: dtcCode,
      urgenceLevel: UrgenceLevel.orange, // Par précaution
      titre: 'Code signalé',
      messageEcran:
          'Ton véhicule a signalé un code technique ($dtcCode) '
          'que nous n\'avons pas encore dans notre catalogue. '
          'Ce n\'est pas forcément grave, mais il vaut mieux le faire vérifier.',
      messageVocal:
          'Ton véhicule a signalé un code que nous ne connaissons pas encore. '
          'Prévois une vérification chez un professionnel.',
      questionGaragiste:
          'Tu peux dire à ton garagiste : '
          '"Mon application a détecté le code $dtcCode. Pouvez-vous vérifier ?"',
      peutContinuerRouler: true,
    );
  }

  /// Résumé global d'un scan avec plusieurs codes.
  String _buildResumeGlobal(UrgenceLevel urgenceGlobale, int nbCodes) {
    final nbMessage = nbCodes == 1 ? '1 point signalé' : '$nbCodes points signalés';
    return switch (urgenceGlobale) {
      UrgenceLevel.vert =>
        '$nbMessage — Tout est sous contrôle.',
      UrgenceLevel.orange =>
        '$nbMessage — Rien d\'urgent, mais un contrôle est conseillé.',
      UrgenceLevel.rouge =>
        '$nbMessage — Ton attention est nécessaire. Arrête-toi dès que possible.',
      UrgenceLevel.rougeCritique =>
        '$nbMessage — Par précaution, ne continue pas à rouler. Contacte un professionnel.',
    };
  }
}
