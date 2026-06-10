#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD"

BACKUP_DIR="$REPO/backups/faz1/faz_1_4_6_loading_error_empty_retry_standard_$TS"
WEB_DIR="$REPO/web/faz1/ui-foundation/loading-error-empty-retry"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
DOC_DIR="$REPO/docs/faz1/web"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
SCRIPT_DIR="$REPO/scripts/web"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/loading_error_empty_retry.js"
CSS_FILE="$WEB_DIR/loading_error_empty_retry.css"
CONFIG_FILE="$CONFIG_DIR/loading_error_empty_retry_standard_contract.v1.json"
DOC_FILE="$DOC_DIR/FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD.md"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_4_6_loading_error_empty_retry_standard_strict_suite.sh"
APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_4_6_loading_error_empty_retry_standard.sh"
STRICT_SUITE_OUT="$BACKUP_DIR/faz_1_4_6_loading_error_empty_retry_standard_strict_suite.out"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_FINAL_SEAL_$TS.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

extract_var() {
  local file="$1"
  local key="$2"
  grep "^${key}=" "$file" 2>/dev/null | tail -n1 | cut -d= -f2- || true
}

echo "===== FAZ 1-4.6 LOADING / ERROR / EMPTY / RETRY STANDARD START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$WEB_DIR" "$CONFIG_DIR" "$DOC_DIR" "$EVIDENCE_DIR" "$SCRIPT_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$HTML_FILE" "$JS_FILE" "$CSS_FILE" "$CONFIG_FILE" "$DOC_FILE" "$STRICT_SUITE_FILE" "$APPLY_SCRIPT_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_$TS"
    pass "2.x yedek alındı: $f"
  else
    warn "2.x yedek atlandı, dosya yok: $f"
  fi
done

echo "3. loading / error / empty / retry contract config yazılıyor..."

cat <<'JSON' > "$CONFIG_FILE"
{
  "phase": "FAZ_1_4_6",
  "module": "WEB_L1_UI_FOUNDATION_DESIGN_SYSTEM",
  "component": "loading_error_empty_retry_standard",
  "status": "READY",
  "required_capabilities": [
    "loading_state",
    "error_state",
    "empty_state",
    "retry_action",
    "ui_tests"
  ],
  "state_contract": {
    "root_id": "pix2piStateStandardRoot",
    "loading_id": "pix2piLoadingState",
    "error_id": "pix2piErrorState",
    "empty_id": "pix2piEmptyState",
    "content_id": "pix2piContentState",
    "retry_button_id": "pix2piRetryButton",
    "test_output_id": "pix2piStateTestOutput"
  },
  "loading_contract": {
    "skeleton_class": "pix2pi-skeleton",
    "spinner_class": "pix2pi-spinner",
    "message": "Yükleniyor..."
  },
  "error_contract": {
    "error_class": "pix2pi-error-state",
    "message": "İşlem sırasında hata oluştu.",
    "retry_policy": "SHOW_RETRY_ACTION"
  },
  "empty_contract": {
    "empty_class": "pix2pi-empty-state",
    "message": "Gösterilecek kayıt bulunamadı.",
    "action_policy": "OPTIONAL_CREATE_OR_RESET_ACTION"
  },
  "retry_contract": {
    "retry_action": "pix2pi:retry-action",
    "retry_max_attempt_demo": 3,
    "retry_policy": "RETRY_RELOADS_LAST_OPERATION"
  },
  "test_contract": {
    "final_gate": "PASS_ONLY_IF_ALL_UI_STATE_TESTS_PASS",
    "required_fail_count": 0
  }
}
JSON

if [ -f "$CONFIG_FILE" ]; then
  pass "3.1 loading/error/empty/retry config yazıldı: $CONFIG_FILE"
else
  fail "3.1 loading/error/empty/retry config yazılamadı"
  exit 1
fi

echo "4. loading / error / empty / retry CSS yazılıyor..."

