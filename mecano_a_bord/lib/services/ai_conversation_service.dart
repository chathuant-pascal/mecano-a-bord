// ai_conversation_service.dart — Mécano à Bord (Flutter iOS + Android)
//
// Rôle : gérer les conversations avec une IA depuis l'application.
//
// Deux modes :
//  - MODE GRATUIT : 5 questions/jour, réponses locales (mots-clés)
//  - MODE PERSONNEL : clé API utilisateur (ChatGPT/Gemini), questions illimitées

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:mecano_a_bord/data/moteur_symptomes_knowledge.dart';
import 'package:mecano_a_bord/utils/mab_logger.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
// MODÈLES
// ─────────────────────────────────────────────

enum AiProvider {
  claude,
  chatgpt,
  gemini,
  mistral,
  qwen,
  perplexity,
  grok,
  copilot,
  meta_ai,
  deepseek,
}
enum AiMode { free, personal }

class VehicleContext {
  final String brand;
  final String model;
  final int year;
  final int mileage;
  final String gearboxType;
  /// Dernier diagnostic : témoin MIL (Check Engine).
  final bool milOn;
  /// Codes combinés (mémorisés + en attente + permanents).
  final List<String> dtcCodes;

  const VehicleContext({
    required this.brand,
    required this.model,
    required this.year,
    required this.mileage,
    required this.gearboxType,
    this.milOn = false,
    this.dtcCodes = const [],
  });
}

abstract class AiResponse { const AiResponse(); }

class AiSuccess extends AiResponse {
  final String text;
  final AiMode mode;
  final int remainingFreeQuestions;
  const AiSuccess({
    required this.text,
    required this.mode,
    this.remainingFreeQuestions = -1,
  });
}

class AiLimitReached extends AiResponse {
  final String message;
  final int remainingTomorrow;
  const AiLimitReached({required this.message, required this.remainingTomorrow});
}

class AiError extends AiResponse {
  final String message;
  const AiError(this.message);
}

// ─────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────

class AiConversationService {
  static AiConversationService? _instance;
  static AiConversationService get instance {
    _instance ??= AiConversationService._();
    return _instance!;
  }

  AiConversationService._();

  static const _freeDailyLimit = 5;

  /// Fournisseur IA actuellement sélectionné (réglages + appels API).
  static const _keyProvider = 'mab_ai_provider';

  /// Ancienne clé unique (migration vers `api_key_*` par fournisseur).
  static const _legacyKeyApiKey = 'mab_ai_api_key';

  static const _keyQuestionsDate = 'mab_ai_questions_date';
  static const _keyQuestionsCount = 'mab_ai_questions_count';

  /// Clé secure storage par fournisseur : api_key_chatgpt, api_key_meta_ai, etc.
  static String storageKeyForProvider(AiProvider p) => 'api_key_${p.name}';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _systemPrompt = '''
Tu es l\'assistant de l\'application Mécano à Bord.
Tu aides les conducteurs à comprendre leur véhicule en langage simple et rassurant.
Règles absolues :
- Ne jamais utiliser les mots : panne, danger, défaillance, risque grave, erreur fatale
- Toujours être calme, bienveillant, accessible
- Réponses courtes (3-5 phrases maximum)
- Si tu ne sais pas, dis-le honnêtement
- Tu n\'es pas mécanicien et ne remplaces pas un professionnel
''';

  Future<void> _migrateLegacyApiKeyIfNeeded() async {
    final legacy = await _storage.read(key: _legacyKeyApiKey);
    if (legacy == null || legacy.isEmpty) return;
    final provStr = await _storage.read(key: _keyProvider) ?? 'chatgpt';
    final provider = AiProvider.values.firstWhere(
      (e) => e.name == provStr,
      orElse: () => AiProvider.chatgpt,
    );
    final newKey = storageKeyForProvider(provider);
    final existing = await _storage.read(key: newKey);
    if (existing == null || existing.isEmpty) {
      await _storage.write(key: newKey, value: legacy);
    }
    await _storage.delete(key: _legacyKeyApiKey);
  }

  /// Fournisseur mémorisé (sélecteur Réglages).
  Future<AiProvider> getSavedSelectedProvider() async {
    await _migrateLegacyApiKeyIfNeeded();
    final s = await _storage.read(key: _keyProvider) ?? 'chatgpt';
    return AiProvider.values.firstWhere(
      (e) => e.name == s,
      orElse: () => AiProvider.chatgpt,
    );
  }

