# Vérification : images (accueil et onboarding)

Les images s'affichent :
- **Sur l'onboarding (5 pages)** : 1 = logo.png (Bienvenue), 2 = obd.png (Boîtier connecté), 3 = boite_a_gant.png (Boîte à gants), 4 = suv_images.png (Créer mon profil véhicule), 5 = systeme_io.png (Accès à la méthode sans stress auto). Bouton « Suivant » sur la page 5 → création du profil véhicule.
- **Sur l'écran d'accueil** : bandeau SUV + cartes OBD, Boîte à gants, Système IO.

## Checklist

1. **Où voir les images**
   - **Onboarding** (4 pages au premier lancement) : chaque page affiche son image en haut (SUV → OBD → Boîte à gants → Système IO).
   - **Écran d'accueil** : après l'onboarding, le bandeau SUV et les cartes avec les images sont visibles.

2. **Fichiers dans le bon dossier**
   - Tous les fichiers doivent être dans :  
     `mecano_a_bord/assets/images/`
   - Noms exacts : `suv_images.png`, `obd.png`, `boite_a_gant.png`, `systeme_io.png`

3. **Rebuild complet après ajout/modification d'images**
   - Dans un terminal, depuis le dossier `mecano_a_bord` :
     - `flutter clean`
     - `flutter pub get`
     - `flutter run`
   - Ou au minimum un `flutter run` (sans hot reload) pour régénérer l'APK avec les assets.

4. **Diagnostic dans le terminal**
   - Quand vous lancez `flutter run`, si une image ne se charge pas, un message apparaît dans le terminal du type :  
     `[MAB] Image non chargée: obd.png — ...`
   - Cela confirme que l'asset est introuvable dans l'app (mauvais chemin ou fichier absent du build).

## Projet BMAD vs app Flutter

- Le dossier **bmad_mecano_a_bord** contient la méthode BMAD (workflows, agents). Il ne sert pas au code de l'app.
- L'application installée sur le téléphone est construite **uniquement** à partir du projet **mecano_a_bord** (Flutter).

---

*Dernière mise à jour : 2026-03-09 (onboarding 5 pages, libellés et bouton).*
