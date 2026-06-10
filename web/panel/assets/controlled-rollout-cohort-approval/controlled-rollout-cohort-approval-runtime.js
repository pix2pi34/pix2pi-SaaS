/* PIX2PI_363_CONTROLLED_ROLLOUT_COHORT_APPROVAL_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "controlled_rollout_cohort_approval",
    phase: "FAZ_7R",
    step: "363",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    runtimeContract: {
      realRolloutApprovalEnabled: false,
      realRolloutActivationEnabled: false,
      realFeatureFlagWriteEnabled: false,
      realCustomerNotificationSendEnabled: false,
      realBillingEnabled: false,
      realPaymentEnabled: false,
      realDataMutationEnabled: false,
      approvalPreviewEnabled: true,
      legalKvkkHoldRequired: true,
      readyForStep364: true
    },
    fallbackSnapshot: {
      rollout_id: "controlled-rollout-001",
      cohort_id: "cohort_001",
      approval_scope: "controlled-rollout-cohort-approval",
      correlation_id: "FAZ7R-363-DEMO-CORRELATION",
      approvers: [
        { role: "product_owner", required: true, status: "APPROVED_PREVIEW", decision: "GO_PREVIEW" },
        { role: "sre_monitoring", required: true, status: "APPROVED_PREVIEW", decision: "GO_PREVIEW" },
        { role: "support_owner", required: true, status: "APPROVED_PREVIEW", decision: "GO_PREVIEW" },
        { role: "commercial_owner", required: true, status: "APPROVED_PREVIEW", decision: "GO_PREVIEW" },
        { role: "legal_kvkk_owner", required: true, status: "PENDING_FINAL_APPROVAL", decision: "HOLD_REAL_ROLLOUT" }
      ],
      gates: [
        { code: "PRODUCT_APPROVAL", status: "APPROVED_PREVIEW", decision: "GO_PREVIEW" },
        { code: "SRE_MONITORING_APPROVAL", status: "APPROVED_PREVIEW", decision: "GO_PREVIEW" },
        { code: "SUPPORT_APPROVAL", status: "APPROVED_PREVIEW", decision: "GO_PREVIEW" },
        { code: "COMMERCIAL_APPROVAL", status: "APPROVED_PREVIEW", decision: "GO_PREVIEW" },
        { code: "LEGAL_KVKK_FINAL_APPROVAL", status: "PENDING_FINAL_APPROVAL", decision: "HOLD_REAL_ROLLOUT" },
        { code: "BILLING_PAYMENT_LIVE", status: "DISABLED_EXPECTED", decision: "HOLD_REAL_BILLING" }
      ],
      communication_approval: [
        { target: "cohort_customer", template: "controlled_rollout_invite", status: "DRAFT_APPROVED_PREVIEW", real_send_enabled: false },
        { target: "support_team", template: "cohort_watch_brief", status: "DRAFT_APPROVED_PREVIEW", real_send_enabled: false }
      ],
      safety_guards: [
        { code: "REAL_ROLLOUT_APPROVAL_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_ROLLOUT_ACTIVATION_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_FEATURE_FLAG_WRITE_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_CUSTOMER_NOTIFICATION_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_DATA_MUTATION_DISABLED", status: "ENFORCED", value: false }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "COHORT_SETUP_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "product", action: "APPROVAL_GATE_PREVIEW_READY", result: "READY" },
        { at: "2026-05-demo", actor: "system", action: "REAL_APPROVAL_DISABLED", result: "EXPECTED" }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || "controlled-pilot";
  }

  function approvalGateHeaders() {
    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Approval-Scope": "controlled-rollout-cohort-approval",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "controlled_rollout_cohort_approval",
      "X-Pix2pi-Step": "363"
    };
  }

  function validateApprovalScope(snapshot) {
    const errors = [];
    if (!snapshot || !snapshot.rollout_id) errors.push({ field: "rollout_id", code: "ROLLOUT_ID_REQUIRED" });
    if (!snapshot || !snapshot.cohort_id) errors.push({ field: "cohort_id", code: "COHORT_ID_REQUIRED" });
    if (!snapshot || !snapshot.approval_scope) errors.push({ field: "approval_scope", code: "APPROVAL_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.approvers)) errors.push({ field: "approvers", code: "APPROVERS_REQUIRED" });
    return { valid: errors.length === 0, errors: errors };
  }

  async function fetchApprovalSnapshot() {
    return JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
  }

  function buildApproverChecklist(snapshot) {
    const missing = (snapshot.approvers || []).filter(function (item) {
      return item.required && !["APPROVED_PREVIEW", "PENDING_FINAL_APPROVAL"].includes(item.status);
    });
    return { total: (snapshot.approvers || []).length, missing: missing, valid: missing.length === 0 };
  }

  function buildApprovalDecisionMatrix(snapshot) {
    const realHold = (snapshot.gates || []).filter(function (gate) {
      return gate.decision.indexOf("HOLD_REAL") === 0;
    });
    const previewGo = (snapshot.gates || []).filter(function (gate) {
      return gate.decision === "GO_PREVIEW";
    });
    return {
      preview_go_count: previewGo.length,
      real_hold_count: realHold.length,
      preview_decision: previewGo.length >= 4 ? "CONTROLLED_APPROVAL_PREVIEW_READY" : "APPROVAL_PREVIEW_HOLD",
      real_rollout_decision: "HOLD_REAL_ROLLOUT"
    };
  }

  function buildApprovalSafetyGuard(snapshot) {
    const failed = (snapshot.safety_guards || []).filter(function (item) {
      return item.value !== false || item.status !== "ENFORCED";
    });
    return { total: (snapshot.safety_guards || []).length, failed: failed, valid: failed.length === 0 };
  }

  function buildApprovalRuntimeContract(snapshot) {
    const checklist = buildApproverChecklist(snapshot);
    const matrix = buildApprovalDecisionMatrix(snapshot);
    const safety = buildApprovalSafetyGuard(snapshot);
    return {
      rollout_id: snapshot.rollout_id,
      cohort_id: snapshot.cohort_id,
      approval_scope: snapshot.approval_scope,
      correlation_id: snapshot.correlation_id,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateApprovalScope(snapshot),
      approver_checklist: checklist,
      decision_matrix: matrix,
      safety: safety,
      ready_for_step_364: checklist.valid && safety.valid && CONFIG.runtimeContract.readyForStep364,
      source: { surface: "controlled_rollout_cohort_approval", phase: "FAZ_7R", step: "363" }
    };
  }

  function renderList(targetId, list, attrs) {
    const target = document.getElementById(targetId);
    if (!target) return;
    target.innerHTML = "";
    (list || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "approval-card";
      Object.keys(attrs || {}).forEach(function (key) {
        row.setAttribute(key, item[attrs[key]] || "");
      });
      row.innerHTML = [
        "<strong>" + (item.role || item.code || item.target || item.action) + "</strong>",
        "<p>" + JSON.stringify(item).replace(/[{}"]/g, "") + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderApprovalScreen(snapshot) {
    const rollout = document.getElementById("approval-rollout-id");
    const cohort = document.getElementById("approval-cohort-id");
    const scope = document.getElementById("approval-scope-validation");
    const contract = buildApprovalRuntimeContract(snapshot);

    if (rollout) rollout.textContent = snapshot.rollout_id;
    if (cohort) cohort.textContent = snapshot.cohort_id;
    if (scope) scope.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";

    renderList("approval-approver-checklist", snapshot.approvers, { "data-role": "role", "data-status": "status" });
    renderList("approval-gates", snapshot.gates, { "data-gate-code": "code", "data-gate-status": "status" });
    renderList("approval-communication", snapshot.communication_approval, { "data-target": "target", "data-status": "status" });
    renderList("approval-safety-guards", snapshot.safety_guards, { "data-code": "code", "data-status": "status" });
    renderList("approval-audit-timeline", snapshot.audit_timeline, { "data-audit-action": "action" });

    const runtime = document.getElementById("approval-runtime-contract");
    if (runtime) {
      runtime.textContent = [
        "approval_preview_enabled=" + CONFIG.runtimeContract.approvalPreviewEnabled,
        "real_rollout_approval_enabled=" + CONFIG.runtimeContract.realRolloutApprovalEnabled,
        "real_rollout_activation_enabled=" + CONFIG.runtimeContract.realRolloutActivationEnabled,
        "real_feature_flag_write_enabled=" + CONFIG.runtimeContract.realFeatureFlagWriteEnabled,
        "real_data_mutation_enabled=" + CONFIG.runtimeContract.realDataMutationEnabled,
        "decision=" + contract.decision_matrix.preview_decision,
        "ready_for_step_364=" + CONFIG.runtimeContract.readyForStep364
      ].join(" / ");
    }

    document.body.setAttribute("data-controlled-rollout-cohort-approval-rendered", "true");
  }

  async function bootApprovalScreen() {
    const snapshot = await fetchApprovalSnapshot();
    renderApprovalScreen(snapshot);
    return buildApprovalRuntimeContract(snapshot);
  }

  window.Pix2piControlledRolloutCohortApproval = {
    CONFIG: CONFIG,
    approvalGateHeaders: approvalGateHeaders,
    validateApprovalScope: validateApprovalScope,
    fetchApprovalSnapshot: fetchApprovalSnapshot,
    buildApproverChecklist: buildApproverChecklist,
    buildApprovalDecisionMatrix: buildApprovalDecisionMatrix,
    buildApprovalSafetyGuard: buildApprovalSafetyGuard,
    buildApprovalRuntimeContract: buildApprovalRuntimeContract,
    renderApprovalScreen: renderApprovalScreen,
    bootApprovalScreen: bootApprovalScreen
  };
})();
/* PIX2PI_363_CONTROLLED_ROLLOUT_COHORT_APPROVAL_RUNTIME_END */
