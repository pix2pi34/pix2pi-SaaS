/* PIX2PI_339_MARKET_SELLER_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "market_seller",
    phase: "FAZ_7R",
    step: "339",
    sellerDashboardEndpoint: "/api/market/seller/dashboard",
    sellerOrdersEndpoint: "/api/market/seller/orders",
    sellerStoreEndpoint: "/api/market/seller/store",
    selectedTenantKey: "pix2pi.market.tenant.preference",
    storeSlugKey: "pix2pi.market.store.slug",
    sellerSessionKey: "pix2pi.market.seller.session",
    runtimeContract: {
      realOrderActionEnabled: false,
      realStockUpdateEnabled: false,
      realCampaignPublishEnabled: false,
      realDeliveryOpsEnabled: false,
      sellerDashboardEnabled: true,
      fallbackSellerSnapshotEnabled: true,
      readyForStep340: true
    },
    fallbackSellerSnapshot: {
      tenant_id: "controlled-pilot",
      store_slug: "demo-market",
      seller_session_id: "SELLER_DEMO_SESSION",
      seller_role: "STORE_MANAGER",
      store_profile: {
        business_name: "Demo Market",
        status: "OPEN",
        working_hours: "09:00 - 22:00",
        delivery_enabled: true,
        pickup_enabled: true,
        storefront_url: "/storefront/?store=demo-market",
        products_url: "/products/?store=demo-market"
      },
      kpis: {
        today_order_count: 12,
        pending_order_count: 3,
        visible_product_count: 48,
        low_stock_count: 5,
        campaign_count: 2,
        rating: 4.8
      },
      orders: [
        {
          id: "ord-demo-001",
          customer_label: "Anonim müşteri",
          status: "DRAFT",
          fulfillment_mode: "DELIVERY",
          total: 120,
          currency: "TRY",
          created_at: "demo"
        },
        {
          id: "ord-demo-002",
          customer_label: "Anonim müşteri",
          status: "PAYMENT_PENDING_DISABLED",
          fulfillment_mode: "PICKUP",
          total: 85,
          currency: "TRY",
          created_at: "demo"
        }
      ],
      alerts: [
        { level: "INFO", title: "Satıcı yönetim yüzeyi hazır", description: "Gerçek operasyon aksiyonları kapalı gate altındadır." },
        { level: "WARN", title: "5 düşük stok ürünü", description: "Stok güncelleme gerçek endpoint 340 sonrası planlanacak." }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSellerSnapshot.tenant_id;
  }

  function getStoreSlug() {
    const params = new URLSearchParams(window.location.search);
    return params.get("store") || window.localStorage.getItem(CONFIG.storeSlugKey) || CONFIG.fallbackSellerSnapshot.store_slug;
  }

  function getSellerSession() {
    const raw = window.localStorage.getItem(CONFIG.sellerSessionKey);
    if (!raw) {
      return {
        session_present: false,
        session_id: CONFIG.fallbackSellerSnapshot.seller_session_id,
        role: CONFIG.fallbackSellerSnapshot.seller_role
      };
    }

    try {
      return Object.assign({
        session_present: true
      }, JSON.parse(raw));
    } catch (_error) {
      return {
        session_present: false,
        session_id: "INVALID_SELLER_SESSION",
        role: "UNKNOWN"
      };
    }
  }

  function sellerScopeHeaders() {
    const session = getSellerSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Store-Slug": getStoreSlug(),
      "X-Market-Seller-Session": session.session_id,
      "X-Pix2pi-Surface": "marketplace_seller",
      "X-Pix2pi-Step": "339"
    };
  }

  function moneyTRY(value) {
    try {
      return new Intl.NumberFormat("tr-TR", {
        style: "currency",
        currency: "TRY"
      }).format(Number(value || 0));
    } catch (_error) {
      return String(value || 0) + " TL";
    }
  }

  function validateSellerScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!snapshot || !snapshot.store_slug) {
      errors.push({ field: "store_slug", code: "STORE_SLUG_REQUIRED" });
    }

    if (!snapshot || !snapshot.seller_session_id) {
      errors.push({ field: "seller_session_id", code: "SELLER_SESSION_REQUIRED" });
    }

    if (!snapshot || !snapshot.seller_role) {
      errors.push({ field: "seller_role", code: "SELLER_ROLE_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: sellerScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("MARKET_SELLER_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchSellerDashboardSnapshot() {
    const slug = getStoreSlug();

    try {
      return await apiJson(CONFIG.sellerDashboardEndpoint + "?store=" + encodeURIComponent(slug));
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSellerSnapshot));
      const session = getSellerSession();
      snapshot.tenant_id = getTenantId();
      snapshot.store_slug = slug;
      snapshot.seller_session_id = session.session_id;
      snapshot.seller_role = session.role || snapshot.seller_role;
      snapshot.store_profile.storefront_url = "/storefront/?store=" + encodeURIComponent(slug);
      snapshot.store_profile.products_url = "/products/?store=" + encodeURIComponent(slug);
      return snapshot;
    }
  }

  function buildSellerRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      store_slug: snapshot.store_slug,
      seller_session_id: snapshot.seller_session_id,
      seller_role: snapshot.seller_role,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateSellerScope(snapshot),
      disabled_actions: [
        "ACCEPT_ORDER",
        "REJECT_ORDER",
        "MARK_PREPARING",
        "UPDATE_STOCK",
        "PUBLISH_CAMPAIGN",
        "UPDATE_DELIVERY_STATUS"
      ],
      source: {
        surface: "market_seller",
        phase: "FAZ_7R",
        step: "339"
      }
    };
  }

  function buildDisabledSellerAction(action, payload) {
    return {
      action: action,
      accepted: false,
      reason: "SELLER_REAL_OPERATION_DISABLED_IN_STEP_339",
      real_order_action_enabled: CONFIG.runtimeContract.realOrderActionEnabled,
      real_stock_update_enabled: CONFIG.runtimeContract.realStockUpdateEnabled,
      real_campaign_publish_enabled: CONFIG.runtimeContract.realCampaignPublishEnabled,
      payload: payload || null,
      source: {
        surface: "market_seller",
        phase: "FAZ_7R",
        step: "339"
      }
    };
  }

  function renderSellerContext(snapshot) {
    const tenant = document.getElementById("seller-tenant");
    const store = document.getElementById("seller-store-slug");
    const session = document.getElementById("seller-session");
    const role = document.getElementById("seller-role");
    const validation = document.getElementById("seller-scope-validation");
    const contract = buildSellerRuntimeContract(snapshot);

    if (tenant) tenant.textContent = contract.tenant_id;
    if (store) store.textContent = contract.store_slug;
    if (session) session.textContent = snapshot.seller_session_id;
    if (role) role.textContent = snapshot.seller_role;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderStoreProfile(snapshot) {
    const name = document.getElementById("seller-store-name");
    const status = document.getElementById("seller-store-status");
    const hours = document.getElementById("seller-working-hours");
    const storefront = document.getElementById("seller-storefront-link");
    const products = document.getElementById("seller-products-link");

    if (name) name.textContent = snapshot.store_profile.business_name;
    if (status) status.textContent = snapshot.store_profile.status;
    if (hours) hours.textContent = snapshot.store_profile.working_hours;
    if (storefront) storefront.setAttribute("href", snapshot.store_profile.storefront_url);
    if (products) products.setAttribute("href", snapshot.store_profile.products_url);
  }

  function renderKPIs(snapshot) {
    const map = {
      "seller-kpi-today-orders": snapshot.kpis.today_order_count,
      "seller-kpi-pending-orders": snapshot.kpis.pending_order_count,
      "seller-kpi-products": snapshot.kpis.visible_product_count,
      "seller-kpi-low-stock": snapshot.kpis.low_stock_count,
      "seller-kpi-campaigns": snapshot.kpis.campaign_count,
      "seller-kpi-rating": snapshot.kpis.rating
    };

    Object.keys(map).forEach(function (id) {
      const el = document.getElementById(id);
      if (el) el.textContent = String(map[id]);
    });
  }

  function renderOrderPreview(snapshot) {
    const target = document.getElementById("seller-order-preview");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.orders || []).forEach(function (order) {
      const row = document.createElement("article");
      row.className = "seller-order-row";
      row.setAttribute("data-order-id", order.id);
      row.setAttribute("data-order-status", order.status);
      row.innerHTML = [
        "<div>",
        "<strong>" + order.id + "</strong>",
        "<p>" + order.customer_label + " / " + order.fulfillment_mode + " / " + order.status + "</p>",
        "</div>",
        "<em>" + moneyTRY(order.total) + "</em>",
        "<button type='button' disabled>Operasyon aksiyonu kapalı</button>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAlerts(snapshot) {
    const target = document.getElementById("seller-alert-panel");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.alerts || []).forEach(function (alert) {
      const item = document.createElement("article");
      item.className = "seller-alert";
      item.setAttribute("data-alert-level", alert.level);
      item.innerHTML = [
        "<strong>" + alert.level + " — " + alert.title + "</strong>",
        "<p>" + alert.description + "</p>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("seller-runtime-contract");
    if (!target) return;

    const contract = buildSellerRuntimeContract(snapshot);

    target.textContent = [
      "real_order_action_enabled=" + CONFIG.runtimeContract.realOrderActionEnabled,
      "real_stock_update_enabled=" + CONFIG.runtimeContract.realStockUpdateEnabled,
      "real_campaign_publish_enabled=" + CONFIG.runtimeContract.realCampaignPublishEnabled,
      "real_delivery_ops_enabled=" + CONFIG.runtimeContract.realDeliveryOpsEnabled,
      "ready_for_step_340=" + CONFIG.runtimeContract.readyForStep340,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderSellerScreen(snapshot) {
    renderSellerContext(snapshot);
    renderStoreProfile(snapshot);
    renderKPIs(snapshot);
    renderOrderPreview(snapshot);
    renderAlerts(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-market-seller-rendered", "true");
  }

  async function bootSellerScreen() {
    const snapshot = await fetchSellerDashboardSnapshot();
    renderSellerScreen(snapshot);
    return buildSellerRuntimeContract(snapshot);
  }

  window.Pix2piMarketSeller = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getStoreSlug: getStoreSlug,
    getSellerSession: getSellerSession,
    sellerScopeHeaders: sellerScopeHeaders,
    validateSellerScope: validateSellerScope,
    fetchSellerDashboardSnapshot: fetchSellerDashboardSnapshot,
    buildSellerRuntimeContract: buildSellerRuntimeContract,
    buildDisabledSellerAction: buildDisabledSellerAction,
    renderSellerContext: renderSellerContext,
    renderStoreProfile: renderStoreProfile,
    renderKPIs: renderKPIs,
    renderOrderPreview: renderOrderPreview,
    renderAlerts: renderAlerts,
    renderRuntimeContract: renderRuntimeContract,
    renderSellerScreen: renderSellerScreen,
    bootSellerScreen: bootSellerScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_339_MARKET_SELLER_RUNTIME_END */
