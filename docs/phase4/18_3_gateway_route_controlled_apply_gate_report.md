# FAZ 4 / 18.3 - Gateway Route Controlled Apply Gate Report

Generated at: 2026-04-27 20:09:34 

## Summary
ROOT_DIR=/root/pix2pi/pix2pi-SaaS
APPLY_EXECUTED=NO
APPLY_REPORTING_RUNTIME=0
DB_MUTATION=NO
DB_MIGRATION_CREATED=NO
DB_APPLY_EXECUTED=NO
SERVICE_CODE_CREATED=NO
HTTP_HANDLER_CREATED=NO
ROUTE_REGISTRATION_CREATED=NO
REPORTING_RUNTIME_STARTED=NO
SERVICE_RUNTIME_STARTED=NO
PORT_OPENED=NO
LISTEN_AND_SERVE_USED=NO
GATEWAY_CONFIG_CHANGED=NO
NGINX_CONFIG_CHANGED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
QUERY_TEXT_PRINTED=NO
GATE_MODE=CONTROLLED_APPLY_GATE_ONLY
PREVIOUS_18_1_READINESS_DISCOVERY=PASS
PREVIOUS_18_1_APPLY_READINESS_STATUS=READY
PREVIOUS_18_1_APPLY_READINESS_BLOCKER_COUNT=0
PREVIOUS_18_1_REPORTING_GO_TEST_SUITE=PASS
PREVIOUS_18_2_SERVICE_ENTRY_APPLY_PLAN=PASS
PREVIOUS_18_2_SELECTED_ENTRY_TARGET_STATUS=SELECTED
PREVIOUS_18_2_SELECTED_ENTRY_TARGET_KIND=API_GATEWAY
PREVIOUS_18_2_SELECTED_ENTRY_TARGET=cmd/api-gateway/api_gateway_main.go
PREVIOUS_18_2_CANDIDATE_EXECUTION_CREATED=YES
PREVIOUS_18_2_CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT=YES
PREVIOUS_18_2_REPORTING_GO_TEST_SUITE=PASS
PREVIOUS_18_2_APPLY_EXECUTED=NO
PREVIOUS_18_2_GATEWAY_CONFIG_CHANGED=NO
PREVIOUS_18_2_REPORTING_RUNTIME_STARTED=NO
PREVIOUS_18_2_DB_MUTATION=NO
PREVIOUS_17_FINAL_STATUS=PASS
PREVIOUS_17_REPORTING_API_FINAL_CLOSURE=PASS
PREVIOUS_17_GATEWAY_REPORTING_ROUTE_COUNT=6
PREVIOUS_17_REPORTING_GO_TEST_SUITE=PASS
PREVIOUS_17_REPORTING_RUNTIME_STARTED=NO
PREVIOUS_17_GATEWAY_CONFIG_CHANGED=NO
PREVIOUS_17_DB_MUTATION=NO
PREVIOUS_17_QUERY_TEXT_PRINTED=NO
SELECTED_ENTRY_TARGET=cmd/api-gateway/api_gateway_main.go
SELECTED_ENTRY_TARGET_KIND=API_GATEWAY
SELECTED_ENTRY_TARGET_STATUS=FOUND
SELECTED_ENTRY_TARGET_SHA256=9bf59d57ae0d2f15c927fd2a9e58779db9ee7a6721e396e9498dcde035bec7ac
RUNTIME_REGISTRATION_FILE=internal/platform/reporting/runtime/registration.go
RUNTIME_REGISTRATION_FILE_STATUS=FOUND
RUNTIME_REGISTRATION_SHA256=6c4abbf5cd01faab8de6352322098392ce1abd689d6a758856cc85720c5e382a
TARGET_PACKAGE_MAIN_COUNT=1
TARGET_MAIN_FUNC_COUNT=1
TARGET_MUX_PATTERN_COUNT=25
TARGET_LISTEN_PATTERN_COUNT=1
TARGET_REPORTING_IMPORT_COUNT=0
TARGET_REPORTING_REGISTER_CALL_COUNT=0
REGISTER_REPORTING_ROUTES_FUNCTION_COUNT=1
REPORTING_ROUTES_FUNCTION_COUNT=1
REPORTING_ROUTE_CONSTANT_USAGE_COUNT=6
REPORTING_RUNTIME_ALREADY_APPLIED=NO
REPORTING_GO_TEST_SUITE=PASS
API_GATEWAY_GO_TEST_STATUS=PASS
CANDIDATE_EXECUTION_FILE=docs/phase4/18_3_gateway_route_controlled_apply_candidate_execution.sh
CANDIDATE_EXECUTION_CREATED=YES
CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT=YES
APPLY_GATE_READY=YES
APPLY_GATE_INVENTORY_LINE_COUNT=14
APPLY_GATE_MATRIX_LINE_COUNT=14
GATEWAY_ROUTE_CONTROLLED_APPLY_GATE=PASS
FAIL_COUNT=0
WARN_COUNT=0
GATEWAY_ROUTE_CONTROLLED_APPLY_GATE=PASS

