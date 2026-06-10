# FAZ 4 / 19 - Final Master Closure / Faz 5 Transition Gate Report

Generated at: 2026-04-27 23:27:32 

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
FINAL_MASTER_CLOSURE_MODE=EVIDENCE_ONLY
BLOCK_14_3_FILE_EXISTS=YES
BLOCK_14_3_STATUS=PASS
BLOCK_14_3_EVIDENCE_KEY=FAZ4_14_3_FINAL_STATUS
BLOCK_14_4_FILE_EXISTS=YES
BLOCK_14_4_STATUS=PASS
BLOCK_14_4_EVIDENCE_KEY=FAZ4_14_4_FINAL_STATUS
BLOCK_14_5_FILE_EXISTS=YES
BLOCK_14_5_STATUS=PASS
BLOCK_14_5_EVIDENCE_KEY=DB_PRODUCTION_READINESS_SCORECARD
BLOCK_15_FILE_EXISTS=YES
BLOCK_15_STATUS=PASS
BLOCK_15_EVIDENCE_KEY=FAZ4_15_FINAL_STATUS
BLOCK_16_FILE_EXISTS=YES
BLOCK_16_STATUS=PASS
BLOCK_16_EVIDENCE_KEY=FAZ4_16_FINAL_STATUS
BLOCK_17_FILE_EXISTS=YES
BLOCK_17_STATUS=PASS
BLOCK_17_EVIDENCE_KEY=FAZ4_17_FINAL_STATUS
BLOCK_18_FILE_EXISTS=YES
BLOCK_18_STATUS=PASS
BLOCK_18_EVIDENCE_KEY=FAZ4_18_FINAL_STATUS
DB_PRODUCTION_READINESS_SCORE=96
DB_PRODUCTION_READINESS_GRADE=A
DB_PRODUCTION_READINESS_STATUS=READY_WITH_DEFERRED_ACTIONS
PITR_DEFERRED_ACTION_COUNT=1
LIVE_ROUTE_SECURITY_STATUS=AUTH_PROTECTED
REAL_TOKEN_FULL_SMOKE_STATUS=DEFERRED_NO_VALID_TOKEN
LIVE_REPORTING_AUTH_PROTECTED_401_COUNT=6
LIVE_REPORTING_ROUTE_404_COUNT=0
QUERY_TEXT_LEAK_CHECK=PASS
GATEWAY_REPORTING_RUNTIME_IMPORT_COUNT=1
GATEWAY_REPORTING_RUNTIME_REGISTER_CALL_COUNT=1
REPORTING_GO_TEST_SUITE=PASS
API_GATEWAY_GO_TEST_STATUS=PASS
PHASE4_BLOCKER_COUNT=0
PHASE4_DEFERRED_ACTION_COUNT=2
FAZ5_TRANSITION_GATE=READY_WITH_DEFERRED_ACTIONS
PHASE4_FINAL_MASTER_CLOSURE=PASS
FAZ4_FINAL_STATUS=PASS
FINAL_MASTER_INVENTORY_LINE_COUNT=14
PHASE5_TRANSITION_GATE_LINE_COUNT=12
FAIL_COUNT=0
WARN_COUNT=0
PHASE4_FINAL_MASTER_CLOSURE=PASS
FAZ4_FINAL_STATUS=PASS
FAZ5_TRANSITION_GATE=READY_WITH_DEFERRED_ACTIONS

## Tool Status
TOOL_go=FOUND
TOOL_python3=FOUND
TOOL_grep=FOUND
TOOL_wc=FOUND

## Final Master Inventory
INVENTORY_FILE=docs/phase4/19_phase4_final_master_closure_inventory.tsv
block	status	evidence_file	evidence_key
14.3	PASS	docs/phase4/14_3_final_db_observability_closure_report.md	FAZ4_14_3_FINAL_STATUS
14.4	PASS	docs/phase4/14_4_final_db_performance_closure_report.md	FAZ4_14_4_FINAL_STATUS
14.5	PASS	docs/phase4/14_5_2_db_production_readiness_scorecard_report.md	DB_PRODUCTION_READINESS_SCORECARD
15	PASS	docs/phase4/15_readmodel_final_closure_report.md	FAZ4_15_FINAL_STATUS
16	PASS	docs/phase4/16_reporting_final_closure_report.md	FAZ4_16_FINAL_STATUS
17	PASS	docs/phase4/17_reporting_api_final_closure_report.md	FAZ4_17_FINAL_STATUS
18	PASS	docs/phase4/18_reporting_live_route_final_closure_report.md	FAZ4_18_FINAL_STATUS
gateway_reporting_import	PASS	cmd/api-gateway/api_gateway_main.go	count=1
gateway_reporting_register_call	PASS	cmd/api-gateway/api_gateway_main.go	count=1
reporting_go_test_suite	PASS	go test ./internal/platform/reporting/...	final verification
api_gateway_go_test	PASS	go test ./cmd/api-gateway selected tests	final verification
db_production_readiness	READY_WITH_DEFERRED_ACTIONS	docs/phase4/14_5_2_db_production_readiness_scorecard_report.md	score=96 grade=A
live_route_security	AUTH_PROTECTED	docs/phase4/18_reporting_live_route_final_closure_report.md	auth_401=6 route_404=0

## Phase 5 Transition Gate
TRANSITION_FILE=docs/phase4/19_phase4_to_phase5_transition_gate.tsv
item	status	note
phase4_final_status	PASS	blockers=0
faz5_transition_gate	READY_WITH_DEFERRED_ACTIONS	deferred_actions=2
db_readiness	READY_WITH_DEFERRED_ACTIONS	score=96 grade=A
gateway_reporting_live_route	AUTH_PROTECTED	auth protected route verified
real_jwt_live_smoke	DEFERRED_NO_VALID_TOKEN	optional follow-up with LIVE_SMOKE_AUTH_TOKEN
runtime_restart_executed	NO	final master closure only
gateway_config_changed	NO	final master closure only
nginx_config_changed	NO	final master closure only
db_mutation	NO	final master closure only
deferred_pitr	DEFERRED	PITR aktiflestirme bakim penceresine erteli
deferred_real_jwt_live_smoke	DEFERRED	Gecerli JWT ile full 200/tenant/method smoke daha sonra kosulacak

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

## Deferred Actions
PITR=DEFERRED — PITR aktiflestirme bakim penceresine erteli
REAL_JWT_LIVE_SMOKE=DEFERRED — Gecerli JWT ile full 200/tenant/method smoke daha sonra kosulacak

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
FINAL_MASTER_CLOSURE_MODE=EVIDENCE_ONLY

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
QUERY_TEXT_PRINTED=NO
