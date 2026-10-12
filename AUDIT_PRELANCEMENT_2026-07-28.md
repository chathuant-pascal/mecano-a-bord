# Audit pré-lancement — Mécano à Bord
**Date : 28 juillet 2026**
**Périmètre : application Flutter uniquement** (`mecano_a_bord/`)
**Méthode : lecture de code + `git log` + exécution de `flutter test`. Aucun fichier modifié.**

Projet racine : `C:\Users\karuc\OneDrive\Bureau\Mecano A Bord\mecano_a_bord`
Comparé aux audits précédents : `AUDIT_MECANO_A_BORD_V1.md` et `AUDIT_MECANO_A_BORD_CURSOR_V1.md` (racine du dépôt).

---

## 1. Configuration Android / Google Play

| Point | Statut | Détail |
|---|---|---|
| targetSdk / compileSdk | **OK** | `android/app/build.gradle.kts:18,36` — non codés en dur, dérivés de `flutter.compileSdkVersion` / `flutter.targetSdkVersion`. Le SDK Flutter installé (**3.41.2 stable**, `C:\flutter`) fixe ces deux valeurs à **36** (`packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt:23,34`), au-dessus du minimum API 35 exigé au 31/08/2026. ⚠️ Valeur dépendante du SDK Flutter utilisé au build — à revérifier si la CI/le poste de build utilise une version Flutter différente. |
| Cohérence du package `fr.mecanoabord.app` | **OK** | `namespace` et `applicationId` : `android/app/build.gradle.kts:17,32`. `MainActivity.kt:1` (`package fr.mecanoabord.app`) et son chemin `android/app/src/main/kotlin/fr/mecanoabord/app/MainActivity.kt` correspondent. Le `MethodChannel` `"fr.mecanoabord.app/obd"` est identique côté natif (`MainActivity.kt:26`) et côté Dart (`bluetooth_obd_service.dart:109`). |
| `android/key.properties` | **OK** | Fichier présent, référence `storeFile=../mecanoabord-release.jks` (= le fichier à la racine du projet Flutter) et `keyAlias=mecanoabord`. Non commité : `git check-ignore` confirme qu'il est exclu par `android/.gitignore:12` (`key.properties`) et que `mecanoabord-release.jks` est exclu par `.gitignore:48` (`*.jks`) ; `git ls-files` ne retourne aucun de ces deux fichiers. |

**⚠️ Point non demandé mais important repéré en marge :** le projet vit dans `OneDrive\Bureau\Mecano A Bord\`. `.gitignore` protège Git, **pas OneDrive** : le keystore de release (`mecanoabord-release.jks`) et `key.properties` (qui contient en clair les mots de passe du keystore) sont donc probablement synchronisés vers le cloud Microsoft à chaque modification, même s'ils ne sont jamais commités. Si ce n'est pas voulu, il faudrait soit exclure ces fichiers de la synchronisation OneDrive (attribut "toujours garder ce fichier hors ligne" ne suffit pas, il faut un exclude OneDrive ou déplacer le keystore hors du dossier synchronisé), soit accepter le risque en connaissance de cause. Aucune action prise — à votre décision.

---

## 2. Permissions Bluetooth (module OBD)

| Point | Statut | Détail |
|---|---|---|
| `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` déclarées | **OK** | `AndroidManifest.xml:2-5` — `BLUETOOTH`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`, `ACCESS_FINE_LOCATION`. `BLUETOOTH_ADVERTISE` absent, ce qui est correct : l'app n'émet jamais d'annonce BLE. |
| `maxSdkVersion=30` sur `ACCESS_FINE_LOCATION` | **À CORRIGER** | Absent du manifeste, tout comme `android:usesPermissionFlags="neverForLocation"` sur `BLUETOOTH_SCAN`. **Mais constat plus profond en creusant le code natif** : `MainActivity.kt:98` n'appelle que `adapter.bondedDevices` (liste des appareils déjà appairés) — aucun `startDiscovery()`, aucun `BluetoothLeScanner`. Côté Dart, seule `Permission.bluetoothConnect.request()` est jamais appelée (`obd_scan_screen.dart:427`, `home_screen.dart:257`) : `BLUETOOTH_SCAN` et `ACCESS_FINE_LOCATION` ne sont **même pas demandées au runtime**, elles sont juste déclarées dans le manifeste sans usage réel. → Le correctif le plus simple n'est pas d'ajouter `maxSdkVersion`/`neverForLocation`, mais de **supprimer purement `BLUETOOTH_SCAN` et `ACCESS_FINE_LOCATION` du manifeste**, qui ne servent à rien pour ce cas d'usage (connexion à un appareil déjà appairé = `BLUETOOTH_CONNECT` uniquement). Cela simplifie aussi la fiche de confidentialité Play Console (moins de permissions sensibles à justifier). |
| Demande runtime juste avant usage, avec explication préalable | **À CORRIGER (partiel)** | Le *timing* est bon : la permission est demandée juste avant l'usage (`obd_scan_screen.dart:426-437`, `home_screen.dart:257`). En revanche, **aucun texte/dialogue explicatif n'est affiché avant l'appel système** — `Permission.bluetoothConnect.request()` est appelé directement. L'onboarding évoque le Bluetooth de façon générale (`onboarding_screen.dart:72` : *"Il se connecte à votre téléphone en Bluetooth..."*) mais ce n'est pas une explication contextuelle immédiatement avant la demande système. |

