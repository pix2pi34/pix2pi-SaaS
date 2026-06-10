/* PIX2PI_360_PILOT_STABILIZATION_FIX_PLAN_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "pilot_stabilization_fix_plan",
    phase: "FAZ_7R",
    step: "360",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    runtimeContract: {
      realHotfixDeployEnabled: false,
      realTicketCreateEnabled: false,
      realCustomerNotificationSendEnabled: false,
      realDataMutationEnabled: false,
      stabilizationPreviewEnabled: true,
      fixPlanPreviewEnabled: true,
      regressionChecklistPreviewEnabled: true,
      rollbackReadyRequired: true,
      readyForStep361: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      customer_name: "Demo Market",
      stabilization_scope: "pilot-stabilization-fix-plan-closure",
      correlation_id: "FAZ7R-360-DEMO-CORRELATION",
      triage_summary: {
        total_feedback: 3,
        p1_blocker: 0,
        p2_blocker: 0,
        p3_non_blocker: 2,
        info_expected_disabled: 1,
        hotfix_required: false
      },
      stabilization_scope_board: [
        { area: "panel", status: "STABLE_PREVIEW", action: "WATCH_CONTINUES" },
        { area: "pos", status: "STABLE_PREVIEW", action: "WATCH_CONTINUES" },
        { area: "market", status: "STABLE_PREVIEW", action: "WATCH_CONTINUES" },
        { area: "support", status: "READY_PREVIEW", action: "FOLLOWUP_CONTINUES" }
      ],
      backlog_closure: [
        { issue: "PILOT-ISSUE-001", backlog: "PRODUCT_DISCOVERY", status: "BACKLOG_PREVIEW", blocker: false },
        { issue: "PILOT-ISSUE-002", backlog: "UX_POLISH", status: "BACKLOG_PREVIEW", blocker: false }
      ],
      fix_plan_owners: [
        { area: "product_search_visibility", owner: "product", due: "post-pilot", status: "ASSIGNED_PREVIEW" },
        { area: "pos_button_typography", owner: "frontend", due: "post-pilot", status: "ASSIGNED_PREVIEW" },
        { area: "commercial_disabled_states", owner: "commercial", due: "post-pilot", status: "DOCUMENTED_EXPECTED" }
      ],
      regression_checklist: [
        { check: "panel_route_smoke", status: "PASS_PREVIEW" },
        { check: "pos_route_smoke", status: "PASS_PREVIEW" },
        { check: "market_route_smoke", status: "PASS_PREVIEW" },
        { check: "tenant_isolation_regression", status: "PASS_PREVIEW" },
        { check: "permission_regression", status: "PASS_PREVIEW" },
        { check: "localization_regression", status: "PASS_PREVIEW" }
      ],
      support_followup: [
        { channel: "phone", status: "READY_PREVIEW" },
        { channel: "whatsapp", status: "READY_PREVIEW" },
        { channel: "email", status: "READY_PREVIEW" }
      ],
      communication_plan: [
        { target: "pilot_customer", template: "pilot_stabilization_update", real_send_enabled: false, status: "DRAFT_ONLY" },
        { target: "internal_team", template: "pilot_fix_plan_summary", real_send_enabled: false, status: "DRAFT_ONLY" }
      ],
      monitoring_continuation: [
        { window: "next_24h", status: "WATCH_CONTINUES" },
        { window: "next_business_day", status: "WATCH_CONTINUES" }
      ],
      rollback_readiness: [
        { trigger: "P1_INCIDENT", action: "STOP_CUSTOMER_ACCESS", status: "READY" },
        { trigger: "UNEXPECTED_MUTATION", action: "STOP_CUSTOMER_ACCESS", status: "READY" },
        { trigger: "TENANT_SCOPE_VIOLATION", action: "STOP_CUSTOMER_ACCESS", status: "READY" }
      ],
      safety_guards: [
        { code: "REAL_HOTFIX_DEPLOY_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_TICKET_CREATE_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_CUSTOMER_NOTIFICATION_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_DATA_MUTATION_DISABLED", status: "ENFORCED", value: false }
      ],
      risk_register: [
        { severity: "P2", risk: "UX friction", status: "CONTROLLED", action: "BACKLOG" },
        { severity: "P3", risk: "Support follow-up delay", status: "CONTROLLED", action: "WATCH" },
        { severity: "P1", risk: "Unexpected mutation", status: "CONTROLLED", action: "ROLLBACK_READY" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "support", action: "PILOT_FEEDBACK_TRIAGE_PASS", result: "PASS" },
        { at: "2026-05-demo", actor: "product", action: "FIX_PLAN_PREVIEW_READY", result: "READY" },
        { at: "2026-05-demo", actor: "system", action: "NO_HOTFIX_REQUIRED", result: "EXPECTED" }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSnapshot.tenant_id;
  }

  function stabilizationScopeHeaders() {
    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Stabilization-Scope": "pilot-stabilization-fix-plan-closure",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "pilot_stabilization_fix_plan",
      "X-Pix2pi-Step": "360"
    };
  }

  function validateStabilizationScope(snapshot) {
    const errors = [];
    if (!snapshot || !snapshot.tenant_id) errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    if (!snapshot || !snapshot.customer_name) errors.push({ field: "customer_name", code: "CUSTOMER_REQUIRED" });
    if (!snapshot || !snapshot.stabilization_scope) errors.push({ field: "stabilization_scope", code: "SCOPE_REQUIRED" });
    if (!snapshot || !snapshot.triage_summary) errors.push({ field: "triage_summary", code: "TRIAGE_SUMMARY_REQUIRED" });
    return { valid: errors.length === 0, errors: errors };
  }

  async function fetchStabilizationSnapshot() {
    const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
    snapshot.tenant_id = getTenantId();
    return snapshot;
  }

  function buildHotfixNotRequiredDecision(snapshot) {
    return {
      hotfix_required: Boolean(snapshot.triage_summary.hotfix_required),
      decision: snapshot.triage_summary.hotfix_required ? "HOTFIX_REQUIRED" : "NO_HOTFIX_REQUIRED",
      real_hotfix_deploy_enabled: CONFIG.runtimeContract.realHotfixDeployEnabled
    };
  }

  function buildRegressionChecklist(snapshot) {
    const failed = (snapshot.regression_checklist || []).filter(function (item) {
      return item.status !== "PASS_PREVIEW";
    });
    return { total: (snapshot.regression_checklist || []).length, failed: failed, valid: failed.length === 0 };
  }

  function buildDataMutationGuard(snapshot) {
    const failed = (snapshot.safety_guards || []).filter(function (item) {
      return item.value !== false || item.status !== "ENFORCED";
    });
    return { total: (snapshot.safety_guards || []).length, failed: failed, valid: failed.length === 0 };
  }

  function buildGoForwardDecision(snapshot) {
    const hotfix = buildHotfixNotRequiredDecision(snapshot);
    const regression = buildRegressionChecklist(snapshot);
    const mutation = buildDataMutationGuard(snapshot);
    const allowed = hotfix.decision === "NO_HOTFIX_REQUIRED" && regression.valid && mutation.valid;
    return {
      decision: allowed ? "STABILIZED_READY_FOR_PILOT_CLOSURE" : "BLOCKED_BY_STABILIZATION_RISK",
      ready_for_step_361: allowed && CONFIG.runtimeContract.readyForStep361,
      hotfix: hotfix,
      regression: regression,
      mutation: mutation
    };
  }

  function buildStabilizationRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      customer_name: snapshot.customer_name,
      stabilization_scope: snapshot.stabilization_scope,
      correlation_id: snapshot.correlation_id,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateStabilizationScope(snapshot),
      go_forward_decision: buildGoForwardDecision(snapshot),
      source: { surface: "pilot_stabilization_fix_plan", phase: "FAZ_7R", step: "360" }
    };
  }

  function renderList(targetId, list, attrs) {
    const target = document.getElementById(targetId);
    if (!target) return;
    target.innerHTML = "";
    (list || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "stabilization-card";
      Object.keys(attrs || {}).forEach(function (key) {
        row.setAttribute(key, item[attrs[key]] || "");
      });
      row.innerHTML = [
        "<strong>" + (item.area || item.issue || item.check || item.channel || item.target || item.window || item.trigger || item.code || item.risk || item.action) + "</strong>",
        "<p>" + JSON.stringify(item).replace(/[{}"]/g, "") + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderStabilizationScreen(snapshot) {
    const tenant = document.getElementById("stabilization-tenant-id");
    const customer = document.getElementById("stabilization-customer-name");
    const triage = document.getElementById("stabilization-triage-summary");
    const scope = document.getElementById("stabilization-scope-validation");
    const contract = buildStabilizationRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (customer) customer.textContent = snapshot.customer_name;
    if (triage) triage.textContent = "total_feedback=" + snapshot.triage_summary.total_feedback + " / p1_blocker=" + snapshot.triage_summary.p1_blocker + " / hotfix_required=" + snapshot.triage_summary.hotfix_required;
    if (scope) scope.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";

    renderList("stabilization-scope-board", snapshot.stabilization_scope_board, { "data-area": "area", "data-status": "status" });
    renderList("stabilization-backlog-closure", snapshot.backlog_closure, { "data-issue": "issue", "data-status": "status" });
    renderList("stabilization-fix-owners", snapshot.fix_plan_owners, { "data-area": "area", "data-owner": "owner" });
    renderList("stabilization-regression-checklist", snapshot.regression_checklist, { "data-check": "check", "data-status": "status" });
    renderList("stabilization-support-followup", snapshot.support_followup, { "data-channel": "channel", "data-status": "status" });
    renderList("stabilization-communication-plan", snapshot.communication_plan, { "data-target": "target", "data-status": "status" });
    renderList("stabilization-monitoring-continuation", snapshot.monitoring_continuation, { "data-window": "window", "data-status": "status" });
    renderList("stabilization-rollback-readiness", snapshot.rollback_readiness, { "data-trigger": "trigger", "data-status": "status" });
    renderList("stabilization-safety-guards", snapshot.safety_guards, { "data-code": "code", "data-status": "status" });
    renderList("stabilization-risk-register", snapshot.risk_register, { "data-risk": "risk", "data-status": "status" });
    renderList("stabilization-audit-timeline", snapshot.audit_timeline, { "data-audit-action": "action" });

    const runtime = document.getElementById("stabilization-runtime-contract");
    if (runtime) {
      runtime.textContent = [
        "stabilization_preview_enabled=" + CONFIG.runtimeContract.stabilizationPreviewEnabled,
        "real_hotfix_deploy_enabled=" + CONFIG.runtimeContract.realHotfixDeployEnabled,
        "real_data_mutation_enabled=" + CONFIG.runtimeContract.realDataMutationEnabled,
        "decision=" + contract.go_forward_decision.decision,
        "ready_for_step_361=" + CONFIG.runtimeContract.readyForStep361
      ].join(" / ");
    }

    document.body.setAttribute("data-pilot-stabilization-rendered", "true");
  }

  async function bootStabilizationScreen() {
    const snapshot = await fetchStabilizationSnapshot();
    renderStabilizationScreen(snapshot);
    return buildStabilizationRuntimeContract(snapshot);
  }

  window.Pix2piPilotStabilization = {
    CONFIG: CONFIG,
    stabilizationScopeHeaders: stabilizationScopeHeaders,
    validateStabilizationScope: validateStabilizationScope,
    fetchStabilizationSnapshot: fetchStabilizationSnapshot,
    buildHotfixNotRequiredDecision: buildHotfixNotRequiredDecision,
    buildRegressionChecklist: buildRegressionChecklist,
    buildDataMutationGuard: buildDataMutationGuard,
    buildGoForwardDecision: buildGoForwardDecision,
    buildStabilizationRuntimeContract: buildStabilizationRuntimeContract,
    renderStabilizationScreen: renderStabilizationScreen,
    bootStabilizationScreen: bootStabilizationScreen
  };
})();
/* PIX2PI_360_PILOT_STABILIZATION_FIX_PLAN_RUNTIME_END */
