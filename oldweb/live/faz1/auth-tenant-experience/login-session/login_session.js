(function loginSessionRuntime(global) {
  "use strict";

  const STORAGE_KEYS = {
    session: "pix2pi.session",
    authToken: "pix2pi.authToken",
    refreshToken: "pix2pi.refreshToken",
    activeTenant: "pix2pi.activeTenant",
    loginAttempt: "pix2pi.loginAttempt",
    loginError: "pix2pi.loginError"
  };

  const EVENTS = {
    loginSuccess: "pix2pi:login-success",
    loginError: "pix2pi:login-error",
    sessionValid: "pix2pi:session-valid",
    sessionInvalid: "pix2pi:session-invalid"
  };

  const DEMO_USERS = [
    {
      email: "admin@pix2pi.local",
      password: "Pix2piDemo123",
      user_id: "demo-admin-001",
      display_name: "Pix2pi Tenant Admin",
      roles: ["TENANT_ADMIN", "OWNER"],
      permissions: ["tenant:view", "tenant:switch", "dashboard:view", "erp:view", "users:manage"]
    },
    {
      email: "accountant@pix2pi.local",
      password: "Pix2piDemo123",
      user_id: "demo-accountant-001",
      display_name: "Pix2pi Muhasebeci",
      roles: ["ACCOUNTANT"],
      permissions: ["tenant:view", "tenant:switch", "accounting:view", "accounting:export", "accountant:portal"]
    }
  ];

  function nowIso() {
    return new Date().toISOString();
  }

  function addMinutes(minutes) {
    return new Date(Date.now() + minutes * 60 * 1000).toISOString();
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

  function buildToken(prefix, userId) {
    return prefix + "." + userId + "." + Date.now();
  }

  function buildSession(user, rememberMe) {
    return {
      user_id: user.user_id,
      display_name: user.display_name,
      email: user.email,
      roles: user.roles,
      permissions: user.permissions,
      issued_at: nowIso(),
      expires_at: addMinutes(rememberMe ? 1440 : 30),
      remember_me: Boolean(rememberMe),
      session_source: "FAZ_1_5_1_LOGIN_FLOW"
    };
  }

  function validateCredentials(email, password, tenantHint) {
    if (!email || !password) {
      return {
        ok: false,
        code: "MISSING_CREDENTIALS",
        message: "E-posta ve şifre zorunludur."
      };
    }

    if (!tenantHint) {
      return {
        ok: false,
        code: "TENANT_REQUIRED",
        message: "Tenant hint / firma kodu zorunludur."
      };
    }

    const user = DEMO_USERS.find((candidate) => {
      return candidate.email.toLowerCase() === String(email).toLowerCase() && candidate.password === password;
    });

    if (!user) {
      return {
        ok: false,
        code: "INVALID_CREDENTIALS",
        message: "E-posta veya şifre hatalı."
      };
    }

    if (String(email).includes("locked")) {
      return {
        ok: false,
        code: "ACCOUNT_LOCKED",
        message: "Hesap kilitli. Yöneticiyle görüşün."
      };
    }

    return {
      ok: true,
      user
    };
  }

  function persistTokens(session) {
    const authToken = buildToken("demo_access_token", session.user_id);
    const refreshToken = buildToken("demo_refresh_token", session.user_id);

    storage.setItem(STORAGE_KEYS.authToken, authToken);
    storage.setItem(STORAGE_KEYS.refreshToken, refreshToken);

    return {
      auth_token: authToken,
      refresh_token: refreshToken
    };
  }

  function persistSession(session) {
    storage.setItem(STORAGE_KEYS.session, JSON.stringify(session));
    return session;
  }

  function persistTenantFromHint(tenantHint) {
    const tenant = {
      tenant_id: String(tenantHint).trim() || "tenant_7",
      tenant_uuid: "6dfe8d22-035a-401f-807c-507408d2e439",
      tenant_name: "Pix2pi Login Tenant",
      tenant_code: String(tenantHint).trim() || "PIX2PI-PILOT",
      selected_at: nowIso()
    };

    storage.setItem(STORAGE_KEYS.activeTenant, JSON.stringify(tenant));
    return tenant;
  }

  function setLoginError(code, message) {
    const payload = {
      code,
      message,
      happened_at: nowIso()
    };

    storage.setItem(STORAGE_KEYS.loginError, JSON.stringify(payload));
    dispatchEvent(EVENTS.loginError, payload);
    renderLoginError(payload);
    logLoginEvent("LOGIN_ERROR", payload);

    return payload;
  }

  function clearLoginError() {
    storage.removeItem(STORAGE_KEYS.loginError);
    const alert = document.getElementById("loginErrorAlert");
    if (alert) {
      alert.classList.remove("visible");
      alert.textContent = "";
    }
  }

  function loginWithCredentials(email, password, tenantHint, rememberMe) {
    const attempt = {
      email: email || "",
      tenant_hint: tenantHint || "",
      attempted_at: nowIso()
    };

    storage.setItem(STORAGE_KEYS.loginAttempt, JSON.stringify(attempt));
    clearLoginError();

    const validation = validateCredentials(email, password, tenantHint);

    if (!validation.ok) {
      return {
        ok: false,
        error: setLoginError(validation.code, validation.message)
      };
    }

    const session = buildSession(validation.user, rememberMe);
    const tokens = persistTokens(session);
    const tenant = persistTenantFromHint(tenantHint);

    persistSession(session);

    const result = {
      ok: true,
      session,
      tokens,
      tenant
    };

    dispatchEvent(EVENTS.loginSuccess, result);
    renderLoginSessionState();
    logLoginEvent("LOGIN_SUCCESS", {
      user_id: session.user_id,
      tenant_id: tenant.tenant_id
    });

    return result;
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

  function validateSession() {
    const session = getSession();
    const authToken = storage.getItem(STORAGE_KEYS.authToken);
    const refreshToken = storage.getItem(STORAGE_KEYS.refreshToken);
    const tenant = safeJsonParse(storage.getItem(STORAGE_KEYS.activeTenant), null);

    const result = {
      ok: Boolean(session && authToken && refreshToken && tenant && !isSessionExpired(session)),
      session_present: Boolean(session),
      auth_token_present: Boolean(authToken),
      refresh_token_present: Boolean(refreshToken),
      tenant_present: Boolean(tenant),
      session_expired: isSessionExpired(session),
      checked_at: nowIso()
    };

    dispatchEvent(result.ok ? EVENTS.sessionValid : EVENTS.sessionInvalid, result);
    renderLoginSessionState();
    logLoginEvent(result.ok ? "SESSION_VALID" : "SESSION_INVALID", result);

    return result;
  }

  function expireSessionForTest() {
    const session = getSession();

    if (!session) {
      return setLoginError("SESSION_INVALID", "Expire edilecek session bulunamadı.");
    }

    session.expires_at = addMinutes(-1);
    persistSession(session);
    return validateSession();
  }

  function clearLoginState() {
    storage.removeItem(STORAGE_KEYS.session);
    storage.removeItem(STORAGE_KEYS.authToken);
    storage.removeItem(STORAGE_KEYS.refreshToken);
    storage.removeItem(STORAGE_KEYS.activeTenant);
    storage.removeItem(STORAGE_KEYS.loginError);
    renderLoginSessionState();
    logLoginEvent("LOGIN_STATE_CLEARED", {});
  }

  function renderLoginError(error) {
    const alert = document.getElementById("loginErrorAlert");
    if (!alert) {
      return;
    }

    if (!error) {
      alert.classList.remove("visible");
      alert.textContent = "";
      return;
    }

    alert.classList.add("visible");
    alert.textContent = error.code + " — " + error.message;
  }

  function renderLoginSessionState() {
    const session = getSession();
    const token = storage.getItem(STORAGE_KEYS.authToken);
    const refresh = storage.getItem(STORAGE_KEYS.refreshToken);
    const tenant = safeJsonParse(storage.getItem(STORAGE_KEYS.activeTenant), null);
    const error = safeJsonParse(storage.getItem(STORAGE_KEYS.loginError), null);

    const sessionEl = document.getElementById("sessionSnapshot");
    const tokenEl = document.getElementById("tokenSnapshot");
    const tenantEl = document.getElementById("tenantSnapshot");
    const validationEl = document.getElementById("validationSnapshot");

    if (sessionEl) {
      sessionEl.textContent = session ? JSON.stringify(session, null, 2) : "SESSION_EMPTY";
    }

    if (tokenEl) {
      tokenEl.textContent = JSON.stringify({
        auth_token_present: Boolean(token),
        refresh_token_present: Boolean(refresh)
      }, null, 2);
    }

    if (tenantEl) {
      tenantEl.textContent = tenant ? JSON.stringify(tenant, null, 2) : "TENANT_EMPTY";
    }

    if (validationEl) {
      validationEl.textContent = JSON.stringify({
        session_present: Boolean(session),
        session_expired: isSessionExpired(session),
        error
      }, null, 2);
    }

    renderLoginError(error);
  }

  function logLoginEvent(type, payload) {
    const log = document.getElementById("loginSessionLog");
    if (!log) {
      return;
    }

    const line = "[" + nowIso() + "] " + type + " " + JSON.stringify(payload);
    log.textContent = line + "\n" + log.textContent;
  }

  function bootstrapLoginSessionFlow() {
    const form = document.getElementById("loginForm");
    const validateButton = document.getElementById("validateSessionButton");
    const expireButton = document.getElementById("expireSessionButton");
    const clearButton = document.getElementById("clearLoginStateButton");
    const demoAdminButton = document.getElementById("fillAdminDemoButton");
    const demoAccountantButton = document.getElementById("fillAccountantDemoButton");

    if (form) {
      form.addEventListener("submit", function onLoginSubmit(event) {
        event.preventDefault();

        const email = document.getElementById("loginEmail").value;
        const password = document.getElementById("loginPassword").value;
        const tenantHint = document.getElementById("tenantHint").value;
        const rememberMe = document.getElementById("rememberMe").checked;

        loginWithCredentials(email, password, tenantHint, rememberMe);
      });
    }

    if (validateButton) {
      validateButton.addEventListener("click", validateSession);
    }

    if (expireButton) {
      expireButton.addEventListener("click", expireSessionForTest);
    }

    if (clearButton) {
      clearButton.addEventListener("click", clearLoginState);
    }

    if (demoAdminButton) {
      demoAdminButton.addEventListener("click", function fillAdminDemo() {
        document.getElementById("loginEmail").value = "admin@pix2pi.local";
        document.getElementById("loginPassword").value = "Pix2piDemo123";
        document.getElementById("tenantHint").value = "tenant_7";
      });
    }

    if (demoAccountantButton) {
      demoAccountantButton.addEventListener("click", function fillAccountantDemo() {
        document.getElementById("loginEmail").value = "accountant@pix2pi.local";
        document.getElementById("loginPassword").value = "Pix2piDemo123";
        document.getElementById("tenantHint").value = "tenant_99";
      });
    }

    renderLoginSessionState();
  }

  const api = {
    STORAGE_KEYS,
    EVENTS,
    DEMO_USERS,
    validateCredentials,
    persistTokens,
    persistSession,
    persistTenantFromHint,
    loginWithCredentials,
    getSession,
    isSessionExpired,
    validateSession,
    expireSessionForTest,
    clearLoginState,
    renderLoginError,
    renderLoginSessionState,
    bootstrapLoginSessionFlow
  };

  global.Pix2piLoginSessionFlow = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapLoginSessionFlow);
    } else {
      bootstrapLoginSessionFlow();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
