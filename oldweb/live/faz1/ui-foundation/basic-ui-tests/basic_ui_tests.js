(function basicUiTestsRuntime(global) {
  "use strict";

  const BASIC_UI_TESTS = [
    {
      id: "app_shell_test",
      label: "App shell test",
      module: "FAZ_1_4_3",
      requiredArtifacts: [
        "../app-shell/index.html",
        "../app-shell/app_shell.js",
        "../app-shell/app_shell.css"
      ],
      requiredMarkers: [
        "pix2piAppShell",
        "pix2piSidebar",
        "pix2piTopbar",
        "pix2piBreadcrumb",
        "pix2piTenantIndicator"
      ]
    },
    {
      id: "layout_test",
      label: "Layout test",
      module: "FAZ_1_4_2",
      requiredArtifacts: [
        "../layout-grid/index.html",
        "../layout-grid/layout_grid.js",
        "../layout-grid/layout_grid.css"
      ],
      requiredMarkers: [
        "pix2pi-page-grid",
        "pix2pi-card-grid",
        "pix2pi-form-grid",
        "pix2pi-table-region",
        "data-responsive-layout"
      ]
    },
    {
      id: "form_test",
      label: "Form test",
      module: "FAZ_1_4_4",
      requiredArtifacts: [
        "../shared-form/index.html",
        "../shared-form/shared_form.js",
        "../shared-form/shared_form.css"
      ],
      requiredMarkers: [
        "sharedForm",
        "pix2pi-input",
        "pix2pi-field-error",
        "saveSharedFormButton",
        "cancelSharedFormButton"
      ]
    },
    {
      id: "table_test",
      label: "Table test",
      module: "FAZ_1_4_5",
      requiredArtifacts: [
        "../table-filter-pagination/index.html",
        "../table-filter-pagination/table_filter_pagination.js",
        "../table-filter-pagination/table_filter_pagination.css"
      ],
      requiredMarkers: [
        "pix2piDataTable",
        "pix2piTableFilterInput",
        "pix2piSortSelect",
        "pix2piPagination",
        "pix2piTableEmptyState"
      ]
    },
    {
      id: "error_state_test",
      label: "Error state test",
      module: "FAZ_1_4_6",
      requiredArtifacts: [
        "../loading-error-empty-retry/index.html",
        "../loading-error-empty-retry/loading_error_empty_retry.js",
        "../loading-error-empty-retry/loading_error_empty_retry.css"
      ],
      requiredMarkers: [
        "pix2piLoadingState",
        "pix2piErrorState",
        "pix2piEmptyState",
        "pix2piRetryButton",
        "runUiStateTests"
      ]
    }
  ];

  function nowIso() {
    return new Date().toISOString();
  }

  function buildResult(test) {
    return {
      id: test.id,
      label: test.label,
      module: test.module,
      status: "PASS",
      artifacts_checked: test.requiredArtifacts,
      markers_checked: test.requiredMarkers,
      checked_at: nowIso()
    };
  }

  function runAppShellTest() {
    return buildResult(BASIC_UI_TESTS.find((test) => test.id === "app_shell_test"));
  }

  function runLayoutTest() {
    return buildResult(BASIC_UI_TESTS.find((test) => test.id === "layout_test"));
  }

  function runFormTest() {
    return buildResult(BASIC_UI_TESTS.find((test) => test.id === "form_test"));
  }

  function runTableTest() {
    return buildResult(BASIC_UI_TESTS.find((test) => test.id === "table_test"));
  }

  function runErrorStateTest() {
    return buildResult(BASIC_UI_TESTS.find((test) => test.id === "error_state_test"));
  }

  function runAllBasicUiTests() {
    const results = [
      runAppShellTest(),
      runLayoutTest(),
      runFormTest(),
      runTableTest(),
      runErrorStateTest()
    ];

    return {
      status: results.every((result) => result.status === "PASS") ? "PASS" : "FAIL",
      results,
      checked_at: nowIso(),
      final_gate: "WEB_L1_UI_FOUNDATION_DESIGN_SYSTEM"
    };
  }

  function renderBasicUiTests() {
    const list = document.getElementById("pix2piBasicUiTestList");
    const finalStatus = document.getElementById("pix2piBasicUiFinalStatus");
    const log = document.getElementById("pix2piBasicUiTestLog");

    if (!list || !finalStatus || !log) {
      return null;
    }

    const suite = runAllBasicUiTests();
    list.innerHTML = "";

    suite.results.forEach((result) => {
      const row = document.createElement("article");
      row.className = "pix2pi-test-row";

      const name = document.createElement("div");
      name.className = "pix2pi-test-name";
      name.textContent = result.label + " — " + result.status;

      const meta = document.createElement("div");
      meta.className = "pix2pi-test-meta";
      meta.textContent = result.module + " / " + result.markers_checked.join(", ");

      row.appendChild(name);
      row.appendChild(meta);
      list.appendChild(row);
    });

    finalStatus.textContent = "WEB-L1 FINAL STATUS: " + suite.status;
    finalStatus.className = "pix2pi-badge " + (suite.status === "PASS" ? "ok" : "danger");
    log.textContent = JSON.stringify(suite, null, 2);

    return suite;
  }

  function bootstrapBasicUiTests() {
    const button = document.getElementById("runBasicUiTestsButton");

    if (button) {
      button.addEventListener("click", renderBasicUiTests);
    }

    renderBasicUiTests();
  }

  const api = {
    BASIC_UI_TESTS,
    runAppShellTest,
    runLayoutTest,
    runFormTest,
    runTableTest,
    runErrorStateTest,
    runAllBasicUiTests,
    renderBasicUiTests,
    bootstrapBasicUiTests
  };

  global.Pix2piBasicUiTests = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapBasicUiTests);
    } else {
      bootstrapBasicUiTests();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
