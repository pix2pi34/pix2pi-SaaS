/* PIX2PI_320_MERCHANT_DASHBOARD_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    snapshotEndpoint: "/api/panel/dashboard/snapshot",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    jwtKey: "pix2pi.panel.jwt",
    surface: "merchant_dashboard",
    fallbackSnapshot: {
      tenant: {
        id: "controlled-pilot",
        name: "Controlled Pilot İşletmesi",
        status: "PANEL_READY"
      },
      onboarding: {
        percent: 68,
        status: "DRAFT_READY",
        next_action: "İşletme bilgilerini tamamla"
      },
      kpis: {
        today_sales: 0,
        open_orders: 0,
        product_count: 0,
        pending_documents: 0
      },
      modules: {
        pos: "READY_FOR_BINDING",
        erp: "READY_FOR_BINDING",
        marketplace: "READY_FOR_BINDING"
      },
      alerts: [
        {
          severity: "info",
          title: "Panel hazır",
          message: "Merchant dashboard yüzeyi aktif."
        }
      ]
    }
  };

  function getSelectedTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || "controlled-pilot";
  }

  function getJwt() {
    return window.localStorage.getItem(CONFIG.jwtKey) || "";
  }

  async function fetchDashboardSnapshot() {
    const token = getJwt();
    const tenantId = getSelectedTenantId();

    try {
      const response = await fetch(CONFIG.snapshotEndpoint, {
        method: "GET",
        headers: {
          "Authorization": token ? "Bearer " + token : "",
          "X-Tenant-ID": tenantId,
          "X-Pix2pi-Surface": "panel",
          "X-Pix2pi-Dashboard-Step": "320"
        }
      });

      if (!response.ok) {
        return CONFIG.fallbackSnapshot;
      }

      return response.json();
    } catch (_error) {
      return CONFIG.fallbackSnapshot;
    }
  }

  function moneyTRY(value) {
    try {
      return new Intl.NumberFormat("tr-TR", {
        style: "currency",
        currency: "TRY"
      }).format(Number(value || 0));
    } catch (_error) {
      return String(value || 0) + " TL";
    }
  }

  function setText(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value;
  }

  function setStatus(id, value) {
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = value;
    el.setAttribute("data-module-status", value);
  }

  function renderDashboardSnapshot(snapshot) {
    setText("dashboard-tenant-name", snapshot.tenant.name);
    setText("dashboard-tenant-id", snapshot.tenant.id);
    setStatus("dashboard-tenant-status", snapshot.tenant.status);

    setText("dashboard-onboarding-percent", String(snapshot.onboarding.percent) + "%");
    setStatus("dashboard-onboarding-status", snapshot.onboarding.status);
    setText("dashboard-onboarding-next-action", snapshot.onboarding.next_action);

    setText("kpi-today-sales", moneyTRY(snapshot.kpis.today_sales));
    setText("kpi-open-orders", String(snapshot.kpis.open_orders));
    setText("kpi-product-count", String(snapshot.kpis.product_count));
    setText("kpi-pending-documents", String(snapshot.kpis.pending_documents));

    setStatus("status-pos", snapshot.modules.pos);
    setStatus("status-erp", snapshot.modules.erp);
    setStatus("status-marketplace", snapshot.modules.marketplace);

    const alert = snapshot.alerts && snapshot.alerts[0] ? snapshot.alerts[0] : null;
    if (alert) {
      setText("alert-title", alert.title);
      setText("alert-message", alert.message);
      const alertBox = document.getElementById("dashboard-alert-preview");
      if (alertBox) alertBox.setAttribute("data-alert-severity", alert.severity);
    }

    document.body.setAttribute("data-dashboard-rendered", "true");
    return snapshot;
  }

  async function bootDashboard() {
    const snapshot = await fetchDashboardSnapshot();
    return renderDashboardSnapshot(snapshot);
  }

  window.Pix2piMerchantDashboard = {
    CONFIG,
    getSelectedTenantId,
    getJwt,
    fetchDashboardSnapshot,
    renderDashboardSnapshot,
    bootDashboard,
    moneyTRY
  };
})();
/* PIX2PI_320_MERCHANT_DASHBOARD_RUNTIME_END */
