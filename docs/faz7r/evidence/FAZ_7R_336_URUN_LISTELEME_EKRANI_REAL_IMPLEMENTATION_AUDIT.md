# FAZ 7-R / 336 — Ürün listeleme ekranı real implementation audit

Generated at: 20260510_220128

## Result

- PASS_COUNT=85
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_336_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_336_FINAL_STATUS=PASS
- FAZ_7R_337_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_336_URUN_LISTELEME_EKRANI.md
- Config: configs/faz7r/faz_7r_336_urun_listeleme_ekrani.v1.json
- Runtime: web/market/assets/products/market-products-runtime.js
- Products HTML: web/market/products/index.html
- Smoke fixture: tests/faz7r/faz_7r_336_urun_listeleme_ekrani_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_336_urun_listeleme_ekrani.sh
- Backup directory: backups/faz7r/faz_7r_336_urun_listeleme_ekrani_20260510_220128

## Live paths

- /var/www/pix2pi/market/products/index.html
- /var/www/pix2pi/market/assets/products/market-products-runtime.js

## Public local-route contract

- http://market.pix2pi.com.tr/products/

## Audit check log

```
336 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
336 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
336 config directory IMPLEMENTED_OR_PRESENT / OK ✅
336 products repo directory IMPLEMENTED_OR_PRESENT / OK ✅
336 products asset directory IMPLEMENTED_OR_PRESENT / OK ✅
336 script directory IMPLEMENTED_OR_PRESENT / OK ✅
336 test directory IMPLEMENTED_OR_PRESENT / OK ✅
336 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
336 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
336 config file IMPLEMENTED_OR_PRESENT / OK ✅
336 market products runtime file IMPLEMENTED_OR_PRESENT / OK ✅
336 market products html file IMPLEMENTED_OR_PRESENT / OK ✅
336 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
336 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
336 live products html file IMPLEMENTED_OR_PRESENT / OK ✅
336 live products runtime file IMPLEMENTED_OR_PRESENT / OK ✅
336 active market nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
336 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
336 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
336 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
336 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
336 config products path contract IMPLEMENTED_OR_PRESENT / OK ✅
336 config ready for step 337 IMPLEMENTED_OR_PRESENT / OK ✅
336 config store slug header contract IMPLEMENTED_OR_PRESENT / OK ✅
336 active market server_name route IMPLEMENTED_OR_PRESENT / OK ✅
336 active market root route IMPLEMENTED_OR_PRESENT / OK ✅
336 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
336.11 tenant/store headers function IMPLEMENTED_OR_PRESENT / OK ✅
336.11 product scope validation function IMPLEMENTED_OR_PRESENT / OK ✅
336.12 product listing snapshot function IMPLEMENTED_OR_PRESENT / OK ✅
336 filter read function IMPLEMENTED_OR_PRESENT / OK ✅
336 filter application function IMPLEMENTED_OR_PRESENT / OK ✅
336.6 sort products function IMPLEMENTED_OR_PRESENT / OK ✅
336.12 runtime data contract function IMPLEMENTED_OR_PRESENT / OK ✅
336.8 quick preview payload function IMPLEMENTED_OR_PRESENT / OK ✅
336.7 product grid render function IMPLEMENTED_OR_PRESENT / OK ✅
336.9 basket disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
336 stock reservation disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
336 ready for step 337 runtime IMPLEMENTED_OR_PRESENT / OK ✅
336 tenant header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
336 store slug header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
336.1 product listing app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
336.2 storefront store slug context marker IMPLEMENTED_OR_PRESENT / OK ✅
336.3 product search box marker IMPLEMENTED_OR_PRESENT / OK ✅
336.4 category filter marker IMPLEMENTED_OR_PRESENT / OK ✅
336.5 brand stock price filters marker IMPLEMENTED_OR_PRESENT / OK ✅
336.6 sort options marker IMPLEMENTED_OR_PRESENT / OK ✅
336.7 product card grid marker IMPLEMENTED_OR_PRESENT / OK ✅
336.8 quick preview marker IMPLEMENTED_OR_PRESENT / OK ✅
336.9 add to basket disabled gate marker IMPLEMENTED_OR_PRESENT / OK ✅
336.9 basket disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
336.10 pagination placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
336.11 tenant store product scope guard marker IMPLEMENTED_OR_PRESENT / OK ✅
336.12 runtime data contract marker IMPLEMENTED_OR_PRESENT / OK ✅
336.13 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
336.13 i18n title marker IMPLEMENTED_OR_PRESENT / OK ✅
336.14 SEO OpenGraph marker IMPLEMENTED_OR_PRESENT / OK ✅
336.14 OpenGraph title meta IMPLEMENTED_OR_PRESENT / OK ✅
336 live products html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
336 live products runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
336 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
336 nginx loaded market route exists IMPLEMENTED_OR_PRESENT / OK ✅
336.15 products screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
336.15 products screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
336.15 products screen smoke body is not panel route IMPLEMENTED_OR_PRESENT / OK ✅
336.15 products runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
336.15 products runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
336.15 products runtime smoke body is not panel route IMPLEMENTED_OR_PRESENT / OK ✅
336 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
336 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
336.1 Ürün listeleme app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.2 Storefront / store slug context aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.3 Ürün arama kutusu aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.4 Kategori filtresi aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.5 Marka / stok / fiyat filtreleri aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.6 Sıralama seçenekleri aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.7 Ürün kart grid aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.8 Ürün detay quick preview placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.9 Sepete ekle disabled gate aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.10 Pagination / load-more placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.11 Tenant / store / product scope guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.12 Product listing runtime data contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.13 i18n-ready product listing marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.14 SEO / OpenGraph product listing placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
336.15 Ürün listeleme smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
