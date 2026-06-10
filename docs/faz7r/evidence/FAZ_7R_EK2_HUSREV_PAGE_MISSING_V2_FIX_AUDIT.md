# FAZ 7-R / EK2 — Hüsrev Page Missing V2 Fix Audit

PASS_COUNT=15
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0
FINAL_STATUS=PASS
FAZ_7R_EK2_HUSREV_PAGE_FIX_STATUS=PASS

## Fixed problem

```txt
Missing page fixed:
/var/www/pix2pi/panel/localization-ek2/index.html
/var/www/pix2pi/live/localization-ek2/index.html

Husrev font source:
/var/www/pix2pi/live/assets/fonts/husrev/eKalemDuz-Regular_150.ttf
/var/www/pix2pi/live/assets/fonts/husrev/eKalemTezyinat-Regular_2.ttf
```

## Live checks

```txt
/localization-ek2/ HTTP=200
/assets/fonts/husrev/husrev-ekalem.css HTTP=200
/assets/fonts/husrev/eKalemDuz-Regular_150.ttf HTTP=200
/assets/fonts/husrev/eKalemTezyinat-Regular_2.ttf HTTP=200
```

## Result

```txt
ku-Arab = Pix2piHusrevDuz + Pix2piHusrevTezyinat
zza-Arab = Pix2piHusrevDuz + Pix2piHusrevTezyinat
ku-Latn / zza-Latn = no Husrev font
```
