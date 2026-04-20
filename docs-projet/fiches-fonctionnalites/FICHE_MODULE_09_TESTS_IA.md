# FICHE MODULE 09 — TESTS UNITAIRES SERVICE IA

**Statut** : ✅ **Validé le 19/04/2026**  
**Date** : 19/04/2026  
**Référence projet** : `CLAUDE.md` MODULE 9 — **PRIORITÉ 3** — « Tests unitaires IA service »

**Fichier cible** : `mecano_a_bord/lib/services/ai_conversation_service.dart`  
**Fichier de tests** : `mecano_a_bord/test/ai_conversation_service_test.dart`

**Résultat** : **`flutter test test/ai_conversation_service_test.dart`** — **13 tests verts** ✅

---

## 1. NOM DE LA FONCTIONNALITÉ

**Tests unitaires** sur le service de conversation IA : vérifier sans téléphone réel que le **quota gratuit**, la **sélection / clés des fournisseurs**, et les **réponses d’erreur API** se comportent comme prévu (pas de crash, types de réponse cohérents).

---

## 2. RÔLE EN LANGAGE SIMPLE

Les tests automatisés rejouent des situations (question gratuite, 5ᵉ question du jour, mauvaise clé, pas de réseau) **sans appeler les vraies API**. Ça sécurise les évolutions du fichier et évite les régressions silencieuses.

---

## 3. RÉFÉRENCE CLAUDE.md — MODULE 9

Dans `CLAUDE.md`, section **PRIORITÉ 3 — AMÉLIORATIONS** :

- **MODULE 9** → Tests unitaires IA service  
- **MODULE 10** → Tests unitaires Repository (hors périmètre de cette fiche)

Méthodologie projet : pour les tests — **cas nominal**, **cas d’erreur**, **cas limites**.

---

## 4. FICHIER DE TEST — ÉTAT

| Élément | Résultat |
|--------|----------|
| `mecano_a_bord/test/ai_conversation_service_test.dart` | **Présent** — **13** tests (4 groupes) |
| Autres tests sous `mecano_a_bord/test/` | `widget_test.dart` |

---

## 5. IMPLÉMENTATION TECHNIQUE (VALIDÉE)

### 5.1 Stockage en mémoire (Map)

- **`FlutterSecureStorage.setMockInitialValues(Map<String, String>)`** (API officielle `@visibleForTesting` du package `flutter_secure_storage`) : les lectures / écritures passent par une **`Map`** partagée dans les tests.

### 5.2 HTTP — `MockClient` officiel (`package:http/testing.dart`)

- **`import 'package:http/testing.dart'`** → **`MockClient((request) async => Response(...))`**.
- **Pas de Mockito** sur `http.Client.post` : avec Mockito, `when(mock.post(any, …))` pose problème en **Dart 3** (premier argument **`Uri`** / matchers). Le **`MockClient`** du package **`http`** est la approche recommandée pour les tests.

### 5.3 Service — injection (MODULE 9 code)

- **`AiConversationService.forTesting({ required FlutterSecureStorage storage, required http.Client httpClient })`**  
- Champs **`_httpClient.post`** à la place de **`http.post`** en production ; singleton **`instance`** inchangé pour l’app.

### 5.4 Dépendances dev

- **`mockito`** + **`build_runner`** dans **`pubspec.yaml`** (`dev_dependencies`) — utiles pour d’autres tests ; le fichier IA utilise **`http/testing.dart`** pour le client HTTP.

---

## 6. GROUPES DE TESTS (13 TESTS)

| # | Groupe | Contenu |
|---|--------|---------|
| 1 | **Quota gratuit** | Nominal 1ʳᵉ question ; erreur compteur aberrant ; limite 6ᵉ question ; limite 5ᵉ question (remaining 0). |
| 2 | **ChatGPT** | 200 / 401 / 429 (mock HTTP). |
| 3 | **Gemini** | 200 / 400 / 500 (mock HTTP). |
| 4 | **Démo + manufacturer JSON** | `isDemoMode` ; sans clé ; avec clé + 200. |

---

## 7. JOURNAL

| Date | Étape |
|------|--------|
| 19/04/2026 | Rédaction fiche MODULE 9 — diagnostic, priorités, plan tests. |
| 19/04/2026 | Refacto **`AiConversationService`** : `forTesting` + **`_httpClient`**. |
| 19/04/2026 | Création **`ai_conversation_service_test.dart`** — **13** tests verts ; **`MockClient`** (`http/testing.dart`) + **`setMockInitialValues`**. |
| 19/04/2026 | Fiche validée — **EVOLUTION** / **BACKLOG** mis à jour. |

---

## 8. PROCHAINE ÉTAPE PROJET

- **MODULE 10** — Tests unitaires Repository (`CLAUDE.md`).

---

*Fin de la fiche MODULE 09 — Tests IA service.*
