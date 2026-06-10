(function runtimeConfigEnvironmentRuntime(global) {
  "use strict";

  const ENVIRONMENTS = ["LOCAL", "DEV", "STAGING", "PRODUCTION"];

  const CONFIG_ROWS = [
    { key: "APP_ENV", value: "STAGING", scope: "public", readonly: true },
    { key: "API_BASE_URL", value: "https://api.pix2pi.com.tr", scope: "public", readonly: true },
    { key: "AUTH_BASE_URL", value: "https://auth.pix2pi.com.tr", scope: "public", readonly: true },
    { key: "PUBLIC_APP_URL", value: "https://pix2pi.com.tr", scope: "public", readonly: true },
    { key: "FEATURE_RUNTIME_CONFIG_VIEW", value: "enabled", scope: "feature", readonly: true },
    { key: "SECRET_PAYMENT_PROVIDER_KEY", value: "NEVER_RENDER", scope: "secret", readonly: true }
  ];

  const MASKED_KEYS = ["API_BASE_URL", "AUTH_BASE_URL", "PUBLIC_APP_URL"];
  const SECRET_KEY_PATTERN = /SECRET|PASSWORD|TOKEN|PRIVATE|KEY/i;

  const state = {
    environment: "STAGING",
    currentUser: {
      roles: ["TENANT_ADMIN"],
      permissions: ["config:read"]
    }
  };

  function hasPermission(permission) {
    return state.currentUser.permissions.includes(permission);
  }

  function hasConfigReadPermission() {
    return hasPermission("config:read") || state.currentUser.roles.includes("OPS_ADMIN");
  }

  function isSecretKey(key) {
    return SECRET_KEY_PATTERN.test(String(key || ""));
  }

  function.currentUser.roles.includes("OPS_ADMIN");
  }

  function isSecretKey(key) {
    return SECRET_KEY_PATTERN maskConfigValue(row) {
    if (isSecretKey(row.key)) {
      return "********";
    }

    if (MASKED_KEYS.includes(row.key)) {
      return String(row.value).replace(/^https?:\/\//, "").replace(/./g, "•").slice(0, 16) + "...";
    }

    return row.value;
  }

  function getEnvironmentBadgeClass(environment) {
    const env = String(environment || "STAGING").toLowerCase();
    if (env === "production") return "production";
    if (env === "staging") return "staging";
    if (env === "dev") return "dev";
    return "local";
  }

  function setEnvironment(environment) {
    state.environment = ENVIRONMENTS.includes(environment) ? environment : "STAGING";
    renderEnvironmentIndicator();
    renderRuntimeConfigSurface();
    return state.environment;
  }

  function setRoleMode(mode) {
    if (mode === "denied") {
      state.currentUser = {
        roles: ["VIEWER"],
        permissions: []
      };
    } else if (mode === "ops") {
      state.currentUser = {
        roles: ["OPS_ADMIN"],
        permissions: ["config:read", "ops:read"]
      };
    } else {
      state.currentUser = {
        roles: ["TENANT_ADMIN"],
        permissions: ["config:read"]
      };
    }

    renderConfigPermissionGuard();
    renderRuntimeConfigSurface();
    return state.currentUser;
  }

  function renderEnvironmentIndicator() {
    const indicator = document.getElementById("pix2piEnvironmentIndicator");
    if (!indicator) {
      return null;
    }

    const className = getEnvironmentBadgeClass(state.environment);
    indicator.className = "pix2pi-badge " + className;
    indicator.textContent = "ENV: " + state.environment;
    return state.environment;
  }

  function renderConfigPermissionGuard() {
    const guard = document.getElementById("pix2piConfigPermissionGuard");
    if (!guard) {
      return null;
    }

    const allowed = hasConfigReadPermission();
    guard.className = "pix2pi-config-guard " + (allowed ? "allowed" : "denied");
    guard.textContent = allowed
      ? "Config permission guard: ALLOWED / read-only görünüm açık"
      : "Config permission guard: DENIED / config görünümü kapalı";

    return allowed;
  }

  function getSafeConfigRows() {
    if (!hasConfigReadPermission()) {
      return [];
    }

    return CONFIG_ROWS
      .filter((row) => row.scope !== "secret")
      .map((row) => ({
        key: row.key,
        value: maskConfigValue(row),
        scope: row.scope,
        readonly: true,
        masked: MASKED_KEYS.includes(row.key)
      }));
  }

  function renderRuntimeConfigSurface() {
    renderEnvironmentIndicator();
    renderConfigPermissionGuard();

    const tbody = document.getElementById("pix2piRuntimeConfigTableBody");
    const output = document.getElementById("pix2piRuntimeConfigOutput");
    const rows = getSafeConfigRows();

    if (tbody) {
      tbody.innerHTML = "";

      rows.forEach((row) => {
        const tr = document.createElement("tr");
        tr.innerHTML = "<td></td><td></td><td></td><td></td>";
        tr.children[0].textContent = row.key;
        tr.children[1].textContent = row.scope;
        tr.children[2].textContent = row.readonly ? "READ_ONLY" : "WRITE";
        tr.children[3].textContent = row.value;
        tr.children[3].className = "pix2pi-config-value" + (row.masked ? " masked" : "");
        tbody.appendChild(tr);
      });
    }

    if (output) {
      output.textContent = JSON.stringify({
        environment: state.environment,
        permission_allowed: hasConfigReadPermission(),
        user: state.currentUser,
        safe_config_count: rows.length,
        secrets_rendered: rows.some((row) => isSecretKey(row.key))
      }, null, 2);
    }

    return rows;
  }

  function validateEnvironmentIndicator() {
    return Boolean(document.getElementById("pix2piEnvironmentIndicator") && ENVIRONMENTS.includes(state.environment));
  }

  function validateRuntimeConfigSurface() {
    return Boolean(document.getElementById("pix2piRuntimeConfigSurface") && document.getElementById("pix2piRuntimeConfigTable"));
  }

  function validateConfigPermissionGuard() {
    setRoleMode("denied");
    const deniedRows = getSafeConfigRows();
    setRoleMode("admin");
    const allowedRows = getSafeConfigRows();
    return deniedRows.length === 0 && allowedRows.length > 0;
  }

  function validateReadOnlyConfigView() {
    return getSafeConfigRows().every((row) => row.readonly === true);
  }

  function runRuntimeConfigTests() {
    const result = {
      environment_indicator: validateEnvironmentIndicator() ? "PASS" : "FAIL",
      runtime_config_surface: validateRuntimeConfigSurface() ? "PASS" : "FAIL",
      config_permission_guard: validateConfigPermissionGuard() ? "PASS" : "FAIL",
      read_only_config_view: validateReadOnlyConfigView() ? "PASS" : "FAIL",
      tests: getSafeConfigRows().some((row) => isSecretKey(row.key)) ? "FAIL" : "PASS"
    };

    renderRuntimeConfigSurface();
    return result;
  }

  function renderRuntimeConfigTests() {
    const output = document.getElementById("pix2piRuntimeConfigTestOutput");
    const result = runRuntimeConfigTests();

    if (output) {
      output.textContent = JSON.stringify(result, null, 2);
    }

    return result;
  }

  function bootstrapRuntimeConfigEnvironment() {
    const environmentSelect = document.getElementById("pix2piEnvironmentSelect");
    const roleSelect = document.getElementById("pix2piRoleModeSelect");
    const testButton = document.getElementById("runRuntimeConfigTestsButton");

    if (environmentSelect) {
      environmentSelect.addEventListener("change", () => setEnvironment(environmentSelect.value));
    }

    if (roleSelect) {
      roleSelect.addEventListener("change", () => setRoleMode(roleSelect.value));
    }

    if (testButton) {
      testButton.addEventListener("click", renderRuntimeConfigTests);
    }

    renderRuntimeConfigSurface();
    renderRuntimeConfigTests();
  }

  const api = {
    ENVIRONMENTS,
    CONFIG_ROWS,
    MASKED_KEYS,
    state,
    hasPermission,
    hasConfigReadPermission,
    isSecretKey,
    maskConfigValue,
    getEnvironmentBadgeClass,
    setEnvironment,
    setRoleMode,
    renderEnvironmentIndicator,
    renderConfigPermissionGuard,
    getSafeConfigRows,
    renderRuntimeConfigSurface,
    validateEnvironmentIndicator,
    validateRuntimeConfigSurface,
    validateConfigPermissionGuard,
    validateReadOnlyConfigView,
    runRuntimeConfigTests,
    renderRuntimeConfigTests,
    bootstrapRuntimeConfigEnvironment
  };

  global.Pix2piRuntimeConfigEnvironment = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapRuntimeConfigEnvironment);
    } else {
      bootstrapRuntimeConfigEnvironment();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
