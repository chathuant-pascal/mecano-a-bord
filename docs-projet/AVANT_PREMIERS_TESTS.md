# À faire avant les premiers tests — Mécano à Bord

Document de suivi après intégration des fichiers de `docs-projet` dans l’application Flutter `mecano_a_bord`.

**Phase test actuelle : Android uniquement** (pas de Mac → pas de build iOS pour l'instant.)

---

## Ce qui a été intégré

- **Thème** : `lib/theme/mab_theme.dart` (charte MAB, EAA 2025).
- **Data** : `lib/data/mab_database.dart` (SQLite, tables véhicule, diagnostics, entretien, documents, alertes) et `lib/data/mab_repository.dart` (singleton, mapping domaine ↔ DB, `getVehicleProfile`, `getVehicleContextSummary`, `saveVehicleProfile`, stubs rappels / documents).
- **Services** : `lib/services/bluetooth_obd_service.dart` (stub : états OBD + service sans Bluetooth, pour compiler sans `flutter_blue_plus`).
- **Écrans** :
  - `main.dart` : splash → onboarding ou accueil, routes `/glovebox-profile`, `/obd-scan`, `/glovebox`, `/ai-chat`, `/settings`.
  - `onboarding_screen.dart` (existant), `home_screen.dart` (accueil avec carte OBD, rappels, boîte à gants, 4 boutons, bottom nav), `glovebox_profile_screen.dart` (formulaire complet profil véhicule), `placeholder_screen.dart` (OBD / Boîte à gants / IA / Réglages).
- **Dépendances** (dans `mecano_a_bord/pubspec.yaml`) : `shared_preferences`, `sqflite`, `path`, `intl`.

---

## À faire avant les premiers tests

### 1. Structure Flutter (Android uniquement pour les tests)

- [ ] Vérifier que le projet est bien un projet Flutter : le dossier `mecano_a_bord` doit contenir au minimum :
  - `pubspec.yaml` (présent),
  - `lib/` (présent),
  - **`android/`** (obligatoire pour tester sur Android). Le dossier `ios/` n’est pas nécessaire tant que vous n’avez pas de Mac.
- [ ] Si le dossier **`android/`** est absent : ouvrir un terminal, aller dans `mecano_a_bord`, puis lancer :
  - `flutter create .`
  - (Répondre **n** si on vous demande d’écraser `lib/` ou `pubspec.yaml`.)

### 2. Dépendances et lancement sur Android

- [ ] Dans le dossier `mecano_a_bord`, exécuter :  
  `flutter pub get`
- [ ] Vérifier la compilation :  
  `flutter analyze`
- [ ] Lancer l’app sur Android :
  - **Téléphone ou émulateur Android connecté** : `flutter run` (Flutter choisit l’appareil Android automatiquement).
  - **Créer un APK à installer** : `flutter build apk`  
    L’APK se trouve ensuite dans `build/app/outputs/flutter-apk/app-release.apk`.

### 3. Parcours de test minimal (sans Bluetooth / sans Firebase)

- [ ] Lancer l’app → écran splash puis onboarding (si première fois) ou accueil.
- [ ] Fin de l’onboarding → redirection vers « Mon véhicule » (`/glovebox-profile`).
- [ ] Remplir le formulaire profil (marque, modèle, année, immat, carburant, kilométrage, boîte) et enregistrer → retour à l’accueil.
- [ ] Depuis l’accueil : boutons Diagnostic / Mode conduite / Mode démo / IA → navigation vers les écrans placeholder ou dialogue « profil incomplet » si pertinent.
- [ ] Barre du bas : Accueil / OBD / Boîte à gants / IA / Réglages → chaque onglet ouvre l’écran attendu (placeholders pour OBD, Boîte à gants, IA, Réglages).

### 4. Optionnel pour tests plus poussés (plus tard)

- [ ] **Bluetooth OBD** : ajouter `flutter_blue_plus` dans `pubspec.yaml`, implémenter le vrai `BluetoothObdService` (voir `docs-projet/bluetooth_obd_service.dart`) et remplacer le stub dans `lib/services/`.
- [ ] **Firebase / licence** : si vous réintégrez la gestion de licence et le login, ajouter `firebase_core`, `firebase_auth`, `cloud_firestore`, configurer les options Firebase et brancher `main.dart` sur le flux décrit dans `docs-projet/main.dart`.
- [ ] **Écrans complets** : remplacer les placeholders par les écrans de `docs-projet` (OBD scan, Boîte à gants, IA chat, Réglages) en adaptant les imports et services (repository, AI, etc.).
- [ ] **Permissions** : pour Bluetooth et stockage (photos factures, documents), déclarer et demander les permissions dans `AndroidManifest.xml` (Android). (iOS plus tard si besoin.)

---

## Résumé

| Élément                         | Statut        |
|---------------------------------|---------------|
| Thème MAB                       | Intégré       |
| Base de données + repository   | Intégré       |
| Stub OBD                        | Intégré       |
| Accueil + Profil véhicule      | Intégré       |
| Placeholders OBD / Glovebox / IA / Réglages | Intégré |
| `flutter create` si besoin (pour avoir `android/`) | À faire       |
| `flutter pub get` + run/analyze                    | À faire       |
| Tests manuels du parcours (sur Android)           | À faire       |
| Bluetooth / Firebase / écrans complets            | Optionnel plus tard |
| Tests iOS                                         | Plus tard (avec Mac) |

Une fois les points 1 et 2 faits et le parcours 3 validé sur Android, les premiers tests sont en place. iOS pourra être ajouté plus tard lorsque vous aurez accès à un Mac.
