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

---

## 6. Surveillance et licence

| Id | Élément | Statut | Date / note |
|----|---------|--------|-------------|
| B50 | Surveillance arrière-plan (Foreground Service / Background Task) | À faire | Référence monitoring_background_service |
| B51 | Gestion licence (Firebase) | En cours | **2026-07-30** — projet Firebase `mecano-a-bord` créé (Spark, Firestore Montréal `northamerica-northeast1`) ; app Android enregistrée ; Auth anonyme activée (nettoyage auto désactivé) ; règles Firestore `licenses/` déployées (liaison par `request.auth.uid`) ; `license_service.dart` + `mab_auth_service.dart` + 11 tests unitaires ; **reste à faire** : écran de saisie du code, appel au démarrage/mise à jour, création manuelle des codes de test |
| B52 | Envoi du code de licence par SMS (alternative à l'email) | Reporté | **2026-07-30** — email retenu comme canal V1 (infra déjà en place : Gmail pro + Systeme.io) ; SMS nécessiterait un prestataire payant (ex: Twilio) non intégré au projet ; à ne construire que si un besoin réel se présente (système déjà neutre vis-à-vis du canal d'envoi, aucune adaptation requise côté vérification) |
| B53 | Clé Remote Config texte `discord_invite_url` | En cours | **2026-09-01** — 13ᵉ paramètre Remote Config, **type String** (les 12 autres sont booléens), valeur de repli `""`. `RemoteFeatureFlags` étendu pour lire des chaînes (`_readString`, getter `discordInviteUrl`, `kFeatureStringDefaultsMap`). Pilote le bandeau communauté (B17) : vide/absente/illisible/non-HTTPS/hôte non Discord ⇒ bandeau masqué. Sert aussi de kill switch (vider + publier). **Reste** : créer le paramètre dans la Console Firebase et y coller l'invitation permanente. Voir `REMOTE_CONFIG.md`. |

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

*Dernière mise à jour backlog : 2026-09-22 — verrou d'accès par code de licence sur formation-web (B66), mentions légales/confidentialité formation-web (B65), correctif mots interdits (B64, ferme). Voir EVOLUTION.md.*
