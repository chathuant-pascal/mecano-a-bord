# CLAUDE.md — Mémoire Permanente Claude Code
# Projet : Mécano à Bord — Écosystème Complet
# Dernière mise à jour : 06/04/2026
# © Mécano à Bord — Pascal Chathuant — Guadeloupe
# ================================================================
# ⚠️ CE FICHIER EST LA MÉMOIRE PERMANENTE DE CLAUDE CODE
# À placer à la racine du dossier : Mecano A Bord/
# Claude Code le lit automatiquement à chaque session
# ================================================================

---

## QUI EST PASCAL

- **Prénom** : Pascal Chathuant
- **Localisation** : Guadeloupe (décalage -5h avec Paris)
- **Profession** : Électromécanicien avec 25+ ans d'expérience
- **Niveau programmation** : Débutant complet — expliquer simplement, sans jargon technique
- **Mode de travail** : Guid pas à pas, une chose à la fois, validation avant de continuer
- **Règle absolue** : Ne jamais modifier un fichier sans avoir montré ce qui va être changé et obtenu l'accord de Pascal
- **Workspace** : `C:\Users\karuc\OneDrive\Bureau\Mecano A Bord\`

---

## STRUCTURE DU PROJET

```
Mecano A Bord/
├── CLAUDE.md                    ← CE FICHIER (mémoire Claude Code)
├── app-mobile/                  ← Application Flutter Mécano à Bord
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── repositories/
│   │   │   └── mab_repository.dart
│   │   ├── screens/
│   │   │   └── legal_mentions_screen.dart
│   │   └── services/
│   │       ├── vehicle_health_service.dart    ← CRÉÉ par Cursor 05/04
│   │       └── vehicle_reference_service.dart ← CRÉÉ par Cursor 05/04
│   └── android/
│       └── app/src/main/kotlin/.../MainActivity.kt ← MODIFIÉ 05/04 (RPM fix)
└── formation-web/               ← Application Web Formation (À CRÉER)
    ├── index.html
    └── assets/
        ├── images/
        ├── videos/
        └── pdfs/
```

---

## PILIER 1 — APPLICATION MOBILE MÉCANO À BORD

### Informations techniques

```
Version          : 1.0.0+1
SDK Flutter      : >=3.0.0 <4.0.0
Téléphone test   : Samsung SM-A137F — Android 14
Éditeur          : Cursor (VS Code avec IA intégrée)
GitHub           : configuré avec toute la documentation
Développeuse     : Inès (freelance) — en attente RDV fin de semaine
iOS              : laissé de côté pour l'instant (nécessite Mac ou Codemagic)
```

### Statut au 06/04/2026

```
✅ APPLICATION CONSIDÉRÉE PRÊTE PAR PASCAL
✅ Test RPM Samsung moteur tournant : VALIDÉ (700-950 tr/min au ralenti)
✅ Onglet Santé visible en mode démo
⏳ Bloquée uniquement par les missions d'Inès (clé signature + licence)
⏳ RDV Inès prévu fin de semaine 06/04/2026
```

### Tout ce qui est validé et fonctionnel ✅

```
✅ Version 1.0.0+1 fonctionnelle complète
✅ Boîte à gants fonctionnelle (5 onglets dont Santé)
✅ Mode démo complet et fonctionnel
✅ Politique de confidentialité intégrée
✅ Aide & Contact intégré (section "Par où commencer ?" ajoutée)
✅ Coach vocal TTS fonctionnel
✅ Second profil véhicule (max 2 profils)
✅ Nouvelle présentation visuelle complète
✅ 10 logos IA officiels intégrés
✅ Clés API individuelles par fournisseur IA
✅ Menu accordéon IA dans Réglages
✅ Système de vérification de mise à jour
✅ Bouton "Où est ma prise OBD ?" implémenté
✅ OBD lecture complète et fonctionnelle
✅ Surveillance temps réel MODE CONDUITE
✅ Effacement codes défaut OBD + dialogue pédagogique
✅ Réinitialisation complète application
✅ Rappels administratifs CT/assurance/Crit'Air
✅ Champ motorisation dans profil véhicule
✅ Historique diagnostics OBD dans Boîte à gants
✅ Mentions légales en écran dédié (accessible depuis 4 endroits)
✅ Écran d'accueil harmonisé (titres seuls, sans sous-titres tronqués)
✅ Onboarding corrigé — page d'acceptation en PREMIÈRE (28/03/2026)
✅ Carnet d'entretien : 28 types + 6 catégories visuelles
✅ Dialogue pédagogique après effacement codes défaut
✅ Système OBD intelligent implémenté (vehicle_health_service.dart)
✅ Correction bug RPM PID 010C (05/04/2026)
```

### PIDs OBD Live — État complet

```
✅ 0105 : Température liquide refroidissement (°C)
✅ 0142 : Tension batterie (V)
✅ 010B : Pression (kPa)
✅ 010C : Régime moteur RPM — CORRIGÉ 05/04/2026
         Formule : ((A * 256) + B) / 4.0
