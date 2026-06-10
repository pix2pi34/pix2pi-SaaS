# FAZ 4 / 18.2 - Reporting Runtime Service Entry Apply Plan Report

Generated at: 2026-04-27 19:52:04 +0300

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
PLAN_MODE=APPLY_PLAN_ONLY
PREVIOUS_18_1_READINESS_DISCOVERY=PASS
PREVIOUS_18_1_APPLY_READINESS_STATUS=READY
PREVIOUS_18_1_APPLY_READINESS_BLOCKER_COUNT=0
PREVIOUS_18_1_APPLY_READINESS_WARN_COUNT=0
PREVIOUS_18_1_REPORTING_GO_TEST_SUITE=PASS
PREVIOUS_18_1_CMD_API_GATEWAY_CANDIDATE_COUNT=22
PREVIOUS_18_1_COMPOSE_FILE_COUNT=9
PREVIOUS_18_1_ENV_FILE_COUNT=11
PREVIOUS_18_1_NGINX_FILE_COUNT=11
PREVIOUS_18_1_SYSTEMD_PIX2PI_SERVICE_COUNT=26
PREVIOUS_17_FINAL_STATUS=PASS
PREVIOUS_17_REPORTING_API_FINAL_CLOSURE=PASS
PREVIOUS_17_GATEWAY_REPORTING_ROUTE_COUNT=6
PREVIOUS_17_REPORTING_RUNTIME_STARTED=NO
PREVIOUS_17_GATEWAY_CONFIG_CHANGED=NO
PREVIOUS_17_DB_MUTATION=NO
PREVIOUS_17_QUERY_TEXT_PRINTED=NO
PREVIOUS_17_2_REPORTING_API_ROUTE_REGISTRATION=PASS
PREVIOUS_17_2_ROUTE_REGISTRATION_COUNT=6
PREVIOUS_17_4_REPORTING_RUNTIME_SMOKE_TEST=PASS
PREVIOUS_17_4_REPORTING_AUTH_GATE_SMOKE=PASS
PREVIOUS_17_4_REPORTING_TENANT_GATE_SMOKE=PASS
REPORTING_REGISTRATION_FILE_STATUS=FOUND
REGISTER_REPORTING_ROUTES_FUNCTION_COUNT=1
REPORTING_ROUTES_FUNCTION_COUNT=1
REPORTING_ROUTE_CONSTANT_USAGE_COUNT=6
ENTRY_CANDIDATE_COUNT=96
SELECTED_ENTRY_TARGET_STATUS=SELECTED
SELECTED_ENTRY_TARGET_KIND=API_GATEWAY
SELECTED_ENTRY_TARGET=cmd/api-gateway/api_gateway_main.go
COMPOSE_API_GATEWAY_CANDIDATE_COUNT=2
ENV_CANDIDATE_COUNT=11
REPORTING_GO_TEST_SUITE=PASS
CANDIDATE_EXECUTION_FILE=docs/phase4/18_2_reporting_runtime_service_entry_candidate_execution.sh
CANDIDATE_EXECUTION_CREATED=YES
CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT=YES
SERVICE_ENTRY_CANDIDATE_INVENTORY_LINE_COUNT=49
SERVICE_ENTRY_APPLY_MATRIX_LINE_COUNT=11
REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN=PASS
FAIL_COUNT=0
WARN_COUNT=0
REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN=PASS

## Tool Status
TOOL_go=FOUND
TOOL_grep=FOUND
TOOL_find=FOUND
TOOL_wc=FOUND
TOOL_sha256sum=FOUND

