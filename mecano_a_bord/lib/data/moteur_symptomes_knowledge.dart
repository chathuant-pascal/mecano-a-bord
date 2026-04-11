// Base locale voyants / symptômes (mode gratuit IA) — données : assets/data/moteur_symptomes.json

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Entrée JSON (fiche voyant ou symptôme).
class MoteurSymptomeEntry {
  MoteurSymptomeEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.aliases,
    required this.severity,
    required this.canDrive,
    required this.shortMessage,
    required this.simpleExplanation,
    required this.possibleCauses,
    required this.driverActions,
    required this.stopNow,
    required this.urgentIf,
    required this.garagePhrase,
    required this.obdRecommended,
    required this.category,
  });

  final String id;
  final String type;
  final String title;
  final List<String> aliases;
  final String severity;
  final String canDrive;
  final String shortMessage;
  final String simpleExplanation;
  final List<String> possibleCauses;
  final List<String> driverActions;
  final bool stopNow;
  final List<String> urgentIf;
  final String garagePhrase;
  final bool obdRecommended;
  final String category;

  factory MoteurSymptomeEntry.fromJson(Map<String, dynamic> j) {
    List<String> asList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return MoteurSymptomeEntry(
      id: j['id']?.toString() ?? '',
      type: j['type']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      aliases: asList(j['aliases']),
      severity: j['severity']?.toString() ?? '',
      canDrive: j['canDrive']?.toString() ?? '',
      shortMessage: j['shortMessage']?.toString() ?? '',
      simpleExplanation: j['simpleExplanation']?.toString() ?? '',
      possibleCauses: asList(j['possibleCauses']),
      driverActions: asList(j['driverActions']),
      stopNow: j['stopNow'] == true,
      urgentIf: asList(j['urgentIf']),
      garagePhrase: j['garagePhrase']?.toString() ?? '',
      obdRecommended: j['obdRecommended'] == true,
      category: j['category']?.toString() ?? '',
    );
  }
}

/// Charge l’asset une fois, recherche par alias (priorité au libellé le plus long).
class MoteurSymptomesKnowledge {
  MoteurSymptomesKnowledge._();

  static const _assetPath = 'assets/data/moteur_symptomes.json';

  static List<MoteurSymptomeEntry>? _entries;

  static Future<void> ensureLoaded() async {
    if (_entries != null) return;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      _entries = [];
      return;
    }
    _entries = decoded
        .map((e) => MoteurSymptomeEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fiche par identifiant (après [ensureLoaded]). Utile à l’arbre guidé.
  static MoteurSymptomeEntry? entryById(String id) {
    final entries = _entries;
    if (entries == null || id.isEmpty) return null;
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Texte affiché à l’utilisateur (mots interdits projet retirés).
  static String sanitizeForDisplay(String s) => _sanitizeMabUserText(s);

  /// [vehicleInfo] : même préfixe que le mode gratuit (`Pour votre Marque Modèle (km)` ou défaut).
  /// Réponse prête à afficher, ou null si aucune fiche ne correspond.
  static String? matchAndBuild(String question, String vehicleInfo) {
    final entries = _entries;
    if (entries == null || entries.isEmpty) return null;

    final q = question.toLowerCase().trim();
    if (q.isEmpty) return null;

    MoteurSymptomeEntry? best;
    var bestScore = 0;

    void consider(String needle, MoteurSymptomeEntry e) {
      final n = needle.toLowerCase().trim();
      if (n.length < 2) return;
      if (q.contains(n)) {
        final score = n.length;
        if (score > bestScore) {
          bestScore = score;
          best = e;
        }
      }
    }

    for (final e in entries) {
      for (final a in e.aliases) {
        consider(a, e);
      }
      consider(e.title, e);
    }

    if (best == null) return null;
    return _compose(best!, vehicleInfo);
  }

  static String _labelCanDrive(String v) {
    return switch (v) {
      'oui' => 'Oui, conduite possible.',
      'oui_prudence' => 'Oui, en restant prudent.',
      'non' => 'Non : évitez de rouler ou arrêtez-vous.',
      'court_trajet_uniquement' => 'Court trajet uniquement, puis contrôle rapide.',
      _ => v,
    };
  }

  static String _labelSeverity(String v) {
    return switch (v) {
      'faible' => 'Peu critique',
      'moyenne' => 'À surveiller',
      'elevee' => 'Sérieux',
      'critique' => 'Très sérieux',
      _ => v,
    };
  }

  static String _compose(MoteurSymptomeEntry e, String vehicleInfo) {
    final buf = StringBuffer();
    buf.writeln(vehicleInfo);
    buf.writeln();
    buf.writeln(e.title);
    buf.writeln(_sanitizeMabUserText(e.shortMessage));
    buf.writeln();
    buf.writeln(_sanitizeMabUserText(e.simpleExplanation));
    buf.writeln();
    buf.writeln('Conduite : ${_labelCanDrive(e.canDrive)}');
    buf.writeln('Niveau : ${_labelSeverity(e.severity)}');
    if (e.stopNow) {
      buf.writeln('Il est conseillé de vous arrêter en sécurité sans attendre.');
    }
    buf.writeln();
    if (e.possibleCauses.isNotEmpty) {
      buf.writeln('Pistes possibles : ${_sanitizeMabUserText(e.possibleCauses.join(', '))}');
    }
    if (e.driverActions.isNotEmpty) {
      buf.writeln('À faire : ${_sanitizeMabUserText(e.driverActions.join(' · '))}');
    }
    if (e.urgentIf.isNotEmpty) {
      buf.writeln('Surveillez si : ${_sanitizeMabUserText(e.urgentIf.join(' · '))}');
    }
    buf.writeln();
    buf.writeln('Au garage : « ${_sanitizeMabUserText(e.garagePhrase)} »');
    if (e.obdRecommended) {
      buf.writeln();
      buf.writeln(
        'Un diagnostic OBD depuis l’accueil peut aider à préciser la cause.',
      );
    }
    return _sanitizeMabUserText(buf.toString().trim());
  }

  /// Règles projet : pas de « panne », « danger », « défaillance » dans les textes utilisateur.
  static String _sanitizeMabUserText(String s) {
    var o = s;
    o = o.replaceAll(RegExp(r'\bdéfaillante\b', caseSensitive: false), 'en erreur');
    o = o.replaceAll(RegExp(r'\bdéfaillant\b', caseSensitive: false), 'en erreur');
    o = o.replaceAll(RegExp(r'\bdéfaillance\b', caseSensitive: false), 'anomalie');
    o = o.replaceAll(RegExp(r'\bpanne\b', caseSensitive: false), 'situation');
    o = o.replaceAll(RegExp(r'\bdangereuse\b', caseSensitive: false), 'délicate');
    o = o.replaceAll(RegExp(r'\bdangereux\b', caseSensitive: false), 'délicat');
    o = o.replaceAll(RegExp(r'\bdanger\b', caseSensitive: false), 'attention');
    return o;
  }
}
