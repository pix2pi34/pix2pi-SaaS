# FAZ 4 / 17.1 - Reporting Runtime Wiring Plan / Service Entry Contract

Amac:
16 Reporting query layer tamamlandiktan sonra reporting API runtime'a baglanmadan once service entry, route registration ve gateway entegrasyon sozlesmesini hazirlamak.

Bu adim:
- Runtime server baslatmaz.
- DB mutate etmez.
- DB migration yazmaz.
- PostgreSQL config degistirmez.
- Container restart etmez.
- Nginx / gateway config degistirmez.
- Kod runtime apply yapmaz.
- Sadece wiring plan, service entry contract ve gateway premanifest dokumanlarini uretir.
- 17.2 route registration icin kapilari belirler.

Bagimli kapanis:
- 16 Reporting final closure PASS olmali.
- 16.4 API endpoint skeleton PASS olmali.
- 16.5 Query smoke / final closure PASS olmali.

Zorunlu kurallar:
1. Reporting runtime read-only olmalidir.
2. Runtime entry Handler + Service + Repository zincirini baglamalidir.
3. Auth / tenant middleware upstream kabul edilir, ama handler icinde Authorization ve X-Tenant-ID skeleton kontrolu korunur.
4. Gateway route manifest 6 endpoint icermelidir.
5. Route registration 17.2'de yapilacaktir.
6. Runtime smoke 17.4'te yapilacaktir.
7. Query text response/log icine basilmaz.
8. DB write/mutation yoktur.

Kapanis hedefi:
REPORTING_RUNTIME_WIRING_PLAN=PASS
REPORTING_SERVICE_ENTRY_CONTRACT=PASS
REPORTING_GATEWAY_PREMANIFEST=PASS
REPORTING_RUNTIME_STARTED=NO
DB_MUTATION=NO
FAZ4_17_1_FINAL_STATUS=PASS
