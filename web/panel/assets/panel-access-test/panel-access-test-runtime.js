/* PIX2PI_350_PANEL_ACCESS_TEST_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "panel_access_test",
    phase: "FAZ_7R",
    step: "350",
    panelAccessSnapshotEndpoint: "/api/access/panel/snapshot",
    panelRouteCheckEndpoint: "/api/access/panel/routes/check",
    panelAccessAuditEndpoint: "/api/access/panel/audit",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    userSessionKey: "pix2pi.panel.user.session",
    runtimeContract: {
      realJwtVerifyEnabled: false,
      realSessionCreateEnabled: false,
      realRbacBackendEnforcementEnabled: false,
      realCustomerLoginEnabled: false,
      panelAccessPreviewEnabled: true,
      routeSmokePreviewEnabled: true,
      fallbackPanelAccessSnapshotEnabled: true,
      readyForStep351: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      user_session_id: "USER_DEMO_SESSION",
      user_email: "owner@example.invalid",
      user_role: "OWNER_ADMIN",
      route_scope: "controlled-panel-access-test",
      correlation_id: "FAZ7R-350-DEMO-CORRELATION",
      session_status: "SIMULATED_NOT_REAL",
      access_status: "PREVIEW_ALLOWED",
      routes: [
        { route: "/", label: "Panel home", status: "AVAILABLE", decision: "ALLOW_PREVIEW" },
        { route: "/dashboard/", label: "Merchant dashboard", status: "AVAILABLE", decision: "ALLOW_PREVIEW" },
        { route: "/users/", label: "Users / roles", status: "AVAILABLE", decision: "ALLOW_PREVIEW" },
        { route: "/products/", label: "Products / stock", status: "AVAILABLE", decision: "ALLOW_PREVIEW" },
        { route: "/billing/", label: "Billing", status: "AVAILABLE", decision: "ALLOW_PREVIEW" },
        { route: "/entitlements/", label: "Entitlements", status: "AVAILABLE", decision: "ALLOW_PREVIEW" }
      ],
      denied_previews: [
        { code: "UNAUTHORIZED", label: "Session yok", status: "PREVIEW_ONLY" },
        { code: "FORBIDDEN", label: "Rol yetkisi yok", status: "PREVIEW_ONLY" },
        { code: "SESSION_TIMEOUT", label: "Oturum süresi doldu", status: "PREVIEW_ONLY" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "PASSWORD_LOGIN_FLOW_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "PANEL_ACCESS_PREVIEW_READY", result: "DRY_RUN" },
        { at: "2026-05-demo", actor: "system", action: "REAL_JWT_VERIFY_BLOCKED", result: "EXPECTED" }
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

  function panelAccessScopeHeaders() {
    const session = getUserSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-User-Session": session.session_id,
      "X-User-Role": session.role,
      "X-Route-Scope": "controlled-panel-access-test",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "merchant_panel_controlled_access",
      "X-Pix2pi-Step": "350"
    };
  }

  function validatePanelAccessScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    if (!snapshot || !snapshot.user_session_id) errors.push({ field: "user_session_id", code: "USER_SESSION_REQUIRED" });
    if (!snapshot || !snapshot.user_role) errors.push({ field: "user_role", code: "ROLE_REQUIRED" });
    if (!snapshot || !snapshot.route_scope) errors.push({ field: "route_scope", code: "ROUTE_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.routes)) errors.push({ field: "routes", code: "ROUTE_LIST_REQUIRED" });

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: panelAccessScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("PANEL_ACCESS_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchPanelAccessSnapshot() {
    try {
      return await apiJson(CONFIG.panelAccessSnapshotEndpoint);
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

  function buildRouteAccessPreview(snapshot, route) {
    const item = (snapshot.routes || []).find(function (entry) {
      return entry.route === route;
    });

    if (!item) {
      return {
        route: route,
        status: "MISSING",
        decision: "DENY_PREVIEW",
        reason: "ROUTE_NOT_REGISTERED",
        preview_only: true
      };
    }

    return {
      route: item.route,
      label: item.label,
      status: item.status,
      decision: item.decision,
      tenant_id: snapshot.tenant_id,
      user_role: snapshot.user_role,
      preview_only: true,
      real_rbac_backend_enforcement_enabled: CONFIG.runtimeContract.realRbacBackendEnforcementEnabled
    };
  }

  function buildUnauthorizedPreview(snapshot, code) {
    const item = (snapshot.denied_previews || []).find(function (entry) {
      return entry.code === code;
    }) || { code: code, label: "Bilinmeyen hata", status: "PREVIEW_ONLY" };

    return {
      code: item.code,
      label: item.label,
      status: item.status,
      real_jwt_verify_enabled: CONFIG.runtimeContract.realJwtVerifyEnabled,
      real_session_create_enabled: CONFIG.runtimeContract.realSessionCreateEnabled,
      preview_only: true,
      source: {
        surface: "panel_access_test",
        phase: "FAZ_7R",
        step: "350"
      }
    };
  }

  function buildPanelNavigationHandoff(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      user_role: snapshot.user_role,
      dashboard_url: "https://panel.pix2pi.com.tr/dashboard/",
      users_url: "https://panel.pix2pi.com.tr/users/",
      products_url: "https://panel.pix2pi.com.tr/products/",
      billing_url: "https://panel.pix2pi.com.tr/billing/",
      next_step: "351 - POS erişim testi",
      ready_for_step_351: CONFIG.runtimeContract.readyForStep351
    };
  }

  function buildPanelAccessRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      user_session_id: snapshot.user_session_id,
      user_email: snapshot.user_email,
      user_role: snapshot.user_role,
      route_scope: snapshot.route_scope,
      route_count: Array.isArray(snapshot.routes) ? snapshot.routes.length : 0,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validatePanelAccessScope(snapshot),
      source: {
        surface: "panel_access_test",
        phase: "FAZ_7R",
        step: "350"
      }
    };
  }

  function renderAccessContext(snapshot) {
    const tenant = document.getElementById("panel-access-tenant-id");
    const session = document.getElementById("panel-access-session-id");
    const email = document.getElementById("panel-access-email");
    const role = document.getElementById("panel-access-role");
    const validation = document.getElementById("panel-access-scope-validation");
    const contract = buildPanelAccessRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (session) session.textContent = snapshot.user_session_id;
    if (email) email.textContent = snapshot.user_email;
    if (role) role.textContent = snapshot.user_role;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderRouteChecklist(snapshot) {
    const target = document.getElementById("panel-route-checklist");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.routes || []).forEach(function (route) {
      const decision = buildRouteAccessPreview(snapshot, route.route);
      const row = document.createElement("article");
      row.className = "access-card";
      row.setAttribute("data-route", route.route);
      row.setAttribute("data-decision", decision.decision);
      row.innerHTML = [
        "<strong>" + route.label + "</strong>",
        "<p>" + route.route + " / " + route.status + " / " + decision.decision + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderDeniedPreviews(snapshot) {
    const target = document.getElementById("panel-denied-previews");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.denied_previews || []).forEach(function (item) {
      const preview = buildUnauthorizedPreview(snapshot, item.code);
      const row = document.createElement("article");
      row.className = "access-card";
      row.setAttribute("data-error-code", preview.code);
      row.innerHTML = [
        "<strong>" + preview.code + "</strong>",
        "<p>" + preview.label + " / " + preview.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAuditTimeline(snapshot) {
    const target = document.getElementById("panel-access-audit-timeline");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.audit_timeline || []).forEach(function (event) {
      const row = document.createElement("article");
      row.className = "access-card";
      row.setAttribute("data-audit-action", event.action);
      row.innerHTML = [
        "<strong>" + event.action + "</strong>",
        "<p>" + event.at + " / " + event.actor + " / " + event.result + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("panel-access-runtime-contract");
    if (!target) return;

    const contract = buildPanelAccessRuntimeContract(snapshot);

    target.textContent = [
      "real_jwt_verify_enabled=" + CONFIG.runtimeContract.realJwtVerifyEnabled,
      "real_session_create_enabled=" + CONFIG.runtimeContract.realSessionCreateEnabled,
      "real_rbac_backend_enforcement_enabled=" + CONFIG.runtimeContract.realRbacBackendEnforcementEnabled,
      "panel_access_preview_enabled=" + CONFIG.runtimeContract.panelAccessPreviewEnabled,
      "route_smoke_preview_enabled=" + CONFIG.runtimeContract.routeSmokePreviewEnabled,
      "ready_for_step_351=" + CONFIG.runtimeContract.readyForStep351,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderPanelAccessScreen(snapshot) {
    renderAccessContext(snapshot);
    renderRouteChecklist(snapshot);
    renderDeniedPreviews(snapshot);
    renderAuditTimeline(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-panel-access-test-rendered", "true");
  }

  async function bootPanelAccessScreen() {
    const snapshot = await fetchPanelAccessSnapshot();
    renderPanelAccessScreen(snapshot);
    return buildPanelAccessRuntimeContract(snapshot);
  }

  window.Pix2piPanelAccessTest = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getUserSession: getUserSession,
    panelAccessScopeHeaders: panelAccessScopeHeaders,
    validatePanelAccessScope: validatePanelAccessScope,
    fetchPanelAccessSnapshot: fetchPanelAccessSnapshot,
    buildRouteAccessPreview: buildRouteAccessPreview,
    buildUnauthorizedPreview: buildUnauthorizedPreview,
    buildPanelNavigationHandoff: buildPanelNavigationHandoff,
    buildPanelAccessRuntimeContract: buildPanelAccessRuntimeContract,
    renderAccessContext: renderAccessContext,
    renderRouteChecklist: renderRouteChecklist,
    renderDeniedPreviews: renderDeniedPreviews,
    renderAuditTimeline: renderAuditTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderPanelAccessScreen: renderPanelAccessScreen,
    bootPanelAccessScreen: bootPanelAccessScreen
  };
})();
/* PIX2PI_350_PANEL_ACCESS_TEST_RUNTIME_END */
