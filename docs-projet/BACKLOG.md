# Backlog — Mécano à Bord

Liste priorisée des fonctionnalités et tâches, avec statut et dates.  
**À mettre à jour à chaque avancement.**

Légende des statuts : **À faire** | **En cours** | **Fait** | **Reporté**

---

## Légende

| Statut | Signification |
|--------|----------------|
| À faire | Non démarré |
| En cours | En cours de réalisation |
| Fait | Livré / terminé (avec date de clôture si pertinent) |
| Reporté | Hors V1 ou reporté à plus tard |

---

## 1. Fondations et projet

| Id | Élément | Statut | Date / note |
|----|---------|--------|-------------|
| B1 | Structure projet Flutter (android, ios, web, test) | Fait | 2026-02-25 |
| B2 | Système de documentation projet (PRD, BACKLOG, EVOLUTION, notes techniques) | Fait | 2026-02-25 |
| B3 | Thème MAB (mab_theme.dart) et design system | Fait | Déjà en place |
| B3b | Identité visuelle (palette, logo, splash, icône, filigrane, thème Réglages) | Fait | 2026-02-27 — validé par l’utilisateur |
| B4 | Configuration Android (manifest, permissions Bluetooth) | Fait | 2026-02-25 |
| B5 | Configuration iOS (Info.plist, NSBluetoothAlwaysUsageDescription) | Fait | 2026-02-25 |
| B5b | Provisioning Firebase iOS (Auth + Firestore + Remote Config + Analytics) | À faire | **2026-08-02** — ce n'est pas un manque du kill switch (MODULE 6+) mais un manque global : toute la chaîne Firebase (Auth anonyme, Firestore licences, Remote Config, Analytics) est Android uniquement aujourd'hui (pas de `GoogleService-Info.plist`, bundle ID encore `com.example.mecanoABord`, pas de `Podfile`). À traiter en bloc avec les autres chantiers iOS déjà connus (Codemagic, compte Apple Developer, renommage bundle ID) le jour où une sortie iOS sera planifiée — pas de date prévue à ce jour |

---

## 2. Parcours utilisateur

