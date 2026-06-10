/* PIX2PI_338_MARKET_ORDERS_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "market_orders",
    phase: "FAZ_7R",
    step: "338",
    orderDraftEndpoint: "/api/market/orders/draft",
    orderSubmitEndpoint: "/api/market/orders/submit",
    orderStatusEndpoint: "/api/market/orders/status",
    selectedTenantKey: "pix2pi.market.tenant.preference",
    storeSlugKey: "pix2pi.market.store.slug",
    customerSessionKey: "pix2pi.market.customer.session",
    basketDraftKey: "pix2pi.market.basket.draft",
    orderDraftKey: "pix2pi.market.order.draft",
    runtimeContract: {
      realOrderSubmitEnabled: false,
      realPaymentHandoffEnabled: false,
      realStockReservationEnabled: false,
      realDeliveryIntegrationEnabled: false,
      orderDraftEnabled: true,
      fallbackOrderEnabled: true,
      readyForStep339: true
    },
    fallbackOrder: {
      tenant_id: "controlled-pilot",
      store_slug: "demo-market",
      customer_session_id: "ANONYMOUS_DEMO_SESSION",
      fulfillment_mode: "DELIVERY",
      delivery_address_placeholder: {
        title: "Demo Mahalle",
        line: "Adres doğrulama 340 sonrası açılacak",
        note: "Kapıya bırakma notu placeholder"
      },
      lines: [
        {
          product_id: "mkt-prd-001",
          sku: "MKT-SUT-001",
          name: "Demo Süt 1L",
          unit: "ADET",
          quantity: 2,
          unit_price: 35,
          vat_rate: 10
        },
        {
          product_id: "mkt-prd-002",
          sku: "MKT-EKMEK-001",
          name: "Demo Ekmek",
          unit: "ADET",
          quantity: 3,
          unit_price: 10,
          vat_rate: 1
        }
      ],
      delivery_fee: 20,
      currency: "TRY",
      status_timeline: [
        { status: "DRAFT", label: "Sipariş taslağı", done: true },
        { status: "VALIDATION", label: "Validasyon", done: false },
        { status: "PAYMENT_PENDING_DISABLED", label: "Ödeme kapalı gate", done: false },
        { status: "SUBMIT_DISABLED", label: "Gerçek sipariş kapalı", done: false }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackOrder.tenant_id;
  }

  function getStoreSlug() {
    const params = new URLSearchParams(window.location.search);
    return params.get("store") || window.localStorage.getItem(CONFIG.storeSlugKey) || CONFIG.fallbackOrder.store_slug;
  }

  function getCustomerSession() {
    const raw = window.localStorage.getItem(CONFIG.customerSessionKey);
    if (!raw) {
      return {
        session_present: false,
        session_id: CONFIG.fallbackOrder.customer_session_id,
        real_customer_login_enabled: false
      };
    }

    try {
      return Object.assign({
        session_present: true,
        real_customer_login_enabled: false
      }, JSON.parse(raw));
    } catch (_error) {
      return {
        session_present: false,
        session_id: "INVALID_SESSION",
        real_customer_login_enabled: false
      };
    }
  }

  function orderScopeHeaders() {
    const session = getCustomerSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Store-Slug": getStoreSlug(),
      "X-Market-Customer-Session": session.session_id,
      "X-Pix2pi-Surface": "marketplace",
      "X-Pix2pi-Step": "338"
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

  function loadBasketDraft() {
    const raw = window.localStorage.getItem(CONFIG.basketDraftKey);
    if (!raw) return null;

    try {
      return JSON.parse(raw);
    } catch (_error) {
      return null;
    }
  }

  function calculateOrderTotals(lines, deliveryFee) {
    const totals = (lines || []).reduce(function (acc, line) {
      const lineGross = Number(line.unit_price || 0) * Number(line.quantity || 0);
      const lineVat = lineGross * Number(line.vat_rate || 0) / 100;

      acc.subtotal += lineGross;
      acc.vat_total += lineVat;
      acc.item_count += Number(line.quantity || 0);
      acc.line_count += 1;

      return acc;
    }, {
      subtotal: 0,
      vat_total: 0,
      delivery_fee: Number(deliveryFee || 0),
      grand_total: 0,
      item_count: 0,
      line_count: 0,
      currency: "TRY"
    });

    totals.grand_total = totals.subtotal + totals.vat_total + totals.delivery_fee;
    return totals;
  }

  function validateOrderScope(order) {
    const errors = [];

    if (!order || !order.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!order || !order.store_slug) {
      errors.push({ field: "store_slug", code: "STORE_SLUG_REQUIRED" });
    }

    if (!order || !order.customer_session_id) {
      errors.push({ field: "customer_session_id", code: "CUSTOMER_SESSION_REQUIRED" });
    }

    if (!order || !Array.isArray(order.lines) || order.lines.length === 0) {
      errors.push({ field: "lines", code: "ORDER_LINES_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  function buildOrderDraftPayload(options) {
    const basketDraft = loadBasketDraft();
    const source = basketDraft && Array.isArray(basketDraft.lines) ? basketDraft : CONFIG.fallbackOrder;
    const session = getCustomerSession();
    const fulfillmentMode = options && options.fulfillment_mode ? options.fulfillment_mode : source.fulfillment_mode;
    const deliveryFee = fulfillmentMode === "DELIVERY" ? source.delivery_fee : 0;
    const totals = calculateOrderTotals(source.lines, deliveryFee);

    const payload = {
      tenant_id: getTenantId(),
      store_slug: getStoreSlug(),
      customer_session_id: session.session_id,
      customer_session_present: session.session_present,
      fulfillment_mode: fulfillmentMode,
      delivery_address_placeholder: source.delivery_address_placeholder,
      lines: source.lines,
      totals: totals,
      status_timeline: source.status_timeline,
      runtime_contract: CONFIG.runtimeContract,
      source: {
        surface: "market_orders",
        phase: "FAZ_7R",
        step: "338"
      }
    };

    payload.validation = validateOrderScope(payload);
    return payload;
  }

  function saveOrderDraft(payload) {
    window.localStorage.setItem(CONFIG.orderDraftKey, JSON.stringify(payload));
    return payload;
  }

  function buildPaymentHandoffDraft(order) {
    return {
      tenant_id: order.tenant_id,
      store_slug: order.store_slug,
      customer_session_id: order.customer_session_id,
      amount: order.totals.grand_total,
      currency: order.totals.currency,
      payment_handoff_enabled: CONFIG.runtimeContract.realPaymentHandoffEnabled,
      provider_transaction_id: null,
      reason: "PAYMENT_HANDOFF_DISABLED_IN_STEP_338",
      source: {
        surface: "market_orders",
        phase: "FAZ_7R",
        step: "338"
      }
    };
  }

  async function apiJson(endpoint, options) {
    const response = await fetch(endpoint, Object.assign({
      headers: orderScopeHeaders()
    }, options || {}));

    if (!response.ok) {
      throw new Error("MARKET_ORDER_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function prepareOrderDraft(options) {
    const payload = buildOrderDraftPayload(options);
    saveOrderDraft(payload);

    if (!CONFIG.runtimeContract.realOrderSubmitEnabled) {
      return {
        prepared: true,
        local_order_draft: true,
        submit_enabled: false,
        payload: payload
      };
    }

    try {
      const response = await apiJson(CONFIG.orderDraftEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });

      return {
        prepared: true,
        response: response
      };
    } catch (_error) {
      return {
        prepared: true,
        fallback_payload: payload
      };
    }
  }

  async function submitOrderDisabledGuard() {
    const payload = buildOrderDraftPayload();

    return {
      submitted: false,
      reason: "REAL_ORDER_SUBMIT_DISABLED",
      real_order_submit_enabled: CONFIG.runtimeContract.realOrderSubmitEnabled,
      payment_handoff: buildPaymentHandoffDraft(payload),
      payload: payload
    };
  }

  function renderContext(order) {
    const tenant = document.getElementById("order-tenant");
    const store = document.getElementById("order-store-slug");
    const customer = document.getElementById("order-customer-session");
    const validation = document.getElementById("order-scope-validation");

    if (tenant) tenant.textContent = order.tenant_id;
    if (store) store.textContent = order.store_slug;
    if (customer) customer.textContent = order.customer_session_present ? "SESSION_PRESENT" : "ANONYMOUS_PLACEHOLDER";
    if (validation) {
      validation.textContent = order.validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", order.validation.valid ? "valid" : "invalid");
    }
  }

  function renderOrderLines(order) {
    const target = document.getElementById("order-line-items");
    if (!target) return;

    target.innerHTML = "";

    (order.lines || []).forEach(function (line) {
      const row = document.createElement("article");
      row.className = "order-line";
      row.setAttribute("data-product-id", line.product_id);
      row.innerHTML = [
        "<div>",
        "<strong>" + line.name + "</strong>",
        "<p>" + line.sku + " / " + line.quantity + " " + line.unit + " × " + moneyTRY(line.unit_price) + " / KDV %" + line.vat_rate + "</p>",
        "</div>",
        "<em>" + moneyTRY(Number(line.unit_price || 0) * Number(line.quantity || 0)) + "</em>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderOrderTotals(order) {
    const subtotal = document.getElementById("order-subtotal");
    const vat = document.getElementById("order-vat-total");
    const delivery = document.getElementById("order-delivery-fee");
    const grand = document.getElementById("order-grand-total");
    const itemCount = document.getElementById("order-item-count");

    if (subtotal) subtotal.textContent = moneyTRY(order.totals.subtotal);
    if (vat) vat.textContent = moneyTRY(order.totals.vat_total);
    if (delivery) delivery.textContent = moneyTRY(order.totals.delivery_fee);
    if (grand) grand.textContent = moneyTRY(order.totals.grand_total);
    if (itemCount) itemCount.textContent = String(order.totals.item_count);
  }

  function renderFulfillment(order) {
    const mode = document.getElementById("order-fulfillment-mode");
    const address = document.getElementById("order-address-placeholder");
    const note = document.getElementById("order-delivery-note-placeholder");

    if (mode) mode.value = order.fulfillment_mode;
    if (address) address.textContent = order.delivery_address_placeholder.title + " — " + order.delivery_address_placeholder.line;
    if (note) note.textContent = order.delivery_address_placeholder.note;
  }

  function renderStatusTimeline(order) {
    const target = document.getElementById("order-status-timeline");
    if (!target) return;

    target.innerHTML = "";

    (order.status_timeline || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "timeline-item";
      row.setAttribute("data-order-status", item.status);
      row.setAttribute("data-done", String(item.done));
      row.innerHTML = [
        "<strong>" + item.status + "</strong>",
        "<p>" + item.label + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRuntimeContract(order) {
    const target = document.getElementById("order-runtime-contract");
    if (!target) return;

    target.textContent = [
      "real_order_submit_enabled=" + CONFIG.runtimeContract.realOrderSubmitEnabled,
      "real_payment_handoff_enabled=" + CONFIG.runtimeContract.realPaymentHandoffEnabled,
      "real_stock_reservation_enabled=" + CONFIG.runtimeContract.realStockReservationEnabled,
      "ready_for_step_339=" + CONFIG.runtimeContract.readyForStep339,
      "grand_total=" + moneyTRY(order.totals.grand_total)
    ].join(" / ");
  }

  function renderOrderScreen(order) {
    renderContext(order);
    renderOrderLines(order);
    renderOrderTotals(order);
    renderFulfillment(order);
    renderStatusTimeline(order);
    renderRuntimeContract(order);
    document.body.setAttribute("data-market-orders-rendered", "true");
  }

  async function bootOrderScreen() {
    const order = buildOrderDraftPayload();
    saveOrderDraft(order);
    renderOrderScreen(order);
    return order;
  }

  window.Pix2piMarketOrders = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getStoreSlug: getStoreSlug,
    getCustomerSession: getCustomerSession,
    orderScopeHeaders: orderScopeHeaders,
    loadBasketDraft: loadBasketDraft,
    calculateOrderTotals: calculateOrderTotals,
    validateOrderScope: validateOrderScope,
    buildOrderDraftPayload: buildOrderDraftPayload,
    saveOrderDraft: saveOrderDraft,
    buildPaymentHandoffDraft: buildPaymentHandoffDraft,
    prepareOrderDraft: prepareOrderDraft,
    submitOrderDisabledGuard: submitOrderDisabledGuard,
    renderContext: renderContext,
    renderOrderLines: renderOrderLines,
    renderOrderTotals: renderOrderTotals,
    renderFulfillment: renderFulfillment,
    renderStatusTimeline: renderStatusTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderOrderScreen: renderOrderScreen,
    bootOrderScreen: bootOrderScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_338_MARKET_ORDERS_RUNTIME_END */
