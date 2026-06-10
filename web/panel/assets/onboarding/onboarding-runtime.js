/* PIX2PI_319_ONBOARDING_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    draftEndpoint: "/api/onboarding/business/draft",
    submitEndpoint: "/api/onboarding/business/submit",
    draftStorageKey: "pix2pi.panel.onboarding.draft",
    lastStepStorageKey: "pix2pi.panel.onboarding.last_step",
    supportedDefaultLanguages: ["tr-TR", "ota", "ar", "fa", "en"],
    requiredFields: [
      "business_name",
      "business_type",
      "tax_number",
      "tax_office",
      "city",
      "district",
      "owner_name",
      "owner_email",
      "default_language"
    ]
  };

  function readForm(form) {
    const data = {};
    new FormData(form).forEach(function (value, key) {
      data[key] = String(value || "").trim();
    });
    return data;
  }

  function validateEmail(value) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value || ""));
  }

  function validateTaxNumber(value) {
    const normalized = String(value || "").replace(/\D/g, "");
    return normalized.length === 10 || normalized.length === 11;
  }

  function validateOnboardingPayload(payload) {
    const errors = [];

    CONFIG.requiredFields.forEach(function (field) {
      if (!payload[field]) {
        errors.push({
          field,
          code: "REQUIRED",
          message: field + " zorunludur"
        });
      }
    });

    if (payload.owner_email && !validateEmail(payload.owner_email)) {
      errors.push({
        field: "owner_email",
        code: "INVALID_EMAIL",
        message: "Owner e-posta formatı hatalı"
      });
    }

    if (payload.tax_number && !validateTaxNumber(payload.tax_number)) {
      errors.push({
        field: "tax_number",
        code: "INVALID_TAX_NUMBER",
        message: "Vergi/TCKN numarası 10 veya 11 haneli olmalıdır"
      });
    }

    if (payload.default_language && CONFIG.supportedDefaultLanguages.indexOf(payload.default_language) === -1) {
      errors.push({
        field: "default_language",
        code: "UNSUPPORTED_LANGUAGE",
        message: "Desteklenmeyen varsayılan dil"
      });
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  function buildTenantBootstrapPayload(payload) {
    return {
      business: {
        name: payload.business_name,
        type: payload.business_type,
        sector: payload.sector || "retail",
        default_language: payload.default_language || "tr-TR"
      },
      tax: {
        tax_number: payload.tax_number,
        tax_office: payload.tax_office,
        legal_title: payload.legal_title || payload.business_name
      },
      address: {
        city: payload.city,
        district: payload.district,
        address_line: payload.address_line || ""
      },
      contact: {
        phone: payload.phone || "",
        email: payload.business_email || payload.owner_email
      },
      owner: {
        name: payload.owner_name,
        email: payload.owner_email,
        role: "OWNER_ADMIN"
      },
      bootstrap: {
        source: "panel_onboarding",
        phase: "FAZ_7R",
        step: "319",
        status: "DRAFT_READY_FOR_BACKEND_BINDING"
      }
    };
  }

  function saveDraft(payload) {
    const bootstrapPayload = buildTenantBootstrapPayload(payload);
    window.localStorage.setItem(CONFIG.draftStorageKey, JSON.stringify(bootstrapPayload));
    window.localStorage.setItem(CONFIG.lastStepStorageKey, "319");
    return bootstrapPayload;
  }

  function loadDraft() {
    const raw = window.localStorage.getItem(CONFIG.draftStorageKey);
    if (!raw) return null;

    try {
      return JSON.parse(raw);
    } catch (_error) {
      return null;
    }
  }

  function clearDraft() {
    window.localStorage.removeItem(CONFIG.draftStorageKey);
    window.localStorage.removeItem(CONFIG.lastStepStorageKey);
  }

  async function postJson(endpoint, payload) {
    const token = window.localStorage.getItem("pix2pi.panel.jwt") || "";

    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": token ? "Bearer " + token : "",
        "X-Pix2pi-Surface": "panel",
        "X-Pix2pi-Onboarding-Step": "319"
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      throw new Error("ONBOARDING_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function saveDraftRemote(payload) {
    const bootstrapPayload = saveDraft(payload);
    return postJson(CONFIG.draftEndpoint, bootstrapPayload);
  }

  async function submitOnboarding(payload) {
    const validation = validateOnboardingPayload(payload);
    if (!validation.valid) {
      return {
        submitted: false,
        validation
      };
    }

    const bootstrapPayload = saveDraft(payload);
    const response = await postJson(CONFIG.submitEndpoint, bootstrapPayload);

    return {
      submitted: true,
      validation,
      response
    };
  }

  function renderValidation(target, validation) {
    if (!target) return;

    if (validation.valid) {
      target.textContent = "Onboarding formu geçerli.";
      target.setAttribute("data-validation-status", "valid");
      target.hidden = false;
      return;
    }

    target.textContent = validation.errors.map(function (err) {
      return err.message;
    }).join(" / ");
    target.setAttribute("data-validation-status", "invalid");
    target.hidden = false;
  }

  window.Pix2piOnboarding = {
    CONFIG,
    readForm,
    validateEmail,
    validateTaxNumber,
    validateOnboardingPayload,
    buildTenantBootstrapPayload,
    saveDraft,
    loadDraft,
    clearDraft,
    saveDraftRemote,
    submitOnboarding,
    renderValidation
  };
})();
/* PIX2PI_319_ONBOARDING_RUNTIME_END */
