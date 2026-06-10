/* PIX2PI_352_TENANT_ISOLATION_CHECK_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "tenant_isolation_check",
    phase: "FAZ_7R",
    step: "352",
    tenantIsolationSnapshotEndpoint: "/api/security/tenant-isolation/snapshot",
    tenantIsolationDecisionEndpoint: "/api/security/tenant-isolation/decision",
    tenantIsolationAuditEndpoint: "/api/security/tenant-isolation/audit",
    sourceTenantKey: "pix2pi.panel.tenant.preference",
    userSessionKey: "pix2pi.panel.user.session",
    runtimeContract: {
      realCrossTenantQueryEnabled: false,
      realBreakGlassEnabled: false,
      realExportEnabled: false,
      realCustomerAccessEnabled: false,
      tenantIsolationPreviewEnabled: true,
      crossTenantDenialPreviewEnabled: true,
      rlsReadinessPreviewEnabled: true,
      fallbackIsolationSnapshotEnabled: true,
      readyForStep353: true
    },
    fallbackSnapshot: {
      source_tenant_id: "controlled-pilot",
      source_tenant_slug: "demo-market",
      target_tenant_id: "blocked-other-tenant",
      target_tenant_slug: "other-market",
      user_session_id: "USER_DEMO_SESSION",
      user_email: "owner@example.invalid",
      user_role: "OWNER_ADMIN",
      isolation_scope: "controlled-tenant-isolation-check",
      correlation_id: "FAZ7R-352-DEMO-CORRELATION",
      rls_status: "PREVIEW_READY",
      cross_tenant_status: "DENIED_PREVIEW",
      checks: [
        { code: "RLS_ENABLED", label: "RLS enabled", status: "READY", decision: "ALLOW_SAME_TENANT" },
        { code: "RLS_FORCED", label: "RLS forced", status: "READY", decision: "ALLOW_SAME_TENANT" },
        { code: "TENANT_CONTEXT_REQUIRED", label: "Tenant context required", status: "READY", decision: "ALLOW_SAME_TENANT" },
        { code: "CROSS_TENANT_SELECT_DENIED", label: "Cross-tenant select denied", status: "READY", decision: "DENY_CROSS_TENANT" },
        { code: "CROSS_TENANT_EXPORT_DENIED", label: "Cross-tenant export denied", status: "READY", decision: "DENY_EXPORT_SCOPE" }
      ],
      guards: [
        { surface: "panel", scope: "route/data", decision: "ALLOW_SAME_TENANT" },
        { surface: "pos", scope: "store/register/data", decision: "ALLOW_SAME_TENANT" },
        { surface: "marketplace", scope: "storefront/product/order", decision: "ALLOW_SAME_TENANT" },
        { surface: "audit_export", scope: "tenant/export", decision: "DENY_EXPORT_SCOPE" },
        { surface: "break_glass", scope: "emergency/admin", decision: "DENY_BREAK_GLASS_DISABLED" }
      ],
      regression: [
        { test: "same_tenant_panel_read", expected: "ALLOW", status: "PASS_PREVIEW" },
        { test: "cross_tenant_panel_read", expected: "DENY", status: "PASS_PREVIEW" },
        { test: "cross_tenant_pos_read", expected: "DENY", status: "PASS_PREVIEW" },
        { test: "cross_tenant_market_order_read", expected: "DENY", status: "PASS_PREVIEW" }
      ],
      incident_preview: [
        { severity: "P1", code: "TENANT_ISOLATION_BREACH", status: "PREVIEW_ONLY" },
        { severity: "P2", code: "EXPORT_SCOPE_BREACH", status: "PREVIEW_ONLY" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "POS_ACCESS_TEST_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "TENANT_ISOLATION_PREVIEW_READY", result: "DRY_RUN" },
        { at: "2026-05-demo", actor: "system", action: "CROSS_TENANT_ACCESS_DENIED", result: "EXPECTED" }
      ]
    }
  };

  function getSourceTenantId() {
    return window.localStorage.getItem(CONFIG.sourceTenantKey) || CONFIG.fallbackSnapshot.source_tenant_id;
  }

  function getUserSession() {
    const raw = window.localStorage.getItem(CONFIG.userSessionKey);
    if (!raw) {
      return {
        session_present: false,
        session_id: CONFIG.fallbackSnapshot.user_session_id,
        role: CONFIG.fallbackSnapshot.user_role,
        email: CONFIG.fallbackSnapshot.user_email
      };
    }

    try {
      return Object.assign({ session_present: true }, JSON.parse(raw));
    } catch (_error) {
      return {
        session_present: false,
        session_id: "INVALID_USER_SESSION",
        role: "UNKNOWN",
        email: "unknown@example.invalid"
      };
    }
  }

  function tenantIsolationScopeHeaders() {
    const session = getUserSession();

    return {
      "Content-Type": "application/json",
      "X-Source-Tenant-ID": getSourceTenantId(),
      "X-Target-Tenant-ID": CONFIG.fallbackSnapshot.target_tenant_id,
      "X-User-Session": session.session_id,
      "X-Isolation-Scope": "controlled-tenant-isolation-check",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "merchant_panel_controlled_access",
      "X-Pix2pi-Step": "352"
    };
  }

  function validateTenantIsolationScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.source_tenant_id) errors.push({ field: "source_tenant_id", code: "SOURCE_TENANT_REQUIRED" });
    if (!snapshot || !snapshot.target_tenant_id) errors.push({ field: "target_tenant_id", code: "TARGET_TENANT_REQUIRED" });
    if (!snapshot || !snapshot.user_session_id) errors.push({ field: "user_session_id", code: "USER_SESSION_REQUIRED" });
    if (!snapshot || !snapshot.isolation_scope) errors.push({ field: "isolation_scope", code: "ISOLATION_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.checks)) errors.push({ field: "checks", code: "CHECKS_REQUIRED" });

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: tenantIsolationScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("TENANT_ISOLATION_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchTenantIsolationSnapshot() {
    try {
      return await apiJson(CONFIG.tenantIsolationSnapshotEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      const session = getUserSession();
      snapshot.source_tenant_id = getSourceTenantId();
      snapshot.user_session_id = session.session_id;
      snapshot.user_role = session.role || snapshot.user_role;
      snapshot.user_email = session.email || snapshot.user_email;
      return snapshot;
    }
  }

  function buildIsolationDecision(snapshot, requestedTenantId, action) {
    const sameTenant = String(requestedTenantId) === String(snapshot.source_tenant_id);

    if (action === "BREAK_GLASS") {
      return { action: action, decision: "DENY_BREAK_GLASS_DISABLED", reason: "REAL_BREAK_GLASS_DISABLED_IN_STEP_352", allowed: false };
    }

    if (action === "EXPORT" && !sameTenant) {
      return { action: action, decision: "DENY_EXPORT_SCOPE", reason: "CROSS_TENANT_EXPORT_DENIED", allowed: false };
    }

    if (!sameTenant) {
      return { action: action, decision: "DENY_CROSS_TENANT", reason: "SOURCE_TARGET_TENANT_MISMATCH", allowed: false };
    }

    return { action: action, decision: "ALLOW_SAME_TENANT", reason: "TENANT_SCOPE_MATCH", allowed: true };
  }

  function buildCrossTenantAccessDenialPreview(snapshot) {
    return Object.assign(
      {
        source_tenant_id: snapshot.source_tenant_id,
        target_tenant_id: snapshot.target_tenant_id,
        preview_only: true,
        real_cross_tenant_query_enabled: CONFIG.runtimeContract.realCrossTenantQueryEnabled
      },
      buildIsolationDecision(snapshot, snapshot.target_tenant_id, "READ")
    );
  }

  function buildTenantIsolationRuntimeContract(snapshot) {
    return {
      source_tenant_id: snapshot.source_tenant_id,
      target_tenant_id: snapshot.target_tenant_id,
      user_session_id: snapshot.user_session_id,
      user_role: snapshot.user_role,
      isolation_scope: snapshot.isolation_scope,
      rls_status: snapshot.rls_status,
      cross_tenant_status: snapshot.cross_tenant_status,
      check_count: Array.isArray(snapshot.checks) ? snapshot.checks.length : 0,
      guard_count: Array.isArray(snapshot.guards) ? snapshot.guards.length : 0,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateTenantIsolationScope(snapshot),
      cross_tenant_decision: buildCrossTenantAccessDenialPreview(snapshot),
      source: {
        surface: "tenant_isolation_check",
        phase: "FAZ_7R",
        step: "352"
      }
    };
  }

  function renderContext(snapshot) {
    const sourceTenant = document.getElementById("isolation-source-tenant");
    const targetTenant = document.getElementById("isolation-target-tenant");
    const session = document.getElementById("isolation-user-session");
    const role = document.getElementById("isolation-user-role");
    const validation = document.getElementById("isolation-scope-validation");
    const contract = buildTenantIsolationRuntimeContract(snapshot);

    if (sourceTenant) sourceTenant.textContent = snapshot.source_tenant_id;
    if (targetTenant) targetTenant.textContent = snapshot.target_tenant_id;
    if (session) session.textContent = snapshot.user_session_id;
    if (role) role.textContent = snapshot.user_role;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderChecks(snapshot) {
    const target = document.getElementById("isolation-rls-checklist");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.checks || []).forEach(function (check) {
      const row = document.createElement("article");
      row.className = "iso-card";
      row.setAttribute("data-check-code", check.code);
      row.setAttribute("data-decision", check.decision);
      row.innerHTML = [
        "<strong>" + check.label + "</strong>",
        "<p>" + check.code + " / " + check.status + " / " + check.decision + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderGuards(snapshot) {
    const target = document.getElementById("isolation-guard-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.guards || []).forEach(function (guard) {
      const row = document.createElement("article");
      row.className = "iso-card";
      row.setAttribute("data-guard-surface", guard.surface);
      row.setAttribute("data-decision", guard.decision);
      row.innerHTML = [
        "<strong>" + guard.surface + "</strong>",
        "<p>" + guard.scope + " / " + guard.decision + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRegression(snapshot) {
    const target = document.getElementById("isolation-regression-checklist");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.regression || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "iso-card";
      row.setAttribute("data-regression-test", item.test);
      row.innerHTML = [
        "<strong>" + item.test + "</strong>",
        "<p>expected=" + item.expected + " / " + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderIncidentPreview(snapshot) {
    const target = document.getElementById("isolation-incident-preview");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.incident_preview || []).forEach(function (incident) {
      const row = document.createElement("article");
      row.className = "iso-card";
      row.setAttribute("data-incident-code", incident.code);
      row.innerHTML = [
        "<strong>" + incident.code + "</strong>",
        "<p>" + incident.severity + " / " + incident.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAuditTimeline(snapshot) {
    const target = document.getElementById("isolation-audit-timeline");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.audit_timeline || []).forEach(function (event) {
      const row = document.createElement("article");
      row.className = "iso-card";
      row.setAttribute("data-audit-action", event.action);
      row.innerHTML = [
        "<strong>" + event.action + "</strong>",
        "<p>" + event.at + " / " + event.actor + " / " + event.result + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("isolation-runtime-contract");
    if (!target) return;

    const contract = buildTenantIsolationRuntimeContract(snapshot);

    target.textContent = [
      "real_cross_tenant_query_enabled=" + CONFIG.runtimeContract.realCrossTenantQueryEnabled,
      "real_break_glass_enabled=" + CONFIG.runtimeContract.realBreakGlassEnabled,
      "real_export_enabled=" + CONFIG.runtimeContract.realExportEnabled,
      "tenant_isolation_preview_enabled=" + CONFIG.runtimeContract.tenantIsolationPreviewEnabled,
      "cross_tenant_decision=" + contract.cross_tenant_decision.decision,
      "ready_for_step_353=" + CONFIG.runtimeContract.readyForStep353,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderTenantIsolationScreen(snapshot) {
    renderContext(snapshot);
    renderChecks(snapshot);
    renderGuards(snapshot);
    renderRegression(snapshot);
    renderIncidentPreview(snapshot);
    renderAuditTimeline(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-tenant-isolation-check-rendered", "true");
  }

  async function bootTenantIsolationScreen() {
    const snapshot = await fetchTenantIsolationSnapshot();
    renderTenantIsolationScreen(snapshot);
    return buildTenantIsolationRuntimeContract(snapshot);
  }

  window.Pix2piTenantIsolationCheck = {
    CONFIG: CONFIG,
    getSourceTenantId: getSourceTenantId,
    getUserSession: getUserSession,
    tenantIsolationScopeHeaders: tenantIsolationScopeHeaders,
    validateTenantIsolationScope: validateTenantIsolationScope,
    fetchTenantIsolationSnapshot: fetchTenantIsolationSnapshot,
    buildIsolationDecision: buildIsolationDecision,
    buildCrossTenantAccessDenialPreview: buildCrossTenantAccessDenialPreview,
    buildTenantIsolationRuntimeContract: buildTenantIsolationRuntimeContract,
    renderContext: renderContext,
    renderChecks: renderChecks,
    renderGuards: renderGuards,
    renderRegression: renderRegression,
    renderIncidentPreview: renderIncidentPreview,
    renderAuditTimeline: renderAuditTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderTenantIsolationScreen: renderTenantIsolationScreen,
    bootTenantIsolationScreen: bootTenantIsolationScreen
  };
})();
/* PIX2PI_352_TENANT_ISOLATION_CHECK_RUNTIME_END */
