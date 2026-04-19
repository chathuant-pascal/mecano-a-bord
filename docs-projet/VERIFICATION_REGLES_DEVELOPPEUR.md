# Vérification des règles développeur — Mécano à Bord

Contrôle de conformité : charte MAB (`mab_theme.dart`), accessibilité **EAA 2025** (zones tactiles ≥ 48 dp), interface rassurante, stockage et assets documentés.

**Dernière mise à jour (vérification projet) : 14 avril 2026**

---

## 1. Charte graphique `mab_theme.dart`

| Élément | Statut |
|--------|--------|
| Couleurs (rouge, noir, gris doré, etc.) | ✅ `MabColors` |
| Typographie (titres, corps, boutons) | ✅ `MabTextStyles` |
| Espacements et rayons | ✅ `MabDimensions` (paddingEcran, rayonMoyen, `zoneTactileMin`, `boutonHauteur`, etc.) |
| Thème Material (`MabTheme.theme`) | ✅ `main.dart` |
| Fond sombre, pas de bleu technique | ✅ Identité MAB |

**Écrans concernés** : tous les fichiers sous `lib/screens/` + `main.dart` (inventaire § 5).

---

## 2. Boutons et zones tactiles ≥ 48 dp (EAA 2025)

| Écran / widget | Élément | Vérification |
|----------------|---------|---------------|
| **mab_theme.dart** | `zoneTactileMin = 48`, `boutonHauteur = 56` | ✅ Thème |
| **main** | TextButton | ✅ `minimumSize` ≥ 48 dp |
| **onboarding_screen** | Boutons principaux | ✅ `boutonHauteur` / thème |
| **home_screen** | Réglages, cartes bandeaux | ✅ 48×48 / `InkWell` pleine carte |
| **home_screen** | Bandeau statut OBD (non connecté) | ✅ `MabTextStyles.titreCard` + `FittedBox` (`scaleDown`) pour « OBD non connecté » sans troncature ; pastille de statut masquée sur l’état par défaut — validé **SM-A137F** build **1.0.0+4** |
| **home_screen** | Bascule véhicules | ✅ `Semantics` ; confort doigt sur petit écran à valider en test |
| **settings_screen** | Véhicules / boutons section app | ✅ `zoneTactileMin` où requis |
| **settings_screen** | **Réinitialiser l’application** | ✅ `boutonHauteur` + `minimumSize` sur `OutlinedButton` |
| **settings_screen** | Assistant IA : **Enregistrer** / **Retirer la clé** | ✅ `height: zoneTactileMin` sur les boutons du panneau accordéon |
| **settings_screen** | Ligne fournisseur IA (accordéon) | ✅ `InkWell` + padding vertical (cible confortable) — vérifier sur appareil |
| **obd_scan_screen** | **Effacer les codes** (après diagnostic avec DTC) | ✅ `SizedBox` hauteur `boutonHauteur` |
| **glovebox_profile_screen** | Enregistrer | ✅ `boutonHauteur` |
| **ai_chat_screen** | Envoyer | ✅ 48×48 |
| **ai_chat_screen** | Lien **« Je ne sais pas quoi taper → »** (guide diagnostic) | ✅ `InkWell` + padding, cible confortable |
| **diagnostic_guide_screen** | Retour / recommencer (`IconButton`, `TextButton`) | ✅ `zoneTactileMin` ≥ 48 dp |
| **diagnostic_guide_screen** | Choix de l’arbre (grandes tuiles) | ✅ `boutonHauteurGrand` min., `MabWatermarkBackground` |
| **diagnostic_guide_screen** | Copier la phrase garagiste | ✅ `OutlinedButton` thème MAB (`boutonHauteur`) |
| **help_contact_screen** | Boutons formation / YouTube / email / site / envoi | ✅ `OutlinedButton` / `ElevatedButton` thème MAB |
| **help_contact_screen** | « Aller sur le site » (cartes clé API) | ✅ `minimumSize` hauteur ≥ 48 dp |
| **placeholder_screen** | Retour | ✅ Thème |
| **surveillance_only_screen** | Choix AUTO / MANUEL (`InkWell` + padding) | ✅ Zone tactile confortable ; **RadioListTile** dense — valider au doigt |
| **surveillance_only_screen** | TextButton « Mentions légales → » (sous texte outil d’aide) | ✅ `MabTextStyles.label` + `grisTexte` — lien secondaire |
| **privacy_policy_screen** | TextButton « Voir aussi : Mentions légales complètes → » | ✅ `MabTextStyles.label` + `grisDore` |
| **onboarding_screen** | Page d’acceptation (hors carrousel) : texte conditions + lien « Voir les mentions légales complètes → » (`/legal-mentions`) + « J’accepte et je commence » | ✅ `MabTextStyles.titreSection` / lien `corpsNormal` souligné blanc ; pas d’indicateurs sur cette étape |
| **formation_webview_screen** | WebView formation post-onboarding (`kFormationUrl`), AppBar titre **Ta Voiture Sans Galère** | ✅ `MabColors` / `MabTextStyles.titreSection` ; contenu web — zones tactiles déléguées à la page |

