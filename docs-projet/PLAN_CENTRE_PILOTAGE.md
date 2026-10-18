# Plan du centre de pilotage — Phase 3 : tableau de bord socle

**Mis à jour le 18/10/2026 (soir) — A0, A1, A2 et A3 FAITS** (branche app `tableau-de-bord-socle`, dernier commit `7c742ae`) ; reste A4, après le correctif e-mail.
Chaque étape reste à valider par Pascal avant d'être commencée.

**Compatibilité :** le tableau de bord est un **site Flutter Web** (usage principal sur
ordinateur, lisible dans le navigateur d'un Android ou d'un iPhone). L'application mobile
n'est pas modifiée par ce chantier, sauf le correctif `formation_events` (chantier séparé,
Android ✅ / iOS ✅ — Dart uniquement). Les chiffres « iPhone » n'apparaîtront qu'après
iOS-SETUP (Firebase est aujourd'hui inactif sur iPhone).

> ⚠️ Le cahier des charges du 25/09/2026 (« Centre de pilotage Mécano à Bord — Cahier des
> charges ») **n'a pas été retrouvé** sur le PC (ni dans les deux dépôts, ni dans
> `kit-claude-code.zip`, ni dans OneDrive / Téléchargements / Documents / Bureau).
> Ce plan s'appuie sur les décisions de Pascal du 06/10/2026 et sur la liste d'Inès
> (CLAUDE.md). Voir section 7 pour les écarts à vérifier dès que le cahier sera retrouvé.

---

## 1. Décisions de Pascal (06/10/2026) — elles priment sur le cahier et le plan initial

1. Tableau de bord en **Flutter Web**, même langage et même design system que l'app
   (`MabColors` / `MabTextStyles` / `MabDimensions`). Usage principal sur ordinateur,
   lisible sur téléphone.
2. Accès réservé à **2 comptes** : `karucards@gmail.com` et `mecanoabord@gmail.com`.
   Aucun autre compte pour l'instant.
3. Accès par **étiquette « admin »** (custom claim) posée par un script lancé par Pascal
   lui-même. Les règles vérifient aussi `email_verified == true` et la connexion Google
   (`sign_in_provider == 'google.com'`).
4. Le site **ne lit jamais `licenses` ni les e-mails** : seulement des totaux calculés par
   les Cloud Functions, plus les **20 derniers retours**.
5. Onglet **Projet** : saisie manuelle, dans un lot ultérieur. **Pas de jeton GitHub.**
6. Le tableau de bord commence **maintenant, avant OBD-BLE**. Version minimale, puis petits
   lots testés.
7. Le **correctif `formation_events`** = ouvrir la formation dans la WebView de l'app depuis
   l'accueil. Il est fait **avant l'onglet Utilisateurs**.

Décisions complémentaires du 18/10/2026 :

8. **7 onglets** : **Accueil**, **Utilisateurs**, **Technique**, **Incidents** (actifs) ;
   **Projet**, **Stock** (Amazon Seller Central) et **Marketing** (Systeme.io) grisés
   « Bientôt disponible », **sans aucun code de connexion** à Amazon ni à Systeme.io.
9. **Ordre** : correctif 010B → B4 `formation_events` (sur sa propre branche, pas en
   parallèle) → socle A0 à A4.
10. **B54** (`licenses_private`) : à faire **avant l'ouverture de la bêta** à de vrais
    clients.
