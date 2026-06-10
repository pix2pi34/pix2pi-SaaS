# FAZ 4B / 19.3 - Admin Dashboard Cards Contract

## Page

PAGE_ID=admin_dashboard
PAGE_ROUTE=/admin/dashboard
PAGE_TITLE=Admin Dashboard
PAGE_SCOPE=tenant_admin
PAGE_STATUS=contract_only

## Required API Surfaces

| Method | Endpoint | Purpose | Tenant Required | Auth Required |
| --- | --- | --- | --- | --- |
| GET | /api/v1/admin/dashboard/summary | Dashboard summary | YES | YES |
| GET | /api/v1/admin/dashboard/cards | Dashboard card payloads | YES | YES |
| GET | /api/v1/admin/dashboard/runtime-flows | Runtime flow card data | YES | YES |
| GET | /api/v1/admin/dashboard/imports | Import card data | YES | YES |
| GET | /api/v1/admin/dashboard/inventory | Inventory card data | YES | YES |
| GET | /api/v1/admin/dashboard/security | Tenant/security card data | YES | YES |
| GET | /api/v1/admin/dashboard/activity | Recent activity card data | YES | YES |

## Required Dashboard Cards

1. RuntimeFlowSummaryCard
2. RuntimeErrorCard
3. ImportStatusCard
4. InventoryHealthCard
5. StockReservationCard
6. NegativeStockPolicyCard
7. ReportingHealthCard
8. TenantSafetyCard
9. RecentActivityCard
10. UATReadinessCard

## Required Card Fields

Her kart payload içinde minimum şu alanlar bulunmalıdır:

- card_id
- tenant_id
- card_title
- card_status
- card_severity
- primary_metric_key
- primary_metric_value
- secondary_metric_key
- secondary_metric_value
- last_updated_at
- drilldown_route
- action_label
- empty_state_message
- error_state_message

## Card Summaries

### RuntimeFlowSummaryCard

Amaç:
- Son runtime flow sayısı
- Başarılı / hatalı flow sayısı
- Ortalama süre
- Flow detail drilldown

Drilldown:
- `/admin/runtime-flows`

### RuntimeErrorCard

Amaç:
- Açık hata sayısı
- Son hata zamanı
- Severity dağılımı
- Issue feedback / incident hazırlığı

Drilldown:
- `/admin/runtime-flows?status=failed`

### ImportStatusCard

Amaç:
- Import batch durumu
- Başarılı / hatalı satır sayısı
- Son import zamanı
- Import wizard hazırlığı

Drilldown:
- `/admin/imports`

### InventoryHealthCard

Amaç:
- Stok hareket sağlığı
- Sales decrement / purchase increment / valuation özetleri
- Negative stock uyarıları

Drilldown:
- `/admin/inventory`

### StockReservationCard

Amaç:
- Aktif rezervasyon sayısı
- Expire olacak rezervasyonlar
- Released / consumed özetleri

Drilldown:
- `/admin/inventory/reservations`

### NegativeStockPolicyCard

Amaç:
- Block / warn / allow policy özetleri
- Policy karar sayıları
- Approval required sinyali

Drilldown:
- `/admin/inventory/negative-stock-policy`

### ReportingHealthCard

Amaç:
- Readmodel/reporting mart tazeliği
- Geciken projection sayısı
- Raporlama sağlık durumu

Drilldown:
- `/admin/reporting`

### TenantSafetyCard

Amaç:
- Tenant scope durumu
- Header/JWT uyum hazırlığı
- RBAC/audit gate bağlantısı

Drilldown:
- `/admin/security/tenant-safety`

### RecentActivityCard

Amaç:
- Son runtime/event/import/activity listesi
- Request/correlation trace linkleri

Drilldown:
- `/admin/activity`

### UATReadinessCard

Amaç:
- Pilot UAT hazırlık yüzdesi
- Açık kontrol maddeleri
- Go-live rehearsal hazırlığı

Drilldown:
- `/admin/uat`

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
