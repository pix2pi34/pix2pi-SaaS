# FAZ 4 / 16.3 - Reporting Service Layer

Amac:
16.2 readmodel repository layer uzerine reporting service layer iskeletini kurmak.

Bu adim:
- DB mutate etmez.
- DB migration yazmaz.
- PostgreSQL config degistirmez.
- Container restart etmez.
- HTTP endpoint handler yazmaz.
- Runtime servis baslatmaz.
- Repository interface ile dependency inversion kurar.
- Service request/response DTO tanimlar.
- Tenant zorunlu validation uygular.
- Cursor/limit normalize akisini repository kontratiyla baglar.
- Error code mapping yapar.
- Unit test yazar ve calistirir.

Bagimli kapanis:
- 16.1 Reporting query contract PASS olmali.
- 16.2 Readmodel repository layer PASS olmali.

Service kurallari:
1. TenantID zorunludur.
2. Repository concrete type yerine interface kullanilir.
3. Limit default 50, max 200 kontrati korunur.
4. Service layer query execute etmez; query spec uretir.
5. Mutation SQL uretilemez.
6. Query text loglanmaz.
7. HTTP handler bu adimda yoktur.
8. DB connection bu adimda acilmaz.

Kapanis hedefi:
REPORTING_SERVICE_LAYER=PASS
GO_TEST_STATUS=PASS
SERVICE_METHOD_COUNT=6
SERVICE_ERROR_CODE_COUNT>=5
DB_MUTATION=NO
SERVICE_RUNTIME_STARTED=NO
FAZ4_16_3_FINAL_STATUS=PASS
