# CLAUDE.md — Mémoire Permanente Claude Code
# Projet : Mécano à Bord — Écosystème Complet
# Dernière mise à jour : 17/04/2026 — Version 3.1
# © Mécano à Bord — Pascal Chathuant — Guadeloupe
# ================================================================
# ⚠️ CE FICHIER EST LA MÉMOIRE PERMANENTE DE CLAUDE CODE
# À placer à la racine du dossier : Mecano A Bord/
# Claude Code le lit automatiquement à chaque session
# ================================================================

---

## ⚠️ LECTURE OBLIGATOIRE À CHAQUE SESSION — DANS CET ORDRE

Avant de faire quoi que ce soit, Claude Code doit lire ces fichiers :

```
ÉTAPE 1 → Lire CE FICHIER (CLAUDE.md) en entier
ÉTAPE 2 → Lire AUDIT_MECANO_A_BORD_V1.md (audit Claude Code)
ÉTAPE 3 → Lire AUDIT_MECANO_A_BORD_CURSOR_V1.md (audit Cursor)
ÉTAPE 4 → Lire docs-projet/VERIFICATION_REGLES_DEVELOPPEUR.md
ÉTAPE 5 → Lire .cursor/rules/contexte-pascal-mab.mdc
ÉTAPE 6 → Lire .cursor/rules/mab-design-system-figma.mdc
ÉTAPE 7 → Seulement après : demander à Pascal par quoi commencer
```

⚠️ Ne jamais sauter ces lectures. Elles contiennent les règles intouchables du projet.

---

## QUI EST PASCAL

- **Prénom** : Pascal Chathuant
- **Localisation** : Guadeloupe (décalage -5h avec Paris)
- **Profession** : Électromécanicien avec 25+ ans d'expérience
- **Niveau programmation** : Débutant complet — expliquer simplement, sans jargon
- **Mode de travail** : Guidé pas à pas, une chose à la fois, validation avant de continuer
- **Règle absolue** : Ne jamais modifier un fichier sans avoir montré ce qui va être changé et obtenu l'accord de Pascal
- **Workspace** : `C:\Users\karuc\OneDrive\Bureau\Mecano A Bord\`
- **Développeuse** : Inès (freelance) — disponible dans 2 à 3 semaines

---

## 🚨 RÈGLES INTOUCHABLES — NE JAMAIS VIOLER

Ces règles sont figées. Toute modification nécessite un accord explicite de Pascal.

```
RÈGLE 1 — VOIX TTS FÉMININE
→ pitch : 1.2 (figé — ne jamais modifier)
→ speechRate : 0.5 (figé — ne jamais modifier)
→ Fichier : lib/services/tts_service.dart

RÈGLE 2 — MOTS INTERDITS
→ Ne jamais utiliser dans les textes ET messages vocaux :
   ❌ "panne"
   ❌ "danger"
   ❌ "défaillance"
→ Remplacer par : "problème détecté", "attention requise", "vérification nécessaire"

RÈGLE 3 — DESIGN SYSTEM OBLIGATOIRE
→ Utiliser EXCLUSIVEMENT : MabColors / MabTextStyles / MabDimensions
→ Interdit : valeurs hardcodées (ex: Color(0xFFCC0000), fontSize: 16)
→ Fichier référence : lib/theme/mab_theme.dart

RÈGLE 4 — ACCESSIBILITÉ
→ Zones tactiles minimales : 48dp (norme EAA 2025)
→ Toujours vérifier sur chaque widget interactif

RÈGLE 5 — PROFILS VÉHICULE
→ Maximum 2 profils — le 3e doit être refusé (StateError)
→ Ne jamais assouplir cette limite sans accord Pascal