11. **Fiche incident** (maquette) : gravité `bloquante` / `majeure` / `mineure` ; statut `nouveau` /
    `qualifie` / `en_cours` / `resolu` / `clos` (n'importe lequel, sans ordre imposé) ; `clos`
    seulement avec un `bilan` non vide ; champs PRA facultatifs (`scenarioPra`,
    `utilisateursTouches`, `actionsMenees`, `bilan`) ; `creeLe` figé, suppression interdite.
12. **Mode guide** : bouton dans l'en-tête, activé à chaque ouverture, explications sous chaque
    indicateur (composant `Explication` réutilisable).
13. **Accueil** : « À regarder en premier » (vert/orange/rouge, liens vers les onglets), « Ta
    routine de 2 minutes, chaque matin » (4 étapes fixes), cartes résumé.
14. **YouTube = premier branchement de données, juste après A4** (lot Y1), car il ne dépend pas
    du SIRET.

---

## 2. Architecture

```
Navigateur (PC surtout, téléphone possible)
   │  connexion Google → jeton avec étiquette admin
   ▼
Site Flutter Web « pilotage » — Firebase Hosting, 2e site du projet mecano-a-bord
   │  lecture seule
   ▼
Firestore : pilotage/*            ← totaux + 20 derniers retours (déjà nettoyés)
            pilotage_incidents/*  ← incidents (lus + saisis à la main par Pascal)
   ▲
Cloud Functions (TypeScript, région northamerica-northeast1 = Montréal, comme Firestore)
   ├─ chaque heure : totaux licences / formation / retours / consentement
   ├─ à chaque nouveau retour : mise à jour des 20 derniers (sans deviceId)
   └─ alertes Crashlytics → nouvel incident
```

Choix détaillés :

- **Emplacement du code** : dans le dépôt **privé** `mecano-a-bord-app`, à côté de
  `firebase.json` et `firestore.rules` :
  - `mecano_a_bord/pilotage/` → projet Flutter Web séparé (son propre `pubspec.yaml`),
    pour que le code du tableau de bord ne se retrouve jamais dans l'app mobile ;
  - `mecano_a_bord/functions/` → Cloud Functions.
- **Design system** : le fichier `lib/theme/mab_theme.dart` (318 lignes, n'importe que
  `material.dart`) est **copié** dans `pilotage/lib/theme/`, avec un **test de
  synchronisation** qui échoue si les deux copies diffèrent. Évolution possible plus tard :
  un petit paquet partagé `mab_design` (demande de modifier les imports de l'app → chantier
  à part, avec accord de Pascal).
- **Pourquoi pas lire directement `feedback`** : la Function recopie les 20 derniers
  retours dans `pilotage/derniers_retours` **sans `deviceId`**. Ainsi aucune règle n'est
  ouverte sur `feedback`, et le site ne voit que le strict nécessaire.
- **Application Web Firebase dédiée « Pilotage »** (distincte de l'app Web de la
  formation), avec sa propre configuration générée par `flutterfire configure`.
  Recommandé : restreindre la clé API Web au domaine du site (Google Cloud Console).
- **Connexion Google sur téléphone (Safari iPhone)** : connexion par redirection, avec le
  domaine d'authentification réglé sur le domaine du site pilotage (Firebase Hosting sert
  `/__/auth/` sur chaque site du projet).
- **En-têtes de sécurité du site** (`firebase.json`) : pas d'indexation (`X-Robots-Tag:
  noindex`), interdiction d'affichage dans un cadre, politique de contenu stricte.
- **Logger** : un seul logger conditionné à `kDebugMode`, comme dans l'app. Try/catch sur
  toute lecture Firestore et sur la connexion, message clair + bouton « Réessayer ».

---

## 3. Étiquette « admin » (custom claim)

- Script Node (`functions/scripts/poser-admin.js` + `retirer-admin.js`) qui pose ou retire
  `admin: true` sur un compte donné **par son e-mail**, en refusant tout e-mail hors des 2
  autorisés.
- **Lancé par Pascal dans Google Cloud Shell** (console Google Cloud, déjà connecté en tant
  que propriétaire du projet) → **aucun fichier de clé de compte de service sur le PC ni
  dans OneDrive**.
- Préalable : chacun des 2 comptes doit s'être connecté **une fois** au site (le compte
  doit exister dans Firebase Auth avant qu'on pose l'étiquette).
- L'étiquette n'est prise en compte qu'après **déconnexion / reconnexion** (le site
  l'explique sur l'écran « accès refusé »).
- Retrait d'accès d'urgence : `retirer-admin.js`, ou désactiver le compte dans la Console.

---

## 4. Règles Firestore à ajouter (rien de l'existant n'est modifié)

```
function estAdmin() {
  return request.auth != null
    && request.auth.token.admin == true
    && request.auth.token.email_verified == true
    && request.auth.token.firebase.sign_in_provider == 'google.com';
}

