# FAZ 7-R / 348 — İlk işletme kullanıcı daveti real implementation audit

Generated at: 20260511_060840

## Result

- PASS_COUNT=96
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_348_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_348_FINAL_STATUS=PASS
- FAZ_7R_349_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_348_ILK_ISLETME_KULLANICI_DAVETI.md
- Config: configs/faz7r/faz_7r_348_ilk_isletme_kullanici_daveti.v1.json
- Runtime: web/panel/assets/user-invite/panel-user-invite-runtime.js
- User invite HTML: web/panel/user-invite/index.html
- Smoke fixture: tests/faz7r/faz_7r_348_ilk_isletme_kullanici_daveti_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_348_ilk_isletme_kullanici_daveti.sh
- Backup directory: backups/faz7r/faz_7r_348_ilk_isletme_kullanici_daveti_20260511_060840

## Live URL

- https://panel.pix2pi.com.tr/user-invite/

## Audit check log

```
348 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
348 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
348 config directory IMPLEMENTED_OR_PRESENT / OK ✅
348 user invite repo directory IMPLEMENTED_OR_PRESENT / OK ✅
348 user invite asset directory IMPLEMENTED_OR_PRESENT / OK ✅
348 script directory IMPLEMENTED_OR_PRESENT / OK ✅
348 test directory IMPLEMENTED_OR_PRESENT / OK ✅
348 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
348 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
348 config file IMPLEMENTED_OR_PRESENT / OK ✅
348 panel user invite runtime file IMPLEMENTED_OR_PRESENT / OK ✅
348 panel user invite html file IMPLEMENTED_OR_PRESENT / OK ✅
348 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
348 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
348 live user invite html file IMPLEMENTED_OR_PRESENT / OK ✅
348 live user invite runtime file IMPLEMENTED_OR_PRESENT / OK ✅
348 active panel nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
348 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
348 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
348 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
348 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
348 config user invite path contract IMPLEMENTED_OR_PRESENT / OK ✅
348 config ready for step 349 IMPLEMENTED_OR_PRESENT / OK ✅
348 config invite scope header contract IMPLEMENTED_OR_PRESENT / OK ✅
348 active panel server_name route IMPLEMENTED_OR_PRESENT / OK ✅
348 active panel root route IMPLEMENTED_OR_PRESENT / OK ✅
348 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
348 tenant invite scope headers function IMPLEMENTED_OR_PRESENT / OK ✅
348 invite scope validation IMPLEMENTED_OR_PRESENT / OK ✅
348 invite payload validation IMPLEMENTED_OR_PRESENT / OK ✅
348 invite snapshot function IMPLEMENTED_OR_PRESENT / OK ✅
348 invite draft payload function IMPLEMENTED_OR_PRESENT / OK ✅
348 duplicate invitation guard function IMPLEMENTED_OR_PRESENT / OK ✅
348 invite send disabled guard function IMPLEMENTED_OR_PRESENT / OK ✅
348.14 runtime contract function IMPLEMENTED_OR_PRESENT / OK ✅
348 real user create disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
348 invite token disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
348 email send disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
348 SMS send disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
348 password setup disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
348 ready for step 349 runtime IMPLEMENTED_OR_PRESENT / OK ✅
348 admin session header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
348 tenant header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
348 invite scope header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
348.1 first user invite app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
348.2 pilot tenant owner invite context marker IMPLEMENTED_OR_PRESENT / OK ✅
348.3 invite user identity form marker IMPLEMENTED_OR_PRESENT / OK ✅
348.4 owner admin role selection marker IMPLEMENTED_OR_PRESENT / OK ✅
348.5 tenant scope validation marker IMPLEMENTED_OR_PRESENT / OK ✅
348.6 email invite channel placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
348.7 SMS WhatsApp invite placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
348.8 invite token preview disabled marker IMPLEMENTED_OR_PRESENT / OK ✅
348.8 invite token disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
348.9 password setup flow handoff marker IMPLEMENTED_OR_PRESENT / OK ✅
348.9 handoff to step 349 visible contract IMPLEMENTED_OR_PRESENT / OK ✅
348.10 invite send disabled marker IMPLEMENTED_OR_PRESENT / OK ✅
348.10 email send disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
348.11 duplicate invitation guard marker IMPLEMENTED_OR_PRESENT / OK ✅
348.11 duplicate guard visible contract IMPLEMENTED_OR_PRESENT / OK ✅
348.12 invitation audit timeline marker IMPLEMENTED_OR_PRESENT / OK ✅
348.13 user activation status preview marker IMPLEMENTED_OR_PRESENT / OK ✅
348.14 runtime contract marker IMPLEMENTED_OR_PRESENT / OK ✅
348.14 ready for step 349 visible contract IMPLEMENTED_OR_PRESENT / OK ✅
348.15 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
348.15 i18n title marker IMPLEMENTED_OR_PRESENT / OK ✅
348.16 SEO OpenGraph marker IMPLEMENTED_OR_PRESENT / OK ✅
348.16 OpenGraph title meta IMPLEMENTED_OR_PRESENT / OK ✅
348 live user invite html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
348 live user invite runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
348 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
348 nginx loaded panel route exists IMPLEMENTED_OR_PRESENT / OK ✅
348.17 user invite screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
348.17 user invite screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
348.17 user invite screen smoke body is not market route IMPLEMENTED_OR_PRESENT / OK ✅
348.17 user invite runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
348.17 user invite runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
348.17 user invite runtime smoke body is not market route IMPLEMENTED_OR_PRESENT / OK ✅
348 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
348 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
348.1 İlk kullanıcı daveti app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.2 Pilot tenant / owner invite context aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.3 Davet edilecek kullanıcı kimlik formu aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.4 Owner admin rol seçimi aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.5 Tenant scope validation aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.6 E-posta davet kanalı placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.7 SMS / WhatsApp davet kanalı placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.8 Invite token preview disabled gate aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.9 Şifre kurulum akışı handoff aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.10 Davet gönder disabled guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.11 Duplicate invitation guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.12 Invitation audit timeline aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.13 User activation status preview aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.14 Invite runtime data contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.15 i18n-ready invite marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.16 SEO / OpenGraph invite placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
348.17 İlk kullanıcı daveti smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
