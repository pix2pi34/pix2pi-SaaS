# FAZ 4B / 19.5 - UAT Checklist UI Contract

## Page

PAGE_ID=admin_uat_checklist
PAGE_ROUTE=/admin/uat/checklist
PAGE_TITLE=UAT Checklist
PAGE_SCOPE=tenant_admin
PAGE_STATUS=contract_only

## Required API Surfaces

| Method | Endpoint | Purpose | Tenant Required | Auth Required | Status |
| --- | --- | --- | --- | --- | --- |
| GET | /api/v1/admin/uat/checklists | UAT checklist list | YES | YES | contract_only |
| GET | /api/v1/admin/uat/checklists/:checklist_id | UAT checklist detail | YES | YES | contract_only |
| GET | /api/v1/admin/uat/checklists/:checklist_id/items | UAT checklist items | YES | YES | contract_only |
| POST | /api/v1/admin/uat/checklists/:checklist_id/items/:item_id/status | Update item status placeholder | YES | YES | contract_only |
| POST | /api/v1/admin/uat/checklists/:checklist_id/evidence | Attach evidence placeholder | YES | YES | contract_only |
| GET | /api/v1/admin/uat/checklists/:checklist_id/readiness | Go-live readiness summary | YES | YES | contract_only |
| GET | /api/v1/admin/uat/checklists/:checklist_id/blockers | Blocking item list | YES | YES | contract_only |
| GET | /api/v1/admin/uat/history | UAT history list | YES | YES | contract_only |

## Required UI Components

- UATChecklistShell
- UATReadinessSummary
- UATScenarioList
- UATScenarioDetailPanel
- UATStatusBadge
- UATEvidenceLinkPanel
- UATResponsibleOwnerPanel
- UATBlockingItemsPanel
- UATGoLiveReadinessGate
- UATCommentPanel
- UATHistoryPanel
- UATFlowLinkPanel
- UATIssueLinkPanel
- UATEmptyState
- UATLoadingState
- UATErrorState

## Required Payload Fields

Her UAT checklist payload içinde minimum şu alanlar bulunmalıdır:

- checklist_id
- tenant_id
- pilot_id
- checklist_title
- checklist_status
- readiness_percent
- total_item_count
- passed_item_count
- failed_item_count
- blocked_item_count
- not_started_item_count
- blocking_item_count
- go_live_allowed
- scenario_id
- scenario_name
- scenario_status
- evidence_required
- evidence_url
- owner_user_id
- owner_role_code
- reviewer_user_id
- reviewer_role_code
- runtime_flow_run_id
- issue_id
- request_id
- correlation_id
- created_at
- updated_at

## UAT Status Values

- NOT_STARTED
- IN_PROGRESS
- PASS
- FAIL
- BLOCKED
- SKIPPED
- NEEDS_REVIEW

## Go-live Readiness Rules

- `go_live_allowed=false` olmalı, eğer blocking item varsa.
- `go_live_allowed=false` olmalı, eğer failed item varsa.
- `go_live_allowed=true` sadece required senaryolar PASS veya SKIPPED değilse kapalı kalır.
- Evidence required olan senaryolarda evidence_url boşsa readiness düşer.
- Reviewer approval ileride RBAC/audit gate ile bağlanır.

## Tenant Boundary Contract

- `tenant_id` UAT checklist payload içinde zorunludur.
- UAT checklist tenant scope olmadan görüntülenemez.
- UAT scenario tenant context olmadan güncellenemez.
- UAT evidence başka tenant kaydına bağlanamaz.
- UAT blocker başka tenant issue kaydına bağlanamaz.
- UAT runtime flow link tenant uyumlu olmak zorundadır.
- UAT issue link tenant uyumlu olmak zorundadır.
- UAT history her zaman tenant filtreli döner.
- Cross-tenant checklist, cross-tenant evidence ve cross-tenant go-live onayı yasaktır.

## Safety

DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
UAT_RUNTIME_EXECUTED=NO
UAT_STATUS_UPDATE_EXECUTED=NO
UAT_EVIDENCE_UPLOAD_EXECUTED=NO
GO_LIVE_APPROVAL_EXECUTED=NO
PANEL_ROUTE_DEPLOYED=NO
PANEL_BUILD_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
