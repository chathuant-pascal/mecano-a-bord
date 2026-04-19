# Journal d’évolution du projet — Mécano à Bord

**Règle** : toute étape importante doit être notée ici avec **date** et **résumé**, pour que quiconque retrouve l’évolution du projet et puisse affiner la réflexion et l’architecture.

Format : **AAAA-MM-JJ — Titre** puis résumé court (quoi, impact éventuel).

---

## 2026-04-19 — MODULE 7 terminé : try/catch stockage & fichiers (prefs, SQLite, picker, OpenFile)

- **MODULE 7** : **terminé le 2026-04-19** — protections **`try/catch`** + **`mabLog`** sur **`main.dart`** (`SharedPreferences`), **`onboarding_screen.dart`** (prefs + `hasSeenOnboarding`), **`add_maintenance_screen.dart`** (lecture SQLite entrée entretien), **`glovebox_screen.dart`** (`pickImage`, `FilePicker`, `OpenFile.open` + SnackBar en cas d’échec ; copie vers stockage app inchangée).
- **Documentation** : `docs-projet/fiches-fonctionnalites/FICHE_MODULE_07_TRY_CATCH.md` ; **EVOLUTION** / **BACKLOG** mis à jour.

---

## 2026-04-19 — MODULE 6 terminé : feature flags `mab_features.dart`

- **MODULE 6** : **terminé le 2026-04-19** — création de **`mecano_a_bord/lib/config/mab_features.dart`** avec **12** constantes **`kFeature*`** (documentation / futurs `if (kFeatureXxx)`).
- **`kFeatureLicence = false`** (licence Firebase — Mission 2 Inès) ; **toutes les autres à `true`**.
- **Documentation** : `docs-projet/fiches-fonctionnalites/FICHE_MODULE_06_FEATURE_FLAGS.md` ; **EVOLUTION** / **BACKLOG** mis à jour.

---

## 2026-04-19 — MODULE 5 terminé : logger conditionnel `mabLog` (remplacement des `debugPrint`)

- **MODULE 5** : **terminé le 2026-04-19** — création de **`mecano_a_bord/lib/utils/mab_logger.dart`** (`mabLog`, actif uniquement en `kDebugMode`).
- **13 remplacements** dans **7 fichiers** : `home_screen.dart` (6), `bluetooth_obd_service.dart`, `ai_conversation_service.dart`, `vehicle_reference_service.dart` (2), `formation_web_launch_screen.dart`, `help_contact_screen.dart` (2). Seul **`mab_logger.dart`** conserve un appel interne à `debugPrint`.
- **Documentation** : `docs-projet/fiches-fonctionnalites/FICHE_MODULE_05_LOGGER.md` ; **EVOLUTION** / **BACKLOG** mis à jour.

---

## 2026-04-19 — MODULE 4 terminé : WebView formation sécurisée (OWASP + UX)

- **MODULE 4** : **terminé le 2026-04-19** — `mecano_a_bord/lib/screens/formation_webview_screen.dart` (formation « Ta Voiture Sans Galère »).
- **6 correctifs** : **sécurité OWASP** — `NavigationDelegate` + allowlist (`mecanoabord.fr`, `chathuant-pascal.github.io`), liens externes hors WebView ; validation de l’URL courante avant traitement du message JS `MABFormation` (`done`) ; `try/catch` sur `loadRequest`. **UX** — erreur réseau / ressource avec message rassurant + bouton « Réessayer » ; minuteur `formation_done` suspendu en arrière-plan (`inactive` / `paused` / `hidden` / `detached`), relance au `resumed` ; indicateur de chargement (`onPageStarted` / `onPageFinished`).
- **Documentation** : `docs-projet/fiches-fonctionnalites/FICHE_MODULE_04_WEBVIEW.md` ; journal **EVOLUTION** / **BACKLOG** mis à jour.

---

## 2026-04-19 — MODULE 1 terminé et solide : hystérésis surveillance sur 4 canaux

- **MODULE 1** considéré **bouclé côté produit** : diagnostic OBD validé + comportement **surveillance** sans annonces vocales en boucle après retour à la normale (terrain Inès / logique hystérésis).
- **`vehicle_health_service.dart`** : hystérésis complète — **température** (≤ 95 °C + bande), **tension** (seuils 12,5 / 12,8 V + bande), **RPM** (retour plage idle), **pression huile** (&lt; 100 / &gt; 150 kPa) ; **reset** de tous les drapeaux dans `resetLiveMonitoringWarmupState()`.
- **Commit** : message *« MODULE 1 : hystérésis complète sur tous les canaux surveillance… »* sur `main`.

---

## 2026-04-19 — MODULE 1 validé : diagnostic OBD corrigé et testé (SM-A137F)

- **MODULE 1 (diagnostic OBD)** : statut **validé** — connexion dongle sans blocage, lecture diagnostic aboutissante sur **Samsung SM-A137F** + dongle OBD (terrain Pascal).
- **Correctifs livrés** : bouton « Lancer le diagnostic » sur `obd_scan_screen.dart` ; cohérence diagnostic ↔ surveillance ; abonnements au flux Bluetooth annulés (`home_screen` / `obd_scan_screen`) ; anti-chevauchement des cycles de surveillance (`live_monitoring_service.dart`).
- **Documentation** : `docs-projet/fiches-fonctionnalites/FICHE_MODULE_01_DIAGNOSTIC_OBD.md` mise à jour (statut validé 19/04/2026).

---

## 2026-04-14 — Profil véhicule : récupération plaque (API gouv) + fallback manuel

- **Diagnostic écran existant** : `glovebox_profile_screen.dart` utilisait uniquement le formulaire complet local (SQLite via `MabRepository`), sans récupération plaque ni clé `SharedPreferences` dédiée.
- **Ajout logique “une seule tentative API”** dans `glovebox_profile_screen.dart` :
  - appel `GET https://particulier.api.gouv.fr/api/v2/immatriculation?immatriculation=...` (timeout 10 s) ;
  - sauvegarde immédiate des clés prefs `vehicle_marque`, `vehicle_modele`, `vehicle_energie`, `vehicle_annee`, `vehicle_couleur`, `vehicle_immat`, `vehicle_data_fetched` (et `vehicle_portes` pour saisie manuelle) ;
  - si `vehicle_data_fetched == true`, l’écran affiche les données sauvegardées et **n’appelle plus l’API**.
- **Fallback bienveillant** : en cas d’échec API, bascule vers formulaire manuel (marque, modèle, année, carburant, couleur, portes) avec message rassurant.
- **Modification à tout moment** : bouton “Modifier les informations” conservé dans la section identité véhicule ; enregistrement écrase les anciennes valeurs prefs tout en gardant `vehicle_data_fetched = true`.
- **Navigation** : aucun changement du flux onboarding → formation → accueil.

---

## 2026-04-14 — Harmonisation filigrane app mobile (vitrine 15% / contenu sans filigrane)

- **Filigrane vitrine** : opacité fixée à **15%** sur **Splash**, **Onboarding** et **Accueil** (`main.dart`, `onboarding_screen.dart`, `home_screen.dart`).
- **Pages de contenu** : filigrane supprimé sur **diagnostic / résultats**, **profil véhicule** et **historique** (`diagnostic_guide_screen.dart`, `obd_scan_screen.dart`, `glovebox_profile_screen.dart`, `glovebox_screen.dart`).
- **Parcours formation** : filigrane retiré sur l’écran de lancement navigateur (`formation_web_launch_screen.dart`) ; **WebView formation** déjà sans filigrane (`formation_webview_screen.dart`).
- **Impact** : rendu plus lisible sur écrans de contenu, aligné avec la logique demandée (vitrine légère, contenu sans marque visuelle intrusive).

---

## 2026-04-14 — Correction attribution téléphones (Pascal / Inès)

- **Correction** : le téléphone terrain **Samsung SM-A137F (A13, Android 14)** est celui de **Pascal** (et non celui d’Inès).
- **Ajout** : téléphone d’Inès (développeuse) documenté comme **Samsung A36**.
- Fichiers harmonisés : **`.cursor/rules/contexte-pascal-mab.mdc`**, **`CLAUDE.md`**, **`docs-projet/NOTES_INTENTION_TECHNIQUES.md`** (§5b), **`docs-projet/CONTEXTE_CLAUDE_MECANO_A_BORD_V16_15.txt`**.
- **Impact** : clarification des appareils de test et des responsabilités terrain, sans changement de code applicatif.

---

## 2026-04-14 — Splash + parcours post-onboarding : formation en WebView interne

- **`flutter_native_splash`** (`pubspec.yaml`) : image principale du splash → **`assets/images/onboarding_page1.png`** ; **Android 12+** inchangé (`logo_mark.png`). Régénération : `dart run flutter_native_splash:create`.
- **Navigation** : fin d’onboarding → **`FormationWebViewScreen`** (`lib/screens/formation_webview_screen.dart`) : WebView **`webview_flutter`**, charge **`kFormationUrl`** (`formation_url.dart`) ; titre **« Ta Voiture Sans Galère »** ; fond **`MabColors.noir`**. Plus de redirection obligatoire vers **`/glovebox-profile`** au premier lancement — le profil véhicule reste accessible depuis l’accueil / Boîte à gants.
- **Déblocage accueil** : lecture périodique + retour app sur **`SharedPreferences`** clé **`formation_done`** ; canal JS **`MABFormation`** (`postMessage` `done` / `1` / `true`) pour aligner la page web et Flutter.
- **`main.dart`** : commentaire d’en-tête aligné sur le flux **Onboarding → Formation WebView → Accueil**.
- **Terrain** : **`flutter build apk --release`** + **`flutter install -d R58T92HCDAX`** — Samsung **SM-A137F** (Android 14), APK **~87,4 Mo** (`app-release.apk`).