RÈGLE 6 — PÉRIMÈTRE V1 STRICT
→ Interdit de coder ou préparer les modules V2/V3/V4
→ Toute évolution hors V1 doit être validée par Pascal avant implémentation
```

---

## ⚙️ MÉTHODOLOGIE DE TRAVAIL OBLIGATOIRE — VERSION 3.1

### Processus obligatoire pour CHAQUE fonctionnalité

```
ÉTAPE 1  → Relire les deux audits sur la fonctionnalité concernée
ÉTAPE 2  → Audit complet du code existant
ÉTAPE 3  → Développer / corriger
ÉTAPE 4  → Ajouter les try/catch sur tous les points de défaillance
ÉTAPE 5  → Audit sécurité OWASP
ÉTAPE 6  → Audit UX (public débutant / anxieux)
ÉTAPE 7  → Écrire les tests unitaires
ÉTAPE 8  → Valider sur Samsung SM-A137F Android 14
ÉTAPE 9  → Mettre à jour docs-projet/EVOLUTION.md + BACKLOG.md
ÉTAPE 10 → Commit GitHub propre
ÉTAPE 11 → Passer à la fonctionnalité suivante
```

### Architecture MVC obligatoire

```
📁 nom_fonctionnalite/
   📁 backend/    → données, logique métier, API, Firebase
   📁 frontend/   → écrans, boutons, design, UX
   📁 tests/      → tests unitaires
```

### Try/Catch — obligatoire sur

```
→ SharedPreferences (lecture ET écriture)
→ SQLite / sqflite (toutes les opérations)
→ Appels API (IA, plaque immatriculation, Firebase)
→ Connexion Bluetooth OBD
→ Chargement WebView
→ Ouverture de fichiers (open_file)
→ Image picker / file picker
→ Toute opération réseau
```

### Tests unitaires — obligatoires

```
→ Cas nominal (ça fonctionne comme prévu)
→ Cas d'erreur (ça échoue proprement sans planter)
→ Cas limite (valeurs extrêmes, réseau absent, stockage plein)
```

### Audit OWASP — checklist obligatoire

```
✅ Données sensibles chiffrées (FlutterSecureStorage pour clés API et quota IA)
✅ Communications HTTPS uniquement
✅ Aucun debugPrint actif en mode release (utiliser mabLog conditionnel)
✅ WebView avec NavigationDelegate strict (allowlist domaines)
✅ Entrées utilisateur validées avant traitement
✅ Permissions Android justifiées par usage réel
```

### Audit UX — checklist obligatoire

```
✅ Public cible : débutant, anxieux, non technicien
✅ Langage simple, rassurant, concret — zéro jargon technique
✅ Messages d'erreur compréhensibles (pas de codes techniques)
✅ Feedback visuel à chaque action utilisateur
✅ Message d'erreur + bouton "Réessayer" si absence réseau
✅ Mots interdits absents : panne / danger / défaillance
```

### Toggle / Feature Flags — obligatoire

```dart
// Fichier : lib/config/mab_features.dart (à créer — MODULE 6)
const bool kFeatureOBD = true;
const bool kFeatureSurveillance = true;
const bool kFeatureTTS = true;
const bool kFeatureFormation = true;
const bool kFeatureIA = true;
const bool kFeaturePlaque = true;
const bool kFeatureLicence = false;        // ← Inès Mission 2
const bool kFeatureCarnetEntretien = true;
const bool kFeatureDocuments = true;
const bool kFeatureSanteVehicule = true;
const bool kFeatureMiseAJour = true;
const bool kFeatureRappelsAdmin = true;
```

### Logger conditionnel — obligatoire

```dart
// Fichier : lib/utils/mab_logger.dart (à créer — MODULE 5)
import 'package:flutter/foundation.dart';
void mabLog(String message) {
  if (kDebugMode) {
    debugPrint('[MAB] $message');
  }
}
// Remplace TOUS les debugPrint() existants
```

---

## 📋 PLAN DE TRAVAIL — 15 MODULES DANS L'ORDRE

### PRIORITÉ 1 — BLOQUANT

```
MODULE 1  → Bug diagnostic OBD ← FAIRE EN PREMIER (seul)
            Fichier : lib/screens/obd_scan_screen.dart
            Action : adb logcat -s flutter + Samsung SM-A137F
            Méthodes OBD complexes à surveiller :
            → connect() : lignes 250-288
            → runProtocolDetection() : lignes 295-322
            → getVehicleData() : lignes 343-421
            → readLivePid() : lignes 145-184
            → getBondedDevices() : lignes 224-240

