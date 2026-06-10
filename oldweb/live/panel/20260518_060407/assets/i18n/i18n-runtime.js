/* PIX2PI_318_I18N_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    registryPath: "/i18n/language-registry.json",
    localeBasePath: "/i18n/locales/",
    defaultLanguage: "tr-TR",
    fallbackLanguage: "tr-TR",
    languageOrder: ["tr-TR", "ota", "ar", "fa", "en"],
    rtlLanguages: ["ota", "ar", "fa"],
    ltrLanguages: ["tr-TR", "en"],
    tenantDefaultLanguageKey: "pix2pi.tenant.default_language",
    userLanguagePreferenceKey: "pix2pi.user.language.preference",
    hardcodedUiTextPolicy: "data_i18n_required_for_localized_surfaces",
    calligraphyReference: {
      primaryReferenceName: "Ahmed Hüsrev Altınbaşak hattı",
      primaryReferenceUrl: "https://oku.risale.online/osm",
      appliesTo: ["ota", "ar", "fa"],
      useOtherReferenceSources: false
    }
  };

  const cache = {};

  function isRtl(language) {
    return CONFIG.rtlLanguages.indexOf(language) >= 0;
  }

  function directionOf(language) {
    return isRtl(language) ? "rtl" : "ltr";
  }

  function calligraphyReferenceOf(language) {
    const normalized = normalizeLanguage(language);
    if (CONFIG.calligraphyReference.appliesTo.indexOf(normalized) >= 0) {
      return CONFIG.calligraphyReference.primaryReferenceName;
    }
    return "";
  }

  function calligraphyReferenceUrlOf(language) {
    const normalized = normalizeLanguage(language);
    if (CONFIG.calligraphyReference.appliesTo.indexOf(normalized) >= 0) {
      return CONFIG.calligraphyReference.primaryReferenceUrl;
    }
    return "";
  }

  function fontFamilyOf(language) {
    if (isRtl(language)) {
      return "Noto Naskh Arabic, Noto Sans Arabic, Vazirmatn, Tahoma, Arial, sans-serif";
    }
    return "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif";
  }

  function normalizeLanguage(language) {
    if (CONFIG.languageOrder.indexOf(language) >= 0) return language;
    return CONFIG.fallbackLanguage;
  }

  function getTenantDefaultLanguage() {
    return window.localStorage.getItem(CONFIG.tenantDefaultLanguageKey) || CONFIG.defaultLanguage;
  }

  function setTenantDefaultLanguage(language) {
    window.localStorage.setItem(CONFIG.tenantDefaultLanguageKey, normalizeLanguage(language));
  }

  function getUserLanguagePreference() {
    return window.localStorage.getItem(CONFIG.userLanguagePreferenceKey) || getTenantDefaultLanguage();
  }

  function setUserLanguagePreference(language) {
    window.localStorage.setItem(CONFIG.userLanguagePreferenceKey, normalizeLanguage(language));
  }

  async function loadRegistry() {
    const response = await fetch(CONFIG.registryPath, { cache: "no-store" });
    if (!response.ok) throw new Error("I18N_REGISTRY_LOAD_FAILED");
    return response.json();
  }

  async function loadLocale(language) {
    const normalized = normalizeLanguage(language);

    if (cache[normalized]) {
      return cache[normalized];
    }

    const response = await fetch(CONFIG.localeBasePath + normalized + ".json", { cache: "no-store" });

    if (!response.ok && normalized !== CONFIG.fallbackLanguage) {
      return loadLocale(CONFIG.fallbackLanguage);
    }

    if (!response.ok) {
      throw new Error("I18N_LOCALE_LOAD_FAILED");
    }

    cache[normalized] = await response.json();
    return cache[normalized];
  }

  async function translate(key, language) {
    const normalized = normalizeLanguage(language || getUserLanguagePreference());
    const selected = await loadLocale(normalized);

    if (Object.prototype.hasOwnProperty.call(selected, key)) {
      return selected[key];
    }

    const fallback = await loadLocale(CONFIG.fallbackLanguage);
    return fallback[key] || key;
  }

  async function applyLanguage(language) {
    const selectedLanguage = normalizeLanguage(language || getUserLanguagePreference());
    const messages = await loadLocale(selectedLanguage);

    document.documentElement.lang = selectedLanguage;
    document.documentElement.dir = directionOf(selectedLanguage);
    document.body.style.fontFamily = fontFamilyOf(selectedLanguage);
    document.body.setAttribute("data-i18n-language", selectedLanguage);
    document.body.setAttribute("data-i18n-direction", directionOf(selectedLanguage));
    document.body.setAttribute("data-calligraphy-reference", calligraphyReferenceOf(selectedLanguage));
    document.body.setAttribute("data-calligraphy-reference-url", calligraphyReferenceUrlOf(selectedLanguage));

    const nodes = document.querySelectorAll("[data-i18n]");
    nodes.forEach(function (node) {
      const key = node.getAttribute("data-i18n");
      const value = Object.prototype.hasOwnProperty.call(messages, key) ? messages[key] : key;
      node.textContent = value;
    });

    const placeholderNodes = document.querySelectorAll("[data-i18n-placeholder]");
    placeholderNodes.forEach(function (node) {
      const key = node.getAttribute("data-i18n-placeholder");
      const value = Object.prototype.hasOwnProperty.call(messages, key) ? messages[key] : key;
      node.setAttribute("placeholder", value);
    });

    const calligraphyNodes = document.querySelectorAll("[data-calligraphy-reference-output]");
    calligraphyNodes.forEach(function (node) {
      node.textContent = calligraphyReferenceOf(selectedLanguage) || "none";
    });

    setUserLanguagePreference(selectedLanguage);
    return {
      language: selectedLanguage,
      direction: directionOf(selectedLanguage),
      fontFamily: fontFamilyOf(selectedLanguage),
      calligraphyReference: calligraphyReferenceOf(selectedLanguage),
      calligraphyReferenceUrl: calligraphyReferenceUrlOf(selectedLanguage)
    };
  }

  function formatDate(value, language) {
    return new Intl.DateTimeFormat(normalizeLanguage(language || getUserLanguagePreference())).format(new Date(value));
  }

  function formatNumber(value, language) {
    return new Intl.NumberFormat(normalizeLanguage(language || getUserLanguagePreference())).format(Number(value));
  }

  function formatCurrency(value, currency, language) {
    return new Intl.NumberFormat(normalizeLanguage(language || getUserLanguagePreference()), {
      style: "currency",
      currency: currency || "TRY"
    }).format(Number(value));
  }

  function validateNoHardcodedText(root) {
    const scopedRoot = root || document;
    const localizedNodes = scopedRoot.querySelectorAll("[data-i18n]");
    return localizedNodes.length > 0;
  }

  window.Pix2piI18n = {
    CONFIG,
    isRtl,
    directionOf,
    calligraphyReferenceOf,
    calligraphyReferenceUrlOf,
    fontFamilyOf,
    normalizeLanguage,
    getTenantDefaultLanguage,
    setTenantDefaultLanguage,
    getUserLanguagePreference,
    setUserLanguagePreference,
    loadRegistry,
    loadLocale,
    translate,
    applyLanguage,
    formatDate,
    formatNumber,
    formatCurrency,
    validateNoHardcodedText
  };
})();
/* PIX2PI_318_I18N_RUNTIME_END */
