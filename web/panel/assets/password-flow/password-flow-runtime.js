/* PIX2PI_349_PASSWORD_FLOW_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "password_flow",
    phase: "FAZ_7R",
    step: "349",
    initialPasswordEndpoint: "/api/auth/password/initial",
    resetRequestEndpoint: "/api/auth/password/reset/request",
    resetCompleteEndpoint: "/api/auth/password/reset/complete",
    loginEndpoint: "/api/auth/login",
    sessionValidateEndpoint: "/api/auth/session/validate",
    tenantSelectionPath: "/tenant-select/",
    sessionKey: "pix2pi.auth.session_id",
    accessTokenKey: "pix2pi.auth.access_token_id",
    refreshTokenKey: "pix2pi.auth.refresh_token_id"
  };

  function readValue(id) {
    const node = document.getElementById(id);
    return node ? node.value : "";
  }

  function setStatus(message) {
    const node = document.getElementById("password-flow-status");
    if (node) node.textContent = message;
  }

  function correlationId() {
    return "corr-" + Date.now().toString(36);
  }

  async function postJSON(endpoint, payload) {
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Pix2pi-Step": "349",
        "X-Correlation-ID": payload.correlation_id || correlationId()
      },
      credentials: "same-origin",
      body: JSON.stringify(payload)
    });

    const body = await response.json().catch(function () {
      return {};
    });

    if (!response.ok) {
      throw new Error(body.error || "request failed");
    }

    return body;
  }

  async function submitInitialPassword() {
    setStatus("İlk şifre kaydediliyor...");
    const result = await postJSON(CONFIG.initialPasswordEndpoint, {
      invite_token: readValue("invite-token"),
      password: readValue("initial-password"),
      confirm: readValue("initial-password-confirm"),
      correlation_id: correlationId()
    });
    setStatus("İlk şifre kaydedildi: " + result.email);
    return result;
  }

  async function submitLogin() {
    setStatus("Giriş yapılıyor...");
    const result = await postJSON(CONFIG.loginEndpoint, {
      email: readValue("login-email"),
      password: readValue("login-password"),
      tenant_id: readValue("login-tenant-id"),
      correlation_id: correlationId()
    });

    window.localStorage.setItem(CONFIG.sessionKey, result.session_id);
    window.localStorage.setItem(CONFIG.accessTokenKey, result.access_token_id);
    window.localStorage.setItem(CONFIG.refreshTokenKey, result.refresh_token_id);
    setStatus("Giriş başarılı. Tenant seçimine yönlendiriliyor.");
    window.location.href = result.next_path || CONFIG.tenantSelectionPath;
    return result;
  }

  async function submitResetRequest() {
    setStatus("Şifre sıfırlama isteği alınıyor...");
    const result = await postJSON(CONFIG.resetRequestEndpoint, {
      email: readValue("reset-email"),
      correlation_id: correlationId()
    });
    setStatus("Şifre sıfırlama tokenı üretildi.");
    return result;
  }

  async function submitResetComplete() {
    setStatus("Yeni şifre kaydediliyor...");
    const result = await postJSON(CONFIG.resetCompleteEndpoint, {
      reset_token: readValue("reset-token"),
      password: readValue("reset-password"),
      confirm: readValue("reset-password-confirm"),
      correlation_id: correlationId()
    });
    setStatus("Yeni şifre kaydedildi: " + result.email);
    return result;
  }

  function bootPasswordFlow() {
    document.body.setAttribute("data-password-flow-ready", "true");
    setStatus("Şifre ve giriş akışı hazır.");
  }

  window.Pix2piPasswordFlow = {
    CONFIG: CONFIG,
    submitInitialPassword: submitInitialPassword,
    submitLogin: submitLogin,
    submitResetRequest: submitResetRequest,
    submitResetComplete: submitResetComplete,
    bootPasswordFlow: bootPasswordFlow
  };
})();
/* PIX2PI_349_PASSWORD_FLOW_RUNTIME_END */
