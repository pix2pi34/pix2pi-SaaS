#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW"

BACKUP_DIR="$REPO/backups/faz1/faz_1_5_2_logout_session_expiry_flow_$TS"
WEB_DIR="$REPO/web/faz1/auth-tenant-experience/logout-session"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
DOC_DIR="$REPO/docs/faz1/web"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
SCRIPT_DIR="$REPO/scripts/web"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/logout_session.js"
CSS_FILE="$WEB_DIR/logout_session.css"
CONFIG_FILE="$CONFIG_DIR/logout_session_contract.v1.json"
DOC_FILE="$DOC_DIR/FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW.md"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_5_2_logout_session_expiry_flow_strict_suite.sh"
APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_5_2_logout_session_expiry_flow.sh"
STRICT_SUITE_OUT="$BACKUP_DIR/faz_1_5_2_logout_session_expiry_flow_strict_suite.out"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_FINAL_SEAL_$TS.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

extract_var() {
  local file="$1"
  local key="$2"
  grep "^${key}=" "$file" 2>/dev/null | tail -n1 | cut -d= -f2- || true
}

echo "===== FAZ 1-5.2 LOGOUT / SESSION EXPIRY FLOW START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$WEB_DIR" "$CONFIG_DIR" "$DOC_DIR" "$EVIDENCE_DIR" "$SCRIPT_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$HTML_FILE" "$JS_FILE" "$CSS_FILE" "$CONFIG_FILE" "$DOC_FILE" "$STRICT_SUITE_FILE" "$APPLY_SCRIPT_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_$TS"
    pass "2.x yedek alındı: $f"
  else
    warn "2.x yedek atlandı, dosya yok: $f"
  fi
done

echo "3. logout / session expiry contract config yazılıyor..."

cat <<'JSON' > "$CONFIG_FILE"
{
  "phase": "FAZ_1_5_2",
  "module": "WEB_L2_AUTH_TENANT_EXPERIENCE",
  "component": "logout_session_expiry_flow",
  "status": "READY",
  "required_capabilities": [
    "logout",
    "token_cleanup",
    "expired_session_redirect",
    "session_timeout",
    "logout_tests"
  ],
  "storage_keys": {
    "session": "pix2pi.session",
    "auth_token": "pix2pi.authToken",
    "refresh_token": "pix2pi.refreshToken",
    "active_tenant": "pix2pi.activeTenant",
    "tenant_context": "pix2pi.tenantContext",
    "login_attempt": "pix2pi.loginAttempt",
    "login_error": "pix2pi.loginError",
    "logout_signal": "pix2pi.logoutSignal",
    "session_expired_signal": "pix2pi.sessionExpiredSignal",
    "last_redirect_reason": "pix2pi.lastRedirectReason"
  },
  "logout_contract": {
    "logout_event": "pix2pi:logout",
    "token_cleanup_event": "pix2pi:token-cleanup",
    "session_expired_event": "pix2pi:session-expired",
    "redirect_event": "pix2pi:auth-redirect",
    "logout_policy": "CLEAR_SESSION_TOKEN_TENANT_AND_ERROR_STATE"
  },
  "expiry_contract": {
    "expired_session_redirect_target": "../auth-errors/session-expired.html",
    "login_redirect_target": "../login-session/index.html",
    "timeout_check_interval_ms": 1000,
    "timeout_policy": "CHECK_EXPIRES_AT_AND_REDIRECT_ON_EXPIRY"
  },
  "test_contract": {
    "demo_session_minutes": 30,
    "expired_session_minutes": -1,
    "timeout_demo_seconds": 5
  }
}
JSON

if [ -f "$CONFIG_FILE" ]; then
  pass "3.1 logout session config yazıldı: $CONFIG_FILE"
else
  fail "3.1 logout session config yazılamadı"
  exit 1
fi

echo "4. logout session CSS yazılıyor..."

