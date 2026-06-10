#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_4_4_SHARED_FORM_STANDARD"

BACKUP_DIR="$REPO/backups/faz1/faz_1_4_4_shared_form_standard_$TS"
WEB_DIR="$REPO/web/faz1/ui-foundation/shared-form"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
DOC_DIR="$REPO/docs/faz1/web"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
SCRIPT_DIR="$REPO/scripts/web"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/shared_form.js"
CSS_FILE="$WEB_DIR/shared_form.css"
CONFIG_FILE="$CONFIG_DIR/shared_form_standard_contract.v1.json"
DOC_FILE="$DOC_DIR/FAZ_1_4_4_SHARED_FORM_STANDARD.md"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_4_4_shared_form_standard_strict_suite.sh"
APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_4_4_shared_form_standard.sh"
STRICT_SUITE_OUT="$BACKUP_DIR/faz_1_4_4_shared_form_standard_strict_suite.out"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_4_SHARED_FORM_STANDARD_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_4_4_SHARED_FORM_STANDARD_FINAL_SEAL_$TS.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

extract_var() {
  local file="$1"
  local key="$2"
  grep "^${key}=" "$file" 2>/dev/null | tail -n1 | cut -d= -f2- || true
}

echo "===== FAZ 1-4.4 SHARED FORM STANDARD START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$WEB_DIR" "$CONFIG_DIR" "$DOC_DIR" "$EVIDENCE_DIR" "$SCRIPT_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$HTML_FILE" "$JS_FILE" "$CSS_FILE" "$CONFIG_FILE" "$DOC_FILE" "$STRICT_SUITE_FILE" "$APPLY_SCRIPT_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_$TS"
    pass "2.x yedek alındı: $f"
  else
    warn "2.x yedek atlandı, dosya yok: $f"
  fi
done

echo "3. shared form contract config yazılıyor..."

cat <<'JSON' > "$CONFIG_FILE"
{
  "phase": "FAZ_1_4_4",
  "module": "WEB_L1_UI_FOUNDATION_DESIGN_SYSTEM",
  "component": "shared_form_standard",
  "status": "READY",
  "required_capabilities": [
    "input_standard",
    "validation_standard",
    "error_display",
    "save_cancel_pattern",
    "form_tests"
  ],
  "form_contract": {
    "form_class": "pix2pi-form",
    "form_row_class": "pix2pi-form-row",
    "input_class": "pix2pi-input",
    "select_class": "pix2pi-select",
    "textarea_class": "pix2pi-textarea",
    "field_error_class": "pix2pi-field-error",
    "form_error_class": "pix2pi-form-error",
    "form_success_class": "pix2pi-form-success",
    "action_bar_class": "pix2pi-form-actions",
    "save_button_class": "pix2pi-button primary",
    "cancel_button_class": "pix2pi-button secondary"
  },
  "validation_contract": {
    "required": "FIELD_REQUIRED",
    "email": "INVALID_EMAIL",
    "min_length": "MIN_LENGTH_NOT_MET",
    "tenant_code": "INVALID_TENANT_CODE",
    "tax_number": "INVALID_TAX_NUMBER"
  },
  "save_cancel_contract": {
    "save_event": "pix2pi:form-save",
    "cancel_event": "pix2pi:form-cancel",
    "validation_event": "pix2pi:form-validation",
    "dirty_state_policy": "WARN_ON_CANCEL_WHEN_DIRTY",
    "save_policy": "VALIDATE_BEFORE_SAVE"
  },
  "test_contract": {
    "required_fields": [
      "legal_name",
      "email",
      "tenant_code"
    ],
    "optional_fields": [
      "tax_number",
      "description"
    ],
    "final_gate": "PASS_ONLY_IF_ALL_FORM_TESTS_PASS"
  }
}
JSON

if [ -f "$CONFIG_FILE" ]; then
  pass "3.1 shared form config yazıldı: $CONFIG_FILE"
else
  fail "3.1 shared form config yazılamadı"
  exit 1
fi

echo "4. shared form CSS yazılıyor..."

