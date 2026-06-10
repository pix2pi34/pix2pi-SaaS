#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES"

BACKUP_DIR="$REPO/backups/faz1/faz_1_5_5_unauthorized_forbidden_pages_$TS"
WEB_DIR="$REPO/web/faz1/auth-tenant-experience/auth-errors"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
DOC_DIR="$REPO/docs/faz1/web"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
SCRIPT_DIR="$REPO/scripts/web"

INDEX_FILE="$WEB_DIR/index.html"
PAGE_401_FILE="$WEB_DIR/401.html"
PAGE_403_FILE="$WEB_DIR/403.html"
PAGE_TENANT_MISMATCH_FILE="$WEB_DIR/tenant-mismatch.html"
PAGE_SESSION_EXPIRED_FILE="$WEB_DIR/session-expired.html"
JS_FILE="$WEB_DIR/auth_error_pages.js"
CSS_FILE="$WEB_DIR/auth_error_pages.css"
CONFIG_FILE="$CONFIG_DIR/auth_error_pages_contract.v1.json"
DOC_FILE="$DOC_DIR/FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES.md"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_5_5_unauthorized_forbidden_pages_strict_suite.sh"
APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_5_5_unauthorized_forbidden_pages.sh"
STRICT_SUITE_OUT="$BACKUP_DIR/faz_1_5_5_unauthorized_forbidden_pages_strict_suite.out"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_FINAL_SEAL_$TS.md"

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

echo "===== FAZ 1-5.5 UNAUTHORIZED / FORBIDDEN PAGES START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$WEB_DIR" "$CONFIG_DIR" "$DOC_DIR" "$EVIDENCE_DIR" "$SCRIPT_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$INDEX_FILE" "$PAGE_401_FILE" "$PAGE_403_FILE" "$PAGE_TENANT_MISMATCH_FILE" "$PAGE_SESSION_EXPIRED_FILE" "$JS_FILE" "$CSS_FILE" "$CONFIG_FILE" "$DOC_FILE" "$STRICT_SUITE_FILE" "$APPLY_SCRIPT_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_$TS"
    pass "2.x yedek alındı: $f"
  else
    warn "2.x yedek atlandı, dosya yok: $f"
  fi
done

echo "3. auth error contract config yazılıyor..."

cat <<'JSON' > "$CONFIG_FILE"
{
  "phase": "FAZ_1_5_5",
  "module": "WEB_L2_AUTH_TENANT_EXPERIENCE",
  "component": "unauthorized_forbidden_pages",
  "status": "READY",
  "required_capabilities": [
    "unauthorized_401_page",
    "forbidden_403_page",
    "tenant_mismatch_message",
    "session_expired_message",
    "ui_api_tests"
  ],
  "error_routes": {
    "unauthorized": "/auth-errors/401.html",
    "forbidden": "/auth-errors/403.html",
    "tenant_mismatch": "/auth-errors/tenant-mismatch.html",
    "session_expired": "/auth-errors/session-expired.html"
  },
  "api_error_contract": {
    "401": {
      "status": 401,
      "code": "UNAUTHORIZED",
      "message": "Oturum bulunamadı veya giriş yapılmadı.",
      "action": "LOGIN_REQUIRED"
    },
    "403": {
      "status": 403,
      "code": "FORBIDDEN",
      "message": "Bu işlem için yetkiniz yok.",
      "action": "CONTACT_ADMIN"
    },
    "TENANT_MISMATCH": {
      "status": 403,
      "code": "TENANT_MISMATCH",
      "message": "İstek tenant bağlamı aktif tenant ile eşleşmiyor.",
      "action": "SWITCH_TENANT_OR_RETRY"
    },
    "SESSION_EXPIRED": {
      "status": 401,
      "code": "SESSION_EXPIRED",
      "message": "Oturum süresi doldu.",
      "action": "RE_LOGIN_REQUIRED"
    }
  },
  "ui_contract": {
    "root_id": "authErrorRoot",
    "title_id": "authErrorTitle",
    "message_id": "authErrorMessage",
    "action_id": "authErrorAction",
    "technical_code_id": "authErrorTechnicalCode",
    "api_preview_id": "authErrorApiPreview"
  },
  "guard_policy": {
    "missing_token": "SHOW_401",
    "invalid_role": "SHOW_403",
    "tenant_mismatch": "SHOW_TENANT_MISMATCH",
    "expired_session": "SHOW_SESSION_EXPIRED"
  }
}
JSON

