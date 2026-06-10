# FAZ 7-R / 349 — Kullanıcı şifre / giriş akışı real implementation audit

Generated at: 20260511_061243

## Result

- PASS_COUNT=97
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_349_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_349_FINAL_STATUS=PASS
- FAZ_7R_350_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_349_KULLANICI_SIFRE_GIRIS_AKISI.md
- Config: configs/faz7r/faz_7r_349_kullanici_sifre_giris_akisi.v1.json
- Runtime: web/panel/assets/password-login/panel-password-login-runtime.js
- Password login HTML: web/panel/password-login/index.html
- Smoke fixture: tests/faz7r/faz_7r_349_kullanici_sifre_giris_akisi_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_349_kullanici_sifre_giris_akisi.sh
- Backup directory: backups/faz7r/faz_7r_349_kullanici_sifre_giris_akisi_20260511_061243

## Live URL

- https://panel.pix2pi.com.tr/password-login/

## Audit check log

```
349 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
349 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
349 config directory IMPLEMENTED_OR_PRESENT / OK ✅
349 password login repo directory IMPLEMENTED_OR_PRESENT / OK ✅
349 password login asset directory IMPLEMENTED_OR_PRESENT / OK ✅
349 script directory IMPLEMENTED_OR_PRESENT / OK ✅
349 test directory IMPLEMENTED_OR_PRESENT / OK ✅
349 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
349 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
349 config file IMPLEMENTED_OR_PRESENT / OK ✅
349 panel password login runtime file IMPLEMENTED_OR_PRESENT / OK ✅
349 panel password login html file IMPLEMENTED_OR_PRESENT / OK ✅
349 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
349 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
349 live password login html file IMPLEMENTED_OR_PRESENT / OK ✅
349 live password login runtime file IMPLEMENTED_OR_PRESENT / OK ✅
349 active panel nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
349 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
349 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
349 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
349 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
349 config password login path contract IMPLEMENTED_OR_PRESENT / OK ✅
349 config ready for step 350 IMPLEMENTED_OR_PRESENT / OK ✅
349 config auth scope header contract IMPLEMENTED_OR_PRESENT / OK ✅
349 active panel server_name route IMPLEMENTED_OR_PRESENT / OK ✅
349 active panel root route IMPLEMENTED_OR_PRESENT / OK ✅
349 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
349.14 auth scope headers function IMPLEMENTED_OR_PRESENT / OK ✅
349.14 auth scope validation IMPLEMENTED_OR_PRESENT / OK ✅
349.4 password policy function IMPLEMENTED_OR_PRESENT / OK ✅
349.5 password confirm validation function IMPLEMENTED_OR_PRESENT / OK ✅
349 auth snapshot function IMPLEMENTED_OR_PRESENT / OK ✅
349.3 password setup payload function IMPLEMENTED_OR_PRESENT / OK ✅
349.6 login preview payload function IMPLEMENTED_OR_PRESENT / OK ✅
349.7 JWT disabled guard function IMPLEMENTED_OR_PRESENT / OK ✅
349.15 runtime contract function IMPLEMENTED_OR_PRESENT / OK ✅
349 password persist disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
349.7 JWT issue disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
349.8 session create disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
349.10 MFA disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
349 ready for step 350 runtime IMPLEMENTED_OR_PRESENT / OK ✅
349 tenant header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
349 invite token header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
349 auth scope header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
349.1 password login app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
349.2 invite token user activation context marker IMPLEMENTED_OR_PRESENT / OK ✅
349.3 password setup form marker IMPLEMENTED_OR_PRESENT / OK ✅
349.4 password policy check marker IMPLEMENTED_OR_PRESENT / OK ✅
349.5 password confirm validation marker IMPLEMENTED_OR_PRESENT / OK ✅
349.6 first login form marker IMPLEMENTED_OR_PRESENT / OK ✅
349.7 JWT issuance disabled marker IMPLEMENTED_OR_PRESENT / OK ✅
349.7 JWT disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
349.8 session creation disabled marker IMPLEMENTED_OR_PRESENT / OK ✅
349.8 session disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
349.9 password reset placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
349.10 MFA OTP placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
349.10 MFA disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
349.11 login error state preview marker IMPLEMENTED_OR_PRESENT / OK ✅
349.12 first login handoff marker IMPLEMENTED_OR_PRESENT / OK ✅
349.12 ready for step 350 visible contract IMPLEMENTED_OR_PRESENT / OK ✅
349.13 auth audit timeline marker IMPLEMENTED_OR_PRESENT / OK ✅
349.14 scope guard marker IMPLEMENTED_OR_PRESENT / OK ✅
349.15 runtime contract marker IMPLEMENTED_OR_PRESENT / OK ✅
349.16 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
349.16 i18n title marker IMPLEMENTED_OR_PRESENT / OK ✅
349.17 SEO OpenGraph marker IMPLEMENTED_OR_PRESENT / OK ✅
349.17 OpenGraph title meta IMPLEMENTED_OR_PRESENT / OK ✅
349 live password login html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
349 live password login runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
349 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
349 nginx loaded panel route exists IMPLEMENTED_OR_PRESENT / OK ✅
349.18 password login screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
349.18 password login screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
349.18 password login screen smoke body is not market route IMPLEMENTED_OR_PRESENT / OK ✅
349.18 password login runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
349.18 password login runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
349.18 password login runtime smoke body is not market route IMPLEMENTED_OR_PRESENT / OK ✅
349 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
349 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
349.1 Şifre / giriş app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.2 Invite token / user activation context aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.3 Şifre kurulum formu aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.4 Şifre politika kontrolü aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.5 Şifre tekrar doğrulama aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.6 İlk giriş formu aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.7 JWT issuance disabled gate aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.8 Session creation disabled gate aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.9 Password reset placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.10 MFA / OTP placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.11 Login error state preview aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.12 First login handoff to panel access test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.13 Auth audit timeline aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.14 Tenant / user / auth scope guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.15 Auth runtime data contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.16 i18n-ready auth marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.17 SEO / OpenGraph auth placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
349.18 Kullanıcı şifre / giriş smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
