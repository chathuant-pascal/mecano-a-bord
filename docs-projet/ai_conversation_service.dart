// ai_conversation_service.dart — Mécano à Bord (Flutter iOS + Android)
//
// Rôle : gérer les conversations avec une IA depuis l'application.
//
// Deux modes de fonctionnement :
//
//  MODE GRATUIT (par défaut, sans configuration)
//  - L'utilisateur peut poser jusqu'à 5 questions par jour
//  - Réponses générées localement à partir de mots-clés
//  - Pas de clé API nécessaire
//  - Compteur remis à zéro chaque jour à minuit
//
//  MODE PERSONNEL (avec clé API de l'utilisateur)
//  - L'utilisateur connecte son propre compte IA (ChatGPT, Gemini, etc.)
//  - Questions illimitées
//  - La clé API est stockée de façon chiffrée sur l'appareil
//  - L'application ne fournit aucune IA payante elle-même
//
// Dépendances Flutter à ajouter dans pubspec.yaml :
//   flutter_secure_storage: ^9.0.0   (stockage chiffré de la clé API)
//   http: ^1.2.0                     (appels API)

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
// MODÈLES DE DONNÉES
// ─────────────────────────────────────────────

/// Les IA supportées en mode personnel
enum AiProvider { chatgpt, gemini }

/// Le mode actif de l'assistant IA
enum AiMode { free, personal }

/// Contexte du véhicule transmis à l'IA pour des réponses personnalisées
class VehicleContext {
  final String brand;
  final String model;
  final int year;
  final int mileage;
  final String gearboxType;
  final List<String> dtcCodes;

  const VehicleContext({
    required this.brand,
    required this.model,
    required this.year,
    required this.mileage,
    required this.gearboxType,
    this.dtcCodes = const [],
  });
}

/// Résultat d'une question posée à l'IA
abstract class AiResponse { const AiResponse(); }

class AiSuccess extends AiResponse {
  final String text;
  final AiMode mode;
  final int remainingFreeQuestions; // -1 = illimité (mode personnel)
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
// SERVICE IA CONVERSATIONNEL
// ─────────────────────────────────────────────

class AiConversationService {
  static const _freeDailyLimit = 5;

  // Clés de stockage chiffré
  static const _keyProvider      = 'mab_ai_provider';
  static const _keyApiKey        = 'mab_ai_api_key';
  static const _keyQuestionsDate = 'mab_ai_questions_date';
  static const _keyQuestionsCount = 'mab_ai_questions_count';

  // Stockage chiffré (Keychain iOS / Keystore Android)
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Prompt système commun à toutes les IA
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

  // ─────────────────────────────────────────────
  // CONFIGURATION DU COMPTE IA PERSONNEL
  // ─────────────────────────────────────────────

  /// Enregistre la clé API de l'utilisateur (stockage chiffré).
  Future<void> savePersonalApiKey(AiProvider provider, String apiKey) async {
    await _storage.write(key: _keyProvider, value: provider.name);
    await _storage.write(key: _keyApiKey, value: apiKey);
  }

  /// Supprime la clé API (retour au mode gratuit).
  Future<void> removePersonalApiKey() async {
    await _storage.delete(key: _keyProvider);
    await _storage.delete(key: _keyApiKey);
  }

  /// Retourne le mode actif : personal si une clé est configurée, free sinon.
  Future<AiMode> getCurrentMode() async {
    final apiKey = await _storage.read(key: _keyApiKey);
    return (apiKey != null && apiKey.isNotEmpty) ? AiMode.personal : AiMode.free;
  }

  /// Retourne le nombre de questions gratuites restantes aujourd'hui.
  Future<int> getRemainingFreeQuestions() async {
    await _resetDailyCounterIfNeeded();
    final countStr = await _storage.read(key: _keyQuestionsCount) ?? '0';
    final used = int.tryParse(countStr) ?? 0;
    return (_freeDailyLimit - used).clamp(0, _freeDailyLimit);
  }

  // ─────────────────────────────────────────────
  // ENVOI D'UNE QUESTION
  // ─────────────────────────────────────────────

  /// Envoie une question à l'IA et retourne la réponse.
  Future<AiResponse> ask(
    String question, {
    VehicleContext? vehicleContext,
  }) async {
    final mode = await getCurrentMode();
    return mode == AiMode.personal
        ? await _askPersonalAi(question, vehicleContext)
        : await _askFreeMode(question, vehicleContext);
  }

  // ─────────────────────────────────────────────
  // MODE GRATUIT (réponses locales)
  // ─────────────────────────────────────────────

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
    final response = _generateLocalResponse(question, vehicleContext);

    return AiSuccess(
      text: response,
      mode: AiMode.free,
      remainingFreeQuestions: _freeDailyLimit - (used + 1),
    );
  }

