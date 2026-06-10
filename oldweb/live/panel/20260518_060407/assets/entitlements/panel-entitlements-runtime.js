/* PIX2PI_346_PANEL_ENTITLEMENTS_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "panel_entitlements",
    phase: "FAZ_7R",
    step: "346",
    entitlementSnapshotEndpoint: "/api/commercial/entitlements/snapshot",
    entitlementDecisionEndpoint: "/api/commercial/entitlements/decision",
    enforcementAuditEndpoint: "/api/commercial/entitlements/audit",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    userSessionKey: "pix2pi.panel.user.session",
    runtimeContract: {
      realBackendEnforcementEnabled: false,
      realPlanChangeEnabled: false,
      realPaymentCollectionEnabled: false,
      realTenantSuspendEnabled: false,
      uiGuardEnabled: true,
      dryRunEnforcementEnabled: true,
      fallbackEntitlementSnapshotEnabled: true,
      readyForStep347: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      user_session_id: "USER_DEMO_SESSION",
      user_role: "OWNER",
      current_plan_code: "pilot_free",
      plan_label: "Pilot Free",
      entitlement_scope: "merchant-panel-entitlement-ui-guard",
      features: [
        { code: "merchant_panel", label: "Merchant Panel", area: "panel", entitled: true, decision: "ALLOW", reason: "PLAN_FEATURE_INCLUDED" },
        { code: "pos_surface", label: "POS Surface", area: "pos", entitled: true, decision: "ALLOW", reason: "PLAN_FEATURE_INCLUDED" },
        { code: "marketplace_surface", label: "Marketplace Surface", area: "marketplace", entitled: true, decision: "ALLOW", reason: "PLAN_FEATURE_INCLUDED" },
        { code: "advanced_reports", label: "Advanced Reports", area: "reporting", entitled: false, decision: "UPGRADE_REQUIRED", reason: "PLAN_UPGRADE_REQUIRED" },
        { code: "multi_store", label: "Multi Store", area: "tenant", entitled: false, decision: "DISABLE", reason: "QUOTA_LIMIT_REACHED" },
        { code: "accounting_export", label: "Accounting Export", area: "finance", entitled: false, decision: "DISABLE", reason: "PROVIDER_LIVE_GATE_CLOSED" }
      ],
      route_guards: [
        { route: "/dashboard/", feature_code: "merchant_panel", decision: "ALLOW" },
        { route: "/pos-management/", feature_code: "pos_surface", decision: "ALLOW" },
        { route: "/marketplace/", feature_code: "marketplace_surface", decision: "ALLOW" },
        { route: "/reports/advanced/", feature_code: "advanced_reports", decision: "UPGRADE_REQUIRED" },
        { route: "/settings/stores/new/", feature_code: "multi_store", decision: "DISABLE" }
      ],
      quota_bridge: [
        { quota_code: "products", used: 72, limit: 250, decision: "ALLOW" },
        { quota_code: "users", used: 2, limit: 3, decision: "ALLOW" },
        { quota_code: "stores", used: 1, limit: 1, decision: "DISABLE" },
        { quota_code: "market_visible_products", used: 45, limit: 200, decision: "ALLOW" }
      ],
      disabled_actions: [
        { action: "CREATE_SECOND_STORE", feature_code: "multi_store", decision: "DISABLE", label: "İkinci mağaza oluşturma" },
        { action: "OPEN_ADVANCED_REPORT", feature_code: "advanced_reports", decision: "UPGRADE_REQUIRED", label: "Gelişmiş rapor açma" },
        { action: "ACCOUNTING_EXPORT", feature_code: "accounting_export", decision: "DISABLE", label: "Muhasebe export" }
      ],
      audit_preview: [
        { event_type: "ENTITLEMENT_UI_GUARD_DECISION", action: "CREATE_SECOND_STORE", decision: "DISABLE", reason: "QUOTA_LIMIT_REACHED" },
        { event_type: "ENTITLEMENT_UI_GUARD_DECISION", action: "OPEN_ADVANCED_REPORT", decision: "UPGRADE_REQUIRED", reason: "PLAN_UPGRADE_REQUIRED" }
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
        role: CONFIG.fallbackSnapshot.user_role
      };
    }

    try {
      return Object.assign({ session_present: true }, JSON.parse(raw));
    } catch (_error) {
      return {
        session_present: false,
        session_id: "INVALID_USER_SESSION",
        role: "UNKNOWN"
      };
    }
  }

  function entitlementGuardScopeHeaders() {
    const session = getUserSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-User-Session": session.session_id,
      "X-Entitlement-Scope": "merchant-panel-entitlement-ui-guard",
      "X-Pix2pi-Surface": "merchant_panel_commercial",
      "X-Pix2pi-Step": "346"
    };
  }

  function validateEntitlementScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!snapshot || !snapshot.user_session_id) {
      errors.push({ field: "user_session_id", code: "USER_SESSION_REQUIRED" });
    }

    if (!snapshot || !snapshot.current_plan_code) {
      errors.push({ field: "current_plan_code", code: "PLAN_REQUIRED" });
    }

    if (!snapshot || !Array.isArray(snapshot.features)) {
      errors.push({ field: "features", code: "FEATURE_MATRIX_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: entitlementGuardScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("PANEL_ENTITLEMENT_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchEntitlementSnapshot() {
    try {
      return await apiJson(CONFIG.entitlementSnapshotEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      const session = getUserSession();
      snapshot.tenant_id = getTenantId();
      snapshot.user_session_id = session.session_id;
      snapshot.user_role = session.role || snapshot.user_role;
      return snapshot;
    }
  }

  function findFeature(snapshot, featureCode) {
    return (snapshot.features || []).find(function (feature) {
      return feature.code === featureCode;
    }) || null;
  }

  function decideEntitlement(snapshot, action, featureCode) {
    const feature = findFeature(snapshot, featureCode);

    if (!feature) {
      return {
        action: action,
        feature_code: featureCode,
        decision: "DENY",
        reason: "FEATURE_NOT_FOUND",
        ui_disabled: true,
        upgrade_required: false
      };
    }

    return {
      action: action,
      feature_code: featureCode,
      decision: feature.decision,
      reason: feature.reason,
      ui_disabled: feature.decision !== "ALLOW",
      upgrade_required: feature.decision === "UPGRADE_REQUIRED",
      entitled: feature.entitled
    };
  }

  function buildRouteAccessDecision(snapshot, route) {
    const guard = (snapshot.route_guards || []).find(function (item) {
      return item.route === route;
    });

    if (!guard) {
      return {
        route: route,
        decision: "DENY",
        reason: "ROUTE_GUARD_NOT_FOUND",
        ui_disabled: true
      };
    }

    const decision = decideEntitlement(snapshot, "ROUTE_ACCESS", guard.feature_code);
    return Object.assign({}, decision, {
      route: route,
      route_decision: guard.decision
    });
  }

  function buildDisabledUiAction(snapshot, actionCode) {
    const item = (snapshot.disabled_actions || []).find(function (action) {
      return action.action === actionCode;
    });

    if (!item) {
      return {
        action: actionCode,
        decision: "DENY",
        reason: "ACTION_GUARD_NOT_FOUND",
        ui_disabled: true
      };
    }

    const decision = decideEntitlement(snapshot, item.action, item.feature_code);
    return Object.assign({}, item, decision, {
      real_backend_enforcement_enabled: CONFIG.runtimeContract.realBackendEnforcementEnabled
    });
  }

  function buildEnforcementDryRunResult(snapshot, actionCode) {
    const decision = buildDisabledUiAction(snapshot, actionCode);

    return {
      dry_run: true,
      action: actionCode,
      decision: decision.decision,
      reason: decision.reason,
      backend_enforcement_applied: false,
      ui_guard_applied: true,
      audit_event_type: "ENTITLEMENT_UI_GUARD_DECISION",
      tenant_id: snapshot.tenant_id,
      user_session_id: snapshot.user_session_id,
      current_plan_code: snapshot.current_plan_code,
      source: {
        surface: "panel_entitlements",
        phase: "FAZ_7R",
        step: "346"
      }
    };
  }

  function buildGuardRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      user_session_id: snapshot.user_session_id,
      user_role: snapshot.user_role,
      current_plan_code: snapshot.current_plan_code,
      entitlement_scope: snapshot.entitlement_scope,
      feature_count: Array.isArray(snapshot.features) ? snapshot.features.length : 0,
      disabled_action_count: Array.isArray(snapshot.disabled_actions) ? snapshot.disabled_actions.length : 0,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateEntitlementScope(snapshot),
      source: {
        surface: "panel_entitlements",
        phase: "FAZ_7R",
        step: "346"
      }
    };
  }

  function renderContext(snapshot) {
    const tenant = document.getElementById("entitlements-tenant");
    const session = document.getElementById("entitlements-user-session");
    const role = document.getElementById("entitlements-user-role");
    const plan = document.getElementById("entitlements-current-plan");
    const validation = document.getElementById("entitlements-scope-validation");
    const contract = buildGuardRuntimeContract(snapshot);

    if (tenant) tenant.textContent = contract.tenant_id;
    if (session) session.textContent = contract.user_session_id;
    if (role) role.textContent = contract.user_role;
    if (plan) plan.textContent = snapshot.plan_label + " / " + snapshot.current_plan_code;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderFeatureMatrix(snapshot) {
    const target = document.getElementById("entitlements-feature-matrix");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.features || []).forEach(function (feature) {
      const row = document.createElement("article");
      row.className = "entitlement-row";
      row.setAttribute("data-feature-code", feature.code);
      row.setAttribute("data-decision", feature.decision);
      row.innerHTML = [
        "<div>",
        "<strong>" + feature.label + "</strong>",
        "<p>" + feature.area + " / " + feature.reason + "</p>",
        "</div>",
        "<span>" + feature.decision + "</span>",
        "<em>entitled=" + feature.entitled + "</em>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRouteGuards(snapshot) {
    const target = document.getElementById("entitlements-route-guards");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.route_guards || []).forEach(function (route) {
      const decision = buildRouteAccessDecision(snapshot, route.route);
      const item = document.createElement("article");
      item.className = "entitlement-card";
      item.setAttribute("data-route", route.route);
      item.setAttribute("data-decision", decision.decision);
      item.innerHTML = [
        "<strong>" + route.route + "</strong>",
        "<p>Feature: " + route.feature_code + " / Decision: " + decision.decision + "</p>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderQuotaBridge(snapshot) {
    const target = document.getElementById("entitlements-quota-bridge");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.quota_bridge || []).forEach(function (quota) {
      const pct = quota.limit > 0 ? Math.round((quota.used / quota.limit) * 100) : 0;
      const item = document.createElement("article");
      item.className = "entitlement-card";
      item.setAttribute("data-quota-code", quota.quota_code);
      item.setAttribute("data-decision", quota.decision);
      item.innerHTML = [
        "<strong>" + quota.quota_code + "</strong>",
        "<p>" + quota.used + " / " + quota.limit + " / %" + pct + "</p>",
        "<span>" + quota.decision + "</span>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderDisabledActions(snapshot) {
    const target = document.getElementById("entitlements-disabled-actions");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.disabled_actions || []).forEach(function (action) {
      const decision = buildDisabledUiAction(snapshot, action.action);
      const item = document.createElement("article");
      item.className = "entitlement-card";
      item.setAttribute("data-action", action.action);
      item.setAttribute("data-decision", decision.decision);
      item.innerHTML = [
        "<strong>" + action.label + "</strong>",
        "<p>" + action.action + " / " + decision.reason + "</p>",
        "<button type='button' disabled>" + decision.decision + "</button>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderAuditPreview(snapshot) {
    const target = document.getElementById("entitlements-audit-preview");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.audit_preview || []).forEach(function (event) {
      const item = document.createElement("article");
      item.className = "entitlement-card";
      item.setAttribute("data-audit-action", event.action);
      item.innerHTML = [
        "<strong>" + event.event_type + "</strong>",
        "<p>" + event.action + " / " + event.decision + " / " + event.reason + "</p>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("entitlements-runtime-contract");
    if (!target) return;

    const contract = buildGuardRuntimeContract(snapshot);

    target.textContent = [
      "real_backend_enforcement_enabled=" + CONFIG.runtimeContract.realBackendEnforcementEnabled,
      "ui_guard_enabled=" + CONFIG.runtimeContract.uiGuardEnabled,
      "dry_run_enforcement_enabled=" + CONFIG.runtimeContract.dryRunEnforcementEnabled,
      "real_plan_change_enabled=" + CONFIG.runtimeContract.realPlanChangeEnabled,
      "ready_for_step_347=" + CONFIG.runtimeContract.readyForStep347,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderEntitlementScreen(snapshot) {
    renderContext(snapshot);
    renderFeatureMatrix(snapshot);
    renderRouteGuards(snapshot);
    renderQuotaBridge(snapshot);
    renderDisabledActions(snapshot);
    renderAuditPreview(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-panel-entitlements-rendered", "true");
  }

  async function bootEntitlementScreen() {
    const snapshot = await fetchEntitlementSnapshot();
    renderEntitlementScreen(snapshot);
    return buildGuardRuntimeContract(snapshot);
  }

  window.Pix2piPanelEntitlements = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getUserSession: getUserSession,
    entitlementGuardScopeHeaders: entitlementGuardScopeHeaders,
    validateEntitlementScope: validateEntitlementScope,
    fetchEntitlementSnapshot: fetchEntitlementSnapshot,
    findFeature: findFeature,
    decideEntitlement: decideEntitlement,
    buildRouteAccessDecision: buildRouteAccessDecision,
    buildDisabledUiAction: buildDisabledUiAction,
    buildEnforcementDryRunResult: buildEnforcementDryRunResult,
    buildGuardRuntimeContract: buildGuardRuntimeContract,
    renderContext: renderContext,
    renderFeatureMatrix: renderFeatureMatrix,
    renderRouteGuards: renderRouteGuards,
    renderQuotaBridge: renderQuotaBridge,
    renderDisabledActions: renderDisabledActions,
    renderAuditPreview: renderAuditPreview,
    renderRuntimeContract: renderRuntimeContract,
    renderEntitlementScreen: renderEntitlementScreen,
    bootEntitlementScreen: bootEntitlementScreen
  };
})();
/* PIX2PI_346_PANEL_ENTITLEMENTS_RUNTIME_END */
