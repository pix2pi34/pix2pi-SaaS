/* PIX2PI_355_FIRST_REAL_USAGE_SMOKE_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "first_real_usage_smoke",
    phase: "FAZ_7R",
    step: "355",
    firstUsageSnapshotEndpoint: "/api/customer-access/first-usage/snapshot",
    firstUsageDecisionEndpoint: "/api/customer-access/first-usage/decision",
    firstUsageAuditEndpoint: "/api/customer-access/first-usage/audit",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    userSessionKey: "pix2pi.panel.user.session",
    runtimeContract: {
      realCustomerGoLiveEnabled: false,
      realSaleEnabled: false,
      realPaymentEnabled: false,
      realInvoiceIssueEnabled: false,
      realStockDecrementEnabled: false,
      realDataMutationEnabled: false,
      firstUsageSmokePreviewEnabled: true,
      customerJourneyPreviewEnabled: true,
      rollbackStopCriteriaPreviewEnabled: true,
      fallbackFirstUsageSnapshotEnabled: true,
      readyForStep356: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      owner_user: "owner@example.invalid",
      owner_role: "OWNER_ADMIN",
      user_session_id: "USER_DEMO_SESSION",
      store_id: "demo-market-main",
      register_id: "register-001",
      language: "tr-TR",
      first_usage_scope: "controlled-first-real-usage-smoke",
      correlation_id: "FAZ7R-355-DEMO-CORRELATION",
      dependencies: [
        { step: "349", name: "password_login", status: "PASS" },
        { step: "350", name: "panel_access", status: "PASS" },
        { step: "351", name: "pos_access", status: "PASS" },
        { step: "352", name: "tenant_isolation", status: "PASS" },
        { step: "353", name: "user_permission", status: "PASS" },
        { step: "354", name: "localization_customer_smoke", status: "PASS" }
      ],
      journey: [
        { code: "PANEL_LOGIN_ACCESS", label: "Panel login + access chain", surface: "panel", decision: "PASS_PREVIEW" },
        { code: "TENANT_ISOLATION_GATE", label: "Tenant isolation gate", surface: "panel", decision: "PASS_PREVIEW" },
        { code: "USER_PERMISSION_GATE", label: "User permission gate", surface: "panel", decision: "PASS_PREVIEW" },
        { code: "LOCALIZATION_GATE", label: "Localization customer smoke", surface: "panel", decision: "PASS_PREVIEW" },
        { code: "POS_ACCESS_CHAIN", label: "POS access chain", surface: "pos", decision: "PASS_PREVIEW" },
        { code: "MARKET_STOREFRONT", label: "Marketplace/storefront availability", surface: "market", decision: "PASS_PREVIEW" },
        { code: "PRODUCT_STOCK_READ", label: "Product / stock read smoke", surface: "panel", decision: "PASS_PREVIEW" },
        { code: "CART_PAYMENT_DRY_RUN", label: "Cart / payment dry-run", surface: "pos", decision: "DRY_RUN_ONLY" },
        { code: "INVOICE_BILLING_DISABLED", label: "Invoice / billing disabled gate", surface: "panel", decision: "DISABLED_EXPECTED" }
      ],
      safety_guards: [
        { code: "REAL_CUSTOMER_GO_LIVE_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_SALE_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_PAYMENT_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_INVOICE_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_STOCK_DECREMENT_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_DATA_MUTATION_DISABLED", status: "ENFORCED", value: false }
      ],
      rollback_stop_criteria: [
        { severity: "P1", code: "TENANT_ISOLATION_FAIL", action: "STOP_GO_LIVE", status: "READY" },
        { severity: "P1", code: "AUTH_PERMISSION_FAIL", action: "STOP_GO_LIVE", status: "READY" },
        { severity: "P1", code: "PAYMENT_MUTATION_UNEXPECTED", action: "STOP_GO_LIVE", status: "READY" },
        { severity: "P2", code: "LOCALIZATION_BLOCKER", action: "FIX_BEFORE_GO_LIVE", status: "READY" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "LOCALIZATION_CUSTOMER_SMOKE_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "FIRST_REAL_USAGE_SMOKE_READY", result: "DRY_RUN" },
        { at: "2026-05-demo", actor: "system", action: "DATA_MUTATION_DISABLED", result: "EXPECTED" }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSnapshot.tenant_id;
  }

  function getUserSession() {
    const raw = window.localStorage.getItem(CONFIG.userSessionKey);
    if (!raw) {
      return {
        session_present: false,
        session_id: CONFIG.fallbackSnapshot.user_session_id,
        email: CONFIG.fallbackSnapshot.owner_user,
        role: CONFIG.fallbackSnapshot.owner_role
      };
    }

    try {
      return Object.assign({ session_present: true }, JSON.parse(raw));
    } catch (_error) {
      return {
        session_present: false,
        session_id: "INVALID_USER_SESSION",
        email: "unknown@example.invalid",
        role: "UNKNOWN"
      };
    }
  }

  function firstUsageScopeHeaders() {
    const session = getUserSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-User-Session": session.session_id,
      "X-Store-ID": CONFIG.fallbackSnapshot.store_id,
      "X-Register-ID": CONFIG.fallbackSnapshot.register_id,
      "X-First-Usage-Scope": "controlled-first-real-usage-smoke",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "controlled_customer_access",
      "X-Pix2pi-Step": "355"
    };
  }

  function validateFirstUsageScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    if (!snapshot || !snapshot.owner_user) errors.push({ field: "owner_user", code: "OWNER_USER_REQUIRED" });
    if (!snapshot || !snapshot.user_session_id) errors.push({ field: "user_session_id", code: "USER_SESSION_REQUIRED" });
    if (!snapshot || !snapshot.store_id) errors.push({ field: "store_id", code: "STORE_REQUIRED" });
    if (!snapshot || !snapshot.register_id) errors.push({ field: "register_id", code: "REGISTER_REQUIRED" });
    if (!snapshot || !snapshot.first_usage_scope) errors.push({ field: "first_usage_scope", code: "FIRST_USAGE_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.journey)) errors.push({ field: "journey", code: "JOURNEY_REQUIRED" });

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: firstUsageScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("FIRST_USAGE_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchFirstUsageSnapshot() {
    try {
      return await apiJson(CONFIG.firstUsageSnapshotEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      const session = getUserSession();
      snapshot.tenant_id = getTenantId();
      snapshot.user_session_id = session.session_id;
      snapshot.owner_user = session.email || snapshot.owner_user;
      snapshot.owner_role = session.role || snapshot.owner_role;
      return snapshot;
    }
  }

  function buildDependencyGate(snapshot) {
    const failed = (snapshot.dependencies || []).filter(function (item) {
      return item.status !== "PASS";
    });

    return {
      total: (snapshot.dependencies || []).length,
      failed: failed,
      valid: failed.length === 0
    };
  }

  function buildCustomerJourneyChecklist(snapshot) {
    const failed = (snapshot.journey || []).filter(function (item) {
      return !["PASS_PREVIEW", "DRY_RUN_ONLY", "DISABLED_EXPECTED"].includes(item.decision);
    });

    return {
      total: (snapshot.journey || []).length,
      failed: failed,
      valid: failed.length === 0
    };
  }

  function buildDataMutationDisabledGuard(snapshot) {
    const failed = (snapshot.safety_guards || []).filter(function (item) {
      return item.value !== false || item.status !== "ENFORCED";
    });

    return {
      total: (snapshot.safety_guards || []).length,
      failed: failed,
      valid: failed.length === 0,
      real_data_mutation_enabled: CONFIG.runtimeContract.realDataMutationEnabled,
      real_sale_enabled: CONFIG.runtimeContract.realSaleEnabled,
      real_payment_enabled: CONFIG.runtimeContract.realPaymentEnabled,
      real_invoice_issue_enabled: CONFIG.runtimeContract.realInvoiceIssueEnabled,
      real_stock_decrement_enabled: CONFIG.runtimeContract.realStockDecrementEnabled
    };
  }

  function buildFirstUsageDecision(snapshot) {
    const dependencies = buildDependencyGate(snapshot);
    const journey = buildCustomerJourneyChecklist(snapshot);
    const safety = buildDataMutationDisabledGuard(snapshot);
    const allowedForDecisionStep = dependencies.valid && journey.valid && safety.valid;

    return {
      decision: allowedForDecisionStep ? "READY_FOR_CONTROLLED_GO_LIVE_DECISION" : "BLOCKED_BEFORE_GO_LIVE_DECISION",
      ready_for_step_356: allowedForDecisionStep && CONFIG.runtimeContract.readyForStep356,
      real_customer_go_live_enabled: CONFIG.runtimeContract.realCustomerGoLiveEnabled,
      dependencies: dependencies,
      journey: journey,
      safety: safety
    };
  }

  function buildFirstUsageRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      owner_user: snapshot.owner_user,
      owner_role: snapshot.owner_role,
      user_session_id: snapshot.user_session_id,
      store_id: snapshot.store_id,
      register_id: snapshot.register_id,
      language: snapshot.language,
      first_usage_scope: snapshot.first_usage_scope,
      correlation_id: snapshot.correlation_id,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateFirstUsageScope(snapshot),
      first_usage_decision: buildFirstUsageDecision(snapshot),
      source: {
        surface: "first_real_usage_smoke",
        phase: "FAZ_7R",
        step: "355"
      }
    };
  }

  function renderContext(snapshot) {
    const tenant = document.getElementById("first-usage-tenant-id");
    const owner = document.getElementById("first-usage-owner-user");
    const store = document.getElementById("first-usage-store-id");
    const register = document.getElementById("first-usage-register-id");
    const validation = document.getElementById("first-usage-scope-validation");
    const contract = buildFirstUsageRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (owner) owner.textContent = snapshot.owner_user;
    if (store) store.textContent = snapshot.store_id;
    if (register) register.textContent = snapshot.register_id;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderDependencies(snapshot) {
    const target = document.getElementById("first-usage-dependency-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.dependencies || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "usage-card";
      row.setAttribute("data-dependency-step", item.step);
      row.setAttribute("data-dependency-status", item.status);
      row.innerHTML = [
        "<strong>" + item.step + " / " + item.name + "</strong>",
        "<p>" + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderJourney(snapshot) {
    const target = document.getElementById("first-usage-journey-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.journey || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "usage-card";
      row.setAttribute("data-journey-code", item.code);
      row.setAttribute("data-journey-surface", item.surface);
      row.setAttribute("data-decision", item.decision);
      row.innerHTML = [
        "<strong>" + item.label + "</strong>",
        "<p>" + item.surface + " / " + item.decision + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderSafetyGuards(snapshot) {
    const target = document.getElementById("first-usage-safety-guards");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.safety_guards || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "usage-card";
      row.setAttribute("data-safety-code", item.code);
      row.setAttribute("data-safety-status", item.status);
      row.innerHTML = [
        "<strong>" + item.code + "</strong>",
        "<p>" + item.status + " / value=" + item.value + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderStopCriteria(snapshot) {
    const target = document.getElementById("first-usage-stop-criteria");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.rollback_stop_criteria || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "usage-card";
      row.setAttribute("data-stop-code", item.code);
      row.setAttribute("data-stop-action", item.action);
      row.innerHTML = [
        "<strong>" + item.severity + " / " + item.code + "</strong>",
        "<p>" + item.action + " / " + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAuditTimeline(snapshot) {
    const target = document.getElementById("first-usage-audit-timeline");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.audit_timeline || []).forEach(function (event) {
      const row = document.createElement("article");
      row.className = "usage-card";
      row.setAttribute("data-audit-action", event.action);
      row.innerHTML = [
        "<strong>" + event.action + "</strong>",
        "<p>" + event.at + " / " + event.actor + " / " + event.result + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("first-usage-runtime-contract");
    if (!target) return;

    const contract = buildFirstUsageRuntimeContract(snapshot);

    target.textContent = [
      "real_customer_go_live_enabled=" + CONFIG.runtimeContract.realCustomerGoLiveEnabled,
      "real_sale_enabled=" + CONFIG.runtimeContract.realSaleEnabled,
      "real_payment_enabled=" + CONFIG.runtimeContract.realPaymentEnabled,
      "real_invoice_issue_enabled=" + CONFIG.runtimeContract.realInvoiceIssueEnabled,
      "real_data_mutation_enabled=" + CONFIG.runtimeContract.realDataMutationEnabled,
      "decision=" + contract.first_usage_decision.decision,
      "ready_for_step_356=" + CONFIG.runtimeContract.readyForStep356,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderFirstUsageSmokeScreen(snapshot) {
    renderContext(snapshot);
    renderDependencies(snapshot);
    renderJourney(snapshot);
    renderSafetyGuards(snapshot);
    renderStopCriteria(snapshot);
    renderAuditTimeline(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-first-real-usage-smoke-rendered", "true");
  }

  async function bootFirstUsageSmokeScreen() {
    const snapshot = await fetchFirstUsageSnapshot();
    renderFirstUsageSmokeScreen(snapshot);
    return buildFirstUsageRuntimeContract(snapshot);
  }

  window.Pix2piFirstRealUsageSmoke = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getUserSession: getUserSession,
    firstUsageScopeHeaders: firstUsageScopeHeaders,
    validateFirstUsageScope: validateFirstUsageScope,
    fetchFirstUsageSnapshot: fetchFirstUsageSnapshot,
    buildDependencyGate: buildDependencyGate,
    buildCustomerJourneyChecklist: buildCustomerJourneyChecklist,
    buildDataMutationDisabledGuard: buildDataMutationDisabledGuard,
    buildFirstUsageDecision: buildFirstUsageDecision,
    buildFirstUsageRuntimeContract: buildFirstUsageRuntimeContract,
    renderContext: renderContext,
    renderDependencies: renderDependencies,
    renderJourney: renderJourney,
    renderSafetyGuards: renderSafetyGuards,
    renderStopCriteria: renderStopCriteria,
    renderAuditTimeline: renderAuditTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderFirstUsageSmokeScreen: renderFirstUsageSmokeScreen,
    bootFirstUsageSmokeScreen: bootFirstUsageSmokeScreen
  };
})();
/* PIX2PI_355_FIRST_REAL_USAGE_SMOKE_RUNTIME_END */