  /// Génère une réponse locale à partir de mots-clés dans la question.
  String _generateLocalResponse(String question, VehicleContext? ctx) {
    final q = question.toLowerCase();
    final vehicleInfo = ctx != null
        ? 'Pour votre ${ctx.brand} ${ctx.model} (${ctx.mileage} km)'
        : 'Pour votre véhicule';

    if (q.contains('voyant') || q.contains('témoin')) {
      return '$vehicleInfo : un voyant allumé indique que le calculateur a détecté '
          'quelque chose d\'inhabituel. Le mieux est de lancer un diagnostic '
          'depuis l\'écran d\'accueil pour identifier de quoi il s\'agit.';
    }
    if (q.contains('vidange') || q.contains('huile')) {
      return '$vehicleInfo : la vidange est généralement recommandée tous les '
          '10 000 à 15 000 km selon le constructeur. Vérifiez votre carnet '
          'd\'entretien dans la Boîte à gants pour connaître la date de votre dernière vidange.';
    }
    if (q.contains('température') || q.contains('chauffe')) {
      return '$vehicleInfo : si le moteur chauffe, arrêtez-vous dès que possible '
          'en sécurité et coupez le moteur. Attendez qu\'il refroidisse avant '
          'de vérifier le niveau de liquide de refroidissement.';
    }
    if (q.contains('frein')) {
      return '$vehicleInfo : les freins sont essentiels à votre sécurité. '
          'Si vous entendez un bruit ou si la pédale est molle, faites vérifier '
          'par un professionnel dès que possible.';
    }
    if (q.contains('pneu') || q.contains('pression')) {
      return '$vehicleInfo : vérifiez la pression de vos pneus à froid, idéalement '
          'une fois par mois. La pression recommandée est indiquée sur l\'autocollant '
          'dans l\'encadrement de votre portière conducteur.';
    }
    if (q.contains('batterie')) {
      return '$vehicleInfo : une batterie dure généralement 4 à 6 ans. '
          'Si votre voiture démarre difficilement, il peut être utile de '
          'la faire tester par un professionnel.';
    }
    if (q.contains('courroie') || q.contains('distribution')) {
      return '$vehicleInfo : la courroie de distribution est à remplacer selon '
          'le kilométrage de votre carnet d\'entretien (souvent entre 60 000 et 120 000 km). '
          'C\'est une maintenance préventive clé à ne pas oublier.';
    }
    if (ctx != null && ctx.dtcCodes.isNotEmpty) {
      return 'Votre véhicule a des codes d\'anomalie actifs : ${ctx.dtcCodes.join(", ")}. '
          'Ces codes sont détaillés dans votre historique de diagnostics. '
          'Pour une analyse approfondie, connectez votre compte IA personnel.';
    }
    return 'Bonne question ! Pour une réponse personnalisée, vous pouvez connecter '
        'votre compte ChatGPT ou Gemini dans les réglages. '
        'En attendant, lancez un diagnostic complet depuis l\'écran d\'accueil.';
  }

  // ─────────────────────────────────────────────
  // MODE PERSONNEL (appel API externe)
  // ─────────────────────────────────────────────

  Future<AiResponse> _askPersonalAi(
    String question,
    VehicleContext? vehicleContext,
  ) async {
    final providerStr = await _storage.read(key: _keyProvider) ?? 'chatgpt';
    final apiKey = await _storage.read(key: _keyApiKey);
    if (apiKey == null || apiKey.isEmpty) {
      return const AiError('Clé API introuvable. Vérifiez vos réglages.');
    }

    final provider = AiProvider.values.firstWhere(
      (p) => p.name == providerStr,
      orElse: () => AiProvider.chatgpt,
    );
    final fullQuestion = _buildEnrichedQuestion(question, vehicleContext);

    return provider == AiProvider.chatgpt
        ? await _callChatGpt(apiKey, fullQuestion)
        : await _callGemini(apiKey, fullQuestion);
  }

  String _buildEnrichedQuestion(String question, VehicleContext? ctx) {
    if (ctx == null) return question;
    final buffer = StringBuffer();
    buffer.write('Contexte du véhicule : ');
    buffer.write('${ctx.brand} ${ctx.model} ${ctx.year}, ');
    buffer.write('${ctx.mileage} km, boîte ${ctx.gearboxType}. ');
    if (ctx.dtcCodes.isNotEmpty) {
      buffer.write('Codes d\'anomalie actifs : ${ctx.dtcCodes.join(", ")}. ');
    }
    buffer.write('\nQuestion : $question');
    return buffer.toString();
  }

  // ─────────────────────────────────────────────
  // APPEL CHATGPT (OpenAI)
  // ─────────────────────────────────────────────

  Future<AiResponse> _callChatGpt(String apiKey, String question) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'max_tokens': 300,
          'messages': [
            {'role': 'system', 'content': _systemPrompt.trim()},
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
      return const AiError('Connexion impossible à ChatGPT. Vérifiez votre connexion Internet.');
    }
  }

  // ─────────────────────────────────────────────
  // APPEL GEMINI (Google)
  // ─────────────────────────────────────────────

  Future<AiResponse> _callGemini(String apiKey, String question) async {
    try {
      final fullPrompt = '${_systemPrompt.trim()}\n\n$question';
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
          'generationConfig': {'maxOutputTokens': 300},
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

  // ─────────────────────────────────────────────
  // COMPTEUR JOURNALIER
  // ─────────────────────────────────────────────

  Future<void> _resetDailyCounterIfNeeded() async {
    final today = DateTime.now().toIso8601String().substring(0, 10); // "2026-02-19"
    final savedDate = await _storage.read(key: _keyQuestionsDate);
    if (savedDate != today) {
      await _storage.write(key: _keyQuestionsDate, value: today);
      await _storage.write(key: _keyQuestionsCount, value: '0');
    }
  }
}