MODULE 2  → Clé de signature Release ← INES OBLIGATOIRE
            Fichier : android/app/build.gradle.kts ligne 37
            signingConfig = debug → keystore .jks permanent

MODULE 3  → Changer package name ← FAIRE AVEC INES AVANT PUBLICATION
            Fichier : android/app/build.gradle.kts ligne 9
            com.example.mecano_a_bord → fr.mecanoabord.app
            ⚠️ IRRÉVERSIBLE après publication Play Store
```

### PRIORITÉ 2 — IMPORTANT (faire seul avec Claude Code)

```
MODULE 4  → Sécuriser la WebView
            Fichier : lib/screens/formation_webview_screen.dart
            → NavigationDelegate + allowlist mecanoabord.fr + github.io
            → Valider source JS avant déblocage app
            → try/catch sur loadRequest()
            → Message erreur réseau + bouton Réessayer
            → Stopper Timer.periodic en arrière-plan

MODULE 5  → Nettoyer les 13 debugPrint
            → Créer lib/utils/mab_logger.dart
            → home_screen.dart : lignes 574/672/698/731/767/821
            → bluetooth_obd_service.dart : ligne 313 (🚨 OBD brut)
            → ai_conversation_service.dart : ligne 689
            → vehicle_reference_service.dart : lignes 74/78
            → formation_web_launch_screen.dart : ligne 37
            → help_contact_screen.dart : lignes 52/69

MODULE 6  → Créer les Feature Flags
            Fichier à créer : lib/config/mab_features.dart

MODULE 7  → Ajouter try/catch manquants
            → lib/main.dart : SharedPreferences.getInstance()
            → lib/screens/onboarding_screen.dart : prefs.setBool()
            → lib/screens/add_maintenance_screen.dart : SQLite
            → lib/screens/glovebox_screen.dart :
              FilePicker lignes 377-380 / open_file / copie fichier ligne 385

MODULE 8  → Système de licence Firebase ← INES OBLIGATOIRE
            Packages : firebase_core + cloud_firestore + device_info_plus
            Format : MAB-XXXX-XXXX-XXXX lié à l'identifiant appareil
            Vérification : au démarrage ET à chaque mise à jour
```

### PRIORITÉ 3 — AMÉLIORATIONS

```
MODULE 9  → Tests unitaires IA service
MODULE 10 → Tests unitaires Repository
MODULE 11 → Refactoring MVC Carnet entretien
MODULE 12 → Refactoring MVC Profil véhicule
MODULE 13 → Verrouillage formation (quand mecanoabord.fr prêt)
MODULE 14 → Validation 10 providers IA
MODULE 15 → Mise à jour packages
```

---

## 🔍 PRÉCISIONS TECHNIQUES ISSUES DES DEUX AUDITS

### Corrections notables entre les deux audits

```
✅ Quota IA : DÉJÀ CHIFFRÉ dans FlutterSecureStorage
   → lib/services/ai_conversation_service.dart lignes 108-111
   → Fausse alerte de Claude Code — corrigé par Cursor

⚠️ SIRET manquant :
   → lib/widgets/mab_legal_mentions_body.dart ligne 60
   → '[SIRET : à compléter avant mise en vente]'

⚠️ Validation VIN insuffisante :
   → lib/screens/glovebox_profile_screen.dart lignes 328-332
   → Ajouter checksum ISO 3779

⚠️ Limite upload fichier absente :
   → lib/screens/glovebox_screen.dart lignes 377-385
   → Ajouter limite max 10 Mo
