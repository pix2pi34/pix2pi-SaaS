/* PIX2PI_347_PILOT_TENANT_OPENING_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "pilot_tenant_opening",
    phase: "FAZ_7R",
    step: "347",
    endpoint: "/api/pilot-tenant/opening",
    nextPath: "/user-invite/"
  };

  function value(id) {
    const node = document.getElementById(id);
    return node ? node.value : "";
  }

  function status(message) {
    const node = document.getElementById("pilot-tenant-opening-status");
    if (node) node.textContent = message;
  }

  function correlationId() {
    return "corr-347-" + Date.now().toString(36);
  }

  function payload() {
    return {
      tenant_id: value("tenant-id"),
      owner_user_id: value("owner-user-id"),
      tenant_slug: value("tenant-slug"),
      default_language: value("default-language"),
      default_currency: value("default-currency"),
      default_plan_code: value("default-plan-code"),
      branch_name: value("branch-name"),
      register_name: value("register-name"),
      timezone: value("timezone"),
      correlation_id: correlationId()
    };
  }

  async function submitOpening() {
    status("Pilot tenant açılışı gönderiliyor...");

    const response = await fetch(CONFIG.endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Pix2pi-Step": "347"
      },
      credentials: "same-origin",
      body: JSON.stringify(payload())
    });

    const body = await response.json().catch(function () {
      return {};
    });

    if (!response.ok) {
      status("Tenant açılış hatası: " + (body.error || "request failed"));
      throw new Error(body.error || "request failed");
    }

    status("Pilot tenant açılışı tamamlandı. Branch: " + body.branch_id + " Register: " + body.register_id);
    return body;
  }

  function bootOpening() {
    document.body.setAttribute("data-pilot-tenant-opening-ready", "true");
    status("Pilot tenant açılış ekranı hazır.");
  }

  window.Pix2piPilotTenantOpening = {
    CONFIG: CONFIG,
    payload: payload,
    submitOpening: submitOpening,
    bootOpening: bootOpening
  };
})();
/* PIX2PI_347_PILOT_TENANT_OPENING_RUNTIME_END */