---

## 2026-04-11 — Build 1.0.0+14 + formation / liens externes (Android 11+) — SM-A137F

- **Cause** : `canLaunchUrl` renvoyait souvent **false** sur Android 11+ sans déclaration de visibilité ; `formation_web_launch_screen` n’appelait alors jamais `launchUrl` et revenait à l’accueil sans ouvrir le navigateur.
- **`AndroidManifest.xml`** : `<queries>` pour intents **VIEW** `https` / `http` et **VIEW** `mailto`.
- **`formation_web_launch_screen.dart`** : appel direct à `launchUrl` ; SnackBar si échec ; `pubspec` **1.0.0+14**.
- **`help_contact_screen.dart`** / **`update_check_service.dart`** : même logique (plus de blocage sur `canLaunchUrl` seul).
- **`flutter build apk --release`** + **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14).

---

## 2026-04-11 — Règle développeur : inventaire § 5.4 exhaustif + alignement Cursor

- **`VERIFICATION_REGLES_DEVELOPPEUR.md`** : tableau § 5.4 complété (`formation_url.dart`, `formation_web_launch_screen.dart`, `vehicle_reference_service.dart`, `glovebox_vehicle_health_tab.dart`) ; **42** fichiers `lib/` ; dernière revue **2026-04-11**.
- **`.cursor/rules/contexte-pascal-mab.mdc`** : inventaire **42** fichiers (au lieu de 35) pour coller à la source de vérité.

---

## 2026-04-11 — Mise à jour téléphone terrain SM-A137F (APK release + lien formation GitHub Pages)

- **`formation_url.dart`** : URL formation → hébergement **GitHub Pages** (`chathuant-pascal.github.io/mecano-a-bord/formation-web/index.html`) — incluse dans l’APK déployé.
- **`flutter build apk --release`** + **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14) — **1.0.0+13** installée (référence terrain `docs-projet/NOTES_INTENTION_TECHNIQUES.md` §5b).

---

## 2026-04-09 — Build 1.0.0+13 + TTS surveillance / OBD réel + sondage 4 s + écran OBD connexion seule (SM-A137F)

- **`surveillance_auto_coordinator.dart`** : avant de démarrer la surveillance ou de parler, **ping PID 010C** (`success`) — pas de TTS « Je suis connecté… » si le calculateur ne répond pas.
- **`live_monitoring_service.dart`** : contrôle **état natif connecté** + **au moins une réponse PID** ; sinon **arrêt surveillance** ; **sondage 4 s** (au lieu de 10 s) avec **4 lectures PID** par cycle (0105, 0142, 010C, 010B) pour retrouver l’activité visible du dongle.
- **`vehicle_health_service.dart`** : aucun traitement si `!ecuResponding` ; **bilan positif 2 h** et annonces chauffe / alertes TTS conditionnés à **`engineRunning`** (RPM ≥ 400 pour thermique ; électrique = `ecuResponding`).
- **`obd_scan_screen.dart`** : titre **« Connecte ton OBD »** ; suppression des boutons **« Lancer le diagnostic »** ; depuis l’accueil avec `autoStartDiagnostic`, **une seule lecture auto** après connexion (sans bouton sur cet écran).
- **`pubspec.yaml`** : **1.0.0+13**.
- **`flutter build apk --release`** + **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14) — **1.0.0+13** installée (référence terrain `docs-projet/NOTES_INTENTION_TECHNIQUES.md` §5b).

---

## 2026-04-08 — Build 1.0.0+12 + libellé accueil OBD + diagnostic déclenché manuellement (écran OBD)

- **`home_screen.dart`** : bandeau OBD — texte par défaut **« Connecte ton OBD »** (à la place de « OBD non connecté »).
- **`obd_scan_screen.dart`** : à la connexion OBD réussie, **plus de lancement automatique** de la lecture véhicule ; message **« OBD connecté. Prêt pour le diagnostic. »** (interface + SnackBar + TTS) ; le diagnostic est lancé via le bouton **« Lancer le diagnostic »** sur cet écran. Le mode AUTO surveillance et `vehicle_health_service` ne sont pas modifiés dans ce périmètre.
- **`pubspec.yaml`** : **1.0.0+12**.
- **`flutter build apk --release`** + **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14) — **1.0.0+12** installée.

---

## 2026-04-05 — Build 1.0.0+11 + version réelle dans Réglages + install SM-A137F

- **`settings_screen.dart`** : la ligne **Version** affiche désormais **`PackageInfo`** (`version` + `buildNumber` depuis `pubspec.yaml`), au lieu du texte figé « 1.0.0 » — permet de **voir** chaque mise à jour terrain.
- **`pubspec.yaml`** : **1.0.0+11**.
- **`flutter build apk --release`** + **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14).

---

## 2026-04-05 — Build APK 1.0.0+10 + décodage natif PID 010C (RPM) — APK prêt pour le SM-A137F

- **`MainActivity.kt`** : le canal **`readLiveData`** décode désormais le **PID 010C** (régime moteur, formule OBD standard `((A×256)+B)/4`, unité **RPM**), aligné sur les autres PIDs (`success`, `value`, `unit`, `supported`).
- **`pubspec.yaml`** : version **1.0.0+10** (build +1).
- **`flutter build apk --release`** → `mecano_a_bord/build/app/outputs/flutter-apk/app-release.apk` (~84,9 Mo).
- **`flutter install -d R58T92HCDAX`** : après **autorisation du débogage USB** sur le **SM-A137F**, installation réussie — **1.0.0+10** (ancienne version désinstallée, APK release installé).

---

## 2026-03-29 — Règle développeur : revue `VERIFICATION_REGLES_DEVELOPPEUR.md`

- Mise à jour **EAA** (guide diagnostic + chat), **assets** §5.3 (`moteur_symptomes.json`), **synthèse données** (fiches locales + sanitation), **pied de page** (build **1.0.0+9**, **35** fichiers).
- **`contexte-pascal-mab.mdc`** : exemple d’écran `diagnostic_guide_screen`.

---

## 2026-03-29 — Build APK 1.0.0+9 + mise à jour téléphone SM-A137F

- **`pubspec.yaml`** : version **1.0.0+9** (numéro de build +1).
- **`flutter build apk --release`** → `mecano_a_bord/build/app/outputs/flutter-apk/app-release.apk` (~84,5 Mo).
- **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14) — **1.0.0+9** installée.
- **Contenu** : guide diagnostic (`/diagnostic-guide`, filigrane), évolutions récentes depuis **1.0.0+8**.

---

## 2026-03-29 — Écran « Guide pas à pas » (arbre diagnostic)

- **`lib/screens/diagnostic_guide_screen.dart`** : questions à gros boutons, navigation retour / recommencer, fiche finale depuis **`MoteurSymptomesKnowledge.entryById`** (bandeau gravité, « Puis-je rouler ? », actions, signes d’aggravation, phrase garage + copier, message OBD si besoin).
- **`moteur_symptomes_knowledge.dart`** : **`entryById`**, **`sanitizeForDisplay`** pour l’affichage.
- **`main.dart`** : route **`/diagnostic-guide`**.
- **`ai_chat_screen.dart`** : lien **« Je ne sais pas quoi taper → »** vers le guide.

---

## 2026-03-29 — Build APK 1.0.0+8 + mise à jour téléphone SM-A137F

- **`pubspec.yaml`** : version **1.0.0+8** (numéro de build +1).
- **`flutter build apk --release`** → `mecano_a_bord/build/app/outputs/flutter-apk/app-release.apk` (~84,5 Mo).
- **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14) — **1.0.0+8** installée.
- **À valider** : mode gratuit IA (fiches JSON `moteur_symptomes`), parcours habituels.

---

## 2026-03-28 — Mode gratuit IA : base JSON voyants / symptômes (matching alias)

- **`assets/data/moteur_symptomes.json`** : ~40 fiches (voyants, symptômes, urgences) ; déclaré dans **`pubspec.yaml`**.
- **`lib/data/moteur_symptomes_knowledge.dart`** : chargement cache, correspondance par alias / titre (score = longueur du libellé), composition du texte, assainissement mots interdits projet (`panne`, `danger`, `défaillance`).
- **`lib/services/ai_conversation_service.dart`** : en mode gratuit, appel **JSON en premier**, puis repli sur **`_generateLocalResponse`** si aucune fiche ne correspond.

---

## 2026-03-28 — Build APK 1.0.0+7 + mise à jour téléphone SM-A137F (INTERNET manifest)

- **`pubspec.yaml`** : version **1.0.0+7** (numéro de build +1).
- **`flutter build apk --release`** → `mecano_a_bord/build/app/outputs/flutter-apk/app-release.apk` (~84,5 Mo).
- **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14) — **1.0.0+7** installée.
- **Contenu** : **`AndroidManifest.xml`** — `<uses-permission android:name="android.permission.INTERNET" />` avant `<application>` (accès réseau explicite).
- **À valider** : Assistant IA et appels HTTP sur l’appareil.

---

## 2026-03-28 — Build APK 1.0.0+6 + mise à jour téléphone SM-A137F

- **`pubspec.yaml`** : version **1.0.0+6** (numéro de build +1).
- **`flutter build apk --release`** → `mecano_a_bord/build/app/outputs/flutter-apk/app-release.apk` (~84,5 Mo).
- **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14) — **1.0.0+6** installée.
- **Contenu** : `ai_conversation_service.dart` — `_callChatGpt` : `debugPrint` + message d’erreur détaillé dans le `catch` (diagnostic connexion API).
- **À valider** : Assistant IA en mode personnel (ChatGPT), Logcat si besoin.

