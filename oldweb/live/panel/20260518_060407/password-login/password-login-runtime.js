/* PIX2PI_349_PASSWORD_LOGIN_RUNTIME_V2_START */
(function () {
  const state = {
    tenantId: "pilot-tenant",
    nextRoute: "https://panel.pix2pi.com.tr/tenant-select/",
    policy: {
      minLength: 10,
      upper: true,
      lower: true,
      digit: true,
      symbol: true
    }
  };

  function hasUpper(value) { return /[A-Z]/.test(value); }
  function hasLower(value) { return /[a-z]/.test(value); }
  function hasDigit(value) { return /[0-9]/.test(value); }
  function hasSymbol(value) { return /[^A-Za-z0-9]/.test(value); }

  function validatePassword(value) {
    const checks = [
      value.length >= state.policy.minLength,
      hasUpper(value),
      hasLower(value),
      hasDigit(value),
      hasSymbol(value)
    ];
    return checks.every(Boolean);
  }

  function setStatus(message, ok) {
    const el = document.querySelector("[data-auth-status]");
    if (!el) return;
    el.textContent = message;
    el.dataset.status = ok ? "ok" : "error";
  }

  window.PIX2PI_349_PASSWORD_FLOW = {
    validatePassword,
    tenantSelectionHandoff: function () {
      return state.nextRoute;
    },
    submitLoginPreview: function () {
      setStatus("Giriş doğrulandı. Tenant seçimine yönlendiriliyor.", true);
      window.location.href = state.nextRoute;
    },
    submitPasswordSetupPreview: function () {
      const p1 = document.querySelector("[data-password-new]")?.value || "";
      const p2 = document.querySelector("[data-password-confirm]")?.value || "";

      if (p1 !== p2) {
        setStatus("Şifre tekrarı eşleşmiyor.", false);
        return false;
      }
      if (!validatePassword(p1)) {
        setStatus("Şifre politika şartlarını karşılamıyor.", false);
        return false;
      }
      setStatus("Şifre politikası geçti. Giriş akışı hazır.", true);
      return true;
    }
  };

  document.addEventListener("submit", function (event) {
    const form = event.target;
    if (!form || !form.matches("[data-password-flow-form]")) return;
    event.preventDefault();

    const mode = form.getAttribute("data-mode");
    if (mode === "login") {
      window.PIX2PI_349_PASSWORD_FLOW.submitLoginPreview();
      return;
    }
    window.PIX2PI_349_PASSWORD_FLOW.submitPasswordSetupPreview();
  });
})();
/* PIX2PI_349_PASSWORD_LOGIN_RUNTIME_V2_END */
