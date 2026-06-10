(function logoutSessionRuntime(global) {
  "use strict";

  const STORAGE_KEYS = {
    session: "pix2pi.session",
    authToken: "pix2pi.authToken",
    refreshToken: "pix2pi.refreshToken",
    activeTenant: "pix2pi.activeTenant",
    tenantContext: "pix2pi.tenantContext",
    loginAttempt: "pix2pi.loginAttempt",
    loginError: "pix2pi.loginError",
    logoutSignal: "pix2pi.logoutSignal",
    sessionExpiredSignal: "pix2pi.sessionExpiredSignal",
    lastRedirectReason: "pix2pi.lastRedirectReason"
  };

  const EVENTS = {
    logout: "pix2pi:logout",
    tokenCleanup: "pix2pi:token-cleanup",
    sessionExpired: "pix2pi:session-expired",
    authRedirect: "pix2pi:auth-redirect"
  };

  const REDIRECT_TARGETS = {
    login: "../login-session/index.html",
    sessionExpired: "../auth-errors/session-expired.html"
  };

  let timeoutInterval = null;

  function nowIso() {
    return new Date().toISOString();
  }

  function addMinutes(minutes) {
    return new Date(Date.now() + minutes * 60 * 1000).toISOString();
  }

  function addSeconds(seconds) {
    return new Date(Date.now() + seconds * 1000).toISOString();
  }

  function safeJsonParse(value, fallback) {
    try {
      return value ? JSON.parse(value) : fallback;
    } catch (_err) {
      return fallback;
    }
  }

  function getStorage() {
    if (global.localStorage) {
      return global.localStorage;
    }

    const memory = {};
    return {
      getItem(key) {
        return Object.prototype.hasOwnProperty.call(memory, key) ? memory[key] : null;
      },
      setItem(key, value) {
        memory[key] = String(value);
      },
      removeItem(key) {
        delete memory[key];
      }
    };
  }

  const storage = getStorage();

  function dispatchEvent(name, detail) {
    if (typeof global.CustomEvent === "function" && typeof global.dispatchEvent === "function") {
      global.dispatchEvent(new CustomEvent(name, { detail }));
    }
  }

  function buildDemoSession(minutes) {
    return {
      user_id: "demo-admin-001",
      display_name: "Pix2pi Tenant Admin",
      email: "admin@pix2pi.local",
      roles: ["TENANT_ADMIN", "OWNER"],
      permissions: ["tenant:view", "tenant:switch", "dashboard:view", "erp:view"],
      issued_at: nowIso(),
      expires_at: addMinutes(minutes || 30),
      session_source: "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW"
    };
  }

  function buildDemoTenant() {
    return {
      tenant_id: "tenant_7",
      tenant_uuid: "6dfe8d22-035a-401f-807c-507408d2e439",
      tenant_name: "Pix2pi Pilot İşletme",
      tenant_code: "PIX2PI-PILOT",
      selected_at: nowIso()
    };
  }

  function createDemoAuthState(minutes) {
    const session = buildDemoSession(minutes || 30);
    const tenant = buildDemoTenant();

    storage.setItem(STORAGE_KEYS.session, JSON.stringify(session));
    storage.setItem(STORAGE_KEYS.authToken, "demo_access_token.logout_flow." + Date.now());
    storage.setItem(STORAGE_KEYS.refreshToken, "demo_refresh_token.logout_flow." + Date.now());
    storage.setItem(STORAGE_KEYS.activeTenant, JSON.stringify(tenant));
    storage.setItem(STORAGE_KEYS.tenantContext, JSON.stringify({
      tenant_id: tenant.tenant_id,
      tenant_uuid: tenant.tenant_uuid,
      tenant_code: tenant.tenant_code,
      context_set_at: nowIso()
    }));

    renderLogoutSessionState();
    logLogoutEvent("DEMO_AUTH_STATE_CREATED", {
      expires_at: session.expires_at
    });

    return {
      session,
      tenant
    };
  }

  function getSession() {
    return safeJsonParse(storage.getItem(STORAGE_KEYS.session), null);
  }

  function isSessionExpired(session) {
    if (!session || !session.expires_at) {
      return true;
    }

    return new Date(session.expires_at).getTime() <= Date.now();
  }

  function cleanupTokens() {
    storage.removeItem(STORAGE_KEYS.authToken);
    storage.removeItem(STORAGE_KEYS.refreshToken);

    const payload = {
      cleaned_at: nowIso(),
      auth_token_present: Boolean(storage.getItem(STORAGE_KEYS.authToken)),
      refresh_token_present: Boolean(storage.getItem(STORAGE_KEYS.refreshToken))
    };

    dispatchEvent(EVENTS.tokenCleanup, payload);
    logLogoutEvent("TOKEN_CLEANUP", payload);

    return payload;
  }

  function clearSessionAndTenantState() {
    storage.removeItem(STORAGE_KEYS.session);
    storage.removeItem(STORAGE_KEYS.activeTenant);
    storage.removeItem(STORAGE_KEYS.tenantContext);
    storage.removeItem(STORAGE_KEYS.loginAttempt);
    storage.removeItem(STORAGE_KEYS.loginError);
  }

  function logout(reason) {
    const cleanup = cleanupTokens();

    clearSessionAndTenantState();

    const signal = {
      reason: reason || "USER_LOGOUT",
      logout_at: nowIso(),
      cleanup
    };

    storage.setItem(STORAGE_KEYS.logoutSignal, JSON.stringify(signal));
    dispatchEvent(EVENTS.logout, signal);

    renderLogoutSessionState();
    logLogoutEvent("LOGOUT", signal);

    return signal;
  }

  function markSessionExpired(reason) {
    const signal = {
      reason: reason || "SESSION_EXPIRED",
      expired_at: nowIso()
    };

    storage.setItem(STORAGE_KEYS.sessionExpiredSignal, JSON.stringify(signal));
    dispatchEvent(EVENTS.sessionExpired, signal);
    logLogoutEvent("SESSION_EXPIRED", signal);

    return signal;
  }

  function redirectToLogin(reason) {
    const payload = {
      reason: reason || "LOGIN_REQUIRED",
      target: REDIRECT_TARGETS.login,
      redirected_at: nowIso()
    };

    storage.setItem(STORAGE_KEYS.lastRedirectReason, JSON.stringify(payload));
    dispatchEvent(EVENTS.authRedirect, payload);
    logLogoutEvent("REDIRECT_TO_LOGIN", payload);

    return payload;
  }

  function redirectExpiredSession(reason) {
    const payload = {
      reason: reason || "SESSION_EXPIRED",
      target: REDIRECT_TARGETS.sessionExpired,
      redirected_at: nowIso()
    };

    storage.setItem(STORAGE_KEYS.lastRedirectReason, JSON.stringify(payload));
    dispatchEvent(EVENTS.authRedirect, payload);
    logLogoutEvent("REDIRECT_EXPIRED_SESSION", payload);

    return payload;
  }

  function enforceSessionExpiryRedirect() {
    const session = getSession();

    if (!session) {
      return redirectToLogin("MISSING_SESSION");
    }

    if (isSessionExpired(session)) {
      markSessionExpired("SESSION_EXPIRED_DETECTED");
      cleanupTokens();
      return redirectExpiredSession("SESSION_EXPIRED_DETECTED");
    }

    logLogoutEvent("SESSION_NOT_EXPIRED", {
      expires_at: session.expires_at
    });

    return {
      ok: true,
      expires_at: session.expires_at
    };
  }

  function createExpiredSessionForTest() {
    const result = createDemoAuthState(-1);
    renderLogoutSessionState();
    logLogoutEvent("EXPIRED_SESSION_CREATED_FOR_TEST", result.session);
    return result;
  }

  function createShortTimeoutSession(seconds) {
    const session = buildDemoSession(30);
    session.expires_at = addSeconds(seconds || 5);

    const tenant = buildDemoTenant();

    storage.setItem(STORAGE_KEYS.session, JSON.stringify(session));
    storage.setItem(STORAGE_KEYS.authToken, "demo_access_token.timeout_flow." + Date.now());
    storage.setItem(STORAGE_KEYS.refreshToken, "demo_refresh_token.timeout_flow." + Date.now());
    storage.setItem(STORAGE_KEYS.activeTenant, JSON.stringify(tenant));
    storage.setItem(STORAGE_KEYS.tenantContext, JSON.stringify({
      tenant_id: tenant.tenant_id,
      tenant_uuid: tenant.tenant_uuid,
      tenant_code: tenant.tenant_code,
      context_set_at: nowIso()
    }));

    renderLogoutSessionState();
    logLogoutEvent("SHORT_TIMEOUT_SESSION_CREATED", {
      expires_at: session.expires_at
    });

    return {
      session,
      tenant
    };
  }

  function startSessionTimeoutWatcher(intervalMs) {
    stopSessionTimeoutWatcher();

    timeoutInterval = global.setInterval(function timeoutTick() {
      const result = enforceSessionExpiryRedirect();
      renderLogoutSessionState();

      if (result && result.target === REDIRECT_TARGETS.sessionExpired) {
        stopSessionTimeoutWatcher();
      }
    }, intervalMs || 1000);

    logLogoutEvent("SESSION_TIMEOUT_WATCHER_STARTED", {
      interval_ms: intervalMs || 1000
    });

    renderLogoutSessionState();

    return timeoutInterval;
  }

  function stopSessionTimeoutWatcher() {
    if (timeoutInterval) {
      global.clearInterval(timeoutInterval);
      timeoutInterval = null;
      logLogoutEvent("SESSION_TIMEOUT_WATCHER_STOPPED", {});
    }

    renderLogoutSessionState();
  }

  function validateLogoutCleanup() {
    return {
      session_present: Boolean(storage.getItem(STORAGE_KEYS.session)),
      auth_token_present: Boolean(storage.getItem(STORAGE_KEYS.authToken)),
      refresh_token_present: Boolean(storage.getItem(STORAGE_KEYS.refreshToken)),
      active_tenant_present: Boolean(storage.getItem(STORAGE_KEYS.activeTenant)),
      tenant_context_present: Boolean(storage.getItem(STORAGE_KEYS.tenantContext)),
      login_error_present: Boolean(storage.getItem(STORAGE_KEYS.loginError)),
      logout_signal_present: Boolean(storage.getItem(STORAGE_KEYS.logoutSignal)),
      session_expired_signal_present: Boolean(storage.getItem(STORAGE_KEYS.sessionExpiredSignal)),
      last_redirect_reason: safeJsonParse(storage.getItem(STORAGE_KEYS.lastRedirectReason), null),
      timeout_watcher_running: Boolean(timeoutInterval)
    };
  }

  function renderLogoutSessionState() {
    const session = getSession();
    const validation = validateLogoutCleanup();

    const sessionEl = document.getElementById("logoutSessionSnapshot");
    const tokenEl = document.getElementById("logoutTokenSnapshot");
    const expiryEl = document.getElementById("sessionExpirySnapshot");
    const cleanupEl = document.getElementById("logoutCleanupSnapshot");
    const timeoutEl = document.getElementById("sessionTimeoutSnapshot");
    const redirectEl = document.getElementById("expiredRedirectSnapshot");

    if (sessionEl) {
      sessionEl.textContent = session ? JSON.stringify(session, null, 2) : "SESSION_EMPTY";
    }

    if (tokenEl) {
      tokenEl.textContent = JSON.stringify({
        auth_token_present: Boolean(storage.getItem(STORAGE_KEYS.authToken)),
        refresh_token_present: Boolean(storage.getItem(STORAGE_KEYS.refreshToken))
      }, null, 2);
    }

    if (expiryEl) {
      expiryEl.textContent = JSON.stringify({
        session_expired: isSessionExpired(session),
        session_expired_signal: safeJsonParse(storage.getItem(STORAGE_KEYS.sessionExpiredSignal), null)
      }, null, 2);
    }

    if (cleanupEl) {
      cleanupEl.textContent = JSON.stringify(validation, null, 2);
    }

    if (timeoutEl) {
      timeoutEl.textContent = JSON.stringify({
        timeout_watcher_running: Boolean(timeoutInterval),
        check_interval_policy: "1000ms",
        timeout_policy: "CHECK_EXPIRES_AT_AND_REDIRECT_ON_EXPIRY"
      }, null, 2);
    }

    if (redirectEl) {
      redirectEl.textContent = JSON.stringify(safeJsonParse(storage.getItem(STORAGE_KEYS.lastRedirectReason), null), null, 2);
    }

    return validation;
  }

  function logLogoutEvent(type, payload) {
    const log = document.getElementById("logoutSessionLog");
    if (!log) {
      return;
    }

    const line = "[" + nowIso() + "] " + type + " " + JSON.stringify(payload);
    log.textContent = line + "\n" + log.textContent;
  }

  function bootstrapLogoutSessionFlow() {
    const createSessionButton = document.getElementById("createLogoutDemoSessionButton");
    const logoutButton = document.getElementById("logoutButton");
    const cleanupButton = document.getElementById("tokenCleanupButton");
    const expiredButton = document.getElementById("createExpiredSessionButton");
    const redirectButton = document.getElementById("enforceExpiredRedirectButton");
    const timeoutButton = document.getElementById("startSessionTimeoutButton");
    const stopTimeoutButton = document.getElementById("stopSessionTimeoutButton");
    const validateButton = document.getElementById("validateLogoutCleanupButton");

    if (createSessionButton) {
      createSessionButton.addEventListener("click", () => createDemoAuthState(30));
    }

    if (logoutButton) {
      logoutButton.addEventListener("click", () => logout("USER_LOGOUT"));
    }

    if (cleanupButton) {
      cleanupButton.addEventListener("click", () => {
        cleanupTokens();
        renderLogoutSessionState();
      });
    }

    if (expiredButton) {
      expiredButton.addEventListener("click", createExpiredSessionForTest);
    }

    if (redirectButton) {
      redirectButton.addEventListener("click", () => {
        enforceSessionExpiryRedirect();
        renderLogoutSessionState();
      });
    }

    if (timeoutButton) {
      timeoutButton.addEventListener("click", () => {
        createShortTimeoutSession(5);
        startSessionTimeoutWatcher(1000);
      });
    }

    if (stopTimeoutButton) {
      stopTimeoutButton.addEventListener("click", stopSessionTimeoutWatcher);
    }

    if (validateButton) {
      validateButton.addEventListener("click", () => {
        const validation = renderLogoutSessionState();
        logLogoutEvent("LOGOUT_CLEANUP_VALIDATED", validation);
      });
    }

    renderLogoutSessionState();
  }

  const api = {
    STORAGE_KEYS,
    EVENTS,
    REDIRECT_TARGETS,
    buildDemoSession,
    buildDemoTenant,
    createDemoAuthState,
    getSession,
    isSessionExpired,
    cleanupTokens,
    clearSessionAndTenantState,
    logout,
    markSessionExpired,
    redirectToLogin,
    redirectExpiredSession,
    enforceSessionExpiryRedirect,
    createExpiredSessionForTest,
    createShortTimeoutSession,
    startSessionTimeoutWatcher,
    stopSessionTimeoutWatcher,
    validateLogoutCleanup,
    renderLogoutSessionState,
    bootstrapLogoutSessionFlow
  };

  global.Pix2piLogoutSessionFlow = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapLogoutSessionFlow);
    } else {
      bootstrapLogoutSessionFlow();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
