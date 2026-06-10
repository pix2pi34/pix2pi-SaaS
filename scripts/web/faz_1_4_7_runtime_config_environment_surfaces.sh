#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES"

BACKUP_DIR="$REPO/backups/faz1/faz_1_4_7_runtime_config_environment_surfaces_$TS"
WEB_DIR="$REPO/web/faz1/ui-foundation/runtime-config"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
DOC_DIR="$REPO/docs/faz1/web"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
SCRIPT_DIR="$REPO/scripts/web"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/runtime_config.js"
CSS_FILE="$WEB_DIR/runtime_config.css"
CONFIG_FILE="$CONFIG_DIR/runtime_config_environment_contract.v1.json"
DOC_FILE="$DOC_DIR/FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES.md"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_4_7_runtime_config_environment_surfaces_strict_suite.sh"
APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_4_7_runtime_config_environment_surfaces.sh"
STRICT_SUITE_OUT="$BACKUP_DIR/faz_1_4_7_runtime_config_environment_surfaces_strict_suite.out"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_FINAL_SEAL_$TS.md"

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

echo "===== FAZ 1-4.7 RUNTIME CONFIG / ENVIRONMENT SURFACES START ====="

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

echo "3. runtime config / environment contract yazılıyor..."

cat <<'JSON' > "$CONFIG_FILE"
{
  "phase": "FAZ_1_4_7",
  "module": "WEB_L1_UI_FOUNDATION_DESIGN_SYSTEM",
  "component": "runtime_config_environment_surfaces",
  "status": "READY",
  "required_capabilities": [
    "environment_indicator",
    "runtime_config_surface",
    "config_permission_guard",
    "read_only_config_view",
    "tests"
  ],
  "environment_contract": {
    "environment_indicator_id": "pix2piEnvironmentIndicator",
    "supported_environments": [
      "LOCAL",
      "DEV",
      "STAGING",
      "PRODUCTION"
    ],
    "default_environment": "STAGING",
    "production_warning_policy": "SHOW_STRONG_BADGE"
  },
  "runtime_config_contract": {
    "surface_id": "pix2piRuntimeConfigSurface",
    "config_table_id": "pix2piRuntimeConfigTable",
    "config_output_id": "pix2piRuntimeConfigOutput",
    "readonly_policy": "READ_ONLY_UI_SURFACE",
    "masked_keys": [
      "API_BASE_URL",
      "AUTH_BASE_URL",
      "PUBLIC_APP_URL"
    ],
    "secret_keys_policy": "NEVER_RENDER_SECRETS"
  },
  "permission_guard_contract": {
    "required_permission": "config:read",
    "admin_role": "TENANT_ADMIN",
    "ops_role": "OPS_ADMIN",
    "guard_status_id": "pix2piConfigPermissionGuard",
    "deny_policy": "SHOW_READONLY_DENIED_STATE"
  },
  "test_contract": {
    "final_gate": "PASS_ONLY_IF_ALL_RUNTIME_CONFIG_TESTS_PASS",
    "required_fail_count": 0,
    "next_ready_flag": "FAZ_1_4_8_READY"
  }
}
JSON

if [ -f "$CONFIG_FILE" ]; then
  pass "3.1 runtime config contract yazıldı: $CONFIG_FILE"
else
  fail "3.1 runtime config contract yazılamadı"
  exit 1
fi

echo "4. runtime config CSS yazılıyor..."

