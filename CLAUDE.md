# CLAUDE.md — Mémoire Permanente Claude Code
# Projet : Mécano à Bord — Écosystème Complet
# Dernière mise à jour : 11/10/2026 — Version 5.1
# © Mécano à Bord — Pascal Chathuant — Guadeloupe
# ================================================================
# ⚠️ CE FICHIER EST LA MÉMOIRE PERMANENTE DE CLAUDE CODE
# À placer à la racine du dossier : Mecano A Bord/
# Claude Code le lit automatiquement à chaque session
# Il remplace intégralement la Version 4.0 du 03/08/2026
# ================================================================

---

## ⚠️ LECTURE OBLIGATOIRE À CHAQUE SESSION — DANS CET ORDRE

```
ÉTAPE 1 → Lire CE FICHIER (CLAUDE.md) en entier — surtout la RÈGLE 0
ÉTAPE 2 → Lire docs-projet/BACKLOG.md et docs-projet/EVOLUTION.md
ÉTAPE 3 → Lire REMOTE_CONFIG.md (kill switch)
ÉTAPE 4 → Lire docs-projet/VERIFICATION_REGLES_DEVELOPPEUR.md
ÉTAPE 5 → Lire .cursor/rules/contexte-pascal-mab.mdc
ÉTAPE 6 → Lire .cursor/rules/mab-design-system-figma.mdc
ÉTAPE 7 → Si le chantier touche un point d'audit : AUDIT_PRELANCEMENT_2026-07-28.md
          (le plus récent), puis AUDIT_MECANO_A_BORD_V1.md et
          AUDIT_MECANO_A_BORD_CURSOR_V1.md (historiques, avril 2026)
ÉTAPE 8 → Seulement après : rappeler à Pascal la liste « CE QUI RESTE À FAIRE »
          (section dédiée plus bas) et lui demander par quoi commencer
```

⚠️ Ne jamais sauter ces lectures. Elles contiennent les règles intouchables du projet.

⚠️ Les documents REFERENTIEL_FONCTIONNEL_INES.md (racine) et
docs-projet/archives/REFERENTIEL_FONCTIONNEL_INES_2026-04_obsolete.html
datent d'avril 2026.
Plusieurs points y sont PÉRIMÉS (licence, keystore, package name, Firebase sont
désormais faits). Les utiliser comme description fonctionnelle, jamais comme
état d'avancement. En cas de contradiction, CE FICHIER fait foi.

---

## QUI EST PASCAL

- **Nom** : Pascal Chathuant
- **Localisation** : Sainte-Rose, Guadeloupe
- **Profession** : Électromécanicien et entrepreneur, 25+ ans d'expérience en préparation/reprogrammation moteur
- **Statut** : entrepreneur individuel (EI), entreprise créée le 21/09/2026 (SIREN 531007128) — **SIRET encore attendu**
- **Niveau programmation** : Débutant complet — expliquer simplement, sans jargon
- **Mode de travail** : Guidé pas à pas, une chose à la fois, validation avant de continuer, diagnostic (lecture seule) avant toute modification
- **Règle absolue** : Ne jamais modifier un fichier sans avoir montré ce qui va être changé et obtenu l'accord de Pascal ; ne jamais commit/push sans accord explicite
- **Workspace** : `C:\Users\karuc\OneDrive\Bureau\Mecano A Bord\`
- **Téléphone de test** : Samsung SM-A137F (Android 14), build release installé
- **Boîtier OBD de test** : Vgate iCar Pro BLE 4.0 (fonctionne aujourd'hui avec l'app sur Android)
- **Développeuse** : Inès (freelance, très occupée) — a réalisé le système de licences et l'instrumentation analytics avec Pascal ; téléphone de test (Samsung A36) encore en build debug, transition release à faire à la prochaine rencontre

---

## 🚨 RÈGLE 0 — NOUVELLE ET PRIORITAIRE SUR TOUT (30/09/2026)

```
TOUT CE QUI EST CODÉ DOIT FONCTIONNER SUR ANDROID ET SUR iPHONE.

Pascal a choisi Flutter précisément pour avoir UN SEUL CODE pour les deux
systèmes. Il vend son offre à tous les débutants francophones, sans jamais
leur demander quel téléphone ils ont. C'est essentiel au bon fonctionnement
et à la vente de l'application.

Conséquences obligatoires pour chaque chantier :
1. Avant d'ajouter une bibliothèque (pub.dev ou native), vérifier qu'elle
   supporte officiellement Android ET iOS. Si elle ne supporte qu'un seul
   système : NE PAS l'ajouter, le signaler à Pascal et proposer une
   alternative compatible.
2. INTERDIT d'écrire de la logique métier en code natif spécifique à une
   plateforme (Kotlin/Java seulement, ou Swift seulement). La logique vit
   en Dart. Du code natif n'est toléré que s'il existe pour les DEUX
   plateformes, avec l'accord explicite de Pascal.
