# Documentation projet — Mécano à Bord

**Règle prioritaire** : cette documentation doit rester à jour au fur et à mesure de l’avancement du projet. Toute personne (développeur, producteur, partenaire) doit pouvoir retrouver des informations **datées** sur l’évolution du projet pour affiner la réflexion et améliorer l’architecture.

---

## Où trouver quoi

| Document | Rôle | Quand le mettre à jour |
|----------|------|------------------------|
| **[PRD.md](PRD.md)** | Cahier des charges produit (périmètre V1, objectifs, exclusions) | Quand le périmètre ou les objectifs changent |
| **[BACKLOG.md](BACKLOG.md)** | Liste priorisée des fonctionnalités / tâches avec statut et dates | À chaque avancement : nouvelle tâche, changement de statut, livraison |
| **[NOTES_INTENTION_TECHNIQUES.md](NOTES_INTENTION_TECHNIQUES.md)** | Décisions d’architecture, choix techniques, contraintes | Quand une décision technique importante est prise |
| **[EVOLUTION.md](EVOLUTION.md)** | **Journal daté** de l’évolution du projet (résumé des changements par date) | **À chaque étape importante** : livraison, correction majeure, refonte, mise en place d’un module |
| **[CONTEXTE_CLAUDE_MECANO_A_BORD_V6.md](CONTEXTE_CLAUDE_MECANO_A_BORD_V6.md)** | Contexte détaillé pour les assistants IA (Pascal, sessions, fichiers de référence) | En début de grosse session ou quand le contexte change |

---

## Règles de mise à jour

1. **Après chaque étape importante** : ajouter une entrée datée dans **EVOLUTION.md** (quoi, quand, impact éventuel).
2. **Quand une tâche avance** : mettre à jour **BACKLOG.md** (statut, date de fin si pertinent).
3. **Quand une décision technique est prise** : documenter dans **NOTES_INTENTION_TECHNIQUES.md** (et éventuellement une ligne dans EVOLUTION.md).
4. **Changement de périmètre ou d’objectif** : mettre à jour **PRD.md** (et EVOLUTION.md).

---

## Autres fichiers dans `docs-projet`

- **Fichiers .dart** : copies de référence / spécifications d’écrans (à comparer avec `mecano_a_bord/lib/`).
- **VERIFICATION_*.md**, **AVANT_PREMIERS_TESTS.md** : vérifications et checklists avant tests.
- **FLUTTER_ET_EMULATEUR_CURSOR.md**, **EMULATEUR_ANDROID_*.md** : notes d'environnement et outillage.
- **images/** (optionnel) : visuels de référence (ex. maquette « Système IO »). L'image utilisée dans l'app doit aussi être déposée dans `mecano_a_bord/assets/images/` (voir `mecano_a_bord/assets/images/README.txt`).
- **[PROCEDURE_IMAGE_MENU.md](PROCEDURE_IMAGE_MENU.md)** : procédure pour ajouter une image d'accès direct dans le menu principal (ex. Système IO). notes d’environnement et outillage.

Pour l’**historique daté** et l’**état du projet**, utiliser en priorité **EVOLUTION.md** et **BACKLOG.md**.

---

*Dernière mise à jour de cet index : **2026-04-14** — entrée **EVOLUTION** + **VERIFICATION** (43 fichiers Dart, WebView formation) ; **BACKLOG** B10 ; **NOTES** navigation formation*