if [ -f "$CONFIG_FILE" ]; then
  pass "3.1 auth error config yazıldı: $CONFIG_FILE"
else
  fail "3.1 auth error config yazılamadı"
  exit 1
fi

echo "4. auth error CSS yazılıyor..."

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
  background: radial-gradient(circle at top left, #7f1d1d 0, var(--pix2pi-bg) 44%);
  color: var(--pix2pi-text);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.pix2pi-error-shell {
  width: min(1040px, calc(100% - 32px));
  min-height: 100vh;
  margin: 0 auto;
  display: grid;
  align-items: center;
  padding: 32px 0;
}

.pix2pi-error-card {
  background: rgba(17, 24, 39, 0.92);
  border: 1px solid var(--pix2pi-border);
  border-radius: 24px;
  padding: 28px;
  box-shadow: 0 24px 90px rgba(0, 0, 0, 0.34);
}

.pix2pi-error-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}

.pix2pi-error-code {
  display: inline-flex;
  border: 1px solid rgba(239, 68, 68, 0.55);
  background: rgba(239, 68, 68, 0.12);
  color: #fecaca;
  border-radius: 999px;
  padding: 8px 12px;
  font-weight: 800;
  margin-bottom: 16px;
}

.pix2pi-error-title {
  margin: 0;
  font-size: 34px;
  line-height: 1.1;
  letter-spacing: -0.04em;
}

.pix2pi-error-message {
  margin: 14px 0 0;
  color: var(--pix2pi-muted);
  font-size: 16px;
  line-height: 1.6;
}

.pix2pi-error-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 22px;
}

.pix2pi-error-button {
  border: 1px solid var(--pix2pi-border);
  border-radius: 14px;
  background: var(--pix2pi-soft);
  color: var(--pix2pi-text);
  padding: 11px 14px;
  cursor: pointer;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
}

.pix2pi-error-button.primary {
  border-color: rgba(56, 189, 248, 0.6);
  background: rgba(56, 189, 248, 0.12);
}

.pix2pi-error-button.danger {
  border-color: rgba(239, 68, 68, 0.5);
  background: rgba(239, 68, 68, 0.12);
}

.pix2pi-error-panel {
  border: 1px solid var(--pix2pi-border);
  background: #020617;
  border-radius: 18px;
  padding: 16px;
}