À valider en **test manuel** sur **Samsung SM-A137F** : lignes d’accordéon IA, tuiles surveillance mode conduite, **navigation mentions légales** (scroll automatique vers la section dans Réglages) et lisibilité des 9 blocs sur petit écran.

---

## 3. Interface simple et rassurante

| Règle | Application |
|-------|-------------|
| Langage simple | ✅ Assistant auto, messages quota, aide « clés API » en 3 étapes, guide diagnostic sans jargon |
| Pas de look « technique » dominant | ✅ Palette sombre MAB |
| Ton rassurant | ✅ Prompt IA, onboarding, filigranes discrets |
| Sémantique | ✅ `Semantics` sur actions clés (IA, réglages, accordéon fournisseur `expanded`) |

---

## 4. Synthèse — données et persistance

- **Charte MAB** : maintenue sur les écrans intégrés (dont **`diagnostic_guide_screen`** : `MabColors` / `MabTextStyles` / `MabDimensions` uniquement).
- **Fiches locales** : `assets/data/moteur_symptomes.json` + `MoteurSymptomesKnowledge` (mode gratuit IA, guide) — pas de mots interdits projet dans les textes affichés (sanitation).
- **48 dp** : boutons principaux et actions explicites conformes ; **accordéon IA** et **mode conduite** : contrôle tactile recommandé sur matériel réel.
- **Clés API** : par fournisseur dans `flutter_secure_storage` (`api_key_<fournisseur>`), fournisseur actif `mab_ai_provider` — voir `ai_conversation_service.dart`.
- **Réinitialisation complète** (Réglages) : `AppResetService` — fichiers référencés en base + dossiers `glovebox_documents` / `vehicle_profile_photos` ; suppression fichier SQLite `mab_database.db` ; `FlutterSecureStorage.deleteAll` ; prefs natives OBD Android (`resetObdNativePrefs` / `MainActivity`) ; puis `SharedPreferences.clear`. Voir `docs-projet/EVOLUTION.md` et `NOTES_INTENTION_TECHNIQUES.md`.
- **Phase test** : poursuivre selon `AVANT_PREMIERS_TESTS.md` (ou équivalent projet).

---

## 5. Inventaire fichiers Dart & `pubspec.yaml` *(projet `mecano_a_bord/`)*

### 5.1 Version application

| Champ | Valeur |
|-------|--------|
| **name** | `mecano_a_bord` |
| **version** | **1.0.0+14** |
| **SDK** | `>=3.0.0 <4.0.0` |

### 5.2 Dépendances (`dependencies`)

| Package | Contrainte |
|---------|------------|
| flutter | sdk |
| shared_preferences | ^2.2.2 |
| sqflite | ^2.3.0 |
| path | ^1.8.3 |
| intl | ^0.19.0 |
| flutter_secure_storage | ^9.0.0 |
| http | ^1.2.0 |
| package_info_plus | ^8.0.0 |
| url_launcher | ^6.2.0 |
| path_provider | ^2.1.1 |
| open_file | ^3.3.2 |
| image_picker | ^1.0.7 |
| file_picker | ^8.0.0 |
| flutter_reactive_ble | ^5.2.3 |
| permission_handler | ^11.3.0 |
| flutter_tts | ^4.2.0 |
| speech_to_text | ^7.0.0 |
| webview_flutter | ^4.13.1 — WebView formation post-onboarding |