  Future<void> saveSelectedProvider(AiProvider provider) async {
    await _migrateLegacyApiKeyIfNeeded();
    await _storage.write(key: _keyProvider, value: provider.name);
  }

  /// True si une clé non vide est enregistrée pour ce fournisseur.
  Future<bool> hasApiKeyForProvider(AiProvider p) async {
    await _migrateLegacyApiKeyIfNeeded();
    final k = await _storage.read(key: storageKeyForProvider(p));
    return k != null && k.isNotEmpty;
  }

  /// Enregistre la clé pour ce fournisseur (ne change pas le fournisseur sélectionné).
  Future<void> savePersonalApiKey(AiProvider provider, String apiKey) async {
    await _migrateLegacyApiKeyIfNeeded();
    await _storage.write(
      key: storageKeyForProvider(provider),
      value: apiKey.trim(),
    );
  }

  Future<void> removeApiKeyForProvider(AiProvider provider) async {
    await _storage.delete(key: storageKeyForProvider(provider));
  }

  /// Supprime la clé du fournisseur actuellement sélectionné (compatibilité).
  Future<void> removePersonalApiKey() async {
    final p = await getSavedSelectedProvider();
    await removeApiKeyForProvider(p);
  }

  Future<AiMode> getCurrentMode() async {
    await _migrateLegacyApiKeyIfNeeded();
    final p = await getSavedSelectedProvider();
    final apiKey = await _storage.read(key: storageKeyForProvider(p));
    return (apiKey != null && apiKey.isNotEmpty) ? AiMode.personal : AiMode.free;
  }

  /// Nombre de questions gratuites restantes aujourd'hui.
  Future<int> getRemainingFreeQuota() async {
    await _resetDailyCounterIfNeeded();
    final countStr = await _storage.read(key: _keyQuestionsCount) ?? '0';
    final used = int.tryParse(countStr) ?? 0;
    return (_freeDailyLimit - used).clamp(0, _freeDailyLimit);
  }

  /// Pour l'écran IA : true si une clé API personnelle est configurée.
  Future<bool> hasPersonalAiConnected() async {
    return await getCurrentMode() == AiMode.personal;
  }

  /// [systemContext] : contexte véhicule injecté en début de system prompt (invisible à l'utilisateur).
  /// [isDemoMode] : si true, renvoie une réponse pré-enregistrée (pas d'API, pas de quota).
  Future<AiResponse> ask(
    String question, {
    VehicleContext? vehicleContext,
    String? systemContext,
    bool isDemoMode = false,
    String? demoScenario,
  }) async {
    if (isDemoMode) {
      final text = _getDemoResponse(question, demoScenario ?? 'green');
      return AiSuccess(text: text, mode: AiMode.free, remainingFreeQuestions: 5);
    }
    final mode = await getCurrentMode();
    return mode == AiMode.personal
        ? await _askPersonalAi(question, vehicleContext, systemContext)
        : await _askFreeMode(question, vehicleContext);
  }

  static const int _maxTokensManufacturerJson = 512;

  /// Valeurs constructeur (JSON) — **mode personnel uniquement** ; ne touche pas au quota gratuit.
  /// Utilisé après enregistrement du profil véhicule (surveillance pédagogique).
  Future<AiResponse> askManufacturerReferenceJson({
    required String marque,
    required String modele,
    required int annee,
    required String motorisation,
  }) async {
    await _migrateLegacyApiKeyIfNeeded();
    final apiKey = await _storage.read(
      key: storageKeyForProvider(await getSavedSelectedProvider()),
    );
    if (apiKey == null || apiKey.isEmpty) {
      return const AiError('assistant_ia_non_configuré');
    }
    final userPrompt =
        'Tu es un expert automobile. Pour le véhicule suivant : '
        '$marque $modele $annee $motorisation, donne-moi '
        'UNIQUEMENT en JSON les valeurs normales constructeur : '
        '{'
        '"temperature_normale_min": XX, '
        '"temperature_normale_max": XX, '
        '"tension_batterie_min": XX, '
        '"tension_batterie_max": XX, '
        '"regime_ralenti_min": XX, '
        '"regime_ralenti_max": XX, '
        '"temperature_huile_min": XX, '
        '"temperature_huile_max": XX'
        '} '
        'Réponds UNIQUEMENT avec le JSON, rien d\'autre.';
    const systemExtra =
        'Réponds uniquement avec un objet JSON valide, sans markdown, sans blocs de code, sans texte avant ou après.';
    return _askPersonalAi(
      userPrompt,
      null,
      systemExtra,
      maxTokens: _maxTokensManufacturerJson,
    );
  }

