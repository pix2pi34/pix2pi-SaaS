# FAZ 7-R / 353 — Kullanıcı yetki kontrolü real implementation audit

Generated at: 20260511_062535

## Result

- PASS_COUNT=91
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_353_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_353_FINAL_STATUS=PASS
- FAZ_7R_354_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_353_KULLANICI_YETKI_KONTROLU.md
- Config: configs/faz7r/faz_7r_353_kullanici_yetki_kontrolu.v1.json
- Runtime: web/panel/assets/user-permission-check/user-permission-check-runtime.js
- User permission HTML: web/panel/user-permission-check/index.html
- Smoke fixture: tests/faz7r/faz_7r_353_kullanici_yetki_kontrolu_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_353_kullanici_yetki_kontrolu.sh
- Backup directory: backups/faz7r/faz_7r_353_kullanici_yetki_kontrolu_20260511_062535

## Live URL

- https://panel.pix2pi.com.tr/user-permission-check/

## Audit check log

```
353 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
353 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
353 config directory IMPLEMENTED_OR_PRESENT / OK ✅
353 user permission repo directory IMPLEMENTED_OR_PRESENT / OK ✅
353 user permission asset directory IMPLEMENTED_OR_PRESENT / OK ✅
353 script directory IMPLEMENTED_OR_PRESENT / OK ✅
353 test directory IMPLEMENTED_OR_PRESENT / OK ✅
353 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
353 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
353 config file IMPLEMENTED_OR_PRESENT / OK ✅
353 user permission runtime file IMPLEMENTED_OR_PRESENT / OK ✅
353 user permission html file IMPLEMENTED_OR_PRESENT / OK ✅
353 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
353 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
353 live user permission html file IMPLEMENTED_OR_PRESENT / OK ✅
353 live user permission runtime file IMPLEMENTED_OR_PRESENT / OK ✅
353 active panel nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
353 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
353 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
353 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
353 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
353 config user permission path contract IMPLEMENTED_OR_PRESENT / OK ✅
353 config ready for step 354 IMPLEMENTED_OR_PRESENT / OK ✅
353 config permission scope header contract IMPLEMENTED_OR_PRESENT / OK ✅
353 active panel server_name route IMPLEMENTED_OR_PRESENT / OK ✅
353 active panel root route IMPLEMENTED_OR_PRESENT / OK ✅
353 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
353.14 permission scope headers function IMPLEMENTED_OR_PRESENT / OK ✅
353 permission scope validation function IMPLEMENTED_OR_PRESENT / OK ✅
353 permission snapshot function IMPLEMENTED_OR_PRESENT / OK ✅
353.4 permission decision function IMPLEMENTED_OR_PRESENT / OK ✅
353.9 admin-only disabled gate function IMPLEMENTED_OR_PRESENT / OK ✅
353.10 deny-by-default function IMPLEMENTED_OR_PRESENT / OK ✅
353.15 runtime contract function IMPLEMENTED_OR_PRESENT / OK ✅
353 RBAC backend disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
353 role mutation disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
353 admin override disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
353 ready for step 354 runtime IMPLEMENTED_OR_PRESENT / OK ✅
353.1 user permission app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
353.2 tenant user role session context marker IMPLEMENTED_OR_PRESENT / OK ✅
353.3 role permission matrix marker IMPLEMENTED_OR_PRESENT / OK ✅
353.4 permission decision contract marker IMPLEMENTED_OR_PRESENT / OK ✅
353.4 permission decision visible contract IMPLEMENTED_OR_PRESENT / OK ✅
353.5 panel route permission checks marker IMPLEMENTED_OR_PRESENT / OK ✅
353.6 POS action permission checks marker IMPLEMENTED_OR_PRESENT / OK ✅
353.7 marketplace action permission checks marker IMPLEMENTED_OR_PRESENT / OK ✅
353.8 commercial billing permission checks marker IMPLEMENTED_OR_PRESENT / OK ✅
353.9 admin-only disabled marker IMPLEMENTED_OR_PRESENT / OK ✅
353.9 admin override disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
353.10 deny-by-default marker IMPLEMENTED_OR_PRESENT / OK ✅
353.10 deny-by-default visible contract IMPLEMENTED_OR_PRESENT / OK ✅
353.11 role switch regression marker IMPLEMENTED_OR_PRESENT / OK ✅
353.12 unauthorized forbidden preview marker IMPLEMENTED_OR_PRESENT / OK ✅
353.13 permission audit timeline marker IMPLEMENTED_OR_PRESENT / OK ✅
353.14 action scope guard marker IMPLEMENTED_OR_PRESENT / OK ✅
353.15 runtime contract marker IMPLEMENTED_OR_PRESENT / OK ✅
353.15 ready for step 354 visible contract IMPLEMENTED_OR_PRESENT / OK ✅
353.16 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
353.16 i18n title marker IMPLEMENTED_OR_PRESENT / OK ✅
353.17 SEO OpenGraph marker IMPLEMENTED_OR_PRESENT / OK ✅
353.17 OpenGraph title meta IMPLEMENTED_OR_PRESENT / OK ✅
353 live user permission html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
353 live user permission runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
353 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
353 nginx loaded panel route exists IMPLEMENTED_OR_PRESENT / OK ✅
353.18 user permission screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
353.18 user permission screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
353.18 user permission screen smoke body is not POS/market route IMPLEMENTED_OR_PRESENT / OK ✅
353.18 user permission runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
353.18 user permission runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
353.18 user permission runtime smoke body is not POS/market route IMPLEMENTED_OR_PRESENT / OK ✅
353 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
353 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
353.1 User permission check app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.2 Tenant / user / role / session context aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.3 Role permission matrix preview aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.4 Permission decision contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.5 Panel route permission checks aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.6 POS action permission checks aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.7 Marketplace action permission checks aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.8 Commercial / billing permission checks aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.9 Admin-only action disabled gate aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.10 Least privilege / deny-by-default preview aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.11 Role switch regression preview aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.12 Unauthorized / forbidden permission state preview aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.13 Permission audit timeline aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.14 Tenant / user / role / action scope guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.15 Permission runtime data contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.16 i18n-ready permission marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.17 SEO / OpenGraph permission placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
353.18 Kullanıcı yetki kontrolü smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
