# FAZ 7-R / 335 FIX V2 — Market domain isolation real implementation audit

Generated at: 20260510_215912

## Result

- PASS_COUNT=42
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_335_FIX_V2_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_335_FINAL_STATUS=PASS
- FAZ_7R_336_READY=YES

## Fix

market.pix2pi.com.tr domain hard-pinned edildi. Smoke test panel body leak kontrolü ekledi.

## Audit check log

```
335 FIX V2 config file IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 storefront html file IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 storefront runtime file IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 health json file IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 repo nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 active nginx route file IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 live storefront html file IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 live storefront runtime file IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 live market health json file IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 repo health json syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 live health json syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 config market domain hard-pinned IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 config market web root hard-pinned IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 health market domain IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 health market service IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 active exact market server_name IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 active market root IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 active isolation marker IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 active route marker IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 live storefront shell marker IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 live runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 live storefront html matches repo IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 live runtime matches repo IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 live health matches repo IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 active nginx route matches repo IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 nginx loaded exact market route exists IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 nginx reload status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
335.13 storefront screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
335.13 storefront screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
335.13 storefront screen smoke body is not panel route IMPLEMENTED_OR_PRESENT / OK ✅
335.13 storefront runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
335.13 storefront runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
335.13 storefront runtime smoke body is not panel route IMPLEMENTED_OR_PRESENT / OK ✅
335.13 market health smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
335.13 market health smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
335.13 market health smoke body is not panel route IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
335 FIX V2 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
335.13 Storefront smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