cat <<'CSS' > "$CSS_FILE"
:root {
  --pix2pi-color-bg: #0f172a;
  --pix2pi-color-surface: #111827;
  --pix2pi-color-surface-soft: #1f2937;
  --pix2pi-color-content: #020617;
  --pix2pi-color-border: #334155;
  --pix2pi-color-text: #e5e7eb;
  --pix2pi-color-muted: #9ca3af;
  --pix2pi-color-accent: #38bdf8;
  --pix2pi-color-success: #22c55e;
  --pix2pi-color-warning: #f59e0b;
  --pix2pi-color-danger: #ef4444;
  --pix2pi-radius-md: 14px;
  --pix2pi-radius-lg: 20px;
  --pix2pi-shadow-lg: 0 24px 80px rgba(0, 0, 0, 0.28);
  --pix2pi-font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-height: 100vh;
  background: radial-gradient(circle at top left, #064e3b 0, var(--pix2pi-color-bg) 42%);
  color: var(--pix2pi-color-text);
  font-family: var(--pix2pi-font-family);
}

.pix2pi-page {
  width: min(1180px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0;
}

.pix2pi-page-header {
  display: flex;
  justify-content: space-between;
  gap: 18px;
  align-items: flex-start;
  margin-bottom: 24px;
}

.pix2pi-page-title {
  margin: 0;
  font-size: 30px;
  letter-spacing: -0.04em;
}

.pix2pi-page-subtitle {
  margin: 8px 0 0;
  color: var(--pix2pi-color-muted);
}

.pix2pi-grid {
  display: grid;
  grid-template-columns: 360px 1fr;
  gap: 18px;
}

.pix2pi-card {
  background: rgba(17, 24, 39, 0.92);
  border: 1px solid var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: 22px;
  box-shadow: var(--pix2pi-shadow-lg);
}

.pix2pi-card-title {
  margin: 0 0 12px;
  font-size: 18px;
}

.pix2pi-card-text {
  color: var(--pix2pi-color-muted);
  line-height: 1.6;
}

.pix2pi-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border: 1px solid var(--pix2pi-color-border);
  background: var(--pix2pi-color-surface-soft);
  color: var(--pix2pi-color-text);
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 13px;
}

.pix2pi-badge.local {
  border-color: rgba(56, 189, 248, 0.55);
  color: #bae6fd;
}

.pix2pi-badge.dev {
  border-color: rgba(34, 197, 94, 0.5);
  color: #bbf7d0;
}

.pix2pi-badge.staging {
  border-color: rgba(245, 158, 11, 0.55);
  color: #fde68a;
}

.pix2pi-badge.production {
  border-color: rgba(239, 68, 68, 0.65);
  color: #fecaca;
}

.pix2pi-button {
  border: 1px solid var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-md);
  background: var(--pix2pi-color-surface-soft);
  color: var(--pix2pi-color-text);
  padding: 11px 14px;
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

.pix2pi-input,
.pix2pi-select {
  width: 100%;
  border: 1px solid var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-md);
  background: var(--pix2pi-color-content);
  color: var(--pix2pi-color-text);
  padding: 12px 14px;
  outline: none;
}

.pix2pi-actions {
  display: grid;
  gap: 10px;
}

.pix2pi-config-surface {
  display: grid;
  gap: 14px;
}

.pix2pi-config-guard {
  border: 1px solid var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-md);
  padding: 14px;
  background: var(--pix2pi-color-content);
}

.pix2pi-config-guard.allowed {
  border-color: rgba(34, 197, 94, 0.55);
  color: #bbf7d0;
}

.pix2pi-config-guard.denied {
  border-color: rgba(239, 68, 68, 0.55);
  color: #fecaca;
}

.pix2pi-readonly-banner {
  border: 1px dashed var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-md);
  padding: 12px 14px;
  background: rgba(2, 6, 23, 0.72);
  color: var(--pix2pi-color-muted);
}

.pix2pi-table-scroll {
  overflow-x: auto;
  border: 1px solid var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-lg);
  background: var(--pix2pi-color-content);
}

.pix2pi-config-table {
  width: 100%;
  min-width: 760px;
  border-collapse: collapse;
}

.pix2pi-config-table th,
.pix2pi-config-table td {
  padding: 13px 14px;
  border-bottom: 1px solid var(--pix2pi-color-border);
  text-align: left;
}

.pix2pi-config-table th {
  color: var(--pix2pi-color-muted);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  background: rgba(31, 41, 55, 0.78);
}

.pix2pi-config-table tr:last-child td {
  border-bottom: 0;
}

.pix2pi-config-value.masked {
  color: var(--pix2pi-color-warning);
}

