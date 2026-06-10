(function authTenantStatePersistenceRuntime(global) {
  "use strict";

  const STORAGE_KEYS = {
    session: "pix2pi.session",
    authToken: "pix2pi.authToken",
    refreshToken: "pix2pi.refreshToken",
    activeTenant: "pix2pi.activeTenant",
    tenantContext: "pix2pi.tenantContext",
    lastRefresh: "pix2pi.lastRefresh",
    logoutSignal: "pix2pi.logoutSignal",
    stateRevision: "pix2pi.stateRevision"
  };

  const EVENTS = {
    stateChanged: "pix2pi:auth-state-changed",
    sessionRefreshed: "pix2pi:session-refreshed",
    logout: "pix2pi:logout",
    tenantStateChanged: "pix2pi:tenant-state-changed"
  };

  const CHANNEL_NAME = "pix2pi-auth-state";

  function nowIso() {
    return new Date().toISOString();
  }

  function addMinutes(date, minutes) {
    return new Date(date.getTime() + minutes * 60 * 1000);
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

  function getBroadcastChannel() {
    if (typeof global.BroadcastChannel === "function") {
      return new global.BroadcastChannel(CHANNEL_NAME);
    }

    return null;
  }

  let broadcastChannel = null;

  function ensureBroadcastChannel() {
    if (!broadcastChannel) {
      broadcastChannel = getBroadcastChannel();
      if (broadcastChannel) {
        broadcastChannel.onmessage = function onBroadcastMessage(event) {
          handleExternalStateMessage(event.data || {});
        };
      }
    }

    return broadcastChannel;
  }

  function getStateRevision() {
    const raw = Number(storage.getItem(STORAGE_KEYS.stateRevision) || "0");
    return Number.isFinite(raw) ? raw : 0;
  }

  function bumpStateRevision() {
    const next = getStateRevision() + 1;
    storage.setItem(STORAGE_KEYS.stateRevision, String(next));
    return next;
  }

  function dispatchEvent(name, detail) {
    if (typeof global.CustomEvent === "function" && typeof global.dispatchEvent === "function") {
      global.dispatchEvent(new CustomEvent(name, { detail }));
    }
  }

  function broadcastState(type, payload) {
    const message = {
      type,
      payload,
      revision: getStateRevision(),
      sent_at: nowIso()
    };

    const channel = ensureBroadcastChannel();
    if (channel) {
      channel.postMessage(message);
    }

    dispatchEvent(EVENTS.stateChanged, message);
    return message;
  }

  function createDemoSession(minutesToLive) {
    const issued = new Date();
    const expires = addMinutes(issued, minutesToLive || 30);

    return {
      user_id: "demo-user-001",
      display_name: "Pix2pi Demo Kullanıcı",
      roles: ["TENANT_ADMIN", "ACCOUNTANT"],
      permissions: ["tenant:view", "tenant:switch", "dashboard:view", "erp:view"],
      issued_at: issued.toISOString(),
      expires_at: expires.toISOString(),
      refresh_count: 0
    };
  }

  function createDemoTenant() {
    return {
      tenant_id: "tenant_7",
      tenant_uuid: "6dfe8d22-035a-401f-807c-507408d2e439",
      tenant_name: "Pix2pi Pilot İşletme",
      tenant_code: "PIX2PI-PILOT",
      selected_at: nowIso()
    };
  }

  function saveSessionState(session, options) {
    const opts = options || {};
    const normalized = Object.assign({}, session, {
      updated_at: nowIso()
    });

    storage.setItem(STORAGE_KEYS.session, JSON.stringify(normalized));
    storage.setItem(STORAGE_KEYS.authToken, "demo-access-token-" + bumpStateRevision());
    storage.setItem(STORAGE_KEYS.refreshToken, "demo-refresh-token-" + getStateRevision());

    if (!opts.silent) {
      broadcastState("SESSION_STATE_SAVED", normalized);
      renderAuthTenantState();
      logStateEvent("SESSION_STATE_SAVED", normalized);
    }

    return normalized;
  }

  function getSessionState() {
    return safeJsonParse(storage.getItem(STORAGE_KEYS.session), null);
  }

  function isSessionExpired(session) {
    if (!session || !session.expires_at) {
      return true;
    }

    return new Date(session.expires_at).getTime() <= Date.now();
  }

  function shouldRefreshSession(session, thresholdMinutes) {
    if (!session || !session.expires_at) {
      return false;
    }

    const threshold = (thresholdMinutes || 5) * 60 * 1000;
    const remaining = new Date(session.expires_at).getTime() - Date.now();

    return remaining > 0 && remaining <= threshold;
  }

  function refreshSessionState() {
    const current = getSessionState();

    if (!current || isSessionExpired(current)) {
      clearAuthState({
        reason: "REFRESH_FAILED_EXPIRED_SESSION"
      });
      return null;
    }

    const refreshed = Object.assign({}, current, {
      issued_at: nowIso(),
      expires_at: addMinutes(new Date(), 30).toISOString(),
      refresh_count: Number(current.refresh_count || 0) + 1,
      refreshed_at: nowIso()
    });

    storage.setItem(STORAGE_KEYS.lastRefresh, JSON.stringify({
      refreshed_at: refreshed.refreshed_at,
      refresh_count: refreshed.refresh_count
    }));

    saveSessionState(refreshed, { silent: true });
    broadcastState("SESSION_REFRESHED", refreshed);
    dispatchEvent(EVENTS.sessionRefreshed, refreshed);
    renderAuthTenantState();
    logStateEvent("SESSION_REFRESHED", refreshed);

    return refreshed;
  }

  function saveTenantState(tenant, options) {
    const opts = options || {};
    const normalized = Object.assign({}, tenant, {
      selected_at: tenant.selected_at || nowIso(),
      updated_at: nowIso()
    });

    storage.setItem(STORAGE_KEYS.activeTenant, JSON.stringify(normalized));
    storage.setItem(STORAGE_KEYS.tenantContext, JSON.stringify({
      tenant_id: normalized.tenant_id,
      tenant_uuid: normalized.tenant_uuid,
      tenant_code: normalized.tenant_code,
      context_set_at: nowIso()
    }));

    bumpStateRevision();

    if (!opts.silent) {
      broadcastState("TENANT_STATE_SAVED", normalized);
      dispatchEvent(EVENTS.tenantStateChanged, normalized);
      renderAuthTenantState();
      logStateEvent("TENANT_STATE_SAVED", normalized);
    }

    return normalized;
  }

  function getTenantState() {
    return safeJsonParse(storage.getItem(STORAGE_KEYS.activeTenant), null);
  }

  function getTenantContext() {
    return safeJsonParse(storage.getItem(STORAGE_KEYS.tenantContext), null);
  }

  function clearAuthState(options) {
    const opts = options || {};
    const reason = opts.reason || "LOGOUT";

    storage.removeItem(STORAGE_KEYS.session);
    storage.removeItem(STORAGE_KEYS.authToken);
    storage.removeItem(STORAGE_KEYS.refreshToken);
    storage.removeItem(STORAGE_KEYS.activeTenant);
    storage.removeItem(STORAGE_KEYS.tenantContext);
    storage.removeItem(STORAGE_KEYS.lastRefresh);

    const signal = {
      reason,
      logout_at: nowIso(),
      revision: bumpStateRevision()
    };

    storage.setItem(STORAGE_KEYS.logoutSignal, JSON.stringify(signal));

    if (!opts.silent) {
      broadcastState("LOGOUT", signal);
      dispatchEvent(EVENTS.logout, signal);
      renderAuthTenantState();
      logStateEvent("LOGOUT", signal);
    }

    return signal;
  }

  function ensureInitialState() {
    if (!getSessionState()) {
      saveSessionState(createDemoSession(30), { silent: true });
    }

    if (!getTenantState()) {
      saveTenantState(createDemoTenant(), { silent: true });
    }

    renderAuthTenantState();
  }

  function handleExternalStateMessage(message) {
    if (!message || !message.type) {
      return;
    }

    if (message.type === "LOGOUT") {
      renderAuthTenantState();
      logStateEvent("MULTI_TAB_LOGOUT_RECEIVED", message);
      return;
    }

    if (message.type === "SESSION_STATE_SAVED" || message.type === "SESSION_REFRESHED" || message.type === "TENANT_STATE_SAVED") {
      renderAuthTenantState();
      logStateEvent("MULTI_TAB_STATE_SYNC_RECEIVED", message);
    }
  }

  function handleStorageEvent(event) {
    if (!event || !event.key) {
      return;
    }

    const watchedKeys = [
      STORAGE_KEYS.session,
      STORAGE_KEYS.activeTenant,
      STORAGE_KEYS.tenantContext,
      STORAGE_KEYS.logoutSignal,
      STORAGE_KEYS.stateRevision
    ];

    if (!watchedKeys.includes(event.key)) {
      return;
    }

    if (event.key === STORAGE_KEYS.logoutSignal) {
      logStateEvent("STORAGE_LOGOUT_SIGNAL_RECEIVED", safeJsonParse(event.newValue, {}));
    } else {
      logStateEvent("STORAGE_STATE_CHANGE_RECEIVED", {
        key: event.key
      });
    }

    renderAuthTenantState();
  }

  function validateAuthTenantState() {
    const session = getSessionState();
    const tenant = getTenantState();

    return {
      session_present: Boolean(session),
      session_expired: isSessionExpired(session),
      tenant_present: Boolean(tenant),
      tenant_context_present: Boolean(getTenantContext()),
      auth_token_present: Boolean(storage.getItem(STORAGE_KEYS.authToken)),
      refresh_token_present: Boolean(storage.getItem(STORAGE_KEYS.refreshToken)),
      state_revision: getStateRevision()
    };
  }

  function renderAuthTenantState() {
    const session = getSessionState();
    const tenant = getTenantState();
    const context = getTenantContext();
    const validation = validateAuthTenantState();

    const sessionEl = document.getElementById("sessionStateValue");
    const tenantEl = document.getElementById("tenantStateValue");
    const refreshEl = document.getElementById("refreshStateValue");
    const logoutEl = document.getElementById("logoutStateValue");
    const multiTabEl = document.getElementById("multiTabStateValue");
    const validationEl = document.getElementById("stateValidationValue");

    if (sessionEl) {
      sessionEl.textContent = session ? JSON.stringify(session, null, 2) : "SESSION_EMPTY";
    }

    if (tenantEl) {
      tenantEl.textContent = tenant ? JSON.stringify({ tenant, context }, null, 2) : "TENANT_EMPTY";
    }

    if (refreshEl) {
      refreshEl.textContent = JSON.stringify({
        should_refresh: shouldRefreshSession(session, 5),
        last_refresh: safeJsonParse(storage.getItem(STORAGE_KEYS.lastRefresh), null)
      }, null, 2);
    }

    if (logoutEl) {
      logoutEl.textContent = storage.getItem(STORAGE_KEYS.logoutSignal) || "LOGOUT_SIGNAL_EMPTY";
    }

    if (multiTabEl) {
      multiTabEl.textContent = JSON.stringify({
        broadcast_channel: typeof global.BroadcastChannel === "function" ? "SUPPORTED" : "UNAVAILABLE",
        storage_event_listener: "REGISTERED",
        state_revision: getStateRevision()
      }, null, 2);
    }

    if (validationEl) {
      validationEl.textContent = JSON.stringify(validation, null, 2);
    }

    return validation;
  }

  function logStateEvent(type, payload) {
    const log = document.getElementById("authStateLog");
    if (!log) {
      return;
    }

    const line = "[" + nowIso() + "] " + type + " " + JSON.stringify(payload);
    log.textContent = line + "\n" + log.textContent;
  }

  function bootstrapAuthTenantStatePersistence() {
    ensureBroadcastChannel();

    if (global.addEventListener) {
      global.addEventListener("storage", handleStorageEvent);
    }

    const createSessionButton = document.getElementById("createSessionButton");
    const refreshSessionButton = document.getElementById("refreshSessionButton");
    const expireSessionButton = document.getElementById("expireSessionButton");
    const saveTenantButton = document.getElementById("saveTenantButton");
    const logoutButton = document.getElementById("logoutButton");
    const validateButton = document.getElementById("validateStateButton");

    if (createSessionButton) {
      createSessionButton.addEventListener("click", () => saveSessionState(createDemoSession(30)));
    }

    if (refreshSessionButton) {
      refreshSessionButton.addEventListener("click", refreshSessionState);
    }

    if (expireSessionButton) {
      expireSessionButton.addEventListener("click", () => saveSessionState(createDemoSession(-1)));
    }

    if (saveTenantButton) {
      saveTenantButton.addEventListener("click", () => saveTenantState(createDemoTenant()));
    }

    if (logoutButton) {
      logoutButton.addEventListener("click", () => clearAuthState({ reason: "USER_LOGOUT" }));
    }

    if (validateButton) {
      validateButton.addEventListener("click", () => {
        const validation = renderAuthTenantState();
        logStateEvent("STATE_VALIDATED", validation);
      });
    }

    ensureInitialState();
  }

  const api = {
    STORAGE_KEYS,
    EVENTS,
    CHANNEL_NAME,
    createDemoSession,
    createDemoTenant,
    saveSessionState,
    getSessionState,
    isSessionExpired,
    shouldRefreshSession,
    refreshSessionState,
    saveTenantState,
    getTenantState,
    getTenantContext,
    clearAuthState,
    ensureInitialState,
    handleExternalStateMessage,
    handleStorageEvent,
    validateAuthTenantState,
    renderAuthTenantState,
    bootstrapAuthTenantStatePersistence
  };

  global.Pix2piAuthTenantStatePersistence = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapAuthTenantStatePersistence);
    } else {
      bootstrapAuthTenantStatePersistence();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