---

## 2026-03-28 — Fin de session : livrables validés, reprise à la prochaine session

- **Synthèse** : harmonisation **accueil** (`home_screen` — bandeau OBD « OBD non connecté », lisibilité) ; **onboarding** avec page d’**acceptation des conditions** en premier (hors carrousel) ; builds terrain **1.0.0+2** → **1.0.0+5** sur **Samsung SM-A137F** (`R58T92HCDAX`) ; documentation projet tenue à jour (**EVOLUTION**, **BACKLOG**, **NOTES** §5b, **VERIFICATION**).
- **Suite** : travaux repris à la **prochaine session** ; priorités inchangées — voir **`BACKLOG.md`** et règles Cursor.

---

## 2026-03-28 — Build APK 1.0.0+5 + mise à jour téléphone SM-A137F

- **`pubspec.yaml`** : version **1.0.0+5** (numéro de build +1).
- **`flutter build apk --release`** → `mecano_a_bord/build/app/outputs/flutter-apk/app-release.apk` (~84,5 Mo).
- **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14) — **1.0.0+5** installée.
- **Contenu** : onboarding (page d'acceptation en premier) + correctifs accueil précédents.
- **À valider** : premier écran onboarding (acceptation + lien mentions légales), puis parcours habituels.

---

## 2026-03-28 — Onboarding : page d’acceptation des conditions en premier (hors carrousel)

- **`onboarding_screen.dart`** : étape **1** — écran dédié (logo `MabLogo`, titre bienvenue, texte d’acceptation, lien `/legal-mentions`, bouton **« J’accepte et je commence »**) avant le carrousel ; pas d’indicateurs de page sur cette étape ; impossible d’accéder au carrousel sans ce bouton. **Étape 2** — les 5 pages existantes inchangées ; bloc légal répété en bas du carrousel **supprimé**.
- **Style** : `MabColors` / `MabTextStyles` / `MabWatermarkBackground` / bouton `ElevatedButton` thème MAB.

---

## 2026-03-28 — Doc « règle développeur » : VERIFICATION + BACKLOG + règle Cursor

- **`VERIFICATION_REGLES_DEVELOPPEUR.md`** : date **28 mars 2026** ; version app **1.0.0+5** (cf. entrées suivantes) ; dépendance **`package_info_plus`** ; inventaire **33** fichiers Dart ; rôle **`home_screen`** / **`onboarding_screen`** ; ligne **§2** bandeau OBD.
- **`BACKLOG.md`** : **B10** / **B12** / **B15** actualisés (onboarding, accueil, builds terrain).
- **`.cursor/rules/contexte-pascal-mab.mdc`** : inventaire **33** fichiers (aligné §5.4).

---

## 2026-03-28 — Build APK 1.0.0+4 + mise à jour téléphone SM-A137F (bandeau OBD)

- **`pubspec.yaml`** : version **1.0.0+4** (numéro de build +1).
- **`flutter build apk --release`** → `mecano_a_bord/build/app/outputs/flutter-apk/app-release.apk` (~84,5 Mo).
- **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14) — **1.0.0+4** installée.
- **Contenu** : bandeau « OBD non connecté » — pastille de statut retirée + `FittedBox` (`scaleDown`) pour affichage complet sans troncature (`home_screen.dart`).
- **À valider** : libellé entier visible, taille de texte acceptable.

---

## 2026-03-28 — Build APK 1.0.0+3 + mise à jour téléphone SM-A137F

- **`pubspec.yaml`** : version **1.0.0+3** (numéro de build +1).
- **`flutter build apk --release`** → `mecano_a_bord/build/app/outputs/flutter-apk/app-release.apk` (~84,5 Mo).
- **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14) — ancienne version désinstallée, **1.0.0+3** installée.
- **Contenu** : bandeau accueil **« OBD non connecté »** (libellé court) + accessibilité `Semantics` corrigée (`$label. Ouvrir le diagnostic.`).
- **À valider** : texte entier visible dans le cadre du bandeau, parcours habituels.

---

## 2026-03-28 — Build APK 1.0.0+2 + mise à jour téléphone SM-A137F (accueil)

- **`pubspec.yaml`** : version **1.0.0+2** (numéro de build +1).
- **`flutter build apk --release`** → `mecano_a_bord/build/app/outputs/flutter-apk/app-release.apk` (~84,5 Mo).
- **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14) — ancienne version désinstallée, **1.0.0+2** installée.
- **Contenu livré** : écran d’accueil harmonisé (`home_screen.dart`) — cartes Boîte à Gants / Mode Conduite / Mode Démo sans sous-titre tronqué ; bandeau « OBD non connecté » en `MabTextStyles.titreCard` (sans icône Bluetooth à côté du texte sur l’état par défaut).
- **À valider sur l’appareil** : lisibilité accueil, bandeau OBD, parcours habituels.

---

## 2026-03-28 — Mentions légales : écran dédié + lien Réglages (📱 Application)

- **`legal_mentions_screen.dart`** : `MabLegalMentionsSettingsSection` dans un écran scroll (même gabarit que politique de confidentialité).
- **`main.dart`** : route `/legal-mentions`.
- **`settings_screen.dart`** : lien `_SettingsLinkRow` (icône balance) dans la section Application ; bloc inline des mentions retiré ; fin du scroll `initialSection: 'legal'`.
- **Onboarding, politique de confidentialité, mode conduite** : lien vers `/legal-mentions` au lieu de Réglages + `arguments: 'legal'`.

---

## 2026-03-28 — Carnet d’entretien : types regroupés par catégorie

- **`add_maintenance_screen.dart`** : titres de catégorie (rouge MAB, séparateurs) au-dessus des puces ; `_categoryDisplay` + assert cohérence avec `_maintenanceTypes`.

---

## 2026-03-28 — Carnet d’entretien : nouveaux types d’intervention

- **`add_maintenance_screen.dart`** : 12 types ajoutés avant « Autre intervention » (moteur, électrique, climatisation, train roulant) ; icônes Material ; rappels auto km/date selon fiche produit.

---

## 2026-03-28 — Build APK + mise à jour téléphone SM-A137F

- **`flutter build apk --release`** → `mecano_a_bord/build/app/outputs/flutter-apk/app-release.apk` (~84,5 Mo).
- **`flutter install -d R58T92HCDAX`** : Samsung **SM-A137F** (Android 14) — ancienne version désinstallée, nouvelle installée.
- **Doc** : `NOTES_INTENTION_TECHNIQUES.md` §5b « Dernière note terrain » actualisée ; checklist terrain (historique OBD, dialogue après effacement codes).

---

## 2026-03-28 — Effacement codes OBD : TTS + dialogue pédagogique

- **`tts_service.dart`** : texte vocal après effacement réussi aligné sur le message pédagogique (voyant au redémarrage, normalité si problème non réparé).
- **`mab_obd_session_dialogs.dart`** : `showMabDtcClearSuccessInfoDialog` (codes mémorisés / permanents, voyant, cycle 50–100 km).
- **`obd_scan_screen.dart`** : après effacement réussi (démo ou réel), TTS puis dialogue « J’ai compris ».

---

## 2026-03-28 — Historique diagnostics OBD (SQLite + Boîte à gants)

- **`mab_repository.dart`** : modèle `ObdDiagnosticHistoryEntry` ; `appendObdDiagnosticHistory` (insert `diagnostic_entries`, JSON mil + codes par catégorie) ; `getObdDiagnosticsForVehicle` — hors mode démo, aligné sur `saveLastObdDiagnostic`.
- **`obd_scan_screen.dart`** : après `saveLastObdDiagnostic`, appel `appendObdDiagnosticHistory` avec la même date `scanAt` (lecture réussie uniquement).
- **`glovebox_screen.dart`** : onglet Historique = liste cartes expansibles (date, km, Check Engine, nombre de codes, détail) + états vide / démo / sans profil ; rafraîchissement à l’ouverture de l’onglet et pull-to-refresh.

---

## 2026-03-23 — Build APK + mise à jour doc « téléphone de test » (SM-A137F)

- **APK release** généré : `mecano_a_bord/build/app/outputs/flutter-apk/app-release.apk` — à copier sur le **Samsung SM-A137F** (Android 14) ou `flutter install` en USB débogage pour remplacer la version installée et valider la livraison **mentions légales** (liens + scroll).
- **`NOTES_INTENTION_TECHNIQUES.md` §5b** : procédure `flutter build apk --release`, emplacement du fichier, checklist rapide après installation (onboarding, politique de confidentialité, mode conduite → Réglages section légale).
- **`VERIFICATION_REGLES_DEVELOPPEUR.md`** : inventaire **32** fichiers Dart sous `lib/` + lignes liens « mentions légales » (charte `MabTextStyles`).

---

## 2026-03-23 — Mentions légales complètes & CGU (Réglages + liens)

- **`mab_legal_mentions_body.dart`** : section **Mentions légales & CGU** en 9 blocs (éditeur, hébergeur, propriété intellectuelle, données, limitation de responsabilité — **« aléas mécaniques »** à la place du mot interdit —, liens externes, loi applicable, contact, SIRET placeholder **`[SIRET : à compléter avant mise en vente]`**).
- **`settings_screen.dart`** : `initialSection: 'legal'` + scroll automatique vers la section (clé `_legalSectionKey`).
- **`surveillance_only_screen.dart`**, **`privacy_policy_screen.dart`**, **`onboarding_screen.dart`** : liens discrets vers `Navigator.pushNamed('/settings', arguments: 'legal')`.
- **`flutter analyze`** : aucune erreur ; infos existantes dans le projet (const, dépréciations API).

