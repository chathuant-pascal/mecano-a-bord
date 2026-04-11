# PRD — Product Requirements Document  
## Mécano à Bord — La Méthode Sans Stress Auto

**Version** : 1.0  
**Dernière mise à jour** : 2026-03-25  
**Référence détaillée** : [CONTEXTE_CLAUDE_MECANO_A_BORD_V6.md](CONTEXTE_CLAUDE_MECANO_A_BORD_V6.md)

---

## 1. Vision et objectifs

| Élément | Description |
|--------|-------------|
| **Nom** | Mécano à Bord |
| **Type** | Application mobile d’assistance automobile |
| **Public cible** | Conducteurs débutants, femmes, jeunes conducteurs, personnes stressées par la mécanique |
| **Objectif principal** | Lire les données OBD du véhicule et les traduire en **langage humain simple, rassurant, sans jargon** |

---

## 2. Périmètre V1 (strict)

### 2.1 Modules inclus

1. Onboarding obligatoire (première ouverture)  
2. Accueil  
3. Connexion OBD (Bluetooth ELM327)  
4. Lecture véhicule à l’arrêt (quick scan)  
5. Résultat simplifié (3 niveaux : vert / orange / rouge)  
6. Explication guidée (optionnelle)  
7. Mode conduite / surveillance (arrière-plan)  
8. Coach vocal (voix féminine OU masculine au choix)  
9. Boîte à gants (historique + documents + carnet d’entretien complet)  
10. Aide & sécurité (accessible partout)  
11. Mode démo (sans véhicule, scénarios vert/orange/rouge)  
12. Réglages (AUTO / MANUEL)  
13. IA conversationnelle (mode gratuit limité + connexion compte IA personnel)

### 2.2 Exclusions V1 (hors scope)

- Pas de GPS intégré  
- Pas de dictionnaire dans l’app  
- Pas de Miroir Garage (décodeur de devis par photo)  
- Pas de réparation mécanique  
- Pas d’explorateur moteur AR  
- Pas de Bulle Anti-Panne audio  
- Pas de formation (vidéos, quiz, badges)

### 2.3 Précision périmètre — carnet d’entretien V1 (livré 2026-03-25)

Le point **§2.1 n°9** (« Boîte à gants … carnet d’entretien complet ») est couvert pour la **V1** par les fonctions suivantes : liste des interventions par véhicule actif ; **ajout** et **modification** d’une intervention ; **suppression** d’une intervention (y compris fichier photo de facture associé) ; **joindre une facture** par prise de photo ou galerie ; **pré-remplissage** des champs « prochain km / prochaine date » selon le type d’entretien (valeurs modifiables) ; **rappels visuels in-app** (accueil et carnet) sur la base du kilométrage et/ou de la date de rappel, y compris lorsque seule la date est renseignée. **Hors périmètre V1** pour ce module : notifications système (barre de statut Android / iOS).

---

## 3. Plateformes et technologies

- **Plateformes** : Android et iOS.  
- **Choix technique actuel** : Flutter (un seul codebase Android + iOS).  
- Référence Kotlin/Android disponible dans la doc pour alternative.

---

## 4. Contraintes produit (résumé)

- **Boîte à gants** = source de vérité unique (profil véhicule, documents, carnet).  
- Sans profil véhicule complet (kilométrage + type de boîte), l’OBD réel ne démarre pas ; mode démo accessible sans profil.  
- Surveillance arrière-plan : arrêt automatique après 60 s sans connexion OBD.  
- IA : mode gratuit (5 questions/jour) + mode personnel (clé API utilisateur, stockée de façon sécurisée).  
- Voix : mots interdits (panne, danger, défaillance, risque grave, erreur fatale) ; ton calme et rassurant.  
- Distribution : gratuit sur stores ; licence à vie via achat externe (site web), vérification Firebase, max 2 appareils par licence.  
- Conformité RGPD ; données locales chiffrées.

---

## 5. Références

- Détails complets, règles de session, tableaux de fichiers : **[CONTEXTE_CLAUDE_MECANO_A_BORD_V6.md](CONTEXTE_CLAUDE_MECANO_A_BORD_V6.md)**  
- Évolution du projet (datée) : **[EVOLUTION.md](EVOLUTION.md)**  
- Tâches et statuts : **[BACKLOG.md](BACKLOG.md)**  
- Décisions techniques : **[NOTES_INTENTION_TECHNIQUES.md](NOTES_INTENTION_TECHNIQUES.md)**

---

*Ce PRD est le document de référence pour le périmètre produit. Toute évolution de scope doit être reflétée ici et datée dans EVOLUTION.md.*
