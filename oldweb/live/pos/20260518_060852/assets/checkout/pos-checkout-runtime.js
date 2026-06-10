/* PIX2PI_332_POS_CHECKOUT_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "pos_checkout",
    phase: "FAZ_7R",
    step: "332",
    checkoutDraftEndpoint: "/api/pos/checkout/draft",
    paymentPrepareEndpoint: "/api/pos/payments/prepare",
    receiptDraftEndpoint: "/api/pos/receipts/draft",
    saleScreenPath: "/sale/",
    selectedTenantKey: "pix2pi.pos.tenant.preference",
    deviceKey: "pix2pi.pos.device.id",
    cashierSessionKey: "pix2pi.pos.cashier.session",
    saleDraftKey: "pix2pi.pos.sale.draft",
    checkoutDraftKey: "pix2pi.pos.checkout.draft",
    paymentMethods: ["CASH", "CARD", "QR"],
    runtimeContract: {
      realPaymentEnabled: false,
      realSaleFinalizeEnabled: false,
      realStockDecrementEnabled: false,
      receiptDraftEnabled: true,
      checkoutDraftEnabled: true,
      offlinePaymentQueueEnabled: false,
      readyForStep333: true
    },
    fallbackSaleDraft: {
      tenant_id: "controlled-pilot",
      device_id: "pos-device-demo",
      cashier_code: "DEMO_CASHIER",
      session_ok: true,
      cart: [
        {
          product_id: "pos-prd-001",
          sku: "SKU-DEMO-001",
          barcode: "869000000001",
          name: "Demo Ürün",
          unit: "ADET",
          vat_rate: 20,
          unit_price: 100,
          quantity: 1
        }
      ],
      totals: {
        gross_total: 100,
        vat_total: 20,
        grand_total: 120,
        line_count: 1,
        item_count: 1,
        currency: "TRY"
      }
    }
  };

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
      "X-Pix2pi-Step": "332"
    };
  }

  function loadSaleDraft() {
    const raw = window.localStorage.getItem(CONFIG.saleDraftKey);
    if (!raw) return CONFIG.fallbackSaleDraft;

    try {
      const draft = JSON.parse(raw);
      if (!draft || !Array.isArray(draft.cart)) return CONFIG.fallbackSaleDraft;
      return draft;
    } catch (_error) {
      return CONFIG.fallbackSaleDraft;
    }
  }

  function calculateCartTotals(cart) {
    const lines = Array.isArray(cart) ? cart : [];

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

  function validatePaymentMethod(method) {
    return CONFIG.paymentMethods.indexOf(String(method || "").toUpperCase()) >= 0;
  }

  function calculateTender(paymentMethod, amountDue, tenderedAmount) {
    const due = Number(amountDue || 0);
    const tendered = Number(tenderedAmount || 0);

    if (paymentMethod === "CASH") {
      return {
        amount_due: due,
        tendered_amount: tendered,
        change_amount: Math.max(0, tendered - due),
        remaining_amount: Math.max(0, due - tendered),
        fully_paid: tendered >= due
      };
    }

    return {
      amount_due: due,
      tendered_amount: due,
      change_amount: 0,
      remaining_amount: 0,
      fully_paid: true
    };
  }

  function validateCheckoutPayload(payload) {
    const errors = [];

    if (!payload.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!payload.device_id) {
      errors.push({ field: "device_id", code: "DEVICE_REQUIRED" });
    }

    if (!payload.cashier_code) {
      errors.push({ field: "cashier_code", code: "CASHIER_REQUIRED" });
    }

    if (!Array.isArray(payload.cart) || payload.cart.length === 0) {
      errors.push({ field: "cart", code: "EMPTY_CART" });
    }

    if (!validatePaymentMethod(payload.payment.method)) {
      errors.push({ field: "payment.method", code: "INVALID_PAYMENT_METHOD" });
    }

    if (payload.payment.method === "CASH" && payload.payment.tender.remaining_amount > 0) {
      errors.push({ field: "payment.tendered_amount", code: "INSUFFICIENT_TENDER" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  function buildCheckoutDraftPayload(paymentMethod, tenderedAmount) {
    const saleDraft = loadSaleDraft();
    const cart = saleDraft.cart || [];
    const totals = calculateCartTotals(cart);
    const method = String(paymentMethod || "CASH").toUpperCase();
    const tender = calculateTender(method, totals.grand_total, tenderedAmount);

    return {
      tenant_id: getSelectedTenantId(),
      device_id: getOrCreateDeviceId(),
      cashier_code: getCashierCode(),
      cart: cart,
      totals: totals,
      payment: {
        method: method,
        tendered_amount: tender.tendered_amount,
        change_amount: tender.change_amount,
        remaining_amount: tender.remaining_amount,
        fully_paid: tender.fully_paid,
        provider_live_enabled: false,
        provider_transaction_id: null
      },
      runtime_contract: CONFIG.runtimeContract,
      source: {
        surface: "pos_checkout",
        phase: "FAZ_7R",
        step: "332"
      }
    };
  }

  function buildReceiptDraftPayload(checkoutPayload) {
    return {
      tenant_id: checkoutPayload.tenant_id,
      device_id: checkoutPayload.device_id,
      cashier_code: checkoutPayload.cashier_code,
      receipt_no: "RCPT-DRAFT-" + Date.now(),
      cart: checkoutPayload.cart,
      totals: checkoutPayload.totals,
      payment: checkoutPayload.payment,
      receipt_status: "DRAFT_NOT_FISCALIZED",
      real_sale_finalize_enabled: false,
      real_payment_enabled: false,
      real_stock_decrement_enabled: false,
      source: {
        surface: "pos_checkout",
        phase: "FAZ_7R",
        step: "332"
      }
    };
  }

  function saveCheckoutDraft(payload) {
    window.localStorage.setItem(CONFIG.checkoutDraftKey, JSON.stringify(payload));
    return payload;
  }

  function loadCheckoutDraft() {
    const raw = window.localStorage.getItem(CONFIG.checkoutDraftKey);
    if (!raw) return null;

    try {
      return JSON.parse(raw);
    } catch (_error) {
      return null;
    }
  }

  async function apiJson(endpoint, options) {
    const response = await fetch(endpoint, Object.assign({
      headers: tenantDeviceCashierHeaders()
    }, options || {}));

    if (!response.ok) {
      throw new Error("POS_CHECKOUT_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function prepareCheckout(paymentMethod, tenderedAmount) {
    const payload = buildCheckoutDraftPayload(paymentMethod, tenderedAmount);
    const validation = validateCheckoutPayload(payload);
    saveCheckoutDraft(payload);

    if (!validation.valid) {
      return {
        prepared: false,
        validation: validation,
        payload: payload
      };
    }

    if (!CONFIG.runtimeContract.realPaymentEnabled) {
      return {
        prepared: true,
        validation: validation,
        local_checkout_draft: true,
        provider_live_enabled: false,
        payload: payload
      };
    }

    try {
      const response = await apiJson(CONFIG.checkoutDraftEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });

      return {
        prepared: true,
        validation: validation,
        response: response
      };
    } catch (_error) {
      return {
        prepared: false,
        validation: validation,
        fallback_payload: payload
      };
    }
  }

  async function prepareReceiptDraft(paymentMethod, tenderedAmount) {
    const checkoutPayload = buildCheckoutDraftPayload(paymentMethod, tenderedAmount);
    const receiptPayload = buildReceiptDraftPayload(checkoutPayload);

    if (!CONFIG.runtimeContract.receiptDraftEnabled) {
      return {
        receipt_ready: false,
        reason: "RECEIPT_DRAFT_DISABLED",
        payload: receiptPayload
      };
    }

    try {
      const response = await apiJson(CONFIG.receiptDraftEndpoint, {
        method: "POST",
        body: JSON.stringify(receiptPayload)
      });

      return {
        receipt_ready: true,
        response: response
      };
    } catch (_error) {
      return {
        receipt_ready: true,
        local_receipt_draft: true,
        payload: receiptPayload
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

  function renderCartReview(target, saleDraft) {
    if (!target) return;

    target.innerHTML = "";

    (saleDraft.cart || []).forEach(function (line) {
      const row = document.createElement("article");
      row.className = "checkout-row";
      row.setAttribute("data-checkout-product-id", line.product_id);
      row.innerHTML = [
        "<div>",
        "<strong>" + line.name + "</strong>",
        "<p>" + line.quantity + " " + line.unit + " × " + moneyTRY(line.unit_price) + " / KDV %" + line.vat_rate + "</p>",
        "</div>",
        "<strong>" + moneyTRY(Number(line.unit_price || 0) * Number(line.quantity || 0)) + "</strong>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderTotals(totals, tender) {
    const gross = document.getElementById("checkout-gross-total");
    const vat = document.getElementById("checkout-vat-total");
    const grand = document.getElementById("checkout-grand-total");
    const change = document.getElementById("checkout-change-amount");
    const remaining = document.getElementById("checkout-remaining-amount");

    if (gross) gross.textContent = moneyTRY(totals.gross_total);
    if (vat) vat.textContent = moneyTRY(totals.vat_total);
    if (grand) grand.textContent = moneyTRY(totals.grand_total);
    if (change) change.textContent = moneyTRY(tender.change_amount);
    if (remaining) remaining.textContent = moneyTRY(tender.remaining_amount);
  }

  function renderCheckoutValidation(target, validation) {
    if (!target) return;

    if (validation.valid) {
      target.textContent = "Checkout payload geçerli. Gerçek ödeme/finalizasyon kapalı gate arkasında.";
      target.setAttribute("data-validation-status", "valid");
      target.hidden = false;
      return;
    }

    target.textContent = validation.errors.map(function (err) {
      return err.field + ":" + err.code;
    }).join(" / ");
    target.setAttribute("data-validation-status", "invalid");
    target.hidden = false;
  }

  function readCheckoutForm(form) {
    const data = {};
    new FormData(form).forEach(function (value, key) {
      data[key] = String(value || "").trim();
    });
    return data;
  }

  function recomputeFromForm(form) {
    const data = readCheckoutForm(form);
    const saleDraft = loadSaleDraft();
    const totals = calculateCartTotals(saleDraft.cart || []);
    const tender = calculateTender(String(data.payment_method || "CASH").toUpperCase(), totals.grand_total, data.tendered_amount);
    renderTotals(totals, tender);
    return { data: data, saleDraft: saleDraft, totals: totals, tender: tender };
  }

  function bootPOSCheckoutScreen() {
    const saleDraft = loadSaleDraft();
    const totals = calculateCartTotals(saleDraft.cart || []);
    const tender = calculateTender("CASH", totals.grand_total, totals.grand_total);

    renderCartReview(document.getElementById("checkout-cart-lines"), saleDraft);
    renderTotals(totals, tender);

    document.body.setAttribute("data-pos-checkout-rendered", "true");
    return buildCheckoutDraftPayload("CASH", totals.grand_total);
  }

  window.Pix2piPOSCheckout = {
    CONFIG: CONFIG,
    getSelectedTenantId: getSelectedTenantId,
    getOrCreateDeviceId: getOrCreateDeviceId,
    getCashierSession: getCashierSession,
    getCashierCode: getCashierCode,
    tenantDeviceCashierHeaders: tenantDeviceCashierHeaders,
    loadSaleDraft: loadSaleDraft,
    calculateCartTotals: calculateCartTotals,
    validatePaymentMethod: validatePaymentMethod,
    calculateTender: calculateTender,
    validateCheckoutPayload: validateCheckoutPayload,
    buildCheckoutDraftPayload: buildCheckoutDraftPayload,
    buildReceiptDraftPayload: buildReceiptDraftPayload,
    saveCheckoutDraft: saveCheckoutDraft,
    loadCheckoutDraft: loadCheckoutDraft,
    prepareCheckout: prepareCheckout,
    prepareReceiptDraft: prepareReceiptDraft,
    renderCartReview: renderCartReview,
    renderTotals: renderTotals,
    renderCheckoutValidation: renderCheckoutValidation,
    readCheckoutForm: readCheckoutForm,
    recomputeFromForm: recomputeFromForm,
    bootPOSCheckoutScreen: bootPOSCheckoutScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_332_POS_CHECKOUT_RUNTIME_END */
