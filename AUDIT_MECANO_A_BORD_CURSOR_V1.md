# AUDIT COMPLET — MÉCANO À BORD CURSOR V1
### Base de travail complémentaire — Corrections fonctionnalité par fonctionnalité
### Généré le 17 avril 2026 — Version 1.0.0+14
### © Pascal Chathuant — Guadeloupe — mecanoabord@gmail.com

---

> **Méthodologie de travail obligatoire (CLAUDE.md v3.0)**
> Pour chaque fonctionnalité : Audit → Développer → Try/Catch → OWASP → UX → Tests → Valider → Commit

---

## RÉSUMÉ EXÉCUTIF

| Catégorie | Score | État |
|---|---|---|
| Fonctionnalités implémentées | 18/18 | ✅ Toutes présentes dans le périmètre V1 |
| Try/Catch couverts | ~65% | ⚠️ Partiel et hétérogène selon les modules |
| Tests unitaires réels | 1/18 | 🚨 Quasi inexistants |
| Feature Flags | 0/18 | 🚨 Aucun système centralisé |
| Architecture MVC | 2/18 | 🚨 Écart important avec la méthode cible |
| Sécurité OWASP | 3 problèmes majeurs | 🚨 À traiter avant diffusion large |
| Logs en mode release | 13 debugPrint | ⚠️ Risque d’exposition technique |
| Signature release / publication | Configuration incomplète | 🚨 Bloquant Play Store |

---

## SECTION 1 — LISTE COMPLÈTE DES FONCTIONNALITÉS

### 1.1 Splash Screen / Routing initial

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/main.dart` |
| **Statut** | ✅ Fonctionnel |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON — logique bootstrap + UI mêlées |

**Problèmes détectés :**
- Lecture d’état onboarding/formation non uniformisée avec gestion d’échec globale
- Pas de test de démarrage en cas de prefs invalides

---

### 1.2 Onboarding (première ouverture)

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/screens/onboarding_screen.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

**Problèmes détectés :**
- Gestion erreurs prefs non systématique
- Peu de garde-fous automatisés (aucun test widget dédié)

---

### 1.3 Formation WebView (post-onboarding)

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/screens/formation_webview_screen.dart` |
| **Statut** | ⚠️ Fonctionne mais durcissement sécurité requis |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

**Problèmes détectés :**
- 🚨 Validation de navigation/source JS à renforcer (risque de contournement du flux formation)
- Gestion des échecs réseau perfectible pour un public novice

---

### 1.4 Accueil (HomeScreen)

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/screens/home_screen.dart` |
| **Statut** | ✅ Fonctionnel |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

**Problèmes détectés :**
- Chargement multi-sources sans stratégie d’erreur centralisée
- Présence de logs techniques `debugPrint`

---

### 1.5 Profil Véhicule

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/screens/glovebox_profile_screen.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ⚠️ PARTIEL — repository utilisé mais écran encore chargé |

**Problèmes détectés :**
- Cas limites API plaque + sauvegarde locale non testés automatiquement
- Validation métier encore majoritairement côté UI

---

### 1.6 Boîte à Gants (5 onglets)

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/screens/glovebox_screen.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ⚠️ PARTIEL |

---

### 1.7 Documents (onglet Boîte à gants)

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/screens/glovebox_screen.dart` + `mecano_a_bord/lib/data/mab_repository.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ⚠️ PARTIEL |

**Problèmes détectés :**
- Cas d’ouverture de fichier externe pas homogènes selon plateforme
- Absence de tests dédiés aux erreurs d’accès disque

---

### 1.8 Carnet d'entretien

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/screens/add_maintenance_screen.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

---

### 1.9 Connexion OBD Bluetooth

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/services/bluetooth_obd_service.dart` |
| **Statut** | ✅ Implémentation riche |
| **Try/Catch** | ✅ PLUTÔT BON |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ⚠️ PARTIEL — bon service mais intégration couplée aux écrans |

**Problèmes détectés :**
- Logs techniques encore présents
- Complexité élevée, sensible aux régressions sans tests

---

