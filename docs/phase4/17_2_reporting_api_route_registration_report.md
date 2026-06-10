# FAZ 4 / 17.2 - Reporting API Route Registration Report

Generated at: 2026-04-27 19:15:47 +0300

## Summary
ROOT_DIR=.
DB_MUTATION=NO
DB_MIGRATION_CREATED=NO
DB_APPLY_EXECUTED=NO
SERVICE_CODE_CREATED=YES
HTTP_HANDLER_CREATED=NO_NEW_HANDLER
ROUTE_REGISTRATION_CREATED=YES
REPORTING_RUNTIME_STARTED=NO
SERVICE_RUNTIME_STARTED=NO
GATEWAY_CONFIG_CHANGED=NO
NGINX_CONFIG_CHANGED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
QUERY_TEXT_PRINTED=NO
PREVIOUS_17_1_REPORTING_RUNTIME_WIRING_PLAN=PASS
PREVIOUS_17_1_GATEWAY_PREMANIFEST_ROUTE_COUNT=6
PREVIOUS_17_1_REPORTING_RUNTIME_STARTED=NO
PREVIOUS_16_FINAL_STATUS=PASS
PREVIOUS_16_REPORTING_FINAL_CLOSURE=PASS
PREVIOUS_16_REPORTING_ENDPOINT_COUNT=6
ROUTE_REGISTRATION_COUNT=6
ROUTE_REGISTRATION_TEST_COUNT=5
GO_TEST_STATUS=PASS
ROUTE_REGISTRATION_INVENTORY_LINE_COUNT=12
REPORTING_API_ROUTE_REGISTRATION=PASS
FAIL_COUNT=0
WARN_COUNT=0
REPORTING_API_ROUTE_REGISTRATION=PASS

## Tool Status
TOOL_go=FOUND
TOOL_grep=FOUND
TOOL_wc=FOUND

## Go Test Output
=== RUN   TestRoutes
=== PAUSE TestRoutes
=== RUN   TestRegisterReportingRoutesNilMux
=== PAUSE TestRegisterReportingRoutesNilMux
=== RUN   TestRegisterReportingRoutes
=== PAUSE TestRegisterReportingRoutes
=== RUN   TestRegisterReportingRoutesAuthGate
=== PAUSE TestRegisterReportingRoutesAuthGate
=== RUN   TestRegisterReportingRoutesTenantGate
=== PAUSE TestRegisterReportingRoutesTenantGate
=== CONT  TestRoutes
--- PASS: TestRoutes (0.00s)
=== CONT  TestRegisterReportingRoutes
=== CONT  TestRegisterReportingRoutesTenantGate
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/operational/summary
=== CONT  TestRegisterReportingRoutesAuthGate
=== CONT  TestRegisterReportingRoutesNilMux
--- PASS: TestRegisterReportingRoutesNilMux (0.00s)
--- PASS: TestRegisterReportingRoutesTenantGate (0.00s)
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/operational/daily-metrics
--- PASS: TestRegisterReportingRoutesAuthGate (0.00s)
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/inventory/status
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/documents/work-queue
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/reconciliation/status
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/projections/state
--- PASS: TestRegisterReportingRoutes (0.00s)
    --- PASS: TestRegisterReportingRoutes//api/v1/reporting/operational/summary (0.00s)
    --- PASS: TestRegisterReportingRoutes//api/v1/reporting/operational/daily-metrics (0.00s)
    --- PASS: TestRegisterReportingRoutes//api/v1/reporting/inventory/status (0.00s)
    --- PASS: TestRegisterReportingRoutes//api/v1/reporting/documents/work-queue (0.00s)
    --- PASS: TestRegisterReportingRoutes//api/v1/reporting/reconciliation/status (0.00s)
    --- PASS: TestRegisterReportingRoutes//api/v1/reporting/projections/state (0.00s)
PASS
ok  	github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/runtime	(cached)

## Inventory
INVENTORY_FILE=docs/phase4/17_2_reporting_api_route_registration_inventory.tsv

## Safety Decision
DB_MUTATION=NO
DB_MIGRATION_CREATED=NO
DB_APPLY_EXECUTED=NO
SERVICE_CODE_CREATED=YES
HTTP_HANDLER_CREATED=NO_NEW_HANDLER
ROUTE_REGISTRATION_CREATED=YES
REPORTING_RUNTIME_STARTED=NO
SERVICE_RUNTIME_STARTED=NO
GATEWAY_CONFIG_CHANGED=NO
NGINX_CONFIG_CHANGED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
QUERY_TEXT_PRINTED=NO

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
QUERY_TEXT_PRINTED=NO