---

## 2026-03-23 — Vérification règles développeur (doc + Réglages)

- **`docs-projet/VERIFICATION_REGLES_DEVELOPPEUR.md`** : actualisé (inventaire 31 fichiers Dart, services reset/surveillance/OBD, persistance réinitialisation, date 23 mars 2026).
- **`settings_screen.dart`** : bouton « Réinitialiser l’application » — `MabTextStyles.boutonSecondaire`, hauteur / `minimumSize` **`MabDimensions.boutonHauteur`** (EAA).

---

## 2026-03-23 — Réinitialisation complète (Réglages)

- **`AppResetService.performFullReset`** : suppression des fichiers référencés en base + dossiers `glovebox_documents` et `vehicle_profile_photos` ; **`MabDatabase.closeAndDeleteDatabaseFile`** (fichier `mab_database.db`) ; **`FlutterSecureStorage.deleteAll`** (clés IA, compteurs, etc.) ; **`BluetoothObdService.resetObdNativePrefs`** → `resetObdNativePrefs` dans **MainActivity.kt** (`prefs("obd").clear()`) ; puis **`SharedPreferences.clear`**.
- **`settings_screen.dart`** : dialogue de chargement « Réinitialisation en cours… » pendant l’opération ; navigation vers **Onboarding** après succès.

---

## 2026-03-23 — Effacement codes défaut OBD (mode 04)

- **MainActivity.kt** : `clearDtcCodes` sur le MethodChannel `com.example.mecano_a_bord/obd` — commande ELM `04`, succès si un octet `0x44` apparaît dans la réponse (hors NO DATA / ERROR).
- **bluetooth_obd_service.dart** : `clearDtcCodes()` ; refus si surveillance temps réel active (`ObdScanException` même code que le diagnostic).
- **obd_scan_screen.dart** : bouton « Effacer les codes » si des codes sont présents (réel : dongle connecté ; démo : simulation mémoire uniquement) ; dialogue `showMabClearDtcConfirmDialog` ; SnackBar en cas d’échec ; après succès : `saveLastObdDiagnostic` avec listes vides, MIL éteint, **kmAtScan** inchangé (dernier scan) ; résultat écran repassé en vert.
- **mab_obd_session_dialogs.dart** : dialogue de confirmation (textes validés).
- **tts_service.dart** : `speakAfterDtcClear()` + constante `messageAfterDtcClear` (respect `voice_alerts_enabled`).

---

## 2026-03-28 — Surveillance OBD temps réel (Mode conduite) + readLiveData Android

- **MainActivity.kt** : méthode `readLiveData` (PID `0105` °C, `0142` V, `010B` kPa) via `sendObdCommand` ; retour `success` / `value` / `unit` / `supported`.
- **bluetooth_obd_service.dart** : `LivePidResult`, `readLivePid`, exclusion mutuelle `getVehicleData` / `runProtocolDetection` si surveillance active (`ObdSessionCoordinator`).
- **obd_session_coordinator.dart** : drapeaux `liveMonitoringActive` / `diagnosticRunning`.
- **live_monitoring_service.dart** : timers 10 s / 30 s / 15 s, seuils + TTS + bandeau ; démo : valeurs `liveMonitoringDemoScenario` (`normal` | `alert_temp` | `alert_volt` | `alert_oil`).
- **surveillance_only_screen.dart** : démarrer / arrêter surveillance, « Lancer un diagnostic », dialogues blocage croisés, mention légale bas d’écran.
- **obd_scan_screen.dart** : blocage diagnostic + dialogue si surveillance active.

---

## 2026-03-28 — Profil véhicule & contexte IA : motorisation, boîte, km au diagnostic

- **Base** (`mab_database.dart` v4) : colonne **`motorisation`** sur `vehicle_profiles` (migration `ALTER TABLE`).
- **Formulaire** (`glovebox_profile_screen.dart`) : champ texte optionnel « Motorisation (ex: 1.5 dCi 90ch) » entre modèle et année ; persistance SQLite.
- **OBD / prefs** : `saveLastObdDiagnostic` avec **`kmAtScan`** ; clé **`mab_last_obd_km_<id>`** ; `getLastObdDiagnostic` retourne **`kmAtScan`** ; suppression de la clé à la suppression de profil.
- **IA** (`getAiSystemContextString`) : ligne véhicule avec **type de boîte**, **motorisation** si renseignée, et dans le bloc OBD **« Kilométrage au diagnostic : … km »** ; profil démo : motorisation exemple `1.5 dCi 90ch` (`demo_data.dart`).
- **`obd_scan_screen.dart`** : passage de **`profile.mileage`** comme **`kmAtScan`** après lecture véhicule.
- **Téléphone de test** : référence terrain documentée dans **NOTES_INTENTION_TECHNIQUES.md** — Samsung **SM-A137F**, Android **14** (build / validation manuelle).
- **Déploiement** : `flutter build apk --release` + `flutter install` sur **SM A137F** (id `R58T92HCDAX`) — APK à jour installé.

---

## 2026-03-27 — Contexte IA : diagnostic OBD (MIL + codes par catégorie)

- **`mab_repository.dart`** : `saveLastObdDiagnostic` / `getLastObdDiagnostic` avec MIL et listes stored / pending / permanent ; `getAiSystemContextString` (lignes Témoin Check Engine + trois catégories ou « aucun ») ; nettoyage prefs à la suppression de profil.
- **`obd_scan_screen.dart`** : sauvegarde après scan avec les champs `ObdVehicleResult`.
- **`bluetooth_obd_service.dart` + `demo_data.dart`** : déjà livrés à l’étape 1 (ObdVehicleResult étendu).

---

## 2026-03-26 — OBD Android : séquence d’init ELM327 (correction 1)

- **`MainActivity.kt`** — `tryProtocol` : ordre ATZ → pause **1500 ms** (`ATZ_POST_DELAY_MS`) → ATE0 → ATL0 → ATH0 → ATAT1 → ATSP$index ; suppression ATS0 / ATH1. **`readVehicleDataStep`** : mini-init ATE0, ATL0, ATH0, ATAT1 (ATH1 → ATH0).

---

## 2026-03-26 — OBD Android : lecture ATZ jusqu’au prompt « > » (correction 2)

- **`MainActivity.kt`** — `sendAtzAndComplete` : fin de lecture **uniquement** sur **`>`** ; plus d’arrêt sur `ELM327` ou `OK` seuls.

---

## 2026-03-26 — OBD Android : `sendObdCommand` (settle 150 ms) + `applyProtocolAndComplete` (init complète)

- **`sendObdCommand`** : fin après **`>`** + **150 ms** (`OBD_POST_PROMPT_SETTLE_MS`) ; suppression du délai fixe 3000 ms ; timeout global inchangé.
- **`applyProtocolAndComplete`** : séquence **ATE0 → ATL0 → ATH0 → ATAT1 → ATSP** (protocole enregistré), via `sendAtCommandAndWait`.

---

## 2026-03-25 — Carnet d’entretien V1 (point 1) : suppression d’une intervention

- **Base** : `MabDatabase.deleteMaintenanceEntry(String id)` — suppression de la ligne `maintenance_entries` et tentative de suppression du fichier `facture_photo_path` si présent.
- **Repository** : `MabRepository.deleteMaintenanceEntry` (hors mode démo, vérifie que l’entrée appartient au véhicule actif).
- **UI** : `glovebox_screen.dart` — icône poubelle sur chaque carte, dialogue de confirmation (texte demandé), boutons Annuler / Oui, supprimer (rouge).

---

## 2026-03-25 — Carnet d’entretien V1 (point 2) : modification d’une intervention

- **Navigation** : route `'/add-maintenance'` lit `arguments` (`Map` avec clé `editEntryId` en `int` ou `String`) et construit `AddMaintenanceScreen(editEntryId: …)` ; sans argument = ajout comme avant.
- **Boîte à gants** : `_MaintenanceCard` avec `InkWell` sur la carte → `Navigator.pushNamed` avec `editEntryId` ; rafraîchissement liste au retour ; la poubelle reste indépendante (ne lance pas l’édition).
- **Formulaire** : `initState` inchangé — si `editEntryId != null`, `_loadExistingEntry` est déjà appelé.

---

## 2026-03-25 — Carnet d’entretien V1 (point 3) : photo facture (appareil ou galerie)

- **`add_maintenance_screen.dart`** : au tap sur la zone facture (ou « Changer »), dialogue MAB avec **Prendre une photo** (`ImageSource.camera`) et **Choisir dans la galerie** (`ImageSource.gallery`), puis `pickImage` avec la source choisie.
- **Android** : `AndroidManifest.xml` — permission `CAMERA` pour l’appareil photo.

---

## 2026-03-25 — Carnet d’entretien V1 (point 4) : rappels prochains km / date (pré-remplissage)

- **`add_maintenance_screen.dart`** : lorsque **type** + **kilométrage** sont renseignés, pré-remplissage des champs optionnels « prochain km » et « prochaine date » selon le type (vidange, plaquettes, courroie, pneus, CT, révision, autre) ; base date = date d’intervention ; rechargement édition sans écraser via `_suppressAutoNextDefaults` ; types non listés = pas de calcul auto.

---

## 2026-03-25 — Carnet d’entretien V1 (point 5) : requête rappels (date sans km)

