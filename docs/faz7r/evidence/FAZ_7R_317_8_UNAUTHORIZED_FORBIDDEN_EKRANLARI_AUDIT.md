# FAZ 7-R / 317.8 — Unauthorized / forbidden ekranları audit

Generated at: 20260511_073016

## Result

- PASS_COUNT=74
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_317_8_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_317_8_FINAL_STATUS=PASS
- FAZ_7R_317_9_READY=YES

## Live URLs

- https://panel.pix2pi.com.tr/unauthorized/
- https://panel.pix2pi.com.tr/forbidden/

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_317_8_UNAUTHORIZED_FORBIDDEN_EKRANLARI.md
- Config: configs/faz7r/faz_7r_317_8_unauthorized_forbidden_ekranlari.v1.json
- Migration: db/migrations/20260511_317_8_auth_access_denial_events.sql
- Runtime: internal/auth/accessdenial/access_denial.go
- Test: internal/auth/accessdenial/access_denial_test.go
- JS: web/panel/assets/access-denial/access-denial-runtime.js
- Unauthorized HTML: web/panel/unauthorized/index.html
- Forbidden HTML: web/panel/forbidden/index.html
- Audit script: scripts/faz7r/audit_faz_7r_317_8_unauthorized_forbidden_ekranlari.sh
- Backup: backups/faz7r/faz_7r_317_8_unauthorized_forbidden_ekranlari_20260511_073016

## Audit check log

```
317.8 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
317.8 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
317.8 config directory IMPLEMENTED_OR_PRESENT / OK ✅
317.8 migration directory IMPLEMENTED_OR_PRESENT / OK ✅
317.8 runtime directory IMPLEMENTED_OR_PRESENT / OK ✅
317.8 unauthorized web directory IMPLEMENTED_OR_PRESENT / OK ✅
317.8 forbidden web directory IMPLEMENTED_OR_PRESENT / OK ✅
317.8 access denial asset directory IMPLEMENTED_OR_PRESENT / OK ✅
317.8 script directory IMPLEMENTED_OR_PRESENT / OK ✅
317.8 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
317.8 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
317.8 config file IMPLEMENTED_OR_PRESENT / OK ✅
317.8 DB migration file IMPLEMENTED_OR_PRESENT / OK ✅
317.8 runtime file IMPLEMENTED_OR_PRESENT / OK ✅
317.8 test file IMPLEMENTED_OR_PRESENT / OK ✅
317.8 panel JS runtime file IMPLEMENTED_OR_PRESENT / OK ✅
317.8 unauthorized HTML file IMPLEMENTED_OR_PRESENT / OK ✅
317.8 forbidden HTML file IMPLEMENTED_OR_PRESENT / OK ✅
317.8 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
317.8 live unauthorized html file IMPLEMENTED_OR_PRESENT / OK ✅
317.8 live forbidden html file IMPLEMENTED_OR_PRESENT / OK ✅
317.8 live access denial runtime file IMPLEMENTED_OR_PRESENT / OK ✅
317.8 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
317.8 doc unauthorized scope IMPLEMENTED_OR_PRESENT / OK ✅
317.8 doc forbidden scope IMPLEMENTED_OR_PRESENT / OK ✅
317.8 doc audit event scope IMPLEMENTED_OR_PRESENT / OK ✅
317.8 config unauthorized to 401 IMPLEMENTED_OR_PRESENT / OK ✅
317.8 config forbidden to 403 IMPLEMENTED_OR_PRESENT / OK ✅
317.8 config event record IMPLEMENTED_OR_PRESENT / OK ✅
317.8 migration access denial events table IMPLEMENTED_OR_PRESENT / OK ✅
317.8 migration correlation required IMPLEMENTED_OR_PRESENT / OK ✅
317.8 migration code index IMPLEMENTED_OR_PRESENT / OK ✅
317.8 migration correlation index IMPLEMENTED_OR_PRESENT / OK ✅
317.8 runtime catalog function IMPLEMENTED_OR_PRESENT / OK ✅
317.8 runtime decision function IMPLEMENTED_OR_PRESENT / OK ✅
317.8 runtime HTTP writer IMPLEMENTED_OR_PRESENT / OK ✅
317.8 runtime error mapping IMPLEMENTED_OR_PRESENT / OK ✅
317.8 runtime catalog validation IMPLEMENTED_OR_PRESENT / OK ✅
317.8 runtime event record contract IMPLEMENTED_OR_PRESENT / OK ✅
317.8 runtime unauthorized screen IMPLEMENTED_OR_PRESENT / OK ✅
317.8 runtime forbidden screen IMPLEMENTED_OR_PRESENT / OK ✅
317.8 test catalog complete IMPLEMENTED_OR_PRESENT / OK ✅
317.8 test unauthorized decision IMPLEMENTED_OR_PRESENT / OK ✅
317.8 test forbidden decision IMPLEMENTED_OR_PRESENT / OK ✅
317.8 test error mappings IMPLEMENTED_OR_PRESENT / OK ✅
317.8 test HTTP writer IMPLEMENTED_OR_PRESENT / OK ✅
317.8 test locale fallback IMPLEMENTED_OR_PRESENT / OK ✅
317.8 panel runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 panel runtime screen function IMPLEMENTED_OR_PRESENT / OK ✅
317.8 unauthorized screen marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 forbidden screen marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 doc has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 config has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 migration has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 runtime has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 test has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 JS has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 unauthorized HTML has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 forbidden HTML has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 gofmt completed IMPLEMENTED_OR_PRESENT / OK ✅
317.8 go test accessdenial status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
317.8 live unauthorized html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
317.8 live forbidden html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
317.8 live access denial runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
317.8 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
317.8 nginx loaded panel route exists IMPLEMENTED_OR_PRESENT / OK ✅
317.8 unauthorized screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
317.8 unauthorized screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 forbidden screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
317.8 forbidden screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 access denial runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
317.8 access denial runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
317.8 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
317.8 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
```
