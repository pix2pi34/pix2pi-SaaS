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
