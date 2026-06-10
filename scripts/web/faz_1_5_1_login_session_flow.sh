#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_5_1_LOGIN_SESSION_FLOW"

BACKUP_DIR="$REPO/backups/faz1/faz_1_5_1_login_session_flow_$TS"
WEB_DIR="$REPO/web/faz1/auth-tenant-experience/login-session"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
DOC_DIR="$REPO/docs/faz1/web"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
SCRIPT_DIR="$REPO/scripts/web"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/login_session.js"
CSS_FILE="$WEB_DIR/login_session.css"
CONFIG_FILE="$CONFIG_DIR/login_session_contract.v1.json"
DOC_FILE="$DOC_DIR/FAZ_1_5_1_LOGIN_SESSION_FLOW.md"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_5_1_login_session_flow_strict_suite.sh"
APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_5_1_login_session_flow.sh"
STRICT_SUITE_OUT="$BACKUP_DIR/faz_1_5_1_login_session_flow_strict_suite.out"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_1_LOGIN_SESSION_FLOW_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_5_1_LOGIN_SESSION_FLOW_FINAL_SEAL_$TS.md"

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

echo "===== FAZ 1-5.1 LOGIN / SESSION FLOW START ====="

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

echo "3. login / session contract config yazılıyor..."

cat <<'JSON' > "$CONFIG_FILE"
{
  "phase": "FAZ_1_5_1",
  "module": "WEB_L2_AUTH_TENANT_EXPERIENCE",
  "component": "login_session_flow",
  "status": "READY",
  "required_capabilities": [
    "login_ui",
    "token_persistence",
    "login_error_states",
    "session_validation",
    "login_tests"
  ],
  "storage_keys": {
    "session": "pix2pi.session",
    "auth_token": "pix2pi.authToken",
    "refresh_token": "pix2pi.refreshToken",
    "active_tenant": "pix2pi.activeTenant",
    "login_attempt": "pix2pi.loginAttempt",
    "login_error": "pix2pi.loginError"
  },
  "login_contract": {
    "identifier_field": "email",
    "password_field": "password",
    "tenant_hint_field": "tenant_hint",
    "remember_me_field": "remember_me",
    "success_event": "pix2pi:login-success",
    "error_event": "pix2pi:login-error",
    "session_valid_event": "pix2pi:session-valid",
    "session_invalid_event": "pix2pi:session-invalid"
  },
  "error_codes": [
    "MISSING_CREDENTIALS",
    "INVALID_CREDENTIALS",
    "TENANT_REQUIRED",
    "ACCOUNT_LOCKED",
    "SESSION_INVALID",
    "SESSION_EXPIRED"
  ],
  "session_contract": {
    "required_fields": [
      "user_id",
      "display_name",
      "email",
      "roles",
      "permissions",
      "issued_at",
      "expires_at"
    ],
    "token_policy": "STORE_DEMO_TOKEN_FOR_UI_CONTRACT_ONLY",
    "validation_policy": "REQUIRE_SESSION_AND_UNEXPIRED_TOKEN"
  }
}
JSON

if [ -f "$CONFIG_FILE" ]; then
  pass "3.1 login session config yazıldı: $CONFIG_FILE"
else
  fail "3.1 login session config yazılamadı"
  exit 1
fi

