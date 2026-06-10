# FAZ 7-R / 347 — Pilot müşteri tenant açılışı gerçek provisioning audit

Generated at: 20260511_075200

## Result

- PASS_COUNT=75
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_347_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_347_FINAL_STATUS=PASS
- FAZ_7R_348_READY=YES

## Live URL

- https://panel.pix2pi.com.tr/pilot-tenant-opening/

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_347_PILOT_MUSTERI_TENANT_ACILISI_GERCEK_PROVISIONING.md
- Config: configs/faz7r/faz_7r_347_pilot_tenant_opening.v1.json
- Migration: db/migrations/20260511_347_pilot_tenant_opening_real_provisioning.sql
- Runtime: internal/onboarding/pilottenantopening/pilot_tenant_opening.go
- Test: internal/onboarding/pilottenantopening/pilot_tenant_opening_test.go
- JS: web/panel/assets/pilot-tenant-opening/pilot-tenant-opening-runtime.js
- HTML: web/panel/pilot-tenant-opening/index.html
- Audit script: scripts/faz7r/audit_faz_7r_347_pilot_tenant_opening.sh
- Backup: backups/faz7r/faz_7r_347_pilot_musteri_tenant_acilisi_gercek_provisioning_20260511_075200

## Audit check log

```
347 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
347 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
347 config directory IMPLEMENTED_OR_PRESENT / OK ✅
347 migration directory IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime directory IMPLEMENTED_OR_PRESENT / OK ✅
347 pilot tenant opening web directory IMPLEMENTED_OR_PRESENT / OK ✅
347 pilot tenant opening asset directory IMPLEMENTED_OR_PRESENT / OK ✅
347 script directory IMPLEMENTED_OR_PRESENT / OK ✅
347 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
347 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
347 config file IMPLEMENTED_OR_PRESENT / OK ✅
347 DB migration file IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime file IMPLEMENTED_OR_PRESENT / OK ✅
347 test file IMPLEMENTED_OR_PRESENT / OK ✅
347 panel JS runtime file IMPLEMENTED_OR_PRESENT / OK ✅
347 panel HTML file IMPLEMENTED_OR_PRESENT / OK ✅
347 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
347 live pilot tenant opening html file IMPLEMENTED_OR_PRESENT / OK ✅
347 live pilot tenant opening runtime file IMPLEMENTED_OR_PRESENT / OK ✅
347 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
347 doc tenant config scope IMPLEMENTED_OR_PRESENT / OK ✅
347 doc default language scope IMPLEMENTED_OR_PRESENT / OK ✅
347 doc branch scope IMPLEMENTED_OR_PRESENT / OK ✅
347 config tenant config IMPLEMENTED_OR_PRESENT / OK ✅
347 config tr-TR language IMPLEMENTED_OR_PRESENT / OK ✅
347 config plan binding IMPLEMENTED_OR_PRESENT / OK ✅
347 config register created IMPLEMENTED_OR_PRESENT / OK ✅
347 migration opening runs IMPLEMENTED_OR_PRESENT / OK ✅
347 migration audit events IMPLEMENTED_OR_PRESENT / OK ✅
347 migration tenant configs IMPLEMENTED_OR_PRESENT / OK ✅
347 migration plan bindings IMPLEMENTED_OR_PRESENT / OK ✅
347 migration POS registers IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime provision function IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime HTTP provision IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime register code IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime owner membership IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime tenant config creation IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime plan binding IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime branch creation IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime register creation IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime opening run IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime audit event IMPLEMENTED_OR_PRESENT / OK ✅
347 test creates opening records IMPLEMENTED_OR_PRESENT / OK ✅
347 test missing tenant owner IMPLEMENTED_OR_PRESENT / OK ✅
347 test tr-TR language IMPLEMENTED_OR_PRESENT / OK ✅
347 test missing plan branch register IMPLEMENTED_OR_PRESENT / OK ✅
347 test owner membership IMPLEMENTED_OR_PRESENT / OK ✅
347 test register code IMPLEMENTED_OR_PRESENT / OK ✅
347 test HTTP provision IMPLEMENTED_OR_PRESENT / OK ✅
347 panel JS runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
347 panel JS submit function IMPLEMENTED_OR_PRESENT / OK ✅
347 panel HTML screen marker IMPLEMENTED_OR_PRESENT / OK ✅
347 panel HTML tenant config marker IMPLEMENTED_OR_PRESENT / OK ✅
347 panel HTML defaults marker IMPLEMENTED_OR_PRESENT / OK ✅
347 panel HTML branch register marker IMPLEMENTED_OR_PRESENT / OK ✅
347 panel HTML completion marker IMPLEMENTED_OR_PRESENT / OK ✅
347 doc has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
347 config has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
347 migration has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
347 runtime has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
347 test has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
347 JS has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
347 HTML has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
347 gofmt completed IMPLEMENTED_OR_PRESENT / OK ✅
347 go test pilottenantopening status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
347 live pilot tenant opening html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
347 live pilot tenant opening runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
347 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
347 nginx loaded panel route exists IMPLEMENTED_OR_PRESENT / OK ✅
347 pilot tenant opening screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
347 pilot tenant opening screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
347 pilot tenant opening runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
347 pilot tenant opening runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
347 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
347 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
```
