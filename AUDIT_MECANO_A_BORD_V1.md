# AUDIT COMPLET — MÉCANO À BORD V1
### Base de travail pour Inès — Corrections fonctionnalité par fonctionnalité
### Généré le 16 avril 2026 — Version 1.0.0+14
### © Pascal Chathuant — Guadeloupe — mecanoabord@gmail.com

---

> **Méthodologie de travail obligatoire (CLAUDE.md v3.0)**
> Pour chaque fonctionnalité : Audit → Développer → Try/Catch → OWASP → UX → Tests → Valider → Commit

---

## RÉSUMÉ EXÉCUTIF

| Catégorie | Score | État |
|---|---|---|
| Fonctionnalités implémentées | 18/18 | ✅ Toutes présentes |
| Try/Catch couverts | ~60% | ⚠️ Incomplet |
| Tests unitaires réels | 1/18 | 🚨 Quasi inexistants |
| Feature Flags | 0/18 | 🚨 Aucun |
| Architecture MVC | 0/18 | 🚨 Non appliquée |
| Sécurité OWASP | 3 problèmes critiques | 🚨 À traiter |
| Logs en mode release | 16 debugPrint actifs | 🚨 À nettoyer |
| Signature release | Debug signing | 🚨 BLOQUANT |

---

## SECTION 1 — LISTE COMPLÈTE DES FONCTIONNALITÉS

### 1.1 Splash Screen / Routing initial

| Critère | État |
|---|---|
| **Fichier** | `lib/main.dart` — classe `SplashRouting` |
| **Statut** | ✅ OK |
| **Try/Catch** | ❌ NON — `prefs.getBool()` non protégé |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON — tout dans le widget |

**Problèmes détectés :**
- Lecture SharedPreferences (`prefs.getBool('onboarding_done')`) sans try/catch — si SharedPreferences corrompu, l'app plante au démarrage
- Pas de timeout sur la lecture prefs (blocage possible)

---

### 1.2 Onboarding (première ouverture)

| Critère | État |
|---|---|
| **Fichier** | `lib/screens/onboarding_screen.dart` |
| **Statut** | ✅ OK — 2 phases (acceptation + carrousel 5 pages) |
| **Try/Catch** | ❌ NON — `prefs.setBool()` non protégé |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

