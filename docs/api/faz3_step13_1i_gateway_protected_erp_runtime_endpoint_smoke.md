# FAZ 3 / STEP 13.1I — Gateway Protected ERP Runtime Endpoint Smoke

## Amaç

ERP Runtime endpoint'inin gerçek API Gateway protected chain üzerinden çalıştığını doğrulamak.

## Endpoint

POST `/api/v1/erp/runtime/flows`

## Doğrulanan Akış

Gateway protected route → JWT auth → tenant middleware → rate limit → quota → ERP Runtime API handler → E2E Flow → PostgreSQL

## Doğrulanan Senaryolar

- Geçerli token + tenant header ile `200 OK`
- Eksik bearer token ile `401 Unauthorized`
- Tenant mismatch ile `403 Forbidden`
- Yanlış method ile `405 Method Not Allowed`
- Başarılı istekte DB’ye runtime flow + steps yazılması

## Sonuç

ERP Runtime endpoint gerçek gateway protected chain üzerinde smoke test için hazırlandı.
