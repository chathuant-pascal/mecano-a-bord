// Service Worker minimal — formation-web (Mécano à Bord)
//
// Objectif : permettre à un élève qui a déjà ouvert la formation une fois
// de continuer à y accéder (leçons déjà lues, photos déjà vues) même
// sans connexion, ou avec une connexion très instable.
//
// Stratégies (voir le plan validé avec Pascal) :
// - Coquille de l'app (index.html, optin.html) : network-first, repli
//   sur le cache si le réseau échoue. Un élève connecté reçoit toujours
//   la dernière version ; le cache ne sert qu'en secours hors-ligne.
// - Images et fiches PDF (assets/images/*, assets/pdfs/*) : mises en
//   cache à la volée, au moment où elles sont réellement demandées par
//   le navigateur (donc au rythme du lazy loading déjà en place, pas
//   d'un coup à l'installation) — puis cache-first une fois en cache,
//   car ce contenu change rarement.
// - Tout le reste (YouTube, Google Fonts, etc.) : non intercepté, le
//   navigateur gère normalement. Les vidéos YouTube (iframe cross-
//   origine) ne peuvent de toute façon pas être mises en cache par ce
//   Service Worker — elles nécessitent toujours une connexion.
//
// IMPORTANT — à chaque mise à jour notable de index.html ou optin.html,
// changer CACHE_VERSION ci-dessous (ex. 'mab-formation-v2') pour que les
// anciens caches soient nettoyés à l'activation.
const CACHE_VERSION = "mab-formation-v1";

const APP_SHELL = ["./", "./index.html", "./optin.html"];

function estRequeteImageOuPdf(url) {
  return url.pathname.includes("/assets/images/") || url.pathname.includes("/assets/pdfs/");
}

function estRequeteDeNavigation(request) {
  if (request.mode === "navigate") return true;
  return request.destination === "document";
}

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches
      .open(CACHE_VERSION)
      .then(function (cache) {
        // best-effort : une leçon/image manquante ne doit jamais bloquer
        // l'installation du Service Worker
        return Promise.all(
          APP_SHELL.map(function (url) {
            return cache.add(url).catch(function () {});
          })
        );
      })
      .then(function () {
        return self.skipWaiting();
      })
  );
});

self.addEventListener("activate", function (event) {
  event.waitUntil(
    caches
      .keys()
      .then(function (noms) {
        return Promise.all(
          noms
            .filter(function (nom) {
              return nom !== CACHE_VERSION;
            })
            .map(function (nom) {
              return caches.delete(nom);
            })
        );
      })
      .then(function () {
        return self.clients.claim();
      })
  );
});

self.addEventListener("fetch", function (event) {
  var request = event.request;
  if (request.method !== "GET") return;

  var url = new URL(request.url);
  if (url.origin !== self.location.origin) return; // YouTube, Google Fonts, etc. — non intercepté

  if (estRequeteDeNavigation(request) || url.pathname.endsWith(".html")) {
    event.respondWith(reseauPrioritaireAvecRepliCache(request));
    return;
  }

  if (estRequeteImageOuPdf(url)) {
    event.respondWith(cacheAvecRemplissageALaVolee(request));
  }
});

// Coquille de l'app : toujours essayer le réseau d'abord (contenu à jour),
// et alimenter le cache au passage ; si le réseau échoue, servir la
// dernière version connue en cache.
function reseauPrioritaireAvecRepliCache(request) {
  return fetch(request)
    .then(function (reponseReseau) {
      var copie = reponseReseau.clone();
      caches.open(CACHE_VERSION).then(function (cache) {
        cache.put(request, copie);
      });
      return reponseReseau;
    })
    .catch(function () {
      return caches.match(request).then(function (reponseCache) {
        if (reponseCache) return reponseCache;
        // Rien en cache et hors-ligne : on ne peut rien faire de mieux,
        // le navigateur affichera son écran d'erreur réseau habituel.
        return caches.match("./index.html");
      });
    });
}

// Images / fiches PDF : servir depuis le cache si déjà vues, sinon aller
// les chercher sur le réseau et les mettre en cache pour la prochaine
// visite hors-ligne — jamais tout précaché d'un coup.
function cacheAvecRemplissageALaVolee(request) {
  return caches.match(request).then(function (reponseCache) {
    if (reponseCache) return reponseCache;
    return fetch(request).then(function (reponseReseau) {
      var copie = reponseReseau.clone();
      caches.open(CACHE_VERSION).then(function (cache) {
        cache.put(request, copie);
      });
      return reponseReseau;
    });
  });
}