| Id | Élément | Statut | Date / note |
|----|---------|--------|-------------|
| B10 | Onboarding (5 pages avec images) | Fait | 2026-03-09 — logo, obd, boite_a_gant, suv_images, systeme_io ; **2026-03-28** — page d’**acceptation des conditions** en premier (hors carrousel), puis 5 pages ; lien `/legal-mentions` ; bouton « J’accepte et je commence » ; **2026-04-14** — après onboarding → **formation WebView interne** (`formation_webview_screen.dart`, `kFormationUrl`) puis accueil si **`formation_done`** ; profil véhicule **non** imposé au premier lancement |
| B11 | Profil véhicule (glovebox_profile) | Fait | 2026-03-09 — VIN obligatoire (17 car. alphanum.), infobulle, validation ; isComplete inclut VIN ; **2026-03-28** — champ optionnel **motorisation** (SQLite `motorisation`, migration v4) |
| B12 | Accueil (home_screen) + navigation | Fait | **2026-03-28** — bandeaux harmonisés : cartes Boîte à Gants / Mode Conduite / Mode Démo **sans sous-titre** tronqué ; **2026-04-08** — bandeau OBD par défaut **« Connecte ton OBD »** (`titreCard`, pastille masquée + `FittedBox`) — validé build **1.0.0+12** ; **2026-04-09** — build **1.0.0+13** (terrain SM-A137F) |
| B12b | Accès direct « Système IO » (carte avec image sur l'accueil) | Fait | 2026-03-09 — route /systeme-io, image systeme_io.png |
| B13 | Réglages (settings_screen) | Fait | 2026-03-09 — logos IA (10 fournisseurs), grille à la place des noms ; **2026-03-23** — **Mentions légales & CGU** (9 blocs, `MabLegalMentionsSettingsSection`), navigation avec `initialSection: 'legal'` |
| B14 | Licences Android (flutter doctor --android-licenses) | Fait | 2026-02-26 |
| B15 | Lancement et tests sur téléphone physique (Android) | Fait | 2026-02-26 — SM A137F ; **référence terrain** : Samsung **SM-A137F**, Android **14** (voir NOTES §5b) ; **2026-04-09** — build **1.0.0+13** (TTS surveillance / OBD réel, sondage 4 s, écran OBD connexion) + **`flutter install`** sur **R58T92HCDAX** ; **2026-04-08** — build **1.0.0+12** ; **2026-04-05** — build **1.0.0+11** (version Réglages + PID **010C**) ; **2026-03-29** — build **1.0.0+9** ; **2026-03-28** — builds **1.0.0+2** à **1.0.0+7** ; **2026-03-23** — APK + checklist mentions légales |
| B16 | Tests manuels par l’utilisateur | En cours | Démarrage 2026-02-26 |
| B17 | Accès communauté Discord après Module 6 | En cours | **2026-09-01** — bonus « Groupe privé Discord » de `formation-web/index.html` : prérequis `module3` → `module6` ; bandeau natif **« Rejoindre la communauté »** sur l'accueil (position 2, sous « La méthode sans stress auto »), visible uniquement si Module 6 validé **et** URL d'invitation Discord valide publiée dans Remote Config (`discord_invite_url`, cf. §6/B53) ; masqué sinon (jamais grisé) ; latch local `formation_module6_done` posé par le pont `MABFormation` (`module_completed:module6` ou `formation_done`) ; icône générique `Icons.groups_rounded` dorée (pas le logo Discord — marque déposée) ; ouverture via `url_launcher` en application externe ; **reste** : créer le serveur Discord, publier l'URL dans Remote Config, valider sur SM-A137F |

---

## 3. OBD et diagnostic

| Id | Élément | Statut | Date / note |
|----|---------|--------|-------------|
| B20 | Service Bluetooth OBD (classique SPP, iCar Pro Vgate) | En cours | **2026-04-05** — **`readLiveData`** : décodage **PID 010C** (RPM) côté **MainActivity.kt** ; **2026-03-23** — MainActivity : fin de ligne `\r`, mini-init AT avant lecture, délais init/détection/lecture affinés ; tests dongle + véhicule à poursuivre |
| B21 | Écran OBD / scan (obd_scan_screen) | Fait | 2026-03-14 — Scan BLE historique ; **parcours actuel** : appareils appairés SPP ; **2026-04-09** — titre **« Connecte ton OBD »**, pas de bouton diagnostic sur cet écran ; lecture auto uniquement depuis l’**accueil** (`autoStartDiagnostic`) ; **2026-04-08** — message connexion + diagnostic manuel (remplacé par 04-09) ; 2026-03-09 — VIN + détection protocole ; **2026-03-23** — effacement codes défaut (mode 04), dialogue + TTS + prefs dernier diagnostic |
| B21b | Protocole OBD par VIN (SharedPreferences, ATSP0–9, tryProtocol) | Fait | 2026-03-09 — Android MainActivity + Flutter service + écran ; 2026-03-23 — délais tryProtocol réduits (500 ms) |
| B22 | Résultat simplifié (vert / orange / rouge) | Fait | 2026-03-09 — ObdVehicleResult + écran OBD ; 2026-03-23 — lecture native fiabilisée (voir B20) |
| B23 | Mode démo (sans véhicule) | Fait | 2026-03-09 — Profil démo (Clio 4), 3 scénarios OBD, IA pré-enregistrée, boîte à gants démo, bannière MODE DÉMO, activation dans Réglages |

---

## 4. Boîte à gants

| Id | Élément | Statut | Date / note |
|----|---------|--------|-------------|
| B30 | Écran Boîte à gants (4 onglets) | En cours | 2026-03-09 — Onglet Profil intégré dans l’app (GloveboxScreen + route /glovebox) ; 2026-03-09 — Onglet Documents branché (liste + ajout photo/fichier) ; **2026-03-28** — Onglet Historique diagnostics OBD (liste SQLite + cartes expansibles) |
| B31 | Carnet d’entretien (add_maintenance, liste, rappels) | Fait | 2026-03-25 — V1 complétée : suppression entrée + fichier facture ; édition (route `/add-maintenance` + `editEntryId`) ; facture appareil photo ou galerie ; pré-remplissage prochains km/date selon type ; requête `getMaintenanceAvecRappel` inclut rappels date seule (`rappel_date_ms > 0`) |
| B32 | Base de données locale (mab_database, mab_repository) | Fait | mecano_a_bord/lib/data |

---

## 5. IA et voix

| Id | Élément | Statut | Date / note |
|----|---------|--------|-------------|
| B40 | IA conversationnelle (mode gratuit + personnel) | Fait | 2026-03-09 — Contexte véhicule auto (profil, dernier OBD, 3 derniers entretiens) injecté en system prompt ; profil incomplet = blocage + message Boîte à gants ; **2026-03-28** — contexte enrichi : **boîte**, **motorisation**, **km au diagnostic OBD** (`mab_last_obd_km_<id>`) |
| B41 | Coach vocal (voix F/M, alertes) | Fait | 2026-03-09 — TTS (flutter_tts) : alertes OBD orange/rouge, test voix dans Réglages ; STT (speech_to_text) : bouton micro sur Assistant IA |
| B42 | Simplifier le système IA (fournisseur unique intégré) | Reporté | Remplacer le choix entre 8 clés API BYOK par un seul fournisseur intégré et pré-configuré, plus adapté à un public débutant. Prévu pour la V2 de Mécano à Bord. |
| B67 | Accès aux tutoriels vidéo (écran dédié + carte accueil + liens contextuels) | En cours | **2026-09-27** — audit puis conception validés par Pascal avant tout code : écran `TutorialsScreen` (5 cartes miniature/titre/durée/« Vu »), carte permanente « Bien démarrer » sur l'accueil (jamais fermable), proposition en bottom sheet au premier lancement après activation de licence, 5 liens contextuels « Voir comment faire » (OBD, surveillance, alerte, carnet d'entretien, boîte à gants), bouton Aide & contact redirigé. 11 nouvelles clés Remote Config (voir `REMOTE_CONFIG.md`) : `feature_tutoriels` + 5 URL + 5 durées. Miniatures fournies par Pascal, recompressées (WebP, ~2 Mo → ~70 Ko chacune). Implémenté sur la branche dédiée `chantier-tutoriels-video` (les deux dépôts), tests 326 → 350. **Reste** : validation visuelle de Pascal sur le SM-A137F, commit/push après accord explicite, puis publication des 5 URL (et durées, facultatif) dans la Console Firebase Remote Config une fois les vidéos mises en ligne (non répertorié) — tant qu'une URL est vide, sa carte affiche « Bientôt disponible » sans bloquer le reste. **2026-09-30** — visuel « TUTORIELS » fourni par Pascal sur la carte d'accueil (WebP ~50 Ko, original rangé dans `docs-projet/visuels-sources/`) ; à vérifier sur le SM-A137F avec le reste du chantier (une seule vérification, un seul push). |

