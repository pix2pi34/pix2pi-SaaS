# FAZ 4 / 18.6 - Reporting Live Route Final Closure Report

Generated at: 2026-04-27 23:22:52 

## Summary
ROOT_DIR=/root/pix2pi/pix2pi-SaaS
APPLY_EXECUTED=NO
RUNTIME_RESTART_EXECUTED=NO
CONTAINER_RESTARTED=NO
DB_MUTATION=NO
DB_MIGRATION_CREATED=NO
DB_APPLY_EXECUTED=NO
GATEWAY_CONFIG_CHANGED=NO
NGINX_CONFIG_CHANGED=NO
POSTGRES_CONFIG_CHANGED=NO
QUERY_TEXT_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
FINAL_CLOSURE_MODE=EVIDENCE_ONLY
PREVIOUS_17_FINAL_STATUS=PASS
PREVIOUS_17_REPORTING_API_FINAL_CLOSURE=PASS
18_1_GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY=PASS
18_1_APPLY_READINESS_STATUS=READY
18_1_APPLY_READINESS_BLOCKER_COUNT=0
18_2_REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN=PASS
18_2_SELECTED_ENTRY_TARGET=cmd/api-gateway/api_gateway_main.go
18_2_SELECTED_ENTRY_TARGET_KIND=API_GATEWAY
18_3_GATEWAY_ROUTE_CONTROLLED_APPLY_GATE=PASS
18_3_APPLY_GATE_READY=YES
18_4_CONTROLLED_GATEWAY_RUNTIME_APPLY=PASS
18_4_REPORTING_RUNTIME_IMPORT_COUNT_AFTER=1
18_4_REPORTING_RUNTIME_REGISTER_CALL_COUNT_AFTER=1
18_4_REPORTING_GO_TEST_SUITE=PASS
18_4_API_GATEWAY_GO_TEST_STATUS=PASS
18_4_REPORTING_RUNTIME_STARTED=NO
18_4_GATEWAY_CONFIG_CHANGED=NO
18_4_DB_MUTATION=NO
18_5_LIVE_HTTP_SMOKE_AUTH_TENANT=PASS
18_5_GATEWAY_BASE_URL=http://127.0.0.1:9010
18_5_LIVE_GATEWAY_REACHABLE=YES
18_5_LIVE_AUTH_MODE=NO_VALID_TOKEN_PROVIDED
18_5_LIVE_REPORTING_ENDPOINT_200_COUNT=0
18_5_LIVE_REPORTING_AUTH_PROTECTED_401_COUNT=6
18_5_LIVE_REPORTING_ROUTE_404_COUNT=0
18_5_LIVE_REPORTING_PROTECTED_ROUTE_STATUS=PASS
18_5_LIVE_AUTH_GATE_STATUS=PASS
18_5_LIVE_TENANT_GATE_STATUS=DEFERRED_NO_VALID_TOKEN
18_5_LIVE_METHOD_GATE_STATUS=DEFERRED_NO_VALID_TOKEN
18_5_QUERY_TEXT_LEAK_CHECK=PASS
18_5_RUNTIME_RESTART_EXECUTED=NO
18_5_GATEWAY_CONFIG_CHANGED=NO
18_5_NGINX_CONFIG_CHANGED=NO
18_5_DB_MUTATION=NO
TARGET_REPORTING_IMPORT_COUNT=1
TARGET_REPORTING_REGISTER_CALL_COUNT=1
LIVE_ROUTE_SECURITY_STATUS=AUTH_PROTECTED
REAL_TOKEN_FULL_SMOKE_STATUS=DEFERRED_NO_VALID_TOKEN
REPORTING_GO_TEST_SUITE=PASS
API_GATEWAY_GO_TEST_STATUS=PASS
FINAL_CLOSURE_INVENTORY_LINE_COUNT=19
FINAL_CLOSURE_MATRIX_LINE_COUNT=18
REPORTING_LIVE_ROUTE_FINAL_CLOSURE=PASS
FAZ4_18_FINAL_STATUS=PASS
FAIL_COUNT=0
WARN_COUNT=0
REPORTING_LIVE_ROUTE_FINAL_CLOSURE=PASS
FAZ4_18_FINAL_STATUS=PASS

## Tool Status
TOOL_go=FOUND
TOOL_python3=FOUND
TOOL_grep=FOUND
TOOL_wc=FOUND