### 1.10 Diagnostic OBD

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/screens/obd_scan_screen.dart` |
| **Statut** | 🚨 Bug rapporté dans la documentation projet |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

**Problèmes détectés :**
- 🚨 Régression à confirmer sur appareil réel (logcat requis)
- Chaîne OBD complexe sans tests de non-régression

---

### 1.11 Mode Conduite (Surveillance temps réel)

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/screens/surveillance_only_screen.dart` + `mecano_a_bord/lib/services/live_monitoring_service.dart` |
| **Statut** | ✅ Présent |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ⚠️ PARTIEL |

---

### 1.12 Assistant IA

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/screens/ai_chat_screen.dart` + `mecano_a_bord/lib/services/ai_conversation_service.dart` |
| **Statut** | ✅ Fonctionnel (mode gratuit/perso + fournisseurs) |
| **Try/Catch** | ✅ OUI côté appels API |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ⚠️ PARTIEL |

**Problèmes détectés :**
- Variabilité possible entre fournisseurs sans suite de tests dédiée
- Logs d’erreurs techniques exposés

---

### 1.13 Santé Véhicule

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/services/vehicle_health_service.dart` + `mecano_a_bord/lib/widgets/glovebox_vehicle_health_tab.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ⚠️ PARTIEL |

---

### 1.14 Coach Vocal (TTS)

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/services/tts_service.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ⚠️ PARTIEL |

---

### 1.15 Paramètres

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/screens/settings_screen.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

---

### 1.16 Mentions légales / Confidentialité / Aide

| Critère | État |
|---|---|
| **Fichiers** | `legal_mentions_screen.dart`, `privacy_policy_screen.dart`, `help_contact_screen.dart` |
| **Statut** | ⚠️ Fonctionnel mais points de conformité à finaliser |
| **Try/Catch** | ⚠️ PARTIEL |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ❌ NON |

---

### 1.17 Vérification de mise à jour

| Critère | État |
|---|---|
| **Fichier** | `mecano_a_bord/lib/services/update_check_service.dart` |
| **Statut** | ✅ OK |
| **Try/Catch** | ✅ OUI |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ⚠️ PARTIEL |

---

### 1.18 Mode Démo

| Critère | État |
|---|---|
| **Fichiers** | `mecano_a_bord/lib/data/demo_data.dart` + intégration écrans |
| **Statut** | ✅ OK |
| **Try/Catch** | N/A |
| **Tests unitaires** | ❌ NON |
| **Feature Flag** | ❌ NON |
| **Architecture MVC** | ⚠️ PARTIEL |

---

## SECTION 2 — AUDIT SÉCURITÉ OWASP

### OWASP-01 — Durcissement WebView incomplet

| Détail | |
|---|---|
| **Niveau** | 🟠 Important |
| **Fichier** | `mecano_a_bord/lib/screens/formation_webview_screen.dart` |
| **Description** | Le flux de formation via WebView est fonctionnel, mais la vérification stricte de navigation/source JS doit être renforcée pour éviter un contournement du déblocage. |
| **Solution** | Ajouter une politique allowlist stricte de domaines, renforcer la validation de source avant traitement du message de fin. |

---

### OWASP-02 — Logs techniques en release

| Détail | |
|---|---|
| **Niveau** | 🟠 Important |
| **Fichiers** | `home_screen.dart`, `bluetooth_obd_service.dart`, `ai_conversation_service.dart`, `vehicle_reference_service.dart`, `formation_web_launch_screen.dart`, `help_contact_screen.dart` |
| **Description** | 13 occurrences `debugPrint(` encore présentes, pouvant exposer des détails internes en production. |
| **Solution** | Remplacer par un logger conditionnel (`kDebugMode`) et nettoyer les logs sensibles OBD/erreurs internes. |

---

### OWASP-03 — Configuration release Android non finalisée

| Détail | |
|---|---|
| **Niveau** | 🔴 Critique |
| **Fichier** | `mecano_a_bord/android/app/build.gradle.kts` |
| **Description** | La chaîne de publication sécurisée (signature release/identité finale) reste à finaliser avant Play Store. |
| **Solution** | Finaliser keystore release, sécuriser la signature et verrouiller l’identifiant package cible avant publication. |

---

### OWASP-04 — Permissions sensibles à cadrer

| Détail | |
|---|---|
| **Niveau** | 🟡 Mineur à important selon le store review |
| **Fichier** | `mecano_a_bord/android/app/src/main/AndroidManifest.xml` |
| **Description** | Les permissions Bluetooth/localisation/caméra/micro doivent rester strictement justifiées par usage réel et demandées au bon moment. |
| **Solution** | Vérifier la cohérence “permission ↔ fonctionnalité” et la justification côté politique de confidentialité / fiche store. |

---

## SECTION 3 — AUDIT UX

### Écran 1 — Splash Screen

| | |
|---|---|
| **Problèmes UX** | Retour utilisateur minimal pendant le chargement |
| **Recommandation** | Ajouter un message court de progression rassurant |

---

### Écran 2 — Onboarding

| | |
|---|---|
| **Problèmes UX** | Les implications de l’acceptation peuvent être encore plus explicites |
| **Recommandation** | Ajouter un résumé visuel simple (3 points clés) |

---

### Écran 3 — Formation WebView

| | |
|---|---|
| **Problèmes UX** | Gestion d’erreur réseau perfectible |
| **Recommandation** | Ajouter état hors-ligne + bouton “Réessayer” |

---

### Écran 4 — Accueil

| | |
|---|---|
| **Problèmes UX** | Densité fonctionnelle élevée pour primo-utilisateur |
| **Recommandation** | Renforcer hiérarchie visuelle et parcours “premier pas” |

---

### Écran 5 — Profil Véhicule

| | |
|---|---|
| **Problèmes UX** | VIN et champs techniques encore impressionnants pour débutant |
| **Recommandation** | Ajouter aides contextuelles courtes et localisables |

---

### Écran 6 — Boîte à gants

| | |
|---|---|
| **Problèmes UX** | Compréhension des onglets peut rester floue |
| **Recommandation** | Icônes + micro-textes d’aide par onglet |

---

### Écran 7 — Diagnostic OBD

| | |
|---|---|
| **Problèmes UX** | Bug rapporté + complexité technique pour novice |
| **Recommandation** | Corriger la stabilité puis renforcer les explications “que faire maintenant” |

---

### Écran 8 — Mode Conduite

| | |
|---|---|
| **Problèmes UX** | Les seuils peuvent rester trop techniques |
| **Recommandation** | Associer systématiquement valeur + statut en langage simple |

---

### Écran 9 — Assistant IA

| | |
|---|---|
| **Problèmes UX** | Choix fournisseur et quota peuvent être confus |
| **Recommandation** | Mieux guider le choix par défaut et les limites du mode gratuit |

---

### Écran 10 — Paramètres

| | |
|---|---|
| **Problèmes UX** | Volume d’options élevé pour un débutant |
| **Recommandation** | Prioriser visuellement les réglages essentiels |

---

### Écran 11 — Guide Diagnostic

| | |
|---|---|
| **Problèmes UX** | ✅ Base pédagogique cohérente |
| **Recommandation** | Maintenir cette qualité sur les écrans techniques |

---

## SECTION 4 — BUGS CONNUS ET PROBLÈMES TECHNIQUES

### BUG-01 — Écran diagnostic défaillant

| | |
|---|---|
| **Priorité** | 🚨 P1 — Bloquant |
| **Fichier** | `mecano_a_bord/lib/screens/obd_scan_screen.dart` |
| **Symptôme** | Dysfonctionnement rapporté dans la documentation projet |
| **Comment investiguer** | Test réel Samsung SM-A137F + `adb logcat -s flutter` |
| **Cause probable** | Régression dans la chaîne UI OBD ↔ service ↔ natif Android |

---

### BUG-02 — Release Android non finalisée

| | |
|---|---|
| **Priorité** | 🚨 P1 — Bloquant (publication) |
| **Fichier** | `mecano_a_bord/android/app/build.gradle.kts` |
| **Symptôme** | Configuration release à finaliser (signature/package) |
| **Correction** | Finaliser keystore + paramètres release avant toute mise en production |

---

### BUG-03 — Sécurisation WebView incomplète

| | |
|---|---|
| **Priorité** | 🟠 P2 — Sécurité |
| **Fichier** | `mecano_a_bord/lib/screens/formation_webview_screen.dart` |
| **Symptôme** | Durcissement allowlist/source JS insuffisant |
| **Correction** | NavigationDelegate stricte + validation d’origine systématique |

---

### BUG-04 — Logs debugPrint en production

| | |
|---|---|
| **Priorité** | 🟠 P2 — Sécurité/Confidentialité |
| **Fichiers** | 6 fichiers principaux (`home_screen.dart`, `bluetooth_obd_service.dart`, etc.) |
| **Symptôme** | 13 occurrences de logs techniques |
| **Correction** | Logger conditionnel + nettoyage des traces sensibles |

---

### BUG-05 — Couverture tests quasi nulle

| | |
|---|---|
| **Priorité** | 🟡 P3 |
| **Fichier** | `mecano_a_bord/test/widget_test.dart` |
| **Symptôme** | 1 seul test smoke |
| **Correction** | Créer une base de tests unitaires/services priorisés |

---

### BUG-06 — Feature flags absents

| | |
|---|---|
| **Priorité** | 🟡 P3 |
| **Symptôme** | Impossible de désactiver un module fragile sans redéployer |
| **Correction** | Ajouter `lib/config/mab_features.dart` et brancher module par module |

---

### BUG-07 — Écart méthodologie MVC

| | |
|---|---|
| **Priorité** | 🟡 P3 |
| **Symptôme** | Logique métier encore fortement dans les écrans |
| **Correction** | Refactor progressif par module critique (OBD puis profil puis accueil) |

---

## SECTION 5 — DÉPENDANCES ET PACKAGES

### Packages de production (constat global)

| Package | État observé | Alerte |
|---|---|---|
| `shared_preferences` | utilisé largement | ⚠️ sécuriser les usages critiques |
| `sqflite` | cœur du stockage local | ✅ pertinent pour V1 |
| `flutter_secure_storage` | utilisé pour clés API | ✅ bon choix |
| `http` | utilisé | ⚠️ vérifier timeouts/retry homogènes |
| `url_launcher` | utilisé | ✅ |
| `image_picker` / `file_picker` / `open_file` | utilisés | ⚠️ renforcer gestion erreurs périphériques |
| `flutter_reactive_ble` | utilisé (OBD) | ⚠️ tests terrain indispensables Android 14 |
| `permission_handler` | utilisé | ⚠️ cadrage UX et conformité requis |
| `flutter_tts` / `speech_to_text` | utilisés | ✅ |
| `webview_flutter` | utilisé | 🚨 durcissement sécurité à compléter |

### Packages de dev

| Package | Version (famille) | Usage |
|---|---|---|
| `flutter_test` | SDK | Tests |
| `flutter_lints` | 3.x | Qualité code |
| `flutter_native_splash` | 2.x | Splash |
| `flutter_launcher_icons` | 0.14.x | Icône app |

### Packages potentiellement utiles (amélioration)

| Package | Usage prévu | Priorité |
|---|---|---|
| `logger` | logging conditionnel propre | P2 |
| `connectivity_plus` | états réseau utilisateur | P2 |
| `firebase_core` / `cloud_firestore` / `device_info_plus` | licence (roadmap validée) | P2/P3 selon décision produit |

---

## SECTION 6 — PLAN DE TRAVAIL PRIORISÉ

### PRIORITÉ 1 — BLOQUANT (immédiat)

```
P1-01 — Corriger le bug Diagnostic OBD
         → Repro sur Samsung SM-A137F + logcat
         → Tracer : obd_scan_screen.dart → bluetooth_obd_service.dart → MainActivity.kt

P1-02 — Finaliser la release Android
         → Keystore définitif + signature release
         → Vérification build et installation propre

P1-03 — Verrouiller l’identité de publication
         → Vérifier/figer package name final avant soumission store
```

---

### PRIORITÉ 2 — IMPORTANT

```
P2-01 — Durcir WebView formation
         → Allowlist domaines + validation source JS

P2-02 — Remplacer debugPrint par logger conditionnel
         → Nettoyage des logs sensibles en priorité OBD/IA

P2-03 — Uniformiser try/catch critiques
         → prefs, DB, réseau, ouverture fichiers

P2-04 — Ajouter Feature Flags centraux
         → Activer/désactiver modules sans redéploiement complet
```

---

### PRIORITÉ 3 — AMÉLIORATION

```
P3-01 — Mettre en place base de tests unitaires
         → OBD service, repository, IA service en premier

P3-02 — Refactor architecture vers MVC/MVVM
         → module par module, sans big-bang

P3-03 — Renforcer UX novice/anxieux
         → messages simples, aides contextuelles, erreurs guidées

P3-04 — Réviser permissions et conformité store
         → aligner usage réel + politique de confidentialité
```

---

## SECTION 7 — PRÉCISIONS TECHNIQUES

### 7.1 Quota IA stocké en clair — correction du constat initial

- **Constat corrigé :** dans la version actuelle, le quota IA n'est **pas** stocké dans `SharedPreferences`.
- **Fichier exact :** `mecano_a_bord/lib/services/ai_conversation_service.dart`
- **Lignes exactes et code concerné :**
  - `108-111` : stockage chiffré Android/iOS (`FlutterSecureStorage` + `encryptedSharedPreferences: true`)
  - `191-193`, `300-301`, `312`, `734-737` : lecture/écriture quota via `_storage.read/_storage.write`
  - clés : `mab_ai_questions_date`, `mab_ai_questions_count`
- **Conclusion :** quota IA en **FlutterSecureStorage**, pas en `SharedPreferences`.

---

### 7.2 Validation VIN insuffisante (pas de checksum ISO 3779)

- **Fichier exact :** `mecano_a_bord/lib/screens/glovebox_profile_screen.dart`
- **Lignes exactes et code concerné :**
  - `328-332` : `_isVinValid()` vérifie seulement longueur 17 + alphanumérique
  - `823` : message validation limité à la forme (`17 caractères alphanumériques`)
- **Conclusion :** validation de forme correcte, mais pas de validation checksum VIN.

---

### 7.3 Pas de limite de taille de fichier uploadé

- **Fichier exact :** `mecano_a_bord/lib/screens/glovebox_screen.dart`
- **Lignes exactes et code concerné :**
  - `377-380` : `FilePicker.platform.pickFiles(...)` sans contrôle de taille
  - `382-383` : path pris directement
  - `385` : copie immédiate vers stockage app (`copyDocumentToAppStorage(path)`)
  - `359` : `imageQuality: 85` (compression), mais aucune limite de poids
- **Conclusion :** aucune validation explicite du poids max (ex. 10 Mo).

---

### 7.4 SIRET manquant dans mentions légales

- **Fichier exact :** `mecano_a_bord/lib/widgets/mab_legal_mentions_body.dart`
  - **Ligne `60`** : `'[SIRET : à compléter avant mise en vente]'`
- **Fichier exact :** `mecano_a_bord/lib/screens/legal_mentions_screen.dart`
  - **Ligne `31`** : `child: const MabLegalMentionsSettingsSection(),`
- **Conclusion :** absence SIRET confirmée dans le contenu affiché.

---

### 7.5 Permissions Bluetooth / localisation / micro à justifier

- **Fichier exact :** `mecano_a_bord/android/app/src/main/AndroidManifest.xml`
- **Lignes exactes :**
  - `2` : `android.permission.BLUETOOTH`
  - `3` : `android.permission.BLUETOOTH_CONNECT`
  - `4` : `android.permission.BLUETOOTH_SCAN`
  - `5` : `android.permission.ACCESS_FINE_LOCATION`
  - `6` : `android.permission.RECORD_AUDIO`

---

### 7.6 Liste complète des `debugPrint` (compte exact confirmé)

- **Compteur confirmé (code app `mecano_a_bord/lib`) : `13` occurrences.**
- **Pourquoi pas 16 ?** le `16` vient d’un ancien relevé incluant du contexte documentaire miroir, pas seulement le code app actif.

| # | Fichier | Ligne | Contenu exact |
|---|---|---:|---|
| 1 | `mecano_a_bord/lib/screens/formation_web_launch_screen.dart` | 37 | `debugPrint('Formation launchUrl: $e\n$st');` |
| 2 | `mecano_a_bord/lib/services/vehicle_reference_service.dart` | 74 | `debugPrint('VehicleReferenceService: pas de clé IA — valeurs constructeur non chargées.',);` |
| 3 | `mecano_a_bord/lib/services/vehicle_reference_service.dart` | 78 | `debugPrint('VehicleReferenceService IA: ${response.message}');` |
| 4 | `mecano_a_bord/lib/screens/home_screen.dart` | 574 | `debugPrint('[MAB] Image non chargée: obd.png — $error');` |
| 5 | `mecano_a_bord/lib/screens/home_screen.dart` | 672 | `debugPrint('[MAB] Image non chargée: boite_a_gant.png — $error');` |
| 6 | `mecano_a_bord/lib/screens/home_screen.dart` | 698 | `debugPrint('[MAB] Image non chargée: systeme_io.png — $error');` |
| 7 | `mecano_a_bord/lib/screens/home_screen.dart` | 731 | `debugPrint('[MAB] Image non chargée: suv_images.png — $error');` |
| 8 | `mecano_a_bord/lib/screens/home_screen.dart` | 767 | `debugPrint('[MAB] Image non chargée: modeconduite.png — $error');` |
| 9 | `mecano_a_bord/lib/screens/home_screen.dart` | 821 | `debugPrint('[MAB] Image non chargée: iamecanoabord.png — $error');` |
| 10 | `mecano_a_bord/lib/services/bluetooth_obd_service.dart` | 313 | `debugPrint('OBD protocole $i: réponse brute = $rawResponse');` |
| 11 | `mecano_a_bord/lib/services/ai_conversation_service.dart` | 689 | `debugPrint('CHATGPT ERROR: $e');` |
| 12 | `mecano_a_bord/lib/screens/help_contact_screen.dart` | 52 | `debugPrint('help_contact _openUrl: $e\n$st');` |
| 13 | `mecano_a_bord/lib/screens/help_contact_screen.dart` | 69 | `debugPrint('help_contact _openEmail: $e\n$st');` |

---

### 7.7 Complexité `bluetooth_obd_service.dart` sensible aux régressions

- **Fichier exact :** `mecano_a_bord/lib/services/bluetooth_obd_service.dart`
- **Méthodes les plus complexes (lignes) :**
  1. `connect(...)` — `250-288`
  2. `runProtocolDetection(...)` — `295-322`
  3. `getVehicleData(...)` — `343-421`
  4. `readLivePid(...)` — `145-184`
  5. `getBondedDevices(...)` — `224-240`
- **Point de vigilance :** combinaison asynchrone + canal natif + états globaux (`ObdSessionCoordinator`).

---

## SECTION 8 — LISTE COMPLÈTE DES PLUGINS/PACKAGES

### 8.1 Packages de `pubspec.yaml` (runtime + dev)

| Package | Version actuelle | Dernière stable | Usage concret | Fichiers utilisés | Statut | Alternative recommandée |
|---|---|---|---|---|---|---|
| `flutter` (SDK) | SDK | n/a | Framework principal app | tout `lib/` | ✅ | n/a |
| `shared_preferences` | `^2.2.2` | `2.5.5` | préférences locales (onboarding, réglages, mode démo, etc.) | `main.dart`, `onboarding_screen.dart`, `settings_screen.dart`, `formation_webview_screen.dart`, `glovebox_profile_screen.dart`, `surveillance_only_screen.dart`, `tts_service.dart`, `surveillance_auto_coordinator.dart`, `app_reset_service.dart`, `mab_repository.dart`, `surveillance_settings_body.dart` | ⚠️ | `hive` |
| `sqflite` | `^2.3.0` | `2.4.2` | base SQLite locale | `mab_database.dart` | ⚠️ | `drift` |
| `path` | `^1.8.3` | `1.9.1` | manipulation chemins | `mab_database.dart`, `mab_repository.dart`, `app_reset_service.dart` | ⚠️ | n/a |
| `intl` | `^0.19.0` | `0.20.2` | i18n/formatage | import direct non trouvé dans `lib/` | ⚠️ (possiblement inutilisé) | retirer si inutile |
| `flutter_secure_storage` | `^9.0.0` | `10.0.0` | stockage sécurisé (clés IA + quota) | `ai_conversation_service.dart`, `app_reset_service.dart` | ⚠️ | n/a |
| `http` | `^1.2.0` | `1.6.0` | appels API IA/plaque/version | `ai_conversation_service.dart`, `glovebox_profile_screen.dart`, `update_check_service.dart` | ⚠️ | `dio` |
| `package_info_plus` | `^8.0.0` | `10.0.0` | version app | `settings_screen.dart`, `update_check_service.dart` | ⚠️ | n/a |
| `url_launcher` | `^6.2.0` | `6.3.2` | ouverture web/mail/tel | `formation_web_launch_screen.dart`, `help_contact_screen.dart`, `update_check_service.dart` | ⚠️ | n/a |
| `path_provider` | `^2.1.1` | `2.1.5` | dossiers app | `mab_repository.dart`, `app_reset_service.dart` | ⚠️ | n/a |
| `open_file` | `^3.3.2` | `3.5.11` | ouverture documents | `glovebox_screen.dart` | ⚠️ | `open_filex` |
| `image_picker` | `^1.0.7` | `1.2.1` | photo justificatifs | `glovebox_screen.dart`, `add_maintenance_screen.dart` | ⚠️ | n/a |
| `file_picker` | `^8.0.0` | `11.0.2` | import fichiers | `glovebox_screen.dart` | ⚠️ | n/a |
| `flutter_reactive_ble` | `^5.2.3` | `5.4.2` | BLE OBD (prévu/indirect) | import direct non trouvé dans `lib/` | ⚠️ | `flutter_blue_plus` |
| `permission_handler` | `^11.3.0` | `12.0.1` | permissions runtime | `home_screen.dart`, `ai_chat_screen.dart`, `obd_scan_screen.dart` | ⚠️ | n/a |
| `flutter_tts` | `^4.2.0` | `4.2.5` | synthèse vocale | `tts_service.dart` | ⚠️ | n/a |
| `speech_to_text` | `^7.0.0` | `7.3.0` | dictée vocale | `ai_chat_screen.dart` | ⚠️ | n/a |
| `webview_flutter` | `^4.13.1` | `4.13.1` | écran formation | `formation_webview_screen.dart` | ✅ | `flutter_inappwebview` |
| `flutter_test` | SDK | SDK | tests | `test/widget_test.dart` | ✅ | n/a |
| `flutter_lints` | `^3.0.0` | `6.0.0` | linting | `pubspec.yaml` | ⚠️ | `very_good_analysis` |
| `flutter_native_splash` | `^2.4.7` | `2.4.7` | splash natif | `pubspec.yaml` | ✅ | n/a |
| `flutter_launcher_icons` | `^0.14.4` | `0.14.4` | icône app | `pubspec.yaml` | ✅ | n/a |

---

### 8.2 Outils/plugins hors `pubspec.yaml` utilisés pour cet audit

| Outil / plugin | Usage concret | Statut |
|---|---|---|
| `Cursor tools` (`ReadFile`, `rg`, `ApplyPatch`) | lecture exhaustive + extraction lignes + mise à jour fichier audit | ✅ |
| `Subagent explore` | analyse globale readonly du codebase | ✅ |
| `pub.dev API` | récupération dernières versions stables | ✅ |

> Ces outils ne sont pas des dépendances runtime de l’application mobile.

---

## SECTION 9 — RÈGLES DÉVELOPPEUR (À RESPECTER)

### 9.1 Sources de référence

- `docs-projet/VERIFICATION_REGLES_DEVELOPPEUR.md`
- `.cursor/rules/contexte-pascal-mab.mdc`
- `.cursor/rules/mab-design-system-figma.mdc`
- `CLAUDE.md` (méthodologie projet)

---

### 9.2 Règles intouchables confirmées

| Règle | Exigence |
|---|---|
| Voix TTS féminine | **Figée** : `pitch 1.2` / `speechRate 0.5` — ne jamais modifier sans accord explicite |
| Mots interdits | Ne jamais utiliser : `panne`, `danger`, `défaillance` dans textes et messages vocaux |
| Design system | Utiliser exclusivement `MabColors`, `MabTextStyles`, `MabDimensions` (pas de valeurs hardcodées) |
| Accessibilité | Zones tactiles minimales `48dp` (EAA 2025) |
| Profils véhicule | Maximum `2` profils ; le 3e doit être refusé (`StateError`) |

---

### 9.3 Règles méthodologiques (développement)

| Domaine | Règle |
|---|---|
| Processus | Toujours : **diagnostic avant modification** |
| Avancement | Travailler **module par module**, pas plusieurs chantiers critiques en même temps |
| Robustesse | Ajouter `try/catch` sur opérations à risque (réseau, prefs, DB, Bluetooth, WebView) |
| Qualité | Créer des tests unitaires par fonctionnalité (cas nominal + erreur + limite) |
| Sécurité | Vérification OWASP mobile (HTTPS, logs, validation entrées, stockage sensible) |
| Documentation | Mettre à jour `docs-projet/EVOLUTION.md`, `BACKLOG.md`, `NOTES_INTENTION_TECHNIQUES.md` après étape majeure |

---

### 9.4 Règles UX / ton produit

- Public cible : débutant, anxieux, non technicien.
- Langage simple, rassurant, concret, sans jargon.
- Feedback utilisateur clair en cas d’erreur ou d’attente.
- Cohérence visuelle MAB sur tous les écrans.

---

### 9.5 Règles roadmap et périmètre

- Les modules V2/V3/V4 documentés sont des **pistes futures**.
- Interdiction de coder/préparer ces modules sans demande explicite de Pascal.
- Toute évolution hors périmètre V1 doit être validée avant implémentation.

---

## ANNEXE A — MÉTRIQUES CODE

| Métrique | Valeur |
|---|---|
| Nombre de fichiers Dart (`mecano_a_bord/lib`) | 43 |
| Nombre d’écrans | 16 |
| Nombre de services explicites | 8 |
| Nombre de coordinateurs/gates | 3 |
| Nombre de `try` | ~41 |
| Nombre de `catch` | ~42 |
| Nombre de `debugPrint` | 13 |
| Nombre de tests unitaires | 1 |
| Nombre de feature flags globaux | 0 |
| Couverture tests estimée | < 5% |

---

## ANNEXE B — ORDRE DE TRAITEMENT RECOMMANDÉ (module par module)

Selon la méthodologie CLAUDE.md v3.0 (audit → développer → try/catch → OWASP → UX → tests → valider → commit) :

```
MODULE 1  → Bug diagnostic OBD (P1)
MODULE 2  → Finalisation release Android (P1)
MODULE 3  → Durcissement WebView formation (P2)
MODULE 4  → Nettoyage logs debugPrint (P2)
MODULE 5  → Uniformisation try/catch critiques (P2)
MODULE 6  → Feature flags centraux (P2)
MODULE 7  → Tests unitaires OBD/Repository/IA (P3)
MODULE 8  → Refactor architecture module par module (P3)
MODULE 9  → Renforcement UX guidage novice (P3)
MODULE 10 → Vérification conformité permissions/store (P3)
```

---

*Audit généré le 17 avril 2026 — Mécano à Bord v1.0.0+14*
*Basé sur l’analyse complète du code source et de la documentation projet disponible*
*Méthodologie : structure AUDIT_MECANO_A_BORD_V1 + contraintes CLAUDE.md v3.0 + OWASP Mobile*
*Contact : mecanoabord@gmail.com*
