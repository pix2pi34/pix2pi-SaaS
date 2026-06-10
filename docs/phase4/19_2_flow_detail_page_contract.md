# FAZ 4B / 19.2 - Flow Detail Page Contract

## Page

PAGE_ID=admin_runtime_flow_detail
PAGE_ROUTE=/admin/runtime-flows/:flow_run_id
PAGE_TITLE=Runtime Flow Detail
PAGE_SCOPE=tenant_admin
PAGE_STATUS=contract_only

## Route Parameters

| Param | Required | Note |
| --- | --- | --- |
| flow_run_id | YES | Runtime flow run identifier |

## Required API Surfaces

| Method | Endpoint | Purpose | Tenant Required | Auth Required |
| --- | --- | --- | --- | --- |
| GET | /api/v1/admin/runtime-flows/:flow_run_id | Flow run summary | YES | YES |
| GET | /api/v1/admin/runtime-flows/:flow_run_id/steps | Flow steps | YES | YES |
| GET | /api/v1/admin/runtime-flows/:flow_run_id/events | Flow events | YES | YES |
| GET | /api/v1/admin/runtime-flows/:flow_run_id/timeline | Flow timeline | YES | YES |
| GET | /api/v1/admin/runtime-flows/:flow_run_id/errors | Flow error links | YES | YES |
| GET | /api/v1/admin/runtime-flows/:flow_run_id/snapshots | Flow snapshots | YES | YES |

## Required Data Blocks

### Flow Summary

Required fields:
- runtime_flow_run_id
- tenant_id
- flow_run_no
- flow_type
- flow_name
- flow_source
- source_service
- source_route
- request_id
- correlation_id
- source_event_id
- status_code
- severity
- started_at
- finished_at
- duration_ms
- step_count
- success_step_count
- failed_step_count
- warning_count
- error_count
- panel_visibility

### Step Timeline

Required fields:
- runtime_flow_step_id
- runtime_flow_run_id
- step_no
- step_key
- step_name
- step_type
- service_name
- route_path
- http_method
- event_type
- job_type
- request_id
- correlation_id
- status_code
- severity
- started_at
- finished_at
- duration_ms
- retry_count
- error_code
- error_message

### Event History

Required fields:
- runtime_flow_event_id
- runtime_flow_run_id
- runtime_flow_step_id
- event_no
- event_type
- event_name
- source_service
- source_event_id
- request_id
- correlation_id
- status_code
- severity
- event_at
- payload_ref
- payload_hash
- error_code
- error_message

### Error Links

Required fields:
- runtime_flow_error_link_id
- runtime_flow_run_id
- runtime_flow_step_id
- runtime_flow_event_id
- error_source
- error_code
- error_message
- severity
- request_id
- correlation_id
- source_event_id
- source_job_id
- service_name
- route_path
- issue_status
- linked_incident_id
- linked_audit_id
- first_seen_at
- last_seen_at

### Snapshot / Progress

Required fields:
- runtime_flow_snapshot_id
- runtime_flow_run_id
- snapshot_no
- snapshot_type
- flow_type
- status_code
- progress_percent
- current_step_key
- current_step_name
- step_count
- success_step_count
- failed_step_count
- warning_count
- error_count
- last_request_id
- last_correlation_id
- snapshot_at

## UI Components

Required components:
- FlowSummaryHeader
- FlowStatusBadge
- FlowTraceBar
- FlowTimeline
- FlowStepList
- FlowEventList
- FlowErrorPanel
- FlowSnapshotPanel
- FlowActionBar
- FlowEmptyState
- FlowLoadingState
- FlowErrorState

## Safety

DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
PANEL_ROUTE_DEPLOYED=NO
PANEL_BUILD_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