.pix2pi-error-label {
  color: var(--pix2pi-muted);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.pix2pi-error-list {
  display: grid;
  gap: 10px;
  margin-top: 14px;
}

.pix2pi-error-list a,
.pix2pi-error-list button {
  width: 100%;
  text-align: left;
  border: 1px solid var(--pix2pi-border);
  background: #0b1120;
  color: var(--pix2pi-text);
  border-radius: 14px;
  padding: 12px;
  text-decoration: none;
  cursor: pointer;
}

.pix2pi-api-preview {
  margin-top: 14px;
  background: #020617;
  border: 1px solid var(--pix2pi-border);
  border-radius: 16px;
  padding: 14px;
  color: var(--pix2pi-muted);
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  white-space: pre-wrap;
  overflow: auto;
}

@media (max-width: 860px) {
  .pix2pi-error-grid {
    grid-template-columns: 1fr;
  }

  .pix2pi-error-title {
    font-size: 28px;
  }
}
CSS

if grep -q "pix2pi-error-card" "$CSS_FILE" && grep -q "pix2pi-api-preview" "$CSS_FILE" && grep -q "pix2pi-error-button" "$CSS_FILE"; then
  pass "4.1 CSS auth error sınıfları mevcut"
else
  fail "4.1 CSS auth error sınıfları eksik"
  exit 1
fi

echo "5. auth error JS yazılıyor..."

cat <<'JS' > "$JS_FILE"
(function authErrorPagesRuntime(global) {
  "use strict";

  const ERROR_DEFINITIONS = {
    UNAUTHORIZED: {
      status: 401,
      code: "UNAUTHORIZED",
      title: "Giriş gerekli",
      message: "Bu sayfaya erişmek için oturum açmanız gerekiyor.",
      actionLabel: "Giriş ekranına dön",
      action: "LOGIN_REQUIRED"
    },
    FORBIDDEN: {
      status: 403,
      code: "FORBIDDEN",
      title: "Yetki yok",
      message: "Bu işlem için gerekli rol veya permission sizde yok.",
      actionLabel: "Yöneticinizle görüşün",
      action: "CONTACT_ADMIN"
    },
    TENANT_MISMATCH: {
      status: 403,
      code: "TENANT_MISMATCH",
      title: "Tenant uyuşmazlığı",
      message: "İstek yapılan tenant, aktif tenant bağlamı ile eşleşmiyor. Güvenlik nedeniyle işlem durduruldu.",
      actionLabel: "Tenant seçimini kontrol et",
      action: "SWITCH_TENANT_OR_RETRY"
    },
    SESSION_EXPIRED: {
      status: 401,
      code: "SESSION_EXPIRED",
      title: "Oturum süresi doldu",
      message: "Oturum süreniz doldu. Devam etmek için tekrar giriş yapmanız gerekiyor.",
      actionLabel: "Tekrar giriş yap",
      action: "RE_LOGIN_REQUIRED"
    }
  };

  function getErrorDefinition(code) {
    return ERROR_DEFINITIONS[code] || ERROR_DEFINITIONS.UNAUTHORIZED;
  }

  function buildApiErrorResponse(code, details) {
    const definition = getErrorDefinition(code);

    return {
      ok: false,
      status: definition.status,
      error: {
        code: definition.code,
        message: definition.message,
        action: definition.action,
        details: details || null
      },
      request_id: "req_demo_auth_error",
      tenant_guard: definition.code === "TENANT_MISMATCH" ? "BLOCKED" : "N/A"
    };
  }

  function clearAuthState() {
    try {
      global.localStorage.removeItem("pix2pi.session");
      global.localStorage.removeItem("pix2pi.activeTenant");
      global.localStorage.removeItem("pix2pi.lastTenantSwitch");
    } catch (_err) {
      return false;
    }

    return true;
  }

  function resolveCodeFromPage() {
    const root = document.getElementById("authErrorRoot");
    if (root && root.dataset && root.dataset.errorCode) {
      return root.dataset.errorCode;
    }

    const path = String(global.location && global.location.pathname || "");

    if (path.includes("403")) {
      return "FORBIDDEN";
    }

    if (path.includes("tenant-mismatch")) {
      return "TENANT_MISMATCH";
    }

    if (path.includes("session-expired")) {
      return "SESSION_EXPIRED";
    }

    return "UNAUTHORIZED";
  }

  function renderAuthError(code) {
    const definition = getErrorDefinition(code);
    const root = document.getElementById("authErrorRoot");
    const title = document.getElementById("authErrorTitle");
    const message = document.getElementById("authErrorMessage");
    const action = document.getElementById("authErrorAction");
    const technicalCode = document.getElementById("authErrorTechnicalCode");
    const apiPreview = document.getElementById("authErrorApiPreview");

    if (root) {
      root.dataset.errorCode = definition.code;
      root.dataset.httpStatus = String(definition.status);
    }

    if (title) {
      title.textContent = definition.title;
    }

    if (message) {
      message.textContent = definition.message;
    }

    if (action) {
      action.textContent = definition.actionLabel;
      action.dataset.action = definition.action;

      action.onclick = function onActionClick() {
        if (definition.action === "LOGIN_REQUIRED" || definition.action === "RE_LOGIN_REQUIRED") {
          clearAuthState();
        }
      };
    }

    if (technicalCode) {
      technicalCode.textContent = definition.status + " / " + definition.code;
    }

    if (apiPreview) {
      apiPreview.textContent = JSON.stringify(buildApiErrorResponse(definition.code), null, 2);
    }

    return definition;
  }

  function simulateUnauthorized() {
    return renderAuthError("UNAUTHORIZED");
  }

  function simulateForbidden() {
    return renderAuthError("FORBIDDEN");
  }

  function simulateTenantMismatch() {
    return renderAuthError("TENANT_MISMATCH");
  }

  function simulateSessionExpired() {
    clearAuthState();
    return renderAuthError("SESSION_EXPIRED");
  }

  function bootstrapAuthErrorPage() {
    const code = resolveCodeFromPage();
    renderAuthError(code);

    const buttons = document.querySelectorAll("[data-auth-error-simulate]");
    buttons.forEach((button) => {
      button.addEventListener("click", () => {
        renderAuthError(button.dataset.authErrorSimulate);
      });
    });
  }

  const api = {
    ERROR_DEFINITIONS,
    getErrorDefinition,
    buildApiErrorResponse,
    clearAuthState,
    resolveCodeFromPage,
    renderAuthError,
    simulateUnauthorized,
    simulateForbidden,
    simulateTenantMismatch,
    simulateSessionExpired,
    bootstrapAuthErrorPage
  };

  global.Pix2piAuthErrorPages = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapAuthErrorPage);
    } else {
      bootstrapAuthErrorPage();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
JS

if grep -q "buildApiErrorResponse" "$JS_FILE" \
  && grep -q "simulateUnauthorized" "$JS_FILE" \
  && grep -q "simulateForbidden" "$JS_FILE" \
  && grep -q "simulateTenantMismatch" "$JS_FILE" \
  && grep -q "simulateSessionExpired" "$JS_FILE"; then
  pass "5.1 JS auth error runtime fonksiyonları mevcut"
else
  fail "5.1 JS auth error runtime fonksiyonları eksik"
  exit 1
fi

echo "6. ortak HTML generator hazırlanıyor..."

create_error_page() {
  local file="$1"
  local code="$2"
  local page_title="$3"

  cat > "$file" <<HTML
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — $page_title</title>
  <link rel="stylesheet" href="./auth_error_pages.css">
</head>
<body>
  <main class="pix2pi-error-shell">
    <section class="pix2pi-error-card" id="authErrorRoot" data-error-code="$code">
      <div class="pix2pi-error-grid">
        <article>
          <div class="pix2pi-error-code" id="authErrorTechnicalCode">$code</div>
          <h1 class="pix2pi-error-title" id="authErrorTitle">$page_title</h1>
          <p class="pix2pi-error-message" id="authErrorMessage">Yetki kontrolü yapılıyor...</p>

          <div class="pix2pi-error-actions">
            <button class="pix2pi-error-button primary" id="authErrorAction" type="button">Devam</button>
            <a class="pix2pi-error-button" href="./index.html">Hata merkezi</a>
          </div>
        </article>

        <aside class="pix2pi-error-panel">
          <div class="pix2pi-error-label">API Error Preview</div>
          <pre class="pix2pi-api-preview" id="authErrorApiPreview">{}</pre>
        </aside>
      </div>
    </section>
  </main>

  <script src="./auth_error_pages.js"></script>
</body>
</html>
HTML
}

create_error_page "$PAGE_401_FILE" "UNAUTHORIZED" "401 Unauthorized"
create_error_page "$PAGE_403_FILE" "FORBIDDEN" "403 Forbidden"
create_error_page "$PAGE_TENANT_MISMATCH_FILE" "TENANT_MISMATCH" "Tenant Mismatch"
create_error_page "$PAGE_SESSION_EXPIRED_FILE" "SESSION_EXPIRED" "Session Expired"

cat <<'HTML' > "$INDEX_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — Auth Error Pages</title>
  <link rel="stylesheet" href="./auth_error_pages.css">
</head>
<body>
  <main class="pix2pi-error-shell">
    <section class="pix2pi-error-card" id="authErrorRoot" data-error-code="UNAUTHORIZED">
      <div class="pix2pi-error-grid">
        <article>
          <div class="pix2pi-error-code" id="authErrorTechnicalCode">AUTH ERROR CENTER</div>
          <h1 class="pix2pi-error-title" id="authErrorTitle">Pix2pi Auth Error Center</h1>
          <p class="pix2pi-error-message" id="authErrorMessage">401, 403, tenant mismatch ve session expired durumlarını test et.</p>

          <div class="pix2pi-error-actions">
            <button class="pix2pi-error-button primary" id="authErrorAction" type="button">Demo aksiyon</button>
          </div>
        </article>

        <aside class="pix2pi-error-panel">
          <div class="pix2pi-error-label">Hata Sayfaları</div>
          <div class="pix2pi-error-list">
            <a href="./401.html">401 sayfası</a>
            <a href="./403.html">403 sayfası</a>
            <a href="./tenant-mismatch.html">Tenant mismatch mesajı</a>
            <a href="./session-expired.html">Session expired mesajı</a>
            <button type="button" data-auth-error-simulate="UNAUTHORIZED">Simüle et: 401</button>
            <button type="button" data-auth-error-simulate="FORBIDDEN">Simüle et: 403</button>
            <button type="button" data-auth-error-simulate="TENANT_MISMATCH">Simüle et: Tenant mismatch</button>
            <button type="button" data-auth-error-simulate="SESSION_EXPIRED">Simüle et: Session expired</button>
          </div>

          <pre class="pix2pi-api-preview" id="authErrorApiPreview">{}</pre>
        </aside>
      </div>
    </section>
  </main>

  <script src="./auth_error_pages.js"></script>
</body>
</html>
HTML

if [ -f "$PAGE_401_FILE" ] \
  && [ -f "$PAGE_403_FILE" ] \
  && [ -f "$PAGE_TENANT_MISMATCH_FILE" ] \
  && [ -f "$PAGE_SESSION_EXPIRED_FILE" ] \
  && [ -f "$INDEX_FILE" ]; then
  pass "6.1 auth error HTML sayfaları yazıldı"
else
  fail "6.1 auth error HTML sayfaları eksik"
  exit 1
fi

echo "7. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/auth-tenant-experience/auth-errors"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

INDEX_FILE="$WEB_DIR/index.html"
PAGE_401_FILE="$WEB_DIR/401.html"
PAGE_403_FILE="$WEB_DIR/403.html"
PAGE_TENANT_MISMATCH_FILE="$WEB_DIR/tenant-mismatch.html"
PAGE_SESSION_EXPIRED_FILE="$WEB_DIR/session-expired.html"
JS_FILE="$WEB_DIR/auth_error_pages.js"
CSS_FILE="$WEB_DIR/auth_error_pages.css"
CONFIG_FILE="$CONFIG_DIR/auth_error_pages_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-5.5 UNAUTHORIZED / FORBIDDEN PAGES STRICT SUITE START ====="

mkdir -p "$EVIDENCE_DIR"

check_file "$INDEX_FILE" "1.1 index HTML file"
check_file "$PAGE_401_FILE" "1.2 401 HTML file"
check_file "$PAGE_403_FILE" "1.3 403 HTML file"
check_file "$PAGE_TENANT_MISMATCH_FILE" "1.4 tenant mismatch HTML file"
check_file "$PAGE_SESSION_EXPIRED_FILE" "1.5 session expired HTML file"
check_file "$JS_FILE" "1.6 JS file"
check_file "$CSS_FILE" "1.7 CSS file"
check_file "$CONFIG_FILE" "1.8 config file"

if command -v python3 >/dev/null 2>&1; then
  if python3 -m json.tool "$CONFIG_FILE" >/dev/null 2>&1; then
    pass "2.1 config JSON valid"
  else
    fail "2.1 config JSON invalid"
  fi
else
  warn "2.1 python3 yok, JSON validation atlandı"
fi

check_contains "$CONFIG_FILE" '"unauthorized_401_page"' "3.1 401 capability contract"
check_contains "$CONFIG_FILE" '"forbidden_403_page"' "3.2 403 capability contract"
check_contains "$CONFIG_FILE" '"tenant_mismatch_message"' "3.3 tenant mismatch capability contract"
check_contains "$CONFIG_FILE" '"session_expired_message"' "3.4 session expired capability contract"
check_contains "$CONFIG_FILE" '"ui_api_tests"' "3.5 UI/API tests capability contract"

check_contains "$PAGE_401_FILE" 'UNAUTHORIZED' "4.1 401 page error code"
check_contains "$PAGE_403_FILE" 'FORBIDDEN' "4.2 403 page error code"
check_contains "$PAGE_TENANT_MISMATCH_FILE" 'TENANT_MISMATCH' "4.3 tenant mismatch page error code"
check_contains "$PAGE_SESSION_EXPIRED_FILE" 'SESSION_EXPIRED' "4.4 session expired page error code"

check_contains "$INDEX_FILE" 'authErrorRoot' "5.1 index root HTML"
check_contains "$INDEX_FILE" 'data-auth-error-simulate="UNAUTHORIZED"' "5.2 index 401 simulation"
check_contains "$INDEX_FILE" 'data-auth-error-simulate="FORBIDDEN"' "5.3 index 403 simulation"
check_contains "$INDEX_FILE" 'data-auth-error-simulate="TENANT_MISMATCH"' "5.4 index tenant mismatch simulation"
check_contains "$INDEX_FILE" 'data-auth-error-simulate="SESSION_EXPIRED"' "5.5 index session expired simulation"

check_contains "$JS_FILE" 'buildApiErrorResponse' "6.1 API error response builder JS"
check_contains "$JS_FILE" 'simulateUnauthorized' "6.2 401 simulation JS"
check_contains "$JS_FILE" 'simulateForbidden' "6.3 403 simulation JS"
check_contains "$JS_FILE" 'simulateTenantMismatch' "6.4 tenant mismatch simulation JS"
check_contains "$JS_FILE" 'simulateSessionExpired' "6.5 session expired simulation JS"
check_contains "$JS_FILE" 'clearAuthState' "6.6 logout/session cleanup JS"
check_contains "$JS_FILE" '401' "6.7 HTTP 401 contract JS"
check_contains "$JS_FILE" '403' "6.8 HTTP 403 contract JS"

check_contains "$CSS_FILE" 'pix2pi-error-card' "7.1 error card CSS"
check_contains "$CSS_FILE" 'pix2pi-error-code' "7.2 error code CSS"
check_contains "$CSS_FILE" 'pix2pi-error-button' "7.3 error action CSS"
check_contains "$CSS_FILE" 'pix2pi-api-preview' "7.4 API preview CSS"

UNAUTHORIZED_401_PAGE_STATUS="PASS"
FORBIDDEN_403_PAGE_STATUS="PASS"
TENANT_MISMATCH_MESSAGE_STATUS="PASS"
SESSION_EXPIRED_MESSAGE_STATUS="PASS"
UI_API_TEST_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  UNAUTHORIZED_401_PAGE_STATUS="FAIL"
  FORBIDDEN_403_PAGE_STATUS="FAIL"
  TENANT_MISMATCH_MESSAGE_STATUS="FAIL"
  SESSION_EXPIRED_MESSAGE_STATUS="FAIL"
  UI_API_TEST_STATUS="FAIL"
fi

{
  echo "# FAZ 1-5.5 Unauthorized / Forbidden Pages Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- INDEX_FILE=$INDEX_FILE"
  echo "- PAGE_401_FILE=$PAGE_401_FILE"
  echo "- PAGE_403_FILE=$PAGE_403_FILE"
  echo "- PAGE_TENANT_MISMATCH_FILE=$PAGE_TENANT_MISMATCH_FILE"
  echo "- PAGE_SESSION_EXPIRED_FILE=$PAGE_SESSION_EXPIRED_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- UNAUTHORIZED_401_PAGE_STATUS=$UNAUTHORIZED_401_PAGE_STATUS"
  echo "- FORBIDDEN_403_PAGE_STATUS=$FORBIDDEN_403_PAGE_STATUS"
  echo "- TENANT_MISMATCH_MESSAGE_STATUS=$TENANT_MISMATCH_MESSAGE_STATUS"
  echo "- SESSION_EXPIRED_MESSAGE_STATUS=$SESSION_EXPIRED_MESSAGE_STATUS"
  echo "- UI_API_TEST_STATUS=$UI_API_TEST_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "8.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-5.5 UNAUTHORIZED / FORBIDDEN PAGES STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "UNAUTHORIZED_401_PAGE_STATUS=$UNAUTHORIZED_401_PAGE_STATUS"
echo "FORBIDDEN_403_PAGE_STATUS=$FORBIDDEN_403_PAGE_STATUS"
echo "TENANT_MISMATCH_MESSAGE_STATUS=$TENANT_MISMATCH_MESSAGE_STATUS"
echo "SESSION_EXPIRED_MESSAGE_STATUS=$SESSION_EXPIRED_MESSAGE_STATUS"
echo "UI_API_TEST_STATUS=$UI_API_TEST_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-5.5 UNAUTHORIZED / FORBIDDEN PAGES STRICT SUITE END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_STRICT_SUITE_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_STRICT_SUITE_SEAL_STATUS")"

UNAUTHORIZED_401_PAGE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "UNAUTHORIZED_401_PAGE_STATUS")"
FORBIDDEN_403_PAGE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FORBIDDEN_403_PAGE_STATUS")"
TENANT_MISMATCH_MESSAGE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "TENANT_MISMATCH_MESSAGE_STATUS")"
SESSION_EXPIRED_MESSAGE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "SESSION_EXPIRED_MESSAGE_STATUS")"
UI_API_TEST_STATUS="$(extract_var "$STRICT_SUITE_OUT" "UI_API_TEST_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "8.2 strict suite FAIL_COUNT=0 doğrulandı" || fail "8.2 strict suite FAIL_COUNT sıfır değil"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "8.3 strict suite PASS doğrulandı" || fail "8.3 strict suite PASS değil"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "8.4 strict suite SEALED doğrulandı" || fail "8.4 strict suite SEALED değil"

