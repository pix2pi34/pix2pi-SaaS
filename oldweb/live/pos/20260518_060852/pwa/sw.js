/* PIX2PI_334_SERVICE_WORKER_START */
const PIX2PI_POS_PWA_PREFIX = "pix2pi-pos-pwa";
const PIX2PI_POS_PWA_CACHE_VERSION = "pix2pi-pos-pwa-334-20260513_203626";
const PIX2PI_POS_PWA_ASSETS = [
  "/mobile-pos/",
  "/offline-pos/",
  "/offline.html",
  "/manifest.json",
  "/assets/pwa/icon-192.svg",
  "/assets/pwa/icon-512.svg",
  "/assets/pwa/splash.svg"
];

self.addEventListener("install", (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(PIX2PI_POS_PWA_CACHE_VERSION)
      .then((cache) => cache.addAll(PIX2PI_POS_PWA_ASSETS))
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys
          .filter((key) => key.startsWith(PIX2PI_POS_PWA_PREFIX) && key !== PIX2PI_POS_PWA_CACHE_VERSION)
          .map((key) => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET") return;

  event.respondWith(
    fetch(req)
      .then((res) => {
        const copy = res.clone();
        caches.open(PIX2PI_POS_PWA_CACHE_VERSION).then((cache) => cache.put(req, copy));
        return res;
      })
      .catch(() => {
        if (req.mode === "navigate") {
          return caches.match("/offline.html");
        }
        return caches.match(req);
      })
  );
});
/* PIX2PI_334_SERVICE_WORKER_END */