## Final Closure Inventory
INVENTORY_FILE=docs/phase4/18_6_reporting_live_route_final_closure_inventory.tsv
item	status	note
18.1_readiness	PASS	readiness=READY blockers=0
18.2_service_entry_plan	PASS	target=cmd/api-gateway/api_gateway_main.go kind=API_GATEWAY
18.3_apply_gate	PASS	ready=YES
18.4_controlled_apply	PASS	import=1 call=1
18.5_live_smoke	PASS	auth_mode=NO_VALID_TOKEN_PROVIDED protected=PASS
gateway_target_file	FOUND	cmd/api-gateway/api_gateway_main.go
target_reporting_import_count	1	expected=1
target_reporting_register_call_count	1	expected=1
live_gateway_reachable	YES	base_url=http://127.0.0.1:9010
live_route_security_status	AUTH_PROTECTED	200_count=0 auth_401_count=6
real_token_full_smoke_status	DEFERRED_NO_VALID_TOKEN	auth_mode=NO_VALID_TOKEN_PROVIDED
reporting_go_test_suite	PASS	internal/platform/reporting
api_gateway_go_test_status	PASS	cmd/api-gateway
runtime_restart_executed	NO	closure only
gateway_config_changed	NO	closure only
nginx_config_changed	NO	closure only
db_mutation	NO	closure only
query_text_printed	NO	closure only

