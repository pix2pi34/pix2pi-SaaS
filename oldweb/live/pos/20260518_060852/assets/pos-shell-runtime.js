/* PIX2PI_329_POS_SHELL_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "pos",
    phase: "FAZ_7R",
    step: "329",
    healthEndpoint: "/health",
    selectedTenantKey: "pix2pi.pos.tenant.preference",
    cashierSessionKey: "pix2pi.pos.cashier.session",
    runtimeContract: {
      realCashierLoginEnabled: false,
      realSaleEnabled: false,
      offlineQueueEnabled: false,
      readyForCashierLoginStep330: true
    }
  };

  function getSelectedTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || "controlled-pilot";
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

  async function fetchPOSHealth() {
    try {
      const response = await fetch(CONFIG.healthEndpoint, {
        headers: {
          "X-Pix2pi-Surface": "pos",
          "X-Pix2pi-Step": "329"
        }
      });

      if (!response.ok) {
        return { status: "offline", service: "pix2pi-pos" };
      }

      return response.json();
    } catch (_error) {
      return { status: "offline", service: "pix2pi-pos" };
    }
  }

  function renderPOSHealth(health) {
    const status = document.getElementById("pos-health-status");
    const service = document.getElementById("pos-health-service");
    const tenant = document.getElementById("pos-tenant-indicator");

    if (status) status.textContent = health.status || "unknown";
    if (service) service.textContent = health.service || "pix2pi-pos";
    if (tenant) tenant.textContent = getSelectedTenantId();

    document.body.setAttribute("data-pos-rendered", "true");
    return health;
  }

  async function bootPOSShell() {
    const health = await fetchPOSHealth();
    return renderPOSHealth(health);
  }

  window.Pix2piPOSShell = {
    CONFIG,
    getSelectedTenantId,
    getCashierSession,
    fetchPOSHealth,
    renderPOSHealth,
    bootPOSShell
  };
})();
/* PIX2PI_329_POS_SHELL_RUNTIME_END */
