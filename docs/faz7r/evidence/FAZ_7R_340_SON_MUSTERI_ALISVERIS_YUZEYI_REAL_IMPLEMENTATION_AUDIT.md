# FAZ 7-R / 340 — Son müşteri alışveriş yüzeyi real implementation audit

Generated at: 20260510_221750

## Result

- PASS_COUNT=91
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_340_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_340_FINAL_STATUS=PASS
- FAZ_7R_341_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_340_SON_MUSTERI_ALISVERIS_YUZEYI.md
- Config: configs/faz7r/faz_7r_340_son_musteri_alisveris_yuzeyi.v1.json
- Runtime: web/market/assets/shop/market-shop-runtime.js
- Shop HTML: web/market/shop/index.html
- Smoke fixture: tests/faz7r/faz_7r_340_son_musteri_alisveris_yuzeyi_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_340_son_musteri_alisveris_yuzeyi.sh
- Backup directory: backups/faz7r/faz_7r_340_son_musteri_alisveris_yuzeyi_20260510_221750

## Live paths

- /var/www/pix2pi/market/shop/index.html
- /var/www/pix2pi/market/assets/shop/market-shop-runtime.js

## Public local-route contract

- http://market.pix2pi.com.tr/shop/

## Audit check log

```
340 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
340 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
340 config directory IMPLEMENTED_OR_PRESENT / OK ✅
340 shop repo directory IMPLEMENTED_OR_PRESENT / OK ✅
340 shop asset directory IMPLEMENTED_OR_PRESENT / OK ✅
340 script directory IMPLEMENTED_OR_PRESENT / OK ✅
340 test directory IMPLEMENTED_OR_PRESENT / OK ✅
340 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
340 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
340 config file IMPLEMENTED_OR_PRESENT / OK ✅
340 market shop runtime file IMPLEMENTED_OR_PRESENT / OK ✅
340 market shop html file IMPLEMENTED_OR_PRESENT / OK ✅
340 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
340 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
340 live shop html file IMPLEMENTED_OR_PRESENT / OK ✅
340 live shop runtime file IMPLEMENTED_OR_PRESENT / OK ✅
340 active market nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
340 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
340 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
340 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
340 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
340 config shop path contract IMPLEMENTED_OR_PRESENT / OK ✅
340 config ready for step 341 IMPLEMENTED_OR_PRESENT / OK ✅
340 config customer session header contract IMPLEMENTED_OR_PRESENT / OK ✅
340 active market server_name route IMPLEMENTED_OR_PRESENT / OK ✅
340 active market root route IMPLEMENTED_OR_PRESENT / OK ✅
340 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
340.13 shopping scope headers function IMPLEMENTED_OR_PRESENT / OK ✅
340.13 shopping scope validation IMPLEMENTED_OR_PRESENT / OK ✅
340 shopping snapshot function IMPLEMENTED_OR_PRESENT / OK ✅
340.14 shopping runtime contract function IMPLEMENTED_OR_PRESENT / OK ✅
340 disabled shopping action function IMPLEMENTED_OR_PRESENT / OK ✅
340 customer login disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
340.10 basket mutation disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
340.11 order submit disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
340.12 payment disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
340 stock reservation disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
340 ready for step 341 runtime IMPLEMENTED_OR_PRESENT / OK ✅
340 region header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
340 customer session header runtime contract IMPLEMENTED_OR_PRESENT / OK ✅
340.1 customer shopping app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
340.2 customer session marker IMPLEMENTED_OR_PRESENT / OK ✅
340.3 region context marker IMPLEMENTED_OR_PRESENT / OK ✅
340.4 store discovery shortcut marker IMPLEMENTED_OR_PRESENT / OK ✅
340.5 product discovery shortcut marker IMPLEMENTED_OR_PRESENT / OK ✅
340.6 basket preview widget marker IMPLEMENTED_OR_PRESENT / OK ✅
340.7 deep-link hub marker IMPLEMENTED_OR_PRESENT / OK ✅
340.8 campaign strip marker IMPLEMENTED_OR_PRESENT / OK ✅
340.9 fulfillment preference marker IMPLEMENTED_OR_PRESENT / OK ✅
340.10 add-to-basket disabled marker IMPLEMENTED_OR_PRESENT / OK ✅
340.10 basket disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
340.11 checkout order submit disabled marker IMPLEMENTED_OR_PRESENT / OK ✅
340.11 order disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
340.12 payment disabled marker IMPLEMENTED_OR_PRESENT / OK ✅
340.12 payment disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
340.13 scope guard marker IMPLEMENTED_OR_PRESENT / OK ✅
340.14 runtime data contract marker IMPLEMENTED_OR_PRESENT / OK ✅
340.14 ready for step 341 visible contract IMPLEMENTED_OR_PRESENT / OK ✅
340.15 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
340.15 i18n title marker IMPLEMENTED_OR_PRESENT / OK ✅
340.16 SEO OpenGraph marker IMPLEMENTED_OR_PRESENT / OK ✅
340.16 OpenGraph title meta IMPLEMENTED_OR_PRESENT / OK ✅
340 live shop html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
340 live shop runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
340 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
340 nginx loaded market route exists IMPLEMENTED_OR_PRESENT / OK ✅
340.17 customer shop screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
340.17 customer shop screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
340.17 customer shop screen smoke body is not panel route IMPLEMENTED_OR_PRESENT / OK ✅
340.17 customer shop runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
340.17 customer shop runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
340.17 customer shop runtime smoke body is not panel route IMPLEMENTED_OR_PRESENT / OK ✅
340 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
340 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
340.1 Son müşteri shopping app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.2 Customer session / anonymous context aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.3 Region / neighborhood context aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.4 Store discovery shortcut aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.5 Product discovery shortcut aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.6 Basket preview widget aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.7 Storefront/products/order deep-link hub aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.8 Campaign / recommendation strip aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.9 Delivery / pickup preference selector aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.10 Add-to-basket disabled guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.11 Checkout / order submit disabled guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.12 Payment disabled guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.13 Customer / region / store / basket scope guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.14 Shopping runtime data contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.15 i18n-ready shopping marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.16 SEO / OpenGraph shopping placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
340.17 Son müşteri alışveriş smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
