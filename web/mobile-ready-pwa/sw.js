const PIX2PI_PWA_CACHE = "pix2pi-mobile-ready-pwa-v1";

const PIX2PI_PWA_ASSETS = [
  "./",
  "./index.html",
  "./manifest.webmanifest"
];

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches.open(PIX2PI_PWA_CACHE).then(function (cache) {
      return cache.addAll(PIX2PI_PWA_ASSETS);
    })
  );
  self.skipWaiting();
});

self.addEventListener("activate", function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(
        keys
          .filter(function (key) {
            return key !== PIX2PI_PWA_CACHE;
          })
          .map(function (key) {
            return caches.delete(key);
          })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener("fetch", function (event) {
  if (event.request.method !== "GET") {
    return;
  }

  event.respondWith(
    caches.match(event.request).then(function (cachedResponse) {
      if (cachedResponse) {
        return cachedResponse;
      }

      return fetch(event.request).catch(function () {
        return caches.match("./index.html");
      });
    })
  );
});
