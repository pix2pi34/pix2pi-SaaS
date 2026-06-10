/* PIX2PI_342_PANEL_QUOTA_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "panel_quota",
    phase: "FAZ_7R",
    step: "342",
    quotaSnapshotEndpoint: "/api/commercial/quota/snapshot",
    entitlementPreviewEndpoint: "/api/commercial/entitlements/preview",
    quotaAlertEndpoint: "/api/commercial/quota/alerts",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    merchantSessionKey: "pix2pi.panel.merchant.session",
    runtimeContract: {
      realQuotaEnforcementEnabled: false,
      realPlanChangeEnabled: false,
      realPaymentCollectionEnabled: false,
      quotaSnapshotEnabled: true,
      fallbackQuotaSnapshotEnabled: true,
      readyForStep343: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      merchant_session_id: "MERCHANT_DEMO_SESSION",
      current_plan_code: "pilot_free",
      plan_label: "Pilot Free",
      quotas: [
        { code: "products", label: "Ürün limiti", used: 72, limit: 250, unit: "ürün", scope: "catalog" },
        { code: "users", label: "Kullanıcı limiti", used: 2, limit: 3, unit: "kullanıcı", scope: "merchant_panel" },
        { code: "stores", label: "Mağaza / şube limiti", used: 1, limit: 1, unit: "mağaza", scope: "tenant" },
        { code: "pos_devices", label: "POS cihaz / kasa", used: 1, limit: 2, unit: "kasa", scope: "pos" },
        { code: "market_visible_products", label: "Marketplace görünür ürün", used: 45, limit: 200, unit: "ürün", scope: "marketplace" },
        { code: "api_events_imports", label: "API / event / import", used: 1200, limit: 10000, unit: "işlem", scope: "platform" }
      ],
      alerts: [
        { level: "INFO", code: "PILOT_LIMITS_VISIBLE", title: "Pilot kullanım hakları görünür", description: "Gerçek enforcement kapalıdır." },
        { level: "WARN", code: "STORE_LIMIT_FULL", title: "Mağaza limiti dolu", description: "Pilot Free planında 1 mağaza sınırı görünür." }
      ],
      upgrade_handoff: {
        target_path: "/plans/",
        suggested_plan_code: "small_business",
        reason: "Daha fazla mağaza, kullanıcı ve ürün limiti için paket yükseltme önerilir."
      }
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSnapshot.tenant_id;
  }

  function getMerchantSession() {
    const raw = window.localStorage.getItem(CONFIG.merchantSessionKey);
    if (!raw) {
      return {
        session_present: false,
        session_id: CONFIG.fallbackSnapshot.merchant_session_id,
        role: "OWNER"
      };
    }

    try {
      return Object.assign({ session_present: true }, JSON.parse(raw));
    } catch (_error) {
      return {
        session_present: false,
        session_id: "INVALID_MERCHANT_SESSION",
        role: "UNKNOWN"
      };
    }
  }

  function quotaScopeHeaders() {
    const session = getMerchantSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Merchant-Session": session.session_id,
      "X-Pix2pi-Surface": "merchant_panel_commercial",
      "X-Pix2pi-Step": "342"
    };
  }

  function percentUsed(used, limit) {
    if (limit === null || limit === undefined || limit === "custom" || Number(limit) <= 0) return 0;
    return Math.min(999, Math.round((Number(used || 0) / Number(limit || 1)) * 100));
  }

  function quotaStatus(quota) {
    const pct = percentUsed(quota.used, quota.limit);
    if (pct >= 100) return "BLOCK_THRESHOLD";
    if (pct >= 80) return "WARN_THRESHOLD";
    return "OK";
  }

  function validateQuotaScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!snapshot || !snapshot.merchant_session_id) {
      errors.push({ field: "merchant_session_id", code: "MERCHANT_SESSION_REQUIRED" });
    }

    if (!snapshot || !snapshot.current_plan_code) {
      errors.push({ field: "current_plan_code", code: "PLAN_REQUIRED" });
    }

    if (!snapshot || !Array.isArray(snapshot.quotas) || snapshot.quotas.length === 0) {
      errors.push({ field: "quotas", code: "QUOTA_LIST_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: quotaScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("PANEL_QUOTA_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchQuotaSnapshot() {
    try {
      return await apiJson(CONFIG.quotaSnapshotEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      const session = getMerchantSession();
      snapshot.tenant_id = getTenantId();
      snapshot.merchant_session_id = session.session_id;
      return snapshot;
    }
  }

  function buildEntitlementSummary(snapshot) {
    return (snapshot.quotas || []).map(function (quota) {
      const pct = percentUsed(quota.used, quota.limit);
      return {
        code: quota.code,
        label: quota.label,
        used: quota.used,
        limit: quota.limit,
        unit: quota.unit,
        scope: quota.scope,
        percent_used: pct,
        status: quotaStatus(quota),
        enforcement_enabled: CONFIG.runtimeContract.realQuotaEnforcementEnabled
      };
    });
  }

  function buildQuotaRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      merchant_session_id: snapshot.merchant_session_id,
      current_plan_code: snapshot.current_plan_code,
      quota_count: Array.isArray(snapshot.quotas) ? snapshot.quotas.length : 0,
      warning_count: buildEntitlementSummary(snapshot).filter(function (q) { return q.status !== "OK"; }).length,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateQuotaScope(snapshot),
      source: {
        surface: "panel_quota",
        phase: "FAZ_7R",
        step: "342"
      }
    };
  }

  function buildEnforcementDisabledGuard(quotaCode) {
    return {
      accepted: false,
      quota_code: quotaCode,
      reason: "REAL_QUOTA_ENFORCEMENT_DISABLED_IN_STEP_342",
      real_quota_enforcement_enabled: CONFIG.runtimeContract.realQuotaEnforcementEnabled,
      real_plan_change_enabled: CONFIG.runtimeContract.realPlanChangeEnabled,
      real_payment_collection_enabled: CONFIG.runtimeContract.realPaymentCollectionEnabled,
      source: {
        surface: "panel_quota",
        phase: "FAZ_7R",
        step: "342"
      }
    };
  }

  function renderContext(snapshot) {
    const tenant = document.getElementById("quota-tenant");
    const session = document.getElementById("quota-merchant-session");
    const plan = document.getElementById("quota-current-plan");
    const validation = document.getElementById("quota-scope-validation");
    const contract = buildQuotaRuntimeContract(snapshot);

    if (tenant) tenant.textContent = contract.tenant_id;
    if (session) session.textContent = contract.merchant_session_id;
    if (plan) plan.textContent = snapshot.plan_label + " / " + snapshot.current_plan_code;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderQuotaCards(snapshot) {
    const target = document.getElementById("quota-card-grid");
    if (!target) return;

    target.innerHTML = "";

    buildEntitlementSummary(snapshot).forEach(function (quota) {
      const card = document.createElement("article");
      card.className = "quota-card";
      card.setAttribute("data-quota-code", quota.code);
      card.setAttribute("data-quota-status", quota.status);
      card.innerHTML = [
        "<strong>" + quota.label + "</strong>",
        "<p>" + quota.used + " / " + quota.limit + " " + quota.unit + "</p>",
        "<div class='bar'><span style='width:" + Math.min(100, quota.percent_used) + "%'></span></div>",
        "<em>%" + quota.percent_used + "</em>",
        "<small>Scope: " + quota.scope + " / Status: " + quota.status + "</small>"
      ].join("");
      target.appendChild(card);
    });
  }

  function renderSummaryCards(snapshot) {
    const summary = buildEntitlementSummary(snapshot);
    const total = document.getElementById("quota-total-count");
    const ok = document.getElementById("quota-ok-count");
    const warn = document.getElementById("quota-warning-count");
    const blocked = document.getElementById("quota-block-count");

    if (total) total.textContent = String(summary.length);
    if (ok) ok.textContent = String(summary.filter(function (q) { return q.status === "OK"; }).length);
    if (warn) warn.textContent = String(summary.filter(function (q) { return q.status === "WARN_THRESHOLD"; }).length);
    if (blocked) blocked.textContent = String(summary.filter(function (q) { return q.status === "BLOCK_THRESHOLD"; }).length);
  }

  function renderAlerts(snapshot) {
    const target = document.getElementById("quota-alert-panel");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.alerts || []).forEach(function (alert) {
      const item = document.createElement("article");
      item.className = "quota-alert";
      item.setAttribute("data-alert-level", alert.level);
      item.innerHTML = [
        "<strong>" + alert.level + " — " + alert.title + "</strong>",
        "<p>" + alert.description + "</p>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderUpgradeHandoff(snapshot) {
    const link = document.getElementById("quota-upgrade-link");
    const reason = document.getElementById("quota-upgrade-reason");

    if (link) link.setAttribute("href", snapshot.upgrade_handoff.target_path);
    if (reason) reason.textContent = snapshot.upgrade_handoff.reason;
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("quota-runtime-contract");
    if (!target) return;

    const contract = buildQuotaRuntimeContract(snapshot);

    target.textContent = [
      "real_quota_enforcement_enabled=" + CONFIG.runtimeContract.realQuotaEnforcementEnabled,
      "real_plan_change_enabled=" + CONFIG.runtimeContract.realPlanChangeEnabled,
      "real_payment_collection_enabled=" + CONFIG.runtimeContract.realPaymentCollectionEnabled,
      "quota_snapshot_enabled=" + CONFIG.runtimeContract.quotaSnapshotEnabled,
      "ready_for_step_343=" + CONFIG.runtimeContract.readyForStep343,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderQuotaScreen(snapshot) {
    renderContext(snapshot);
    renderSummaryCards(snapshot);
    renderQuotaCards(snapshot);
    renderAlerts(snapshot);
    renderUpgradeHandoff(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-panel-quota-rendered", "true");
  }

  async function bootQuotaScreen() {
    const snapshot = await fetchQuotaSnapshot();
    renderQuotaScreen(snapshot);
    return buildQuotaRuntimeContract(snapshot);
  }

  window.Pix2piPanelQuota = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getMerchantSession: getMerchantSession,
    quotaScopeHeaders: quotaScopeHeaders,
    percentUsed: percentUsed,
    quotaStatus: quotaStatus,
    validateQuotaScope: validateQuotaScope,
    fetchQuotaSnapshot: fetchQuotaSnapshot,
    buildEntitlementSummary: buildEntitlementSummary,
    buildQuotaRuntimeContract: buildQuotaRuntimeContract,
    buildEnforcementDisabledGuard: buildEnforcementDisabledGuard,
    renderContext: renderContext,
    renderQuotaCards: renderQuotaCards,
    renderSummaryCards: renderSummaryCards,
    renderAlerts: renderAlerts,
    renderUpgradeHandoff: renderUpgradeHandoff,
    renderRuntimeContract: renderRuntimeContract,
    renderQuotaScreen: renderQuotaScreen,
    bootQuotaScreen: bootQuotaScreen
  };
})();
/* PIX2PI_342_PANEL_QUOTA_RUNTIME_END */
