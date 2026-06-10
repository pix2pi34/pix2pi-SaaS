# FAZ 4B / 19.4 - Import Wizard UI Contract

## Page

PAGE_ID=admin_import_wizard
PAGE_ROUTE=/admin/imports/wizard
PAGE_TITLE=Import Wizard
PAGE_SCOPE=tenant_admin
PAGE_STATUS=contract_only

## Required API Surfaces

| Method | Endpoint | Purpose | Tenant Required | Auth Required | Status |
| --- | --- | --- | --- | --- | --- |
| GET | /api/v1/admin/imports/templates | Import template list | YES | YES | contract_only |
| POST | /api/v1/admin/imports/upload | Upload import file placeholder | YES | YES | contract_only |
| POST | /api/v1/admin/imports/:import_batch_id/mapping | Save column mapping | YES | YES | contract_only |
| POST | /api/v1/admin/imports/:import_batch_id/validate | Validate staged data | YES | YES | contract_only |
| GET | /api/v1/admin/imports/:import_batch_id/preview | Preview staged rows | YES | YES | contract_only |
| GET | /api/v1/admin/imports/:import_batch_id/errors | Import error list / download | YES | YES | contract_only |
| POST | /api/v1/admin/imports/:import_batch_id/commit-plan | Controlled commit plan | YES | YES | contract_only |
| GET | /api/v1/admin/imports/history | Import history list | YES | YES | contract_only |

## Required Wizard Steps

1. ImportTemplateStep
2. ImportUploadStep
3. ImportMappingStep
4. ImportValidationStep
5. ImportPreviewStep
6. ImportErrorDownloadStep
7. ImportCommitPlanStep
8. ImportHistoryLinkStep

## Required Components

- ImportWizardShell
- ImportStepIndicator
- ImportTemplateSelector
- ImportFileDropzone
- ImportFileSummary
- ImportColumnMapper
- ImportValidationPanel
- ImportPreviewTable
- ImportErrorDownloadPanel
- ImportCommitPlanPanel
- ImportHistoryLinkPanel
- ImportFlowLinkPanel
- ImportEmptyState
- ImportLoadingState
- ImportErrorState

## Required Payload Fields

Her wizard payload içinde minimum şu alanlar bulunmalıdır:

- import_batch_id
- tenant_id
- import_type
- import_template_code
- upload_file_name
- upload_file_hash
- total_row_count
- valid_row_count
- invalid_row_count
- warning_count
- error_count
- mapping_status
- validation_status
- preview_status
- commit_plan_status
- runtime_flow_run_id
- request_id
- correlation_id
- created_at
- updated_at

## Import Types

- party_customer
- party_vendor
- product_item
- inventory_opening_stock
- inventory_stock_balance
- address_contact
- finance_opening_balance

## Wizard Safety Rules

- File upload gerçek runtime olarak çalıştırılmayacak; bu adım contract-only.
- Commit gerçek runtime olarak çalıştırılmayacak; bu adım commit-plan seviyesinde kalacak.
- Mapping tenant scope dışına çıkmayacak.
- Preview sadece staged data contract olarak tanımlanacak.
- Error download route contract-only kalacak.
- Runtime flow link 19.1 / 19.2 altyapısına bağlanmaya hazır olacak.

## Safety

DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
FILE_UPLOAD_EXECUTED=NO
IMPORT_RUNTIME_EXECUTED=NO
IMPORT_COMMIT_EXECUTED=NO
PANEL_ROUTE_DEPLOYED=NO
PANEL_BUILD_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
AUTH_TOKEN_PRINTED=NO

## 19.4R Tenant Boundary Contract

Tenant boundary kuralları:

- `tenant_id` import wizard payload içinde zorunlu bağlam alanıdır.
- `tenant_id` upload, mapping, validation, preview, error ve commit-plan akışlarında korunur.
- Import template seçimi tenant scope ile yapılır.
- Import batch oluşturma tenant context olmadan başlatılamaz.
- Import mapping başka tenant kolon şemasına bağlanamaz.
- Import preview başka tenant staged datasını gösteremez.
- Import error download sadece ilgili tenant import batch için çalışır.
- Import history her zaman tenant filtreli döner.
- Runtime flow link tenant uyumlu flow run ile eşleşir.
- Cross-tenant import operasyonu yasaktır.
