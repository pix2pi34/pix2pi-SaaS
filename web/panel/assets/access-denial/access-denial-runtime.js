/* PIX2PI_317_8_ACCESS_DENIAL_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "access_denial",
    phase: "FAZ_7R",
    step: "317.8",
    correlationKey: "pix2pi.auth.correlation_id",
    lastDeniedRouteKey: "pix2pi.auth.last_denied_route"
  };

  function readCorrelationId() {
    return window.sessionStorage.getItem(CONFIG.correlationKey) || "access-correlation-missing";
  }

  function readDeniedRoute() {
    return window.sessionStorage.getItem(CONFIG.lastDeniedRouteKey) || "/";
  }

  function setAccessDenialScreen(screenType) {
    document.body.setAttribute("data-access-denial-screen", screenType);
    document.body.setAttribute("data-access-denial-correlation-id", readCorrelationId());

    const correlation = document.getElementById("access-denial-correlation-id");
    if (correlation) correlation.textContent = readCorrelationId();

    const route = document.getElementById("access-denial-route");
    if (route) route.textContent = readDeniedRoute();
  }

  function goToLogin() {
    window.location.href = "/login/";
  }

  function goToTenantSelection() {
    window.location.href = "/tenant-select/";
  }

  window.Pix2piAccessDenial = {
    CONFIG: CONFIG,
    readCorrelationId: readCorrelationId,
    readDeniedRoute: readDeniedRoute,
    setAccessDenialScreen: setAccessDenialScreen,
    goToLogin: goToLogin,
    goToTenantSelection: goToTenantSelection
  };
})();
/* PIX2PI_317_8_ACCESS_DENIAL_RUNTIME_END */