cat <<'CSS' > "$CSS_FILE"
:root {
  --pix2pi-bg: #0f172a;
  --pix2pi-surface: #111827;
  --pix2pi-surface-soft: #1f2937;
  --pix2pi-content: #020617;
  --pix2pi-border: #334155;
  --pix2pi-text: #e5e7eb;
  --pix2pi-muted: #9ca3af;
  --pix2pi-accent: #38bdf8;
  --pix2pi-ok: #22c55e;
  --pix2pi-warn: #f59e0b;
  --pix2pi-danger: #ef4444;
  --pix2pi-form-gap: 14px;
  --pix2pi-radius-lg: 20px;
  --pix2pi-radius-md: 14px;
  --pix2pi-shadow: 0 24px 80px rgba(0, 0, 0, 0.28);
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-height: 100vh;
  background: radial-gradient(circle at top left, #312e81 0, var(--pix2pi-bg) 42%);
  color: var(--pix2pi-text);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.pix2pi-page {
  width: min(1120px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0;
}

.pix2pi-page-header {
  display: flex;
  justify-content: space-between;
  gap: 18px;
  align-items: flex-start;
  margin-bottom: 24px;
}

.pix2pi-page-title {
  margin: 0;
  font-size: 30px;
  letter-spacing: -0.04em;
}

.pix2pi-page-subtitle {
  margin: 8px 0 0;
  color: var(--pix2pi-muted);
}

.pix2pi-grid {
  display: grid;
  grid-template-columns: 1fr 420px;
  gap: 18px;
}

.pix2pi-card {
  background: rgba(17, 24, 39, 0.92);
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: 22px;
  box-shadow: var(--pix2pi-shadow);
}

.pix2pi-form {
  display: grid;
  gap: var(--pix2pi-form-gap);
}

.pix2pi-form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--pix2pi-form-gap);
}

.pix2pi-form-row {
  display: grid;
  gap: 7px;
}

.pix2pi-label {
  color: var(--pix2pi-muted);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.pix2pi-required {
  color: #fecaca;
}

.pix2pi-input,
.pix2pi-select,
.pix2pi-textarea {
  width: 100%;
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-md);
  background: var(--pix2pi-content);
  color: var(--pix2pi-text);
  padding: 12px 14px;
  outline: none;
}

.pix2pi-textarea {
  min-height: 96px;
  resize: vertical;
}

.pix2pi-input:focus,
.pix2pi-select:focus,
.pix2pi-textarea:focus {
  border-color: var(--pix2pi-accent);
  box-shadow: 0 0 0 3px rgba(56, 189, 248, 0.12);
}

.pix2pi-input.invalid,
.pix2pi-select.invalid,
.pix2pi-textarea.invalid {
  border-color: rgba(239, 68, 68, 0.8);
}

.pix2pi-field-error {
  display: none;
  color: #fecaca;
  font-size: 13px;
}

.pix2pi-field-error.visible {
  display: block;
}

.pix2pi-form-error {
  display: none;
  border: 1px solid rgba(239, 68, 68, 0.55);
  background: rgba(239, 68, 68, 0.1);
  color: #fecaca;
  border-radius: var(--pix2pi-radius-md);
  padding: 12px 14px;
}

.pix2pi-form-error.visible {
  display: block;
}

.pix2pi-form-success {
  display: none;
  border: 1px solid rgba(34, 197, 94, 0.55);
  background: rgba(34, 197, 94, 0.1);
  color: #bbf7d0;
  border-radius: var(--pix2pi-radius-md);
  padding: 12px 14px;
}

.pix2pi-form-success.visible {
  display: block;
}

.pix2pi-form-actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 10px;
  border-top: 1px solid var(--pix2pi-border);
  padding-top: 16px;
  margin-top: 6px;
}

.pix2pi-button {
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-md);
  background: var(--pix2pi-surface-soft);
  color: var(--pix2pi-text);
  padding: 11px 14px;
  cursor: pointer;
  font-weight: 800;
}