```

PIDs réservés V2 :
```
⏳ 0111 : Position papillon (Coach Conducteur V2)
⏳ 015E : Débit carburant (consommation réelle V2)
⏳ 010D : Vitesse véhicule (Coach Conducteur V2)
⏳ 0104 : Charge moteur (détection préventive V2)
⏳ 012F : Niveau carburant (confort débutant V2)
⏳ 010F : Température air admission (intercooler V2)
```

### Nouvelle logique OBD — Décidée et implémentée 05/04/2026

**Philosophie** : Mécano à Bord N'EST PAS une app de diagnostic technique.
C'est un COACH PÉDAGOGIQUE pour conducteurs débutants.
Objectif : RASSURER et INFORMER, jamais frustrer.

**Option retenue : B + C combinées**
- Codes OBD cachés par défaut (jamais en premier plan)
- Message humain clair en premier
- Explication vocale TTS graduée 🟢🟡🔴
- Code accessible via "En savoir plus"
- Bilan positif toutes les 2h de conduite

**Système de référence véhicule : Option A + C + Solution 3**
- IA intégrée récupère valeurs constructeur au profil
- Base communautaire qui grandit avec chaque utilisateur
- Apprentissage progressif 14 jours du véhicule réel
- Double référence : constructeur + comportement réel

**Gradation coach vocal :**
```
🟢 NIVEAU 0 — BILAN POSITIF (toutes les 2h)
   "Tout va bien, ta voiture se comporte normalement."

🟡 NIVEAU 1 — SURVEILLANCE (déviation 10-15%)
   "Surveille ta température, elle est un peu haute par rapport
   à d'habitude. Pas d'urgence."

🔴 NIVEAU 2 — URGENT (déviation >20% ou seuil critique)
   "Stop. Ta batterie chute anormalement.
   Rends-toi chez un professionnel aujourd'hui."
```

**Fichiers créés par Cursor :**
```
lib/services/vehicle_health_service.dart
lib/services/vehicle_reference_service.dart
```

Base SQLite v5 avec tables :
- vehicle_reference_values
- vehicle_learned_values
- vehicle_health_alert_history

### Missions Inès — En attente RDV fin de semaine

```
MISSION 1 — PRIORITÉ ABSOLUE : Clé de signature Release
→ Générer keystore .jks
→ Configurer build.gradle.kts
→ Compiler APK Release : flutter build apk --release
→ Tester sur Samsung SM-A137F
→ Sauvegarder keystore : Google Drive + copie locale
⚠️ JAMAIS dans GitHub

MISSION 2 : Système de licence Firebase
→ firebase_core + cloud_firestore + device_info_plus
→ Collection 'licences' : code → { valide, appareils: [id1,id2] }
→ Écran activation code au 1er démarrage
→ Format : MAB-XXXX-XXXX-XXXX
→ Max 2 appareils par licence
→ Mode démo reste accessible sans code

MISSION 3 : ANNULÉE ✅ (OBD résolu par Cursor)
```

### Ce qui reste à faire — Application

```
⏳ Clé de signature Release (Mission 1 Inès) ← BLOQUANT
⏳ Système de licence Firebase (Mission 2 Inès) ← BLOQUANT
⏳ Compléter SIRET dans mentions légales
⏳ Confirmer contact@mecanoabord.fr actif
⏳ URL formation → https://mecanoabord.systeme.io/formation
   (sera remplacée par lien app web formation quand prête)
```

### Identité visuelle application mobile

```
Couleur principale : Rouge #CC0000
Fond               : Noir / Anthracite sombre
Texte              : Blanc
Tableaux           : Colonne rouge #CC0000
```

### Roadmap V2/V3/V4 application mobile

```
V2 Priorité 1 → Base Communautaire Intelligente
                "Le Waze de la santé automobile"
                Données anonymes opt-in / alertes prédictives par modèle
V2 Priorité 2 → Coach Conducteur
                Score conduite / impact financier / détection fatigue
