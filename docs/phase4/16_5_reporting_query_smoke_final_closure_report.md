# FAZ 4 / 16.5 - Reporting Query Smoke / Final Closure Report

Generated at: 2026-04-27 18:29:47 +0300

## Summary
ROOT_DIR=.
DB_MUTATION=NO
DB_MIGRATION_CREATED=NO
DB_APPLY_EXECUTED=NO
SERVICE_CODE_CREATED=YES
HTTP_HANDLER_CREATED=YES
SERVICE_RUNTIME_STARTED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
QUERY_KILL_EXECUTED=NO
VACUUM_EXECUTED=NO
ANALYZE_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
REPORTING_FINAL_CLOSURE_FILE=docs/phase4/16_reporting_final_closure_report.md
PREVIOUS_15_READMODEL_FINAL_STATUS=PASS
PREVIOUS_15_READMODEL_FINAL_CLOSURE=PASS
PREVIOUS_15_READMODEL_TARGET_TABLE_COUNT=6
PREVIOUS_16_1_REPORTING_QUERY_CONTRACT=PASS
PREVIOUS_16_1_REPORTING_ENDPOINT_COUNT=6
PREVIOUS_16_2_READMODEL_REPOSITORY_LAYER=PASS
PREVIOUS_16_2_REPOSITORY_METHOD_COUNT=6
PREVIOUS_16_2_GO_TEST_STATUS=PASS
PREVIOUS_16_3_REPORTING_SERVICE_LAYER=PASS
PREVIOUS_16_3_SERVICE_METHOD_COUNT=6
PREVIOUS_16_3_GO_TEST_STATUS=PASS
PREVIOUS_16_4_REPORTING_API_ENDPOINT_SKELETON=PASS
PREVIOUS_16_4_API_ENDPOINT_COUNT=6
PREVIOUS_16_4_HANDLER_ROUTE_CASE_COUNT=6
PREVIOUS_16_4_GO_TEST_STATUS=PASS
REPORTING_GO_TEST_SUITE=PASS
DB_DSN_STATUS=CONFIGURED
DB_DSN_MASKED=postgres://pix2pi:***@127.0.0.1:5433/pix2pi?sslmode=disable
DB_CONNECTION_CHECK=PASS
DB_ROLE=PRIMARY_WRITE
READMODEL_SCHEMA_EXISTS=t
READMODEL_TARGET_TABLE_COUNT=6
READMODEL_PRIMARY_KEY_COUNT=6
READMODEL_INDEX_COUNT=13
READMODEL_TENANT_ID_COLUMN_COUNT=6
READMODEL_NOT_NULL_TENANT_COUNT=6
READMODEL_READ_SMOKE_PASS_COUNT=6
READMODEL_READ_SMOKE_FAIL_COUNT=0
REPORTING_QUERY_SMOKE_INVENTORY_LINE_COUNT=7
REPORTING_QUERY_SMOKE=PASS
REPORTING_FINAL_CLOSURE=PASS
FAIL_COUNT=0
WARN_COUNT=0
REPORTING_QUERY_SMOKE=PASS

## Tool Status
TOOL_go=FOUND
TOOL_psql=FOUND
TOOL_grep=FOUND
TOOL_wc=FOUND

## Read Smoke Inventory
INVENTORY_FILE=docs/phase4/16_5_reporting_query_smoke_inventory.tsv
smoke_name	status	result_count
operational_summary	PASS	0
daily_metrics	PASS	0
inventory_status	PASS	0
document_work_queue	PASS	0
reconciliation_status	PASS	0
projection_state	PASS	0

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
DB_MUTATION=NO
DB_MIGRATION_CREATED=NO
DB_APPLY_EXECUTED=NO
SERVICE_CODE_CREATED=YES
HTTP_HANDLER_CREATED=YES
SERVICE_RUNTIME_STARTED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
QUERY_KILL_EXECUTED=NO
VACUUM_EXECUTED=NO
ANALYZE_EXECUTED=NO
QUERY_TEXT_PRINTED=NO

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
QUERY_TEXT_PRINTED=NO