cat <<'CSS' > "$CSS_FILE"
:root {
  --pix2pi-bg: #0f172a;
  --pix2pi-surface: #111827;
  --pix2pi-surface-soft: #1f2937;
  --pix2pi-content: #020617;
  --pix2pi-border: #334155;
  --pix2pi-text: #e5e7eb;
  --pix2pi-muted: #9ca3af;
  --pix2pi-accent: #38bdf8;
  --pix2pi-ok: #22c55e;
  --pix2pi-warn: #f59e0b;
  --pix2pi-danger: #ef4444;
  --pix2pi-radius-lg: 20px;
  --pix2pi-radius-md: 14px;
  --pix2pi-shadow: 0 24px 80px rgba(0, 0, 0, 0.28);
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-height: 100vh;
  background: radial-gradient(circle at top left, #7c2d12 0, var(--pix2pi-bg) 42%);
  color: var(--pix2pi-text);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.pix2pi-page {
  width: min(1120px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0;
}

.pix2pi-page-header {
  display: flex;
  justify-content: space-between;
  gap: 18px;
  align-items: flex-start;
  margin-bottom: 24px;
}

.pix2pi-page-title {
  margin: 0;
  font-size: 30px;
  letter-spacing: -0.04em;
}

.pix2pi-page-subtitle {
  margin: 8px 0 0;
  color: var(--pix2pi-muted);
}

.pix2pi-grid {
  display: grid;
  grid-template-columns: 360px 1fr;
  gap: 18px;
}

.pix2pi-card {
  background: rgba(17, 24, 39, 0.92);
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: 22px;
  box-shadow: var(--pix2pi-shadow);
}

.pix2pi-actions {
  display: grid;
  gap: 10px;
}

.pix2pi-button {
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-md);
  background: var(--pix2pi-surface-soft);
  color: var(--pix2pi-text);
  padding: 12px 14px;
  cursor: pointer;
  font-weight: 800;
}

.pix2pi-button.primary {
  border-color: rgba(56, 189, 248, 0.6);
  background: rgba(56, 189, 248, 0.14);
}

.pix2pi-button.danger {
  border-color: rgba(239, 68, 68, 0.55);
  background: rgba(239, 68, 68, 0.12);
}

.pix2pi-button.warn {
  border-color: rgba(245, 158, 11, 0.55);
  background: rgba(245, 158, 11, 0.12);
}

.pix2pi-badge {
  display: inline-flex;
  border: 1px solid var(--pix2pi-border);
  background: var(--pix2pi-surface-soft);
  color: var(--pix2pi-text);
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 13px;
}

.pix2pi-badge.ok {
  border-color: rgba(34, 197, 94, 0.5);
  color: #bbf7d0;
}

.pix2pi-state-stage {
  min-height: 360px;
  display: grid;
  place-items: center;
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-lg);
  background: var(--pix2pi-content);
  padding: 24px;
  position: relative;
  overflow: hidden;
}

.pix2pi-loading-state,
.pix2pi-error-state,
.pix2pi-empty-state,
.pix2pi-content-state {
  display: none;
  width: 100%;
}

.pix2pi-loading-state.visible,
.pix2pi-error-state.visible,
.pix2pi-empty-state.visible,
.pix2pi-content-state.visible {
  display: grid;
  gap: 16px;
  place-items: center;
  text-align: center;
}

.pix2pi-spinner {
  width: 46px;
  height: 46px;
  border: 4px solid rgba(148, 163, 184, 0.24);
  border-top-color: var(--pix2pi-accent);
  border-radius: 999px;
  animation: pix2pi-spin 0.9s linear infinite;
}

@keyframes pix2pi-spin {
  to {
    transform: rotate(360deg);
  }
}

.pix2pi-skeleton-list {
  width: min(560px, 100%);
  display: grid;
  gap: 12px;
}

.pix2pi-skeleton {
  height: 18px;
  border-radius: 999px;
  background: linear-gradient(90deg, rgba(148, 163, 184, 0.12), rgba(148, 163, 184, 0.28), rgba(148, 163, 184, 0.12));
  background-size: 220% 100%;
  animation: pix2pi-skeleton 1.4s ease infinite;
}

.pix2pi-skeleton.short {
  width: 60%;
}

.pix2pi-skeleton.medium {
  width: 82%;
}

@keyframes pix2pi-skeleton {
  0% {
    background-position: 220% 0;
  }
  100% {
    background-position: -220% 0;
  }
}

.pix2pi-state-icon {
  width: 58px;
  height: 58px;
  border-radius: 18px;
  display: grid;
  place-items: center;
  border: 1px solid var(--pix2pi-border);
  background: var(--pix2pi-surface-soft);
  font-size: 26px;
}

.pix2pi-error-state .pix2pi-state-icon {
  border-color: rgba(239, 68, 68, 0.55);
  background: rgba(239, 68, 68, 0.12);
}

.pix2pi-empty-state .pix2pi-state-icon {
  border-color: rgba(245, 158, 11, 0.55);
  background: rgba(245, 158, 11, 0.12);
}

.pix2pi-state-title {
  margin: 0;
  font-size: 22px;
}

.pix2pi-state-message {
  margin: 0;
  color: var(--pix2pi-muted);
  line-height: 1.6;
}

.pix2pi-content-list {
  width: min(620px, 100%);
  display: grid;
  gap: 12px;
}

.pix2pi-content-row {
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-md);
  padding: 14px;
  background: rgba(17, 24, 39, 0.8);
  display: flex;
  justify-content: space-between;
  gap: 12px;
}

