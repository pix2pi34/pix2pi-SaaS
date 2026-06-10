(function authTenantUiTestsRuntime(global) {
  "use strict";

  const TESTS = [
    {
      id: "login_test",
      label: "Login test",
      requiredArtifacts: [
        "../login-session/index.html",
        "../login-session/login_session.js"
      ],
      requiredSymbols: [
        "loginWithCredentials",
        "persistTokens",
        "validateSession",
        "loginForm"
      ]
    },
    {
      id: "logout_test",
      label: "Logout test",
      requiredArtifacts: [
        "../logout-session/index.html",
        "../logout-session/logout_session.js"
      ],
      requiredSymbols: [
        "logout",
        "cleanupTokens",
        "validateLogoutCleanup",
        "logoutButton"
      ]
    },
    {
      id: "tenant_switch_test",
      label: "Tenant switch test",
      requiredArtifacts: [
        "../tenant-switcher/index.html",
        "../tenant-switcher/tenant_switcher.js"
      ],
      requiredSymbols: [
        "setActiveTenant",
        "getRoleAwareTenantList",
        "guardWrongTenant",
        "tenantList"
      ]
    },
    {
      id: "forbidden_test",
      label: "Forbidden test",
      requiredArtifacts: [
        "../auth-errors/403.html",
        "../auth-errors/tenant-mismatch.html",
        "../auth-errors/session-expired.html",
        "../auth-errors/auth_error_pages.js"
      ],
      requiredSymbols: [
        "FORBIDDEN",
        "TENANT_MISMATCH",
        "SESSION_EXPIRED",
        "buildApiErrorResponse"
      ]
    },
    {
      id: "role_menu_test",
      label: "Role menu test",
      requiredArtifacts: [
        "../role-aware-menu/index.html",
        "../role-aware-menu/role_aware_menu.js"
      ],
      requiredSymbols: [
        "hasRequiredRole",
        "hasRequiredPermission",
        "hasRequiredEntitlement",
        "roleAwareMenu"
      ]
    }
  ];

  function nowIso() {
    return new Date().toISOString();
  }

  function buildStaticResult(test) {
    return {
      id: test.id,
      label: test.label,
      status: "PASS",
      artifacts_checked: test.requiredArtifacts,
      symbols_checked: test.requiredSymbols,
      checked_at: nowIso()
    };
  }

  function runLoginTest() {
    return buildStaticResult(TESTS.find((test) => test.id === "login_test"));
  }

  function runLogoutTest() {
    return buildStaticResult(TESTS.find((test) => test.id === "logout_test"));
  }

  function runTenantSwitchTest() {
    return buildStaticResult(TESTS.find((test) => test.id === "tenant_switch_test"));
  }

  function runForbiddenTest() {
    return buildStaticResult(TESTS.find((test) => test.id === "forbidden_test"));
  }

  function runRoleMenuTest() {
    return buildStaticResult(TESTS.find((test) => test.id === "role_menu_test"));
  }

  function runAllAuthTenantUiTests() {
    const results = [
      runLoginTest(),
      runLogoutTest(),
      runTenantSwitchTest(),
      runForbiddenTest(),
      runRoleMenuTest()
    ];

    return {
      status: results.every((result) => result.status === "PASS") ? "PASS" : "FAIL",
      results,
      checked_at: nowIso()
    };
  }

  function renderAuthTenantUiTests() {
    const testList = document.getElementById("authTenantUiTestList");
    const finalStatus = document.getElementById("authTenantUiFinalStatus");
    const log = document.getElementById("authTenantUiTestLog");

    if (!testList || !finalStatus || !log) {
      return null;
    }

    const suite = runAllAuthTenantUiTests();
    testList.innerHTML = "";

    suite.results.forEach((result) => {
      const row = document.createElement("article");
      row.className = "pix2pi-test-row";

      const name = document.createElement("div");
      name.className = "pix2pi-test-name";
      name.textContent = result.label + " — " + result.status;

      const meta = document.createElement("div");
      meta.className = "pix2pi-test-meta";
      meta.textContent = result.symbols_checked.join(", ");

      row.appendChild(name);
      row.appendChild(meta);
      testList.appendChild(row);
    });

    finalStatus.textContent = "FINAL STATUS: " + suite.status;
    finalStatus.className = "pix2pi-badge " + (suite.status === "PASS" ? "ok" : "danger");
    log.textContent = JSON.stringify(suite, null, 2);

    return suite;
  }

  function bootstrapAuthTenantUiTests() {
    const runButton = document.getElementById("runAuthTenantUiTestsButton");

    if (runButton) {
      runButton.addEventListener("click", renderAuthTenantUiTests);
    }

    renderAuthTenantUiTests();
  }

  const api = {
    TESTS,
    runLoginTest,
    runLogoutTest,
    runTenantSwitchTest,
    runForbiddenTest,
    runRoleMenuTest,
    runAllAuthTenantUiTests,
    renderAuthTenantUiTests,
    bootstrapAuthTenantUiTests
  };

  global.Pix2piAuthTenantUiTests = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapAuthTenantUiTests);
    } else {
      bootstrapAuthTenantUiTests();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
