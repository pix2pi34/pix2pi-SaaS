# FAZ 4 / 16.2 - Readmodel Repository Layer

Amac:
16.1 reporting query contract uzerine readmodel repository layer iskeletini kurmak.

Bu adim:
- DB mutate etmez.
- DB migration yazmaz.
- PostgreSQL config degistirmez.
- Container restart etmez.
- Endpoint handler yazmaz.
- Service runtime acmaz.
- Read-only query spec builder yazar.
- Tenant zorunlu repository method contract kurar.
- Cursor / limit validation kurar.
- Unit test yazar ve calistirir.

Bagimli kapanis:
- 16.1 Reporting query contract PASS olmali.
- 15 Readmodel final closure PASS olmali.

Repository kurallari:
1. TenantID zorunludur.
2. Limit default 50, max 200 olmalidir.
3. Query spec read-only olmalidir.
4. Mutation SQL uretilemez.
5. Raw SQL loglama yoktur.
6. Endpoint handler bu adimda yoktur.
7. DB connection bu adimda acilmaz.
8. Testler unit seviyesindedir.

Kapanis hedefi:
READMODEL_REPOSITORY_LAYER=PASS
GO_TEST_STATUS=PASS
REPOSITORY_METHOD_COUNT=6
DB_MUTATION=NO
SERVICE_RUNTIME_STARTED=NO
FAZ4_16_2_FINAL_STATUS=PASS
