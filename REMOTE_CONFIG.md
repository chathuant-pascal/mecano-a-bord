# Kill switch à distance — Firebase Remote Config

Ce document explique comment désactiver une fonctionnalité de l'app **à distance, sans recompiler ni republier sur les stores**, en cas de bug critique détecté après publication.

Le code correspondant est dans :
- `mecano_a_bord/lib/services/remote_feature_flags.dart` — lit les valeurs distantes
- `mecano_a_bord/lib/config/mab_features.dart` — valeurs de repli si Remote Config est injoignable

---

## Liste des clés Remote Config

À créer dans le projet Firebase `mecano-a-bord` (Firebase Console → Remote Config), de type **Boolean** (une clé texte s'ajoute plus bas) :

| Clé Remote Config | Fonctionnalité couverte | Valeur par défaut (repli) |
|---|---|---|
| `feature_obd` | Diagnostic OBD Bluetooth (bouton menu + bandeau accueil) | `true` |
| `feature_surveillance` | Mode Conduite / surveillance temps réel (écran + démarrage auto en arrière-plan) | `true` |
| `feature_tts` | Coach vocal (toutes les annonces + réglages voix) | `true` |
| `feature_formation` | Formation obligatoire après onboarding + lien "La méthode sans stress auto" | `true` |
| `feature_ia` | Assistant IA conversationnel | `true` |
| `feature_plaque` | Recherche automatique du véhicule par plaque | `true` |
| `feature_licence` | Écran de vérification de licence au démarrage | `true` |
| `feature_carnet_entretien` | Onglet Carnet d'entretien (Boîte à gants) | `true` |
| `feature_documents` | Onglet Documents (Boîte à gants) | `true` |
| `feature_sante_vehicule` | Onglet Santé véhicule (Boîte à gants) | `true` |
| `feature_mise_a_jour` | Vérification de mise à jour au démarrage de l'accueil | `true` |
| `feature_rappels_admin` | **Réservé — aucune fonctionnalité correspondante n'est implémentée à ce jour.** Ce flag n'a actuellement aucun effet dans l'app. | `true` |
| `feature_tutoriels` | Clé maîtresse des tutoriels vidéo (écran Tutoriels, carte d'accueil « Bien démarrer », tous les liens « Voir comment faire », proposition au premier lancement). Coupée : le bouton Aide & contact ouvre directement la chaîne YouTube au lieu de l'écran Tutoriels. | `true` |

Si une clé n'existe pas encore dans la console Firebase (avant sa première création), l'app utilise automatiquement la valeur de repli codée dans `mab_features.dart` — aucun risque à ajouter les clés progressivement.

---

## Clé Remote Config de type texte (String)

| Clé Remote Config | Type | Rôle | Valeur par défaut (repli) |
|---|---|---|---|
| `discord_invite_url` | **String** | URL d'invitation du serveur Discord « Mécano à Bord — Communauté ». Pilote l'affichage du bouton **« Rejoindre la communauté »** sur l'accueil. | `""` (chaîne vide) |

Comportement :

- Le bouton n'apparaît sur l'accueil **que si** l'élève a validé le **Module 6** de la formation **ET** que `discord_invite_url` contient une invitation Discord valide (`https://discord.gg/…` ou `https://discord.com/invite/…`).
- Valeur vide, absente, illisible, non-HTTPS, ou hôte autre que Discord ⇒ bouton **totalement masqué** (jamais de lien cassé). C'est aussi le **kill switch** : vider la valeur et publier fait disparaître le bouton chez tout le monde (délai de propagation habituel, voir plus bas).
- Pour publier l'URL : **Remote Config → Ajouter un paramètre → nom `discord_invite_url` → type `String` → coller l'URL d'invitation permanente du serveur → Publier les modifications.**
- Générer une invitation **permanente** dans Discord (Paramètres du salon → Inviter → « Modifier le lien d'invitation » → Expiration : *Jamais*, Nombre max d'utilisations : *Illimité*).

---

## Tutoriels vidéo — clés URL et durée (String)

10 clés, une paire (URL + durée) par tutoriel. Aucune n'est un flag on/off — c'est `feature_tutoriels` (tableau ci-dessus) qui coupe toute la fonctionnalité.

| Clé Remote Config | Tutoriel | Valeur par défaut |
|---|---|---|
| `tutoriel_boitier_url` | 1. Brancher ton boîtier | `""` |
| `tutoriel_boitier_duree` | 1. Brancher ton boîtier | `""` |
| `tutoriel_surveillance_url` | 2. Surveiller ta voiture en roulant | `""` |
| `tutoriel_surveillance_duree` | 2. Surveiller ta voiture en roulant | `""` |
| `tutoriel_alerte_url` | 3. Quand l'app t'alerte | `""` |
| `tutoriel_alerte_duree` | 3. Quand l'app t'alerte | `""` |
| `tutoriel_entretien_url` | 4. Ton carnet d'entretien et tes rappels | `""` |
| `tutoriel_entretien_duree` | 4. Ton carnet d'entretien et tes rappels | `""` |
| `tutoriel_glovebox_url` | 5. Ta boîte à gants | `""` |
| `tutoriel_glovebox_duree` | 5. Ta boîte à gants | `""` |

Comportement :

- `tutoriel_xxx_url` vide ⇒ la carte du tutoriel correspondant affiche **« Bientôt disponible »** dans l'écran Tutoriels et le lien contextuel « Voir comment faire » associé reste **masqué** ailleurs dans l'app (jamais de lien mort).
- `tutoriel_xxx_duree` vide ⇒ aucune durée affichée sur la carte (le champ est purement indicatif, ex. `"1 min 30"`).
- La proposition au premier lancement (juste après l'activation de la licence) ne s'affiche que si `tutoriel_boitier_url` est renseignée — sinon rien, la carte d'accueil « Bien démarrer » prend le relais seule.
- Vidéos hébergées en **YouTube non répertorié** ; l'app les ouvre dans YouTube/le navigateur externe (pas de lecteur intégré) via `url_launcher` — mêmes principes que `discord_invite_url` ci-dessus (aucune tentative sans réseau détecté, message clair à la place).

---

## Comment couper une fonctionnalité depuis la console Firebase

1. Ouvrir [console.firebase.google.com](https://console.firebase.google.com) → projet **mecano-a-bord**.
2. Dans le menu de gauche : **Engagement** → **Remote Config**.
3. Si la clé existe déjà : cliquer sur la ligne du paramètre (ex. `feature_ia`) → modifier la valeur à `false` → **Publier les modifications**.
4. Si la clé n'existe pas encore : **Ajouter un paramètre** → nom = la clé exacte du tableau ci-dessus (ex. `feature_obd`) → type **Boolean** → valeur par défaut → **Enregistrer** → **Publier les modifications**.
5. Pour réactiver : remettre la valeur à `true` et publier à nouveau.

⚠️ Toujours cliquer sur **Publier les modifications** — une valeur simplement saisie sans publication n'est jamais envoyée aux appareils.

---

## Délai de propagation réel

- L'app vérifie Remote Config **au maximum une fois par heure** par appareil (`minimumFetchInterval = 1h`, dans `remote_feature_flags.dart`).
- Concrètement : après avoir publié un changement dans la console, un appareil qui a déjà l'app ouverte depuis moins d'1h **ne verra pas le changement immédiatement**. Il faut soit :
  - attendre jusqu'à 1h (le prochain fetch silencieux le récupère automatiquement), soit
  - que l'utilisateur ferme et rouvre complètement l'app (un nouveau démarrage relance le fetch).
- **Exception** : l'écran de formation bloquant (si `feature_formation` est coupé) propose un bouton **"Réessayer"** qui force un nouveau fetch immédiat, sans attendre l'heure — utile en cas d'incident en cours pendant que quelqu'un finit l'onboarding.
- En résumé : prévoir **jusqu'à 1h** avant qu'un changement soit vu par tous les utilisateurs déjà connectés, potentiellement immédiat pour les nouveaux lancements d'app.

---

## Limites connues

- **`feature_rappels_admin` n'a aucun effet aujourd'hui.** Aucune fonctionnalité de rappels administratifs (contrôle technique, assurance, etc.) n'est implémentée dans le code actuel — seuls les rappels d'entretien (`feature_carnet_entretien`) et les échéances de documents (`feature_documents`) existent. Ce flag est réservé pour une future évolution.
- **Remote Config ne fonctionne que sur Android pour l'instant**, comme le reste de l'intégration Firebase du projet (licences, analytics) — `firebase_options.dart` n'a pas encore de configuration iOS. Quand iOS sera provisionné, Remote Config fonctionnera automatiquement sans changement de code.
- Si Remote Config est injoignable (hors ligne, erreur réseau, ou avant le tout premier fetch réussi), l'app utilise silencieusement les valeurs de repli de `mab_features.dart` (toutes à `true` actuellement) — jamais de plantage, jamais de blocage inattendu.
