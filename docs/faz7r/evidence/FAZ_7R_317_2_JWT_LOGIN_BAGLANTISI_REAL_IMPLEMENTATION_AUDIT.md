# FAZ 7-R / 317.2 — JWT login bağlantısı gerçek implementasyon audit

Generated at: 20260511_071118

## Result

- PASS_COUNT=50
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_317_2_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_317_2_FINAL_STATUS=PASS
- FAZ_7R_317_3_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_317_2_JWT_LOGIN_BAGLANTISI_REAL_IMPLEMENTATION.md
- Config: configs/faz7r/faz_7r_317_2_jwt_login_baglantisi.v1.json
- Migration: db/migrations/20260511_317_2_auth_jwt_login.sql
- Runtime: internal/auth/jwtlogin/jwt_login.go
- Test: internal/auth/jwtlogin/jwt_login_test.go
- Audit script: scripts/faz7r/audit_faz_7r_317_2_jwt_login_baglantisi.sh
- Backup: backups/faz7r/faz_7r_317_2_jwt_login_baglantisi_real_implementation_20260511_071118

## Web URL

Bu iş web sayfası üretmez. URL yok.

## Audit check log

```
317.2 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
317.2 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
317.2 config directory IMPLEMENTED_OR_PRESENT / OK ✅
317.2 migration directory IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime directory IMPLEMENTED_OR_PRESENT / OK ✅
317.2 script directory IMPLEMENTED_OR_PRESENT / OK ✅
317.2 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
317.2 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
317.2 config file IMPLEMENTED_OR_PRESENT / OK ✅
317.2 DB migration file IMPLEMENTED_OR_PRESENT / OK ✅
317.2 JWT runtime file IMPLEMENTED_OR_PRESENT / OK ✅
317.2 JWT test file IMPLEMENTED_OR_PRESENT / OK ✅
317.2 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
317.2 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
317.2 doc JWT signing scope IMPLEMENTED_OR_PRESENT / OK ✅
317.2 doc tenant membership scope IMPLEMENTED_OR_PRESENT / OK ✅
317.2 doc real test rule IMPLEMENTED_OR_PRESENT / OK ✅
317.2 config HS256 contract IMPLEMENTED_OR_PRESENT / OK ✅
317.2 config login sessions contract IMPLEMENTED_OR_PRESENT / OK ✅
317.2 config membership contract IMPLEMENTED_OR_PRESENT / OK ✅
317.2 migration login sessions table IMPLEMENTED_OR_PRESENT / OK ✅
317.2 migration membership table IMPLEMENTED_OR_PRESENT / OK ✅
317.2 migration session unique IMPLEMENTED_OR_PRESENT / OK ✅
317.2 migration access token unique IMPLEMENTED_OR_PRESENT / OK ✅
317.2 migration refresh token unique IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime claims type IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime user store interface IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime password verifier interface IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime login function IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime sign function IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime verify function IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime tenant membership enforcement IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime session record contract IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime invalid credentials error IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime tenant forbidden error IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime expired token error IMPLEMENTED_OR_PRESENT / OK ✅
317.2 test login issues and verifies JWT IMPLEMENTED_OR_PRESENT / OK ✅
317.2 test wrong password rejection IMPLEMENTED_OR_PRESENT / OK ✅
317.2 test tenant membership rejection IMPLEMENTED_OR_PRESENT / OK ✅
317.2 test expired token rejection IMPLEMENTED_OR_PRESENT / OK ✅
317.2 test tampered token rejection IMPLEMENTED_OR_PRESENT / OK ✅
317.2 doc has no forbidden partial marker IMPLEMENTED_OR_PRESENT / OK ✅
317.2 config has no forbidden partial marker IMPLEMENTED_OR_PRESENT / OK ✅
317.2 migration has no forbidden partial marker IMPLEMENTED_OR_PRESENT / OK ✅
317.2 runtime has no forbidden partial marker IMPLEMENTED_OR_PRESENT / OK ✅
317.2 test has no forbidden partial marker IMPLEMENTED_OR_PRESENT / OK ✅
317.2 gofmt completed IMPLEMENTED_OR_PRESENT / OK ✅
317.2 go test jwtlogin status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
317.2 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
317.2 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
```
