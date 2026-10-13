# Plan du chantier OBD-BLE — Mécano à Bord

Réécriture de la communication OBD en Dart (flutter_reactive_ble), en Bluetooth BLE,
une seule fois pour Android et iPhone. Boîtier de référence : Vgate iCar Pro BLE 4.0.

**Compatibilité : Android ✅ / iOS ✅** (test iPhone réel après le chantier iOS-SETUP).

**Statut au 04/10/2026 : NON DÉMARRÉ.** Ordre validé par Pascal : d'abord la correction
de `formation_events`, puis B54, puis l'hébergement de la formation, puis OBD-BLE.

---

## 1. Décisions de Pascal (04/10/2026)

- Interrupteur Remote Config `feature_obd_ble` : **oui**, **Android seulement**, pendant
  la bêta (repli possible sur l'ancien Bluetooth classique). Code Kotlin supprimé une fois
  le BLE validé sur les deux systèmes.
- Boîtier : **Vgate iCar Pro BLE 4.0 uniquement** pour la bêta (pas d'autres clones ELM327).
- Les 2 limites de lecture des codes défaut (section 4) : **copiées à l'identique**, puis
  corrigées dans un chantier séparé **juste après l'étape 6** (essais sur route Android).
- Étape 0 (identifiants BLE) : **faite par Pascal** (voir section 2).

---

## 2. Identifiants et comportement du boîtier — CONFIRMÉS (étape 0)

Source : décompilation de l'outil officiel Vgate **VgateFwUpdater 2.1.1**
(classes `LocalUUID` et `BleManage`), par Pascal, le 04/10/2026.

| Élément | Valeur |
|---|---|
| Service GATT | `e7810a71-73ae-499d-8c15-faa9aef0c3f2` |
| Caractéristique unique (écriture **et** notifications) | `bef8d6c9-9c21-4c9e-b632-bd58c1009f9f` |
| Descripteur | CCCD `2902` activé en **NOTIFICATION** |
| Nom BLE à rechercher | commence par **`IOS-Vlink`** (aussi « vLinker » chez Vgate) |
| Noms à **ignorer** | `Android-Vlink`, `V-LINK` = Bluetooth **classique** |

Comportement de l'outil officiel Vgate, à reproduire :

- Recherche par **préfixe de nom**, **sans filtre de service** ; abandon après **20 s**.
- **Android** : `requestMtu(185)` après connexion.
- Envois **découpés à MTU − 3** octets.
- Écriture **SANS réponse** (write without response).
- Attente de **2 s après la connexion**, puis **0,5 s** après que la caractéristique
  est prête (notifications activées), avant la première commande.

Pièges du firmware à respecter :

- **Firmware iCar Pro 4.1.16+** : un retour à la ligne seul (`\r`) **répète la dernière
  commande** → **ne jamais envoyer de commande vide**.
- **Firmware 4.1.06** : la réponse à `ATZ` a changé → **ne pas exiger un texte précis**
  (ex. « ELM327 ») ; attendre **seulement le `>`**.
- Commande Vgate **`VTVERS`** = version du firmware (**non vérifiée**) → piste pour
  l'ajouter comme clé de contexte Crashlytics (utile pour relier un problème à un firmware).

Historique utile : un premier essai BLE avait échoué le 14/03/2026 (EVOLUTION.md,
« suspicion UUID NUS ») — les bons identifiants sont désormais connus.

---

## 3. Ce que fait aujourd'hui le code Kotlin (à porter en Dart)

`android/app/src/main/kotlin/fr/mecanoabord/app/MainActivity.kt` (755 lignes), canal
`fr.mecanoabord.app/obd`, appelé depuis `lib/services/bluetooth_obd_service.dart`.
Toutes les fonctions natives passent par **un seul fil d'exécution** (ligne 50) : c'est
ce qui empêche aujourd'hui deux commandes de se mélanger.

| Fonction Kotlin (lignes) | Rôle | Appel Dart | Utilisée par |
|---|---|---|---|
| `getBondedDevices` (86-110) | Appareils appairés | `getBondedDevices` 237-253, `discoverDevices` 256 | `home_screen.dart:389`, `obd_scan_screen.dart:507` |
| `connect` + `sendAtzAndComplete` + `applyProtocolAndComplete` (112-227) | Connexion, ATZ (15 s max, attendre `>`), init avec protocole mémorisé par VIN ou demande de détection | `connect` 263-325 | `obd_scan_screen.dart:201`, `:873` |
| `tryProtocol` (297-348) | Init complète (ATZ + 1,5 s, ATE0, ATL0, ATH0, ATAT1, ATSPx), test `0100`, mémorise si valide | `runProtocolDetection` 332-366 | `obd_scan_screen.dart:263` |
| `disconnect` (350-363) | Ferme la liaison | `disconnect` 480-486 | `obd_scan_screen.dart:169`, `:636` |
| `getConnectionState` (365-375) | Liaison ouverte ? | `readNativeConnectionState` 131-141 | `live_monitoring_service.dart:279`, `surveillance_auto_coordinator.dart:57`, `surveillance_only_screen.dart:113` |
| `readLiveData` (452-620) | 4 valeurs : 0105 = A−40 ; 0142 = (256A+B)/1000 ; 010B = A ; 010C = ((A×256)+B)/4 ; option `skipInit` | `readLivePid` 152-192 | `live_monitoring_service.dart:291-294`, `surveillance_auto_coordinator.dart:136` |
| `readVehicleDataStep` + `decodeDtc` (679-749) | Diagnostic 0101 (MIL 0x80, nombre 0x7F), 03, 07, 0A | `getVehicleData` 387-477 | `obd_scan_screen.dart:350` |
| `clearDtcCodes` (650-676) | `04`, succès si octet 0x44 | `clearDtcCodes` 197-213 | `obd_scan_screen.dart:1217` |
| `resetObdNativePrefs` (378-387) | Efface les protocoles mémorisés | `resetObdNativePrefs` 216-221 | `app_reset_service.dart:60`, `:96` |

Délais à reproduire : ATZ 15 s + pause 1,5 s ; commandes AT 8 s max, 0,5 s entre deux ;
`0100` en détection 15 s max ; commande OBD 45 s max puis 150 ms après le `>`.

Déjà en Dart et conservé tel quel (si l'interface publique ne change pas) : race condition
de l'annonce de déconnexion, `computeEngineRunning`, `isLivePidValuePlausible`, délai
d'arrêt automatique, protection contre deux cycles simultanés, vérification de connexion
avant démarrage manuel, cas hybride, init une fois par cycle, mode AUTO, exclusion
diagnostic ↔ surveillance.

---

## 4. Limites connues du code actuel (copiées à l'identique, corrigées après l'étape 6)

1. **Véhicules d'avant le CAN** : la réponse 03/07/0A n'a pas d'octet « nombre de codes »,
   lu pourtant en `bytes[1]` (MainActivity.kt ligne 721) → codes possiblement mal lus.
2. **3 codes ou plus sur CAN** : réponse sur plusieurs lignes `0:` `1:`… ; le découpage
   (ligne 420) garde ces chiffres et décale la lecture.

Code mort repéré : `live_monitoring_service.dart` lignes 430, 480, 529 (jamais exécutées).

---

## 5. Architecture prévue

```
lib/services/obd/
├── elm327_protocol.dart      fonctions pures (découpage, validité, décodages) — testables
├── obd_transport.dart        interface commune (connect, disconnect, send, état)
├── ble_obd_transport.dart    flutter_reactive_ble : recherche par préfixe « IOS-Vlink »,
│                             connexion, MTU, notifications, découpage MTU−3,
│                             réassemblage jusqu'au « > »
├── obd_command_queue.dart    file d'attente : UNE commande à la fois
├── elm327_session.dart       logique portée du Kotlin
└── obd_protocol_store.dart   protocole mémorisé par VIN (shared_preferences)
test/ : faux boîtier qui rejoue des réponses fragmentées
```

`bluetooth_obd_service.dart` garde **exactement la même interface publique** → les tests
existants ne cassent pas (aucun test n'utilise le canal natif, vérifié le 04/10/2026).

---

## 6. Autorisations

**Android** (minSdk 28) — à remettre dans AndroidManifest.xml :
- `BLUETOOTH_SCAN` avec `android:usesPermissionFlags="neverForLocation"` (Android 12+) ;
- `BLUETOOTH_CONNECT` (déjà présent) ;
- `BLUETOOTH` et `BLUETOOTH_ADMIN` avec `android:maxSdkVersion="30"` ;
- `ACCESS_FINE_LOCATION` avec `android:maxSdkVersion="30"` (Android 9 à 11 ; la
  localisation du téléphone doit aussi être activée — message clair à prévoir).
- Écran d'explication AVANT chaque demande. Politique de confidentialité : localisation
  utilisée uniquement pour trouver le boîtier, sur Android 9 à 11.

**iPhone** :
- `NSBluetoothAlwaysUsageDescription` (déjà présent, Info.plist lignes 69-70) ;
- Podfile (iOS-SETUP) avec la macro `PERMISSION_BLUETOOTH=1` pour permission_handler ;
- `Permission.bluetooth` sur iPhone (pas `bluetoothConnect`) ;
- `UIBackgroundModes` → `bluetooth-central` : chantier B50, pas celui-ci.

---

## 7. Étapes

| # | Étape | Durée | Vérification |
|---|---|---|---|
| 0 | Identifiants BLE du boîtier | — | **Fait (04/10, Pascal)** |
| 1 | Décodeurs purs (`elm327_protocol.dart`) | 1-2 j | Tests unitaires |
| 2 | File d'attente + session avec faux boîtier | 2-3 j | Tests (fragments, délais, coupure, commande vide interdite) |
| 3 | Transport BLE + autorisations Android + écran d'explication | 3-4 j | Samsung : recherche « IOS-Vlink », connexion, ATZ → `>` |
| 4 | Brancher `BluetoothObdService` (derrière `feature_obd_ble`, Android) | 2 j | Tous les tests + Samsung |
| 5 | Écrans : recherche au lieu d'« appareils appairés », plus de code PIN | 2 j | Samsung, vérification visuelle |
| 6 | Essais sur route Android (≥ 2 véhicules, coupure volontaire, 30 min+) | 1-2 sem. | Pascal |
| 6b | Correction des 2 limites de lecture des codes (section 4) | à estimer | Tests + véhicule |
| 7 | iPhone (après iOS-SETUP) | 1 sem.+ | Vrai iPhone + Vgate via TestFlight |
| 8 | Suppression du code OBD Kotlin et de l'interrupteur | ½ j | Android + iPhone |
| 9 | **OBLIGATOIRE avant publication** — Autorisations ↔ politique de confidentialité (BACKLOG B78) | ½ j | Les autorisations réellement déclarées (`AndroidManifest.xml`, `Info.plist`) et demandées (`Permission.*`) correspondent **mot pour mot** à la section 5 de `docs-projet/juridique/POLITIQUE_CONFIDENTIALITE.md` ; sinon corriger, puis régénérer l'écran (procédure CLAUDE.md) |

---

## 8. Ce qui ne pourra être vérifié que sur un vrai iPhone

Connexion BLE réelle et notifications, demande d'autorisation et son texte,
permission_handler une fois le Podfile réglé, taille réelle des paquets et réassemblage,
comportement écran verrouillé / arrière-plan, reconnexion après coupure du contact.

---

## 9. Pistes futures (hors chantier OBD-BLE, décision de Pascal requise)

### Vraie pression d'huile via les PID constructeur (mode 22)

Décision de Pascal (04/10/2026) : la fonction « pression d'huile » est **conservée**,
mais **débranchée de `010B`** (qui est la pression d'admission / MAP, pas l'huile).
La norme OBD-II (mode 01) **ne contient aucune valeur standard de pression d'huile**.

Piste : lire la vraie pression d'huile avec les **PID constructeur (mode 22)**, sur les
marques et modèles qui ont un **capteur** de pression (et pas seulement un **manocontact**
tout-ou-rien, qui n'allume que le voyant).

À étudier avant tout code :
- quelles marques/modèles ont un capteur, et avec quel identifiant (DID) et quelle formule ;
- adressage du bon calculateur (`ATSH` + en-têtes), surtout en CAN ;
- source fiable et licite des identifiants (documentation constructeur, base communautaire
  ou commerciale) ;
- repli clair pour toutes les autres voitures : « pression d'huile non disponible sur ta
  voiture, surveille le voyant d'huile » (mis en place par le correctif 010B).

---

*Créé le 04/10/2026 — à compléter au démarrage du chantier.*