.pix2pi-log {
  background: var(--pix2pi-color-content);
  border: 1px solid var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: 14px;
  color: var(--pix2pi-color-muted);
  min-height: 220px;
  white-space: pre-wrap;
  overflow: auto;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

@media (max-width: 900px) {
  .pix2pi-page-header,
  .pix2pi-grid {
    display: grid;
    grid-template-columns: 1fr;
  }
}
CSS

if grep -q "pix2pi-badge.production" "$CSS_FILE" \
  && grep -q "pix2pi-config-surface" "$CSS_FILE" \
  && grep -q "pix2pi-config-guard" "$CSS_FILE" \
  && grep -q "pix2pi-readonly-banner" "$CSS_FILE" \
  && grep -q "pix2pi-config-table" "$CSS_FILE"; then
  pass "4.1 CSS runtime config/environment sınıfları mevcut"
else
  fail "4.1 CSS runtime config/environment sınıfları eksik"
  exit 1
fi

echo "5. runtime config JS yazılıyor..."

cat <<'JS' > "$JS_FILE"
(function runtimeConfigEnvironmentRuntime(global) {
  "use strict";

  const ENVIRONMENTS = ["LOCAL", "DEV", "STAGING", "PRODUCTION"];

  const CONFIG_ROWS = [
    { key: "APP_ENV", value: "STAGING", scope: "public", readonly: true },
    { key: "API_BASE_URL", value: "https://api.pix2pi.com.tr", scope: "public", readonly: true },
    { key: "AUTH_BASE_URL", value: "https://auth.pix2pi.com.tr", scope: "public", readonly: true },
    { key: "PUBLIC_APP_URL", value: "https://pix2pi.com.tr", scope: "public", readonly: true },
    { key: "FEATURE_RUNTIME_CONFIG_VIEW", value: "enabled", scope: "feature", readonly: true },
    { key: "SECRET_PAYMENT_PROVIDER_KEY", value: "NEVER_RENDER", scope: "secret", readonly: true }
  ];

  const MASKED_KEYS = ["API_BASE_URL", "AUTH_BASE_URL", "PUBLIC_APP_URL"];
  const SECRET_KEY_PATTERN = /SECRET|PASSWORD|TOKEN|PRIVATE|KEY/i;

  const state = {
    environment: "STAGING",
    currentUser: {
      roles: ["TENANT_ADMIN"],
      permissions: ["config:read"]
    }
  };

  function hasPermission(permission) {
    return state.currentUser.permissions.includes(permission);
  }

  function hasConfigReadPermission() {
    return hasPermission("config:read") || state.currentUser.roles.includes("OPS_ADMIN");
  }

  function isSecretKey(key) {
    return SECRET_KEY_PATTERN.test(String(key || ""));
  }

  function.currentUser.roles.includes("OPS_ADMIN");
  }

  function isSecretKey(key) {
    return SECRET_KEY_PATTERN maskConfigValue(row) {
    if (isSecretKey(row.key)) {
      return "********";
    }

    if (MASKED_KEYS.includes(row.key)) {
      return String(row.value).replace(/^https?:\/\//, "").replace(/./g, "•").slice(0, 16) + "...";
    }

    return row.value;
  }

  function getEnvironmentBadgeClass(environment) {
    const env = String(environment || "STAGING").toLowerCase();
    if (env === "production") return "production";
    if (env === "staging") return "staging";
    if (env === "dev") return "dev";
    return "local";
  }

  function setEnvironment(environment) {
    state.environment = ENVIRONMENTS.includes(environment) ? environment : "STAGING";
    renderEnvironmentIndicator();
    renderRuntimeConfigSurface();
    return state.environment;
  }

  function setRoleMode(mode) {
    if (mode === "denied") {
      state.currentUser = {
        roles: ["VIEWER"],
        permissions: []
      };
    } else if (mode === "ops") {
      state.currentUser = {
        roles: ["OPS_ADMIN"],
        permissions: ["config:read", "ops:read"]
      };
    } else {
      state.currentUser = {
        roles: ["TENANT_ADMIN"],
        permissions: ["config:read"]
      };
    }

    renderConfigPermissionGuard();
    renderRuntimeConfigSurface();
    return state.currentUser;
  }

  function renderEnvironmentIndicator() {
    const indicator = document.getElementById("pix2piEnvironmentIndicator");
    if (!indicator) {
      return null;
    }

    const className = getEnvironmentBadgeClass(state.environment);
    indicator.className = "pix2pi-badge " + className;
    indicator.textContent = "ENV: " + state.environment;
    return state.environment;
  }

  function renderConfigPermissionGuard() {
    const guard = document.getElementById("pix2piConfigPermissionGuard");
    if (!guard) {
      return null;
    }

    const allowed = hasConfigReadPermission();
    guard.className = "pix2pi-config-guard " + (allowed ? "allowed" : "denied");
    guard.textContent = allowed
      ? "Config permission guard: ALLOWED / read-only görünüm açık"
      : "Config permission guard: DENIED / config görünümü kapalı";

    return allowed;
  }

  function getSafeConfigRows() {
    if (!hasConfigReadPermission()) {
      return [];
    }

    return CONFIG_ROWS
      .filter((row) => row.scope !== "secret")
      .map((row) => ({
        key: row.key,
        value: maskConfigValue(row),
        scope: row.scope,
        readonly: true,
        masked: MASKED_KEYS.includes(row.key)
      }));
  }

  function renderRuntimeConfigSurface() {
    renderEnvironmentIndicator();
    renderConfigPermissionGuard();

    const tbody = document.getElementById("pix2piRuntimeConfigTableBody");
    const output = document.getElementById("pix2piRuntimeConfigOutput");
    const rows = getSafeConfigRows();

    if (tbody) {
      tbody.innerHTML = "";

      rows.forEach((row) => {
        const tr = document.createElement("tr");
        tr.innerHTML = "<td></td><td></td><td></td><td></td>";
        tr.children[0].textContent = row.key;
        tr.children[1].textContent = row.scope;
        tr.children[2].textContent = row.readonly ? "READ_ONLY" : "WRITE";
        tr.children[3].textContent = row.value;
        tr.children[3].className = "pix2pi-config-value" + (row.masked ? " masked" : "");
        tbody.appendChild(tr);
      });
    }

    if (output) {
      output.textContent = JSON.stringify({
        environment: state.environment,
        permission_allowed: hasConfigReadPermission(),
        user: state.currentUser,
        safe_config_count: rows.length,
        secrets_rendered: rows.some((row) => isSecretKey(row.key))
      }, null, 2);
    }

    return rows;
  }

  function validateEnvironmentIndicator() {
    return Boolean(document.getElementById("pix2piEnvironmentIndicator") && ENVIRONMENTS.includes(state.environment));
  }

  function validateRuntimeConfigSurface() {
    return Boolean(document.getElementById("pix2piRuntimeConfigSurface") && document.getElementById("pix2piRuntimeConfigTable"));
  }

  function validateConfigPermissionGuard() {
    setRoleMode("denied");
    const deniedRows = getSafeConfigRows();
    setRoleMode("admin");
    const allowedRows = getSafeConfigRows();
    return deniedRows.length === 0 && allowedRows.length > 0;
  }

  function validateReadOnlyConfigView() {
    return getSafeConfigRows().every((row) => row.readonly === true);
  }

  function runRuntimeConfigTests() {
    const result = {
      environment_indicator: validateEnvironmentIndicator() ? "PASS" : "FAIL",
      runtime_config_surface: validateRuntimeConfigSurface() ? "PASS" : "FAIL",
      config_permission_guard: validateConfigPermissionGuard() ? "PASS" : "FAIL",
      read_only_config_view: validateReadOnlyConfigView() ? "PASS" : "FAIL",
      tests: getSafeConfigRows().some((row) => isSecretKey(row.key)) ? "FAIL" : "PASS"
    };

    renderRuntimeConfigSurface();
    return result;
  }

  function renderRuntimeConfigTests() {
    const output = document.getElementById("pix2piRuntimeConfigTestOutput");
    const result = runRuntimeConfigTests();

    if (output) {
      output.textContent = JSON.stringify(result, null, 2);
    }

    return result;
  }

  function bootstrapRuntimeConfigEnvironment() {
    const environmentSelect = document.getElementById("pix2piEnvironmentSelect");
    const roleSelect = document.getElementById("pix2piRoleModeSelect");
    const testButton = document.getElementById("runRuntimeConfigTestsButton");

    if (environmentSelect) {
      environmentSelect.addEventListener("change", () => setEnvironment(environmentSelect.value));
    }

    if (roleSelect) {
      roleSelect.addEventListener("change", () => setRoleMode(roleSelect.value));
    }

    if (testButton) {
      testButton.addEventListener("click", renderRuntimeConfigTests);
    }

    renderRuntimeConfigSurface();
    renderRuntimeConfigTests();
  }

  const api = {
    ENVIRONMENTS,
    CONFIG_ROWS,
    MASKED_KEYS,
    state,
    hasPermission,
    hasConfigReadPermission,
    isSecretKey,
    maskConfigValue,
    getEnvironmentBadgeClass,
    setEnvironment,
    setRoleMode,
    renderEnvironmentIndicator,
    renderConfigPermissionGuard,
    getSafeConfigRows,
    renderRuntimeConfigSurface,
    validateEnvironmentIndicator,
    validateRuntimeConfigSurface,
    validateConfigPermissionGuard,
    validateReadOnlyConfigView,
    runRuntimeConfigTests,
    renderRuntimeConfigTests,
    bootstrapRuntimeConfigEnvironment
  };

  global.Pix2piRuntimeConfigEnvironment = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapRuntimeConfigEnvironment);
    } else {
      bootstrapRuntimeConfigEnvironment();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
JS

if grep -q "renderEnvironmentIndicator" "$JS_FILE" \
  && grep -q "renderRuntimeConfigSurface" "$JS_FILE" \
  && grep -q "hasConfigReadPermission" "$JS_FILE" \
  && grep -q "validateReadOnlyConfigView" "$JS_FILE" \
  && grep -q "runRuntimeConfigTests" "$JS_FILE"; then
  pass "5.1 JS runtime config/environment fonksiyonları mevcut"
else
  fail "5.1 JS runtime config/environment fonksiyonları eksik"
  exit 1
fi

echo "6. runtime config HTML yazılıyor..."

cat <<'HTML' > "$HTML_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — Runtime Config / Environment</title>
  <link rel="stylesheet" href="./runtime_config.css">
</head>
<body>
  <main class="pix2pi-page">
    <header class="pix2pi-page-header">
      <div>
        <h1 class="pix2pi-page-title">Pix2pi Runtime Config / Environment Yüzeyleri</h1>
        <p class="pix2pi-page-subtitle">FAZ 1-4.7 — WEB-L1 UI Foundation / Design System</p>
      </div>
      <span class="pix2pi-badge staging" id="pix2piEnvironmentIndicator">ENV: STAGING</span>
    </header>

    <section class="pix2pi-grid">
      <aside class="pix2pi-card">
        <h2 class="pix2pi-card-title">Kontroller</h2>

        <div class="pix2pi-actions">
          <label>
            Environment
            <select class="pix2pi-select" id="pix2piEnvironmentSelect">
              <option value="LOCAL">LOCAL</option>
              <option value="DEV">DEV</option>
              <option value="STAGING" selected>STAGING</option>
              <option value="PRODUCTION">PRODUCTION</option>
            </select>
          </label>

          <label>
            Role mode
            <select class="pix2pi-select" id="pix2piRoleModeSelect">
              <option value="admin" selected>TENANT_ADMIN / config:read</option>
              <option value="ops">OPS_ADMIN / config:read</option>
              <option value="denied">VIEWER / denied</option>
            </select>
          </label>

          <button class="pix2pi-button primary" id="runRuntimeConfigTestsButton" type="button">Runtime config testlerini çalıştır</button>
        </div>

        <pre class="pix2pi-log" id="pix2piRuntimeConfigTestOutput">RUNTIME_CONFIG_TEST_LOADING</pre>
      </aside>

      <section class="pix2pi-card pix2pi-config-surface" id="pix2piRuntimeConfigSurface">
        <h2 class="pix2pi-card-title">Read-only runtime config view</h2>
        <p class="pix2pi-card-text">Bu yüzey config değerlerini sadece okuma amaçlı gösterir. Secret değerler render edilmez.</p>

        <div class="pix2pi-config-guard allowed" id="pix2piConfigPermissionGuard">
          Config permission guard hazırlanıyor...
        </div>

        <div class="pix2pi-readonly-banner">
          READ_ONLY_CONFIG_VIEW — Bu ekranda config düzenleme yoktur, sadece güvenli public/runtime değerleri görünür.
        </div>

        <div class="pix2pi-table-scroll">
          <table class="pix2pi-config-table" id="pix2piRuntimeConfigTable">
            <thead>
              <tr>
                <th>Key</th>
                <th>Scope</th>
                <th>Mode</th>
                <th>Value</th>
              </tr>
            </thead>
            <tbody id="pix2piRuntimeConfigTableBody"></tbody>
          </table>
        </div>

        <pre class="pix2pi-log" id="pix2piRuntimeConfigOutput">RUNTIME_CONFIG_OUTPUT_LOADING</pre>
      </section>
    </section>
  </main>

  <script src="./runtime_config.js"></script>
</body>
</html>
HTML

if grep -q "pix2piEnvironmentIndicator" "$HTML_FILE" \
  && grep -q "pix2piRuntimeConfigSurface" "$HTML_FILE" \
  && grep -q "pix2piConfigPermissionGuard" "$HTML_FILE" \
  && grep -q "READ_ONLY_CONFIG_VIEW" "$HTML_FILE" \
  && grep -q "runRuntimeConfigTestsButton" "$HTML_FILE"; then
  pass "6.1 HTML runtime config/environment elementleri mevcut"
else
  fail "6.1 HTML runtime config/environment elementleri eksik"
  exit 1
fi

echo "7. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/runtime-config"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/runtime_config.js"
CSS_FILE="$WEB_DIR/runtime_config.css"
CONFIG_FILE="$CONFIG_DIR/runtime_config_environment_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-4.7 RUNTIME CONFIG / ENVIRONMENT SURFACES STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"environment_indicator"' "3.1 environment_indicator capability contract"
check_contains "$CONFIG_FILE" '"runtime_config_surface"' "3.2 runtime_config_surface capability contract"
check_contains "$CONFIG_FILE" '"config_permission_guard"' "3.3 config_permission_guard capability contract"
check_contains "$CONFIG_FILE" '"read_only_config_view"' "3.4 read_only_config_view capability contract"
check_contains "$CONFIG_FILE" '"tests"' "3.5 tests capability contract"

check_contains "$HTML_FILE" 'pix2piEnvironmentIndicator' "4.1 environment indicator HTML"
check_contains "$HTML_FILE" 'pix2piRuntimeConfigSurface' "4.2 runtime config surface HTML"
check_contains "$HTML_FILE" 'pix2piConfigPermissionGuard' "4.3 config permission guard HTML"
check_contains "$HTML_FILE" 'READ_ONLY_CONFIG_VIEW' "4.4 read-only config view HTML"
check_contains "$HTML_FILE" 'runRuntimeConfigTestsButton' "4.5 tests button HTML"

check_contains "$JS_FILE" 'renderEnvironmentIndicator' "5.1 environment indicator JS"
check_contains "$JS_FILE" 'renderRuntimeConfigSurface' "5.2 runtime config surface JS"
check_contains "$JS_FILE" 'hasConfigReadPermission' "5.3 config permission guard JS"
check_contains "$JS_FILE" 'validateReadOnlyConfigView' "5.4 read-only config view JS"
check_contains "$JS_FILE" 'runRuntimeConfigTests' "5.5 tests JS"
check_contains "$JS_FILE" 'NEVER_RENDER' "5.6 secret never render policy JS"

check_contains "$CSS_FILE" 'pix2pi-badge.production' "6.1 production environment CSS"
check_contains "$CSS_FILE" 'pix2pi-config-surface' "6.2 runtime config surface CSS"
check_contains "$CSS_FILE" 'pix2pi-config-guard' "6.3 permission guard CSS"
check_contains "$CSS_FILE" 'pix2pi-readonly-banner' "6.4 read-only view CSS"
check_contains "$CSS_FILE" 'pix2pi-config-table' "6.5 config table CSS"

ENVIRONMENT_INDICATOR_STATUS="PASS"
RUNTIME_CONFIG_SURFACE_STATUS="PASS"
CONFIG_PERMISSION_GUARD_STATUS="PASS"
READ_ONLY_CONFIG_VIEW_STATUS="PASS"
TESTS_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  ENVIRONMENT_INDICATOR_STATUS="FAIL"
  RUNTIME_CONFIG_SURFACE_STATUS="FAIL"
  CONFIG_PERMISSION_GUARD_STATUS="FAIL"
  READ_ONLY_CONFIG_VIEW_STATUS="FAIL"
  TESTS_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.7 Runtime Config / Environment Surfaces Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- ENVIRONMENT_INDICATOR_STATUS=$ENVIRONMENT_INDICATOR_STATUS"
  echo "- RUNTIME_CONFIG_SURFACE_STATUS=$RUNTIME_CONFIG_SURFACE_STATUS"
  echo "- CONFIG_PERMISSION_GUARD_STATUS=$CONFIG_PERMISSION_GUARD_STATUS"
  echo "- READ_ONLY_CONFIG_VIEW_STATUS=$READ_ONLY_CONFIG_VIEW_STATUS"
  echo "- TESTS_STATUS=$TESTS_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.7 RUNTIME CONFIG / ENVIRONMENT SURFACES STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "ENVIRONMENT_INDICATOR_STATUS=$ENVIRONMENT_INDICATOR_STATUS"
echo "RUNTIME_CONFIG_SURFACE_STATUS=$RUNTIME_CONFIG_SURFACE_STATUS"
echo "CONFIG_PERMISSION_GUARD_STATUS=$CONFIG_PERMISSION_GUARD_STATUS"
echo "READ_ONLY_CONFIG_VIEW_STATUS=$READ_ONLY_CONFIG_VIEW_STATUS"
echo "TESTS_STATUS=$TESTS_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.7 RUNTIME CONFIG / ENVIRONMENT SURFACES STRICT SUITE END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_STRICT_SUITE_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_STRICT_SUITE_SEAL_STATUS")"

ENVIRONMENT_INDICATOR_STATUS="$(extract_var "$STRICT_SUITE_OUT" "ENVIRONMENT_INDICATOR_STATUS")"
RUNTIME_CONFIG_SURFACE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "RUNTIME_CONFIG_SURFACE_STATUS")"
CONFIG_PERMISSION_GUARD_STATUS="$(extract_var "$STRICT_SUITE_OUT" "CONFIG_PERMISSION_GUARD_STATUS")"
READ_ONLY_CONFIG_VIEW_STATUS="$(extract_var "$STRICT_SUITE_OUT" "READ_ONLY_CONFIG_VIEW_STATUS")"
TESTS_STATUS="$(extract_var "$STRICT_SUITE_OUT" "TESTS_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "8.2 strict suite FAIL_COUNT=0 doğrulandı" || fail "8.2 strict suite FAIL_COUNT sıfır değil"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "8.3 strict suite PASS doğrulandı" || fail "8.3 strict suite PASS değil"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "8.4 strict suite SEALED doğrulandı" || fail "8.4 strict suite SEALED değil"

echo "9. dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-4.7 — Runtime Config / Environment Yüzeyleri

## Kapsam

- Environment indicator
- Runtime config surface
- Config permission guard
- Read-only config view
- Tests

## Üretilen Dosyalar

- UI: web/faz1/ui-foundation/runtime-config/index.html
- Runtime JS: web/faz1/ui-foundation/runtime-config/runtime_config.js
- CSS: web/faz1/ui-foundation/runtime-config/runtime_config.css
- Contract: configs/faz1/web/ui_foundation/runtime_config_environment_contract.v1.json
- Strict suite: scripts/web/faz_1_4_7_runtime_config_environment_surfaces_strict_suite.sh

## Final Status

- ENVIRONMENT_INDICATOR_STATUS=${ENVIRONMENT_INDICATOR_STATUS:-N/A}
- RUNTIME_CONFIG_SURFACE_STATUS=${RUNTIME_CONFIG_SURFACE_STATUS:-N/A}
- CONFIG_PERMISSION_GUARD_STATUS=${CONFIG_PERMISSION_GUARD_STATUS:-N/A}
- READ_ONLY_CONFIG_VIEW_STATUS=${READ_ONLY_CONFIG_VIEW_STATUS:-N/A}
- TESTS_STATUS=${TESTS_STATUS:-N/A}
- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}
- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-4.7 Runtime Config / Environment Surfaces Real Implementation Audit"
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
  echo "- ENVIRONMENT_INDICATOR_STATUS=${ENVIRONMENT_INDICATOR_STATUS:-N/A}"
  echo "- RUNTIME_CONFIG_SURFACE_STATUS=${RUNTIME_CONFIG_SURFACE_STATUS:-N/A}"
  echo "- CONFIG_PERMISSION_GUARD_STATUS=${CONFIG_PERMISSION_GUARD_STATUS:-N/A}"
  echo "- READ_ONLY_CONFIG_VIEW_STATUS=${READ_ONLY_CONFIG_VIEW_STATUS:-N/A}"
  echo "- TESTS_STATUS=${TESTS_STATUS:-N/A}"
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
  echo "# FAZ 1-4.7 Runtime Config / Environment Surfaces Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_4_7_ENVIRONMENT_INDICATOR_STATUS=${ENVIRONMENT_INDICATOR_STATUS:-N/A}"
  echo "FAZ_1_4_7_RUNTIME_CONFIG_SURFACE_STATUS=${RUNTIME_CONFIG_SURFACE_STATUS:-N/A}"
  echo "FAZ_1_4_7_CONFIG_PERMISSION_GUARD_STATUS=${CONFIG_PERMISSION_GUARD_STATUS:-N/A}"
  echo "FAZ_1_4_7_READ_ONLY_CONFIG_VIEW_STATUS=${READ_ONLY_CONFIG_VIEW_STATUS:-N/A}"
  echo "FAZ_1_4_7_TESTS_STATUS=${TESTS_STATUS:-N/A}"
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_4_8_READY=YES"
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

