# FICHE MODULE 15 — MISE À JOUR PACKAGES

**Statut** : 🔄 **En cours — Groupes 1, 2a, 2b, 2c-1, permission_handler, file_picker validés — Groupe 3 à planifier en session dédiée**
**Date début** : 21/04/2026
**Référence projet** : `CLAUDE.md` MODULE 15 — **PRIORITÉ 3** — « Mise à jour packages »

**Commits du module** :
- `dbb4139` — MODULE 15 (groupe 1) : shared_preferences + flutter_reactive_ble
- `524680e` — MODULE 15 (groupe 2a) : intl 0.19.0 → 0.20.2
- `47e0c8b` — MODULE 15 (groupe 2b) : flutter_lints 3.0.2 → 6.0.0
- `c143842` — MODULE 15 (groupe 2c-1) : package_info_plus 8.3.1 → 9.0.1
- `ebac174` — MODULE 15 : permission_handler 11.4.0 → 12.0.1
- `029ff1c` — MODULE 15 : file_picker 8.3.7 → 11.0.2 + adaptation API

---

## 1. OBJECTIF

Maintenir les dépendances à jour pour :
- corriger des failles de sécurité connues,
- assurer la compatibilité Android 14 (Samsung SM-A137F),
- réduire les dépréciations signalées par `flutter analyze`.

Les mises à jour sont regroupées par niveau de risque et appliquées
module par module avec validation `flutter test` à chaque étape.

---

## 2. PACKAGES MIS À JOUR — GROUPES 1 ET 2

### Groupe 1 — Faible risque ✅ (commit dbb4139)

| Package | Avant | Après | Type |
|---|---|---|---|
| `shared_preferences` | 2.5.4 | **2.5.5** | Patch |
| `flutter_reactive_ble` | 5.4.0 | **5.4.2** | Patch (Android 14) |
| `reactive_ble_mobile` *(transitif)* | 5.4.0 | **5.4.2** | Transitif |
| `reactive_ble_platform_interface` *(transitif)* | 5.4.0 | **5.4.2** | Transitif |
| `protobuf` *(transitif BLE)* | 2.1.0 | **6.0.0** | Transitif |

### Groupe 2a — Risque moyen ✅ (commit 524680e)

| Package | Avant | Après | Breaking ? |
|---|---|---|---|
| `intl` | 0.19.0 | **0.20.2** | Partiel (0.x) |

### Groupe 2b — Risque moyen ✅ (commit 47e0c8b)

| Package | Avant | Après | Breaking ? |
|---|---|---|---|
| `flutter_lints` | 3.0.2 | **6.0.0** | Oui (nouvelles règles lint) |
| `lints` *(transitif)* | 3.0.0 | **6.1.0** | Transitif |

**Résultat réel** : aucune nouvelle règle déclenchée sur le code existant.

### Groupe 2c-1 — Risque moyen ✅ (commit c143842)

| Package | Avant | Après | Breaking ? |
|---|---|---|---|
| `package_info_plus` | 8.3.1 | **9.0.1** | Non — `PackageInfo.fromPlatform()` inchangée |

### Groupe 2c-2 — 🔒 Bloqué (lié au groupe 3)

La montée `package_info_plus` 9.0.1 → **10.0.0** est bloquée par un conflit `win32` :

| Package | Exige |
|---|---|
| `package_info_plus ^10.0.0` | `win32 ^6.0.0` |
| `flutter_secure_storage ^9.0.0` *(version actuelle)* | `win32 ^5.0.0` |

**Résolution** : les deux doivent être montés ensemble.  
`package_info_plus ^10.0.0` sera appliqué **en même temps** que `flutter_secure_storage ^10.0.0` lors de la session groupe 3.

### Groupe 2d — Risque moyen ✅ (commit ebac174)

| Package | Avant | Après | Breaking ? |
|---|---|---|---|
| `permission_handler` | 11.4.0 | **12.0.1** | Oui — compileSdk 35, permissions Android 14 |

Aucune adaptation de code requise — l'API `Permission.xxx.request()` est inchangée.

### Groupe 2e — Risque élevé ✅ (commit 029ff1c)

| Package | Avant | Après | Breaking ? |
|---|---|---|---|
| `file_picker` | 8.3.7 | **11.0.2** | Oui — `FilePicker.platform` supprimé |

**Adaptation requise** — `glovebox_screen.dart:398` :

```dart
// Avant (8.x) — cassé en 11.x
result = await FilePicker.platform.pickFiles(...)

// Après (11.x) — méthode statique directe
result = await FilePicker.pickFiles(...)
```

`FilePicker` est devenu une classe abstraite avec méthodes statiques. Plus d'instance,
plus de `.platform`. Un seul appel à changer.

---

## 3. PACKAGES RESTANTS — GROUPE 3 (SESSION DÉDIÉE)

> ⚠️ **Les 2 packages ci-dessous doivent être traités dans une seule session dédiée**
> avec le Samsung SM-A137F connecté et disponible pour les tests sur appareil.
> Ne pas les appliquer séparément — les dépendances `win32` les lient.

| Package | Actuel | Cible | Raison du risque |
|---|---|---|---|
| `package_info_plus` | 9.0.1 | **10.0.0** | Lié à `flutter_secure_storage ^10.0.0` (conflit win32) |
| `flutter_secure_storage` | 9.2.4 | **10.0.0** | Breaking — réécriture Android crypto (Tink), min SDK 23 |

