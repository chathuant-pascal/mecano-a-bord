# Carte des branches — Mécano à Bord

**À jour au 18/10/2026 (après les suppressions).** Claude Code la met à jour à chaque
création, fusion ou suppression de branche (règle de Pascal, 18/10/2026). Deux dépôts Git distincts (voir CLAUDE.md, « État Git ») :

- **Dépôt principal** `chathuant-pascal/mecano-a-bord` (docs + formation web) — dossier racine `Mecano A Bord/`
- **Dépôt app** `chathuant-pascal/mecano-a-bord-app` (application Flutter) — dossier `Mecano A Bord/mecano_a_bord/`

Légende : 🟢 prête / à jour · 🟡 travail en cours · 🔴 bloquée · ⚪ terminée (gardée pour mémoire) · 🔒 locale, jamais poussée

---

## Dépôt app (`mecano-a-bord-app`)

| Branche | Contenu | État | Attend |
|---|---|---|---|
| `main` | Version de référence de l'app (`2c28bf5`) — contient B85 (formation dans l'app depuis l'accueil), **pas encore le 010B** : ne pas installer sur le Samsung depuis `main` | 🟢 | — |
| `correctif-010b` | Correctif 010B : 010B = pression d'admission, plus jamais lue comme pression d'huile ; plage 0-255 kPa ; règle « électrique ? » ; message huile une fois par véhicule (`88f24c7`, 375 tests) | 🟡 poussée | **Test en vraie voiture** (Samsung + Vgate), puis documentation, revue de commit, fusion dans `main` — **prochaine fusion** |
| `tableau-de-bord-socle` | Socle du tableau de bord (étapes A0 à A4 du plan) : `.firebaserc` (projet `mecano-a-bord`, cible `pilotage` → site `mab-pilotage`), émulateur Firestore, puis règles `pilotage/*` et `pilotage_incidents/*`, site Flutter Web (connexion Google réservée à 2 comptes, 7 onglets dont 3 grisés), script du rôle admin | 🟡 en cours (créée le 18/10/2026 depuis `main` `2c28bf5`) — **A0, A1 (règles publiées le 18/10), A2 et A3 faits** (`7c742ae` ; 50 tests pilotage, 31 tests outils-admin ; étiquette admin posée sur les 2 comptes le 18/10) | Étape A4 (mise en ligne), après le correctif e-mail, puis revue et fusion dans `main`. ⚠️ **Ne jamais publier les règles Firestore depuis `main` tant que cette branche n'est pas fusionnée** (cela effacerait les règles du tableau de bord) |
| `chantier-confidentialite` | Écran Politique de confidentialité généré depuis le texte maître (B72) + retrait du VIN de l'assistant IA (`94e1a51`) | 🔴 poussée | **SIRET**, mention TVA, médiateur (décision du 12/10), puis vérification Samsung (B79) |
| `essai-local-samsung` | Combinaison **010B + B4**, uniquement pour compiler l'APK installé sur le Samsung (`e943104`, 385 tests) — c'est la version actuellement sur le Samsung | 🔒 locale | **Rien** : jamais poussée (hook `pre-push` local), jamais fusionnée. Sert au test voiture du 010B. À supprimer quand le 010B sera dans `main` |

## Dépôt principal (`mecano-a-bord`)

| Branche | Contenu | État | Attend |
|---|---|---|---|
| `main` | Docs et formation web publiées (GitHub Pages) (`bd97924`) | 🟢 | — |
| `docs-backlog-010b` | Backlog B70, B80 à B85 ; journal EVOLUTION du 18/10 (B85) ; règle de nommage de la formation et règle de la carte (CLAUDE.md) ; cette carte des branches | 🟡 poussée | **Revue**, puis fusion dans `main` (aucun blocage SIRET) |
| `chantier-pilotage` | Plan du centre de pilotage (7 onglets, ordre des chantiers) — le code est sur `tableau-de-bord-socle` (dépôt app) | 🟡 poussée | Début du socle A0-A4 (après le 010B) |
| `chantier-cgv` | CGV définitives, backlog B71-B76, CLAUDE.md V5.1 (`c30d3c2`) | 🔴 poussée | **SIRET**, mention TVA, médiateur, relecture juridique ; correction du seuil de garantie (Module 1, B84) |
| `chantier-confidentialite` | Contient `chantier-cgv` + politique de confidentialité (B72), pages publiques, plan OBD-BLE (`8b95d0c`) | 🔴 poussée | **SIRET**, mention TVA, médiateur (décision du 12/10) |
| `backup-avant-reorganisation` | Sauvegarde, entièrement contenue dans `main` (locale seulement) | ⚪ | Rien (conservée, décision de Pascal) |

## Travail non commité dans la copie de travail (dépôt principal)

La copie de travail du dépôt principal est sur `chantier-confidentialite`. `docs-projet/BACKLOG.md`
y porte B70, B80 à B84 (déjà à l'abri sur `docs-backlog-010b`) et la mise à jour de **B74**
(qui n'existe que sur `chantier-cgv` / `chantier-confidentialite` : elle partira avec ce chantier).

## Branches supprimées

| Date | Branche | Dépôt | Raison |
|---|---|---|---|
| 18/10/2026 | `chantier-tutoriels-video` | app | Entièrement contenue dans `main` (vérifié en local et sur GitHub) |
| 18/10/2026 | `chantier-tutoriels-video` | principal | Entièrement contenue dans `main` (vérifié en local et sur GitHub) |
| 18/10/2026 | `formation-publique` | principal | Entièrement contenue dans `main` (vérifié en local et sur GitHub) |
| 18/10/2026 | `correctif-formation-events` | app | Fusionnée dans `main` (`2c28bf5`, B85), puis vérifiée entièrement contenue (local et GitHub) |

## ⚠️ Règle Firestore

**Ne jamais publier les règles Firestore (`firebase deploy --only firestore:rules`) depuis `main` (dépôt app) tant que `tableau-de-bord-socle` n'est pas fusionnée** : le `firestore.rules` de `main` ne contient pas les règles du tableau de bord, une publication les effacerait (l'app ne serait pas touchée, mais le tableau de bord serait coupé). Toujours publier avec `--only firestore:rules` (jamais un `firebase deploy` complet).

## Ordre de fusion prévu

1. ~~`correctif-formation-events` → `main` (app)~~ — **fait le 18/10/2026** (`2c28bf5`).
2. `correctif-010b` → `main` (app), après le test voiture — **prochaine**.
2 bis. `tableau-de-bord-socle` → `main` (app), après A1-A4 et revue.
3. `docs-backlog-010b` → `main` (principal).
4. `chantier-cgv` puis `chantier-confidentialite` → `main`, après le SIRET.
5. Suppression de `essai-local-samsung` (avec l'accord de Pascal).
