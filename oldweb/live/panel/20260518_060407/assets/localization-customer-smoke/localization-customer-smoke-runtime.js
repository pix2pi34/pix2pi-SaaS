/* PIX2PI_354_LOCALIZATION_CUSTOMER_SMOKE_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "localization_customer_smoke",
    phase: "FAZ_7R",
    step: "354",
    localizationSnapshotEndpoint: "/api/i18n/customer-smoke/snapshot",
    translationCompletenessEndpoint: "/api/i18n/customer-smoke/completeness",
    localizationAuditEndpoint: "/api/i18n/customer-smoke/audit",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    userSessionKey: "pix2pi.panel.user.session",
    userLanguageKey: "pix2pi.panel.language.preference",
    calligraphyPolicy: {
      primaryReferenceName: "Ahmed Hüsrev Altınbaşak",
      primaryReferenceUrl: "https://oku.risale.online/osm",
      appliesTo: ["ota", "tr-Arab", "ar", "fa"],
      otherReferenceSourcesAllowed: false
    },
    runtimeContract: {
      realTenantLanguageMutationEnabled: false,
      realUserLanguageMutationEnabled: false,
      realNotificationSendEnabled: false,
      localizationPreviewEnabled: true,
      rtlLtrPreviewEnabled: true,
      formatPreviewEnabled: true,
      translationCompletenessPreviewEnabled: true,
      hardcodedUiTextGuardPreviewEnabled: true,
      fallbackLocalizationSnapshotEnabled: true,
      readyForStep355: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      tenant_slug: "demo-market",
      tenant_default_language: "tr-TR",
      user_session_id: "USER_DEMO_SESSION",
      user_email: "owner@example.invalid",
      user_language_preference: "tr-TR",
      localization_scope: "controlled-localization-customer-smoke",
      correlation_id: "FAZ7R-354-DEMO-CORRELATION",
      languages: [
        { code: "tr-TR", label: "Latin Türkçe", direction: "ltr", complete: true, sample: "Pix2pi panel erişim testi hazır." },
        { code: "ota", label: "Osmanlıca Türkçesi", direction: "rtl", complete: true, sample: "پیكستۇپی پانل حاضردر", calligraphy_reference_required: true },
        { code: "tr-Arab", label: "Arap harfli Türkçe", direction: "rtl", complete: true, sample: "پیكستۇپی پانل حاضردر", calligraphy_reference_required: true },
        { code: "ar", label: "العربية", direction: "rtl", complete: true, sample: "لوحة بيكس تو بي جاهزة", calligraphy_reference_required: true },
        { code: "fa", label: "فارسی", direction: "rtl", complete: true, sample: "پنل پیکس تو پی آماده است", calligraphy_reference_required: true },
        { code: "en", label: "English", direction: "ltr", complete: true, sample: "Pix2pi panel access test is ready." }
      ],
      format_preview: [
        { locale: "tr-TR", date: "11.05.2026", time: "14:30", number: "1.234,56", currency: "₺1.234,56" },
        { locale: "ar", date: "١١‏/٠٥‏/٢٠٢٦", time: "١٤:٣٠", number: "١٬٢٣٤٫٥٦", currency: "١٬٢٣٤٫٥٦ ₺" },
        { locale: "fa", date: "۱۴۰۵/۰۲/۲۱", time: "۱۴:۳۰", number: "۱٬۲۳۴٫۵۶", currency: "۱٬۲۳۴٫۵۶ ₺" },
        { locale: "en", date: "05/11/2026", time: "2:30 PM", number: "1,234.56", currency: "₺1,234.56" }
      ],
      readiness: [
        { surface: "panel", scope: "routes/errors/forms", status: "READY_PREVIEW" },
        { surface: "pos", scope: "cashier/sales/payment", status: "READY_PREVIEW" },
        { surface: "marketplace", scope: "storefront/products/orders", status: "READY_PREVIEW" },
        { surface: "notifications", scope: "email/sms/whatsapp/errors", status: "READY_PREVIEW" }
      ],
      fallback_preview: [
        { key: "dashboard.unknown", requested: "ota", fallback: "tr-TR", decision: "FALLBACK_TO_DEFAULT" },
        { key: "pos.unknown", requested: "ar", fallback: "tr-TR", decision: "FALLBACK_TO_DEFAULT" }
      ],
      hardcoded_guard: [
        { surface: "panel", status: "PASS_PREVIEW", hardcoded_text_found: false },
        { surface: "pos", status: "PASS_PREVIEW", hardcoded_text_found: false },
        { surface: "marketplace", status: "PASS_PREVIEW", hardcoded_text_found: false }
      ],
      completeness: [
        { code: "tr-TR", required_keys: 42, translated_keys: 42, status: "COMPLETE" },
        { code: "ota", required_keys: 42, translated_keys: 42, status: "COMPLETE" },
        { code: "ar", required_keys: 42, translated_keys: 42, status: "COMPLETE" },
        { code: "fa", required_keys: 42, translated_keys: 42, status: "COMPLETE" },
        { code: "en", required_keys: 42, translated_keys: 42, status: "COMPLETE" }
      ],
      audit_timeline: [
        { at: "2026-05-demo", actor: "system", action: "USER_PERMISSION_READY", result: "PASS" },
        { at: "2026-05-demo", actor: "system", action: "LOCALIZATION_CUSTOMER_SMOKE_READY", result: "DRY_RUN" },
        { at: "2026-05-demo", actor: "system", action: "AHMED_HUSREV_REFERENCE_BOUND", result: "PASS" }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSnapshot.tenant_id;
  }

  function getUserLanguagePreference() {
    return window.localStorage.getItem(CONFIG.userLanguageKey) || CONFIG.fallbackSnapshot.user_language_preference;
  }

  function getUserSession() {
    const raw = window.localStorage.getItem(CONFIG.userSessionKey);
    if (!raw) {
      return {
        session_present: false,
        session_id: CONFIG.fallbackSnapshot.user_session_id,
        email: CONFIG.fallbackSnapshot.user_email
      };
    }

    try {
      return Object.assign({ session_present: true }, JSON.parse(raw));
    } catch (_error) {
      return {
        session_present: false,
        session_id: "INVALID_USER_SESSION",
        email: "unknown@example.invalid"
      };
    }
  }

  function localizationScopeHeaders(language) {
    const session = getUserSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-User-Session": session.session_id,
      "X-Language": language || getUserLanguagePreference(),
      "X-Localization-Scope": "controlled-localization-customer-smoke",
      "X-Correlation-ID": CONFIG.fallbackSnapshot.correlation_id,
      "X-Pix2pi-Surface": "merchant_panel_controlled_access",
      "X-Pix2pi-Step": "354"
    };
  }

  function validateLocalizationScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    if (!snapshot || !snapshot.user_session_id) errors.push({ field: "user_session_id", code: "USER_SESSION_REQUIRED" });
    if (!snapshot || !snapshot.tenant_default_language) errors.push({ field: "tenant_default_language", code: "TENANT_DEFAULT_LANGUAGE_REQUIRED" });
    if (!snapshot || !snapshot.user_language_preference) errors.push({ field: "user_language_preference", code: "USER_LANGUAGE_REQUIRED" });
    if (!snapshot || !snapshot.localization_scope) errors.push({ field: "localization_scope", code: "LOCALIZATION_SCOPE_REQUIRED" });
    if (!snapshot || !Array.isArray(snapshot.languages)) errors.push({ field: "languages", code: "LANGUAGE_REGISTRY_REQUIRED" });

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: localizationScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("LOCALIZATION_CUSTOMER_SMOKE_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchLocalizationSnapshot() {
    try {
      return await apiJson(CONFIG.localizationSnapshotEndpoint);
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      const session = getUserSession();
      snapshot.tenant_id = getTenantId();
      snapshot.user_session_id = session.session_id;
      snapshot.user_email = session.email || snapshot.user_email;
      snapshot.user_language_preference = getUserLanguagePreference();
      return snapshot;
    }
  }

  function buildLanguageRegistrySmoke(snapshot) {
    const required = ["tr-TR", "ota", "ar", "fa", "en"];
    const present = (snapshot.languages || []).map(function (item) { return item.code; });

    return {
      required: required,
      present: present,
      missing: required.filter(function (code) { return !present.includes(code); }),
      valid: required.every(function (code) { return present.includes(code); })
    };
  }

  function buildCalligraphyReferenceBindingCheck(snapshot) {
    const applies = CONFIG.calligraphyPolicy.appliesTo;
    const languages = snapshot.languages || [];
    const missingBinding = languages
      .filter(function (item) { return applies.includes(item.code); })
      .filter(function (item) { return item.calligraphy_reference_required !== true; })
      .map(function (item) { return item.code; });

    return {
      primary_reference_name: CONFIG.calligraphyPolicy.primaryReferenceName,
      primary_reference_url: CONFIG.calligraphyPolicy.primaryReferenceUrl,
      other_reference_sources_allowed: CONFIG.calligraphyPolicy.otherReferenceSourcesAllowed,
      applies_to: applies,
      missing_binding: missingBinding,
      valid: missingBinding.length === 0 && CONFIG.calligraphyPolicy.otherReferenceSourcesAllowed === false
    };
  }

  function buildRtlLtrLayoutSmoke(snapshot) {
    const ltr = (snapshot.languages || []).filter(function (item) { return item.direction === "ltr"; }).map(function (item) { return item.code; });
    const rtl = (snapshot.languages || []).filter(function (item) { return item.direction === "rtl"; }).map(function (item) { return item.code; });

    return {
      ltr: ltr,
      rtl: rtl,
      valid: ltr.includes("tr-TR") && ltr.includes("en") && rtl.includes("ota") && rtl.includes("ar") && rtl.includes("fa")
    };
  }

  function buildTranslationCompletenessSmoke(snapshot) {
    const incomplete = (snapshot.completeness || []).filter(function (item) {
      return item.status !== "COMPLETE" || item.required_keys !== item.translated_keys;
    });

    return {
      total_languages: (snapshot.completeness || []).length,
      incomplete: incomplete,
      valid: incomplete.length === 0
    };
  }

  function buildHardcodedTextGuardPreview(snapshot) {
    const failed = (snapshot.hardcoded_guard || []).filter(function (item) {
      return item.hardcoded_text_found === true || item.status !== "PASS_PREVIEW";
    });

    return {
      surfaces_checked: (snapshot.hardcoded_guard || []).map(function (item) { return item.surface; }),
      failed: failed,
      valid: failed.length === 0
    };
  }

  function buildLocalizationRuntimeContract(snapshot) {
    return {
      tenant_id: snapshot.tenant_id,
      tenant_slug: snapshot.tenant_slug,
      tenant_default_language: snapshot.tenant_default_language,
      user_session_id: snapshot.user_session_id,
      user_email: snapshot.user_email,
      user_language_preference: snapshot.user_language_preference,
      localization_scope: snapshot.localization_scope,
      language_registry: buildLanguageRegistrySmoke(snapshot),
      calligraphy_reference: buildCalligraphyReferenceBindingCheck(snapshot),
      rtl_ltr: buildRtlLtrLayoutSmoke(snapshot),
      completeness: buildTranslationCompletenessSmoke(snapshot),
      hardcoded_guard: buildHardcodedTextGuardPreview(snapshot),
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validateLocalizationScope(snapshot),
      source: {
        surface: "localization_customer_smoke",
        phase: "FAZ_7R",
        step: "354"
      }
    };
  }

  function renderContext(snapshot) {
    const tenant = document.getElementById("localization-tenant-id");
    const tenantLanguage = document.getElementById("tenant-default-language");
    const userLanguage = document.getElementById("user-language-preference");
    const session = document.getElementById("localization-user-session");
    const validation = document.getElementById("localization-scope-validation");
    const contract = buildLocalizationRuntimeContract(snapshot);

    if (tenant) tenant.textContent = snapshot.tenant_id;
    if (tenantLanguage) tenantLanguage.textContent = snapshot.tenant_default_language;
    if (userLanguage) userLanguage.textContent = snapshot.user_language_preference;
    if (session) session.textContent = snapshot.user_session_id;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderLanguages(snapshot) {
    const target = document.getElementById("language-registry-smoke-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.languages || []).forEach(function (language) {
      const row = document.createElement("article");
      row.className = "loc-card";
      row.setAttribute("data-language-code", language.code);
      row.setAttribute("data-direction", language.direction);
      row.setAttribute("dir", language.direction);
      row.innerHTML = [
        "<strong>" + language.label + " / " + language.code + "</strong>",
        "<p>" + language.sample + "</p>",
        "<small>direction=" + language.direction + " / complete=" + language.complete + "</small>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderFormatPreview(snapshot) {
    const target = document.getElementById("localization-format-preview");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.format_preview || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "loc-card";
      row.setAttribute("data-locale", item.locale);
      row.innerHTML = [
        "<strong>" + item.locale + "</strong>",
        "<p>" + item.date + " / " + item.time + " / " + item.number + " / " + item.currency + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderReadiness(snapshot) {
    const target = document.getElementById("localization-readiness-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.readiness || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "loc-card";
      row.setAttribute("data-readiness-surface", item.surface);
      row.innerHTML = [
        "<strong>" + item.surface + "</strong>",
        "<p>" + item.scope + " / " + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderFallbackPreview(snapshot) {
    const target = document.getElementById("localization-fallback-preview");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.fallback_preview || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "loc-card";
      row.setAttribute("data-fallback-key", item.key);
      row.innerHTML = [
        "<strong>" + item.key + "</strong>",
        "<p>" + item.requested + " → " + item.fallback + " / " + item.decision + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderCompleteness(snapshot) {
    const target = document.getElementById("translation-completeness-list");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.completeness || []).forEach(function (item) {
      const row = document.createElement("article");
      row.className = "loc-card";
      row.setAttribute("data-completeness-language", item.code);
      row.innerHTML = [
        "<strong>" + item.code + "</strong>",
        "<p>" + item.translated_keys + "/" + item.required_keys + " / " + item.status + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderAuditTimeline(snapshot) {
    const target = document.getElementById("localization-audit-timeline");
    if (!target) return;

    target.innerHTML = "";
    (snapshot.audit_timeline || []).forEach(function (event) {
      const row = document.createElement("article");
      row.className = "loc-card";
      row.setAttribute("data-audit-action", event.action);
      row.innerHTML = [
        "<strong>" + event.action + "</strong>",
        "<p>" + event.at + " / " + event.actor + " / " + event.result + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderRuntimeContract(snapshot) {
    const target = document.getElementById("localization-runtime-contract");
    if (!target) return;

    const contract = buildLocalizationRuntimeContract(snapshot);

    target.textContent = [
      "real_tenant_language_mutation_enabled=" + CONFIG.runtimeContract.realTenantLanguageMutationEnabled,
      "real_user_language_mutation_enabled=" + CONFIG.runtimeContract.realUserLanguageMutationEnabled,
      "rtl_ltr_preview_enabled=" + CONFIG.runtimeContract.rtlLtrPreviewEnabled,
      "translation_completeness_preview_enabled=" + CONFIG.runtimeContract.translationCompletenessPreviewEnabled,
      "ahmed_husrev_reference_valid=" + contract.calligraphy_reference.valid,
      "ready_for_step_355=" + CONFIG.runtimeContract.readyForStep355,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderLocalizationSmokeScreen(snapshot) {
    renderContext(snapshot);
    renderLanguages(snapshot);
    renderFormatPreview(snapshot);
    renderReadiness(snapshot);
    renderFallbackPreview(snapshot);
    renderCompleteness(snapshot);
    renderAuditTimeline(snapshot);
    renderRuntimeContract(snapshot);
    document.body.setAttribute("data-localization-customer-smoke-rendered", "true");
  }

  async function bootLocalizationSmokeScreen() {
    const snapshot = await fetchLocalizationSnapshot();
    renderLocalizationSmokeScreen(snapshot);
    return buildLocalizationRuntimeContract(snapshot);
  }

  window.Pix2piLocalizationCustomerSmoke = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getUserLanguagePreference: getUserLanguagePreference,
    getUserSession: getUserSession,
    localizationScopeHeaders: localizationScopeHeaders,
    validateLocalizationScope: validateLocalizationScope,
    fetchLocalizationSnapshot: fetchLocalizationSnapshot,
    buildLanguageRegistrySmoke: buildLanguageRegistrySmoke,
    buildCalligraphyReferenceBindingCheck: buildCalligraphyReferenceBindingCheck,
    buildRtlLtrLayoutSmoke: buildRtlLtrLayoutSmoke,
    buildTranslationCompletenessSmoke: buildTranslationCompletenessSmoke,
    buildHardcodedTextGuardPreview: buildHardcodedTextGuardPreview,
    buildLocalizationRuntimeContract: buildLocalizationRuntimeContract,
    renderContext: renderContext,
    renderLanguages: renderLanguages,
    renderFormatPreview: renderFormatPreview,
    renderReadiness: renderReadiness,
    renderFallbackPreview: renderFallbackPreview,
    renderCompleteness: renderCompleteness,
    renderAuditTimeline: renderAuditTimeline,
    renderRuntimeContract: renderRuntimeContract,
    renderLocalizationSmokeScreen: renderLocalizationSmokeScreen,
    bootLocalizationSmokeScreen: bootLocalizationSmokeScreen
  };
})();
/* PIX2PI_354_LOCALIZATION_CUSTOMER_SMOKE_RUNTIME_END */
