# FICHE MODULE 10 — TESTS UNITAIRES MABREPOSITORY

**Statut** : ✅ **Validé le 20/04/2026**  
**Date** : 20/04/2026  
**Référence projet** : `CLAUDE.md` MODULE 10 — **PRIORITÉ 3** — « Tests unitaires Repository »

**Fichier cible** : `mecano_a_bord/lib/data/mab_repository.dart`  
**Fichier de tests** : `mecano_a_bord/test/mab_repository_test.dart`

**Résultat** : **`flutter test test/mab_repository_test.dart`** — **47 tests verts** ✅

---

## 1. NOM DE LA FONCTIONNALITÉ

Tests unitaires complets du `MabRepository` pour valider les comportements des profils véhicule, carnet d'entretien, OBD, documents, références constructeur et contexte IA.

---

## 2. RÔLE EN LANGAGE SIMPLE

Ces tests rejouent automatiquement les cas importants du repository (lecture/écriture données, règles métier, mode démo) pour vérifier que l'application continue de se comporter correctement à chaque évolution.

---

## 3. RÉFÉRENCE CLAUDE.md — MODULE 10

Dans `CLAUDE.md`, section **PRIORITÉ 3 — AMÉLIORATIONS** :

- **MODULE 10** → Tests unitaires Repository

Méthodologie projet appliquée : **cas nominal**, **cas d'erreur**, **cas limite**.

---

## 4. FICHIER DE TEST — ÉTAT

| Élément | Résultat |
|--------|----------|
| `mecano_a_bord/test/mab_repository_test.dart` | **Présent** — **47** tests (8 groupes) |
| Autres tests sous `mecano_a_bord/test/` | `ai_conversation_service_test.dart`, `widget_test.dart` |

---

## 5. IMPLÉMENTATION TECHNIQUE (VALIDÉE)

### 5.1 SQLite en test avec `sqflite_common_ffi`

- Initialisation en `setUpAll()` : `sqfliteFfiInit()` puis `databaseFactory = databaseFactoryFfi`.
- Exécution des tests repository sur une base SQLite locale de test, sans modifier le code de production.

### 5.2 Isolation entre les tests

- `SharedPreferences.setMockInitialValues({})` à chaque `setUp()`.
- Nettoyage base via `db.MabDatabase.instance.closeAndDeleteDatabaseFile()`.

### 5.3 Portée testée

- Méthodes statiques/pures (`getMimeTypeFromPath`, `vehicleFingerprint`)
- Mode démo / SharedPreferences
- Profils véhicule (avec règle max 2 profils)
- Carnet d'entretien
- OBD (prefs + historique SQLite)
- Documents boîte à gants
- Références constructeur + santé véhicule
- Contexte IA `getAiSystemContextString()` (5 scénarios)

---

## 6. GROUPES DE TESTS (47 TESTS)

| # | Groupe | Contenu |
|---|--------|---------|
| 1 | **Méthodes statiques / pures** | MIME types + normalisation fingerprint |
| 2 | **Mode démo / SharedPreferences** | Démo on/off, scénario OBD, retours démo |
| 3 | **Profils véhicule** | CRUD profil + limite 2 profils |
| 4 | **Carnet d'entretien** | CRUD entretien + `getLast3MaintenanceEntries` |
| 5 | **OBD** | Dernier diag prefs, adresse dongle, historique, alertes entretien |
| 6 | **Documents boîte à gants** | Lecture / ajout / validation mimeType |
| 7 | **Références + santé** | JSON références, partage communauté, alertes santé, learned values |
| 8 | **Contexte IA** | Profil incomplet, sans OBD, OBD vide, démo green, démo red |

---

## 7. JOURNAL

| Date | Étape |
|------|--------|
| 20/04/2026 | Ajout dépendance dev `sqflite_common_ffi` pour tests SQLite repository. |
| 20/04/2026 | Création de `mab_repository_test.dart` avec 42 tests (groupes 1 à 7). |
| 20/04/2026 | Passe 2 : ajout de 5 tests `getAiSystemContextString()` (groupe 8). |
| 20/04/2026 | Validation finale : **47/47 verts**. |

---

## 8. PROCHAINE ÉTAPE PROJET

- Poursuivre les modules suivants de la roadmap `CLAUDE.md` selon priorité validée.

---

## 9. CONDITIONS DE TEST

### 1. MATÉRIEL UTILISÉ

| Élément | Détail |
|---|---|
| PC | Windows 11 |
| Téléphone | Samsung SM-A137F Android 14 (non requis pour ces tests automatisés) |
| Outils | Flutter SDK + `flutter test` |

### 2. ENVIRONNEMENT DE TEST

- Tests unitaires Flutter exécutés en local sur PC.
- SQLite de test via `sqflite_common_ffi`.
- SharedPreferences mocké via `setMockInitialValues({})`.
- Aucun service externe requis (pas d'API réseau).

### 3. PROCÉDURE SUIVIE

```
flutter test test/mab_repository_test.dart
```

### 4. RÉSULTAT

| Élément | Détail |
|---|---|
| Total tests | **47** |
| Résultat | ✅ **47/47 verts — All tests passed!** |
| Durée observée | ~5 à 6 secondes |

### 5. STATUT TEST

| Élément | Détail |
|---|---|
| Statut | ✅ **Validé le 20/04/2026** |
| Plateforme | PC Windows (tests automatisés) |

*Fin de la fiche MODULE 10 — Tests unitaires MabRepository.*