- **`mab_database.dart`** — `getMaintenanceAvecRappel` : filtre `rappel_actif = 1` et **`rappel_kilometrage > 0 OR rappel_date_ms > 0`** (les dates « vides » sont stockées en `0`, pas en SQL `NULL`).

---

## 2026-03-25 — PRD : précision périmètre carnet d’entretien V1

- **PRD.md** : §2.3 ajouté — détail du livrable « carnet d’entretien complet » (CRUD, facture photo, pré-remplissage, rappels in-app ; exclusion notifications système) ; date du document portée à 2026-03-25.

---

## 2026-03-24 — Mise à jour APK : vérification via JSON distant (hors Play Store)

- **Principe** : à l’affichage de l’accueil, requête silencieuse vers un JSON (`kMabVersionCheckJsonUrl`, par défaut `https://mecanoabord.systeme.io/version.json`) ; comparaison semver avec `package_info_plus` ; si version distante &gt; version installée → dialogue MAB (« Une nouvelle version est disponible 🎉 », message, boutons **Mettre à jour** → `url_launcher` sur `download_url`, **Plus tard** → fermeture).
- **Sans réseau ou erreur** : aucun message, comportement normal.
- **Fichiers** : `lib/services/update_check_service.dart`, `home_screen.dart` (post-frame callback), `docs-projet/version.json` (exemple à publier sur le même domaine / GitHub Pages), dépendance `package_info_plus`.

---

## 2026-03-24 — Écran OBD : bouton « Où est ma prise OBD ? » → Assistant IA

- **Bouton** en bas de l’écran OBD (`obd_scan_screen.dart`) : libellé « Où est ma prise OBD ? », icône `Icons.help_outline`, style `ElevatedButton` (MabColors.rouge, hauteur bouton MAB, `SafeArea`).
- **Comportement** : lecture du profil véhicule actif via `MabRepository.getVehicleProfile()` ; si marque, modèle et année (> 0) sont renseignés, envoi automatique d’une question personnalisée à l’IA sur l’emplacement de la prise ; sinon question générique (voiture en général, sous tableau de bord).
- **Navigation** : `Navigator.pushNamed` vers `/ai-chat` avec `arguments: {'initialQuestion': ...}`.
- **Assistant IA** (`ai_chat_screen.dart`, `main.dart`) : paramètre optionnel `initialQuestion` ; après le message d’accueil, envoi automatique de la question (via `_sendQuestion(obdLocationShortcut: true)`) pour afficher la réponse dans le fil. Si profil incomplet, ouverture depuis l’OBD affiche quand même le chat (drapeau `_openedWithObdQuestion`) pour ne pas bloquer cette aide.

---

## 2026-03-23 — OBD Android (MainActivity) : alignement ELM327, init lecture, délais

- **Fin de commande** : toutes les écritures vers le dongle utilisent le **retour chariot seul** (`\r`, 0x0D), et non plus **CR+LF** (`\r\n`), conformément à l’usage ELM327 courant.
- **Lecture véhicule (`readVehicleDataStep`)** : avant chaque commande OBD (`0101`, `03`, `07`, `0A`), envoi séquentiel **ATE0**, **ATL0**, **ATH1** via `sendAtCommandAndWait` avec **500 ms** entre chaque (mini-init pour un état dongle prévisible).
- **Détection de protocole (`tryProtocol`)** : **`INIT_CMD_DELAY_MS`** passé de 3000 ms à **500 ms** entre chaque commande AT de la séquence d’init, pour réduire fortement la durée totale des 10 essais (ordre de grandeur ~30 s au lieu de ~3 min) ; commentaires KDoc ajustés.
- **Lecture OBD (`sendObdCommand`)** : **`OBD_CMD_MIN_WAIT_MS`** passé de 8000 ms à **3000 ms** (délai minimal après apparition du prompt `>` avant de considérer la réponse figée) ; commentaire explicatif ajouté sur ce rôle de « sécurité raisonnable ».
- **Constante** : `PROTOCOL_DETECTION_WAIT_MS` (90 s) reste déclarée mais **non utilisée** dans le code — inchangé ce jour.
- **Fichier unique modifié** : `mecano_a_bord/android/app/src/main/kotlin/com/example/mecano_a_bord/MainActivity.kt`.
- **Déploiement test** : build APK release + `flutter install` sur Samsung **SM-A137F** (Android 14) pour validation terrain.

---

## 2026-03-09 — Coach vocal : choix de voix par pitch et débit (Android)

- Sur Android, les voix disponibles dépendent du téléphone ; le choix d’une voix masculine/féminine spécifique (getVoices/setVoice) ne changeait rien. **Correction** : on n’utilise plus la liste des voix. On règle la **hauteur** (pitch) et le **débit** (speech rate) avec flutter_tts : **Féminine** = pitch 1.2 (plus aigu) + speechRate 0.5 ; **Masculine** = pitch 0.7 (plus grave) + speechRate 0.45. À chaque synthèse (alerte ou « Tester la voix »), le service relit le réglage dans les préférences et applique ces paramètres, afin que l’utilisateur entende immédiatement la différence en changeant Féminine/Masculine puis en tapant « Tester la voix ». Fichier : `lib/services/tts_service.dart` (_applyPitchAndRate, suppression de getVoices/setVoice).

---

## 2026-03-09 — Coach vocal : alertes TTS, test voix, reconnaissance vocale Assistant IA

- **Alertes vocales** : quand l'OBD renvoie un résultat orange ou rouge (après lecture véhicule), l'app lit à voix haute un message d'alerte via `flutter_tts` (messages sans les mots interdits : panne, danger, défaillance). Voix et débit configurés pour la voiture ; respect du réglage « Alertes vocales » et « Voix féminine/masculine » dans Réglages.
- **Service TTS** : `lib/services/tts_service.dart` — langue fr-FR, volume 1.0, débit 0.45 ; choix de voix française selon genre (getVoices + filtre) ; `speakAlertForLevel(level)` et `speakTest()`.
- **Bouton « Tester la voix »** dans Réglages (section Coach vocal) : lit une phrase de démonstration pour vérifier la synthèse.
- **Reconnaissance vocale** : bouton micro sur l'écran Assistant IA (`speech_to_text`) ; permission micro (Android RECORD_AUDIO, iOS NSMicrophoneUsageDescription) ; texte reconnu inséré dans le champ de saisie, langue fr_FR.
- Dépendances : `flutter_tts`, `speech_to_text`. Déclenchement alerte : `obd_scan_screen.dart` après `saveLastObdDiagnostic` si `result.level` orange ou red.

---

## 2026-03-15 — Aide & Contact en écran intégré (2 onglets)

- Le bouton « Aide & contact » dans Réglages ouvrait une URL inaccessible. **Remplacement** : nouvel écran `help_contact_screen.dart` avec deux onglets. **Onglet Aide** : section « Guide d'utilisation » (6 étapes), section « Formation La Méthode Sans Stress Auto » avec bouton (lien à renseigner), section « Vidéos tutoriels » avec bouton (lien YouTube à renseigner). **Onglet Contact** : affichage email et site (placeholders), boutons « Ouvrir l'app email » / « Ouvrir le site », formulaire Nom, Email, Sujet, Message avec bouton « Envoyer » ouvrant le client mail avec champs pré-remplis. Route `/help-contact`, bouton Réglages → `Navigator.pushNamed(context, '/help-contact')`. Placeholders en tête de fichier : `_lienFormation`, `_lienYoutube`, `_emailContact`, `_lienSite`.

---

## 2026-03-15 — Politique de confidentialité en écran intégré

- Le bouton « Politique de confidentialité » dans Réglages ouvrait une URL inaccessible. **Remplacement** : nouvel écran intégré `privacy_policy_screen.dart` avec titre « Politique de confidentialité », bouton retour, filigrane et texte complet (10 sections : présentation, données collectées, stockage, tiers, permissions Android, sécurité, droits RGPD, mineurs, modifications, contact). Route `/privacy-policy` ajoutée dans `main.dart` ; le bouton dans Réglages appelle désormais `Navigator.pushNamed(context, '/privacy-policy')`. Contact : contact@mecanoabord.fr — France.

---

## 2026-03-09 — Boîte à gants : retour à OpenFile pour l'ouverture des documents

- Sur Android 14 (ex. Samsung SM-A137F), OpenFile ignorait le type MIME et affichait systématiquement « Choisir l’application ». **Correction** : ouverture via **Intent natif** avec **FileProvider** et type MIME sur l’Intent.
- **FileProvider** : `res/xml/file_paths.xml` expose le répertoire `files` de l’app ; provider dans le Manifest avec `grantUriPermissions="true"`. Fichier ouvert via URI `content://` sécurisé.
- **Intent** : `ACTION_VIEW`, `setDataAndType(uri, mimeType)`, `FLAG_ACTIVITY_NEW_TASK`, `FLAG_GRANT_READ_URI_PERMISSION`. En cas d’`ActivityNotFoundException`, le canal renvoie l’erreur `NO_APP` et l’app affiche « Aucune application disponible pour ouvrir ce type de fichier ».
- **Flutter** : sur Android, appel au MethodChannel `com.example.mecano_a_bord/file_opener` (méthode `openFile` avec `path` et `mimeType`) ; sur les autres plateformes, conservation de `OpenFile.open`. Fichiers : `MainActivity.kt` (openFileWithIntent), `AndroidManifest.xml` (provider), `file_paths.xml`, `glovebox_screen.dart` (channel + message NO_APP).

---

## 2026-03-09 — Boîte à gants : suppression par appui long + type MIME pour ouverture

