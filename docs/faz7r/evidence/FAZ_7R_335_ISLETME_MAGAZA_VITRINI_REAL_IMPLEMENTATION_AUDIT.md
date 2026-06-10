# FAZ 7-R / 335 — İşletme mağaza vitrini real implementation audit

Generated at: 20260510_215704

## Result

- PASS_COUNT=97
- FAIL_COUNT=4
- WARN_COUNT=0
- REQUIRED_FAIL=4
- OPTIONAL_WARN=0
- FAZ_7R_335_REAL_IMPLEMENTATION_STATUS=FAIL
- FAZ_7R_335_FINAL_STATUS=FAIL
- FAZ_7R_336_READY=NO

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_335_ISLETME_MAGAZA_VITRINI.md
- Config: configs/faz7r/faz_7r_335_isletme_magaza_vitrini.v1.json
- Runtime: web/market/assets/storefront/market-storefront-runtime.js
- Storefront HTML: web/market/storefront/index.html
- Health JSON: web/market/health.json
- Nginx route: infra/nginx/00_pix2pi_market.conf
- Active Nginx route: /etc/nginx/conf.d/00_pix2pi_market.conf
- Smoke fixture: tests/faz7r/faz_7r_335_isletme_magaza_vitrini_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_335_isletme_magaza_vitrini.sh
- Backup directory: backups/faz7r/faz_7r_335_isletme_magaza_vitrini_20260510_215704

## Live paths

- /var/www/pix2pi/market/storefront/index.html
- /var/www/pix2pi/market/assets/storefront/market-storefront-runtime.js
- /var/www/pix2pi/market/health.json

## Public local-route contract

- http://market.pix2pi.com.tr/storefront/
- http://market.pix2pi.com.tr/health

## Audit check log

