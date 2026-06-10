# FAZ 7-R / 357 HELP CENTER REAL FINAL AUDIT

- PASS_COUNT=42
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- SMOKE_RUN_ID=help-center-357-20260513_080936

## Document registry SELECT
```
help_docs=7
business|helpCenter.business.title|helpCenter.business.body|/help-center/business/
language|helpCenter.language.title|helpCenter.language.body|/help-center/language/
login|helpCenter.login.title|helpCenter.login.body|/help-center/login/
party|helpCenter.party.title|helpCenter.party.body|/help-center/party/
pos-sale|helpCenter.posSale.title|helpCenter.posSale.body|/help-center/pos-sale/
product|helpCenter.product.title|helpCenter.product.body|/help-center/product/
report|helpCenter.report.title|helpCenter.report.body|/help-center/report/
```

## HTTP document report
```
/help-center/|200|/root/pix2pi/pix2pi-SaaS/backups/faz7r_357_help_center_real_final_20260513_080936/http__help-center_.html
/help-center/login/|200|/root/pix2pi/pix2pi-SaaS/backups/faz7r_357_help_center_real_final_20260513_080936/http__help-center_login_.html
/help-center/business/|200|/root/pix2pi/pix2pi-SaaS/backups/faz7r_357_help_center_real_final_20260513_080936/http__help-center_business_.html
/help-center/party/|200|/root/pix2pi/pix2pi-SaaS/backups/faz7r_357_help_center_real_final_20260513_080936/http__help-center_party_.html
/help-center/product/|200|/root/pix2pi/pix2pi-SaaS/backups/faz7r_357_help_center_real_final_20260513_080936/http__help-center_product_.html
/help-center/pos-sale/|200|/root/pix2pi/pix2pi-SaaS/backups/faz7r_357_help_center_real_final_20260513_080936/http__help-center_pos-sale_.html
/help-center/report/|200|/root/pix2pi/pix2pi-SaaS/backups/faz7r_357_help_center_real_final_20260513_080936/http__help-center_report_.html
/help-center/language/|200|/root/pix2pi/pix2pi-SaaS/backups/faz7r_357_help_center_real_final_20260513_080936/http__help-center_language_.html
```

## i18n validation report
```json
{
  "documentKeys": {
    "index": [
      "helpCenter.business.title",
      "helpCenter.language.title",
      "helpCenter.login.title",
      "helpCenter.party.title",
      "helpCenter.posSale.title",
      "helpCenter.product.title",
      "helpCenter.report.title",
      "helpCenter.subtitle",
      "helpCenter.title"
    ],
    "login": [
      "helpCenter.login.body",
      "helpCenter.login.title",
      "helpCenter.subtitle",
      "helpCenter.title"
    ],
    "business": [
      "helpCenter.business.body",
      "helpCenter.business.title",
      "helpCenter.subtitle",
      "helpCenter.title"
    ],
    "party": [
      "helpCenter.party.body",
      "helpCenter.party.title",
      "helpCenter.subtitle",
      "helpCenter.title"
    ],
    "product": [
      "helpCenter.product.body",
      "helpCenter.product.title",
      "helpCenter.subtitle",
      "helpCenter.title"
    ],
    "pos-sale": [
      "helpCenter.posSale.body",
      "helpCenter.posSale.title",
      "helpCenter.subtitle",
      "helpCenter.title"
    ],
    "report": [
      "helpCenter.report.body",
      "helpCenter.report.title",
      "helpCenter.subtitle",
      "helpCenter.title"
    ],
    "language": [
      "helpCenter.language.body",
      "helpCenter.language.title",
      "helpCenter.subtitle",
      "helpCenter.title"
    ]
  },
  "allRequiredHelpKeys": [
    "helpCenter.business.body",
    "helpCenter.business.title",
    "helpCenter.language.body",
    "helpCenter.language.title",
    "helpCenter.login.body",
    "helpCenter.login.title",
    "helpCenter.party.body",
    "helpCenter.party.title",
    "helpCenter.posSale.body",
    "helpCenter.posSale.title",
    "helpCenter.product.body",
    "helpCenter.product.title",
    "helpCenter.report.body",
    "helpCenter.report.title",
    "helpCenter.subtitle",
    "helpCenter.title"
  ],
  "locales": {
    "tr-TR": {
      "flattenedKeyCount": 50,
      "requiredHelpKeyCount": 16,
      "missingHelpKeys": [],
      "status": true
    },
    "ota": {
      "flattenedKeyCount": 50,
      "requiredHelpKeyCount": 16,
      "missingHelpKeys": [],
      "status": true
    },
    "ar": {
      "flattenedKeyCount": 50,
      "requiredHelpKeyCount": 16,
      "missingHelpKeys": [],
      "status": true
    },
    "fa": {
      "flattenedKeyCount": 50,
      "requiredHelpKeyCount": 16,
      "missingHelpKeys": [],
      "status": true
    },
    "en": {
      "flattenedKeyCount": 50,
      "requiredHelpKeyCount": 16,
      "missingHelpKeys": [],
      "status": true
    }
  },
  "overallStatus": true
}
```