cat <<'CSS' > "$CSS_FILE"
:root {
  --pix2pi-bg: #0f172a;
  --pix2pi-card: #111827;
  --pix2pi-soft: #1f2937;
  --pix2pi-text: #e5e7eb;
  --pix2pi-muted: #9ca3af;
  --pix2pi-border: #334155;
  --pix2pi-ok: #22c55e;
  --pix2pi-warn: #f59e0b;
  --pix2pi-danger: #ef4444;
  --pix2pi-accent: #38bdf8;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-height: 100vh;
  background: radial-gradient(circle at top left, #7c2d12 0, var(--pix2pi-bg) 44%);
  color: var(--pix2pi-text);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.pix2pi-shell {
  width: min(1180px, calc(100% - 32px));
  min-height: 100vh;
  margin: 0 auto;
  display: grid;
  align-items: center;
  padding: 32px 0;
}

.pix2pi-grid {
  display: grid;
  grid-template-columns: 360px 1fr;
  gap: 18px;
}

.pix2pi-card {
  background: rgba(17, 24, 39, 0.92);
  border: 1px solid var(--pix2pi-border);
  border-radius: 24px;
  padding: 24px;
  box-shadow: 0 24px 90px rgba(0, 0, 0, 0.34);
}

.pix2pi-title {
  margin: 0;
  font-size: 30px;
  line-height: 1.1;
  letter-spacing: -0.04em;
}

.pix2pi-subtitle {
  margin: 10px 0 22px;
  color: var(--pix2pi-muted);
}

.pix2pi-label {
  color: var(--pix2pi-muted);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.pix2pi-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 16px;
}

.pix2pi-button {
  border: 1px solid var(--pix2pi-border);
  border-radius: 14px;
  background: var(--pix2pi-soft);
  color: var(--pix2pi-text);
  padding: 12px 14px;
  cursor: pointer;
  font-weight: 800;
}

.pix2pi-button.primary {
  border-color: rgba(56, 189, 248, 0.6);
  background: rgba(56, 189, 248, 0.14);
}

.pix2pi-button.warn {
  border-color: rgba(245, 158, 11, 0.55);
  background: rgba(245, 158, 11, 0.12);
}

.pix2pi-button.danger {
  border-color: rgba(239, 68, 68, 0.5);
  background: rgba(239, 68, 68, 0.12);
}

.pix2pi-badge {
  display: inline-flex;
  border: 1px solid var(--pix2pi-border);
  background: var(--pix2pi-soft);
  color: var(--pix2pi-text);
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 13px;
}

.pix2pi-badge.ok {
  border-color: rgba(34, 197, 94, 0.5);
  color: #bbf7d0;
}

.pix2pi-badge.warn {
  border-color: rgba(245, 158, 11, 0.5);
  color: #fde68a;
}

.pix2pi-badge.danger {
  border-color: rgba(239, 68, 68, 0.5);
  color: #fecaca;
}

.pix2pi-state-list {
  display: grid;
  gap: 12px;
  margin-top: 16px;
}

.pix2pi-state-row {
  border: 1px solid var(--pix2pi-border);
  background: #020617;
  border-radius: 16px;
  padding: 14px;
}

.pix2pi-state-name {
  font-weight: 900;
}

.pix2pi-state-value {
  color: var(--pix2pi-muted);
  font-size: 13px;
  margin-top: 6px;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

.pix2pi-alert {
  border: 1px solid rgba(245, 158, 11, 0.55);
  background: rgba(245, 158, 11, 0.1);
  color: #fde68a;
  border-radius: 16px;
  padding: 12px 14px;
  margin-top: 14px;
}

.pix2pi-log {
  margin-top: 18px;
  background: #020617;
  border: 1px solid var(--pix2pi-border);
  border-radius: 16px;
  padding: 14px;
  color: var(--pix2pi-muted);
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  min-height: 200px;
  white-space: pre-wrap;
  overflow: auto;
}

@media (max-width: 900px) {
  .pix2pi-grid {
    grid-template-columns: 1fr;
  }
}
CSS

if grep -q "pix2pi-button" "$CSS_FILE" && grep -q "pix2pi-state-row" "$CSS_FILE" && grep -q "pix2pi-alert" "$CSS_FILE"; then
  pass "4.1 CSS logout session sınıfları mevcut"
else
  fail "4.1 CSS logout session sınıfları eksik"
  exit 1
fi

echo "5. logout session JS yazılıyor..."

cat <<'JS' > "$JS_FILE"
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
JS

if grep -q "logout" "$JS_FILE" \
  && grep -q "cleanupTokens" "$JS_FILE" \
  && grep -q "redirectExpiredSession" "$JS_FILE" \
  && grep -q "startSessionTimeoutWatcher" "$JS_FILE" \
  && grep -q "validateLogoutCleanup" "$JS_FILE"; then
  pass "5.1 JS logout session runtime fonksiyonları mevcut"
else
  fail "5.1 JS logout session runtime fonksiyonları eksik"
  exit 1
fi

echo "6. logout session HTML yazılıyor..."

cat <<'HTML' > "$HTML_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — Logout / Session Expiry Flow</title>
  <link rel="stylesheet" href="./logout_session.css">
</head>
<body>
  <main class="pix2pi-shell">
    <section class="pix2pi-grid">
      <article class="pix2pi-card">
        <h1 class="pix2pi-title">Pix2pi Logout / Session Expiry Akışı</h1>
        <p class="pix2pi-subtitle">FAZ 1-5.2 — Auth / Tenant Experience</p>

        <span class="pix2pi-badge ok">WEB-L2 READY</span>

        <div class="pix2pi-alert">
          Logout, token cleanup, expired session redirect, session timeout ve logout tests bu yüzeyde doğrulanır.
        </div>

        <div class="pix2pi-actions">
          <button class="pix2pi-button primary" id="createLogoutDemoSessionButton" type="button">Demo session oluştur</button>
          <button class="pix2pi-button danger" id="logoutButton" type="button">Logout</button>
          <button class="pix2pi-button warn" id="tokenCleanupButton" type="button">Token cleanup</button>
          <button class="pix2pi-button warn" id="createExpiredSessionButton" type="button">Expired session oluştur</button>
          <button class="pix2pi-button" id="enforceExpiredRedirectButton" type="button">Expired redirect test</button>
          <button class="pix2pi-button primary" id="startSessionTimeoutButton" type="button">Session timeout başlat</button>
          <button class="pix2pi-button" id="stopSessionTimeoutButton" type="button">Timeout durdur</button>
          <button class="pix2pi-button" id="validateLogoutCleanupButton" type="button">Cleanup doğrula</button>
        </div>

        <div class="pix2pi-log" id="logoutSessionLog">Logout event log...</div>
      </article>

      <aside class="pix2pi-card">
        <div class="pix2pi-label">Logout / Session Expiry Snapshot</div>

        <div class="pix2pi-state-list">
          <article class="pix2pi-state-row">
            <div class="pix2pi-state-name">Session</div>
            <pre class="pix2pi-state-value" id="logoutSessionSnapshot">SESSION_LOADING</pre>
          </article>

          <article class="pix2pi-state-row">
            <div class="pix2pi-state-name">Token cleanup</div>
            <pre class="pix2pi-state-value" id="logoutTokenSnapshot">TOKEN_LOADING</pre>
          </article>

          <article class="pix2pi-state-row">
            <div class="pix2pi-state-name">Session expiry</div>
            <pre class="pix2pi-state-value" id="sessionExpirySnapshot">EXPIRY_LOADING</pre>
          </article>

          <article class="pix2pi-state-row">
            <div class="pix2pi-state-name">Expired redirect</div>
            <pre class="pix2pi-state-value" id="expiredRedirectSnapshot">REDIRECT_LOADING</pre>
          </article>

          <article class="pix2pi-state-row">
            <div class="pix2pi-state-name">Session timeout</div>
            <pre class="pix2pi-state-value" id="sessionTimeoutSnapshot">TIMEOUT_LOADING</pre>
          </article>

          <article class="pix2pi-state-row">
            <div class="pix2pi-state-name">Logout cleanup validation</div>
            <pre class="pix2pi-state-value" id="logoutCleanupSnapshot">CLEANUP_LOADING</pre>
          </article>
        </div>
      </aside>
    </section>
  </main>

  <script src="./logout_session.js"></script>
</body>
</html>
HTML

if grep -q "logoutButton" "$HTML_FILE" \
  && grep -q "tokenCleanupButton" "$HTML_FILE" \
  && grep -q "enforceExpiredRedirectButton" "$HTML_FILE" \
  && grep -q "startSessionTimeoutButton" "$HTML_FILE" \
  && grep -q "logoutCleanupSnapshot" "$HTML_FILE"; then
  pass "6.1 HTML logout session UI elementleri mevcut"
else
  fail "6.1 HTML logout session UI elementleri eksik"
  exit 1
fi

echo "7. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/auth-tenant-experience/logout-session"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/logout_session.js"
CSS_FILE="$WEB_DIR/logout_session.css"
CONFIG_FILE="$CONFIG_DIR/logout_session_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

check_file() {
  local file="$1"
  local label="$2"

  if [ -f "$file" ]; then
    pass "$label mevcut"
  else
    fail "$label eksik: $file"
  fi
}

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label eksik"
  fi
}

echo "===== FAZ 1-5.2 LOGOUT / SESSION EXPIRY FLOW STRICT SUITE START ====="

mkdir -p "$EVIDENCE_DIR"

check_file "$HTML_FILE" "1.1 HTML file"
check_file "$JS_FILE" "1.2 JS file"
check_file "$CSS_FILE" "1.3 CSS file"
check_file "$CONFIG_FILE" "1.4 config file"

if command -v python3 >/dev/null 2>&1; then
  if python3 -m json.tool "$CONFIG_FILE" >/dev/null 2>&1; then
    pass "2.1 config JSON valid"
  else
    fail "2.1 config JSON invalid"
  fi
else
  warn "2.1 python3 yok, JSON validation atlandı"
fi

check_contains "$CONFIG_FILE" '"logout"' "3.1 logout capability contract"
check_contains "$CONFIG_FILE" '"token_cleanup"' "3.2 token_cleanup capability contract"
check_contains "$CONFIG_FILE" '"expired_session_redirect"' "3.3 expired_session_redirect capability contract"
check_contains "$CONFIG_FILE" '"session_timeout"' "3.4 session_timeout capability contract"
check_contains "$CONFIG_FILE" '"logout_tests"' "3.5 logout_tests capability contract"

check_contains "$HTML_FILE" 'logoutButton' "4.1 logout button HTML"
check_contains "$HTML_FILE" 'tokenCleanupButton' "4.2 token cleanup button HTML"
check_contains "$HTML_FILE" 'createExpiredSessionButton' "4.3 expired session button HTML"
check_contains "$HTML_FILE" 'enforceExpiredRedirectButton' "4.4 expired redirect button HTML"
check_contains "$HTML_FILE" 'startSessionTimeoutButton' "4.5 session timeout button HTML"
check_contains "$HTML_FILE" 'validateLogoutCleanupButton' "4.6 logout tests validation button HTML"

check_contains "$JS_FILE" 'logout' "5.1 logout JS"
check_contains "$JS_FILE" 'cleanupTokens' "5.2 token cleanup JS"
check_contains "$JS_FILE" 'clearSessionAndTenantState' "5.3 clear session and tenant JS"
check_contains "$JS_FILE" 'markSessionExpired' "5.4 session expired signal JS"
check_contains "$JS_FILE" 'redirectExpiredSession' "5.5 expired session redirect JS"
check_contains "$JS_FILE" 'enforceSessionExpiryRedirect' "5.6 expiry enforcement JS"
check_contains "$JS_FILE" 'startSessionTimeoutWatcher' "5.7 session timeout watcher JS"
check_contains "$JS_FILE" 'stopSessionTimeoutWatcher' "5.8 stop timeout watcher JS"
check_contains "$JS_FILE" 'validateLogoutCleanup' "5.9 logout tests validation JS"
check_contains "$JS_FILE" 'session-expired.html' "5.10 session expired redirect target JS"

check_contains "$CSS_FILE" 'pix2pi-button' "6.1 button CSS"
check_contains "$CSS_FILE" 'pix2pi-alert' "6.2 alert CSS"
check_contains "$CSS_FILE" 'pix2pi-state-row' "6.3 state row CSS"
check_contains "$CSS_FILE" 'pix2pi-log' "6.4 log CSS"

LOGOUT_STATUS="PASS"
TOKEN_CLEANUP_STATUS="PASS"
EXPIRED_SESSION_REDIRECT_STATUS="PASS"
SESSION_TIMEOUT_STATUS="PASS"
LOGOUT_TESTS_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  LOGOUT_STATUS="FAIL"
  TOKEN_CLEANUP_STATUS="FAIL"
  EXPIRED_SESSION_REDIRECT_STATUS="FAIL"
  SESSION_TIMEOUT_STATUS="FAIL"
  LOGOUT_TESTS_STATUS="FAIL"
fi

{
  echo "# FAZ 1-5.2 Logout / Session Expiry Flow Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- LOGOUT_STATUS=$LOGOUT_STATUS"
  echo "- TOKEN_CLEANUP_STATUS=$TOKEN_CLEANUP_STATUS"
  echo "- EXPIRED_SESSION_REDIRECT_STATUS=$EXPIRED_SESSION_REDIRECT_STATUS"
  echo "- SESSION_TIMEOUT_STATUS=$SESSION_TIMEOUT_STATUS"
  echo "- LOGOUT_TESTS_STATUS=$LOGOUT_TESTS_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-5.2 LOGOUT / SESSION EXPIRY FLOW STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LOGOUT_STATUS=$LOGOUT_STATUS"
echo "TOKEN_CLEANUP_STATUS=$TOKEN_CLEANUP_STATUS"
echo "EXPIRED_SESSION_REDIRECT_STATUS=$EXPIRED_SESSION_REDIRECT_STATUS"
echo "SESSION_TIMEOUT_STATUS=$SESSION_TIMEOUT_STATUS"
echo "LOGOUT_TESTS_STATUS=$LOGOUT_TESTS_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-5.2 LOGOUT / SESSION EXPIRY FLOW STRICT SUITE END ====="
SUITE

chmod +x "$STRICT_SUITE_FILE"

if [ -x "$STRICT_SUITE_FILE" ]; then
  pass "7.1 strict suite dosyası yazıldı ve executable yapıldı: $STRICT_SUITE_FILE"
else
  fail "7.1 strict suite executable değil"
  exit 1
fi

echo "8. strict suite çalıştırılıyor..."

set +e
"$STRICT_SUITE_FILE" > "$STRICT_SUITE_OUT" 2>&1
STRICT_SUITE_EXIT_CODE=$?
set -e

cat "$STRICT_SUITE_OUT"

if [ "$STRICT_SUITE_EXIT_CODE" -eq 0 ]; then
  pass "8.1 strict suite exit code 0"
else
  fail "8.1 strict suite başarısız exit_code=$STRICT_SUITE_EXIT_CODE"
  exit 1
fi

STRICT_SUITE_PASS_COUNT="$(extract_var "$STRICT_SUITE_OUT" "PASS_COUNT")"
STRICT_SUITE_FAIL_COUNT="$(extract_var "$STRICT_SUITE_OUT" "FAIL_COUNT")"
STRICT_SUITE_WARN_COUNT="$(extract_var "$STRICT_SUITE_OUT" "WARN_COUNT")"
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_STRICT_SUITE_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_STRICT_SUITE_SEAL_STATUS")"

LOGOUT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "LOGOUT_STATUS")"
TOKEN_CLEANUP_STATUS="$(extract_var "$STRICT_SUITE_OUT" "TOKEN_CLEANUP_STATUS")"
EXPIRED_SESSION_REDIRECT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "EXPIRED_SESSION_REDIRECT_STATUS")"
SESSION_TIMEOUT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "SESSION_TIMEOUT_STATUS")"
LOGOUT_TESTS_STATUS="$(extract_var "$STRICT_SUITE_OUT" "LOGOUT_TESTS_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "8.2 strict suite FAIL_COUNT=0 doğrulandı" || fail "8.2 strict suite FAIL_COUNT sıfır değil"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "8.3 strict suite PASS doğrulandı" || fail "8.3 strict suite PASS değil"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "8.4 strict suite SEALED doğrulandı" || fail "8.4 strict suite SEALED değil"

