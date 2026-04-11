# Vérification du bon fonctionnement — Mécano à Bord

Date de vérification : février 2025  
Contexte : avant tests sur émulateur (AVD en cours de création dans Android Studio).

---

## 1. Analyse statique et linter

- **Linter (Cursor/IDE)** : aucune erreur signalée dans `mecano_a_bord/lib`.
- **Flutter analyze** : non exécuté depuis cet environnement (Flutter n’est pas dans le PATH du terminal utilisé). À faire de ton côté une fois Flutter installé et PATH configuré :
  ```bash
  cd mecano_a_bord
  flutter pub get
  flutter analyze
  ```

---

## 2. Cohérence du code (revue manuelle)

| Fichier / zone | Statut | Remarque |
|----------------|--------|----------|
| **main.dart** | OK | Splash → onboarding ou Home, routes cohérentes. `/settings` pointe vers PlaceholderScreen (normal tant que l’écran Réglages complet n’est pas intégré). |
| **ai_chat_screen.dart** | OK | Utilise `getRemainingFreeQuota()` et `VehicleContext` du service ; gestion `mounted` correcte ; messages d’erreur et quota cohérents. |
| **ai_conversation_service.dart** | OK | `VehicleContext`, `getRemainingFreeQuota()`, modes gratuit/personnel, ChatGPT/Gemini. Pas d’incohérence détectée. |
| **mab_repository.dart** | OK | `getVehicleContextSummary()` (String), `getActiveVehicleProfile()`, stubs rappels/documents. |
| **home_screen.dart** | OK | Navigation, profil incomplet, OBD/Glovebox/IA/Réglages. |
| **glovebox_profile_screen.dart** | OK | Formulaire profil, sauvegarde via repository. |
| **mab_theme.dart** | OK | Couleurs et styles MAB définis. |

Aucun bug évident ni incohérence de types ou d’appels de méthode repérée dans les fichiers parcourus.

---

## 3. Point d’attention : plateforme Android

- Le dossier **`mecano_a_bord/android/`** est **absent** (aucun fichier trouvé).
- Sans ce dossier, `flutter run` ou `flutter build apk` échouera.

**À faire une fois Flutter dans le PATH :**

1. Ouvrir un terminal dans le projet.
2. Se placer dans le dossier Flutter :
   ```bash
   cd "C:\Users\karuc\OneDrive\Bureau\Mecano A Bord\mecano_a_bord"
   ```
3. Générer les dossiers de plateforme :
   ```bash
   flutter create .
   ```
   Quand il demande d’écraser des fichiers, répondre **n** pour préserver `lib/` et `pubspec.yaml`.

Après cela, le dossier `android/` (et éventuellement `ios/`) sera créé et tu pourras lancer l’app sur l’émulateur.

---

## 4. Résumé

| Élément | État |
|--------|------|
| Erreurs de linter | Aucune |
| Incohérences de code repérées | Aucune |
| Flutter analyze | À lancer par toi (Flutter dans PATH) |
| Dossier `android/` | À créer avec `flutter create .` |
| Émulateur (AVD) | En cours de création de ton côté |

Dès que l’AVD est créé, que Flutter est dans le PATH et que `flutter create .` a été exécuté, tu peux lancer l’émulateur puis `flutter run` dans `mecano_a_bord` pour tester le bon fonctionnement de l’application.
