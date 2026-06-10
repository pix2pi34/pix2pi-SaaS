# FAZ 7-R / 354 LOCALIZATION CUSTOMER SMOKE REAL FINAL AUDIT

- PASS_COUNT=41
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS

## Locale ls
```
total 28
drwxr-xr-x 2 root root 4096 May 10 20:39 .
drwxr-xr-x 3 root root 4096 May 10 20:39 ..
-rw-r--r-- 1 root root 1991 May 10 20:39 ar.json
-rw-r--r-- 1 root root 1539 May 10 20:39 en.json
-rw-r--r-- 1 root root 1827 May 10 20:39 fa.json
-rw-r--r-- 1 root root 1873 May 10 20:39 ota.json
-rw-r--r-- 1 root root 1555 May 10 20:39 tr-TR.json
```

## Locale validation report
```json
{
  "localeDir": "/var/www/pix2pi/panel/i18n/locales",
  "runtimeFile": "/var/www/pix2pi/panel/assets/i18n/i18n-runtime.js",
  "runtimeExists": true,
  "locales": {
    "tr-TR": {
      "file": "/var/www/pix2pi/panel/i18n/locales/tr-TR.json",
      "exists": true,
      "readable": true,
      "jsonValid": true,
      "flattenedKeyCount": 32,
      "directionExpected": "ltr",
      "directionFromJson": null,
      "directionFromRuntimeEvidence": true,
      "directionStatus": true,
      "sampleKeys": [
        "app.name",
        "panel.title",
        "panel.dashboard",
        "panel.customer_surface",
        "panel.language_switcher",
        "panel.tenant_indicator",
        "auth.login.title",
        "auth.login.email",
        "auth.login.password",
        "auth.login.submit",
        "auth.tenant_select.title",
        "auth.errors.INVALID_CREDENTIALS",
        "auth.errors.TENANT_REQUIRED",
        "auth.errors.TENANT_FORBIDDEN",
        "auth.errors.SESSION_EXPIRED",
        "auth.errors.NETWORK_ERROR",
        "auth.errors.UNKNOWN",
        "pos.title",
        "pos.cart",
        "pos.payment"
      ]
    },
    "ota": {
      "file": "/var/www/pix2pi/panel/i18n/locales/ota.json",
      "exists": true,
      "readable": true,
      "jsonValid": true,
      "flattenedKeyCount": 32,
      "directionExpected": "rtl",
      "directionFromJson": null,
      "directionFromRuntimeEvidence": true,
      "directionStatus": true,
      "sampleKeys": [
        "app.name",
        "panel.title",
        "panel.dashboard",
        "panel.customer_surface",
        "panel.language_switcher",
        "panel.tenant_indicator",
        "auth.login.title",
        "auth.login.email",
        "auth.login.password",
        "auth.login.submit",
        "auth.tenant_select.title",
        "auth.errors.INVALID_CREDENTIALS",
        "auth.errors.TENANT_REQUIRED",
        "auth.errors.TENANT_FORBIDDEN",
        "auth.errors.SESSION_EXPIRED",
        "auth.errors.NETWORK_ERROR",
        "auth.errors.UNKNOWN",
        "pos.title",
        "pos.cart",
        "pos.payment"
      ]
    },
    "ar": {
      "file": "/var/www/pix2pi/panel/i18n/locales/ar.json",
      "exists": true,
      "readable": true,
      "jsonValid": true,
      "flattenedKeyCount": 32,
      "directionExpected": "rtl",
      "directionFromJson": null,
      "directionFromRuntimeEvidence": true,
      "directionStatus": true,
      "sampleKeys": [
        "app.name",
        "panel.title",
        "panel.dashboard",
        "panel.customer_surface",
        "panel.language_switcher",
        "panel.tenant_indicator",
        "auth.login.title",
        "auth.login.email",
        "auth.login.password",
        "auth.login.submit",
        "auth.tenant_select.title",
        "auth.errors.INVALID_CREDENTIALS",
        "auth.errors.TENANT_REQUIRED",
        "auth.errors.TENANT_FORBIDDEN",
        "auth.errors.SESSION_EXPIRED",
        "auth.errors.NETWORK_ERROR",
        "auth.errors.UNKNOWN",
        "pos.title",
        "pos.cart",
        "pos.payment"
      ]
    },
    "fa": {
      "file": "/var/www/pix2pi/panel/i18n/locales/fa.json",
      "exists": true,
      "readable": true,
      "jsonValid": true,
      "flattenedKeyCount": 32,
      "directionExpected": "rtl",
      "directionFromJson": null,
      "directionFromRuntimeEvidence": true,
      "directionStatus": true,
      "sampleKeys": [
        "app.name",
        "panel.title",
        "panel.dashboard",
        "panel.customer_surface",
        "panel.language_switcher",
        "panel.tenant_indicator",
        "auth.login.title",
        "auth.login.email",
        "auth.login.password",
        "auth.login.submit",
        "auth.tenant_select.title",
        "auth.errors.INVALID_CREDENTIALS",
        "auth.errors.TENANT_REQUIRED",
        "auth.errors.TENANT_FORBIDDEN",
        "auth.errors.SESSION_EXPIRED",
        "auth.errors.NETWORK_ERROR",
        "auth.errors.UNKNOWN",
        "pos.title",
        "pos.cart",
        "pos.payment"
      ]
    },
    "en": {
      "file": "/var/www/pix2pi/panel/i18n/locales/en.json",
      "exists": true,
      "readable": true,
      "jsonValid": true,
      "flattenedKeyCount": 32,
      "directionExpected": "ltr",
      "directionFromJson": null,
      "directionFromRuntimeEvidence": true,
      "directionStatus": true,
      "sampleKeys": [
        "app.name",
        "panel.title",
        "panel.dashboard",
        "panel.customer_surface",
        "panel.language_switcher",
        "panel.tenant_indicator",
        "auth.login.title",
        "auth.login.email",
        "auth.login.password",
        "auth.login.submit",
        "auth.tenant_select.title",
        "auth.errors.INVALID_CREDENTIALS",
        "auth.errors.TENANT_REQUIRED",
        "auth.errors.TENANT_FORBIDDEN",
        "auth.errors.SESSION_EXPIRED",
        "auth.errors.NETWORK_ERROR",
        "auth.errors.UNKNOWN",
        "pos.title",
        "pos.cart",
        "pos.payment"
      ]
    }
  },
  "fallback": {
    "runtimeHasFallbackOrDefaultTrTR": true,
    "trTRKeyCount": 32,
    "perLocale": {
      "ota": {
        "localeKeyCount": 32,
        "trTRKeysAvailable": 32,
        "missingKeysThatWouldFallbackToTrTR": [],
        "hasFallbackCandidate": false
      },
      "ar": {
        "localeKeyCount": 32,
        "trTRKeysAvailable": 32,
        "missingKeysThatWouldFallbackToTrTR": [],
        "hasFallbackCandidate": false
      },
      "fa": {
        "localeKeyCount": 32,
        "trTRKeysAvailable": 32,
        "missingKeysThatWouldFallbackToTrTR": [],
        "hasFallbackCandidate": false
      },
      "en": {
        "localeKeyCount": 32,
        "trTRKeysAvailable": 32,
        "missingKeysThatWouldFallbackToTrTR": [],
        "hasFallbackCandidate": false
      }
    }
  }
}
```