## Tool Status
TOOL_go=FOUND
TOOL_grep=FOUND
TOOL_wc=FOUND
TOOL_sha256sum=FOUND
TOOL_gofmt=FOUND

## Apply Gate Inventory
INVENTORY_FILE=docs/phase4/18_3_gateway_route_apply_gate_inventory.tsv
item	status	note
selected_entry_target	FOUND	cmd/api-gateway/api_gateway_main.go
selected_entry_kind	API_GATEWAY	api gateway target enforced
target_sha256	CAPTURED	9bf59d57ae0d2f15c927fd2a9e58779db9ee7a6721e396e9498dcde035bec7ac
runtime_registration	FOUND	internal/platform/reporting/runtime/registration.go
register_function	FOUND	count=1
routes_function	FOUND	count=1
route_constants	FOUND	count=6
target_package_main	CHECKED	count=1
target_main_func	CHECKED	count=1
target_mux_pattern	CHECKED	count=25
reporting_already_applied	NO	import_count=0 call_count=0
candidate_execution	YES	blocked_by_default=YES
apply_gate_ready	YES	failures=0 warnings=0

## Apply Gate Matrix
MATRIX_FILE=docs/phase4/18_3_gateway_route_apply_gate_matrix.tsv
gate	status	note
previous_18_1_readiness	PASS	readiness=READY blockers=0
previous_18_2_plan	PASS	selected=cmd/api-gateway/api_gateway_main.go kind=API_GATEWAY
previous_17_final	PASS	reporting api closure
selected_target_api_gateway	FOUND	cmd/api-gateway/api_gateway_main.go
runtime_registration	PASS	RegisterReportingRoutes available
reporting_go_test_suite	PASS	internal platform reporting
api_gateway_go_test	PASS	selected api-gateway tests
candidate_execution_created	YES	blocked_by_default=YES
apply_executed	NO	gate only
gateway_config_changed	NO	gate only
runtime_started	NO	gate only
db_mutation	NO	gate only
apply_gate_ready	YES	warnings=0

## Candidate Execution First 140 Lines
#!/usr/bin/env bash
set -euo pipefail
echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 18.3 gateway route controlled apply candidate execution plan."
echo "18.3 does not apply runtime/gateway changes."
echo "Actual controlled apply belongs to 18.4 after explicit apply decision."
exit 99

# FAZ 4 / 18.3 - Gateway Route Controlled Apply Candidate Execution
# Generated at: 2026-04-27 20:09:34 
# This file is intentionally blocked by exit 99 above.

ROOT_DIR="."
SELECTED_ENTRY_TARGET="cmd/api-gateway/api_gateway_main.go"
SELECTED_ENTRY_TARGET_SHA256="9bf59d57ae0d2f15c927fd2a9e58779db9ee7a6721e396e9498dcde035bec7ac"
RUNTIME_REGISTRATION_FILE="internal/platform/reporting/runtime/registration.go"
RUNTIME_REGISTRATION_SHA256="6c4abbf5cd01faab8de6352322098392ce1abd689d6a758856cc85720c5e382a"

# Proposed import:
# reportingruntime "github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/runtime"

# Proposed route registration call after mux/router creation:
# if err := reportingruntime.RegisterReportingRoutes(mux); err != nil {
#   log.Fatalf("reporting route registration failed: %v", err)
# }

# Idempotency rule:
# 1. If reportingruntime import already exists, do not add duplicate import.
# 2. If RegisterReportingRoutes call already exists, do not add duplicate call.
# 3. Patch only api-gateway target, never accounting-service or unrelated cmd.

# Controlled apply sequence for 18.4:
# 1. Backup cmd/api-gateway/api_gateway_main.go.
# 2. Detect mux/router symbol in api-gateway entry.
# 3. Add reportingruntime import if missing.
# 4. Add reportingruntime.RegisterReportingRoutes(mux) if missing.
# 5. Run gofmt on changed file.
# 6. Run go test ./internal/platform/reporting/... .
# 7. Run go test ./cmd/api-gateway with route/runtime tests.
# 8. Build or compile api-gateway if needed.
# 9. Restart only controlled gateway runtime if explicitly approved.
# 10. Run live HTTP smoke in 18.4/18.5.