## Smoke DB SELECT
```
smoke_run=help-center-357-20260513_080936|pass|7|8|16|true
smoke_events=8
smoke_event_fail=0
```

## Check log
```
dependency PASS evidence: FAZ_7R_356_CONTROLLED_USAGE_GO_LIVE_DECISION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_357_CONTROLLED_CUSTOMER_ACCESS_ACTIVATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_354_LOCALIZATION_CUSTOMER_SMOKE_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: product_support.help_center_documents / OK ✅
table exists: product_support.help_center_smoke_events / OK ✅
table exists: product_support.help_center_smoke_runs / OK ✅
locale directory exists: /var/www/pix2pi/panel/i18n/locales / OK ✅
locale file readable before patch: tr-TR.json / OK ✅
locale file readable before patch: ota.json / OK ✅
locale file readable before patch: ar.json / OK ✅
locale file readable before patch: fa.json / OK ✅
locale file readable before patch: en.json / OK ✅
locale JSON valid after patch: tr-TR / OK ✅
locale JSON valid after patch: ota / OK ✅
locale JSON valid after patch: ar / OK ✅
locale JSON valid after patch: fa / OK ✅
locale JSON valid after patch: en / OK ✅
help center HTML documents written / OK ✅
help center document registry upserted / OK ✅
REAL_DB_SELECT_STATUS help_docs=7 / OK ✅
nginx help center route bind / OK ✅
DOC_HTTP_STATUS /help-center/ HTTP 200 marker / OK ✅
DOC_HTTP_STATUS /help-center/login/ HTTP 200 marker / OK ✅
DOC_HTTP_STATUS /help-center/business/ HTTP 200 marker / OK ✅
DOC_HTTP_STATUS /help-center/party/ HTTP 200 marker / OK ✅
DOC_HTTP_STATUS /help-center/product/ HTTP 200 marker / OK ✅
DOC_HTTP_STATUS /help-center/pos-sale/ HTTP 200 marker / OK ✅
DOC_HTTP_STATUS /help-center/report/ HTTP 200 marker / OK ✅
DOC_HTTP_STATUS /help-center/language/ HTTP 200 marker / OK ✅
I18N_KEY_STATUS all help center data-i18n keys exist in all locales / OK ✅
I18N_KEY_STATUS tr-TR help keys complete / OK ✅
I18N_KEY_STATUS ota help keys complete / OK ✅
I18N_KEY_STATUS ar help keys complete / OK ✅
I18N_KEY_STATUS fa help keys complete / OK ✅
I18N_KEY_STATUS en help keys complete / OK ✅
HELP_CENTER_SMOKE_DB_WRITE_STATUS smoke run/events inserted / OK ✅
REAL_DB_SELECT_STATUS smoke_run pass db_written / OK ✅
REAL_DB_SELECT_STATUS smoke_events=8 / OK ✅
REAL_DB_SELECT_STATUS smoke_event_fail=0 / OK ✅
config semantic validation / OK ✅
```