```

---

## 📦 PACKAGES — ÉTAT

| Package | Version actuelle | Dernière stable | Statut |
|---|---|---|---|
| shared_preferences | ^2.2.2 | 2.5.5 | ⚠️ Mettre à jour |
| sqflite | ^2.3.0 | 2.4.2 | ⚠️ Mettre à jour |
| flutter_secure_storage | ^9.0.0 | 10.0.0 | ⚠️ Mettre à jour |
| http | ^1.2.0 | 1.6.0 | ⚠️ Mettre à jour |
| open_file | ^3.3.2 | 3.5.11 | ⚠️ Sécurité |
| file_picker | ^8.0.0 | 11.0.2 | ⚠️ Mettre à jour |
| flutter_reactive_ble | ^5.2.3 | 5.4.2 | ⚠️ Android 14 |
| permission_handler | ^11.3.0 | 12.0.1 | ⚠️ Mettre à jour |
| webview_flutter | ^4.13.1 | 4.13.1 | ✅ OK |
| flutter_tts | ^4.2.0 | 4.2.5 | ✅ OK |
| intl | ^0.19.0 | 0.20.2 | ⚠️ Vérifier si utilisé |

Packages à ajouter (quand prêt) :
```
firebase_core + cloud_firestore + device_info_plus ← Mission 2 Inès
logger ← remplacer debugPrint
connectivity_plus ← détecter absence réseau
```

---

## STRUCTURE DU PROJET

```
Mecano A Bord/
├── CLAUDE.md                             ← CE FICHIER ✅
├── AUDIT_MECANO_A_BORD_V1.md             ← Audit Claude Code ✅ LIRE
├── AUDIT_MECANO_A_BORD_CURSOR_V1.md      ← Audit Cursor ✅ LIRE
├── docs-projet/
│   ├── VERIFICATION_REGLES_DEVELOPPEUR.md ← LIRE À CHAQUE SESSION
│   ├── EVOLUTION.md                      ← Mettre à jour après chaque étape
│   ├── BACKLOG.md                        ← Mettre à jour après chaque étape
│   └── NOTES_INTENTION_TECHNIQUES.md     ← Mettre à jour après chaque étape
├── .cursor/rules/
│   ├── contexte-pascal-mab.mdc           ← LIRE À CHAQUE SESSION
│   └── mab-design-system-figma.mdc       ← LIRE À CHAQUE SESSION
├── formation-web/
│   ├── index.html                        ← ~8000+ lignes
│   └── assets/ (images / videos / pdfs)
└── mecano_a_bord/
    ├── lib/
    │   ├── config/     ← À créer : mab_features.dart (MODULE 6)
    │   ├── utils/      ← À créer : mab_logger.dart (MODULE 5)
    │   ├── theme/
    │   │   └── mab_theme.dart   ← Design system MAB — RÉFÉRENCE
    │   ├── data/
    │   ├── screens/
    │   ├── services/
    │   └── widgets/
    ├── test/
    └── android/
        └── app/
            ├── build.gradle.kts     ← ⚠️ signature + package à corriger
            └── src/main/AndroidManifest.xml ← ⚠️ permissions à justifier
```

---

## GITHUB — INFRASTRUCTURE

```
Repo         : chathuant-pascal/mecano-a-bord
Branche      : main
GitHub Pages : https://chathuant-pascal.github.io/mecano-a-bord/formation-web/index.html
URL finale   : https://mecanoabord.fr/formation (CNAME OVH à configurer)
```

⚠️ Token GitHub → générer sur GitHub → coller dans Claude Code uniquement
⚠️ Keystore .jks → JAMAIS dans GitHub

---

## PILIER 1 — APPLICATION MOBILE

```
Version        : 1.0.0+14
Téléphone test : Samsung SM-A137F — Android 14
Flux actuel    : Onboarding → Formation WebView → Accueil
Pont JS        : MABFormation.postMessage('done') → déblocage app
API plaque     : particulier.api.gouv.fr (gratuite / DROM couverts)
```

### Missions Inès (2-3 semaines)

```
MISSION 1 : Keystore Release (bloquant Play Store)
MISSION 2 : Système licence Firebase MAB-XXXX-XXXX-XXXX
```

---

## PILIER 2 — FORMATION WEB

```
Structure    : 7 modules + 9 bonus + félicitations = 18 étapes
GitHub Pages : actif ✅