# Rollback:
# 1. Restore backed-up cmd/api-gateway/api_gateway_main.go.
# 2. Run gofmt.
# 3. Run go test ./cmd/api-gateway.
# 4. Verify gateway returns to previous route set.

## Go Test Output
=== RUN   TestAllReportingEndpointsRoute
=== RUN   TestAllReportingEndpointsRoute//api/v1/reporting/operational/summary
=== RUN   TestAllReportingEndpointsRoute//api/v1/reporting/operational/daily-metrics
=== RUN   TestAllReportingEndpointsRoute//api/v1/reporting/inventory/status
=== RUN   TestAllReportingEndpointsRoute//api/v1/reporting/documents/work-queue
=== RUN   TestAllReportingEndpointsRoute//api/v1/reporting/reconciliation/status
=== RUN   TestAllReportingEndpointsRoute//api/v1/reporting/projections/state
--- PASS: TestAllReportingEndpointsRoute (0.00s)
    --- PASS: TestAllReportingEndpointsRoute//api/v1/reporting/operational/summary (0.00s)
    --- PASS: TestAllReportingEndpointsRoute//api/v1/reporting/operational/daily-metrics (0.00s)
    --- PASS: TestAllReportingEndpointsRoute//api/v1/reporting/inventory/status (0.00s)
    --- PASS: TestAllReportingEndpointsRoute//api/v1/reporting/documents/work-queue (0.00s)
    --- PASS: TestAllReportingEndpointsRoute//api/v1/reporting/reconciliation/status (0.00s)
    --- PASS: TestAllReportingEndpointsRoute//api/v1/reporting/projections/state (0.00s)
