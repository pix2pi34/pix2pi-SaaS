/* PIX2PI_343_PANEL_BILLING_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "panel_billing",
    phase: "FAZ_7R",
    step: "343",
    billingSummaryEndpoint: "/api/commercial/billing/summary",
    invoiceDraftEndpoint: "/api/commercial/billing/invoice-draft",
    paymentAttemptEndpoint: "/api/commercial/billing/payment-attempt",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    merchantSessionKey: "pix2pi.panel.merchant.session",
    runtimeContract: {
      realPaymentCollectionEnabled: false,
      realCardStorageEnabled: false,
      realProviderTransactionEnabled: false,
      realInvoiceIssueEnabled: false,
      realSubscriptionActivationEnabled: false,
      billingSummaryEnabled: true,
      fallbackBillingSnapshotEnabled: true,
      readyForStep344: true
    },
    approvalGates: {
      financialApprovalRequired: true,
      taxConsultantApprovalRequired: true,
      legalApprovalRequired: true,
      paymentProviderContractRequired: true,
      livePaymentAllowed: false
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      merchant_session_id: "MERCHANT_DEMO_SESSION",
      subscription: {
        plan_code: "small_business",
        plan_name: "Small Business",
        billing_cycle: "monthly",
        status: "DRAFT_NOT_COLLECTING",
        next_invoice_date: "pilot-disabled"
      },
      pricing: {
        currency: "TRY",
        subtotal: 999,
        vat_rate: 20,
        vat_total: 199.8,
        discount_total: 0,
        grand_total: 1198.8
      },
      payment_method: {
        method_type: "CARD_PLACEHOLDER",
        card_storage_enabled: false,
        provider_token: null,
        provider: "SIMULATION_ONLY"
      },
      invoice_draft: {
        draft_no: "INV-DRAFT-343-DEMO",
        title: "Pix2pi Small Business abonelik taslağı",
        lines: [
          { code: "PLAN_SMALL_BUSINESS", description: "Small Business aylık kullanım bedeli", quantity: 1, unit_price: 999, vat_rate: 20 }
        ],
        issue_enabled: false
      },
      approval_statuses: [
        { code: "FINANCIAL_APPROVAL", label: "Finans onayı", status: "REQUIRED" },
        { code: "TAX_CONSULTANT_APPROVAL", label: "Vergi / mali müşavir onayı", status: "REQUIRED" },
        { code: "LEGAL_APPROVAL", label: "Hukuk / sözleşme onayı", status: "REQUIRED" },
        { code: "PAYMENT_PROVIDER_CONTRACT", label: "Ödeme sağlayıcı sözleşmesi", status: "REQUIRED" }
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

  function billingScopeHeaders() {
    const session = getMerchantSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Merchant-Session": session.session_id,
      "X-Billing-Scope": "commercial-billing",
      "X-Pix2pi-Surface": "merchant_panel_commercial",
      "X-Pix2pi-Step": "343"
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

  function calculateVatBreakdown(subtotal, vatRate, discountTotal) {
    const netSubtotal = Math.max(0, Number(subtotal || 0) - Number(discountTotal || 0));
    const vatTotal = netSubtotal * Number(vatRate || 0) / 100;
    const grandTotal = netSubtotal + vatTotal;

    return {
      subtotal: Number(subtotal || 0),
      discount_total: Number(discountTotal || 0),
      net_subtotal: netSubtotal,
      vat_rate: Number(vatRate || 0),
      vat_total: vatTotal,
      grand_total: grandTotal,
      currency: "TRY"
    };
  }

  function validateBillingScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!snapshot || !snapshot.merchant_session_id) {
      errors.push({ field: "merchant_session_id", code: "MERCHANT_SESSION_REQUIRED" });
    }

    if (!snapshot || !snapshot.subscription || !snapshot.subscription.plan_code) {
      errors.push({ field: "subscription.plan_code", code: "PLAN_REQUIRED" });
    }

    if (!snapshot || !snapshot.invoice_draft || !snapshot.invoice_draft.draft_no) {
      errors.push({ field: "invoice_draft.draft_no", code: "INVOICE_DRAFT_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: billingScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("PANEL_BILLING_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchBillingSnapshot() {
    try {
      return await apiJson(CONFIG.billingSummaryEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      const session = getMerchantSession();
      snapshot.tenant_id = getTenantId();
      snapshot.merchant_session_id = session.session_id;
      snapshot.pricing = calculateVatBreakdown(
        snapshot.pricing.subtotal,
        snapshot.pricing.vat_rate,
        snapshot.pricing.discount_total
      );
      return snapshot;
    }
  }

  function buildInvoiceDraftPreview(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      draft_no: snapshot.invoice_draft.draft_no,
      title: snapshot.invoice_draft.title,
      line_count: Array.isArray(snapshot.invoice_draft.lines) ? snapshot.invoice_draft.lines.length : 0,
      issue_enabled: CONFIG.runtimeContract.realInvoiceIssueEnabled,
      pricing: snapshot.pricing,
      source: {
        surface: "panel_billing",
        phase: "FAZ_7R",
        step: "343"
      }
    };
  }

  function buildPaymentAttemptDisabledGuard(snapshot) {
    return {
      accepted: false,
      tenant_id: snapshot.tenant_id,
      plan_code: snapshot.subscription.plan_code,
      amount: snapshot.pricing.grand_total,
      currency: snapshot.pricing.currency,
      reason: "REAL_PAYMENT_COLLECTION_DISABLED_IN_STEP_343",
      real_payment_collection_enabled: CONFIG.runtimeContract.realPaymentCollectionEnabled,
      real_card_storage_enabled: CONFIG.runtimeContract.realCardStorageEnabled,
      real_provider_transaction_enabled: CONFIG.runtimeContract.realProviderTransactionEnabled,
      real_invoice_issue_enabled: CONFIG.runtimeContract.realInvoiceIssueEnabled,
      source: {
        surface: "panel_billing",
        phase: "FAZ_7R",
        step: "343"
      }
    };
  }

  function buildBillingRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      merchant_session_id: snapshot.merchant_session_id,
      plan_code: snapshot.subscription.plan_code,
      billing_cycle: snapshot.subscription.billing_cycle,
      subscription_status: snapshot.subscription.status,
      runtime_contract: CONFIG.runtimeContract,
      approval_gates: CONFIG.approvalGates,
      scope_validation: validateBillingScope(snapshot),
      source: {
        surface: "panel_billing",
        phase: "FAZ_7R",
        step: "343"
      }
    };
  }

  function renderContext(snapshot) {
    const tenant = document.getElementById("billing-tenant");
    const session = document.getElementById("billing-merchant-session");
    const subscription = document.getElementById("billing-subscription");
    const validation = document.getElementById("billing-scope-validation");
    const contract = buildBillingRuntimeContract(snapshot);

    if (tenant) tenant.textContent = contract.tenant_id;
    if (session) session.textContent = contract.merchant_session_id;
    if (subscription) subscription.textContent = snapshot.subscription.plan_name + " / " + snapshot.subscription.status;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderBillingSummary(snapshot) {
    const subtotal = document.getElementById("billing-subtotal");
    const discount = document.getElementById("billing-discount");
    const vat = document.getElementById("billing-vat-total");
    const grand = document.getElementById("billing-grand-total");

    if (subtotal) subtotal.textContent = moneyTRY(snapshot.pricing.subtotal);
    if (discount) discount.textContent = moneyTRY(snapshot.pricing.discount_total);
    if (vat) vat.textContent = moneyTRY(snapshot.pricing.vat_total);
    if (grand) grand.textContent = moneyTRY(snapshot.pricing.grand_total);
  }

  function renderPaymentMethod(snapshot) {
    const type = document.getElementById("billing-payment-method");
    const provider = document.getElementById("billing-provider");
    const token = document.getElementById("billing-provider-token");

    if (type) type.textContent = snapshot.payment_method.method_type;
    if (provider) provider.textContent = snapshot.payment_method.provider;
    if (token) token.textContent = snapshot.payment_method.provider_token || "null";
  }

  function renderInvoiceDraft(snapshot) {
    const draftNo = document.getElementById("billing-invoice-draft-no");
    const title = document.getElementById("billing-invoice-title");
    const lines = document.getElementById("billing-invoice-lines");
    const preview = buildInvoiceDraftPreview(snapshot);

    if (draftNo) draftNo.textContent = preview.draft_no;
    if (title) title.textContent = preview.title;

    if (lines) {
      lines.innerHTML = "";
      (snapshot.invoice_draft.lines || []).forEach(function (line) {
        const row = document.createElement("article");
        row.className = "billing-line";
        row.setAttribute("data-line-code", line.code);
        row.innerHTML = [
          "<strong>" + line.description + "</strong>",
          "<p>" + line.quantity + " × " + moneyTRY(line.unit_price) + " / KDV %" + line.vat_rate + "</p>"
        ].join("");
        lines.appendChild(row);
      });
    }
  }

  function renderApprovalGates(snapshot) {
    const target = document.getElementById("billing-approval-gates");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.approval_statuses || []).forEach(function (gate) {
      const item = document.createElement("article");
      item.className = "approval-gate";
      item.setAttribute("data-gate-code", gate.code);
      item.setAttribute("data-gate-status", gate.status);
      item.innerHTML = [
        "<strong>" + gate.label + "</strong>",
        "<p>Status: " + gate.status + "</p>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("billing-runtime-contract");
    if (!target) return;

    const contract = buildBillingRuntimeContract(snapshot);

    target.textContent = [
      "real_payment_collection_enabled=" + CONFIG.runtimeContract.realPaymentCollectionEnabled,
      "real_card_storage_enabled=" + CONFIG.runtimeContract.realCardStorageEnabled,
      "real_provider_transaction_enabled=" + CONFIG.runtimeContract.realProviderTransactionEnabled,
      "real_invoice_issue_enabled=" + CONFIG.runtimeContract.realInvoiceIssueEnabled,
      "ready_for_step_344=" + CONFIG.runtimeContract.readyForStep344,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderBillingScreen(snapshot) {
    renderContext(snapshot);
    renderBillingSummary(snapshot);
    renderPaymentMethod(snapshot);
    renderInvoiceDraft(snapshot);
    renderApprovalGates(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-panel-billing-rendered", "true");
  }

  async function bootBillingScreen() {
    const snapshot = await fetchBillingSnapshot();
    renderBillingScreen(snapshot);
    return buildBillingRuntimeContract(snapshot);
  }

  window.Pix2piPanelBilling = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getMerchantSession: getMerchantSession,
    billingScopeHeaders: billingScopeHeaders,
    moneyTRY: moneyTRY,
    calculateVatBreakdown: calculateVatBreakdown,
    validateBillingScope: validateBillingScope,
    fetchBillingSnapshot: fetchBillingSnapshot,
    buildInvoiceDraftPreview: buildInvoiceDraftPreview,
    buildPaymentAttemptDisabledGuard: buildPaymentAttemptDisabledGuard,
    buildBillingRuntimeContract: buildBillingRuntimeContract,
    renderContext: renderContext,
    renderBillingSummary: renderBillingSummary,
    renderPaymentMethod: renderPaymentMethod,
    renderInvoiceDraft: renderInvoiceDraft,
    renderApprovalGates: renderApprovalGates,
    renderRuntimeContract: renderRuntimeContract,
    renderBillingScreen: renderBillingScreen,
    bootBillingScreen: bootBillingScreen
  };
})();
/* PIX2PI_343_PANEL_BILLING_RUNTIME_END */
