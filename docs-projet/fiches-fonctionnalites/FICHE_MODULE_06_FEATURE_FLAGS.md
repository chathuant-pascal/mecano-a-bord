# FICHE MODULE 06 — FEATURE FLAGS (`mab_features`)

**Statut** : ✅ **Validé le 19/04/2026**  
**Référence projet** : `CLAUDE.md` MODULE 6 (PRIORITÉ 2)

---

## 1. NOM DE LA FONCTIONNALITÉ

**Feature flags MAB** — Fichier unique `mab_features.dart` listant des constantes booléennes `kFeature*` pour documenter et, plus tard, conditionner l’exposition de blocs fonctionnels (sans supprimer le code).

---

## 2. RÔLE EN LANGAGE SIMPLE

Chaque interrupteur indique si une « grande zone » de l’app est prévue comme active ou non. Pour l’instant, le code peut ne pas encore les lire partout : les constantes servent déjà de **contrat produit** et de point d’ancrage pour des bascules (tests, Play Store, licence).

---

## 3. FICHIER

| Fichier | Rôle |
|---|---|
| `lib/config/mab_features.dart` | 12 constantes `kFeature*` + commentaires |

---

## 4. LES 12 CONSTANTES — RÔLE ET VALEUR PAR DÉFAUT

| Constante | Valeur défaut | Rôle |
|-----------|---------------|------|
| `kFeatureOBD` | `true` | Connexion OBD / diagnostic véhicule (Bluetooth, codes défaut, etc.). |
| `kFeatureSurveillance` | `true` | Surveillance / mode conduite (alertes, capteurs). |
| `kFeatureTTS` | `true` | Coach vocal TTS (annonces, réglages voix). |
| `kFeatureFormation` | `true` | Parcours formation (WebView, lien externe, déblocage). |
| `kFeatureIA` | `true` | Assistant IA (clés API, quota, chat). |
| `kFeaturePlaque` | `true` | Données véhicule via plaque (API gouv, etc.). |
| `kFeatureLicence` | **`false`** | Licence / activation Firebase (Mission 2 Inès) — désactivé jusqu’à implémentation. |
| `kFeatureCarnetEntretien` | `true` | Carnet d’entretien (entrées, rappels). |
| `kFeatureDocuments` | `true` | Documents Boîte à gants. |
| `kFeatureSanteVehicule` | `true` | Santé véhicule / onglets associés Boîte à gants. |
| `kFeatureMiseAJour` | `true` | Vérification mise à jour de l’app. |
| `kFeatureRappelsAdmin` | `true` | Rappels administratifs / échéances véhicule. |

---

## 5. NOTES

- **Aucune utilisation obligatoire** dans le code au moment de la validation : les flags sont prêts pour branchement progressif (`if (kFeatureXxx) { ... }`).
- **`kFeatureLicence = false`** : aligné avec la roadmap licence Firebase (Inès).

---

## 6. JOURNAL

| Date | Étape |
|---|---|
| 19/04/2026 | Création `lib/config/mab_features.dart` + fiche MODULE 06 |

---

## 7. CONDITIONS DE TEST RÉALISÉES PAR PASCAL

### 1. MATÉRIEL UTILISÉ

| Élément | Détail |
|---|---|
| Téléphone | Samsung SM-A137F — Android 14 |
| Outil | `dart analyze` + compilation |

### 2. ENVIRONNEMENT DE TEST

- Vérification statique uniquement (les flags ne sont pas encore branchés dans le code)
- `dart analyze lib/` pour confirmer l'absence d'erreur de compilation

### 3. PROCÉDURE À SUIVRE

1. Vérifier que `dart analyze lib/` ne signale aucune erreur sur `mab_features.dart`
2. Vérifier que les 12 constantes sont bien `const bool`
3. Vérifier que `kFeatureLicence = false` (seule constante désactivée)

### 4. RÉSULTAT ATTENDU

- Aucune erreur `dart analyze` sur `mab_features.dart` ✅
- 12 constantes présentes avec valeurs conformes ✅

### 5. STATUT TEST

| Élément | Détail |
|---|---|
| Statut | ✅ **Validé le 19/04/2026** (vérification statique) |
| Note | Branchement effectif dans le code prévu aux MODULEs suivants |
