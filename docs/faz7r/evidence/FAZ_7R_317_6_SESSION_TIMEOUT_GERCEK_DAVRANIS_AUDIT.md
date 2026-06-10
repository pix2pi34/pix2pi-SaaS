# FAZ 7-R / 317.6 — Session timeout gerçek davranış audit

Generated at: 20260511_072628

## Result

- PASS_COUNT=50
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_317_6_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_317_6_FINAL_STATUS=PASS
- FAZ_7R_317_7_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_317_6_SESSION_TIMEOUT_GERCEK_DAVRANIS.md
- Config: configs/faz7r/faz_7r_317_6_session_timeout.v1.json
- Migration: db/migrations/20260511_317_6_auth_session_timeout.sql
- Runtime: internal/auth/sessiontimeout/session_timeout.go
- Test: internal/auth/sessiontimeout/session_timeout_test.go
- Audit script: scripts/faz7r/audit_faz_7r_317_6_session_timeout.sh
- Backup: backups/faz7r/faz_7r_317_6_session_timeout_gercek_davranis_20260511_072628

## Web URL

Bu iş web sayfası üretmez. URL yok.

## Audit check log

```
317.6 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
317.6 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
317.6 config directory IMPLEMENTED_OR_PRESENT / OK ✅
317.6 migration directory IMPLEMENTED_OR_PRESENT / OK ✅
317.6 runtime directory IMPLEMENTED_OR_PRESENT / OK ✅
317.6 script directory IMPLEMENTED_OR_PRESENT / OK ✅
317.6 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
317.6 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
317.6 config file IMPLEMENTED_OR_PRESENT / OK ✅
317.6 DB migration file IMPLEMENTED_OR_PRESENT / OK ✅
317.6 runtime file IMPLEMENTED_OR_PRESENT / OK ✅
317.6 test file IMPLEMENTED_OR_PRESENT / OK ✅
317.6 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
317.6 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
317.6 doc access expiry scope IMPLEMENTED_OR_PRESENT / OK ✅
317.6 doc idle timeout scope IMPLEMENTED_OR_PRESENT / OK ✅
317.6 doc absolute timeout scope IMPLEMENTED_OR_PRESENT / OK ✅
317.6 config access expiry validation IMPLEMENTED_OR_PRESENT / OK ✅
317.6 config idle timeout validation IMPLEMENTED_OR_PRESENT / OK ✅
317.6 config absolute timeout validation IMPLEMENTED_OR_PRESENT / OK ✅
317.6 config logout revoke IMPLEMENTED_OR_PRESENT / OK ✅
317.6 migration session timeout events table IMPLEMENTED_OR_PRESENT / OK ✅
317.6 migration last seen column IMPLEMENTED_OR_PRESENT / OK ✅
317.6 migration last seen index IMPLEMENTED_OR_PRESENT / OK ✅
317.6 migration revoked index IMPLEMENTED_OR_PRESENT / OK ✅
317.6 runtime validate session function IMPLEMENTED_OR_PRESENT / OK ✅
317.6 runtime logout function IMPLEMENTED_OR_PRESENT / OK ✅
317.6 runtime HTTP validate handler IMPLEMENTED_OR_PRESENT / OK ✅
317.6 runtime HTTP logout handler IMPLEMENTED_OR_PRESENT / OK ✅
317.6 runtime idle timeout error IMPLEMENTED_OR_PRESENT / OK ✅
317.6 runtime absolute timeout error IMPLEMENTED_OR_PRESENT / OK ✅
317.6 runtime event recording contract IMPLEMENTED_OR_PRESENT / OK ✅
317.6 test active session validation IMPLEMENTED_OR_PRESENT / OK ✅
317.6 test expired access token IMPLEMENTED_OR_PRESENT / OK ✅
317.6 test expired refresh token IMPLEMENTED_OR_PRESENT / OK ✅
317.6 test idle timeout IMPLEMENTED_OR_PRESENT / OK ✅
317.6 test absolute timeout IMPLEMENTED_OR_PRESENT / OK ✅
317.6 test revoked session IMPLEMENTED_OR_PRESENT / OK ✅
317.6 test logout revoke IMPLEMENTED_OR_PRESENT / OK ✅
317.6 test HTTP validate IMPLEMENTED_OR_PRESENT / OK ✅
317.6 test HTTP logout IMPLEMENTED_OR_PRESENT / OK ✅
317.6 doc has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.6 config has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.6 migration has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.6 runtime has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.6 test has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
317.6 gofmt completed IMPLEMENTED_OR_PRESENT / OK ✅
317.6 go test sessiontimeout status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
317.6 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
317.6 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
```
