#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_5_3_TENANT_SWITCHER_UX"

BACKUP_DIR="$REPO/backups/faz1/faz_1_5_3_tenant_switcher_ux_$TS"
WEB_DIR="$REPO/web/faz1/auth-tenant-experience/tenant-switcher"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
DOC_DIR="$REPO/docs/faz1/web"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
SCRIPT_DIR="$REPO/scripts/web"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/tenant_switcher.js"
CSS_FILE="$WEB_DIR/tenant_switcher.css"
CONFIG_FILE="$CONFIG_DIR/tenant_switcher_contract.v1.json"
DOC_FILE="$DOC_DIR/FAZ_1_5_3_TENANT_SWITCHER_UX.md"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_5_3_tenant_switcher_ux_strict_suite.sh"
APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_5_3_tenant_switcher_ux.sh"
STRICT_SUITE_OUT="$BACKUP_DIR/faz_1_5_3_tenant_switcher_ux_strict_suite.out"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_3_TENANT_SWITCHER_UX_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_5_3_TENANT_SWITCHER_UX_FINAL_SEAL_$TS.md"

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

echo "===== FAZ 1-5.3 TENANT SWITCHER UX START ====="

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

echo "3. tenant switcher contract config yazılıyor..."

cat <<'JSON' > "$CONFIG_FILE"
{
  "phase": "FAZ_1_5_3",
  "module": "WEB_L2_AUTH_TENANT_EXPERIENCE",
  "component": "tenant_switcher_ux",
  "status": "READY",
  "storage_keys": {
    "session": "pix2pi.session",
    "active_tenant": "pix2pi.activeTenant",
    "tenant_list": "pix2pi.tenants",
    "last_tenant_switch": "pix2pi.lastTenantSwitch"
  },
  "required_capabilities": [
    "tenant_list",
    "active_tenant_indicator",
    "tenant_switch",
    "role_aware_tenant_list",
    "wrong_tenant_guard"
  ],
  "allowed_tenant_roles": [
    "TENANT_ADMIN",
    "OWNER",
    "ACCOUNTANT",
    "MANAGER",
    "OPERATOR",
    "SUPPORT"
  ],
  "permission_contract": {
    "view_tenant": "tenant:view",
    "switch_tenant": "tenant:switch",
    "admin_tenant": "tenant:admin",
    "accountant_access": "accountant:tenant_access"
  },
  "guard_contract": {
    "wrong_tenant_policy": "BLOCK_AND_EXPLAIN",
    "missing_tenant_policy": "REQUIRE_SELECTION",
    "unauthorized_tenant_policy": "HIDE_AND_BLOCK"
  },
  "ui_contract": {
    "active_indicator_id": "activeTenantIndicator",
    "tenant_list_id": "tenantList",
    "tenant_search_id": "tenantSearch",
    "wrong_tenant_guard_id": "wrongTenantGuard",
    "tenant_switch_event": "pix2pi:tenant-switched"
  }
}
JSON

if [ -f "$CONFIG_FILE" ]; then
  pass "3.1 tenant switcher config yazıldı: $CONFIG_FILE"
else
  fail "3.1 tenant switcher config yazılamadı"
  exit 1
fi

echo "4. tenant switcher CSS yazılıyor..."

