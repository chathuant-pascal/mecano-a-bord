# Notes d’intention techniques — Mécano à Bord

Décisions d’architecture et choix techniques, pour affiner la réflexion et améliorer l’architecture au fil du projet.  
**À compléter à chaque décision technique importante.**

---

## 1. Stack et plateformes

| Décision | Détail |
|----------|--------|
| **Framework** | Flutter (Dart) — un seul codebase pour Android et iOS. Alternative Kotlin/Android documentée dans le contexte projet. |
| **Cibles** | Android, iOS (build iOS sur Mac uniquement ; le code est commun). Web et Windows utilisables pour dev/démo. |
| **SDK** | Dart ≥ 3.0 ; Flutter stable (3.41+ vérifié). |

---

## 2. Architecture applicative

| Décision | Détail |
|----------|--------|
| **Modèle cible** | MVVM (Model-View-ViewModel). Source de vérité : Boîte à gants (profil véhicule, documents, carnet). |
| **Navigation** | Routage Flutter (routes nommées dans `main.dart` : `/glovebox-profile`, `/obd-scan`, `/glovebox`, `/add-maintenance` avec arguments optionnels `editEntryId`, `/ai-chat`, `/settings`). |
| **État** | StatefulWidgets + services (AiConversationService, BluetoothObdService, MabRepository). Pas de state management global pour V1. |
| **Données locales** | sqflite (SQLite) ; schéma et accès via `mab_database.dart` et `mab_repository.dart`. Données sensibles : flutter_secure_storage (Keychain iOS, EncryptedSharedPreferences Android). |

---

## 2b. Carnet d’entretien (V1 — 2026-03-25)

| Décision | Détail |
|----------|--------|
| **CRUD** | Suppression d’une ligne `maintenance_entries` via `deleteMaintenanceEntry` : suppression aussi du fichier local `facture_photo_path` s’il existe. |
| **Édition** | `AddMaintenanceScreen(editEntryId: …)` ; navigation nommée avec `arguments: {'editEntryId': int}`. |
| **Facture** | Choix utilisateur : appareil photo (`ImageSource.camera`) ou galerie ; permission **`CAMERA`** déclarée dans `AndroidManifest.xml`. |
| **Pré-remplissage rappels** | Lorsque type + kilométrage sont saisis, propositions automatiques pour « prochain km » et « prochaine date » selon le libellé de type (vidange, plaquettes, courroie, pneus, CT, révision, autre) ; champs modifiables ensuite. |
| **Requête rappels** | `getMaintenanceAvecRappel` : `rappel_actif = 1` et `(rappel_kilometrage > 0 OR rappel_date_ms > 0)` — les dates « absentes » sont stockées en `0`, pas en SQL `NULL`. |
| **Rappels UI** | Toujours **in-app** (bandeau accueil / carnet) ; pas de notifications système Android dans ce périmètre. |

---

## 3. UI et accessibilité

| Décision | Détail |
|----------|--------|
| **Charte** | `mecano_a_bord/lib/theme/mab_theme.dart` — MabColors, MabTextStyles, MabDimensions. Aucune couleur/typo en dur dans les écrans. Palette officielle : Rouge principal `#C4161C`, Rouge secondaire `#E31E24`, Noir profond `#111111`, Gris anthracite `#2A2A2A`, Gris métallique `#B8A98A`, Fond clair `#F5F5F5`. |
| **Accessibilité** | Conformité EAA 2025 : zones tactiles ≥ 48 dp (MabDimensions.zoneTactileMin), boutons 56 dp. |
| **Ton** | Interface rassurante, pas de jargon ; mots interdits dans les messages (panne, danger, défaillance, etc.). |
| **Design system / Figma** | Règles Cursor `.cursor/rules/mab-design-system-figma.mdc` pour aligner Figma et code (couleurs, typo, espacements). Logo complet (`assets/images/logo.png`) pour splash et écran d’accueil ; symbole sans texte (`assets/images/logo_mark.png`) pour icône et filigrane. |

---

## 4. OBD et Bluetooth