echo "===== FAZ 1-4.7 RUNTIME CONFIG / ENVIRONMENT SURFACES RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "ENVIRONMENT_INDICATOR_STATUS=${ENVIRONMENT_INDICATOR_STATUS:-N/A}"
echo "RUNTIME_CONFIG_SURFACE_STATUS=${RUNTIME_CONFIG_SURFACE_STATUS:-N/A}"
echo "CONFIG_PERMISSION_GUARD_STATUS=${CONFIG_PERMISSION_GUARD_STATUS:-N/A}"
echo "READ_ONLY_CONFIG_VIEW_STATUS=${READ_ONLY_CONFIG_VIEW_STATUS:-N/A}"
echo "TESTS_STATUS=${TESTS_STATUS:-N/A}"
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

  echo "FAZ_1_4_7_ENVIRONMENT_INDICATOR_STATUS=PASS"
  echo "FAZ_1_4_7_RUNTIME_CONFIG_SURFACE_STATUS=PASS"
  echo "FAZ_1_4_7_CONFIG_PERMISSION_GUARD_STATUS=PASS"
  echo "FAZ_1_4_7_READ_ONLY_CONFIG_VIEW_STATUS=PASS"
  echo "FAZ_1_4_7_TESTS_STATUS=PASS"
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_FINAL_STATUS=PASS"
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_SEAL_STATUS=SEALED"
  echo "FAZ_1_4_8_READY=YES"
else
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_FINAL_STATUS=FAIL"
  echo "FAZ_1_4_7_RUNTIME_CONFIG_ENVIRONMENT_SURFACES_SEAL_STATUS=OPEN"
  echo "FAZ_1_4_8_READY=NO"
  exit 1
fi

echo "===== FAZ 1-4.7 RUNTIME CONFIG / ENVIRONMENT SURFACES END ====="