  /// Réponses pré-enregistrées en mode démo (profil Renault Clio 4 + scénario OBD).
  String _getDemoResponse(String question, String scenario) {
    final q = question.toLowerCase();
    final vehicle = 'Pour votre Renault Clio 4 Diesel (87 500 km)';
    if (q.contains('défaut') || q.contains('code') || q.contains('voyant') || q.contains('obd')) {
      if (scenario == 'green') {
        return '$vehicle : le dernier diagnostic (démo) n\'a détecté aucun code défaut. Tous les systèmes sont OK.';
      }
      if (scenario == 'orange') {
        return '$vehicle : le dernier diagnostic démo a enregistré 2 codes : P0171 (mélange pauvre) et P0420 (catalyseur). '
            'Le témoin moteur est éteint. Ces codes datent du dernier diagnostic ; vous pouvez les faire effacer après réparation.';
      }
      if (scenario == 'red') {
        return '$vehicle : le dernier diagnostic démo signale 3 codes critiques : P0301 (cylindre 1), P0562 (tension batterie), U0100 (communication). '
            'Le témoin moteur est allumé. Consultez un professionnel. Ces codes datent du dernier diagnostic.';
      }
    }
    if (q.contains('vidange') || q.contains('huile')) {
      return '$vehicle : selon le carnet démo, dernière vidange à 85 000 km. Prochaine prévue vers 95 000 km. '
          'Sur un Diesel, respectez les intervalles prévus par le constructeur.';
    }
    if (q.contains('entretien') || q.contains('carnet')) {
      return '$vehicle : le carnet démo indique vidange 85 000 km, filtres 82 000 km, contrôle technique à 78 000 km. '
          'Consultez l\'onglet Boîte à gants pour le détail.';
    }
    if (q.contains('bonjour') || q.contains('salut') || q.isEmpty) {
      return 'Bonjour ! En mode démo, je réponds avec des données simulées (Renault Clio 4, 87 500 km). '
          'Posez-moi une question sur les défauts, la vidange ou l\'entretien.';
    }
    return '$vehicle : en mode démo, les réponses sont simulées. '
        'Vous pouvez me demander des infos sur les codes défaut, la vidange ou le carnet d\'entretien.';
  }

  Future<AiResponse> _askFreeMode(
    String question,
    VehicleContext? vehicleContext,
  ) async {
    await _resetDailyCounterIfNeeded();
    final countStr = await _storage.read(key: _keyQuestionsCount) ?? '0';
    final used = int.tryParse(countStr) ?? 0;

    if (used >= _freeDailyLimit) {
      return AiLimitReached(
        message: 'Vous avez utilisé vos $_freeDailyLimit questions gratuites du jour. '
            'Elles se renouvellent chaque jour à minuit. '
            'Vous pouvez aussi connecter votre compte ChatGPT ou Gemini pour des questions illimitées.',
        remainingTomorrow: _freeDailyLimit,
      );
    }

    await _storage.write(key: _keyQuestionsCount, value: '${used + 1}');

    await MoteurSymptomesKnowledge.ensureLoaded();
    final vehicleInfo = vehicleContext != null
        ? 'Pour votre ${vehicleContext.brand} ${vehicleContext.model} (${vehicleContext.mileage} km)'
        : 'Pour votre véhicule';
    final response = MoteurSymptomesKnowledge.matchAndBuild(question, vehicleInfo) ??
        _generateLocalResponse(question, vehicleContext);

    return AiSuccess(
      text: response,
      mode: AiMode.free,
      remainingFreeQuestions: _freeDailyLimit - (used + 1),
    );
  }

