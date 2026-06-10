# FAZ 4 / 17.4 - Reporting Runtime Smoke Test Report

Generated at: 2026-04-27 19:23:41 +0300

## Summary
ROOT_DIR=.
DB_MUTATION=NO
DB_MIGRATION_CREATED=NO
DB_APPLY_EXECUTED=NO
SERVICE_CODE_CREATED=YES
HTTP_HANDLER_CREATED=NO_NEW_HANDLER
ROUTE_REGISTRATION_CREATED=NO_NEW_ROUTE
REPORTING_RUNTIME_STARTED=NO
SERVICE_RUNTIME_STARTED=NO
PORT_OPENED=NO
LISTEN_AND_SERVE_USED=NO
GATEWAY_CONFIG_CHANGED=NO
NGINX_CONFIG_CHANGED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
QUERY_TEXT_PRINTED=NO
SMOKE_MODE=IN_PROCESS_HTTPTEST
PREVIOUS_17_1_REPORTING_RUNTIME_WIRING_PLAN=PASS
PREVIOUS_17_1_REPORTING_RUNTIME_STARTED=NO
PREVIOUS_17_2_REPORTING_API_ROUTE_REGISTRATION=PASS
PREVIOUS_17_2_ROUTE_REGISTRATION_COUNT=6
PREVIOUS_17_2_GO_TEST_STATUS=PASS
PREVIOUS_17_2_REPORTING_RUNTIME_STARTED=NO
PREVIOUS_17_3_GATEWAY_ROUTE_MANIFEST=PASS
PREVIOUS_17_3_AUTH_TENANT_MIDDLEWARE_GATE=PASS
PREVIOUS_17_3_GATEWAY_REPORTING_ROUTE_COUNT=6
PREVIOUS_17_3_REPORTING_RUNTIME_STARTED=NO
PREVIOUS_17_3_GATEWAY_CONFIG_CHANGED=NO
PREVIOUS_16_FINAL_STATUS=PASS
PREVIOUS_16_REPORTING_FINAL_CLOSURE=PASS
RUNTIME_SMOKE_ENDPOINT_TEST_COUNT=7
RUNTIME_SMOKE_TEST_FUNC_COUNT=3
GO_TEST_STATUS=PASS
REPORTING_RUNTIME_SMOKE_PASS_COUNT=13
REPORTING_RUNTIME_SMOKE_FAIL_COUNT=0
RUNTIME_SMOKE_INVENTORY_LINE_COUNT=8
REPORTING_RUNTIME_SMOKE_TEST=PASS
REPORTING_AUTH_GATE_SMOKE=PASS
REPORTING_TENANT_GATE_SMOKE=PASS
FAIL_COUNT=0
WARN_COUNT=0
REPORTING_RUNTIME_SMOKE_TEST=PASS
REPORTING_AUTH_GATE_SMOKE=PASS
REPORTING_TENANT_GATE_SMOKE=PASS

## Tool Status
TOOL_go=FOUND
TOOL_grep=FOUND
TOOL_wc=FOUND

