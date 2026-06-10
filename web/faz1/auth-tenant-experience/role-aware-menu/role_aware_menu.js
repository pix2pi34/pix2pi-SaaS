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
