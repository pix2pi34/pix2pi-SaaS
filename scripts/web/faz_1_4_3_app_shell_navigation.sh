#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_4_3_APP_SHELL_NAVIGATION"

BACKUP_DIR="$REPO/backups/faz1/faz_1_4_3_app_shell_navigation_$TS"
WEB_DIR="$REPO/web/faz1/ui-foundation/app-shell"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
DOC_DIR="$REPO/docs/faz1/web"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
SCRIPT_DIR="$REPO/scripts/web"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/app_shell.js"
CSS_FILE="$WEB_DIR/app_shell.css"
CONFIG_FILE="$CONFIG_DIR/app_shell_navigation_contract.v1.json"
DOC_FILE="$DOC_DIR/FAZ_1_4_3_APP_SHELL_NAVIGATION.md"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_4_3_app_shell_navigation_strict_suite.sh"
APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_4_3_app_shell_navigation.sh"
STRICT_SUITE_OUT="$BACKUP_DIR/faz_1_4_3_app_shell_navigation_strict_suite.out"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_3_APP_SHELL_NAVIGATION_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_4_3_APP_SHELL_NAVIGATION_FINAL_SEAL_$TS.md"

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

echo "===== FAZ 1-4.3 APP SHELL / NAVIGATION START ====="

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

echo "3. app shell contract config yazılıyor..."

cat <<'JSON' > "$CONFIG_FILE"
{
  "phase": "FAZ_1_4_3",
  "module": "WEB_L1_UI_FOUNDATION_DESIGN_SYSTEM",
  "component": "app_shell_navigation",
  "status": "READY",
  "required_capabilities": [
    "app_shell",
    "sidebar",
    "topbar",
    "breadcrumb",
    "tenant_indicator",
    "responsive_shell"
  ],
  "shell_contract": {
    "root_id": "pix2piAppShell",
    "sidebar_id": "pix2piSidebar",
    "topbar_id": "pix2piTopbar",
    "breadcrumb_id": "pix2piBreadcrumb",
    "tenant_indicator_id": "pix2piTenantIndicator",
    "content_id": "pix2piMainContent",
    "mobile_toggle_id": "pix2piSidebarToggle"
  },
  "navigation_groups": [
    "dashboard",
    "erp",
    "operations",
    "accounting",
    "admin",
    "ops"
  ],
  "responsive_contract": {
    "desktop_min_width_px": 1024,
    "tablet_min_width_px": 768,
    "mobile_policy": "COLLAPSIBLE_SIDEBAR",
    "shell_policy": "SIDEBAR_TOPBAR_CONTENT_GRID"
  },
  "tenant_contract": {
    "active_tenant_storage_key": "pix2pi.activeTenant",
    "fallback_tenant_name": "Tenant seçilmedi",
    "wrong_tenant_guard_source": "FAZ_1_5_3_TENANT_SWITCHER_UX"
  }
}
JSON

if [ -f "$CONFIG_FILE" ]; then
  pass "3.1 app shell config yazıldı: $CONFIG_FILE"
else
  fail "3.1 app shell config yazılamadı"
  exit 1
fi

echo "4. app shell CSS yazılıyor..."

