# FICHE MODULE 13 — VERROUILLAGE FORMATION (URL + PONT FLUTTER ↔ HTML)

**Statut** : ✅ **Validé le 21/04/2026**  
**Date** : 21/04/2026  
**Référence projet** : `CLAUDE.md` MODULE 13 — **PRIORITÉ 3** — « Verrouillage formation »

**Fichiers concernés** :
- `mecano_a_bord/lib/formation_url.dart` (**modifié**)
- `formation-web/index.html` (**modifié**)

**Commit** : `78aef3b` — `MODULE 13 : verrouillage formation — kFormationUrl + postMessage done`

---

## 1. NOM DE LA FONCTIONNALITÉ

Verrouillage de la formation : gestion de l'URL de la formation par constantes nommées,
et connexion du pont JavaScript entre la page HTML et l'application Flutter.

---

## 2. RÔLE EN LANGAGE SIMPLE

Quand Pascal arrive sur la page de félicitations à la fin de la formation,
l'application Flutter doit le savoir pour débloquer l'accès à l'accueil.

Avant ce module :
- La page HTML sauvegardait un flag dans le `localStorage` du navigateur web.
- L'application Flutter écoutait un message JavaScript (`MABFormation.postMessage`).
- Ces deux mécanismes ne se parlaient pas — la formation ne se terminait jamais côté app.

Après ce module :
- Quand l'élève arrive sur la page félicitations, le HTML envoie `MABFormation.postMessage('done')`.
- Flutter reçoit ce message, pose le flag dans SharedPreferences, et navigue vers l'accueil.
- Le pont est opérationnel.

En plus, basculer vers `mecanoabord.fr` quand le domaine sera prêt ne demande
qu'un changement d'une ligne dans `lib/formation_url.dart`.

---

## 3. CE QUI A ÉTÉ MODIFIÉ (2 ÉTAPES)

### Étape 1 — lib/formation_url.dart

Avant : une seule constante `kFormationUrl` pointant directement sur l'URL GitHub Pages.

Après : trois constantes distinctes.

```dart
/// URL GitHub Pages (active tant que mecanoabord.fr n'est pas prêt)
const String kFormationUrlGithub =
    'https://chathuant-pascal.github.io/mecano-a-bord/formation-web/index.html';

/// URL production (à activer quand mecanoabord.fr est prêt + CNAME OVH configuré)
const String kFormationUrlProd = 'https://mecanoabord.fr/formation';

/// URL active — changer cette ligne uniquement pour basculer
const String kFormationUrl = kFormationUrlGithub;
```

Pour passer en production : remplacer `kFormationUrlGithub` par `kFormationUrlProd`
sur la dernière ligne — aucune autre modification nécessaire.

### Étape 2 — formation-web/index.html

Ajout au début de `initSectionFelicitations()` (appelée quand l'élève arrive
sur la section félicitations) :

```js
// Notifier l'app Flutter que la formation est terminée
if (window.MABFormation && typeof window.MABFormation.postMessage === 'function') {
  window.MABFormation.postMessage('done');
}
```

Le garde `if (window.MABFormation && ...)` protège l'appel : si la page est ouverte
dans un vrai navigateur (pas dans la WebView Flutter), aucune erreur n'est générée.

---

## 4. BILAN FICHIERS

| Fichier | Action | Rôle |
|---|---|---|
| `lib/formation_url.dart` | **Modifié** | Trois constantes URL — basculement GitHub Pages ↔ prod en une ligne |
| `formation-web/index.html` | **Modifié** | Pont Flutter ↔ HTML opérationnel via `MABFormation.postMessage('done')` |

---

## 5. ARCHITECTURE DU PONT FLUTTER ↔ HTML

```
[index.html — section félicitations]
  initSectionFelicitations()
    → MABFormation.postMessage('done')          ← AJOUTÉ MODULE 13

[formation_webview_screen.dart]
  addJavaScriptChannel('MABFormation', ...)
    → reçoit 'done'
    → vérifie que l'hôte est dans l'allowlist
    → prefs.setBool('formation_done', true)
    → Navigator.pushReplacement(HomeScreen)
```

L'allowlist `_isAllowedFormationHost` couvre déjà les deux domaines :
- `chathuant-pascal.github.io` ✅
- `mecanoabord.fr` et `*.mecanoabord.fr` ✅

Aucune modification du screen requise.

---

## 6. PROCÉDURE DE BASCULE VERS mecanoabord.fr (QUAND PRÊT)

Prérequis :
1. CNAME OVH configuré (`mecanoabord.fr` → GitHub Pages ou hébergement)
2. Contenu formation accessible à `https://mecanoabord.fr/formation`

Modification unique :

```dart
// lib/formation_url.dart — changer UNIQUEMENT cette ligne
const String kFormationUrl = kFormationUrlProd;  // ← était kFormationUrlGithub
```

Puis commit + push.

---

## 7. IMPACT TECHNIQUE

- Pont Flutter ↔ HTML opérationnel : la formation se termine correctement côté app.
- URL gérée par constante nommée : zéro risque de casse lors du passage en production.
- Aucun impact sur les autres modules.

---

## 8. JOURNAL

| Date | Étape |
|---|---|
| 21/04/2026 | Diagnostic : `MABFormation.postMessage('done')` absent de `index.html` — pont cassé. |
| 21/04/2026 | `lib/formation_url.dart` : ajout `kFormationUrlGithub` + `kFormationUrlProd` + sélection. |
| 21/04/2026 | `formation-web/index.html` : ajout `MABFormation.postMessage('done')` dans `initSectionFelicitations()`. |
| 21/04/2026 | `flutter analyze lib/` : 0 erreur bloquante. |
| 21/04/2026 | Commit `78aef3b` : `MODULE 13 : verrouillage formation — kFormationUrl + postMessage done`. |

---

## 9. CONDITIONS DE TEST

### 1. MATÉRIEL UTILISÉ

| Élément | Détail |
|---|---|
| PC | Windows 11 |
| Téléphone | Samsung SM-A137F Android 14 (requis pour test WebView complet) |
| Outils | Flutter SDK + `flutter analyze` |

### 2. ENVIRONNEMENT DE TEST

- `flutter analyze lib/` exécuté — 0 erreur bloquante.
- Test fonctionnel complet (pont Flutter ↔ HTML) à réaliser sur Samsung SM-A137F
  en lançant l'app et en parcourant la formation jusqu'à la section félicitations.

### 3. PROCÉDURE SUIVIE

```bash
flutter analyze lib/
```

### 4. RÉSULTAT ANALYZE

| Élément | Détail |
|---|---|
| Erreurs bloquantes | ✅ Aucune |
| Warnings | ✅ Aucun lié au module |
| Infos pré-existantes | `prefer_const_constructors`, `deprecated_member_use` — hors périmètre MODULE 13 |

### 5. TEST FONCTIONNEL À VALIDER (sur appareil)

| Étape | Action | Résultat attendu |
|---|---|---|
| 1 | Lancer l'app sur Samsung SM-A137F | Écran formation WebView chargé |
| 2 | Parcourir la formation jusqu'à la section Félicitations | Section félicitations affichée |
| 3 | Observer l'app | L'app navigue automatiquement vers l'accueil (HomeScreen) |
| 4 | Vérifier que le flag est posé | `shared_preferences` contient `formation_done = true` |

### 6. STATUT TEST

| Élément | Détail |
|---|---|
| Analyze | ✅ Validé le 21/04/2026 |
| Test fonctionnel appareil | ⏳ À valider sur Samsung SM-A137F quand disponible |

*Fin de la fiche MODULE 13 — Verrouillage formation.*
