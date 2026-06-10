# FAZ 7-R / 316 FIX V2 — panel.pix2pi.com.tr altyapısı real implementation audit

Generated at: 20260510_192253

## Result

- PASS_COUNT=40
- FAIL_COUNT=15
- WARN_COUNT=0
- REQUIRED_FAIL=15
- OPTIONAL_WARN=0
- FAZ_7R_316_FIX_V2_REAL_IMPLEMENTATION_STATUS=FAIL
- FAZ_7R_316_FINAL_STATUS=FAIL
- FAZ_7R_317_READY=NO

## Active route

- PANEL_DOMAIN=panel.pix2pi.com.tr
- PANEL_ACTIVE_COUNT=1
- NGINX_TARGET=/etc/nginx/conf.d/00_pix2pi_panel.conf
- PANEL_WEB_ROOT=/var/www/pix2pi/panel

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_316_PANEL_PIX2PI_ALTYAPISI.md
- Config: configs/faz7r/faz_7r_316_panel_pix2pi_altyapisi.v1.json
- Panel HTML: web/panel/index.html
- Panel health JSON: web/panel/health.json
- Smoke fixture: tests/faz7r/faz_7r_316_panel_smoke_test.json
- Nginx repo route: infra/nginx/00_pix2pi_panel.conf
- Nginx target route: /etc/nginx/conf.d/00_pix2pi_panel.conf
- Standalone audit script: scripts/faz7r/audit_faz_7r_316_panel_pix2pi_altyapisi.sh
- Backup directory: backups/faz7r/faz_7r_316_fix_v2_panel_route_smoke_20260510_192253

## Audit check log

```
316 FIX V2 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
316 FIX V2 live panel web root IMPLEMENTED_OR_PRESENT / OK ✅
316 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
316 config file IMPLEMENTED_OR_PRESENT / OK ✅
316 repo panel html file IMPLEMENTED_OR_PRESENT / OK ✅
316 repo health json file IMPLEMENTED_OR_PRESENT / OK ✅
316 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
316 repo nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
316 active nginx target route file IMPLEMENTED_OR_PRESENT / OK ✅
316 live panel html file IMPLEMENTED_OR_PRESENT / OK ✅
316 live health json file IMPLEMENTED_OR_PRESENT / OK ✅
316 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
316 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
316 health json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
316 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
316.1 active panel server_name routing IMPLEMENTED_OR_PRESENT / OK ✅
316.2 active nginx root standard IMPLEMENTED_OR_PRESENT / OK ✅
316.8 active nginx health route IMPLEMENTED_OR_PRESENT / OK ✅
316.2 active nginx SPA fallback IMPLEMENTED_OR_PRESENT / OK ✅
316.2 active nginx surface header IMPLEMENTED_OR_PRESENT / OK ✅
316.3 panel app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
316.4 sidebar marker IMPLEMENTED_OR_PRESENT / OK ✅
316.4 topbar marker IMPLEMENTED_OR_PRESENT / OK ✅
316.5 breadcrumb marker IMPLEMENTED_OR_PRESENT / OK ✅
316.6 tenant indicator marker IMPLEMENTED_OR_PRESENT / OK ✅
316.7 responsive shell marker IMPLEMENTED_OR_PRESENT / OK ✅
316.8 health client marker IMPLEMENTED_OR_PRESENT / OK ✅
316 panel title contract IMPLEMENTED_OR_PRESENT / OK ✅
316 responsive viewport contract IMPLEMENTED_OR_PRESENT / OK ✅
316 live panel html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
316 live health json matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
316 active nginx target matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
316 duplicate nginx panel route guard has single active route IMPLEMENTED_OR_PRESENT / OK ✅
316 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
316 nginx reload status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
316.9 panel health smoke returned HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
316.9 panel health body has status ok REQUIRED_FAIL / FAIL ❌
HEALTH_BODY=<html>
<head><title>301 Moved Permanently</title></head>
<body>
<center><h1>301 Moved Permanently</h1></center>
<hr><center>nginx/1.18.0 (Ubuntu)</center>
</body>
</html>
316.9 panel health body has surface panel REQUIRED_FAIL / FAIL ❌
316.9 panel health body has pix2pi-panel service REQUIRED_FAIL / FAIL ❌
316.9 panel health body has step 316 REQUIRED_FAIL / FAIL ❌
316.9 panel index smoke returned HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
316.9 panel index body has title REQUIRED_FAIL / FAIL ❌
INDEX_BODY_HEAD=<html>
<head><title>301 Moved Permanently</title></head>
<body>
<center><h1>301 Moved Permanently</h1></center>
<hr><center>nginx/1.18.0 (Ubuntu)</center>
</body>
</html>
316.9 panel index body has app shell marker REQUIRED_FAIL / FAIL ❌
316.9 panel index body has tenant indicator REQUIRED_FAIL / FAIL ❌
316 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
316 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
316.1 Panel subdomain routing aggregate gate REQUIRED_FAIL / FAIL ❌
316.2 Nginx route standard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
316.3 Panel app shell aggregate gate REQUIRED_FAIL / FAIL ❌
316.4 Sidebar / topbar aggregate gate REQUIRED_FAIL / FAIL ❌
316.5 Breadcrumb aggregate gate REQUIRED_FAIL / FAIL ❌
316.6 Tenant indicator aggregate gate REQUIRED_FAIL / FAIL ❌
316.7 Responsive shell aggregate gate REQUIRED_FAIL / FAIL ❌
316.8 Panel health check aggregate gate REQUIRED_FAIL / FAIL ❌
316.9 Panel smoke test aggregate gate REQUIRED_FAIL / FAIL ❌
```