cat <<'CSS' > "$CSS_FILE"
:root {
  --pix2pi-bg: #0f172a;
  --pix2pi-surface: #111827;
  --pix2pi-surface-soft: #1f2937;
  --pix2pi-content: #020617;
  --pix2pi-border: #334155;
  --pix2pi-text: #e5e7eb;
  --pix2pi-muted: #9ca3af;
  --pix2pi-accent: #38bdf8;
  --pix2pi-ok: #22c55e;
  --pix2pi-warn: #f59e0b;
  --pix2pi-danger: #ef4444;
  --pix2pi-sidebar-width: 280px;
  --pix2pi-topbar-height: 72px;
  --pix2pi-radius-lg: 20px;
  --pix2pi-radius-md: 14px;
  --pix2pi-shadow: 0 24px 80px rgba(0, 0, 0, 0.28);
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-height: 100vh;
  background: var(--pix2pi-bg);
  color: var(--pix2pi-text);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.pix2pi-app-shell {
  min-height: 100vh;
  display: grid;
  grid-template-columns: var(--pix2pi-sidebar-width) 1fr;
  grid-template-rows: var(--pix2pi-topbar-height) 1fr;
  grid-template-areas:
    "sidebar topbar"
    "sidebar content";
}

.pix2pi-sidebar {
  grid-area: sidebar;
  background: linear-gradient(180deg, #111827 0%, #020617 100%);
  border-right: 1px solid var(--pix2pi-border);
  padding: 20px;
  position: sticky;
  top: 0;
  height: 100vh;
  overflow: auto;
}

.pix2pi-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: 950;
  letter-spacing: -0.04em;
  font-size: 22px;
  margin-bottom: 22px;
}

.pix2pi-brand-mark {
  width: 38px;
  height: 38px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  background: rgba(56, 189, 248, 0.14);
  border: 1px solid rgba(56, 189, 248, 0.45);
}

.pix2pi-nav {
  display: grid;
  gap: 18px;
}

.pix2pi-nav-group {
  display: grid;
  gap: 8px;
}

.pix2pi-nav-group-title {
  color: var(--pix2pi-muted);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
}

.pix2pi-nav-item {
  width: 100%;
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: center;
  border: 1px solid transparent;
  background: transparent;
  color: var(--pix2pi-text);
  border-radius: var(--pix2pi-radius-md);
  padding: 11px 12px;
  cursor: pointer;
  text-align: left;
}

.pix2pi-nav-item:hover {
  background: rgba(148, 163, 184, 0.08);
  border-color: var(--pix2pi-border);
}

.pix2pi-nav-item.active {
  background: rgba(56, 189, 248, 0.12);
  border-color: rgba(56, 189, 248, 0.45);
}

.pix2pi-topbar {
  grid-area: topbar;
  background: rgba(17, 24, 39, 0.88);
  border-bottom: 1px solid var(--pix2pi-border);
  backdrop-filter: blur(16px);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding: 0 22px;
  position: sticky;
  top: 0;
  z-index: 10;
}

.pix2pi-sidebar-toggle {
  display: none;
  border: 1px solid var(--pix2pi-border);
  background: var(--pix2pi-surface-soft);
  color: var(--pix2pi-text);
  border-radius: 12px;
  padding: 9px 11px;
  cursor: pointer;
}

.pix2pi-breadcrumb {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
  color: var(--pix2pi-muted);
  font-size: 14px;
}

.pix2pi-breadcrumb strong {
  color: var(--pix2pi-text);
}

.pix2pi-topbar-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

.pix2pi-tenant-indicator {
  display: inline-flex;
  flex-direction: column;
  gap: 3px;
  border: 1px solid var(--pix2pi-border);
  background: var(--pix2pi-content);
  border-radius: 14px;
  padding: 8px 12px;
  min-width: 180px;
}

.pix2pi-tenant-name {
  font-weight: 850;
  font-size: 13px;
}

.pix2pi-tenant-code {
  color: var(--pix2pi-muted);
  font-size: 12px;
}

.pix2pi-badge {
  display: inline-flex;
  border: 1px solid var(--pix2pi-border);
  background: var(--pix2pi-surface-soft);
  color: var(--pix2pi-text);
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 13px;
}

.pix2pi-badge.ok {
  border-color: rgba(34, 197, 94, 0.5);
  color: #bbf7d0;
}

.pix2pi-main-content {
  grid-area: content;
  padding: 24px;
  background: radial-gradient(circle at top left, #1e293b 0, var(--pix2pi-bg) 38%);
}

.pix2pi-page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 20px;
}

.pix2pi-page-title {
  margin: 0;
  font-size: 30px;
  letter-spacing: -0.04em;
}

.pix2pi-page-subtitle {
  margin: 8px 0 0;
  color: var(--pix2pi-muted);
}

.pix2pi-content-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 18px;
}