| Décision | Détail |
|----------|--------|
| **Protocole** | Dongle cible : **iCar Pro Vgate**, **Bluetooth classique** (SPP), appairage par **code PIN** dans les réglages du téléphone. Pas de BLE pour ce dongle. Connexion SPP (UUID `00001101-...`) puis envoi ATZ pour valider le dialogue ELM327. |
| **Flutter** | `BluetoothObdService` utilise le **MethodChannel** `com.example.mecano_a_bord/obd` : `getBondedDevices()` (liste des appareils appairés), `connect(address, deviceName)` (connexion SPP + ATZ côté natif), `disconnect()`, `getConnectionState()`. Plus de scan BLE. |
| **Android** | `MainActivity.kt` : getBondedDevices, connect (BluetoothSocket SPP + ATZ timeout 15 s), `tryProtocol` (séquence ATZ → ATE0 → ATL0 → ATS0 → ATH1 → ATSPx + test `0100`), `readVehicleDataStep` (mini-init **ATE0 / ATL0 / ATH1** avec 500 ms entre chaque, puis commandes `0101` / `03` / `07` / `0A`). **Fin de ligne vers le dongle : retour chariot seul** (`\r`, pas `\r\n`). Délais : `INIT_CMD_DELAY_MS` = 500 ms entre commandes AT dans `tryProtocol` ; `OBD_CMD_MIN_WAIT_MS` = 3000 ms (attente min après prompt `>` dans `sendObdCommand`). Permissions : BLUETOOTH, BLUETOOTH_CONNECT. minSdk 28. |
| **Écran OBD** | Liste des **appareils déjà appairés** (priorité / seule source). Si liste vide : message « Appairez d’abord le dongle dans les réglages Bluetooth de votre téléphone, puis revenez ici » + bouton Rafraîchir. Tap sur un appareil → connexion SPP + overlay « Connexion au dongle en cours... ». |
| **Diagnostic manuel après connexion (2026-04-08)** | Une fois **ObdConnected**, **ne pas** lancer automatiquement `_readVehicleData` : annonce **« OBD connecté. Prêt pour le diagnostic. »** (SnackBar + TTS) ; le diagnostic est déclenché par l’utilisateur via **« Lancer le diagnostic »** sur l’écran OBD (distinct du parcours accueil). Le mode AUTO surveillance reste inchangé. |
| **Profil véhicule** | Sans profil complet (kilométrage + type de boîte), pas d’OBD réel ; mode démo disponible. |
| **Effacement codes (mode 04)** | **2026-03-23** — MethodChannel `clearDtcCodes` : commande **`04`**, mini-init ELM comme `readVehicleDataStep` ; succès si la trame parsée contient un octet **`0x44`**. Flutter : `BluetoothObdService.clearDtcCodes()` ; refus si surveillance temps réel active. Après succès : `saveLastObdDiagnostic` avec listes vides, MIL faux, **`kmAtScan`** = celui du dernier scan enregistré. Mode démo : **aucune écriture prefs**, simulation uniquement sur l’état d’écran. |
| **Réinitialisation complète** | **2026-03-23** — **`AppResetService.performFullReset`** : fichiers listés en base + dossiers `glovebox_documents` / `vehicle_profile_photos` ; **`closeAndDeleteDatabaseFile`** sur `mab_database.db` ; **`FlutterSecureStorage.deleteAll`** ; **`resetObdNativePrefs`** (Android, prefs `obd`) ; **`SharedPreferences.clear`**. Réglages : dialogue de progression puis onboarding. |

---

## 5. IA et confidentialité

| Décision | Détail |
|----------|--------|
| **Modes IA** | Gratuit (5 questions/jour, réponses locales par mots-clés) ; personnel (clé API utilisateur, ChatGPT/Gemini). |
| **Stockage clé API** | flutter_secure_storage (chiffré). Aucune clé fournie par l’app. |
| **Données** | Données stockées localement ; conformité RGPD ; pas de transmission sans consentement. |
| **Contexte system prompt (2026-03-28)** | `getAiSystemContextString` : marque, modèle, **motorisation** (si non vide), carburant, **type de boîte**, année, km profil, VIN ; bloc dernier OBD avec date, **kilométrage au diagnostic** (`kmAtScan` en prefs), MIL, codes par catégorie (mémorisés / attente / permanents) ; 3 derniers entretiens ; instructions de réponse. Dernier km de scan enregistré à chaque `saveLastObdDiagnostic` (profil actif au moment du scan). |

---

## 5b. Téléphone de test (référence terrain)

| Décision | Détail |
|----------|--------|
| **Appareil** | **Samsung Galaxy A13** — modèle **SM-A137F**, **Android 14**. |
| **Usage** | Builds terrain (`flutter build apk` / `flutter install`), tests OBD (dongle, permissions), UI petit écran (zones tactiles EAA), Assistant IA, coach vocal. |
| **Mise à jour (installer une nouvelle version)** | Depuis le dossier **`mecano_a_bord/`** : `flutter build apk --release` → APK : **`build/app/outputs/flutter-apk/app-release.apk`**. Transfert sur le téléphone (USB, cloud) puis installation, **ou** avec USB et débogage : `flutter install`. À chaque livraison significative, installer sur le **SM-A137F** et consigner le résultat dans **EVOLUTION.md** (règle doc projet). |
| **Dernière note terrain** | **2026-04-09** — Build **1.0.0+13** — Surveillance : TTS seulement si **ECU répond** (ping PID) ; sondage **4 s** ; bilan 2 h / chauffe si **moteur tournant** ; écran **« Connecte ton OBD »** sans bouton diagnostic (lecture auto depuis l’accueil uniquement). `flutter build apk --release` → APK `mecano_a_bord/build/app/outputs/flutter-apk/app-release.apk` ; installation USB : **`flutter install -d R58T92HCDAX`** (Samsung **SM-A137F**, Android 14) quand le téléphone est branché en débogage. |

---

## 6. Documentation et processus

| Décision | Détail |
|----------|--------|
| **Documentation projet** | Priorité : garder la doc à jour (PRD, BACKLOG, EVOLUTION, notes techniques). Tout le monde doit pouvoir retrouver l’évolution datée. |
| **Emplacement** | `docs-projet/` : PRD.md, BACKLOG.md, EVOLUTION.md, NOTES_INTENTION_TECHNIQUES.md, README (index). Contexte détaillé : CONTEXTE_CLAUDE_MECANO_A_BORD_V6.md. |
| **Règle** | Après chaque étape importante : mise à jour de EVOLUTION.md et, si besoin, BACKLOG.md et NOTES_INTENTION_TECHNIQUES.md. |

---

*Ces notes reflètent les intentions techniques actuelles. Toute évolution importante doit être ajoutée ici et datée dans EVOLUTION.md.*

*Dernière mise à jour : 2026-04-09 — §5b build **1.0.0+13** (terrain SM-A137F), surveillance OBD + écran connexion OBD*
