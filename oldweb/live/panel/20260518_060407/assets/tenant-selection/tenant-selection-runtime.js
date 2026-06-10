/* PIX2PI_317_3_TENANT_SELECTION_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "tenant_selection",
    phase: "FAZ_7R",
    step: "317.3",
    tokenKey: "pix2pi.auth.access_token",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    listTenantsEndpoint: "/api/auth/tenants",
    selectTenantEndpoint: "/api/auth/tenant/select"
  };

  function getAccessToken() {
    return window.localStorage.getItem(CONFIG.tokenKey) || "";
  }

  function authHeaders() {
    const token = getAccessToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer " + token,
      "X-Pix2pi-Surface": "tenant_selection",
      "X-Pix2pi-Step": "317.3"
    };
  }

  async function loadTenantList() {
    const response = await fetch(CONFIG.listTenantsEndpoint, {
      method: "GET",
      headers: authHeaders(),
      credentials: "same-origin"
    });

    if (!response.ok) {
      throw new Error("tenant list api error " + response.status);
    }

    return response.json();
  }

  async function selectTenant(tenantId) {
    const response = await fetch(CONFIG.selectTenantEndpoint, {
      method: "POST",
      headers: authHeaders(),
      credentials: "same-origin",
      body: JSON.stringify({ tenant_id: tenantId })
    });

    if (!response.ok) {
      throw new Error("tenant select api error " + response.status);
    }

    const result = await response.json();
    window.localStorage.setItem(CONFIG.selectedTenantKey, result.tenant_id);
    return result;
  }

  function renderTenants(result) {
    const target = document.getElementById("tenant-selection-list");
    const status = document.getElementById("tenant-selection-status");
    if (!target) return;

    target.innerHTML = "";

    if (!result || !Array.isArray(result.tenants) || result.tenants.length === 0) {
      if (status) status.textContent = "Aktif tenant bulunamadı.";
      return;
    }

    result.tenants.forEach(function (tenant) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "tenant-card";
      button.setAttribute("data-tenant-id", tenant.tenant_id);
      button.innerHTML = [
        "<strong>" + tenant.tenant_name + "</strong>",
        "<span>" + tenant.tenant_slug + " / " + tenant.role_code + "</span>",
        "<small>" + tenant.default_language + " / " + tenant.currency + "</small>"
      ].join("");

      button.addEventListener("click", async function () {
        try {
          if (status) status.textContent = "Tenant seçiliyor...";
          const selected = await selectTenant(tenant.tenant_id);
          if (status) status.textContent = "Seçilen tenant: " + selected.tenant_name;
          document.body.setAttribute("data-selected-tenant-id", selected.tenant_id);
        } catch (error) {
          if (status) status.textContent = "Tenant seçimi tamamlanamadı: " + error.message;
        }
      });

      target.appendChild(button);
    });

    if (status) status.textContent = "Tenant listesi API cevabından yüklendi.";
    document.body.setAttribute("data-tenant-selection-rendered", "true");
  }

  async function bootTenantSelectionScreen() {
    const status = document.getElementById("tenant-selection-status");

    try {
      if (!getAccessToken()) {
        if (status) status.textContent = "Access token gerekiyor.";
        return null;
      }

      if (status) status.textContent = "Tenant listesi yükleniyor...";
      const result = await loadTenantList();
      renderTenants(result);
      return result;
    } catch (error) {
      if (status) status.textContent = "Tenant listesi alınamadı: " + error.message;
      return null;
    }
  }

  window.Pix2piTenantSelection = {
    CONFIG: CONFIG,
    getAccessToken: getAccessToken,
    authHeaders: authHeaders,
    loadTenantList: loadTenantList,
    selectTenant: selectTenant,
    renderTenants: renderTenants,
    bootTenantSelectionScreen: bootTenantSelectionScreen
  };
})();
/* PIX2PI_317_3_TENANT_SELECTION_RUNTIME_END */