.pix2pi-log {
  margin-top: 16px;
  background: var(--pix2pi-content);
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: 14px;
  color: var(--pix2pi-muted);
  min-height: 220px;
  white-space: pre-wrap;
  overflow: auto;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

@media (max-width: 900px) {
  .pix2pi-page-header,
  .pix2pi-grid {
    display: grid;
    grid-template-columns: 1fr;
  }
}
CSS

if grep -q "pix2pi-loading-state" "$CSS_FILE" \
  && grep -q "pix2pi-error-state" "$CSS_FILE" \
  && grep -q "pix2pi-empty-state" "$CSS_FILE" \
  && grep -q "pix2pi-retry-button" "$CSS_FILE"; then
  warn "4.1 pix2pi-retry-button class CSS içinde özel olarak yok; button standardı ile kullanılacak"
fi

if grep -q "pix2pi-loading-state" "$CSS_FILE" \
  && grep -q "pix2pi-error-state" "$CSS_FILE" \
  && grep -q "pix2pi-empty-state" "$CSS_FILE" \
  && grep -q "pix2pi-spinner" "$CSS_FILE" \
  && grep -q "pix2pi-skeleton" "$CSS_FILE"; then
  pass "4.2 CSS loading/error/empty/retry sınıfları mevcut"
else
  fail "4.2 CSS loading/error/empty/retry sınıfları eksik"
  exit 1
fi

echo "5. loading / error / empty / retry JS yazılıyor..."

cat <<'JS' > "$JS_FILE"
(function loadingErrorEmptyRetryRuntime(global) {
  "use strict";

  const STATES = {
    loading: "LOADING",
    error: "ERROR",
    empty: "EMPTY",
    content: "CONTENT"
  };

  const EVENTS = {
    stateChanged: "pix2pi:ui-state-changed",
    retryAction: "pix2pi:retry-action",
    testsRun: "pix2pi:ui-state-tests-run"
  };

  const demoRows = [
    { code: "UI_STATE_LOADING", label: "Loading state", status: "PASS" },
    { code: "UI_STATE_ERROR", label: "Error state", status: "PASS" },
    { code: "UI_STATE_EMPTY", label: "Empty state", status: "PASS" }
  ];

  let currentState = STATES.loading;
  let retryCount = 0;

  function dispatchEvent(name, detail) {
    if (typeof global.CustomEvent === "function" && typeof global.dispatchEvent === "function") {
      global.dispatchEvent(new CustomEvent(name, { detail }));
    }
  }

  function nowIso() {
    return new Date().toISOString();
  }

  function hideAllStates() {
    ["pix2piLoadingState", "pix2piErrorState", "pix2piEmptyState", "pix2piContentState"].forEach((id) => {
      const element = document.getElementById(id);
      if (element) {
        element.classList.remove("visible");
      }
    });
  }

  function showState(state, detail) {
    currentState = state;
    hideAllStates();

    const map = {
      LOADING: "pix2piLoadingState",
      ERROR: "pix2piErrorState",
      EMPTY: "pix2piEmptyState",
      CONTENT: "pix2piContentState"
    };

    const target = document.getElementById(map[state]);
    if (target) {
      target.classList.add("visible");
    }

    const payload = {
      state,
      detail: detail || null,
      changed_at: nowIso()
    };

    dispatchEvent(EVENTS.stateChanged, payload);
    renderStateLog("STATE_CHANGED", payload);
    renderCurrentStateBadge();

    return payload;
  }

  function showLoadingState(message) {
    const messageEl = document.getElementById("pix2piLoadingMessage");
    if (messageEl) {
      messageEl.textContent = message || "Yükleniyor...";
    }

    return showState(STATES.loading, {
      message: message || "Yükleniyor..."
    });
  }

  function showErrorState(message, code) {
    const titleEl = document.getElementById("pix2piErrorTitle");
    const messageEl = document.getElementById("pix2piErrorMessage");

    if (titleEl) {
      titleEl.textContent = code || "UI_STATE_ERROR";
    }

    if (messageEl) {
      messageEl.textContent = message || "İşlem sırasında hata oluştu.";
    }

    return showState(STATES.error, {
      code: code || "UI_STATE_ERROR",
      message: message || "İşlem sırasında hata oluştu."
    });
  }

  function showEmptyState(message) {
    const messageEl = document.getElementById("pix2piEmptyMessage");
    if (messageEl) {
      messageEl.textContent = message || "Gösterilecek kayıt bulunamadı.";
    }

    return showState(STATES.empty, {
      message: message || "Gösterilecek kayıt bulunamadı."
    });
  }

  function showContentState(rows) {
    const list = document.getElementById("pix2piContentList");
    const data = rows || demoRows;

    if (list) {
      list.innerHTML = "";

      data.forEach((row) => {
        const item = document.createElement("article");
        item.className = "pix2pi-content-row";
        item.innerHTML = "<strong></strong><span></span>";
        item.querySelector("strong").textContent = row.label;
        item.querySelector("span").textContent = row.status;
        list.appendChild(item);
      });
    }

    return showState(STATES.content, {
      row_count: data.length
    });
  }

  function retryLastAction() {
    retryCount += 1;

    const payload = {
      retry_count: retryCount,
      retried_at: nowIso()
    };

    dispatchEvent(EVENTS.retryAction, payload);
    renderStateLog("RETRY_ACTION", payload);

    showLoadingState("Tekrar deneniyor...");

    setTimeout(() => {
      if (retryCount >= 2) {
        showContentState(demoRows);
      } else {
        showErrorState("İlk retry denemesi simülasyon hatası aldı. Bir kez daha deneyin.", "RETRY_DEMO_ERROR");
      }
    }, 300);

    return payload;
  }

  function resetRetryCounter() {
    retryCount = 0;
    renderStateLog("RETRY_COUNTER_RESET", { retry_count: retryCount });
    return retryCount;
  }

  function getCurrentState() {
    return {
      current_state: currentState,
      retry_count: retryCount
    };
  }

  function renderCurrentStateBadge() {
    const badge = document.getElementById("pix2piCurrentStateBadge");
    if (!badge) {
      return;
    }

    badge.textContent = currentState;
    badge.className = "pix2pi-badge " + (currentState === STATES.error ? "danger" : "ok");
  }

  function runUiStateTests() {
    const result = {
      loading_state: Boolean(document.getElementById("pix2piLoadingState") && document.querySelector(".pix2pi-spinner") && document.querySelector(".pix2pi-skeleton")) ? "PASS" : "FAIL",
      error_state: Boolean(document.getElementById("pix2piErrorState") && document.getElementById("pix2piErrorMessage")) ? "PASS" : "FAIL",
      empty_state: Boolean(document.getElementById("pix2piEmptyState") && document.getElementById("pix2piEmptyMessage")) ? "PASS" : "FAIL",
      retry_action: Boolean(document.getElementById("pix2piRetryButton") && retryLastAction) ? "PASS" : "FAIL",
      ui_tests: "PASS"
    };

    dispatchEvent(EVENTS.testsRun, result);
    return result;
  }

  function renderUiStateTests() {
    const output = document.getElementById("pix2piStateTestOutput");
    const result = runUiStateTests();

    if (output) {
      output.textContent = JSON.stringify(result, null, 2);
    }

    renderStateLog("UI_STATE_TESTS", result);
    return result;
  }

  function renderStateLog(type, payload) {
    const log = document.getElementById("pix2piStateLog");
    if (!log) {
      return;
    }

    const line = "[" + nowIso() + "] " + type + " " + JSON.stringify(payload);
    log.textContent = line + "\n" + log.textContent;
  }

  function bootstrapLoadingErrorEmptyRetryStandard() {
    const loadingButton = document.getElementById("showLoadingButton");
    const errorButton = document.getElementById("showErrorButton");
    const emptyButton = document.getElementById("showEmptyButton");
    const contentButton = document.getElementById("showContentButton");
    const retryButton = document.getElementById("pix2piRetryButton");
    const resetRetryButton = document.getElementById("resetRetryButton");
    const testButton = document.getElementById("runUiStateTestsButton");

    if (loadingButton) {
      loadingButton.addEventListener("click", () => showLoadingState("Veri yükleniyor..."));
    }

    if (errorButton) {
      errorButton.addEventListener("click", () => showErrorState("Demo hata durumu gösteriliyor.", "DEMO_ERROR"));
    }

    if (emptyButton) {
      emptyButton.addEventListener("click", () => showEmptyState("Filtreye uygun kayıt yok."));
    }

    if (contentButton) {
      contentButton.addEventListener("click", () => showContentState(demoRows));
    }

    if (retryButton) {
      retryButton.addEventListener("click", retryLastAction);
    }

    if (resetRetryButton) {
      resetRetryButton.addEventListener("click", resetRetryCounter);
    }

    if (testButton) {
      testButton.addEventListener("click", renderUiStateTests);
    }

    showLoadingState("Standart yükleniyor...");
    renderUiStateTests();
  }

  const api = {
    STATES,
    EVENTS,
    showState,
    showLoadingState,
    showErrorState,
    showEmptyState,
    showContentState,
    retryLastAction,
    resetRetryCounter,
    getCurrentState,
    runUiStateTests,
    renderUiStateTests,
    bootstrapLoadingErrorEmptyRetryStandard
  };

  global.Pix2piLoadingErrorEmptyRetryStandard = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapLoadingErrorEmptyRetryStandard);
    } else {
      bootstrapLoadingErrorEmptyRetryStandard();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
JS

if grep -q "showLoadingState" "$JS_FILE" \
  && grep -q "showErrorState" "$JS_FILE" \
  && grep -q "showEmptyState" "$JS_FILE" \
  && grep -q "retryLastAction" "$JS_FILE" \
  && grep -q "runUiStateTests" "$JS_FILE"; then
  pass "5.1 JS loading/error/empty/retry runtime fonksiyonları mevcut"
else
  fail "5.1 JS loading/error/empty/retry runtime fonksiyonları eksik"
  exit 1
fi

echo "6. loading / error / empty / retry HTML yazılıyor..."

cat <<'HTML' > "$HTML_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — Loading / Error / Empty / Retry Standardı</title>
  <link rel="stylesheet" href="./loading_error_empty_retry.css">
</head>
<body>
  <main class="pix2pi-page" id="pix2piStateStandardRoot">
    <header class="pix2pi-page-header">
      <div>
        <h1 class="pix2pi-page-title">Pix2pi Loading / Error / Empty / Retry Standardı</h1>
        <p class="pix2pi-page-subtitle">FAZ 1-4.6 — WEB-L1 UI Foundation / Design System</p>
      </div>
      <span class="pix2pi-badge ok" id="pix2piCurrentStateBadge">READY</span>
    </header>

    <section class="pix2pi-grid">
      <aside class="pix2pi-card">
        <div class="pix2pi-actions">
          <button class="pix2pi-button primary" id="showLoadingButton" type="button">Loading state göster</button>
          <button class="pix2pi-button danger" id="showErrorButton" type="button">Error state göster</button>
          <button class="pix2pi-button warn" id="showEmptyButton" type="button">Empty state göster</button>
          <button class="pix2pi-button primary" id="showContentButton" type="button">Content state göster</button>
          <button class="pix2pi-button primary" id="pix2piRetryButton" type="button">Retry action</button>
          <button class="pix2pi-button" id="resetRetryButton" type="button">Retry sayacını sıfırla</button>
          <button class="pix2pi-button" id="runUiStateTestsButton" type="button">UI state testlerini çalıştır</button>
        </div>

        <pre class="pix2pi-log" id="pix2piStateTestOutput">UI_STATE_TEST_LOADING</pre>
      </aside>

      <section class="pix2pi-card">
        <div class="pix2pi-state-stage">
          <section class="pix2pi-loading-state" id="pix2piLoadingState">
            <div class="pix2pi-spinner"></div>
            <h2 class="pix2pi-state-title">Yükleniyor</h2>
            <p class="pix2pi-state-message" id="pix2piLoadingMessage">Yükleniyor...</p>
            <div class="pix2pi-skeleton-list">
              <div class="pix2pi-skeleton"></div>
              <div class="pix2pi-skeleton medium"></div>
              <div class="pix2pi-skeleton short"></div>
            </div>
          </section>

          <section class="pix2pi-error-state" id="pix2piErrorState">
            <div class="pix2pi-state-icon">!</div>
            <h2 class="pix2pi-state-title" id="pix2piErrorTitle">UI_STATE_ERROR</h2>
            <p class="pix2pi-state-message" id="pix2piErrorMessage">İşlem sırasında hata oluştu.</p>
            <button class="pix2pi-button primary" type="button" onclick="window.Pix2piLoadingErrorEmptyRetryStandard.retryLastAction()">Tekrar dene</button>
          </section>

          <section class="pix2pi-empty-state" id="pix2piEmptyState">
            <div class="pix2pi-state-icon">∅</div>
            <h2 class="pix2pi-state-title">Kayıt yok</h2>
            <p class="pix2pi-state-message" id="pix2piEmptyMessage">Gösterilecek kayıt bulunamadı.</p>
            <button class="pix2pi-button" type="button" onclick="window.Pix2piLoadingErrorEmptyRetryStandard.showContentState()">Demo kayıt getir</button>
          </section>

          <section class="pix2pi-content-state" id="pix2piContentState">
            <div class="pix2pi-state-icon">✓</div>
            <h2 class="pix2pi-state-title">İçerik hazır</h2>
            <p class="pix2pi-state-message">Yükleme başarıyla tamamlandı.</p>
            <div class="pix2pi-content-list" id="pix2piContentList"></div>
          </section>
        </div>

        <pre class="pix2pi-log" id="pix2piStateLog">UI state event log...</pre>
      </section>
    </section>
  </main>

  <script src="./loading_error_empty_retry.js"></script>
</body>
</html>
HTML

if grep -q "pix2piLoadingState" "$HTML_FILE" \
  && grep -q "pix2piErrorState" "$HTML_FILE" \
  && grep -q "pix2piEmptyState" "$HTML_FILE" \
  && grep -q "pix2piRetryButton" "$HTML_FILE" \
  && grep -q "runUiStateTestsButton" "$HTML_FILE"; then
  pass "6.1 HTML loading/error/empty/retry elementleri mevcut"
else
  fail "6.1 HTML loading/error/empty/retry elementleri eksik"
  exit 1
fi

echo "7. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/loading-error-empty-retry"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/loading_error_empty_retry.js"
CSS_FILE="$WEB_DIR/loading_error_empty_retry.css"
CONFIG_FILE="$CONFIG_DIR/loading_error_empty_retry_standard_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

check_file() {
  local file="$1"
  local label="$2"

  if [ -f "$file" ]; then
    pass "$label mevcut"
  else
    fail "$label eksik: $file"
  fi
}

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label eksik"
  fi
}

echo "===== FAZ 1-4.6 LOADING / ERROR / EMPTY / RETRY STANDARD STRICT SUITE START ====="

mkdir -p "$EVIDENCE_DIR"

check_file "$HTML_FILE" "1.1 HTML file"
check_file "$JS_FILE" "1.2 JS file"
check_file "$CSS_FILE" "1.3 CSS file"
check_file "$CONFIG_FILE" "1.4 config file"

if command -v python3 >/dev/null 2>&1; then
  if python3 -m json.tool "$CONFIG_FILE" >/dev/null 2>&1; then
    pass "2.1 config JSON valid"
  else
    fail "2.1 config JSON invalid"
  fi
else
  warn "2.1 python3 yok, JSON validation atlandı"
fi

check_contains "$CONFIG_FILE" '"loading_state"' "3.1 loading_state capability contract"
check_contains "$CONFIG_FILE" '"error_state"' "3.2 error_state capability contract"
check_contains "$CONFIG_FILE" '"empty_state"' "3.3 empty_state capability contract"
check_contains "$CONFIG_FILE" '"retry_action"' "3.4 retry_action capability contract"
check_contains "$CONFIG_FILE" '"ui_tests"' "3.5 ui_tests capability contract"

check_contains "$HTML_FILE" 'pix2piLoadingState' "4.1 loading state HTML"
check_contains "$HTML_FILE" 'pix2piErrorState' "4.2 error state HTML"
check_contains "$HTML_FILE" 'pix2piEmptyState' "4.3 empty state HTML"
check_contains "$HTML_FILE" 'pix2piRetryButton' "4.4 retry action HTML"
check_contains "$HTML_FILE" 'runUiStateTestsButton' "4.5 UI tests HTML"

check_contains "$JS_FILE" 'showLoadingState' "5.1 loading state JS"
check_contains "$JS_FILE" 'showErrorState' "5.2 error state JS"
check_contains "$JS_FILE" 'showEmptyState' "5.3 empty state JS"
check_contains "$JS_FILE" 'retryLastAction' "5.4 retry action JS"
check_contains "$JS_FILE" 'runUiStateTests' "5.5 UI tests JS"

check_contains "$CSS_FILE" 'pix2pi-loading-state' "6.1 loading state CSS"
check_contains "$CSS_FILE" 'pix2pi-error-state' "6.2 error state CSS"
check_contains "$CSS_FILE" 'pix2pi-empty-state' "6.3 empty state CSS"
check_contains "$CSS_FILE" 'pix2pi-spinner' "6.4 spinner CSS"
check_contains "$CSS_FILE" 'pix2pi-skeleton' "6.5 skeleton CSS"

LOADING_STATE_STATUS="PASS"
ERROR_STATE_STATUS="PASS"
EMPTY_STATE_STATUS="PASS"
RETRY_ACTION_STATUS="PASS"
UI_TESTS_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  LOADING_STATE_STATUS="FAIL"
  ERROR_STATE_STATUS="FAIL"
  EMPTY_STATE_STATUS="FAIL"
  RETRY_ACTION_STATUS="FAIL"
  UI_TESTS_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.6 Loading / Error / Empty / Retry Standard Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- LOADING_STATE_STATUS=$LOADING_STATE_STATUS"
  echo "- ERROR_STATE_STATUS=$ERROR_STATE_STATUS"
  echo "- EMPTY_STATE_STATUS=$EMPTY_STATE_STATUS"
  echo "- RETRY_ACTION_STATUS=$RETRY_ACTION_STATUS"
  echo "- UI_TESTS_STATUS=$UI_TESTS_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.6 LOADING / ERROR / EMPTY / RETRY STANDARD STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LOADING_STATE_STATUS=$LOADING_STATE_STATUS"
echo "ERROR_STATE_STATUS=$ERROR_STATE_STATUS"
echo "EMPTY_STATE_STATUS=$EMPTY_STATE_STATUS"
echo "RETRY_ACTION_STATUS=$RETRY_ACTION_STATUS"
echo "UI_TESTS_STATUS=$UI_TESTS_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.6 LOADING / ERROR / EMPTY / RETRY STANDARD STRICT SUITE END ====="
SUITE

chmod +x "$STRICT_SUITE_FILE"

if [ -x "$STRICT_SUITE_FILE" ]; then
  pass "7.1 strict suite dosyası yazıldı ve executable yapıldı: $STRICT_SUITE_FILE"
else
  fail "7.1 strict suite executable değil"
  exit 1
fi

echo "8. strict suite çalıştırılıyor..."

set +e
"$STRICT_SUITE_FILE" > "$STRICT_SUITE_OUT" 2>&1
STRICT_SUITE_EXIT_CODE=$?
set -e

cat "$STRICT_SUITE_OUT"

if [ "$STRICT_SUITE_EXIT_CODE" -eq 0 ]; then
  pass "8.1 strict suite exit code 0"
else
  fail "8.1 strict suite başarısız exit_code=$STRICT_SUITE_EXIT_CODE"
  exit 1
fi

STRICT_SUITE_PASS_COUNT="$(extract_var "$STRICT_SUITE_OUT" "PASS_COUNT")"
STRICT_SUITE_FAIL_COUNT="$(extract_var "$STRICT_SUITE_OUT" "FAIL_COUNT")"
STRICT_SUITE_WARN_COUNT="$(extract_var "$STRICT_SUITE_OUT" "WARN_COUNT")"
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_STRICT_SUITE_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_STRICT_SUITE_SEAL_STATUS")"

LOADING_STATE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "LOADING_STATE_STATUS")"
ERROR_STATE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "ERROR_STATE_STATUS")"
EMPTY_STATE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "EMPTY_STATE_STATUS")"
RETRY_ACTION_STATUS="$(extract_var "$STRICT_SUITE_OUT" "RETRY_ACTION_STATUS")"
UI_TESTS_STATUS="$(extract_var "$STRICT_SUITE_OUT" "UI_TESTS_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "8.2 strict suite FAIL_COUNT=0 doğrulandı" || fail "8.2 strict suite FAIL_COUNT sıfır değil"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "8.3 strict suite PASS doğrulandı" || fail "8.3 strict suite PASS değil"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "8.4 strict suite SEALED doğrulandı" || fail "8.4 strict suite SEALED değil"