  String _generateLocalResponse(String question, VehicleContext? ctx) {
    final q = question.toLowerCase();
    final vehicleInfo = ctx != null
        ? 'Pour votre ${ctx.brand} ${ctx.model} (${ctx.mileage} km)'
        : 'Pour votre véhicule';
  
    // ─── NIVEAU 1 — URGENCES ───────────────────────────────────────
  
    if (q.contains('fumée blanche') || q.contains('fumee blanche')) {
      return '$vehicleInfo : une fumée blanche épaisse au démarrage peut indiquer '
          'un problème de liquide de refroidissement. Arrêtez-vous dès que possible, '
          'coupez le moteur et appelez un professionnel. Ne redémarrez pas.';
    }
    if (q.contains('fumée noire') || q.contains('fumee noire')) {
      return '$vehicleInfo : une fumée noire indique une combustion trop riche en carburant. '
          'C\'est souvent lié à un filtre à air encrassé ou un injecteur. '
          'Ce n\'est pas une urgence immédiate mais faites vérifier rapidement.';
    }
    if (q.contains('fumée bleue') || q.contains('fumee bleue')) {
      return '$vehicleInfo : une fumée bleue signifie que le moteur brûle de l\'huile. '
          'Vérifiez votre niveau d\'huile immédiatement. '
          'Si le niveau est bas, ne roulez pas et contactez un professionnel.';
    }
    if (q.contains('fumée') || q.contains('fumee')) {
      return '$vehicleInfo : si vous voyez de la fumée, arrêtez-vous en sécurité '
          'et coupez le moteur. Notez la couleur (blanche, noire, bleue) '
          'et signalez-la au professionnel — c\'est une information très utile.';
    }
    if (q.contains('pédale molle') || q.contains('pedale molle') ||
        q.contains('frein mou') || q.contains('freins mous')) {
      return '$vehicleInfo : une pédale de frein molle est une urgence de sécurité. '
          'Ralentissez progressivement, arrêtez-vous dès que possible '
          'et ne reprenez pas la route. Appelez un professionnel immédiatement.';
    }
    if (q.contains('perte de frein') || q.contains('freins ne répondent') ||
        q.contains('freins ne repondent')) {
      return '$vehicleInfo : si vos freins ne répondent plus, restez calme. '
          'Rétrogradez progressivement, utilisez le frein à main doucement '
          'et dirigez-vous vers un endroit sûr. Appelez les secours si nécessaire.';
    }
    if (q.contains('voyant huile') || q.contains('voyant rouge') && q.contains('huile') ||
        q.contains('pression huile')) {
      return '$vehicleInfo : le voyant rouge huile est une urgence moteur. '
          'Arrêtez-vous immédiatement, coupez le moteur. '
          'Rouler sans pression d\'huile peut détruire le moteur en quelques minutes. '
          'Appelez un professionnel avant de redémarrer.';
    }
    if (q.contains('bruit fort') || q.contains('choc') && q.contains('moteur') ||
        q.contains('claquement') || q.contains('cognement')) {
      return '$vehicleInfo : un bruit fort ou claquement soudain sous le capot '
          'peut indiquer un problème mécanique sérieux. '
          'Arrêtez-vous dès que possible et coupez le moteur. '
          'Notez dans quelles conditions le bruit est apparu pour le décrire au professionnel.';
    }
    if (q.contains('odeur brûlé') || q.contains('odeur brule') ||
        q.contains('ça sent le brûlé') || q.contains('ca sent le brule')) {
      return '$vehicleInfo : une odeur de brûlé peut venir des freins, '
          'de l\'embrayage ou d\'un câble électrique. '
          'Arrêtez-vous en sécurité et laissez refroidir. '
          'Si l\'odeur persiste au redémarrage, ne roulez pas et faites appel à un professionnel.';
    }
    if (q.contains('odeur caoutchouc') || q.contains('odeur de caoutchouc')) {
      return '$vehicleInfo : une odeur de caoutchouc brûlé vient souvent '
          'des freins surchauffés ou d\'un pneu qui frotte. '
          'Arrêtez-vous et vérifiez visuellement vos roues. '
          'Ne repartez pas si un pneu est à plat ou une roue anormalement chaude.';
    }
    if (q.contains('fuite') || q.contains('tache sous') || q.contains('flaque sous')) {
      return '$vehicleInfo : une fuite sous le véhicule doit être identifiée '
          'par sa couleur : huile (marron/noire), liquide de refroidissement (vert/rose), '
          'liquide de frein (transparent/jaunâtre). '
          'Photographiez la tache et montrez-la à votre professionnel.';
    }
    if (q.contains('vibr') && (q.contains('fort') || q.contains('volant') || q.contains('siège'))) {
      return '$vehicleInfo : des vibrations fortes au volant ou au siège '
          'peuvent venir d\'un pneu déséquilibré, d\'un problème de train avant '
          'ou d\'un disque de frein voilé. '
          'Réduisez la vitesse et faites vérifier rapidement.';
    }
  
    // ─── NIVEAU 2 — VOYANTS FRÉQUENTS ─────────────────────────────
  
    if (q.contains('check engine') || q.contains('voyant moteur') ||
        q.contains('témoin moteur') || q.contains('temoin moteur')) {
      return '$vehicleInfo : le voyant moteur (Check Engine) signale '
          'qu\'un capteur a détecté quelque chose d\'inhabituel. '
          'Ce n\'est pas toujours urgent, mais lancez un diagnostic OBD '
          'depuis l\'accueil pour lire le code exact. C\'est la meilleure façon de comprendre.';
    }
    if (q.contains('voyant batterie') || q.contains('témoin batterie')) {
      return '$vehicleInfo : le voyant batterie allumé en roulant indique '
          'que l\'alternateur ne recharge plus la batterie. '
          'Limitez l\'électricité (clim, radio) et rejoignez un professionnel rapidement. '
          'La voiture peut s\'arrêter si la batterie se vide complètement.';
    }
    if (q.contains('voyant température') || q.contains('voyant temperature') ||
        q.contains('témoin température') || q.contains('temoin temperature')) {
      return '$vehicleInfo : le voyant température rouge indique une surchauffe moteur. '
          'Arrêtez-vous immédiatement, coupez le moteur et attendez 30 minutes. '
          'Ne jamais ouvrir le bouchon du radiateur à chaud. '
          'Vérifiez le niveau de liquide de refroidissement une fois refroidi.';
    }
    if (q.contains('tpms') || q.contains('pression pneu') ||
        q.contains('voyant pneu') || q.contains('témoin pneu')) {
      return '$vehicleInfo : le voyant TPMS signale qu\'un ou plusieurs pneus '
          'sont sous-gonflés. Arrêtez-vous dès que possible et vérifiez '
          'la pression de vos 4 pneus à froid. La pression recommandée '
          'est indiquée sur l\'autocollant dans l\'encadrement de votre portière.';
    }
    if (q.contains('voyant abs') || q.contains('témoin abs')) {
      return '$vehicleInfo : le voyant ABS allumé signifie que le système '
          'anti-blocage est désactivé. Vos freins fonctionnent encore normalement '
          'mais sans assistance ABS. Roulez prudemment et faites vérifier '
          'par un professionnel rapidement.';
    }
    if (q.contains('voyant airbag') || q.contains('témoin airbag')) {
      return '$vehicleInfo : le voyant airbag indique un problème dans le système '
          'de sécurité passive. Ce n\'est pas une urgence de conduite immédiate '
          'mais les airbags pourraient ne pas se déclencher en cas de choc. '
          'Faites vérifier dès que possible.';
    }
    if (q.contains('direction assistée') || q.contains('direction assistee') ||
        q.contains('voyant direction')) {
      return '$vehicleInfo : le voyant direction assistée allumé peut rendre '
          'la direction plus lourde. Vous pouvez encore conduire mais avec plus d\'effort. '
          'Faites vérifier rapidement — c\'est souvent la pompe ou le capteur de direction.';
    }
    if (q.contains('préchauffage') || q.contains('prechauffage') || q.contains('bougie')) {
      return '$vehicleInfo : le voyant préchauffage (spirale orange sur Diesel) '
          'doit normalement s\'éteindre après quelques secondes. '
          'S\'il reste allumé, cela indique un problème sur une bougie de préchauffage '
          'ou le système d\'injection. Faites un diagnostic OBD pour en savoir plus.';
    }
  
    // ─── NIVEAU 3 — ENTRETIEN COURANT ─────────────────────────────
  
    if (q.contains('vidange') || q.contains('huile')) {
      return '$vehicleInfo : la vidange est recommandée tous les 10 000 à 15 000 km '
          'selon le constructeur. Consultez votre carnet d\'entretien dans la Boîte à gants '
          'pour connaître la date de votre dernière vidange et anticiper la prochaine.';
    }
    if (q.contains('filtre à air') || q.contains('filtre a air')) {
      return '$vehicleInfo : le filtre à air se remplace généralement tous les 20 000 à 30 000 km. '
          'Un filtre encrassé augmente la consommation et réduit les performances. '
          'C\'est une intervention simple et peu coûteuse.';
    }
    if (q.contains('filtre habitacle') || q.contains('filtre pollen') || q.contains('filtre cabine')) {
      return '$vehicleInfo : le filtre habitacle (anti-pollen) se remplace tous les ans '
          'ou tous les 15 000 km. Il filtre l\'air que vous respirez dans l\'habitacle. '
          'C\'est une intervention rapide et accessible.';
    }
    if (q.contains('liquide de frein') || q.contains('liquide frein')) {
      return '$vehicleInfo : le liquide de frein se remplace tous les 2 ans '
          'indépendamment du kilométrage. Il absorbe l\'humidité avec le temps '
          'ce qui réduit son efficacité. C\'est une maintenance de sécurité importante.';
    }
    if (q.contains('liquide de refroidissement') || q.contains('liquide refroidissement') ||
        q.contains('antigel')) {
      return '$vehicleInfo : le liquide de refroidissement se contrôle régulièrement '
          'et se remplace selon les préconisations constructeur (souvent tous les 3-5 ans). '
          'Vérifiez le niveau à froid dans le vase d\'expansion sous le capot.';
    }
    if (q.contains('essuie-glace') || q.contains('essuie glace') || q.contains('balai')) {
      return '$vehicleInfo : les essuie-glaces se remplacent généralement tous les ans '
          'ou dès qu\'ils rayent ou laissent des traces. '
          'C\'est une question de sécurité visuelle par temps de pluie — ne les négligez pas.';
    }
    if (q.contains('courroie') || q.contains('distribution')) {
      return '$vehicleInfo : la courroie de distribution est à remplacer '
          'selon le kilométrage de votre carnet (souvent entre 60 000 et 120 000 km). '
          'C\'est une maintenance préventive clé — une rupture peut détruire le moteur.';
    }
    if (q.contains('embrayage') || q.contains('patine') || q.contains('pédale embrayage')) {
      return '$vehicleInfo : si l\'embrayage patine (le moteur monte en régime '
          'sans que la voiture accélère), c\'est signe d\'usure avancée. '
          'L\'embrayage se remplace généralement entre 80 000 et 150 000 km '
          'selon le style de conduite.';
    }
    if (q.contains('démarrage difficile') || q.contains('demarrage difficile') ||
        q.contains('démarre mal') || q.contains('demarre mal')) {
      return '$vehicleInfo : un démarrage difficile peut venir de la batterie, '
          'du démarreur ou des bougies d\'allumage. '
          'Si votre batterie a plus de 4 ans, commencez par la faire tester '
          'chez un professionnel — c\'est souvent la cause la plus fréquente.';
    }
  
    // ─── NIVEAU 4 — COMPRENDRE SON VÉHICULE ───────────────────────
  
    if (q.contains('code défaut') || q.contains('code defaut') ||
        q.contains('qu\'est-ce qu\'un code') || q.contains('c\'est quoi un code')) {
      return 'Un code défaut OBD est un message généré par le calculateur de votre voiture '
          'quand il détecte quelque chose d\'anormal. '
          'Il commence par une lettre (P pour moteur, B pour carrosserie, C pour châssis) '
          'suivie de 4 chiffres. Lancez un diagnostic depuis l\'accueil pour lire les vôtres.';
    }
    if (q.contains('puis-je rouler') || q.contains('puis je rouler') ||
        q.contains('peut-on rouler') || q.contains('peut on rouler')) {
      if (ctx != null && ctx.milOn) {
        return '$vehicleInfo : le voyant moteur est allumé. '
            'Vous pouvez généralement rouler prudemment jusqu\'à un professionnel '
            'si le voyant est orange et fixe. '
            'En revanche, arrêtez-vous si le voyant est rouge ou clignote.';
      }
      return '$vehicleInfo : si un voyant est allumé, lancez d\'abord un diagnostic OBD '
          'depuis l\'accueil pour identifier le problème. '
          'En cas de doute, il vaut toujours mieux consulter un professionnel avant de rouler.';
    }
    if (q.contains('consomm') && (q.contains('plus') || q.contains('augment'))) {
      return '$vehicleInfo : une consommation qui augmente peut avoir plusieurs causes : '
          'filtre à air encrassé, pression des pneus insuffisante, injecteurs usés '
          'ou simplement un changement de conduite ou de trajet. '
          'Commencez par vérifier la pression des pneus — c\'est gratuit et rapide.';
    }
    if (q.contains('climatisation') || q.contains('clim') && q.contains('refroidit pas') ||
        q.contains('clim') && q.contains('ne fonctionne')) {
      return '$vehicleInfo : si la climatisation ne refroidit plus, '
          'le gaz réfrigérant est probablement épuisé. '
          'C\'est une recharge à faire chez un professionnel (tous les 2-3 ans en moyenne). '
          'Ce n\'est pas une urgence mécanique mais ça peut être gênant en été.';
    }
    if (q.contains('boîte automatique') || q.contains('boite automatique')) {
      return 'Une boîte automatique change les rapports toute seule sans pédale d\'embrayage. '
          'Elle demande moins d\'effort en conduite urbaine. '
          'L\'entretien principal est le remplacement de l\'huile de boîte '
          'tous les 60 000 à 80 000 km selon le constructeur.';
    }
    if (q.contains('turbo')) {
      return '$vehicleInfo : le turbo est un compresseur entraîné par les gaz d\'échappement '
          'qui augmente la puissance du moteur. '
          'Pour le préserver, laissez toujours le moteur tourner 1 à 2 minutes '
          'au ralenti avant de l\'éteindre après un trajet sportif.';
    }
    if (q.contains('rodage') || q.contains('voiture neuve') && q.contains('km')) {
      return 'Le rodage concerne les 1 000 à 2 000 premiers kilomètres d\'un moteur neuf. '
          'Évitez les régimes élevés, variez les vitesses et ne chargez pas inutilement. '
          'Cela permet aux pièces de s\'ajuster parfaitement et prolonge la durée de vie du moteur.';
    }
  
    // ─── NIVEAU 5 — QUOI DIRE AU GARAGISTE ────────────────────────
  
    if (q.contains('dire au garagiste') || q.contains('dire au mécanicien') ||
        q.contains('dire au mecanicien') || q.contains('expliquer au garagiste')) {
      return 'Pour bien expliquer un problème à votre garagiste, notez : '
          '1) Quand ça arrive (démarrage, en roulant, en freinant), '
          '2) À quelle vitesse ou température, '
          '3) Si c\'est permanent ou par intermittence, '
          '4) Depuis combien de temps. Plus vous êtes précis, plus le diagnostic est rapide.';
    }
    if (q.contains('décrire un bruit') || q.contains('decrire un bruit') ||
        q.contains('quel bruit')) {
      return 'Pour décrire un bruit à votre garagiste, précisez : '
          'claquement, sifflement, grondement, frottement ou vibration. '
          'Indiquez aussi d\'où il vient (avant, arrière, gauche, droite, sous le capot) '
          'et dans quelles conditions il apparaît (freinage, virage, accélération).';
    }
    if (q.contains('devis') || q.contains('facture') || q.contains('prix') && q.contains('répar')) {
      return 'Avant toute réparation, demandez toujours un devis écrit et signé. '
          'Il doit mentionner le prix des pièces et de la main d\'œuvre séparément. '
          'Vous avez le droit de demander les anciennes pièces remplacées. '
          'N\'hésitez pas à demander un deuxième avis pour les grosses réparations.';
    }
    if (q.contains('se faire avoir') || q.contains('arnaque') || q.contains('confiance')) {
      return 'Pour éviter les mauvaises surprises chez le garagiste : '
          'demandez toujours un devis avant, faites préciser ce qui est urgent et ce qui peut attendre, '
          'et ne donnez jamais votre accord pour des travaux supplémentaires par téléphone sans devis. '
          'Un bon professionnel prend le temps de vous expliquer.';
    }
  
    // ─── RÉPONSES AVEC CODES DTC ACTIFS ───────────────────────────
  
    if (ctx != null && ctx.dtcCodes.isNotEmpty) {
      return '$vehicleInfo : votre dernier diagnostic a relevé des codes actifs : '
          '${ctx.dtcCodes.join(", ")}. '
          'Ces codes sont visibles dans votre historique de diagnostics (Boîte à gants). '
          'Pour une analyse détaillée, connectez votre assistant IA dans les réglages.';
    }
  
    // ─── RÉPONSE GÉNÉRIQUE ─────────────────────────────────────────
  
    return 'Bonne question ! Pour une réponse personnalisée à votre situation, '
        'vous pouvez connecter votre assistant IA dans les réglages. '
        'En attendant, lancez un diagnostic complet depuis l\'écran d\'accueil — '
        'c\'est le meilleur point de départ pour comprendre l\'état de votre véhicule.';
  }

