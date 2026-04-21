# FICHE MODULE 12 — MVC PROFIL VÉHICULE (CONTROLLER + ÉCRAN)

**Statut** : ✅ **Validé le 21/04/2026**  
**Date** : 21/04/2026  
**Référence projet** : `CLAUDE.md` MODULE 12 — **PRIORITÉ 3** — « Refactoring MVC Profil véhicule »

**Fichiers concernés** :
- `mecano_a_bord/lib/controllers/vehicle_profile_controller.dart` (**créé**)
- `mecano_a_bord/lib/screens/glovebox_profile_screen.dart` (**modifié**)
- `mecano_a_bord/test/controllers/vehicle_profile_controller_test.dart` (**créé**)

**Résultat tests** : **`flutter test test/controllers/vehicle_profile_controller_test.dart`** — **25 tests verts** ✅

---

## 1. NOM DE LA FONCTIONNALITÉ

Refactoring MVC de l'écran profil véhicule pour déplacer la logique métier dans un controller dédié et garder l'écran concentré sur l'affichage et les interactions utilisateur.

---

## 2. RÔLE EN LANGAGE SIMPLE

Avant, l'écran mélangeait l'interface, les appels API plaque, la persistance locale et la sauvegarde SQLite.  
Maintenant, `VehicleProfileController` centralise ces règles, et l'écran se limite à déclencher des actions, afficher l'état et les messages visuels.

---

## 3. CE QUI A ÉTÉ REFACTORISÉ (4 ÉTAPES)

### Étape 1 — Création controller métier
- Création de `vehicle_profile_controller.dart`.
- Extraction des méthodes métier :
  - `mapApiFuelToAppFuel`
  - `isVinValid`
  - `normalizePlate`
  - `canSave`
  - `lookupVehicle` (API plaque)
  - `saveIdentityPrefs`
  - `loadIdentityFromPrefs`
  - `loadExistingProfile`
  - `saveProfile`
- Ajout des `try/catch` + `mabLog` sur les opérations SharedPreferences et SQLite.
- Ajout du garde-fou feature flag `kFeaturePlaque`.
- Ajout de `mabLog` dans le catch silencieux de `lookupVehicle`.

### Étape 2 — Allègement de la vue
- `glovebox_profile_screen.dart` délègue maintenant la logique au controller.
- Suppression des accès directs au repository et à l'HTTP dans le `State`.
- Remplacement des 3 usages `withOpacity()` demandés par `.withValues(alpha: ...)`.

### Étape 3 — Tests unitaires controller
- Création de `test/controllers/vehicle_profile_controller_test.dart`.
- Couverture nominale / erreur / limite pour les méthodes du controller.
- Total exécuté : **25/25 verts**.

### Étape 4 — Validation technique
- Exécution de `flutter test test/controllers/vehicle_profile_controller_test.dart`.
- Exécution de `flutter analyze lib/`.
- Aucun warning/erreur bloquant restant sur le périmètre du module (hors infos ignorées : `prefer_const*` et `deprecated_member_use`).

---

## 4. BILAN FICHIERS

| Fichier | Action | Rôle |
|---|---|---|
| `lib/controllers/vehicle_profile_controller.dart` | **Créé** | Logique métier profil véhicule + API plaque + persistance |
| `lib/screens/glovebox_profile_screen.dart` | **Modifié** | Vue simplifiée, délégation au controller |
| `test/controllers/vehicle_profile_controller_test.dart` | **Créé** | Validation unitaire des règles du controller |

---

## 5. IMPACT TECHNIQUE

- Réduction forte du couplage UI / métier sur le profil véhicule.
- Logique testable hors écran (controller isolé).
- Préparation des prochains modules MVC avec une structure homogène (controller + tests).

---

## 6. JOURNAL

| Date | Étape |
|---|---|
| 21/04/2026 | Création `VehicleProfileController` + extraction des méthodes métier du screen. |
| 21/04/2026 | Refactor `glovebox_profile_screen.dart` : délégation complète au controller. |
| 21/04/2026 | Remplacement `withOpacity()` -> `.withValues(alpha: ...)` sur les 3 occurrences ciblées. |
| 21/04/2026 | Création des tests unitaires controller et validation `25/25` verts. |
| 21/04/2026 | Commit final module : `MODULE 12 : refactoring MVC Profil véhicule + 24 tests verts`. |

---

## 7. CONDITIONS DE TEST

### 1. MATÉRIEL UTILISÉ

| Élément | Détail |
|---|---|
| PC | Windows 11 |
| Téléphone | Samsung SM-A137F Android 14 (non requis pour tests unitaires) |
| Outils | Flutter SDK + `flutter test` + `flutter analyze` |

### 2. ENVIRONNEMENT DE TEST

- Tests unitaires Flutter en local.
- Mocks HTTP (`MockClient`) pour isoler les cas API plaque.
- `SharedPreferences.setMockInitialValues(...)` pour isoler la persistance locale.
- Aucune dépendance réseau réelle requise.

### 3. PROCÉDURE SUIVIE

```bash
flutter test test/controllers/vehicle_profile_controller_test.dart
flutter analyze lib/
```

### 4. RÉSULTAT

| Élément | Détail |
|---|---|
| Total tests | **25** |
| Résultat tests | ✅ **25/25 verts — All tests passed!** |
| Analyze | ✅ Aucun warning/erreur bloquant (hors infos explicitement ignorées) |
| Portée | Mapping carburant, validation VIN, normalisation plaque, règles `canSave`, API plaque, prefs, chargement/sauvegarde profil |

### 5. STATUT TEST

| Élément | Détail |
|---|---|
| Statut | ✅ **Validé le 21/04/2026** |
| Plateforme | PC Windows (tests automatisés) |

*Fin de la fiche MODULE 12 — MVC Profil véhicule.*
