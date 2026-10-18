# Carte des branches — Mécano à Bord

**À jour au 18/10/2026.** À mettre à jour à chaque création, fusion ou suppression
de branche. Deux dépôts Git distincts (voir CLAUDE.md, « État Git ») :

- **Dépôt principal** `chathuant-pascal/mecano-a-bord` (docs + formation web) — dossier racine `Mecano A Bord/`
- **Dépôt app** `chathuant-pascal/mecano-a-bord-app` (application Flutter) — dossier `Mecano A Bord/mecano_a_bord/`

Légende : 🟢 prête / à jour · 🟡 travail en cours · 🔴 bloquée · ⚪ terminée (gardée pour mémoire) · 🔒 locale, jamais poussée

---

## Dépôt app (`mecano-a-bord-app`)

| Branche | Contenu | État | Attend |
|---|---|---|---|
| `main` | Version de référence de l'app (`5d1aec3`) | 🟢 | — |
| `correctif-010b` | Correctif 010B : 010B = pression d'admission, plus jamais lue comme pression d'huile ; plage 0-255 kPa ; règle « électrique ? » ; message huile une fois par véhicule (`88f24c7`, 375 tests) | 🟡 poussée | **Test en vraie voiture** (Samsung + Vgate), puis documentation, revue de commit, fusion dans `main` |
| `correctif-formation-events` | B85 (lot B4) : formation dans l'app depuis l'accueil sur Android, navigateur sur iPhone (`d8bd08f`, 360 tests) | 🟡 poussée, validée sur le Samsung | **Revue de commit**, puis fusion dans `main` |
| `chantier-confidentialite` | Écran Politique de confidentialité généré depuis le texte maître (B72) + retrait du VIN de l'assistant IA (`94e1a51`) | 🔴 poussée | **SIRET**, mention TVA, médiateur (décision du 12/10), puis vérification Samsung (B79) |
| `essai-local-samsung` | Combinaison **010B + B4**, uniquement pour compiler l'APK installé sur le Samsung (`e943104`, 385 tests) | 🔒 locale | **Rien** : jamais poussée (hook `pre-push` local), jamais fusionnée. Sert aussi au test voiture du 010B. À supprimer quand les deux chantiers seront dans `main` |
| `chantier-tutoriels-video` | Tutoriels vidéo (déjà fusionnée dans `main`) | ⚪ | Rien (conservée sur GitHub, décision de Pascal) |

## Dépôt principal (`mecano-a-bord`)

| Branche | Contenu | État | Attend |
|---|---|---|---|
| `main` | Docs et formation web publiées (GitHub Pages) (`bd97924`) | 🟢 | — |
| `docs-backlog-010b` | Backlog B70, B80 à B85 ; journal EVOLUTION du 18/10 (B85) ; règle de nommage de la formation (CLAUDE.md) ; cette carte des branches | 🟡 poussée | **Revue**, puis fusion dans `main` (aucun blocage SIRET) |
| `chantier-pilotage` | Plan du centre de pilotage (7 onglets, ordre des chantiers) | 🟡 poussée | Début du socle A0-A4 (après le 010B) |
| `chantier-cgv` | CGV définitives, backlog B71-B76, CLAUDE.md V5.1 (`c30d3c2`) | 🔴 poussée | **SIRET**, mention TVA, médiateur, relecture juridique ; correction du seuil de garantie (Module 1, B84) |
| `chantier-confidentialite` | Contient `chantier-cgv` + politique de confidentialité (B72), pages publiques, plan OBD-BLE (`8b95d0c`) | 🔴 poussée | **SIRET**, mention TVA, médiateur (décision du 12/10) |
| `chantier-tutoriels-video` | Déjà fusionnée dans `main` | ⚪ | Rien (conservée) |
| `formation-publique` | Ancienne branche, entièrement contenue dans `main` (`2c007a5`) | ⚪ | Rien — suppression possible avec l'accord de Pascal |
| `backup-avant-reorganisation` | Sauvegarde, entièrement contenue dans `main` (locale seulement) | ⚪ | Rien (conservée, décision de Pascal) |

## Travail non commité dans la copie de travail (dépôt principal)

La copie de travail du dépôt principal est sur `chantier-confidentialite`. `docs-projet/BACKLOG.md`
y porte B70, B80 à B84 (déjà à l'abri sur `docs-backlog-010b`) et la mise à jour de **B74**
(qui n'existe que sur `chantier-cgv` / `chantier-confidentialite` : elle partira avec ce chantier).

## Ordre de fusion prévu

1. `correctif-formation-events` → `main` (app), après revue.
2. `correctif-010b` → `main` (app), après le test voiture.
3. `docs-backlog-010b` → `main` (principal).
4. `chantier-cgv` puis `chantier-confidentialite` → `main`, après le SIRET.
5. Suppression de `essai-local-samsung` (avec l'accord de Pascal).