V2 Priorité 3 → Boîte Noire Conducteur (complétion)
                Notes vocales + rapport hebdomadaire
V2 Priorité 4 → Miroir Garage (OCR devis)
V2 Priorité 5 → Passeport Véhicule (revente → 2 licences vendues)
V3             → Garage des IA (serveur sécurisé multi-IA)
V4             → Système Multi-IA Collaboratif
```

### Comptes créés

```
OVH :
→ Email compte : karucards@gmail.com
→ Domaines : mecanoabord.fr + mecanoabord.com
→ DNSSEC activé

Gmail pro :
→ mecanoabord@gmail.com
→ Utiliser CET email pour tous les autres comptes

Systeme.io :
→ Créé avec mecanoabord@gmail.com ✅
→ Formation à construire

Comptes à créer :
⏳ YouTube
⏳ Facebook (Page + Groupe privé élèves)
⏳ Instagram
⏳ TikTok (plus tard)
⏳ LinkedIn (plus tard)
```

---

## PILIER 2 — APPLICATION WEB DE FORMATION

### "La Méthode Sans Stress Auto — Ta Voiture Sans Galère"

### Décision du 06/04/2026

```
→ Application WEB (pas mobile, pas Play Store)
→ Accessible via navigateur PC et mobile
→ Accessible via lien depuis l'app mobile Mécano à Bord
→ Vendue en BUNDLE avec la licence Mécano à Bord
→ Construite avec Claude Code
→ Hébergée sur mecanoabord.fr
→ Un seul fichier index.html (SPA — Single Page Application)
```

### Identité visuelle — À RESPECTER STRICTEMENT

```css
--rouge-principal    : #CC0000
--fond-principal     : #111111
--fond-secondaire    : #1a1a1a
--fond-cartes        : #242424
--texte-principal    : #FFFFFF
--texte-secondaire   : #AAAAAA
--texte-discret      : #666666
--bordures           : #333333
--bordure-active     : #CC0000
--succes             : #4CAF50
--fond-succes        : #1a3a1a
--police             : Inter, sans-serif
```

Logo : Cercle rouge #CC0000 avec lettre "M" blanche
Nom affiché : "Mécano" blanc + "à Bord" rouge #CC0000

### Identité de la formation

```
Nom commercial    : TA VOITURE SANS GALÈRE
Nom méthode       : La Méthode Sans Stress Auto
Slogan            : "Je ne t'apprends pas la mécanique.
                     Je t'apprends à parler le même langage que ta voiture."
