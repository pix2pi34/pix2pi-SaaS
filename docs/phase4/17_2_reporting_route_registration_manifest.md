# FAZ 4 / 17.2 - Reporting Route Registration Manifest

## Runtime Package

Target package:

internal/platform/reporting/runtime

## Registration Chain

repo := repository.New()
svc  := service.New(repo)
h    := api.NewHandler(svc)
h.Register(mux)

## Route Table

| No | Method | Path | Handler Source | Status |
|---:|---|---|---|---|
| 1 | GET | /api/v1/reporting/operational/summary | reporting api handler | REGISTERED_BY_CODE |
| 2 | GET | /api/v1/reporting/operational/daily-metrics | reporting api handler | REGISTERED_BY_CODE |
| 3 | GET | /api/v1/reporting/inventory/status | reporting api handler | REGISTERED_BY_CODE |
| 4 | GET | /api/v1/reporting/documents/work-queue | reporting api handler | REGISTERED_BY_CODE |
| 5 | GET | /api/v1/reporting/reconciliation/status | reporting api handler | REGISTERED_BY_CODE |
| 6 | GET | /api/v1/reporting/projections/state | reporting api handler | REGISTERED_BY_CODE |

## Runtime Safety

REPORTING_RUNTIME_STARTED=NO
LISTEN_AND_SERVE_USED=NO
DB_CONNECTION_OPENED=NO
GATEWAY_CONFIG_CHANGED=NO
NGINX_CONFIG_CHANGED=NO
QUERY_TEXT_PRINTED=NO

## Next Gate

17.3 Gateway route manifest / auth-tenant middleware gate
