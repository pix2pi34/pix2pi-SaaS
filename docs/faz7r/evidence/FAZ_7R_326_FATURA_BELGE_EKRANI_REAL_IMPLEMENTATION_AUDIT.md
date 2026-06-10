# FAZ 7-R / 326 — Fatura / belge ekranı real implementation audit

Generated at: 20260510_211109

## Result

- PASS_COUNT=78
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_326_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_326_FINAL_STATUS=PASS
- FAZ_7R_327_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_326_FATURA_BELGE_EKRANI.md
- Config: configs/faz7r/faz_7r_326_fatura_belge_ekrani.v1.json
- Runtime: web/panel/assets/documents/documents-runtime.js
- Documents HTML: web/panel/documents/index.html
- Smoke fixture: tests/faz7r/faz_7r_326_fatura_belge_ekrani_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_326_fatura_belge_ekrani.sh
- Backup directory: backups/faz7r/faz_7r_326_fatura_belge_ekrani_20260510_211109

## Live paths

- /var/www/pix2pi/panel/documents/index.html
- /var/www/pix2pi/panel/assets/documents/documents-runtime.js

## Audit check log

```
326 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
326 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
326 config directory IMPLEMENTED_OR_PRESENT / OK ✅
326 documents repo directory IMPLEMENTED_OR_PRESENT / OK ✅
326 documents asset directory IMPLEMENTED_OR_PRESENT / OK ✅
326 script directory IMPLEMENTED_OR_PRESENT / OK ✅
326 test directory IMPLEMENTED_OR_PRESENT / OK ✅
326 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
326 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
326 config file IMPLEMENTED_OR_PRESENT / OK ✅
326 documents runtime file IMPLEMENTED_OR_PRESENT / OK ✅
326 documents html file IMPLEMENTED_OR_PRESENT / OK ✅
326 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
326 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
326 live documents html file IMPLEMENTED_OR_PRESENT / OK ✅
326 live documents runtime file IMPLEMENTED_OR_PRESENT / OK ✅
326 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
326 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
326 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
326 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
326 config documents path contract IMPLEMENTED_OR_PRESENT / OK ✅
326 config tenant header contract IMPLEMENTED_OR_PRESENT / OK ✅
326 config provider live disabled IMPLEMENTED_OR_PRESENT / OK ✅
326 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
326.11 tenant scoped headers function IMPLEMENTED_OR_PRESENT / OK ✅
326.12 validation function IMPLEMENTED_OR_PRESENT / OK ✅
326.12 document payload function IMPLEMENTED_OR_PRESENT / OK ✅
326.7 KDV total calculation function IMPLEMENTED_OR_PRESENT / OK ✅
326.8 lifecycle action payload function IMPLEMENTED_OR_PRESENT / OK ✅
326.9 provider closed gate runtime IMPLEMENTED_OR_PRESENT / OK ✅
326.9 real send disabled runtime IMPLEMENTED_OR_PRESENT / OK ✅
326.10 export payload function IMPLEMENTED_OR_PRESENT / OK ✅
326.11 runtime tenant header contract IMPLEMENTED_OR_PRESENT / OK ✅
326.1 app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
326.2 document list marker IMPLEMENTED_OR_PRESENT / OK ✅
326.3 create edit form marker IMPLEMENTED_OR_PRESENT / OK ✅
326.4 document type marker IMPLEMENTED_OR_PRESENT / OK ✅
326.4 e-Fatura option IMPLEMENTED_OR_PRESENT / OK ✅
326.4 e-Arşiv option IMPLEMENTED_OR_PRESENT / OK ✅
326.4 e-Adisyon option IMPLEMENTED_OR_PRESENT / OK ✅
326.5 customer tax preview marker IMPLEMENTED_OR_PRESENT / OK ✅
326.6 document line items marker IMPLEMENTED_OR_PRESENT / OK ✅
326.7 VAT total summary marker IMPLEMENTED_OR_PRESENT / OK ✅
326.8 lifecycle preview marker IMPLEMENTED_OR_PRESENT / OK ✅
326.9 provider closed gate marker IMPLEMENTED_OR_PRESENT / OK ✅
326.9 GIB live disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
326.9 real send disabled visible contract IMPLEMENTED_OR_PRESENT / OK ✅
326.10 export placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
326.11 tenant guard marker IMPLEMENTED_OR_PRESENT / OK ✅
326.12 validation contract marker IMPLEMENTED_OR_PRESENT / OK ✅
326.13 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
326.13 i18n documents title marker IMPLEMENTED_OR_PRESENT / OK ✅
326 live documents html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
326 live documents runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
326 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
326 panel nginx loaded route exists IMPLEMENTED_OR_PRESENT / OK ✅
326.14 documents screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
326.14 documents screen smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
326.14 documents screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
326.14 documents runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
326.14 documents runtime smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
326.14 documents runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
326 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
326 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
326.1 Fatura/belge app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.2 Belge liste ekranı aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.3 Belge oluştur / düzenle formu aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.4 Belge tipi aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.5 Cari vergi preview aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.6 Belge satırları aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.7 KDV / toplam hesap özeti aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.8 Belge lifecycle preview aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.9 Provider canlı kapalı policy gate aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.10 PDF/XML/export placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.11 Tenant scoped document guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.12 Document validation contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.13 i18n-ready document marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
326.14 Fatura/belge smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
