/* PIX2PI_322_BUSINESS_SETTINGS_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    readEndpoint: "/api/panel/settings/business",
    saveEndpoint: "/api/panel/settings/business/save",
    draftStorageKey: "pix2pi.panel.business.settings.draft",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    jwtKey: "pix2pi.panel.jwt",
    supportedDefaultLanguages: ["tr-TR", "ota", "ar", "fa", "en"],
    fallbackSettings: {
      tenant_id: "controlled-pilot",
      business: {
        name: "Controlled Pilot İşletmesi",
        legal_title: "Controlled Pilot İşletmesi",
        business_type: "market",
        default_language: "tr-TR"
      },
      tax: {
        tax_number: "0000000000",
        tax_office: "Pilot Vergi Dairesi"
      },
      contact: {
        city: "İstanbul",
        district: "Kadıköy",
        phone: "",
        email: "owner@pix2pi.test",
        address_line: ""
      },
      branding: {
        logo_status: "PLACEHOLDER",
        color_theme: "default"
      },
      modules: {
        pos_visible: true,
        erp_visible: true,
        marketplace_visible: false
      },
      notifications: {
        email_enabled: true,
        sms_enabled: false,
        system_alerts_enabled: true
      }
    }
  };

  function getSelectedTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || "controlled-pilot";
  }

  function getJwt() {
    return window.localStorage.getItem(CONFIG.jwtKey) || "";
  }

  function tenantScopedHeaders() {
    const token = getJwt();
    return {
      "Content-Type": "application/json",
      "Authorization": token ? "Bearer " + token : "",
      "X-Tenant-ID": getSelectedTenantId(),
      "X-Pix2pi-Surface": "panel",
      "X-Pix2pi-Step": "322"
    };
  }

  function readForm(form) {
    const data = {};
    new FormData(form).forEach(function (value, key) {
      data[key] = String(value || "").trim();
    });

    data.pos_visible = form.querySelector("[name='pos_visible']").checked;
    data.erp_visible = form.querySelector("[name='erp_visible']").checked;
    data.marketplace_visible = form.querySelector("[name='marketplace_visible']").checked;
    data.email_enabled = form.querySelector("[name='email_enabled']").checked;
    data.sms_enabled = form.querySelector("[name='sms_enabled']").checked;
    data.system_alerts_enabled = form.querySelector("[name='system_alerts_enabled']").checked;

    return data;
  }

  function validateTaxNumber(value) {
    const normalized = String(value || "").replace(/\D/g, "");
    return normalized.length === 10 || normalized.length === 11;
  }

  function validateSettingsPayload(payload) {
    const errors = [];

    ["business_name", "legal_title", "tax_number", "tax_office", "city", "district", "default_language"].forEach(function (field) {
      if (!payload[field]) {
        errors.push({ field, code: "REQUIRED", message: field + " zorunludur" });
      }
    });

    if (payload.tax_number && !validateTaxNumber(payload.tax_number)) {
      errors.push({ field: "tax_number", code: "INVALID_TAX_NUMBER", message: "Vergi/TCKN numarası 10 veya 11 haneli olmalıdır" });
    }

    if (payload.default_language && CONFIG.supportedDefaultLanguages.indexOf(payload.default_language) === -1) {
      errors.push({ field: "default_language", code: "UNSUPPORTED_LANGUAGE", message: "Desteklenmeyen varsayılan dil" });
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  function buildSettingsPayload(payload) {
    return {
      tenant_id: getSelectedTenantId(),
      business: {
        name: payload.business_name,
        legal_title: payload.legal_title,
        business_type: payload.business_type || "market",
        default_language: payload.default_language || "tr-TR"
      },
      tax: {
        tax_number: payload.tax_number,
        tax_office: payload.tax_office
      },
      contact: {
        city: payload.city,
        district: payload.district,
        phone: payload.phone || "",
        email: payload.email || "",
        address_line: payload.address_line || ""
      },
      branding: {
        logo_status: "PLACEHOLDER",
        color_theme: payload.color_theme || "default"
      },
      modules: {
        pos_visible: Boolean(payload.pos_visible),
        erp_visible: Boolean(payload.erp_visible),
        marketplace_visible: Boolean(payload.marketplace_visible)
      },
      notifications: {
        email_enabled: Boolean(payload.email_enabled),
        sms_enabled: Boolean(payload.sms_enabled),
        system_alerts_enabled: Boolean(payload.system_alerts_enabled)
      },
      source: {
        surface: "panel_business_settings",
        phase: "FAZ_7R",
        step: "322"
      }
    };
  }

  function saveDraft(payload) {
    const settingsPayload = buildSettingsPayload(payload);
    window.localStorage.setItem(CONFIG.draftStorageKey, JSON.stringify(settingsPayload));
    return settingsPayload;
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

  async function apiJson(endpoint, options) {
    const response = await fetch(endpoint, Object.assign({
      headers: tenantScopedHeaders()
    }, options || {}));

    if (!response.ok) {
      throw new Error("BUSINESS_SETTINGS_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchSettings() {
    try {
      return await apiJson(CONFIG.readEndpoint, { method: "GET" });
    } catch (_error) {
      return CONFIG.fallbackSettings;
    }
  }

  async function saveSettings(payload) {
    const validation = validateSettingsPayload(payload);
    if (!validation.valid) {
      return { saved: false, validation };
    }

    const settingsPayload = saveDraft(payload);

    try {
      const response = await apiJson(CONFIG.saveEndpoint, {
        method: "POST",
        body: JSON.stringify(settingsPayload)
      });

      return { saved: true, validation, response };
    } catch (_error) {
      return { saved: false, validation, fallback_payload: settingsPayload };
    }
  }

  function renderValidation(target, validation) {
    if (!target) return;

    if (validation.valid) {
      target.textContent = "İşletme ayarları geçerli.";
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

  function fillForm(form, settings) {
    if (!form || !settings) return;

    form.business_name.value = settings.business.name || "";
    form.legal_title.value = settings.business.legal_title || "";
    form.business_type.value = settings.business.business_type || "market";
    form.default_language.value = settings.business.default_language || "tr-TR";

    form.tax_number.value = settings.tax.tax_number || "";
    form.tax_office.value = settings.tax.tax_office || "";

    form.city.value = settings.contact.city || "";
    form.district.value = settings.contact.district || "";
    form.phone.value = settings.contact.phone || "";
    form.email.value = settings.contact.email || "";
    form.address_line.value = settings.contact.address_line || "";

    form.color_theme.value = settings.branding.color_theme || "default";
    form.pos_visible.checked = Boolean(settings.modules.pos_visible);
    form.erp_visible.checked = Boolean(settings.modules.erp_visible);
    form.marketplace_visible.checked = Boolean(settings.modules.marketplace_visible);

    form.email_enabled.checked = Boolean(settings.notifications.email_enabled);
    form.sms_enabled.checked = Boolean(settings.notifications.sms_enabled);
    form.system_alerts_enabled.checked = Boolean(settings.notifications.system_alerts_enabled);
  }

  async function bootSettingsScreen() {
    const settings = loadDraft() || await fetchSettings();
    const form = document.getElementById("business-settings-form");

    if (settings && form) {
      fillForm(form, settings);
    }

    document.body.setAttribute("data-settings-rendered", "true");
    return settings;
  }

  window.Pix2piBusinessSettings = {
    CONFIG,
    getSelectedTenantId,
    getJwt,
    tenantScopedHeaders,
    readForm,
    validateTaxNumber,
    validateSettingsPayload,
    buildSettingsPayload,
    saveDraft,
    loadDraft,
    fetchSettings,
    saveSettings,
    renderValidation,
    fillForm,
    bootSettingsScreen
  };
})();
/* PIX2PI_322_BUSINESS_SETTINGS_RUNTIME_END */