## Runtime Smoke Inventory
INVENTORY_FILE=docs/phase4/17_4_reporting_runtime_smoke_inventory.tsv
smoke	status	note
all_6_reporting_endpoints	PASS	in_process_httptest
bearer_auth_gate	PASS	missing_bearer_returns_401
tenant_header_gate	PASS	missing_tenant_returns_400
tenant_mismatch_gate	PASS	mismatch_returns_403
method_gate	PASS	post_returns_405
query_text_leak_gate	PASS	response_does_not_expose_raw_sql
runtime_start_gate	PASS	no_port_no_listen

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
=== RUN   TestReportingRuntimeSmoke_AllEndpoints
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints
=== RUN   TestReportingRuntimeSmoke_AuthTenantAndMethodGates
=== PAUSE TestReportingRuntimeSmoke_AuthTenantAndMethodGates
=== RUN   TestReportingRuntimeSmoke_RoutesAreReadOnlyGET
=== PAUSE TestReportingRuntimeSmoke_RoutesAreReadOnlyGET
=== CONT  TestRoutes
--- PASS: TestRoutes (0.00s)
=== CONT  TestReportingRuntimeSmoke_RoutesAreReadOnlyGET
--- PASS: TestReportingRuntimeSmoke_RoutesAreReadOnlyGET (0.00s)
=== CONT  TestReportingRuntimeSmoke_AuthTenantAndMethodGates
=== RUN   TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_bearer
=== PAUSE TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_bearer
=== CONT  TestRegisterReportingRoutesAuthGate
=== CONT  TestReportingRuntimeSmoke_AllEndpoints
=== RUN   TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_tenant_header
=== CONT  TestRegisterReportingRoutes
=== PAUSE TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_tenant_header
--- PASS: TestRegisterReportingRoutesAuthGate (0.00s)
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/operational/summary
=== CONT  TestRegisterReportingRoutesNilMux
--- PASS: TestRegisterReportingRoutesNilMux (0.00s)
=== CONT  TestRegisterReportingRoutesTenantGate
=== RUN   TestReportingRuntimeSmoke_AuthTenantAndMethodGates/tenant_mismatch
=== RUN   TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/summary
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/summary
--- PASS: TestRegisterReportingRoutesTenantGate (0.00s)
=== PAUSE TestReportingRuntimeSmoke_AuthTenantAndMethodGates/tenant_mismatch
=== RUN   TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/daily-metrics
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/daily-metrics
=== RUN   TestReportingRuntimeSmoke_AuthTenantAndMethodGates/method_not_allowed
=== PAUSE TestReportingRuntimeSmoke_AuthTenantAndMethodGates/method_not_allowed
=== CONT  TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_bearer
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/operational/daily-metrics
=== CONT  TestReportingRuntimeSmoke_AuthTenantAndMethodGates/method_not_allowed
=== CONT  TestReportingRuntimeSmoke_AuthTenantAndMethodGates/tenant_mismatch
=== CONT  TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_tenant_header
=== RUN   TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/inventory/status
--- PASS: TestReportingRuntimeSmoke_AuthTenantAndMethodGates (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_bearer (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AuthTenantAndMethodGates/method_not_allowed (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_tenant_header (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AuthTenantAndMethodGates/tenant_mismatch (0.00s)
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/inventory/status
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/inventory/status
=== RUN   TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/documents/work-queue
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/documents/work-queue
=== RUN   TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/reconciliation/status
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/reconciliation/status
=== RUN   TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/projections/state
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/projections/state
=== CONT  TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/summary
=== CONT  TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/documents/work-queue
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/documents/work-queue
=== CONT  TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/projections/state
=== CONT  TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/inventory/status
=== CONT  TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/reconciliation/status
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/reconciliation/status
=== CONT  TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/daily-metrics
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/projections/state
--- PASS: TestReportingRuntimeSmoke_AllEndpoints (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/documents/work-queue (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/summary (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/inventory/status (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/projections/state (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/reconciliation/status (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/daily-metrics (0.00s)
--- PASS: TestRegisterReportingRoutes (0.00s)
    --- PASS: TestRegisterReportingRoutes//api/v1/reporting/operational/summary (0.00s)
    --- PASS: TestRegisterReportingRoutes//api/v1/reporting/operational/daily-metrics (0.00s)
    --- PASS: TestRegisterReportingRoutes//api/v1/reporting/inventory/status (0.00s)
    --- PASS: TestRegisterReportingRoutes//api/v1/reporting/documents/work-queue (0.00s)
    --- PASS: TestRegisterReportingRoutes//api/v1/reporting/reconciliation/status (0.00s)
    --- PASS: TestRegisterReportingRoutes//api/v1/reporting/projections/state (0.00s)
PASS
ok  	github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/runtime	(cached)

## Safety Decision
DB_MUTATION=NO
DB_MIGRATION_CREATED=NO
DB_APPLY_EXECUTED=NO
SERVICE_CODE_CREATED=YES
HTTP_HANDLER_CREATED=NO_NEW_HANDLER
ROUTE_REGISTRATION_CREATED=NO_NEW_ROUTE
REPORTING_RUNTIME_STARTED=NO
SERVICE_RUNTIME_STARTED=NO
PORT_OPENED=NO
LISTEN_AND_SERVE_USED=NO
GATEWAY_CONFIG_CHANGED=NO
NGINX_CONFIG_CHANGED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
QUERY_TEXT_PRINTED=NO
SMOKE_MODE=IN_PROCESS_HTTPTEST

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
QUERY_TEXT_PRINTED=NO
