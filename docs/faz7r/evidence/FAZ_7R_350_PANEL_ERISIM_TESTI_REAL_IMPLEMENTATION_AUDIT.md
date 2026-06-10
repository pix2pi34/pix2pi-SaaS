# FAZ 7-R / 350 — Panel erişim testi real implementation audit

Generated at: 20260511_061739

## Result

- PASS_COUNT=93
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_350_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_350_FINAL_STATUS=PASS
- FAZ_7R_351_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_350_PANEL_ERISIM_TESTI.md
- Config: configs/faz7r/faz_7r_350_panel_erisim_testi.v1.json
- Runtime: web/panel/assets/panel-access-test/panel-access-test-runtime.js
- Panel access HTML: web/panel/panel-access-test/index.html
- Smoke fixture: tests/faz7r/faz_7r_350_panel_erisim_testi_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_350_panel_erisim_testi.sh
- Backup directory: backups/faz7r/faz_7r_350_panel_erisim_testi_20260511_061739

## Live URL

- https://panel.pix2pi.com.tr/panel-access-test/

## Audit check log

```
350 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
350 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
350 config directory IMPLEMENTED_OR_PRESENT / OK ✅
350 panel access repo directory IMPLEMENTED_OR_PRESENT / OK ✅
350 panel access asset directory IMPLEMENTED_OR_PRESENT / OK ✅
350 script directory IMPLEMENTED_OR_PRESENT / OK ✅
350 test directory IMPLEMENTED_OR_PRESENT / OK ✅
350 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
350 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
350 config file IMPLEMENTED_OR_PRESENT / OK ✅
350 panel access runtime file IMPLEMENTED_OR_PRESENT / OK ✅
350 panel access html file IMPLEMENTED_OR_PRESENT / OK ✅
350 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
350 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
350 live panel access html file IMPLEMENTED_OR_PRESENT / OK ✅
350 live panel access runtime file IMPLEMENTED_OR_PRESENT / OK ✅
350 active panel nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
350 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
350 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
350 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
350 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
350 config panel access path contract IMPLEMENTED_OR_PRESENT / OK ✅
350 config ready for step 351 IMPLEMENTED_OR_PRESENT / OK ✅
350 config route scope header contract IMPLEMENTED_OR_PRESENT / OK ✅
350 active panel server_name route IMPLEMENTED_OR_PRESENT / OK ✅
350 active panel root route IMPLEMENTED_OR_PRESENT / OK ✅
350 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
350.14 panel access scope headers function IMPLEMENTED_OR_PRESENT / OK ✅
350.14 panel access scope validation IMPLEMENTED_OR_PRESENT / OK ✅
350 panel access snapshot function IMPLEMENTED_OR_PRESENT / OK ✅
350 route access preview function IMPLEMENTED_OR_PRESENT / OK ✅
350 unauthorized preview function IMPLEMENTED_OR_PRESENT / OK ✅
350.12 navigation handoff function IMPLEMENTED_OR_PRESENT / OK ✅
350.15 runtime contract function IMPLEMENTED_OR_PRESENT / OK ✅
350 JWT verify disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
350 session create disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
350 RBAC backend disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
350 ready for step 351 runtime IMPLEMENTED_OR_PRESENT / OK ✅
350 tenant header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
350 user session header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
350 user role header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
350 route scope header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
350.1 panel access test app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
350.2 auth session simulation context marker IMPLEMENTED_OR_PRESENT / OK ✅
350.3 tenant selected context marker IMPLEMENTED_OR_PRESENT / OK ✅
350.4 owner admin role preview marker IMPLEMENTED_OR_PRESENT / OK ✅
350.5 route availability checklist marker IMPLEMENTED_OR_PRESENT / OK ✅
350.6 dashboard access check marker IMPLEMENTED_OR_PRESENT / OK ✅
350.7 users roles access check marker IMPLEMENTED_OR_PRESENT / OK ✅
350.8 products stock access check marker IMPLEMENTED_OR_PRESENT / OK ✅
350.9 billing entitlements access check marker IMPLEMENTED_OR_PRESENT / OK ✅
350.10 unauthorized forbidden preview marker IMPLEMENTED_OR_PRESENT / OK ✅
350.11 session timeout preview marker IMPLEMENTED_OR_PRESENT / OK ✅
350.12 panel navigation handoff marker IMPLEMENTED_OR_PRESENT / OK ✅
350.12 POS handoff visible contract IMPLEMENTED_OR_PRESENT / OK ✅
350.13 access audit timeline marker IMPLEMENTED_OR_PRESENT / OK ✅
350.14 scope guard marker IMPLEMENTED_OR_PRESENT / OK ✅
350.15 runtime contract marker IMPLEMENTED_OR_PRESENT / OK ✅
350.15 ready for step 351 visible contract IMPLEMENTED_OR_PRESENT / OK ✅
350.16 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
350.16 i18n title marker IMPLEMENTED_OR_PRESENT / OK ✅
350.17 SEO OpenGraph marker IMPLEMENTED_OR_PRESENT / OK ✅
350.17 OpenGraph title meta IMPLEMENTED_OR_PRESENT / OK ✅
350 live panel access html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
350 live panel access runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
350 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
350 nginx loaded panel route exists IMPLEMENTED_OR_PRESENT / OK ✅
350.18 panel access screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
350.18 panel access screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
350.18 panel access screen smoke body is not market route IMPLEMENTED_OR_PRESENT / OK ✅
350.18 panel access runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
350.18 panel access runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
350.18 panel access runtime smoke body is not market route IMPLEMENTED_OR_PRESENT / OK ✅
350 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
350 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
350.1 Panel access test app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.2 Auth/session simulation context aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.3 Tenant selected context aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.4 Owner admin role access preview aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.5 Panel route availability checklist aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.6 Dashboard access check aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.7 Users / roles access check aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.8 Products / stock access check aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.9 Billing / entitlements access check aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.10 Unauthorized / forbidden preview aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.11 Session timeout preview aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.12 Panel navigation handoff aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.13 Access audit timeline aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.14 Tenant / user / role / route scope guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.15 Panel access runtime data contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.16 i18n-ready panel access marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.17 SEO / OpenGraph panel access placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
350.18 Panel erişim smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