3. Toute nouvelle autorisation (Bluetooth, caméra, micro, photos,
   localisation, notifications, arrière-plan…) doit être déclarée des DEUX
   côtés : AndroidManifest.xml ET ios/Runner/Info.plist (avec un texte
   d'explication en français, simple, pour un débutant).
4. Tout fonctionnement en arrière-plan doit être prévu pour les deux
   systèmes (Foreground Service Android + UIBackgroundModes iOS).
5. Chaque plan présenté à Pascal contient une ligne :
   « Compatibilité : Android ✅ / iOS ✅ » — ou explique précisément ce qui
   manque pour l'un des deux.
6. Chaque rapport de fin de chantier précise ce qui a été testé sur Android,
   ce qui n'a PAS pu être testé sur iPhone, et ce qu'il faudra vérifier
   sur un vrai iPhone.
7. Le code existant qui viole cette règle (voir « Dette iOS ») doit être
   corrigé progressivement — jamais aggravé.
```

---

## 🚨 RÈGLES INTOUCHABLES — NE JAMAIS VIOLER

```
RÈGLE 1 — VOIX TTS FÉMININE
→ pitch : 1.2 (figé — ne jamais modifier)
→ speechRate : 0.5 (figé — ne jamais modifier)
→ Fichier : lib/services/tts_service.dart

RÈGLE 2 — MOTS INTERDITS
→ Ne jamais utiliser dans les textes ET messages vocaux :
   ❌ "panne"   ❌ "danger"   ❌ "défaillance"
→ Remplacer par : "problème détecté", "attention requise", "vérification nécessaire"
→ Exception : les textes juridiques (mentions légales, CGV) peuvent
  employer le vocabulaire juridique exact si nécessaire — le signaler à Pascal

RÈGLE 3 — DESIGN SYSTEM OBLIGATOIRE
→ Utiliser EXCLUSIVEMENT : MabColors / MabTextStyles / MabDimensions
→ Interdit : valeurs hardcodées (ex: Color(0xFFCC0000), fontSize: 16)
→ Fichier référence : lib/theme/mab_theme.dart

RÈGLE 4 — ACCESSIBILITÉ
→ Zones tactiles minimales : 48dp (norme EAA 2025)

RÈGLE 5 — PROFILS VÉHICULE
→ Maximum 2 profils — le 3e doit être refusé (StateError)

RÈGLE 6 — PÉRIMÈTRE V1 STRICT
→ Interdit de coder ou préparer les modules V2/V3/V4 sans accord Pascal
→ Un flag sans fonctionnalité correspondante (ex. feature_rappels_admin) reste
  documenté "réservé, sans effet" plutôt que de construire une fonctionnalité pour lui

RÈGLE 7 — ENCODAGE UTF-8 OBLIGATOIRE POUR formation-web/index.html
→ Set-Content : -Encoding utf8NoBOM / Get-Content : -Encoding utf8
→ Remplacements globaux : [System.IO.File]::ReadAllText/WriteAllText en UTF8

RÈGLE 8 — COMMIT/PUSH
→ Aucun commit ni push sans accord explicite de Pascal, même après plusieurs
  fichiers validés un par un
→ Revue de commit systématique avant tout commit : lister les fichiers touchés,
  confirmer qu'aucun chantier en cours non lié n'est inclus par erreur

RÈGLE 9 — HONNÊTETÉ SUR LA VÉRIFICATION
→ Ne jamais affirmer qu'un comportement fonctionne sans preuve — dire
  explicitement ce qui n'a pas pu être vérifié (visuellement, sur téléphone,
  sur iPhone) et ce qui reste à tester par Pascal

RÈGLE 10 — DISCRÉTION FOURNISSEURS (NOUVEAU)
→ Dans tout document destiné à un fournisseur (Vgate ou autre), ne jamais
  décrire les fonctions de l'app ni l'usage prévu du boîtier. Pascal se
  présente comme une entreprise française qui vend le boîtier sous sa marque.

RÈGLE 11 — VOUVOIEMENT DANS LES TEXTES JURIDIQUES (NOUVEAU)
→ Mentions légales, politique de confidentialité, CGV : vouvoiement partout.
  La formation et l'app peuvent tutoyer ailleurs.
```

---

## ⚙️ MÉTHODOLOGIE DE TRAVAIL OBLIGATOIRE

### Processus obligatoire pour chaque fonctionnalité

```
ÉTAPE 1  → Audit lecture seule du code existant, sans rien modifier
ÉTAPE 2  → Présenter le diagnostic complet à Pascal, proposer un plan
           (avec la ligne « Compatibilité : Android / iOS » — RÈGLE 0)
ÉTAPE 3  → Attendre validation du plan avant de toucher au code
ÉTAPE 4  → Développer / corriger, un fichier à la fois, montré avant le suivant
ÉTAPE 5  → Try/catch sur tous les points de défaillance
ÉTAPE 6  → Tests unitaires (nominal / erreur / limite) quand la stack le permet
ÉTAPE 7  → flutter analyze + flutter test après chaque étape, confirmer
           le nombre de tests avant/après
ÉTAPE 8  → Valider visuellement quand possible (Samsung SM-A137F Android 14),
           sinon le dire explicitement ; préciser ce qui reste à tester sur iPhone
ÉTAPE 9  → Mettre à jour docs-projet/EVOLUTION.md et BACKLOG.md
ÉTAPE 10 → Revue de commit (liste des fichiers, exclusions vérifiées)
ÉTAPE 11 → Commit/push uniquement après accord explicite de Pascal
```

### Try/Catch — obligatoire sur
SharedPreferences, SQLite/sqflite, appels API (IA, plaque, Firebase),
connexion Bluetooth OBD, WebView, ouverture de fichiers, image/file picker,
toute opération réseau.

### Tests unitaires — obligatoires
Cas nominal / cas d'erreur / cas limite. Pour la logique métier sensible sans
DI de test existant (ex. services OBD), extraire la logique de décision pure
en fonctions/classes `@visibleForTesting` plutôt qu'un refactor DI complet risqué.

### Audit OWASP — checklist
Données sensibles chiffrées (FlutterSecureStorage / Keychain), HTTPS uniquement,
aucun log sensible en release (ni Dart ni natif), WebView avec NavigationDelegate
strict, entrées validées, permissions justifiées et déclarées sur les deux systèmes.

### Audit UX — checklist
Public débutant/anxieux, langage simple, messages d'erreur compréhensibles,
feedback visuel à chaque action, bouton "Réessayer" si réseau absent, mots
interdits absents, texte explicatif AVANT chaque demande d'autorisation système.

### Feature Flags
Le vrai kill switch à distance est `lib/services/remote_feature_flags.dart`
(Firebase Remote Config). `lib/config/mab_features.dart` = valeurs de repli.
Ne jamais recréer un système de flags parallèle. Voir REMOTE_CONFIG.md.

### Logger conditionnel
`lib/utils/mab_logger.dart` — `mabLog()` conditionné par `kDebugMode`.
Aucun `print`/`debugPrint` brut en Dart. Aucun `Log.d()` brut en natif.

---

## 📱 DETTE iOS — ÉTAT RÉEL (audit du 30/09/2026)

```
CE QUI EST DÉJÀ BON
✅ Tous les packages pub.dev du projet supportent Android ET iOS.
✅ flutter_reactive_ble (Android + iOS) est DÉJÀ dans pubspec.yaml,
   prévu pour le Vgate iCar Pro — mais jamais utilisé dans le code.
