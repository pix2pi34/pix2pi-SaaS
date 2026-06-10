# FAZ 7-R / 355 — İlk gerçek kullanım smoke testi real implementation audit

Generated at: 20260511_063111

## Result

- PASS_COUNT=94
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_355_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_355_FINAL_STATUS=PASS
- FAZ_7R_356_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_355_ILK_GERCEK_KULLANIM_SMOKE_TESTI.md
- Config: configs/faz7r/faz_7r_355_ilk_gercek_kullanim_smoke_testi.v1.json
- Runtime: web/panel/assets/first-real-usage-smoke/first-real-usage-smoke-runtime.js
- First usage HTML: web/panel/first-real-usage-smoke/index.html
- Smoke fixture: tests/faz7r/faz_7r_355_ilk_gercek_kullanim_smoke_testi.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_355_ilk_gercek_kullanim_smoke_testi.sh
- Backup directory: backups/faz7r/faz_7r_355_ilk_gercek_kullanim_smoke_testi_20260511_063111

## Live URL

- https://panel.pix2pi.com.tr/first-real-usage-smoke/

## Audit check log

```
355 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
355 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
355 config directory IMPLEMENTED_OR_PRESENT / OK ✅
355 first usage smoke repo directory IMPLEMENTED_OR_PRESENT / OK ✅
355 first usage smoke asset directory IMPLEMENTED_OR_PRESENT / OK ✅
355 script directory IMPLEMENTED_OR_PRESENT / OK ✅
355 test directory IMPLEMENTED_OR_PRESENT / OK ✅
355 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
355 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
355 config file IMPLEMENTED_OR_PRESENT / OK ✅
355 first usage smoke runtime file IMPLEMENTED_OR_PRESENT / OK ✅
355 first usage smoke html file IMPLEMENTED_OR_PRESENT / OK ✅
355 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
355 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
355 live first usage smoke html file IMPLEMENTED_OR_PRESENT / OK ✅
355 live first usage smoke runtime file IMPLEMENTED_OR_PRESENT / OK ✅
355 active panel nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
355 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
355 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
355 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
355 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
355 config first usage path contract IMPLEMENTED_OR_PRESENT / OK ✅
355 config ready for step 356 IMPLEMENTED_OR_PRESENT / OK ✅
355 config data mutation disabled contract IMPLEMENTED_OR_PRESENT / OK ✅
355 active panel server_name route IMPLEMENTED_OR_PRESENT / OK ✅
355 active panel root route IMPLEMENTED_OR_PRESENT / OK ✅
355 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
355 scope headers function IMPLEMENTED_OR_PRESENT / OK ✅
355 scope validation function IMPLEMENTED_OR_PRESENT / OK ✅
355 snapshot function IMPLEMENTED_OR_PRESENT / OK ✅
355 dependency gate function IMPLEMENTED_OR_PRESENT / OK ✅
355.14 customer journey checklist function IMPLEMENTED_OR_PRESENT / OK ✅
355.13 data mutation guard function IMPLEMENTED_OR_PRESENT / OK ✅
355 first usage decision function IMPLEMENTED_OR_PRESENT / OK ✅
355.16 runtime contract function IMPLEMENTED_OR_PRESENT / OK ✅
355 customer go-live disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
355 sale disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
355 payment disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
355 invoice disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
355 stock decrement disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
355 data mutation disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
355 ready for step 356 runtime IMPLEMENTED_OR_PRESENT / OK ✅
355.1 first usage app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
355.2 scenario context marker IMPLEMENTED_OR_PRESENT / OK ✅
355.3 panel login access smoke marker IMPLEMENTED_OR_PRESENT / OK ✅
355.4 tenant isolation gate marker IMPLEMENTED_OR_PRESENT / OK ✅
355.5 user permission gate marker IMPLEMENTED_OR_PRESENT / OK ✅
355.6 localization dependency marker IMPLEMENTED_OR_PRESENT / OK ✅
355.7 POS access chain marker IMPLEMENTED_OR_PRESENT / OK ✅
355.8 marketplace smoke marker IMPLEMENTED_OR_PRESENT / OK ✅
355.9 product stock read marker IMPLEMENTED_OR_PRESENT / OK ✅
355.10 cart payment dry-run marker IMPLEMENTED_OR_PRESENT / OK ✅
355.11 invoice billing disabled marker IMPLEMENTED_OR_PRESENT / OK ✅
355.12 audit correlation timeline marker IMPLEMENTED_OR_PRESENT / OK ✅
355.13 data mutation safety marker IMPLEMENTED_OR_PRESENT / OK ✅
355.14 customer journey checklist marker IMPLEMENTED_OR_PRESENT / OK ✅
355.15 rollback stop criteria marker IMPLEMENTED_OR_PRESENT / OK ✅
355.16 runtime contract marker IMPLEMENTED_OR_PRESENT / OK ✅
355.16 ready for step 356 visible contract IMPLEMENTED_OR_PRESENT / OK ✅
355.17 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
355.17 i18n title marker IMPLEMENTED_OR_PRESENT / OK ✅
355.18 SEO OpenGraph marker IMPLEMENTED_OR_PRESENT / OK ✅
355.18 OpenGraph title meta IMPLEMENTED_OR_PRESENT / OK ✅
355 live first usage smoke html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
355 live first usage smoke runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
355 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
355 nginx loaded panel route exists IMPLEMENTED_OR_PRESENT / OK ✅
355.19 first usage screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
355.19 first usage screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
355.19 first usage screen smoke body is not POS/market route IMPLEMENTED_OR_PRESENT / OK ✅
355.19 first usage runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
355.19 first usage runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
355.19 first usage runtime smoke body is not POS/market route IMPLEMENTED_OR_PRESENT / OK ✅
355 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
355 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
355.1 First real usage smoke app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.2 Pilot tenant / owner / store / register context aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.3 Panel login + access chain smoke aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.4 Tenant isolation gate smoke aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.5 User permission gate smoke aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.6 Localization customer smoke dependency aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.7 POS access chain smoke aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.8 Marketplace/storefront availability smoke aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.9 Product / stock read smoke aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.10 Cart / payment dry-run smoke aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.11 Invoice / billing disabled gate smoke aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.12 Audit / correlation timeline aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.13 Data mutation disabled safety guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.14 Customer journey checklist aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.15 Rollback / stop criteria preview aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.16 First usage runtime data contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.17 i18n-ready first usage marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.18 SEO / OpenGraph first usage placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
355.19 İlk gerçek kullanım smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
