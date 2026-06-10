/* PIX2PI_325_SALES_POS_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    salesSnapshotEndpoint: "/api/panel/sales/snapshot",
    posTerminalsEndpoint: "/api/panel/pos/terminals",
    shiftPolicyEndpoint: "/api/panel/pos/shift-policy",
    saleActionEndpoint: "/api/panel/sales/action",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    jwtKey: "pix2pi.panel.jwt",
    surface: "merchant_panel_sales_pos",
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      summary: {
        today_sales_total: 0,
        receipt_count: 0,
        average_basket: 0,
        return_count: 0
      },
      payment_methods: [
        { method: "cash", amount: 0 },
        { method: "card", amount: 0 },
        { method: "qr", amount: 0 }
      ],
      terminals: [
        {
          id: "pos-terminal-demo-1",
          name: "Ana Kasa",
          status: "READY_FOR_BINDING",
          cashier: "Demo Kasiyer",
          device_status: "NOT_CONNECTED"
        }
      ],
      recent_sales: [
        {
          id: "sale-demo-001",
          receipt_no: "RCPT-DEMO-001",
          amount: 0,
          payment_method: "cash",
          document_status: "DOCUMENT_NOT_CREATED",
          sale_status: "DRAFT"
        }
      ],
      shift_policy: {
        cash_open_required: true,
        cash_close_required: true,
        cashier_required: true,
        offline_ready_policy: "PHASE_333_READY_FOR_BINDING"
      },
      guards: {
        return_enabled: false,
        cancel_enabled: false,
        void_enabled: false,
        reason_required: true
      }
    }
  };

  function getSelectedTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || "controlled-pilot";
  }

  function getJwt() {
    return window.localStorage.getItem(CONFIG.jwtKey) || "";
  }

  function tenantScopedHeaders() {
    const token = getJwt();
    return {
      "Content-Type": "application/json",
      "Authorization": token ? "Bearer " + token : "",
      "X-Tenant-ID": getSelectedTenantId(),
      "X-Pix2pi-Surface": "panel",
      "X-Pix2pi-Step": "325"
    };
  }

  async function apiJson(endpoint, options) {
    const response = await fetch(endpoint, Object.assign({
      headers: tenantScopedHeaders()
    }, options || {}));

    if (!response.ok) {
      throw new Error("SALES_POS_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchSalesSnapshot() {
    try {
      return await apiJson(CONFIG.salesSnapshotEndpoint, { method: "GET" });
    } catch (_error) {
      return CONFIG.fallbackSnapshot;
    }
  }

  async function fetchPosTerminals() {
    try {
      return await apiJson(CONFIG.posTerminalsEndpoint, { method: "GET" });
    } catch (_error) {
      return {
        tenant_id: getSelectedTenantId(),
        terminals: CONFIG.fallbackSnapshot.terminals
      };
    }
  }

  async function fetchShiftPolicy() {
    try {
      return await apiJson(CONFIG.shiftPolicyEndpoint, { method: "GET" });
    } catch (_error) {
      return CONFIG.fallbackSnapshot.shift_policy;
    }
  }

  function buildSaleActionPayload(saleId, action, reason) {
    return {
      tenant_id: getSelectedTenantId(),
      sale_id: saleId,
      action: action,
      reason: reason || "",
      reason_required: true,
      source: "panel_sales_pos",
      phase: "FAZ_7R",
      step: "325"
    };
  }

  function validateSaleAction(action, reason) {
    const validActions = ["RETURN", "CANCEL", "VOID"];
    const errors = [];

    if (validActions.indexOf(action) === -1) {
      errors.push({ field: "action", code: "INVALID_ACTION" });
    }

    if (!reason) {
      errors.push({ field: "reason", code: "REASON_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function submitSaleAction(saleId, action, reason) {
    const validation = validateSaleAction(action, reason);
    const payload = buildSaleActionPayload(saleId, action, reason);

    if (!validation.valid) {
      return {
        submitted: false,
        validation: validation,
        payload: payload
      };
    }

    try {
      const response = await apiJson(CONFIG.saleActionEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });

      return {
        submitted: true,
        validation: validation,
        response: response
      };
    } catch (_error) {
      return {
        submitted: false,
        validation: validation,
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

  function setText(id, value) {
    const el = document.getElementById(id);
    if (el) {
      el.textContent = value;
    }
  }

  function renderPaymentMethods(target, methods) {
    if (!target) return;

    target.innerHTML = "";

    (methods || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "mini-row";
      row.setAttribute("data-payment-method", item.method);
      row.innerHTML = "<strong>" + item.method.toUpperCase() + "</strong><span>" + moneyTRY(item.amount) + "</span>";
      target.appendChild(row);
    });
  }

  function renderTerminals(target, terminals) {
    if (!target) return;

    target.innerHTML = "";

    (terminals || []).forEach(function (terminal) {
      const row = document.createElement("article");
      row.className = "mini-row";
      row.setAttribute("data-terminal-id", terminal.id);
      row.setAttribute("data-terminal-status", terminal.status);
      row.innerHTML = [
        "<div>",
        "<strong>" + terminal.name + "</strong>",
        "<p>" + terminal.cashier + " / " + terminal.device_status + "</p>",
        "</div>",
        "<span class='pill'>" + terminal.status + "</span>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRecentSales(target, sales) {
    if (!target) return;

    target.innerHTML = "";

    (sales || []).forEach(function (sale) {
      const row = document.createElement("article");
      row.className = "sale-row";
      row.setAttribute("data-sale-id", sale.id);
      row.setAttribute("data-sale-status", sale.sale_status);
      row.innerHTML = [
        "<div>",
        "<strong>" + sale.receipt_no + "</strong>",
        "<p>" + sale.payment_method + " / " + sale.document_status + "</p>",
        "</div>",
        "<span class='pill'>" + sale.sale_status + "</span>",
        "<strong>" + moneyTRY(sale.amount) + "</strong>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderShiftPolicy(target, policy) {
    if (!target) return;

    target.textContent = [
      "Kasa açılış zorunlu: " + String(Boolean(policy.cash_open_required)),
      "Kasa kapanış zorunlu: " + String(Boolean(policy.cash_close_required)),
      "Kasiyer zorunlu: " + String(Boolean(policy.cashier_required)),
      "Offline policy: " + policy.offline_ready_policy
    ].join(" / ");
  }

  function renderSalesSnapshot(snapshot) {
    setText("sales-today-total", moneyTRY(snapshot.summary.today_sales_total));
    setText("sales-receipt-count", String(snapshot.summary.receipt_count));
    setText("sales-average-basket", moneyTRY(snapshot.summary.average_basket));
    setText("sales-return-count", String(snapshot.summary.return_count));

    renderPaymentMethods(document.getElementById("payment-method-summary"), snapshot.payment_methods);
    renderTerminals(document.getElementById("pos-terminal-list"), snapshot.terminals);
    renderRecentSales(document.getElementById("recent-sales-list"), snapshot.recent_sales);
    renderShiftPolicy(document.getElementById("shift-policy-summary"), snapshot.shift_policy);

    document.body.setAttribute("data-sales-pos-rendered", "true");
    return snapshot;
  }

  async function bootSalesPosScreen() {
    const snapshot = await fetchSalesSnapshot();
    return renderSalesSnapshot(snapshot);
  }

  window.Pix2piSalesPOS = {
    CONFIG: CONFIG,
    getSelectedTenantId: getSelectedTenantId,
    getJwt: getJwt,
    tenantScopedHeaders: tenantScopedHeaders,
    fetchSalesSnapshot: fetchSalesSnapshot,
    fetchPosTerminals: fetchPosTerminals,
    fetchShiftPolicy: fetchShiftPolicy,
    buildSaleActionPayload: buildSaleActionPayload,
    validateSaleAction: validateSaleAction,
    submitSaleAction: submitSaleAction,
    renderPaymentMethods: renderPaymentMethods,
    renderTerminals: renderTerminals,
    renderRecentSales: renderRecentSales,
    renderShiftPolicy: renderShiftPolicy,
    renderSalesSnapshot: renderSalesSnapshot,
    bootSalesPosScreen: bootSalesPosScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_325_SALES_POS_RUNTIME_END */