✅ Le Vgate iCar Pro BLE 4.0 est compatible Android ET iPhone (Bluetooth BLE).
✅ Info.plist : NSBluetoothAlwaysUsageDescription et NSMicrophoneUsageDescription présents.

LE PROBLÈME PRINCIPAL — CONNEXION OBD 100 % ANDROID
❌ Toute la communication OBD est dans android/app/src/main/kotlin/fr/
   mecanoabord/app/MainActivity.kt (756 lignes, Kotlin), via le MethodChannel
   "fr.mecanoabord.app/obd" appelé depuis bluetooth_obd_service.dart.
   Fonctions : getBondedDevices, connect (Bluetooth CLASSIQUE, RFCOMM/SPP,
   UUID 00001101-...), tryProtocol (ATZ, ATE0, ATL0, ATH0, ATAT1, ATSPx,
   détection parmi 10 protocoles via 0100), readVehicleDataStep (0101, 03,
   07, 0A + décodage DTC), readLiveData (0105 température, 0142 tension,
   010B pression admission, 010C régime), clearDtcCodes (04),
   resetObdNativePrefs (protocole mémorisé par VIN).
❌ Aucun équivalent iOS (AppDelegate.swift = squelette par défaut).
❌ Apple INTERDIT le Bluetooth classique (SPP) aux accessoires non certifiés
   MFi → sur iPhone, seul le BLE (GATT) est possible.

LA SOLUTION RETENUE (chantier « OBD-BLE », voir priorités)
→ Réécrire la communication OBD UNE SEULE FOIS en Dart pur avec
  flutter_reactive_ble, en BLE, pour Android ET iOS.
→ Porter en Dart toute la logique Kotlin : init ELM327, détection des 10
  protocoles, 4 PID temps réel, 4 étapes de diagnostic, décodage DTC,
  effacement des codes, mémorisation du protocole par VIN.
