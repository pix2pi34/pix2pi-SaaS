/* PIX2PI_356_CONTROLLED_GO_LIVE_DECISION_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "controlled_usage_go_live_decision",
    phase: "FAZ_7R",
    step: "356",
    decisionSnapshotEndpoint: "/api/customer-access/go-live-decision/snapshot",
    decisionPreviewEndpoint: "/api/customer-access/go-live-decision/preview",
    decisionAuditEndpoint: "/api/customer-access/go-live-decision/audit",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    userSessionKey: "pix2pi.panel.user.session",
    runtimeContract: {
      realCustomerGoLiveEnabled: false,
      realActivationEnabled: false,
      realPaymentEnabled: false,
      realBillingEnabled: false,
      realDataMutationEnabled: false,
      decisionPreviewEnabled: true,
      humanApprovalRequired: true,
      rollbackReadyRequired: true,
      fallbackDecisionSnapshotEnabled: true,
      readyForStep357: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      owner_user: "owner@example.invalid",
      owner_role: "OWNER_ADMIN",
      user_session_id: "USER_DEMO_SESSION",
      decision_scope: "controlled-usage-go-live-decision",
      correlation_id: "FAZ7R-356-DEMO-CORRELATION",
      prerequisites: [
        { step: "350", name: "panel_access_test", status: "PASS" },
        { step: "351", name: "pos_access_test", status: "PASS" },
        { step: "352", name: "tenant_isolation_check", status: "PASS" },
        { step: "353", name: "user_permission_check", status: "PASS" },
        { step: "354", name: "localization_customer_smoke", status: "PASS" },
        { step: "355", name: "first_real_usage_smoke", status: "PASS" }
      ],
      gates: [
        { code: "SECURITY_GATE", label: "Security gate", status: "PASS", decision: "GO_PREVIEW" },
        { code: "TENANT_ISOLATION_GATE", label: "Tenant isolation gate", status: "PASS", decision: "GO_PREVIEW" },
        { code: "PERMISSION_GATE", label: "Permission gate", status: "PASS", decision: "GO_PREVIEW" },
        { code: "LOCALIZATION_GATE", label: "Localization gate", status: "PASS", decision: "GO_PREVIEW" },
        { code: "ROUTE_GATE", label: "Panel / POS / Market route gate", status: "PASS", decision: "GO_PREVIEW" },
        { code: "DATA_MUTATION_SAFETY", label: "Data mutation safety", status: "PASS", decision: "GO_PREVIEW" },
        { code: "BILLING_PAYMENT_DISABLED", label: "Billing / payment disabled", status: "PASS", decision: "GO_PREVIEW" },
        { code: "SUPPORT_ROLLBACK_READY", label: "Support / rollback readiness", status: "PASS", decision: "READY_FOR_APPROVAL" }
      ],
      access_mode: {
        mode: "CONTROLLED_PREVIEW",
        real_customer_go_live_enabled: false,
        real_activation_enabled: false,
        allowed_for_human_approval: true,
        next_step: "357 - Controlled customer access activation"
      },
      approver_checklist: [
        { role: "Founder / Product Owner", required: true, status: "PENDING_APPROVAL" },
        { role: "Security / SRE", required: true, status: "PENDING_APPROVAL" },
        { role: "Legal / KVKK", required: true, status: "PENDING_APPROVAL" },
        { role: "Support Owner", required: true, status: "PENDING_APPROVAL" }
      ],
      risk_register: [
        { severity: "P1", risk: "Tenant isolation failure", mitigation: "STOP_GO_LIVE", status: "CONTROLLED" },
        { severity: "P1", risk: "Unexpected data mutation", mitigation: "STOP_GO_LIVE", status: "CONTROLLED" },
        { severity: "P2", risk: "Localization blocker", mitigation: "FIX_BEFORE_ACTIVATION", status: "CONTROLLED" },
        { severity: "P2", risk: "Support unavailable", mitigation: "DELAY_ACTIVATION", status: "CONTROLLED" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "FIRST_REAL_USAGE_SMOKE_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "CONTROLLED_GO_LIVE_DECISION_READY", result: "READY_FOR_APPROVAL" },
        { at: "2026-05-demo", actor: "system", action: "REAL_ACTIVATION_DISABLED", result: "EXPECTED" }
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

  function goLiveDecisionScopeHeaders() {
    const session = getUserSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-User-Session": session.session_id,
      "X-Go-Live-Decision-Scope": "controlled-usage-go-live-decision",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "controlled_customer_access_decision",
      "X-Pix2pi-Step": "356"
    };
  }

  function validateGoLiveDecisionScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    if (!snapshot || !snapshot.owner_user) errors.push({ field: "owner_user", code: "OWNER_USER_REQUIRED" });
    if (!snapshot || !snapshot.user_session_id) errors.push({ field: "user_session_id", code: "USER_SESSION_REQUIRED" });
    if (!snapshot || !snapshot.decision_scope) errors.push({ field: "decision_scope", code: "DECISION_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.gates)) errors.push({ field: "gates", code: "GATES_REQUIRED" });

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: goLiveDecisionScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("GO_LIVE_DECISION_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchGoLiveDecisionSnapshot() {
    try {
      return await apiJson(CONFIG.decisionSnapshotEndpoint);
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

  function buildPrerequisiteEvidenceChecklist(snapshot) {
    const failed = (snapshot.prerequisites || []).filter(function (item) {
      return item.status !== "PASS";
    });

    return {
      total: (snapshot.prerequisites || []).length,
      failed: failed,
      valid: failed.length === 0
    };
  }

  function buildGateDecision(snapshot, code) {
    const gate = (snapshot.gates || []).find(function (item) {
      return item.code === code;
    });

    if (!gate) {
      return {
        code: code,
        status: "MISSING",
        decision: "NO_GO",
        allowed: false
      };
    }

    return {
      code: gate.code,
      label: gate.label,
      status: gate.status,
      decision: gate.decision,
      allowed: gate.status === "PASS" && ["GO_PREVIEW", "READY_FOR_APPROVAL"].includes(gate.decision)
    };
  }

  function buildGoNoGoDecisionPreview(snapshot) {
    const prerequisites = buildPrerequisiteEvidenceChecklist(snapshot);
    const failedGates = (snapshot.gates || []).filter(function (gate) {
      return gate.status !== "PASS";
    });
    const riskBlocked = (snapshot.risk_register || []).some(function (risk) {
      return risk.status !== "CONTROLLED";
    });

    const allowedForApproval = prerequisites.valid && failedGates.length === 0 && !riskBlocked;

    return {
      decision: allowedForApproval ? "READY_FOR_APPROVAL" : "BLOCKED_BY_RISK",
      go_preview: allowedForApproval,
      real_customer_go_live_enabled: CONFIG.runtimeContract.realCustomerGoLiveEnabled,
      real_activation_enabled: CONFIG.runtimeContract.realActivationEnabled,
      human_approval_required: CONFIG.runtimeContract.humanApprovalRequired,
      ready_for_step_357: allowedForApproval && CONFIG.runtimeContract.readyForStep357,
      failed_gates: failedGates,
      prerequisites: prerequisites
    };
  }

  function buildControlledGoLiveRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      owner_user: snapshot.owner_user,
      owner_role: snapshot.owner_role,
      user_session_id: snapshot.user_session_id,
      decision_scope: snapshot.decision_scope,
      correlation_id: snapshot.correlation_id,
      gate_count: Array.isArray(snapshot.gates) ? snapshot.gates.length : 0,
      risk_count: Array.isArray(snapshot.risk_register) ? snapshot.risk_register.length : 0,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateGoLiveDecisionScope(snapshot),
      go_no_go_decision: buildGoNoGoDecisionPreview(snapshot),
      source: {
        surface: "controlled_usage_go_live_decision",
        phase: "FAZ_7R",
        step: "356"
      }
    };
  }

  function renderContext(snapshot) {
    const tenant = document.getElementById("go-live-tenant-id");
    const owner = document.getElementById("go-live-owner-user");
    const mode = document.getElementById("go-live-access-mode");
    const validation = document.getElementById("go-live-scope-validation");
    const contract = buildControlledGoLiveRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (owner) owner.textContent = snapshot.owner_user;
    if (mode) mode.textContent = snapshot.access_mode.mode;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderPrerequisites(snapshot) {
    const target = document.getElementById("go-live-prerequisite-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.prerequisites || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "decision-card";
      row.setAttribute("data-prerequisite-step", item.step);
      row.setAttribute("data-status", item.status);
      row.innerHTML = [
        "<strong>" + item.step + " / " + item.name + "</strong>",
        "<p>" + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderGateDecisions(snapshot) {
    const target = document.getElementById("go-live-gate-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.gates || []).forEach(function (gate) {
      const decision = buildGateDecision(snapshot, gate.code);
      const row = document.createElement("article");
      row.className = "decision-card";
      row.setAttribute("data-gate-code", gate.code);
      row.setAttribute("data-decision", decision.decision);
      row.innerHTML = [
        "<strong>" + gate.label + "</strong>",
        "<p>" + gate.status + " / " + decision.decision + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderApprovers(snapshot) {
    const target = document.getElementById("go-live-approver-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.approver_checklist || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "decision-card";
      row.setAttribute("data-approver-role", item.role);
      row.setAttribute("data-approval-status", item.status);
      row.innerHTML = [
        "<strong>" + item.role + "</strong>",
        "<p>required=" + item.required + " / " + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRiskRegister(snapshot) {
    const target = document.getElementById("go-live-risk-register");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.risk_register || []).forEach(function (risk) {
      const row = document.createElement("article");
      row.className = "decision-card";
      row.setAttribute("data-risk-severity", risk.severity);
      row.setAttribute("data-risk-status", risk.status);
      row.innerHTML = [
        "<strong>" + risk.severity + " / " + risk.risk + "</strong>",
        "<p>" + risk.mitigation + " / " + risk.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAuditTimeline(snapshot) {
    const target = document.getElementById("go-live-audit-timeline");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.audit_timeline || []).forEach(function (event) {
      const row = document.createElement("article");
      row.className = "decision-card";
      row.setAttribute("data-audit-action", event.action);
      row.innerHTML = [
        "<strong>" + event.action + "</strong>",
        "<p>" + event.at + " / " + event.actor + " / " + event.result + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("go-live-runtime-contract");
    if (!target) return;

    const contract = buildControlledGoLiveRuntimeContract(snapshot);

    target.textContent = [
      "real_customer_go_live_enabled=" + CONFIG.runtimeContract.realCustomerGoLiveEnabled,
      "real_activation_enabled=" + CONFIG.runtimeContract.realActivationEnabled,
      "real_data_mutation_enabled=" + CONFIG.runtimeContract.realDataMutationEnabled,
      "decision=" + contract.go_no_go_decision.decision,
      "human_approval_required=" + CONFIG.runtimeContract.humanApprovalRequired,
      "ready_for_step_357=" + CONFIG.runtimeContract.readyForStep357,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderGoLiveDecisionScreen(snapshot) {
    renderContext(snapshot);
    renderPrerequisites(snapshot);
    renderGateDecisions(snapshot);
    renderApprovers(snapshot);
    renderRiskRegister(snapshot);
    renderAuditTimeline(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-controlled-go-live-decision-rendered", "true");
  }

  async function bootGoLiveDecisionScreen() {
    const snapshot = await fetchGoLiveDecisionSnapshot();
    renderGoLiveDecisionScreen(snapshot);
    return buildControlledGoLiveRuntimeContract(snapshot);
  }

  window.Pix2piControlledGoLiveDecision = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getUserSession: getUserSession,
    goLiveDecisionScopeHeaders: goLiveDecisionScopeHeaders,
    validateGoLiveDecisionScope: validateGoLiveDecisionScope,
    fetchGoLiveDecisionSnapshot: fetchGoLiveDecisionSnapshot,
    buildPrerequisiteEvidenceChecklist: buildPrerequisiteEvidenceChecklist,
    buildGateDecision: buildGateDecision,
    buildGoNoGoDecisionPreview: buildGoNoGoDecisionPreview,
    buildControlledGoLiveRuntimeContract: buildControlledGoLiveRuntimeContract,
    renderContext: renderContext,
    renderPrerequisites: renderPrerequisites,
    renderGateDecisions: renderGateDecisions,
    renderApprovers: renderApprovers,
    renderRiskRegister: renderRiskRegister,
    renderAuditTimeline: renderAuditTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderGoLiveDecisionScreen: renderGoLiveDecisionScreen,
    bootGoLiveDecisionScreen: bootGoLiveDecisionScreen
  };
})();
/* PIX2PI_356_CONTROLLED_GO_LIVE_DECISION_RUNTIME_END */
