# FICHE MODULE 07 — TRY/CATCH (ROBUSTESSE STOCKAGE & FICHIERS)

**Statut** : ✅ **Terminé** (2026-04-19)  
**Date diagnostic** : 19/04/2026  
**Référence projet** : `CLAUDE.md` MODULE 7 (PRIORITÉ 2)

---

## 1. NOM DE LA FONCTIONNALITÉ

**Protections try/catch** sur opérations à risque : **SharedPreferences**, **SQLite**, **ImagePicker / FilePicker**, **OpenFile** — pour éviter plantages ou états incohérents sans message.

---

## 2. RÔLE EN LANGAGE SIMPLE

Si le téléphone refuse le stockage des préférences, si la base locale pose problème, ou si l’utilisateur refuse la caméra / l’accès fichiers, l’app ne doit pas « planter » sans explication. Les **`try/catch`** permettent de gérer l’erreur proprement (log technique en debug via **`mabLog`**, comportement utilisateur défini fichier par fichier).

---

## 3. POINTS IDENTIFIÉS (ORDRE DE TRAITEMENT)

| # | Fichier | Zone | Risque si non géré |
|---|---------|------|---------------------|
| 1 | `lib/main.dart` | `SplashRouting._route()` — `SharedPreferences.getInstance()` ~L117 | Crash ou blocage au démarrage |
| 2 | `lib/screens/onboarding_screen.dart` | `getInstance()` + `setBool` ~L119-120 | Onboarding / préférences incohérents |
| 3 | `lib/screens/onboarding_screen.dart` | `hasSeenOnboarding()` — `getInstance()` ~L386 | Même famille |
| 4 | `lib/screens/add_maintenance_screen.dart` | `getMaintenanceEntryById()` SQLite ~L301 | Formulaire vide sans explication |
| 5 | `lib/screens/glovebox_screen.dart` | `pickImage()` caméra ~L358 | `PlatformException` (permission) |
| 6 | `lib/screens/glovebox_screen.dart` | `FilePicker.pickFiles()` ~L377 | `PlatformException` |
| 7 | `lib/screens/glovebox_screen.dart` | `OpenFile.open()` ~L580 | Échec ouverture fichier |

---

## 4. RÈGLES PROJET

- Logger les erreurs techniques avec **`mabLog`** (pas de `debugPrint` direct).
- Messages utilisateur : langage simple, **mots interdits** du projet (`panne`, `danger`, `défaillance`).
- UI : **`MabColors` / `MabTextStyles` / `MabDimensions`** si SnackBar ou dialogue.

---

## 5. JOURNAL

| Date | Étape |
|---|---|
| 19/04/2026 | Rédaction fiche + plan corrections ordre **main.dart** → … |
| 19/04/2026 | `main.dart` | `SplashRouting._route()` : `try/catch` + `mabLog` sur `SharedPreferences.getInstance()` ; fallback `onboardingDone = false`. |
| 19/04/2026 | `onboarding_screen.dart` | `_finishOnboarding()` : `try/catch` sur prefs + `setBool` ; navigation formation conservée. `hasSeenOnboarding()` : `try/catch`, retour `false` si erreur. |
| 19/04/2026 | `add_maintenance_screen.dart` | `_loadExistingEntry` : `try/catch` sur `getMaintenanceEntryById` ; `SnackBar` si erreur. |
| 19/04/2026 | `glovebox_screen.dart` | `_addFromCamera` : `try/catch` sur `pickImage`. `_addFromFile` : `try/catch` sur `pickFiles`. `_DocumentCard._openDocument` : `try/catch` sur `OpenFile.open`. |

**Validation** : `dart analyze lib/screens/glovebox_screen.dart` sans erreur ; `dart analyze lib/` : aucune erreur (warning connu `obd_scan_screen` champ non utilisé ; infos style/dépréciations préexistants).