Auteur            : Pascal Chathuant — Électromécanicien 25 ans
Public cible      : Conducteurs novices, femmes, jeunes permis
Ton               : Bienveillant, rassurant, jamais condescendant
Structure leçons  : PROBLÈME → SOLUTION → RÉSULTAT ATTENDU
```

### Les 4 piliers de la méthode

```
Pilier 1 → Observation  : Voir ce que la majorité ignore
Pilier 2 → Prévention   : Agir avant la panne
Pilier 3 → Dialogue     : Comprendre et communiquer avec le pro
Pilier 4 → Organisation : Suivre et planifier pour ne jamais subir
```

### Architecture de l'application web

```
Section 1  → Page d'accueil + Simulateur de Stress Auto (14 questions)
Section 2  → Page résultat quiz (4 profils)
Section 3  → Tableau de bord élève (progression)
Section 4  → Module 0 : Mindset
Section 5  → Étape 1 : Quelle voiture j'ai ?
Section 6  → Étape 2 : Démarrer sans stress
Section 7  → Étape 3 : Comprendre sous le capot
Section 8  → Étape 4 : Éviter les grosses galères
Section 9  → Étape 5 : Parler au garagiste sans se faire avoir
Section 10 → Section Bonus (10 bonus)
```

### Simulateur de Stress Auto — 4 profils

```
🔴 Le Stressé   → majorité réponses A → "Je panique dès qu'un voyant s'allume"
🟡 Le Distrait  → réponses B/C mixtes → "Je sais faire mais j'oublie"
🟢 Le Zen       → majorité réponses B → "Je suis calme mais j'ai besoin de repères"
🔵 L'Organisé   → majorité réponses C/D → "J'ai de bons réflexes, quelques lacunes"
```

### Contenu pédagogique complet

**MODULE 0 — MINDSET**
- 10 principes du conducteur autonome
- 7 attitudes clés
- Règle d'or : MOTEUR FROID pour toutes vérifications
- Support : Fiche Mindset ✅

**ÉTAPE 1 — QUELLE VOITURE J'AI ?**
- Lire sa carte grise (D.1/D.2/E/P.3/J.1/F.2)
- Découvrir son moteur et carburant
- Connaître le nom de son moteur (PureTech / TDI / HDi...)
- Trouver pression pneus + type huile
- Support : Fiche Ma Voiture ✅

**ÉTAPE 2 — DÉMARRER SANS STRESS**
- 10 réflexes essentiels
- Tour de 30 Secondes (5 sens : Vue/Ouïe/Odorat/Toucher/Intuition)
- Les 7 premiers jours (mini-rituel 5 min/jour)
- Erreurs à éviter
- Supports : Check-list Tour 30s / Checklist Entretien ✅

**ÉTAPE 3 — COMPRENDRE SOUS LE CAPOT**
- Ouvrir le capot sans crainte
- Zones visibles : batterie / huile / refroidissement / lave-glace / filtre air
- Tableau voyants ↔ éléments physiques :
  · Huile → jauge d'huile (vérifier à froid)
  · Température → réservoir refroidissement (ne jamais ouvrir à chaud)
  · Batterie → câbles (vérifier cosses)
  · Frein/ABS → réservoir frein (si bas → garage)
  · Check Engine → diagnostic électronique
- Support : Fiche Voyants ↔ Capot ✅

**ÉTAPE 4 — ÉVITER LES GROSSES GALÈRES**
- 10 erreurs idiotes :
  1. Pneus sous-gonflés
  2. Volant en butée
  3. Accélérer fort moteur froid
  4. Couper moteur après long trajet (turbo)
  5. Ne jamais vidanger boîte auto
  6. Micro-trajets uniquement
  7. Monter côte pied au plancher
  8. Trop d'huile
  9. Ignorer voyant moteur clignotant
  10. Monter/descendre trottoirs violemment
- Tableau entretien VS conséquences (coûts réels) :
  · Huile négligée → 1 500-5 000€
  · Refroidissement → 800-3 000€
  · Courroie distribution → 1 000-4 000€
  · Erreur carburant → 1 000-6 000€
- 15 gestes conduite intelligente
- Routine 5 minutes par mois
- Supports : Calendrier Anti-Galère / 10 Erreurs / Conduite Intelligente ✅

**ÉTAPE 5 — PARLER AU GARAGISTE SANS SE FAIRE AVOIR**
- 10 questions clés à poser
- Phrases par situation (diagnostic/pièce/devis flou/pression/récupération)
- Contrôles invisibles à demander (12 éléments)
- Préparer son contrôle technique :
  · Véhicule neuf → après 4 ans
  · Plus de 4 ans → tous les 2 ans
  · Amende si non fait → 135€
  · 10 points à vérifier soi-même
- Supports : Fiche Garagiste / Contrôle Technique / Contrôle Pro ✅

### 10 Modules reformulés (titres accrocheurs)

```
Module 1  → Apprends à connaître ta voiture avant de la juger
Module 2  → Quand un voyant s'allume, garde ton calme
Module 3  → Les gestes simples qui t'évitent les galères
Module 4  → Savoir parler à un garagiste (et te faire respecter)
Module 5  → Les erreurs qui coûtent cher (et comment les éviter)
Module 6  → Réagir sans panique en cas de crevaison ou panne
Module 7  → Ton carnet d'entretien zen
Module 8  → Écoute ta voiture, elle te parle
Module 9  → Prépare-toi à partir sereinement
Module 10 → Ton mental de conducteur zen
```

### 10 Bonus

```
#1  Audio "Panne, pas de panique"    → Débloqué après Étape 2  ⏳ À créer
#2  PDF Entretien 12 mois            → Débloqué après Étape 4  ⏳ À créer
#3  Groupe privé WhatsApp            → Débloqué après Étape 3
#4  Checklist Entretien Simple       → Disponible dès départ   ✅
#5  Dictionnaire du Garagiste        → Disponible dès départ   ✅
    (Thermique 11 sections + Hybride/Électrique 7 sections + Index A-Z)
#6  Kit de Survie Voiture            → Débloqué après Étape 3  ✅
#7  Fiche Remorquage & Crochet       → Débloqué après Étape 4  ✅
#8  Drive Zen (10 situations urgence)→ Débloqué après Étape 4  ✅
    Méthode : REGARDE → PROTÈGE → ALERTE
