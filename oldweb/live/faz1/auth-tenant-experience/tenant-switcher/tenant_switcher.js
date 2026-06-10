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