=== RUN   TestRegisterAttachesRoutes
--- PASS: TestRegisterAttachesRoutes (0.00s)
=== RUN   TestMissingBearerToken
--- PASS: TestMissingBearerToken (0.00s)
=== RUN   TestMissingTenantHeader
--- PASS: TestMissingTenantHeader (0.00s)
=== RUN   TestTenantClaimMismatch
--- PASS: TestTenantClaimMismatch (0.00s)
=== RUN   TestMethodNotAllowed
--- PASS: TestMethodNotAllowed (0.00s)
=== RUN   TestInvalidLimitFilter
--- PASS: TestInvalidLimitFilter (0.00s)
=== RUN   TestDailyMetricsLimitForwarding
--- PASS: TestDailyMetricsLimitForwarding (0.00s)
=== RUN   TestServiceErrorMapping
--- PASS: TestServiceErrorMapping (0.00s)
PASS
ok  	github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/api	(cached)
?   	github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/domain	[no test files]
=== RUN   TestValidateTenantID
=== PAUSE TestValidateTenantID
=== RUN   TestNormalizePage
=== PAUSE TestNormalizePage
=== RUN   TestOperationalSummary
=== PAUSE TestOperationalSummary
=== RUN   TestDailyMetrics
=== PAUSE TestDailyMetrics
=== RUN   TestDailyMetricsInvalidDate
=== PAUSE TestDailyMetricsInvalidDate
=== RUN   TestInventoryStatusAlertOnly
=== PAUSE TestInventoryStatusAlertOnly
=== RUN   TestDocumentWorkQueue
=== PAUSE TestDocumentWorkQueue
=== RUN   TestReconciliationStatus
=== PAUSE TestReconciliationStatus
=== RUN   TestProjectionState
=== PAUSE TestProjectionState
=== RUN   TestRepositoryMethodsRequireTenant
=== PAUSE TestRepositoryMethodsRequireTenant
=== RUN   TestNoMutationSQL
=== PAUSE TestNoMutationSQL
=== CONT  TestValidateTenantID
--- PASS: TestValidateTenantID (0.00s)
=== CONT  TestInventoryStatusAlertOnly
=== CONT  TestDocumentWorkQueue
--- PASS: TestInventoryStatusAlertOnly (0.00s)
--- PASS: TestDocumentWorkQueue (0.00s)
=== CONT  TestOperationalSummary
--- PASS: TestOperationalSummary (0.00s)
=== CONT  TestNormalizePage
--- PASS: TestNormalizePage (0.00s)
=== CONT  TestDailyMetricsInvalidDate
--- PASS: TestDailyMetricsInvalidDate (0.00s)
=== CONT  TestRepositoryMethodsRequireTenant
=== RUN   TestRepositoryMethodsRequireTenant/OperationalSummary
=== PAUSE TestRepositoryMethodsRequireTenant/OperationalSummary
=== RUN   TestRepositoryMethodsRequireTenant/DailyMetrics
=== PAUSE TestRepositoryMethodsRequireTenant/DailyMetrics
=== CONT  TestNoMutationSQL
=== CONT  TestProjectionState
--- PASS: TestNoMutationSQL (0.00s)
=== CONT  TestReconciliationStatus
--- PASS: TestProjectionState (0.00s)
--- PASS: TestReconciliationStatus (0.00s)
=== CONT  TestDailyMetrics
--- PASS: TestDailyMetrics (0.00s)
=== RUN   TestRepositoryMethodsRequireTenant/InventoryStatus
=== PAUSE TestRepositoryMethodsRequireTenant/InventoryStatus
=== RUN   TestRepositoryMethodsRequireTenant/DocumentWorkQueue
=== PAUSE TestRepositoryMethodsRequireTenant/DocumentWorkQueue
=== RUN   TestRepositoryMethodsRequireTenant/ReconciliationStatus
=== PAUSE TestRepositoryMethodsRequireTenant/ReconciliationStatus
=== RUN   TestRepositoryMethodsRequireTenant/ProjectionState
=== PAUSE TestRepositoryMethodsRequireTenant/ProjectionState
=== CONT  TestRepositoryMethodsRequireTenant/OperationalSummary
=== CONT  TestRepositoryMethodsRequireTenant/InventoryStatus
=== CONT  TestRepositoryMethodsRequireTenant/DocumentWorkQueue
=== CONT  TestRepositoryMethodsRequireTenant/ProjectionState
=== CONT  TestRepositoryMethodsRequireTenant/DailyMetrics
=== CONT  TestRepositoryMethodsRequireTenant/ReconciliationStatus
--- PASS: TestRepositoryMethodsRequireTenant (0.00s)
    --- PASS: TestRepositoryMethodsRequireTenant/OperationalSummary (0.00s)
    --- PASS: TestRepositoryMethodsRequireTenant/InventoryStatus (0.00s)
    --- PASS: TestRepositoryMethodsRequireTenant/DocumentWorkQueue (0.00s)
    --- PASS: TestRepositoryMethodsRequireTenant/ProjectionState (0.00s)
    --- PASS: TestRepositoryMethodsRequireTenant/DailyMetrics (0.00s)
    --- PASS: TestRepositoryMethodsRequireTenant/ReconciliationStatus (0.00s)
