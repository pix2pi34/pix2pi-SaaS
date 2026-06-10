# FAZ 7-R / 338 — Sipariş ekranı real implementation audit

Generated at: 20260510_221125

## Result

- PASS_COUNT=87
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_338_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_338_FINAL_STATUS=PASS
- FAZ_7R_339_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_338_SIPARIS_EKRANI.md
- Config: configs/faz7r/faz_7r_338_siparis_ekrani.v1.json
- Runtime: web/market/assets/orders/market-orders-runtime.js
- Orders HTML: web/market/orders/index.html
- Smoke fixture: tests/faz7r/faz_7r_338_siparis_ekrani_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_338_siparis_ekrani.sh
- Backup directory: backups/faz7r/faz_7r_338_siparis_ekrani_20260510_221125

## Live paths

- /var/www/pix2pi/market/orders/index.html
- /var/www/pix2pi/market/assets/orders/market-orders-runtime.js

## Public local-route contract

- http://market.pix2pi.com.tr/orders/

## Audit check log

```
338 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
338 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
338 config directory IMPLEMENTED_OR_PRESENT / OK ✅
338 orders repo directory IMPLEMENTED_OR_PRESENT / OK ✅
338 orders asset directory IMPLEMENTED_OR_PRESENT / OK ✅
338 script directory IMPLEMENTED_OR_PRESENT / OK ✅
338 test directory IMPLEMENTED_OR_PRESENT / OK ✅
338 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
338 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
338 config file IMPLEMENTED_OR_PRESENT / OK ✅
338 market orders runtime file IMPLEMENTED_OR_PRESENT / OK ✅
338 market orders html file IMPLEMENTED_OR_PRESENT / OK ✅
338 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
338 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
338 live orders html file IMPLEMENTED_OR_PRESENT / OK ✅
338 live orders runtime file IMPLEMENTED_OR_PRESENT / OK ✅
338 active market nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
338 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
338 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
338 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
338 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
338 config orders path contract IMPLEMENTED_OR_PRESENT / OK ✅
338 config ready for step 339 IMPLEMENTED_OR_PRESENT / OK ✅
338 config customer session header contract IMPLEMENTED_OR_PRESENT / OK ✅
338 active market server_name route IMPLEMENTED_OR_PRESENT / OK ✅
338 active market root route IMPLEMENTED_OR_PRESENT / OK ✅
338 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
338.11 order scope headers function IMPLEMENTED_OR_PRESENT / OK ✅
338.3 basket draft loader IMPLEMENTED_OR_PRESENT / OK ✅
338.7 order totals function IMPLEMENTED_OR_PRESENT / OK ✅
338.11 order scope validation IMPLEMENTED_OR_PRESENT / OK ✅
338.12 order draft payload function IMPLEMENTED_OR_PRESENT / OK ✅
338.10 payment handoff draft function IMPLEMENTED_OR_PRESENT / OK ✅
338.9 submit disabled guard function IMPLEMENTED_OR_PRESENT / OK ✅
338.9 real order submit disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
338.10 payment handoff disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
338 stock reservation disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
338 ready for step 339 runtime IMPLEMENTED_OR_PRESENT / OK ✅
338 tenant header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
338 store slug header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
338 customer session header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
338.1 order app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
338.2 store customer session context marker IMPLEMENTED_OR_PRESENT / OK ✅
338.3 basket order draft context marker IMPLEMENTED_OR_PRESENT / OK ✅
338.4 delivery pickup selection marker IMPLEMENTED_OR_PRESENT / OK ✅
338.5 address delivery note placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
338.6 order line items marker IMPLEMENTED_OR_PRESENT / OK ✅
338.7 order totals marker IMPLEMENTED_OR_PRESENT / OK ✅
338.8 order status timeline marker IMPLEMENTED_OR_PRESENT / OK ✅
338.9 real order disabled gate marker IMPLEMENTED_OR_PRESENT / OK ✅
338.9 real order disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
338.10 payment handoff disabled marker IMPLEMENTED_OR_PRESENT / OK ✅
338.10 payment handoff disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
338.11 scope guard marker IMPLEMENTED_OR_PRESENT / OK ✅
338.12 runtime data contract marker IMPLEMENTED_OR_PRESENT / OK ✅
338.12 ready for step 339 visible contract IMPLEMENTED_OR_PRESENT / OK ✅
338.13 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
338.13 i18n title marker IMPLEMENTED_OR_PRESENT / OK ✅
338.14 SEO OpenGraph marker IMPLEMENTED_OR_PRESENT / OK ✅
338.14 OpenGraph title meta IMPLEMENTED_OR_PRESENT / OK ✅
338 live orders html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
338 live orders runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
338 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
338 nginx loaded market route exists IMPLEMENTED_OR_PRESENT / OK ✅
338.15 orders screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
338.15 orders screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
338.15 orders screen smoke body is not panel route IMPLEMENTED_OR_PRESENT / OK ✅
338.15 orders runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
338.15 orders runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
338.15 orders runtime smoke body is not panel route IMPLEMENTED_OR_PRESENT / OK ✅
338 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
338 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
338.1 Sipariş app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.2 Store / customer session context aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.3 Sepet / sipariş taslak context aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.4 Teslimat / gel-al seçimi aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.5 Adres / teslimat notu placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.6 Sipariş ürün satırları aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.7 Ara toplam / KDV / teslimat / genel toplam aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.8 Sipariş durum timeline aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.9 Gerçek sipariş oluşturma disabled gate aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.10 Payment handoff disabled gate aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.11 Tenant / store / customer / order scope guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.12 Order runtime data contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.13 i18n-ready order marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.14 SEO / OpenGraph order placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
338.15 Sipariş smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
