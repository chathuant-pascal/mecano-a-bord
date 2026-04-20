// ai_conversation_service_test.dart — MODULE 9 — Mécano à Bord
//
// Stockage : Map via FlutterSecureStorage.setMockInitialValues (in-memory officiel).
// HTTP : package:http/testing.dart — MockClient (recommandé pour mocker http.Client ;
// Mockito + when(post(any)) pose problème avec le 1er argument Uri en Dart 3).

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mecano_a_bord/services/ai_conversation_service.dart';

/// Même configuration que le service en production (forTesting).
const FlutterSecureStorage kTestSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

/// Date du jour au format YYYY-MM-DD (aligné sur le service).
String todayIsoDate() =>
    DateTime.now().toIso8601String().substring(0, 10);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> secureStore;
  late http.Client mockHttp;
  late AiConversationService service;

  /// Réinitialise la Map + plateforme de test secure storage + service avec deps injectées.
  void resetService() {
    secureStore = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(secureStore);
    mockHttp = MockClient(
      (_) async => http.Response('unexpected HTTP call', 599),
    );
    service = AiConversationService.forTesting(
      storage: kTestSecureStorage,
      httpClient: mockHttp,
    );
  }

  void rebindServiceWithClient(http.Client client) {
    mockHttp = client;
    service = AiConversationService.forTesting(
      storage: kTestSecureStorage,
      httpClient: mockHttp,
    );
  }

  setUp(() {
    resetService();
  });

  // ─── Groupe 1 — Quota gratuit (5 questions, AiLimitReached) ─────────────

  group('1. Quota gratuit', () {
    /// ✅ Cas nominal : première question du jour, réponse locale attendue.
    test('nominal : 1ère question mode gratuit → AiSuccess, remaining = 4', () async {
      secureStore['mab_ai_questions_date'] = todayIsoDate();
      secureStore['mab_ai_questions_count'] = '0';
      // Pas de clé API → mode gratuit.

      final r = await service.ask('vidange');

      expect(r, isA<AiSuccess>());
      final s = r as AiSuccess;
      expect(s.mode, AiMode.free);
      expect(s.remainingFreeQuestions, 4);
      expect(s.text.toLowerCase(), contains('vidange'));
      expect(secureStore['mab_ai_questions_count'], '1');
    });

    /// ❌ Cas erreur : compteur corrompu (très élevé) → pas de crash, blocage quota.
    test('erreur : compteur aberrant → getRemainingFreeQuota 0, ask → AiLimitReached', () async {
      secureStore['mab_ai_questions_date'] = todayIsoDate();
      secureStore['mab_ai_questions_count'] = '999';

      expect(await service.getRemainingFreeQuota(), 0);

      final r = await service.ask('question');
      expect(r, isA<AiLimitReached>());
    });

    /// ⚠️ Cas limite : après 5 questions consommées, la 6e → AiLimitReached.
    test('limite : 6e question du jour → AiLimitReached', () async {
      secureStore['mab_ai_questions_date'] = todayIsoDate();
      secureStore['mab_ai_questions_count'] = '5';

      final r = await service.ask('encore une question');

      expect(r, isA<AiLimitReached>());
      final lim = r as AiLimitReached;
      expect(lim.remainingTomorrow, 5);
    });

    /// ⚠️ Cas limite : 5e question encore acceptée (remaining tombe à 0).
    test('limite : 5e question encore autorisée → AiSuccess, remaining = 0', () async {
      secureStore['mab_ai_questions_date'] = todayIsoDate();
      secureStore['mab_ai_questions_count'] = '4';

      final r = await service.ask('vidange');

      expect(r, isA<AiSuccess>());
      expect((r as AiSuccess).remainingFreeQuestions, 0);
      expect(secureStore['mab_ai_questions_count'], '5');
    });
  });

  // ─── Groupe 2 — Mode personnel ChatGPT (mock HTTP) ────────────────────────

  group('2. Mode personnel — ChatGPT', () {
    void setupPersonalChatGpt() {
      secureStore['mab_ai_provider'] = 'chatgpt';
      secureStore['api_key_chatgpt'] = 'sk-test-key';
    }

    /// ✅ Cas nominal : HTTP 200 + JSON OpenAI valide → AiSuccess.
    test('nominal : 200 → AiSuccess texte extrait', () async {
      setupPersonalChatGpt();
      var posts = 0;
      rebindServiceWithClient(
        MockClient((request) async {
          posts++;
          expect(request.url.host, 'api.openai.com');
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Réponse test ChatGPT'},
                },
              ],
            }),
            200,
          );
        }),
      );

      final r = await service.ask('Bonjour');

      expect(r, isA<AiSuccess>());
      expect((r as AiSuccess).text, 'Réponse test ChatGPT');
      expect(r.mode, AiMode.personal);
      expect(posts, 1);
    });

    /// ❌ Cas erreur : HTTP 401 → AiError clé invalide.
    test('erreur : 401 → AiError clé ChatGPT invalide', () async {
      setupPersonalChatGpt();
      rebindServiceWithClient(
        MockClient((_) async => http.Response('Unauthorized', 401)),
      );

      final r = await service.ask('test');

      expect(r, isA<AiError>());
      expect((r as AiError).message, contains('invalide'));
    });

    /// ⚠️ Cas limite : HTTP 429 → message limite compte.
    test('limite : 429 → AiError quota ChatGPT', () async {
      setupPersonalChatGpt();
      rebindServiceWithClient(
        MockClient((_) async => http.Response('Too Many Requests', 429)),
      );

      final r = await service.ask('test');

      expect(r, isA<AiError>());
      expect((r as AiError).message.toLowerCase(), contains('limite'));
    });
  });

  // ─── Groupe 3 — Mode personnel Gemini (mock HTTP) ─────────────────────────

  group('3. Mode personnel — Gemini', () {
    void setupPersonalGemini() {
      secureStore['mab_ai_provider'] = 'gemini';
      secureStore['api_key_gemini'] = 'gemini-test-key';
    }

    /// ✅ Cas nominal : HTTP 200 + JSON Gemini valide → AiSuccess.
    test('nominal : 200 → AiSuccess texte extrait', () async {
      setupPersonalGemini();
      var posts = 0;
      rebindServiceWithClient(
        MockClient((request) async {
          posts++;
          expect(request.url.host, 'generativelanguage.googleapis.com');
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Réponse test Gemini'},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final r = await service.ask('Question');

      expect(r, isA<AiSuccess>());
      expect((r as AiSuccess).text, 'Réponse test Gemini');
      expect(posts, 1);
    });

    /// ❌ Cas erreur : HTTP 400 → clé Gemini invalide.
    test('erreur : 400 → AiError clé Gemini invalide', () async {
      setupPersonalGemini();
      rebindServiceWithClient(
        MockClient((_) async => http.Response('Bad Request', 400)),
      );

      final r = await service.ask('test');

      expect(r, isA<AiError>());
      expect((r as AiError).message, contains('invalide'));
    });

    /// ⚠️ Cas limite : autre code erreur (ex. 500) → message générique Gemini.
    test('limite : 500 → AiError générique sans crash', () async {
      setupPersonalGemini();
      rebindServiceWithClient(
        MockClient((_) async => http.Response('Server Error', 500)),
      );

      final r = await service.ask('test');

      expect(r, isA<AiError>());
      expect((r as AiError).message, contains('Gemini'));
    });
  });

  // ─── Groupe 4 — Mode démo + askManufacturerReferenceJson ───────────────────

  group('4. Démo + askManufacturerReferenceJson', () {
    /// ✅ Cas nominal : mode démo → réponse locale, pas d’HTTP.
    test('nominal : isDemoMode → AiSuccess sans appel HTTP', () async {
      var posts = 0;
      rebindServiceWithClient(
        MockClient((_) async {
          posts++;
          return http.Response('', 500);
        }),
      );

      final r = await service.ask(
        'Bonjour',
        isDemoMode: true,
      );

      expect(r, isA<AiSuccess>());
      expect((r as AiSuccess).text.toLowerCase(), contains('démo'));
      expect(posts, 0);
    });

    /// ❌ Cas erreur : askManufacturerReferenceJson sans clé API → AiError code.
    test('erreur : manufacturer JSON sans clé → assistant_ia_non_configuré', () async {
      secureStore['mab_ai_provider'] = 'chatgpt';
      // pas de api_key_chatgpt

      final r = await service.askManufacturerReferenceJson(
        marque: 'Renault',
        modele: 'Clio',
        annee: 2018,
        motorisation: 'Diesel',
      );

      expect(r, isA<AiError>());
      expect((r as AiError).message, 'assistant_ia_non_configuré');
    });

    /// ⚠️ Cas limite : clé présente + HTTP 200 JSON constructeur (mock).
    test('limite : manufacturer JSON avec clé + 200 → AiSuccess', () async {
      secureStore['mab_ai_provider'] = 'chatgpt';
      secureStore['api_key_chatgpt'] = 'sk-test';

      rebindServiceWithClient(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': '{"temperature_normale_min":80}',
                  },
                },
              ],
            }),
            200,
          ),
        ),
      );

      final r = await service.askManufacturerReferenceJson(
        marque: 'Peugeot',
        modele: '208',
        annee: 2020,
        motorisation: 'Essence',
      );

      expect(r, isA<AiSuccess>());
      expect((r as AiSuccess).text, contains('temperature_normale_min'));
    });
  });
}
