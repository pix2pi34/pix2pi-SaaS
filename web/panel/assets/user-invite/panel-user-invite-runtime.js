/* PIX2PI_348_PANEL_USER_INVITE_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "panel_user_invite",
    phase: "FAZ_7R",
    step: "348",
    inviteDraftEndpoint: "/api/admin/pilot-tenants/user-invite-draft",
    inviteSendEndpoint: "/api/admin/pilot-tenants/user-invites",
    inviteAuditEndpoint: "/api/admin/pilot-tenants/user-invite-audit",
    adminSessionKey: "pix2pi.panel.admin.session",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    inviteDraftKey: "pix2pi.panel.user_invite.draft",
    runtimeContract: {
      realUserCreateEnabled: false,
      realInviteTokenEnabled: false,
      realEmailSendEnabled: false,
      realSmsSendEnabled: false,
      realPasswordSetupEnabled: false,
      inviteDraftEnabled: true,
      duplicateInvitationGuardEnabled: true,
      fallbackInviteSnapshotEnabled: true,
      readyForStep349: true
    },
    fallbackSnapshot: {
      admin_session_id: "ADMIN_DEMO_SESSION",
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      invite_scope: "controlled-first-business-user-invite",
      correlation_id: "FAZ7R-348-DEMO-CORRELATION",
      invite_draft: {
        invite_id: "INVITE-DRAFT-348-DEMO",
        email: "owner@example.invalid",
        phone_placeholder: "+90-000-000-0000",
        full_name: "Pilot Owner Admin",
        role: "OWNER_ADMIN",
        channel: "EMAIL_PLACEHOLDER",
        status: "DRAFT_NOT_SENT",
        password_setup_status: "HANDOFF_TO_STEP_349"
      },
      allowed_roles: [
        { code: "OWNER_ADMIN", label: "Owner Admin", default: true },
        { code: "MANAGER", label: "Manager", default: false },
        { code: "CASHIER", label: "Cashier", default: false },
        { code: "ACCOUNTANT_READONLY", label: "Accountant Readonly", default: false }
      ],
      channels: [
        { code: "EMAIL_PLACEHOLDER", label: "E-posta", enabled: false },
        { code: "SMS_PLACEHOLDER", label: "SMS", enabled: false },
        { code: "WHATSAPP_PLACEHOLDER", label: "WhatsApp", enabled: false }
      ],
      duplicate_guard: {
        duplicate_check_enabled: true,
        duplicate_found: false,
        checked_fields: ["tenant_id", "email", "role"]
      },
      activation_preview: [
        { step: "INVITE_DRAFT", status: "READY" },
        { step: "INVITE_SEND", status: "DISABLED" },
        { step: "PASSWORD_SETUP", status: "HANDOFF_TO_STEP_349" },
        { step: "FIRST_LOGIN", status: "NOT_STARTED" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "PILOT_TENANT_OPENING_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "FIRST_USER_INVITE_DRAFT_CREATED", result: "DRY_RUN" },
        { at: "2026-05-demo", actor: "system", action: "REAL_INVITE_SEND_BLOCKED", result: "EXPECTED" }
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

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSnapshot.tenant_id;
  }

  function loadInviteDraft() {
    const raw = window.localStorage.getItem(CONFIG.inviteDraftKey);
    if (!raw) return CONFIG.fallbackSnapshot.invite_draft;

    try {
      return Object.assign({}, CONFIG.fallbackSnapshot.invite_draft, JSON.parse(raw));
    } catch (_error) {
      return CONFIG.fallbackSnapshot.invite_draft;
    }
  }

  function inviteScopeHeaders() {
    const session = getAdminSession();

    return {
      "Content-Type": "application/json",
      "X-Admin-Session": session.session_id,
      "X-Tenant-ID": getTenantId(),
      "X-Invite-Scope": "controlled-first-business-user-invite",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "merchant_panel_controlled_access",
      "X-Pix2pi-Step": "348"
    };
  }

  function validateInviteScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.admin_session_id) {
      errors.push({ field: "admin_session_id", code: "ADMIN_SESSION_REQUIRED" });
    }

    if (!snapshot || !snapshot.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!snapshot || !snapshot.invite_scope) {
      errors.push({ field: "invite_scope", code: "INVITE_SCOPE_REQUIRED" });
    }

    if (!snapshot || !snapshot.invite_draft || !snapshot.invite_draft.email) {
      errors.push({ field: "invite_draft.email", code: "EMAIL_REQUIRED" });
    }

    if (!snapshot || !snapshot.invite_draft || !snapshot.invite_draft.role) {
      errors.push({ field: "invite_draft.role", code: "ROLE_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  function validateInvitePayload(payload) {
    const errors = [];

    if (!payload.email || !String(payload.email).includes("@")) {
      errors.push({ field: "email", code: "EMAIL_INVALID" });
    }

    if (!payload.full_name || String(payload.full_name).trim().length < 2) {
      errors.push({ field: "full_name", code: "FULL_NAME_REQUIRED" });
    }

    if (!payload.role) {
      errors.push({ field: "role", code: "ROLE_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: inviteScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("FIRST_USER_INVITE_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchInviteSnapshot() {
    try {
      return await apiJson(CONFIG.inviteDraftEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      const session = getAdminSession();
      snapshot.admin_session_id = session.session_id;
      snapshot.tenant_id = getTenantId();
      snapshot.invite_draft = loadInviteDraft();
      return snapshot;
    }
  }

  function buildInviteDraftPayload(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      invite_id: snapshot.invite_draft.invite_id,
      email: snapshot.invite_draft.email,
      full_name: snapshot.invite_draft.full_name,
      role: snapshot.invite_draft.role,
      channel: snapshot.invite_draft.channel,
      status: snapshot.invite_draft.status,
      payload_validation: validateInvitePayload(snapshot.invite_draft),
      source: {
        surface: "panel_user_invite",
        phase: "FAZ_7R",
        step: "348"
      }
    };
  }

  function buildDuplicateInvitationGuard(snapshot) {
    return {
      checked: true,
      tenant_id: snapshot.tenant_id,
      email: snapshot.invite_draft.email,
      role: snapshot.invite_draft.role,
      duplicate_found: Boolean(snapshot.duplicate_guard.duplicate_found),
      duplicate_check_enabled: Boolean(snapshot.duplicate_guard.duplicate_check_enabled),
      decision: snapshot.duplicate_guard.duplicate_found ? "DISABLE" : "ALLOW_DRAFT_ONLY",
      source: {
        surface: "panel_user_invite",
        phase: "FAZ_7R",
        step: "348"
      }
    };
  }

  function buildInviteSendDisabledGuard(snapshot) {
    return {
      accepted: false,
      action: "SEND_FIRST_BUSINESS_USER_INVITE",
      tenant_id: snapshot.tenant_id,
      email: snapshot.invite_draft.email,
      role: snapshot.invite_draft.role,
      reason: "REAL_INVITE_SEND_DISABLED_IN_STEP_348",
      real_user_create_enabled: CONFIG.runtimeContract.realUserCreateEnabled,
      real_invite_token_enabled: CONFIG.runtimeContract.realInviteTokenEnabled,
      real_email_send_enabled: CONFIG.runtimeContract.realEmailSendEnabled,
      real_sms_send_enabled: CONFIG.runtimeContract.realSmsSendEnabled,
      real_password_setup_enabled: CONFIG.runtimeContract.realPasswordSetupEnabled,
      source: {
        surface: "panel_user_invite",
        phase: "FAZ_7R",
        step: "348"
      }
    };
  }

  function buildInviteRuntimeContract(snapshot) {
    return {
      admin_session_id: snapshot.admin_session_id,
      tenant_id: snapshot.tenant_id,
      invite_scope: snapshot.invite_scope,
      correlation_id: snapshot.correlation_id,
      invite_id: snapshot.invite_draft.invite_id,
      invite_status: snapshot.invite_draft.status,
      role: snapshot.invite_draft.role,
      channel: snapshot.invite_draft.channel,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateInviteScope(snapshot),
      duplicate_guard: buildDuplicateInvitationGuard(snapshot),
      source: {
        surface: "panel_user_invite",
        phase: "FAZ_7R",
        step: "348"
      }
    };
  }

  function renderInviteContext(snapshot) {
    const tenant = document.getElementById("invite-tenant-id");
    const slug = document.getElementById("invite-tenant-slug");
    const invite = document.getElementById("invite-id");
    const status = document.getElementById("invite-status");
    const validation = document.getElementById("invite-scope-validation");
    const contract = buildInviteRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (slug) slug.textContent = snapshot.tenant_slug;
    if (invite) invite.textContent = snapshot.invite_draft.invite_id;
    if (status) status.textContent = snapshot.invite_draft.status;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderInviteForm(snapshot) {
    const email = document.getElementById("invite-email");
    const name = document.getElementById("invite-full-name");
    const phone = document.getElementById("invite-phone");
    const role = document.getElementById("invite-role");

    if (email) email.value = snapshot.invite_draft.email;
    if (name) name.value = snapshot.invite_draft.full_name;
    if (phone) phone.value = snapshot.invite_draft.phone_placeholder;

    if (role) {
      role.innerHTML = "";
      (snapshot.allowed_roles || []).forEach(function (item) {
        const option = document.createElement("option");
        option.value = item.code;
        option.textContent = item.label;
        option.selected = item.code === snapshot.invite_draft.role;
        role.appendChild(option);
      });
    }
  }

  function renderChannels(snapshot) {
    const target = document.getElementById("invite-channels");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.channels || []).forEach(function (channel) {
      const row = document.createElement("article");
      row.className = "invite-card";
      row.setAttribute("data-channel-code", channel.code);
      row.setAttribute("data-channel-enabled", String(channel.enabled));
      row.innerHTML = [
        "<strong>" + channel.label + "</strong>",
        "<p>" + channel.code + " / enabled=" + channel.enabled + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderActivationPreview(snapshot) {
    const target = document.getElementById("invite-activation-preview");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.activation_preview || []).forEach(function (step) {
      const row = document.createElement("article");
      row.className = "invite-card";
      row.setAttribute("data-activation-step", step.step);
      row.setAttribute("data-activation-status", step.status);
      row.innerHTML = [
        "<strong>" + step.step + "</strong>",
        "<p>Status: " + step.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAuditTimeline(snapshot) {
    const target = document.getElementById("invite-audit-timeline");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.audit_timeline || []).forEach(function (event) {
      const row = document.createElement("article");
      row.className = "invite-card";
      row.setAttribute("data-audit-action", event.action);
      row.innerHTML = [
        "<strong>" + event.action + "</strong>",
        "<p>" + event.at + " / " + event.actor + " / " + event.result + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("invite-runtime-contract");
    if (!target) return;

    const contract = buildInviteRuntimeContract(snapshot);

    target.textContent = [
      "real_user_create_enabled=" + CONFIG.runtimeContract.realUserCreateEnabled,
      "real_invite_token_enabled=" + CONFIG.runtimeContract.realInviteTokenEnabled,
      "real_email_send_enabled=" + CONFIG.runtimeContract.realEmailSendEnabled,
      "real_sms_send_enabled=" + CONFIG.runtimeContract.realSmsSendEnabled,
      "real_password_setup_enabled=" + CONFIG.runtimeContract.realPasswordSetupEnabled,
      "duplicate_invitation_guard_enabled=" + CONFIG.runtimeContract.duplicateInvitationGuardEnabled,
      "ready_for_step_349=" + CONFIG.runtimeContract.readyForStep349,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderInviteScreen(snapshot) {
    renderInviteContext(snapshot);
    renderInviteForm(snapshot);
    renderChannels(snapshot);
    renderActivationPreview(snapshot);
    renderAuditTimeline(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-panel-user-invite-rendered", "true");
  }

  async function bootInviteScreen() {
    const snapshot = await fetchInviteSnapshot();
    renderInviteScreen(snapshot);
    return buildInviteRuntimeContract(snapshot);
  }

  window.Pix2piPanelUserInvite = {
    CONFIG: CONFIG,
    getAdminSession: getAdminSession,
    getTenantId: getTenantId,
    loadInviteDraft: loadInviteDraft,
    inviteScopeHeaders: inviteScopeHeaders,
    validateInviteScope: validateInviteScope,
    validateInvitePayload: validateInvitePayload,
    fetchInviteSnapshot: fetchInviteSnapshot,
    buildInviteDraftPayload: buildInviteDraftPayload,
    buildDuplicateInvitationGuard: buildDuplicateInvitationGuard,
    buildInviteSendDisabledGuard: buildInviteSendDisabledGuard,
    buildInviteRuntimeContract: buildInviteRuntimeContract,
    renderInviteContext: renderInviteContext,
    renderInviteForm: renderInviteForm,
    renderChannels: renderChannels,
    renderActivationPreview: renderActivationPreview,
    renderAuditTimeline: renderAuditTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderInviteScreen: renderInviteScreen,
    bootInviteScreen: bootInviteScreen
  };
})();
/* PIX2PI_348_PANEL_USER_INVITE_RUNTIME_END */