---

## 6. Surveillance et licence

| Id | Élément | Statut | Date / note |
|----|---------|--------|-------------|
| B50 | Surveillance arrière-plan (Foreground Service / Background Task) | À faire | Référence monitoring_background_service |
| B51 | Gestion licence (Firebase) | En cours | **2026-07-30** — projet Firebase `mecano-a-bord` créé (Spark, Firestore Montréal `northamerica-northeast1`) ; app Android enregistrée ; Auth anonyme activée (nettoyage auto désactivé) ; règles Firestore `licenses/` déployées (liaison par `request.auth.uid`) ; `license_service.dart` + `mab_auth_service.dart` + 11 tests unitaires ; **reste à faire** : écran de saisie du code, appel au démarrage/mise à jour, création manuelle des codes de test |
| B52 | Envoi du code de licence par SMS (alternative à l'email) | Reporté | **2026-07-30** — email retenu comme canal V1 (infra déjà en place : Gmail pro + Systeme.io) ; SMS nécessiterait un prestataire payant (ex: Twilio) non intégré au projet ; à ne construire que si un besoin réel se présente (système déjà neutre vis-à-vis du canal d'envoi, aucune adaptation requise côté vérification) |
| B53 | Clé Remote Config texte `discord_invite_url` | En cours | **2026-09-01** — 13ᵉ paramètre Remote Config, **type String** (les 12 autres sont booléens), valeur de repli `""`. `RemoteFeatureFlags` étendu pour lire des chaînes (`_readString`, getter `discordInviteUrl`, `kFeatureStringDefaultsMap`). Pilote le bandeau communauté (B17) : vide/absente/illisible/non-HTTPS/hôte non Discord ⇒ bandeau masqué. Sert aussi de kill switch (vider + publier). **Reste** : créer le paramètre dans la Console Firebase et y coller l'invitation permanente. Voir `REMOTE_CONFIG.md`. |
| B54 | Champs sensibles lisibles dans `licenses/{code}` (email, purchaseDate) | À faire | **2026-09-26** — constat lors de l'audit pré-lancement (Lot 3, formulaires de retour) : les règles Firestore actuelles (`allow get: if request.auth != null`) permettent à **n'importe quel appareil connaissant le code exact** de lire tout le document `licenses/{code}`, y compris les champs `email` et `purchaseDate` — jamais modifiables depuis l'app (voir règles), mais **lisibles**, ce qui n'était pas nécessaire au fonctionnement (seuls `status`/`deviceId`/`deviceBrand`/`deviceModel`/`osVersion` sont réellement utilisés côté client). Un code de licence peut fuiter (capture d'écran, partage accidentel, email transféré) sans que ça expose normalement de donnée personnelle — hors ce cas précis. **Correction proposée, à soumettre à Inès avant le lancement public** : déplacer `email`/`purchaseDate` dans une sous-collection ou un document séparé non couvert par la règle `allow get` de l'app (ex. `licenses_private/{code}`, accessible uniquement depuis la Console/un script serveur), en ne laissant dans `licenses/{code}` que les champs réellement lus par le client. Non traité dans ce lot (périmètre formulaires de retour uniquement). |

---

## 7. Système IO

| Id | Élément | Statut | Date / note |
|----|---------|--------|-------------|
| B55 | Module Système IO (écran et fonctionnalités) | À faire | Accès depuis l'accueil en place ; écran à créer |

---

## 8. Qualité et livraison

| Id | Élément | Statut | Date / note |
|----|---------|--------|-------------|
| B60 | Tests unitaires / widget (premier smoke test) | Fait | 2026-02-25 (widget_test MabApp) |
| B61 | Analyse statique (flutter analyze) sans erreur | Fait | 2026-02-25 |
| B62 | Assets onboarding (images) | À faire | Optionnel ; icônes utilisées pour l’instant |
| B62b | Logo sur splash (visuel actuel : icône ; optionnel : logo.png dans assets/images/) | Fait | 2026-02-26 |
| B63 | Dossier complet pour développeuse (Inès) | À faire | Selon CONTEXTE v6 |
| B64 | Mot interdit « panne » dans `formation-web/index.html` | Fait | **2026-09-01** — repéré pendant le chantier B17 (bonus « Checklist Entretien Simple »). Règle 2 CLAUDE.md. **2026-09-22** — corrigé pendant un audit lecture seule des 9 bonus : « panne » remplacé par « problème détecté » (Bonus 3), et une occurrence supplémentaire de « danger » trouvée et corrigée (Bonus 4, non repérée en 2026-09-01) + 2 occurrences de « dangereux » dans le même esprit. Commit `0def5c2` (`mecano-a-bord`). |
| B65 | Mentions légales, confidentialité et contact sur `formation-web/index.html` | Fait | **2026-09-22** — signalé par Pascal : le site étant accessible par URL publique indépendante (GitHub Pages), pas seulement affiché dans la WebView de l'app, il lui fallait ses propres informations légales (LCEN). Nouvelle section `#mentions-legales` + pied de page persistant (`#footer-site`) avec liens Mentions légales/Confidentialité et Aide & Contact (mailto). SIRET toujours « à compléter » (même lacune que côté app). Commit `b3dd2fb`. |
| B66 | Verrou d'accès par code de licence sur `formation-web/index.html` | Fait | **2026-09-22** — le site étant public, n'importe qui pouvait accéder gratuitement à toute la formation sans code de licence. Écran de verrou (`#mab-gate-overlay`) + vérification lecture seule Firestore `licenses/{code}` (Auth anonyme, nouvelle app Firebase Web dédiée) + code transmis silencieusement par l'app via fragment `#licence=...` (jamais `?query`, anti-fuite Referer) sur les deux écrans qui ouvrent la formation (`formation_webview_screen.dart` onboarding + `formation_web_launch_screen.dart` bouton accueil — bug trouvé et corrigé en testant sur le SM-A137F, ce second écran avait été oublié au premier passage). **Validé avec un code actif réel par Pascal sur le SM-A137F.** Commits `3d0c4f6` (`mecano-a-bord`), `5492ae0` + `8db374e` (`mecano-a-bord-app`). |
| B68 | 🔴 **PRIORITÉ HAUTE — avant la bêta** — Masquage des numéros de téléphone avec indicatif international | À faire | **2026-10-04** — constaté en préparant les tests du Lot 3 : `lib/utils/mab_sensitive_data.dart` ne masque que les formats français `0X XX XX XX XX` et `+33…`. Un numéro écrit avec un autre indicatif (ex. **+590** Guadeloupe, **+596** Martinique, **+594** Guyane, **+262** La Réunion/Mayotte, **+32** Belgique, **+41** Suisse, **+225** Côte d'Ivoire, etc.) part **en clair** dans les retours (`feedback`) et les rapports Crashlytics. La cible étant tous les pays francophones, il faut masquer tout numéro international (format `+` suivi de l'indicatif et des chiffres, avec ou sans séparateurs). Tests à prévoir : cas nominal (chaque indicatif cité), cas d'erreur (texte sans numéro inchangé), cas limite (séparateurs espaces/points/tirets, numéro collé à du texte, nombres qui ne sont pas des téléphones : kilométrage, prix). Ne pas corriger avant validation de Pascal. |
| B69 | 🔴 **PRIORITÉ HAUTE — avant la bêta** — Taille de police écrite en dur dans le formulaire de retour | À faire | **2026-10-04** — `lib/widgets/mab_feedback_sheet.dart:284` : `TextStyle(fontSize: 26)` pour les émojis de la note, contraire à la RÈGLE 3 (design system obligatoire). Remplacer par un style ou une dimension de `MabTextStyles` / `MabDimensions` (en créer une si aucune ne convient, après accord de Pascal). Vérifier visuellement sur le SM-A137F que la taille des émojis ne change pas. |

---

## 9. Plan modules (CLAUDE.md — priorité livraison)

| Module | Élément | Statut | Date / note |
|--------|---------|--------|-------------|
| **MODULE 4** | WebView formation sécurisée (`formation_webview_screen.dart`) — NavigationDelegate, allowlist, validation JS, erreurs, timer cycle de vie, spinner | **Fait** | **2026-04-19** — 6 correctifs (OWASP + UX) ; fiche `fiches-fonctionnalites/FICHE_MODULE_04_WEBVIEW.md` |
| **MODULE 5** | Logger conditionnel `mab_logger.dart` + remplacement **13** `debugPrint` dans **7** fichiers | **Fait** | **2026-04-19** — fiche `fiches-fonctionnalites/FICHE_MODULE_05_LOGGER.md` |
| **MODULE 6** | Feature flags `lib/config/mab_features.dart` — **12** `kFeature*` (`kFeatureLicence=false`) | **Fait** | **2026-04-19** — fiche `fiches-fonctionnalites/FICHE_MODULE_06_FEATURE_FLAGS.md` ; étendu en kill switch distant le **2026-08-02** (voir ligne ci-dessous) |
| **MODULE 7** | Ajouter `try/catch` manquants (`main.dart`, `onboarding_screen`, `add_maintenance_screen`, `glovebox_screen` — voir CLAUDE.md) | **Fait** | **2026-04-19** — fiche `fiches-fonctionnalites/FICHE_MODULE_07_TRY_CATCH.md` |
| **MODULE 8** | Système licence Firebase (CLAUDE.md — Mission 2 Inès) | **En cours** | **2026-07-30** — réalisé directement avec Pascal (hors planning Inès, sur demande explicite) : projet Firebase + Firestore + Auth anonyme + règles de sécurité + service de licence + tests (voir B51) ; reste : écran de saisie + intégration au flux de démarrage |
| **MODULE 9** | Tests unitaires service IA (`ai_conversation_service_test.dart` — **13** tests ; `MockClient` `http/testing.dart`) | **Fait** | **2026-04-19** — fiche `fiches-fonctionnalites/FICHE_MODULE_09_TESTS_IA.md` |
| **MODULE 14** | Providers IA — **8** appels API (`_callChatGpt`, `_callGemini`, `_callMistral`, `_callPerplexity`, `_callGrok`, `_callDeepSeek`, `_callQwen`, `_callClaude`) + **Copilot** / **Meta AI** (`AiError` sans API perso) | **Fait** | **2026-04-19** — fiche `fiches-fonctionnalites/FICHE_MODULE_14_PROVIDERS_IA.md` |
| **MODULE 2** | Keystore de signature Release Android (bloquant Play Store) — `mecanoabord-release.jks` + `android/key.properties` | **Fait** | **2026-07-26** — RSA 2048, alias `mecanoabord`, validité 10 000 jours ; ancienne tentative (mot de passe exposé) sans fichier trouvé à révoquer ; réalisé directement (hors planning Inès, sur demande explicite de Pascal) |
| **MODULE 3** | Renommage package Android `com.example.mecano_a_bord` → `fr.mecanoabord.app` (irréversible après publication) | **Fait** | **2026-07-26** — `build.gradle.kts` (`namespace`/`applicationId`) + déplacement `MainActivity.kt` ; réalisé directement (hors planning Inès) ; changements code pas encore commités à cette date |
| **MODULE 10** | Tests unitaires Repository (CLAUDE.md PRIORITÉ 3) | **À faire** | **Suivant** |
| **MODULE 6+** | Kill switch à distance — Firebase Remote Config pour les 12 feature flags (`remote_feature_flags.dart`, `mab_feature_disabled_notice.dart`) | **Fait** | **2026-08-02** — 10 des 12 flags désormais réellement branchés (routes, TTS, onglets Boîte à gants, mise à jour, formation) ; repli automatique sur les valeurs par défaut si Remote Config injoignable ; `kFeatureRappelsAdmin` documenté comme sans effet (aucune fonctionnalité correspondante) ; voir `REMOTE_CONFIG.md` ; 167/167 tests verts |

---

## 10. Juridique et vente

| Id | Élément | Statut | Date / note |
|----|---------|--------|-------------|
| B71 | Conditions générales de vente (CGV) | En cours | **2026-10-11** — rédigées en version définitive : `docs-projet/juridique/CGV_MECANO_A_BORD.md` (référence) + `CGV_SYSTEMEIO.txt` (texte à coller dans Systeme.io, **généré depuis le .md** : toujours modifier le .md d'abord). Produit présenté comme entièrement prêt (Android ET iPhone), sans bêta, sans prix chiffré, garantie commerciale 14 jours sous conditions (art. 13, Module 0 exclu). Reste : relecture de Pascal, compléter B75, relecture par un professionnel du droit, publication sur Systeme.io. |
| B72 | 🔴 **BLOQUANT avant mise en vente** — Politique de confidentialité : nouvel usage des données de progression (garantie commerciale) | En cours | **2026-10-12** — texte maître rédigé et validé, écran de l'app généré (commits app `e123d41`, `94e1a51`), page publique `confidentialite.html`, résumé dans la formation web (voir EVOLUTION.md). Reste : compléter les crochets (date, SIRET, durées Analytics/Crashlytics, prestataires de paiement, hébergement Systeme.io, entité Amazon), publier, vérifier sur le Samsung (B79), relecture par un juriste (questions dans la note du texte maître). **⛔ CONDITION DE MISE EN LIGNE (décision de Pascal, 12/10/2026)** : ne fusionner dans `main` (ce qui publie sur GitHub Pages `confidentialite.html`, `cgv.html` et le nouveau lien de la formation web) **qu'une fois `[SIRET]`, `[MENTION TVA]` et `[MÉDIATEUR]` complétés** dans les textes maîtres, puis pages régénérées et vérifiées. D'ici là, les branches `chantier-cgv` et `chantier-confidentialite` restent sur GitHub sans fusion. Les points « CONFORMITÉ » hors politique (e-mail `contact@` dans les mentions légales et l'aide, bloc Éditeur de la formation web) restent à faire. **2026-10-11** — l'art. 13.3 des CGV prévoit que Mécano à Bord consulte les données de progression (`formation_events` : modules ouverts/terminés liés au code de licence) pour vérifier qu'aucun module à partir du Module 1 n'a été commencé. La politique de l'app (`privacy_policy_screen.dart`, section 5) ne cite aujourd'hui que deux usages (accompagnement, amélioration) → ajouter celui-ci **avant** la mise en vente (règle RGPD de Pascal), ainsi que dans la politique de la formation web. À regrouper avec le chantier « CONFORMITÉ » (PRIORITÉ 1 de CLAUDE.md) : e-mail `mecanoabord@gmail.com` au lieu de `contact@`, données d'achat (Systeme.io), adresse transmise au prestataire logistique, vouvoiement, « rien n'est envoyé à un serveur » faux sur la formation web. |
| B73 | Prix de lancement **sans prix barré** | À faire | **2026-10-11** — décision de Pascal : sur la page de vente, présenter seulement un « prix de lancement », jamais « X € au lieu de 297 € ». Raison : art. L. 112-1-1 du Code de la consommation (le prix de référence d'une réduction = prix le plus bas pratiqué dans les 30 jours précédents ; au lancement, 297 € n'aura jamais été pratiqué). Conditions de l'offre (prix, durée, places) uniquement sur la page de vente (CGV art. 6). |
| B74 | Limite du suivi d'activité de la formation (garantie commerciale) | À faire | **2026-10-11** — les événements `module_started` ne sont enregistrés que si la formation est ouverte **depuis l'app** (WebView → `FormationEventService`), avec une licence active et du réseau (échec silencieux sinon). Une ouverture **dans un navigateur** (accès possible avec le verrou de licence B66) ou hors connexion n'est pas enregistrée → la CGV prévoit alors que la condition « aucun module commencé » est remplie (en faveur du client). À relier au chantier du verrou de licence de la formation web (B66) : étudier l'envoi des événements directement depuis `formation-web/index.html`. Ne rien coder sans accord de Pascal. |
| B75 | Éléments entre crochets à compléter dans les CGV | À faire | **2026-10-11** — `[SIRET]` ; `[MENTION TVA]` (franchise : « TVA non applicable, art. 293 B du CGI », règles TVA de la Guadeloupe à confirmer avec un comptable) ; `[MÉDIATEUR]` (obligatoire) ; `[ZONES DE LIVRAISON]` (emplacement de la liste des zones desservies — couverture Amazon expédition multicanal non confirmée : France métropolitaine, UE, DOM, hors UE ; si les DOM ne sont pas couverts, la Guadeloupe ne peut pas être livrée) ; `[FRAIS DE LIVRAISON]` ; `[DÉLAI D'EXPÉDITION]` ; douane / octroi de mer à la charge de qui (art. 5.5) ; `[MONTANT INDICATIF]` d'un retour ; frais de réexpédition si adresse erronée (art. 11.8) ; étiquette de retour disponible ou non (art. 12.6) ; `[DURÉE MINIMALE D'EXPLOITATION]` ; `[PRÉAVIS]` ; `[MODALITÉ À DÉCIDER]` si arrêt du service avant la durée minimale ; `[VERSION MINIMALE D'IOS]` ; `[MOYENS DE PAIEMENT]` ; délai d'envoi du code de licence ; délai de réponse du service client ; `[DATE D'ENTRÉE EN VIGUEUR]` ; `[NUMÉRO DE VERSION]`. Vérifier aussi l'Annexe 2 (garanties) **mot pour mot** avec le texte officiel sur Légifrance. |
| B76 | Configuration de la page de vente Systeme.io (conformité CGV) | À faire | **2026-10-11** — deux cases à cocher séparées (acceptation des CGV ; accès immédiat + renoncement à la rétractation pour le numérique — si non cochée, code envoyé après 14 jours) ; bouton « Commander avec obligation de paiement » ; e-mail de confirmation contenant les CGV, la répartition du prix boîtier / numérique et l'accord d'accès immédiat ; liste des zones desservies publiée ; informations de compatibilité visibles avant paiement ; vérifier que l'entrepôt Amazon accepte les retours des clients. |
| B77 | 🔴 **BLOQUANT avant lancement** — Recherche du véhicule par plaque : l'API Particulier fonctionne-t-elle réellement ? | À faire | **2026-10-11** — `vehicle_profile_controller.dart` (~ligne 96) appelle `https://particulier.api.gouv.fr/api/v2/immatriculation` **sans jeton d'accès** ; cette API exige normalement une habilitation officielle et une clé → la recherche échoue probablement aujourd'hui (non vérifié). 1) Tester réellement ; 2) si elle ne fonctionne pas : décider entre une solution légale (habilitation officielle) ou le retrait de la fonction ; 3) aligner la politique de confidentialité (section 4.8 du texte maître) et l'interrupteur `feature_plaque`. |
| B78 | 🔴 **BLOQUANT avant publication** — Autorisations : correspondance mot pour mot avec la politique | À faire | **2026-10-11** — la section 5 du texte maître décrit les autorisations **au lancement** (BLE, Android + iPhone, localisation seulement sur Android 9 à 11). Avant toute publication sur les stores : comparer les autorisations réellement déclarées (`AndroidManifest.xml`, `ios/Runner/Info.plist`) et réellement demandées dans le code (`Permission.*`) avec la section 5 ; toute différence → corriger le code ou le texte maître, puis régénérer l'écran. Étape ajoutée au plan OBD-BLE (`PLAN_OBD_BLE.md`, étape 9). |
| B79 | Vérifications visuelles sur le Samsung SM-A137F à la prochaine installation | À faire | **2026-10-11** — liste tenue à jour, à cocher par Pascal : **(1)** écran Politique de confidentialité (Réglages) : lisibilité des titres dorés des sous-parties 4.1 à 4.10, titre principal un peu plus grand (style `titreSection`), défilement jusqu'à « 13. Contact », bouton retour, lien « Mentions légales ». *(Commit `94e1a51`, dépôt app, branche `chantier-confidentialite`.)* **(2)** Formation intégrée à l'app, section « Mentions légales & Confidentialité » → « Politique de confidentialité » : résumé en 5 points lisible, lien « Lire la politique de confidentialité complète → » qui ouvre bien la page publique `confidentialite.html` (et retour possible à la formation avec le bouton retour du téléphone). *(À faire après publication sur GitHub Pages.)* |

---

*Dernière mise à jour backlog : 2026-10-11 — nouvelle section 10 « Juridique et vente » : CGV rédigées (B71), politique de confidentialité à compléter avant la vente (B72, bloquant), prix de lancement sans prix barré (B73), limite du suivi d'activité (B74), éléments à compléter (B75), page de vente Systeme.io (B76). Précédente : 2026-10-04 — ajout B68 (masquage des numéros internationaux) et B69 (taille de police en dur, formulaire de retour), priorité haute avant la bêta. Précédente : 2026-09-22 — verrou d'accès par code de licence sur formation-web (B66), mentions légales/confidentialité formation-web (B65), correctif mots interdits (B64, ferme). Voir EVOLUTION.md.*
