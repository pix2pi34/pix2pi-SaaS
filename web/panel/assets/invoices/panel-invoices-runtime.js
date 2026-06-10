/* PIX2PI_344_PANEL_INVOICES_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "panel_invoices",
    phase: "FAZ_7R",
    step: "344",
    invoiceHistoryEndpoint: "/api/commercial/invoices/history",
    invoiceDetailEndpoint: "/api/commercial/invoices/detail",
    invoiceExportEndpoint: "/api/commercial/invoices/export",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    merchantSessionKey: "pix2pi.panel.merchant.session",
    invoiceFilterKey: "pix2pi.panel.invoices.filter",
    runtimeContract: {
      realInvoiceIssueEnabled: false,
      realInvoicePdfEnabled: false,
      realEbelgeSendEnabled: false,
      realAccountingExportEnabled: false,
      realReceiptGenerationEnabled: false,
      invoiceHistoryEnabled: true,
      fallbackInvoiceSnapshotEnabled: true,
      readyForStep345: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      merchant_session_id: "MERCHANT_DEMO_SESSION",
      billing_scope: "commercial-invoice-history",
      period: "2026-05",
      summary: {
        invoice_count: 4,
        draft_count: 2,
        paid_simulation_count: 1,
        total_subtotal: 3996,
        total_vat: 799.2,
        total_grand: 4795.2,
        currency: "TRY"
      },
      invoices: [
        {
          invoice_id: "inv-demo-344-001",
          invoice_no: "INV-DRAFT-343-DEMO",
          document_type: "SUBSCRIPTION_INVOICE_DRAFT",
          status: "DRAFT",
          payment_status: "PAYMENT_PENDING_DISABLED",
          period: "2026-05",
          issue_date: "pilot-disabled",
          plan_code: "small_business",
          subtotal: 999,
          vat_rate: 20,
          vat_total: 199.8,
          grand_total: 1198.8,
          currency: "TRY"
        },
        {
          invoice_id: "inv-demo-344-002",
          invoice_no: "INV-DRAFT-342-DEMO",
          document_type: "SUBSCRIPTION_INVOICE_DRAFT",
          status: "ISSUE_DISABLED",
          payment_status: "PAYMENT_DISABLED",
          period: "2026-04",
          issue_date: "pilot-disabled",
          plan_code: "pilot_free",
          subtotal: 0,
          vat_rate: 20,
          vat_total: 0,
          grand_total: 0,
          currency: "TRY"
        },
        {
          invoice_id: "inv-demo-344-003",
          invoice_no: "RCPT-PLACEHOLDER-001",
          document_type: "PAYMENT_RECEIPT_PLACEHOLDER",
          status: "PAID_SIMULATION",
          payment_status: "PAID_SIMULATION",
          period: "2026-03",
          issue_date: "simulation",
          plan_code: "small_business",
          subtotal: 999,
          vat_rate: 20,
          vat_total: 199.8,
          grand_total: 1198.8,
          currency: "TRY"
        },
        {
          invoice_id: "inv-demo-344-004",
          invoice_no: "INV-CANCELLED-SIM-001",
          document_type: "SUBSCRIPTION_INVOICE_DRAFT",
          status: "CANCELLED_SIMULATION",
          payment_status: "CANCELLED_SIMULATION",
          period: "2026-02",
          issue_date: "simulation",
          plan_code: "small_business",
          subtotal: 999,
          vat_rate: 20,
          vat_total: 199.8,
          grand_total: 1198.8,
          currency: "TRY"
        }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSnapshot.tenant_id;
  }

  function getMerchantSession() {
    const raw = window.localStorage.getItem(CONFIG.merchantSessionKey);
    if (!raw) {
      return {
        session_present: false,
        session_id: CONFIG.fallbackSnapshot.merchant_session_id,
        role: "OWNER"
      };
    }

    try {
      return Object.assign({ session_present: true }, JSON.parse(raw));
    } catch (_error) {
      return {
        session_present: false,
        session_id: "INVALID_MERCHANT_SESSION",
        role: "UNKNOWN"
      };
    }
  }

  function invoiceScopeHeaders() {
    const session = getMerchantSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Merchant-Session": session.session_id,
      "X-Invoice-Scope": "commercial-invoice-history",
      "X-Pix2pi-Surface": "merchant_panel_commercial",
      "X-Pix2pi-Step": "344"
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

  function loadInvoiceFilter() {
    const raw = window.localStorage.getItem(CONFIG.invoiceFilterKey);
    if (!raw) {
      return {
        status: "all",
        period: "all",
        payment_status: "all"
      };
    }

    try {
      return Object.assign({
        status: "all",
        period: "all",
        payment_status: "all"
      }, JSON.parse(raw));
    } catch (_error) {
      return {
        status: "all",
        period: "all",
        payment_status: "all"
      };
    }
  }

  function saveInvoiceFilter(filter) {
    window.localStorage.setItem(CONFIG.invoiceFilterKey, JSON.stringify(filter));
    return filter;
  }

  function validateInvoiceScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!snapshot || !snapshot.merchant_session_id) {
      errors.push({ field: "merchant_session_id", code: "MERCHANT_SESSION_REQUIRED" });
    }

    if (!snapshot || !Array.isArray(snapshot.invoices)) {
      errors.push({ field: "invoices", code: "INVOICE_LIST_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: invoiceScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("PANEL_INVOICE_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchInvoiceHistorySnapshot() {
    try {
      return await apiJson(CONFIG.invoiceHistoryEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      const session = getMerchantSession();
      snapshot.tenant_id = getTenantId();
      snapshot.merchant_session_id = session.session_id;
      return snapshot;
    }
  }

  function applyInvoiceFilters(invoices, filter) {
    const f = filter || loadInvoiceFilter();

    return (invoices || []).filter(function (invoice) {
      const statusOk = f.status === "all" || invoice.status === f.status;
      const periodOk = f.period === "all" || invoice.period === f.period;
      const paymentOk = f.payment_status === "all" || invoice.payment_status === f.payment_status;

      return statusOk && periodOk && paymentOk;
    });
  }

  function buildInvoiceDetailPreview(invoice) {
    return {
      invoice_id: invoice.invoice_id,
      invoice_no: invoice.invoice_no,
      document_type: invoice.document_type,
      status: invoice.status,
      payment_status: invoice.payment_status,
      period: invoice.period,
      issue_date: invoice.issue_date,
      plan_code: invoice.plan_code,
      subtotal_label: moneyTRY(invoice.subtotal),
      vat_label: moneyTRY(invoice.vat_total),
      grand_total_label: moneyTRY(invoice.grand_total),
      pdf_download_enabled: CONFIG.runtimeContract.realInvoicePdfEnabled,
      ebelge_send_enabled: CONFIG.runtimeContract.realEbelgeSendEnabled,
      accounting_export_enabled: CONFIG.runtimeContract.realAccountingExportEnabled,
      receipt_generation_enabled: CONFIG.runtimeContract.realReceiptGenerationEnabled,
      source: {
        surface: "panel_invoices",
        phase: "FAZ_7R",
        step: "344"
      }
    };
  }

  function buildInvoiceDisabledAction(action, invoiceId) {
    return {
      accepted: false,
      action: action,
      invoice_id: invoiceId,
      reason: "REAL_INVOICE_ACTION_DISABLED_IN_STEP_344",
      real_invoice_issue_enabled: CONFIG.runtimeContract.realInvoiceIssueEnabled,
      real_invoice_pdf_enabled: CONFIG.runtimeContract.realInvoicePdfEnabled,
      real_ebelge_send_enabled: CONFIG.runtimeContract.realEbelgeSendEnabled,
      real_accounting_export_enabled: CONFIG.runtimeContract.realAccountingExportEnabled,
      source: {
        surface: "panel_invoices",
        phase: "FAZ_7R",
        step: "344"
      }
    };
  }

  function buildInvoiceRuntimeContract(snapshot) {
    const filtered = applyInvoiceFilters(snapshot.invoices, loadInvoiceFilter());

    return {
      tenant_id: snapshot.tenant_id,
      merchant_session_id: snapshot.merchant_session_id,
      billing_scope: snapshot.billing_scope,
      invoice_count: snapshot.invoices.length,
      filtered_invoice_count: filtered.length,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateInvoiceScope(snapshot),
      source: {
        surface: "panel_invoices",
        phase: "FAZ_7R",
        step: "344"
      }
    };
  }

  function renderContext(snapshot) {
    const tenant = document.getElementById("invoices-tenant");
    const session = document.getElementById("invoices-merchant-session");
    const period = document.getElementById("invoices-period");
    const validation = document.getElementById("invoices-scope-validation");
    const contract = buildInvoiceRuntimeContract(snapshot);

    if (tenant) tenant.textContent = contract.tenant_id;
    if (session) session.textContent = contract.merchant_session_id;
    if (period) period.textContent = snapshot.period;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderSummary(snapshot) {
    const invoiceCount = document.getElementById("invoices-count");
    const draftCount = document.getElementById("invoices-draft-count");
    const subtotal = document.getElementById("invoices-total-subtotal");
    const vat = document.getElementById("invoices-total-vat");
    const grand = document.getElementById("invoices-total-grand");

    if (invoiceCount) invoiceCount.textContent = String(snapshot.summary.invoice_count);
    if (draftCount) draftCount.textContent = String(snapshot.summary.draft_count);
    if (subtotal) subtotal.textContent = moneyTRY(snapshot.summary.total_subtotal);
    if (vat) vat.textContent = moneyTRY(snapshot.summary.total_vat);
    if (grand) grand.textContent = moneyTRY(snapshot.summary.total_grand);
  }

  function readFiltersFromDOM() {
    const status = document.getElementById("invoice-status-filter");
    const period = document.getElementById("invoice-period-filter");
    const payment = document.getElementById("invoice-payment-filter");

    return {
      status: status ? status.value : "all",
      period: period ? period.value : "all",
      payment_status: payment ? payment.value : "all"
    };
  }

  function renderInvoiceList(snapshot) {
    const target = document.getElementById("invoice-list-table");
    if (!target) return;

    const filter = loadInvoiceFilter();
    const invoices = applyInvoiceFilters(snapshot.invoices, filter);

    target.innerHTML = "";

    invoices.forEach(function (invoice) {
      const row = document.createElement("article");
      row.className = "invoice-row";
      row.setAttribute("data-invoice-id", invoice.invoice_id);
      row.setAttribute("data-invoice-status", invoice.status);
      row.innerHTML = [
        "<div>",
        "<strong>" + invoice.invoice_no + "</strong>",
        "<p>" + invoice.document_type + " / " + invoice.period + " / " + invoice.plan_code + "</p>",
        "</div>",
        "<span class='status'>" + invoice.status + "</span>",
        "<span class='payment'>" + invoice.payment_status + "</span>",
        "<em>" + moneyTRY(invoice.grand_total) + "</em>",
        "<button type='button' data-preview-invoice='" + invoice.invoice_id + "'>Preview</button>"
      ].join("");

      row.querySelector("[data-preview-invoice]").addEventListener("click", function () {
        renderInvoiceDetailPreview(buildInvoiceDetailPreview(invoice));
      });

      target.appendChild(row);
    });
  }

  function renderInvoiceDetailPreview(preview) {
    const target = document.getElementById("invoice-detail-preview");
    if (!target) return;

    target.innerHTML = [
      "<strong>" + preview.invoice_no + "</strong>",
      "<p>Type: " + preview.document_type + " / Status: " + preview.status + " / Payment: " + preview.payment_status + "</p>",
      "<p>Period: " + preview.period + " / Plan: " + preview.plan_code + "</p>",
      "<p>Ara toplam: " + preview.subtotal_label + " / KDV: " + preview.vat_label + " / Genel toplam: " + preview.grand_total_label + "</p>",
      "<p>PDF enabled: false / e-Belge send enabled: false / Export enabled: false</p>"
    ].join("");
    target.setAttribute("data-preview-invoice-id", preview.invoice_id);
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("invoices-runtime-contract");
    if (!target) return;

    const contract = buildInvoiceRuntimeContract(snapshot);

    target.textContent = [
      "real_invoice_issue_enabled=" + CONFIG.runtimeContract.realInvoiceIssueEnabled,
      "real_invoice_pdf_enabled=" + CONFIG.runtimeContract.realInvoicePdfEnabled,
      "real_ebelge_send_enabled=" + CONFIG.runtimeContract.realEbelgeSendEnabled,
      "real_accounting_export_enabled=" + CONFIG.runtimeContract.realAccountingExportEnabled,
      "ready_for_step_345=" + CONFIG.runtimeContract.readyForStep345,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderInvoiceScreen(snapshot) {
    renderContext(snapshot);
    renderSummary(snapshot);
    renderInvoiceList(snapshot);
    if (snapshot.invoices && snapshot.invoices.length > 0) {
      renderInvoiceDetailPreview(buildInvoiceDetailPreview(snapshot.invoices[0]));
    }
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-panel-invoices-rendered", "true");
  }

  async function bootInvoiceScreen() {
    const snapshot = await fetchInvoiceHistorySnapshot();
    renderInvoiceScreen(snapshot);
    return buildInvoiceRuntimeContract(snapshot);
  }

  window.Pix2piPanelInvoices = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getMerchantSession: getMerchantSession,
    invoiceScopeHeaders: invoiceScopeHeaders,
    moneyTRY: moneyTRY,
    loadInvoiceFilter: loadInvoiceFilter,
    saveInvoiceFilter: saveInvoiceFilter,
    validateInvoiceScope: validateInvoiceScope,
    fetchInvoiceHistorySnapshot: fetchInvoiceHistorySnapshot,
    applyInvoiceFilters: applyInvoiceFilters,
    buildInvoiceDetailPreview: buildInvoiceDetailPreview,
    buildInvoiceDisabledAction: buildInvoiceDisabledAction,
    buildInvoiceRuntimeContract: buildInvoiceRuntimeContract,
    readFiltersFromDOM: readFiltersFromDOM,
    renderContext: renderContext,
    renderSummary: renderSummary,
    renderInvoiceList: renderInvoiceList,
    renderInvoiceDetailPreview: renderInvoiceDetailPreview,
    renderRuntimeContract: renderRuntimeContract,
    renderInvoiceScreen: renderInvoiceScreen,
    bootInvoiceScreen: bootInvoiceScreen
  };
})();
/* PIX2PI_344_PANEL_INVOICES_RUNTIME_END */