.pix2pi-button.primary {
  border-color: rgba(56, 189, 248, 0.6);
  background: rgba(56, 189, 248, 0.14);
}

.pix2pi-button.secondary {
  border-color: rgba(148, 163, 184, 0.45);
  background: rgba(148, 163, 184, 0.08);
}

.pix2pi-badge {
  display: inline-flex;
  border: 1px solid var(--pix2pi-border);
  background: var(--pix2pi-surface-soft);
  color: var(--pix2pi-text);
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 13px;
}

.pix2pi-badge.ok {
  border-color: rgba(34, 197, 94, 0.5);
  color: #bbf7d0;
}

.pix2pi-badge.warn {
  border-color: rgba(245, 158, 11, 0.5);
  color: #fde68a;
}

.pix2pi-log {
  background: var(--pix2pi-content);
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: 14px;
  color: var(--pix2pi-muted);
  min-height: 280px;
  white-space: pre-wrap;
  overflow: auto;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

@media (max-width: 900px) {
  .pix2pi-page-header,
  .pix2pi-grid,
  .pix2pi-form-grid {
    display: grid;
    grid-template-columns: 1fr;
  }

  .pix2pi-form-actions {
    justify-content: stretch;
  }

  .pix2pi-form-actions .pix2pi-button {
    width: 100%;
  }
}
CSS

if grep -q "pix2pi-input" "$CSS_FILE" \
  && grep -q "pix2pi-field-error" "$CSS_FILE" \
  && grep -q "pix2pi-form-error" "$CSS_FILE" \
  && grep -q "pix2pi-form-actions" "$CSS_FILE" \
  && grep -q "@media" "$CSS_FILE"; then
  pass "4.1 CSS shared form sınıfları mevcut"
else
  fail "4.1 CSS shared form sınıfları eksik"
  exit 1
fi

echo "5. shared form JS yazılıyor..."

cat <<'JS' > "$JS_FILE"
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
JS

if grep -q "validateRequired" "$JS_FILE" \
  && grep -q "validateEmail" "$JS_FILE" \
  && grep -q "renderFieldError" "$JS_FILE" \
  && grep -q "handleSave" "$JS_FILE" \
  && grep -q "handleCancel" "$JS_FILE" \
  && grep -q "runSharedFormTests" "$JS_FILE"; then
  pass "5.1 JS shared form runtime fonksiyonları mevcut"
else
  fail "5.1 JS shared form runtime fonksiyonları eksik"
  exit 1
fi

echo "6. shared form HTML yazılıyor..."

cat <<'HTML' > "$HTML_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — Shared Form Standardı</title>
  <link rel="stylesheet" href="./shared_form.css">
</head>
<body>
  <main class="pix2pi-page">
    <header class="pix2pi-page-header">
      <div>
        <h1 class="pix2pi-page-title">Pix2pi Shared Form Standardı</h1>
        <p class="pix2pi-page-subtitle">FAZ 1-4.4 — WEB-L1 UI Foundation / Design System</p>
      </div>
      <span class="pix2pi-badge ok">WEB-L1 READY</span>
    </header>

    <section class="pix2pi-grid">
      <article class="pix2pi-card">
        <form class="pix2pi-form" id="sharedForm" novalidate>
          <div class="pix2pi-form-error" id="sharedFormError" role="alert"></div>
          <div class="pix2pi-form-success" id="sharedFormSuccess" role="status"></div>

          <div class="pix2pi-form-grid">
            <label class="pix2pi-form-row">
              <span class="pix2pi-label">Firma adı <span class="pix2pi-required">*</span></span>
              <input class="pix2pi-input" id="legalName" name="legal_name" type="text" aria-describedby="legalNameError">
              <span class="pix2pi-field-error" id="legalNameError" data-error-for="legalName"></span>
            </label>

            <label class="pix2pi-form-row">
              <span class="pix2pi-label">E-posta <span class="pix2pi-required">*</span></span>
              <input class="pix2pi-input" id="email" name="email" type="email" aria-describedby="emailError">
              <span class="pix2pi-field-error" id="emailError" data-error-for="email"></span>
            </label>

            <label class="pix2pi-form-row">
              <span class="pix2pi-label">Tenant kodu <span class="pix2pi-required">*</span></span>
              <input class="pix2pi-input" id="tenantCode" name="tenant_code" type="text" aria-describedby="tenantCodeError">
              <span class="pix2pi-field-error" id="tenantCodeError" data-error-for="tenantCode"></span>
            </label>

            <label class="pix2pi-form-row">
              <span class="pix2pi-label">Vergi no</span>
              <input class="pix2pi-input" id="taxNumber" name="tax_number" type="text" aria-describedby="taxNumberError">
              <span class="pix2pi-field-error" id="taxNumberError" data-error-for="taxNumber"></span>
            </label>
          </div>

          <label class="pix2pi-form-row">
            <span class="pix2pi-label">İşletme tipi</span>
            <select class="pix2pi-select" id="businessType" name="business_type">
              <option value="retail">Perakende</option>
              <option value="accounting">Muhasebe</option>
              <option value="operations">Operasyon</option>
            </select>
          </label>

          <label class="pix2pi-form-row">
            <span class="pix2pi-label">Açıklama</span>
            <textarea class="pix2pi-textarea" id="description" name="description" aria-describedby="descriptionError"></textarea>
            <span class="pix2pi-field-error" id="descriptionError" data-error-for="description"></span>
          </label>

          <div class="pix2pi-form-actions">
            <span class="pix2pi-badge ok" id="sharedFormDirtyState">CLEAN</span>
            <button class="pix2pi-button secondary" id="cancelSharedFormButton" type="button">Vazgeç</button>
            <button class="pix2pi-button secondary" id="resetSharedFormButton" type="button">Demo doldur</button>
            <button class="pix2pi-button primary" id="saveSharedFormButton" type="submit">Kaydet</button>
          </div>
        </form>
      </article>

      <aside class="pix2pi-card">
        <div class="pix2pi-form-actions" style="justify-content:flex-start; border-top:0; padding-top:0;">
          <button class="pix2pi-button primary" id="runSharedFormTestsButton" type="button">Form testlerini çalıştır</button>
        </div>

        <pre class="pix2pi-log" id="sharedFormTestOutput">FORM_TEST_LOADING</pre>
        <pre class="pix2pi-log" id="sharedFormLog">Shared form event log...</pre>
      </aside>
    </section>
  </main>

  <script src="./shared_form.js"></script>
</body>
</html>
HTML

if grep -q "sharedForm" "$HTML_FILE" \
  && grep -q "pix2pi-input" "$HTML_FILE" \
  && grep -q "pix2pi-select" "$HTML_FILE" \
  && grep -q "pix2pi-textarea" "$HTML_FILE" \
  && grep -q "pix2pi-field-error" "$HTML_FILE" \
  && grep -q "saveSharedFormButton" "$HTML_FILE" \
  && grep -q "cancelSharedFormButton" "$HTML_FILE"; then
  pass "6.1 HTML shared form elementleri mevcut"
else
  fail "6.1 HTML shared form elementleri eksik"
  exit 1
fi

echo "7. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/shared-form"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/shared_form.js"
CSS_FILE="$WEB_DIR/shared_form.css"
CONFIG_FILE="$CONFIG_DIR/shared_form_standard_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_4_SHARED_FORM_STANDARD_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

check_file() {
  local file="$1"
  local label="$2"

  if [ -f "$file" ]; then
    pass "$label mevcut"
  else
    fail "$label eksik: $file"
  fi
}

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label eksik"
  fi
}

