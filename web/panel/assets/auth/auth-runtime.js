/* PIX2PI_317_AUTH_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    loginEndpoint: "/api/auth/login",
    tenantListEndpoint: "/api/auth/tenants",
    tokenStorageKey: "pix2pi.panel.jwt",
    tokenIssuedAtStorageKey: "pix2pi.panel.jwt.issued_at",
    tenantPreferenceStorageKey: "pix2pi.panel.tenant.preference",
    sessionTimeoutMs: 30 * 60 * 1000,
    paths: {
      login: "/login/",
      tenantSelect: "/tenant-select/",
      unauthorized: "/unauthorized/",
      forbidden: "/forbidden/",
      sessionTimeout: "/session-timeout/"
    }
  };

  const LOGIN_ERROR_MESSAGES = {
    INVALID_CREDENTIALS: "E-posta veya şifre hatalı.",
    TENANT_REQUIRED: "Devam etmek için işletme seçimi gerekli.",
    TENANT_FORBIDDEN: "Bu kullanıcı seçilen işletmeye erişemez.",
    SESSION_EXPIRED: "Oturum süresi doldu. Lütfen tekrar giriş yapın.",
    NETWORK_ERROR: "Sunucuya ulaşılamadı. Lütfen tekrar deneyin.",
    UNKNOWN: "Giriş işlemi tamamlanamadı."
  };

  function now() {
    return Date.now();
  }

  function normalizeTenants(payload) {
    if (!payload) return [];
    if (Array.isArray(payload.tenants)) return payload.tenants;
    if (Array.isArray(payload.available_tenants)) return payload.available_tenants;
    if (payload.tenant) return [payload.tenant];
    return [];
  }

  function extractToken(payload) {
    if (!payload) return "";
    return payload.access_token || payload.jwt || payload.token || "";
  }

  function saveToken(token) {
    window.localStorage.setItem(CONFIG.tokenStorageKey, token);
    window.localStorage.setItem(CONFIG.tokenIssuedAtStorageKey, String(now()));
  }

  function getToken() {
    return window.localStorage.getItem(CONFIG.tokenStorageKey) || "";
  }

  function clearSession() {
    window.localStorage.removeItem(CONFIG.tokenStorageKey);
    window.localStorage.removeItem(CONFIG.tokenIssuedAtStorageKey);
  }

  function isSessionExpired() {
    const issuedAtRaw = window.localStorage.getItem(CONFIG.tokenIssuedAtStorageKey);
    if (!issuedAtRaw) return false;
    const issuedAt = Number(issuedAtRaw);
    if (!Number.isFinite(issuedAt)) return true;
    return now() - issuedAt > CONFIG.sessionTimeoutMs;
  }

  function saveTenantPreference(tenantId) {
    if (!tenantId) return;
    window.localStorage.setItem(CONFIG.tenantPreferenceStorageKey, tenantId);
  }

  function getTenantPreference() {
    return window.localStorage.getItem(CONFIG.tenantPreferenceStorageKey) || "";
  }

  function getLoginErrorMessage(code) {
    return LOGIN_ERROR_MESSAGES[code] || LOGIN_ERROR_MESSAGES.UNKNOWN;
  }

  function renderLoginError(target, code) {
    if (!target) return;
    target.textContent = getLoginErrorMessage(code);
    target.setAttribute("data-error-code", code);
    target.hidden = false;
  }

  async function loginWithJwtConnection(credentials) {
    const response = await fetch(CONFIG.loginEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Pix2pi-Surface": "panel"
      },
      body: JSON.stringify(credentials)
    });

    if (response.status === 401) {
      throw new Error("INVALID_CREDENTIALS");
    }

    if (response.status === 403) {
      throw new Error("TENANT_FORBIDDEN");
    }

    if (!response.ok) {
      throw new Error("UNKNOWN");
    }

    const payload = await response.json();
    const token = extractToken(payload);
    const tenants = normalizeTenants(payload);

    if (!token) {
      throw new Error("UNKNOWN");
    }

    saveToken(token);

    return {
      token,
      tenants,
      preferredTenantId: getTenantPreference()
    };
  }

  async function fetchTenants() {
    const token = getToken();
    const response = await fetch(CONFIG.tenantListEndpoint, {
      method: "GET",
      headers: {
        "Authorization": "Bearer " + token,
        "X-Pix2pi-Surface": "panel"
      }
    });

    if (response.status === 401) {
      clearSession();
      window.location.href = CONFIG.paths.unauthorized;
      return [];
    }

    if (response.status === 403) {
      window.location.href = CONFIG.paths.forbidden;
      return [];
    }

    if (!response.ok) {
      throw new Error("UNKNOWN");
    }

    return normalizeTenants(await response.json());
  }

  function enforceSessionTimeout() {
    if (isSessionExpired()) {
      clearSession();
      window.location.href = CONFIG.paths.sessionTimeout;
      return false;
    }
    return true;
  }

  function bootSessionTimeoutWatcher() {
    window.setInterval(enforceSessionTimeout, 30000);
    ["click", "keydown", "mousemove", "touchstart"].forEach(function (eventName) {
      window.addEventListener(eventName, function () {
        if (getToken()) {
          window.localStorage.setItem(CONFIG.tokenIssuedAtStorageKey, String(now()));
        }
      }, { passive: true });
    });
  }

  window.Pix2piAuth = {
    CONFIG,
    LOGIN_ERROR_MESSAGES,
    normalizeTenants,
    extractToken,
    saveToken,
    getToken,
    clearSession,
    isSessionExpired,
    saveTenantPreference,
    getTenantPreference,
    getLoginErrorMessage,
    renderLoginError,
    loginWithJwtConnection,
    fetchTenants,
    enforceSessionTimeout,
    bootSessionTimeoutWatcher
  };
})();
/* PIX2PI_317_AUTH_RUNTIME_END */
