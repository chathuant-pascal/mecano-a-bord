# FICHE MODULE 11 — MVC MAINTENANCE (CONTROLLER + ÉCRAN)

**Statut** : ✅ **Validé le 20/04/2026**  
**Date** : 20/04/2026  
**Référence projet** : `CLAUDE.md` MODULE 11 — **PRIORITÉ 3** — « Refactoring MVC Carnet entretien »

**Fichiers concernés** :
- `mecano_a_bord/lib/controllers/maintenance_controller.dart` (**créé**)
- `mecano_a_bord/lib/screens/add_maintenance_screen.dart` (**modifié**)
- `mecano_a_bord/test/controllers/maintenance_controller_test.dart` (**créé**)

**Résultat tests** : **`flutter test test/controllers/maintenance_controller_test.dart`** — **32 tests verts** ✅

---

## 1. NOM DE LA FONCTIONNALITÉ

Refactoring MVC de l'écran d'ajout/modification d'entretien pour extraire la logique métier dans un controller dédié et rendre l'écran plus centré sur la vue.

---

## 2. RÔLE EN LANGAGE SIMPLE

Avant, l'écran mélangeait beaucoup de logique (règles de rappel, chargement/sauvegarde, UI).  
Maintenant, les règles et les appels métier passent par `MaintenanceController`, et l'écran garde surtout l'affichage et les retours visuels utilisateur.

---

## 3. CE QUI A ÉTÉ REFACTORISÉ (5 ÉTAPES)

### Étape 1 — Création controller métier
- Création de `maintenance_controller.dart`
- Extraction des données de référence :
  - `categoryDisplay`
  - `maintenanceTypes`
  - `typeIcons`
- Ajout des helpers métier :
  - `computeNextDefaults(...)`
  - `canSave(...)`

### Étape 2 — Raccord des constantes dans la vue
- Remplacement dans `add_maintenance_screen.dart` des constantes locales par :
  - `MaintenanceController.categoryDisplay`
  - `MaintenanceController.maintenanceTypes`
  - `MaintenanceController.typeIcons`
- Suppression des constantes du `State`.

### Étape 3 — Extraction de la logique de calcul des rappels
- `_applyNextServiceDefaults()` délègue à `computeNextDefaults(...)`.
- Suppression de la méthode locale `_addYears()` de l'écran.
- Comportement visuel conservé à l'identique.

### Étape 4 — Délégation chargement / sauvegarde
- Ajout dans le controller :
  - `loadEntry(int id)`
  - `saveEntry(MaintenanceEntry entry, {required bool isEditMode})`
- Ajout de `MaintenanceControllerException`.
- `add_maintenance_screen.dart` délègue au controller pour charger/sauver.
- Suppression du repository direct dans le `State`.

### Étape 5 — Tests unitaires controller
- Création de `test/controllers/maintenance_controller_test.dart`
- 28 tests `computeNextDefaults` (1 par type d'entretien)
- + 1 test type inconnu
- + 3 tests `canSave`
- Total : **32/32 verts**

---

## 4. BILAN FICHIERS

| Fichier | Action | Rôle |
|---|---|---|
| `lib/controllers/maintenance_controller.dart` | **Créé** | Logique métier maintenance + délégation repository |
| `lib/screens/add_maintenance_screen.dart` | **Modifié** | Vue simplifiée, logique déléguée au controller |
| `test/controllers/maintenance_controller_test.dart` | **Créé** | Validation unitaire des règles du controller |

---

## 5. IMPACT TECHNIQUE

- Réduction du couplage entre UI et logique métier.
- Préparation à la suite du refactoring MVC (écrans liste/détail maintenance).
- Règles de calcul centralisées dans un seul composant testable.

---

## 6. JOURNAL

| Date | Étape |
|---|---|
| 20/04/2026 | Création `MaintenanceController` + extraction constantes et règles métier. |
| 20/04/2026 | Refactor `add_maintenance_screen.dart` (constantes puis calcul des défauts). |
| 20/04/2026 | Délégation `loadEntry` / `saveEntry` + suppression repository direct dans la vue. |
| 20/04/2026 | Ajout tests controller et validation `32/32` verts. |

---

## 7. CONDITIONS DE TEST

### 1. MATÉRIEL UTILISÉ

| Élément | Détail |
|---|---|
| PC | Windows 11 |
| Téléphone | Samsung SM-A137F Android 14 (non requis pour tests unitaires) |
| Outils | Flutter SDK + `flutter test` |

### 2. ENVIRONNEMENT DE TEST

- Tests unitaires Flutter en local.
- Aucun accès réseau requis.
- Aucun périphérique physique requis.

### 3. PROCÉDURE SUIVIE

```
flutter test test/controllers/maintenance_controller_test.dart
```

### 4. RÉSULTAT

| Élément | Détail |
|---|---|
| Total tests | **32** |
| Résultat | ✅ **32/32 verts — All tests passed!** |
| Portée | `computeNextDefaults` (28 types), type inconnu, `canSave` |

### 5. STATUT TEST

| Élément | Détail |
|---|---|
| Statut | ✅ **Validé le 20/04/2026** |
| Plateforme | PC Windows (tests automatisés) |

*Fin de la fiche MODULE 11 — MVC Maintenance.*