.pix2pi-card {
  background: rgba(17, 24, 39, 0.9);
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: 20px;
  box-shadow: var(--pix2pi-shadow);
}

.pix2pi-card-title {
  margin: 0;
  font-size: 18px;
}

.pix2pi-card-text {
  color: var(--pix2pi-muted);
  line-height: 1.6;
}

body.pix2pi-sidebar-open .pix2pi-sidebar {
  transform: translateX(0);
}

@media (max-width: 1023px) {
  .pix2pi-app-shell {
    grid-template-columns: 1fr;
    grid-template-areas:
      "topbar"
      "content";
  }

  .pix2pi-sidebar {
    position: fixed;
    z-index: 20;
    transform: translateX(-105%);
    transition: transform 0.18s ease;
    width: var(--pix2pi-sidebar-width);
  }

  .pix2pi-sidebar-toggle {
    display: inline-flex;
  }

  .pix2pi-content-grid {
    grid-template-columns: 1fr;
  }

  .pix2pi-topbar {
    padding: 0 14px;
  }

  .pix2pi-tenant-indicator {
    min-width: 130px;
  }
}
CSS

if grep -q "pix2pi-app-shell" "$CSS_FILE" \
  && grep -q "pix2pi-sidebar" "$CSS_FILE" \
  && grep -q "pix2pi-topbar" "$CSS_FILE" \
  && grep -q "pix2pi-breadcrumb" "$CSS_FILE" \
  && grep -q "pix2pi-tenant-indicator" "$CSS_FILE"; then
  pass "4.1 CSS app shell/navigation sınıfları mevcut"
else
  fail "4.1 CSS app shell/navigation sınıfları eksik"
  exit 1
fi

echo "5. app shell JS yazılıyor..."