PASS
ok  	github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/repository	(cached)
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
=== CONT  TestRegisterReportingRoutesAuthGate
=== CONT  TestRegisterReportingRoutesTenantGate
--- PASS: TestRegisterReportingRoutesAuthGate (0.00s)
=== CONT  TestReportingRuntimeSmoke_RoutesAreReadOnlyGET
--- PASS: TestReportingRuntimeSmoke_RoutesAreReadOnlyGET (0.00s)
=== CONT  TestReportingRuntimeSmoke_AuthTenantAndMethodGates
--- PASS: TestRegisterReportingRoutesTenantGate (0.00s)
=== CONT  TestRegisterReportingRoutes
=== CONT  TestRegisterReportingRoutesNilMux
--- PASS: TestRegisterReportingRoutesNilMux (0.00s)
=== CONT  TestReportingRuntimeSmoke_AllEndpoints
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/operational/summary
=== RUN   TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/summary
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/summary
=== RUN   TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/daily-metrics
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/daily-metrics
=== RUN   TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/inventory/status
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/operational/daily-metrics
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/inventory/status
=== RUN   TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/documents/work-queue
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/inventory/status
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/documents/work-queue
=== RUN   TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/reconciliation/status
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/reconciliation/status
=== RUN   TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/projections/state
=== PAUSE TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/projections/state
=== CONT  TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/summary
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/documents/work-queue
=== CONT  TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/reconciliation/status
=== RUN   TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_bearer
=== PAUSE TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_bearer
=== RUN   TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_tenant_header
=== PAUSE TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_tenant_header
=== RUN   TestReportingRuntimeSmoke_AuthTenantAndMethodGates/tenant_mismatch
=== PAUSE TestReportingRuntimeSmoke_AuthTenantAndMethodGates/tenant_mismatch
=== RUN   TestReportingRuntimeSmoke_AuthTenantAndMethodGates/method_not_allowed
=== CONT  TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/documents/work-queue
=== PAUSE TestReportingRuntimeSmoke_AuthTenantAndMethodGates/method_not_allowed
=== CONT  TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_bearer
=== CONT  TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/inventory/status
=== CONT  TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/projections/state
=== CONT  TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/daily-metrics
--- PASS: TestReportingRuntimeSmoke_AllEndpoints (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/summary (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/documents/work-queue (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/reconciliation/status (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/inventory/status (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/operational/daily-metrics (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AllEndpoints//api/v1/reporting/projections/state (0.00s)
=== CONT  TestReportingRuntimeSmoke_AuthTenantAndMethodGates/method_not_allowed
=== RUN   TestRegisterReportingRoutes//api/v1/reporting/reconciliation/status
=== CONT  TestReportingRuntimeSmoke_AuthTenantAndMethodGates/tenant_mismatch
=== CONT  TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_tenant_header
--- PASS: TestReportingRuntimeSmoke_AuthTenantAndMethodGates (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_bearer (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AuthTenantAndMethodGates/method_not_allowed (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AuthTenantAndMethodGates/tenant_mismatch (0.00s)
    --- PASS: TestReportingRuntimeSmoke_AuthTenantAndMethodGates/missing_tenant_header (0.00s)
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
=== RUN   TestNewUsesDefaultRepositoryWhenNil
=== PAUSE TestNewUsesDefaultRepositoryWhenNil
=== RUN   TestOperationalSummary
=== PAUSE TestOperationalSummary
=== RUN   TestDailyMetricsDefaultLimit
=== PAUSE TestDailyMetricsDefaultLimit
=== RUN   TestDailyMetricsInvalidLimit
=== PAUSE TestDailyMetricsInvalidLimit
=== RUN   TestDailyMetricsInvalidDate
=== PAUSE TestDailyMetricsInvalidDate
=== RUN   TestInventoryStatus
=== PAUSE TestInventoryStatus
=== RUN   TestDocumentWorkQueue
=== PAUSE TestDocumentWorkQueue
=== RUN   TestReconciliationStatus
=== PAUSE TestReconciliationStatus
=== RUN   TestProjectionState
=== PAUSE TestProjectionState
=== RUN   TestAllMethodsRequireTenant
=== PAUSE TestAllMethodsRequireTenant
=== RUN   TestMapsRepositoryFailure
=== PAUSE TestMapsRepositoryFailure
=== RUN   TestServiceProducesReadOnlyQueries
=== PAUSE TestServiceProducesReadOnlyQueries
=== CONT  TestNewUsesDefaultRepositoryWhenNil
=== CONT  TestDocumentWorkQueue
--- PASS: TestNewUsesDefaultRepositoryWhenNil (0.00s)
=== CONT  TestDailyMetricsDefaultLimit
=== CONT  TestOperationalSummary
=== CONT  TestAllMethodsRequireTenant
=== CONT  TestServiceProducesReadOnlyQueries
--- PASS: TestDocumentWorkQueue (0.00s)
=== CONT  TestProjectionState
--- PASS: TestProjectionState (0.00s)
=== CONT  TestReconciliationStatus
--- PASS: TestReconciliationStatus (0.00s)
=== CONT  TestDailyMetricsInvalidLimit
=== RUN   TestAllMethodsRequireTenant/OperationalSummary
=== PAUSE TestAllMethodsRequireTenant/OperationalSummary
=== RUN   TestAllMethodsRequireTenant/DailyMetrics
=== PAUSE TestAllMethodsRequireTenant/DailyMetrics
=== RUN   TestAllMethodsRequireTenant/InventoryStatus
=== PAUSE TestAllMethodsRequireTenant/InventoryStatus
=== RUN   TestAllMethodsRequireTenant/DocumentWorkQueue
=== PAUSE TestAllMethodsRequireTenant/DocumentWorkQueue
=== RUN   TestAllMethodsRequireTenant/ReconciliationStatus
--- PASS: TestServiceProducesReadOnlyQueries (0.00s)
--- PASS: TestDailyMetricsDefaultLimit (0.00s)
--- PASS: TestOperationalSummary (0.00s)
=== CONT  TestMapsRepositoryFailure
--- PASS: TestDailyMetricsInvalidLimit (0.00s)
=== CONT  TestInventoryStatus
--- PASS: TestMapsRepositoryFailure (0.00s)
--- PASS: TestInventoryStatus (0.00s)
=== CONT  TestDailyMetricsInvalidDate
--- PASS: TestDailyMetricsInvalidDate (0.00s)
=== PAUSE TestAllMethodsRequireTenant/ReconciliationStatus
=== RUN   TestAllMethodsRequireTenant/ProjectionState
=== PAUSE TestAllMethodsRequireTenant/ProjectionState
=== CONT  TestAllMethodsRequireTenant/OperationalSummary
=== CONT  TestAllMethodsRequireTenant/ProjectionState
=== CONT  TestAllMethodsRequireTenant/ReconciliationStatus
=== CONT  TestAllMethodsRequireTenant/DocumentWorkQueue
=== CONT  TestAllMethodsRequireTenant/InventoryStatus
=== CONT  TestAllMethodsRequireTenant/DailyMetrics
--- PASS: TestAllMethodsRequireTenant (0.00s)
    --- PASS: TestAllMethodsRequireTenant/OperationalSummary (0.00s)
    --- PASS: TestAllMethodsRequireTenant/ProjectionState (0.00s)
    --- PASS: TestAllMethodsRequireTenant/ReconciliationStatus (0.00s)
    --- PASS: TestAllMethodsRequireTenant/DocumentWorkQueue (0.00s)
    --- PASS: TestAllMethodsRequireTenant/InventoryStatus (0.00s)
    --- PASS: TestAllMethodsRequireTenant/DailyMetrics (0.00s)
PASS
ok  	github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/service	(cached)
=== RUN   TestGatewayNotFoundMappedJSON
2026/04/27 20:09:33 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:09:33 INFO gateway request | method=GET | path=/olmayan-route | remote=192.0.2.1:1234 | request_id=078c16d666ae17345c70c835005f5ac4 | correlation_id=078c16d666ae17345c70c835005f5ac4
2026/04/27 20:09:33 TRACE gateway | method=GET | path=/olmayan-route | status=404 | duration_ms=0 | request_id=078c16d666ae17345c70c835005f5ac4 | correlation_id=078c16d666ae17345c70c835005f5ac4
--- PASS: TestGatewayNotFoundMappedJSON (0.00s)
=== RUN   TestGatewayListenAddrFromPortDefaultBind
--- PASS: TestGatewayListenAddrFromPortDefaultBind (0.00s)
=== RUN   TestGatewayListenAddrFromPortUsesEnvBind
--- PASS: TestGatewayListenAddrFromPortUsesEnvBind (0.00s)
=== RUN   TestRegisterERPRuntimeUnavailableProtectedRoute
--- PASS: TestRegisterERPRuntimeUnavailableProtectedRoute (0.00s)
=== RUN   TestRegisterERPRuntimeUnavailableProtectedRouteNilMux
--- PASS: TestRegisterERPRuntimeUnavailableProtectedRouteNilMux (0.00s)
=== RUN   TestAPIGatewayMainContainsERPRuntimeLiveMountWiring
--- PASS: TestAPIGatewayMainContainsERPRuntimeLiveMountWiring (0.00s)
=== RUN   TestMountERPRuntimeGatewayRoutesSuccess
--- PASS: TestMountERPRuntimeGatewayRoutesSuccess (0.00s)
=== RUN   TestMountERPRuntimeGatewayRoutesNilMux
--- PASS: TestMountERPRuntimeGatewayRoutesNilMux (0.00s)
=== RUN   TestMountERPRuntimeGatewayRoutesNilService
--- PASS: TestMountERPRuntimeGatewayRoutesNilService (0.00s)
=== RUN   TestERPRuntimeGatewayMuxRegistrarNilMux
--- PASS: TestERPRuntimeGatewayMuxRegistrarNilMux (0.00s)
=== RUN   TestERPRuntimeGatewayMuxRegistrarNilHandler
--- PASS: TestERPRuntimeGatewayMuxRegistrarNilHandler (0.00s)
=== RUN   TestGatewayProtectedERPRuntimeEndpointSmokeSuccess
    erp_runtime_protected_endpoint_smoke_test.go:22: PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping gateway protected ERP runtime smoke test
--- SKIP: TestGatewayProtectedERPRuntimeEndpointSmokeSuccess (0.00s)
=== RUN   TestGatewayProtectedERPRuntimeEndpointRejectsMissingBearer
2026/04/27 20:09:33 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:09:33 INFO gateway request | method=POST | path=/api/v1/erp/runtime/flows | remote=192.0.2.1:1234 | request_id=req-missing-bearer | correlation_id=req-missing-bearer
2026/04/27 20:09:33 TRACE gateway | method=POST | path=/api/v1/erp/runtime/flows | status=401 | duration_ms=0 | request_id=req-missing-bearer | correlation_id=req-missing-bearer
--- PASS: TestGatewayProtectedERPRuntimeEndpointRejectsMissingBearer (0.00s)
=== RUN   TestGatewayProtectedERPRuntimeEndpointRejectsTenantMismatch
2026/04/27 20:09:33 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:09:33 INFO gateway request | method=POST | path=/api/v1/erp/runtime/flows | remote=192.0.2.1:1234 | request_id=req-tenant-mismatch | correlation_id=req-tenant-mismatch
2026/04/27 20:09:33 TRACE gateway | method=POST | path=/api/v1/erp/runtime/flows | status=403 | duration_ms=0 | request_id=req-tenant-mismatch | correlation_id=req-tenant-mismatch
--- PASS: TestGatewayProtectedERPRuntimeEndpointRejectsTenantMismatch (0.00s)
=== RUN   TestGatewayProtectedERPRuntimeEndpointRejectsWrongMethod
2026/04/27 20:09:33 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:09:33 INFO gateway request | method=GET | path=/api/v1/erp/runtime/flows | remote=192.0.2.1:1234 | request_id=req-wrong-method | correlation_id=req-wrong-method
2026/04/27 20:09:33 TRACE gateway | method=GET | path=/api/v1/erp/runtime/flows | status=405 | duration_ms=0 | request_id=req-wrong-method | correlation_id=req-wrong-method
--- PASS: TestGatewayProtectedERPRuntimeEndpointRejectsWrongMethod (0.00s)
=== RUN   TestGatewayRoutesCatalogIncludesERPRuntimeVisibilitySource
--- PASS: TestGatewayRoutesCatalogIncludesERPRuntimeVisibilitySource (0.00s)
=== RUN   TestGatewayRouteRulesIncludesERPRuntimeRoute
--- PASS: TestGatewayRouteRulesIncludesERPRuntimeRoute (0.00s)
=== RUN   TestMatchRouteRuleFindsERPRuntimeRoute
--- PASS: TestMatchRouteRuleFindsERPRuntimeRoute (0.00s)
=== RUN   TestERPRuntimeGatewayRouteRuleContract
--- PASS: TestERPRuntimeGatewayRouteRuleContract (0.00s)
=== RUN   TestAppendERPRuntimeGatewayRouteRuleAddsOnce
--- PASS: TestAppendERPRuntimeGatewayRouteRuleAddsOnce (0.00s)
=== RUN   TestRegisterERPRuntimeProtectedRoutesSuccess
--- PASS: TestRegisterERPRuntimeProtectedRoutesSuccess (0.00s)
=== RUN   TestRegisterERPRuntimeProtectedRoutesNilMux
--- PASS: TestRegisterERPRuntimeProtectedRoutesNilMux (0.00s)
=== RUN   TestRegisterERPRuntimeProtectedRoutesNilService
--- PASS: TestRegisterERPRuntimeProtectedRoutesNilService (0.00s)
=== RUN   TestERPRuntimeGatewayDSNFromEnv
--- PASS: TestERPRuntimeGatewayDSNFromEnv (0.00s)
=== RUN   TestNewERPRuntimeGatewayAPIServiceBundleDSNRequired
--- PASS: TestNewERPRuntimeGatewayAPIServiceBundleDSNRequired (0.00s)
=== RUN   TestBuildERPRuntimeGatewayAPIServicePoolRequired
--- PASS: TestBuildERPRuntimeGatewayAPIServicePoolRequired (0.00s)
=== RUN   TestRuntimeGatewayBridgeHandlersRegistry
--- PASS: TestRuntimeGatewayBridgeHandlersRegistry (0.00s)
=== RUN   TestNewERPRuntimeGatewayAPIServiceBundleExecutesRuntimeFlow
    erp_runtime_service_factory_test.go:66: PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping gateway runtime factory DB test
--- SKIP: TestNewERPRuntimeGatewayAPIServiceBundleExecutesRuntimeFlow (0.00s)
=== RUN   TestGatewayEntryCatalogUsesOnlyAllowedPrefixes
--- PASS: TestGatewayEntryCatalogUsesOnlyAllowedPrefixes (0.00s)
=== RUN   TestGatewayEntryCatalogHasNoLegacyRootLeaks
--- PASS: TestGatewayEntryCatalogHasNoLegacyRootLeaks (0.00s)
=== RUN   TestGatewayEntryCatalogScopeAuthContract
--- PASS: TestGatewayEntryCatalogScopeAuthContract (0.00s)
=== RUN   TestGatewayEntryInternalRoutesAreActuallyMounted
--- PASS: TestGatewayEntryInternalRoutesAreActuallyMounted (0.00s)
=== RUN   TestInternalRoutesRequireInternalKey
2026/04/27 20:09:33 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:09:33 INFO gateway request | method=GET | path=/internal/routes | remote=192.0.2.1:1234 | request_id=dfb10cf847c2d601df1458437273e66e | correlation_id=dfb10cf847c2d601df1458437273e66e
2026/04/27 20:09:33 TRACE gateway | method=GET | path=/internal/routes | status=403 | duration_ms=0 | request_id=dfb10cf847c2d601df1458437273e66e | correlation_id=dfb10cf847c2d601df1458437273e66e
--- PASS: TestInternalRoutesRequireInternalKey (0.00s)
=== RUN   TestInternalRoutesAllowValidInternalKey
2026/04/27 20:09:33 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:09:33 INFO gateway request | method=GET | path=/internal/routes | remote=192.0.2.1:1234 | request_id=0e7a06ce134ee8e0b70b5623a8935384 | correlation_id=0e7a06ce134ee8e0b70b5623a8935384
2026/04/27 20:09:33 TRACE gateway | method=GET | path=/internal/routes | status=200 | duration_ms=0 | request_id=0e7a06ce134ee8e0b70b5623a8935384 | correlation_id=0e7a06ce134ee8e0b70b5623a8935384
--- PASS: TestInternalRoutesAllowValidInternalKey (0.00s)
=== RUN   TestInternalPolicyAllowValidInternalKey
2026/04/27 20:09:33 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:09:33 INFO gateway request | method=GET | path=/internal/policy | remote=192.0.2.1:1234 | request_id=708b461939431ab7d422d1a937451622 | correlation_id=708b461939431ab7d422d1a937451622
2026/04/27 20:09:33 TRACE gateway | method=GET | path=/internal/policy | status=200 | duration_ms=0 | request_id=708b461939431ab7d422d1a937451622 | correlation_id=708b461939431ab7d422d1a937451622
--- PASS: TestInternalPolicyAllowValidInternalKey (0.00s)
=== RUN   TestRouteStandardRejectsWrongMethod
2026/04/27 20:09:33 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:09:33 INFO gateway request | method=POST | path=/health/live | remote=192.0.2.1:1234 | request_id=0c128e7931729929c6954f783d2134e6 | correlation_id=0c128e7931729929c6954f783d2134e6
2026/04/27 20:09:33 TRACE gateway | method=POST | path=/health/live | status=405 | duration_ms=0 | request_id=0c128e7931729929c6954f783d2134e6 | correlation_id=0c128e7931729929c6954f783d2134e6
--- PASS: TestRouteStandardRejectsWrongMethod (0.00s)
=== RUN   TestS2SPolicyCatalogRegistersInternalRoutes
--- PASS: TestS2SPolicyCatalogRegistersInternalRoutes (0.00s)
=== RUN   TestS2SPolicyEndpointReturnsInternalContract
--- PASS: TestS2SPolicyEndpointReturnsInternalContract (0.00s)
=== RUN   TestS2SRoutesEndpointReturnsScopedAuthMetadata
--- PASS: TestS2SRoutesEndpointReturnsScopedAuthMetadata (0.00s)
PASS
ok  	github.com/divrigili/pix2pi-SaaS/cmd/api-gateway	(cached)

## Safety Decision
APPLY_EXECUTED=NO
APPLY_REPORTING_RUNTIME=0
DB_MUTATION=NO
DB_MIGRATION_CREATED=NO
DB_APPLY_EXECUTED=NO
SERVICE_CODE_CREATED=NO
HTTP_HANDLER_CREATED=NO
ROUTE_REGISTRATION_CREATED=NO
REPORTING_RUNTIME_STARTED=NO
SERVICE_RUNTIME_STARTED=NO
PORT_OPENED=NO
LISTEN_AND_SERVE_USED=NO
GATEWAY_CONFIG_CHANGED=NO
NGINX_CONFIG_CHANGED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
QUERY_TEXT_PRINTED=NO
GATE_MODE=CONTROLLED_APPLY_GATE_ONLY

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
QUERY_TEXT_PRINTED=NO