## Candidate Inventory
INVENTORY_FILE=docs/phase4/18_2_reporting_runtime_service_entry_candidate_inventory.tsv
candidate_type	path_or_name	status	note
selected_entry_target	cmd/api-gateway/api_gateway_main.go	SELECTED	type=API_GATEWAY
runtime_registration	internal/platform/reporting/runtime/registration.go	FOUND	RegisterReportingRoutes available
candidate_execution	docs/phase4/18_2_reporting_runtime_service_entry_candidate_execution.sh	YES	blocked_by_default=YES
compose_candidates	deploy/api-gateway_or_gateway	DISCOVERED	2
env_candidates	env_files	DISCOVERED	11
entry_candidate_total	go_files	DISCOVERED	96
apply_mode	plan_only	NO_APPLY	18.2 does not mutate code
candidate_index	path
1	./cmd/accounting-service/accounting_service_main.go
2	./cmd/api-gateway/api_gateway_main.go
3	./cmd/api-gateway/api_gateway_main_test.go
4	./cmd/api-gateway/erp_runtime_live_mount_wiring_test.go
5	./cmd/api-gateway/erp_runtime_mount.go
6	./cmd/api-gateway/erp_runtime_mount_test.go
7	./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go
8	./cmd/api-gateway/erp_runtime_route_catalog_visibility_test.go
9	./cmd/api-gateway/erp_runtime_route_catalog_wiring_test.go
10	./cmd/api-gateway/erp_runtime_route_policy.go
11	./cmd/api-gateway/erp_runtime_route_policy_test.go
12	./cmd/api-gateway/erp_runtime_service_factory.go
13	./cmd/api-gateway/erp_runtime_service_factory_test.go
14	./cmd/api-gateway/gateway_config.go
15	./cmd/api-gateway/gateway_config_security_test.go
16	./cmd/api-gateway/gateway_entry_contract_test.go
17	./cmd/api-gateway/gateway_middleware.go
18	./cmd/api-gateway/gateway_routes.go
19	./cmd/api-gateway/gateway_routes_test.go
20	./cmd/api-gateway/gateway_s2s_policy_test.go
21	./cmd/api-gateway/user_detail_route.go
22	./cmd/auth-api/auth_api_main.go
23	./cmd/cache-pattern-clean-test/cache_pattern_clean_test_main.go
24	./cmd/cache-service/cache_service_main.go
25	./cmd/cache-test/cache_test_main.go
26	./cmd/early-warning-runtime/early_warning_runtime_main.go
27	./cmd/erp/core/ufk/erp_ufk_main.go
28	./cmd/event-bus/event_bus_main.go
29	./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go
30	./cmd/event-concurrency-test/event_concurrency_test_main.go
31	./cmd/event-consumer/event_consumer_main.go
32	./cmd/event-idempotency-test/event_idempotency_test_main.go
33	./cmd/event-metadata-test/event_metadata_test_main.go
34	./cmd/event-replay-test/event_replay_test_main.go
35	./cmd/event-schema-test/event_schema_test_main.go
36	./cmd/event-store-postgres-test/event_store_postgres_test_main.go
37	./cmd/gateway-quota-redis-test/gateway_quota_redis_test_main.go
38	./cmd/gateway-rate-limit-redis-test/gateway_rate_limit_redis_test_main.go
39	./cmd/identity-api/identity_api_main.go
40	./cmd/incident-audit-runtime/incident_audit_runtime_main.go

## Apply Matrix
MATRIX_FILE=docs/phase4/18_2_reporting_runtime_service_entry_apply_matrix.tsv
gate	status	note
previous_18_1_readiness	PASS	readiness=READY blockers=0
previous_17_final	PASS	reporting api closure
runtime_registration	PASS	RegisterReportingRoutes available
entry_candidate_selection	SELECTED	cmd/api-gateway/api_gateway_main.go
candidate_execution_created	YES	blocked_by_default=YES
reporting_go_test_suite	PASS	internal platform reporting
apply_executed	NO	plan only
gateway_config_changed	NO	plan only
runtime_started	NO	plan only
db_mutation	NO	plan only

## Candidate Execution First 120 Lines
#!/usr/bin/env bash
set -euo pipefail
echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 18.2 reporting runtime service entry candidate execution plan."
echo "18.2 does not apply runtime/gateway changes."
echo "Actual controlled apply belongs to 18.3 or later."
exit 99

# FAZ 4 / 18.2 - Reporting Runtime Service Entry Candidate Execution
# Generated at: 2026-04-27 19:52:03 +0300
# This file is intentionally blocked by exit 99 above.

ROOT_DIR="."
SELECTED_ENTRY_TARGET="cmd/api-gateway/api_gateway_main.go"
REPORTING_RUNTIME_REGISTRATION="internal/platform/reporting/runtime/registration.go"

# Candidate import to add if target is Go-based:
# reportingruntime "github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/runtime"

# Candidate registration call:
# if err := reportingruntime.RegisterReportingRoutes(mux); err != nil {
#   return err
# }

# High-level controlled apply sequence:
# 1. Backup selected gateway/service entry file.
# 2. Add reporting runtime import.
# 3. Add RegisterReportingRoutes(mux) after base mux/router creation.
# 4. Run gofmt on changed Go file.
# 5. Run go test ./internal/platform/reporting/... ./cmd/... where applicable.
# 6. Do not restart runtime in 18.2.
# 7. 18.3 will perform controlled apply gate.

# Rollback plan:
# 1. Restore backed-up gateway/service entry file.
# 2. Run gofmt.
# 3. Run go test.
# 4. Confirm reporting route registration reverts to previous state.

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
PLAN_MODE=APPLY_PLAN_ONLY

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
QUERY_TEXT_PRINTED=NO