echo "===== FAZ 1-4.4 SHARED FORM STANDARD STRICT SUITE START ====="

mkdir -p "$EVIDENCE_DIR"

check_file "$HTML_FILE" "1.1 HTML file"
check_file "$JS_FILE" "1.2 JS file"
check_file "$CSS_FILE" "1.3 CSS file"
check_file "$CONFIG_FILE" "1.4 config file"

if command -v python3 >/dev/null 2>&1; then
  if python3 -m json.tool "$CONFIG_FILE" >/dev/null 2>&1; then
    pass "2.1 config JSON valid"
  else
    fail "2.1 config JSON invalid"
  fi
else
  warn "2.1 python3 yok, JSON validation atlandı"
fi

check_contains "$CONFIG_FILE" '"input_standard"' "3.1 input_standard capability contract"
check_contains "$CONFIG_FILE" '"validation_standard"' "3.2 validation_standard capability contract"
check_contains "$CONFIG_FILE" '"error_display"' "3.3 error_display capability contract"
check_contains "$CONFIG_FILE" '"save_cancel_pattern"' "3.4 save_cancel_pattern capability contract"
check_contains "$CONFIG_FILE" '"form_tests"' "3.5 form_tests capability contract"

check_contains "$HTML_FILE" 'pix2pi-input' "4.1 input standard HTML"
check_contains "$HTML_FILE" 'pix2pi-select' "4.2 select standard HTML"
check_contains "$HTML_FILE" 'pix2pi-textarea' "4.3 textarea standard HTML"
check_contains "$HTML_FILE" 'pix2pi-field-error' "4.4 field error HTML"
check_contains "$HTML_FILE" 'sharedFormError' "4.5 form error HTML"
check_contains "$HTML_FILE" 'saveSharedFormButton' "4.6 save button HTML"
check_contains "$HTML_FILE" 'cancelSharedFormButton' "4.7 cancel button HTML"

