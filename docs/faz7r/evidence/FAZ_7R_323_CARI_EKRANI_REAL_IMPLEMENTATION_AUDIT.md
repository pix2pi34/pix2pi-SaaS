# FAZ 7-R / 323 — Cari ekranı real implementation audit

Generated at: 20260510_205953

## Result

- PASS_COUNT=77
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_323_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_323_FINAL_STATUS=PASS
- FAZ_7R_324_READY=YES

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_323_CARI_EKRANI.md
- Config: configs/faz7r/faz_7r_323_cari_ekrani.v1.json
- Runtime: web/panel/assets/customers/customers-runtime.js
- Customers HTML: web/panel/customers/index.html
- Smoke fixture: tests/faz7r/faz_7r_323_cari_ekrani_smoke_test.json
- Standalone audit script: scripts/faz7r/audit_faz_7r_323_cari_ekrani.sh
- Backup directory: backups/faz7r/faz_7r_323_cari_ekrani_20260510_205953

## Live paths

- /var/www/pix2pi/panel/customers/index.html
- /var/www/pix2pi/panel/assets/customers/customers-runtime.js

## Audit check log

```
323 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
323 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
323 config directory IMPLEMENTED_OR_PRESENT / OK ✅
323 customers repo directory IMPLEMENTED_OR_PRESENT / OK ✅
323 customers asset directory IMPLEMENTED_OR_PRESENT / OK ✅
323 script directory IMPLEMENTED_OR_PRESENT / OK ✅
323 test directory IMPLEMENTED_OR_PRESENT / OK ✅
323 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
323 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
323 config file IMPLEMENTED_OR_PRESENT / OK ✅
323 customers runtime file IMPLEMENTED_OR_PRESENT / OK ✅
323 customers html file IMPLEMENTED_OR_PRESENT / OK ✅
323 smoke fixture file IMPLEMENTED_OR_PRESENT / OK ✅
323 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
323 live customers html file IMPLEMENTED_OR_PRESENT / OK ✅
323 live customers runtime file IMPLEMENTED_OR_PRESENT / OK ✅
323 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
323 smoke fixture json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
323 documentation app shell scope IMPLEMENTED_OR_PRESENT / OK ✅
323 documentation smoke scope IMPLEMENTED_OR_PRESENT / OK ✅
323 config customers path contract IMPLEMENTED_OR_PRESENT / OK ✅
323 config tenant header contract IMPLEMENTED_OR_PRESENT / OK ✅
323 config tax number required field IMPLEMENTED_OR_PRESENT / OK ✅
323 config tax office required field IMPLEMENTED_OR_PRESENT / OK ✅
323 config address required field IMPLEMENTED_OR_PRESENT / OK ✅
323 runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
323.9 tenant scoped headers function IMPLEMENTED_OR_PRESENT / OK ✅
323.10 validation function IMPLEMENTED_OR_PRESENT / OK ✅
323.10 customer payload function IMPLEMENTED_OR_PRESENT / OK ✅
323.7 balance summary function IMPLEMENTED_OR_PRESENT / OK ✅
323.5 tax validation function IMPLEMENTED_OR_PRESENT / OK ✅
323.9 runtime tenant header contract IMPLEMENTED_OR_PRESENT / OK ✅
323.1 app shell marker IMPLEMENTED_OR_PRESENT / OK ✅
323.2 customer list marker IMPLEMENTED_OR_PRESENT / OK ✅
323.3 create edit form marker IMPLEMENTED_OR_PRESENT / OK ✅
323.4 customer supplier type marker IMPLEMENTED_OR_PRESENT / OK ✅
323.5 tax address required marker IMPLEMENTED_OR_PRESENT / OK ✅
323.5 tax number input IMPLEMENTED_OR_PRESENT / OK ✅
323.5 tax office input IMPLEMENTED_OR_PRESENT / OK ✅
323.5 address input IMPLEMENTED_OR_PRESENT / OK ✅
323.5 mersis optional input IMPLEMENTED_OR_PRESENT / OK ✅
323.6 phone email marker IMPLEMENTED_OR_PRESENT / OK ✅
323.6 phone input IMPLEMENTED_OR_PRESENT / OK ✅
323.6 email input IMPLEMENTED_OR_PRESENT / OK ✅
323.7 balance summary marker IMPLEMENTED_OR_PRESENT / OK ✅
323.8 status marker IMPLEMENTED_OR_PRESENT / OK ✅
323.8 ACTIVE status option IMPLEMENTED_OR_PRESENT / OK ✅
323.8 PASSIVE status option IMPLEMENTED_OR_PRESENT / OK ✅
323.9 tenant guard marker IMPLEMENTED_OR_PRESENT / OK ✅
323.10 validation contract marker IMPLEMENTED_OR_PRESENT / OK ✅
323.11 import export placeholder marker IMPLEMENTED_OR_PRESENT / OK ✅
323.12 i18n marker IMPLEMENTED_OR_PRESENT / OK ✅
323 live customers html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
323 live customers runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
323 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
323 panel nginx loaded route exists IMPLEMENTED_OR_PRESENT / OK ✅
323.13 customers screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
323.13 customers screen smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
323.13 customers screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
323.13 customers runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
323.13 customers runtime smoke is not HTTP 301 IMPLEMENTED_OR_PRESENT / OK ✅
323.13 customers runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
323 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
323 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
323.1 Cari app shell aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
323.2 Cari liste ekranı aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
323.3 Cari oluştur / düzenle formu aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
323.4 Müşteri / tedarikçi / karma tipi aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
323.5 Vergi/adres zorunlu alan aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
323.6 Telefon / e-posta alanları aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
323.7 Cari bakiye özeti aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
323.8 Cari durum aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
323.9 Tenant scoped cari guard aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
323.10 Cari validation contract aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
323.11 Import / export placeholder aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
323.12 i18n-ready cari marker aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
323.13 Cari smoke test aggregate gate IMPLEMENTED_OR_PRESENT / OK ✅
```
