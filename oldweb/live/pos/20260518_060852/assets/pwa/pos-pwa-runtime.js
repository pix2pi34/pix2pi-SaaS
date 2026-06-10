/* PIX2PI_334_POS_PWA_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "pos_mobile_pwa",
    phase: "FAZ_7R",
    step: "334",
    manifestPath: "/manifest.json",
    serviceWorkerPath: "/sw.js",
    offlineFallbackPath: "/offline-fallback.html",
    selectedTenantKey: "pix2pi.pos.tenant.preference",
    deviceKey: "pix2pi.pos.device.id",
    cashierSessionKey: "pix2pi.pos.cashier.session",
    offlineQueueKey: "pix2pi.pos.offline.queue",
    pwaContract: {
      display: "standalone",
      orientation: "portrait",
      installPromptEnabled: true,
      serviceWorkerRegistrationEnabled: true,
      productionOfflineReplayEnabled: false,
      productionPaymentFinalizeEnabled: false,
      readyForStep335: true
    },
    cacheStrategy: {
      strategy: "CACHE_FIRST_STATIC_NETWORK_FALLBACK",
      offlineFallback: "/offline-fallback.html",
      cacheAllowlist: [
        "/",
        "/login/",
        "/sale/",
        "/checkout/",
        "/offline/",
        "/pwa/",
        "/manifest.json",
        "/offline-fallback.html"
      ]
    }
  };

  let deferredInstallPrompt = null;

  function getSelectedTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || "controlled-pilot";
  }

  function getDeviceId() {
    return window.localStorage.getItem(CONFIG.deviceKey) || "NO_DEVICE_REGISTERED";
  }

  function getCashierSession() {
    const raw = window.localStorage.getItem(CONFIG.cashierSessionKey);
    if (!raw) return null;

    try {
      return JSON.parse(raw);
    } catch (_error) {
      return null;
    }
  }

  function getOfflineQueueCount() {
    const raw = window.localStorage.getItem(CONFIG.offlineQueueKey);
    if (!raw) return 0;

    try {
      const queue = JSON.parse(raw);
      return Array.isArray(queue) ? queue.length : 0;
    } catch (_error) {
      return 0;
    }
  }

  function getPWAStandaloneStatus() {
    const standaloneMedia = window.matchMedia && window.matchMedia("(display-mode: standalone)").matches;
    const iosStandalone = Boolean(window.navigator.standalone);
    return {
      standalone: Boolean(standaloneMedia || iosStandalone),
      display_mode: standaloneMedia ? "standalone" : "browser",
      ios_standalone: iosStandalone
    };
  }

  function buildSessionPreservationSnapshot() {
    const session = getCashierSession();

    return {
      tenant_id: getSelectedTenantId(),
      device_id: getDeviceId(),
      cashier_code: session && session.cashier_code ? session.cashier_code : null,
      cashier_session_present: Boolean(session),
      offline_queue_count: getOfflineQueueCount(),
      pwa_standalone: getPWAStandaloneStatus(),
      source: {
        surface: "pos_mobile_pwa",
        phase: "FAZ_7R",
        step: "334"
      }
    };
  }

  async function registerServiceWorker() {
    if (!CONFIG.pwaContract.serviceWorkerRegistrationEnabled) {
      return { registered: false, reason: "SERVICE_WORKER_REGISTRATION_DISABLED" };
    }

    if (!("serviceWorker" in navigator)) {
      return { registered: false, reason: "SERVICE_WORKER_NOT_SUPPORTED" };
    }

    try {
      const registration = await navigator.serviceWorker.register(CONFIG.serviceWorkerPath, {
        scope: "/"
      });

      return {
        registered: true,
        scope: registration.scope
      };
    } catch (error) {
      return {
        registered: false,
        reason: "SERVICE_WORKER_REGISTER_FAILED",
        message: String(error && error.message ? error.message : error)
      };
    }
  }

  function captureInstallPrompt(event) {
    event.preventDefault();
    deferredInstallPrompt = event;
    renderInstallPromptStatus("READY");
    return event;
  }

  async function requestInstallPrompt() {
    if (!deferredInstallPrompt) {
      return { prompted: false, reason: "INSTALL_PROMPT_NOT_AVAILABLE" };
    }

    deferredInstallPrompt.prompt();
    const choice = await deferredInstallPrompt.userChoice;
    deferredInstallPrompt = null;
    renderInstallPromptStatus(choice.outcome || "DONE");

    return {
      prompted: true,
      outcome: choice.outcome
    };
  }

  function renderInstallPromptStatus(value) {
    const target = document.getElementById("pwa-install-status");
    if (target) target.textContent = value || "WAITING";
  }

  function renderPWAStatus(serviceWorkerResult) {
    const tenant = document.getElementById("pwa-tenant");
    const device = document.getElementById("pwa-device");
    const session = document.getElementById("pwa-session");
    const queue = document.getElementById("pwa-offline-queue-count");
    const standalone = document.getElementById("pwa-standalone-status");
    const sw = document.getElementById("pwa-service-worker-status");

    const snapshot = buildSessionPreservationSnapshot();

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (device) device.textContent = snapshot.device_id;
    if (session) session.textContent = snapshot.cashier_session_present ? "SESSION_PRESENT" : "NO_SESSION";
    if (queue) queue.textContent = String(snapshot.offline_queue_count);
    if (standalone) standalone.textContent = snapshot.pwa_standalone.standalone ? "STANDALONE" : "BROWSER";
    if (sw) sw.textContent = serviceWorkerResult && serviceWorkerResult.registered ? "REGISTERED" : "NOT_REGISTERED";

    document.body.setAttribute("data-pos-pwa-rendered", "true");
    return snapshot;
  }

  async function bootPOSPWAScreen() {
    const sw = await registerServiceWorker();
    return renderPWAStatus(sw);
  }

  window.addEventListener("beforeinstallprompt", captureInstallPrompt);

  window.Pix2piPOSPWA = {
    CONFIG: CONFIG,
    getSelectedTenantId: getSelectedTenantId,
    getDeviceId: getDeviceId,
    getCashierSession: getCashierSession,
    getOfflineQueueCount: getOfflineQueueCount,
    getPWAStandaloneStatus: getPWAStandaloneStatus,
    buildSessionPreservationSnapshot: buildSessionPreservationSnapshot,
    registerServiceWorker: registerServiceWorker,
    captureInstallPrompt: captureInstallPrompt,
    requestInstallPrompt: requestInstallPrompt,
    renderInstallPromptStatus: renderInstallPromptStatus,
    renderPWAStatus: renderPWAStatus,
    bootPOSPWAScreen: bootPOSPWAScreen
  };
})();
/* PIX2PI_334_POS_PWA_RUNTIME_END */