#9  Rouler Malin (éco-conduite)      → Débloqué après Étape 2  ✅
#10 Boîte Automatique BVA            → Disponible dès départ   ✅
```

### Emplacements images (à créer avec ChatGPT)

```
IMAGE_HERO_01       → Accueil    : Conductrice sereine au volant, ambiance sombre cinématique
IMAGE_MODULE0_01    → Mindset    : Conducteur confiant, lumière chaude, route devant lui
IMAGE_MODULE0_02    → Mindset    : Moteur froid, main stop, style flat rouge/sombre
IMAGE_ETAPE1_01     → Étape 1   : Carte grise française sur table sombre avec stylo
IMAGE_ETAPE1_02     → Étape 1   : Schéma annoté carte grise (zones D1/D2/E/P3/J1/F2)
IMAGE_ETAPE1_03     → Étape 1   : 4 icônes motorisation flat (essence/diesel/hybride/élec)
IMAGE_ETAPE2_01     → Étape 2   : Voiture vue dessus + flèche horaire + 5 sens
IMAGE_ETAPE2_02     → Étape 2   : Erreurs communes conducteur débutant
IMAGE_ETAPE3_01     → Étape 3   : Photo compartiment moteur annoté (6 zones)
IMAGE_ETAPE3_02     → Étape 3   : Schéma simplifié compartiment moteur
IMAGE_ETAPE3_03     → Étape 3   : Tableau voyants ↔ zones moteur
IMAGE_ETAPE4_01     → Étape 4   : Grille 10 erreurs idiotes (icônes flat)
IMAGE_ETAPE4_02     → Étape 4   : Comparatif entretien/conséquences/prix
IMAGE_ETAPE4_03     → Étape 4   : Calendrier mensuel avec 5 vérifications
IMAGE_ETAPE5_01     → Étape 5   : Conductrice calme en discussion avec garagiste
IMAGE_ETAPE5_02     → Étape 5   : Infographie phrases clés par situation garagiste
IMAGE_ETAPE5_03     → Étape 5   : Checklist contrôle technique (10 points)
IMAGE_BONUS_01      → Bonus     : Coffre aux trésors avec icônes auto
IMAGE_APP_BANNER_01 → Partout   : Mockup smartphone app Mécano à Bord
```

### Emplacements vidéos (à filmer par Pascal)

```
VIDEO_MODULE0_01 → 3-5 min  → Pascal se présente, philosophie, transformation promise
VIDEO_ETAPE1_01  → 5-7 min  → Lire la carte grise zone par zone (Pascal tient la carte grise)
VIDEO_ETAPE1_02  → 2-3 min  → L'ordinateur de bord expliqué (Pascal montre le tableau de bord)
VIDEO_ETAPE2_01  → 7-10 min → Les 10 réflexes essentiels démontrés en extérieur
VIDEO_ETAPE2_02  → 3 min    → Démonstration Tour de 30 Secondes en temps réel
VIDEO_ETAPE3_01  → 8-10 min → Découverte compartiment moteur sur une vraie voiture
VIDEO_ETAPE4_01  → 8-10 min → Les 10 erreurs idiotes avec exemples et coûts réels
VIDEO_ETAPE4_02  → 5 min    → Démonstration routine 5 minutes par mois
VIDEO_ETAPE5_01  → 8-10 min → Jeu de rôle conducteur/garagiste (Pascal joue les 2 rôles)
VIDEO_BONUS_01   → 10-15min → Drive Zen — 10 situations d'urgence sur route
```
**Total : 10 vidéos — environ 60-80 minutes de contenu**

### Fonctionnalités techniques requises

```
→ Navigation SPA (sans rechargement de page)
→ Progression sauvegardée en localStorage
→ Déblocage progressif des étapes après quiz validé
→ Quiz : 5 questions minimum par étape
   Score ≥ 3/5 → débloque étape suivante
   Score < 3/5 → propose de revoir la leçon
