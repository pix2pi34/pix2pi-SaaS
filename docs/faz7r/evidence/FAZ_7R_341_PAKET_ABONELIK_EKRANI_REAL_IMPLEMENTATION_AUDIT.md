# FAZ 7-R / 341 — Paket / abonelik ekranı real implementation audit

Generated at: 20260510_222019

## Result

- PASS_COUNT=88
- FAIL_COUNT=4
- WARN_COUNT=0
- REQUIRED_FAIL=4
- OPTIONAL_WARN=0
- FAZ_7R_341_REAL_IMPLEMENTATION_STATUS=FAIL
- FAZ_7R_341_FINAL_STATUS=FAIL
- FAZ_7R_342_READY=NO

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_341_PAKET_ABONELIK_EKRANI.md
- Config: configs/faz7r/faz_7r_341_paket_abonelik_ekrani.v1.json
- Runtime: web/panel/assets/plans/panel-plans-runtime.js
- Plans HTML: web/panel/plans/index.html
- Smoke fixture: tests/faz7r/faz_7r_341_paket_abonelik_ekrani_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_341_paket_abonelik_ekrani.sh
- Backup directory: backups/faz7r/faz_7r_341_paket_abonelik_ekrani_20260510_222019

## Live paths

- /var/www/pix2pi/panel/plans/index.html
- /var/www/pix2pi/panel/assets/plans/panel-plans-runtime.js

## Public local-route contract

- http://panel.pix2pi.com.tr/plans/

## Audit check log

```
341 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
341 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
341 config directory IMPLEMENTED_OR_PRESENT / OK ✅
341 plans repo directory IMPLEMENTED_OR_PRESENT / OK ✅
341 plans asset directory IMPLEMENTED_OR_PRESENT / OK ✅
341 script directory IMPLEMENTED_OR_PRESENT / OK ✅
341 test directory IMPLEMENTED_OR_PRESENT / OK ✅
341 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
341 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
341 config file IMPLEMENTED_OR_PRESENT / OK ✅
341 panel plans runtime file IMPLEMENTED_OR_PRESENT / OK ✅
341 panel plans html file IMPLEMENTED_OR_PRESENT / OK ✅
341 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
341 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
341 live plans html file IMPLEMENTED_OR_PRESENT / OK ✅
341 live plans runtime file IMPLEMENTED_OR_PRESENT / OK ✅
341 active panel nginx route file REQUIRED_FAIL / FAIL ❌
341 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
341 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
341 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
341 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
341 config plans path contract IMPLEMENTED_OR_PRESENT / OK ✅
341 config ready for step 342 IMPLEMENTED_OR_PRESENT / OK ✅
341 config merchant session header contract IMPLEMENTED_OR_PRESENT / OK ✅
341 active panel server_name route REQUIRED_FAIL / FAIL ❌
341 active panel root route REQUIRED_FAIL / FAIL ❌
341 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
341.14 commercial scope headers function IMPLEMENTED_OR_PRESENT / OK ✅
341.14 plan scope validation IMPLEMENTED_OR_PRESENT / OK ✅
341 plan catalog function IMPLEMENTED_OR_PRESENT / OK ✅
341.11 plan comparison function IMPLEMENTED_OR_PRESENT / OK ✅
341.12 entitlement preview function IMPLEMENTED_OR_PRESENT / OK ✅
341.7 plan change disabled guard IMPLEMENTED_OR_PRESENT / OK ✅
341.11 runtime contract function IMPLEMENTED_OR_PRESENT / OK ✅
341.7 real plan change disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
341.13 payment collection disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
341 invoice issue disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
341 entitlement enforcement disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
341 ready for step 342 runtime IMPLEMENTED_OR_PRESENT / OK ✅
341 tenant header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
341 merchant session header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
341.1 plan subscription app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
341.2 tenant merchant context marker IMPLEMENTED_OR_PRESENT / OK ✅
341.3 plan cards marker IMPLEMENTED_OR_PRESENT / OK ✅
341.4 feature matrix marker IMPLEMENTED_OR_PRESENT / OK ✅
341.5 monthly annual price view marker IMPLEMENTED_OR_PRESENT / OK ✅
341.6 current plan badge marker IMPLEMENTED_OR_PRESENT / OK ✅
341.7 upgrade downgrade disabled marker IMPLEMENTED_OR_PRESENT / OK ✅
341.7 plan change disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
341.8 trial pilot placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
341.9 tax vat price note marker IMPLEMENTED_OR_PRESENT / OK ✅
341.10 commercial policy marker IMPLEMENTED_OR_PRESENT / OK ✅
341.11 runtime contract marker IMPLEMENTED_OR_PRESENT / OK ✅
341.11 ready for step 342 visible contract IMPLEMENTED_OR_PRESENT / OK ✅
341.12 entitlement preview handoff marker IMPLEMENTED_OR_PRESENT / OK ✅
341.12 entitlement enforcement disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
341.13 billing handoff disabled marker IMPLEMENTED_OR_PRESENT / OK ✅
341.13 payment collection disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
341.14 tenant plan subscription scope guard marker IMPLEMENTED_OR_PRESENT / OK ✅
341.15 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
341.15 i18n title marker IMPLEMENTED_OR_PRESENT / OK ✅
341.16 SEO OpenGraph marker IMPLEMENTED_OR_PRESENT / OK ✅
341.16 OpenGraph title meta IMPLEMENTED_OR_PRESENT / OK ✅
341 live plans html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
341 live plans runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
341 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
341 nginx loaded panel route exists IMPLEMENTED_OR_PRESENT / OK ✅
341.17 plans screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
341.17 plans screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
341.17 plans screen smoke body is not market route IMPLEMENTED_OR_PRESENT / OK ✅
341.17 plans runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
341.17 plans runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
341.17 plans runtime smoke body is not market route IMPLEMENTED_OR_PRESENT / OK ✅
341 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
341 standalone audit script execution status is PASS REQUIRED_FAIL / FAIL ❌
341.1 Paket / abonelik app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.2 Tenant / merchant context aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.3 Paket kartları aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.4 Plan özellik matrisi aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.5 Aylık / yıllık fiyat görünümü aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.6 Mevcut plan rozeti aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.7 Plan yükseltme / düşürme disabled gate aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.8 Trial / pilot plan placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.9 Vergi / KDV fiyat notu aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.10 Commercial policy note aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.11 Plan comparison runtime contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.12 Entitlement preview handoff aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.13 Billing handoff disabled gate aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.14 Tenant / plan / subscription scope guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.15 i18n-ready plan marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.16 SEO / OpenGraph plan placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
341.17 Paket / abonelik smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
