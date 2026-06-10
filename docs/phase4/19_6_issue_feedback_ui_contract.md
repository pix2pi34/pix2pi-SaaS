# FAZ 4B / 19.6 - Issue / Feedback UI Contract

## Page

PAGE_ID=admin_issue_feedback
PAGE_ROUTE=/admin/issues-feedback
PAGE_TITLE=Issue / Feedback
PAGE_SCOPE=tenant_admin
PAGE_STATUS=contract_only

## Required API Surfaces

| Method | Endpoint | Purpose | Tenant Required | Auth Required | Status |
| --- | --- | --- | --- | --- | --- |
| GET | /api/v1/admin/issues/summary | Issue summary cards | YES | YES | contract_only |
| GET | /api/v1/admin/issues | Issue list | YES | YES | contract_only |
| POST | /api/v1/admin/issues | Create issue placeholder | YES | YES | contract_only |
| GET | /api/v1/admin/issues/:issue_id | Issue detail | YES | YES | contract_only |
| POST | /api/v1/admin/issues/:issue_id/comments | Add issue comment placeholder | YES | YES | contract_only |
| POST | /api/v1/admin/issues/:issue_id/evidence | Attach evidence placeholder | YES | YES | contract_only |
| POST | /api/v1/admin/issues/:issue_id/status | Update issue status placeholder | YES | YES | contract_only |
| GET | /api/v1/admin/feedback | Feedback list | YES | YES | contract_only |
| POST | /api/v1/admin/feedback | Create feedback placeholder | YES | YES | contract_only |

## Required UI Components

- IssueFeedbackShell
- IssueSummaryCards
- IssueCreateForm
- FeedbackCreateForm
- IssueTypeSelector
- IssueSeveritySelector
- IssuePrioritySelector
- IssueContextLinkPanel
- IssueRuntimeFlowLinkPanel
- IssueUATLinkPanel
- IssueImportLinkPanel
- IssueEvidencePanel
- IssueCommentPanel
- IssueStatusTimeline
- IssueAssigneePanel
- IssueListTable
- FeedbackListTable
- IssueEmptyState
- IssueLoadingState
- IssueErrorState

## Required Payload Fields

Her issue / feedback payload içinde minimum şu alanlar bulunmalıdır:

- issue_id
- feedback_id
- tenant_id
- issue_no
- feedback_no
- issue_type
- feedback_type
- issue_title
- issue_description
- issue_status
- feedback_status
- severity
- priority
- source_page
- source_route
- runtime_flow_run_id
- uat_checklist_id
- uat_item_id
- import_batch_id
- inventory_context_id
- evidence_required
- evidence_url
- assignee_user_id
- reporter_user_id
- reporter_role_code
- request_id
- correlation_id
- created_at
- updated_at

## Issue Status Values

- OPEN
- TRIAGED
- IN_PROGRESS
- WAITING_USER
- RESOLVED
- CLOSED
- DUPLICATE
- CANCELLED

## Feedback Status Values

- NEW
- REVIEWED
- ACCEPTED
- PLANNED
- REJECTED
- ARCHIVED

## Severity Values

- INFO
- LOW
- MEDIUM
- HIGH
- CRITICAL

## Priority Values

- P0
- P1
- P2
- P3
- P4

## Context Link Rules

- `runtime_flow_run_id` 19.1 Runtime flow history ile tenant uyumlu olmalıdır.
- `uat_checklist_id` ve `uat_item_id` 19.5 UAT checklist ile tenant uyumlu olmalıdır.
- `import_batch_id` 19.4 Import wizard ile tenant uyumlu olmalıdır.
- `inventory_context_id` 18 Inventory Pilot Motoru ile tenant uyumlu olmalıdır.
- Evidence link tenant sınırını aşamaz.
- Request/correlation trace alanları issue debug için korunur.

## Tenant Boundary Contract

- `tenant_id` issue payload içinde zorunludur.
- `tenant_id` feedback payload içinde zorunludur.
- Issue list her zaman tenant filtreli döner.
- Feedback list her zaman tenant filtreli döner.
- Issue detail başka tenant kaydını gösteremez.
- Feedback detail başka tenant kaydını gösteremez.
- Evidence link başka tenant dosyasına bağlanamaz.
- Runtime flow link başka tenant flow kaydına bağlanamaz.
- UAT link başka tenant checklist kaydına bağlanamaz.
- Import link başka tenant batch kaydına bağlanamaz.
- Cross-tenant issue, cross-tenant feedback ve cross-tenant evidence yasaktır.

## Safety

DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
ISSUE_RUNTIME_EXECUTED=NO
ISSUE_CREATE_EXECUTED=NO
FEEDBACK_CREATE_EXECUTED=NO
ISSUE_STATUS_UPDATE_EXECUTED=NO
ISSUE_EVIDENCE_UPLOAD_EXECUTED=NO
PANEL_ROUTE_DEPLOYED=NO
PANEL_BUILD_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
