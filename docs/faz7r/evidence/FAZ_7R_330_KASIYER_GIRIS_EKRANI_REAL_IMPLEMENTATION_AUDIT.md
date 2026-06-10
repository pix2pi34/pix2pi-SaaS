# FAZ 7-R / 330 — Kasiyer giriş ekranı real implementation audit

Generated at: 20260510_212658

## Result

- PASS_COUNT=76
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_330_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_330_FINAL_STATUS=PASS
- FAZ_7R_331_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_330_KASIYER_GIRIS_EKRANI.md
- Config: configs/faz7r/faz_7r_330_kasiyer_giris_ekrani.v1.json
- Runtime: web/pos/assets/login/cashier-login-runtime.js
- Login HTML: web/pos/login/index.html
- Smoke fixture: tests/faz7r/faz_7r_330_kasiyer_giris_ekrani_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_330_kasiyer_giris_ekrani.sh
- Backup directory: backups/faz7r/faz_7r_330_kasiyer_giris_ekrani_20260510_212658

## Live paths

- /var/www/pix2pi/pos/login/index.html
- /var/www/pix2pi/pos/assets/login/cashier-login-runtime.js

## Audit check log

```
330 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
330 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
330 config directory IMPLEMENTED_OR_PRESENT / OK ✅
330 login repo directory IMPLEMENTED_OR_PRESENT / OK ✅
330 login asset directory IMPLEMENTED_OR_PRESENT / OK ✅
330 script directory IMPLEMENTED_OR_PRESENT / OK ✅
330 test directory IMPLEMENTED_OR_PRESENT / OK ✅
330 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
330 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
330 config file IMPLEMENTED_OR_PRESENT / OK ✅
330 cashier login runtime file IMPLEMENTED_OR_PRESENT / OK ✅
330 cashier login html file IMPLEMENTED_OR_PRESENT / OK ✅
330 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
330 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
330 live cashier login html file IMPLEMENTED_OR_PRESENT / OK ✅
330 live cashier login runtime file IMPLEMENTED_OR_PRESENT / OK ✅
330 active POS nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
330 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
330 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
330 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
330 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
330 config login path contract IMPLEMENTED_OR_PRESENT / OK ✅
330 config ready for step 331 IMPLEMENTED_OR_PRESENT / OK ✅
330 config device header contract IMPLEMENTED_OR_PRESENT / OK ✅
330 active POS server_name route IMPLEMENTED_OR_PRESENT / OK ✅
330 active POS root route IMPLEMENTED_OR_PRESENT / OK ✅
330 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
330.5 tenant/device headers function IMPLEMENTED_OR_PRESENT / OK ✅
330.7 login validation function IMPLEMENTED_OR_PRESENT / OK ✅
330.5 auth payload function IMPLEMENTED_OR_PRESENT / OK ✅
330.6 demo session builder IMPLEMENTED_OR_PRESENT / OK ✅
330.6 session storage function IMPLEMENTED_OR_PRESENT / OK ✅
330.6 session verify function IMPLEMENTED_OR_PRESENT / OK ✅
330 backend login disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
330 ready for step 331 runtime IMPLEMENTED_OR_PRESENT / OK ✅
330 tenant header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
330 device header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
330.1 cashier login app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
330.2 cashier code PIN form marker IMPLEMENTED_OR_PRESENT / OK ✅
330.2 cashier code input IMPLEMENTED_OR_PRESENT / OK ✅
330.2 PIN input IMPLEMENTED_OR_PRESENT / OK ✅
330.3 tenant context marker IMPLEMENTED_OR_PRESENT / OK ✅
330.4 device register marker IMPLEMENTED_OR_PRESENT / OK ✅
330.5 auth endpoint marker IMPLEMENTED_OR_PRESENT / OK ✅
330.5 auth endpoint visible contract IMPLEMENTED_OR_PRESENT / OK ✅
330.6 session storage marker IMPLEMENTED_OR_PRESENT / OK ✅
330.7 validation marker IMPLEMENTED_OR_PRESENT / OK ✅
330.8 error lockout marker IMPLEMENTED_OR_PRESENT / OK ✅
330.9 sale redirect marker IMPLEMENTED_OR_PRESENT / OK ✅
330.10 offline login policy marker IMPLEMENTED_OR_PRESENT / OK ✅
330.11 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
330.11 i18n title marker IMPLEMENTED_OR_PRESENT / OK ✅
330 live login html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
330 live login runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
330 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
330 nginx loaded POS route exists IMPLEMENTED_OR_PRESENT / OK ✅
330.12 cashier login screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
330.12 cashier login screen smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
330.12 cashier login screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
330.12 cashier login runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
330.12 cashier login runtime smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
330.12 cashier login runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
330 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
330 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
330.1 Kasiyer login app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
330.2 Kasiyer kodu / PIN formu aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
330.3 Tenant context göstergesi aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
330.4 Cihaz / kasa register placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
330.5 Auth endpoint contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
330.6 Session storage contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
330.7 Login validation contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
330.8 Hata / lockout mesajları aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
330.9 POS satış ekranına yönlendirme placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
330.10 Offline login policy placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
330.11 i18n-ready cashier login marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
330.12 Kasiyer login smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