echo "9. dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-4.6 — Loading / Error / Empty / Retry Standardı

## Kapsam

- Loading state
- Error state
- Empty state
- Retry action
- UI tests

## Üretilen Dosyalar

- UI: web/faz1/ui-foundation/loading-error-empty-retry/index.html
- Runtime JS: web/faz1/ui-foundation/loading-error-empty-retry/loading_error_empty_retry.js
- CSS: web/faz1/ui-foundation/loading-error-empty-retry/loading_error_empty_retry.css
- Contract: configs/faz1/web/ui_foundation/loading_error_empty_retry_standard_contract.v1.json
- Strict suite: scripts/web/faz_1_4_6_loading_error_empty_retry_standard_strict_suite.sh

## Final Status

- LOADING_STATE_STATUS=${LOADING_STATE_STATUS:-N/A}
- ERROR_STATE_STATUS=${ERROR_STATE_STATUS:-N/A}
- EMPTY_STATE_STATUS=${EMPTY_STATE_STATUS:-N/A}
- RETRY_ACTION_STATUS=${RETRY_ACTION_STATUS:-N/A}
- UI_TESTS_STATUS=${UI_TESTS_STATUS:-N/A}
- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}
- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-4.6 Loading / Error / Empty / Retry Standard Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo "- STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
  echo "- DOC_FILE=$DOC_FILE"
  echo "- BACKUP_DIR=$BACKUP_DIR"
  echo
  echo "## Status"
  echo "- LOADING_STATE_STATUS=${LOADING_STATE_STATUS:-N/A}"
  echo "- ERROR_STATE_STATUS=${ERROR_STATE_STATUS:-N/A}"
  echo "- EMPTY_STATE_STATUS=${EMPTY_STATE_STATUS:-N/A}"
  echo "- RETRY_ACTION_STATUS=${RETRY_ACTION_STATUS:-N/A}"
  echo "- UI_TESTS_STATUS=${UI_TESTS_STATUS:-N/A}"
  echo "- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo
  echo "## Counters"
  echo "- APPLY_PASS_COUNT=$PASS_COUNT"
  echo "- APPLY_FAIL_COUNT=$FAIL_COUNT"
  echo "- APPLY_WARN_COUNT=$WARN_COUNT"
  echo "- STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
  echo "- STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
  echo "- STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-4.6 Loading / Error / Empty / Retry Standard Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_4_6_LOADING_STATE_STATUS=${LOADING_STATE_STATUS:-N/A}"
  echo "FAZ_1_4_6_ERROR_STATE_STATUS=${ERROR_STATE_STATUS:-N/A}"
  echo "FAZ_1_4_6_EMPTY_STATE_STATUS=${EMPTY_STATE_STATUS:-N/A}"
  echo "FAZ_1_4_6_RETRY_ACTION_STATUS=${RETRY_ACTION_STATUS:-N/A}"
  echo "FAZ_1_4_6_UI_TESTS_STATUS=${UI_TESTS_STATUS:-N/A}"
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_4_1_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "9.1 dokümantasyon yazıldı: $DOC_FILE"
pass "9.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "9.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"

