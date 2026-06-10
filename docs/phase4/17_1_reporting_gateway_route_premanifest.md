# FAZ 4 / 17.1 - Reporting Gateway Route Premanifest

## Purpose

Bu dosya 17.3 gateway route manifest icin on-manifesttir. Bu adim gateway config degistirmez.

## Route Table

| No | Method | Path | Target | Auth | Tenant |
|---:|---|---|---|---|---|
| 1 | GET | /api/v1/reporting/operational/summary | reporting-api | Bearer required | X-Tenant-ID required |
| 2 | GET | /api/v1/reporting/operational/daily-metrics | reporting-api | Bearer required | X-Tenant-ID required |
| 3 | GET | /api/v1/reporting/inventory/status | reporting-api | Bearer required | X-Tenant-ID required |
| 4 | GET | /api/v1/reporting/documents/work-queue | reporting-api | Bearer required | X-Tenant-ID required |
| 5 | GET | /api/v1/reporting/reconciliation/status | reporting-api | Bearer required | X-Tenant-ID required |
| 6 | GET | /api/v1/reporting/projections/state | reporting-api | Bearer required | X-Tenant-ID required |

## Gateway Rules

- Sadece GET methodlari.
- Bearer token zorunlu.
- X-Tenant-ID zorunlu.
- Rate-limit gateway tarafinda uygulanabilir.
- Tenant mismatch kontrolu auth/tenant middleware tarafinda yapilmalidir.
- API handler icinde skeleton tenant mismatch kontrolu korunur.
- Request ID header gecirilmelidir.
- Query text loglanmamalidir.

## 17.3 Icin Beklenen Cikti

GATEWAY_REPORTING_ROUTE_COUNT=6
GATEWAY_AUTH_TENANT_GATE=PASS
GATEWAY_CONFIG_MUTATION=CONTROLLED_OR_NOOP