---

## 3. WebView (formation intégrée)

| Point | Statut | Détail |
|---|---|---|
| `NavigationDelegate` en place | **OK — résolu depuis l'audit précédent** | `formation_webview_screen.dart:64-105`. Restriction stricte à une allowlist (`_isAllowedFormationHost`, lignes 14-20 : `mecanoabord.fr` et sous-domaines, `chathuant-pascal.github.io`), schémas non http/https bloqués, tout lien hors domaine s'ouvre dans le navigateur externe via `url_launcher` au lieu de charger dans la WebView (lignes 76-82). Correspond exactement au correctif recommandé dans `AUDIT_MECANO_A_BORD_V1.md` (BUG-04 / OWASP-02). |
| JavaScript activé seulement si nécessaire + inputs validés | **OK** | `setJavaScriptMode(JavaScriptMode.unrestricted)` (ligne 45) — nécessaire, la formation est un contenu HTML/JS interactif qui communique via le canal `MABFormation`. Le handler du canal JS (lignes 46-62) **vérifie que l'URL de la page courante a un schéma http/https et appartient à l'allowlist avant de faire confiance au message `'done'`** et d'écrire dans `SharedPreferences` — corrige aussi la faille signalée dans l'audit précédent (le canal `postMessage('done')` n'était lié à aucun domaine). |

---

## 4. Logs et mode release

| Point | Statut | Détail |
|---|---|---|
| Logs OBD bruts en Dart | **OK — résolu** | `lib/utils/mab_logger.dart` : `mabLog()` encapsule `debugPrint()` derrière `if (kDebugMode)`, silencieux en release. Recherche de tout `print(`/`debugPrint(` brut hors `mab_logger.dart` dans `lib/` → **0 résultat**. Le log OBD brut historique (`bluetooth_obd_service.dart:313`, `"OBD protocole $i: réponse brute = $rawResponse"`) passe maintenant par `mabLog`. Confirmé par les commits `1ab1263` et `3d548b9`. |
| Logs OBD bruts en natif Android | **À CORRIGER** | `MainActivity.kt` contient encore **3 appels `Log.d()` bruts, non conditionnés**, qui loguent des données OBD : <br>• `MainActivity.kt:320` — `Log.d(OBD_LOG_TAG, "Protocol $protocolIndex response: $testRaw")` (réponse brute ELM327) <br>• `MainActivity.kt:334` — message d'exception protocole <br>• `MainActivity.kt:596` — exception `readLiveData` <br>`android/app/build.gradle.kts:50-54` ne configure ni `minifyEnabled`/`isMinifyEnabled`, ni ProGuard/R8 pour le buildType `release` : ces `Log.d()` ne sont donc **pas supprimés en release** et resteront lisibles via `adb logcat` sur le build Play Store — même catégorie de fuite que le point initialement corrigé côté Dart, simplement déplacée côté natif. |
| Clés API en dur | **OK** | Aucune clé API en dur trouvée. Les clés (ChatGPT, Claude, Gemini, Mistral, Perplexity, Grok, DeepSeek, Qwen) sont saisies par l'utilisateur dans Réglages et stockées via `flutter_secure_storage` (`ai_conversation_service.dart`), jamais codées dans le code source. |

---

## 5. RGPD / confidentialité

| Point | Statut | Détail |
|---|---|---|
| Politique de confidentialité accessible en permanence | **OK** | `Réglages → Application → "Politique de confidentialité"` (`settings_screen.dart:1017-1021`, route `/privacy-policy` → `privacy_policy_screen.dart`), en plus de son affichage éventuel à l'onboarding — pas seulement à l'onboarding. |
| Consentement aussi facile à retirer qu'à donner | **OK / NON APPLICABLE** | Il n'existe pas d'écran de consentement RGPD formel (aucune case "j'accepte" trouvée dans `onboarding_screen.dart`) — cohérent avec le fait qu'aucune donnée ne quitte l'appareil par défaut (`privacy_policy_screen.dart` section 3 : *"Toutes vos données sont stockées uniquement sur votre téléphone"*) et qu'aucun SDK tiers de tracking/analytics n'est intégré. Le seul point de partage optionnel avec un tiers (clé API IA personnelle envoyée au fournisseur choisi) se retire aussi facilement qu'il se configure : bouton **"Retirer la clé"** dans Réglages (`settings_screen.dart:917-927`, `_confirmRemoveApiKeyFor`). |
| Firebase mentionné explicitement | **NON APPLICABLE** | Firebase n'est **pas intégré** à l'app : aucune dépendance `firebase_*` dans `pubspec.yaml`, aucun `google-services.json` trouvé. Seule mention du mot "Firebase" : un commentaire de doc dans `lib/config/mab_features.dart:6,31` anticipant le futur module licence (voir point 7). Rien à afficher tant que le SDK n'est pas intégré — **mais à ajouter dans la politique de confidentialité dès que le module licence d'Inès sera câblé.** |
| Minimisation des données | **OK, avec un doublon du point 2** | Les données listées dans la politique (`privacy_policy_screen.dart` section 2 : profil véhicule, documents, entretien, clé API perso, données OBD, préférences) correspondent aux fonctionnalités réellement implémentées. Seul écart : `ACCESS_FINE_LOCATION` est déclarée dans le manifeste mais jamais utilisée pour obtenir une position (aucun `Geolocator`/`Position` dans le code) — la politique le mentionne d'ailleurs elle-même comme "requise par Android pour le scan Bluetooth" (section 5), ce qui n'est même plus exact vu le constat du point 2 (aucun scan actif, permission superflue). |

---

## 6. Complétude / stabilité

| Point | Statut | Détail |
|---|---|---|
| Placeholders / TODO / écrans inachevés | **OK, avec une réserve** | Aucun `TODO`/`FIXME`/"Lorem ipsum" dans `lib/`. `PlaceholderScreen` (`lib/screens/placeholder_screen.dart`) existe mais n'est **référencée par aucune route** dans `main.dart` ni appelée nulle part — code mort, sans impact utilisateur. <br>**Réserve trouvée :** dans `Réglages → Assistant IA`, les fournisseurs **"Copilot"** et **"Meta AI"** apparaissent dans la grille de sélection et acceptent l'enregistrement d'une clé API (`settings_screen.dart` lignes 44-45 et 61-62, `_aiProviderLabel`/`_aiProviderDisplayLabel`), mais **aucun appel réseau n'est implémenté** pour ces deux fournisseurs dans `ai_conversation_service.dart` : les sélectionner et poser une question renvoie systématiquement `AiError('$label sera disponible prochainement.')` (`ai_conversation_service.dart:682`). Pas de crash, mais un parcours accessible depuis le menu principal qui ne fait pas ce qu'il semble promettre à l'utilisateur. |
| Bug écran diagnostic (audit précédent) | **OK — résolu** | `AUDIT_MECANO_A_BORD_V1.md` (BUG-01) signalait *"Écran diagnostic ne fonctionne plus"*. Commit `0b16b60` — *"MODULE 1 validé : diagnostic OBD corrigé et testé"* (19/04/2026). Lecture actuelle de `obd_scan_screen.dart`, `bluetooth_obd_service.dart` et `diagnostic_guide_screen.dart` : logique cohérente, pas d'anomalie structurelle relevée. |
| Tests | **OK — 128/128** | `flutter test` exécuté intégralement : **`All tests passed!`**, `+128` (répartis sur `ai_conversation_service_test.dart`, `controllers/maintenance_controller_test.dart`, `controllers/vehicle_profile_controller_test.dart`, `mab_repository_test.dart`, `widget_test.dart`). Correspond exactement au nombre annoncé. |

---

## 7. Firebase / système de licence

| Point | Statut | Détail |
|---|---|---|
| `kFeatureLicence` toujours désactivé | **OK** | `lib/config/mab_features.dart:32` — `const bool kFeatureLicence = false;`, commentaire *"prévu avec Inès (Mission 2)"*. |
| Aucune fonctionnalité ne dépend silencieusement d'un état de licence non initialisé | **OK** | Recherche de toute référence à `kFeatureLicence` dans `lib/` → **aucune occurrence en dehors de sa propre déclaration**. Aucun écran, service ou route ne teste ce flag pour conditionner un accès — donc aucun risque de crash lié à un état de licence non initialisé, puisque rien n'en dépend encore. Cohérent avec le commentaire du fichier lui-même (*"Tant qu'aucun appel n'utilise ces constantes, elles documentent seulement l'intention produit"*). Aucune dépendance Firebase dans `pubspec.yaml` à ce stade. **À ré-auditer dès qu'Inès câble le module** (jeudi), notamment pour vérifier qu'un état "licence en cours de chargement" ne bloque/crash pas un écran qui l'utiliserait. |

---

## Synthèse — À corriger avant publication

1. **`AndroidManifest.xml`** : supprimer `BLUETOOTH_SCAN` et `ACCESS_FINE_LOCATION` (non utilisées — l'app ne fait que lire les appareils déjà appairés) *(section 2)*.
2. **`MainActivity.kt:320,334,596`** : retirer ou conditionner (`BuildConfig.DEBUG`) les 3 appels `Log.d()` qui exposent des réponses OBD brutes en build release *(section 4)*.
3. **UX permission Bluetooth** : ajouter un texte explicatif avant l'appel à `Permission.bluetoothConnect.request()` *(section 2)*.
4. **Réglages → Assistant IA** : Copilot et Meta AI sont sélectionnables mais non fonctionnels — les masquer ou les implémenter avant publication *(section 6)*.
5. **OneDrive** *(hors périmètre technique, à votre arbitrage)* : le keystore et son mot de passe en clair se trouvent dans un dossier synchronisé cloud *(section 1)*.

Aucun de ces points n'a été modifié — en attente de votre validation avant toute correction.
