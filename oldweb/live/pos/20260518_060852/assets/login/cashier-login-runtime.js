/* PIX2PI_330_CASHIER_LOGIN_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "pos_cashier_login",
    phase: "FAZ_7R",
    step: "330",
    cashierLoginEndpoint: "/api/pos/auth/cashier-login",
    sessionVerifyEndpoint: "/api/pos/auth/session",
    saleScreenRedirectPath: "/sale/",
    selectedTenantKey: "pix2pi.pos.tenant.preference",
    deviceKey: "pix2pi.pos.device.id",
    cashierSessionKey: "pix2pi.pos.cashier.session",
    runtimeContract: {
      realBackendLoginEnabled: false,
      demoSessionEnabled: true,
      readyForStep331: true
    },
    lockoutPolicy: {
      maxFailedAttempts: 5,
      lockoutSeconds: 300
    }
  };

  function getSelectedTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || "controlled-pilot";
  }

  function getOrCreateDeviceId() {
    let deviceId = window.localStorage.getItem(CONFIG.deviceKey);
    if (!deviceId) {
      deviceId = "pos-device-" + Math.random().toString(36).slice(2, 10);
      window.localStorage.setItem(CONFIG.deviceKey, deviceId);
    }
    return deviceId;
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

  function tenantDeviceHeaders() {
    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getSelectedTenantId(),
      "X-POS-Device-ID": getOrCreateDeviceId(),
      "X-Pix2pi-Surface": "pos",
      "X-Pix2pi-Step": "330"
    };
  }

  function readLoginForm(form) {
    const data = {};
    new FormData(form).forEach(function (value, key) {
      data[key] = String(value || "").trim();
    });
    data.tenant_id = getSelectedTenantId();
    data.device_id = getOrCreateDeviceId();
    return data;
  }

  function validateCashierCode(value) {
    return /^[A-Za-z0-9_.-]{3,32}$/.test(String(value || ""));
  }

  function validatePin(value) {
    return /^[0-9]{4,8}$/.test(String(value || ""));
  }

  function validateLoginPayload(payload) {
    const errors = [];

    if (!validateCashierCode(payload.cashier_code)) {
      errors.push({ field: "cashier_code", code: "INVALID_CASHIER_CODE", message: "Kasiyer kodu 3-32 karakter olmalıdır" });
    }

    if (!validatePin(payload.pin)) {
      errors.push({ field: "pin", code: "INVALID_PIN", message: "PIN 4-8 haneli sayısal olmalıdır" });
    }

    if (!payload.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED", message: "Tenant bilgisi zorunludur" });
    }

    if (!payload.device_id) {
      errors.push({ field: "device_id", code: "DEVICE_REQUIRED", message: "POS cihaz bilgisi zorunludur" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  function buildLoginPayload(payload) {
    return {
      tenant_id: payload.tenant_id || getSelectedTenantId(),
      device_id: payload.device_id || getOrCreateDeviceId(),
      cashier_code: payload.cashier_code,
      pin_present: Boolean(payload.pin),
      auth_mode: "CASHIER_CODE_PIN",
      source: {
        surface: "pos_cashier_login",
        phase: "FAZ_7R",
        step: "330"
      }
    };
  }

  function buildDemoSession(payload) {
    return {
      tenant_id: payload.tenant_id || getSelectedTenantId(),
      device_id: payload.device_id || getOrCreateDeviceId(),
      cashier_code: payload.cashier_code,
      cashier_name: "Demo Kasiyer",
      role: "CASHIER",
      session_status: "DEMO_SESSION_READY",
      real_backend_login_enabled: false,
      created_at: new Date().toISOString(),
      expires_in_seconds: 28800,
      next_path: CONFIG.saleScreenRedirectPath
    };
  }

  function saveCashierSession(session) {
    window.localStorage.setItem(CONFIG.cashierSessionKey, JSON.stringify(session));
    return session;
  }

  function clearCashierSession() {
    window.localStorage.removeItem(CONFIG.cashierSessionKey);
  }

  async function apiJson(endpoint, options) {
    const response = await fetch(endpoint, Object.assign({
      headers: tenantDeviceHeaders()
    }, options || {}));

    if (!response.ok) {
      throw new Error("POS_CASHIER_AUTH_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function loginCashier(payload) {
    const validation = validateLoginPayload(payload);
    const loginPayload = buildLoginPayload(payload);

    if (!validation.valid) {
      return {
        logged_in: false,
        validation: validation,
        payload: loginPayload
      };
    }

    if (!CONFIG.runtimeContract.realBackendLoginEnabled) {
      const session = saveCashierSession(buildDemoSession(payload));
      return {
        logged_in: true,
        demo_session: true,
        validation: validation,
        session: session
      };
    }

    try {
      const response = await apiJson(CONFIG.cashierLoginEndpoint, {
        method: "POST",
        body: JSON.stringify(loginPayload)
      });

      if (response && response.session) {
        saveCashierSession(response.session);
      }

      return {
        logged_in: true,
        demo_session: false,
        validation: validation,
        response: response
      };
    } catch (_error) {
      return {
        logged_in: false,
        validation: validation,
        fallback_payload: loginPayload
      };
    }
  }

  async function verifyCashierSession() {
    const session = getCashierSession();

    if (!session) {
      return { valid: false, reason: "NO_SESSION" };
    }

    if (!CONFIG.runtimeContract.realBackendLoginEnabled) {
      return { valid: true, demo_session: true, session: session };
    }

    try {
      return await apiJson(CONFIG.sessionVerifyEndpoint, { method: "GET" });
    } catch (_error) {
      return { valid: false, reason: "SESSION_VERIFY_FAILED" };
    }
  }

  function renderLoginValidation(target, validation) {
    if (!target) return;

    if (validation.valid) {
      target.textContent = "Kasiyer giriş bilgileri geçerli.";
      target.setAttribute("data-validation-status", "valid");
      target.hidden = false;
      return;
    }

    target.textContent = validation.errors.map(function (err) {
      return err.message;
    }).join(" / ");
    target.setAttribute("data-validation-status", "invalid");
    target.hidden = false;
  }

  function renderLoginContext() {
    const tenant = document.getElementById("pos-login-tenant");
    const device = document.getElementById("pos-login-device");
    const session = document.getElementById("pos-login-session-status");

    if (tenant) tenant.textContent = getSelectedTenantId();
    if (device) device.textContent = getOrCreateDeviceId();

    const currentSession = getCashierSession();
    if (session) {
      session.textContent = currentSession ? currentSession.session_status : "NO_SESSION";
    }

    document.body.setAttribute("data-cashier-login-rendered", "true");
  }

  function bootCashierLoginScreen() {
    renderLoginContext();
    return {
      tenant_id: getSelectedTenantId(),
      device_id: getOrCreateDeviceId(),
      session: getCashierSession()
    };
  }

  window.Pix2piCashierLogin = {
    CONFIG: CONFIG,
    getSelectedTenantId: getSelectedTenantId,
    getOrCreateDeviceId: getOrCreateDeviceId,
    getCashierSession: getCashierSession,
    tenantDeviceHeaders: tenantDeviceHeaders,
    readLoginForm: readLoginForm,
    validateCashierCode: validateCashierCode,
    validatePin: validatePin,
    validateLoginPayload: validateLoginPayload,
    buildLoginPayload: buildLoginPayload,
    buildDemoSession: buildDemoSession,
    saveCashierSession: saveCashierSession,
    clearCashierSession: clearCashierSession,
    loginCashier: loginCashier,
    verifyCashierSession: verifyCashierSession,
    renderLoginValidation: renderLoginValidation,
    renderLoginContext: renderLoginContext,
    bootCashierLoginScreen: bootCashierLoginScreen
  };
})();
/* PIX2PI_330_CASHIER_LOGIN_RUNTIME_END */
