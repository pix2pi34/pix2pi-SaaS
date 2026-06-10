# FAZ 4 / 18.5 - Live HTTP Smoke / Auth-Tenant Verification

Amac:
18.4 ile api-gateway koduna baglanan reporting route'larin mevcut live gateway uzerinden HTTP smoke ile dogrulanmasi.

Bu adim:
- DB mutate etmez.
- DB migration yazmaz.
- PostgreSQL config degistirmez.
- Gateway/Nginx config degistirmez.
- Container restart etmez.
- Runtime restart etmez.
- Sadece mevcut live HTTP gateway uzerinde GET/POST smoke yapar.
- Auth ve tenant gate davranisini dogrular.
- Response body icinde raw SQL / query text sizmasi olmadigini kontrol eder.
- Token veya secret rapora basmaz.

Varsayilan gateway base URL:
- GATEWAY_BASE_URL env varsa onu kullanir.
- API_GATEWAY_BASE_URL env varsa onu kullanir.
- PIX2PI_GATEWAY_BASE_URL env varsa onu kullanir.
- Yoksa http://127.0.0.1:9010 kullanir.

Beklenen HTTP kontrolleri:
1. 6 reporting endpoint Bearer + X-Tenant-ID ile 200 donmeli.
2. Missing Bearer 401 donmeli.
3. Missing X-Tenant-ID 400 donmeli.
4. POST method 405 donmeli.
5. Query text leak olmamali.
6. Gateway live route 404 donmemeli.

Kapanis hedefi:
LIVE_HTTP_SMOKE_AUTH_TENANT=PASS
LIVE_GATEWAY_REACHABLE=YES
LIVE_REPORTING_ROUTE_ACTIVE=YES
LIVE_REPORTING_ENDPOINT_200_COUNT=6
LIVE_AUTH_GATE_STATUS=PASS
LIVE_TENANT_GATE_STATUS=PASS
LIVE_METHOD_GATE_STATUS=PASS
QUERY_TEXT_LEAK_CHECK=PASS
RUNTIME_RESTART_EXECUTED=NO
GATEWAY_CONFIG_CHANGED=NO
DB_MUTATION=NO
FAZ4_18_5_FINAL_STATUS=PASS
