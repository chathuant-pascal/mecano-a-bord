# Procédure : ajouter une image d'accès direct dans le menu principal

Pour afficher une **image** comme accès direct sur l'écran d'accueil (ex. « Système IO »), procéder comme suit.

## 1. Où déposer l'image

- **Pour l'application Flutter** : déposer le fichier dans  
  `mecano_a_bord/assets/images/`  
  (ex. `systeme_io.png`).  
  Le `pubspec.yaml` déclare déjà le dossier `assets/images/`, aucune modification n'est nécessaire.

- **Pour la documentation / référence** (optionnel) : vous pouvez en garder une copie dans  
  `docs-projet/images/`  
  pour traçabilité ou maquette (voir [README.md](README.md), section « Autres fichiers »).

## 2. Noms des fichiers (écran d'accueil)

| Fichier | Usage |
|---------|--------|
| `systeme_io.png` | Carte « Système IO » |
| `OBD.png` | Carte « Boîtier connecté » (accès OBD / diagnostic) |
| `boite a gant.png` | Carte « Boîte à gants » |
| `suv images.png` | Bandeau visuel véhicule (partie haute) |

Tous dans `mecano_a_bord/assets/images/`. Si un fichier est absent, l'app affiche une icône de remplacement sans planter.

## 3. Ce qui est déjà en place

- **Système IO** : carte avec `systeme_io.png` → route `/systeme-io`.
- **Boîtier connecté (OBD)** : carte avec `OBD.png` et statut de connexion → route `/obd-scan`.
- **Boîte à gants** : carte avec `boite a gant.png` → route `/glovebox`.
- **Véhicule** : bandeau avec `suv images.png` sous l'en-tête (nom du véhicule).

## 4. Récapitulatif

| Image | Emplacement app | Référence (optionnel) |
|-------|-----------------|------------------------|
| systeme_io.png | `mecano_a_bord/assets/images/` | `docs-projet/images/` |
| OBD.png | idem | idem |
| boite a gant.png | idem | idem |
| suv images.png | idem | idem |

Après avoir déposé les fichiers dans `mecano_a_bord/assets/images/`, faire un hot restart pour voir les images.