- **Suppression par appui long** : sur un document, appui long affiche une boîte de dialogue « Supprimer ce document ? » avec boutons Annuler et Supprimer (rouge). Si confirmé : suppression du document en base (Room) et du fichier physique sur le stockage permanent ; la liste se met à jour immédiatement via callback `onDeleted`. En mode démo, la suppression ne fait rien.
- **Mémorisation du type MIME** : à l’ajout d’un document (photo ou import), le type MIME (image/jpeg, application/pdf, etc.) est déduit de l’extension du fichier et enregistré en base (nouvelle colonne `type_mime`, migration version 3). À l’ouverture, `OpenFile.open(path, type: mimeType)` utilise ce type pour ouvrir directement avec la bonne app, sans demander « Avec quelle application ouvrir ? ». Si le type est inconnu, `type` est passé à null pour laisser le système choisir sans popup. Fichiers : `mab_database.dart` (DocumentEntry.typeMime, migration 3, deleteDocument), `mab_repository.dart` (getMimeTypeFromPath, deleteGloveboxDocument, mapping mimeType), `glovebox_screen.dart` (_DocumentCard onLongPress + dialogue, ouverture avec type).

---

## 2026-03-09 — Boîte à gants : documents par photo/import — persistance et ouverture

- **Bug 1 (impossible d’ouvrir)** : le chemin enregistré pointait vers un fichier temporaire (photo ou import), supprimé après coup. **Correction** : lors de l’ajout par photo ou import, le fichier est **copié immédiatement** dans le répertoire permanent de l’app (`getApplicationDocumentsDirectory()/glovebox_documents/`) avant d’enregistrer le chemin en base. Le chemin sauvegardé pointe donc vers ce fichier permanent.
- **Bug 2 (documents disparaissent après fermeture)** : les documents étaient bien insérés en base Room, mais le chemin en base pointant vers un fichier temporaire, le flux pouvait échouer ou les anciens documents (sans copie) n’étaient plus ouverts. En enregistrant uniquement des chemins vers des fichiers permanents, la liste reste cohérente après redémarrage.
- **Ouverture** : au tap sur un document, vérification que le fichier existe ; si absent, message clair (« Fichier introuvable. Il a peut-être été supprimé ou déplacé. ») ; sinon ouverture avec `open_file`. Dépendances ajoutées : `path_provider`, `open_file`. Fichiers : `mab_repository.dart` (`copyDocumentToAppStorage`), `glovebox_screen.dart` (copie avant sauvegarde, ouverture avec contrôle d’existence).

---

## 2026-03-09 — Filigrane de fond : visibilité renforcée et présence sur toutes les pages

- **Visibilité** : opacité du logo filigrane (logo_mark.png) passée de 0,20 à **0,38** dans `mab_watermark_background.dart` pour qu’il ressorte davantage.
- **Couverture** : le filigrane s’affiche désormais sur **toutes** les pages concernées : Boîte à gants (GloveboxScreen — enveloppe du TabBarView), Réglages (déjà présent, désormais plus visible), Ajouter un entretien (AddMaintenanceScreen), Onboarding. Déjà présents : Accueil, OBD, Assistant IA, Profil véhicule, écrans placeholder.

---

## 2026-03-09 — Mode démo complet (sans voiture, sans dongle, sans clé API)

- Activation dans Réglages ou accueil « Mode démo ». Bandeau MODE DÉMO + Quitter le mode démo. Profil démo : Renault Clio 4, 87 500 km, VIN VF1R0000054321098. OBD : 3 scénarios VERT/ORANGE/ROUGE avec simulation. IA : réponses pré-enregistrées. Boîte à gants : faux documents et carnet. Fichiers : demo_data.dart, mab_demo_banner.dart, repository, écrans, ai_conversation_service.

---

## 2026-03-09 — Contexte véhicule automatique pour l’IA conversationnelle

- **Contexte injecté en arrière-plan** : au moment où l’utilisateur envoie un message à l’IA, l’app construit un contexte à partir du profil véhicule (marque, modèle, année, carburant, kilométrage, VIN), du dernier diagnostic OBD (codes défaut + date) et des 3 dernières entrées du carnet d’entretien. Ce contexte est injecté **en début de system prompt** (ChatGPT / Gemini), **invisible** pour l’utilisateur.
- **Instructions système** : le contexte demande à l’IA de répondre en tenant compte de ce véhicule précis et, si des codes défaut sont mentionnés, de préciser qu’ils datent du dernier diagnostic et qu’ils peuvent être effacés s’ils ont été réparés.
- **Persistance dernier OBD** : après chaque lecture véhicule réussie (écran OBD), date et codes défaut sont enregistrés dans SharedPreferences pour alimenter le contexte IA.
- **Profil incomplet** : si le profil véhicule n’est pas complet (VIN, etc.), l’écran Assistant affiche un message invitant à compléter le profil dans la Boîte à gants et **bloque l’envoi** de questions jusqu’à complétion.
- **Fichiers** : `mab_repository.dart` (saveLastObdDiagnostic, getLastObdDiagnostic, getLast3MaintenanceEntries, getAiSystemContextString), `ai_conversation_service.dart` (paramètre systemContext, injection dans le system prompt uniquement), `ai_chat_screen.dart` (vérification profil, bannière et écran « profil incomplet »), `obd_scan_screen.dart` (sauvegarde du diagnostic après lecture).

---

## 2026-03-09 — Détection protocole OBD : init ELM327 complète et validation assouplie

- **Problème** : la détection automatique (ATSP0..ATSP9) concluait « aucun protocole trouvé » alors que la voiture communique avec d’autres apps OBD (validation trop stricte : uniquement réponse commençant par 41).
- **Init avant chaque test** : avant chaque essai de protocole, envoi de la séquence ELM327 : **ATZ** (reset), **ATE0** (pas d’écho), **ATL0** (pas de saut de ligne), **ATS0** (pas d’espaces), **ATH1** (headers activés), **ATSPx** (protocole). **3 secondes** d’attente entre chaque commande pour laisser le dongle répondre.
- **Validation** : un protocole est considéré valide si la réponse à 0100 est **non vide** et **ne contient pas** ERROR, UNABLE, NO DATA, NODATA ni « ? » (plus seulement le préfixe 41).
- **Logs** : la réponse brute est loguée côté Android (`Log.d("MecanoOBD", "Protocol X response: ...")`) et renvoyée à Flutter ; `debugPrint('OBD protocole X: réponse brute = ...')` dans le service pour le débogage.

---

## 2026-03-09 — VIN obligatoire et protocole OBD par véhicule

