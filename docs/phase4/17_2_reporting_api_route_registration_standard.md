# FAZ 4 / 17.2 - Reporting API Route Registration

Amac:
17.1 wiring planina gore reporting API handler'ini net/http mux uzerine route registration paketi olarak baglamak.

Bu adim:
- Runtime server baslatmaz.
- Port dinlemez.
- DB mutate etmez.
- DB migration yazmaz.
- PostgreSQL config degistirmez.
- Gateway / Nginx config degistirmez.
- Sadece route registration kodu yazar.
- repository.New -> service.New -> api.NewHandler -> Register zincirini kurar.
- Unit test ile 6 endpoint registration dogrular.

Bagimli kapanis:
- 16 Reporting final closure PASS olmali.
- 17.1 Runtime wiring plan PASS olmali.

Zorunlu kurallar:
1. 6 reporting endpoint route edilmeli.
2. Sadece GET endpointleri planlanmali.
3. Runtime ListenAndServe yok.
4. Gateway config mutation yok.
5. DB connection acilmaz.
6. Query text response icinde gorunmez.
7. Authorization Bearer ve X-Tenant-ID kontrolu API handler uzerinden korunur.
8. Registration testleri PASS olmali.

Kapanis hedefi:
REPORTING_API_ROUTE_REGISTRATION=PASS
GO_TEST_STATUS=PASS
ROUTE_REGISTRATION_COUNT=6
REPORTING_RUNTIME_STARTED=NO
GATEWAY_CONFIG_CHANGED=NO
DB_MUTATION=NO
FAZ4_17_2_FINAL_STATUS=PASS
