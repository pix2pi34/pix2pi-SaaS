/* PIX2PI_347_PANEL_PILOT_TENANT_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "panel_pilot_tenant_opening",
    phase: "FAZ_7R",
    step: "347",
    pilotTenantDraftEndpoint: "/api/admin/pilot-tenants/draft",
    pilotTenantOpeningEndpoint: "/api/admin/pilot-tenants/opening",
    pilotTenantAuditEndpoint: "/api/admin/pilot-tenants/audit",
    adminSessionKey: "pix2pi.panel.admin.session",
    pilotTenantDraftKey: "pix2pi.panel.pilot_tenant.draft",
    runtimeContract: {
      realTenantInsertEnabled: false,
      realOwnerInviteEnabled: false,
      realTenantActivationEnabled: false,
      realCustomerAccessEnabled: false,
      pilotTenantDraftEnabled: true,
      controlledOpeningGateEnabled: true,
      fallbackPilotTenantSnapshotEnabled: true,
      readyForStep348: true
    },
    approvalGates: {
      kvkkApprovalRequired: true,
      legalApprovalRequired: true,
      commercialApprovalRequired: true,
      rlsIsolationCheckRequired: true,
      productionCustomerAccessAllowed: false
    },
    fallbackSnapshot: {
      admin_session_id: "ADMIN_DEMO_SESSION",
      tenant_opening_scope: "controlled-pilot-tenant-opening",
      correlation_id: "FAZ7R-347-DEMO-CORRELATION",
      draft: {
        tenant_id: "controlled-pilot",
        tenant_slug: "demo-market",
        tenant_domain_hint: "demo-market.panel.pix2pi.local",
        environment: "CONTROLLED_PILOT",
        opening_status: "DRAFT_NOT_PROVISIONED",
        business_name: "Demo Market",
        sector: "market",
        country: "TR",
        city: "İstanbul",
        district: "Pilot",
        tax_no_placeholder: "PENDING",
        mersis_placeholder: "PENDING",
        legal_entity_status: "PLACEHOLDER",
        branch_status: "PLACEHOLDER",
        default_plan_code: "pilot_free",
        default_language: "tr-TR",
        timezone: "Europe/Istanbul",
        currency: "TRY",
        owner_admin_email_placeholder: "owner@example.invalid"
      },
      checklist: [
        { code: "BUSINESS_NAME", label: "İşletme adı", status: "READY" },
        { code: "SECTOR", label: "Sektör", status: "READY" },
        { code: "LOCATION", label: "Konum", status: "READY" },
        { code: "LEGAL_ENTITY", label: "Legal entity", status: "PLACEHOLDER" },
        { code: "BRANCH", label: "Şube", status: "PLACEHOLDER" },
        { code: "OWNER_ADMIN", label: "Owner admin", status: "PLACEHOLDER" }
      ],
      gates: [
        { code: "KVKK_APPROVAL", label: "KVKK onayı", status: "REQUIRED" },
        { code: "LEGAL_APPROVAL", label: "Hukuk onayı", status: "REQUIRED" },
        { code: "COMMERCIAL_APPROVAL", label: "Ticari onay", status: "REQUIRED" },
        { code: "RLS_ISOLATION_CHECK", label: "RLS izolasyon kontrolü", status: "REQUIRED" },
        { code: "CUSTOMER_ACCESS", label: "Production müşteri erişimi", status: "BLOCKED" }
      ],
      access_preparation: [
        { surface: "panel", url: "https://panel.pix2pi.com.tr/", status: "PREPARED" },
        { surface: "pos", url: "https://pos.pix2pi.com.tr/", status: "PREPARED" },
        { surface: "market", url: "https://market.pix2pi.com.tr/", status: "PREPARED" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "ENTITLEMENT_UI_GUARD_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "PILOT_TENANT_DRAFT_CREATED", result: "DRY_RUN" },
        { at: "2026-05-demo", actor: "system", action: "REAL_TENANT_INSERT_BLOCKED", result: "EXPECTED" }
      ]
    }
  };

  function getAdminSession() {
    const raw = window.localStorage.getItem(CONFIG.adminSessionKey);
    if (!raw) {
      return {
        session_present: false,
        session_id: CONFIG.fallbackSnapshot.admin_session_id,
        role: "PLATFORM_ADMIN"
      };
    }

    try {
      return Object.assign({ session_present: true }, JSON.parse(raw));
    } catch (_error) {
      return {
        session_present: false,
        session_id: "INVALID_ADMIN_SESSION",
        role: "UNKNOWN"
      };
    }
  }

  function loadPilotTenantDraft() {
    const raw = window.localStorage.getItem(CONFIG.pilotTenantDraftKey);
    if (!raw) return CONFIG.fallbackSnapshot.draft;

    try {
      return Object.assign({}, CONFIG.fallbackSnapshot.draft, JSON.parse(raw));
    } catch (_error) {
      return CONFIG.fallbackSnapshot.draft;
    }
  }

  function tenantOpeningScopeHeaders() {
    const session = getAdminSession();

    return {
      "Content-Type": "application/json",
      "X-Admin-Session": session.session_id,
      "X-Tenant-Opening-Scope": "controlled-pilot-tenant-opening",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "merchant_panel_controlled_access",
      "X-Pix2pi-Step": "347"
    };
  }

  function validateTenantOpeningScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.admin_session_id) {
      errors.push({ field: "admin_session_id", code: "ADMIN_SESSION_REQUIRED" });
    }

    if (!snapshot || !snapshot.tenant_opening_scope) {
      errors.push({ field: "tenant_opening_scope", code: "OPENING_SCOPE_REQUIRED" });
    }

    if (!snapshot || !snapshot.draft || !snapshot.draft.tenant_slug) {
      errors.push({ field: "draft.tenant_slug", code: "TENANT_SLUG_REQUIRED" });
    }

    if (!snapshot || !snapshot.draft || !snapshot.draft.default_plan_code) {
      errors.push({ field: "draft.default_plan_code", code: "DEFAULT_PLAN_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: tenantOpeningScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("PILOT_TENANT_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchPilotTenantSnapshot() {
    try {
      return await apiJson(CONFIG.pilotTenantDraftEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      const session = getAdminSession();
      snapshot.admin_session_id = session.session_id;
      snapshot.draft = loadPilotTenantDraft();
      return snapshot;
    }
  }

  function buildPilotTenantDraftPayload(snapshot) {
    return {
      tenant_id: snapshot.draft.tenant_id,
      tenant_slug: snapshot.draft.tenant_slug,
      business_name: snapshot.draft.business_name,
      sector: snapshot.draft.sector,
      default_plan_code: snapshot.draft.default_plan_code,
      default_language: snapshot.draft.default_language,
      timezone: snapshot.draft.timezone,
      currency: snapshot.draft.currency,
      opening_status: snapshot.draft.opening_status,
      source: {
        surface: "panel_pilot_tenant_opening",
        phase: "FAZ_7R",
        step: "347"
      }
    };
  }

  function buildTenantProvisioningDisabledGuard(snapshot) {
    return {
      accepted: false,
      action: "PROVISION_PILOT_TENANT",
      tenant_slug: snapshot.draft.tenant_slug,
      reason: "REAL_TENANT_INSERT_DISABLED_IN_STEP_347",
      real_tenant_insert_enabled: CONFIG.runtimeContract.realTenantInsertEnabled,
      real_owner_invite_enabled: CONFIG.runtimeContract.realOwnerInviteEnabled,
      real_tenant_activation_enabled: CONFIG.runtimeContract.realTenantActivationEnabled,
      real_customer_access_enabled: CONFIG.runtimeContract.realCustomerAccessEnabled,
      source: {
        surface: "panel_pilot_tenant_opening",
        phase: "FAZ_7R",
        step: "347"
      }
    };
  }

  function buildTenantOpeningRuntimeContract(snapshot) {
    return {
      admin_session_id: snapshot.admin_session_id,
      tenant_opening_scope: snapshot.tenant_opening_scope,
      correlation_id: snapshot.correlation_id,
      tenant_slug: snapshot.draft.tenant_slug,
      opening_status: snapshot.draft.opening_status,
      default_plan_code: snapshot.draft.default_plan_code,
      runtime_contract: CONFIG.runtimeContract,
      approval_gates: CONFIG.approvalGates,
      scope_validation: validateTenantOpeningScope(snapshot),
      source: {
        surface: "panel_pilot_tenant_opening",
        phase: "FAZ_7R",
        step: "347"
      }
    };
  }

  function renderDraftContext(snapshot) {
    const tenant = document.getElementById("pilot-tenant-id");
    const slug = document.getElementById("pilot-tenant-slug");
    const env = document.getElementById("pilot-tenant-environment");
    const status = document.getElementById("pilot-tenant-status");
    const validation = document.getElementById("pilot-tenant-scope-validation");
    const contract = buildTenantOpeningRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.draft.tenant_id;
    if (slug) slug.textContent = snapshot.draft.tenant_slug;
    if (env) env.textContent = snapshot.draft.environment;
    if (status) status.textContent = snapshot.draft.opening_status;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderBusinessChecklist(snapshot) {
    const target = document.getElementById("pilot-tenant-business-checklist");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.checklist || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "pilot-card";
      row.setAttribute("data-check-code", item.code);
      row.setAttribute("data-check-status", item.status);
      row.innerHTML = [
        "<strong>" + item.label + "</strong>",
        "<p>Status: " + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderApprovalGates(snapshot) {
    const target = document.getElementById("pilot-tenant-approval-gates");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.gates || []).forEach(function (gate) {
      const row = document.createElement("article");
      row.className = "pilot-card";
      row.setAttribute("data-gate-code", gate.code);
      row.setAttribute("data-gate-status", gate.status);
      row.innerHTML = [
        "<strong>" + gate.label + "</strong>",
        "<p>Status: " + gate.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAccessPreparation(snapshot) {
    const target = document.getElementById("pilot-tenant-access-preparation");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.access_preparation || []).forEach(function (access) {
      const row = document.createElement("article");
      row.className = "pilot-card";
      row.setAttribute("data-surface", access.surface);
      row.innerHTML = [
        "<strong>" + access.surface + "</strong>",
        "<p>" + access.url + " / " + access.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAuditTimeline(snapshot) {
    const target = document.getElementById("pilot-tenant-audit-timeline");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.audit_timeline || []).forEach(function (event) {
      const row = document.createElement("article");
      row.className = "pilot-card";
      row.setAttribute("data-audit-action", event.action);
      row.innerHTML = [
        "<strong>" + event.action + "</strong>",
        "<p>" + event.at + " / " + event.actor + " / " + event.result + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("pilot-tenant-runtime-contract");
    if (!target) return;

    const contract = buildTenantOpeningRuntimeContract(snapshot);

    target.textContent = [
      "real_tenant_insert_enabled=" + CONFIG.runtimeContract.realTenantInsertEnabled,
      "real_owner_invite_enabled=" + CONFIG.runtimeContract.realOwnerInviteEnabled,
      "real_tenant_activation_enabled=" + CONFIG.runtimeContract.realTenantActivationEnabled,
      "real_customer_access_enabled=" + CONFIG.runtimeContract.realCustomerAccessEnabled,
      "controlled_opening_gate_enabled=" + CONFIG.runtimeContract.controlledOpeningGateEnabled,
      "ready_for_step_348=" + CONFIG.runtimeContract.readyForStep348,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderPilotTenantScreen(snapshot) {
    renderDraftContext(snapshot);
    renderBusinessChecklist(snapshot);
    renderApprovalGates(snapshot);
    renderAccessPreparation(snapshot);
    renderAuditTimeline(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-panel-pilot-tenant-rendered", "true");
  }

  async function bootPilotTenantScreen() {
    const snapshot = await fetchPilotTenantSnapshot();
    renderPilotTenantScreen(snapshot);
    return buildTenantOpeningRuntimeContract(snapshot);
  }

  window.Pix2piPanelPilotTenant = {
    CONFIG: CONFIG,
    getAdminSession: getAdminSession,
    loadPilotTenantDraft: loadPilotTenantDraft,
    tenantOpeningScopeHeaders: tenantOpeningScopeHeaders,
    validateTenantOpeningScope: validateTenantOpeningScope,
    fetchPilotTenantSnapshot: fetchPilotTenantSnapshot,
    buildPilotTenantDraftPayload: buildPilotTenantDraftPayload,
    buildTenantProvisioningDisabledGuard: buildTenantProvisioningDisabledGuard,
    buildTenantOpeningRuntimeContract: buildTenantOpeningRuntimeContract,
    renderDraftContext: renderDraftContext,
    renderBusinessChecklist: renderBusinessChecklist,
    renderApprovalGates: renderApprovalGates,
    renderAccessPreparation: renderAccessPreparation,
    renderAuditTimeline: renderAuditTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderPilotTenantScreen: renderPilotTenantScreen,
    bootPilotTenantScreen: bootPilotTenantScreen
  };
})();
/* PIX2PI_347_PANEL_PILOT_TENANT_RUNTIME_END */