- **Profil véhicule** : champ obligatoire « Numéro VIN (17 caractères) » avec validation (exactement 17 caractères alphanumériques) et info-bulle (« Le numéro VIN se trouve sur votre carte grise, sur le tableau de bord côté conducteur ou dans l'encadrement de la portière »). Base de données : colonne `numero_vin` ajoutée à `vehicle_profiles` (migration version 2). Profil « complet » exige désormais un VIN valide.
- **Android (MainActivity.kt)** : SharedPreferences (`obd`) avec clé `obd_protocol_<VIN>` pour enregistrer le protocole OBD (0..9) par véhicule. Connexion : `connect(address, deviceName, vin)` ; après ATZ, si un protocole est enregistré pour le VIN, envoi de `ATSPx` et connexion immédiate ; sinon retour `protocolDetectionNeeded: true`. Nouvelle méthode `tryProtocol(vin, protocolIndex)` : envoi ATSP0..ATSP9, attente 1 min 30 par protocole, test 0100 ; si réponse valide (41), enregistrement du protocole pour ce VIN.
- **Flutter** : `BluetoothObdService.connect(deviceId, deviceName, vin)` ; nouvel état `ObdConnectedNeedsProtocolDetection(deviceName)` ; `runProtocolDetection(vin, onProgress)` appelle `tryProtocol` en boucle (0..9) avec message « Test du protocole X/10 en cours... ». Écran OBD : au premier branchement (protocolDetectionNeeded), affichage du message « Premier branchement détecté — l'application s'adapte à votre véhicule, cela peut prendre 5 à 10 minutes. C'est normal et ne se fait qu'une seule fois » et de la progression ; une fois un protocole trouvé, lecture véhicule comme d’habitude.

---

## 2026-03-15 — OBD : lecture véhicule complète (30 s–3 min, modes 01/03/07/0A, progression)

- **Délai** : lecture entre **30 secondes et 3 minutes** (minimum 8 s par étape, max 45 s par étape).
- **Modes OBD** : 4 étapes — mode **01** PID 01 (statut moteur, MIL), **03** (codes stockés), **07** (codes en attente), **0A** (codes permanents). Réponse considérée valide seulement si préfixe OBD attendu (41 01, 43, 47, 4A) ; une réponse vide ou invalide n’est plus interprétée comme « aucun défaut ».
- **Progression** : libellés « Interrogation du moteur... », « Interrogation des freins... », « Interrogation de l’électronique... » et **barre de progression** pendant la lecture.
- **Résultat** : si aucune étape ne renvoie de réponse valide → niveau **incomplete** avec message « Lecture incomplète - Pas de réponse du véhicule ». Sinon vert / orange / rouge comme avant.

---

## 2026-03-15 — OBD : flux post-connexion (lecture véhicule, 3 niveaux vert/orange/rouge)

- Dès que la connexion au dongle est établie, l’app envoie automatiquement les commandes OBD **mode 01 PID 01** (statut général, MIL, nombre de DTC) et **mode 03** (codes défaut stockés).
- Pendant la lecture : affichage « Lecture du véhicule en cours... » (écran de chargement).
- Résultat affiché en **3 niveaux** : **vert** (aucun défaut), **orange** (défauts mineurs enregistrés), **rouge** (témoin moteur allumé / défauts critiques). Carte avec message et liste des codes défaut si présents.
- Android : méthode `readVehicleData` sur le canal OBD (envoi 0101 puis 03, parsing des réponses hex, calcul du niveau). Flutter : `getVehicleData()` dans le service, `ObdVehicleResult` (level, message, dtcs).

---

## 2026-03-15 — OBD : passage au Bluetooth classique (iCar Pro Vgate appairé par PIN)

- **Contexte** : le dongle iCar Pro Vgate fonctionne en **Bluetooth classique** avec appairage par code PIN dans les réglages du téléphone, pas en BLE. L’app utilisait BLE sans PIN et ne pouvait pas se connecter.
- **Android** : `MainActivity.kt` expose un **MethodChannel** `com.example.mecano_a_bord/obd` : `getBondedDevices` (liste des appareils déjà appairés), `connect(address, deviceName)` (connexion SPP + envoi ATZ, retour si OK), `disconnect`, `getConnectionState`. Connexion via `BluetoothSocket` et UUID SPP `00001101-...`.
- **Flutter** : `BluetoothObdService` utilise uniquement ce canal (plus de BLE) : `getBondedDevices()` pour la liste, `connect()` pour SPP + ATZ, `disconnect()`. Mêmes états `ObdConnectionState` pour l’accueil.
- **Écran OBD** : affiche en priorité les **appareils appairés** (liste = getBondedDevices). Si la liste est vide : message « Appairez d’abord le dongle dans les réglages Bluetooth de votre téléphone, puis revenez ici » + rappel PIN (Bluetooth classique) + bouton Rafraîchir. Connexion via SPP au tap sur un appareil.

---

## 2026-03-15 — OBD BLE : mode diagnostic et profils UUID alternatifs

- **Contexte** : connexion iCar Pro Vgate en échec ; suspicion UUID NUS.
- **Diagnostic** : après `discoverServices`, tous les services/caractéristiques UUID sont logués (`debugPrint`, visible en **mode debug**). Voir `_logAllServicesAndCharacteristics` dans `bluetooth_obd_service.dart`.
- **Profils** : `_obdBleProfiles` (Nordic NUS, FFE0/FFE1, Veepeak FFF0, OBDLink). Chaque tentative loguée ; si aucun ne correspond, ajouter les UUID du diagnostic.
- **Suite** : lancer en debug (Run/F5), reproduire, lire la console ; voir NOTES_INTENTION_TECHNIQUES.md § OBD.

---

## 2026-03-15 — OBD : délais de connexion 15 s, overlay et message d’erreur explicite

- **Connexion BLE** : délai maximum de tentative de connexion porté à **15 secondes** (timer qui annule et émet une erreur si la connexion n’est pas établie à temps).
- **Réponse ATZ** : délai d’attente de la réponse du dongle après la commande ATZ porté à **15 secondes** (au lieu de 8).
- **Écran OBD** : pendant toute la tentative de connexion, overlay plein écran avec le message « Connexion au dongle en cours... X secondes », animation (cercles pulsants), indicateur tournant et rappel « Vérifiez que le dongle est branché sur la voiture ». Compte à rebours visible (15 → 0).
- **Erreur** : en cas d’échec (timeout connexion, timeout ATZ, erreur BLE, service introuvable), message unique et explicite : « Échec de connexion - Vérifiez que le dongle est branché sur la voiture et que le contact est allumé. »

---

## 2026-03-09 — OBD : permissions BLE au scan et compte à rebours 15 s

- **Permissions** : au lancement du scan OBD, l’app demande explicitement les autorisations Bluetooth (BLUETOOTH_SCAN, BLUETOOTH_CONNECT) et localisation (ACCESS_FINE_LOCATION) via **permission_handler**. En cas de refus, un message explique d’activer les autorisations dans Réglages → Applications → Mécano à Bord.
- **Durée du scan** : scan porté à **15 secondes** (service + écran). Un **compte à rebours** s’affiche pendant la recherche (« Recherche en cours... X secondes ») pour que l’utilisateur voie clairement que l’app cherche.
- **Dépendance** : `permission_handler: ^11.3.0` ajouté. Android : ACCESS_FINE_LOCATION ajoutée au manifest (BLUETOOTH_SCAN sans `neverForLocation` pour compatibilité).

---

## 2026-03-14 — OBD : retour visuel pendant le scan et correction du scan BLE

- **Écran OBD** : pendant la recherche, affichage d’une animation (cercles pulsants type radar), du texte « Recherche du dongle en cours... » et « Allumez le iCar Pro Vgate à proximité », plus un indicateur tournant. Gestion des erreurs de scan : message explicite si Bluetooth désactivé ou permission refusée (`ObdScanException`).
- **Service BLE** : après `initialize()`, attente 400 ms puis re-vérification du statut avant de lancer le scan ; si non prêt, levée de `ObdScanException` au lieu de retourner une liste vide. Scan sans filtre de service (`withServices: []`) pour détecter le iCar Pro même s’il n’annonce pas NUS au scan.

---

## 2026-03-14 — OBD : passage au Bluetooth LE (iCar Pro Vgate)

- **Contexte** : le dongle utilisé est un iCar Pro Vgate en BLE (Bluetooth Low Energy), alors que le code utilisait le Bluetooth classique (SPP) et la lib pnuema (ELM327 sur socket classique).
- **Flutter** : `bluetooth_obd_service.dart` réécrit pour utiliser **flutter_reactive_ble** : scan des appareils annonçant le service Nordic UART (NUS), connexion au device, découverte des caractéristiques RX/TX NUS, envoi de la commande ATZ et attente de réponse pour valider la liaison. Les états (`ObdConnectionState`) et le stream `connectionState` sont inchangés pour l’accueil. Nouvelle API : `discoverDevices()` (remplace l’ancienne liste d’appareils appairés), `connect(deviceId, deviceName)`.
- **Écran OBD** : `ObdScanScreen` appelle `discoverDevices()` au chargement, affiche « Dongles OBD BLE », liste les appareils trouvés par le scan, bouton Rafraîchir ; au tap, `connect(deviceId, deviceName)`.
- **Android** : `MainActivity.kt` simplifiée (plus de MethodChannel ni de code OBD natif). Dépendance `com.pnuema.android:obd` retirée de `build.gradle.kts`. Permission `BLUETOOTH_SCAN` ajoutée dans le manifest (BLE). `minSdk` reste 28.

---

## 2026-03-14 — OBD : correctifs build et déploiement ; tests dongle à reprendre

- **Build** : mise à jour `file_picker` de 6.x à 8.x (compatibilité Flutter 3.27+ sans v1 embedding). Bibliothèque OBD passée à `com.pnuema.android:obd:1.9.0` (1.5.0 non résolue côté Kotlin). `minSdk` Android porté à 28 pour satisfaire la lib OBD. Correction du switch exhaustif dans `obd_scan_screen.dart` (pattern `_` pour `ObdConnectionState`).
- **Déploiement** : application compilée et installée sur Samsung SM-A137F. Connexion au dongle ELM327 non validée pour l’instant ; tests à reprendre ultérieurement (appairage Bluetooth, permission BLUETOOTH_CONNECT au runtime sur Android 12+).

---

## 2026-03-09 — OBD : intégration bibliothèque pnuema (ELM327)

- **Android** : dépendance `com.pnuema.android:obd` (1.9.0 en production) dans `android/app/build.gradle.kts`. Connexion Bluetooth + séquence d’init OBD gérées dans `MainActivity.kt` via un `MethodChannel` (`com.example.mecano_a_bord/obd`) : `getBondedDevices`, `connect(address)`, `disconnect`, `getConnectionState`. Utilisation de `ObdInitSequence.run(BluetoothSocket)` après création du socket RFCOMM (UUID SPP).
- **Flutter** : `bluetooth_obd_service.dart` utilise ce canal au lieu du stub : mêmes états (`ObdConnectionState`), méthodes `getBondedDevices()`, `connect(address)`, `disconnect()`. L’écran `/obd-scan` pointe vers `ObdScanScreen` (liste des appareils appairés, connexion / déconnexion au dongle). L’accueil continue d’afficher l’état OBD via le stream du service.

---

## 2026-03-09 — Boîte à gants (écran intégré, onglet Profil)

- **Écran Boîte à gants** : intégration de `GloveboxScreen` dans `mecano_a_bord/lib/screens/` et branchement de la route `/glovebox` dans `main.dart`. L'écran affiche désormais un vrai onglet Profil (lecture du profil véhicule via `MabRepository.instance`) avec bandeau d'état (profil complet / à compléter) et bouton pour créer / modifier le profil.
- **Autres onglets** : Documents, Carnet d’entretien, Historique existent visuellement mais affichent pour l’instant « Bientôt disponible » (aucune logique de données encore branchée).

---

## 2026-03-09 — Carnet d’entretien (repository + écran d’ajout)

- **Repository** : mapping complet entre `db.MaintenanceEntry` et le modèle de domaine `MaintenanceEntry` (garage, coût, rappels). Ajout des méthodes `getAllMaintenanceEntries`, `addMaintenanceEntry`, `updateMaintenanceEntry`, `getMaintenanceEntryById` et `getUpcomingMaintenanceAlerts` en s’appuyant sur `mab_database.dart`.
- **Base de données** : nouvelles méthodes dans `MabDatabase` pour récupérer / mettre à jour une entrée d’entretien par id.
- **Écran AddMaintenanceScreen** : porté dans `mecano_a_bord/lib/screens/add_maintenance_screen.dart` (thème MAB) avec saisie complète d’un entretien (type, date, km, rappels, notes, garage, coût, photo de facture) et route `/add-maintenance` déclarée dans `main.dart`.
- **Onglet Carnet** : dans `GloveboxScreen`, l’onglet Carnet charge maintenant les vraies données du carnet via `MabRepository` et permet d’ajouter des entretiens (les documents restent non branchés à ce stade).

---

## 2026-03-09 — Réglages : logos IA à la place des noms

- **Section Assistant IA** : affichage des fournisseurs par logos (grille) au lieu des libellés « ChatGPT » / « Gemini ». Dix fournisseurs : Claude, ChatGPT, Gemini, Mistral, Qwen, Perplexity, Grok, Copilot, Meta AI, DeepSeek. Logos attendus dans `assets/images/ia/` (claude.png, chatgpt.png, etc.) ; à défaut, affichage de l’initiale. Seuls ChatGPT et Gemini sont connectés pour l’instant ; les autres renvoient « sera disponible prochainement ».
- **Service IA** : enum `AiProvider` étendue ; documentation dans `assets/images/ia/README.txt`.

---

## 2026-03-09 — Onboarding 5 pages avec images et libellés

- **Onboarding** : passage à 5 pages avec images dédiées. Page 1 : logo.png, « Bienvenue dans Mécano à Bord ». Page 2 : obd.png, « Le boîtier connecté ». Page 3 : boite_a_gant.png, « Votre Boîte à gants numérique ». Page 4 : suv_images.png, « Créer mon profil véhicule ». Page 5 : systeme_io.png, « Accès à la méthode sans stress auto », bouton « Suivant » → création du profil véhicule.
- **Écran d'accueil** : inchangé (bandeau SUV, cartes OBD, Boîte à gants, Système IO).

---

## 2026-03-09 — Accès direct « la méthode sans stress auto » au menu principal

- **Écran d'accueil** : ajout d'une carte cliquable « la méthode sans stress auto » affichant une image (`assets/images/systeme_io.png`) ou une icône de remplacement si le fichier est absent. Au tap, navigation vers la route `/systeme-io` (écran placeholder en attendant le module).
- **Documentation** : procédure détaillée dans `docs-projet/PROCEDURE_IMAGE_MENU.md` (où déposer l'image pour l'app et optionnellement dans docs-projet/images/). Mise à jour de `mecano_a_bord/assets/images/README.txt` et de `docs-projet/README.md` (section images de référence).

## 2026-03-09 — Images Boîtier OBD, Boîte à gants et véhicule (SUV)

- **Boîtier connecté** : carte OBD avec image `OBD.png`, cliquable vers `/obd-scan`.
- **Boîte à gants** : carte avec image `boite a gant.png` à la place de l'icône dossier.
- **Véhicule** : bandeau visuel avec `suv images.png` sous l'en-tête (partie haute de l'accueil).
- Mise à jour `assets/images/README.txt` et `PROCEDURE_IMAGE_MENU.md` avec les quatre images (systeme_io, OBD, boite a gant, suv images).