Reste à faire :
⏳ Prompt C : section 3.2 + liquides + pneus (Claude Code)
⏳ 10 photos options véhicule (Pascal)
⏳ 10 vidéos à filmer (Pascal)
⏳ Pointer mecanoabord.fr → GitHub Pages (OVH CNAME)
⏳ MABFormation.postMessage('done') dans index.html
⏳ Page de vente Systeme.io
⏳ Séquence email post-webinaire
```

---

## RÈGLES DE TRAVAIL — LISTE COMPLÈTE (25 règles)

```
RÈGLES GÉNÉRALES :
1.  Lire les 6 fichiers obligatoires avant toute action
2.  Expliquer ce qu'on va faire AVANT de le faire
3.  Travailler un fichier à la fois
4.  Montrer le résultat après chaque modification
5.  Ne jamais modifier sans accord explicite de Pascal
6.  Diagnostic AVANT modification — toujours
7.  Git push après chaque série de modifications validées
8.  Langage simple — Pascal est électromécanicien, pas développeur
9.  Vérifier avec script bash que les modifications sont en place
10. Mettre à jour EVOLUTION.md + BACKLOG.md après chaque étape majeure

RÈGLES INTOUCHABLES :
11. TTS : pitch 1.2 / speechRate 0.5 — JAMAIS modifier
12. Mots interdits : panne / danger / défaillance
13. Design system : MabColors / MabTextStyles / MabDimensions uniquement
14. Zones tactiles : minimum 48dp
15. Profils véhicule : maximum 2 — refuser le 3e (StateError)
16. Périmètre V1 strict — pas de V2/V3/V4 sans accord Pascal

RÈGLES MÉTHODOLOGIE :
17. Architecture MVC : backend / frontend / tests séparés
18. Try/Catch sur CHAQUE opération à risque
19. Tests unitaires pour CHAQUE fonctionnalité
20. Audit OWASP sur CHAQUE fonctionnalité
21. Audit UX sur CHAQUE écran
22. Toggle Feature Flag sur CHAQUE module et fonctionnalité
23. Travailler module par module — JAMAIS plusieurs en même temps
24. Utiliser Tavily pour vérifier compatibilité packages AVANT de coder
25. Vérifier compatibilité Android 14 systématiquement
```

---

## PHRASES CLÉS DE PASCAL

```
"Quand tu comprends ta voiture, tu apprends à la faire durer."
"Un contrôle, c'est 2 minutes. Une casse, c'est 2 000 euros."
"Ton moteur te pardonne tout, sauf l'oubli."
"Un conducteur informé n'est plus un client perdu."
"Comprendre ≠ réparer soi-même. Comprendre = décider calmement."
"Je ne t'apprends pas la mécanique, je t'apprends à parler le même langage que ta voiture."
"Être Mécano à Bord, c'est être maître de sa route."
"Respire. Allume tes warnings. Tu n'es pas seul(e)."
```

---

## INFORMATIONS COMPTES

```
OVH        : karucards@gmail.com (mecanoabord.fr + mecanoabord.com)
Gmail pro  : mecanoabord@gmail.com
Systeme.io : mecanoabord@gmail.com ✅
GitHub     : chathuant-pascal/mecano-a-bord ✅
```

---

*Fin du fichier CLAUDE.md — Version 3.1 — 17/04/2026*
*© Mécano à Bord — Pascal Chathuant — Guadeloupe*
*Ce fichier est la mémoire permanente de Claude Code.*
*Il est lu automatiquement à chaque nouvelle session.*
