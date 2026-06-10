/* PIX2PI_349_PANEL_PASSWORD_LOGIN_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "panel_password_login",
    phase: "FAZ_7R",
    step: "349",
    passwordSetupEndpoint: "/api/auth/password/setup",
    loginEndpoint: "/api/auth/login",
    sessionEndpoint: "/api/auth/session",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    inviteTokenKey: "pix2pi.panel.invite.token.preview",
    runtimeContract: {
      realPasswordPersistEnabled: false,
      realJwtIssueEnabled: false,
      realSessionCreateEnabled: false,
      realEmailVerifyEnabled: false,
      realMfaEnabled: false,
      passwordPolicyPreviewEnabled: true,
      loginPreviewEnabled: true,
      fallbackAuthSnapshotEnabled: true,
      readyForStep350: true
    },
    passwordPolicy: {
      minLength: 12,
      requiresUppercase: true,
      requiresLowercase: true,
      requiresNumber: true,
      requiresSymbol: true,
      forbiddenEmailLocalPart: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      invite_id: "INVITE-DRAFT-348-DEMO",
      invite_token_preview: "TOKEN_PREVIEW_DISABLED",
      auth_scope: "controlled-first-user-password-login",
      correlation_id: "FAZ7R-349-DEMO-CORRELATION",
      user: {
        email: "owner@example.invalid",
        full_name: "Pilot Owner Admin",
        role: "OWNER_ADMIN",
        activation_status: "PASSWORD_SETUP_PENDING",
        login_status: "NOT_STARTED"
      },
      error_states: [
        { code: "TOKEN_EXPIRED", label: "Davet süresi doldu", visible: true },
        { code: "PASSWORD_POLICY_FAILED", label: "Şifre politikası sağlanmadı", visible: true },
        { code: "LOGIN_DISABLED", label: "Gerçek giriş bu adımda kapalı", visible: true }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "FIRST_USER_INVITE_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "PASSWORD_SETUP_UI_READY", result: "DRY_RUN" },
        { at: "2026-05-demo", actor: "system", action: "REAL_JWT_ISSUE_BLOCKED", result: "EXPECTED" }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSnapshot.tenant_id;
  }

  function getInviteTokenPreview() {
    return window.localStorage.getItem(CONFIG.inviteTokenKey) || CONFIG.fallbackSnapshot.invite_token_preview;
  }

  function authScopeHeaders() {
    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Invite-Token": getInviteTokenPreview(),
      "X-Auth-Scope": "controlled-first-user-password-login",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "merchant_panel_controlled_access",
      "X-Pix2pi-Step": "349"
    };
  }

  function validateAuthScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!snapshot || !snapshot.invite_id) {
      errors.push({ field: "invite_id", code: "INVITE_REQUIRED" });
    }

    if (!snapshot || !snapshot.auth_scope) {
      errors.push({ field: "auth_scope", code: "AUTH_SCOPE_REQUIRED" });
    }

    if (!snapshot || !snapshot.user || !snapshot.user.email) {
      errors.push({ field: "user.email", code: "EMAIL_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  function checkPasswordPolicy(password, email) {
    const value = String(password || "");
    const localPart = String(email || "").split("@")[0] || "";
    const policy = CONFIG.passwordPolicy;

    const checks = [
      { code: "MIN_LENGTH", passed: value.length >= policy.minLength },
      { code: "UPPERCASE", passed: /[A-ZÇĞİÖŞÜ]/.test(value) },
      { code: "LOWERCASE", passed: /[a-zçğıöşü]/.test(value) },
      { code: "NUMBER", passed: /[0-9]/.test(value) },
      { code: "SYMBOL", passed: /[^A-Za-z0-9ÇĞİÖŞÜçğıöşü]/.test(value) },
      { code: "EMAIL_LOCAL_PART_FORBIDDEN", passed: localPart.length === 0 || !value.toLowerCase().includes(localPart.toLowerCase()) }
    ];

    return {
      valid: checks.every(function (item) { return item.passed; }),
      checks: checks
    };
  }

  function validatePasswordConfirm(password, confirmPassword) {
    return {
      valid: String(password || "") === String(confirmPassword || "") && String(password || "").length > 0,
      code: String(password || "") === String(confirmPassword || "") ? "PASSWORD_MATCH" : "PASSWORD_MISMATCH"
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: authScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("PASSWORD_LOGIN_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchAuthSnapshot() {
    try {
      return await apiJson(CONFIG.passwordSetupEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      snapshot.tenant_id = getTenantId();
      snapshot.invite_token_preview = getInviteTokenPreview();
      return snapshot;
    }
  }

  function buildPasswordSetupPayload(snapshot, password, confirmPassword) {
    const policy = checkPasswordPolicy(password, snapshot.user.email);
    const confirm = validatePasswordConfirm(password, confirmPassword);

    return {
      tenant_id: snapshot.tenant_id,
      invite_id: snapshot.invite_id,
      email: snapshot.user.email,
      role: snapshot.user.role,
      password_policy: policy,
      password_confirm: confirm,
      accepted: false,
      reason: "REAL_PASSWORD_PERSIST_DISABLED_IN_STEP_349",
      source: {
        surface: "panel_password_login",
        phase: "FAZ_7R",
        step: "349"
      }
    };
  }

  function buildLoginPreviewPayload(snapshot, email) {
    return {
      tenant_id: snapshot.tenant_id,
      email: email || snapshot.user.email,
      role: snapshot.user.role,
      accepted: false,
      reason: "REAL_LOGIN_DISABLED_IN_STEP_349",
      real_jwt_issue_enabled: CONFIG.runtimeContract.realJwtIssueEnabled,
      real_session_create_enabled: CONFIG.runtimeContract.realSessionCreateEnabled,
      source: {
        surface: "panel_password_login",
        phase: "FAZ_7R",
        step: "349"
      }
    };
  }

  function buildJwtIssuanceDisabledGuard(snapshot) {
    return {
      accepted: false,
      tenant_id: snapshot.tenant_id,
      invite_id: snapshot.invite_id,
      email: snapshot.user.email,
      reason: "REAL_JWT_ISSUE_DISABLED_IN_STEP_349",
      real_jwt_issue_enabled: CONFIG.runtimeContract.realJwtIssueEnabled,
      real_session_create_enabled: CONFIG.runtimeContract.realSessionCreateEnabled,
      real_password_persist_enabled: CONFIG.runtimeContract.realPasswordPersistEnabled,
      source: {
        surface: "panel_password_login",
        phase: "FAZ_7R",
        step: "349"
      }
    };
  }

  function buildAuthRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      invite_id: snapshot.invite_id,
      auth_scope: snapshot.auth_scope,
      user_email: snapshot.user.email,
      activation_status: snapshot.user.activation_status,
      login_status: snapshot.user.login_status,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateAuthScope(snapshot),
      source: {
        surface: "panel_password_login",
        phase: "FAZ_7R",
        step: "349"
      }
    };
  }

  function renderAuthContext(snapshot) {
    const tenant = document.getElementById("auth-tenant-id");
    const invite = document.getElementById("auth-invite-id");
    const email = document.getElementById("auth-email");
    const role = document.getElementById("auth-role");
    const validation = document.getElementById("auth-scope-validation");
    const contract = buildAuthRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (invite) invite.textContent = snapshot.invite_id;
    if (email) email.textContent = snapshot.user.email;
    if (role) role.textContent = snapshot.user.role;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderPasswordPolicy(snapshot) {
    const password = document.getElementById("password-setup-input");
    const confirm = document.getElementById("password-confirm-input");
    const target = document.getElementById("password-policy-preview");
    const confirmTarget = document.getElementById("password-confirm-preview");

    if (!password || !target) return;

    const policy = checkPasswordPolicy(password.value, snapshot.user.email);
    target.innerHTML = "";

    policy.checks.forEach(function (check) {
      const item = document.createElement("article");
      item.className = "auth-card";
      item.setAttribute("data-policy-code", check.code);
      item.setAttribute("data-policy-passed", String(check.passed));
      item.innerHTML = [
        "<strong>" + check.code + "</strong>",
        "<p>passed=" + check.passed + "</p>"
      ].join("");
      target.appendChild(item);
    });

    if (confirm && confirmTarget) {
      const confirmResult = validatePasswordConfirm(password.value, confirm.value);
      confirmTarget.textContent = confirmResult.code;
      confirmTarget.setAttribute("data-confirm-valid", String(confirmResult.valid));
    }
  }

  function renderErrorStates(snapshot) {
    const target = document.getElementById("login-error-state-preview");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.error_states || []).forEach(function (state) {
      const row = document.createElement("article");
      row.className = "auth-card";
      row.setAttribute("data-error-code", state.code);
      row.innerHTML = [
        "<strong>" + state.code + "</strong>",
        "<p>" + state.label + " / visible=" + state.visible + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAuditTimeline(snapshot) {
    const target = document.getElementById("auth-audit-timeline");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.audit_timeline || []).forEach(function (event) {
      const row = document.createElement("article");
      row.className = "auth-card";
      row.setAttribute("data-audit-action", event.action);
      row.innerHTML = [
        "<strong>" + event.action + "</strong>",
        "<p>" + event.at + " / " + event.actor + " / " + event.result + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("auth-runtime-contract");
    if (!target) return;

    const contract = buildAuthRuntimeContract(snapshot);

    target.textContent = [
      "real_password_persist_enabled=" + CONFIG.runtimeContract.realPasswordPersistEnabled,
      "real_jwt_issue_enabled=" + CONFIG.runtimeContract.realJwtIssueEnabled,
      "real_session_create_enabled=" + CONFIG.runtimeContract.realSessionCreateEnabled,
      "real_mfa_enabled=" + CONFIG.runtimeContract.realMfaEnabled,
      "login_preview_enabled=" + CONFIG.runtimeContract.loginPreviewEnabled,
      "ready_for_step_350=" + CONFIG.runtimeContract.readyForStep350,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderAuthScreen(snapshot) {
    renderAuthContext(snapshot);
    renderPasswordPolicy(snapshot);
    renderErrorStates(snapshot);
    renderAuditTimeline(snapshot);
    renderRuntimeContract(snapshot);

    const password = document.getElementById("password-setup-input");
    const confirm = document.getElementById("password-confirm-input");
    if (password) password.addEventListener("input", function () { renderPasswordPolicy(snapshot); });
    if (confirm) confirm.addEventListener("input", function () { renderPasswordPolicy(snapshot); });

    document.body.setAttribute("data-panel-password-login-rendered", "true");
  }

  async function bootAuthScreen() {
    const snapshot = await fetchAuthSnapshot();
    renderAuthScreen(snapshot);
    return buildAuthRuntimeContract(snapshot);
  }

  window.Pix2piPanelPasswordLogin = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getInviteTokenPreview: getInviteTokenPreview,
    authScopeHeaders: authScopeHeaders,
    validateAuthScope: validateAuthScope,
    checkPasswordPolicy: checkPasswordPolicy,
    validatePasswordConfirm: validatePasswordConfirm,
    fetchAuthSnapshot: fetchAuthSnapshot,
    buildPasswordSetupPayload: buildPasswordSetupPayload,
    buildLoginPreviewPayload: buildLoginPreviewPayload,
    buildJwtIssuanceDisabledGuard: buildJwtIssuanceDisabledGuard,
    buildAuthRuntimeContract: buildAuthRuntimeContract,
    renderAuthContext: renderAuthContext,
    renderPasswordPolicy: renderPasswordPolicy,
    renderErrorStates: renderErrorStates,
    renderAuditTimeline: renderAuditTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderAuthScreen: renderAuthScreen,
    bootAuthScreen: bootAuthScreen
  };
})();
/* PIX2PI_349_PANEL_PASSWORD_LOGIN_RUNTIME_END */