  Future<AiResponse> _askPersonalAi(
    String question,
    VehicleContext? vehicleContext,
    String? systemContext, {
    int maxTokens = 300,
  }) async {
    await _migrateLegacyApiKeyIfNeeded();
    final provider = await getSavedSelectedProvider();
    final apiKey = await _storage.read(key: storageKeyForProvider(provider));
    if (apiKey == null || apiKey.isEmpty) {
      return const AiError('Clé API introuvable. Vérifiez vos réglages.');
    }
    final systemPromptWithContext = systemContext != null && systemContext.isNotEmpty
        ? '${_systemPrompt.trim()}\n\n$systemContext'
        : _systemPrompt.trim();

    if (provider == AiProvider.chatgpt) {
      return await _callChatGpt(apiKey, question, systemPromptWithContext, maxTokens: maxTokens);
    }
    if (provider == AiProvider.gemini) {
      return await _callGemini(apiKey, question, systemPromptWithContext, maxOutputTokens: maxTokens);
    }
    final label = _providerLabel(provider);
    return AiError('$label sera disponible prochainement.');
  }

  static String _providerLabel(AiProvider p) {
    return switch (p) {
      AiProvider.claude => 'Claude',
      AiProvider.chatgpt => 'ChatGPT',
      AiProvider.gemini => 'Gemini',
      AiProvider.mistral => 'Mistral',
      AiProvider.qwen => 'Qwen',
      AiProvider.perplexity => 'Perplexity',
      AiProvider.grok => 'Grok',
      AiProvider.copilot => 'Copilot',
      AiProvider.meta_ai => 'Meta AI',
      AiProvider.deepseek => 'DeepSeek',
    };
  }

