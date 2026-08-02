# Kill switch à distance — Firebase Remote Config

Ce document explique comment désactiver une fonctionnalité de l'app **à distance, sans recompiler ni republier sur les stores**, en cas de bug critique détecté après publication.

Le code correspondant est dans :
- `mecano_a_bord/lib/services/remote_feature_flags.dart` — lit les valeurs distantes
- `mecano_a_bord/lib/config/mab_features.dart` — valeurs de repli si Remote Config est injoignable

---

## Liste des clés Remote Config

À créer dans le projet Firebase `mecano-a-bord` (Firebase Console → Remote Config), toutes de type **Boolean** :

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

Si une clé n'existe pas encore dans la console Firebase (avant sa première création), l'app utilise automatiquement la valeur de repli codée dans `mab_features.dart` — aucun risque à ajouter les clés progressivement.

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
