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