---

## 2026-02-27 — Clôture de session : validation identité visuelle

- Mise à jour de l’app sur téléphone (SM A137F) ; l’utilisateur valide que le rendu est « beaucoup mieux » (splash, filigrane visible, Réglages en thème noir/gris anthracite).
- Session clôturée ; documentation à jour (EVOLUTION, BACKLOG).

---

## 2026-02-27 — Corrections identité visuelle : splash, filigrane, thème Réglages

- **Filigrane** : opacité portée de 0.04 à 0.12 et taille max 280×280 dans `MabWatermarkBackground` pour le rendre visible en arrière-plan.
- **Écran Réglages** : harmonisation avec le thème MAB (fond `MabColors.noir` / `noirMoyen`, textes `MabTextStyles`, boutons/cartes/champs selon la charte) ; filigrane ajouté.
- **Splash** : `fullscreen: true` dans `flutter_native_splash` ; Android 12+ utilise `logo_mark.png` dans le cercle système ; README `assets/images` mis à jour (option `splash_screen.png` pour logo plein écran sans bulle sur Android &lt; 12).
- **Filigrane étendu** : appliqué aux écrans Réglages, Assistant IA, Profil véhicule (Boîte à gants) et Placeholder.

---

## 2026-02-27 — Nouvelle identité visuelle et logo Mécano à Bord

- **Palette** : mise à jour de `MabColors` avec la palette officielle (Rouge principal `#C4161C`, Rouge secondaire `#E31E24`, Noir profond `#111111`, Gris anthracite `#2A2A2A`, Gris métallique `#B8A98A`, Fond clair `#F5F5F5`).
- **Thème** : conservation d’un thème sombre Material 3 (`ColorScheme.dark`) aligné sur la palette pour éviter les incohérences `ColorScheme` / `ThemeData`.
- **Logo** : intégration des assets `assets/images/logo.png` (logo complet) et `assets/images/logo_mark.png` (symbole sans texte) via widgets réutilisables (`MabLogo`, `MabWatermarkBackground`).
- **Accueil** : logo visible sur l’écran d’accueil + filigrane discret (opacity ~0.04) sur les écrans principaux à partir d’un wrapper commun.
- **Packaging** : configuration de `flutter_native_splash` (splash natif avec logo complet sur fond noir profond) et `flutter_launcher_icons` (icône Android à partir du symbole sans texte).

---

## 2026-02-26 — Lancement sur téléphone Android et préparation aux tests

- **Licences Android** : acceptées via `flutter doctor --android-licenses` (toutes les licences SDK).
- **NDK** : correction d’un NDK corrompu (suppression du dossier, retéléchargement automatique par Gradle) pour que le build Android aboutisse.
- **Premier lancement sur téléphone** : app installée et lancée sur Samsung SM A137F (Android 14) ; build réussi, installation OK.
- **Correctifs UI** : écran d’onboarding rendu défilable (SingleChildScrollView) pour supprimer l’overflow sur petits écrans ; ajout d’un visuel type logo sur le splash (icône voiture dans un cercle aux couleurs MAB).
- **Assets** : création de `mecano_a_bord/assets/images/` et configuration dans pubspec ; README pour ajout du vrai logo (logo.png) plus tard.
- **Suite** : l’utilisateur commence les tests manuels de l’application sur téléphone.

---

## 2026-03-09 — Boîte à gants — onglet Documents

- **Repository** : ajout du mapping `GloveboxDocument` ↔ `DocumentEntry` dans `MabRepository` + méthodes `getAllGloveboxDocuments()` et `addGloveboxDocument()`.
- **Écran** : activation de l’onglet **Documents** dans `GloveboxScreen` (liste des documents réels, état vide, carte par document).
- **Ajout** : bouton `+` proposant **Photographier** (image_picker) ou **Importer un fichier** (file_picker), stockage du chemin local dans la base SQLite.
- **Technique** : ajout de la dépendance `file_picker` dans `pubspec.yaml` pour la sélection de fichiers (images) sur l’appareil.

---

## 2026-02-25 — Mise en place du système de documentation projet

- **Création** du système de gestion de la documentation dans `docs-projet/` :
  - **README** : index (où trouver PRD, BACKLOG, notes techniques, évolution) et règles de mise à jour.
  - **PRD.md** : cahier des charges produit (périmètre V1, objectifs, exclusions), aligné avec CONTEXTE v6.
  - **BACKLOG.md** : backlog priorisé avec statuts (À faire / En cours / Fait / Reporté) et dates.
  - **NOTES_INTENTION_TECHNIQUES.md** : décisions d’architecture et choix techniques (stack, UI, OBD, IA, doc).
  - **EVOLUTION.md** : ce journal daté.
- **Objectif** : respecter la demande du développeur de mettre en priorité un système de doc à jour (PRD, backlog, notes d’intention techniques), avec évolution datée pour tous.

---

## 2026-02-25 — Complétion structure Flutter et vérification projet

- **Structure** : exécution de `flutter create .` dans `mecano_a_bord/` : ajout des dossiers android, ios, web, windows, test, etc., pour pouvoir builder et tester sur toutes les plateformes.
- **Corrections** : correction de 4 points bloquants — `getRemainingFreeQuota` dans settings_screen ; `CardThemeData` / `DialogThemeData` dans mab_theme ; test widget basé sur `MabApp` au lieu de `MyApp`.
- **Configuration** : permissions Bluetooth (Android manifest) ; NSBluetoothAlwaysUsageDescription (iOS Info.plist). Assets onboarding désactivés temporairement (affichage par icônes) pour éviter 404.
- **Tests** : `flutter test` OK (smoke test MabApp) ; `flutter analyze` sans erreur (reste des infos de style).
- **Impact** : projet prêt pour tests sur Chrome et, après acceptation des licences, sur Android. Code aligné pour compatibilité Android + iOS.

---

## 2026-02-25 — Règles design system Figma

- Ajout de la règle Cursor `.cursor/rules/mab-design-system-figma.mdc` pour toute l’app : couleurs, typo, espacements (MabColors, MabTextStyles, MabDimensions), et instructions pour l’implémentation depuis Figma. Règle en « always apply » pour garder la cohérence design/code.

---

## Références antérieures

- **2026-02-20** : Version 6 du fichier de contexte (CONTEXTE_CLAUDE_MECANO_A_BORD_V6.md) — périmètre V1, tableaux de fichiers, règles de travail.
- Les vérifications (charte, EAA, réglages développeur) et premiers pas Flutter/émulateur sont documentés dans les autres MD de `docs-projet/`.

---

*Ajouter une nouvelle entrée en haut de cette section « Journal » à chaque étape importante. Indiquer la date (AAAA-MM-JJ) et un résumé clair.*