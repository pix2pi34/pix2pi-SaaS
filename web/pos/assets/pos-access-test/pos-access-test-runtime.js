/* PIX2PI_351_POS_ACCESS_TEST_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "pos_access_test",
    phase: "FAZ_7R",
    step: "351",
    posAccessSnapshotEndpoint: "/api/access/pos/snapshot",
    posRouteCheckEndpoint: "/api/access/pos/routes/check",
    posAccessAuditEndpoint: "/api/access/pos/audit",
    selectedTenantKey: "pix2pi.pos.tenant.preference",
    selectedStoreKey: "pix2pi.pos.store.preference",
    selectedRegisterKey: "pix2pi.pos.register.preference",
    userSessionKey: "pix2pi.pos.user.session",
    runtimeContract: {
      realPosLoginEnabled: false,
      realSaleEnabled: false,
      realPaymentEnabled: false,
      realStockDecrementEnabled: false,
      realOfflineQueueEnabled: false,
      posAccessPreviewEnabled: true,
      routeSmokePreviewEnabled: true,
      mobileReadyPreviewEnabled: true,
      fallbackPosAccessSnapshotEnabled: true,
      readyForStep352: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      store_id: "demo-market-main",
      register_id: "register-001",
      user_session_id: "USER_DEMO_SESSION",
      user_email: "owner@example.invalid",
      user_role: "OWNER_ADMIN",
      pos_scope: "controlled-pos-access-test",
      correlation_id: "FAZ7R-351-DEMO-CORRELATION",
      session_status: "SIMULATED_NOT_REAL",
      access_status: "PREVIEW_ALLOWED",
      routes: [
        { route: "/", label: "POS home", status: "AVAILABLE", decision: "ALLOW_PREVIEW" },
        { route: "/cashier-login/", label: "Cashier login", status: "AVAILABLE", decision: "ALLOW_PREVIEW" },
        { route: "/sales/", label: "POS sales screen", status: "AVAILABLE", decision: "ALLOW_PREVIEW" },
        { route: "/cart-payment/", label: "Cart / payment", status: "AVAILABLE", decision: "ALLOW_PREVIEW" },
        { route: "/offline-ready/", label: "Offline-ready POS", status: "AVAILABLE", decision: "ALLOW_PREVIEW" },
        { route: "/pos-access-test/", label: "POS access test", status: "AVAILABLE", decision: "ALLOW_PREVIEW" }
      ],
      readiness: [
        { code: "MOBILE_VIEWPORT", label: "Mobile viewport", status: "READY" },
        { code: "TOUCH_TARGETS", label: "Touch readiness", status: "READY" },
        { code: "PWA_MANIFEST_PLACEHOLDER", label: "PWA manifest placeholder", status: "READY" },
        { code: "OFFLINE_QUEUE_PLACEHOLDER", label: "Offline queue placeholder", status: "DISABLED_PREVIEW" }
      ],
      denied_previews: [
        { code: "UNAUTHORIZED", label: "POS session yok", status: "PREVIEW_ONLY" },
        { code: "FORBIDDEN", label: "Kasiyer/owner rol yetkisi yok", status: "PREVIEW_ONLY" },
        { code: "POS_SESSION_TIMEOUT", label: "POS oturum süresi doldu", status: "PREVIEW_ONLY" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "PANEL_ACCESS_TEST_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "POS_ACCESS_PREVIEW_READY", result: "DRY_RUN" },
        { at: "2026-05-demo", actor: "system", action: "REAL_POS_SALE_BLOCKED", result: "EXPECTED" }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSnapshot.tenant_id;
  }

  function getStoreId() {
    return window.localStorage.getItem(CONFIG.selectedStoreKey) || CONFIG.fallbackSnapshot.store_id;
  }

  function getRegisterId() {
    return window.localStorage.getItem(CONFIG.selectedRegisterKey) || CONFIG.fallbackSnapshot.register_id;
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
        session_id: "INVALID_POS_USER_SESSION",
        role: "UNKNOWN",
        email: "unknown@example.invalid"
      };
    }
  }

  function posAccessScopeHeaders() {
    const session = getUserSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Store-ID": getStoreId(),
      "X-Register-ID": getRegisterId(),
      "X-User-Session": session.session_id,
      "X-User-Role": session.role,
      "X-POS-Scope": "controlled-pos-access-test",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "pos_controlled_access",
      "X-Pix2pi-Step": "351"
    };
  }

  function validatePosAccessScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    if (!snapshot || !snapshot.store_id) errors.push({ field: "store_id", code: "STORE_REQUIRED" });
    if (!snapshot || !snapshot.register_id) errors.push({ field: "register_id", code: "REGISTER_REQUIRED" });
    if (!snapshot || !snapshot.user_session_id) errors.push({ field: "user_session_id", code: "USER_SESSION_REQUIRED" });
    if (!snapshot || !snapshot.user_role) errors.push({ field: "user_role", code: "ROLE_REQUIRED" });
    if (!snapshot || !snapshot.pos_scope) errors.push({ field: "pos_scope", code: "POS_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.routes)) errors.push({ field: "routes", code: "POS_ROUTE_LIST_REQUIRED" });

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: posAccessScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("POS_ACCESS_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchPosAccessSnapshot() {
    try {
      return await apiJson(CONFIG.posAccessSnapshotEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      const session = getUserSession();
      snapshot.tenant_id = getTenantId();
      snapshot.store_id = getStoreId();
      snapshot.register_id = getRegisterId();
      snapshot.user_session_id = session.session_id;
      snapshot.user_role = session.role || snapshot.user_role;
      snapshot.user_email = session.email || snapshot.user_email;
      return snapshot;
    }
  }

  function buildPosRouteAccessPreview(snapshot, route) {
    const item = (snapshot.routes || []).find(function (entry) {
      return entry.route === route;
    });

    if (!item) {
      return {
        route: route,
        status: "MISSING",
        decision: "DENY_PREVIEW",
        reason: "POS_ROUTE_NOT_REGISTERED",
        preview_only: true
      };
    }

    return {
      route: item.route,
      label: item.label,
      status: item.status,
      decision: item.decision,
      tenant_id: snapshot.tenant_id,
      store_id: snapshot.store_id,
      register_id: snapshot.register_id,
      user_role: snapshot.user_role,
      preview_only: true,
      real_pos_login_enabled: CONFIG.runtimeContract.realPosLoginEnabled,
      real_sale_enabled: CONFIG.runtimeContract.realSaleEnabled,
      real_payment_enabled: CONFIG.runtimeContract.realPaymentEnabled
    };
  }

  function buildPosDeniedPreview(snapshot, code) {
    const item = (snapshot.denied_previews || []).find(function (entry) {
      return entry.code === code;
    }) || { code: code, label: "Bilinmeyen POS erişim hatası", status: "PREVIEW_ONLY" };

    return {
      code: item.code,
      label: item.label,
      status: item.status,
      real_pos_login_enabled: CONFIG.runtimeContract.realPosLoginEnabled,
      real_offline_queue_enabled: CONFIG.runtimeContract.realOfflineQueueEnabled,
      preview_only: true,
      source: {
        surface: "pos_access_test",
        phase: "FAZ_7R",
        step: "351"
      }
    };
  }

  function buildPosNavigationHandoff(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      store_id: snapshot.store_id,
      register_id: snapshot.register_id,
      user_role: snapshot.user_role,
      pos_home_url: "https://pos.pix2pi.com.tr/",
      cashier_login_url: "https://pos.pix2pi.com.tr/cashier-login/",
      sales_url: "https://pos.pix2pi.com.tr/sales/",
      cart_payment_url: "https://pos.pix2pi.com.tr/cart-payment/",
      next_step: "352 - Tenant izolasyon kontrolü",
      ready_for_step_352: CONFIG.runtimeContract.readyForStep352
    };
  }

  function buildPosAccessRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      store_id: snapshot.store_id,
      register_id: snapshot.register_id,
      user_session_id: snapshot.user_session_id,
      user_email: snapshot.user_email,
      user_role: snapshot.user_role,
      pos_scope: snapshot.pos_scope,
      route_count: Array.isArray(snapshot.routes) ? snapshot.routes.length : 0,
      readiness_count: Array.isArray(snapshot.readiness) ? snapshot.readiness.length : 0,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validatePosAccessScope(snapshot),
      source: {
        surface: "pos_access_test",
        phase: "FAZ_7R",
        step: "351"
      }
    };
  }

  function renderAccessContext(snapshot) {
    const tenant = document.getElementById("pos-access-tenant-id");
    const store = document.getElementById("pos-access-store-id");
    const register = document.getElementById("pos-access-register-id");
    const session = document.getElementById("pos-access-session-id");
    const role = document.getElementById("pos-access-role");
    const validation = document.getElementById("pos-access-scope-validation");
    const contract = buildPosAccessRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (store) store.textContent = snapshot.store_id;
    if (register) register.textContent = snapshot.register_id;
    if (session) session.textContent = snapshot.user_session_id;
    if (role) role.textContent = snapshot.user_role;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderRouteChecklist(snapshot) {
    const target = document.getElementById("pos-route-checklist");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.routes || []).forEach(function (route) {
      const decision = buildPosRouteAccessPreview(snapshot, route.route);
      const row = document.createElement("article");
      row.className = "pos-access-card";
      row.setAttribute("data-route", route.route);
      row.setAttribute("data-decision", decision.decision);
      row.innerHTML = [
        "<strong>" + route.label + "</strong>",
        "<p>" + route.route + " / " + route.status + " / " + decision.decision + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderReadiness(snapshot) {
    const target = document.getElementById("pos-readiness-checklist");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.readiness || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "pos-access-card";
      row.setAttribute("data-readiness-code", item.code);
      row.setAttribute("data-readiness-status", item.status);
      row.innerHTML = [
        "<strong>" + item.label + "</strong>",
        "<p>" + item.code + " / " + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderDeniedPreviews(snapshot) {
    const target = document.getElementById("pos-denied-previews");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.denied_previews || []).forEach(function (item) {
      const preview = buildPosDeniedPreview(snapshot, item.code);
      const row = document.createElement("article");
      row.className = "pos-access-card";
      row.setAttribute("data-error-code", preview.code);
      row.innerHTML = [
        "<strong>" + preview.code + "</strong>",
        "<p>" + preview.label + " / " + preview.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAuditTimeline(snapshot) {
    const target = document.getElementById("pos-access-audit-timeline");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.audit_timeline || []).forEach(function (event) {
      const row = document.createElement("article");
      row.className = "pos-access-card";
      row.setAttribute("data-audit-action", event.action);
      row.innerHTML = [
        "<strong>" + event.action + "</strong>",
        "<p>" + event.at + " / " + event.actor + " / " + event.result + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("pos-access-runtime-contract");
    if (!target) return;

    const contract = buildPosAccessRuntimeContract(snapshot);

    target.textContent = [
      "real_pos_login_enabled=" + CONFIG.runtimeContract.realPosLoginEnabled,
      "real_sale_enabled=" + CONFIG.runtimeContract.realSaleEnabled,
      "real_payment_enabled=" + CONFIG.runtimeContract.realPaymentEnabled,
      "real_offline_queue_enabled=" + CONFIG.runtimeContract.realOfflineQueueEnabled,
      "mobile_ready_preview_enabled=" + CONFIG.runtimeContract.mobileReadyPreviewEnabled,
      "ready_for_step_352=" + CONFIG.runtimeContract.readyForStep352,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderPosAccessScreen(snapshot) {
    renderAccessContext(snapshot);
    renderRouteChecklist(snapshot);
    renderReadiness(snapshot);
    renderDeniedPreviews(snapshot);
    renderAuditTimeline(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-pos-access-test-rendered", "true");
  }

  async function bootPosAccessScreen() {
    const snapshot = await fetchPosAccessSnapshot();
    renderPosAccessScreen(snapshot);
    return buildPosAccessRuntimeContract(snapshot);
  }

  window.Pix2piPosAccessTest = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getStoreId: getStoreId,
    getRegisterId: getRegisterId,
    getUserSession: getUserSession,
    posAccessScopeHeaders: posAccessScopeHeaders,
    validatePosAccessScope: validatePosAccessScope,
    fetchPosAccessSnapshot: fetchPosAccessSnapshot,
    buildPosRouteAccessPreview: buildPosRouteAccessPreview,
    buildPosDeniedPreview: buildPosDeniedPreview,
    buildPosNavigationHandoff: buildPosNavigationHandoff,
    buildPosAccessRuntimeContract: buildPosAccessRuntimeContract,
    renderAccessContext: renderAccessContext,
    renderRouteChecklist: renderRouteChecklist,
    renderReadiness: renderReadiness,
    renderDeniedPreviews: renderDeniedPreviews,
    renderAuditTimeline: renderAuditTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderPosAccessScreen: renderPosAccessScreen,
    bootPosAccessScreen: bootPosAccessScreen
  };
})();
/* PIX2PI_351_POS_ACCESS_TEST_RUNTIME_END */
