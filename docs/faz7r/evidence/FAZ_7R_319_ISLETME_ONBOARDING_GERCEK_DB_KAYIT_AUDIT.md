# FAZ 7-R / 319 — İşletme onboarding gerçek DB kayıt audit

Generated at: 20260511_074417

## Result

- PASS_COUNT=74
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_319_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_319_FINAL_STATUS=PASS
- FAZ_7R_347_READY=YES

## Live URL

- https://panel.pix2pi.com.tr/onboarding/

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_319_ISLETME_ONBOARDING_GERCEK_DB_KAYIT.md
- Config: configs/faz7r/faz_7r_319_isletme_onboarding.v1.json
- Migration: db/migrations/20260511_319_business_onboarding_real_records.sql
- Runtime: internal/onboarding/businessonboarding/business_onboarding.go
- Test: internal/onboarding/businessonboarding/business_onboarding_test.go
- JS: web/panel/assets/onboarding/business-onboarding-runtime.js
- HTML: web/panel/onboarding/index.html
- Audit script: scripts/faz7r/audit_faz_7r_319_isletme_onboarding.sh
- Backup: backups/faz7r/faz_7r_319_isletme_onboarding_gercek_db_kayit_20260511_074417

## Audit check log

```
319 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
319 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
319 config directory IMPLEMENTED_OR_PRESENT / OK ✅
319 migration directory IMPLEMENTED_OR_PRESENT / OK ✅
319 runtime directory IMPLEMENTED_OR_PRESENT / OK ✅
319 onboarding web directory IMPLEMENTED_OR_PRESENT / OK ✅
319 onboarding asset directory IMPLEMENTED_OR_PRESENT / OK ✅
319 script directory IMPLEMENTED_OR_PRESENT / OK ✅
319 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
319 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
319 config file IMPLEMENTED_OR_PRESENT / OK ✅
319 DB migration file IMPLEMENTED_OR_PRESENT / OK ✅
319 runtime file IMPLEMENTED_OR_PRESENT / OK ✅
319 test file IMPLEMENTED_OR_PRESENT / OK ✅
319 panel JS runtime file IMPLEMENTED_OR_PRESENT / OK ✅
319 panel HTML file IMPLEMENTED_OR_PRESENT / OK ✅
319 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
319 live onboarding html file IMPLEMENTED_OR_PRESENT / OK ✅
319 live onboarding runtime file IMPLEMENTED_OR_PRESENT / OK ✅
319 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
319 doc business name validation IMPLEMENTED_OR_PRESENT / OK ✅
319 doc tax validation IMPLEMENTED_OR_PRESENT / OK ✅
319 doc tenant slug IMPLEMENTED_OR_PRESENT / OK ✅
319 config tenant record IMPLEMENTED_OR_PRESENT / OK ✅
319 config legal entity IMPLEMENTED_OR_PRESENT / OK ✅
319 config branch record IMPLEMENTED_OR_PRESENT / OK ✅
319 config owner role binding IMPLEMENTED_OR_PRESENT / OK ✅
319 migration onboarding requests IMPLEMENTED_OR_PRESENT / OK ✅
319 migration audit events IMPLEMENTED_OR_PRESENT / OK ✅
319 migration tenants IMPLEMENTED_OR_PRESENT / OK ✅
319 migration legal entities IMPLEMENTED_OR_PRESENT / OK ✅
319 migration branches IMPLEMENTED_OR_PRESENT / OK ✅
319 migration memberships IMPLEMENTED_OR_PRESENT / OK ✅
319 runtime complete function IMPLEMENTED_OR_PRESENT / OK ✅
319 runtime HTTP complete IMPLEMENTED_OR_PRESENT / OK ✅
319 runtime slug function IMPLEMENTED_OR_PRESENT / OK ✅
319 runtime tenant creation IMPLEMENTED_OR_PRESENT / OK ✅
319 runtime legal creation IMPLEMENTED_OR_PRESENT / OK ✅
319 runtime branch creation IMPLEMENTED_OR_PRESENT / OK ✅
319 runtime membership creation IMPLEMENTED_OR_PRESENT / OK ✅
319 runtime request save IMPLEMENTED_OR_PRESENT / OK ✅
319 runtime audit event IMPLEMENTED_OR_PRESENT / OK ✅
319 test complete creates records IMPLEMENTED_OR_PRESENT / OK ✅
319 test missing business name IMPLEMENTED_OR_PRESENT / OK ✅
319 test invalid tax IMPLEMENTED_OR_PRESENT / OK ✅
319 test unsupported language currency role IMPLEMENTED_OR_PRESENT / OK ✅
319 test tenant slug IMPLEMENTED_OR_PRESENT / OK ✅
319 test HTTP complete IMPLEMENTED_OR_PRESENT / OK ✅
319 panel JS runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
319 panel JS submit function IMPLEMENTED_OR_PRESENT / OK ✅
319 panel HTML screen marker IMPLEMENTED_OR_PRESENT / OK ✅
319 panel HTML business info marker IMPLEMENTED_OR_PRESENT / OK ✅
319 panel HTML address branch marker IMPLEMENTED_OR_PRESENT / OK ✅
319 panel HTML defaults role marker IMPLEMENTED_OR_PRESENT / OK ✅
319 panel HTML completion marker IMPLEMENTED_OR_PRESENT / OK ✅
319 doc has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
319 config has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
319 migration has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
319 runtime has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
319 test has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
319 JS has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
319 HTML has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
319 gofmt completed IMPLEMENTED_OR_PRESENT / OK ✅
319 go test businessonboarding status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
319 live onboarding html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
319 live onboarding runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
319 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
319 nginx loaded panel route exists IMPLEMENTED_OR_PRESENT / OK ✅
319 onboarding screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
319 onboarding screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
319 onboarding runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
319 onboarding runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
319 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
319 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
```
