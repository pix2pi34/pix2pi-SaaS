# FAZ 7-R / 327 — Rapor ekranları real implementation audit

Generated at: 20260510_211423

## Result

- PASS_COUNT=71
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_327_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_327_FINAL_STATUS=PASS
- FAZ_7R_328_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_327_RAPOR_EKRANLARI.md
- Config: configs/faz7r/faz_7r_327_rapor_ekranlari.v1.json
- Runtime: web/panel/assets/reports/reports-runtime.js
- Reports HTML: web/panel/reports/index.html
- Smoke fixture: tests/faz7r/faz_7r_327_rapor_ekranlari_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_327_rapor_ekranlari.sh
- Backup directory: backups/faz7r/faz_7r_327_rapor_ekranlari_20260510_211423

## Live paths

- /var/www/pix2pi/panel/reports/index.html
- /var/www/pix2pi/panel/assets/reports/reports-runtime.js

## Audit check log

```
327 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
327 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
327 config directory IMPLEMENTED_OR_PRESENT / OK ✅
327 reports repo directory IMPLEMENTED_OR_PRESENT / OK ✅
327 reports asset directory IMPLEMENTED_OR_PRESENT / OK ✅
327 script directory IMPLEMENTED_OR_PRESENT / OK ✅
327 test directory IMPLEMENTED_OR_PRESENT / OK ✅
327 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
327 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
327 config file IMPLEMENTED_OR_PRESENT / OK ✅
327 reports runtime file IMPLEMENTED_OR_PRESENT / OK ✅
327 reports html file IMPLEMENTED_OR_PRESENT / OK ✅
327 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
327 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
327 live reports html file IMPLEMENTED_OR_PRESENT / OK ✅
327 live reports runtime file IMPLEMENTED_OR_PRESENT / OK ✅
327 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
327 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
327 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
327 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
327 config reports path contract IMPLEMENTED_OR_PRESENT / OK ✅
327 config tenant header contract IMPLEMENTED_OR_PRESENT / OK ✅
327 config reporting store source contract IMPLEMENTED_OR_PRESENT / OK ✅
327 config production query disabled contract IMPLEMENTED_OR_PRESENT / OK ✅
327 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
327.10 tenant scoped headers function IMPLEMENTED_OR_PRESENT / OK ✅
327.7 filter validation function IMPLEMENTED_OR_PRESENT / OK ✅
327.11 fallback snapshot fetch function IMPLEMENTED_OR_PRESENT / OK ✅
327.8 export payload function IMPLEMENTED_OR_PRESENT / OK ✅
327.9 read model contract runtime IMPLEMENTED_OR_PRESENT / OK ✅
327.11 fallback snapshot runtime IMPLEMENTED_OR_PRESENT / OK ✅
327.10 runtime tenant header contract IMPLEMENTED_OR_PRESENT / OK ✅
327.1 app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
327.2 KPI cards marker IMPLEMENTED_OR_PRESENT / OK ✅
327.3 sales report marker IMPLEMENTED_OR_PRESENT / OK ✅
327.4 stock report marker IMPLEMENTED_OR_PRESENT / OK ✅
327.5 customer report marker IMPLEMENTED_OR_PRESENT / OK ✅
327.6 document report marker IMPLEMENTED_OR_PRESENT / OK ✅
327.7 date range filter marker IMPLEMENTED_OR_PRESENT / OK ✅
327.8 export placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
327.9 reporting store contract marker IMPLEMENTED_OR_PRESENT / OK ✅
327.9 production query disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
327.10 tenant guard marker IMPLEMENTED_OR_PRESENT / OK ✅
327.11 runtime fallback snapshot marker IMPLEMENTED_OR_PRESENT / OK ✅
327.12 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
327.12 i18n reports title marker IMPLEMENTED_OR_PRESENT / OK ✅
327 live reports html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
327 live reports runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
327 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
327 panel nginx loaded route exists IMPLEMENTED_OR_PRESENT / OK ✅
327.13 reports screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
327.13 reports screen smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
327.13 reports screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
327.13 reports runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
327.13 reports runtime smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
327.13 reports runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
327 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
327 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
327.1 Reports app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
327.2 KPI summary cards aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
327.3 Satış raporu yüzeyi aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
327.4 Stok raporu yüzeyi aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
327.5 Cari raporu yüzeyi aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
327.6 Fatura / belge raporu yüzeyi aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
327.7 Tarih aralığı / filtre yüzeyi aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
327.8 Export placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
327.9 Reporting store / read model contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
327.10 Tenant scoped report guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
327.11 Runtime fallback snapshot aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
327.12 i18n-ready report marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
327.13 Reports smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
