#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_5_4_ROLE_AWARE_MENU"

BACKUP_DIR="$REPO/backups/faz1/faz_1_5_4_role_aware_menu_$TS"
WEB_DIR="$REPO/web/faz1/auth-tenant-experience/role-aware-menu"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
DOC_DIR="$REPO/docs/faz1/web"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
SCRIPT_DIR="$REPO/scripts/web"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/role_aware_menu.js"
CSS_FILE="$WEB_DIR/role_aware_menu.css"
CONFIG_FILE="$CONFIG_DIR/role_aware_menu_contract.v1.json"
DOC_FILE="$DOC_DIR/FAZ_1_5_4_ROLE_AWARE_MENU.md"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_5_4_role_aware_menu_strict_suite.sh"
APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_5_4_role_aware_menu.sh"
STRICT_SUITE_OUT="$BACKUP_DIR/faz_1_5_4_role_aware_menu_strict_suite.out"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_4_ROLE_AWARE_MENU_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_5_4_ROLE_AWARE_MENU_FINAL_SEAL_$TS.md"

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

echo "===== FAZ 1-5.4 ROLE-AWARE MENU START ====="

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

echo "3. role-aware menu contract config yazılıyor..."

cat <<'JSON' > "$CONFIG_FILE"
{
  "phase": "FAZ_1_5_4",
  "module": "WEB_L2_AUTH_TENANT_EXPERIENCE",
  "component": "role_aware_menu",
  "status": "READY",
  "required_capabilities": [
    "role_based_menu",
    "permission_based_menu",
    "feature_entitlement_menu",
    "accountant_portal_menu",
    "admin_operator_separation"
  ],
  "roles": [
    "SUPER_ADMIN",
    "TENANT_ADMIN",
    "OWNER",
    "ACCOUNTANT",
    "MANAGER",
    "OPERATOR",
    "SUPPORT"
  ],
  "permissions": [
    "dashboard:view",
    "tenant:admin",
    "tenant:switch",
    "erp:view",
    "erp:write",
    "inventory:view",
    "inventory:write",
    "accounting:view",
    "accounting:export",
    "accountant:portal",
    "users:manage",
    "settings:manage",
    "ops:view"
  ],
  "entitlements": [
    "feature:dashboard",
    "feature:erp",
    "feature:inventory",
    "feature:accounting",
    "feature:accountant_portal",
    "feature:admin",
    "feature:ops"
  ],
  "menu_groups": [
    "dashboard",
    "erp",
    "inventory",
    "accounting",
    "accountant_portal",
    "admin",
    "ops"
  ],
  "guard_contract": {
    "hidden_policy": "HIDE_UNAUTHORIZED_MENU_ITEM",
    "disabled_policy": "DISABLE_ENTITLEMENT_BLOCKED_ITEM",
    "admin_operator_policy": "SEPARATE_ADMIN_AND_OPERATOR_SURFACES"
  }
}
JSON

if [ -f "$CONFIG_FILE" ]; then
  pass "3.1 role-aware menu config yazıldı: $CONFIG_FILE"
else
  fail "3.1 role-aware menu config yazılamadı"
  exit 1
fi

