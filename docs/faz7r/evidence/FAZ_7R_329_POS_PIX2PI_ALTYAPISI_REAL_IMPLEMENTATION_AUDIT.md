# FAZ 7-R / 329 — pos.pix2pi.com.tr altyapısı real implementation audit

Generated at: 20260510_212046

## Result

- PASS_COUNT=70
- FAIL_COUNT=3
- WARN_COUNT=0
- REQUIRED_FAIL=3
- OPTIONAL_WARN=0
- FAZ_7R_329_REAL_IMPLEMENTATION_STATUS=FAIL
- FAZ_7R_329_FINAL_STATUS=FAIL
- FAZ_7R_330_READY=NO

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_329_POS_PIX2PI_ALTYAPISI.md
- Config: configs/faz7r/faz_7r_329_pos_pix2pi_altyapisi.v1.json
- POS HTML: web/pos/index.html
- POS health JSON: web/pos/health.json
- POS runtime: web/pos/assets/pos-shell-runtime.js
- Smoke fixture: tests/faz7r/faz_7r_329_pos_pix2pi_altyapisi_smoke_test.json
- Nginx route: infra/nginx/00_pix2pi_pos.conf
- Active Nginx route: /etc/nginx/conf.d/00_pix2pi_pos.conf
- Standalone audit script: scripts/faz7r/audit_faz_7r_329_pos_pix2pi_altyapisi.sh
- Backup directory: backups/faz7r/faz_7r_329_pos_pix2pi_altyapisi_20260510_212046

## Live paths

- /var/www/pix2pi/pos/index.html
- /var/www/pix2pi/pos/health.json
- /var/www/pix2pi/pos/assets/pos-shell-runtime.js

## SSL

- SSL_CERT=/etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem

## Audit check log

```
329 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
329 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
329 config directory IMPLEMENTED_OR_PRESENT / OK ✅
329 POS repo web directory IMPLEMENTED_OR_PRESENT / OK ✅
329 POS asset directory IMPLEMENTED_OR_PRESENT / OK ✅
329 script directory IMPLEMENTED_OR_PRESENT / OK ✅
329 test directory IMPLEMENTED_OR_PRESENT / OK ✅
329 infra nginx directory IMPLEMENTED_OR_PRESENT / OK ✅
329 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
329 live POS web root IMPLEMENTED_OR_PRESENT / OK ✅
329 live POS asset directory IMPLEMENTED_OR_PRESENT / OK ✅
329 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
329 config file IMPLEMENTED_OR_PRESENT / OK ✅
329 POS app shell html file IMPLEMENTED_OR_PRESENT / OK ✅
329 POS health json file IMPLEMENTED_OR_PRESENT / OK ✅
329 POS runtime file IMPLEMENTED_OR_PRESENT / OK ✅
329 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
329 repo nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
329 active nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
329 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
329 live POS html file IMPLEMENTED_OR_PRESENT / OK ✅
329 live POS health json file IMPLEMENTED_OR_PRESENT / OK ✅
329 live POS runtime file IMPLEMENTED_OR_PRESENT / OK ✅
329 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
329 POS health json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
329 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
329 documentation routing scope IMPLEMENTED_OR_PRESENT / OK ✅
329 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
329 config domain contract IMPLEMENTED_OR_PRESENT / OK ✅
329 config next step readiness contract IMPLEMENTED_OR_PRESENT / OK ✅
329.1 active POS server_name routing IMPLEMENTED_OR_PRESENT / OK ✅
329.2 active POS root standard IMPLEMENTED_OR_PRESENT / OK ✅
329.8 active POS health route IMPLEMENTED_OR_PRESENT / OK ✅
329.2 active POS SPA fallback IMPLEMENTED_OR_PRESENT / OK ✅
329.2 active POS surface header IMPLEMENTED_OR_PRESENT / OK ✅
329.3 POS app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
329.4 POS mobile-first marker IMPLEMENTED_OR_PRESENT / OK ✅
329.4 mobile viewport contract IMPLEMENTED_OR_PRESENT / OK ✅
329.5 POS PWA placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
329.7 POS tenant session placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
329.6 POS runtime contract marker IMPLEMENTED_OR_PRESENT / OK ✅
329.6 POS runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
329.6 boot POS shell function IMPLEMENTED_OR_PRESENT / OK ✅
329.6 cashier login disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
329.6 real sale disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
329.6 ready for step 330 runtime IMPLEMENTED_OR_PRESENT / OK ✅
329 live POS html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
329 live POS health json matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
329 live POS runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
329 active nginx route matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
329 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
329 nginx loaded POS route exists IMPLEMENTED_OR_PRESENT / OK ✅
329 nginx reload status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
329.9 POS home smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
329.9 POS home smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
329.9 POS home smoke body has marker REQUIRED_FAIL / FAIL ❌
329.8 POS health smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
329.8 POS health smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
329.8 POS health smoke body has marker REQUIRED_FAIL / FAIL ❌
329.9 POS runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
329.9 POS runtime smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
329.9 POS runtime smoke body has marker REQUIRED_FAIL / FAIL ❌
329 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
329 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
329.1 POS subdomain routing aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
329.2 POS Nginx route standard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
329.3 POS app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
329.4 POS mobile-first responsive shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
329.5 POS PWA manifest placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
329.6 POS runtime shell contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
329.7 POS tenant/session placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
329.8 POS health check aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
329.9 POS smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
