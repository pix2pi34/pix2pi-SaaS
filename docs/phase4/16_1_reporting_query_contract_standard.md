# FAZ 4 / 16.1 - Reporting Query Contract / Endpoint Manifest

Amac:
15 Readmodel blogu uzerine reporting/query API katmaninin endpoint manifestini ve request/response sozlesmesini hazirlamak.

Bu adim:
- DB mutate etmez.
- DB migration yazmaz.
- PostgreSQL config degistirmez.
- Container restart etmez.
- Go servis kodu yazmaz.
- Query calistirmaz.
- Query text rapora basmaz.
- Sadece reporting query API sozlesmesini dokumante eder.
- 16.2 repository layer icin zemin hazirlar.

Bagimli kapanis:
- 15 Readmodel final closure PASS olmali.

Zorunlu kurallar:
1. Tum endpointler tenant scoped olmalidir.
2. Tenant kaynagi JWT tenant claim + X-Tenant-ID header uyumu ile dogrulanacaktir.
3. Response envelope standart olmalidir.
4. Cursor/pagination sozlesmesi standart olmalidir.
5. Reporting endpointleri source-of-truth degildir; readmodel uzerinden okur.
6. Endpointler read-only davranislidir.
7. Query text veya raw SQL rapora basilmaz.
8. Error response standart formda doner.

Kapanis hedefi:
REPORTING_QUERY_CONTRACT=PASS
REPORTING_ENDPOINT_MANIFEST=PASS
REPORTING_CONTRACTS=PASS
REPORTING_ENDPOINT_COUNT=6
DB_MUTATION=NO
FAZ4_16_1_FINAL_STATUS=PASS