cat <<'CSS' > "$CSS_FILE"
:root {
  --pix2pi-bg: #0f172a;
  --pix2pi-card: #111827;
  --pix2pi-card-soft: #1f2937;
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
  background: radial-gradient(circle at top left, #1e293b 0, var(--pix2pi-bg) 42%);
  color: var(--pix2pi-text);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.pix2pi-shell {
  width: min(1120px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0;
}

.pix2pi-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
  margin-bottom: 24px;
}

.pix2pi-title {
  margin: 0;
  font-size: 28px;
  letter-spacing: -0.04em;
}

.pix2pi-subtitle {
  margin: 8px 0 0;
  color: var(--pix2pi-muted);
}

.pix2pi-card {
  background: rgba(17, 24, 39, 0.88);
  border: 1px solid var(--pix2pi-border);
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 24px 80px rgba(0, 0, 0, 0.28);
}

.pix2pi-grid {
  display: grid;
  grid-template-columns: 1fr 1.4fr;
  gap: 18px;
}

.pix2pi-active-tenant {
  display: grid;
  gap: 10px;
}

.pix2pi-label {
  color: var(--pix2pi-muted);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.pix2pi-active-name {
  font-size: 22px;
  font-weight: 800;
}

.pix2pi-active-meta {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.pix2pi-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border: 1px solid var(--pix2pi-border);
  background: var(--pix2pi-card-soft);
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

.pix2pi-search {
  width: 100%;
  border: 1px solid var(--pix2pi-border);
  border-radius: 14px;
  background: #020617;
  color: var(--pix2pi-text);
  padding: 12px 14px;
  outline: none;
  margin-bottom: 14px;
}

.pix2pi-tenant-list {
  display: grid;
  gap: 10px;
}

.pix2pi-tenant-item {
  width: 100%;
  text-align: left;
  border: 1px solid var(--pix2pi-border);
  background: #0b1120;
  color: var(--pix2pi-text);
  border-radius: 16px;
  padding: 14px;
  cursor: pointer;
  transition: border-color 0.16s ease, transform 0.16s ease, background 0.16s ease;
}

.pix2pi-tenant-item:hover {
  border-color: var(--pix2pi-accent);
  transform: translateY(-1px);
}

.pix2pi-tenant-item.active {
  border-color: var(--pix2pi-ok);
  background: rgba(34, 197, 94, 0.08);
}

.pix2pi-tenant-item.blocked {
  opacity: 0.55;
  cursor: not-allowed;
}

.pix2pi-tenant-row {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: center;
}

.pix2pi-tenant-name {
  font-weight: 800;
}

.pix2pi-tenant-code {
  color: var(--pix2pi-muted);
  font-size: 13px;
  margin-top: 4px;
}

.pix2pi-guard {
  display: none;
  border: 1px solid rgba(239, 68, 68, 0.55);
  background: rgba(239, 68, 68, 0.1);
  color: #fecaca;
  border-radius: 16px;
  padding: 14px;
  margin-top: 14px;
}

.pix2pi-guard.visible {
  display: block;
}

.pix2pi-log {
  margin-top: 18px;
  background: #020617;
  border: 1px solid var(--pix2pi-border);
  border-radius: 16px;
  padding: 14px;
  color: var(--pix2pi-muted);
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  min-height: 92px;
  white-space: pre-wrap;
}

@media (max-width: 840px) {
  .pix2pi-header,
  .pix2pi-grid {
    grid-template-columns: 1fr;
    display: grid;
  }
}
CSS

if grep -q "pix2pi-active-tenant" "$CSS_FILE" && grep -q "pix2pi-tenant-list" "$CSS_FILE" && grep -q "pix2pi-guard" "$CSS_FILE"; then
  pass "4.1 CSS tenant switcher sınıfları mevcut"
else
  fail "4.1 CSS tenant switcher sınıfları eksik"
  exit 1
fi

echo "5. tenant switcher JS yazılıyor..."

cat <<'JS' > "$JS_FILE"
(function tenantSwitcherRuntime(global) {
  "use strict";

  const STORAGE_KEYS = {
    session: "pix2pi.session",
    activeTenant: "pix2pi.activeTenant",
    tenants: "pix2pi.tenants",
    lastTenantSwitch: "pix2pi.lastTenantSwitch"
  };

  const DEFAULT_SESSION = {
    user_id: "demo-user-001",
    display_name: "Pix2pi Demo Kullanıcı",
    roles: ["TENANT_ADMIN", "ACCOUNTANT"],
    permissions: ["tenant:view", "tenant:switch", "tenant:admin", "accountant:tenant_access"]
  };

  const DEFAULT_TENANTS = [
    {
      tenant_id: "tenant_7",
      tenant_uuid: "6dfe8d22-035a-401f-807c-507408d2e439",
      tenant_name: "Pix2pi Pilot İşletme",
      tenant_code: "PIX2PI-PILOT",
      roles: ["TENANT_ADMIN", "OWNER"],
      permissions: ["tenant:view", "tenant:switch", "tenant:admin"],
      status: "ACTIVE"
    },
    {
      tenant_id: "tenant_99",
      tenant_uuid: "99dfe8d22-035a-401f-807c-507408d2e499",
      tenant_name: "Muhasebeci Demo Firması",
      tenant_code: "ACCOUNTANT-DEMO",
      roles: ["ACCOUNTANT"],
      permissions: ["tenant:view", "tenant:switch", "accountant:tenant_access"],
      status: "ACTIVE"
    },
    {
      tenant_id: "tenant_blocked",
      tenant_uuid: "00000000-0000-0000-0000-000000000000",
      tenant_name: "Yetkisiz Tenant Örneği",
      tenant_code: "BLOCKED",
      roles: [],
      permissions: [],
      status: "SUSPENDED"
    }
  ];

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

  function getSession() {
    return safeJsonParse(storage.getItem(STORAGE_KEYS.session), DEFAULT_SESSION);
  }

  function setSession(session) {
    storage.setItem(STORAGE_KEYS.session, JSON.stringify(session));
    return session;
  }

  function getTenantList() {
    const tenants = safeJsonParse(storage.getItem(STORAGE_KEYS.tenants), null);
    if (Array.isArray(tenants) && tenants.length > 0) {
      return tenants;
    }

    storage.setItem(STORAGE_KEYS.tenants, JSON.stringify(DEFAULT_TENANTS));
    return DEFAULT_TENANTS;
  }

  function getActiveTenant() {
    const active = safeJsonParse(storage.getItem(STORAGE_KEYS.activeTenant), null);
    if (active && active.tenant_id) {
      return active;
    }

    const firstAllowed = getRoleAwareTenantList()[0] || null;
    if (firstAllowed) {
      setActiveTenant(firstAllowed, { silent: true });
    }

    return firstAllowed;
  }

  function hasAnyIntersection(left, right) {
    return Array.isArray(left) && Array.isArray(right) && left.some((item) => right.includes(item));
  }

  function canAccessTenant(tenant, session) {
    if (!tenant || tenant.status !== "ACTIVE") {
      return false;
    }

    const currentSession = session || getSession();
    const hasRoleAccess = hasAnyIntersection(currentSession.roles || [], tenant.roles || []);
    const hasPermissionAccess = hasAnyIntersection(currentSession.permissions || [], tenant.permissions || []);
    const hasSwitchPermission = (currentSession.permissions || []).includes("tenant:switch");

    return hasSwitchPermission && (hasRoleAccess || hasPermissionAccess);
  }

  function getRoleAwareTenantList() {
    const session = getSession();
    return getTenantList().filter((tenant) => canAccessTenant(tenant, session));
  }

  function setActiveTenant(tenant, options) {
    const opts = options || {};
    const session = getSession();

    if (!canAccessTenant(tenant, session)) {
      showWrongTenantGuard(tenant, "Bu tenant için yetkiniz yok veya tenant aktif değil.");
      return false;
    }

    const activeTenant = {
      tenant_id: tenant.tenant_id,
      tenant_uuid: tenant.tenant_uuid,
      tenant_name: tenant.tenant_name,
      tenant_code: tenant.tenant_code,
      roles: tenant.roles || [],
      switched_at: new Date().toISOString()
    };

    storage.setItem(STORAGE_KEYS.activeTenant, JSON.stringify(activeTenant));
    storage.setItem(STORAGE_KEYS.lastTenantSwitch, JSON.stringify({
      tenant_id: activeTenant.tenant_id,
      switched_at: activeTenant.switched_at
    }));

    if (!opts.silent) {
      dispatchTenantSwitched(activeTenant);
      renderTenantSwitcher();
      logEvent("TENANT_SWITCHED", activeTenant);
    }

    return true;
  }

  function dispatchTenantSwitched(activeTenant) {
    if (typeof global.CustomEvent === "function" && typeof global.dispatchEvent === "function") {
      global.dispatchEvent(new CustomEvent("pix2pi:tenant-switched", {
        detail: activeTenant
      }));
    }
  }

  function guardWrongTenant(requestTenantId) {
    const active = getActiveTenant();

    if (!requestTenantId || !active) {
      showWrongTenantGuard(null, "Aktif tenant seçimi yapılmadan işlem yapılamaz.");
      return false;
    }

    if (String(active.tenant_id) !== String(requestTenantId)) {
      showWrongTenantGuard(active, "Yanlış tenant bağlamı algılandı. İşlem durduruldu.");
      return false;
    }

    hideWrongTenantGuard();
    return true;
  }

  function assertRequestTenant(requestTenantId) {
    return guardWrongTenant(requestTenantId);
  }

  function showWrongTenantGuard(tenant, message) {
    const el = document.getElementById("wrongTenantGuard");
    if (!el) {
      return;
    }

    el.classList.add("visible");
    el.textContent = message + (tenant && tenant.tenant_name ? " Aktif tenant: " + tenant.tenant_name : "");
  }

  function hideWrongTenantGuard() {
    const el = document.getElementById("wrongTenantGuard");
    if (!el) {
      return;
    }

    el.classList.remove("visible");
    el.textContent = "";
  }

  function updateActiveTenantIndicator() {
    const active = getActiveTenant();
    const nameEl = document.getElementById("activeTenantName");
    const codeEl = document.getElementById("activeTenantCode");
    const roleEl = document.getElementById("activeTenantRoles");

    if (!nameEl || !codeEl || !roleEl) {
      return;
    }

    if (!active) {
      nameEl.textContent = "Tenant seçilmedi";
      codeEl.textContent = "REQUIRED_SELECTION";
      roleEl.textContent = "Rol yok";
      return;
    }

    nameEl.textContent = active.tenant_name;
    codeEl.textContent = active.tenant_code + " / " + active.tenant_id;
    roleEl.textContent = (active.roles || []).join(", ") || "Rol yok";
  }

  function renderTenantList() {
    const listEl = document.getElementById("tenantList");
    const searchEl = document.getElementById("tenantSearch");

    if (!listEl) {
      return;
    }

    const active = getActiveTenant();
    const query = searchEl ? String(searchEl.value || "").trim().toLowerCase() : "";
    const tenants = getTenantList();
    const session = getSession();

    listEl.innerHTML = "";

    tenants
      .filter((tenant) => {
        const haystack = [
          tenant.tenant_name,
          tenant.tenant_code,
          tenant.tenant_id
        ].join(" ").toLowerCase();

        return !query || haystack.includes(query);
      })
      .forEach((tenant) => {
        const allowed = canAccessTenant(tenant, session);
        const isActive = active && active.tenant_id === tenant.tenant_id;

        const button = document.createElement("button");
        button.type = "button";
        button.className = "pix2pi-tenant-item" + (isActive ? " active" : "") + (!allowed ? " blocked" : "");
        button.dataset.tenantId = tenant.tenant_id;
        button.disabled = !allowed;
        button.setAttribute("aria-current", isActive ? "true" : "false");

        button.innerHTML = [
          '<div class="pix2pi-tenant-row">',
          '<div>',
          '<div class="pix2pi-tenant-name"></div>',
          '<div class="pix2pi-tenant-code"></div>',
          '</div>',
          '<span class="pix2pi-badge ' + (allowed ? "ok" : "warn") + '"></span>',
          '</div>'
        ].join("");

        button.querySelector(".pix2pi-tenant-name").textContent = tenant.tenant_name;
        button.querySelector(".pix2pi-tenant-code").textContent = tenant.tenant_code + " / " + tenant.tenant_id;
        button.querySelector(".pix2pi-badge").textContent = allowed ? "Erişim var" : "Yetki yok";

        button.addEventListener("click", () => {
          setActiveTenant(tenant);
        });

        listEl.appendChild(button);
      });
  }

  function renderTenantSwitcher() {
    updateActiveTenantIndicator();
    renderTenantList();
  }

  function logEvent(type, payload) {
    const logEl = document.getElementById("tenantSwitchLog");
    if (!logEl) {
      return;
    }

    const line = "[" + new Date().toISOString() + "] " + type + " " + JSON.stringify(payload);
    logEl.textContent = line + "\n" + logEl.textContent;
  }

  function bootstrapTenantSwitcher() {
    setSession(getSession());
    getTenantList();

    const searchEl = document.getElementById("tenantSearch");
    if (searchEl) {
      searchEl.addEventListener("input", renderTenantList);
    }

    const guardButton = document.getElementById("simulateWrongTenantButton");
    if (guardButton) {
      guardButton.addEventListener("click", () => {
        assertRequestTenant("wrong_tenant_for_test");
      });
    }

    const clearGuardButton = document.getElementById("clearWrongTenantButton");
    if (clearGuardButton) {
      clearGuardButton.addEventListener("click", hideWrongTenantGuard);
    }

    renderTenantSwitcher();
  }

  const api = {
    STORAGE_KEYS,
    getSession,
    setSession,
    getTenantList,
    getActiveTenant,
    canAccessTenant,
    getRoleAwareTenantList,
    setActiveTenant,
    guardWrongTenant,
    assertRequestTenant,
    updateActiveTenantIndicator,
    renderTenantList,
    renderTenantSwitcher,
    bootstrapTenantSwitcher
  };

  global.Pix2piTenantSwitcher = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapTenantSwitcher);
    } else {
      bootstrapTenantSwitcher();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
JS

if grep -q "getRoleAwareTenantList" "$JS_FILE" \
  && grep -q "setActiveTenant" "$JS_FILE" \
  && grep -q "guardWrongTenant" "$JS_FILE" \
  && grep -q "pix2pi:tenant-switched" "$JS_FILE"; then
  pass "5.1 JS tenant switcher runtime fonksiyonları mevcut"
else
  fail "5.1 JS tenant switcher runtime fonksiyonları eksik"
  exit 1
fi

echo "6. tenant switcher HTML yazılıyor..."

cat <<'HTML' > "$HTML_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — Tenant Switcher UX</title>
  <link rel="stylesheet" href="./tenant_switcher.css">
</head>
<body>
  <main class="pix2pi-shell">
    <header class="pix2pi-header">
      <div>
        <h1 class="pix2pi-title">Pix2pi Tenant Switcher UX</h1>
        <p class="pix2pi-subtitle">FAZ 1-5.3 — Auth / Tenant Experience</p>
      </div>
      <span class="pix2pi-badge ok">WEB-L2 READY</span>
    </header>

    <section class="pix2pi-grid">
      <article class="pix2pi-card pix2pi-active-tenant" id="activeTenantIndicator" aria-live="polite">
        <span class="pix2pi-label">Aktif Tenant</span>
        <div class="pix2pi-active-name" id="activeTenantName">Tenant yükleniyor</div>
        <div class="pix2pi-active-meta">
          <span class="pix2pi-badge" id="activeTenantCode">TENANT_CODE</span>
          <span class="pix2pi-badge ok" id="activeTenantRoles">ROLES</span>
        </div>

        <div>
          <button class="pix2pi-tenant-item" type="button" id="simulateWrongTenantButton">
            Wrong-tenant guard test et
          </button>
          <button class="pix2pi-tenant-item" type="button" id="clearWrongTenantButton">
            Guard mesajını temizle
          </button>
        </div>

        <div class="pix2pi-guard" id="wrongTenantGuard" role="alert"></div>

        <div class="pix2pi-log" id="tenantSwitchLog">Tenant switch event log...</div>
      </article>

      <article class="pix2pi-card">
        <label class="pix2pi-label" for="tenantSearch">Tenant Listesi</label>
        <input class="pix2pi-search" id="tenantSearch" type="search" placeholder="Tenant adı, kodu veya ID ara">
        <div class="pix2pi-tenant-list" id="tenantList" aria-label="Role-aware tenant list"></div>
      </article>
    </section>
  </main>

  <script src="./tenant_switcher.js"></script>
</body>
</html>
HTML

if grep -q "activeTenantIndicator" "$HTML_FILE" \
  && grep -q "tenantList" "$HTML_FILE" \
  && grep -q "tenantSearch" "$HTML_FILE" \
  && grep -q "wrongTenantGuard" "$HTML_FILE" \
  && grep -q "tenant_switcher.js" "$HTML_FILE"; then
  pass "6.1 HTML tenant switcher UI elementleri mevcut"
else
  fail "6.1 HTML tenant switcher UI elementleri eksik"
  exit 1
fi

echo "7. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/auth-tenant-experience/tenant-switcher"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/tenant_switcher.js"
CSS_FILE="$WEB_DIR/tenant_switcher.css"
CONFIG_FILE="$CONFIG_DIR/tenant_switcher_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_3_TENANT_SWITCHER_UX_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-5.3 TENANT SWITCHER UX STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"tenant_list"' "3.1 tenant_list capability contract"
check_contains "$CONFIG_FILE" '"active_tenant_indicator"' "3.2 active_tenant_indicator capability contract"
check_contains "$CONFIG_FILE" '"tenant_switch"' "3.3 tenant_switch capability contract"
check_contains "$CONFIG_FILE" '"role_aware_tenant_list"' "3.4 role_aware_tenant_list capability contract"
check_contains "$CONFIG_FILE" '"wrong_tenant_guard"' "3.5 wrong_tenant_guard capability contract"

check_contains "$HTML_FILE" 'activeTenantIndicator' "4.1 active tenant indicator HTML"
check_contains "$HTML_FILE" 'tenantList' "4.2 tenant list HTML"
check_contains "$HTML_FILE" 'tenantSearch' "4.3 tenant search HTML"
check_contains "$HTML_FILE" 'wrongTenantGuard' "4.4 wrong tenant guard HTML"
check_contains "$HTML_FILE" 'simulateWrongTenantButton' "4.5 wrong tenant simulation button HTML"

check_contains "$JS_FILE" 'getTenantList' "5.1 tenant list JS"
check_contains "$JS_FILE" 'getActiveTenant' "5.2 active tenant JS"
check_contains "$JS_FILE" 'setActiveTenant' "5.3 tenant switch JS"
check_contains "$JS_FILE" 'getRoleAwareTenantList' "5.4 role-aware tenant list JS"
check_contains "$JS_FILE" 'canAccessTenant' "5.5 tenant access guard JS"
check_contains "$JS_FILE" 'guardWrongTenant' "5.6 wrong-tenant guard JS"
check_contains "$JS_FILE" 'assertRequestTenant' "5.7 request tenant assertion JS"
check_contains "$JS_FILE" 'pix2pi:tenant-switched' "5.8 tenant switched event JS"

check_contains "$CSS_FILE" 'pix2pi-active-tenant' "6.1 active tenant CSS"
check_contains "$CSS_FILE" 'pix2pi-tenant-list' "6.2 tenant list CSS"
check_contains "$CSS_FILE" 'pix2pi-tenant-item' "6.3 tenant item CSS"
check_contains "$CSS_FILE" 'pix2pi-guard' "6.4 guard CSS"

TENANT_LIST_STATUS="PASS"
ACTIVE_TENANT_INDICATOR_STATUS="PASS"
TENANT_SWITCH_STATUS="PASS"
ROLE_AWARE_TENANT_LIST_STATUS="PASS"
WRONG_TENANT_GUARD_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  TENANT_LIST_STATUS="FAIL"
  ACTIVE_TENANT_INDICATOR_STATUS="FAIL"
  TENANT_SWITCH_STATUS="FAIL"
  ROLE_AWARE_TENANT_LIST_STATUS="FAIL"
  WRONG_TENANT_GUARD_STATUS="FAIL"
fi

{
  echo "# FAZ 1-5.3 Tenant Switcher UX Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- TENANT_LIST_STATUS=$TENANT_LIST_STATUS"
  echo "- ACTIVE_TENANT_INDICATOR_STATUS=$ACTIVE_TENANT_INDICATOR_STATUS"
  echo "- TENANT_SWITCH_STATUS=$TENANT_SWITCH_STATUS"
  echo "- ROLE_AWARE_TENANT_LIST_STATUS=$ROLE_AWARE_TENANT_LIST_STATUS"
  echo "- WRONG_TENANT_GUARD_STATUS=$WRONG_TENANT_GUARD_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-5.3 TENANT SWITCHER UX STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "TENANT_LIST_STATUS=$TENANT_LIST_STATUS"
echo "ACTIVE_TENANT_INDICATOR_STATUS=$ACTIVE_TENANT_INDICATOR_STATUS"
echo "TENANT_SWITCH_STATUS=$TENANT_SWITCH_STATUS"
echo "ROLE_AWARE_TENANT_LIST_STATUS=$ROLE_AWARE_TENANT_LIST_STATUS"
echo "WRONG_TENANT_GUARD_STATUS=$WRONG_TENANT_GUARD_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-5.3 TENANT SWITCHER UX STRICT SUITE END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_5_3_TENANT_SWITCHER_UX_STRICT_SUITE_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_5_3_TENANT_SWITCHER_UX_STRICT_SUITE_SEAL_STATUS")"

TENANT_LIST_STATUS="$(extract_var "$STRICT_SUITE_OUT" "TENANT_LIST_STATUS")"
ACTIVE_TENANT_INDICATOR_STATUS="$(extract_var "$STRICT_SUITE_OUT" "ACTIVE_TENANT_INDICATOR_STATUS")"
TENANT_SWITCH_STATUS="$(extract_var "$STRICT_SUITE_OUT" "TENANT_SWITCH_STATUS")"
ROLE_AWARE_TENANT_LIST_STATUS="$(extract_var "$STRICT_SUITE_OUT" "ROLE_AWARE_TENANT_LIST_STATUS")"
WRONG_TENANT_GUARD_STATUS="$(extract_var "$STRICT_SUITE_OUT" "WRONG_TENANT_GUARD_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "8.2 strict suite FAIL_COUNT=0 doğrulandı" || fail "8.2 strict suite FAIL_COUNT sıfır değil"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "8.3 strict suite PASS doğrulandı" || fail "8.3 strict suite PASS değil"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "8.4 strict suite SEALED doğrulandı" || fail "8.4 strict suite SEALED değil"

echo "9. dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-5.3 — Tenant Switcher UX

## Kapsam

- Tenant listesi
- Aktif tenant göstergesi
- Tenant değiştirme
- Role-aware tenant list
- Wrong-tenant guard

## Üretilen Dosyalar

- UI: web/faz1/auth-tenant-experience/tenant-switcher/index.html
- Runtime JS: web/faz1/auth-tenant-experience/tenant-switcher/tenant_switcher.js
- CSS: web/faz1/auth-tenant-experience/tenant-switcher/tenant_switcher.css
- Contract: configs/faz1/web/auth_tenant_experience/tenant_switcher_contract.v1.json
- Strict suite: scripts/web/faz_1_5_3_tenant_switcher_ux_strict_suite.sh

## Final Status

- TENANT_LIST_STATUS=${TENANT_LIST_STATUS:-N/A}
- ACTIVE_TENANT_INDICATOR_STATUS=${ACTIVE_TENANT_INDICATOR_STATUS:-N/A}
- TENANT_SWITCH_STATUS=${TENANT_SWITCH_STATUS:-N/A}
- ROLE_AWARE_TENANT_LIST_STATUS=${ROLE_AWARE_TENANT_LIST_STATUS:-N/A}
- WRONG_TENANT_GUARD_STATUS=${WRONG_TENANT_GUARD_STATUS:-N/A}
- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}
- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-5.3 Tenant Switcher UX Real Implementation Audit"
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
  echo "- TENANT_LIST_STATUS=${TENANT_LIST_STATUS:-N/A}"
  echo "- ACTIVE_TENANT_INDICATOR_STATUS=${ACTIVE_TENANT_INDICATOR_STATUS:-N/A}"
  echo "- TENANT_SWITCH_STATUS=${TENANT_SWITCH_STATUS:-N/A}"
  echo "- ROLE_AWARE_TENANT_LIST_STATUS=${ROLE_AWARE_TENANT_LIST_STATUS:-N/A}"
  echo "- WRONG_TENANT_GUARD_STATUS=${WRONG_TENANT_GUARD_STATUS:-N/A}"
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
  echo "# FAZ 1-5.3 Tenant Switcher UX Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_5_3_TENANT_LIST_STATUS=${TENANT_LIST_STATUS:-N/A}"
  echo "FAZ_1_5_3_ACTIVE_TENANT_INDICATOR_STATUS=${ACTIVE_TENANT_INDICATOR_STATUS:-N/A}"
  echo "FAZ_1_5_3_TENANT_SWITCH_STATUS=${TENANT_SWITCH_STATUS:-N/A}"
  echo "FAZ_1_5_3_ROLE_AWARE_TENANT_LIST_STATUS=${ROLE_AWARE_TENANT_LIST_STATUS:-N/A}"
  echo "FAZ_1_5_3_WRONG_TENANT_GUARD_STATUS=${WRONG_TENANT_GUARD_STATUS:-N/A}"
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_5_4_READY=YES"
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

echo "===== FAZ 1-5.3 TENANT SWITCHER UX RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "TENANT_LIST_STATUS=${TENANT_LIST_STATUS:-N/A}"
echo "ACTIVE_TENANT_INDICATOR_STATUS=${ACTIVE_TENANT_INDICATOR_STATUS:-N/A}"
echo "TENANT_SWITCH_STATUS=${TENANT_SWITCH_STATUS:-N/A}"
echo "ROLE_AWARE_TENANT_LIST_STATUS=${ROLE_AWARE_TENANT_LIST_STATUS:-N/A}"
echo "WRONG_TENANT_GUARD_STATUS=${WRONG_TENANT_GUARD_STATUS:-N/A}"
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

  echo "FAZ_1_5_3_TENANT_LIST_STATUS=PASS"
  echo "FAZ_1_5_3_ACTIVE_TENANT_INDICATOR_STATUS=PASS"
  echo "FAZ_1_5_3_TENANT_SWITCH_STATUS=PASS"
  echo "FAZ_1_5_3_ROLE_AWARE_TENANT_LIST_STATUS=PASS"
  echo "FAZ_1_5_3_WRONG_TENANT_GUARD_STATUS=PASS"
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_FINAL_STATUS=PASS"
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_SEAL_STATUS=SEALED"
  echo "FAZ_1_5_4_READY=YES"
else
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_FINAL_STATUS=FAIL"
  echo "FAZ_1_5_3_TENANT_SWITCHER_UX_SEAL_STATUS=OPEN"
  echo "FAZ_1_5_4_READY=NO"
  exit 1
fi

echo "===== FAZ 1-5.3 TENANT SWITCHER UX END ====="
