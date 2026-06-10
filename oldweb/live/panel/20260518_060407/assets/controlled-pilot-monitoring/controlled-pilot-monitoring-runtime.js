/* PIX2PI_358_CONTROLLED_PILOT_MONITORING_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "controlled_pilot_monitoring",
    phase: "FAZ_7R",
    step: "358",
    monitoringSnapshotEndpoint: "/api/customer-access/pilot-monitoring/snapshot",
    incidentWatchEndpoint: "/api/customer-access/pilot-monitoring/incidents",
    dailyReportEndpoint: "/api/customer-access/pilot-monitoring/daily-report",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    userSessionKey: "pix2pi.panel.user.session",
    runtimeContract: {
      realCustomerDataMutationEnabled: false,
      realSaleEnabled: false,
      realPaymentEnabled: false,
      realInvoiceIssueEnabled: false,
      realStockDecrementEnabled: false,
      pilotMonitoringPreviewEnabled: true,
      incidentWatchPreviewEnabled: true,
      dailyReportPreviewEnabled: true,
      rollbackTriggerPreviewEnabled: true,
      fallbackMonitoringSnapshotEnabled: true,
      readyForStep359: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      customer_name: "Demo Market",
      owner_user: "owner@example.invalid",
      watch_mode: "FIRST_DAY_CONTROLLED_WATCH",
      monitoring_scope: "controlled-pilot-monitoring-first-day-watch",
      correlation_id: "FAZ7R-358-DEMO-CORRELATION",
      watch_timeline: [
        { slot: "T+00", label: "Activation preview complete", status: "PASS" },
        { slot: "T+01", label: "Panel route watch", status: "PASS_PREVIEW" },
        { slot: "T+02", label: "POS route watch", status: "PASS_PREVIEW" },
        { slot: "T+03", label: "Market route watch", status: "PASS_PREVIEW" },
        { slot: "T+04", label: "Support contact check", status: "READY_PREVIEW" }
      ],
      health: [
        { surface: "panel", check: "panel_http_200", status: "PASS_PREVIEW", severity: "ok" },
        { surface: "pos", check: "pos_http_200", status: "PASS_PREVIEW", severity: "ok" },
        { surface: "market", check: "market_http_200", status: "PASS_PREVIEW", severity: "ok" },
        { surface: "auth", check: "session_permission_preview", status: "PASS_PREVIEW", severity: "ok" },
        { surface: "tenant", check: "tenant_isolation_preview", status: "PASS_PREVIEW", severity: "ok" },
        { surface: "localization", check: "language_render_preview", status: "PASS_PREVIEW", severity: "ok" }
      ],
      errors: [
        { source: "panel", count: 0, threshold: 1, status: "OK" },
        { source: "pos", count: 0, threshold: 1, status: "OK" },
        { source: "market", count: 0, threshold: 1, status: "OK" },
        { source: "api", count: 0, threshold: 1, status: "OK" }
      ],
      incidents: [
        { id: "INC-PILOT-001", severity: "P3", title: "Pilot watch placeholder", status: "OPEN_PREVIEW", action: "WATCH" }
      ],
      support_handoff: [
        { channel: "phone", owner: "support-owner", status: "READY_PREVIEW" },
        { channel: "email", owner: "support-owner", status: "READY_PREVIEW" },
        { channel: "whatsapp", owner: "support-owner", status: "READY_PREVIEW" }
      ],
      customer_activity: [
        { event: "panel_view", count: 1, status: "PREVIEW" },
        { event: "pos_view", count: 1, status: "PREVIEW" },
        { event: "market_view", count: 1, status: "PREVIEW" },
        { event: "real_sale", count: 0, status: "DISABLED_EXPECTED" },
        { event: "real_payment", count: 0, status: "DISABLED_EXPECTED" }
      ],
      safety_guards: [
        { code: "REAL_CUSTOMER_DATA_MUTATION_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_SALE_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_PAYMENT_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_INVOICE_DISABLED", status: "ENFORCED", value: false },
        { code: "REAL_STOCK_DECREMENT_DISABLED", status: "ENFORCED", value: false }
      ],
      thresholds: [
        { metric: "p1_incidents", warn_at: 1, current: 0, status: "OK" },
        { metric: "auth_denied_unexpected", warn_at: 1, current: 0, status: "OK" },
        { metric: "tenant_scope_violation", warn_at: 1, current: 0, status: "OK" },
        { metric: "unexpected_mutation", warn_at: 1, current: 0, status: "OK" }
      ],
      rollback_checklist: [
        { trigger: "P1_INCIDENT", action: "STOP_CUSTOMER_ACCESS", status: "READY" },
        { trigger: "TENANT_SCOPE_VIOLATION", action: "STOP_CUSTOMER_ACCESS", status: "READY" },
        { trigger: "UNEXPECTED_MUTATION", action: "STOP_CUSTOMER_ACCESS", status: "READY" },
        { trigger: "SUPPORT_UNAVAILABLE", action: "PAUSE_ACTIVATION", status: "READY" }
      ],
      daily_report: [
        { section: "health", status: "READY_PREVIEW" },
        { section: "incidents", status: "READY_PREVIEW" },
        { section: "support_feedback", status: "READY_PREVIEW" },
        { section: "next_actions", status: "READY_PREVIEW" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "CONTROLLED_ACTIVATION_PREVIEW_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "FIRST_DAY_WATCH_READY", result: "DRY_RUN" },
        { at: "2026-05-demo", actor: "system", action: "MUTATION_GUARD_ACTIVE", result: "EXPECTED" }
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
        session_id: "USER_DEMO_SESSION",
        email: CONFIG.fallbackSnapshot.owner_user,
        role: "OWNER_ADMIN"
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

  function monitoringScopeHeaders() {
    const session = getUserSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-User-Session": session.session_id,
      "X-Pilot-Monitoring-Scope": "controlled-pilot-monitoring-first-day-watch",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "controlled_pilot_monitoring",
      "X-Pix2pi-Step": "358"
    };
  }

  function validateMonitoringScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    if (!snapshot || !snapshot.customer_name) errors.push({ field: "customer_name", code: "CUSTOMER_REQUIRED" });
    if (!snapshot || !snapshot.watch_mode) errors.push({ field: "watch_mode", code: "WATCH_MODE_REQUIRED" });
    if (!snapshot || !snapshot.monitoring_scope) errors.push({ field: "monitoring_scope", code: "MONITORING_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.health)) errors.push({ field: "health", code: "HEALTH_REQUIRED" });

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: monitoringScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("PILOT_MONITORING_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchMonitoringSnapshot() {
    try {
      return await apiJson(CONFIG.monitoringSnapshotEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      snapshot.tenant_id = getTenantId();
      return snapshot;
    }
  }

  function buildPilotHealthDashboard(snapshot) {
    const failed = (snapshot.health || []).filter(function (item) {
      return !["PASS_PREVIEW", "OK"].includes(item.status);
    });

    return {
      total: (snapshot.health || []).length,
      failed: failed,
      valid: failed.length === 0
    };
  }

  function buildRuntimeErrorDashboard(snapshot) {
    const breached = (snapshot.errors || []).filter(function (item) {
      return item.count >= item.threshold;
    });

    return {
      total_sources: (snapshot.errors || []).length,
      breached: breached,
      valid: breached.length === 0
    };
  }

  function buildMutationGuardWatch(snapshot) {
    const failed = (snapshot.safety_guards || []).filter(function (item) {
      return item.value !== false || item.status !== "ENFORCED";
    });

    return {
      total: (snapshot.safety_guards || []).length,
      failed: failed,
      valid: failed.length === 0,
      real_customer_data_mutation_enabled: CONFIG.runtimeContract.realCustomerDataMutationEnabled
    };
  }

  function buildEarlyWarningThresholds(snapshot) {
    const warning = (snapshot.thresholds || []).filter(function (item) {
      return item.current >= item.warn_at || item.status !== "OK";
    });

    return {
      total: (snapshot.thresholds || []).length,
      warning: warning,
      valid: warning.length === 0
    };
  }

  function buildMonitoringDecision(snapshot) {
    const health = buildPilotHealthDashboard(snapshot);
    const errors = buildRuntimeErrorDashboard(snapshot);
    const mutation = buildMutationGuardWatch(snapshot);
    const thresholds = buildEarlyWarningThresholds(snapshot);

    const ok = health.valid && errors.valid && mutation.valid && thresholds.valid;

    return {
      decision: ok ? "FIRST_DAY_WATCH_READY" : "FIRST_DAY_WATCH_BLOCKED",
      ready_for_step_359: ok && CONFIG.runtimeContract.readyForStep359,
      health: health,
      errors: errors,
      mutation: mutation,
      thresholds: thresholds
    };
  }

  function buildMonitoringRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      customer_name: snapshot.customer_name,
      owner_user: snapshot.owner_user,
      watch_mode: snapshot.watch_mode,
      monitoring_scope: snapshot.monitoring_scope,
      correlation_id: snapshot.correlation_id,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateMonitoringScope(snapshot),
      monitoring_decision: buildMonitoringDecision(snapshot),
      source: {
        surface: "controlled_pilot_monitoring",
        phase: "FAZ_7R",
        step: "358"
      }
    };
  }

  function renderContext(snapshot) {
    const tenant = document.getElementById("monitoring-tenant-id");
    const customer = document.getElementById("monitoring-customer-name");
    const owner = document.getElementById("monitoring-owner-user");
    const mode = document.getElementById("monitoring-watch-mode");
    const validation = document.getElementById("monitoring-scope-validation");
    const contract = buildMonitoringRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (customer) customer.textContent = snapshot.customer_name;
    if (owner) owner.textContent = snapshot.owner_user;
    if (mode) mode.textContent = snapshot.watch_mode;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderList(targetId, list, attrs) {
    const target = document.getElementById(targetId);
    if (!target) return;

    target.innerHTML = "";
    (list || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "monitoring-card";
      Object.keys(attrs || {}).forEach(function (key) {
        row.setAttribute(key, item[attrs[key]] || "");
      });
      row.innerHTML = [
        "<strong>" + (item.label || item.check || item.title || item.code || item.metric || item.trigger || item.section || item.event || item.channel || item.action) + "</strong>",
        "<p>" + JSON.stringify(item).replace(/[{}"]/g, "") + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderMonitoringScreen(snapshot) {
    renderContext(snapshot);
    renderList("monitoring-watch-timeline", snapshot.watch_timeline, { "data-watch-slot": "slot" });
    renderList("monitoring-health-list", snapshot.health, { "data-health-surface": "surface", "data-health-status": "status" });
    renderList("monitoring-error-list", snapshot.errors, { "data-error-source": "source", "data-error-status": "status" });
    renderList("monitoring-incident-queue", snapshot.incidents, { "data-incident-id": "id", "data-incident-status": "status" });
    renderList("monitoring-support-handoff", snapshot.support_handoff, { "data-support-channel": "channel", "data-support-status": "status" });
    renderList("monitoring-customer-activity", snapshot.customer_activity, { "data-activity-event": "event", "data-activity-status": "status" });
    renderList("monitoring-safety-guards", snapshot.safety_guards, { "data-safety-code": "code", "data-safety-status": "status" });
    renderList("monitoring-thresholds", snapshot.thresholds, { "data-threshold-metric": "metric", "data-threshold-status": "status" });
    renderList("monitoring-rollback-checklist", snapshot.rollback_checklist, { "data-rollback-trigger": "trigger", "data-rollback-status": "status" });
    renderList("monitoring-daily-report", snapshot.daily_report, { "data-report-section": "section", "data-report-status": "status" });
    renderList("monitoring-audit-timeline", snapshot.audit_timeline, { "data-audit-action": "action" });

    const target = document.getElementById("monitoring-runtime-contract");
    if (target) {
      const contract = buildMonitoringRuntimeContract(snapshot);
      target.textContent = [
        "pilot_monitoring_preview_enabled=" + CONFIG.runtimeContract.pilotMonitoringPreviewEnabled,
        "incident_watch_preview_enabled=" + CONFIG.runtimeContract.incidentWatchPreviewEnabled,
        "real_customer_data_mutation_enabled=" + CONFIG.runtimeContract.realCustomerDataMutationEnabled,
        "decision=" + contract.monitoring_decision.decision,
        "ready_for_step_359=" + CONFIG.runtimeContract.readyForStep359,
        "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
      ].join(" / ");
    }

    document.body.setAttribute("data-controlled-pilot-monitoring-rendered", "true");
  }

  async function bootMonitoringScreen() {
    const snapshot = await fetchMonitoringSnapshot();
    renderMonitoringScreen(snapshot);
    return buildMonitoringRuntimeContract(snapshot);
  }

  window.Pix2piControlledPilotMonitoring = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getUserSession: getUserSession,
    monitoringScopeHeaders: monitoringScopeHeaders,
    validateMonitoringScope: validateMonitoringScope,
    fetchMonitoringSnapshot: fetchMonitoringSnapshot,
    buildPilotHealthDashboard: buildPilotHealthDashboard,
    buildRuntimeErrorDashboard: buildRuntimeErrorDashboard,
    buildMutationGuardWatch: buildMutationGuardWatch,
    buildEarlyWarningThresholds: buildEarlyWarningThresholds,
    buildMonitoringDecision: buildMonitoringDecision,
    buildMonitoringRuntimeContract: buildMonitoringRuntimeContract,
    renderMonitoringScreen: renderMonitoringScreen,
    bootMonitoringScreen: bootMonitoringScreen
  };
})();
/* PIX2PI_358_CONTROLLED_PILOT_MONITORING_RUNTIME_END */
