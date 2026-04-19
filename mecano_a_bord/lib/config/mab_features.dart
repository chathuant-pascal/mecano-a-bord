// =============================================================================
// Feature flags Mécano à Bord — MODULE 6
//
// Rôle : centraliser des interrupteurs (booléens) pour activer ou désactiver des
// blocs fonctionnels sans supprimer le code. Utile pour des bascules progressives,
// des tests, ou une préparation Play Store (ex. licence Firebase).
//
// Usage prévu : importer ce fichier et tester `if (kFeatureXxx) { ... }` avant
// d’exposer une route, un écran ou un service. Tant qu’aucun appel n’utilise ces
// constantes, elles documentent seulement l’intention produit.
// =============================================================================

/// Connexion OBD / diagnostic véhicule (Bluetooth, lecture codes, etc.).
const bool kFeatureOBD = true;

/// Surveillance / mode conduite (alertes, capteurs, services associés).
const bool kFeatureSurveillance = true;

/// Coach vocal TTS (annonces, réglages voix).
const bool kFeatureTTS = true;

/// Parcours formation (WebView, lien externe, déblocage après formation).
const bool kFeatureFormation = true;

/// Assistant IA conversationnel (clés API, quota, écrans chat).
const bool kFeatureIA = true;

/// Récupération / affichage données véhicule via plaque (API gouv, etc.).
const bool kFeaturePlaque = true;

/// Système de licence / activation (Firebase, code MAB) — prévu avec Inès (Mission 2).
const bool kFeatureLicence = false;

/// Carnet d’entretien (entrées, rappels kilométriques / dates).
const bool kFeatureCarnetEntretien = true;

/// Boîte à gants — documents et pièces jointes utilisateur.
const bool kFeatureDocuments = true;

/// Santé véhicule / indicateurs et onglets associés dans la Boîte à gants.
const bool kFeatureSanteVehicule = true;

/// Vérification de mise à jour de l’app (store / lien).
const bool kFeatureMiseAJour = true;

/// Rappels administratifs / échéances liées au véhicule (selon implémentation).
const bool kFeatureRappelsAdmin = true;
