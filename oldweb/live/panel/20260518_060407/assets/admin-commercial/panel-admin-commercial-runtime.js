/* PIX2PI_345_PANEL_ADMIN_COMMERCIAL_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "panel_admin_commercial",
    phase: "FAZ_7R",
    step: "345",
    commercialAdminSnapshotEndpoint: "/api/admin/commercial/snapshot",
    tenantSubscriptionAdminEndpoint: "/api/admin/commercial/tenant-subscriptions",
    billingApprovalEndpoint: "/api/admin/commercial/billing-approvals",
    adminSessionKey: "pix2pi.panel.admin.session",
    selectedTenantKey: "pix2pi.panel.admin.selected_tenant",
    runtimeContract: {
      realManualOverrideEnabled: false,
      realTenantSuspendResumeEnabled: false,
      realSubscriptionMutationEnabled: false,
      realPaymentProviderLiveEnabled: false,
      realExportReportEnabled: false,
      adminSnapshotEnabled: true,
      fallbackAdminCommercialSnapshotEnabled: true,
      readyForStep346: true
    },
    approvalGates: {
      financialApprovalRequired: true,
      taxConsultantApprovalRequired: true,
      legalApprovalRequired: true,
      paymentProviderContractRequired: true,
      productionLiveCommercialAllowed: false
    },
    fallbackSnapshot: {
      admin_session_id: "ADMIN_DEMO_SESSION",
      admin_role: "COMMERCIAL_ADMIN_READONLY",
      selected_tenant_id: "controlled-pilot",
      commercial_scope: "platform-admin-commercial",
      kpis: {
        active_subscriptions: 1,
        trial_tenants: 3,
        suspended_tenants: 0,
        draft_invoices: 4,
        mrr_simulation: 999,
        approval_queue_count: 4
      },
      tenant_overview: [
        {
          tenant_id: "controlled-pilot",
          business_name: "Demo Market",
          plan_code: "pilot_free",
          subscription_status: "TRIALING",
          billing_status: "DRAFT_NOT_COLLECTING",
          risk_level: "LOW",
          commercial_gate: "CONTROLLED_PILOT"
        },
        {
          tenant_id: "tenant-small-business-demo",
          business_name: "Small Business Demo",
          plan_code: "small_business",
          subscription_status: "ACTIVE_SIMULATION",
          billing_status: "PAYMENT_DISABLED",
          risk_level: "MEDIUM",
          commercial_gate: "BILLING_APPROVAL_REQUIRED"
        }
      ],
      plan_catalog_preview: [
        { code: "pilot_free", name: "Pilot Free", price_monthly: 0, visible: true, mutation_enabled: false },
        { code: "small_business", name: "Small Business", price_monthly: 999, visible: true, mutation_enabled: false },
        { code: "growth", name: "Growth", price_monthly: 2999, visible: true, mutation_enabled: false },
        { code: "enterprise", name: "Enterprise", price_monthly: null, visible: true, mutation_enabled: false }
      ],
      billing_approval_queue: [
        { id: "appr-fin-001", type: "FINANCIAL_APPROVAL", status: "REQUIRED", owner: "finance" },
        { id: "appr-tax-001", type: "TAX_CONSULTANT_APPROVAL", status: "REQUIRED", owner: "tax" },
        { id: "appr-legal-001", type: "LEGAL_APPROVAL", status: "REQUIRED", owner: "legal" },
        { id: "appr-provider-001", type: "PAYMENT_PROVIDER_CONTRACT", status: "REQUIRED", owner: "ops" }
      ],
      payment_provider_gates: [
        { provider: "SIMULATION", mode: "SIMULATION", status: "OPEN_FOR_TEST", live_allowed: false },
        { provider: "SANDBOX_PROVIDER", mode: "SANDBOX", status: "CONTRACT_REQUIRED", live_allowed: false },
        { provider: "PRODUCTION_PROVIDER", mode: "PRODUCTION", status: "CLOSED", live_allowed: false }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "PLAN_SCREEN_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "QUOTA_SCREEN_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "BILLING_SCREEN_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "INVOICE_HISTORY_READY", result: "PASS" }
      ]
    }
  };

  function getAdminSession() {
    const raw = window.localStorage.getItem(CONFIG.adminSessionKey);
    if (!raw) {
      return {
        session_present: false,
        session_id: CONFIG.fallbackSnapshot.admin_session_id,
        role: CONFIG.fallbackSnapshot.admin_role
      };
    }

    try {
      return Object.assign({ session_present: true }, JSON.parse(raw));
    } catch (_error) {
      return {
        session_present: false,
        session_id: "INVALID_ADMIN_SESSION",
        role: "UNKNOWN"
      };
    }
  }

  function getSelectedTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSnapshot.selected_tenant_id;
  }

  function adminCommercialScopeHeaders() {
    const session = getAdminSession();

    return {
      "Content-Type": "application/json",
      "X-Admin-Session": session.session_id,
      "X-Tenant-ID": getSelectedTenantId(),
      "X-Commercial-Scope": "platform-admin-commercial",
      "X-Pix2pi-Surface": "platform_admin_commercial",
      "X-Pix2pi-Step": "345"
    };
  }

  function moneyTRY(value) {
    if (value === null || value === undefined) return "Teklif";
    try {
      return new Intl.NumberFormat("tr-TR", {
        style: "currency",
        currency: "TRY",
        maximumFractionDigits: 0
      }).format(Number(value || 0));
    } catch (_error) {
      return String(value || 0) + " TL";
    }
  }

  function validateAdminCommercialScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.admin_session_id) {
      errors.push({ field: "admin_session_id", code: "ADMIN_SESSION_REQUIRED" });
    }

    if (!snapshot || !snapshot.admin_role) {
      errors.push({ field: "admin_role", code: "ADMIN_ROLE_REQUIRED" });
    }

    if (!snapshot || !snapshot.selected_tenant_id) {
      errors.push({ field: "selected_tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!snapshot || !snapshot.commercial_scope) {
      errors.push({ field: "commercial_scope", code: "COMMERCIAL_SCOPE_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: adminCommercialScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("ADMIN_COMMERCIAL_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchAdminCommercialSnapshot() {
    try {
      return await apiJson(CONFIG.commercialAdminSnapshotEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      const session = getAdminSession();
      snapshot.admin_session_id = session.session_id;
      snapshot.admin_role = session.role || snapshot.admin_role;
      snapshot.selected_tenant_id = getSelectedTenantId();
      return snapshot;
    }
  }

  function buildAdminCommercialRuntimeContract(snapshot) {
    return {
      admin_session_id: snapshot.admin_session_id,
      admin_role: snapshot.admin_role,
      selected_tenant_id: snapshot.selected_tenant_id,
      commercial_scope: snapshot.commercial_scope,
      tenant_count: Array.isArray(snapshot.tenant_overview) ? snapshot.tenant_overview.length : 0,
      approval_queue_count: Array.isArray(snapshot.billing_approval_queue) ? snapshot.billing_approval_queue.length : 0,
      runtime_contract: CONFIG.runtimeContract,
      approval_gates: CONFIG.approvalGates,
      scope_validation: validateAdminCommercialScope(snapshot),
      source: {
        surface: "panel_admin_commercial",
        phase: "FAZ_7R",
        step: "345"
      }
    };
  }

  function buildCommercialOverrideDisabledGuard(action, payload) {
    return {
      accepted: false,
      action: action,
      reason: "REAL_COMMERCIAL_ADMIN_MUTATION_DISABLED_IN_STEP_345",
      real_manual_override_enabled: CONFIG.runtimeContract.realManualOverrideEnabled,
      real_tenant_suspend_resume_enabled: CONFIG.runtimeContract.realTenantSuspendResumeEnabled,
      real_subscription_mutation_enabled: CONFIG.runtimeContract.realSubscriptionMutationEnabled,
      real_payment_provider_live_enabled: CONFIG.runtimeContract.realPaymentProviderLiveEnabled,
      payload: payload || null,
      source: {
        surface: "panel_admin_commercial",
        phase: "FAZ_7R",
        step: "345"
      }
    };
  }

  function renderAdminContext(snapshot) {
    const session = document.getElementById("admin-commercial-session");
    const role = document.getElementById("admin-commercial-role");
    const tenant = document.getElementById("admin-commercial-selected-tenant");
    const validation = document.getElementById("admin-commercial-scope-validation");
    const contract = buildAdminCommercialRuntimeContract(snapshot);

    if (session) session.textContent = snapshot.admin_session_id;
    if (role) role.textContent = snapshot.admin_role;
    if (tenant) tenant.textContent = snapshot.selected_tenant_id;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderKpis(snapshot) {
    const map = {
      "admin-commercial-active-subscriptions": snapshot.kpis.active_subscriptions,
      "admin-commercial-trial-tenants": snapshot.kpis.trial_tenants,
      "admin-commercial-suspended-tenants": snapshot.kpis.suspended_tenants,
      "admin-commercial-draft-invoices": snapshot.kpis.draft_invoices,
      "admin-commercial-mrr-simulation": moneyTRY(snapshot.kpis.mrr_simulation),
      "admin-commercial-approval-queue-count": snapshot.kpis.approval_queue_count
    };

    Object.keys(map).forEach(function (id) {
      const el = document.getElementById(id);
      if (el) el.textContent = String(map[id]);
    });
  }

  function renderTenantOverview(snapshot) {
    const target = document.getElementById("admin-commercial-tenant-overview");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.tenant_overview || []).forEach(function (tenant) {
      const row = document.createElement("article");
      row.className = "admin-commercial-row";
      row.setAttribute("data-tenant-id", tenant.tenant_id);
      row.innerHTML = [
        "<div>",
        "<strong>" + tenant.business_name + "</strong>",
        "<p>" + tenant.tenant_id + " / " + tenant.plan_code + " / " + tenant.commercial_gate + "</p>",
        "</div>",
        "<span>" + tenant.subscription_status + "</span>",
        "<span>" + tenant.billing_status + "</span>",
        "<em>" + tenant.risk_level + "</em>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderPlanCatalogPreview(snapshot) {
    const target = document.getElementById("admin-commercial-plan-catalog");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.plan_catalog_preview || []).forEach(function (plan) {
      const card = document.createElement("article");
      card.className = "admin-commercial-card";
      card.setAttribute("data-plan-code", plan.code);
      card.innerHTML = [
        "<strong>" + plan.name + "</strong>",
        "<p>Code: " + plan.code + " / Visible: " + plan.visible + "</p>",
        "<em>" + moneyTRY(plan.price_monthly) + "</em>",
        "<button type='button' disabled>Plan yönetimi kapalı</button>"
      ].join("");
      target.appendChild(card);
    });
  }

  function renderBillingApprovalQueue(snapshot) {
    const target = document.getElementById("admin-commercial-approval-queue");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.billing_approval_queue || []).forEach(function (approval) {
      const item = document.createElement("article");
      item.className = "admin-commercial-card";
      item.setAttribute("data-approval-id", approval.id);
      item.innerHTML = [
        "<strong>" + approval.type + "</strong>",
        "<p>Status: " + approval.status + " / Owner: " + approval.owner + "</p>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderPaymentProviderGates(snapshot) {
    const target = document.getElementById("admin-commercial-provider-gates");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.payment_provider_gates || []).forEach(function (gate) {
      const item = document.createElement("article");
      item.className = "admin-commercial-card";
      item.setAttribute("data-provider", gate.provider);
      item.innerHTML = [
        "<strong>" + gate.provider + "</strong>",
        "<p>Mode: " + gate.mode + " / Status: " + gate.status + " / Live allowed: " + gate.live_allowed + "</p>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderAuditTimeline(snapshot) {
    const target = document.getElementById("admin-commercial-audit-timeline");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.audit_timeline || []).forEach(function (event) {
      const item = document.createElement("article");
      item.className = "admin-commercial-card";
      item.setAttribute("data-audit-action", event.action);
      item.innerHTML = [
        "<strong>" + event.action + "</strong>",
        "<p>" + event.at + " / " + event.actor + " / " + event.result + "</p>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("admin-commercial-runtime-contract");
    if (!target) return;

    const contract = buildAdminCommercialRuntimeContract(snapshot);

    target.textContent = [
      "real_manual_override_enabled=" + CONFIG.runtimeContract.realManualOverrideEnabled,
      "real_tenant_suspend_resume_enabled=" + CONFIG.runtimeContract.realTenantSuspendResumeEnabled,
      "real_subscription_mutation_enabled=" + CONFIG.runtimeContract.realSubscriptionMutationEnabled,
      "real_payment_provider_live_enabled=" + CONFIG.runtimeContract.realPaymentProviderLiveEnabled,
      "real_export_report_enabled=" + CONFIG.runtimeContract.realExportReportEnabled,
      "ready_for_step_346=" + CONFIG.runtimeContract.readyForStep346,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderAdminCommercialScreen(snapshot) {
    renderAdminContext(snapshot);
    renderKpis(snapshot);
    renderTenantOverview(snapshot);
    renderPlanCatalogPreview(snapshot);
    renderBillingApprovalQueue(snapshot);
    renderPaymentProviderGates(snapshot);
    renderAuditTimeline(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-panel-admin-commercial-rendered", "true");
  }

  async function bootAdminCommercialScreen() {
    const snapshot = await fetchAdminCommercialSnapshot();
    renderAdminCommercialScreen(snapshot);
    return buildAdminCommercialRuntimeContract(snapshot);
  }

  window.Pix2piPanelAdminCommercial = {
    CONFIG: CONFIG,
    getAdminSession: getAdminSession,
    getSelectedTenantId: getSelectedTenantId,
    adminCommercialScopeHeaders: adminCommercialScopeHeaders,
    validateAdminCommercialScope: validateAdminCommercialScope,
    fetchAdminCommercialSnapshot: fetchAdminCommercialSnapshot,
    buildAdminCommercialRuntimeContract: buildAdminCommercialRuntimeContract,
    buildCommercialOverrideDisabledGuard: buildCommercialOverrideDisabledGuard,
    renderAdminContext: renderAdminContext,
    renderKpis: renderKpis,
    renderTenantOverview: renderTenantOverview,
    renderPlanCatalogPreview: renderPlanCatalogPreview,
    renderBillingApprovalQueue: renderBillingApprovalQueue,
    renderPaymentProviderGates: renderPaymentProviderGates,
    renderAuditTimeline: renderAuditTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderAdminCommercialScreen: renderAdminCommercialScreen,
    bootAdminCommercialScreen: bootAdminCommercialScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_345_PANEL_ADMIN_COMMERCIAL_RUNTIME_END */
