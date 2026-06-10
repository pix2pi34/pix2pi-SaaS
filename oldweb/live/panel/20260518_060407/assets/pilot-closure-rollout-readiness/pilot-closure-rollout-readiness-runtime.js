/* PIX2PI_361_PILOT_CLOSURE_ROLLOUT_READINESS_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "pilot_closure_controlled_rollout_readiness",
    phase: "FAZ_7R",
    step: "361",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    runtimeContract: {
      productionPublicRolloutEnabled: false,
      controlledRolloutPreviewEnabled: true,
      realBillingEnabled: false,
      realPaymentEnabled: false,
      realDataMutationEnabled: false,
      legalKvkkFinalApprovalRequired: true,
      supportReadyRequired: true,
      monitoringReadyRequired: true,
      readyForStep362: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      customer_name: "Demo Market",
      closure_scope: "pilot-closure-controlled-rollout-readiness",
      correlation_id: "FAZ7R-361-DEMO-CORRELATION",
      completion_summary: {
        pilot_status: "STABILIZED_PREVIEW",
        p1_blockers: 0,
        p2_blockers: 0,
        hotfix_required: false,
        customer_acceptance: "PREVIEW_ACCEPTED"
      },
      evidence_package: [
        { step: "355", name: "first_real_usage_smoke", status: "PASS" },
        { step: "356", name: "go_live_decision", status: "PASS" },
        { step: "357", name: "access_activation", status: "PASS" },
        { step: "358", name: "first_day_watch", status: "PASS" },
        { step: "359", name: "feedback_triage", status: "PASS" },
        { step: "360", name: "stabilization_fix_plan", status: "PASS" }
      ],
      kpis: [
        { metric: "critical_incidents", value: 0, target: 0, status: "PASS" },
        { metric: "tenant_scope_violations", value: 0, target: 0, status: "PASS" },
        { metric: "unexpected_mutations", value: 0, target: 0, status: "PASS" },
        { metric: "customer_feedback_blockers", value: 0, target: 0, status: "PASS" }
      ],
      rollout_cohort: [
        { cohort: "cohort_001", type: "controlled", max_customers: 3, status: "READY_PREVIEW" },
        { cohort: "cohort_002", type: "hold", max_customers: 0, status: "HOLD" }
      ],
      gates: [
        { code: "COMMERCIAL_READINESS", status: "READY_PREVIEW", decision: "GO_PREVIEW" },
        { code: "SUPPORT_READINESS", status: "READY_PREVIEW", decision: "GO_PREVIEW" },
        { code: "MONITORING_READINESS", status: "READY_PREVIEW", decision: "GO_PREVIEW" },
        { code: "LEGAL_KVKK_APPROVAL", status: "PENDING_FINAL_APPROVAL", decision: "HOLD_REAL_ROLLOUT" },
        { code: "BILLING_PAYMENT_LIVE", status: "DISABLED_EXPECTED", decision: "HOLD_REAL_BILLING" }
      ],
      safety_guards: [
        { code: "PRODUCTION_PUBLIC_ROLLOUT_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_BILLING_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_PAYMENT_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_DATA_MUTATION_DISABLED", status: "ENFORCED", value: false }
      ],
      risk_register: [
        { severity: "P1", risk: "Public rollout before legal approval", status: "CONTROLLED", action: "HOLD_PUBLIC_ROLLOUT" },
        { severity: "P1", risk: "Unexpected mutation", status: "CONTROLLED", action: "ROLLBACK_READY" },
        { severity: "P2", risk: "Support overload", status: "CONTROLLED", action: "LIMIT_COHORT" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "product", action: "PILOT_STABILIZATION_PASS", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "CONTROLLED_ROLLOUT_READINESS_PREVIEW", result: "READY" },
        { at: "2026-05-demo", actor: "system", action: "PUBLIC_ROLLOUT_DISABLED", result: "EXPECTED" }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSnapshot.tenant_id;
  }

  function rolloutReadinessHeaders() {
    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Rollout-Readiness-Scope": "pilot-closure-controlled-rollout-readiness",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "pilot_closure_controlled_rollout_readiness",
      "X-Pix2pi-Step": "361"
    };
  }

  function validateRolloutReadinessScope(snapshot) {
    const errors = [];
    if (!snapshot || !snapshot.tenant_id) errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    if (!snapshot || !snapshot.customer_name) errors.push({ field: "customer_name", code: "CUSTOMER_REQUIRED" });
    if (!snapshot || !snapshot.closure_scope) errors.push({ field: "closure_scope", code: "CLOSURE_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.evidence_package)) errors.push({ field: "evidence_package", code: "EVIDENCE_REQUIRED" });
    return { valid: errors.length === 0, errors: errors };
  }

  async function fetchRolloutReadinessSnapshot() {
    const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
    snapshot.tenant_id = getTenantId();
    return snapshot;
  }

  function buildEvidencePackageChecklist(snapshot) {
    const failed = (snapshot.evidence_package || []).filter(function (item) { return item.status !== "PASS"; });
    return { total: (snapshot.evidence_package || []).length, failed: failed, valid: failed.length === 0 };
  }

  function buildPilotKpiClosureBoard(snapshot) {
    const failed = (snapshot.kpis || []).filter(function (item) { return item.status !== "PASS"; });
    return { total: (snapshot.kpis || []).length, failed: failed, valid: failed.length === 0 };
  }

  function buildRolloutGateDecision(snapshot) {
    const hardBlockers = (snapshot.gates || []).filter(function (gate) {
      return gate.code !== "LEGAL_KVKK_APPROVAL" && gate.status !== "READY_PREVIEW" && gate.status !== "DISABLED_EXPECTED";
    });
    const safetyFailures = (snapshot.safety_guards || []).filter(function (item) {
      return item.value !== false || item.status !== "ENFORCED";
    });

    const evidence = buildEvidencePackageChecklist(snapshot);
    const kpis = buildPilotKpiClosureBoard(snapshot);
    const ready = evidence.valid && kpis.valid && hardBlockers.length === 0 && safetyFailures.length === 0;

    return {
      decision: ready ? "CONTROLLED_ROLLOUT_READY_PREVIEW" : "ROLLOUT_HOLD",
      production_public_rollout_enabled: CONFIG.runtimeContract.productionPublicRolloutEnabled,
      ready_for_step_362: ready && CONFIG.runtimeContract.readyForStep362,
      evidence: evidence,
      kpis: kpis,
      hard_blockers: hardBlockers,
      safety_failures: safetyFailures
    };
  }

  function buildRolloutReadinessRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      customer_name: snapshot.customer_name,
      closure_scope: snapshot.closure_scope,
      correlation_id: snapshot.correlation_id,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateRolloutReadinessScope(snapshot),
      rollout_decision: buildRolloutGateDecision(snapshot),
      source: { surface: "pilot_closure_controlled_rollout_readiness", phase: "FAZ_7R", step: "361" }
    };
  }

  function renderList(targetId, list, attrs) {
    const target = document.getElementById(targetId);
    if (!target) return;
    target.innerHTML = "";
    (list || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "closure-card";
      Object.keys(attrs || {}).forEach(function (key) {
        row.setAttribute(key, item[attrs[key]] || "");
      });
      row.innerHTML = [
        "<strong>" + (item.step || item.metric || item.cohort || item.code || item.risk || item.action || item.name) + "</strong>",
        "<p>" + JSON.stringify(item).replace(/[{}"]/g, "") + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRolloutReadinessScreen(snapshot) {
    const tenant = document.getElementById("closure-tenant-id");
    const customer = document.getElementById("closure-customer-name");
    const summary = document.getElementById("closure-completion-summary");
    const scope = document.getElementById("closure-scope-validation");
    const contract = buildRolloutReadinessRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (customer) customer.textContent = snapshot.customer_name;
    if (summary) summary.textContent = "pilot_status=" + snapshot.completion_summary.pilot_status + " / p1_blockers=" + snapshot.completion_summary.p1_blockers + " / acceptance=" + snapshot.completion_summary.customer_acceptance;
    if (scope) scope.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";

    renderList("closure-evidence-package", snapshot.evidence_package, { "data-step": "step", "data-status": "status" });
    renderList("closure-kpi-board", snapshot.kpis, { "data-metric": "metric", "data-status": "status" });
    renderList("closure-rollout-cohort", snapshot.rollout_cohort, { "data-cohort": "cohort", "data-status": "status" });
    renderList("closure-gates", snapshot.gates, { "data-gate-code": "code", "data-gate-status": "status" });
    renderList("closure-safety-guards", snapshot.safety_guards, { "data-code": "code", "data-status": "status" });
    renderList("closure-risk-register", snapshot.risk_register, { "data-risk": "risk", "data-status": "status" });
    renderList("closure-audit-timeline", snapshot.audit_timeline, { "data-audit-action": "action" });

    const runtime = document.getElementById("closure-runtime-contract");
    if (runtime) {
      runtime.textContent = [
        "controlled_rollout_preview_enabled=" + CONFIG.runtimeContract.controlledRolloutPreviewEnabled,
        "production_public_rollout_enabled=" + CONFIG.runtimeContract.productionPublicRolloutEnabled,
        "real_billing_enabled=" + CONFIG.runtimeContract.realBillingEnabled,
        "real_payment_enabled=" + CONFIG.runtimeContract.realPaymentEnabled,
        "real_data_mutation_enabled=" + CONFIG.runtimeContract.realDataMutationEnabled,
        "decision=" + contract.rollout_decision.decision,
        "ready_for_step_362=" + CONFIG.runtimeContract.readyForStep362
      ].join(" / ");
    }

    document.body.setAttribute("data-pilot-closure-rollout-readiness-rendered", "true");
  }

  async function bootRolloutReadinessScreen() {
    const snapshot = await fetchRolloutReadinessSnapshot();
    renderRolloutReadinessScreen(snapshot);
    return buildRolloutReadinessRuntimeContract(snapshot);
  }

  window.Pix2piPilotClosureRolloutReadiness = {
    CONFIG: CONFIG,
    rolloutReadinessHeaders: rolloutReadinessHeaders,
    validateRolloutReadinessScope: validateRolloutReadinessScope,
    fetchRolloutReadinessSnapshot: fetchRolloutReadinessSnapshot,
    buildEvidencePackageChecklist: buildEvidencePackageChecklist,
    buildPilotKpiClosureBoard: buildPilotKpiClosureBoard,
    buildRolloutGateDecision: buildRolloutGateDecision,
    buildRolloutReadinessRuntimeContract: buildRolloutReadinessRuntimeContract,
    renderRolloutReadinessScreen: renderRolloutReadinessScreen,
    bootRolloutReadinessScreen: bootRolloutReadinessScreen
  };
})();
/* PIX2PI_361_PILOT_CLOSURE_ROLLOUT_READINESS_RUNTIME_END */