  Future<AiResponse> _callChatGpt(
    String apiKey,
    String question,
    String systemPrompt, {
    int maxTokens = 300,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'max_tokens': maxTokens,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': question},
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json['choices'][0]['message']['content'] as String;
        return AiSuccess(text: text.trim(), mode: AiMode.personal);
      } else if (response.statusCode == 401) {
        return const AiError('Clé API ChatGPT invalide. Vérifiez-la dans vos réglages.');
      } else if (response.statusCode == 429) {
        return const AiError('Vous avez atteint la limite de votre compte ChatGPT. Réessayez dans quelques instants.');
      } else {
        return const AiError('Une erreur est survenue avec ChatGPT. Réessayez dans quelques instants.');
      }
    } catch (e) {
      mabLog('CHATGPT ERROR: $e');
      return AiError('Connexion impossible à ChatGPT. Erreur : $e');
    }
  }

  Future<AiResponse> _callGemini(
    String apiKey,
    String question,
    String systemPrompt, {
    int maxOutputTokens = 300,
  }) async {
    try {
      final fullPrompt = '$systemPrompt\n\nQuestion de l\'utilisateur : $question';
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/'
          'gemini-1.5-flash:generateContent?key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': fullPrompt}]
            }
          ],
          'generationConfig': {'maxOutputTokens': maxOutputTokens},
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json['candidates'][0]['content']['parts'][0]['text'] as String;
        return AiSuccess(text: text.trim(), mode: AiMode.personal);
      } else if (response.statusCode == 400) {
        return const AiError('Clé API Gemini invalide. Vérifiez-la dans vos réglages.');
      } else {
        return const AiError('Une erreur est survenue avec Gemini. Réessayez dans quelques instants.');
      }
    } catch (e) {
      return const AiError('Connexion impossible à Gemini. Vérifiez votre connexion Internet.');
    }
  }

  Future<void> _resetDailyCounterIfNeeded() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = await _storage.read(key: _keyQuestionsDate);
    if (savedDate != today) {
      await _storage.write(key: _keyQuestionsDate, value: today);
      await _storage.write(key: _keyQuestionsCount, value: '0');
    }
  }
}
