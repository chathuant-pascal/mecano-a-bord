# FICHE MODULE 04 — WEBVIEW FORMATION

**Statut** : ✅ **Correctifs BUG-1 à BUG-6 implémentés** (tests terrain MODULE 4 à faire en fin de lot)  
**Date diagnostic** : 19/04/2026  
**Fichier principal** : `mecano_a_bord/lib/screens/formation_webview_screen.dart`  
**URL formation (constante)** : `mecano_a_bord/lib/formation_url.dart` — `kFormationUrl`  
**Référence projet** : `CLAUDE.md` MODULE 4 (PRIORITÉ 2)

---

## 1. NOM DE LA FONCTIONNALITÉ

**Écran WebView « Ta Voiture Sans Galère »** — Affichage de la formation web dans l’app après l’onboarding, avec pont JavaScript `MABFormation` pour marquer la formation comme terminée et passer à l’accueil.

---

## 2. RÔLE EN LANGAGE SIMPLE

L’utilisateur suit la formation dans une page web intégrée à l’application. Quand la page envoie le signal prévu (`done`), l’app enregistre que la formation est faite et affiche l’écran d’accueil. Un minuteur vérifie aussi périodiquement cette information au cas où le pont JS ne suffit pas.

---

## 3. FICHIERS CONCERNÉS

| Fichier | Rôle |
|---|---|
| `lib/screens/formation_webview_screen.dart` | WebView, canal JS, minuteur, navigation vers `HomeScreen` |
| `lib/formation_url.dart` | URL unique de la formation (`kFormationUrl`) |
| `lib/screens/formation_web_launch_screen.dart` | Référence `url_launcher` + `LaunchMode.externalApplication` (ouverture externe) |

---

## 4. RÈGLES INTOUCHABLES (PROJET)

- **Design** : uniquement `MabColors` / `MabTextStyles` / `MabDimensions` (`lib/theme/mab_theme.dart`).
- **Zones tactiles** : minimum 48 dp sur les actions (boutons, etc.).
- **Mots interdits** dans les textes UI : `panne` / `danger` / `défaillance`.
- **TTS** : ne pas modifier `tts_service.dart` dans le cadre de ce module.

---

## 5. DIAGNOSTIC — BUGS IDENTIFIÉS

| ID | Gravité | Description | Correction prévue |
|---|---|---|---|
| BUG-1 | Critique | Pas de `NavigationDelegate` : toute URL peut se charger dans la WebView. | Allowlist stricte : `mecanoabord.fr` (et sous-domaines), `chathuant-pascal.github.io` ; autres URLs → `launchUrl` en navigateur externe (`LaunchMode.externalApplication`). |
| BUG-2 | Critique | Le canal `MABFormation` accepte `done` sans vérifier la page d’origine. | Avant traitement, vérifier que l’URL courante du contrôleur est sur un hôte autorisé (même logique que BUG-1). |
| BUG-3 | Critique | `loadRequest` non protégé. | `try/catch` + état d’erreur (ex. `_loadError`) pour affichage contrôlé. |
| BUG-4 | Important | Pas de feedback si la page ne charge pas (réseau). | `onWebResourceError` + message rassurant + bouton « Réessayer » (tokens MAB). |
| BUG-5 | Important | Minuteur périodique actif en arrière-plan. | Annuler sur `paused` / `inactive`, relancer sur `resumed` (cohérent avec le cycle de vie). |
| BUG-6 | Cosmétique | Pas d’indicateur de chargement. | Spinner ou équivalent via `onPageStarted` / `onPageFinished`. |

---

## 6. ALLOWLIST — DÉTAIL TECHNIQUE (BUG-1 / BUG-2)

- **Autorisé** : hôte exact `mecanoabord.fr` ou tout hôte se terminant par `.mecanoabord.fr` (ex. `www.mecanoabord.fr`).
- **Autorisé** : hôte exact `chathuant-pascal.github.io` (GitHub Pages du dépôt).
- **Schémas** : pour la navigation dans la WebView, n’autoriser en principe que `https:` et `http:` (les autres schémas ne se chargent pas comme du web classique).
- **Hors liste** : ne pas charger dans la WebView ; tenter `launchUrl(..., mode: LaunchMode.externalApplication)` comme pour `formation_web_launch_screen.dart`.

**Note développement local** : si `kFormationUrl` pointe vers une IP locale (`192.168.x.x`), elle ne sera pas sur l’allowlist stricte — prévoir un contournement documenté (URL de prod, ou règle de debug explicite si demandée par Pascal).

---

## 7. PLAN DE VALIDATION

1. Valider BUG-1 (navigation + domaines) — terrain : liens internes OK, lien externe s’ouvre hors WebView.
2. Enchaîner BUG-2 → BUG-6 dans l’ordre convenu, avec accord explicite entre étapes si demandé.
3. Tester sur Samsung SM-A137F (Android 14) : chargement, absence réseau, retour avant-plan / arrière-plan.

---

## 8. JOURNAL DES MODIFICATIONS

| Date | Étape | Résumé |
|---|---|---|
| 19/04/2026 | Rédaction fiche | Diagnostic consolidé + plan BUG-1 à BUG-6. |
| 19/04/2026 | BUG-1 appliqué | `NavigationDelegate` + `_isAllowedFormationHost` + `launchUrl` externe hors allowlist (`mecanoabord.fr`, `chathuant-pascal.github.io`). |
| 19/04/2026 | BUG-2 appliqué | Canal `MABFormation` : `currentUrl()` + `Uri` + même allowlist avant `SharedPreferences` / `_checkFormationDone`. |
| 19/04/2026 | BUG-3 appliqué | `_loadFormationPage()` : `try/catch` sur `Uri.parse` + `loadRequest`, état `_loadError`, `unawaited` depuis `initState`, message utilisateur si échec. |
| 19/04/2026 | BUG-4 appliqué | `onWebResourceError` (cadre principal) + message + bouton « Réessayer » (`retry: true` → réinitialise `_loadError` puis `loadRequest`). |
| 19/04/2026 | BUG-5 appliqué | `_startPollTimer()` ; annulation du minuteur sur `inactive` / `paused` / `hidden` / `detached` ; relance sur `resumed` + `_checkFormationDone`. |
| 19/04/2026 | BUG-6 appliqué | `_pageLoading` + `onPageStarted` / `onPageFinished` ; overlay `CircularProgressIndicator` (`MabColors.rouge`) + voile `MabColors.noir` semi-transparent ; cohérence avec erreurs / réessai. |

*(À compléter après chaque correctif validé.)*
