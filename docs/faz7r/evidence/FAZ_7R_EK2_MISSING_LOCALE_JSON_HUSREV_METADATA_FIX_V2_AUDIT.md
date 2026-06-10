# FAZ 7-R / EK2 — Missing Locale JSON + Hüsrev Metadata Fix V2 Audit

PASS_COUNT=33
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0
FINAL_STATUS=PASS
FAZ_7R_EK2_MISSING_LOCALE_JSON_HUSREV_METADATA_V2_STATUS=PASS

## Fixed issue

```txt
Previous run failed only because COMMON_KEY_COUNT=15 while expected was 16.
Added missing key: nav.marketplace
```

## Semantic validation

```txt
KEY_PARITY_/root/pix2pi/pix2pi-SaaS/locales_ku-Latn=PASS
KEY_COUNT_/root/pix2pi/pix2pi-SaaS/locales_ku-Latn=PASS
NAV_MARKETPLACE_/root/pix2pi/pix2pi-SaaS/locales_ku-Latn=PASS
SEMANTIC_/root/pix2pi/pix2pi-SaaS/locales_ku-Latn=PASS
KEY_PARITY_/root/pix2pi/pix2pi-SaaS/locales_ku-Arab=PASS
KEY_COUNT_/root/pix2pi/pix2pi-SaaS/locales_ku-Arab=PASS
NAV_MARKETPLACE_/root/pix2pi/pix2pi-SaaS/locales_ku-Arab=PASS
SEMANTIC_/root/pix2pi/pix2pi-SaaS/locales_ku-Arab=PASS
KEY_PARITY_/root/pix2pi/pix2pi-SaaS/locales_zza-Latn=PASS
KEY_COUNT_/root/pix2pi/pix2pi-SaaS/locales_zza-Latn=PASS
NAV_MARKETPLACE_/root/pix2pi/pix2pi-SaaS/locales_zza-Latn=PASS
SEMANTIC_/root/pix2pi/pix2pi-SaaS/locales_zza-Latn=PASS
KEY_PARITY_/root/pix2pi/pix2pi-SaaS/locales_zza-Arab=PASS
KEY_COUNT_/root/pix2pi/pix2pi-SaaS/locales_zza-Arab=PASS
NAV_MARKETPLACE_/root/pix2pi/pix2pi-SaaS/locales_zza-Arab=PASS
SEMANTIC_/root/pix2pi/pix2pi-SaaS/locales_zza-Arab=PASS
COMMON_KEY_COUNT_/root/pix2pi/pix2pi-SaaS/locales=16
KEY_PARITY_/var/www/pix2pi/panel/assets/i18n_ku-Latn=PASS
KEY_COUNT_/var/www/pix2pi/panel/assets/i18n_ku-Latn=PASS
NAV_MARKETPLACE_/var/www/pix2pi/panel/assets/i18n_ku-Latn=PASS
SEMANTIC_/var/www/pix2pi/panel/assets/i18n_ku-Latn=PASS
KEY_PARITY_/var/www/pix2pi/panel/assets/i18n_ku-Arab=PASS
KEY_COUNT_/var/www/pix2pi/panel/assets/i18n_ku-Arab=PASS
NAV_MARKETPLACE_/var/www/pix2pi/panel/assets/i18n_ku-Arab=PASS
SEMANTIC_/var/www/pix2pi/panel/assets/i18n_ku-Arab=PASS
KEY_PARITY_/var/www/pix2pi/panel/assets/i18n_zza-Latn=PASS
KEY_COUNT_/var/www/pix2pi/panel/assets/i18n_zza-Latn=PASS
NAV_MARKETPLACE_/var/www/pix2pi/panel/assets/i18n_zza-Latn=PASS
SEMANTIC_/var/www/pix2pi/panel/assets/i18n_zza-Latn=PASS
KEY_PARITY_/var/www/pix2pi/panel/assets/i18n_zza-Arab=PASS
KEY_COUNT_/var/www/pix2pi/panel/assets/i18n_zza-Arab=PASS
NAV_MARKETPLACE_/var/www/pix2pi/panel/assets/i18n_zza-Arab=PASS
SEMANTIC_/var/www/pix2pi/panel/assets/i18n_zza-Arab=PASS
COMMON_KEY_COUNT_/var/www/pix2pi/panel/assets/i18n=16
KEY_PARITY_/var/www/pix2pi/live/assets/i18n_ku-Latn=PASS
KEY_COUNT_/var/www/pix2pi/live/assets/i18n_ku-Latn=PASS
NAV_MARKETPLACE_/var/www/pix2pi/live/assets/i18n_ku-Latn=PASS
SEMANTIC_/var/www/pix2pi/live/assets/i18n_ku-Latn=PASS
KEY_PARITY_/var/www/pix2pi/live/assets/i18n_ku-Arab=PASS
KEY_COUNT_/var/www/pix2pi/live/assets/i18n_ku-Arab=PASS
NAV_MARKETPLACE_/var/www/pix2pi/live/assets/i18n_ku-Arab=PASS
SEMANTIC_/var/www/pix2pi/live/assets/i18n_ku-Arab=PASS
KEY_PARITY_/var/www/pix2pi/live/assets/i18n_zza-Latn=PASS
KEY_COUNT_/var/www/pix2pi/live/assets/i18n_zza-Latn=PASS
NAV_MARKETPLACE_/var/www/pix2pi/live/assets/i18n_zza-Latn=PASS
SEMANTIC_/var/www/pix2pi/live/assets/i18n_zza-Latn=PASS
KEY_PARITY_/var/www/pix2pi/live/assets/i18n_zza-Arab=PASS
KEY_COUNT_/var/www/pix2pi/live/assets/i18n_zza-Arab=PASS
NAV_MARKETPLACE_/var/www/pix2pi/live/assets/i18n_zza-Arab=PASS
SEMANTIC_/var/www/pix2pi/live/assets/i18n_zza-Arab=PASS
COMMON_KEY_COUNT_/var/www/pix2pi/live/assets/i18n=16
COMMON_KEY_COUNT=16
```

## Live i18n route smoke

```txt
/assets/i18n/ku-Latn/common.json HTTP=200
/assets/i18n/ku-Arab/common.json HTTP=200
/assets/i18n/zza-Latn/common.json HTTP=200
/assets/i18n/zza-Arab/common.json HTTP=200
```

## Page/font smoke

```txt
/localization-ek2/ HTTP=200
/assets/fonts/husrev/husrev-ekalem.css HTTP=200
/assets/fonts/husrev/eKalemDuz-Regular_150.ttf HTTP=200
/assets/fonts/husrev/eKalemTezyinat-Regular_2.ttf HTTP=200
```

## Result

```txt
ku-Latn  = 16 keys / Latin / no Husrev
ku-Arab  = 16 keys / Arab / Hüsrev Düz + Tezyinat
zza-Latn = 16 keys / Latin / no Husrev
zza-Arab = 16 keys / Arab / Hüsrev Düz + Tezyinat
```