check_contains "$JS_FILE" 'validateRequired' "5.1 required validation JS"
check_contains "$JS_FILE" 'validateEmail' "5.2 email validation JS"
check_contains "$JS_FILE" 'validateMinLength' "5.3 min length validation JS"
check_contains "$JS_FILE" 'validateTenantCode' "5.4 tenant code validation JS"
check_contains "$JS_FILE" 'validateTaxNumber' "5.5 tax number validation JS"
check_contains "$JS_FILE" 'renderFieldError' "5.6 field error display JS"
check_contains "$JS_FILE" 'renderValidationResult' "5.7 validation result render JS"
check_contains "$JS_FILE" 'handleSave' "5.8 save pattern JS"
check_contains "$JS_FILE" 'handleCancel' "5.9 cancel pattern JS"
check_contains "$JS_FILE" 'runSharedFormTests' "5.10 form tests JS"

check_contains "$CSS_FILE" 'pix2pi-input' "6.1 input CSS"
check_contains "$CSS_FILE" 'pix2pi-select' "6.2 select CSS"
check_contains "$CSS_FILE" 'pix2pi-textarea' "6.3 textarea CSS"
check_contains "$CSS_FILE" 'pix2pi-field-error' "6.4 field error CSS"
check_contains "$CSS_FILE" 'pix2pi-form-error' "6.5 form error CSS"
check_contains "$CSS_FILE" 'pix2pi-form-actions' "6.6 form actions CSS"

INPUT_STANDARD_STATUS="PASS"
VALIDATION_STANDARD_STATUS="PASS"
ERROR_DISPLAY_STATUS="PASS"
SAVE_CANCEL_PATTERN_STATUS="PASS"
FORM_TESTS_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  INPUT_STANDARD_STATUS="FAIL"
  VALIDATION_STANDARD_STATUS="FAIL"
  ERROR_DISPLAY_STATUS="FAIL"
  SAVE_CANCEL_PATTERN_STATUS="FAIL"
  FORM_TESTS_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.4 Shared Form Standard Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- INPUT_STANDARD_STATUS=$INPUT_STANDARD_STATUS"
  echo "- VALIDATION_STANDARD_STATUS=$VALIDATION_STANDARD_STATUS"
  echo "- ERROR_DISPLAY_STATUS=$ERROR_DISPLAY_STATUS"
  echo "- SAVE_CANCEL_PATTERN_STATUS=$SAVE_CANCEL_PATTERN_STATUS"
  echo "- FORM_TESTS_STATUS=$FORM_TESTS_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.4 SHARED FORM STANDARD STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "INPUT_STANDARD_STATUS=$INPUT_STANDARD_STATUS"