**Problèmes détectés :**
- `prefs.setBool('onboarding_done', true)` sans try/catch — si SharedPreferences écrit échoue, l'onboarding recommence à l'infini
- Pas de gestion si `assets/images/onboarding_page1.png` est absent (pas d'errorBuilder)
- Consentement implicite (clic bouton) : pas de case à cocher explicite

---

### 1.3 Formation WebView (post-onboarding)

| Critère | État |
|---|---|
| **Fichier** | `lib/screens/formation_webview_screen.dart` |
| **Statut** | ⚠️ Fonctionne mais problèmes de sécurité |
| **Try/Catch** | ❌ NON — `loadRequest()` sans gestion d'erreur |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

**Problèmes détectés :**
- 🚨 **Pas de NavigationDelegate** — la WebView peut naviguer vers n'importe quel domaine externe si un lien est cliqué dans la formation
- 🚨 **Canal JS `MABFormation` non sécurisé** — n'importe quelle page peut envoyer `MABFormation.postMessage('done')` et déclencher le déblocage si l'URL change
- Polling toutes les 2 secondes (`Timer.periodic`) même quand l'app est en arrière-plan — consommation batterie inutile
- Pas de message d'erreur si le chargement de la formation échoue (pas de connexion internet)

---

### 1.4 Accueil (HomeScreen)

| Critère | État |
|---|---|
| **Fichier** | `lib/screens/home_screen.dart` |
| **Statut** | ✅ OK — 7 bandeaux fonctionnels |
| **Try/Catch** | ❌ NON — `_loadData()` sans try/catch global |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

**Problèmes détectés :**
- `_loadData()` appelle 5 méthodes repository sans try/catch global — si SQLite corrompu, accueil plante au chargement
- `UpdateCheckService.instance.checkForUpdateAndPromptIfNeeded()` appelé dans `addPostFrameCallback` — si l'appel réseau échoue, rien n'est affiché à l'utilisateur (silent fail)
- 6 `debugPrint` actifs dans ce fichier (informations internes exposées en release)

---

### 1.5 Profil Véhicule

| Critère | État |
|---|---|
| **Fichier** | `lib/screens/glovebox_profile_screen.dart` |
| **Statut** | ✅ OK — lookup plaque + validation VIN |
| **Try/Catch** | ⚠️ PARTIEL — API plaque protégée, mais sauvegarde SQLite non |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

**Problèmes détectés :**
- Appel API plaque avec timeout 10s ✅ — mais pas de retry automatique
- Sauvegarde profil (insertOrUpdate SQLite) sans try/catch → si disque plein, l'app plante silencieusement
- Validation VIN uniquement par longueur (17 chars) — pas de validation du checksum algorithme VIN
- `debugPrint` présents dans le fichier (logs internes visibles en release)

---

### 1.6 Boîte à Gants (5 onglets)

| Critère | État |
|---|---|
| **Fichier** | `lib/screens/glovebox_screen.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ⚠️ PARTIEL — 2 try/catch sur 10+ opérations |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

---

### 1.7 Documents (onglet Boîte à gants)

| Critère | État |
|---|---|
| **Fichier** | `lib/screens/glovebox_screen.dart` + `lib/data/mab_repository.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

**Problèmes détectés :**
- Ajout de fichier (image_picker / file_picker) sans gestion du cas "stockage plein"
- Ouverture document (open_file) sans try/catch — si l'app associée au MIME type est absente, exception non gérée
- Pas de limite de taille de fichier — un PDF de 500 Mo peut être stocké

---

### 1.8 Carnet d'entretien

| Critère | État |
|---|---|
| **Fichier** | `lib/screens/add_maintenance_screen.dart` |
| **Statut** | ✅ OK — 28 types, 6 catégories |
| **Try/Catch** | ⚠️ PARTIEL — 1 try/catch détecté |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

---

### 1.9 Connexion OBD Bluetooth

| Critère | État |
|---|---|
| **Fichier** | `lib/services/bluetooth_obd_service.dart` |
| **Statut** | ✅ OK — SPP, détection protocole |
| **Try/Catch** | ⚠️ PARTIEL — 12 try/catch sur les opérations critiques |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

**Problèmes détectés :**
- 🚨 **`debugPrint('OBD protocole $i: réponse brute = $rawResponse')` ligne 313** — logs OBD bruts actifs en mode release — fuite d'informations techniques
- Bluetooth classique SPP uniquement — Bluetooth LE non supporté (prévu V2)

---

### 1.10 Diagnostic OBD

| Critère | État |
|---|---|
| **Fichier** | `lib/screens/obd_scan_screen.dart` |
| **Statut** | 🚨 BUG — écran diagnostic signalé défaillant (CLAUDE.md) |
| **Try/Catch** | ⚠️ PARTIEL — 4 try/catch |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

**Problèmes détectés :**
- 🚨 Bug rapporté dans CLAUDE.md : "Écran diagnostic ne fonctionne plus" — analyser avec `adb logcat -s flutter`
- DTC clearing (effacement codes) sans confirmation utilisateur suffisamment explicite sur les conséquences

---

### 1.11 Mode Conduite (Surveillance temps réel)

| Critère | État |
|---|---|
| **Fichier** | `lib/screens/surveillance_only_screen.dart` + `lib/services/live_monitoring_service.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

---

### 1.12 Assistant IA

| Critère | État |
|---|---|
| **Fichier** | `lib/screens/ai_chat_screen.dart` + `lib/services/ai_conversation_service.dart` |
| **Statut** | ✅ OK — quota 5/jour + 10 providers |
| **Try/Catch** | ✅ OUI — appels API protégés dans ai_conversation_service |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

**Problèmes détectés :**
- 8 des 10 providers IA implémentés mais seulement 2 testés (OpenAI, Gemini) — les autres peuvent avoir des erreurs silencieuses
- System prompt hardcodé dans le service (pas de fichier de config externe)
- Quota stocké dans SharedPreferences (non chiffré) — modifiable manuellement sur Android rooté

---

### 1.13 Santé Véhicule

| Critère | État |
|---|---|
| **Fichier** | `lib/services/vehicle_health_service.dart` + `lib/widgets/glovebox_vehicle_health_tab.dart` |
| **Statut** | ✅ OK — seuils apprentissage 14 jours |
| **Try/Catch** | ⚠️ PARTIEL — 2 try/catch |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

---

### 1.14 Coach Vocal (TTS)

| Critère | État |
|---|---|
| **Fichier** | `lib/services/tts_service.dart` |
| **Statut** | ✅ OK — voix F/M, alertes OBD |
| **Try/Catch** | ⚠️ PARTIEL — 1 try/catch |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

---

### 1.15 Paramètres

| Critère | État |
|---|---|
| **Fichier** | `lib/screens/settings_screen.dart` |
| **Statut** | ✅ OK — 4 sections |
| **Try/Catch** | ⚠️ PARTIEL — 3 try/catch |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

---

### 1.16 Mentions légales / Confidentialité / Aide

| Critère | État |
|---|---|
| **Fichiers** | `legal_mentions_screen.dart`, `privacy_policy_screen.dart`, `help_contact_screen.dart` |
| **Statut** | ⚠️ SIRET manquant dans mentions légales |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

---

### 1.17 Vérification de mise à jour

| Critère | État |
|---|---|
| **Fichier** | `lib/services/update_check_service.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ✅ OUI — 2 try/catch sur les appels réseau |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

---

### 1.18 Mode Démo

| Critère | État |
|---|---|
| **Fichiers** | `lib/data/demo_data.dart` + integration dans tous les écrans |
| **Statut** | ✅ OK |
| **Try/Catch** | N/A — données statiques |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

---

## SECTION 2 — AUDIT SÉCURITÉ OWASP

### OWASP-01 — Stockage de données sensibles non sécurisé

| Détail | |
|---|---|
| **Niveau** | 🟡 Mineur |
| **Fichier** | `lib/services/ai_conversation_service.dart` |
| **Description** | Le compteur de quota IA gratuit (`mab_ai_questions_count` + `mab_ai_questions_date`) est stocké dans **SharedPreferences non chiffré**. Sur un appareil Android rooté, un utilisateur peut réinitialiser son quota à 0 manuellement et ainsi obtenir des questions illimitées gratuitement. |
| **Solution** | Déplacer le compteur quota vers **FlutterSecureStorage** (déjà utilisé pour les clés API). Ou implémenter une vérification côté serveur via Firebase quand le système de licence sera en place. |

---

### OWASP-02 — WebView sans NavigationDelegate (injection de contenu)

| Détail | |
|---|---|
| **Niveau** | 🟠 Important |
| **Fichier** | `lib/screens/formation_webview_screen.dart` |
| **Description** | La WebView qui charge la formation n'a pas de `NavigationDelegate`. Si un lien externe est présent dans la formation (même accidentellement), l'utilisateur peut naviguer vers n'importe quel domaine sans restriction dans la WebView. De plus, le canal JS `MABFormation.postMessage('done')` n'est pas lié à un domaine autorisé : si un attaquant réussit à faire charger une page externe dans la WebView, il peut envoyer `'done'` et débloquer l'app sans que l'utilisateur ait vraiment terminé la formation. |
| **Solution** | Ajouter un `NavigationDelegate` avec une allowlist stricte (ex. `github.io`, `mecanoabord.fr`). Bloquer toute navigation hors domaine autorisé. Vérifier dans le handler JS que l'URL source appartient bien au domaine de la formation. |

```dart
// SOLUTION RECOMMANDÉE
_controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setNavigationDelegate(NavigationDelegate(
    onNavigationRequest: (request) {
      final host = Uri.tryParse(request.url)?.host ?? '';
      if (host.contains('mecanoabord.fr') ||
          host.contains('github.io')) {
        return NavigationDecision.navigate;
      }
      // Ouvrir les liens externes dans le navigateur, pas dans la WebView
      launchUrl(Uri.parse(request.url));
      return NavigationDecision.prevent;
    },
  ))
  ..addJavaScriptChannel('MABFormation', onMessageReceived: ...);
```

---

### OWASP-03 — Logs actifs en mode release (fuite d'informations)

| Détail | |
|---|---|
| **Niveau** | 🟠 Important |
| **Fichiers** | 7 fichiers — total 16 `debugPrint` actifs |
| **Description** | `debugPrint()` en Flutter n'est **pas désactivé en mode release** contrairement à `print()`. Ces logs exposent des données techniques : réponses brutes OBD (`debugPrint('OBD protocole $i: réponse brute = $rawResponse')`), erreurs URL, états internes. Sur Android, ces logs sont lisibles via `adb logcat` par n'importe qui ayant accès à l'appareil. |

**Liste des fichiers avec debugPrint :**

| Fichier | Occurrences | Contenu exposé |
|---|---|---|
| `home_screen.dart` | 6 | États OBD, navigation |
| `bluetooth_obd_service.dart` | 1 | Réponses brutes OBD 🚨 |
| `ai_conversation_service.dart` | 1 | Erreurs appels IA |
| `vehicle_reference_service.dart` | 4 | Références véhicule |
| `formation_web_launch_screen.dart` | 1 | Erreurs URL |
| `help_contact_screen.dart` | 2 | Erreurs URL |
| `mab_repository.dart` | 1 | Erreurs base de données |

| **Solution** | Remplacer tous les `debugPrint` par un logger conditionnel |

```dart
// SOLUTION RECOMMANDÉE — lib/utils/mab_logger.dart
void mabLog(String message) {
  if (kDebugMode) {
    debugPrint('[MAB] $message');
  }
}
```

---

### OWASP-04 — Application ID par défaut (identification Play Store)

| Détail | |
|---|---|
| **Niveau** | 🔴 Critique |
| **Fichier** | `android/app/build.gradle.kts` ligne 9 |
| **Description** | L'`applicationId` est `"com.example.mecano_a_bord"` — le préfixe `com.example` est réservé aux applications de test et **sera rejeté par le Play Store**. De plus, cet ID est identique à ce que tous les projets Flutter créent par défaut, ce qui crée un risque de conflit et d'identification. |
| **Solution** | Changer en `"fr.mecanoabord.app"` avant la première publication. **⚠️ Ce changement est irréversible après publication — ne pas changer après.** |

---

### OWASP-05 — Signature de release avec clé debug

| Détail | |
|---|---|
| **Niveau** | 🔴 Critique |
| **Fichier** | `android/app/build.gradle.kts` ligne 37 |
| **Description** | `signingConfig = signingConfigs.getByName("debug")` — l'APK release est signé avec la clé debug temporaire de Flutter. **Cette APK ne peut pas être publiée sur le Play Store** et peut être remplacée par n'importe qui (pas d'authenticité garantie). |
| **Solution** | Générer un keystore permanent et configurer la signature release. **Mission 1 d'Inès.** |

---

### OWASP-06 — Permission CAMERA sans justification d'usage

| Détail | |
|---|---|
| **Niveau** | 🟡 Mineur |
| **Fichier** | `android/app/src/main/AndroidManifest.xml` ligne 7 |
| **Description** | `CAMERA` est déclarée mais son usage n'est pas explicitement justifié dans le manifest. Sur Android 14 (Play Store policy 2024), les permissions caméra et micro doivent avoir une déclaration `android:required="false"` si elles ne sont pas essentielles, et une justification dans la fiche Play Store. |
| **Solution** | Ajouter `android:required="false"` et s'assurer que la permission est demandée uniquement au moment de l'ajout de photo dans la Boîte à gants. |

---

## SECTION 3 — AUDIT UX

### Écran 1 — Splash Screen

| | |
|---|---|
| **Problèmes UX** | Le spinner tourne sans message — l'utilisateur ne sait pas si l'app charge, plante ou attend |
| **Recommandation** | Ajouter un texte discret sous le logo : "Chargement en cours…" avec un délai max visible de 3 secondes |

---

### Écran 2 — Onboarding Phase 1 (Acceptation)

| | |
|---|---|
| **Problèmes UX** | Texte légal affiché en corps normal sans mise en valeur. Le bouton "J'accepte et je commence" ne fait pas comprendre ce que l'utilisateur accepte exactement |
| **Recommandation** | Mettre en gras les mots clés du texte d'acceptation. Ajouter un résumé visuel en 3 points (✅ Vos données restent sur votre téléphone, ✅ Aucun abonnement automatique, ✅ Vous pouvez tout supprimer). |

---

### Écran 3 — Formation WebView

| | |
|---|---|
| **Problèmes UX** | Aucun message si la connexion internet est absente. L'utilisateur voit une page blanche sans explication. Pas de bouton "Réessayer". |
| **Recommandation** | Ajouter un message d'erreur avec bouton "Réessayer" en cas d'échec de chargement de la WebView. |

---

### Écran 4 — Accueil (HomeScreen)

| | |
|---|---|
| **Problèmes UX** | 7 bandeaux identiques en hauteur — aucune hiérarchie visuelle. Un débutant ne sait pas par où commencer. |
| **Recommandation** | Mettre en avant le bandeau "Diagnostic" ou "Boîte à gants" avec une taille ou couleur différente pour guider le premier usage. Ajouter une info-bulle "Premier démarrage ? Commencez par créer votre profil véhicule." si aucun profil n'existe. |

---

### Écran 5 — Profil Véhicule

| | |
|---|---|
| **Problèmes UX** | Le champ VIN (17 caractères) n'explique pas où trouver le VIN. Un débutant ne sait pas ce que c'est. |
| **Recommandation** | Ajouter sous le champ VIN : "Où trouver le VIN ? Sur la carte grise, rubrique E. Ou sur la plaque dans le pare-brise côté conducteur." avec une icône d'aide. |

---

### Écran 6 — Boîte à gants

| | |
|---|---|
| **Problèmes UX** | Les 5 onglets sont des labels texte courts — un débutant ne comprend pas "Santé" vs "Historique" vs "Carnet" |
| **Recommandation** | Ajouter des icônes aux onglets + une description courte au premier affichage de chaque onglet (tooltip ou dialog d'info). |

---

### Écran 7 — Diagnostic OBD

| | |
|---|---|
| **Problèmes UX** | 🚨 Bug signalé — l'écran ne fonctionne plus. En dehors du bug, les codes DTC (P0300, B0020…) ne sont pas expliqués en français au premier affichage. |
| **Recommandation** | Après correction du bug, s'assurer que chaque code DTC affiché comporte une description en français. Ajouter un bouton "Que faire maintenant ?" après chaque diagnostic. |

---

### Écran 8 — Mode Conduite

| | |
|---|---|
| **Problèmes UX** | Les seuils d'alerte (°C, V, RPM) sont techniques. Un conducteur novice ne sait pas si "95°C de liquide de refroidissement" c'est normal ou inquiétant. |
| **Recommandation** | Afficher les valeurs avec une couleur (vert/orange/rouge) ET une phrase simple : "✅ Température normale" ou "⚠️ Moteur qui chauffe — ralentissez." |

---

### Écran 9 — Assistant IA

| | |
|---|---|
| **Problèmes UX** | Message "Profil véhicule incomplet" affiché mais bouton de correction peu visible. La limite de 5 questions/jour peut frustrer sans explication claire de comment l'augmenter. |
| **Recommandation** | Rendre le bouton "Compléter mon profil" plus visible (bouton rouge plein, pas discret). Expliquer clairement comment connecter son propre assistant IA pour les questions illimitées. |

---

### Écran 10 — Paramètres

| | |
|---|---|
| **Problèmes UX** | Section "Assistant IA" avec 10 providers en accordéon — un débutant ne sait pas quel provider choisir. |
| **Recommandation** | Ajouter une recommandation par défaut : "Pour commencer, nous recommandons ChatGPT (OpenAI)." avec un lien vers la documentation pour obtenir une clé API. |

---

### Écran 11 — Guide Diagnostic

| | |
|---|---|
| **Problèmes UX** | ✅ Bon écran pédagogique — rien à signaler |

---

## SECTION 4 — BUGS CONNUS ET PROBLÈMES TECHNIQUES

### BUG-01 — Écran diagnostic défaillant

| | |
|---|---|
| **Priorité** | 🚨 P1 — Bloquant |
| **Fichier** | `lib/screens/obd_scan_screen.dart` |
| **Symptôme** | L'écran diagnostic ne fonctionne plus (signalé dans CLAUDE.md) |
| **Comment investiguer** | Brancher Samsung SM-A137F en USB + `adb logcat -s flutter` + ouvrir l'écran diagnostic |
| **Cause probable** | Régression liée aux modifications du 09/04/2026 (corrections TTS/dongle) ou incompatibilité avec la nouvelle version de `bluetooth_obd_service.dart` |

---

### BUG-02 — Signature release avec clé debug

| | |
|---|---|
| **Priorité** | 🚨 P1 — Bloquant (Play Store) |
| **Fichier** | `android/app/build.gradle.kts` ligne 37 |
| **Symptôme** | `signingConfig = signingConfigs.getByName("debug")` |
| **Correction** | Mission 1 Inès : générer keystore .jks + configurer build.gradle.kts |

---

### BUG-03 — ApplicationId com.example

| | |
|---|---|
| **Priorité** | 🚨 P1 — Bloquant (Play Store) |
| **Fichier** | `android/app/build.gradle.kts` ligne 9 |
| **Symptôme** | `applicationId = "com.example.mecano_a_bord"` |
| **Correction** | Changer en `"fr.mecanoabord.app"` AVANT première publication |

---

### BUG-04 — WebView sans NavigationDelegate

| | |
|---|---|
| **Priorité** | 🟠 P2 — Sécurité |
| **Fichier** | `lib/screens/formation_webview_screen.dart` |
| **Symptôme** | Navigation libre vers tout domaine + canal JS non restreint |
| **Correction** | Ajouter `NavigationDelegate` avec allowlist (voir Section 2, OWASP-02) |

---

### BUG-05 — Logs OBD bruts actifs en release

| | |
|---|---|
| **Priorité** | 🟠 P2 — Sécurité |
| **Fichier** | `lib/services/bluetooth_obd_service.dart` ligne 313 |
| **Symptôme** | `debugPrint('OBD protocole $i: réponse brute = $rawResponse')` |
| **Correction** | Remplacer par `if (kDebugMode) debugPrint(...)` ou logger conditionnel |

---

### BUG-06 — Absence de try/catch sur SharedPreferences critiques

| | |
|---|---|
| **Priorité** | 🟠 P2 |
| **Fichiers** | `main.dart`, `onboarding_screen.dart`, `formation_webview_screen.dart` |
| **Symptôme** | Crash potentiel au démarrage si SharedPreferences corrompu |
| **Correction** | Encapsuler toutes les lectures/écritures SharedPreferences dans try/catch |

---

### BUG-07 — Aucun test unitaire réel

| | |
|---|---|
| **Priorité** | 🟡 P3 |
| **Fichier** | `test/widget_test.dart` |
| **Symptôme** | 1 seul smoke test qui charge `MabApp()` — aucune vérification de logique métier |
| **Correction** | Écrire les tests unitaires fonctionnalité par fonctionnalité selon la méthodologie CLAUDE.md |

---

### BUG-08 — Aucun Feature Flag

| | |
|---|---|
| **Priorité** | 🟡 P3 |
| **Symptôme** | Impossible de désactiver une fonctionnalité sans mise à jour |
| **Correction** | Créer `lib/config/mab_features.dart` avec constantes `kFeature*` pour chaque module |

---

### BUG-09 — Architecture non MVC

| | |
|---|---|
| **Priorité** | 🟡 P3 |
| **Symptôme** | Logique métier mélangée dans les widgets (setState direct, appels repository depuis les écrans) |
| **Correction** | Restructurer progressivement selon la méthodologie : `backend/` → `frontend/` → `tests/` par module |

---

### BUG-10 — SIRET absent dans mentions légales

| | |
|---|---|
| **Priorité** | 🟡 P3 |
| **Fichier** | `lib/screens/legal_mentions_screen.dart` |
| **Symptôme** | SIRET manquant — non conforme RGPD et obligations légales e-commerce |
| **Correction** | Pascal doit fournir son SIRET — l'ajouter dans `legal_mentions_screen.dart` et `lib/widgets/mab_legal_mentions_body.dart` |

---

## SECTION 5 — DÉPENDANCES ET PACKAGES

### Packages de production (17 packages)

| Package | Version déclarée | Dernière stable | Android 14 ✅ | Alerte |
|---|---|---|---|---|
| `shared_preferences` | ^2.2.2 | 2.3.x | ✅ | Mettre à jour |
| `sqflite` | ^2.3.0 | 2.4.x | ✅ | Mettre à jour |
| `path` | ^1.8.3 | 1.9.x | ✅ | OK |
| `intl` | ^0.19.0 | 0.19.x | ✅ | OK |
| `flutter_secure_storage` | ^9.0.0 | 9.2.x | ✅ | Mettre à jour |
| `http` | ^1.2.0 | 1.3.x | ✅ | Mettre à jour |
| `package_info_plus` | ^8.0.0 | 8.1.x | ✅ | OK |
| `url_launcher` | ^6.2.0 | 6.3.x | ✅ | Mettre à jour |
| `path_provider` | ^2.1.1 | 2.1.x | ✅ | OK |
| `open_file` | ^3.3.2 | 3.5.x | ✅ | ⚠️ Mettre à jour (sécurité) |
| `image_picker` | ^1.0.7 | 1.1.x | ✅ | Mettre à jour |
| `file_picker` | ^8.0.0 | 8.1.x | ✅ | OK |
| `flutter_reactive_ble` | ^5.2.3 | 5.4.x | ✅ | ⚠️ Vérifier compat Android 14 |
| `permission_handler` | ^11.3.0 | 11.4.x | ✅ | Mettre à jour |
| `flutter_tts` | ^4.2.0 | 4.2.x | ✅ | OK |
| `speech_to_text` | ^7.0.0 | 7.0.x | ✅ | OK |
| `webview_flutter` | ^4.13.1 | 4.13.x | ✅ | OK |

### Packages de dev (4 packages)

| Package | Version | Usage |
|---|---|---|
| `flutter_test` | SDK | Tests |
| `flutter_lints` | ^3.0.0 | Qualité code |
| `flutter_native_splash` | ^2.4.7 | Splash screen |
| `flutter_launcher_icons` | ^0.14.4 | Icônes app |

### Packages manquants à ajouter (selon CLAUDE.md)

| Package | Usage prévu | Priorité |
|---|---|---|
| `firebase_core` | Base Firebase | Mission 2 Inès |
| `cloud_firestore` | Système licence | Mission 2 Inès |
| `device_info_plus` | ID appareil pour licence | Mission 2 Inès |
| `logger` | Remplacer debugPrint | P2 |
| `connectivity_plus` | Détecter absence réseau | P2 |

---

## SECTION 6 — PLAN DE TRAVAIL PRIORISÉ

### PRIORITÉ 1 — BLOQUANT (à faire immédiatement avec Inès)

```
P1-01 — Diagnostiquer le bug écran diagnostic
         → adb logcat -s flutter pendant test sur Samsung SM-A137F
         → Fichier : obd_scan_screen.dart

P1-02 — Générer keystore Release (Mission 1 Inès)
         → keytool → build.gradle.kts → flutter build apk --release
         → Sauvegarder keystore Google Drive + copie locale (JAMAIS GitHub)

P1-03 — Changer le package name
         → com.example.mecano_a_bord → fr.mecanoabord.app
         → Avant toute autre publication sur Play Store
```

---

### PRIORITÉ 2 — IMPORTANT (à faire rapidement)

```
P2-01 — Sécuriser la WebView (NavigationDelegate + allowlist)
         → formation_webview_screen.dart
         → Ajouter domaines autorisés : mecanoabord.fr, github.io

P2-02 — Nettoyer tous les debugPrint (→ logger conditionnel)
         → Créer lib/utils/mab_logger.dart
         → Remplacer les 16 debugPrint dans 7 fichiers

P2-03 — Ajouter try/catch sur les opérations critiques manquantes
         → SharedPreferences dans main.dart, onboarding_screen.dart
         → SQLite dans add_maintenance_screen.dart, glovebox_screen.dart
         → Ouverture fichier dans documents (open_file)

P2-04 — Créer les Feature Flags
         → Créer lib/config/mab_features.dart
         → Constantes : kFeatureOBD, kFeatureLicence, kFeaturePlaque, kFeatureFormation, etc.

P2-05 — Implémenter le système de licence Firebase (Mission 2 Inès)
         → firebase_core + cloud_firestore + device_info_plus
         → Format MAB-XXXX-XXXX-XXXX lié à l'identifiant appareil
         → Vérification au démarrage ET à chaque mise à jour
```

---

### PRIORITÉ 3 — AMÉLIORATION (à faire quand possible)

```
P3-01 — Écrire les tests unitaires (minimum 1 test nominal + 1 test erreur par fonctionnalité)
         → Commencer par ai_conversation_service.dart (quota, providers)
         → Puis mab_repository.dart (CRUD véhicule, maintenance)
         → Puis bluetooth_obd_service.dart (états connexion)

P3-02 — Restructurer en architecture MVC
         → Module par module, en commençant par le plus simple (carnet entretien)
         → Créer les dossiers backend/ frontend/ tests/ pour chaque module

P3-03 — Améliorer la validation VIN
         → Ajouter validation checksum algorithme VIN (ISO 3779)
         → Aide contextuelle "Où trouver votre VIN ?"

P3-04 — Verrouillage app jusqu'à fin formation
         → À implémenter quand mecanoabord.fr est prêt
         → Ajouter MABFormation.postMessage('done') dans index.html
         → Bloquer les écrans tant que formation_done = false

P3-05 — Ajouter connectivity_plus pour détecter absence réseau
         → Afficher message explicite si pas de connexion (WebView, IA, API plaque)

P3-06 — Compléter SIRET dans les mentions légales
         → Pascal fournit SIRET → legal_mentions_screen.dart + mab_legal_mentions_body.dart

P3-07 — Valider tous les 10 providers IA
         → Tester chaque appel API (Mistral, Qwen, Perplexity, Grok, Copilot, Meta AI, DeepSeek)
         → S'assurer que le format des réponses est correctement parsé pour chacun

P3-08 — Mettre à jour les packages
         → shared_preferences → 2.3.x
         → open_file → 3.5.x (sécurité)
         → flutter_reactive_ble → 5.4.x (compatibilité Android 14)
         → Utiliser flutter pub upgrade --major-versions AVEC PRÉCAUTION
         → Tester sur Samsung SM-A137F après chaque mise à jour

P3-09 — Ajouter animations de feedback UX
         → Feedback visuel sur chaque action (loading indicator sur bouton "Sauvegarder")
         → Message de succès après sauvegarde profil véhicule
         → Confirmation visuelle après ajout document
```

---

## ANNEXE A — MÉTRIQUES CODE

| Métrique | Valeur |
|---|---|
| Nombre de fichiers Dart | ~30 fichiers dans `lib/` |
| Nombre d'écrans | 16 screens |
| Nombre de services | 11 services |
| Nombre de tables SQLite | 9 tables |
| Nombre de try/catch | ~53 occurrences |
| Nombre de debugPrint | 16 occurrences (7 fichiers) |
| Nombre de tests unitaires | 1 (smoke test uniquement) |
| Nombre de feature flags | 0 |
| Couverture tests estimée | < 5% |

---

## ANNEXE B — ORDRE DE TRAITEMENT RECOMMANDÉ (module par module)

Selon la méthodologie CLAUDE.md v3.0 (audit → développer → try/catch → OWASP → UX → tests → valider → commit) :

```
MODULE 1  → Bug diagnostic OBD (P1 — bloquant)
MODULE 2  → Clé signature Release (P1 — Inès)
MODULE 3  → Package name + applicationId (P1)
MODULE 4  → WebView NavigationDelegate (P2 — sécurité)
MODULE 5  → Nettoyage debugPrint + logger (P2)
MODULE 6  → Feature Flags (P2)
MODULE 7  → Try/Catch manquants (P2)
MODULE 8  → Système de licence Firebase (P2 — Inès)
MODULE 9  → Tests unitaires — IA service (P3)
MODULE 10 → Tests unitaires — Repository (P3)
MODULE 11 → Refactoring MVC — Carnet entretien (P3)
MODULE 12 → Refactoring MVC — Profil véhicule (P3)
MODULE 13 → Verrouillage formation (P3 — quand mecanoabord.fr prêt)
MODULE 14 → Validation 10 providers IA (P3)
MODULE 15 → Mise à jour packages (P3)
```

---

*Audit généré le 16 avril 2026 — Mécano à Bord v1.0.0+14*
*Basé sur l'analyse complète du code source Flutter*
*Méthodologie : CLAUDE.md v3.0 + OWASP Mobile Top 10 2024*
*Contact : mecanoabord@gmail.com*