## Final Closure Matrix
MATRIX_FILE=docs/phase4/18_6_reporting_live_route_final_closure_matrix.tsv
gate	status	note
previous_17_final	PASS	reporting api prerequisite
18.1_readiness	PASS	ready=READY
18.2_service_entry_plan	PASS	target_kind=API_GATEWAY
18.3_apply_gate	PASS	apply_gate_ready=YES
18.4_controlled_apply	PASS	code patch applied
18.5_live_http_smoke	PASS	auth-protected live route evidence
target_code_patch	PASS	import=1 call=1
live_gateway_reachable	YES	base_url=http://127.0.0.1:9010
live_route_security	AUTH_PROTECTED	auth_mode=NO_VALID_TOKEN_PROVIDED
query_text_leak	PASS	no query text leak
reporting_go_test_suite	PASS	final verification
api_gateway_go_test	PASS	final verification
runtime_restart_executed	NO	final closure only
gateway_config_changed	NO	final closure only
nginx_config_changed	NO	final closure only
db_mutation	NO	final closure only
reporting_live_route_final_closure	PASS	failures=0 warnings=0

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
2026/04/27 20:17:52 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:17:52 INFO gateway request | method=GET | path=/olmayan-route | remote=192.0.2.1:1234 | request_id=c50388d35039665a0fab7536668bbb28 | correlation_id=c50388d35039665a0fab7536668bbb28
2026/04/27 20:17:52 TRACE gateway | method=GET | path=/olmayan-route | status=404 | duration_ms=0 | request_id=c50388d35039665a0fab7536668bbb28 | correlation_id=c50388d35039665a0fab7536668bbb28
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
2026/04/27 20:17:52 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:17:52 INFO gateway request | method=POST | path=/api/v1/erp/runtime/flows | remote=192.0.2.1:1234 | request_id=req-missing-bearer | correlation_id=req-missing-bearer
2026/04/27 20:17:52 TRACE gateway | method=POST | path=/api/v1/erp/runtime/flows | status=401 | duration_ms=0 | request_id=req-missing-bearer | correlation_id=req-missing-bearer
--- PASS: TestGatewayProtectedERPRuntimeEndpointRejectsMissingBearer (0.00s)
=== RUN   TestGatewayProtectedERPRuntimeEndpointRejectsTenantMismatch
2026/04/27 20:17:52 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:17:52 INFO gateway request | method=POST | path=/api/v1/erp/runtime/flows | remote=192.0.2.1:1234 | request_id=req-tenant-mismatch | correlation_id=req-tenant-mismatch
2026/04/27 20:17:52 TRACE gateway | method=POST | path=/api/v1/erp/runtime/flows | status=403 | duration_ms=0 | request_id=req-tenant-mismatch | correlation_id=req-tenant-mismatch
--- PASS: TestGatewayProtectedERPRuntimeEndpointRejectsTenantMismatch (0.00s)
=== RUN   TestGatewayProtectedERPRuntimeEndpointRejectsWrongMethod
2026/04/27 20:17:52 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:17:52 INFO gateway request | method=GET | path=/api/v1/erp/runtime/flows | remote=192.0.2.1:1234 | request_id=req-wrong-method | correlation_id=req-wrong-method
2026/04/27 20:17:52 TRACE gateway | method=GET | path=/api/v1/erp/runtime/flows | status=405 | duration_ms=0 | request_id=req-wrong-method | correlation_id=req-wrong-method
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
2026/04/27 20:17:52 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:17:52 INFO gateway request | method=GET | path=/internal/routes | remote=192.0.2.1:1234 | request_id=a3f0418df63d34d2c554347f19bc9bca | correlation_id=a3f0418df63d34d2c554347f19bc9bca
2026/04/27 20:17:52 TRACE gateway | method=GET | path=/internal/routes | status=403 | duration_ms=0 | request_id=a3f0418df63d34d2c554347f19bc9bca | correlation_id=a3f0418df63d34d2c554347f19bc9bca
--- PASS: TestInternalRoutesRequireInternalKey (0.00s)
=== RUN   TestInternalRoutesAllowValidInternalKey
2026/04/27 20:17:52 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:17:52 INFO gateway request | method=GET | path=/internal/routes | remote=192.0.2.1:1234 | request_id=2495bb6b07220e7b5ce464a727d3038c | correlation_id=2495bb6b07220e7b5ce464a727d3038c
2026/04/27 20:17:52 TRACE gateway | method=GET | path=/internal/routes | status=200 | duration_ms=0 | request_id=2495bb6b07220e7b5ce464a727d3038c | correlation_id=2495bb6b07220e7b5ce464a727d3038c
--- PASS: TestInternalRoutesAllowValidInternalKey (0.00s)
=== RUN   TestInternalPolicyAllowValidInternalKey
2026/04/27 20:17:52 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:17:52 INFO gateway request | method=GET | path=/internal/policy | remote=192.0.2.1:1234 | request_id=69dc64c6cc8de3b60fa839a4b32d75b1 | correlation_id=69dc64c6cc8de3b60fa839a4b32d75b1
2026/04/27 20:17:52 TRACE gateway | method=GET | path=/internal/policy | status=200 | duration_ms=0 | request_id=69dc64c6cc8de3b60fa839a4b32d75b1 | correlation_id=69dc64c6cc8de3b60fa839a4b32d75b1
--- PASS: TestInternalPolicyAllowValidInternalKey (0.00s)
=== RUN   TestRouteStandardRejectsWrongMethod
2026/04/27 20:17:52 WARN ⚠️ ERP Runtime gateway service hazirlanamadi: erp runtime gateway dsn zorunlu
2026/04/27 20:17:52 INFO gateway request | method=POST | path=/health/live | remote=192.0.2.1:1234 | request_id=95e0f46834b4ccb1681f1564277ef5e5 | correlation_id=95e0f46834b4ccb1681f1564277ef5e5
2026/04/27 20:17:52 TRACE gateway | method=POST | path=/health/live | status=405 | duration_ms=0 | request_id=95e0f46834b4ccb1681f1564277ef5e5 | correlation_id=95e0f46834b4ccb1681f1564277ef5e5
--- PASS: TestRouteStandardRejectsWrongMethod (0.00s)
=== RUN   TestS2SPolicyCatalogRegistersInternalRoutes
--- PASS: TestS2SPolicyCatalogRegistersInternalRoutes (0.00s)
=== RUN   TestS2SPolicyEndpointReturnsInternalContract
--- PASS: TestS2SPolicyEndpointReturnsInternalContract (0.00s)
=== RUN   TestS2SRoutesEndpointReturnsScopedAuthMetadata
--- PASS: TestS2SRoutesEndpointReturnsScopedAuthMetadata (0.00s)
PASS
ok  	github.com/divrigili/pix2pi-SaaS/cmd/api-gateway	(cached)

## Deferred / Follow-up
REAL_TOKEN_FULL_SMOKE_STATUS=DEFERRED_NO_VALID_TOKEN
LIVE_AUTH_MODE=NO_VALID_TOKEN_PROVIDED
NOTE=Gecerli JWT saglandiginda 18.5 scripti LIVE_SMOKE_AUTH_TOKEN ve LIVE_SMOKE_TENANT_ID ile tekrar kosulabilir.

## Safety Decision
APPLY_EXECUTED=NO
RUNTIME_RESTART_EXECUTED=NO
CONTAINER_RESTARTED=NO
DB_MUTATION=NO
DB_MIGRATION_CREATED=NO
DB_APPLY_EXECUTED=NO
GATEWAY_CONFIG_CHANGED=NO
NGINX_CONFIG_CHANGED=NO
POSTGRES_CONFIG_CHANGED=NO
QUERY_TEXT_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
FINAL_CLOSURE_MODE=EVIDENCE_ONLY

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
QUERY_TEXT_PRINTED=NO