cat <<'JS' > "$JS_FILE"
(function appShellNavigationRuntime(global) {
  "use strict";

  const STORAGE_KEYS = {
    activeTenant: "pix2pi.activeTenant",
    activeRoute: "pix2pi.activeRoute",
    sidebarOpen: "pix2pi.sidebarOpen"
  };

  const NAVIGATION = [
    {
      group: "dashboard",
      groupLabel: "Dashboard",
      items: [
        { id: "dashboard", label: "Genel Durum", path: "/dashboard", breadcrumb: ["Pix2pi", "Dashboard"] }
      ]
    },
    {
      group: "erp",
      groupLabel: "ERP",
      items: [
        { id: "erp-core", label: "ERP Çekirdeği", path: "/erp", breadcrumb: ["Pix2pi", "ERP"] },
        { id: "stock", label: "Stok", path: "/erp/stock", breadcrumb: ["Pix2pi", "ERP", "Stok"] }
      ]
    },
    {
      group: "operations",
      groupLabel: "Operasyon",
      items: [
        { id: "pos", label: "POS", path: "/pos", breadcrumb: ["Pix2pi", "Operasyon", "POS"] },
        { id: "orders", label: "Siparişler", path: "/orders", breadcrumb: ["Pix2pi", "Operasyon", "Siparişler"] }
      ]
    },
    {
      group: "accounting",
      groupLabel: "Muhasebe",
      items: [
        { id: "accounting", label: "TDHP", path: "/accounting", breadcrumb: ["Pix2pi", "Muhasebe", "TDHP"] },
        { id: "exports", label: "Export", path: "/accounting/exports", breadcrumb: ["Pix2pi", "Muhasebe", "Export"] }
      ]
    },
    {
      group: "admin",
      groupLabel: "Admin",
      items: [
        { id: "users", label: "Kullanıcılar", path: "/admin/users", breadcrumb: ["Pix2pi", "Admin", "Kullanıcılar"] },
        { id: "settings", label: "Ayarlar", path: "/admin/settings", breadcrumb: ["Pix2pi", "Admin", "Ayarlar"] }
      ]
    },
    {
      group: "ops",
      groupLabel: "Ops",
      items: [
        { id: "ops-console", label: "Ops Console", path: "/ops", breadcrumb: ["Pix2pi", "Ops"] }
      ]
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

  function getActiveTenant() {
    return safeJsonParse(storage.getItem(STORAGE_KEYS.activeTenant), {
      tenant_id: "tenant_7",
      tenant_name: "Pix2pi Pilot İşletme",
      tenant_code: "PIX2PI-PILOT"
    });
  }

  function getActiveRoute() {
    return storage.getItem(STORAGE_KEYS.activeRoute) || "dashboard";
  }

  function findNavigationItem(id) {
    for (const group of NAVIGATION) {
      const item = group.items.find((candidate) => candidate.id === id);
      if (item) {
        return item;
      }
    }

    return NAVIGATION[0].items[0];
  }

  function setActiveRoute(id) {
    const item = findNavigationItem(id);
    storage.setItem(STORAGE_KEYS.activeRoute, item.id);
    renderSidebarNavigation();
    renderBreadcrumb();
    renderMainContent();
    closeSidebar();
    return item;
  }

  function toggleSidebar() {
    const isOpen = document.body.classList.toggle("pix2pi-sidebar-open");
    storage.setItem(STORAGE_KEYS.sidebarOpen, isOpen ? "true" : "false");
    return isOpen;
  }

  function closeSidebar() {
    document.body.classList.remove("pix2pi-sidebar-open");
    storage.setItem(STORAGE_KEYS.sidebarOpen, "false");
  }

  function renderTenantIndicator() {
    const tenant = getActiveTenant();
    const nameEl = document.getElementById("pix2piTenantName");
    const codeEl = document.getElementById("pix2piTenantCode");

    if (nameEl) {
      nameEl.textContent = tenant.tenant_name || "Tenant seçilmedi";
    }

    if (codeEl) {
      codeEl.textContent = (tenant.tenant_code || "NO_CODE") + " / " + (tenant.tenant_id || "NO_TENANT");
    }

    return tenant;
  }

  function renderBreadcrumb() {
    const breadcrumbEl = document.getElementById("pix2piBreadcrumb");
    if (!breadcrumbEl) {
      return null;
    }

    const item = findNavigationItem(getActiveRoute());
    breadcrumbEl.innerHTML = "";

    item.breadcrumb.forEach((part, index) => {
      const span = document.createElement(index === item.breadcrumb.length - 1 ? "strong" : "span");
      span.textContent = part;
      breadcrumbEl.appendChild(span);

      if (index < item.breadcrumb.length - 1) {
        const separator = document.createElement("span");
        separator.textContent = "/";
        breadcrumbEl.appendChild(separator);
      }
    });

    return item.breadcrumb;
  }

  function renderSidebarNavigation() {
    const navEl = document.getElementById("pix2piNavigation");
    if (!navEl) {
      return;
    }

    const activeRoute = getActiveRoute();
    navEl.innerHTML = "";

    NAVIGATION.forEach((group) => {
      const groupEl = document.createElement("section");
      groupEl.className = "pix2pi-nav-group";
      groupEl.dataset.navGroup = group.group;

      const title = document.createElement("div");
      title.className = "pix2pi-nav-group-title";
      title.textContent = group.groupLabel;
      groupEl.appendChild(title);

      group.items.forEach((item) => {
        const button = document.createElement("button");
        button.type = "button";
        button.className = "pix2pi-nav-item" + (item.id === activeRoute ? " active" : "");
        button.dataset.routeId = item.id;
        button.innerHTML = "<span></span><small></small>";
        button.querySelector("span").textContent = item.label;
        button.querySelector("small").textContent = "›";
        button.addEventListener("click", () => setActiveRoute(item.id));
        groupEl.appendChild(button);
      });

      navEl.appendChild(groupEl);
    });
  }

  function renderMainContent() {
    const item = findNavigationItem(getActiveRoute());
    const titleEl = document.getElementById("pix2piPageTitle");
    const subtitleEl = document.getElementById("pix2piPageSubtitle");
    const contentEl = document.getElementById("pix2piPageContent");

    if (titleEl) {
      titleEl.textContent = item.label;
    }

    if (subtitleEl) {
      subtitleEl.textContent = item.path + " route yüzeyi / app shell placeholder";
    }

    if (contentEl) {
      contentEl.innerHTML = [
        '<article class="pix2pi-card">',
        '<h2 class="pix2pi-card-title">Navigation State</h2>',
        '<p class="pix2pi-card-text">Aktif route: ' + item.id + '</p>',
        '<p class="pix2pi-card-text">Breadcrumb: ' + item.breadcrumb.join(" / ") + '</p>',
        '</article>',
        '<article class="pix2pi-card">',
        '<h2 class="pix2pi-card-title">Tenant Context</h2>',
        '<p class="pix2pi-card-text">' + JSON.stringify(getActiveTenant()) + '</p>',
        '</article>'
      ].join("");
    }

    return item;
  }

  function bootstrapAppShellNavigation() {
    const toggle = document.getElementById("pix2piSidebarToggle");
    if (toggle) {
      toggle.addEventListener("click", toggleSidebar);
    }

    renderTenantIndicator();
    renderSidebarNavigation();
    renderBreadcrumb();
    renderMainContent();
  }

  const api = {
    STORAGE_KEYS,
    NAVIGATION,
    getActiveTenant,
    getActiveRoute,
    findNavigationItem,
    setActiveRoute,
    toggleSidebar,
    closeSidebar,
    renderTenantIndicator,
    renderBreadcrumb,
    renderSidebarNavigation,
    renderMainContent,
    bootstrapAppShellNavigation
  };

  global.Pix2piAppShellNavigation = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapAppShellNavigation);
    } else {
      bootstrapAppShellNavigation();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
JS

if grep -q "renderSidebarNavigation" "$JS_FILE" \
  && grep -q "renderBreadcrumb" "$JS_FILE" \
  && grep -q "renderTenantIndicator" "$JS_FILE" \
  && grep -q "toggleSidebar" "$JS_FILE" \
  && grep -q "bootstrapAppShellNavigation" "$JS_FILE"; then
  pass "5.1 JS app shell/navigation runtime fonksiyonları mevcut"
else
  fail "5.1 JS app shell/navigation runtime fonksiyonları eksik"
  exit 1
fi

echo "6. app shell HTML yazılıyor..."

cat <<'HTML' > "$HTML_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — App Shell / Navigation</title>
  <link rel="stylesheet" href="./app_shell.css">
</head>
<body>
  <div class="pix2pi-app-shell" id="pix2piAppShell">
    <aside class="pix2pi-sidebar" id="pix2piSidebar">
      <div class="pix2pi-brand">
        <span class="pix2pi-brand-mark">P</span>
        <span>Pix2pi</span>
      </div>

      <nav class="pix2pi-nav" id="pix2piNavigation" aria-label="Pix2pi ana navigasyon"></nav>
    </aside>

    <header class="pix2pi-topbar" id="pix2piTopbar">
      <div style="display:flex; align-items:center; gap:12px;">
        <button class="pix2pi-sidebar-toggle" id="pix2piSidebarToggle" type="button">☰</button>
        <div class="pix2pi-breadcrumb" id="pix2piBreadcrumb" aria-label="Breadcrumb"></div>
      </div>

      <div class="pix2pi-topbar-actions">
        <span class="pix2pi-badge ok">WEB-L1 READY</span>
        <div class="pix2pi-tenant-indicator" id="pix2piTenantIndicator">
          <span class="pix2pi-tenant-name" id="pix2piTenantName">Tenant yükleniyor</span>
          <span class="pix2pi-tenant-code" id="pix2piTenantCode">TENANT_CODE</span>
        </div>
      </div>
    </header>

    <main class="pix2pi-main-content" id="pix2piMainContent">
      <section class="pix2pi-page-header">
        <div>
          <h1 class="pix2pi-page-title" id="pix2piPageTitle">App Shell</h1>
          <p class="pix2pi-page-subtitle" id="pix2piPageSubtitle">Navigation iskeleti yükleniyor</p>
        </div>
      </section>

      <section class="pix2pi-content-grid" id="pix2piPageContent"></section>
    </main>
  </div>

  <script src="./app_shell.js"></script>
</body>
</html>
HTML

if grep -q "pix2piAppShell" "$HTML_FILE" \
  && grep -q "pix2piSidebar" "$HTML_FILE" \
  && grep -q "pix2piTopbar" "$HTML_FILE" \
  && grep -q "pix2piBreadcrumb" "$HTML_FILE" \
  && grep -q "pix2piTenantIndicator" "$HTML_FILE" \
  && grep -q "pix2piMainContent" "$HTML_FILE"; then
  pass "6.1 HTML app shell/navigation elementleri mevcut"
else
  fail "6.1 HTML app shell/navigation elementleri eksik"
  exit 1
fi

echo "7. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/app-shell"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/app_shell.js"
CSS_FILE="$WEB_DIR/app_shell.css"
CONFIG_FILE="$CONFIG_DIR/app_shell_navigation_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_3_APP_SHELL_NAVIGATION_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-4.3 APP SHELL / NAVIGATION STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"app_shell"' "3.1 app_shell capability contract"
check_contains "$CONFIG_FILE" '"sidebar"' "3.2 sidebar capability contract"
check_contains "$CONFIG_FILE" '"topbar"' "3.3 topbar capability contract"
check_contains "$CONFIG_FILE" '"breadcrumb"' "3.4 breadcrumb capability contract"
check_contains "$CONFIG_FILE" '"tenant_indicator"' "3.5 tenant_indicator capability contract"
check_contains "$CONFIG_FILE" '"responsive_shell"' "3.6 responsive_shell capability contract"

check_contains "$HTML_FILE" 'pix2piAppShell' "4.1 app shell HTML"
check_contains "$HTML_FILE" 'pix2piSidebar' "4.2 sidebar HTML"
check_contains "$HTML_FILE" 'pix2piTopbar' "4.3 topbar HTML"
check_contains "$HTML_FILE" 'pix2piBreadcrumb' "4.4 breadcrumb HTML"
check_contains "$HTML_FILE" 'pix2piTenantIndicator' "4.5 tenant indicator HTML"
check_contains "$HTML_FILE" 'pix2piSidebarToggle' "4.6 mobile sidebar toggle HTML"

check_contains "$JS_FILE" 'renderSidebarNavigation' "5.1 sidebar navigation JS"
check_contains "$JS_FILE" 'renderBreadcrumb' "5.2 breadcrumb JS"
check_contains "$JS_FILE" 'renderTenantIndicator' "5.3 tenant indicator JS"
check_contains "$JS_FILE" 'toggleSidebar' "5.4 responsive sidebar JS"
check_contains "$JS_FILE" 'setActiveRoute' "5.5 route switch JS"
check_contains "$JS_FILE" 'bootstrapAppShellNavigation' "5.6 bootstrap JS"

check_contains "$CSS_FILE" 'pix2pi-app-shell' "6.1 app shell CSS"
check_contains "$CSS_FILE" 'pix2pi-sidebar' "6.2 sidebar CSS"
check_contains "$CSS_FILE" 'pix2pi-topbar' "6.3 topbar CSS"
check_contains "$CSS_FILE" 'pix2pi-breadcrumb' "6.4 breadcrumb CSS"
check_contains "$CSS_FILE" 'pix2pi-tenant-indicator' "6.5 tenant indicator CSS"
check_contains "$CSS_FILE" '@media' "6.6 responsive media CSS"

APP_SHELL_STATUS="PASS"
SIDEBAR_STATUS="PASS"
TOPBAR_STATUS="PASS"
BREADCRUMB_STATUS="PASS"
TENANT_INDICATOR_STATUS="PASS"
RESPONSIVE_SHELL_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  APP_SHELL_STATUS="FAIL"
  SIDEBAR_STATUS="FAIL"
  TOPBAR_STATUS="FAIL"
  BREADCRUMB_STATUS="FAIL"
  TENANT_INDICATOR_STATUS="FAIL"
  RESPONSIVE_SHELL_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.3 App Shell / Navigation Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- APP_SHELL_STATUS=$APP_SHELL_STATUS"
  echo "- SIDEBAR_STATUS=$SIDEBAR_STATUS"
  echo "- TOPBAR_STATUS=$TOPBAR_STATUS"
  echo "- BREADCRUMB_STATUS=$BREADCRUMB_STATUS"
  echo "- TENANT_INDICATOR_STATUS=$TENANT_INDICATOR_STATUS"
  echo "- RESPONSIVE_SHELL_STATUS=$RESPONSIVE_SHELL_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.3 APP SHELL / NAVIGATION STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "APP_SHELL_STATUS=$APP_SHELL_STATUS"
echo "SIDEBAR_STATUS=$SIDEBAR_STATUS"
echo "TOPBAR_STATUS=$TOPBAR_STATUS"
echo "BREADCRUMB_STATUS=$BREADCRUMB_STATUS"
echo "TENANT_INDICATOR_STATUS=$TENANT_INDICATOR_STATUS"
echo "RESPONSIVE_SHELL_STATUS=$RESPONSIVE_SHELL_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.3 APP SHELL / NAVIGATION STRICT SUITE END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_3_APP_SHELL_NAVIGATION_STRICT_SUITE_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_3_APP_SHELL_NAVIGATION_STRICT_SUITE_SEAL_STATUS")"

APP_SHELL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "APP_SHELL_STATUS")"
SIDEBAR_STATUS="$(extract_var "$STRICT_SUITE_OUT" "SIDEBAR_STATUS")"
TOPBAR_STATUS="$(extract_var "$STRICT_SUITE_OUT" "TOPBAR_STATUS")"
BREADCRUMB_STATUS="$(extract_var "$STRICT_SUITE_OUT" "BREADCRUMB_STATUS")"
TENANT_INDICATOR_STATUS="$(extract_var "$STRICT_SUITE_OUT" "TENANT_INDICATOR_STATUS")"
RESPONSIVE_SHELL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "RESPONSIVE_SHELL_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "8.2 strict suite FAIL_COUNT=0 doğrulandı" || fail "8.2 strict suite FAIL_COUNT sıfır değil"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "8.3 strict suite PASS doğrulandı" || fail "8.3 strict suite PASS değil"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "8.4 strict suite SEALED doğrulandı" || fail "8.4 strict suite SEALED değil"

echo "9. dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-4.3 — App Shell / Navigation İskeleti

## Kapsam

- App shell
- Sidebar
- Topbar
- Breadcrumb
- Tenant indicator
- Responsive shell

## Üretilen Dosyalar

- UI: web/faz1/ui-foundation/app-shell/index.html
- Runtime JS: web/faz1/ui-foundation/app-shell/app_shell.js
- CSS: web/faz1/ui-foundation/app-shell/app_shell.css
- Contract: configs/faz1/web/ui_foundation/app_shell_navigation_contract.v1.json
- Strict suite: scripts/web/faz_1_4_3_app_shell_navigation_strict_suite.sh

## Final Status

- APP_SHELL_STATUS=${APP_SHELL_STATUS:-N/A}
- SIDEBAR_STATUS=${SIDEBAR_STATUS:-N/A}
- TOPBAR_STATUS=${TOPBAR_STATUS:-N/A}
- BREADCRUMB_STATUS=${BREADCRUMB_STATUS:-N/A}
- TENANT_INDICATOR_STATUS=${TENANT_INDICATOR_STATUS:-N/A}
- RESPONSIVE_SHELL_STATUS=${RESPONSIVE_SHELL_STATUS:-N/A}
- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}
- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-4.3 App Shell / Navigation Real Implementation Audit"
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
  echo "- APP_SHELL_STATUS=${APP_SHELL_STATUS:-N/A}"
  echo "- SIDEBAR_STATUS=${SIDEBAR_STATUS:-N/A}"
  echo "- TOPBAR_STATUS=${TOPBAR_STATUS:-N/A}"
  echo "- BREADCRUMB_STATUS=${BREADCRUMB_STATUS:-N/A}"
  echo "- TENANT_INDICATOR_STATUS=${TENANT_INDICATOR_STATUS:-N/A}"
  echo "- RESPONSIVE_SHELL_STATUS=${RESPONSIVE_SHELL_STATUS:-N/A}"
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
  echo "# FAZ 1-4.3 App Shell / Navigation Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_4_3_APP_SHELL_STATUS=${APP_SHELL_STATUS:-N/A}"
  echo "FAZ_1_4_3_SIDEBAR_STATUS=${SIDEBAR_STATUS:-N/A}"
  echo "FAZ_1_4_3_TOPBAR_STATUS=${TOPBAR_STATUS:-N/A}"
  echo "FAZ_1_4_3_BREADCRUMB_STATUS=${BREADCRUMB_STATUS:-N/A}"
  echo "FAZ_1_4_3_TENANT_INDICATOR_STATUS=${TENANT_INDICATOR_STATUS:-N/A}"
  echo "FAZ_1_4_3_RESPONSIVE_SHELL_STATUS=${RESPONSIVE_SHELL_STATUS:-N/A}"
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_4_2_READY=YES"
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

