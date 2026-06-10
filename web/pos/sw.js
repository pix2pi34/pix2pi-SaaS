/* PIX2PI_334_POS_SERVICE_WORKER_START */
const PIX2PI_PWA_CACHE_NAME = "pix2pi-pos-pwa-v334";
const PIX2PI_PWA_CACHE_STRATEGY = "CACHE_FIRST_STATIC_NETWORK_FALLBACK";
const PIX2PI_PWA_OFFLINE_FALLBACK = "/offline-fallback.html";
const PIX2PI_PWA_CACHE_ALLOWLIST = [
  "/",
  "/login/",
  "/sale/",
  "/checkout/",
  "/offline/",
  "/pwa/",
  "/manifest.json",
  "/offline-fallback.html",
  "/assets/pwa/pos-pwa-runtime.js",
  "/assets/pwa/icon-192-placeholder.svg",
  "/assets/pwa/icon-512-placeholder.svg"
];

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches.open(PIX2PI_PWA_CACHE_NAME).then(function (cache) {
      return cache.addAll(PIX2PI_PWA_CACHE_ALLOWLIST);
    }).then(function () {
      return self.skipWaiting();
    })
  );
});

self.addEventListener("activate", function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.map(function (key) {
        if (key !== PIX2PI_PWA_CACHE_NAME) {
          return caches.delete(key);
        }
        return Promise.resolve();
      }));
    }).then(function () {
      return self.clients.claim();
    })
  );
});

self.addEventListener("fetch", function (event) {
  if (event.request.method !== "GET") {
    return;
  }

  event.respondWith(
    caches.match(event.request).then(function (cached) {
      if (cached) return cached;

      return fetch(event.request).then(function (response) {
        const responseClone = response.clone();

        if (response && response.ok && event.request.url.indexOf(self.location.origin) === 0) {
          caches.open(PIX2PI_PWA_CACHE_NAME).then(function (cache) {
            cache.put(event.request, responseClone);
          });
        }

        return response;
      }).catch(function () {
        if (event.request.mode === "navigate") {
          return caches.match(PIX2PI_PWA_OFFLINE_FALLBACK);
        }
        return caches.match(PIX2PI_PWA_OFFLINE_FALLBACK);
      });
    })
  );
});
/* PIX2PI_334_POS_SERVICE_WORKER_END */
