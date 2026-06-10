# FAZ 4 / 16.4 - Reporting API Endpoint Skeleton

Amac:
16.1 endpoint manifest, 16.2 repository layer ve 16.3 service layer uzerine HTTP API endpoint skeleton katmanini kurmak.

Bu adim:
- DB mutate etmez.
- DB migration yazmaz.
- PostgreSQL config degistirmez.
- Container restart etmez.
- Runtime server baslatmaz.
- Sadece handler/router skeleton yazar.
- Tenant header / bearer auth skeleton kontrolu yapar.
- Service interface cagrilarini route eder.
- Query text response/log icine basmaz.
- Unit test yazar ve calistirir.

Bagimli kapanis:
- 16.1 Reporting query contract PASS olmali.
- 16.2 Readmodel repository layer PASS olmali.
- 16.3 Reporting service layer PASS olmali.

Endpoint skeleton kurallari:
1. 6 reporting endpoint path'i tanimlanir.
2. Sadece GET methodu kabul edilir.
3. Authorization: Bearer zorunludur.
4. X-Tenant-ID zorunludur.
5. Context icinde JWT tenant claim varsa X-Tenant-ID ile eslesmelidir.
6. Response envelope standarttir.
7. Error envelope standarttir.
8. Raw SQL / query text response icine basilmaz.
9. Runtime Listen / server start yoktur.

Kapanis hedefi:
REPORTING_API_ENDPOINT_SKELETON=PASS
GO_TEST_STATUS=PASS
API_ENDPOINT_COUNT=6
HTTP_HANDLER_CREATED=YES
SERVICE_RUNTIME_STARTED=NO
DB_MUTATION=NO
FAZ4_16_4_FINAL_STATUS=PASS