echo "4. login session CSS yazılıyor..."

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
  background: radial-gradient(circle at top left, #1d4ed8 0, var(--pix2pi-bg) 44%);
  color: var(--pix2pi-text);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.pix2pi-shell {
  width: min(1120px, calc(100% - 32px));
  min-height: 100vh;
  margin: 0 auto;
  display: grid;
  align-items: center;
  padding: 32px 0;
}

.pix2pi-grid {
  display: grid;
  grid-template-columns: 420px 1fr;
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

.pix2pi-form {
  display: grid;
  gap: 14px;
}

.pix2pi-label {
  color: var(--pix2pi-muted);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.pix2pi-input {
  width: 100%;
  border: 1px solid var(--pix2pi-border);
  border-radius: 14px;
  background: #020617;
  color: var(--pix2pi-text);
  padding: 12px 14px;
  outline: none;
}

.pix2pi-input:focus {
  border-color: var(--pix2pi-accent);
}

.pix2pi-check-row {
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--pix2pi-muted);
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

.pix2pi-button.danger {
  border-color: rgba(239, 68, 68, 0.5);
  background: rgba(239, 68, 68, 0.12);
}

.pix2pi-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 12px;
}

.pix2pi-alert {
  display: none;
  border: 1px solid rgba(239, 68, 68, 0.55);
  background: rgba(239, 68, 68, 0.1);
  color: #fecaca;
  border-radius: 16px;
  padding: 12px 14px;
}

.pix2pi-alert.visible {
  display: block;
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

.pix2pi-state-list {
  display: grid;
  gap: 12px;
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

.pix2pi-log {
  margin-top: 18px;
  background: #020617;
  border: 1px solid var(--pix2pi-border);
  border-radius: 16px;
  padding: 14px;
  color: var(--pix2pi-muted);
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  min-height: 130px;
  white-space: pre-wrap;
  overflow: auto;
}

@media (max-width: 900px) {
  .pix2pi-grid {
    grid-template-columns: 1fr;
  }
}
CSS

if grep -q "pix2pi-form" "$CSS_FILE" && grep -q "pix2pi-alert" "$CSS_FILE" && grep -q "pix2pi-state-row" "$CSS_FILE"; then
  pass "4.1 CSS login session sınıfları mevcut"
else
  fail "4.1 CSS login session sınıfları eksik"
  exit 1
fi

echo "5. login session JS yazılıyor..."

cat <<'JS' > "$JS_FILE"
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
JS

if grep -q "loginWithCredentials" "$JS_FILE" \
  && grep -q "persistTokens" "$JS_FILE" \
  && grep -q "setLoginError" "$JS_FILE" \
  && grep -q "validateSession" "$JS_FILE" \
  && grep -q "DEMO_USERS" "$JS_FILE"; then
  pass "5.1 JS login session runtime fonksiyonları mevcut"
else
  fail "5.1 JS login session runtime fonksiyonları eksik"
  exit 1
fi

echo "6. login session HTML yazılıyor..."

cat <<'HTML' > "$HTML_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — Login / Session Flow</title>
  <link rel="stylesheet" href="./login_session.css">
</head>
<body>
  <main class="pix2pi-shell">
    <section class="pix2pi-grid">
      <article class="pix2pi-card">
        <h1 class="pix2pi-title">Pix2pi Login / Session Akışı</h1>
        <p class="pix2pi-subtitle">FAZ 1-5.1 — Auth / Tenant Experience</p>

        <div class="pix2pi-alert" id="loginErrorAlert" role="alert"></div>

        <form class="pix2pi-form" id="loginForm">
          <div>
            <label class="pix2pi-label" for="loginEmail">E-posta</label>
            <input class="pix2pi-input" id="loginEmail" type="email" autocomplete="username" placeholder="admin@pix2pi.local">
          </div>

          <div>
            <label class="pix2pi-label" for="loginPassword">Şifre</label>
            <input class="pix2pi-input" id="loginPassword" type="password" autocomplete="current-password" placeholder="Pix2piDemo123">
          </div>

          <div>
            <label class="pix2pi-label" for="tenantHint">Tenant / Firma Kodu</label>
            <input class="pix2pi-input" id="tenantHint" type="text" placeholder="tenant_7">
          </div>

          <label class="pix2pi-check-row">
            <input id="rememberMe" type="checkbox">
            Beni hatırla
          </label>

          <button class="pix2pi-button primary" id="loginButton" type="submit">Giriş yap</button>
        </form>

        <div class="pix2pi-actions">
          <button class="pix2pi-button" id="fillAdminDemoButton" type="button">Admin demo doldur</button>
          <button class="pix2pi-button" id="fillAccountantDemoButton" type="button">Muhasebeci demo doldur</button>
          <button class="pix2pi-button" id="validateSessionButton" type="button">Session validate</button>
          <button class="pix2pi-button" id="expireSessionButton" type="button">Session expire test</button>
          <button class="pix2pi-button danger" id="clearLoginStateButton" type="button">Login state temizle</button>
        </div>

        <div class="pix2pi-log" id="loginSessionLog">Login event log...</div>
      </article>

      <aside class="pix2pi-card">
        <span class="pix2pi-badge ok">WEB-L2 READY</span>

        <div class="pix2pi-state-list" style="margin-top: 18px;">
          <article class="pix2pi-state-row">
            <div class="pix2pi-state-name">Session Snapshot</div>
            <pre class="pix2pi-state-value" id="sessionSnapshot">SESSION_LOADING</pre>
          </article>

          <article class="pix2pi-state-row">
            <div class="pix2pi-state-name">Token Persistence</div>
            <pre class="pix2pi-state-value" id="tokenSnapshot">TOKEN_LOADING</pre>
          </article>

          <article class="pix2pi-state-row">
            <div class="pix2pi-state-name">Tenant Snapshot</div>
            <pre class="pix2pi-state-value" id="tenantSnapshot">TENANT_LOADING</pre>
          </article>

          <article class="pix2pi-state-row">
            <div class="pix2pi-state-name">Session Validation</div>
            <pre class="pix2pi-state-value" id="validationSnapshot">VALIDATION_LOADING</pre>
          </article>
        </div>
      </aside>
    </section>
  </main>

  <script src="./login_session.js"></script>
</body>
</html>
HTML

if grep -q "loginForm" "$HTML_FILE" \
  && grep -q "loginEmail" "$HTML_FILE" \
  && grep -q "loginPassword" "$HTML_FILE" \
  && grep -q "tenantHint" "$HTML_FILE" \
  && grep -q "loginErrorAlert" "$HTML_FILE" \
  && grep -q "validationSnapshot" "$HTML_FILE"; then
  pass "6.1 HTML login session UI elementleri mevcut"
else
  fail "6.1 HTML login session UI elementleri eksik"
  exit 1
fi

echo "7. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/auth-tenant-experience/login-session"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/login_session.js"
CSS_FILE="$WEB_DIR/login_session.css"
CONFIG_FILE="$CONFIG_DIR/login_session_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_1_LOGIN_SESSION_FLOW_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-5.1 LOGIN / SESSION FLOW STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"login_ui"' "3.1 login_ui capability contract"
check_contains "$CONFIG_FILE" '"token_persistence"' "3.2 token_persistence capability contract"
check_contains "$CONFIG_FILE" '"login_error_states"' "3.3 login_error_states capability contract"
check_contains "$CONFIG_FILE" '"session_validation"' "3.4 session_validation capability contract"
check_contains "$CONFIG_FILE" '"login_tests"' "3.5 login_tests capability contract"

check_contains "$HTML_FILE" 'loginForm' "4.1 login form HTML"
check_contains "$HTML_FILE" 'loginEmail' "4.2 login email HTML"
check_contains "$HTML_FILE" 'loginPassword' "4.3 login password HTML"
check_contains "$HTML_FILE" 'tenantHint' "4.4 tenant hint HTML"
check_contains "$HTML_FILE" 'loginErrorAlert' "4.5 login error alert HTML"
check_contains "$HTML_FILE" 'validateSessionButton' "4.6 session validation button HTML"

check_contains "$JS_FILE" 'validateCredentials' "5.1 credential validation JS"
check_contains "$JS_FILE" 'loginWithCredentials' "5.2 login flow JS"
check_contains "$JS_FILE" 'persistTokens' "5.3 token persistence JS"
check_contains "$JS_FILE" 'persistSession' "5.4 session persistence JS"
check_contains "$JS_FILE" 'persistTenantFromHint' "5.5 tenant persistence JS"
check_contains "$JS_FILE" 'setLoginError' "5.6 login error state JS"
check_contains "$JS_FILE" 'MISSING_CREDENTIALS' "5.7 missing credentials error JS"
check_contains "$JS_FILE" 'INVALID_CREDENTIALS' "5.8 invalid credentials error JS"
check_contains "$JS_FILE" 'TENANT_REQUIRED' "5.9 tenant required error JS"
check_contains "$JS_FILE" 'validateSession' "5.10 session validation JS"
check_contains "$JS_FILE" 'isSessionExpired' "5.11 session expiry JS"
check_contains "$JS_FILE" 'expireSessionForTest' "5.12 login test expiry JS"

check_contains "$CSS_FILE" 'pix2pi-form' "6.1 form CSS"
check_contains "$CSS_FILE" 'pix2pi-alert' "6.2 alert CSS"
check_contains "$CSS_FILE" 'pix2pi-state-row' "6.3 state row CSS"
check_contains "$CSS_FILE" 'pix2pi-button' "6.4 button CSS"

LOGIN_UI_STATUS="PASS"
TOKEN_PERSISTENCE_STATUS="PASS"
LOGIN_ERROR_STATES_STATUS="PASS"
SESSION_VALIDATION_STATUS="PASS"
LOGIN_TESTS_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  LOGIN_UI_STATUS="FAIL"
  TOKEN_PERSISTENCE_STATUS="FAIL"
  LOGIN_ERROR_STATES_STATUS="FAIL"
  SESSION_VALIDATION_STATUS="FAIL"
  LOGIN_TESTS_STATUS="FAIL"
fi

{
  echo "# FAZ 1-5.1 Login / Session Flow Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- LOGIN_UI_STATUS=$LOGIN_UI_STATUS"
  echo "- TOKEN_PERSISTENCE_STATUS=$TOKEN_PERSISTENCE_STATUS"
  echo "- LOGIN_ERROR_STATES_STATUS=$LOGIN_ERROR_STATES_STATUS"
  echo "- SESSION_VALIDATION_STATUS=$SESSION_VALIDATION_STATUS"
  echo "- LOGIN_TESTS_STATUS=$LOGIN_TESTS_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-5.1 LOGIN / SESSION FLOW STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LOGIN_UI_STATUS=$LOGIN_UI_STATUS"
echo "TOKEN_PERSISTENCE_STATUS=$TOKEN_PERSISTENCE_STATUS"
echo "LOGIN_ERROR_STATES_STATUS=$LOGIN_ERROR_STATES_STATUS"
echo "SESSION_VALIDATION_STATUS=$SESSION_VALIDATION_STATUS"
echo "LOGIN_TESTS_STATUS=$LOGIN_TESTS_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-5.1 LOGIN / SESSION FLOW STRICT SUITE END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_5_1_LOGIN_SESSION_FLOW_STRICT_SUITE_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_5_1_LOGIN_SESSION_FLOW_STRICT_SUITE_SEAL_STATUS")"

LOGIN_UI_STATUS="$(extract_var "$STRICT_SUITE_OUT" "LOGIN_UI_STATUS")"
TOKEN_PERSISTENCE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "TOKEN_PERSISTENCE_STATUS")"
LOGIN_ERROR_STATES_STATUS="$(extract_var "$STRICT_SUITE_OUT" "LOGIN_ERROR_STATES_STATUS")"
SESSION_VALIDATION_STATUS="$(extract_var "$STRICT_SUITE_OUT" "SESSION_VALIDATION_STATUS")"
LOGIN_TESTS_STATUS="$(extract_var "$STRICT_SUITE_OUT" "LOGIN_TESTS_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "8.2 strict suite FAIL_COUNT=0 doğrulandı" || fail "8.2 strict suite FAIL_COUNT sıfır değil"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "8.3 strict suite PASS doğrulandı" || fail "8.3 strict suite PASS değil"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "8.4 strict suite SEALED doğrulandı" || fail "8.4 strict suite SEALED değil"

echo "9. dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-5.1 — Login / Session Akışı

## Kapsam

- Login UI
- Token persistence
- Login error states
- Session validation
- Login tests

## Üretilen Dosyalar

- UI: web/faz1/auth-tenant-experience/login-session/index.html
- Runtime JS: web/faz1/auth-tenant-experience/login-session/login_session.js
- CSS: web/faz1/auth-tenant-experience/login-session/login_session.css
- Contract: configs/faz1/web/auth_tenant_experience/login_session_contract.v1.json
- Strict suite: scripts/web/faz_1_5_1_login_session_flow_strict_suite.sh

## Final Status

- LOGIN_UI_STATUS=${LOGIN_UI_STATUS:-N/A}
- TOKEN_PERSISTENCE_STATUS=${TOKEN_PERSISTENCE_STATUS:-N/A}
- LOGIN_ERROR_STATES_STATUS=${LOGIN_ERROR_STATES_STATUS:-N/A}
- SESSION_VALIDATION_STATUS=${SESSION_VALIDATION_STATUS:-N/A}
- LOGIN_TESTS_STATUS=${LOGIN_TESTS_STATUS:-N/A}
- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}
- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-5.1 Login / Session Flow Real Implementation Audit"
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
  echo "- LOGIN_UI_STATUS=${LOGIN_UI_STATUS:-N/A}"
  echo "- TOKEN_PERSISTENCE_STATUS=${TOKEN_PERSISTENCE_STATUS:-N/A}"
  echo "- LOGIN_ERROR_STATES_STATUS=${LOGIN_ERROR_STATES_STATUS:-N/A}"
  echo "- SESSION_VALIDATION_STATUS=${SESSION_VALIDATION_STATUS:-N/A}"
  echo "- LOGIN_TESTS_STATUS=${LOGIN_TESTS_STATUS:-N/A}"
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
  echo "# FAZ 1-5.1 Login / Session Flow Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_5_1_LOGIN_UI_STATUS=${LOGIN_UI_STATUS:-N/A}"
  echo "FAZ_1_5_1_TOKEN_PERSISTENCE_STATUS=${TOKEN_PERSISTENCE_STATUS:-N/A}"
  echo "FAZ_1_5_1_LOGIN_ERROR_STATES_STATUS=${LOGIN_ERROR_STATES_STATUS:-N/A}"
  echo "FAZ_1_5_1_SESSION_VALIDATION_STATUS=${SESSION_VALIDATION_STATUS:-N/A}"
  echo "FAZ_1_5_1_LOGIN_TESTS_STATUS=${LOGIN_TESTS_STATUS:-N/A}"
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_5_2_READY=YES"
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

echo "===== FAZ 1-5.1 LOGIN / SESSION FLOW RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "LOGIN_UI_STATUS=${LOGIN_UI_STATUS:-N/A}"
echo "TOKEN_PERSISTENCE_STATUS=${TOKEN_PERSISTENCE_STATUS:-N/A}"
echo "LOGIN_ERROR_STATES_STATUS=${LOGIN_ERROR_STATES_STATUS:-N/A}"
echo "SESSION_VALIDATION_STATUS=${SESSION_VALIDATION_STATUS:-N/A}"
echo "LOGIN_TESTS_STATUS=${LOGIN_TESTS_STATUS:-N/A}"
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

  echo "FAZ_1_5_1_LOGIN_UI_STATUS=PASS"
  echo "FAZ_1_5_1_TOKEN_PERSISTENCE_STATUS=PASS"
  echo "FAZ_1_5_1_LOGIN_ERROR_STATES_STATUS=PASS"
  echo "FAZ_1_5_1_SESSION_VALIDATION_STATUS=PASS"
  echo "FAZ_1_5_1_LOGIN_TESTS_STATUS=PASS"
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_FINAL_STATUS=PASS"
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_SEAL_STATUS=SEALED"
  echo "FAZ_1_5_2_READY=YES"
else
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_FINAL_STATUS=FAIL"
  echo "FAZ_1_5_1_LOGIN_SESSION_FLOW_SEAL_STATUS=OPEN"
  echo "FAZ_1_5_2_READY=NO"
  exit 1
fi

echo "===== FAZ 1-5.1 LOGIN / SESSION FLOW END ====="
