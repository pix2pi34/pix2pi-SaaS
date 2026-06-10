/* PIX2PI_333_POS_OFFLINE_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "pos_offline_ready",
    phase: "FAZ_7R",
    step: "333",
    offlineSyncEndpoint: "/api/pos/offline/sync",
    replayStatusEndpoint: "/api/pos/offline/replay-status",
    selectedTenantKey: "pix2pi.pos.tenant.preference",
    deviceKey: "pix2pi.pos.device.id",
    cashierSessionKey: "pix2pi.pos.cashier.session",
    checkoutDraftKey: "pix2pi.pos.checkout.draft",
    offlineQueueKey: "pix2pi.pos.offline.queue",
    offlineContract: {
      realOfflineReplayEnabled: false,
      realStockDecrementEnabled: false,
      realPaymentFinalizeEnabled: false,
      localQueueEnabled: true,
      idempotencyRequired: true,
      conflictResolutionRequired: true,
      readyForStep334: true
    },
    retentionPolicy: {
      maxQueueItems: 500,
      maxAgeDays: 7,
      clearRequiresSupervisor: true
    },
    conflictPolicy: {
      stockConflict: "REQUIRE_REVIEW",
      paymentConflict: "DO_NOT_REPLAY_PAYMENT_WITHOUT_PROVIDER_CONFIRMATION",
      duplicateIdempotencyKey: "SKIP_DUPLICATE"
    }
  };

  function getSelectedTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || "controlled-pilot";
  }

  function getOrCreateDeviceId() {
    let deviceId = window.localStorage.getItem(CONFIG.deviceKey);
    if (!deviceId) {
      deviceId = "pos-device-" + Math.random().toString(36).slice(2, 10);
      window.localStorage.setItem(CONFIG.deviceKey, deviceId);
    }
    return deviceId;
  }

  function getCashierSession() {
    const raw = window.localStorage.getItem(CONFIG.cashierSessionKey);
    if (!raw) return null;

    try {
      return JSON.parse(raw);
    } catch (_error) {
      return null;
    }
  }

  function getCashierCode() {
    const session = getCashierSession();
    return session && session.cashier_code ? session.cashier_code : "DEMO_CASHIER";
  }

  function tenantDeviceCashierHeaders() {
    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getSelectedTenantId(),
      "X-POS-Device-ID": getOrCreateDeviceId(),
      "X-POS-Cashier-Code": getCashierCode(),
      "X-Pix2pi-Surface": "pos",
      "X-Pix2pi-Step": "333"
    };
  }

  function getNetworkStatus() {
    return {
      online: window.navigator.onLine,
      label: window.navigator.onLine ? "ONLINE" : "OFFLINE",
      checked_at: new Date().toISOString()
    };
  }

  function generateIdempotencyKey(prefix) {
    const base = [
      prefix || "offline-sale",
      getSelectedTenantId(),
      getOrCreateDeviceId(),
      getCashierCode(),
      Date.now(),
      Math.random().toString(36).slice(2, 10)
    ].join(":");

    return base.replace(/[^A-Za-z0-9_.:-]/g, "_");
  }

  function loadOfflineQueue() {
    const raw = window.localStorage.getItem(CONFIG.offlineQueueKey);
    if (!raw) return [];

    try {
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed : [];
    } catch (_error) {
      return [];
    }
  }

  function saveOfflineQueue(queue) {
    const safeQueue = Array.isArray(queue) ? queue : [];
    window.localStorage.setItem(CONFIG.offlineQueueKey, JSON.stringify(safeQueue));
    return safeQueue;
  }

  function loadCheckoutDraft() {
    const raw = window.localStorage.getItem(CONFIG.checkoutDraftKey);
    if (!raw) return null;

    try {
      return JSON.parse(raw);
    } catch (_error) {
      return null;
    }
  }

  function buildOfflineSaleDraft(checkoutDraft) {
    const draft = checkoutDraft || loadCheckoutDraft() || {
      tenant_id: getSelectedTenantId(),
      device_id: getOrCreateDeviceId(),
      cashier_code: getCashierCode(),
      cart: [],
      totals: {
        gross_total: 0,
        vat_total: 0,
        grand_total: 0,
        currency: "TRY"
      },
      payment: {
        method: "CASH",
        provider_live_enabled: false
      }
    };

    return {
      idempotency_key: generateIdempotencyKey("pos-offline-sale"),
      tenant_id: getSelectedTenantId(),
      device_id: getOrCreateDeviceId(),
      cashier_code: getCashierCode(),
      payload_type: "CHECKOUT_DRAFT",
      payload: draft,
      queue_status: "LOCAL_PENDING",
      replay_status: "NOT_REPLAYED",
      conflict_status: "NOT_CHECKED",
      created_at: new Date().toISOString(),
      replay_attempt_count: 0,
      offline_contract: CONFIG.offlineContract,
      source: {
        surface: "pos_offline_ready",
        phase: "FAZ_7R",
        step: "333"
      }
    };
  }

  function enqueueOfflineSaleDraft(checkoutDraft) {
    const queue = loadOfflineQueue();
    const item = buildOfflineSaleDraft(checkoutDraft);

    if (queue.some(function (existing) { return existing.idempotency_key === item.idempotency_key; })) {
      return {
        queued: false,
        reason: "DUPLICATE_IDEMPOTENCY_KEY",
        item: item,
        queue: queue
      };
    }

    queue.push(item);

    if (queue.length > CONFIG.retentionPolicy.maxQueueItems) {
      queue.shift();
    }

    saveOfflineQueue(queue);

    return {
      queued: true,
      item: item,
      queue: queue
    };
  }

  function buildSyncPayload() {
    const queue = loadOfflineQueue();

    return {
      tenant_id: getSelectedTenantId(),
      device_id: getOrCreateDeviceId(),
      cashier_code: getCashierCode(),
      queue: queue,
      replay_enabled: CONFIG.offlineContract.realOfflineReplayEnabled,
      stock_decrement_enabled: CONFIG.offlineContract.realStockDecrementEnabled,
      payment_finalize_enabled: CONFIG.offlineContract.realPaymentFinalizeEnabled,
      conflict_policy: CONFIG.conflictPolicy,
      source: {
        surface: "pos_offline_ready",
        phase: "FAZ_7R",
        step: "333"
      }
    };
  }

  function validateOfflineQueue(queue) {
    const errors = [];
    const seen = {};

    (queue || []).forEach(function (item, index) {
      if (!item.idempotency_key) {
        errors.push({ index: index, field: "idempotency_key", code: "REQUIRED" });
      }

      if (item.idempotency_key && seen[item.idempotency_key]) {
        errors.push({ index: index, field: "idempotency_key", code: "DUPLICATE" });
      }

      seen[item.idempotency_key] = true;

      if (!item.tenant_id || !item.device_id || !item.cashier_code) {
        errors.push({ index: index, field: "scope", code: "TENANT_DEVICE_CASHIER_REQUIRED" });
      }
    });

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  function evaluateConflictPreview(queue) {
    const list = queue || loadOfflineQueue();

    return {
      total_items: list.length,
      pending_items: list.filter(function (item) { return item.queue_status === "LOCAL_PENDING"; }).length,
      duplicate_keys: validateOfflineQueue(list).errors.filter(function (err) { return err.code === "DUPLICATE"; }).length,
      policy: CONFIG.conflictPolicy
    };
  }

  function clearOfflineQueue(supervisorApproved) {
    if (!supervisorApproved && CONFIG.retentionPolicy.clearRequiresSupervisor) {
      return {
        cleared: false,
        reason: "SUPERVISOR_APPROVAL_REQUIRED",
        queue: loadOfflineQueue()
      };
    }

    saveOfflineQueue([]);
    return {
      cleared: true,
      queue: []
    };
  }

  async function apiJson(endpoint, options) {
    const response = await fetch(endpoint, Object.assign({
      headers: tenantDeviceCashierHeaders()
    }, options || {}));

    if (!response.ok) {
      throw new Error("POS_OFFLINE_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function requestReplayStatus() {
    try {
      return await apiJson(CONFIG.replayStatusEndpoint, { method: "GET" });
    } catch (_error) {
      return {
        replay_enabled: CONFIG.offlineContract.realOfflineReplayEnabled,
        status: "LOCAL_ONLY",
        queue_count: loadOfflineQueue().length
      };
    }
  }

  async function syncOfflineQueueDryRun() {
    const payload = buildSyncPayload();
    const validation = validateOfflineQueue(payload.queue);

    if (!validation.valid) {
      return {
        synced: false,
        validation: validation,
        payload: payload
      };
    }

    if (!CONFIG.offlineContract.realOfflineReplayEnabled) {
      return {
        synced: false,
        dry_run_only: true,
        replay_enabled: false,
        validation: validation,
        payload: payload
      };
    }

    try {
      const response = await apiJson(CONFIG.offlineSyncEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });

      return {
        synced: true,
        validation: validation,
        response: response
      };
    } catch (_error) {
      return {
        synced: false,
        validation: validation,
        fallback_payload: payload
      };
    }
  }

  function renderNetworkStatus(target) {
    if (!target) return;

    const status = getNetworkStatus();
    target.textContent = status.label;
    target.setAttribute("data-network-online", String(status.online));
  }

  function renderOfflineQueue(target, queue) {
    if (!target) return;

    const list = queue || loadOfflineQueue();
    target.innerHTML = "";

    if (list.length === 0) {
      const empty = document.createElement("article");
      empty.className = "offline-row";
      empty.setAttribute("data-empty-queue", "true");
      empty.innerHTML = "<strong>Queue boş</strong><span>LOCAL_READY</span>";
      target.appendChild(empty);
      return;
    }

    list.forEach(function (item) {
      const row = document.createElement("article");
      row.className = "offline-row";
      row.setAttribute("data-idempotency-key", item.idempotency_key);
      row.innerHTML = [
        "<div>",
        "<strong>" + item.idempotency_key + "</strong>",
        "<p>" + item.payload_type + " / " + item.queue_status + "</p>",
        "</div>",
        "<span>" + item.replay_status + "</span>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderOfflineSummary() {
    const queue = loadOfflineQueue();
    const validation = validateOfflineQueue(queue);
    const conflict = evaluateConflictPreview(queue);

    const queueCount = document.getElementById("offline-queue-count");
    const validationStatus = document.getElementById("offline-validation-status");
    const conflictStatus = document.getElementById("offline-conflict-status");

    if (queueCount) queueCount.textContent = String(queue.length);
    if (validationStatus) validationStatus.textContent = validation.valid ? "VALID" : "INVALID";
    if (conflictStatus) conflictStatus.textContent = "pending=" + conflict.pending_items + " duplicate=" + conflict.duplicate_keys;

    renderOfflineQueue(document.getElementById("offline-queue-list"), queue);
    document.body.setAttribute("data-pos-offline-rendered", "true");
  }

  function bootPOSOfflineScreen() {
    renderNetworkStatus(document.getElementById("offline-network-status"));
    renderOfflineSummary();
    return {
      network: getNetworkStatus(),
      queue: loadOfflineQueue(),
      contract: CONFIG.offlineContract
    };
  }

  window.Pix2piPOSOffline = {
    CONFIG: CONFIG,
    getSelectedTenantId: getSelectedTenantId,
    getOrCreateDeviceId: getOrCreateDeviceId,
    getCashierSession: getCashierSession,
    getCashierCode: getCashierCode,
    tenantDeviceCashierHeaders: tenantDeviceCashierHeaders,
    getNetworkStatus: getNetworkStatus,
    generateIdempotencyKey: generateIdempotencyKey,
    loadOfflineQueue: loadOfflineQueue,
    saveOfflineQueue: saveOfflineQueue,
    loadCheckoutDraft: loadCheckoutDraft,
    buildOfflineSaleDraft: buildOfflineSaleDraft,
    enqueueOfflineSaleDraft: enqueueOfflineSaleDraft,
    buildSyncPayload: buildSyncPayload,
    validateOfflineQueue: validateOfflineQueue,
    evaluateConflictPreview: evaluateConflictPreview,
    clearOfflineQueue: clearOfflineQueue,
    requestReplayStatus: requestReplayStatus,
    syncOfflineQueueDryRun: syncOfflineQueueDryRun,
    renderNetworkStatus: renderNetworkStatus,
    renderOfflineQueue: renderOfflineQueue,
    renderOfflineSummary: renderOfflineSummary,
    bootPOSOfflineScreen: bootPOSOfflineScreen
  };
})();
/* PIX2PI_333_POS_OFFLINE_RUNTIME_END */
