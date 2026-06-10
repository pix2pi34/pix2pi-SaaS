/* PIX2PI_331_POS_SALE_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "pos_sale",
    phase: "FAZ_7R",
    step: "331",
    productSearchEndpoint: "/api/pos/products/search",
    saleDraftEndpoint: "/api/pos/sales/draft",
    sessionVerifyEndpoint: "/api/pos/auth/session",
    paymentStepPath: "/checkout/",
    selectedTenantKey: "pix2pi.pos.tenant.preference",
    deviceKey: "pix2pi.pos.device.id",
    cashierSessionKey: "pix2pi.pos.cashier.session",
    saleDraftKey: "pix2pi.pos.sale.draft",
    runtimeContract: {
      realSaleEnabled: false,
      realPaymentEnabled: false,
      realStockDecrementEnabled: false,
      saleDraftEnabled: true,
      fallbackCatalogEnabled: true,
      offlineQueueEnabled: false,
      readyForStep332: true
    },
    fallbackCatalog: [
      {
        id: "pos-prd-001",
        sku: "SKU-DEMO-001",
        barcode: "869000000001",
        name: "Demo Ürün",
        unit: "ADET",
        vat_rate: 20,
        price: 100,
        stock_hint: 12
      },
      {
        id: "pos-prd-002",
        sku: "SKU-EKMEK-001",
        barcode: "869000000002",
        name: "Demo Ekmek",
        unit: "ADET",
        vat_rate: 1,
        price: 10,
        stock_hint: 50
      },
      {
        id: "pos-prd-003",
        sku: "SKU-SUT-001",
        barcode: "869000000003",
        name: "Demo Süt",
        unit: "ADET",
        vat_rate: 10,
        price: 35,
        stock_hint: 20
      }
    ]
  };

  let CART = [];

  function getSelectedTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || "controlled-pilot";
  }

  function getOrCreateDeviceId() {
    let deviceId = window.localStorage.getItem(CONFIG.deviceKey);
    if (!deviceId) {
      deviceId = "pos-device-" + Math.random().toString(36).slice(2, 10);
      window.localStorage.setItem(CONFIG.deviceKey, deviceId);
    }
    return deviceId;
  }

  function getCashierSession() {
    const raw = window.localStorage.getItem(CONFIG.cashierSessionKey);
    if (!raw) return null;

    try {
      return JSON.parse(raw);
    } catch (_error) {
      return null;
    }
  }

  function getCashierCode() {
    const session = getCashierSession();
    return session && session.cashier_code ? session.cashier_code : "DEMO_CASHIER";
  }

  function tenantDeviceCashierHeaders() {
    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getSelectedTenantId(),
      "X-POS-Device-ID": getOrCreateDeviceId(),
      "X-POS-Cashier-Code": getCashierCode(),
      "X-Pix2pi-Surface": "pos",
      "X-Pix2pi-Step": "331"
    };
  }

  function verifySessionGuard() {
    const session = getCashierSession();

    if (!session) {
      return {
        ok: false,
        reason: "NO_CASHIER_SESSION",
        redirect_path: "/login/"
      };
    }

    return {
      ok: true,
      tenant_id: getSelectedTenantId(),
      device_id: getOrCreateDeviceId(),
      cashier_code: getCashierCode(),
      session: session
    };
  }

  async function apiJson(endpoint, options) {
    const response = await fetch(endpoint, Object.assign({
      headers: tenantDeviceCashierHeaders()
    }, options || {}));

    if (!response.ok) {
      throw new Error("POS_SALE_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  function normalizeTerm(value) {
    return String(value || "").trim().toLowerCase();
  }

  async function searchProducts(term) {
    const normalized = normalizeTerm(term);

    try {
      return await apiJson(CONFIG.productSearchEndpoint + "?q=" + encodeURIComponent(normalized), { method: "GET" });
    } catch (_error) {
      const list = CONFIG.fallbackCatalog.filter(function (item) {
        if (!normalized) return true;
        return item.name.toLowerCase().indexOf(normalized) >= 0 ||
          item.sku.toLowerCase().indexOf(normalized) >= 0 ||
          item.barcode.toLowerCase().indexOf(normalized) >= 0;
      });

      return {
        tenant_id: getSelectedTenantId(),
        products: list
      };
    }
  }

  function findProductById(productId) {
    return CONFIG.fallbackCatalog.find(function (item) {
      return item.id === productId;
    }) || null;
  }

  function findProductByBarcode(barcode) {
    const normalized = normalizeTerm(barcode);
    return CONFIG.fallbackCatalog.find(function (item) {
      return normalizeTerm(item.barcode) === normalized || normalizeTerm(item.sku) === normalized;
    }) || null;
  }

  function addToCart(product, quantity) {
    const qty = Number(quantity || 1);
    const safeQty = Number.isFinite(qty) && qty > 0 ? qty : 1;

    const existing = CART.find(function (line) {
      return line.product_id === product.id;
    });

    if (existing) {
      existing.quantity += safeQty;
    } else {
      CART.push({
        product_id: product.id,
        sku: product.sku,
        barcode: product.barcode,
        name: product.name,
        unit: product.unit,
        vat_rate: Number(product.vat_rate || 0),
        unit_price: Number(product.price || 0),
        quantity: safeQty
      });
    }

    saveSaleDraft();
    return CART;
  }

  function incrementLine(productId) {
    const line = CART.find(function (item) { return item.product_id === productId; });
    if (line) {
      line.quantity += 1;
      saveSaleDraft();
    }
    return CART;
  }

  function decrementLine(productId) {
    const line = CART.find(function (item) { return item.product_id === productId; });
    if (line) {
      line.quantity -= 1;
      if (line.quantity <= 0) {
        removeLine(productId);
      } else {
        saveSaleDraft();
      }
    }
    return CART;
  }

  function removeLine(productId) {
    CART = CART.filter(function (item) {
      return item.product_id !== productId;
    });
    saveSaleDraft();
    return CART;
  }

  function clearCart() {
    CART = [];
    saveSaleDraft();
    return CART;
  }

  function calculateCartTotals(cart) {
    const lines = cart || CART;

    return lines.reduce(function (acc, line) {
      const gross = Number(line.unit_price || 0) * Number(line.quantity || 0);
      const vat = gross * Number(line.vat_rate || 0) / 100;
      acc.gross_total += gross;
      acc.vat_total += vat;
      acc.grand_total += gross + vat;
      acc.line_count += 1;
      acc.item_count += Number(line.quantity || 0);
      return acc;
    }, {
      gross_total: 0,
      vat_total: 0,
      grand_total: 0,
      line_count: 0,
      item_count: 0,
      currency: "TRY"
    });
  }

  function buildSaleDraftPayload() {
    const sessionGuard = verifySessionGuard();
    const totals = calculateCartTotals(CART);

    return {
      tenant_id: getSelectedTenantId(),
      device_id: getOrCreateDeviceId(),
      cashier_code: getCashierCode(),
      session_ok: sessionGuard.ok,
      cart: CART,
      totals: totals,
      runtime_contract: CONFIG.runtimeContract,
      source: {
        surface: "pos_sale",
        phase: "FAZ_7R",
        step: "331"
      }
    };
  }

  function saveSaleDraft() {
    const payload = buildSaleDraftPayload();
    window.localStorage.setItem(CONFIG.saleDraftKey, JSON.stringify(payload));
    return payload;
  }

  function loadSaleDraft() {
    const raw = window.localStorage.getItem(CONFIG.saleDraftKey);
    if (!raw) return null;

    try {
      const payload = JSON.parse(raw);
      if (payload && Array.isArray(payload.cart)) {
        CART = payload.cart;
      }
      return payload;
    } catch (_error) {
      return null;
    }
  }

  async function persistSaleDraft() {
    const payload = saveSaleDraft();

    if (!CONFIG.runtimeContract.realSaleEnabled) {
      return {
        persisted: false,
        local_draft: true,
        payload: payload
      };
    }

    try {
      const response = await apiJson(CONFIG.saleDraftEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });

      return {
        persisted: true,
        response: response
      };
    } catch (_error) {
      return {
        persisted: false,
        fallback_payload: payload
      };
    }
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

  function renderSessionGuard(target) {
    if (!target) return;
    const guard = verifySessionGuard();
    target.textContent = guard.ok
      ? "Kasiyer oturumu hazır: " + guard.cashier_code
      : "Kasiyer oturumu yok. /login/ ekranından oturum hazırlanmalı.";
    target.setAttribute("data-session-ok", String(guard.ok));
  }

  function renderProductGrid(target, products) {
    if (!target) return;

    target.innerHTML = "";

    (products || CONFIG.fallbackCatalog).forEach(function (product) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "product-tile";
      button.setAttribute("data-product-id", product.id);
      button.innerHTML = [
        "<strong>" + product.name + "</strong>",
        "<span>" + product.sku + "</span>",
        "<em>" + moneyTRY(product.price) + "</em>"
      ].join("");
      button.addEventListener("click", function () {
        addToCart(product, 1);
        renderCart();
      });
      target.appendChild(button);
    });
  }

  function renderCart() {
    const target = document.getElementById("pos-cart-lines");
    const totalsTarget = document.getElementById("pos-cart-totals");

    if (target) {
      target.innerHTML = "";

      CART.forEach(function (line) {
        const row = document.createElement("article");
        row.className = "cart-row";
        row.setAttribute("data-cart-product-id", line.product_id);
        row.innerHTML = [
          "<div><strong>" + line.name + "</strong><p>" + line.quantity + " " + line.unit + " × " + moneyTRY(line.unit_price) + "</p></div>",
          "<div class='cart-actions'>",
          "<button type='button' data-action='dec'>−</button>",
          "<button type='button' data-action='inc'>+</button>",
          "<button type='button' data-action='remove'>Sil</button>",
          "</div>"
        ].join("");

        row.querySelector("[data-action='dec']").addEventListener("click", function () {
          decrementLine(line.product_id);
          renderCart();
        });

        row.querySelector("[data-action='inc']").addEventListener("click", function () {
          incrementLine(line.product_id);
          renderCart();
        });

        row.querySelector("[data-action='remove']").addEventListener("click", function () {
          removeLine(line.product_id);
          renderCart();
        });

        target.appendChild(row);
      });
    }

    if (totalsTarget) {
      const totals = calculateCartTotals(CART);
      totalsTarget.textContent = "Ara toplam: " + moneyTRY(totals.gross_total) +
        " / KDV: " + moneyTRY(totals.vat_total) +
        " / Genel toplam: " + moneyTRY(totals.grand_total);
      totalsTarget.setAttribute("data-line-count", String(totals.line_count));
      totalsTarget.setAttribute("data-item-count", String(totals.item_count));
    }

    document.body.setAttribute("data-pos-cart-rendered", "true");
  }

  async function handleBarcodeSubmit(barcode) {
    const product = findProductByBarcode(barcode);
    if (product) {
      addToCart(product, 1);
      renderCart();
      return {
        found: true,
        product: product
      };
    }

    const result = await searchProducts(barcode);
    return {
      found: false,
      result: result
    };
  }

  async function bootPOSSaleScreen() {
    loadSaleDraft();
    renderSessionGuard(document.getElementById("pos-session-guard-status"));
    renderProductGrid(document.getElementById("pos-product-grid"), CONFIG.fallbackCatalog);
    renderCart();
    document.body.setAttribute("data-pos-sale-rendered", "true");
    return buildSaleDraftPayload();
  }

  window.Pix2piPOSSale = {
    CONFIG: CONFIG,
    getSelectedTenantId: getSelectedTenantId,
    getOrCreateDeviceId: getOrCreateDeviceId,
    getCashierSession: getCashierSession,
    getCashierCode: getCashierCode,
    tenantDeviceCashierHeaders: tenantDeviceCashierHeaders,
    verifySessionGuard: verifySessionGuard,
    searchProducts: searchProducts,
    findProductById: findProductById,
    findProductByBarcode: findProductByBarcode,
    addToCart: addToCart,
    incrementLine: incrementLine,
    decrementLine: decrementLine,
    removeLine: removeLine,
    clearCart: clearCart,
    calculateCartTotals: calculateCartTotals,
    buildSaleDraftPayload: buildSaleDraftPayload,
    saveSaleDraft: saveSaleDraft,
    loadSaleDraft: loadSaleDraft,
    persistSaleDraft: persistSaleDraft,
    renderSessionGuard: renderSessionGuard,
    renderProductGrid: renderProductGrid,
    renderCart: renderCart,
    handleBarcodeSubmit: handleBarcodeSubmit,
    bootPOSSaleScreen: bootPOSSaleScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_331_POS_SALE_RUNTIME_END */
