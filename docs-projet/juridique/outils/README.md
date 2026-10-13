# Outils — textes juridiques (politique de confidentialité et CGV)

Chaque texte juridique ne s'écrit **qu'à un seul endroit**, son « texte maître » :

| Texte maître | Affichages générés (ne JAMAIS les modifier à la main) |
|---|---|
| `docs-projet/juridique/POLITIQUE_CONFIDENTIALITE.md` | écran de l'app `mecano_a_bord/lib/screens/privacy_policy_screen.dart` ; page publique `confidentialite.html` (racine du dépôt) |
| `docs-projet/juridique/CGV_MECANO_A_BORD.md` | page publique `cgv.html` (racine du dépôt) ; texte à coller dans Systeme.io `docs-projet/juridique/CGV_SYSTEMEIO.txt` |

Adresses publiques : `https://chathuant-pascal.github.io/mecano-a-bord/confidentialite.html` et `.../cgv.html`
(puis `https://mecanoabord.fr/confidentialite.html` et `/cgv.html` quand le nom de domaine sera branché).

## Après chaque modification d'un texte maître

Depuis la racine `Mecano A Bord/` :

1. Mettre à jour la date (« Dernière mise à jour » / « Version en vigueur ») dans le texte maître.
2. Régénérer ce qui en dépend :
   - politique de confidentialité :
     `python docs-projet/juridique/outils/generer_ecran_confidentialite.py`
     `python docs-projet/juridique/outils/generer_pages_publiques.py`
   - CGV :
     `python docs-projet/juridique/outils/generer_pages_publiques.py`
     `python docs-projet/juridique/outils/generer_cgv_systemeio.py`
3. Vérifier mot pour mot (chaque ligne doit finir par « OK ») :
   `python docs-projet/juridique/outils/verifier_textes_juridiques.py`
4. Si l'écran de l'app a changé : dans `mecano_a_bord/`, `flutter analyze` puis `flutter test`
   (`test/privacy_policy_screen_test.dart` contrôle les points juridiques sensibles).
5. Commits : dépôt principal (texte maître + pages + texte Systeme.io) et, si besoin, dépôt de l'app (écran).
6. CGV : recoller `CGV_SYSTEMEIO.txt` dans Systeme.io. Politique : l'écran de l'app ne change
   pour les utilisateurs qu'avec une nouvelle version de l'app.

## Fichiers de ce dossier

- `juridique_commun.py` : lecture des textes maîtres, commune aux autres scripts (ne se lance pas seul).
- `generer_ecran_confidentialite.py`, `generer_pages_publiques.py`, `generer_cgv_systemeio.py` : génération.
- `verifier_textes_juridiques.py` : vérification des 4 affichages.
