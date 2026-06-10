# FAZ 7-R / 317.7 — Login error messages gerçek hata mesajları audit

Generated at: 20260511_072806

## Result

- PASS_COUNT=49
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_317_7_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_317_7_FINAL_STATUS=PASS
- FAZ_7R_317_8_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_317_7_LOGIN_ERROR_MESSAGES_GERCEK_HATA_MESAJLARI.md
- Config: configs/faz7r/faz_7r_317_7_login_error_messages.v1.json
- Migration: db/migrations/20260511_317_7_auth_login_error_events.sql
- Runtime: internal/auth/loginerrors/login_errors.go
- Test: internal/auth/loginerrors/login_errors_test.go
- Audit script: scripts/faz7r/audit_faz_7r_317_7_login_error_messages.sh
- Backup: backups/faz7r/faz_7r_317_7_login_error_messages_gercek_hata_mesajlari_20260511_072806

## Web URL

Bu iş yeni web sayfası üretmez. Mevcut login ekranı: https://panel.pix2pi.com.tr/login/

## Audit check log

```
317.7 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
317.7 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
317.7 config directory IMPLEMENTED_OR_PRESENT / OK ✅
317.7 migration directory IMPLEMENTED_OR_PRESENT / OK ✅
317.7 runtime directory IMPLEMENTED_OR_PRESENT / OK ✅
317.7 script directory IMPLEMENTED_OR_PRESENT / OK ✅
317.7 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
317.7 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
317.7 config file IMPLEMENTED_OR_PRESENT / OK ✅
317.7 DB migration file IMPLEMENTED_OR_PRESENT / OK ✅
317.7 runtime file IMPLEMENTED_OR_PRESENT / OK ✅
317.7 test file IMPLEMENTED_OR_PRESENT / OK ✅
317.7 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
317.7 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
317.7 doc error catalog scope IMPLEMENTED_OR_PRESENT / OK ✅
317.7 doc localized message scope IMPLEMENTED_OR_PRESENT / OK ✅
317.7 doc safe message rule IMPLEMENTED_OR_PRESENT / OK ✅
317.7 config standard error codes IMPLEMENTED_OR_PRESENT / OK ✅
317.7 config Turkish messages IMPLEMENTED_OR_PRESENT / OK ✅
317.7 config English messages IMPLEMENTED_OR_PRESENT / OK ✅
317.7 config safe internal error rule IMPLEMENTED_OR_PRESENT / OK ✅
317.7 migration login error events table IMPLEMENTED_OR_PRESENT / OK ✅
317.7 migration correlation required IMPLEMENTED_OR_PRESENT / OK ✅
317.7 migration code index IMPLEMENTED_OR_PRESENT / OK ✅
317.7 migration correlation index IMPLEMENTED_OR_PRESENT / OK ✅
317.7 runtime catalog function IMPLEMENTED_OR_PRESENT / OK ✅
317.7 runtime build public error IMPLEMENTED_OR_PRESENT / OK ✅
317.7 runtime HTTP writer IMPLEMENTED_OR_PRESENT / OK ✅
317.7 runtime error mapping IMPLEMENTED_OR_PRESENT / OK ✅
317.7 runtime catalog validation IMPLEMENTED_OR_PRESENT / OK ✅
317.7 runtime event record contract IMPLEMENTED_OR_PRESENT / OK ✅
317.7 runtime invalid credential code IMPLEMENTED_OR_PRESENT / OK ✅
317.7 runtime tenant access code IMPLEMENTED_OR_PRESENT / OK ✅
317.7 runtime session error code IMPLEMENTED_OR_PRESENT / OK ✅
317.7 test catalog complete IMPLEMENTED_OR_PRESENT / OK ✅
317.7 test error mappings IMPLEMENTED_OR_PRESENT / OK ✅
317.7 test localized safe message and event IMPLEMENTED_OR_PRESENT / OK ✅
317.7 test internal detail safety IMPLEMENTED_OR_PRESENT / OK ✅
317.7 test locale fallback IMPLEMENTED_OR_PRESENT / OK ✅
317.7 test HTTP writer IMPLEMENTED_OR_PRESENT / OK ✅
317.7 doc has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.7 config has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.7 migration has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.7 runtime has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.7 test has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.7 gofmt completed IMPLEMENTED_OR_PRESENT / OK ✅
317.7 go test loginerrors status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
317.7 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
317.7 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
```