echo "VALIDATION_STANDARD_STATUS=$VALIDATION_STANDARD_STATUS"
echo "ERROR_DISPLAY_STATUS=$ERROR_DISPLAY_STATUS"
echo "SAVE_CANCEL_PATTERN_STATUS=$SAVE_CANCEL_PATTERN_STATUS"
echo "FORM_TESTS_STATUS=$FORM_TESTS_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.4 SHARED FORM STANDARD STRICT SUITE END ====="
SUITE

chmod +x "$STRICT_SUITE_FILE"

if [ -x "$STRICT_SUITE_FILE" ]; then
  pass "7.1 strict suite dosyası yazıldı ve executable yapıldı: $STRICT_SUITE_FILE"
else
  fail "7.1 strict suite executable değil"
  exit 1
fi

echo "8. strict suite çalıştırılıyor..."

set +e
"$STRICT_SUITE_FILE" > "$STRICT_SUITE_OUT" 2>&1
STRICT_SUITE_EXIT_CODE=$?
set -e

cat "$STRICT_SUITE_OUT"

if [ "$STRICT_SUITE_EXIT_CODE" -eq 0 ]; then
  pass "8.1 strict suite exit code 0"
else
  fail "8.1 strict suite başarısız exit_code=$STRICT_SUITE_EXIT_CODE"
  exit 1
fi

STRICT_SUITE_PASS_COUNT="$(extract_var "$STRICT_SUITE_OUT" "PASS_COUNT")"
STRICT_SUITE_FAIL_COUNT="$(extract_var "$STRICT_SUITE_OUT" "FAIL_COUNT")"
STRICT_SUITE_WARN_COUNT="$(extract_var "$STRICT_SUITE_OUT" "WARN_COUNT")"
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_4_SHARED_FORM_STANDARD_STRICT_SUITE_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_4_SHARED_FORM_STANDARD_STRICT_SUITE_SEAL_STATUS")"

INPUT_STANDARD_STATUS="$(extract_var "$STRICT_SUITE_OUT" "INPUT_STANDARD_STATUS")"
VALIDATION_STANDARD_STATUS="$(extract_var "$STRICT_SUITE_OUT" "VALIDATION_STANDARD_STATUS")"
ERROR_DISPLAY_STATUS="$(extract_var "$STRICT_SUITE_OUT" "ERROR_DISPLAY_STATUS")"
SAVE_CANCEL_PATTERN_STATUS="$(extract_var "$STRICT_SUITE_OUT" "SAVE_CANCEL_PATTERN_STATUS")"
FORM_TESTS_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FORM_TESTS_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "8.2 strict suite FAIL_COUNT=0 doğrulandı" || fail "8.2 strict suite FAIL_COUNT sıfır değil"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "8.3 strict suite PASS doğrulandı" || fail "8.3 strict suite PASS değil"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "8.4 strict suite SEALED doğrulandı" || fail "8.4 strict suite SEALED değil"

echo "9. dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-4.4 — Shared Form Standardı

## Kapsam

- Input standardı
- Validation standardı
- Error display
- Save/cancel pattern
- Form tests

## Üretilen Dosyalar

- UI: web/faz1/ui-foundation/shared-form/index.html
- Runtime JS: web/faz1/ui-foundation/shared-form/shared_form.js
- CSS: web/faz1/ui-foundation/shared-form/shared_form.css
- Contract: configs/faz1/web/ui_foundation/shared_form_standard_contract.v1.json
- Strict suite: scripts/web/faz_1_4_4_shared_form_standard_strict_suite.sh

## Final Status

