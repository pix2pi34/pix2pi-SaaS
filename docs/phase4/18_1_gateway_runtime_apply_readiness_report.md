# FAZ 4 / 18.1 - Gateway / Runtime Apply Readiness Discovery Report

Generated at: 2026-04-27 19:44:57 +0300

## Summary
ROOT_DIR=.
APPLY_EXECUTED=NO
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
DISCOVERY_MODE=READ_ONLY
PREVIOUS_16_FINAL_STATUS=PASS
PREVIOUS_16_REPORTING_FINAL_CLOSURE=PASS
PREVIOUS_17_FINAL_STATUS=PASS
PREVIOUS_17_REPORTING_API_FINAL_CLOSURE=PASS
PREVIOUS_17_GATEWAY_REPORTING_ROUTE_COUNT=6
PREVIOUS_17_REPORTING_GO_TEST_SUITE=PASS
PREVIOUS_17_REPORTING_RUNTIME_STARTED=NO
PREVIOUS_17_GATEWAY_CONFIG_CHANGED=NO
PREVIOUS_17_DB_MUTATION=NO
PREVIOUS_17_QUERY_TEXT_PRINTED=NO
PREVIOUS_17_3_GATEWAY_ROUTE_MANIFEST=PASS
PREVIOUS_17_3_AUTH_TENANT_MIDDLEWARE_GATE=PASS
PREVIOUS_17_4_REPORTING_RUNTIME_SMOKE_TEST=PASS
PREVIOUS_17_4_REPORTING_AUTH_GATE_SMOKE=PASS
PREVIOUS_17_4_REPORTING_TENANT_GATE_SMOKE=PASS
PREVIOUS_17_5_REPORTING_API_FINAL_CLOSURE=PASS
PREVIOUS_17_5_FINAL_STATUS=PASS
REPORTING_RUNTIME_DIR_STATUS=FOUND
REPORTING_API_DIR_STATUS=FOUND
REPORTING_SERVICE_DIR_STATUS=FOUND
REPORTING_REPOSITORY_DIR_STATUS=FOUND
REPORTING_REGISTRATION_FILE_STATUS=FOUND
REPORTING_RUNTIME_SMOKE_TEST_FILE_STATUS=FOUND
REGISTER_REPORTING_ROUTES_FUNCTION_COUNT=1
REPORTING_ROUTES_FUNCTION_COUNT=1
REPORTING_ROUTE_CONSTANT_USAGE_COUNT=6
CMD_API_GATEWAY_CANDIDATE_COUNT=22
CMD_REPORTING_CANDIDATE_COUNT=3
GATEWAY_STRING_FILE_COUNT=0
REPORTING_ROUTE_STRING_FILE_COUNT=1
REPORTING_RUNTIME_REGISTER_USAGE_COUNT=3
COMPOSE_FILE_COUNT=9
ENV_FILE_COUNT=11
NGINX_FILE_COUNT=11
SYSTEMD_PIX2PI_SERVICE_COUNT=26
REPORTING_GO_TEST_SUITE=PASS
APPLY_READINESS_BLOCKER_COUNT=0
APPLY_READINESS_WARN_COUNT=0
APPLY_READINESS_STATUS=READY
DISCOVERY_INVENTORY_LINE_COUNT=16
APPLY_READINESS_MATRIX_LINE_COUNT=12
GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY=PASS
FAIL_COUNT=0
WARN_COUNT=0
GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY=PASS

## Tool Status
TOOL_go=FOUND
TOOL_grep=FOUND
TOOL_find=FOUND
TOOL_wc=FOUND

## Discovery Inventory
INVENTORY_FILE=docs/phase4/18_1_gateway_runtime_discovery_inventory.tsv
area	item	status	count_or_value
reporting_runtime	directory	FOUND	internal/platform/reporting/runtime
reporting_api	directory	FOUND	internal/platform/reporting/api
reporting_service	directory	FOUND	internal/platform/reporting/service
reporting_repository	directory	FOUND	internal/platform/reporting/repository
runtime_registration	file	FOUND	internal/platform/reporting/runtime/registration.go
runtime_smoke_test	file	FOUND	internal/platform/reporting/runtime/runtime_smoke_test.go
register_function	RegisterReportingRoutes	FOUND	1
routes_function	Routes	FOUND	1
route_constants	reporting_routes	FOUND	6
cmd_gateway_candidates	cmd	DISCOVERED	22
cmd_reporting_candidates	cmd	DISCOVERED	3
compose_files	compose	DISCOVERED	9
env_files	env	DISCOVERED	11
nginx_files	nginx	DISCOVERED	11
systemd_pix2pi_services	systemd	DISCOVERED	26

## Apply Readiness Matrix
MATRIX_FILE=docs/phase4/18_1_gateway_runtime_apply_readiness_matrix.tsv
gate	status	note
previous_16_final	PASS	reporting query layer closure
previous_17_final	PASS	reporting api runtime closure
route_registration	PASS	RegisterReportingRoutes available
gateway_manifest	PASS	gateway dry-run manifest
auth_tenant_gate	PASS	bearer and tenant gate
runtime_smoke	PASS	in-process httptest
go_test_suite	PASS	internal platform reporting
runtime_started	NO	no runtime start in 18.1
gateway_config_changed	NO	read-only discovery
db_mutation	NO	read-only discovery
apply_readiness	READY	blockers=0 warnings=0

## Candidate Files
### Gateway related Go files

### Reporting route Go files

### Compose files
deploy/event-bus/docker-compose.yml
deploy/nats/docker-compose.yml
deploy/redis/docker-compose.yml
deploy/dev/docker-compose.pg.yml
deploy/docker-compose.yml
deploy/observability/docker-compose.yml
deploy/api-gateway/docker-compose.yml
infra/observability/docker-compose.override.yml
infra/observability/docker-compose.yml

### Env files
scripts/ci/quality_gates.env
deploy/erp-tr/generated/lvl13_phase_closure_summary.env
deploy/edge/reports/lvl10_ops_validation_summary.env
deploy/platform/generated/lvl12_phase_closure_summary.env
deploy/ports.env
deploy/quality/generated/lvl14_phase_closure_summary.env
deploy/observability/generated/lvl11_phase_closure_summary.env
guard/quality_gates.env
tmp/gw_manual_bearer.env
tmp/gw_jwt_default_probe_winner.env
.env

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

## Safety Decision
APPLY_EXECUTED=NO
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
DISCOVERY_MODE=READ_ONLY

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
QUERY_TEXT_PRINTED=NO