→ Boutons téléchargement PDF (liens placeholder pour l'instant)
→ Placeholders visuels rouges pour images manquantes
→ Placeholders sombres pour vidéos manquantes
→ 100% Responsive (PC 1200px / Tablette 768px / Mobile 375px)
→ Menu fixe en haut sur toutes les pages
→ Bannière permanente lien vers app Mécano à Bord
```

### Structure fichiers formation web

```
formation-web/
├── index.html
└── assets/
    ├── images/
    │   ├── hero/
    │   ├── module0/
    │   ├── etape1/
    │   ├── etape2/
    │   ├── etape3/
    │   ├── etape4/
    │   ├── etape5/
    │   └── bonus/
    ├── videos/
    └── pdfs/
```

---

## LIEN ENTRE LES DEUX PROJETS

```
Formation → App Mobile :
Étape 1  → Profil véhicule + Boîte à gants
Étape 2  → Coach vocal + Tour visuel
Étape 3  → Lecture OBD + Voyants traduits
Étape 4  → Mode surveillance + Alertes + Rappels entretien
Étape 5  → IA conversationnelle + Historique diagnostics
Drive Zen→ Coach vocal d'urgence + Bouton panne
Carnet Zen→ Carnet d'entretien numérique + Boîte à gants

App Mobile → Formation :
→ Bouton dans l'app : "Accéder à la formation"
→ URL actuelle placeholder : https://mecanoabord.systeme.io/formation
→ URL finale : https://mecanoabord.fr/formation (quand app web prête)
```

---

## PHRASES CLÉS DE PASCAL (à utiliser dans la formation)

```
"Quand tu comprends ta voiture, tu apprends à la faire durer."
"Un contrôle, c'est 2 minutes. Une casse, c'est 2 000 euros."
"Ton moteur te pardonne tout, sauf l'oubli."
"Chaque pièce oubliée te rappelle son existence... mais toujours trop tard."
"Un conducteur informé n'est plus un client perdu."
"Comprendre ≠ réparer soi-même. Comprendre = décider calmement."
"Je ne t'apprends pas la mécanique, je t'apprends à parler le même langage que ta voiture."
"Ton moteur a un prénom. Apprends à le connaître."
"La mécanique, ce n'est pas une affaire de cambouis.
 C'est une affaire de bon sens, de régularité et de respect."
"Être Mécano à Bord, c'est être maître de sa route."
"Respire. Allume tes warnings. Tu n'es pas seul(e)."
"Tu ne deviens pas mécanicien. Tu deviens malin."
"Ce que tu notes, tu maîtrises."
"Dans 30 jours, tu ne verras plus ta voiture comme avant."
```

---

## RÈGLES DE TRAVAIL POUR CLAUDE CODE

```
1. Toujours expliquer ce qu'on va faire AVANT de le faire
2. Travailler un fichier à la fois
3. Montrer le résultat après chaque modification
4. Ne jamais modifier app-mobile/ sans accord explicite de Pascal
5. Pour la formation-web/ → créer d'abord la structure, puis index.html section par section
6. Placer les placeholders visuels dès le départ pour toutes les images et vidéos
7. Tester que la navigation fonctionne après chaque section ajoutée
8. Sauvegarder régulièrement et rappeler à Pascal de sauvegarder aussi
9. Langage simple — Pascal est électromécanicien, pas développeur
10. Si une erreur survient → diagnostiquer AVANT de modifier quoi que ce soit
```

---

## PROCHAINES ÉTAPES PRIORITAIRES

### Cette semaine :
```
1. ✅ Préparer CLAUDE.md (ce fichier)
2. ⏳ Lancer Claude Code et créer formation-web/index.html
3. ⏳ Générer les images avec ChatGPT (19 images)
4. ⏳ RDV Inès fin de semaine (missions 1 et 2)
```

### Semaine suivante :
```
5. ⏳ Filmer les vidéos de formation (10 vidéos avec Pascal)
6. ⏳ Intégrer images et vidéos dans la formation web
7. ⏳ Créer comptes YouTube, Facebook, Instagram
8. ⏳ Construire la page de vente sur Systeme.io
```

### Pour ouvrir les ventes :
```
1. Formation web finalisée et hébergée sur mecanoabord.fr
2. APK Release signé (Inès Mission 1)
3. Système de licence Firebase (Inès Mission 2)
4. Page de vente + tunnel Systeme.io
5. Séquence email post-webinaire
```

---

## INFORMATIONS COMPTES ET ACCÈS

```
OVH          : karucards@gmail.com
               Domaines : mecanoabord.fr + mecanoabord.com
Gmail pro    : mecanoabord@gmail.com (à utiliser pour tous les comptes)
Systeme.io   : mecanoabord@gmail.com
GitHub       : configuré sur le PC de Pascal
Workspace    : C:\Users\karuc\OneDrive\Bureau\Mecano A Bord\
```

---

*Fin du fichier CLAUDE.md — Version 1.0 — 06/04/2026*
*© Mécano à Bord — Pascal Chathuant — Guadeloupe*
*Ce fichier est la mémoire permanente de Claude Code.*
*Il est lu automatiquement à chaque nouvelle session.*
