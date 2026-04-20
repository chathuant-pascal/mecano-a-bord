# FICHE MODULE 05 — LOGGER CONDITIONNEL (`mab_logger`)

**Statut** : ✅ **Validé le 19/04/2026**  
**Référence projet** : `CLAUDE.md` MODULE 5 (PRIORITÉ 2)

---

## 1. NOM DE LA FONCTIONNALITÉ

**Logger MAB** — Remplacement des appels directs à `debugPrint` par une fonction **`mabLog`** qui n’écrit en console qu’en **mode debug** (`kDebugMode`), conformément à l’audit OWASP (pas de logs bruyants en release).

---

## 2. RÔLE EN LANGAGE SIMPLE

L’application peut afficher des messages techniques dans la console pendant le développement pour le débogage. En version « release » (Play Store), ces messages ne doivent pas polluer les journaux ni exposer d’informations inutiles. **`mabLog`** centralise cela : en production, rien n’est imprimé.

---

## 3. FICHIER CRÉÉ

| Fichier | Rôle |
|---|---|
| `lib/utils/mab_logger.dart` | `void mabLog(String message)` — préfixe `[MAB]` ; appelle `debugPrint` uniquement si `kDebugMode` |

---

## 4. FICHIERS MODIFIÉS (13 remplacements dans 7 fichiers)

| Fichier | Occurrences |
|---|---|
| `lib/screens/home_screen.dart` | 6 — erreurs chargement images (`errorBuilder`) |
| `lib/services/bluetooth_obd_service.dart` | 1 — réponse brute protocole OBD (diagnostic) |
| `lib/services/ai_conversation_service.dart` | 1 — erreur ChatGPT (`catch`) |
| `lib/services/vehicle_reference_service.dart` | 2 — erreurs / absence clé IA |
| `lib/screens/formation_web_launch_screen.dart` | 1 — exception `launchUrl` |
| `lib/screens/help_contact_screen.dart` | 2 — `_openUrl` / `_openEmail` |

**Contrôle** : sous `lib/`, seul `mab_logger.dart` contient encore l’identifiant `debugPrint` (implémentation interne).

---

## 5. RÈGLES INTOUCHABLES (PROJET)

- Ne pas réintroduire de `debugPrint` direct dans les écrans / services — utiliser **`mabLog`**.
- **TTS** et autres règles MAB inchangées par ce module.

---

## 6. VALIDATION

| Contrôle | Résultat (19/04/2026) |
|---|---|
| `grep` `debugPrint` dans `lib/` | Uniquement `mab_logger.dart` |
| `dart analyze lib/` | Exécuté — avertissements / infos préexistants hors périmètre MODULE 5 |

---

## 7. JOURNAL

| Date | Étape |
|---|---|
| 19/04/2026 | Création `mab_logger.dart` + remplacement des 13 `debugPrint` + fiche + doc |

---

## 8. CONDITIONS DE TEST RÉALISÉES PAR PASCAL

### 1. MATÉRIEL UTILISÉ

| Élément | Détail |
|---|---|
| Téléphone | Samsung SM-A137F — Android 14 |
| Connexion | USB PC pour logcat |

### 2. ENVIRONNEMENT DE TEST

- Build release (APK non debug) pour vérifier l'absence de logs
- Build debug pour vérifier la présence des `[MAB]` dans logcat

### 3. PROCÉDURE À SUIVRE

1. Build debug — lancer logcat — vérifier présence des `[MAB]` en console
2. Build release — lancer logcat — vérifier absence totale des `[MAB]`

### 4. RÉSULTAT ATTENDU

- En debug : `[MAB]` visible dans logcat ✅
- En release : aucun `[MAB]` dans logcat ✅

### 5. STATUT TEST

| Élément | Détail |
|---|---|
| Statut | ⏳ **En attente test Samsung SM-A137F** |
| Date prévue | À effectuer en conditions réelles |