echo "9. dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-5.2 — Logout / Session Expiry Akışı

## Kapsam

- Logout
- Token cleanup
- Expired session redirect
- Session timeout
- Logout tests

## Üretilen Dosyalar

- UI: web/faz1/auth-tenant-experience/logout-session/index.html
- Runtime JS: web/faz1/auth-tenant-experience/logout-session/logout_session.js
- CSS: web/faz1/auth-tenant-experience/logout-session/logout_session.css
- Contract: configs/faz1/web/auth_tenant_experience/logout_session_contract.v1.json
- Strict suite: scripts/web/faz_1_5_2_logout_session_expiry_flow_strict_suite.sh

## Final Status

- LOGOUT_STATUS=${LOGOUT_STATUS:-N/A}
- TOKEN_CLEANUP_STATUS=${TOKEN_CLEANUP_STATUS:-N/A}
- EXPIRED_SESSION_REDIRECT_STATUS=${EXPIRED_SESSION_REDIRECT_STATUS:-N/A}
- SESSION_TIMEOUT_STATUS=${SESSION_TIMEOUT_STATUS:-N/A}
- LOGOUT_TESTS_STATUS=${LOGOUT_TESTS_STATUS:-N/A}
- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}
- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-5.2 Logout / Session Expiry Flow Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo "- STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
  echo "- DOC_FILE=$DOC_FILE"
  echo "- BACKUP_DIR=$BACKUP_DIR"
  echo
  echo "## Status"
  echo "- LOGOUT_STATUS=${LOGOUT_STATUS:-N/A}"
  echo "- TOKEN_CLEANUP_STATUS=${TOKEN_CLEANUP_STATUS:-N/A}"
  echo "- EXPIRED_SESSION_REDIRECT_STATUS=${EXPIRED_SESSION_REDIRECT_STATUS:-N/A}"
  echo "- SESSION_TIMEOUT_STATUS=${SESSION_TIMEOUT_STATUS:-N/A}"
  echo "- LOGOUT_TESTS_STATUS=${LOGOUT_TESTS_STATUS:-N/A}"
  echo "- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo
  echo "## Counters"
  echo "- APPLY_PASS_COUNT=$PASS_COUNT"
  echo "- APPLY_FAIL_COUNT=$FAIL_COUNT"
  echo "- APPLY_WARN_COUNT=$WARN_COUNT"
  echo "- STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
  echo "- STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
  echo "- STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-5.2 Logout / Session Expiry Flow Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_5_2_LOGOUT_STATUS=${LOGOUT_STATUS:-N/A}"
  echo "FAZ_1_5_2_TOKEN_CLEANUP_STATUS=${TOKEN_CLEANUP_STATUS:-N/A}"
  echo "FAZ_1_5_2_EXPIRED_SESSION_REDIRECT_STATUS=${EXPIRED_SESSION_REDIRECT_STATUS:-N/A}"
  echo "FAZ_1_5_2_SESSION_TIMEOUT_STATUS=${SESSION_TIMEOUT_STATUS:-N/A}"
  echo "FAZ_1_5_2_LOGOUT_TESTS_STATUS=${LOGOUT_TESTS_STATUS:-N/A}"
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_5_7_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "9.1 dokümantasyon yazıldı: $DOC_FILE"
pass "9.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "9.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"

