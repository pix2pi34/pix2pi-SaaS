(function authErrorPagesRuntime(global) {
  "use strict";

  const ERROR_DEFINITIONS = {
    UNAUTHORIZED: {
      status: 401,
      code: "UNAUTHORIZED",
      title: "Giriş gerekli",
      message: "Bu sayfaya erişmek için oturum açmanız gerekiyor.",
      actionLabel: "Giriş ekranına dön",
      action: "LOGIN_REQUIRED"
    },
    FORBIDDEN: {
      status: 403,
      code: "FORBIDDEN",
      title: "Yetki yok",
      message: "Bu işlem için gerekli rol veya permission sizde yok.",
      actionLabel: "Yöneticinizle görüşün",
      action: "CONTACT_ADMIN"
    },
    TENANT_MISMATCH: {
      status: 403,
      code: "TENANT_MISMATCH",
      title: "Tenant uyuşmazlığı",
      message: "İstek yapılan tenant, aktif tenant bağlamı ile eşleşmiyor. Güvenlik nedeniyle işlem durduruldu.",
      actionLabel: "Tenant seçimini kontrol et",
      action: "SWITCH_TENANT_OR_RETRY"
    },
    SESSION_EXPIRED: {
      status: 401,
      code: "SESSION_EXPIRED",
      title: "Oturum süresi doldu",
      message: "Oturum süreniz doldu. Devam etmek için tekrar giriş yapmanız gerekiyor.",
      actionLabel: "Tekrar giriş yap",
      action: "RE_LOGIN_REQUIRED"
    }
  };

  function getErrorDefinition(code) {
    return ERROR_DEFINITIONS[code] || ERROR_DEFINITIONS.UNAUTHORIZED;
  }

  function buildApiErrorResponse(code, details) {
    const definition = getErrorDefinition(code);

    return {
      ok: false,
      status: definition.status,
      error: {
        code: definition.code,
        message: definition.message,
        action: definition.action,
        details: details || null
      },
      request_id: "req_demo_auth_error",
      tenant_guard: definition.code === "TENANT_MISMATCH" ? "BLOCKED" : "N/A"
    };
  }

  function clearAuthState() {
    try {
      global.localStorage.removeItem("pix2pi.session");
      global.localStorage.removeItem("pix2pi.activeTenant");
      global.localStorage.removeItem("pix2pi.lastTenantSwitch");
    } catch (_err) {
      return false;
    }

    return true;
  }

  function resolveCodeFromPage() {
    const root = document.getElementById("authErrorRoot");
    if (root && root.dataset && root.dataset.errorCode) {
      return root.dataset.errorCode;
    }

    const path = String(global.location && global.location.pathname || "");

    if (path.includes("403")) {
      return "FORBIDDEN";
    }

    if (path.includes("tenant-mismatch")) {
      return "TENANT_MISMATCH";
    }

    if (path.includes("session-expired")) {
      return "SESSION_EXPIRED";
    }

    return "UNAUTHORIZED";
  }

  function renderAuthError(code) {
    const definition = getErrorDefinition(code);
    const root = document.getElementById("authErrorRoot");
    const title = document.getElementById("authErrorTitle");
    const message = document.getElementById("authErrorMessage");
    const action = document.getElementById("authErrorAction");
    const technicalCode = document.getElementById("authErrorTechnicalCode");
    const apiPreview = document.getElementById("authErrorApiPreview");

    if (root) {
      root.dataset.errorCode = definition.code;
      root.dataset.httpStatus = String(definition.status);
    }

    if (title) {
      title.textContent = definition.title;
    }

    if (message) {
      message.textContent = definition.message;
    }

    if (action) {
      action.textContent = definition.actionLabel;
      action.dataset.action = definition.action;

      action.onclick = function onActionClick() {
        if (definition.action === "LOGIN_REQUIRED" || definition.action === "RE_LOGIN_REQUIRED") {
          clearAuthState();
        }
      };
    }

    if (technicalCode) {
      technicalCode.textContent = definition.status + " / " + definition.code;
    }

    if (apiPreview) {
      apiPreview.textContent = JSON.stringify(buildApiErrorResponse(definition.code), null, 2);
    }

    return definition;
  }

  function simulateUnauthorized() {
    return renderAuthError("UNAUTHORIZED");
  }

  function simulateForbidden() {
    return renderAuthError("FORBIDDEN");
  }

  function simulateTenantMismatch() {
    return renderAuthError("TENANT_MISMATCH");
  }

  function simulateSessionExpired() {
    clearAuthState();
    return renderAuthError("SESSION_EXPIRED");
  }

  function bootstrapAuthErrorPage() {
    const code = resolveCodeFromPage();
    renderAuthError(code);

    const buttons = document.querySelectorAll("[data-auth-error-simulate]");
    buttons.forEach((button) => {
      button.addEventListener("click", () => {
        renderAuthError(button.dataset.authErrorSimulate);
      });
    });
  }

  const api = {
    ERROR_DEFINITIONS,
    getErrorDefinition,
    buildApiErrorResponse,
    clearAuthState,
    resolveCodeFromPage,
    renderAuthError,
    simulateUnauthorized,
    simulateForbidden,
    simulateTenantMismatch,
    simulateSessionExpired,
    bootstrapAuthErrorPage
  };

  global.Pix2piAuthErrorPages = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapAuthErrorPage);
    } else {
      bootstrapAuthErrorPage();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
