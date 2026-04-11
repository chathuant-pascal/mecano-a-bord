# MÉCANO À BORD — Fichier de contexte pour Claude
# À transmettre à Claude en début de nouvelle conversation
# Version 6.0 — Mise à jour du 20/02/2026

---

## RÈGLE DE SESSION

À intervalles réguliers (après chaque étape importante), Claude met à jour ce fichier de contexte
et le propose en téléchargement à Pascal. En cas de coupure de session, Pascal repart de ce fichier.

---

## QUI EST L'UTILISATEUR

Prénom : Pascal (Pascal Chathuant)
Profil : Électromécanicien avec 25+ ans d'expérience. Porteur du projet Mécano à Bord.
Niveau tech : Débutant complet en programmation.
Historique : A travaillé avec ChatGPT (assistant "Elina") pour préparer la documentation et une base de code.
Développeuse : Inès (freelance) — en attente du dossier complet.
Mode de travail : Guidé pas à pas, explications simples, sans jargon. Fichiers livrés un par un, téléchargeables.

---

## DESCRIPTION DU PROJET

Nom : Mécano à Bord — La Méthode Sans Stress Auto
Type : Application mobile d'assistance automobile
Public cible : Conducteurs débutants, femmes, jeunes conducteurs, personnes stressées par la mécanique
Objectif : Lire les données OBD du véhicule et les traduire en langage humain simple, rassurant, sans jargon

---

## PÉRIMÈTRE V1 (ce qu'Inès doit livrer — strictement)

### Modules inclus en V1
1. Onboarding obligatoire (première ouverture)
2. Accueil
3. Connexion OBD (Bluetooth ELM327)
4. Lecture véhicule à l'arrêt (quick scan)
5. Résultat simplifié (3 niveaux : vert / orange / rouge)
6. Explication guidée (optionnelle)
7. Mode conduite / surveillance (arrière-plan)
8. Coach vocal (voix féminine OU masculine au choix)
9. Boîte à gants (historique + documents + carnet d'entretien complet)
10. Aide & sécurité (accessible partout)
11. Mode démo (sans véhicule, scénarios vert/orange/rouge)
12. Réglages (AUTO / MANUEL)
13. IA conversationnelle (mode gratuit limité + connexion compte IA personnel)

### Exclusions V1 (hors scope)
- Pas de GPS intégré
- Pas de dictionnaire dans l'app
- Pas de Miroir Garage (décodeur de devis par photo)
- Pas de réparation mécanique
- Pas d'explorateur moteur AR
- Pas de Bulle Anti-Panne audio
- Pas de formation (vidéos, quiz, badges)

---

## DÉCISIONS TECHNIQUES IMPORTANTES

### Compatibilité plateforme
- Android ET iOS
- Deux versions de chaque fichier :
  * Version Kotlin (Android Studio) → dossier Android_Kotlin
  * Version Flutter/Dart (Android + iOS) → dossier Flutter_iOS_Android
- Inès choisira la technologie qu'elle maîtrise (ne pas lui imposer)

### Architecture générale
- MVVM (Model-View-ViewModel)
- Boîte à gants = source de vérité unique
- Base de données locale Room (SQLite) + chiffrement (SQLCipher / Android Keystore)
- Sans profil véhicule complet (kilométrage + type de boîte), l'OBD réel ne démarre pas
- Mode démo accessible sans profil
- Surveillance arrière-plan : Foreground Service (Android) / Background Task (iOS)
- Arrêt automatique après 60s sans connexion OBD
- Alertes rouges toujours protégées (non effaçables)

### IA conversationnelle (V1)
- Mode IA gratuite intégrée (par défaut, 5 questions/jour, réponses locales par mots-clés)
- Mode IA personnelle : l'utilisateur connecte son propre compte (clé API chiffrée sur l'appareil)
- Multi-IA : ChatGPT (OpenAI), Gemini (Google)
- Aucune IA payante fournie par l'application elle-même
- Clé API stockée via EncryptedSharedPreferences (Android) / Keychain (iOS)

### Voix
- Voix féminine OU masculine (choix utilisateur dans les réglages)
- Messages courts, calmes, non anxiogènes
- Mots interdits : panne, danger, défaillance, risque grave, erreur fatale
- Cooldown 30 secondes entre deux alertes vocales

### Distribution et licence
- Téléchargement gratuit Google Play + App Store
- Activation par achat externe (site web) — aucun paiement via les stores
- Licence à vie liée à un compte utilisateur
- Maximum 2 appareils par licence
- Vérification Firebase régulière (côté serveur — JAMAIS uniquement en local)
- Identifiant unique par appareil (hash SHA-256 anonyme)

### Sécurité & Confidentialité
- Données stockées localement, chiffrées
- Aucune donnée transmise sans consentement
- Conformité RGPD

---

## TABLEAU COMPLET DE TOUS LES FICHIERS DE CODE

