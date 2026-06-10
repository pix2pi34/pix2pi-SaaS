/* PIX2PI_353_USER_PERMISSION_CHECK_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "user_permission_check",
    phase: "FAZ_7R",
    step: "353",
    permissionSnapshotEndpoint: "/api/security/permissions/snapshot",
    permissionDecisionEndpoint: "/api/security/permissions/decision",
    permissionAuditEndpoint: "/api/security/permissions/audit",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    userSessionKey: "pix2pi.panel.user.session",
    runtimeContract: {
      realRbacBackendEnforcementEnabled: false,
      realRoleMutationEnabled: false,
      realAdminOverrideEnabled: false,
      realCustomerAccessEnabled: false,
      permissionPreviewEnabled: true,
      denyByDefaultPreviewEnabled: true,
      roleSwitchRegressionPreviewEnabled: true,
      fallbackPermissionSnapshotEnabled: true,
      readyForStep354: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      user_session_id: "USER_DEMO_SESSION",
      user_email: "owner@example.invalid",
      user_role: "OWNER_ADMIN",
      permission_scope: "controlled-user-permission-check",
      correlation_id: "FAZ7R-353-DEMO-CORRELATION",
      permission_status: "PREVIEW_READY",
      role_matrix: [
        { role: "OWNER_ADMIN", permission: "panel.dashboard.read", decision: "ALLOW" },
        { role: "OWNER_ADMIN", permission: "panel.users.manage", decision: "ALLOW" },
        { role: "OWNER_ADMIN", permission: "panel.products.manage", decision: "ALLOW" },
        { role: "OWNER_ADMIN", permission: "commercial.billing.read", decision: "ALLOW" },
        { role: "CASHIER", permission: "panel.users.manage", decision: "DENY_MISSING_PERMISSION" },
        { role: "CASHIER", permission: "pos.sale.create", decision: "ALLOW" },
        { role: "ACCOUNTANT_READONLY", permission: "commercial.billing.read", decision: "ALLOW" }
      ],
      checks: [
        { area: "panel", action: "dashboard.read", permission: "panel.dashboard.read", decision: "ALLOW" },
        { area: "panel", action: "users.manage", permission: "panel.users.manage", decision: "ALLOW" },
        { area: "panel", action: "products.manage", permission: "panel.products.manage", decision: "ALLOW" },
        { area: "pos", action: "sale.create", permission: "pos.sale.create", decision: "ALLOW" },
        { area: "pos", action: "payment.capture", permission: "pos.payment.capture", decision: "DENY_ENTITLEMENT" },
        { area: "marketplace", action: "storefront.manage", permission: "marketplace.storefront.manage", decision: "ALLOW" },
        { area: "commercial", action: "billing.read", permission: "commercial.billing.read", decision: "ALLOW" },
        { area: "admin", action: "platform.override", permission: "admin.platform.override", decision: "DENY_ADMIN_ONLY" }
      ],
      role_switch_regression: [
        { from_role: "OWNER_ADMIN", to_role: "MANAGER", action: "panel.users.manage", expected: "ALLOW", status: "PASS_PREVIEW" },
        { from_role: "OWNER_ADMIN", to_role: "CASHIER", action: "panel.users.manage", expected: "DENY", status: "PASS_PREVIEW" },
        { from_role: "OWNER_ADMIN", to_role: "ACCOUNTANT_READONLY", action: "pos.sale.create", expected: "DENY", status: "PASS_PREVIEW" }
      ],
      denied_previews: [
        { code: "UNAUTHORIZED", label: "Session yok", decision: "DENY_MISSING_PERMISSION", status: "PREVIEW_ONLY" },
        { code: "FORBIDDEN", label: "Yetki yok", decision: "DENY_MISSING_PERMISSION", status: "PREVIEW_ONLY" },
        { code: "ADMIN_ONLY", label: "Admin-only işlem", decision: "DENY_ADMIN_ONLY", status: "PREVIEW_ONLY" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "TENANT_ISOLATION_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "USER_PERMISSION_PREVIEW_READY", result: "DRY_RUN" },
        { at: "2026-05-demo", actor: "system", action: "ADMIN_OVERRIDE_BLOCKED", result: "EXPECTED" }
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

  function permissionScopeHeaders(action) {
    const session = getUserSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-User-Session": session.session_id,
      "X-User-Role": session.role,
      "X-Permission-Scope": "controlled-user-permission-check",
      "X-Requested-Action": action || "permission.snapshot",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "merchant_panel_controlled_access",
      "X-Pix2pi-Step": "353"
    };
  }

  function validatePermissionScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    if (!snapshot || !snapshot.user_session_id) errors.push({ field: "user_session_id", code: "USER_SESSION_REQUIRED" });
    if (!snapshot || !snapshot.user_role) errors.push({ field: "user_role", code: "ROLE_REQUIRED" });
    if (!snapshot || !snapshot.permission_scope) errors.push({ field: "permission_scope", code: "PERMISSION_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.role_matrix)) errors.push({ field: "role_matrix", code: "ROLE_MATRIX_REQUIRED" });

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: permissionScopeHeaders("permission.snapshot")
    });

    if (!response.ok) {
      throw new Error("USER_PERMISSION_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchPermissionSnapshot() {
    try {
      return await apiJson(CONFIG.permissionSnapshotEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      const session = getUserSession();
      snapshot.tenant_id = getTenantId();
      snapshot.user_session_id = session.session_id;
      snapshot.user_role = session.role || snapshot.user_role;
      snapshot.user_email = session.email || snapshot.user_email;
      return snapshot;
    }
  }

  function buildPermissionDecision(snapshot, action, permission) {
    const matched = (snapshot.checks || []).find(function (item) {
      return item.action === action || item.permission === permission;
    });

    if (matched) {
      return {
        tenant_id: snapshot.tenant_id,
        user_role: snapshot.user_role,
        action: matched.action,
        permission: matched.permission,
        decision: matched.decision,
        allowed: matched.decision === "ALLOW",
        preview_only: true
      };
    }

    return {
      tenant_id: snapshot.tenant_id,
      user_role: snapshot.user_role,
      action: action,
      permission: permission || "unknown",
      decision: "DENY_MISSING_PERMISSION",
      allowed: false,
      preview_only: true
    };
  }

  function buildAdminOnlyDisabledGate(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      user_role: snapshot.user_role,
      action: "platform.override",
      permission: "admin.platform.override",
      decision: "DENY_ADMIN_ONLY",
      allowed: false,
      real_admin_override_enabled: CONFIG.runtimeContract.realAdminOverrideEnabled,
      reason: "REAL_ADMIN_OVERRIDE_DISABLED_IN_STEP_353"
    };
  }

  function buildDenyByDefaultPreview(snapshot, action) {
    return {
      tenant_id: snapshot.tenant_id,
      user_role: snapshot.user_role,
      action: action || "unknown.action",
      decision: "DENY_MISSING_PERMISSION",
      allowed: false,
      deny_by_default_preview_enabled: CONFIG.runtimeContract.denyByDefaultPreviewEnabled
    };
  }

  function buildUserPermissionRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      user_session_id: snapshot.user_session_id,
      user_email: snapshot.user_email,
      user_role: snapshot.user_role,
      permission_scope: snapshot.permission_scope,
      role_matrix_count: Array.isArray(snapshot.role_matrix) ? snapshot.role_matrix.length : 0,
      check_count: Array.isArray(snapshot.checks) ? snapshot.checks.length : 0,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validatePermissionScope(snapshot),
      admin_only_gate: buildAdminOnlyDisabledGate(snapshot),
      deny_by_default: buildDenyByDefaultPreview(snapshot, "unknown.action"),
      source: {
        surface: "user_permission_check",
        phase: "FAZ_7R",
        step: "353"
      }
    };
  }

  function renderContext(snapshot) {
    const tenant = document.getElementById("permission-tenant-id");
    const session = document.getElementById("permission-user-session");
    const email = document.getElementById("permission-user-email");
    const role = document.getElementById("permission-user-role");
    const validation = document.getElementById("permission-scope-validation");
    const contract = buildUserPermissionRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (session) session.textContent = snapshot.user_session_id;
    if (email) email.textContent = snapshot.user_email;
    if (role) role.textContent = snapshot.user_role;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderRoleMatrix(snapshot) {
    const target = document.getElementById("permission-role-matrix");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.role_matrix || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "perm-card";
      row.setAttribute("data-role", item.role);
      row.setAttribute("data-permission", item.permission);
      row.setAttribute("data-decision", item.decision);
      row.innerHTML = [
        "<strong>" + item.role + "</strong>",
        "<p>" + item.permission + " / " + item.decision + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderPermissionChecks(snapshot) {
    const target = document.getElementById("permission-check-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.checks || []).forEach(function (item) {
      const decision = buildPermissionDecision(snapshot, item.action, item.permission);
      const row = document.createElement("article");
      row.className = "perm-card";
      row.setAttribute("data-area", item.area);
      row.setAttribute("data-action", item.action);
      row.setAttribute("data-decision", decision.decision);
      row.innerHTML = [
        "<strong>" + item.area + " / " + item.action + "</strong>",
        "<p>" + item.permission + " / " + decision.decision + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRoleSwitchRegression(snapshot) {
    const target = document.getElementById("permission-role-switch-regression");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.role_switch_regression || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "perm-card";
      row.setAttribute("data-from-role", item.from_role);
      row.setAttribute("data-to-role", item.to_role);
      row.innerHTML = [
        "<strong>" + item.from_role + " → " + item.to_role + "</strong>",
        "<p>" + item.action + " / expected=" + item.expected + " / " + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderDeniedPreviews(snapshot) {
    const target = document.getElementById("permission-denied-previews");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.denied_previews || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "perm-card";
      row.setAttribute("data-error-code", item.code);
      row.setAttribute("data-decision", item.decision);
      row.innerHTML = [
        "<strong>" + item.code + "</strong>",
        "<p>" + item.label + " / " + item.decision + " / " + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAuditTimeline(snapshot) {
    const target = document.getElementById("permission-audit-timeline");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.audit_timeline || []).forEach(function (event) {
      const row = document.createElement("article");
      row.className = "perm-card";
      row.setAttribute("data-audit-action", event.action);
      row.innerHTML = [
        "<strong>" + event.action + "</strong>",
        "<p>" + event.at + " / " + event.actor + " / " + event.result + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("permission-runtime-contract");
    if (!target) return;

    const contract = buildUserPermissionRuntimeContract(snapshot);

    target.textContent = [
      "real_rbac_backend_enforcement_enabled=" + CONFIG.runtimeContract.realRbacBackendEnforcementEnabled,
      "real_role_mutation_enabled=" + CONFIG.runtimeContract.realRoleMutationEnabled,
      "real_admin_override_enabled=" + CONFIG.runtimeContract.realAdminOverrideEnabled,
      "permission_preview_enabled=" + CONFIG.runtimeContract.permissionPreviewEnabled,
      "deny_by_default_preview_enabled=" + CONFIG.runtimeContract.denyByDefaultPreviewEnabled,
      "ready_for_step_354=" + CONFIG.runtimeContract.readyForStep354,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderUserPermissionScreen(snapshot) {
    renderContext(snapshot);
    renderRoleMatrix(snapshot);
    renderPermissionChecks(snapshot);
    renderRoleSwitchRegression(snapshot);
    renderDeniedPreviews(snapshot);
    renderAuditTimeline(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-user-permission-check-rendered", "true");
  }

  async function bootUserPermissionScreen() {
    const snapshot = await fetchPermissionSnapshot();
    renderUserPermissionScreen(snapshot);
    return buildUserPermissionRuntimeContract(snapshot);
  }

  window.Pix2piUserPermissionCheck = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getUserSession: getUserSession,
    permissionScopeHeaders: permissionScopeHeaders,
    validatePermissionScope: validatePermissionScope,
    fetchPermissionSnapshot: fetchPermissionSnapshot,
    buildPermissionDecision: buildPermissionDecision,
    buildAdminOnlyDisabledGate: buildAdminOnlyDisabledGate,
    buildDenyByDefaultPreview: buildDenyByDefaultPreview,
    buildUserPermissionRuntimeContract: buildUserPermissionRuntimeContract,
    renderContext: renderContext,
    renderRoleMatrix: renderRoleMatrix,
    renderPermissionChecks: renderPermissionChecks,
    renderRoleSwitchRegression: renderRoleSwitchRegression,
    renderDeniedPreviews: renderDeniedPreviews,
    renderAuditTimeline: renderAuditTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderUserPermissionScreen: renderUserPermissionScreen,
    bootUserPermissionScreen: bootUserPermissionScreen
  };
})();
/* PIX2PI_353_USER_PERMISSION_CHECK_RUNTIME_END */
