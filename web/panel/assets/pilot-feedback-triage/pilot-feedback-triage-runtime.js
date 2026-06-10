/* PIX2PI_359_PILOT_FEEDBACK_TRIAGE_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "pilot_feedback_issue_triage",
    phase: "FAZ_7R",
    step: "359",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    userSessionKey: "pix2pi.panel.user.session",
    runtimeContract: {
      realTicketCreateEnabled: false,
      realCustomerNotificationSendEnabled: false,
      realHotfixDeployEnabled: false,
      realDataMutationEnabled: false,
      feedbackTriagePreviewEnabled: true,
      issueQueuePreviewEnabled: true,
      supportResponseDraftPreviewEnabled: true,
      hotfixDecisionPreviewEnabled: true,
      readyForStep360: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      customer_name: "Demo Market",
      owner_user: "owner@example.invalid",
      feedback_scope: "pilot-feedback-issue-triage",
      correlation_id: "FAZ7R-359-DEMO-CORRELATION",
      intake_channels: [
        { channel: "phone", status: "READY_PREVIEW" },
        { channel: "email", status: "READY_PREVIEW" },
        { channel: "whatsapp", status: "READY_PREVIEW" },
        { channel: "panel_feedback_form", status: "PREVIEW_ONLY" }
      ],
      sentiment: {
        score: 82,
        label: "POSITIVE_PREVIEW",
        blocker_count: 0,
        friction_count: 2
      },
      issues: [
        { id: "PILOT-ISSUE-001", title: "Ürün arama filtresi daha görünür olsun", severity: "P3", priority: "P2", status: "TRIAGE_PREVIEW", owner: "product" },
        { id: "PILOT-ISSUE-002", title: "POS buton yazıları büyütülsün", severity: "P3", priority: "P2", status: "TRIAGE_PREVIEW", owner: "frontend" },
        { id: "PILOT-ISSUE-003", title: "Gerçek ödeme kapalı beklenen durum", severity: "INFO", priority: "P4", status: "EXPECTED_DISABLED", owner: "commercial" }
      ],
      duplicate_merge: [
        { source: "PILOT-ISSUE-002", target: "UX-POS-BUTTONS", decision: "MERGE_PREVIEW" }
      ],
      escalation_links: [
        { issue: "PILOT-ISSUE-001", incident: "NONE", decision: "NO_ESCALATION" },
        { issue: "PILOT-ISSUE-002", incident: "NONE", decision: "NO_ESCALATION" }
      ],
      backlog_candidates: [
        { issue: "PILOT-ISSUE-001", backlog: "PRODUCT_DISCOVERY", decision: "ADD_TO_BACKLOG_PREVIEW" },
        { issue: "PILOT-ISSUE-002", backlog: "UX_POLISH", decision: "ADD_TO_BACKLOG_PREVIEW" }
      ],
      support_drafts: [
        { channel: "whatsapp", issue: "PILOT-ISSUE-001", status: "DRAFT_ONLY" },
        { channel: "email", issue: "PILOT-ISSUE-002", status: "DRAFT_ONLY" }
      ],
      hotfix_decisions: [
        { issue: "PILOT-ISSUE-001", decision: "NO_HOTFIX_BACKLOG", reason: "non_blocker" },
        { issue: "PILOT-ISSUE-002", decision: "NO_HOTFIX_BACKLOG", reason: "non_blocker" }
      ],
      rollback_review: [
        { trigger: "P1_INCIDENT", current: 0, decision: "NO_ROLLBACK" },
        { trigger: "TENANT_SCOPE_VIOLATION", current: 0, decision: "NO_ROLLBACK" },
        { trigger: "UNEXPECTED_MUTATION", current: 0, decision: "NO_ROLLBACK" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "FIRST_DAY_WATCH_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "support", action: "FEEDBACK_TRIAGE_PREVIEW_READY", result: "DRY_RUN" },
        { at: "2026-05-demo", actor: "system", action: "HOTFIX_DECISION_PREVIEW_READY", result: "NO_HOTFIX" }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSnapshot.tenant_id;
  }

  function getUserSession() {
    const raw = window.localStorage.getItem(CONFIG.userSessionKey);
    if (!raw) {
      return { session_present: false, session_id: "USER_DEMO_SESSION", email: CONFIG.fallbackSnapshot.owner_user };
    }
    try { return Object.assign({ session_present: true }, JSON.parse(raw)); }
    catch (_error) { return { session_present: false, session_id: "INVALID_USER_SESSION", email: "unknown@example.invalid" }; }
  }

  function feedbackScopeHeaders() {
    const session = getUserSession();
    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-User-Session": session.session_id,
      "X-Feedback-Scope": "pilot-feedback-issue-triage",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "pilot_feedback_issue_triage",
      "X-Pix2pi-Step": "359"
    };
  }

  function validateFeedbackScope(snapshot) {
    const errors = [];
    if (!snapshot || !snapshot.tenant_id) errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    if (!snapshot || !snapshot.customer_name) errors.push({ field: "customer_name", code: "CUSTOMER_REQUIRED" });
    if (!snapshot || !snapshot.feedback_scope) errors.push({ field: "feedback_scope", code: "FEEDBACK_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.issues)) errors.push({ field: "issues", code: "ISSUE_QUEUE_REQUIRED" });
    return { valid: errors.length === 0, errors: errors };
  }

  async function fetchFeedbackSnapshot() {
    const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
    snapshot.tenant_id = getTenantId();
    return snapshot;
  }

  function buildIssueTriageQueue(snapshot) {
    const blockers = (snapshot.issues || []).filter(function (issue) {
      return issue.severity === "P1" || issue.severity === "P2";
    });
    return { total: (snapshot.issues || []).length, blockers: blockers, valid: blockers.length === 0 };
  }

  function buildSeverityPriorityDecision(snapshot) {
    return (snapshot.issues || []).map(function (issue) {
      return {
        id: issue.id,
        severity: issue.severity,
        priority: issue.priority,
        decision: issue.severity === "P1" ? "ESCALATE" : "TRIAGE_BACKLOG"
      };
    });
  }

  function buildOwnerAssignmentPreview(snapshot) {
    const missing = (snapshot.issues || []).filter(function (issue) { return !issue.owner; });
    return { total: (snapshot.issues || []).length, missing_owner: missing, valid: missing.length === 0 };
  }

  function buildHotfixDecisionPreview(snapshot) {
    const hotfixRequired = (snapshot.hotfix_decisions || []).filter(function (item) {
      return item.decision === "HOTFIX_REQUIRED";
    });
    return { total: (snapshot.hotfix_decisions || []).length, hotfix_required: hotfixRequired, decision: hotfixRequired.length ? "HOTFIX_QUEUE" : "NO_HOTFIX" };
  }

  function buildFeedbackTriageRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      customer_name: snapshot.customer_name,
      owner_user: snapshot.owner_user,
      feedback_scope: snapshot.feedback_scope,
      correlation_id: snapshot.correlation_id,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateFeedbackScope(snapshot),
      issue_triage_queue: buildIssueTriageQueue(snapshot),
      severity_priority: buildSeverityPriorityDecision(snapshot),
      owner_assignment: buildOwnerAssignmentPreview(snapshot),
      hotfix_decision: buildHotfixDecisionPreview(snapshot),
      ready_for_step_360: CONFIG.runtimeContract.readyForStep360,
      source: { surface: "pilot_feedback_issue_triage", phase: "FAZ_7R", step: "359" }
    };
  }

  function renderList(targetId, list, attrs) {
    const target = document.getElementById(targetId);
    if (!target) return;
    target.innerHTML = "";
    (list || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "triage-card";
      Object.keys(attrs || {}).forEach(function (key) { row.setAttribute(key, item[attrs[key]] || ""); });
      row.innerHTML = [
        "<strong>" + (item.id || item.channel || item.issue || item.trigger || item.action || item.title) + "</strong>",
        "<p>" + JSON.stringify(item).replace(/[{}"]/g, "") + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderFeedbackTriageScreen(snapshot) {
    const tenant = document.getElementById("triage-tenant-id");
    const customer = document.getElementById("triage-customer-name");
    const owner = document.getElementById("triage-owner-user");
    const sentiment = document.getElementById("triage-sentiment");
    const scope = document.getElementById("triage-scope-validation");
    const contract = buildFeedbackTriageRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (customer) customer.textContent = snapshot.customer_name;
    if (owner) owner.textContent = snapshot.owner_user;
    if (sentiment) sentiment.textContent = snapshot.sentiment.label + " / score=" + snapshot.sentiment.score;
    if (scope) scope.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";

    renderList("triage-intake-channels", snapshot.intake_channels, { "data-channel": "channel", "data-status": "status" });
    renderList("triage-issue-queue", snapshot.issues, { "data-issue-id": "id", "data-severity": "severity", "data-priority": "priority" });
    renderList("triage-duplicate-merge", snapshot.duplicate_merge, { "data-source": "source", "data-decision": "decision" });
    renderList("triage-escalation-links", snapshot.escalation_links, { "data-issue": "issue", "data-decision": "decision" });
    renderList("triage-backlog-candidates", snapshot.backlog_candidates, { "data-issue": "issue", "data-decision": "decision" });
    renderList("triage-support-drafts", snapshot.support_drafts, { "data-channel": "channel", "data-status": "status" });
    renderList("triage-hotfix-decisions", snapshot.hotfix_decisions, { "data-issue": "issue", "data-decision": "decision" });
    renderList("triage-rollback-review", snapshot.rollback_review, { "data-trigger": "trigger", "data-decision": "decision" });
    renderList("triage-audit-timeline", snapshot.audit_timeline, { "data-audit-action": "action" });

    const runtime = document.getElementById("triage-runtime-contract");
    if (runtime) {
      runtime.textContent = [
        "feedback_triage_preview_enabled=" + CONFIG.runtimeContract.feedbackTriagePreviewEnabled,
        "real_ticket_create_enabled=" + CONFIG.runtimeContract.realTicketCreateEnabled,
        "real_hotfix_deploy_enabled=" + CONFIG.runtimeContract.realHotfixDeployEnabled,
        "real_data_mutation_enabled=" + CONFIG.runtimeContract.realDataMutationEnabled,
        "hotfix_decision=" + contract.hotfix_decision.decision,
        "ready_for_step_360=" + CONFIG.runtimeContract.readyForStep360
      ].join(" / ");
    }

    document.body.setAttribute("data-pilot-feedback-triage-rendered", "true");
  }

  async function bootFeedbackTriageScreen() {
    const snapshot = await fetchFeedbackSnapshot();
    renderFeedbackTriageScreen(snapshot);
    return buildFeedbackTriageRuntimeContract(snapshot);
  }

  window.Pix2piPilotFeedbackTriage = {
    CONFIG: CONFIG,
    feedbackScopeHeaders: feedbackScopeHeaders,
    validateFeedbackScope: validateFeedbackScope,
    fetchFeedbackSnapshot: fetchFeedbackSnapshot,
    buildIssueTriageQueue: buildIssueTriageQueue,
    buildSeverityPriorityDecision: buildSeverityPriorityDecision,
    buildOwnerAssignmentPreview: buildOwnerAssignmentPreview,
    buildHotfixDecisionPreview: buildHotfixDecisionPreview,
    buildFeedbackTriageRuntimeContract: buildFeedbackTriageRuntimeContract,
    renderFeedbackTriageScreen: renderFeedbackTriageScreen,
    bootFeedbackTriageScreen: bootFeedbackTriageScreen
  };
})();
/* PIX2PI_359_PILOT_FEEDBACK_TRIAGE_RUNTIME_END */