→ Gérer la fragmentation BLE (MTU ~20 à 244 octets, notifications
  asynchrones, réassemblage des réponses jusqu'au prompt ">").
→ UUID GATT du Vgate iCar Pro BLE 4.0 à obtenir (documentation Vgate —
  Pascal peut la demander — ou lecture avec un scanner BLE générique).
  Le boîtier expose deux noms : IOS-VLINK et ANDROID-VLINK.
→ Conserver TOUS les correctifs du chantier OBD/surveillance d'août
  (race condition, engineRunning sans RPM, plausibilité, délai d'arrêt,
  vérif connexion avant démarrage manuel) et la formule RPM ((A*256)+B)/4.0.
→ Décision à faire valider par Pascal : garder ou non un chemin Bluetooth
  classique pour d'anciens boîtiers (recommandation : tout en BLE, le boîtier
  officiel de l'offre sera le Vgate iCar Pro BLE 4.0).
→ Une fois le port validé : supprimer le code OBD de MainActivity.kt (ses
  3 Log.d() — lignes 320, 336, 605 — sont DÉJÀ protégés par
  `if (BuildConfig.DEBUG)`, vérifié le 04/10/2026 : aucun log en release).
→ Ampleur estimée : plusieurs semaines, tests sur véhicules réels inclus.
  C'est l'argument de vente n°1 : aucune régression tolérée.

⚠️ CONSÉQUENCE SUR LES PERMISSIONS ANDROID
BLUETOOTH_SCAN et ACCESS_FINE_LOCATION sont DÉJÀ ABSENTS de
AndroidManifest.xml (vérifié le 04/10/2026 : seuls BLUETOOTH et
BLUETOOTH_CONNECT sont déclarés), conformément à l'audit du 28/07
(inutiles avec le Bluetooth classique appairé).
Avec le passage au BLE, ils devront être REMIS dans le chantier OBD-BLE,
avec les bons flags :
- BLUETOOTH_SCAN avec android:usesPermissionFlags="neverForLocation"
  (Android 12+) ;
- ACCESS_FINE_LOCATION avec android:maxSdkVersion="30" (Android 9 à 11,
  minSdk = 28) ;
- BLUETOOTH et BLUETOOTH_ADMIN avec android:maxSdkVersion="30"
  (aujourd'hui BLUETOOTH n'a pas de limite et BLUETOOTH_ADMIN manque).
La politique de confidentialité doit expliquer que la localisation sert
uniquement à trouver le boîtier Bluetooth (exigence Android), jamais à
suivre l'utilisateur.

SURVEILLANCE EN ARRIÈRE-PLAN — ABSENTE SUR LES DEUX SYSTÈMES (B50)
❌ Aujourd'hui, la surveillance ne tourne que si l'app est ouverte au premier
   plan. Si l'écran se verrouille ou si l'utilisateur ouvre le GPS ou la
   musique, elle s'arrête. C'est pourtant l'argument de vente n°1.
❌ AndroidManifest : aucune permission FOREGROUND_SERVICE ni WAKE_LOCK.
❌ Info.plist : aucun UIBackgroundModes (il faudra bluetooth-central).
→ À traiter JUSTE APRÈS le chantier OBD-BLE, directement sur le nouveau code,
  pour les deux systèmes.

AUTRES BLOCAGES iOS (chantier « iOS-SETUP », backlog B5b)
❌ Firebase iOS absent : pas de GoogleService-Info.plist ; firebase_options.dart
   (lignes 9-15) lève UnsupportedError hors Android → licence, Remote Config,
   Analytics, Crashlytics, Performance silencieusement inactifs sur iPhone,
   donc accès bloqué (l'écran licence dépend de Firestore).
   → Ajouter une app iOS dans le MÊME projet Firebase mecano-a-bord
     (même compte, gratuit), puis régénérer firebase_options.dart.
❌ Bundle ID placeholder com.example.mecanoABord (ios/Runner.xcodeproj/
   project.pbxproj lignes 375, 391, 408, 423, 554, 576) → à aligner sur
   fr.mecanoabord.app (identique à Android).
❌ Aucun ios/Podfile — le projet iOS n'a jamais été compilé.
❌ Info.plist manquants : NSCameraUsageDescription et
   NSPhotoLibraryUsageDescription (image_picker — sinon crash à l'ouverture
   de l'appareil photo/galerie), NSSpeechRecognitionUsageDescription
   (speech_to_text).
❌ Compte Apple Developer à ouvrir par Pascal (~99 $/an ; inscription
   « particulier » = son nom affiché, « organisation » = « Mécano à Bord »
   mais numéro D-U-N-S requis, gratuit, quelques jours).
→ Compilation sans Mac : Codemagic (500 minutes macOS M2 gratuites/mois,
  compte personnel ; 0,095 $/min au-delà ; signature iOS et envoi
  App Store Connect / TestFlight intégrés). Claude Code prépara
  codemagic.yaml le moment venu.
→ Test obligatoire sur un vrai iPhone avec le Vgate (le Bluetooth ne se
  teste pas sur simulateur) — via TestFlight.
```

---

## 📋 ÉTAT DES CHANTIERS TERMINÉS

```
MODULE 1  → Bug diagnostic OBD + audit OBD/surveillance      ✅ TERMINÉ
            2 bugs critiques + 4 points corrigés (race condition annonce
            vocale de déconnexion, engineRunning muet sans PID RPM,
            plausibilité physique, délai d'arrêt configurable, vérif
            connexion avant démarrage manuel, nettoyage). Tests 167→195.
            Poussé : e1baa85..0820678. Reste : test terrain avec coupure
            volontaire du dongle en conduite réelle.
MODULE 2  → Keystore release                                  ✅ TERMINÉ
            mecanoabord-release.jks + key.properties (exclus de Git).
            ⚠️ Toute installation release sur un téléphone en debug exige :
            désinstallation + vider deviceId du document licenses/{code}
            dans Firestore + réinstallation + ressaisie du code.
MODULE 3  → Package name fr.mecanoabord.app (Android)         ✅ TERMINÉ
            ⚠️ iOS encore en com.example.mecanoABord (voir Dette iOS).
MODULE 4  → WebView sécurisée (NavigationDelegate, allowlist
            mecanoabord.fr + chathuant-pascal.github.io, canal JS vérifié) ✅ (audit 28/07)
MODULE 5  → debugPrint Dart → mabLog                          ✅ (audit 28/07)
            Les 3 Log.d() de MainActivity.kt (320, 336, 605) sont déjà
            protégés par BuildConfig.DEBUG (vérifié le 04/10/2026) ;
            ils disparaîtront avec le chantier OBD-BLE.
MODULE 6  → Kill switch Firebase Remote Config                ✅ TERMINÉ
            Voir REMOTE_CONFIG.md (flags booléens + discord_invite_url +
            10 clés tutoriels URL/durée + feature_tutoriels).
MODULE 8  → Licence Firebase MAB-XXXX-XXXX-XXXX               ✅ TERMINÉ
            Liée à l'UID Firebase anonyme. Collection licenses/{code}.
Analytics → formation_events, consent_stats, feedback (formulaires de
            retour avec masquage des données sensibles, conservation 2 ans),
            Firebase Analytics avec consentement, device_info_plus. ✅
Séquence de démarrage / animation d'entrée (MabEntranceAnimation)  ✅
            Bug résiduel connu : MabLogo(withText:false) pointe vers
            logo_mark.png qui contient du texte.
Projet Firebase mecano-a-bord : forfait Blaze. Second administrateur
            (Propriétaire) : karucards@gmail.com avec double authentification.
```

---

## 🧭 CE QUI RESTE À FAIRE — LISTE COMPLÈTE (à rappeler à Pascal)

⚠️ Claude Code : à chaque début de session, rappelle cette liste à Pascal
(version courte) et demande-lui par quoi commencer. Coche/ajuste ce fichier
et BACKLOG.md au fur et à mesure.

### 🔴 PRIORITÉ 1 — Conformité légale (texte uniquement, rapide)

```
Chantier « CONFORMITÉ » — prompt en 6 parties préparé par Claude (chat),
à lancer par Pascal. Décisions déjà prises :
- E-mail client UNIQUE : mecanoabord@gmail.com (remplace contact@mecanoabord.fr
  partout : help_contact_screen.dart, privacy_policy_screen.dart,
  mab_legal_mentions_body.dart…) — confirmé par Pascal le 11/10/2026 et
  utilisé dans les CGV ; les 3 fichiers Dart affichent encore contact@.
- CGV RÉDIGÉES le 11/10/2026 (version définitive, en relecture par Pascal) :
  docs-projet/juridique/CGV_MECANO_A_BORD.md + CGV_SYSTEMEIO.txt (texte à
  coller dans Systeme.io, généré depuis le .md — toujours modifier le .md
  d'abord). Décisions : produit présenté comme entièrement prêt, Android ET
  iPhone sans réserve (iOS terminé avant toute mise en vente) ; AUCUNE
  mention de bêta ; aucun prix chiffré (prix = page de vente au jour de la
  commande ; répartition boîtier / numérique sur la page de vente et dans
  la confirmation de commande) ; clause générale « offres promotionnelles
  et prix de lancement » (art. 6) ; PAS de prix barré au lancement, seulement
  « prix de lancement » (art. L. 112-1-1 : prix de référence = plus bas prix
  des 30 jours précédents) ; garantie commerciale 14 jours (art. 13, plus de
  « satisfait ou remboursé ») = remboursement intégral si demande sous 14 j
  après réception du boîtier + aucun module commencé À PARTIR DU MODULE 1
  (Module 0 exclu) vérifié via formation_events + boîtier retourné complet,
  retour à la charge du client ; licence désactivée après remboursement.
  Éléments entre crochets et points ouverts : BACKLOG B71 à B76.
- Politique de confidentialité (app + formation web) : ajouter le NOUVEL
  USAGE des données de progression (vérifier la garantie commerciale) —
  BLOQUANT avant mise en vente (B72).
- Éditeur : Pascal Chathuant, Entrepreneur individuel (EI) — Nom commercial
  Mécano à Bord — L'Anse des Îles, section Cluny, 97115 Sainte-Rose,
  Guadeloupe, France — Tél. +590 690 55 80 77 — Directeur de la
  publication : Pascal Chathuant — SIRET : placeholder visible
  « [à compléter avant mise en vente] » — Site de vente :
  mecanoabord.systeme.io — Formation : mecanoabord.fr
- Formation web : la politique de confidentialité affirme « rien n'est envoyé
  à un serveur » → FAUX (verrou licence + formation_events). À corriger en
  priorité.
- Politique de confidentialité de l'app : regrouper TOUTES les données en
  section 2 (local vs envoyé à Firebase) ; transfert États-Unis → nommer le
  Data Privacy Framework UE–États-Unis + clauses contractuelles types ;
  ajouter les durées de conservation (VALIDÉ PAR PASCAL le 30/09/2026 :
  3 ans après la dernière activité pour licence et progression ; retours
  via formulaires 2 ans max) ; toute nouvelle utilisation de ces données
  (nouvelle fonctionnalité, analyse) doit être annoncée dans la politique
  de confidentialité AVANT d'être mise en place ;
  expliquer la permission de localisation (Bluetooth uniquement) ;
  vouvoiement partout (les sections 5 et 13 tutoient aujourd'hui).
- Hébergement Firebase : Canada (Montréal) pour Firestore ; données techniques
  possiblement aux États-Unis.
- Nouveau bloc « Compatibilité » (app + formation web) :
  Android 9+ ; [iPhone : à confirmer après le chantier iOS] (placeholder) ;
  véhicules OBD2 (Europe : essence ≥ 2001, diesel ≥ 2004 ; USA ≥ 1996) ;
  surveillance indisponible sur véhicules 100 % électriques ;
  boîtier Bluetooth compatible ELM327 ; ne remplace pas un professionnel.
- NE PAS toucher encore à « dongle OBD tiers » (limitation de responsabilité) :
  dépend du fournisseur (si le boîtier est vendu dans l'offre, il n'est plus
  « tiers »).
```

### 🔴 PRIORITÉ 2 — Chantier « OBD-BLE » (cœur du produit, Android + iOS)
Voir « Dette iOS ». Commencer par un PLAN détaillé en lecture seule, sans code.

### 🔴 PRIORITÉ 3 — Surveillance en arrière-plan (B50), Android + iOS
Juste après OBD-BLE, sur le nouveau code.

### 🔴 PRIORITÉ 4 — Chantier « iOS-SETUP » (B5b)
Firebase iOS, bundle ID, Podfile, Info.plist, Codemagic, TestFlight, iPhone réel.

### 🟠 Bloquants avant publication (Play Store ET App Store)

```
- SIRET à intégrer (mab_legal_mentions_body.dart ligne 60 + formation-web/
  index.html ligne ~4774) → nécessite une nouvelle version de l'app.
- Remplacer le placeholder iPhone du bloc Compatibilité.
- Revoir « dongle OBD tiers » selon le fournisseur retenu.
- Réglages → Assistant IA : Copilot et Meta AI sélectionnables mais NON
  fonctionnels (« sera disponible prochainement ») → les masquer ou les
  implémenter (décision Pascal).
- Texte explicatif AVANT chaque demande d'autorisation système (Bluetooth
  notamment — aujourd'hui Permission.bluetoothConnect.request() est appelé
  directement dans obd_scan_screen.dart et home_screen.dart).
- targetSdk = 36 via Flutter 3.41.2 (≥ API 35 exigée) — revérifier si la
  version de Flutter change.
- Fiche store : brouillon FICHE_STORE_DRAFT.md (description courte + longue)
  à valider par Pascal ; ajouter les informations de compatibilité.
- Validation VIN : ajouter le checksum ISO 3779 (glovebox_profile_screen.dart
  ~328-332) + aide « Où trouver le VIN ? » (carte grise rubrique E).
- Limite de taille d'upload 10 Mo (glovebox_screen.dart ~377-385).
- Transition release du téléphone d'Inès.
- Test terrain : coupure volontaire du dongle en conduite réelle.
```

### 🟠 État Git — DEUX dépôts (inventaire du 04/10/2026)

```
⚠️ Il y a DEUX dépôts Git distincts. Toujours vérifier les deux :
1. Dépôt principal (docs + formation-web) : chathuant-pascal/mecano-a-bord
   → racine « Mecano A Bord/ ». Le dossier mecano_a_bord/ y est EXCLU
     (.gitignore ligne 2).
2. Dépôt de l'application Flutter (privé) : chathuant-pascal/mecano-a-bord-app
   → dossier « Mecano A Bord/mecano_a_bord/ », avec son propre .git.

Avant tout nouveau chantier : `git status` + `git log origin/main..` dans
LES DEUX dépôts, et un plan de commits séparés (un par chantier).

DÉJÀ COMMITÉ ET POUSSÉ (vérifié le 04/10/2026 — ne plus les lister ici) :
- Parcours sans licence (optin → vidéo → achat → saisie code) :
  3761afe, 390c4b7 (app).
- Vitesse de cycle OBD + isHybrid : 0b28347 (app).
- Repère de position du sommaire : 79bf01c.
- Module 4 « Sous le capot » (menu, panneaux, déverrouillage 2/5) :
  fbe48c7, 36be29a, 715288e.
- Restructuration pneus 3a4cd8f : désormais poussée.
- Module Pneus séparé : déjà en place (« Étape 3 : Lire tes pneus comme
  un pro », index.html ~ligne 3589).
- Galeries photos pneus / batterie : aaa84b5, 3be0e6d, d5e6fd1…
- Lien Discord réel (index.html ~ligne 8276) : commité.
- Placement des vidéos, doublon vidéo du Module 2 : 6d4491a, 317d643.
- Coquille CSS bloc-regre-or : corrigée.
- Lot 3 (formulaires de retour), tutoriels vidéo (+ visuel accueil),
  correction des 2 avertissements flutter analyze : 939ba73, 7ce6315,
  d06732b, 5d1aec3 — fusionnés dans main et poussés le 04/10/2026 (app),
  validés par Pascal sur le SM-A137F le 04/10/2026.
  Règles Firestore du Lot 3 : vérifiées identiques à celles publiées.

RANGEMENT GIT TERMINÉ LE 04/10/2026 (dépôt principal) :
- Mot interdit « panne sèche » (index.html ligne 2957) : corrigé, 439f7eb.
- fix_partie2.ps1 et tmp_commit_6071.txt : supprimés (jamais suivis).
- Stash du 29/04 : sauvegardé puis effacé. Sauvegarde complète, vérifiée
  identique au stash (images comprises) :
  docs-projet/archives/stash_2026-04-29_complet.patch (23 Mo) ; version
  texte seule : stash_2026-04-29.patch. Les deux sont HORS suivi Git
  (.gitignore : docs-projet/archives/*.patch) — uniquement en local
  (OneDrive). Pour la réappliquer : partir du commit 6f6c4fa.
- « lire tes pneus comme un pro 2.png » : déplacée dans
  docs-projet/visuels-sources/, hors suivi Git (.gitignore), 5e4df45.
- Dernière étape : pousser la branche chantier-tutoriels-video du dépôt
  principal puis la fusionner dans main (vérifier avec
  `git log origin/main..` qu'il ne reste rien).

CONSERVÉ VOLONTAIREMENT (décisions Pascal) :
- Branche backup-avant-reorganisation (dépôt principal) : son contenu est
  déjà entièrement dans main.
- Branche chantier-tutoriels-video du dépôt app, sur GitHub, pour
  l'instant.
```

### 🟡 Formation web (formation-web/index.html — RÈGLE 7 UTF-8)

```
- Paragraphe à ajouter : vérifier seul ses ampoules (feux, clignotants,
  feux stop) en s'aidant de la tombée de la nuit.
- Photos réelles encore manquantes : PHOTO_A_REMPLACER_<liquide>.jpg
  (huile, direction assistée, frein, refroidissement, lave-glace, batterie).
- Vidéos direction assistée et batterie à finir (Pascal) ; vidéos frein,
  refroidissement encore en placeholder.
- Audit d'optimisation du chargement (lazy loading, WebP, Service Worker)
  fait — correction en attente du feu vert de Pascal.
- Verrou de licence formation-web : app Web Firebase dédiée dans le projet
  mecano-a-bord ; vérification du code MAB-XXXX contre Firestore ; l'app
  transmet le code via le fragment d'URL (#licence=...) pour éviter toute
  ressaisie. (Mettre à jour la politique de confidentialité en conséquence.)
- Vidéo d'optin : Pascal la tourne en réel (vertical 9:16) + CapCut ;
  ensuite remplacer l'ID placeholder dans formation-web/optin.html et
  valider l'URL de la page d'achat.
- Pointer mecanoabord.fr vers GitHub Pages (OVH, CNAME) ; puis mettre à jour
  lib/formation_url.dart (pointe encore vers GitHub Pages).
```

### 🟡 App — fonctionnalités décidées, pas encore faites

```
- Discord : bouton natif « Rejoindre la communauté » sur HomeScreen (juste
  après « La méthode sans stress auto », icône Icons.groups_rounded dorée,
  visible seulement après le Module 6) piloté par la clé Remote Config
  discord_invite_url → Pascal doit encore renseigner la clé dans la console.
- Tutoriels (5) : clips Seedance générés le 27/09 ; montage avec
  enregistrements d'écran à faire par Pascal ; puis renseigner les 10 clés
  Remote Config tutoriel_*_url / _duree. La carte « Bien démarrer » de
  l'accueil ne doit JAMAIS disparaître.
- Lot A kilométrage : saisie mensuelle manuelle + historique + recalage des
  rappels (sans notifications).
- Lot B : PID vitesse 010D + accumulation de distance OBD + notifications ;
  ajouter PID 0101 (voyant/nombre de DTC) et 012F (niveau carburant).
  → À faire APRÈS le chantier OBD-BLE, directement en Dart (plus de liste
  blanche Kotlin).
- Date automatique d'intervention : date du jour pré-remplie (modifiable) à
  chaque validation d'entretien, historique par type d'action, kilométrage
  du Lot A rattaché si disponible — universel, sans exception.
- Connexion automatique au démarrage : le Vgate iCar Pro se réveille seul au
  contact et se met en veille 30 min après l'arrêt du moteur (rien à coder
  pour la veille). Idée : détecter le boîtier et lancer la surveillance sans
  action de l'utilisateur. À étudier avec OBD-BLE + B50.
- Engagement quotidien : pas de gamification classique (points/badges/streaks
  écartés par Pascal) ; piste retenue = « présence rassurante » (ce que
  l'utilisateur ressent en refermant l'app). À approfondir avant de coder.
```

### 🟡 Demandes d'Inès — Centre de pilotage (à concevoir avec Pascal)

```
Inès a demandé un outil de monitoring du projet. Pascal le conçoit et le code
avec Claude, puis le soumet à Inès pour son expertise.
Deux volets :
1. Dashboard d'usage de l'app (analytics bêta).
2. Suivi d'avancement du projet (tâches, commits, blocages).
Exigences d'Inès :
- Un maximum de retours sur les performances (Crashlytics et Performance
  sont déjà dans le projet — vérifier qu'ils remontent bien).
- Anticiper les problèmes de connexion en production.
- Un PRA (plan de reprise d'activité), avec incidents remontés liés au PRA.
- Formulaires dans l'app pour que les utilisateurs remontent leur expérience
  (collection feedback DÉJÀ en place) → rapports générés par Claude.
- Pilotage centralisé technique / utilisateurs / marketing.
- Outil de veille qui détecte la casse.
- Solution de sécurité externe (intrusions, logs).
- Suivre le type de téléphone et la version du système (déjà partiellement
  via device_info_plus) — utile aussi pour suivre Android vs iPhone.
Ordre validé : socle Firebase (monitoring, formulaires, dashboard) →
Systeme.io → YouTube.
Pistes techniques déjà envisagées : sync Firestore → Supabase (GitHub
Actions), dashboard React hébergé sur Vercel — rien commencé.
```

### 🟡 Commercial / hors code (pour mémoire, Pascal gère)

```
- Fournisseur boîtier : Vgate (Shenzhen) contacté le 30/09/2026 via
  sale@vgate.com.cn (+ WhatsApp +86 183 8515 2467) : prix partenaire, logo +
  packaging, paiement unique par Pascal avec expédition directe à chaque
  client, transmission des adresses, colis neutres, douanes, garantie,
  CGV fournisseur. Agents européens : SL Elements GmbH (Allemagne),
  info@vgate.pl (Pologne).
- Logistique (décision du 11/10/2026) : le boîtier est stocké et expédié par
  Amazon (service d'expédition multicanal) depuis un entrepôt en France
  métropolitaine. Le client n'a aucun contrat ni contact avec Amazon : il
  reste client de Mécano à Bord uniquement. Remplace l'ancienne mention
  « piste Amazon abandonnée (ruptures) » et l'expédition directe Vgate →
  client. Couverture des zones NON confirmée (France métropolitaine, UE,
  DOM, hors UE) → CGV : liste des zones desservies modifiable (B75).
  → Si besoin pour OBD-BLE : demander à Vgate la documentation BLE (UUID)
  de l'iCar Pro BLE 4.0 (demande neutre — RÈGLE 10).
- CGV : rédigées le 11/10/2026, voir PRIORITÉ 1 (le « satisfait ou
  remboursé » est remplacé par la garantie commerciale 14 jours sous
  conditions). Prix public prévu : 297 € (répartition à afficher sur la page
  de vente) ; retours à la charge du client ; médiateur de la consommation
  à choisir ; « accès sans limite de durée, pour toute la durée
  d'exploitation du service » plutôt que « à vie » ; compatibilité AVANT
  paiement.
- Offre de lancement : ses conditions (prix, durée, places) figurent
  UNIQUEMENT sur la page de vente, jamais dans les CGV, sans prix barré.
- Dépôt de marque INPI (classes 9 et 41) + e-Soleau : différé.
- ⚠️ Keystore + key.properties (mots de passe en clair) dans un dossier
  OneDrive synchronisé : décision de Pascal attendue (exclure de la synchro
  ou déplacer hors OneDrive).
```

---

## 🔐 KILL SWITCH — FIREBASE REMOTE CONFIG

```
Service : lib/services/remote_feature_flags.dart (singleton), fetch 1 h,
repli sur mab_features.dart si hors ligne. Doc complète : REMOTE_CONFIG.md.
Flags : feature_obd, feature_surveillance, feature_tts, feature_formation,
feature_ia, feature_plaque, feature_licence, feature_carnet_entretien,
feature_documents, feature_sante_vehicule, feature_mise_a_jour,
feature_rappels_admin (réservé, sans effet), feature_tutoriels.
Clés texte : discord_invite_url, tutoriel_{boitier,surveillance,alerte,
entretien,glovebox}_{url,duree}.
Comportement coupé : formation → écran bloquant + Réessayer ; Boîte à gants /
OBD → visibles mais bloqués (jamais masqués).
⚠️ Remote Config ne fonctionnera sur iPhone qu'après iOS-SETUP (Firebase iOS).
```

---

## 📄 TEXTES JURIDIQUES — PROCÉDURE (depuis le 11/10/2026)

```
Un texte maître UNIQUE par document (vouvoiement, doit correspondre
EXACTEMENT au code et à l'offre). Ne jamais modifier un affichage à la main.
- docs-projet/juridique/POLITIQUE_CONFIDENTIALITE.md
    → écran app (privacy_policy_screen.dart) + page publique confidentialite.html
- docs-projet/juridique/CGV_MECANO_A_BORD.md
    → page publique cgv.html + CGV_SYSTEMEIO.txt (à coller dans Systeme.io)
Pages publiques à la racine du dépôt principal (GitHub Pages, hors verrou
de licence) : https://chathuant-pascal.github.io/mecano-a-bord/confidentialite.html
et /cgv.html — ce sont les adresses à donner à Google Play et à l'App Store
(puis https://mecanoabord.fr/... quand le domaine sera branché ; GitHub
redirige alors automatiquement les anciennes adresses).

Après chaque modification d'un texte maître (depuis la racine) :
1. Mettre à jour sa date (« Dernière mise à jour » / « Version en vigueur »)
2. python docs-projet/juridique/outils/generer_ecran_confidentialite.py  (politique)
   python docs-projet/juridique/outils/generer_pages_publiques.py        (les deux)
   python docs-projet/juridique/outils/generer_cgv_systemeio.py          (CGV)
3. python docs-projet/juridique/outils/verifier_textes_juridiques.py
   → chaque ligne doit finir par « OK »
4. Si l'écran a changé : dans mecano_a_bord/, flutter analyze + flutter test
5. Commits séparés : dépôt principal (textes, pages) + dépôt app (écran)
Détails : docs-projet/juridique/outils/README.md.
Toute NOUVELLE utilisation de données s'ajoute à la politique AVANT
d'être codée (règle RGPD de Pascal).
```

---

## 🔍 PRÉCISIONS TECHNIQUES

```
- Quota IA chiffré dans FlutterSecureStorage (ai_conversation_service.dart).
- Clés API IA saisies par l'utilisateur, jamais dans le code.
- Version : pubspec.yaml 1.0.0+15 — versions Android/iOS synchronisées depuis
  cette source, bump manuel.
- update_check_service.dart compare à mecanoabord.systeme.io/version.json
  (existence du fichier non vérifiée).
- Migrations Firestore : pas de versionnage de schéma — ajouter des champs,
  ne jamais en renommer/supprimer.
- Aucun pipeline CI/CD aujourd'hui (Codemagic prévu avec iOS-SETUP).
- formation-web/index.html chargé via WebView depuis une URL externe : les
  modifications de la formation ne demandent pas de republier l'app.
- minSdk = 28 (Android 9+). Le commentaire « requis par com.pnuema.android:obd »
  dans build.gradle.kts est obsolète (bibliothèque retirée).
- Firestore : licenses/{code}, formation_events, feedback, consent_stats/counters.
- SQLite local (jamais envoyé) : vehicle_profiles, diagnostic_entries,
  maintenance_entries, documents, alerts, vehicle_reference_values,
  vehicle_learned_values, vehicle_health_alert_history.
```

---

## STRUCTURE DU PROJET (repères)

```
Mecano A Bord/
├── CLAUDE.md                          ← CE FICHIER (V5.1)
├── REMOTE_CONFIG.md                   ← kill switch
├── AUDIT_PRELANCEMENT_2026-07-28.md   ← audit le plus récent
├── AUDIT_MECANO_A_BORD_V1.md          ← historique (avril)
├── AUDIT_MECANO_A_BORD_CURSOR_V1.md   ← historique (avril)
├── FICHE_STORE_DRAFT.md               ← textes Play Store / App Store (brouillon)
├── REFERENTIEL_FONCTIONNEL_INES.md     ← description fonctionnelle (avril, états périmés)
│                                         (version .html : docs-projet/archives/)
├── docs-projet/ (EVOLUTION.md, BACKLOG.md, VERIFICATION_REGLES_DEVELOPPEUR.md,
│                 NOTES_INTENTION_TECHNIQUES.md)
├── .cursor/rules/ (contexte-pascal-mab.mdc, mab-design-system-figma.mdc)
├── formation-web/ (index.html ~9000+ lignes, optin.html, assets/)
└── mecano_a_bord/
    ├── lib/ (config/, services/, screens/, widgets/, data/, theme/, utils/)
    ├── test/                          ← baseline à reconfirmer à chaque session
    ├── android/app/src/main/kotlin/fr/mecanoabord/app/MainActivity.kt ← OBD natif (à porter en Dart BLE)
    └── ios/Runner/ (AppDelegate.swift par défaut, Info.plist incomplet)
```

---

## GITHUB / COMPTES

```
Repo         : chathuant-pascal/mecano-a-bord — branche main
GitHub Pages : https://chathuant-pascal.github.io/mecano-a-bord/formation-web/index.html
URL finale   : mecanoabord.fr (OVH — pas encore servi correctement)
OVH          : karucards@gmail.com (mecanoabord.fr + mecanoabord.com)
E-mail client: mecanoabord@gmail.com (seule adresse affichée aux clients)
Systeme.io   : mecanoabord@gmail.com — page de vente mecanoabord.systeme.io
Firebase     : projet mecano-a-bord (project_number 752455145864), forfait
               Blaze, app Android fr.mecanoabord.app (app iOS et app Web à ajouter)
YouTube      : @mecanoabord — https://www.youtube.com/channel/UC_Ke6SwbBRBwlM4RdkGzhbA
Discord      : « Mécano à Bord — Communauté » — https://discord.gg/SA5qkkPCp
⚠️ Keystore .jks et key.properties → JAMAIS dans GitHub (exclus via .gitignore)
⚠️ Token GitHub → généré sur GitHub, collé dans Claude Code uniquement
```

---

## PROJET COMMERCIAL (contexte)

```
Positionnement : Mécano à Bord n'est pas un outil de diagnostic OBD classique.
C'est un parcours de transformation pour débutants anxieux (formation « La
Méthode Sans Stress Auto » / « Ta Voiture Sans Galère ») qui débloque ensuite
un compagnon de conduite : SURVEILLANCE DU MOTEUR PENDANT QU'ON ROULE
(argument de vente n°1, aucun concurrent ne le fait), plus carnet d'entretien,
boîte à gants, assistant IA.
Offre : 297 € (boîtier OBD inclus), paiement unique.
Cible : tous les pays francophones — Android ET iPhone (RÈGLE 0).
Principe fondateur de Pascal : les débutants ne lisent pas les notices et
veulent que tout soit fait pour eux → zéro friction, zéro choix technique à
leur demander.
```

---

## PHRASES CLÉS DE PASCAL

```
"Quand tu comprends ta voiture, tu apprends à la faire durer."
"Un contrôle, c'est 2 minutes. Une casse, c'est 2 000 euros."
"Ton moteur te pardonne tout, sauf l'oubli."
"Un conducteur informé n'est plus un client perdu."
"Comprendre ≠ réparer soi-même. Comprendre = décider calmement."
"Je ne t'apprends pas la mécanique, je t'apprends à parler le même langage que ta voiture."
"Être Mécano à Bord, c'est être maître de sa route."
"Respire. Allume tes warnings. Tu n'es pas seul(e)."
```

---

*Fin du fichier CLAUDE.md — Version 5.1 — 11/10/2026*
*© Mécano à Bord — Pascal Chathuant — Guadeloupe*
*Ce fichier est la mémoire permanente de Claude Code.*
