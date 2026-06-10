# FAZ 7-R / EK2 — Missing Locale JSON + Hüsrev Metadata Fix Audit

PASS_COUNT=24
FAIL_COUNT=1
WARN_COUNT=0
REQUIRED_FAIL=1
OPTIONAL_WARN=0
FINAL_STATUS=FAIL
FAZ_7R_EK2_MISSING_LOCALE_JSON_HUSREV_METADATA_STATUS=FAIL

## Fixed paths

```txt
/root/pix2pi/pix2pi-SaaS/locales/{ku-Latn,ku-Arab,zza-Latn,zza-Arab}/common.json
/var/www/pix2pi/panel/assets/i18n/{ku-Latn,ku-Arab,zza-Latn,zza-Arab}/common.json
/var/www/pix2pi/live/assets/i18n/{ku-Latn,ku-Arab,zza-Latn,zza-Arab}/common.json
```

## Semantic validation

```txt
SEMANTIC_/root/pix2pi/pix2pi-SaaS/locales_ku-Latn=PASS
KEY_PARITY_/root/pix2pi/pix2pi-SaaS/locales_ku-Arab=PASS
SEMANTIC_/root/pix2pi/pix2pi-SaaS/locales_ku-Arab=PASS
KEY_PARITY_/root/pix2pi/pix2pi-SaaS/locales_zza-Latn=PASS
SEMANTIC_/root/pix2pi/pix2pi-SaaS/locales_zza-Latn=PASS
KEY_PARITY_/root/pix2pi/pix2pi-SaaS/locales_zza-Arab=PASS
SEMANTIC_/root/pix2pi/pix2pi-SaaS/locales_zza-Arab=PASS
SEMANTIC_/var/www/pix2pi/panel/assets/i18n_ku-Latn=PASS
KEY_PARITY_/var/www/pix2pi/panel/assets/i18n_ku-Arab=PASS
SEMANTIC_/var/www/pix2pi/panel/assets/i18n_ku-Arab=PASS
KEY_PARITY_/var/www/pix2pi/panel/assets/i18n_zza-Latn=PASS
SEMANTIC_/var/www/pix2pi/panel/assets/i18n_zza-Latn=PASS
KEY_PARITY_/var/www/pix2pi/panel/assets/i18n_zza-Arab=PASS
SEMANTIC_/var/www/pix2pi/panel/assets/i18n_zza-Arab=PASS
SEMANTIC_/var/www/pix2pi/live/assets/i18n_ku-Latn=PASS
KEY_PARITY_/var/www/pix2pi/live/assets/i18n_ku-Arab=PASS
SEMANTIC_/var/www/pix2pi/live/assets/i18n_ku-Arab=PASS
KEY_PARITY_/var/www/pix2pi/live/assets/i18n_zza-Latn=PASS
SEMANTIC_/var/www/pix2pi/live/assets/i18n_zza-Latn=PASS
KEY_PARITY_/var/www/pix2pi/live/assets/i18n_zza-Arab=PASS
SEMANTIC_/var/www/pix2pi/live/assets/i18n_zza-Arab=PASS
COMMON_KEY_COUNT=15
```

## Live route smoke

```txt
/assets/i18n/ku-Latn/common.json HTTP=200
/assets/i18n/ku-Arab/common.json HTTP=200
/assets/i18n/zza-Latn/common.json HTTP=200
/assets/i18n/zza-Arab/common.json HTTP=200
```

## Result

```txt
ku-Latn  = Latin / no Husrev font
ku-Arab  = Arab / Hüsrev Düz + Tezyinat metadata
zza-Latn = Latin / no Husrev font
zza-Arab = Arab / Hüsrev Düz + Tezyinat metadata
```