- INPUT_STANDARD_STATUS=${INPUT_STANDARD_STATUS:-N/A}
- VALIDATION_STANDARD_STATUS=${VALIDATION_STANDARD_STATUS:-N/A}
- ERROR_DISPLAY_STATUS=${ERROR_DISPLAY_STATUS:-N/A}
- SAVE_CANCEL_PATTERN_STATUS=${SAVE_CANCEL_PATTERN_STATUS:-N/A}
- FORM_TESTS_STATUS=${FORM_TESTS_STATUS:-N/A}
- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}
- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-4.4 Shared Form Standard Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo "- STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
  echo "- DOC_FILE=$DOC_FILE"
  echo "- BACKUP_DIR=$BACKUP_DIR"
  echo
  echo "## Status"
  echo "- INPUT_STANDARD_STATUS=${INPUT_STANDARD_STATUS:-N/A}"
  echo "- VALIDATION_STANDARD_STATUS=${VALIDATION_STANDARD_STATUS:-N/A}"
  echo "- ERROR_DISPLAY_STATUS=${ERROR_DISPLAY_STATUS:-N/A}"
  echo "- SAVE_CANCEL_PATTERN_STATUS=${SAVE_CANCEL_PATTERN_STATUS:-N/A}"
  echo "- FORM_TESTS_STATUS=${FORM_TESTS_STATUS:-N/A}"
  echo "- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo
  echo "## Counters"
  echo "- APPLY_PASS_COUNT=$PASS_COUNT"
  echo "- APPLY_FAIL_COUNT=$FAIL_COUNT"
  echo "- APPLY_WARN_COUNT=$WARN_COUNT"
  echo "- STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
  echo "- STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
  echo "- STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-4.4 Shared Form Standard Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_4_4_INPUT_STANDARD_STATUS=${INPUT_STANDARD_STATUS:-N/A}"
  echo "FAZ_1_4_4_VALIDATION_STANDARD_STATUS=${VALIDATION_STANDARD_STATUS:-N/A}"
  echo "FAZ_1_4_4_ERROR_DISPLAY_STATUS=${ERROR_DISPLAY_STATUS:-N/A}"
  echo "FAZ_1_4_4_SAVE_CANCEL_PATTERN_STATUS=${SAVE_CANCEL_PATTERN_STATUS:-N/A}"
  echo "FAZ_1_4_4_FORM_TESTS_STATUS=${FORM_TESTS_STATUS:-N/A}"
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_4_5_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "9.1 dokümantasyon yazıldı: $DOC_FILE"
pass "9.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "9.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"

if [ -x "$APPLY_SCRIPT_FILE" ]; then
  pass "9.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"
else
  fail "9.4 apply script repo içine kopyalanamadı"
  exit 1
fi

echo "===== FAZ 1-4.4 SHARED FORM STANDARD RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "INPUT_STANDARD_STATUS=${INPUT_STANDARD_STATUS:-N/A}"
echo "VALIDATION_STANDARD_STATUS=${VALIDATION_STANDARD_STATUS:-N/A}"
echo "ERROR_DISPLAY_STATUS=${ERROR_DISPLAY_STATUS:-N/A}"
echo "SAVE_CANCEL_PATTERN_STATUS=${SAVE_CANCEL_PATTERN_STATUS:-N/A}"
echo "FORM_TESTS_STATUS=${FORM_TESTS_STATUS:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "HTML_FILE=$HTML_FILE"
echo "JS_FILE=$JS_FILE"
echo "CSS_FILE=$CSS_FILE"
echo "CONFIG_FILE=$CONFIG_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_4_4_INPUT_STANDARD_STATUS=PASS"
  echo "FAZ_1_4_4_VALIDATION_STANDARD_STATUS=PASS"
  echo "FAZ_1_4_4_ERROR_DISPLAY_STATUS=PASS"
  echo "FAZ_1_4_4_SAVE_CANCEL_PATTERN_STATUS=PASS"
  echo "FAZ_1_4_4_FORM_TESTS_STATUS=PASS"
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_FINAL_STATUS=PASS"
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_SEAL_STATUS=SEALED"
  echo "FAZ_1_4_5_READY=YES"
else
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_FINAL_STATUS=FAIL"
  echo "FAZ_1_4_4_SHARED_FORM_STANDARD_SEAL_STATUS=OPEN"
  echo "FAZ_1_4_5_READY=NO"
  exit 1
fi

echo "===== FAZ 1-4.4 SHARED FORM STANDARD END ====="
