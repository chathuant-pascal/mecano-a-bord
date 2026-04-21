// ======================================================
// URLs Formation — lib/formation_url.dart
// → Pour basculer en prod : changer kFormationUrl = kFormationUrlProd
// ======================================================

/// URL GitHub Pages (active tant que mecanoabord.fr n'est pas prêt)
const String kFormationUrlGithub =
    'https://chathuant-pascal.github.io/mecano-a-bord/formation-web/index.html';

/// URL production (à activer quand mecanoabord.fr est prêt + CNAME OVH configuré)
const String kFormationUrlProd = 'https://mecanoabord.fr/formation';

/// URL active — changer cette ligne uniquement pour basculer
const String kFormationUrl = kFormationUrlGithub;
