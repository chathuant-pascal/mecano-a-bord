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

---

## 2. Parcours utilisateur

| Id | Élément | Statut | Date / note |
|----|---------|--------|-------------|
| B10 | Onboarding (5 pages avec images) | Fait | 2026-03-09 — logo, obd, boite_a_gant, suv_images, systeme_io ; **2026-03-28** — page d’**acceptation des conditions** en premier (hors carrousel), puis 5 pages ; lien `/legal-mentions` ; bouton « J’accepte et je commence » |
| B11 | Profil véhicule (glovebox_profile) | Fait | 2026-03-09 — VIN obligatoire (17 car. alphanum.), infobulle, validation ; isComplete inclut VIN ; **2026-03-28** — champ optionnel **motorisation** (SQLite `motorisation`, migration v4) |
| B12 | Accueil (home_screen) + navigation | Fait | **2026-03-28** — bandeaux harmonisés : cartes Boîte à Gants / Mode Conduite / Mode Démo **sans sous-titre** tronqué ; **2026-04-08** — bandeau OBD par défaut **« Connecte ton OBD »** (`titreCard`, pastille masquée + `FittedBox`) — validé build **1.0.0+12** ; **2026-04-09** — build **1.0.0+13** (terrain SM-A137F) |
| B12b | Accès direct « Système IO » (carte avec image sur l'accueil) | Fait | 2026-03-09 — route /systeme-io, image systeme_io.png |
| B13 | Réglages (settings_screen) | Fait | 2026-03-09 — logos IA (10 fournisseurs), grille à la place des noms ; **2026-03-23** — **Mentions légales & CGU** (9 blocs, `MabLegalMentionsSettingsSection`), navigation avec `initialSection: 'legal'` |
| B14 | Licences Android (flutter doctor --android-licenses) | Fait | 2026-02-26 |
| B15 | Lancement et tests sur téléphone physique (Android) | Fait | 2026-02-26 — SM A137F ; **référence terrain** : Samsung **SM-A137F**, Android **14** (voir NOTES §5b) ; **2026-04-09** — build **1.0.0+13** (TTS surveillance / OBD réel, sondage 4 s, écran OBD connexion) + **`flutter install`** sur **R58T92HCDAX** ; **2026-04-08** — build **1.0.0+12** ; **2026-04-05** — build **1.0.0+11** (version Réglages + PID **010C**) ; **2026-03-29** — build **1.0.0+9** ; **2026-03-28** — builds **1.0.0+2** à **1.0.0+7** ; **2026-03-23** — APK + checklist mentions légales |
| B16 | Tests manuels par l’utilisateur | En cours | Démarrage 2026-02-26 |

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

---

## 6. Surveillance et licence

| Id | Élément | Statut | Date / note |
|----|---------|--------|-------------|
| B50 | Surveillance arrière-plan (Foreground Service / Background Task) | À faire | Référence monitoring_background_service |
| B51 | Gestion licence (Firebase, 2 appareils) | À faire | Référence firebase_licence_manager |

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

---

*Dernière mise à jour backlog : 2026-03-23 — B15 suivi installation APK terrain. Mettre à jour statuts et dates à chaque avancement.*