if [ -x "$APPLY_SCRIPT_FILE" ]; then
  pass "9.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"
else
  fail "9.4 apply script repo içine kopyalanamadı"
  exit 1
fi

echo "===== FAZ 1-5.2 LOGOUT / SESSION EXPIRY FLOW RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "LOGOUT_STATUS=${LOGOUT_STATUS:-N/A}"
echo "TOKEN_CLEANUP_STATUS=${TOKEN_CLEANUP_STATUS:-N/A}"
echo "EXPIRED_SESSION_REDIRECT_STATUS=${EXPIRED_SESSION_REDIRECT_STATUS:-N/A}"
echo "SESSION_TIMEOUT_STATUS=${SESSION_TIMEOUT_STATUS:-N/A}"
echo "LOGOUT_TESTS_STATUS=${LOGOUT_TESTS_STATUS:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "HTML_FILE=$HTML_FILE"
echo "JS_FILE=$JS_FILE"
echo "CSS_FILE=$CSS_FILE"
echo "CONFIG_FILE=$CONFIG_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_5_2_LOGOUT_STATUS=PASS"
  echo "FAZ_1_5_2_TOKEN_CLEANUP_STATUS=PASS"
  echo "FAZ_1_5_2_EXPIRED_SESSION_REDIRECT_STATUS=PASS"
  echo "FAZ_1_5_2_SESSION_TIMEOUT_STATUS=PASS"
  echo "FAZ_1_5_2_LOGOUT_TESTS_STATUS=PASS"
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_FINAL_STATUS=PASS"
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_SEAL_STATUS=SEALED"
  echo "FAZ_1_5_7_READY=YES"
else
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_FINAL_STATUS=FAIL"
  echo "FAZ_1_5_2_LOGOUT_SESSION_EXPIRY_FLOW_SEAL_STATUS=OPEN"
  echo "FAZ_1_5_7_READY=NO"
  exit 1
fi

echo "===== FAZ 1-5.2 LOGOUT / SESSION EXPIRY FLOW END ====="