## Runtime grep
```
8:    defaultLanguage: "tr-TR",
9:    fallbackLanguage: "tr-TR",
10:    languageOrder: ["tr-TR", "ota", "ar", "fa", "en"],
11:    rtlLanguages: ["ota", "ar", "fa"],
12:    ltrLanguages: ["tr-TR", "en"],
13:    tenantDefaultLanguageKey: "pix2pi.tenant.default_language",
14:    userLanguagePreferenceKey: "pix2pi.user.language.preference",
15:    hardcodedUiTextPolicy: "data_i18n_required_for_localized_surfaces",
16:    calligraphyReference: {
17:      primaryReferenceName: "Ahmed Hüsrev Altınbaşak hattı",
18:      primaryReferenceUrl: "https://oku.risale.online/osm",
19:      appliesTo: ["ota", "ar", "fa"],
20:      useOtherReferenceSources: false
27:    return CONFIG.rtlLanguages.indexOf(language) >= 0;
30:  function directionOf(language) {
31:    return isRtl(language) ? "rtl" : "ltr";
34:  function calligraphyReferenceOf(language) {
36:    if (CONFIG.calligraphyReference.appliesTo.indexOf(normalized) >= 0) {
37:      return CONFIG.calligraphyReference.primaryReferenceName;
42:  function calligraphyReferenceUrlOf(language) {
44:    if (CONFIG.calligraphyReference.appliesTo.indexOf(normalized) >= 0) {
45:      return CONFIG.calligraphyReference.primaryReferenceUrl;
50:  function fontFamilyOf(language) {
59:    return CONFIG.fallbackLanguage;
62:  function getTenantDefaultLanguage() {
63:    return window.localStorage.getItem(CONFIG.tenantDefaultLanguageKey) || CONFIG.defaultLanguage;
66:  function setTenantDefaultLanguage(language) {
67:    window.localStorage.setItem(CONFIG.tenantDefaultLanguageKey, normalizeLanguage(language));
70:  function getUserLanguagePreference() {
71:    return window.localStorage.getItem(CONFIG.userLanguagePreferenceKey) || getTenantDefaultLanguage();
74:  function setUserLanguagePreference(language) {
75:    window.localStorage.setItem(CONFIG.userLanguagePreferenceKey, normalizeLanguage(language));
93:    if (!response.ok && normalized !== CONFIG.fallbackLanguage) {
94:      return loadLocale(CONFIG.fallbackLanguage);
106:    const normalized = normalizeLanguage(language || getUserLanguagePreference());
113:    const fallback = await loadLocale(CONFIG.fallbackLanguage);
114:    return fallback[key] || key;
118:    const selectedLanguage = normalizeLanguage(language || getUserLanguagePreference());
121:    document.documentElement.lang = selectedLanguage;
122:    document.documentElement.dir = directionOf(selectedLanguage);
123:    document.body.style.fontFamily = fontFamilyOf(selectedLanguage);
124:    document.body.setAttribute("data-i18n-language", selectedLanguage);
125:    document.body.setAttribute("data-i18n-direction", directionOf(selectedLanguage));
126:    document.body.setAttribute("data-calligraphy-reference", calligraphyReferenceOf(selectedLanguage));
127:    document.body.setAttribute("data-calligraphy-reference-url", calligraphyReferenceUrlOf(selectedLanguage));
129:    const nodes = document.querySelectorAll("[data-i18n]");
133:      node.textContent = value;
136:    const placeholderNodes = document.querySelectorAll("[data-i18n-placeholder]");
143:    const calligraphyNodes = document.querySelectorAll("[data-calligraphy-reference-output]");
145:      node.textContent = calligraphyReferenceOf(selectedLanguage) || "none";
148:    setUserLanguagePreference(selectedLanguage);
151:      direction: directionOf(selectedLanguage),
152:      fontFamily: fontFamilyOf(selectedLanguage),
153:      calligraphyReference: calligraphyReferenceOf(selectedLanguage),
154:      calligraphyReferenceUrl: calligraphyReferenceUrlOf(selectedLanguage)
159:    return new Intl.DateTimeFormat(normalizeLanguage(language || getUserLanguagePreference())).format(new Date(value));
163:    return new Intl.NumberFormat(normalizeLanguage(language || getUserLanguagePreference())).format(Number(value));
166:  function formatCurrency(value, currency, language) {
167:    return new Intl.NumberFormat(normalizeLanguage(language || getUserLanguagePreference()), {
168:      style: "currency",
169:      currency: currency || "TRY"
173:  function validateNoHardcodedText(root) {
174:    const scopedRoot = root || document;
176:    return localizedNodes.length > 0;
182:    directionOf,
183:    calligraphyReferenceOf,
184:    calligraphyReferenceUrlOf,
185:    fontFamilyOf,
187:    getTenantDefaultLanguage,
188:    setTenantDefaultLanguage,
189:    getUserLanguagePreference,
190:    setUserLanguagePreference,
197:    formatCurrency,
198:    validateNoHardcodedText
```