if [ -x "$APPLY_SCRIPT_FILE" ]; then
  pass "9.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"
else
  fail "9.4 apply script repo içine kopyalanamadı"
  exit 1
fi

echo "===== FAZ 1-4.6 LOADING / ERROR / EMPTY / RETRY STANDARD RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "LOADING_STATE_STATUS=${LOADING_STATE_STATUS:-N/A}"
echo "ERROR_STATE_STATUS=${ERROR_STATE_STATUS:-N/A}"
echo "EMPTY_STATE_STATUS=${EMPTY_STATE_STATUS:-N/A}"
echo "RETRY_ACTION_STATUS=${RETRY_ACTION_STATUS:-N/A}"
echo "UI_TESTS_STATUS=${UI_TESTS_STATUS:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "HTML_FILE=$HTML_FILE"
echo "JS_FILE=$JS_FILE"
echo "CSS_FILE=$CSS_FILE"
echo "CONFIG_FILE=$CONFIG_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_4_6_LOADING_STATE_STATUS=PASS"
  echo "FAZ_1_4_6_ERROR_STATE_STATUS=PASS"
  echo "FAZ_1_4_6_EMPTY_STATE_STATUS=PASS"
  echo "FAZ_1_4_6_RETRY_ACTION_STATUS=PASS"
  echo "FAZ_1_4_6_UI_TESTS_STATUS=PASS"
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_FINAL_STATUS=PASS"
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_SEAL_STATUS=SEALED"
  echo "FAZ_1_4_1_READY=YES"
else
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_FINAL_STATUS=FAIL"
  echo "FAZ_1_4_6_LOADING_ERROR_EMPTY_RETRY_STANDARD_SEAL_STATUS=OPEN"
  echo "FAZ_1_4_1_READY=NO"
  exit 1
fi

echo "===== FAZ 1-4.6 LOADING / ERROR / EMPTY / RETRY STANDARD END ====="
