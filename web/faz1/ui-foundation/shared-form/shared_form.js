(function sharedFormStandardRuntime(global) {
  "use strict";

  const EVENTS = {
    save: "pix2pi:form-save",
    cancel: "pix2pi:form-cancel",
    validation: "pix2pi:form-validation"
  };

  const VALIDATION_CODES = {
    required: "FIELD_REQUIRED",
    email: "INVALID_EMAIL",
    minLength: "MIN_LENGTH_NOT_MET",
    tenantCode: "INVALID_TENANT_CODE",
    taxNumber: "INVALID_TAX_NUMBER"
  };

  let dirtyState = false;

  function dispatchEvent(name, detail) {
    if (typeof global.CustomEvent === "function" && typeof global.dispatchEvent === "function") {
      global.dispatchEvent(new CustomEvent(name, { detail }));
    }
  }

  function getField(id) {
    return document.getElementById(id);
  }

  function getFieldValue(id) {
    const field = getField(id);
    return field ? String(field.value || "").trim() : "";
  }

  function setDirtyState(next) {
    dirtyState = Boolean(next);
    renderDirtyState();
    return dirtyState;
  }

  function isDirty() {
    return dirtyState;
  }

  function validateRequired(value) {
    return String(value || "").trim().length > 0;
  }

  function validateEmail(value) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value || "").trim());
  }

  function validateMinLength(value, minLength) {
    return String(value || "").trim().length >= Number(minLength || 0);
  }

  function validateTenantCode(value) {
    return /^[a-zA-Z0-9_-]{3,64}$/.test(String(value || "").trim());
  }

  function validateTaxNumber(value) {
    const normalized = String(value || "").trim();
    return normalized === "" || /^[0-9]{10,11}$/.test(normalized);
  }

  function renderFieldError(fieldId, message) {
    const field = getField(fieldId);
    const error = document.querySelector('[data-error-for="' + fieldId + '"]');

    if (field) {
      field.classList.add("invalid");
      field.setAttribute("aria-invalid", "true");
    }

    if (error) {
      error.textContent = message;
      error.classList.add("visible");
    }
  }

  function clearFieldError(fieldId) {
    const field = getField(fieldId);
    const error = document.querySelector('[data-error-for="' + fieldId + '"]');

    if (field) {
      field.classList.remove("invalid");
      field.setAttribute("aria-invalid", "false");
    }

    if (error) {
      error.textContent = "";
      error.classList.remove("visible");
    }
  }

  function clearAllErrors() {
    ["legalName", "email", "tenantCode", "taxNumber", "description"].forEach(clearFieldError);

    const formError = document.getElementById("sharedFormError");
    const formSuccess = document.getElementById("sharedFormSuccess");

    if (formError) {
      formError.textContent = "";
      formError.classList.remove("visible");
    }

    if (formSuccess) {
      formSuccess.textContent = "";
      formSuccess.classList.remove("visible");
    }
  }

  function getSharedFormPayload() {
    return {
      legal_name: getFieldValue("legalName"),
      email: getFieldValue("email"),
      tenant_code: getFieldValue("tenantCode"),
      tax_number: getFieldValue("taxNumber"),
      business_type: getFieldValue("businessType"),
      description: getFieldValue("description")
    };
  }

  function validateSharedForm(payload) {
    const data = payload || getSharedFormPayload();
    const errors = [];

    if (!validateRequired(data.legal_name)) {
      errors.push({ field: "legalName", code: VALIDATION_CODES.required, message: "Firma adı zorunludur." });
    }

    if (!validateRequired(data.email)) {
      errors.push({ field: "email", code: VALIDATION_CODES.required, message: "E-posta zorunludur." });
    } else if (!validateEmail(data.email)) {
      errors.push({ field: "email", code: VALIDATION_CODES.email, message: "Geçerli bir e-posta girin." });
    }

    if (!validateRequired(data.tenant_code)) {
      errors.push({ field: "tenantCode", code: VALIDATION_CODES.required, message: "Tenant kodu zorunludur." });
    } else if (!validateTenantCode(data.tenant_code)) {
      errors.push({ field: "tenantCode", code: VALIDATION_CODES.tenantCode, message: "Tenant kodu 3-64 karakter, harf/rakam/_/- olmalıdır." });
    }

    if (!validateTaxNumber(data.tax_number)) {
      errors.push({ field: "taxNumber", code: VALIDATION_CODES.taxNumber, message: "Vergi no 10 veya 11 haneli olmalıdır." });
    }

    if (data.description && !validateMinLength(data.description, 3)) {
      errors.push({ field: "description", code: VALIDATION_CODES.minLength, message: "Açıklama en az 3 karakter olmalıdır." });
    }

    return {
      ok: errors.length === 0,
      errors,
      payload: data
    };
  }

  function renderValidationResult(result) {
    clearAllErrors();

    result.errors.forEach((error) => {
      renderFieldError(error.field, error.message);
    });

    const formError = document.getElementById("sharedFormError");
    const formSuccess = document.getElementById("sharedFormSuccess");

    if (!result.ok && formError) {
      formError.textContent = "Form doğrulaması başarısız: " + result.errors.map((error) => error.code).join(", ");
      formError.classList.add("visible");
    }

    if (result.ok && formSuccess) {
      formSuccess.textContent = "Form doğrulaması başarılı. Kayıt simülasyonu hazır.";
      formSuccess.classList.add("visible");
    }

    dispatchEvent(EVENTS.validation, result);
    logFormEvent("FORM_VALIDATION", result);

    return result;
  }

  function handleSave(event) {
    if (event && event.preventDefault) {
      event.preventDefault();
    }

    const result = renderValidationResult(validateSharedForm());

    if (!result.ok) {
      return result;
    }

    setDirtyState(false);

    const savePayload = {
      saved_at: new Date().toISOString(),
      payload: result.payload
    };

    dispatchEvent(EVENTS.save, savePayload);
    logFormEvent("FORM_SAVE", savePayload);

    return result;
  }

  function handleCancel(event) {
    if (event && event.preventDefault) {
      event.preventDefault();
    }

    const payload = {
      canceled_at: new Date().toISOString(),
      was_dirty: isDirty(),
      policy: isDirty() ? "WARN_ON_CANCEL_WHEN_DIRTY" : "SAFE_CANCEL"
    };

    setDirtyState(false);
    clearAllErrors();

    dispatchEvent(EVENTS.cancel, payload);
    logFormEvent("FORM_CANCEL", payload);

    return payload;
  }

  function resetDemoForm() {
    const values = {
      legalName: "Pix2pi Pilot İşletme",
      email: "pilot@pix2pi.local",
      tenantCode: "tenant_7",
      taxNumber: "1234567890",
      businessType: "retail",
      description: "Shared form standardı demo kaydı"
    };

    Object.keys(values).forEach((id) => {
      const field = getField(id);
      if (field) {
        field.value = values[id];
      }
    });

    setDirtyState(false);
    clearAllErrors();
    logFormEvent("FORM_RESET_DEMO", values);
  }

  function renderDirtyState() {
    const dirtyEl = document.getElementById("sharedFormDirtyState");
    if (dirtyEl) {
      dirtyEl.textContent = isDirty() ? "DIRTY" : "CLEAN";
      dirtyEl.className = "pix2pi-badge " + (isDirty() ? "warn" : "ok");
    }
  }

  function runSharedFormTests() {
    const validPayload = {
      legal_name: "Pix2pi Test",
      email: "test@pix2pi.local",
      tenant_code: "tenant_7",
      tax_number: "1234567890",
      business_type: "retail",
      description: "valid"
    };

    const invalidPayload = {
      legal_name: "",
      email: "bad-email",
      tenant_code: "x",
      tax_number: "abc",
      business_type: "retail",
      description: "no"
    };

    const validResult = validateSharedForm(validPayload);
    const invalidResult = validateSharedForm(invalidPayload);

    return {
      input_standard: Boolean(document.querySelector(".pix2pi-input") && document.querySelector(".pix2pi-select") && document.querySelector(".pix2pi-textarea")) ? "PASS" : "FAIL",
      validation_standard: validResult.ok && !invalidResult.ok ? "PASS" : "FAIL",
      error_display: Boolean(document.querySelector(".pix2pi-field-error") && document.querySelector(".pix2pi-form-error")) ? "PASS" : "FAIL",
      save_cancel_pattern: Boolean(document.getElementById("saveSharedFormButton") && document.getElementById("cancelSharedFormButton")) ? "PASS" : "FAIL",
      form_tests: invalidResult.errors.length >= 3 ? "PASS" : "FAIL"
    };
  }

  function renderSharedFormTests() {
    const output = document.getElementById("sharedFormTestOutput");
    const result = runSharedFormTests();

    if (output) {
      output.textContent = JSON.stringify(result, null, 2);
    }

    logFormEvent("FORM_TESTS", result);
    return result;
  }

  function logFormEvent(type, payload) {
    const log = document.getElementById("sharedFormLog");
    if (!log) {
      return;
    }

    const line = "[" + new Date().toISOString() + "] " + type + " " + JSON.stringify(payload);
    log.textContent = line + "\n" + log.textContent;
  }

  function bootstrapSharedFormStandard() {
    const form = document.getElementById("sharedForm");
    const cancelButton = document.getElementById("cancelSharedFormButton");
    const resetButton = document.getElementById("resetSharedFormButton");
    const testButton = document.getElementById("runSharedFormTestsButton");

    if (form) {
      form.addEventListener("submit", handleSave);
      form.querySelectorAll("input, select, textarea").forEach((field) => {
        field.addEventListener("input", () => setDirtyState(true));
        field.addEventListener("change", () => setDirtyState(true));
      });
    }

    if (cancelButton) {
      cancelButton.addEventListener("click", handleCancel);
    }

    if (resetButton) {
      resetButton.addEventListener("click", resetDemoForm);
    }

    if (testButton) {
      testButton.addEventListener("click", renderSharedFormTests);
    }

    resetDemoForm();
    renderSharedFormTests();
  }

  const api = {
    EVENTS,
    VALIDATION_CODES,
    validateRequired,
    validateEmail,
    validateMinLength,
    validateTenantCode,
    validateTaxNumber,
    renderFieldError,
    clearFieldError,
    clearAllErrors,
    getSharedFormPayload,
    validateSharedForm,
    renderValidationResult,
    handleSave,
    handleCancel,
    resetDemoForm,
    runSharedFormTests,
    renderSharedFormTests,
    bootstrapSharedFormStandard
  };

  global.Pix2piSharedFormStandard = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapSharedFormStandard);
    } else {
      bootstrapSharedFormStandard();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
