# FAZ 4 / 17.4 - Reporting Runtime Smoke Test

Amac:
17.1-17.3 ile hazirlanan reporting runtime wiring, route registration ve gateway auth/tenant gate sozlesmesini controlled in-process smoke test ile dogrulamak.

Bu adim:
- Gercek port acmaz.
- Runtime server baslatmaz.
- ListenAndServe kullanmaz.
- Gateway config degistirmez.
- Nginx config degistirmez.
- DB mutate etmez.
- DB migration yazmaz.
- PostgreSQL config degistirmez.
- Container restart etmez.
- In-process http.ServeMux ve httptest ile 6 endpoint smoke test yapar.
- Auth, tenant, tenant mismatch, method not allowed ve query text leak kontrollerini test eder.

Bagimli kapanis:
- 17.1 Reporting runtime wiring plan PASS olmali.
- 17.2 Reporting API route registration PASS olmali.
- 17.3 Gateway route manifest / auth-tenant middleware gate PASS olmali.
- 16 Reporting final closure PASS olmali.

Zorunlu smoke kontrolleri:
1. 6 reporting endpoint 200 OK donmeli.
2. Tum response envelope status=ok olmali.
3. Tum response tenant_id dogru olmali.
4. Raw SQL / query text response icine sizmamali.
5. Missing Bearer 401 donmeli.
6. Missing X-Tenant-ID 400 donmeli.
7. Tenant mismatch 403 donmeli.
8. POST method 405 donmeli.
9. Runtime start NO olmali.
10. Gateway config mutation NO olmali.

Kapanis hedefi:
REPORTING_RUNTIME_SMOKE_TEST=PASS
REPORTING_RUNTIME_SMOKE_ENDPOINT_COUNT=6
REPORTING_AUTH_GATE_SMOKE=PASS
REPORTING_TENANT_GATE_SMOKE=PASS
REPORTING_RUNTIME_STARTED=NO
GATEWAY_CONFIG_CHANGED=NO
DB_MUTATION=NO
FAZ4_17_4_FINAL_STATUS=PASS