// Totaux et 20 derniers retours — écrits uniquement par les Cloud Functions
// (Admin SDK, qui ne passe pas par les règles).
match /pilotage/{document=**} {
  allow read: if estAdmin();
  allow write: if false;
}

// Incidents : lus et saisis par Pascal, jamais supprimés (on les clôture).
match /pilotage_incidents/{incidentId} {
  allow read: if estAdmin();
  allow create, update: if estAdmin() && (validation des champs : titre ≤ 120,
                          gravité dans une liste, statut dans une liste, dates);
  allow delete: if false;
}
```

- **Rien n'est ouvert à l'app** : les appareils clients sont en connexion anonyme, sans
  e-mail ni étiquette → `estAdmin()` est toujours faux. La règle finale « tout le reste est
  refusé » reste en place. `licenses`, `feedback`, `formation_events`, `consent_stats` ne
  changent pas.
- **Tests sur l'émulateur Firestore** (`@firebase/rules-unit-testing`) :
  - normal : compte Google + vérifié + admin → lecture autorisée ;
  - erreur : appareil anonyme refusé ; compte Google sans étiquette refusé ; toute
    écriture dans `pilotage/` refusée (même admin) ; suppression d'incident refusée ;
  - limite : admin mais `email_verified == false` refusé ; étiquette `admin: "true"`
    (texte au lieu de booléen) refusée ; admin connecté autrement que par Google refusé ;
    lecture de `licenses` et `feedback` par l'admin **toujours refusée** en liste.
- Limite connue : une fois Google activé, n'importe qui peut se connecter au projet avec
  Google, mais ne voit rien (règles). Le bloquer complètement demanderait Identity Platform
  (changement de facturation des comptes anonymes) → non recommandé.

---

## 5. Étapes — d'abord celles qui ne dépendent de rien

Durées = temps de travail effectif avec Claude Code ; prévoir 3 à 4 semaines à ton rythme.
Chaque étape : montrée fichier par fichier, `flutter analyze` + `flutter test` (avec le
nombre de tests avant/après), EVOLUTION.md + BACKLOG.md à jour, revue de commit, **un
commit par étape après ton accord**.

### Bloc A — sans dépendance (version minimale)

| # | Étape | Qui | Comment on vérifie | Durée |
|---|---|---|---|---|
| A0 | ✅ **FAIT le 18/10/2026** (site `mab-pilotage`, app Web « Pilotage », `.firebaserc`, émulateur ; commit `e893f0b`) — **Prérequis.** ① Terminer ou mettre de côté le correctif 010B (dépôt app sur la branche `correctif-010b` avec 2 fichiers modifiés — ne rien mélanger) ; nouvelle branche `chantier-pilotage`. ② Installer Firebase CLI (`npm install -g firebase-tools`, outil officiel Google) et Java 21 (nécessaire à l'émulateur Firestore) — à valider par Pascal avant installation. ③ `firebase login`, liaison du projet (`.firebaserc` est vide aujourd'hui). ④ Console Firebase (Pascal) : activer la connexion **Google** dans Authentication ; créer le 2e site Hosting (ex. `mab-pilotage`, nom à vérifier) ; enregistrer l'app Web « Pilotage ». ⑤ Alerte de budget sur le forfait Blaze. | Pascal + Claude | `firebase projects:list` affiche mecano-a-bord ; la connexion Google apparaît active | ½ jour |
| A1 | ✅ **FAIT le 18/10/2026** (33 tests émulateur, règles publiées le 18/10 ; commit `8470498`) — **Règles + tests** (section 4), testées sur l'émulateur, puis publiées. | Claude | Tests de règles verts ; publication `firebase deploy --only firestore:rules` | 1 jour |
| A2 | ✅ **FAIT le 18/10/2026** (50 tests, aperçu local validé par Pascal ; commits `abce1c1` à `2fa2815`) — **Squelette Flutter Web** : écran de connexion Google, 7 onglets : **Accueil** (cartes résumé vides), **Utilisateurs**, **Technique**, **Incidents** (texte « Bientôt disponible » en attendant leurs lots), **Projet**, **Stock** (« À brancher : Amazon Seller Central ») et **Marketing** (« À brancher : Systeme.io ») grisés, écran **« Accès refusé »** (avec l'explication de la reconnexion), bouton Déconnexion, mise en page large sur PC et en colonne sur téléphone, zones tactiles 48 dp. Design system copié + test de synchronisation. | Claude | Tests widget — normal : admin → onglets ; erreur : non-admin → accès refusé, échec réseau → message + Réessayer ; limite : étiquette absente (jeton pas encore rafraîchi), e-mail non vérifié | 1,5 jour |
| A3 | ✅ **FAIT et validé en vrai le 18/10/2026** (scripts poser / retirer / lister, 31 tests émulateur ; Cloud Shell avec mecanoabord@gmail.com ; étiquette posée sur les 2 comptes ; tableau de bord ouvert après « Vérifier à nouveau » ; les 2 comptes sont Propriétaires IAM ; commits `ce7d8da`, `1f16f7a`, `7c742ae`) — **Script étiquette admin** (section 3) + mode d'emploi pas à pas pour Cloud Shell. | Claude écrit, **Pascal lance** | Le script refuse un 3e e-mail ; après reconnexion, les 2 comptes voient les onglets | ½ jour |
| A4 | **Mise en ligne** : d'abord sur un canal d'aperçu temporaire (`hosting:channel:deploy`, expire seul), puis sur le site pilotage. Toujours `--only hosting:pilotage`. | Claude + Pascal | Test sur PC, sur le SM-A137F, sur un iPhone si disponible ; un 3e compte Google voit « Accès refusé » | ½ jour |

**Fin du bloc A = version minimale en ligne** : connexion sécurisée, onglets vides, aucune
donnée exposée. ≈ 4 jours.

### Bloc B — petits lots suivants (dépendances indiquées)

| # | Lot | Dépend de | Durée |
|---|---|---|---|
| B1 | **Socle Functions** (TypeScript, Montréal) + premiers totaux : retours (nombre par type, note moyenne par contexte), consentement (accepté/refusé), et les **20 derniers retours sans deviceId**. Calculs en fonctions pures testées (normal/erreur/limite) + test sur émulateur. | A ; **B68** recommandé avant (sinon les numéros +590, +596… s'afficheraient en clair) ; vérification de la politique de confidentialité (section 7) | 2 jours |
| B2 | **Onglet Technique minimal** : répartition Android/iPhone et versions du système (champs techniques de `licenses` et `feedback`, lus par la Function — jamais l'e-mail), état des interrupteurs Remote Config (lu par la Function), réseau au moment des retours, liens directs vers Crashlytics et Performance. | B1 | 1,5 jour |
| B3 | **Onglet Incidents** : alertes Crashlytics (nouveau plantage, régression, hausse soudaine) → incident automatique ; retours de type « bug » ; saisie et clôture manuelle par Pascal ; rédaction du **PRA** (document, avec Pascal). | B1 | 2 jours |
| B4 | ✅ **FAIT le 18/10/2026** (backlog B85, commit app `d8bd08f`, validé sur le SM-A137F) — **Correctif `formation_events`** : sur Android, le bouton de l'accueil ouvre la formation dans la WebView de l'app, où le pont `MABFormation` enregistre les événements ; iPhone : navigateur (règle Apple 3.1.1, B84). | Rien (peut se faire en parallèle) | 1 jour |
| B5 | **Onglet Utilisateurs** : licences (totales, activées, révoquées), activations par semaine, actifs 7 et 30 jours (`lastCheckedAt`), avancement de la formation par module (avec la mention « données complètes (Android) depuis le JJ/MM » = date de diffusion aux clients de la version contenant B4 — installée sur le téléphone de test le 18/10/2026 ; iPhone non enregistré, voir B84), taux de consentement. | **B4**, B1 | 2 jours |
| B5b | **Onglet Accueil** : cartes résumé remplies (licences actives, incidents ouverts, derniers retours, état des interrupteurs). | B1 (puis B3, B5 pour les cartes correspondantes) | ½ jour |
| B6 | **Onglet Projet** (grisé dans le socle) : saisie manuelle (tâches, blocages, jalons) dans `pilotage_projet` (règles admin à ajouter, mêmes tests). | A | 1 jour |
| B7 | **App Check** pour le site pilotage (reCAPTCHA Enterprise via `firebase_app_check` — à vérifier sur pub.dev avant ajout). | A ; **obligatoire avant** que App Check soit rendu obligatoire sur Firestore | ½ jour |
| Y1 | **YouTube** (premier branchement de données, juste après A4 — ne dépend pas du SIRET). Avant tout code, présenter à Pascal : ① le compte Google propriétaire de la chaîne @mecanoabord et l'autorisation OAuth nécessaire (⚠️ en mode « test », l'autorisation expire au bout de 7 jours) ; ② la Cloud Function quotidienne et sa protection anti-boucle ; ③ la vérification préalable du plafond Cloud Functions (50 $) sur `mecano-a-bord`. **Décision du 18/10/2026 : brancher les DEUX chaînes YouTube de Pascal** (vidéos non répertoriées, réparties sur deux chaînes ; **on ne déplace aucune vidéo**, pour ne pas changer les adresses de la formation) ; affichage des statistiques **par chaîne et en total** ; à vérifier : les deux chaînes sont-elles sur le même compte Google ou sur deux comptes ? **Prérequis confirmés par Pascal** : plafond Cloud Functions à 50 $ sur `mecano-a-bord` ; chaîne principale @mecanoabord sur mecanoabord@gmail.com. Vidéos actuelles : 18 identifiants, tous dans `formation-web/index.html` ; tutoriels de l'app prévus dans Remote Config (`tutoriel_*_url`, pas encore créés). | A4 | à estimer |
| X1 | **Bouton « Exporter pour Claude »** sur l'Accueil (après les onglets remplis) : génère un résumé texte **anonyme** à copier — chiffres clés, incidents ouverts, derniers retours, état des interrupteurs. **Jamais** de nom, d'e-mail, de plaque ni de code de licence (masquage testé : cas normal, erreur, limite). Aucun envoi : Pascal copie-colle lui-même. | Onglets B1-B5 remplis | ½ jour |
| X2 | 💡 **Idée après la bêta** : bouton « Demander conseil » qui interroge Claude via l'API Anthropic, depuis une Cloud Function. À étudier avant tout code : nouvel envoi de données à un prestataire, donc **politique de confidentialité d'abord** (règle RGPD) ; clé d'API rangée dans Secret Manager, jamais dans le code ; coût par question ; même filtre d'anonymat que X1. | Bêta + X1 | à estimer |
| S1 | **Onglet « SAV / Garanties »** — 🔴 **avant l'ouverture de la bêta**. **Fiche par demande** : numéro de dossier, type (`garantie_14j` = remboursement intégral / `retractation` = retour du boîtier / `defaut` = boîtier défectueux), code de licence (seul lien vers le client ; l'e-mail reste dans Gmail, adresse **mecanoabord@gmail.com**), **version des CGV acceptée**, dates (réception du boîtier par le client, réception de la demande, réception du boîtier retourné), statut (`recue` → `en_cours` → `acceptee` / `refusee` → `remboursee` / `cloturee`), notes. **Échéances calculées depuis les CGV** et affichées en compte à rebours, en **orange puis rouge** dans « À regarder en premier » : garantie 14 j → remboursement ≤ 14 j après le retour du boîtier (art. 13.5) ; rétractation → remboursement ≤ 14 j après la demande (art. 12.7) ; défaut → réparation ou remplacement ≤ 30 j (art. 14.2). Contrôle d'éligibilité : demande ≤ 14 j après réception du boîtier (art. 12.1 / 13.1). **Remboursement de formation** : afficher si le client a commencé un module au-delà du seuil de **sa** version des CGV (`formation_events`, B85), avec les dates ; sans donnée → condition remplie (art. 13.3). Saisie manuelle par Pascal au départ ; plus tard, formulaire de demande sur le site. Collection `pilotage_sav`, règles Firestore et tests sur le modèle de `pilotage_incidents` (admin seulement, champs fermés, statuts en liste, `creeLe` figé, suppression interdite). **4 points à trancher avant de coder** : ① le seuil « au-delà du Module 1 » (décision du 17/10) n'est pas encore dans les CGV (art. 13.1-13.2 : à partir du Module 1) → d'où la version des CGV sur chaque fiche ; ② l'art. 14.2 ne fixe pas le point de départ des 30 jours → proposé : la demande du client, à préciser dans les CGV (juriste) ; ③ le code de licence est une donnée **pseudonymisée** (personnelle au sens du RGPD) → annoncer ce suivi SAV dans la politique de confidentialité **avant** de le coder ; notes libres sans nom ni e-mail (masquage automatique) ; ④ la lecture de `formation_events` passera par une Cloud Function (oui / non + dates), jamais en direct depuis le site. | A4 ; politique de confidentialité mise à jour d'abord | à estimer |

Total bloc B ≈ 10 jours. Plus tard, hors de ce plan : chiffres Crashlytics/Performance dans
le site (export BigQuery = nouveau lieu de stockage → politique de confidentialité
d'abord), mesure de l'usage OBD/surveillance (nouveaux événements Analytics →
politique + consentement d'abord), surveillance automatique du site de formation.

---

## 6. Liens avec les autres chantiers

- **OBD-BLE** : le tableau de bord passe **avant** (décision du 06/10). L'ordre noté dans
  `PLAN_OBD_BLE.md` (formation_events → B54 → hébergement formation → OBD-BLE) doit être
  mis à jour en conséquence (ordre validé le 18/10 : 010B → B4 → socle A0-A4 ; B54 avant
  la bêta). **À faire plus tard, dans un commit séparé** — `PLAN_OBD_BLE.md` n'est pas
  modifié par ce document.
- **Stock (Amazon Seller Central) et Marketing (Systeme.io)** : emplacements grisés
  seulement ; ils seront branchés après l'arrivée du SIRET et l'ouverture des comptes,
  chacun dans son propre plan (nouvelle utilisation de données → politique de
  confidentialité d'abord).
- **Correctif `formation_events`** : lot B4, avant l'onglet Utilisateurs (B5).
- **B54** (e-mail et date d'achat lisibles dans `licenses/{code}`) : ne bloque plus le
  tableau de bord, puisque ni le site ni les Functions n'ont besoin de l'e-mail. Reste un
  chantier de sécurité à faire **avant le lancement public**. Quand il sera fait, vérifier
  que les Functions ne lisent rien de ce qui aura été déplacé.
- **App Check (phase 1)** : à activer d'abord en **mode surveillance**. Avant de le rendre
  obligatoire sur Firestore, le site pilotage (B7) **et** la formation web doivent l'avoir,
  sinon ils seront bloqués. Sur iPhone, App Attest n'est possible qu'après iOS-SETUP : le
  rendre obligatoire avant bloquerait les futurs utilisateurs iPhone. Les Cloud Functions
  ne sont pas concernées.
- **Hébergement de la formation sur Firebase Hosting** : 3e site possible dans le même
  projet (domaine mecanoabord.fr). La formation est dans le dépôt **principal**, les règles
  Firestore dans le dépôt **app** → depuis chaque dépôt, toujours publier avec
  `--only hosting:<site>` pour ne jamais écraser les règles. À prévoir en même temps :
  liste blanche de la WebView et `lib/formation_url.dart`. Avec B4, la formation reste
  ouverte dans la WebView, donc l'enregistrement des événements ne dépend pas de
  l'hébergement.

---

## 7. Écarts avec le cahier et points non vérifiés

### Écarts possibles avec le cahier du 25/09 (non vérifiables : cahier introuvable)

- Le plan du 06/10 en chat proposait un site HTML/JS : **remplacé par Flutter Web**
  (décision 1).
- Accès par liste d'e-mails dans les règles : **remplacé par l'étiquette admin**
  (décision 3).
- Onglet Projet par synchronisation GitHub : **remplacé par une saisie manuelle**
  (décision 5).
- Lecture directe de `feedback` envisagée en option : **remplacée par une copie des 20
  derniers retours sans deviceId**, faite par une Function (choix proposé, à valider).
- Les Cloud Functions sont en **TypeScript** (langage officiellement pris en charge), pas
  en Dart : écart avec l'idée « même langage partout », limité au code serveur.
- À confronter avec le cahier dès qu'il est retrouvé : la liste exacte des indicateurs de
  chaque onglet (sections 2, 3, 4, 6, 9), la section 13 (plan de la phase 3) et la section
  14 (liens avec les autres chantiers).

### Incohérences repérées dans la politique de confidentialité (à corriger avant B1/B5)

- Section 5 : annonce un suivi du **« temps passé »** dans la formation → **non collecté**
  dans le code (seulement module démarré / terminé).
- Section 13 : annonce que les numéros de téléphone sont **masqués automatiquement** →
  faux pour les indicatifs autres que +33 (**B68**).
- Section 13 : parle de « la version d'Android » → à compléter pour iPhone (iOS-SETUP).
- Non vérifié : si les champs techniques des licences (marque, modèle, version du
  système) et l'usage « tableau de bord interne » sont annoncés.

### Ce qui n'a pas pu être vérifié

- **Le cahier des charges du 25/09** : introuvable (voir en-tête).
- **L'état de la Console Firebase** : l'outil Firebase ne s'est pas connecté pendant cette
  session. Inconnus : connexion Google activée ou non, Hosting activé, apps Web déjà
  enregistrées, alertes Crashlytics configurées, champs réellement présents dans les
  documents `licenses`.
- **Firebase CLI et Java** : absents de ce PC (commandes introuvables). Node v24 et
  Flutter sont présents ; la version exacte de Flutter n'a pas été lue.
- **La disponibilité du nom de site** `mab-pilotage` sur Firebase Hosting.
- **La fréquence de mise à jour de `lastCheckedAt`** (elle détermine la fiabilité des
  « actifs 7 et 30 jours »).
- **Le rendu réel** sur PC, sur le SM-A137F et sur iPhone : rien n'est construit.
- **La prise en charge de `firebase_app_check` sur le Web** : à vérifier sur pub.dev avant
  le lot B7.
- **Le contenu exact de la « phase 1 »** (App Check) : non documenté dans les dépôts.

---

*Créé le 06/10/2026 — mis à jour le 18/10/2026 (7 onglets, ordre des chantiers, B54).*