## Runtime HTTP headers
```
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Wed, 13 May 2026 04:42:54 GMT
content-type: application/javascript
content-length: 6890
last-modified: Sun, 10 May 2026 17:39:56 GMT
etag: "6a00c2ec-1aea"
x-pix2pi-surface: panel
x-pix2pi-public-route: fixed-panel-https
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
referrer-policy: strict-origin-when-cross-origin
accept-ranges: bytes

```

## DB language columns
```
tenant_onboarding.tenant_configs.default_language text
tenant_onboarding.tenant_configs.default_currency text
tenant_onboarding.tenant_configs.default_timezone text
```

## DB language SELECT
```
tenant_language=tenant-api-e2e-isolated-b|tr-TR|opened
tenant_language=tenant-api-e2e-success|tr-TR|opened
```

## Fallback candidates
```
ota: hasFallbackCandidate=False localeKeyCount=32 trTRKeysAvailable=32 missingSample=[]
ar: hasFallbackCandidate=False localeKeyCount=32 trTRKeysAvailable=32 missingSample=[]
fa: hasFallbackCandidate=False localeKeyCount=32 trTRKeysAvailable=32 missingSample=[]
en: hasFallbackCandidate=False localeKeyCount=32 trTRKeysAvailable=32 missingSample=[]
```

