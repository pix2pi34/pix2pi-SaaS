/* PIX2PI_362_CONTROLLED_ROLLOUT_COHORT_SETUP_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "controlled_rollout_cohort_setup",
    phase: "FAZ_7R",
    step: "362",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    runtimeContract: {
      realCustomerAddEnabled: false,
      realRolloutActivationEnabled: false,
      realFeatureFlagWriteEnabled: false,
      realBillingEnabled: false,
      realPaymentEnabled: false,
      realDataMutationEnabled: false,
      cohortSetupPreviewEnabled: true,
      supportCapacityRequired: true,
      monitoringCapacityRequired: true,
      legalKvkkHoldRequired: true,
      readyForStep363: true
    },
    fallbackSnapshot: {
      rollout_id: "controlled-rollout-001",
      cohort_scope: "controlled-rollout-cohort-setup",
      correlation_id: "FAZ7R-362-DEMO-CORRELATION",
      cohort_limits: {
        max_customers: 3,
        max_tenants: 3,
        rollout_mode: "CONTROLLED_PREVIEW",
        production_public_rollout_enabled: false
      },
      eligibility: [
        { customer: "Demo Market", tenant: "controlled-pilot", eligible: true, risk: "LOW", decision: "INCLUDE_PREVIEW" },
        { customer: "Pilot Market 2", tenant: "pilot-market-2", eligible: true, risk: "LOW", decision: "INCLUDE_PREVIEW" },
        { customer: "Pilot Market 3", tenant: "pilot-market-3", eligible: false, risk: "MEDIUM", decision: "HOLD_PREVIEW" }
      ],
      segmentation: [
        { segment: "auto_parts", region: "TR", risk: "LOW", cohort: "cohort_001" },
        { segment: "grocery", region: "TR", risk: "LOW", cohort: "cohort_001" }
      ],
      wave_schedule: [
        { wave: "wave_001", max_customers: 1, status: "READY_PREVIEW" },
        { wave: "wave_002", max_customers: 2, status: "HOLD_PREVIEW" }
      ],
      bindings: [
        { type: "feature_flag", key: "controlled_rollout_cohort_001", real_write_enabled: false, status: "PREVIEW_ONLY" },
        { type: "entitlement_plan", key: "pilot_controlled_plan", real_write_enabled: false, status: "PREVIEW_ONLY" }
      ],
      gates: [
        { code: "SUPPORT_CAPACITY", status: "READY_PREVIEW", decision: "GO_PREVIEW" },
        { code: "MONITORING_CAPACITY", status: "READY_PREVIEW", decision: "GO_PREVIEW" },
        { code: "LEGAL_KVKK_APPROVAL", status: "PENDING_FINAL_APPROVAL", decision: "HOLD_REAL_ROLLOUT" },
        { code: "BILLING_PAYMENT_LIVE", status: "DISABLED_EXPECTED", decision: "HOLD_REAL_BILLING" }
      ],
      safety_guards: [
        { code: "REAL_CUSTOMER_ADD_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_ROLLOUT_ACTIVATION_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_FEATURE_FLAG_WRITE_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_DATA_MUTATION_DISABLED", status: "ENFORCED", value: false }
      ],
      rollback_plan: [
        { trigger: "P1_INCIDENT", action: "REMOVE_COHORT_ACCESS_PREVIEW", status: "READY" },
        { trigger: "UNEXPECTED_MUTATION", action: "STOP_ROLLOUT_PREVIEW", status: "READY" },
        { trigger: "SUPPORT_OVERLOAD", action: "PAUSE_NEXT_WAVE", status: "READY" }
      ],
      communication_drafts: [
        { target: "cohort_customer", template: "controlled_rollout_invite", real_send_enabled: false, status: "DRAFT_ONLY" },
        { target: "support_team", template: "cohort_watch_brief", real_send_enabled: false, status: "DRAFT_ONLY" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "PILOT_CLOSURE_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "product", action: "COHORT_SETUP_PREVIEW_READY", result: "READY" },
        { at: "2026-05-demo", actor: "system", action: "REAL_ROLLOUT_DISABLED", result: "EXPECTED" }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || "controlled-pilot";
  }

  function cohortSetupHeaders() {
    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Cohort-Setup-Scope": "controlled-rollout-cohort-setup",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "controlled_rollout_cohort_setup",
      "X-Pix2pi-Step": "362"
    };
  }

  function validateCohortSetupScope(snapshot) {
    const errors = [];
    if (!snapshot || !snapshot.rollout_id) errors.push({ field: "rollout_id", code: "ROLLOUT_ID_REQUIRED" });
    if (!snapshot || !snapshot.cohort_scope) errors.push({ field: "cohort_scope", code: "COHORT_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.eligibility)) errors.push({ field: "eligibility", code: "ELIGIBILITY_REQUIRED" });
    return { valid: errors.length === 0, errors: errors };
  }

  async function fetchCohortSetupSnapshot() {
    return JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
  }

  function buildEligibilityChecklist(snapshot) {
    const eligible = (snapshot.eligibility || []).filter(function (item) { return item.eligible; });
    const held = (snapshot.eligibility || []).filter(function (item) { return !item.eligible; });
    return { total: (snapshot.eligibility || []).length, eligible: eligible.length, held: held.length, valid: eligible.length > 0 };
  }

  function buildCapacityGate(snapshot) {
    const blockers = (snapshot.gates || []).filter(function (gate) {
      return ["SUPPORT_CAPACITY", "MONITORING_CAPACITY"].includes(gate.code) && gate.status !== "READY_PREVIEW";
    });
    return { total: (snapshot.gates || []).length, blockers: blockers, valid: blockers.length === 0 };
  }

  function buildSafetyGuard(snapshot) {
    const failed = (snapshot.safety_guards || []).filter(function (item) {
      return item.value !== false || item.status !== "ENFORCED";
    });
    return { total: (snapshot.safety_guards || []).length, failed: failed, valid: failed.length === 0 };
  }

  function buildCohortSetupDecision(snapshot) {
    const eligibility = buildEligibilityChecklist(snapshot);
    const capacity = buildCapacityGate(snapshot);
    const safety = buildSafetyGuard(snapshot);
    const ready = eligibility.valid && capacity.valid && safety.valid;
    return {
      decision: ready ? "COHORT_SETUP_READY_FOR_APPROVAL" : "COHORT_SETUP_HOLD",
      real_rollout_activation_enabled: CONFIG.runtimeContract.realRolloutActivationEnabled,
      ready_for_step_363: ready && CONFIG.runtimeContract.readyForStep363,
      eligibility: eligibility,
      capacity: capacity,
      safety: safety
    };
  }

  function buildCohortSetupRuntimeContract(snapshot) {
    return {
      rollout_id: snapshot.rollout_id,
      cohort_scope: snapshot.cohort_scope,
      correlation_id: snapshot.correlation_id,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateCohortSetupScope(snapshot),
      cohort_setup_decision: buildCohortSetupDecision(snapshot),
      source: { surface: "controlled_rollout_cohort_setup", phase: "FAZ_7R", step: "362" }
    };
  }

  function renderList(targetId, list, attrs) {
    const target = document.getElementById(targetId);
    if (!target) return;
    target.innerHTML = "";
    (list || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "cohort-card";
      Object.keys(attrs || {}).forEach(function (key) {
        row.setAttribute(key, item[attrs[key]] || "");
      });
      row.innerHTML = [
        "<strong>" + (item.customer || item.segment || item.wave || item.key || item.code || item.trigger || item.target || item.action) + "</strong>",
        "<p>" + JSON.stringify(item).replace(/[{}"]/g, "") + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderCohortSetupScreen(snapshot) {
    const rollout = document.getElementById("cohort-rollout-id");
    const scope = document.getElementById("cohort-scope-validation");
    const limits = document.getElementById("cohort-size-limit");
    const contract = buildCohortSetupRuntimeContract(snapshot);

    if (rollout) rollout.textContent = snapshot.rollout_id;
    if (scope) scope.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
    if (limits) limits.textContent = "max_customers=" + snapshot.cohort_limits.max_customers + " / mode=" + snapshot.cohort_limits.rollout_mode;

    renderList("cohort-eligibility", snapshot.eligibility, { "data-customer": "customer", "data-decision": "decision" });
    renderList("cohort-segmentation", snapshot.segmentation, { "data-segment": "segment", "data-risk": "risk" });
    renderList("cohort-wave-schedule", snapshot.wave_schedule, { "data-wave": "wave", "data-status": "status" });
    renderList("cohort-bindings", snapshot.bindings, { "data-binding-type": "type", "data-status": "status" });
    renderList("cohort-gates", snapshot.gates, { "data-gate-code": "code", "data-gate-status": "status" });
    renderList("cohort-safety-guards", snapshot.safety_guards, { "data-code": "code", "data-status": "status" });
    renderList("cohort-rollback-plan", snapshot.rollback_plan, { "data-trigger": "trigger", "data-status": "status" });
    renderList("cohort-communication-drafts", snapshot.communication_drafts, { "data-target": "target", "data-status": "status" });
    renderList("cohort-audit-timeline", snapshot.audit_timeline, { "data-audit-action": "action" });

    const runtime = document.getElementById("cohort-runtime-contract");
    if (runtime) {
      runtime.textContent = [
        "cohort_setup_preview_enabled=" + CONFIG.runtimeContract.cohortSetupPreviewEnabled,
        "real_customer_add_enabled=" + CONFIG.runtimeContract.realCustomerAddEnabled,
        "real_rollout_activation_enabled=" + CONFIG.runtimeContract.realRolloutActivationEnabled,
        "real_data_mutation_enabled=" + CONFIG.runtimeContract.realDataMutationEnabled,
        "decision=" + contract.cohort_setup_decision.decision,
        "ready_for_step_363=" + CONFIG.runtimeContract.readyForStep363
      ].join(" / ");
    }

    document.body.setAttribute("data-controlled-rollout-cohort-setup-rendered", "true");
  }

  async function bootCohortSetupScreen() {
    const snapshot = await fetchCohortSetupSnapshot();
    renderCohortSetupScreen(snapshot);
    return buildCohortSetupRuntimeContract(snapshot);
  }

  window.Pix2piControlledRolloutCohortSetup = {
    CONFIG: CONFIG,
    cohortSetupHeaders: cohortSetupHeaders,
    validateCohortSetupScope: validateCohortSetupScope,
    fetchCohortSetupSnapshot: fetchCohortSetupSnapshot,
    buildEligibilityChecklist: buildEligibilityChecklist,
    buildCapacityGate: buildCapacityGate,
    buildSafetyGuard: buildSafetyGuard,
    buildCohortSetupDecision: buildCohortSetupDecision,
    buildCohortSetupRuntimeContract: buildCohortSetupRuntimeContract,
    renderCohortSetupScreen: renderCohortSetupScreen,
    bootCohortSetupScreen: bootCohortSetupScreen
  };
})();
/* PIX2PI_362_CONTROLLED_ROLLOUT_COHORT_SETUP_RUNTIME_END */
