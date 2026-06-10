/* PIX2PI_340_MARKET_SHOP_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "market_shop",
    phase: "FAZ_7R",
    step: "340",
    shoppingHomeEndpoint: "/api/market/shop/home",
    basketPreviewEndpoint: "/api/market/shop/basket-preview",
    customerSessionEndpoint: "/api/market/customer/session",
    customerSessionKey: "pix2pi.market.customer.session",
    regionKey: "pix2pi.market.region.preference",
    basketPreviewKey: "pix2pi.market.basket.preview",
    fulfillmentPreferenceKey: "pix2pi.market.fulfillment.preference",
    runtimeContract: {
      realCustomerLoginEnabled: false,
      realBasketMutationEnabled: false,
      realOrderSubmitEnabled: false,
      realPaymentHandoffEnabled: false,
      realStockReservationEnabled: false,
      shoppingHomeEnabled: true,
      fallbackShoppingSnapshotEnabled: true,
      readyForStep341: true
    },
    fallbackSnapshot: {
      customer: {
        session_id: "ANONYMOUS_DEMO_SESSION",
        session_present: false,
        label: "Anonim müşteri"
      },
      region: {
        city: "İstanbul",
        district: "Pilot",
        neighborhood: "Demo Mahalle",
        region_code: "TR-34-PILOT"
      },
      recommended_stores: [
        {
          store_slug: "demo-market",
          name: "Demo Market",
          category: "Market",
          status: "OPEN",
          distance_km: 0.4,
          storefront_url: "/storefront/?store=demo-market",
          products_url: "/products/?store=demo-market"
        },
        {
          store_slug: "demo-firin",
          name: "Demo Fırın",
          category: "Fırın",
          status: "OPEN",
          distance_km: 0.7,
          storefront_url: "/storefront/?store=demo-firin",
          products_url: "/products/?store=demo-firin"
        }
      ],
      recommended_products: [
        {
          product_id: "mkt-prd-001",
          name: "Demo Süt 1L",
          store_slug: "demo-market",
          price: 35,
          currency: "TRY",
          image_placeholder: "🥛"
        },
        {
          product_id: "mkt-prd-002",
          name: "Demo Ekmek",
          store_slug: "demo-market",
          price: 10,
          currency: "TRY",
          image_placeholder: "🥖"
        },
        {
          product_id: "mkt-prd-003",
          name: "Demo Peynir",
          store_slug: "demo-market",
          price: 95,
          currency: "TRY",
          image_placeholder: "🧀"
        }
      ],
      basket_preview: {
        line_count: 2,
        item_count: 5,
        subtotal: 100,
        vat_total: 7.3,
        delivery_fee: 20,
        grand_total: 127.3,
        currency: "TRY",
        store_slug: "demo-market"
      },
      campaigns: [
        {
          id: "shop-campaign-001",
          title: "Mahalle vitrini hazır",
          description: "Pilot mağazalardan ürün keşfi ve sipariş taslak akışı."
        }
      ]
    }
  };

  function getCustomerSession() {
    const raw = window.localStorage.getItem(CONFIG.customerSessionKey);
    if (!raw) return CONFIG.fallbackSnapshot.customer;

    try {
      return Object.assign({}, CONFIG.fallbackSnapshot.customer, JSON.parse(raw), {
        session_present: true
      });
    } catch (_error) {
      return {
        session_id: "INVALID_CUSTOMER_SESSION",
        session_present: false,
        label: "Geçersiz session"
      };
    }
  }

  function getRegionContext() {
    const raw = window.localStorage.getItem(CONFIG.regionKey);
    if (!raw) return CONFIG.fallbackSnapshot.region;

    try {
      return Object.assign({}, CONFIG.fallbackSnapshot.region, JSON.parse(raw));
    } catch (_error) {
      return CONFIG.fallbackSnapshot.region;
    }
  }

  function getFulfillmentPreference() {
    return window.localStorage.getItem(CONFIG.fulfillmentPreferenceKey) || "DELIVERY";
  }

  function setFulfillmentPreference(value) {
    const nextValue = value === "PICKUP" ? "PICKUP" : "DELIVERY";
    window.localStorage.setItem(CONFIG.fulfillmentPreferenceKey, nextValue);
    return nextValue;
  }

  function shoppingScopeHeaders() {
    const customer = getCustomerSession();
    const region = getRegionContext();

    return {
      "Content-Type": "application/json",
      "X-Market-Region": region.region_code,
      "X-Market-Customer-Session": customer.session_id,
      "X-Pix2pi-Surface": "marketplace_customer",
      "X-Pix2pi-Step": "340"
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

  function validateShoppingScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.customer || !snapshot.customer.session_id) {
      errors.push({ field: "customer.session_id", code: "CUSTOMER_SESSION_REQUIRED" });
    }

    if (!snapshot || !snapshot.region || !snapshot.region.region_code) {
      errors.push({ field: "region.region_code", code: "REGION_REQUIRED" });
    }

    if (!snapshot || !snapshot.basket_preview || !snapshot.basket_preview.store_slug) {
      errors.push({ field: "basket_preview.store_slug", code: "BASKET_STORE_SCOPE_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: shoppingScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("MARKET_SHOP_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchShoppingSnapshot() {
    try {
      return await apiJson(CONFIG.shoppingHomeEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      snapshot.customer = getCustomerSession();
      snapshot.region = getRegionContext();
      return snapshot;
    }
  }

  function loadBasketPreview() {
    const raw = window.localStorage.getItem(CONFIG.basketPreviewKey);
    if (!raw) return CONFIG.fallbackSnapshot.basket_preview;

    try {
      return Object.assign({}, CONFIG.fallbackSnapshot.basket_preview, JSON.parse(raw));
    } catch (_error) {
      return CONFIG.fallbackSnapshot.basket_preview;
    }
  }

  function buildShoppingRuntimeContract(snapshot) {
    return {
      customer_session_id: snapshot.customer.session_id,
      customer_session_present: snapshot.customer.session_present,
      region_code: snapshot.region.region_code,
      fulfillment_preference: getFulfillmentPreference(),
      recommended_store_count: Array.isArray(snapshot.recommended_stores) ? snapshot.recommended_stores.length : 0,
      recommended_product_count: Array.isArray(snapshot.recommended_products) ? snapshot.recommended_products.length : 0,
      basket_preview: snapshot.basket_preview,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateShoppingScope(snapshot),
      disabled_actions: [
        "CUSTOMER_LOGIN",
        "ADD_TO_BASKET",
        "ORDER_SUBMIT",
        "PAYMENT_HANDOFF",
        "STOCK_RESERVATION"
      ],
      source: {
        surface: "market_shop",
        phase: "FAZ_7R",
        step: "340"
      }
    };
  }

  function buildDisabledShoppingAction(action, payload) {
    return {
      action: action,
      accepted: false,
      reason: "CUSTOMER_SHOPPING_REAL_ACTION_DISABLED_IN_STEP_340",
      real_customer_login_enabled: CONFIG.runtimeContract.realCustomerLoginEnabled,
      real_basket_mutation_enabled: CONFIG.runtimeContract.realBasketMutationEnabled,
      real_order_submit_enabled: CONFIG.runtimeContract.realOrderSubmitEnabled,
      real_payment_handoff_enabled: CONFIG.runtimeContract.realPaymentHandoffEnabled,
      real_stock_reservation_enabled: CONFIG.runtimeContract.realStockReservationEnabled,
      payload: payload || null,
      source: {
        surface: "market_shop",
        phase: "FAZ_7R",
        step: "340"
      }
    };
  }

  function renderCustomerContext(snapshot) {
    const session = document.getElementById("shop-customer-session");
    const label = document.getElementById("shop-customer-label");
    const scope = document.getElementById("shop-scope-validation");
    const contract = buildShoppingRuntimeContract(snapshot);

    if (session) session.textContent = contract.customer_session_present ? "SESSION_PRESENT" : "ANONYMOUS_PLACEHOLDER";
    if (label) label.textContent = snapshot.customer.label || "Anonim müşteri";
    if (scope) {
      scope.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      scope.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderRegionContext(snapshot) {
    const city = document.getElementById("shop-city");
    const district = document.getElementById("shop-district");
    const neighborhood = document.getElementById("shop-neighborhood");
    const region = document.getElementById("shop-region-code");

    if (city) city.textContent = snapshot.region.city;
    if (district) district.textContent = snapshot.region.district;
    if (neighborhood) neighborhood.textContent = snapshot.region.neighborhood;
    if (region) region.textContent = snapshot.region.region_code;
  }

  function renderStoreShortcuts(snapshot) {
    const target = document.getElementById("shop-store-shortcuts");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.recommended_stores || []).forEach(function (store) {
      const card = document.createElement("article");
      card.className = "shop-card";
      card.setAttribute("data-store-slug", store.store_slug);
      card.innerHTML = [
        "<strong>" + store.name + "</strong>",
        "<p>" + store.category + " / " + store.status + " / " + store.distance_km + " km</p>",
        "<a href='" + store.storefront_url + "'>Vitrine git</a>",
        "<a href='" + store.products_url + "'>Ürünlere git</a>"
      ].join("");
      target.appendChild(card);
    });
  }

  function renderProductShortcuts(snapshot) {
    const target = document.getElementById("shop-product-shortcuts");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.recommended_products || []).forEach(function (product) {
      const card = document.createElement("article");
      card.className = "shop-card";
      card.setAttribute("data-product-id", product.product_id);
      card.innerHTML = [
        "<span class='emoji'>" + product.image_placeholder + "</span>",
        "<strong>" + product.name + "</strong>",
        "<p>Store: " + product.store_slug + "</p>",
        "<em>" + moneyTRY(product.price) + "</em>",
        "<button type='button' disabled>Sepete ekleme kapalı</button>"
      ].join("");
      target.appendChild(card);
    });
  }

  function renderBasketPreview(snapshot) {
    const basket = loadBasketPreview();
    snapshot.basket_preview = basket;

    const lineCount = document.getElementById("shop-basket-line-count");
    const itemCount = document.getElementById("shop-basket-item-count");
    const subtotal = document.getElementById("shop-basket-subtotal");
    const vat = document.getElementById("shop-basket-vat");
    const delivery = document.getElementById("shop-basket-delivery-fee");
    const grand = document.getElementById("shop-basket-grand-total");
    const store = document.getElementById("shop-basket-store");

    if (lineCount) lineCount.textContent = String(basket.line_count);
    if (itemCount) itemCount.textContent = String(basket.item_count);
    if (subtotal) subtotal.textContent = moneyTRY(basket.subtotal);
    if (vat) vat.textContent = moneyTRY(basket.vat_total);
    if (delivery) delivery.textContent = moneyTRY(basket.delivery_fee);
    if (grand) grand.textContent = moneyTRY(basket.grand_total);
    if (store) store.textContent = basket.store_slug;
  }

  function renderCampaignStrip(snapshot) {
    const target = document.getElementById("shop-campaign-strip");
    if (!target) return;

    const campaign = Array.isArray(snapshot.campaigns) && snapshot.campaigns.length > 0 ? snapshot.campaigns[0] : null;

    if (!campaign) {
      target.textContent = "Aktif kampanya yok.";
      return;
    }

    target.innerHTML = [
      "<strong>" + campaign.title + "</strong>",
      "<p>" + campaign.description + "</p>"
    ].join("");
  }

  function renderFulfillmentPreference() {
    const selector = document.getElementById("shop-fulfillment-preference");
    if (selector) selector.value = getFulfillmentPreference();
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("shop-runtime-contract");
    if (!target) return;

    const contract = buildShoppingRuntimeContract(snapshot);

    target.textContent = [
      "real_customer_login_enabled=" + CONFIG.runtimeContract.realCustomerLoginEnabled,
      "real_basket_mutation_enabled=" + CONFIG.runtimeContract.realBasketMutationEnabled,
      "real_order_submit_enabled=" + CONFIG.runtimeContract.realOrderSubmitEnabled,
      "real_payment_handoff_enabled=" + CONFIG.runtimeContract.realPaymentHandoffEnabled,
      "real_stock_reservation_enabled=" + CONFIG.runtimeContract.realStockReservationEnabled,
      "ready_for_step_341=" + CONFIG.runtimeContract.readyForStep341,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderShopScreen(snapshot) {
    renderCustomerContext(snapshot);
    renderRegionContext(snapshot);
    renderStoreShortcuts(snapshot);
    renderProductShortcuts(snapshot);
    renderBasketPreview(snapshot);
    renderCampaignStrip(snapshot);
    renderFulfillmentPreference();
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-market-shop-rendered", "true");
  }

  async function bootShopScreen() {
    const snapshot = await fetchShoppingSnapshot();
    renderShopScreen(snapshot);
    return buildShoppingRuntimeContract(snapshot);
  }

  window.Pix2piMarketShop = {
    CONFIG: CONFIG,
    getCustomerSession: getCustomerSession,
    getRegionContext: getRegionContext,
    getFulfillmentPreference: getFulfillmentPreference,
    setFulfillmentPreference: setFulfillmentPreference,
    shoppingScopeHeaders: shoppingScopeHeaders,
    validateShoppingScope: validateShoppingScope,
    fetchShoppingSnapshot: fetchShoppingSnapshot,
    loadBasketPreview: loadBasketPreview,
    buildShoppingRuntimeContract: buildShoppingRuntimeContract,
    buildDisabledShoppingAction: buildDisabledShoppingAction,
    renderCustomerContext: renderCustomerContext,
    renderRegionContext: renderRegionContext,
    renderStoreShortcuts: renderStoreShortcuts,
    renderProductShortcuts: renderProductShortcuts,
    renderBasketPreview: renderBasketPreview,
    renderCampaignStrip: renderCampaignStrip,
    renderFulfillmentPreference: renderFulfillmentPreference,
    renderRuntimeContract: renderRuntimeContract,
    renderShopScreen: renderShopScreen,
    bootShopScreen: bootShopScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_340_MARKET_SHOP_RUNTIME_END */
