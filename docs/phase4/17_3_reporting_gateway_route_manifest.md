# FAZ 4 / 17.3 - Reporting Gateway Route Manifest

## Scope

Bu manifest reporting API endpointlerinin gateway seviyesinde nasil korunacagini tanimlar.
Bu dosya gercek gateway config degisikligi yapmaz.

## Route Table

| No | Method | Path | Target Service | Upstream Handler | Auth Gate | Tenant Gate | Status |
|---:|---|---|---|---|---|---|---|
| 1 | GET | /api/v1/reporting/operational/summary | reporting-api | internal/platform/reporting/runtime | bearer_required | x_tenant_id_required | DRY_RUN_READY |
| 2 | GET | /api/v1/reporting/operational/daily-metrics | reporting-api | internal/platform/reporting/runtime | bearer_required | x_tenant_id_required | DRY_RUN_READY |
| 3 | GET | /api/v1/reporting/inventory/status | reporting-api | internal/platform/reporting/runtime | bearer_required | x_tenant_id_required | DRY_RUN_READY |
| 4 | GET | /api/v1/reporting/documents/work-queue | reporting-api | internal/platform/reporting/runtime | bearer_required | x_tenant_id_required | DRY_RUN_READY |
| 5 | GET | /api/v1/reporting/reconciliation/status | reporting-api | internal/platform/reporting/runtime | bearer_required | x_tenant_id_required | DRY_RUN_READY |
| 6 | GET | /api/v1/reporting/projections/state | reporting-api | internal/platform/reporting/runtime | bearer_required | x_tenant_id_required | DRY_RUN_READY |

## Required Gateway Behavior

- Method: GET only
- Authorization header required
- Authorization must start with Bearer
- X-Tenant-ID header required
- Request ID should be forwarded as X-Request-ID
- Tenant claim and X-Tenant-ID mismatch must be rejected
- Query string filters allowed only for reporting GET endpoints
- Raw SQL / query text must not be logged
- Response must keep standard envelope

## Safety Decision

QUERY_TEXT_PRINTED=NO
GATEWAY_CONFIG_CHANGED=NO
NGINX_CONFIG_CHANGED=NO
REPORTING_RUNTIME_STARTED=NO
DB_MUTATION=NO

## Next Step

17.4 Runtime smoke test will verify HTTP behavior against route registration or controlled runtime target.