echo "===== FAZ 1-4.3 APP SHELL / NAVIGATION RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "APP_SHELL_STATUS=${APP_SHELL_STATUS:-N/A}"
echo "SIDEBAR_STATUS=${SIDEBAR_STATUS:-N/A}"
echo "TOPBAR_STATUS=${TOPBAR_STATUS:-N/A}"
echo "BREADCRUMB_STATUS=${BREADCRUMB_STATUS:-N/A}"
echo "TENANT_INDICATOR_STATUS=${TENANT_INDICATOR_STATUS:-N/A}"
echo "RESPONSIVE_SHELL_STATUS=${RESPONSIVE_SHELL_STATUS:-N/A}"
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

  echo "FAZ_1_4_3_APP_SHELL_STATUS=PASS"
  echo "FAZ_1_4_3_SIDEBAR_STATUS=PASS"
  echo "FAZ_1_4_3_TOPBAR_STATUS=PASS"
  echo "FAZ_1_4_3_BREADCRUMB_STATUS=PASS"
  echo "FAZ_1_4_3_TENANT_INDICATOR_STATUS=PASS"
  echo "FAZ_1_4_3_RESPONSIVE_SHELL_STATUS=PASS"
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_FINAL_STATUS=PASS"
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_SEAL_STATUS=SEALED"
  echo "FAZ_1_4_2_READY=YES"
else
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_FINAL_STATUS=FAIL"
  echo "FAZ_1_4_3_APP_SHELL_NAVIGATION_SEAL_STATUS=OPEN"
  echo "FAZ_1_4_2_READY=NO"
  exit 1
fi

echo "===== FAZ 1-4.3 APP SHELL / NAVIGATION END ====="