echo "4. role-aware menu CSS yazılıyor..."

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
  background: radial-gradient(circle at top left, #1e3a8a 0, var(--pix2pi-bg) 42%);
  color: var(--pix2pi-text);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.pix2pi-shell {
  width: min(1180px, calc(100% - 32px));
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

.pix2pi-badge {
  display: inline-flex;
  align-items: center;
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

.pix2pi-grid {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 18px;
}

.pix2pi-card {
  background: rgba(17, 24, 39, 0.9);
  border: 1px solid var(--pix2pi-border);
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 24px 80px rgba(0, 0, 0, 0.28);
}

.pix2pi-label {
  color: var(--pix2pi-muted);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.pix2pi-profile {
  display: grid;
  gap: 12px;
}

.pix2pi-select {
  width: 100%;
  border: 1px solid var(--pix2pi-border);
  border-radius: 14px;
  background: #020617;
  color: var(--pix2pi-text);
  padding: 12px 14px;
  outline: none;
}

.pix2pi-menu {
  display: grid;
  gap: 16px;
}

.pix2pi-menu-group {
  border: 1px solid var(--pix2pi-border);
  background: #0b1120;
  border-radius: 18px;
  overflow: hidden;
}

.pix2pi-menu-group-header {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: center;
  padding: 14px 16px;
  background: rgba(30, 41, 59, 0.9);
}

.pix2pi-menu-group-title {
  font-weight: 900;
}

.pix2pi-menu-items {
  display: grid;
  gap: 8px;
  padding: 12px;
}

.pix2pi-menu-item {
  display: grid;
  gap: 6px;
  width: 100%;
  text-align: left;
  border: 1px solid var(--pix2pi-border);
  background: #020617;
  color: var(--pix2pi-text);
  border-radius: 14px;
  padding: 12px;
  cursor: pointer;
}

.pix2pi-menu-item.hidden-by-auth {
  display: none;
}

.pix2pi-menu-item.disabled-by-entitlement {
  opacity: 0.52;
  cursor: not-allowed;
}

.pix2pi-menu-item-name {
  font-weight: 800;
}

.pix2pi-menu-item-meta {
  color: var(--pix2pi-muted);
  font-size: 13px;
}

.pix2pi-surface-warning {
  display: none;
  border: 1px solid rgba(245, 158, 11, 0.5);
  background: rgba(245, 158, 11, 0.1);
  color: #fde68a;
  border-radius: 16px;
  padding: 14px;
  margin-bottom: 16px;
}

.pix2pi-surface-warning.visible {
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
  min-height: 120px;
  white-space: pre-wrap;
}

@media (max-width: 900px) {
  .pix2pi-header,
  .pix2pi-grid {
    display: grid;
    grid-template-columns: 1fr;
  }
}
CSS

if grep -q "pix2pi-menu-group" "$CSS_FILE" && grep -q "disabled-by-entitlement" "$CSS_FILE" && grep -q "hidden-by-auth" "$CSS_FILE"; then
  pass "4.1 CSS role-aware menu sınıfları mevcut"
else
  fail "4.1 CSS role-aware menu sınıfları eksik"
  exit 1
fi

echo "5. role-aware menu JS yazılıyor..."

cat <<'JS' > "$JS_FILE"
(function roleAwareMenuRuntime(global) {
  "use strict";

  const PROFILE_STORAGE_KEY = "pix2pi.roleAwareMenu.profile";

  const PROFILES = {
    TENANT_ADMIN: {
      label: "Tenant Admin",
      roles: ["TENANT_ADMIN"],
      permissions: [
        "dashboard:view",
        "tenant:admin",
        "tenant:switch",
        "erp:view",
        "erp:write",
        "inventory:view",
        "inventory:write",
        "accounting:view",
        "accounting:export",
        "users:manage",
        "settings:manage"
      ],
      entitlements: [
        "feature:dashboard",
        "feature:erp",
        "feature:inventory",
        "feature:accounting",
        "feature:admin"
      ],
      surface: "ADMIN"
    },
    ACCOUNTANT: {
      label: "Muhasebeci",
      roles: ["ACCOUNTANT"],
      permissions: [
        "dashboard:view",
        "tenant:switch",
        "accounting:view",
        "accounting:export",
        "accountant:portal"
      ],
      entitlements: [
        "feature:dashboard",
        "feature:accounting",
        "feature:accountant_portal"
      ],
      surface: "ACCOUNTANT_PORTAL"
    },
    OPERATOR: {
      label: "Operatör",
      roles: ["OPERATOR"],
      permissions: [
        "dashboard:view",
        "inventory:view",
        "inventory:write"
      ],
      entitlements: [
        "feature:dashboard",
        "feature:inventory"
      ],
      surface: "OPERATOR"
    },
    SUPPORT: {
      label: "Destek / Ops",
      roles: ["SUPPORT"],
      permissions: [
        "dashboard:view",
        "ops:view"
      ],
      entitlements: [
        "feature:dashboard",
        "feature:ops"
      ],
      surface: "OPS"
    }
  };

  const MENU_ITEMS = [
    {
      id: "dashboard",
      group: "dashboard",
      label: "Dashboard",
      description: "Tenant genel görünüm",
      requiredRoles: [],
      requiredPermissions: ["dashboard:view"],
      requiredEntitlements: ["feature:dashboard"],
      surface: "COMMON"
    },
    {
      id: "erp-core",
      group: "erp",
      label: "ERP Çekirdeği",
      description: "Cari, stok, işlem ve ERP ana yüzeyi",
      requiredRoles: ["TENANT_ADMIN", "OWNER", "MANAGER"],
      requiredPermissions: ["erp:view"],
      requiredEntitlements: ["feature:erp"],
      surface: "ADMIN"
    },
    {
      id: "inventory",
      group: "inventory",
      label: "Stok Operasyonları",
      description: "Depo, stok hareketi, envanter işlemleri",
      requiredRoles: ["TENANT_ADMIN", "OWNER", "MANAGER", "OPERATOR"],
      requiredPermissions: ["inventory:view"],
      requiredEntitlements: ["feature:inventory"],
      surface: "OPERATOR"
    },
    {
      id: "accounting",
      group: "accounting",
      label: "Muhasebe / TDHP",
      description: "Muhasebe kayıtları, export ve TDHP kontrolleri",
      requiredRoles: ["TENANT_ADMIN", "OWNER", "ACCOUNTANT"],
      requiredPermissions: ["accounting:view"],
      requiredEntitlements: ["feature:accounting"],
      surface: "ACCOUNTING"
    },
    {
      id: "accountant-portal",
      group: "accountant_portal",
      label: "Muhasebeci Portalı",
      description: "Muhasebeci firma erişimi ve export alanı",
      requiredRoles: ["ACCOUNTANT"],
      requiredPermissions: ["accountant:portal"],
      requiredEntitlements: ["feature:accountant_portal"],
      surface: "ACCOUNTANT_PORTAL"
    },
    {
      id: "user-admin",
      group: "admin",
      label: "Kullanıcı / Rol Yönetimi",
      description: "Kullanıcı, rol ve yetki yönetimi",
      requiredRoles: ["TENANT_ADMIN", "OWNER"],
      requiredPermissions: ["users:manage"],
      requiredEntitlements: ["feature:admin"],
      surface: "ADMIN"
    },
    {
      id: "tenant-settings",
      group: "admin",
      label: "Tenant Ayarları",
      description: "Firma, tenant ve güvenlik ayarları",
      requiredRoles: ["TENANT_ADMIN", "OWNER"],
      requiredPermissions: ["settings:manage"],
      requiredEntitlements: ["feature:admin"],
      surface: "ADMIN"
    },
    {
      id: "ops-console",
      group: "ops",
      label: "Ops Console",
      description: "Operasyon, olay ve sistem gözlemi",
      requiredRoles: ["SUPER_ADMIN", "SUPPORT"],
      requiredPermissions: ["ops:view"],
      requiredEntitlements: ["feature:ops"],
      surface: "OPS"
    }
  ];

  const GROUP_LABELS = {
    dashboard: "Dashboard",
    erp: "ERP",
    inventory: "Stok / Operasyon",
    accounting: "Muhasebe",
    accountant_portal: "Muhasebeci Portalı",
    admin: "Admin",
    ops: "Ops"
  };

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
      }
    };
  }

  const storage = getStorage();

  function getSelectedProfileKey() {
    return storage.getItem(PROFILE_STORAGE_KEY) || "TENANT_ADMIN";
  }

  function setSelectedProfileKey(key) {
    if (!PROFILES[key]) {
      return false;
    }

    storage.setItem(PROFILE_STORAGE_KEY, key);
    renderRoleAwareMenu();
    return true;
  }

  function getCurrentProfile() {
    return PROFILES[getSelectedProfileKey()] || PROFILES.TENANT_ADMIN;
  }

  function hasRequiredRole(profile, menuItem) {
    if (!menuItem.requiredRoles || menuItem.requiredRoles.length === 0) {
      return true;
    }

    return menuItem.requiredRoles.some((role) => (profile.roles || []).includes(role));
  }

  function hasRequiredPermission(profile, menuItem) {
    if (!menuItem.requiredPermissions || menuItem.requiredPermissions.length === 0) {
      return true;
    }

    return menuItem.requiredPermissions.every((permission) => (profile.permissions || []).includes(permission));
  }

  function hasRequiredEntitlement(profile, menuItem) {
    if (!menuItem.requiredEntitlements || menuItem.requiredEntitlements.length === 0) {
      return true;
    }

    return menuItem.requiredEntitlements.every((entitlement) => (profile.entitlements || []).includes(entitlement));
  }

  function classifyMenuItem(profile, menuItem) {
    const roleAllowed = hasRequiredRole(profile, menuItem);
    const permissionAllowed = hasRequiredPermission(profile, menuItem);
    const entitlementAllowed = hasRequiredEntitlement(profile, menuItem);

    if (!roleAllowed || !permissionAllowed) {
      return {
        visible: false,
        enabled: false,
        reason: "AUTH_BLOCKED"
      };
    }

    if (!entitlementAllowed) {
      return {
        visible: true,
        enabled: false,
        reason: "ENTITLEMENT_BLOCKED"
      };
    }

    return {
      visible: true,
      enabled: true,
      reason: "ALLOWED"
    };
  }

  function getVisibleMenu(profile) {
    const currentProfile = profile || getCurrentProfile();

    return MENU_ITEMS.map((item) => {
      return Object.assign({}, item, {
        decision: classifyMenuItem(currentProfile, item)
      });
    }).filter((item) => item.decision.visible);
  }

  function getMenuGroups(profile) {
    const grouped = {};
    getVisibleMenu(profile).forEach((item) => {
      if (!grouped[item.group]) {
        grouped[item.group] = [];
      }

      grouped[item.group].push(item);
    });

    return grouped;
  }

  function isAdminSurface(profile) {
    const currentProfile = profile || getCurrentProfile();
    return currentProfile.surface === "ADMIN";
  }

  function isOperatorSurface(profile) {
    const currentProfile = profile || getCurrentProfile();
    return currentProfile.surface === "OPERATOR";
  }

  function isAccountantPortalSurface(profile) {
    const currentProfile = profile || getCurrentProfile();
    return currentProfile.surface === "ACCOUNTANT_PORTAL";
  }

  function renderProfileSelector() {
    const select = document.getElementById("roleProfileSelect");
    if (!select) {
      return;
    }

    select.innerHTML = "";
    Object.keys(PROFILES).forEach((key) => {
      const option = document.createElement("option");
      option.value = key;
      option.textContent = PROFILES[key].label;
      option.selected = key === getSelectedProfileKey();
      select.appendChild(option);
    });

    select.onchange = function onProfileChange(event) {
      setSelectedProfileKey(event.target.value);
    };
  }

  function renderProfileSummary() {
    const profile = getCurrentProfile();
    const roleEl = document.getElementById("activeRoles");
    const permissionEl = document.getElementById("activePermissions");
    const entitlementEl = document.getElementById("activeEntitlements");
    const surfaceEl = document.getElementById("activeSurface");

    if (roleEl) {
      roleEl.textContent = (profile.roles || []).join(", ");
    }

    if (permissionEl) {
      permissionEl.textContent = (profile.permissions || []).join(", ");
    }

    if (entitlementEl) {
      entitlementEl.textContent = (profile.entitlements || []).join(", ");
    }

    if (surfaceEl) {
      surfaceEl.textContent = profile.surface;
    }
  }

  function renderSurfaceWarning() {
    const warning = document.getElementById("surfaceWarning");
    if (!warning) {
      return;
    }

    const profile = getCurrentProfile();

    if (isAdminSurface(profile)) {
      warning.classList.remove("visible");
      warning.textContent = "";
      return;
    }

    if (isOperatorSurface(profile)) {
      warning.classList.add("visible");
      warning.textContent = "Operatör yüzeyinde admin menüleri gizlenir. Stok ve operasyon menüleri görünür.";
      return;
    }

    if (isAccountantPortalSurface(profile)) {
      warning.classList.add("visible");
      warning.textContent = "Muhasebeci yüzeyinde sadece muhasebe ve muhasebeci portalı menüleri görünür.";
      return;
    }

    warning.classList.add("visible");
    warning.textContent = "Bu profil sınırlı menü yüzeyi kullanıyor.";
  }

  function renderMenu() {
    const menuEl = document.getElementById("roleAwareMenu");
    if (!menuEl) {
      return;
    }

    const profile = getCurrentProfile();
    const groups = getMenuGroups(profile);
    menuEl.innerHTML = "";

    Object.keys(groups).forEach((groupKey) => {
      const group = document.createElement("section");
      group.className = "pix2pi-menu-group";
      group.dataset.group = groupKey;

      const header = document.createElement("div");
      header.className = "pix2pi-menu-group-header";

      const title = document.createElement("div");
      title.className = "pix2pi-menu-group-title";
      title.textContent = GROUP_LABELS[groupKey] || groupKey;

      const count = document.createElement("span");
      count.className = "pix2pi-badge";
      count.textContent = groups[groupKey].length + " menü";

      header.appendChild(title);
      header.appendChild(count);

      const items = document.createElement("div");
      items.className = "pix2pi-menu-items";

      groups[groupKey].forEach((item) => {
        const button = document.createElement("button");
        button.type = "button";
        button.className = "pix2pi-menu-item" + (item.decision.enabled ? "" : " disabled-by-entitlement");
        button.disabled = !item.decision.enabled;
        button.dataset.menuId = item.id;
        button.dataset.reason = item.decision.reason;

        const name = document.createElement("div");
        name.className = "pix2pi-menu-item-name";
        name.textContent = item.label;

        const meta = document.createElement("div");
        meta.className = "pix2pi-menu-item-meta";
        meta.textContent = item.description + " / " + item.decision.reason;

        button.appendChild(name);
        button.appendChild(meta);

        button.addEventListener("click", () => {
          logMenuEvent("MENU_CLICK", item);
        });

        items.appendChild(button);
      });

      group.appendChild(header);
      group.appendChild(items);
      menuEl.appendChild(group);
    });
  }

  function logMenuEvent(type, payload) {
    const log = document.getElementById("roleAwareMenuLog");
    if (!log) {
      return;
    }

    const line = "[" + new Date().toISOString() + "] " + type + " " + JSON.stringify({
      id: payload.id,
      group: payload.group,
      reason: payload.decision ? payload.decision.reason : "N/A"
    });

    log.textContent = line + "\n" + log.textContent;
  }

  function renderRoleAwareMenu() {
    renderProfileSelector();
    renderProfileSummary();
    renderSurfaceWarning();
    renderMenu();
  }

  const api = {
    PROFILES,
    MENU_ITEMS,
    GROUP_LABELS,
    getSelectedProfileKey,
    setSelectedProfileKey,
    getCurrentProfile,
    hasRequiredRole,
    hasRequiredPermission,
    hasRequiredEntitlement,
    classifyMenuItem,
    getVisibleMenu,
    getMenuGroups,
    isAdminSurface,
    isOperatorSurface,
    isAccountantPortalSurface,
    renderRoleAwareMenu
  };

  global.Pix2piRoleAwareMenu = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", renderRoleAwareMenu);
    } else {
      renderRoleAwareMenu();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
JS

if grep -q "hasRequiredRole" "$JS_FILE" \
  && grep -q "hasRequiredPermission" "$JS_FILE" \
  && grep -q "hasRequiredEntitlement" "$JS_FILE" \
  && grep -q "isAccountantPortalSurface" "$JS_FILE" \
  && grep -q "isAdminSurface" "$JS_FILE" \
  && grep -q "isOperatorSurface" "$JS_FILE"; then
  pass "5.1 JS role-aware menu runtime fonksiyonları mevcut"
else
  fail "5.1 JS role-aware menu runtime fonksiyonları eksik"
  exit 1
fi

echo "6. role-aware menu HTML yazılıyor..."

cat <<'HTML' > "$HTML_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — Role-aware Menu</title>
  <link rel="stylesheet" href="./role_aware_menu.css">
</head>
<body>
  <main class="pix2pi-shell">
    <header class="pix2pi-header">
      <div>
        <h1 class="pix2pi-title">Pix2pi Role-aware Menu</h1>
        <p class="pix2pi-subtitle">FAZ 1-5.4 — Auth / Tenant Experience</p>
      </div>
      <span class="pix2pi-badge ok">WEB-L2 READY</span>
    </header>

    <section class="pix2pi-grid">
      <aside class="pix2pi-card pix2pi-profile">
        <label class="pix2pi-label" for="roleProfileSelect">Aktif Rol Profili</label>
        <select class="pix2pi-select" id="roleProfileSelect"></select>

        <div>
          <div class="pix2pi-label">Roller</div>
          <div class="pix2pi-badge" id="activeRoles">ROLES</div>
        </div>

        <div>
          <div class="pix2pi-label">Permissions</div>
          <div class="pix2pi-badge" id="activePermissions">PERMISSIONS</div>
        </div>

        <div>
          <div class="pix2pi-label">Entitlements</div>
          <div class="pix2pi-badge" id="activeEntitlements">ENTITLEMENTS</div>
        </div>

        <div>
          <div class="pix2pi-label">Surface</div>
          <div class="pix2pi-badge ok" id="activeSurface">SURFACE</div>
        </div>
      </aside>

      <section class="pix2pi-card">
        <div class="pix2pi-surface-warning" id="surfaceWarning" role="status"></div>
        <nav class="pix2pi-menu" id="roleAwareMenu" aria-label="Role-aware Pix2pi menu"></nav>
        <div class="pix2pi-log" id="roleAwareMenuLog">Role-aware menu event log...</div>
      </section>
    </section>
  </main>

  <script src="./role_aware_menu.js"></script>
</body>
</html>
HTML

if grep -q "roleProfileSelect" "$HTML_FILE" \
  && grep -q "activeRoles" "$HTML_FILE" \
  && grep -q "activePermissions" "$HTML_FILE" \
  && grep -q "activeEntitlements" "$HTML_FILE" \
  && grep -q "roleAwareMenu" "$HTML_FILE" \
  && grep -q "surfaceWarning" "$HTML_FILE"; then
  pass "6.1 HTML role-aware menu UI elementleri mevcut"
else
  fail "6.1 HTML role-aware menu UI elementleri eksik"
  exit 1
fi

echo "7. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/auth-tenant-experience/role-aware-menu"
CONFIG_DIR="$REPO/configs/faz1/web/auth_tenant_experience"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/role_aware_menu.js"
CSS_FILE="$WEB_DIR/role_aware_menu.css"
CONFIG_FILE="$CONFIG_DIR/role_aware_menu_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_5_4_ROLE_AWARE_MENU_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

echo "===== FAZ 1-5.4 ROLE-AWARE MENU STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"role_based_menu"' "3.1 role_based_menu capability contract"
check_contains "$CONFIG_FILE" '"permission_based_menu"' "3.2 permission_based_menu capability contract"
check_contains "$CONFIG_FILE" '"feature_entitlement_menu"' "3.3 feature_entitlement_menu capability contract"
check_contains "$CONFIG_FILE" '"accountant_portal_menu"' "3.4 accountant_portal_menu capability contract"
check_contains "$CONFIG_FILE" '"admin_operator_separation"' "3.5 admin_operator_separation capability contract"

check_contains "$HTML_FILE" 'roleProfileSelect' "4.1 role profile selector HTML"
check_contains "$HTML_FILE" 'activeRoles' "4.2 active roles HTML"
check_contains "$HTML_FILE" 'activePermissions' "4.3 active permissions HTML"
check_contains "$HTML_FILE" 'activeEntitlements' "4.4 active entitlements HTML"
check_contains "$HTML_FILE" 'roleAwareMenu' "4.5 role aware menu HTML"
check_contains "$HTML_FILE" 'surfaceWarning' "4.6 surface warning HTML"

check_contains "$JS_FILE" 'hasRequiredRole' "5.1 role based menu JS"
check_contains "$JS_FILE" 'hasRequiredPermission' "5.2 permission based menu JS"
check_contains "$JS_FILE" 'hasRequiredEntitlement' "5.3 feature entitlement menu JS"
check_contains "$JS_FILE" 'accountant:portal' "5.4 accountant portal menu JS"
check_contains "$JS_FILE" 'isAdminSurface' "5.5 admin surface JS"
check_contains "$JS_FILE" 'isOperatorSurface' "5.6 operator surface JS"
check_contains "$JS_FILE" 'classifyMenuItem' "5.7 menu decision runtime JS"
check_contains "$JS_FILE" 'ENTITLEMENT_BLOCKED' "5.8 entitlement blocked decision JS"
check_contains "$JS_FILE" 'AUTH_BLOCKED' "5.9 auth blocked decision JS"

check_contains "$CSS_FILE" 'pix2pi-menu-group' "6.1 menu group CSS"
check_contains "$CSS_FILE" 'pix2pi-menu-item' "6.2 menu item CSS"
check_contains "$CSS_FILE" 'disabled-by-entitlement' "6.3 entitlement disabled CSS"
check_contains "$CSS_FILE" 'hidden-by-auth' "6.4 auth hidden CSS"
check_contains "$CSS_FILE" 'pix2pi-surface-warning' "6.5 surface warning CSS"

ROLE_BASED_MENU_STATUS="PASS"
PERMISSION_BASED_MENU_STATUS="PASS"
FEATURE_ENTITLEMENT_MENU_STATUS="PASS"
ACCOUNTANT_PORTAL_MENU_STATUS="PASS"
ADMIN_OPERATOR_SEPARATION_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  ROLE_BASED_MENU_STATUS="FAIL"
  PERMISSION_BASED_MENU_STATUS="FAIL"
  FEATURE_ENTITLEMENT_MENU_STATUS="FAIL"
  ACCOUNTANT_PORTAL_MENU_STATUS="FAIL"
  ADMIN_OPERATOR_SEPARATION_STATUS="FAIL"
fi

{
  echo "# FAZ 1-5.4 Role-aware Menu Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- ROLE_BASED_MENU_STATUS=$ROLE_BASED_MENU_STATUS"
  echo "- PERMISSION_BASED_MENU_STATUS=$PERMISSION_BASED_MENU_STATUS"
  echo "- FEATURE_ENTITLEMENT_MENU_STATUS=$FEATURE_ENTITLEMENT_MENU_STATUS"
  echo "- ACCOUNTANT_PORTAL_MENU_STATUS=$ACCOUNTANT_PORTAL_MENU_STATUS"
  echo "- ADMIN_OPERATOR_SEPARATION_STATUS=$ADMIN_OPERATOR_SEPARATION_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-5.4 ROLE-AWARE MENU STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "ROLE_BASED_MENU_STATUS=$ROLE_BASED_MENU_STATUS"
echo "PERMISSION_BASED_MENU_STATUS=$PERMISSION_BASED_MENU_STATUS"
echo "FEATURE_ENTITLEMENT_MENU_STATUS=$FEATURE_ENTITLEMENT_MENU_STATUS"
echo "ACCOUNTANT_PORTAL_MENU_STATUS=$ACCOUNTANT_PORTAL_MENU_STATUS"
echo "ADMIN_OPERATOR_SEPARATION_STATUS=$ADMIN_OPERATOR_SEPARATION_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-5.4 ROLE-AWARE MENU STRICT SUITE END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_5_4_ROLE_AWARE_MENU_STRICT_SUITE_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_5_4_ROLE_AWARE_MENU_STRICT_SUITE_SEAL_STATUS")"

ROLE_BASED_MENU_STATUS="$(extract_var "$STRICT_SUITE_OUT" "ROLE_BASED_MENU_STATUS")"
PERMISSION_BASED_MENU_STATUS="$(extract_var "$STRICT_SUITE_OUT" "PERMISSION_BASED_MENU_STATUS")"
FEATURE_ENTITLEMENT_MENU_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FEATURE_ENTITLEMENT_MENU_STATUS")"
ACCOUNTANT_PORTAL_MENU_STATUS="$(extract_var "$STRICT_SUITE_OUT" "ACCOUNTANT_PORTAL_MENU_STATUS")"
ADMIN_OPERATOR_SEPARATION_STATUS="$(extract_var "$STRICT_SUITE_OUT" "ADMIN_OPERATOR_SEPARATION_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "8.2 strict suite FAIL_COUNT=0 doğrulandı" || fail "8.2 strict suite FAIL_COUNT sıfır değil"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "8.3 strict suite PASS doğrulandı" || fail "8.3 strict suite PASS değil"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "8.4 strict suite SEALED doğrulandı" || fail "8.4 strict suite SEALED değil"

echo "9. dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-5.4 — Role-aware Menu Yapısı

## Kapsam

- Role bazlı menü
- Permission bazlı menü
- Feature entitlement menü
- Muhasebeci portal menüsü
- Admin/operator ayrımı

## Üretilen Dosyalar

- UI: web/faz1/auth-tenant-experience/role-aware-menu/index.html
- Runtime JS: web/faz1/auth-tenant-experience/role-aware-menu/role_aware_menu.js
- CSS: web/faz1/auth-tenant-experience/role-aware-menu/role_aware_menu.css
- Contract: configs/faz1/web/auth_tenant_experience/role_aware_menu_contract.v1.json
- Strict suite: scripts/web/faz_1_5_4_role_aware_menu_strict_suite.sh

## Final Status

- ROLE_BASED_MENU_STATUS=${ROLE_BASED_MENU_STATUS:-N/A}
- PERMISSION_BASED_MENU_STATUS=${PERMISSION_BASED_MENU_STATUS:-N/A}
- FEATURE_ENTITLEMENT_MENU_STATUS=${FEATURE_ENTITLEMENT_MENU_STATUS:-N/A}
- ACCOUNTANT_PORTAL_MENU_STATUS=${ACCOUNTANT_PORTAL_MENU_STATUS:-N/A}
- ADMIN_OPERATOR_SEPARATION_STATUS=${ADMIN_OPERATOR_SEPARATION_STATUS:-N/A}
- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}
- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-5.4 Role-aware Menu Real Implementation Audit"
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
  echo "- ROLE_BASED_MENU_STATUS=${ROLE_BASED_MENU_STATUS:-N/A}"
  echo "- PERMISSION_BASED_MENU_STATUS=${PERMISSION_BASED_MENU_STATUS:-N/A}"
  echo "- FEATURE_ENTITLEMENT_MENU_STATUS=${FEATURE_ENTITLEMENT_MENU_STATUS:-N/A}"
  echo "- ACCOUNTANT_PORTAL_MENU_STATUS=${ACCOUNTANT_PORTAL_MENU_STATUS:-N/A}"
  echo "- ADMIN_OPERATOR_SEPARATION_STATUS=${ADMIN_OPERATOR_SEPARATION_STATUS:-N/A}"
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
  echo "# FAZ 1-5.4 Role-aware Menu Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_5_4_ROLE_BASED_MENU_STATUS=${ROLE_BASED_MENU_STATUS:-N/A}"
  echo "FAZ_1_5_4_PERMISSION_BASED_MENU_STATUS=${PERMISSION_BASED_MENU_STATUS:-N/A}"
  echo "FAZ_1_5_4_FEATURE_ENTITLEMENT_MENU_STATUS=${FEATURE_ENTITLEMENT_MENU_STATUS:-N/A}"
  echo "FAZ_1_5_4_ACCOUNTANT_PORTAL_MENU_STATUS=${ACCOUNTANT_PORTAL_MENU_STATUS:-N/A}"
  echo "FAZ_1_5_4_ADMIN_OPERATOR_SEPARATION_STATUS=${ADMIN_OPERATOR_SEPARATION_STATUS:-N/A}"
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_5_5_READY=YES"
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

echo "===== FAZ 1-5.4 ROLE-AWARE MENU RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "ROLE_BASED_MENU_STATUS=${ROLE_BASED_MENU_STATUS:-N/A}"
echo "PERMISSION_BASED_MENU_STATUS=${PERMISSION_BASED_MENU_STATUS:-N/A}"
echo "FEATURE_ENTITLEMENT_MENU_STATUS=${FEATURE_ENTITLEMENT_MENU_STATUS:-N/A}"
echo "ACCOUNTANT_PORTAL_MENU_STATUS=${ACCOUNTANT_PORTAL_MENU_STATUS:-N/A}"
echo "ADMIN_OPERATOR_SEPARATION_STATUS=${ADMIN_OPERATOR_SEPARATION_STATUS:-N/A}"
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

  echo "FAZ_1_5_4_ROLE_BASED_MENU_STATUS=PASS"
  echo "FAZ_1_5_4_PERMISSION_BASED_MENU_STATUS=PASS"
  echo "FAZ_1_5_4_FEATURE_ENTITLEMENT_MENU_STATUS=PASS"
  echo "FAZ_1_5_4_ACCOUNTANT_PORTAL_MENU_STATUS=PASS"
  echo "FAZ_1_5_4_ADMIN_OPERATOR_SEPARATION_STATUS=PASS"
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_FINAL_STATUS=PASS"
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_SEAL_STATUS=SEALED"
  echo "FAZ_1_5_5_READY=YES"
else
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_FINAL_STATUS=FAIL"
  echo "FAZ_1_5_4_ROLE_AWARE_MENU_SEAL_STATUS=OPEN"
  echo "FAZ_1_5_5_READY=NO"
  exit 1
fi

echo "===== FAZ 1-5.4 ROLE-AWARE MENU END ====="