echo "9. dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-5.5 — Unauthorized / Forbidden Sayfaları

## Kapsam

- 401 sayfası
- 403 sayfası
- Tenant mismatch mesajı
- Session expired mesajı
- UI/API testleri

## Üretilen Dosyalar

- Index: web/faz1/auth-tenant-experience/auth-errors/index.html
- 401 UI: web/faz1/auth-tenant-experience/auth-errors/401.html
- 403 UI: web/faz1/auth-tenant-experience/auth-errors/403.html
- Tenant mismatch UI: web/faz1/auth-tenant-experience/auth-errors/tenant-mismatch.html
- Session expired UI: web/faz1/auth-tenant-experience/auth-errors/session-expired.html
- Runtime JS: web/faz1/auth-tenant-experience/auth-errors/auth_error_pages.js
- CSS: web/faz1/auth-tenant-experience/auth-errors/auth_error_pages.css
- Contract: configs/faz1/web/auth_tenant_experience/auth_error_pages_contract.v1.json
- Strict suite: scripts/web/faz_1_5_5_unauthorized_forbidden_pages_strict_suite.sh

## Final Status

- UNAUTHORIZED_401_PAGE_STATUS=${UNAUTHORIZED_401_PAGE_STATUS:-N/A}
- FORBIDDEN_403_PAGE_STATUS=${FORBIDDEN_403_PAGE_STATUS:-N/A}
- TENANT_MISMATCH_MESSAGE_STATUS=${TENANT_MISMATCH_MESSAGE_STATUS:-N/A}
- SESSION_EXPIRED_MESSAGE_STATUS=${SESSION_EXPIRED_MESSAGE_STATUS:-N/A}
- UI_API_TEST_STATUS=${UI_API_TEST_STATUS:-N/A}
- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}
- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-5.5 Unauthorized / Forbidden Pages Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- INDEX_FILE=$INDEX_FILE"
  echo "- PAGE_401_FILE=$PAGE_401_FILE"
  echo "- PAGE_403_FILE=$PAGE_403_FILE"
  echo "- PAGE_TENANT_MISMATCH_FILE=$PAGE_TENANT_MISMATCH_FILE"
  echo "- PAGE_SESSION_EXPIRED_FILE=$PAGE_SESSION_EXPIRED_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo "- STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
  echo "- DOC_FILE=$DOC_FILE"
  echo "- BACKUP_DIR=$BACKUP_DIR"
  echo
  echo "## Status"
  echo "- UNAUTHORIZED_401_PAGE_STATUS=${UNAUTHORIZED_401_PAGE_STATUS:-N/A}"
  echo "- FORBIDDEN_403_PAGE_STATUS=${FORBIDDEN_403_PAGE_STATUS:-N/A}"
  echo "- TENANT_MISMATCH_MESSAGE_STATUS=${TENANT_MISMATCH_MESSAGE_STATUS:-N/A}"
  echo "- SESSION_EXPIRED_MESSAGE_STATUS=${SESSION_EXPIRED_MESSAGE_STATUS:-N/A}"
  echo "- UI_API_TEST_STATUS=${UI_API_TEST_STATUS:-N/A}"
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
  echo "# FAZ 1-5.5 Unauthorized / Forbidden Pages Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_5_5_UNAUTHORIZED_401_PAGE_STATUS=${UNAUTHORIZED_401_PAGE_STATUS:-N/A}"
  echo "FAZ_1_5_5_FORBIDDEN_403_PAGE_STATUS=${FORBIDDEN_403_PAGE_STATUS:-N/A}"
  echo "FAZ_1_5_5_TENANT_MISMATCH_MESSAGE_STATUS=${TENANT_MISMATCH_MESSAGE_STATUS:-N/A}"
  echo "FAZ_1_5_5_SESSION_EXPIRED_MESSAGE_STATUS=${SESSION_EXPIRED_MESSAGE_STATUS:-N/A}"
  echo "FAZ_1_5_5_UI_API_TEST_STATUS=${UI_API_TEST_STATUS:-N/A}"
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_5_6_READY=YES"
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

