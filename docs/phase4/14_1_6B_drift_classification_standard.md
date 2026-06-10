# FAZ 4 / 14.1.6B - Drift Classification / Object Risk Grouping

Amac:
14.1.6A drift evidence raporundaki missing objeleri siniflandirmak.

Bu adim:
- DB mutate etmez.
- Migration apply yapmaz.
- Migration dosyalarini degistirmez.
- Sadece rapor okur ve risk siniflandirmasi uretir.

Siniflar:
1. Missing schema
2. Missing table
3. Missing index
4. Migration dosyasina gore eksik dagilimi
5. ERP / platform / foundation ayrimi
6. Apply risk seviyesi

Risk mantigi:
- Missing table varsa HIGH
- Missing schema varsa HIGH
- Sadece missing index varsa MEDIUM
- Missing object yoksa LOW

Kapanis hedefi:
DRIFT_CLASSIFICATION=PASS
DRIFT_RISK_LEVEL raporlanir
MISSING_TABLE_COUNT raporlanir
MISSING_INDEX_COUNT raporlanir
MISSING_SCHEMA_COUNT raporlanir
FAZ4_14_1_6B_FINAL_STATUS=PASS
