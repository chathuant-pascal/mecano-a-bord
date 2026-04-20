# MÉCANO À BORD — RÉFÉRENTIEL FONCTIONNEL COMPLET
### Document destiné à la développeuse Inès
### Version 1.0 — Avril 2026
### © Pascal Chathuant — Mécano à Bord — Guadeloupe

---

> **Comment lire ce document**
> - ✅ Fonctionnalité existante et opérationnelle
> - ⚠️ Fonctionnalité présente mais incomplète ou partielle
> - 🚫 Fonctionnalité absente / à implémenter
> - 🚨 Point bloquant ou risque technique à traiter en priorité

---

## TABLE DES MATIÈRES

1. [Architecture générale](#1-architecture-générale)
2. [Accès et démarrage (Onboarding + Splash)](#2-accès-et-démarrage)
3. [Profil véhicule (Boîte à gants — Onglet Profil)](#3-profil-véhicule)
4. [Boîte à gants (5 onglets)](#4-boîte-à-gants)
5. [Diagnostic et connexion OBD](#5-diagnostic-et-connexion-obd)
6. [Écran d'accueil](#6-écran-daccueil)
7. [Assistant IA](#7-assistant-ia)
8. [Formation WebView](#8-formation-webview)
9. [Paramètres](#9-paramètres)
10. [Système de licence](#10-système-de-licence)
11. [Services transversaux](#11-services-transversaux)
12. [Contraintes globales et accessibilité](#12-contraintes-globales-et-accessibilité)
13. [Bugs connus et limitations](#13-bugs-connus-et-limitations)
14. [Tableau récapitulatif des missions](#14-tableau-récapitulatif-des-missions)

---

## 1. ARCHITECTURE GÉNÉRALE

### Stack technique

| Élément | Valeur |
|---|---|
| Framework | Flutter (SDK >=3.0.0 <4.0.0) |
| Langage | Dart |
| Version actuelle | 1.0.0+14 |
| Platform cible principale | Android (Google Play Store) |
| Platform secondaire | iOS (laissée de côté — nécessite Mac ou Codemagic) |
| Package name actuel | `com.example.mecano_a_bord` ⚠️ À changer avant publication |
| Téléphone test Pascal | Samsung SM-A137F — Android 14 |
| Téléphone test Inès | Samsung A36 |

### Structure des fichiers clés

```
mecano_a_bord/
├── lib/
│   ├── main.dart                          ← Point d'entrée, routing, SplashRouting
│   ├── formation_url.dart                 ← Constante kFormationUrl (1 ligne à changer)
│   ├── theme/
│   │   └── mab_theme.dart                 ← Charte MAB (couleurs, dimensions, styles)
│   ├── screens/
│   │   ├── onboarding_screen.dart         ← Onboarding 2 phases
│   │   ├── home_screen.dart               ← Accueil (7 bandeaux)
│   │   ├── glovebox_screen.dart           ← Boîte à gants (5 onglets)
│   │   ├── glovebox_profile_screen.dart   ← Profil véhicule (création/édition)
│   │   ├── obd_scan_screen.dart           ← Connexion OBD + diagnostic
│   │   ├── surveillance_only_screen.dart  ← Mode conduite (surveillance temps réel)
│   │   ├── ai_chat_screen.dart            ← Assistant IA (chat)
│   │   ├── settings_screen.dart           ← Réglages (4 sections)
│   │   ├── add_maintenance_screen.dart    ← Ajouter/modifier entrée carnet
│   │   ├── formation_webview_screen.dart  ← Formation (WebView post-onboarding)
│   │   ├── formation_web_launch_screen.dart ← Accès formation depuis accueil
│   │   ├── diagnostic_guide_screen.dart   ← Guide "que taper dans l'IA ?"
│   │   ├── privacy_policy_screen.dart     ← Politique de confidentialité
│   │   ├── legal_mentions_screen.dart     ← Mentions légales
│   │   └── help_contact_screen.dart       ← Aide & Contact
│   ├── data/
│   │   ├── mab_database.dart              ← SQLite (sqflite) — 9 tables
│   │   ├── mab_repository.dart            ← Modèles domaine + accès données
│   │   ├── demo_data.dart                 ← Données fictives mode démo
│   │   ├── chat_message.dart              ← Modèle message IA
│   │   └── moteur_symptomes_knowledge.dart ← Base de connaissances mode gratuit
│   ├── services/
│   │   ├── ai_conversation_service.dart   ← IA (10 providers, quota, system prompt)
│   │   ├── tts_service.dart               ← Coach vocal (flutter_tts)
│   │   ├── bluetooth_obd_service.dart     ← Connexion Bluetooth OBD
│   │   ├── live_monitoring_service.dart   ← Surveillance temps réel (PIDs)
│   │   ├── surveillance_auto_coordinator.dart ← Coordinateur surveillance
│   │   ├── vehicle_health_service.dart    ← Santé véhicule (créé par Cursor 05/04)
│   │   ├── vehicle_reference_service.dart ← Valeurs référence (créé par Cursor 05/04)
│   │   └── app_reset_service.dart         ← Réinitialisation complète
│   └── widgets/
│       ├── mab_logo.dart                  ← Logo officiel
│       ├── mab_watermark_background.dart  ← Filigrane en arrière-plan
│       ├── mab_demo_banner.dart           ← Bannière orange mode démo
│       ├── mab_obd_session_dialogs.dart   ← Dialogues session OBD
│       ├── mab_obd_not_responding_dialog.dart ← Dialogue OBD non répondant
│       └── surveillance_settings_body.dart ← Corps réglages surveillance
├── android/
│   └── app/src/main/kotlin/.../MainActivity.kt ← Modifié 05/04 (fix RPM)
└── pubspec.yaml
```

### Persistance des données

| Mécanisme | Usage |
|---|---|
| SQLite (sqflite) | Profils véhicule, carnet entretien, documents, OBD historique, santé véhicule |
| SharedPreferences | Flags booléens (onboarding_done, formation_done), compteur IA gratuit, préférences vocales, mode surveillance |
| FlutterSecureStorage | Clés API IA (une clé par fournisseur : `api_key_chatgpt`, `api_key_claude`, etc.) |
| Fichiers locaux (path_provider) | Photos reçus / documents Boîte à gants |

### Tables SQLite (9 tables)

```
vehicle_profiles         ← Profils véhicule (max 2)
diagnostic_entries       ← Historique diagnostics OBD
maintenance_entries      ← Carnet d'entretien
documents                ← Documents Boîte à gants
alerts                   ← Alertes générées
vehicle_reference_values ← Valeurs de référence par modèle
vehicle_learned_values   ← Valeurs apprises par usage
vehicle_health_alert_history ← Historique santé véhicule
(+ 1 table interne SQLite)
```

---

## 2. ACCÈS ET DÉMARRAGE

### 2.1 Splash Screen (SplashRouting)

**Fichier :** `lib/main.dart` — classe `SplashRouting`

✅ Logo MAB centré + spinner doré sur fond noir  
✅ Lecture SharedPreferences : clé `onboarding_done`  
✅ Si `false` → redirige vers `OnboardingScreen`  
✅ Si `true` → redirige vers `HomeScreen`  

### 2.2 Onboarding (première ouverture uniquement)

**Fichier :** `lib/screens/onboarding_screen.dart`

L'onboarding se déroule en **2 phases** :

#### Phase 1 : Acceptation des conditions

✅ Image `assets/images/onboarding_page1.png` (200px de hauteur)  
✅ Titre "Bienvenue"  
✅ Texte "En utilisant Mécano à Bord, vous acceptez les conditions d'utilisation applicables."  
✅ Lien "Voir les mentions légales complètes →" → route `/legal-mentions`  
✅ Bouton "J'accepte et je commence" → passe à la Phase 2  
⚠️ Pas de case à cocher (consentement implicite par clic)  

#### Phase 2 : Carrousel 5 pages

✅ Bouton "Passer" en haut à droite (masqué sur la dernière page)  
✅ Indicateurs de page animés (point rouge actif, gris inactif)  
✅ Bouton "Suivant" / "Terminer" sur la dernière page  

| Page | Image | Titre affiché | Description |
|---|---|---|---|
| 1 | `assets/images/logo.png` | non | Présentation de l'app |
| 2 | `assets/images/obd.png` | non | Explication boîtier OBD |
| 3 | `assets/images/boite_a_gant.png` | oui : "Votre Boîte à gants numérique" | Documents numériques |
| 4 | `assets/images/suv_images.png` | non | Créer un profil véhicule |
| 5 | `assets/images/systeme_io.png` | non | Accès au système IO (hauteur 320px) |

#### Fin de l'onboarding

✅ SharedPreferences : `onboarding_done = true`  
✅ Navigation vers `FormationWebViewScreen` (formation obligatoire après onboarding)  

---

## 3. PROFIL VÉHICULE

**Fichier :** `lib/screens/glovebox_profile_screen.dart`  
**Modèle :** `VehicleProfile` dans `lib/data/mab_repository.dart`

### 3.1 Champs du profil

| Champ | Type | Obligatoire | Notes |
|---|---|---|---|
| Marque (`brand`) | String | ✅ oui | |
| Modèle (`model`) | String | ✅ oui | |
| Motorisation (`motorisation`) | String | non | Ex. "1.6 TDI 110ch" |
| Année (`year`) | int | ✅ oui | |
| Immatriculation (`licensePlate`) | String | ✅ oui | Format AA-000-AA |
| VIN | String | ✅ oui | Exactement 17 caractères |
| Carburant (`fuelType`) | String | ✅ oui | |
| Boîte de vitesses (`gearboxType`) | String | ✅ oui | Manuelle / Automatique / etc. |
| Kilométrage (`mileage`) | int | ✅ oui | |
| Couleur | String | non | |
| Notes | String | non | |

### 3.2 Règle `isComplete`

Un profil est **complet** si et seulement si :
```dart
mileage > 0 && gearboxType.isNotEmpty && vin.length == 17
```
⚠️ Si le profil est incomplet, l'assistant IA est bloqué (sauf si ouvert depuis l'OBD).

### 3.3 Lookup automatique par immatriculation

✅ API : `https://particulier.api.gouv.fr/api/v2/immatriculation?immatriculation=PLATE`  
✅ Pré-remplit marque, modèle, année, carburant depuis la plaque  
⚠️ L'API est externe (gratuite, fournie par l'État français) — peut être indisponible  

### 3.4 Limite de profils

✅ Maximum 2 profils véhicule par application  
✅ Sélection du véhicule actif dans les Réglages  

---

## 4. BOÎTE À GANTS

**Fichier :** `lib/screens/glovebox_screen.dart`

La Boîte à gants contient **5 onglets** :

| Index | Nom | Contenu |
|---|---|---|
| 0 | Profil | Résumé du profil véhicule actif + bouton éditer |
| 1 | Documents | Documents numérisés (carte grise, assurance, CT…) |
| 2 | Carnet | Carnet d'entretien (28 types, 6 catégories) |
| 3 | Historique | Historique des diagnostics OBD |
| 4 | Santé | Bilan santé véhicule (visible aussi en mode démo) |

### 4.1 Onglet Documents

✅ Stockage local des photos/PDF  
✅ Ouverture du document avec l'application système (MIME type mémorisé)  
✅ Types de documents : carte grise, assurance, contrôle technique, Crit'Air, etc.  
✅ Date d'expiration optionnelle  
⚠️ Pas de synchronisation cloud  

### 4.2 Onglet Carnet d'entretien

✅ 28 types d'opération  
✅ 6 catégories visuelles  
✅ Champs : type, date, kilométrage au service, prochain service (km + date), notes, garage, coût, photo de reçu  
✅ Édition d'une entrée existante (route `/add-maintenance` avec `editEntryId`)  
✅ Rappels visibles sur l'écran d'accueil si maintenance en retard  

### 4.3 Onglet Historique (OBD)

✅ Liste des diagnostics passés (depuis `diagnostic_entries`)  
✅ Champs par diagnostic : date, kilométrage, MIL on/off, DTC mémorisés/en attente/permanents, niveau d'urgence, résumé global  

### 4.4 Onglet Santé

✅ Bilan santé basé sur `vehicle_health_service.dart`  
✅ Historique des alertes graduées (`vehicle_health_alert_history`)  
✅ Visible en mode démo  

---

## 5. DIAGNOSTIC ET CONNEXION OBD

**Fichier :** `lib/screens/obd_scan_screen.dart`  
**Services :** `bluetooth_obd_service.dart`, `live_monitoring_service.dart`

### 5.1 Connexion Bluetooth

✅ Bluetooth classique SPP (Serial Port Profile)  
✅ Compatible dongle iCar Pro Vgate  
✅ Liste des appareils Bluetooth appairés  
✅ Connexion automatique au dernier appareil connu (paramètre `autoStartDiagnostic`)  
✅ Animation pulse pendant la connexion  
✅ Timer de connexion avec compte à rebours  
✅ Détection automatique du protocole OBD  
✅ Mémorisation de l'adresse du dernier dongle (`setLastObdDeviceAddress`)  
⚠️ Bluetooth LE (BLE) non supporté dans cette version  

### 5.2 Diagnostic complet

✅ Lecture MIL (témoin Check Engine) — PID indirect  
✅ DTC mémorisés, en attente, permanents  
✅ Niveau d'urgence calculé (vert/orange/rouge)  
✅ Résumé global en français  
✅ Effacement des codes défaut + dialogue pédagogique post-effacement  
✅ Sauvegarde automatique dans `diagnostic_entries`  
✅ Mode démo (données fictives depuis `demo_data.dart`)  

### 5.3 PIDs en temps réel (Mode Conduite)

| PID | Donnée | État |
|---|---|---|
| 0105 | Température liquide refroidissement (°C) | ✅ |
| 0142 | Tension batterie (V) | ✅ |
| 010B | Pression collecteur d'admission (kPa) | ✅ |
| 010C | Régime moteur RPM | ✅ Corrigé 05/04/2026 — formule `((A*256)+B)/4.0` |

**PIDs réservés V2 (non implémentés) :**

| PID | Donnée |
|---|---|
| 0111 | Position papillon |
| 015E | Débit carburant |
| 010D | Vitesse véhicule |
| 0104 | Charge moteur |
| 012F | Niveau carburant |
| 010F | Température air admission |

### 5.4 Mode Conduite (Surveillance)

**Fichier :** `lib/screens/surveillance_only_screen.dart`  
**Route :** `/surveillance-only`

✅ Surveillance temps réel des 4 PIDs actifs  
✅ Alertes vocales TTS en cas de seuil dépassé  
✅ Mode AUTO/MANUEL (configurable dans Réglages)  
✅ Délai d'arrêt automatique configurable  
✅ Bannière démo si mode démo  

### 5.5 Statut OBD sur l'accueil

✅ Bandeau de statut OBD sur `home_screen.dart`  
✅ Affiche : connecté/déconnecté, données temps réel si connecté  

---

## 6. ÉCRAN D'ACCUEIL

**Fichier :** `lib/screens/home_screen.dart`

### 6.1 Bandeaux (7 permanents + alertes conditionnelles)

| Ordre | Bandeau | Hauteur | Action |
|---|---|---|---|
| 1 | Méthode sans stress (Systeme.io) | 80px | → route `/systeme-io` |
| 2 | Boîte à gants | 80px | → route `/glovebox` |
| 3 | Statut OBD | 80px | → route `/obd-scan` |
| 4 | Alertes maintenance *(si en retard)* | conditionnel | → route `/add-maintenance` |
| 5 | Diagnostic | 80px | → route `/obd-scan?autoStartDiagnostic=true` |
| 6 | Mode Conduite | 80px | → route `/surveillance-only` |
| 7 | Mode Démo | 80px | Active/désactive le mode démo |
| 8 | Poser une question IA | 80px | → route `/ai-chat` |

### 6.2 Navigation inférieure (Bottom NavBar)

| Index | Label | Route |
|---|---|---|
| 0 | Accueil | home |
| 1 | OBD | `/obd-scan` |
| 2 | Boîte à gants | `/glovebox` |
| 3 | IA | `/ai-chat` |
| 4 | Réglages | `/settings` |

---

## 7. ASSISTANT IA

**Fichier :** `lib/screens/ai_chat_screen.dart`  
**Service :** `lib/services/ai_conversation_service.dart`

### 7.1 Deux modes de fonctionnement

#### Mode Gratuit (AiMode.free)

✅ 5 questions par jour  
✅ Compteur stocké dans SharedPreferences (`mab_ai_questions_date` + `mab_ai_questions_count`)  
✅ Remise à zéro à minuit  
✅ Réponses locales basées sur `moteur_symptomes_knowledge.dart` (base de connaissances symptômes)  
✅ Bandeau quota affiché : "Il vous reste X question(s) gratuite(s) aujourd'hui"  
✅ Quand quota = 0 : message d'info + lien vers Réglages pour connecter une clé  

#### Mode Personnel (AiMode.personal)

✅ Clé API de l'utilisateur (stockée dans FlutterSecureStorage)  
✅ Questions illimitées  
✅ Bandeau vert "Assistant connecté — Questions illimitées"  
✅ Appel API réel vers le provider sélectionné  

### 7.2 Fournisseurs IA supportés (10)

| Enum | Label affiché | Couleur fallback |
|---|---|---|
| `claude` | Claude (Anthropic) | #CC785C |
| `chatgpt` | ChatGPT (OpenAI) | #10A37F |
| `gemini` | Gemini (Google) | #4285F4 |
| `mistral` | Mistral | #FF7000 |
| `qwen` | Qwen | #6B4DE6 |
| `perplexity` | Perplexity | #20808D |
| `grok` | Grok (xAI) | #1DA1F2 |
| `copilot` | Copilot (Microsoft) | #0078D4 |
| `meta_ai` | Meta AI | #0668E1 |
| `deepseek` | DeepSeek | #4D6BFE |

**Clé sécurisée :** `api_key_{provider.name}` — ex. `api_key_chatgpt`, `api_key_meta_ai`  
**Migration :** ancienne clé unique `mab_ai_api_key` migrée automatiquement  

### 7.3 System Prompt (hardcodé)

```
Tu es l'assistant de l'application Mécano à Bord.
Tu aides les conducteurs à comprendre leur véhicule en langage simple et rassurant.
Règles absolues :
- Ne jamais utiliser les mots : panne, danger, défaillance, risque grave, erreur fatale
- Toujours être calme, bienveillant, accessible
- Réponses courtes (3-5 phrases maximum)
- Si tu ne sais pas, dis-le honnêtement
- Tu n'es pas mécanicien et ne remplaces pas un professionnel
```

### 7.4 Contexte véhicule injecté dans chaque question

✅ Marque, modèle, année, kilométrage, type de boîte  
✅ Statut MIL (Check Engine) + codes DTC du dernier diagnostic  
✅ Contexte système additionnel (`getAiSystemContextString()`)  

### 7.5 Interface chat

✅ Messages "flottants" (texte sans bulle) sur fond filigrane `iamecanoabord.png`  
✅ Indicateur de saisie (3 points animés)  
✅ Dictée vocale STT (speech_to_text, locale `fr_FR`, mode confirmation)  
✅ Bouton micro : rouge + fond teinté si écoute active  
✅ Lien "Je ne sais pas quoi taper" → route `/diagnostic-guide`  
✅ Message d'accueil dynamique (mentionne le véhicule si profil complet)  

### 7.6 Conditions de blocage

| Condition | Comportement |
|---|---|
| Profil véhicule incomplet | Bannière orange + message centré + bouton "Compléter mon profil" → `/glovebox` |
| Exception : ouverture depuis OBD | Input actif même si profil incomplet (`_openedWithObdQuestion = true`) |
| Quota gratuit épuisé | Input désactivé, hint "Quota atteint pour aujourd'hui" |
| Mode démo actif | Bannière démo affichée, pas de blocage de contenu |

### 7.7 Modèles de réponse

```dart
AiSuccess   { text, mode, remainingFreeQuestions }
AiLimitReached { message, remainingTomorrow }
AiError     { message }
```

---

## 8. FORMATION WEBVIEW

### 8.1 Écran post-onboarding

**Fichier :** `lib/screens/formation_webview_screen.dart`  
**URL :** définie dans `lib/formation_url.dart` (constante `kFormationUrl`)  
**URL actuelle :** GitHub Pages `https://chathuant-pascal.github.io/mecano-a-bord/formation-web/index.html`  
**URL finale prévue :** `https://mecanoabord.fr/formation`

✅ WebView plein écran (JavaScript unrestricted)  
✅ AppBar avec titre "Ta Voiture Sans Galère"  
✅ Canal JS `MABFormation` (JavaScriptChannel) — reçoit `'done'`, `'1'`, ou `'true'`  
✅ À la réception → `formation_done = true` dans SharedPreferences  
✅ Polling toutes les 2 secondes (`_pollTimer`) + vérification à `AppLifecycleState.resumed`  
✅ Navigation vers `HomeScreen` dès que `formation_done = true`  
✅ Flag `_navigated` empêche double navigation  

### 8.2 Accès formation depuis l'accueil

**Fichier :** `lib/screens/formation_web_launch_screen.dart`  
**Route :** `/systeme-io`

✅ Ouvre la formation via WebView depuis l'accueil (après avoir déjà complété l'onboarding)  
✅ Bandeau "Méthode sans stress" sur l'accueil  

### 8.3 Verrouillage de l'app jusqu'à fin de formation

🚫 **NON IMPLÉMENTÉ** — à faire quand la formation sera hébergée sur `mecanoabord.fr`

**Comportement prévu :**
- À la 1ère ouverture (onboarding_done = true) : seule la formation est accessible
- Toutes les autres fonctions verrouillées avec message "Cette fonction sera disponible une fois ta formation Mécano à Bord complétée."
- Déblocage automatique quand `formation_done = true`

---

## 9. PARAMÈTRES

**Fichier :** `lib/screens/settings_screen.dart`

L'écran est organisé en **4 sections** :

### 9.1 Section 1 — Coach Vocal

✅ Choix voix féminine / masculine  
✅ Clé SharedPreferences : `mab_voice_gender` (`female` ou `male`)  
✅ Toggle alertes vocales activées/désactivées  
✅ Service : `tts_service.dart` (flutter_tts)  

### 9.2 Section 2 — Assistant IA

✅ Accordéon : 10 fournisseurs IA (un seul panneau ouvert à la fois)  
✅ Pour chaque provider :
- Logo PNG officiel (fallback : cercle de couleur + initiale)
- Label complet affiché
- Champ saisie clé API (masqué par défaut, icône œil pour révéler)
- Bouton Sauvegarder / Effacer
- Indicateur "Clé enregistrée ✓"
✅ Fournisseur actuellement sélectionné  
✅ Mode gratuit : affiche quota restant  
✅ Gestion des véhicules actifs dans cette section  

### 9.3 Section 3 — Surveillance

✅ Mode AUTO / MANUEL  
✅ Délai d'arrêt automatique de la surveillance  
✅ Widget dédié : `surveillance_settings_body.dart`  
✅ Scroll automatique si ouvert via `initialSection: 'surveillance'`  

### 9.4 Section 4 — Application

✅ Lien Mentions légales → `/legal-mentions`  
✅ Lien Politique de confidentialité → `/privacy-policy`  
✅ Lien Aide & Contact → `/help-contact`  
✅ Numéro de version dynamique (PackageInfo.fromPlatform)  
✅ Réinitialisation complète de l'application (`app_reset_service.dart`)  
⚠️ SIRET non encore renseigné dans les mentions légales  

---

## 10. SYSTÈME DE LICENCE

### 10.1 État actuel

🚫 **AUCUN système de licence implémenté**  
✅ Mode démo accessible librement sans code  

### 10.2 Mission Inès — PRIORITÉ ABSOLUE : Clé de signature Release

🚨 **BLOQUANT pour la publication sur Play Store**

Étapes à réaliser :
1. Générer un keystore `.jks` avec `keytool`
2. Configurer `android/app/build.gradle.kts` avec les informations de signature
3. Compiler : `flutter build apk --release`
4. Tester sur Samsung SM-A137F
5. Sauvegarder le keystore : **Google Drive + copie locale** — ⚠️ JAMAIS dans GitHub

### 10.3 Mission Inès — Système de licence Firebase

🚫 À implémenter après la clé de signature

**Spécifications :**
- Packages : `firebase_core`, `cloud_firestore`, `device_info_plus`
- Collection Firestore `licences` :
  ```
  {
    code: "MAB-XXXX-XXXX-XXXX",
    valide: true,
    appareils: ["device_id_1", "device_id_2"]
  }
  ```
- Écran d'activation du code au 1er démarrage
- Format code : `MAB-XXXX-XXXX-XXXX`
- Maximum 2 appareils par licence
- Mode démo reste accessible sans code

### 10.4 Changement du package name

🚫 À faire avant publication  
Actuel : `com.example.mecano_a_bord`  
Prévu : à définir (ex. `fr.mecanoabord.app`)

---

## 11. SERVICES TRANSVERSAUX

### 11.1 Coach Vocal (TtsService)

**Fichier :** `lib/services/tts_service.dart`

✅ Singleton : `TtsService.instance`  
✅ Initialisé dans `main()` avant `runApp()`  
✅ Voix féminine / masculine (fr_FR)  
✅ Alertes vocales OBD (seuils température, batterie, RPM)  
✅ Annonce de connexion OBD (ne se répète pas pendant la session)  
✅ Bug corrigé 09/04/2026 : TTS "fantôme" (annonces non souhaitées)  

### 11.2 Surveillance Auto Coordinator

**Fichier :** `lib/services/surveillance_auto_coordinator.dart`

✅ Singleton : `SurveillanceAutoCoordinator.instance`  
✅ Attaché dans `main()` : `SurveillanceAutoCoordinator.instance.attach()`  
✅ Gère le démarrage/arrêt automatique de la surveillance selon le cycle de vie de l'app  

### 11.3 Santé Véhicule

**Fichiers :** `vehicle_health_service.dart`, `vehicle_reference_service.dart`  
(Créés par Cursor le 05/04/2026)

✅ Analyse les données OBD pour générer un bilan de santé  
✅ Alertes graduées (niveaux 1-3 ?)  
✅ Valeurs de référence par modèle de véhicule  
✅ Valeurs apprises par usage  

### 11.4 Mode Démo

**Fichier :** `lib/data/demo_data.dart`

✅ Données fictives complètes (profil véhicule, DTC, historique)  
✅ Bannière orange `MabDemoBanner` affichée sur les écrans concernés  
✅ Activé/désactivé depuis l'accueil  
✅ Onglet Santé visible en mode démo  
✅ Diagnostic OBD simulé en mode démo  

### 11.5 App Reset Service

**Fichier :** `lib/services/app_reset_service.dart`

✅ Supprime toutes les SharedPreferences  
✅ Supprime les données SQLite  
✅ Supprime les fichiers locaux (documents)  
✅ Efface les clés sécurisées (FlutterSecureStorage)  

---

## 12. CONTRAINTES GLOBALES ET ACCESSIBILITÉ

### 12.1 Charte visuelle (MabTheme)

| Élément | Valeur |
|---|---|
| Couleur principale | Rouge `#CC0000` |
| Fond principal | Noir `MabColors.noir` |
| Fond secondaire | `MabColors.noirMoyen` |
| Texte principal | Blanc `MabColors.blanc` |
| Texte secondaire | `MabColors.grisTexte` |
| Or/doré | `MabColors.grisDore` |
| Alerte rouge | `MabColors.diagnosticRouge` |
| Alerte orange | `MabColors.diagnosticOrange` |
| Alerte verte | `MabColors.diagnosticVert` |
| Zone tactile minimale | `MabDimensions.zoneTactileMin` = 48 dp |

### 12.2 Accessibilité (EAA 2025)

✅ Zones tactiles ≥ 48 dp sur tous les boutons interactifs  
✅ `Semantics()` wrapper sur les boutons critiques (micro, envoi, acceptation)  
✅ Labels Semantics en français  
✅ `SingleChildScrollView` sur les pages longues (onboarding, profil)  

### 12.3 Permissions requises

| Permission | Usage |
|---|---|
| `BLUETOOTH` + `BLUETOOTH_CONNECT` + `BLUETOOTH_SCAN` | Connexion dongle OBD |
| `MICROPHONE` | Dictée vocale (speech_to_text) |
| `READ_EXTERNAL_STORAGE` (selon Android) | Ajout documents Boîte à gants |
| `INTERNET` | API immatriculation + Appels IA + Formation WebView |

### 12.4 Routage (Named Routes)

| Route | Écran | Paramètres |
|---|---|---|
| `/glovebox-profile` | GloveboxProfileScreen | `routeArguments` (objet libre) |
| `/obd-scan` | ObdScanScreen | `autoStartDiagnostic: bool` (dans Map) |
| `/surveillance-only` | SurveillanceOnlyScreen | aucun |
| `/glovebox` | GloveboxScreen | `initialTab: String` (onglet initial) |
| `/add-maintenance` | AddMaintenanceScreen | `editEntryId: int?` (dans Map) |
| `/ai-chat` | AiChatScreen | `initialQuestion: String?` (dans Map) |
| `/settings` | SettingsScreen | `initialSection: String?` (ex. `'surveillance'`) |
| `/privacy-policy` | PrivacyPolicyScreen | aucun |
| `/legal-mentions` | LegalMentionsScreen | aucun |
| `/help-contact` | HelpContactScreen | aucun |
| `/diagnostic-guide` | DiagnosticGuideScreen | aucun |
| `/systeme-io` | FormationWebLaunchScreen | aucun |

---

## 13. BUGS CONNUS ET LIMITATIONS

| # | Sévérité | Description | État |
|---|---|---|---|
| 1 | 🚨 Bloquant | Pas de clé de signature Release → APK non publiable | En attente Inès |
| 2 | 🚨 Bloquant | Package name `com.example.mecano_a_bord` → à changer avant publication | En attente |
| 3 | ⚠️ Moyen | PID 010C (RPM) : formule corrigée dans MainActivity.kt le 05/04/2026 mais uniquement pour Android | ✅ Résolu Android |
| 4 | ⚠️ Moyen | TTS "fantôme" (annonces non souhaitées) | ✅ Résolu 09/04/2026 |
| 5 | ⚠️ Moyen | Clignotement dongle OBD en status bar | ✅ Résolu 09/04/2026 |
| 6 | ⚠️ Moyen | Bouton diagnostic ne répondait pas | ✅ Résolu 09/04/2026 |
| 7 | ⚠️ Moyen | SIRET absent dans les mentions légales | En attente Pascal |
| 8 | ℹ️ Info | iOS non supporté (nécessite Mac ou Codemagic) | Décision stratégique |
| 9 | ℹ️ Info | Bluetooth LE non supporté (seulement Classic SPP) | V2 |
| 10 | ℹ️ Info | Pas de synchronisation cloud des données | V2/V3 |
| 11 | ℹ️ Info | Ancienne clé API unique `mab_ai_api_key` → migration automatique vers `api_key_*` | ✅ Migration en place |

---

## 14. TABLEAU RÉCAPITULATIF DES MISSIONS

### Missions Inès — Ordre de priorité

| # | Mission | Priorité | Statut |
|---|---|---|---|
| 1 | Générer keystore Release + configurer build.gradle.kts | 🚨 BLOQUANT | ⏳ En attente |
| 2 | Compiler APK Release + tester sur Samsung SM-A137F | 🚨 BLOQUANT | ⏳ Après mission 1 |
| 3 | Implémenter système de licence Firebase | 🔴 Haute | ⏳ Après mission 2 |
| 4 | Changer le package name | 🔴 Haute | ⏳ Avant publication |
| 5 | Implémenter verrouillage app jusqu'à fin formation | 🟡 Moyenne | ⏳ Quand formation sur mecanoabord.fr |

### Ce qui NE doit PAS être touché

```
✅ La logique OBD et les PIDs (validés, fonctionnels sur Samsung SM-A137F)
✅ La charte graphique MAB (couleurs, dimensions, styles)
✅ Le système de base de données SQLite (9 tables)
✅ La logique de quota IA (5 questions/jour)
✅ Le canal JS MABFormation (WebView ↔ app)
✅ Les corrections RPM dans MainActivity.kt
✅ Les corrections TTS du 09/04/2026
```

---

## ANNEXE A — COMPTES ET ACCÈS

| Service | Compte |
|---|---|
| GitHub | `chathuant-pascal/mecano-a-bord` |
| GitHub Pages | `https://chathuant-pascal.github.io/mecano-a-bord/formation-web/index.html` |
| OVH (domaines) | karucards@gmail.com — mecanoabord.fr + mecanoabord.com |
| Gmail pro | mecanoabord@gmail.com |
| Systeme.io | mecanoabord@gmail.com |
| Workspace Pascal | `C:\Users\karuc\OneDrive\Bureau\Mecano A Bord\` |

---

## ANNEXE B — FLUX APPLICATIF COMPLET

```
1ère ouverture :
Splash → onboarding_done=false → OnboardingScreen (Phase 1 : acceptation)
       → Phase 2 : carrousel 5 pages
       → FormationWebViewScreen (GitHub Pages)
       → [Utilisateur complète la formation] → formation_done=true
       → HomeScreen

Ouvertures suivantes :
Splash → onboarding_done=true → HomeScreen

Depuis HomeScreen :
→ Boîte à gants : /glovebox (5 onglets)
→ Profil véhicule : /glovebox-profile
→ Diagnostic rapide : /obd-scan?autoStartDiagnostic=true
→ Mode Conduite : /surveillance-only
→ Assistant IA : /ai-chat
→ Formation : /systeme-io
→ Réglages : /settings
```

---

*Document généré le 14 avril 2026*  
*Basé sur l'analyse du code source Flutter — version 1.0.0+14*  
*Pour toute question : mecanoabord@gmail.com*
