# FICHE MODULE 14 — PROVIDERS IA (10 FOURNISSEURS)

**Statut** : ✅ **Validé le 19/04/2026**  
**Date** : 19/04/2026  
**Référence projet** : `CLAUDE.md` MODULE 14 — « Validation 10 providers IA »

**Fichier cible** : `mecano_a_bord/lib/services/ai_conversation_service.dart`  
**Clés** : `storageKeyForProvider` → `api_key_<nom_enum>` (ex. `api_key_claude`, `api_key_chatgpt`).

**Tests de non-régression** : `flutter test test/ai_conversation_service_test.dart` — **13 tests verts** ✅ (MODULE 9).

---

## 1. RÔLE EN LANGAGE SIMPLE

L’utilisateur choisit un assistant dans **Réglages** ; en **mode personnel**, l’app appelle l’API correspondante avec la clé enregistrée dans le stockage sécurisé. **Deux** fournisseurs (**Copilot**, **Meta AI**) n’ont **pas** d’API accessible par clé personnelle dans ce périmètre : l’app affiche un message clair au lieu d’échouer silencieusement.

---

## 2. TABLEAU DES 10 PROVIDERS

| # | Fournisseur | Enum `AiProvider` | Clé secure storage | Statut | Implémentation |
|---|-------------|-------------------|--------------------|--------|----------------|
| 1 | **Claude** (Anthropic) | `claude` | `api_key_claude` | ✅ API | `_callClaude` — `POST https://api.anthropic.com/v1/messages`, modèle `claude-sonnet-4-5-20250929`, en-têtes `x-api-key`, `anthropic-version: 2023-06-01` |
| 2 | **ChatGPT** (OpenAI) | `chatgpt` | `api_key_chatgpt` | ✅ API | `_callChatGpt` — `https://api.openai.com/v1/chat/completions`, modèle `gpt-4o-mini` |
| 3 | **Gemini** (Google) | `gemini` | `api_key_gemini` | ✅ API | `_callGemini` — `generativelanguage.googleapis.com`, modèle `gemini-1.5-flash` |
| 4 | **Mistral** | `mistral` | `api_key_mistral` | ✅ API | `_callMistral` — `https://api.mistral.ai/v1/chat/completions`, modèle `mistral-large-latest` |
| 5 | **Perplexity** | `perplexity` | `api_key_perplexity` | ✅ API | `_callPerplexity` — `https://api.perplexity.ai/chat/completions`, modèle `llama-3.1-sonar-large-128k-online` |
| 6 | **Grok** (xAI) | `grok` | `api_key_grok` | ✅ API | `_callGrok` — `https://api.x.ai/v1/chat/completions`, modèle `grok-2-latest` |
| 7 | **DeepSeek** | `deepseek` | `api_key_deepseek` | ✅ API | `_callDeepSeek` — `https://api.deepseek.com/v1/chat/completions`, modèle `deepseek-chat` |
| 8 | **Qwen** (Alibaba DashScope) | `qwen` | `api_key_qwen` | ✅ API | `_callQwen` — `https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions`, modèle `qwen-plus` |
| 9 | **Copilot** (Microsoft) | `copilot` | `api_key_copilot` *(non utilisée pour l’appel)* | ⚠️ Pas d’API perso | `AiError` **avant** lecture clé : compte entreprise Azure requis ; orientation vers un autre assistant |
| 10 | **Meta AI** | `meta_ai` | `api_key_meta_ai` *(non utilisée pour l’appel)* | ⚠️ Pas d’API perso | `AiError` **avant** lecture clé : pas d’accès par clé personnelle pour l’instant |

---

## 3. COMPORTEMENT COMMUN (API RÉELLES)

- Timeout **30 s** sur les requêtes HTTP.
- Gestion **401** (clé invalide), **429** (quota), **autres** codes (message générique).
- Erreurs réseau / exception : `mabLog('<PROVIDER> ERROR: …')` + `AiError` avec détail pour debug.

---

## 4. RÉFÉRENCE CROISÉE

- **MODULE 9** : tests unitaires sur ChatGPT / Gemini et logique quota — inchangés après MODULE 14.
- **Réglages** : grille des **10** logos IA ; sélection enregistrée (`mab_ai_provider`).

---

*Fiche MODULE 14 — Mécano à Bord — 19/04/2026*