## Check log
```
dependency PASS evidence: FAZ_7R_319_347_REAL_DB_API_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_348_REAL_FINAL_V2_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_321_USER_ROLE_PERSONNEL_RBAC_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_351_POS_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
locale directory exists: /var/www/pix2pi/panel/i18n/locales / OK ✅
locale file readable: tr-TR.json / OK ✅
locale file readable: ota.json / OK ✅
locale file readable: ar.json / OK ✅
locale file readable: fa.json / OK ✅
locale file readable: en.json / OK ✅
JSON_VALID_STATUS tr-TR / OK ✅
KEY_COUNT_STATUS tr-TR >= 10 / OK ✅
DIRECTION_STATUS tr-TR / OK ✅
JSON_VALID_STATUS ota / OK ✅
KEY_COUNT_STATUS ota >= 10 / OK ✅
DIRECTION_STATUS ota / OK ✅
JSON_VALID_STATUS ar / OK ✅
KEY_COUNT_STATUS ar >= 10 / OK ✅
DIRECTION_STATUS ar / OK ✅
JSON_VALID_STATUS fa / OK ✅
KEY_COUNT_STATUS fa >= 10 / OK ✅
DIRECTION_STATUS fa / OK ✅
JSON_VALID_STATUS en / OK ✅
KEY_COUNT_STATUS en >= 10 / OK ✅
DIRECTION_STATUS en / OK ✅
runtime file readable: /var/www/pix2pi/panel/assets/i18n/i18n-runtime.js / OK ✅
RTL_FONT_BINDING_STATUS fontFamilyOf exists / OK ✅
DEFAULT_LANGUAGE_STATUS runtime contains tr-TR / OK ✅
RUNTIME_HTTP_STATUS i18n-runtime.js HTTP 200 / OK ✅
RUNTIME_HTTP_BODY_STATUS fontFamilyOf served live / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
DB_LANGUAGE_COLUMN_STATUS tenant_configs.default_language exists / OK ✅
DB_LANGUAGE_PREFERENCE_STATUS tenant-api-e2e-success tr-TR opened / OK ✅
DB_DEFAULT_LANGUAGE_STATUS tr-TR preference exists / OK ✅
FALLBACK_STATUS runtime declares tr-TR fallback/default / OK ✅
FALLBACK_SOURCE_STATUS tr-TR has >=10 fallback source keys / OK ✅
LOCALE_HTTP_STATUS tr-TR.json HTTP 200 / OK ✅
config semantic validation / OK ✅
```