```
335 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
335 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
335 config directory IMPLEMENTED_OR_PRESENT / OK ✅
335 storefront repo directory IMPLEMENTED_OR_PRESENT / OK ✅
335 storefront asset directory IMPLEMENTED_OR_PRESENT / OK ✅
335 script directory IMPLEMENTED_OR_PRESENT / OK ✅
335 test directory IMPLEMENTED_OR_PRESENT / OK ✅
335 infra nginx directory IMPLEMENTED_OR_PRESENT / OK ✅
335 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
335 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
335 config file IMPLEMENTED_OR_PRESENT / OK ✅
335 market storefront runtime file IMPLEMENTED_OR_PRESENT / OK ✅
335 market storefront html file IMPLEMENTED_OR_PRESENT / OK ✅
335 market health json file IMPLEMENTED_OR_PRESENT / OK ✅
335 repo nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
335 active nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
335 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
335 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
335 live storefront html file IMPLEMENTED_OR_PRESENT / OK ✅
335 live storefront runtime file IMPLEMENTED_OR_PRESENT / OK ✅
335 live market health json file IMPLEMENTED_OR_PRESENT / OK ✅
335 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
335 repo market health json syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
335 live market health json syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
335 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
335 repo market health semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
335 live market health semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
335 documentation route scope IMPLEMENTED_OR_PRESENT / OK ✅
335 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
335 config storefront path contract IMPLEMENTED_OR_PRESENT / OK ✅
335 config ready for step 336 IMPLEMENTED_OR_PRESENT / OK ✅
335 config store slug header contract IMPLEMENTED_OR_PRESENT / OK ✅
335.1 active market server_name route IMPLEMENTED_OR_PRESENT / OK ✅
335.1 active market root route IMPLEMENTED_OR_PRESENT / OK ✅
335 active route marker IMPLEMENTED_OR_PRESENT / OK ✅
335 health route IMPLEMENTED_OR_PRESENT / OK ✅
335 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
335.9 tenant/store headers function IMPLEMENTED_OR_PRESENT / OK ✅
335.9 storefront scope validation function IMPLEMENTED_OR_PRESENT / OK ✅
335.10 fetch storefront snapshot function IMPLEMENTED_OR_PRESENT / OK ✅
335.10 storefront snapshot contract function IMPLEMENTED_OR_PRESENT / OK ✅
335.6 product card data function IMPLEMENTED_OR_PRESENT / OK ✅
335.3 business hero render function IMPLEMENTED_OR_PRESENT / OK ✅
335.4 store status render function IMPLEMENTED_OR_PRESENT / OK ✅
335.5 category render function IMPLEMENTED_OR_PRESENT / OK ✅
335.6 products render function IMPLEMENTED_OR_PRESENT / OK ✅
335.7 fulfillment render function IMPLEMENTED_OR_PRESENT / OK ✅
335.8 campaign render function IMPLEMENTED_OR_PRESENT / OK ✅
335.12 SEO render function IMPLEMENTED_OR_PRESENT / OK ✅
335 real order disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
335 real payment disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
335 stock reservation disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
335 ready for step 336 runtime IMPLEMENTED_OR_PRESENT / OK ✅
335 tenant header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
335 store slug header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
335.2 storefront app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
335.3 business profile hero marker IMPLEMENTED_OR_PRESENT / OK ✅
335.4 store status marker IMPLEMENTED_OR_PRESENT / OK ✅
335.5 category preview marker IMPLEMENTED_OR_PRESENT / OK ✅
335.6 featured product grid marker IMPLEMENTED_OR_PRESENT / OK ✅
335.7 delivery pickup placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
335.8 campaign banner marker IMPLEMENTED_OR_PRESENT / OK ✅
335.9 tenant store slug guard marker IMPLEMENTED_OR_PRESENT / OK ✅
335.10 runtime data contract marker IMPLEMENTED_OR_PRESENT / OK ✅
335.10 order disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
335.10 payment disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
335.11 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
335.11 i18n key marker IMPLEMENTED_OR_PRESENT / OK ✅
335.12 SEO OpenGraph marker IMPLEMENTED_OR_PRESENT / OK ✅
335.12 OpenGraph title meta IMPLEMENTED_OR_PRESENT / OK ✅
335 live storefront html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
335 live storefront runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
335 live market health matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
335 active nginx route matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
335 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
335 nginx loaded market route exists IMPLEMENTED_OR_PRESENT / OK ✅
335 nginx reload status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
335.13 storefront screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
335.13 storefront screen smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
335.13 storefront screen smoke body has marker REQUIRED_FAIL / FAIL ❌
BODY_HEAD_335.13_storefront_screen_smoke=
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Pix2pi Merchant Panel</title>

  <!-- PIX2PI_PANEL_RESPONSIVE_SHELL_CSS_START -->
  <style>
    :root {
      --bg: #f7f8fb;
      --panel: #ffffff;
      --text: #172033;
      --muted: #687287;
      --border: #e6e9f0;
      --brand: #1f6feb;
      --brand-soft: #eaf2ff;
      --ok: #0f8b4c;
      --warn: #a16207;
      --danger: #b42318;
      --s
335.13 storefront runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
335.13 storefront runtime smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
335.13 storefront runtime smoke body has marker REQUIRED_FAIL / FAIL ❌
BODY_HEAD_335.13_storefront_runtime_smoke=
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Pix2pi Merchant Panel</title>

  <!-- PIX2PI_PANEL_RESPONSIVE_SHELL_CSS_START -->
  <style>
    :root {
      --bg: #f7f8fb;
      --panel: #ffffff;
      --text: #172033;
      --muted: #687287;
      --border: #e6e9f0;
      --brand: #1f6feb;
      --brand-soft: #eaf2ff;
      --ok: #0f8b4c;
      --warn: #a16207;
      --danger: #b42318;
      --s
335.13 market health smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
335.13 market health smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
335.13 market health smoke body has marker REQUIRED_FAIL / FAIL ❌
BODY_HEAD_335.13_market_health_smoke=
{"status":"ok","surface":"panel","service":"pix2pi-panel","phase":"7-R","route":"public-http","domain":"panel.pix2pi.com.tr"}
335 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
335 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
335.1 Marketplace / storefront subdomain route aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
335.2 İşletme mağaza vitrini app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
335.3 İşletme profil hero aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
335.4 Mağaza durum / çalışma saati aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
335.5 Kategori önizleme aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
335.6 Öne çıkan ürün grid aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
335.7 Teslimat / gel-al placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
335.8 Kampanya / duyuru banner aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
335.9 Tenant / store slug guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
335.10 Storefront runtime data contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
335.11 i18n-ready storefront marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
335.12 SEO / OpenGraph placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
335.13 Storefront smoke test aggregate gate REQUIRED_FAIL / FAIL ❌
```
