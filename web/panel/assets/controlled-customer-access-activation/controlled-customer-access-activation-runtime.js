/* PIX2PI_357_CONTROLLED_CUSTOMER_ACCESS_ACTIVATION_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "controlled_customer_access_activation",
    phase: "FAZ_7R",
    step: "357",
    activationSnapshotEndpoint: "/api/customer-access/activation/snapshot",
    activationPreviewEndpoint: "/api/customer-access/activation/preview",
    activationAuditEndpoint: "/api/customer-access/activation/audit",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    userSessionKey: "pix2pi.panel.user.session",
    runtimeContract: {
      realCustomerAccessActivationEnabled: false,
      realPanelAccessActivationEnabled: false,
      realPosAccessActivationEnabled: false,
      realMarketAccessActivationEnabled: false,
      realActivationTokenIssueEnabled: false,
      realCustomerNotificationSendEnabled: false,
      realDataMutationEnabled: false,
      activationPreviewEnabled: true,
      humanApprovalRequired: true,
      supportHandoffRequired: true,
      monitoringReadyRequired: true,
      rollbackReadyRequired: true,
      fallbackActivationSnapshotEnabled: true,
      readyForStep358: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      customer_name: "Demo Market",
      owner_user: "owner@example.invalid",
      owner_role: "OWNER_ADMIN",
      user_session_id: "USER_DEMO_SESSION",
      activation_scope: "controlled-customer-access-activation",
      activation_window: "CONTROLLED_BUSINESS_HOURS",
      correlation_id: "FAZ7R-357-DEMO-CORRELATION",
      approval_binding: [
        { role: "Founder / Product Owner", required: true, status: "PENDING_APPROVAL" },
        { role: "Security / SRE", required: true, status: "PENDING_APPROVAL" },
        { role: "Legal / KVKK", required: true, status: "PENDING_APPROVAL" },
        { role: "Support Owner", required: true, status: "PENDING_APPROVAL" }
      ],
      access_toggles: [
        { surface: "panel", action: "activate_panel_access", preview: true, real_enabled: false, decision: "PREVIEW_ONLY" },
        { surface: "pos", action: "activate_pos_access", preview: true, real_enabled: false, decision: "PREVIEW_ONLY" },
        { surface: "market", action: "activate_market_access", preview: true, real_enabled: false, decision: "PREVIEW_ONLY" },
        { surface: "token", action: "issue_activation_token", preview: true, real_enabled: false, decision: "DISABLED_EXPECTED" }
      ],
      safety_guards: [
        { code: "REAL_CUSTOMER_ACCESS_ACTIVATION_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_PANEL_ACCESS_ACTIVATION_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_POS_ACCESS_ACTIVATION_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_MARKET_ACCESS_ACTIVATION_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_DATA_MUTATION_DISABLED", status: "ENFORCED", value: false }
      ],
      handoff: [
        { area: "support", item: "support_channel_ready", status: "READY_PREVIEW" },
        { area: "monitoring", item: "first_day_watch_dashboard_ready", status: "READY_PREVIEW" },
        { area: "incident", item: "pilot_incident_route_ready", status: "READY_PREVIEW" },
        { area: "rollback", item: "deactivate_access_preview_ready", status: "READY_PREVIEW" }
      ],
      customer_notification_preview: [
        { channel: "email", template: "controlled_access_ready", real_send_enabled: false, status: "PREVIEW_ONLY" },
        { channel: "sms", template: "controlled_access_ready", real_send_enabled: false, status: "PREVIEW_ONLY" },
        { channel: "whatsapp", template: "controlled_access_ready", real_send_enabled: false, status: "PREVIEW_ONLY" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "GO_LIVE_DECISION_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "CONTROLLED_ACTIVATION_PREVIEW_READY", result: "DRY_RUN" },
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

  function activationScopeHeaders() {
    const session = getUserSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-User-Session": session.session_id,
      "X-Activation-Scope": "controlled-customer-access-activation",
      "X-Human-Approval-Status": "PENDING_APPROVAL",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "controlled_customer_access_activation",
      "X-Pix2pi-Step": "357"
    };
  }

  function validateActivationScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    if (!snapshot || !snapshot.customer_name) errors.push({ field: "customer_name", code: "CUSTOMER_REQUIRED" });
    if (!snapshot || !snapshot.owner_user) errors.push({ field: "owner_user", code: "OWNER_USER_REQUIRED" });
    if (!snapshot || !snapshot.user_session_id) errors.push({ field: "user_session_id", code: "USER_SESSION_REQUIRED" });
    if (!snapshot || !snapshot.activation_scope) errors.push({ field: "activation_scope", code: "ACTIVATION_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.access_toggles)) errors.push({ field: "access_toggles", code: "ACCESS_TOGGLES_REQUIRED" });

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: activationScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("CONTROLLED_ACTIVATION_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchActivationSnapshot() {
    try {
      return await apiJson(CONFIG.activationSnapshotEndpoint);
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

  function buildApprovalBindingPreview(snapshot) {
    const pending = (snapshot.approval_binding || []).filter(function (item) {
      return item.required && item.status !== "APPROVED";
    });

    return {
      total: (snapshot.approval_binding || []).length,
      pending: pending,
      human_approval_required: CONFIG.runtimeContract.humanApprovalRequired,
      valid_for_preview: true,
      valid_for_real_activation: pending.length === 0
    };
  }

  function buildAccessTogglePreview(snapshot, surface) {
    const toggle = (snapshot.access_toggles || []).find(function (item) {
      return item.surface === surface;
    });

    if (!toggle) {
      return {
        surface: surface,
        decision: "MISSING",
        preview: false,
        real_enabled: false
      };
    }

    return {
      surface: toggle.surface,
      action: toggle.action,
      preview: toggle.preview,
      real_enabled: toggle.real_enabled,
      decision: toggle.decision
    };
  }

  function buildDataMutationSafetyGuard(snapshot) {
    const failed = (snapshot.safety_guards || []).filter(function (item) {
      return item.value !== false || item.status !== "ENFORCED";
    });

    return {
      total: (snapshot.safety_guards || []).length,
      failed: failed,
      valid: failed.length === 0,
      real_data_mutation_enabled: CONFIG.runtimeContract.realDataMutationEnabled
    };
  }

  function buildActivationDecisionPreview(snapshot) {
    const approvals = buildApprovalBindingPreview(snapshot);
    const safety = buildDataMutationSafetyGuard(snapshot);

    return {
      decision: approvals.valid_for_preview && safety.valid ? "ACTIVATION_PREVIEW_READY" : "ACTIVATION_PREVIEW_BLOCKED",
      real_activation_enabled: CONFIG.runtimeContract.realCustomerAccessActivationEnabled,
      human_approval_required: CONFIG.runtimeContract.humanApprovalRequired,
      valid_for_real_activation: approvals.valid_for_real_activation && safety.valid,
      ready_for_step_358: CONFIG.runtimeContract.readyForStep358
    };
  }

  function buildActivationRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      customer_name: snapshot.customer_name,
      owner_user: snapshot.owner_user,
      owner_role: snapshot.owner_role,
      user_session_id: snapshot.user_session_id,
      activation_scope: snapshot.activation_scope,
      activation_window: snapshot.activation_window,
      correlation_id: snapshot.correlation_id,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateActivationScope(snapshot),
      approval_binding: buildApprovalBindingPreview(snapshot),
      panel_access: buildAccessTogglePreview(snapshot, "panel"),
      pos_access: buildAccessTogglePreview(snapshot, "pos"),
      market_access: buildAccessTogglePreview(snapshot, "market"),
      token_handoff: buildAccessTogglePreview(snapshot, "token"),
      safety: buildDataMutationSafetyGuard(snapshot),
      activation_decision: buildActivationDecisionPreview(snapshot),
      source: {
        surface: "controlled_customer_access_activation",
        phase: "FAZ_7R",
        step: "357"
      }
    };
  }

  function renderContext(snapshot) {
    const tenant = document.getElementById("activation-tenant-id");
    const customer = document.getElementById("activation-customer-name");
    const owner = document.getElementById("activation-owner-user");
    const windowEl = document.getElementById("activation-window");
    const validation = document.getElementById("activation-scope-validation");
    const contract = buildActivationRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (customer) customer.textContent = snapshot.customer_name;
    if (owner) owner.textContent = snapshot.owner_user;
    if (windowEl) windowEl.textContent = snapshot.activation_window;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderApprovals(snapshot) {
    const target = document.getElementById("activation-approval-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.approval_binding || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "activation-card";
      row.setAttribute("data-approval-role", item.role);
      row.setAttribute("data-approval-status", item.status);
      row.innerHTML = [
        "<strong>" + item.role + "</strong>",
        "<p>required=" + item.required + " / " + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAccessToggles(snapshot) {
    const target = document.getElementById("activation-access-toggle-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.access_toggles || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "activation-card";
      row.setAttribute("data-toggle-surface", item.surface);
      row.setAttribute("data-real-enabled", String(item.real_enabled));
      row.setAttribute("data-decision", item.decision);
      row.innerHTML = [
        "<strong>" + item.surface + " / " + item.action + "</strong>",
        "<p>preview=" + item.preview + " / real_enabled=" + item.real_enabled + " / " + item.decision + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderSafetyGuards(snapshot) {
    const target = document.getElementById("activation-safety-guards");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.safety_guards || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "activation-card";
      row.setAttribute("data-safety-code", item.code);
      row.setAttribute("data-safety-status", item.status);
      row.innerHTML = [
        "<strong>" + item.code + "</strong>",
        "<p>" + item.status + " / value=" + item.value + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderHandoff(snapshot) {
    const target = document.getElementById("activation-handoff-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.handoff || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "activation-card";
      row.setAttribute("data-handoff-area", item.area);
      row.setAttribute("data-handoff-status", item.status);
      row.innerHTML = [
        "<strong>" + item.area + " / " + item.item + "</strong>",
        "<p>" + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderNotifications(snapshot) {
    const target = document.getElementById("activation-notification-preview");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.customer_notification_preview || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "activation-card";
      row.setAttribute("data-notification-channel", item.channel);
      row.innerHTML = [
        "<strong>" + item.channel + " / " + item.template + "</strong>",
        "<p>real_send_enabled=" + item.real_send_enabled + " / " + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAuditTimeline(snapshot) {
    const target = document.getElementById("activation-audit-timeline");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.audit_timeline || []).forEach(function (event) {
      const row = document.createElement("article");
      row.className = "activation-card";
      row.setAttribute("data-audit-action", event.action);
      row.innerHTML = [
        "<strong>" + event.action + "</strong>",
        "<p>" + event.at + " / " + event.actor + " / " + event.result + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("activation-runtime-contract");
    if (!target) return;

    const contract = buildActivationRuntimeContract(snapshot);

    target.textContent = [
      "real_customer_access_activation_enabled=" + CONFIG.runtimeContract.realCustomerAccessActivationEnabled,
      "real_panel_access_activation_enabled=" + CONFIG.runtimeContract.realPanelAccessActivationEnabled,
      "real_pos_access_activation_enabled=" + CONFIG.runtimeContract.realPosAccessActivationEnabled,
      "real_market_access_activation_enabled=" + CONFIG.runtimeContract.realMarketAccessActivationEnabled,
      "real_data_mutation_enabled=" + CONFIG.runtimeContract.realDataMutationEnabled,
      "decision=" + contract.activation_decision.decision,
      "ready_for_step_358=" + CONFIG.runtimeContract.readyForStep358,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderActivationScreen(snapshot) {
    renderContext(snapshot);
    renderApprovals(snapshot);
    renderAccessToggles(snapshot);
    renderSafetyGuards(snapshot);
    renderHandoff(snapshot);
    renderNotifications(snapshot);
    renderAuditTimeline(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-controlled-customer-access-activation-rendered", "true");
  }

  async function bootActivationScreen() {
    const snapshot = await fetchActivationSnapshot();
    renderActivationScreen(snapshot);
    return buildActivationRuntimeContract(snapshot);
  }

  window.Pix2piControlledCustomerAccessActivation = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getUserSession: getUserSession,
    activationScopeHeaders: activationScopeHeaders,
    validateActivationScope: validateActivationScope,
    fetchActivationSnapshot: fetchActivationSnapshot,
    buildApprovalBindingPreview: buildApprovalBindingPreview,
    buildAccessTogglePreview: buildAccessTogglePreview,
    buildDataMutationSafetyGuard: buildDataMutationSafetyGuard,
    buildActivationDecisionPreview: buildActivationDecisionPreview,
    buildActivationRuntimeContract: buildActivationRuntimeContract,
    renderContext: renderContext,
    renderApprovals: renderApprovals,
    renderAccessToggles: renderAccessToggles,
    renderSafetyGuards: renderSafetyGuards,
    renderHandoff: renderHandoff,
    renderNotifications: renderNotifications,
    renderAuditTimeline: renderAuditTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderActivationScreen: renderActivationScreen,
    bootActivationScreen: bootActivationScreen
  };
})();
/* PIX2PI_357_CONTROLLED_CUSTOMER_ACCESS_ACTIVATION_RUNTIME_END */