### Fichiers de référence (fournis par ChatGPT/Elina — à utiliser tels quels)
| Fichier | Contenu | Statut |
|---|---|---|
| mab_integration_contracts_v1.kt | Contrats/interfaces entre modules | ✅ Référence principale |
| mab_glovebox_schema_v1.json | Schéma données Boîte à gants | ✅ Référence |
| MabOrchestratorImpl.kt | Orchestrateur principal | ✅ Utilisable |
| UrgencePolicy.kt | Règles messages d'urgence | ✅ Utilisable |
| DtcCatalog.kt | Catalogue codes DTC en français | ✅ Utilisable |
| VoiceAlertManager.kt | Alertes vocales TTS | ✅ Utilisable |
| InMemoryGloveboxStore.kt | Stockage temporaire mémoire | ✅ Utilisable |
| dtc_fr_starter.json | Base DTC français (simplifiée) | ✅ Utilisable |
| dtc_fr_extended.json | Base DTC français (complète) | ✅ Utilisable |

### Fichiers de code créés ensemble (sessions V1 → V6) — TOUS TERMINÉS ✅
| Fichier Android Kotlin | Fichier Flutter Dart | Contenu | Statut |
|---|---|---|---|
| AdviceEngine.kt | advice_engine.dart | Moteur traduction OBD → langage humain | ✅ |
| MabDatabase.kt | mab_database.dart | Base de données locale raccordée | ✅ |
| MaintenanceEntry.kt | maintenance_entry.dart | Carnet d'entretien | ✅ |
| FirebaseLicenceManager.kt | firebase_licence_manager.dart | Auth Firebase + licence | ✅ |
| MabRepository.kt | mab_repository.dart | Pont BDD / application | ✅ |
| MonitoringForegroundService.kt | monitoring_background_service.dart | Surveillance arrière-plan | ✅ |
| BluetoothObdService.kt | bluetooth_obd_service.dart | Connexion Bluetooth ELM327 | ✅ |
| AiConversationService.kt | ai_conversation_service.dart | Module IA (gratuit + personnel) | ✅ |
| OnboardingActivity.kt | onboarding_screen.dart | Écran onboarding (4 pages) | ✅ |
| HomeActivity.kt | home_screen.dart | Écran accueil + navigation | ✅ |
| ObdScanActivity.kt | obd_scan_screen.dart | Écran OBD (connexion+scan+résultat) | ✅ |
| GloveboxActivity.kt | glovebox_screen.dart | Boîte à gants (4 onglets) | ✅ |
| SettingsActivity.kt | settings_screen.dart | Écran réglages (4 sections) | ✅ |
| AiChatActivity.kt | ai_chat_screen.dart | Écran chat IA (bulles + quota) | ✅ |
| MainActivity.kt | main.dart | Point d'entrée + splash + routage | ✅ |
| GloveboxProfileActivity.kt | glovebox_profile_screen.dart | Formulaire profil véhicule | ✅ |
| AddMaintenanceActivity.kt | add_maintenance_screen.dart | Ajout entretien carnet | ✅ |
| DiagnosticDetailActivity.kt | diagnostic_detail_screen.dart | Détail session diagnostic | ✅ |

### Documents produits (non-code)
| Document | Contenu | Statut |
|---|---|---|
| MAB_Dossier_Pour_Ines_V1.docx | Dossier complet pour la développeuse Inès | ✅ Prêt |
| MAB_Spec_Carnet_Entretien_V1.docx | Spécification carnet d'entretien | ✅ Créé |
| MAB_Logos_Android_iOS_V1.zip | Logos toutes tailles + splash screen | ✅ Créé |

### Fichiers à écarter (versions anciennes ou contradictoires)
| Fichier | Raison |
|---|---|
| Dossier_Technique_Developpeur.pdf | Ancienne architecture contradictoire |
| GloveboxModels.kt | Remplacé par contracts_v1.kt |
| BlackBoxCoordinator.kt | Utilise l'ancienne GloveboxState |

### Fichiers hors scope V1 (à garder pour V2+)
| Fichier | Module |
|---|---|
| OcrService.kt | Miroir Garage (V2+) |
| prompts_offline.json | Boîte Noire IA (V2+) |
| prompts_online.json | Boîte Noire IA (V2+) |
| mg_keywords_base_v1.json | Miroir Garage (V2+) |

---

## ÉTAT D'AVANCEMENT V1

### ✅ TOUS LES FICHIERS DE CODE V1 SONT TERMINÉS

La totalité des fichiers nécessaires à la version V1 ont été créés dans les deux versions
(Android Kotlin ET Flutter iOS+Android).

### Prochaines étapes possibles
1. Préparer un ZIP complet de tous les fichiers pour Inès
2. Mettre à jour le dossier pour Inès (MAB_Dossier_Pour_Ines) avec les nouveaux fichiers
3. Commencer les fichiers V2+ (Miroir Garage, Bulle Anti-Panne, etc.)
4. Créer les fichiers de layout XML Android (les "habillages visuels" des écrans)
5. Créer les fichiers de test unitaire

---

## RÈGLES DE TRAVAIL AVEC PASCAL

- Toujours expliquer chaque fichier en langage simple APRÈS l'avoir créé
- Toujours proposer les deux versions (Kotlin ET Flutter) pour chaque fichier
- Livrer un fichier à la fois, téléchargeable
- Ne jamais utiliser de jargon technique sans l'expliquer
- Tenir à jour le tableau des fichiers créés / restants à chaque étape
- Rappeler à Pascal de sauvegarder les fichiers dans un dossier "Mécano à Bord - Fichiers Code"
- Mettre à jour ce fichier de contexte régulièrement et le proposer en téléchargement

---

Fin du fichier de contexte — Version 6.0 du 20/02/2026