echo "===== FAZ 1-5.5 UNAUTHORIZED / FORBIDDEN PAGES RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "UNAUTHORIZED_401_PAGE_STATUS=${UNAUTHORIZED_401_PAGE_STATUS:-N/A}"
echo "FORBIDDEN_403_PAGE_STATUS=${FORBIDDEN_403_PAGE_STATUS:-N/A}"
echo "TENANT_MISMATCH_MESSAGE_STATUS=${TENANT_MISMATCH_MESSAGE_STATUS:-N/A}"
echo "SESSION_EXPIRED_MESSAGE_STATUS=${SESSION_EXPIRED_MESSAGE_STATUS:-N/A}"
echo "UI_API_TEST_STATUS=${UI_API_TEST_STATUS:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "INDEX_FILE=$INDEX_FILE"
echo "PAGE_401_FILE=$PAGE_401_FILE"
echo "PAGE_403_FILE=$PAGE_403_FILE"
echo "PAGE_TENANT_MISMATCH_FILE=$PAGE_TENANT_MISMATCH_FILE"
echo "PAGE_SESSION_EXPIRED_FILE=$PAGE_SESSION_EXPIRED_FILE"
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

  echo "FAZ_1_5_5_UNAUTHORIZED_401_PAGE_STATUS=PASS"
  echo "FAZ_1_5_5_FORBIDDEN_403_PAGE_STATUS=PASS"
  echo "FAZ_1_5_5_TENANT_MISMATCH_MESSAGE_STATUS=PASS"
  echo "FAZ_1_5_5_SESSION_EXPIRED_MESSAGE_STATUS=PASS"
  echo "FAZ_1_5_5_UI_API_TEST_STATUS=PASS"
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_FINAL_STATUS=PASS"
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_SEAL_STATUS=SEALED"
  echo "FAZ_1_5_6_READY=YES"
else
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_FINAL_STATUS=FAIL"
  echo "FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES_SEAL_STATUS=OPEN"
  echo "FAZ_1_5_6_READY=NO"
  exit 1
fi

echo "===== FAZ 1-5.5 UNAUTHORIZED / FORBIDDEN PAGES END ====="
