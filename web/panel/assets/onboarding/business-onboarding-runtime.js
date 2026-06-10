/* PIX2PI_319_BUSINESS_ONBOARDING_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "business_onboarding",
    phase: "FAZ_7R",
    step: "319",
    endpoint: "/api/onboarding/business",
    nextPath: "/pilot-tenant-opening/",
    sessionKey: "pix2pi.auth.session_id"
  };

  function value(id) {
    const node = document.getElementById(id);
    return node ? node.value : "";
  }

  function status(message) {
    const node = document.getElementById("onboarding-status");
    if (node) node.textContent = message;
  }

  function correlationId() {
    return "corr-319-" + Date.now().toString(36);
  }

  function payload() {
    return {
      owner_user_id: value("owner-user-id"),
      business_name: value("business-name"),
      tax_or_tckn: value("tax-or-tckn"),
      address_line: value("address-line"),
      city: value("city"),
      district: value("district"),
      sector_code: value("sector-code"),
      branch_name: value("branch-name"),
      currency_code: value("currency-code"),
      language_code: value("language-code"),
      first_role_code: value("first-role-code"),
      correlation_id: correlationId()
    };
  }

  async function submitOnboarding() {
    status("İşletme onboarding kaydı gönderiliyor...");

    const response = await fetch(CONFIG.endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Pix2pi-Step": "319"
      },
      credentials: "same-origin",
      body: JSON.stringify(payload())
    });

    const body = await response.json().catch(function () {
      return {};
    });

    if (!response.ok) {
      status("Onboarding hatası: " + (body.error || "request failed"));
      throw new Error(body.error || "request failed");
    }

    status("Onboarding tamamlandı. Tenant: " + body.tenant_slug);
    return body;
  }

  function bootOnboarding() {
    document.body.setAttribute("data-business-onboarding-ready", "true");
    status("İşletme onboarding ekranı hazır.");
  }

  window.Pix2piBusinessOnboarding = {
    CONFIG: CONFIG,
    payload: payload,
    submitOnboarding: submitOnboarding,
    bootOnboarding: bootOnboarding
  };
})();
/* PIX2PI_319_BUSINESS_ONBOARDING_RUNTIME_END */