---

## 4. PACKAGES DÉJÀ À JOUR (diagnostic initial)

| Package | Version installée | Statut |
|---|---|---|
| `sqflite` | 2.4.2 | ✅ Latest |
| `http` | 1.6.0 | ✅ Latest |
| `open_file` | 3.5.11 | ✅ Latest |
| `url_launcher` | 6.3.2 | ✅ Latest |
| `path_provider` | 2.1.5 | ✅ Latest |
| `image_picker` | 1.2.1 | ✅ Latest |
| `flutter_tts` | 4.2.5 | ✅ Latest |
| `speech_to_text` | 7.3.0 | ✅ Latest |
| `webview_flutter` | 4.13.1 | ✅ Latest |
| `path` | 1.9.1 | ✅ Latest |
| `mockito` | 5.6.4 | ✅ Latest |
| `build_runner` | 2.13.1 | ✅ Latest |
| `flutter_native_splash` | 2.4.7 | ✅ Latest |
| `flutter_launcher_icons` | 0.14.4 | ✅ Latest |
| `sqflite_common_ffi` | 2.4.0+2 | ✅ Latest |

---

## 5. JOURNAL DES COMMITS

| Date | Commit | Étape |
|---|---|---|
| 21/04/2026 | `dbb4139` | Groupe 1 : shared_preferences 2.5.5 + flutter_reactive_ble 5.4.2 |
| 21/04/2026 | `524680e` | Groupe 2a : intl 0.20.2 |
| 21/04/2026 | `47e0c8b` | Groupe 2b : flutter_lints 6.0.0 |
| 21/04/2026 | `c143842` | Groupe 2c-1 : package_info_plus 9.0.1 |
| 21/04/2026 | `ebac174` | Groupe 2d : permission_handler 12.0.1 |
| 21/04/2026 | `029ff1c` | Groupe 2e : file_picker 11.0.2 + FilePicker.platform → FilePicker.pickFiles() |

---

## 6. CONDITIONS DE TEST

### 1. MATÉRIEL UTILISÉ

| Élément | Détail |
|---|---|
| PC | Windows 11 |
| Téléphone | Samsung SM-A137F Android 14 (requis groupe 3 uniquement) |
| Outils | Flutter SDK + `flutter pub get` + `flutter analyze` + `flutter test` |

### 2. PROCÉDURE APPLIQUÉE (groupes 1 et 2)

```bash
flutter pub upgrade <package>   # ou flutter pub get après modif pubspec.yaml
flutter analyze lib/ 2>&1 | grep -E "^(error|warning)"
flutter test
```

### 3. RÉSULTATS GROUPES 1 ET 2

| Groupe | Analyze | Tests |
|---|---|---|
| Groupe 1 | ✅ 0 erreur bloquante | ✅ 128/128 verts |
| Groupe 2a (`intl`) | ✅ 0 erreur bloquante | ✅ 128/128 verts |
| Groupe 2b (`flutter_lints`) | ✅ 0 nouveau warning | ✅ 128/128 verts |
| Groupe 2c-1 (`package_info_plus`) | ✅ 0 erreur bloquante | ✅ 128/128 verts |
| Groupe 2d (`permission_handler`) | ✅ 0 erreur bloquante | ✅ 128/128 verts |
| Groupe 2e (`file_picker`) | ✅ 0 erreur bloquante | ✅ 128/128 verts |

Warning pré-existant dans tous les runs :
`obd_scan_screen.dart:61 — unused_field _protocolDetectionDeviceName`
(documenté FICHE_MODULE_01, hors périmètre MODULE 15)

### 4. PROCÉDURE REQUISE — GROUPE 3 (session dédiée)

Les 2 packages du groupe 3 doivent être appliqués **dans la même session**, dans cet ordre :

1. `flutter_secure_storage ^10.0.0` + `package_info_plus ^10.0.0` simultanément

Pour chaque étape :
1. Modifier `pubspec.yaml`
2. `flutter pub get`
3. `flutter analyze lib/` → corriger toute erreur/warning bloquant
4. `flutter test` → 128/128 verts
5. **Test sur Samsung SM-A137F** :
   - `flutter_secure_storage` : vérifier migration données chiffrées existantes (clés API)
   - `package_info_plus` : vérifier affichage version dans écran Paramètres

### 5. STATUT

| Groupe | Statut |
|---|---|
| Groupe 1 (faible risque) | ✅ Validé le 21/04/2026 |
| Groupe 2a — `intl` | ✅ Validé le 21/04/2026 |
| Groupe 2b — `flutter_lints` | ✅ Validé le 21/04/2026 |
| Groupe 2c-1 — `package_info_plus` 9.0.1 | ✅ Validé le 21/04/2026 |
| Groupe 2c-2 — `package_info_plus` 10.x | 🔒 Bloqué — à faire avec groupe 3 |
| Groupe 2d — `permission_handler` 12.0.1 | ✅ Validé le 21/04/2026 |
| Groupe 2e — `file_picker` 11.0.2 | ✅ Validé le 21/04/2026 |
| Groupe 3 — session dédiée (2 packages) | ⏳ À planifier + Samsung SM-A137F |

*Fin de la fiche MODULE 15 — Mise à jour packages.*