**dev_dependencies** : `flutter_test` (sdk), `flutter_lints` ^3.0.0, `flutter_native_splash` ^2.4.7, `flutter_launcher_icons` ^0.14.4.

### 5.3 Assets déclarés (`flutter.assets`)

- `assets/data/moteur_symptomes.json` (fiches voyants / symptômes — mode gratuit IA + guide pas à pas)
- `assets/images/` (dossier)
- `assets/images/ia/` (dossier — logos fournisseurs IA)
- `assets/images/logo.png`
- `assets/images/obd.png`
- `assets/images/boite_a_gant.png`
- `assets/images/suv_images.png`
- `assets/images/modeconduite.png`
- `assets/images/systeme_io.png`

*Également couverts par `assets/images/` si présents sur disque : `logo_mark.png`, `iamecanoabord.png`, etc.*

### 5.4 Fichiers Dart — chemin et rôle (une ligne)

| Fichier | Rôle |
|---------|------|
| `lib/main.dart` | Entrée app, `TtsService.init`, routes, splash Flutter → onboarding ou accueil ; flux documenté : onboarding → formation WebView → accueil. |
| `lib/formation_url.dart` | Constante **`kFormationUrl`** — URL formation web (GitHub Pages ; test local possible). |
| `lib/data/chat_message.dart` | Modèle message chat (user / IA). |
| `lib/data/demo_data.dart` | Données factices mode démo. |
| `lib/data/mab_database.dart` | SQLite : véhicules, entretiens, documents, diagnostics ; chemins fichiers reset ; `closeAndDeleteDatabaseFile`. |
| `lib/data/mab_repository.dart` | Domaine, prefs véhicule actif, OBD, IA, fichiers gants ; suppression profil + fichiers. |
| `lib/data/moteur_symptomes_knowledge.dart` | Mode gratuit IA : fiches voyants / symptômes (`assets/data/moteur_symptomes.json`, matching par alias). |
| `lib/screens/add_maintenance_screen.dart` | Ajout / édition ligne carnet d’entretien. |
| `lib/screens/ai_chat_screen.dart` | Chat IA : messages flottants + ombres, filigrane, quota / clés, lien guide diagnostic. |
| `lib/screens/diagnostic_guide_screen.dart` | Arbre décisionnel guidé → fiches `moteur_symptomes.json` (sans AppBar classique). |
| `lib/screens/formation_web_launch_screen.dart` | Ouverture formation dans le **navigateur externe** (`kFormationUrl`, `url_launcher`) — ex. route `/systeme-io` ; distinct de la WebView post-onboarding. |
| `lib/screens/formation_webview_screen.dart` | **Après onboarding** : WebView interne `kFormationUrl` ; passage **`HomeScreen`** si prefs **`formation_done`** ou message canal JS **`MABFormation`**. |
| `lib/screens/glovebox_profile_screen.dart` | Création / édition profil véhicule. |
| `lib/screens/glovebox_screen.dart` | Boîte à gants : documents & entretien. |
| `lib/screens/help_contact_screen.dart` | Aide (guide étapes, clés API) + contact. |
| `lib/screens/legal_mentions_screen.dart` | Écran dédié mentions légales & CGU (scroll, même gabarit que politique). |
| `lib/screens/home_screen.dart` | Accueil, bandeaux, navigation ; bandeau OBD (libellé par défaut **« Connecte ton OBD »**, `FittedBox` si besoin). |
| `lib/screens/obd_scan_screen.dart` | OBD Bluetooth, connexion + diagnostic depuis l’accueil (auto), effacement codes DTC, filigrane. |
| `lib/screens/onboarding_screen.dart` | Première ouverture : acceptation conditions puis carrousel 5 pages ; fin → **`FormationWebViewScreen`** (plus **`/glovebox-profile`** obligatoire). |
| `lib/screens/placeholder_screen.dart` | Écran titre générique. |
| `lib/screens/privacy_policy_screen.dart` | Politique de confidentialité. |
| `lib/screens/settings_screen.dart` | Coach vocal, IA accordéon, surveillance (lien), **Mentions légales & CGU** (scroll `initialSection: 'legal'`), **version affichée** (`package_info_plus`), **réinitialisation complète** (`AppResetService`). |
| `lib/screens/surveillance_only_screen.dart` | Mode conduite : surveillance temps réel, filigrane, dialogue blocage diagnostic. |
| `lib/services/ai_conversation_service.dart` | IA : quotas, clés secure storage, appels API. |
| `lib/services/app_reset_service.dart` | Réinitialisation usine : fichiers, SQLite, secure storage, prefs OBD natives, `SharedPreferences.clear`. |
| `lib/services/bluetooth_obd_service.dart` | OBD : connexion, lecture véhicule, live PID, effacement DTC, `resetObdNativePrefs`. |
| `lib/services/live_monitoring_service.dart` | Surveillance OBD temps réel (PID toutes les 4 s, seuils, TTS, démo). |
| `lib/services/obd_session_coordinator.dart` | Exclusion mutuelle diagnostic ↔ surveillance. |
| `lib/services/surveillance_auto_coordinator.dart` | Mode AUTO : démarrage / arrêt surveillance selon connexion OBD + ping ECU avant TTS. |
| `lib/services/surveillance_auto_gate.dart` | Mode AUTO : évite reprise surveillance après arrêt manuel sans déconnexion physique. |
| `lib/services/vehicle_health_service.dart` | Coach santé véhicule (références, apprentissage, bilan 2 h, alertes graduées). |
| `lib/services/vehicle_reference_service.dart` | Valeurs constructeur / communautaires (`vehicle_reference_values`) après profil complet. |
| `lib/services/tts_service.dart` | TTS féminin / masculin, alertes, message après effacement DTC. |
| `lib/services/update_check_service.dart` | Vérification mise à jour (si branchée). |
| `lib/theme/mab_theme.dart` | Charte MAB + thème Material. |
| `lib/widgets/mab_legal_mentions_body.dart` | Section Réglages : mentions légales & CGU (9 blocs), charte MAB. |
| `lib/widgets/glovebox_vehicle_health_tab.dart` | Onglet **Santé de ma voiture** (Boîte à gants) : alertes coach, détails repliables. |
| `lib/widgets/mab_demo_banner.dart` | Bandeau mode démo. |
| `lib/widgets/mab_logo.dart` | Logo MAB. |
| `lib/widgets/mab_obd_not_responding_dialog.dart` | Dialogue OBD sans réponse. |
| `lib/widgets/mab_obd_session_dialogs.dart` | Dialogues blocage surveillance / diagnostic ; confirmation effacement DTC. |
| `lib/widgets/mab_watermark_background.dart` | Filigrane paramétrable. |
| `lib/widgets/surveillance_settings_body.dart` | Surveillance AUTO/MANUEL + délais (Réglages). |
| `test/widget_test.dart` | Test widget par défaut. |

**Android natif** : `MainActivity.kt` — MethodChannel OBD (`readLiveData` PIDs **0105, 0142, 010B, 010C**, `clearDtcCodes`, `resetObdNativePrefs`, etc.).

---

**Total** : **43** fichiers Dart sous `mecano_a_bord/lib/` (hors `test/`) — inventaire **exhaustif** dans le tableau § 5.4 ci-dessus.

*Document de référence **règle développeur** MAB / EAA — à actualiser lors de changements majeurs d’UI ou de persistance. Dernière revue : **2026-04-14** — **`formation_webview_screen.dart`** ; dépendance **`webview_flutter`** ; splash natif image **`onboarding_page1.png`** (`flutter_native_splash`) ; parcours onboarding → WebView formation → accueil.*
