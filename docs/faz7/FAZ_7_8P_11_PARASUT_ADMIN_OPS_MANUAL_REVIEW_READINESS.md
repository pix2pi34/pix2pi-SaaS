# FAZ 7-8P.11 Paraşüt Connector Admin / Ops / Manual Review Readiness

## Amaç

FAZ 7-8P.11, Paraşüt connector tarafında oluşabilecek failed sync, retry bekleyen event, webhook dispute ve token/credential operasyonlarını tenant-safe admin/ops yüzeyinde yönetilebilir hale getirir.

Bu modül gerçek Paraşüt API çağrısı yapmaz. Gerçek ERP write yapmaz. Gerçek retry job çalıştırmaz. Manual review queue, admin read/list, assign/retry/ignore/resolve/reject action contract, tenant-safe guard ve audit trail readiness katmanını kurar.

## Akış

1. Failed sync / provider error / webhook dispute review item oluşturulur.
2. Review item tenant/provider/app guard ile kuyruğa alınır.
3. Admin tenant-safe listeleme yapar.
4. Admin tenant-safe detay okur.
5. Ops kullanıcısı review item assign eder.
6. Retry / ignore / resolve / reject action uygulanır.
7. Action audit event yazılır.
8. Queue snapshot / metrics üretilir.
9. Cross-tenant read/action engellenir.
10. Real provider API ve real ERP write kapalı kalır.

## Kapsam

### 7-8P.11.1 Manual Review Queue Contract

- Review item model
- Tenant ID zorunlu
- Provider key zorunlu
- App key zorunlu
- Review ID zorunlu
- Source event ID zorunlu
- Operation zorunlu
- Reason zorunlu
- Correlation ID zorunlu
- Initial status OPEN

### 7-8P.11.2 Tenant-Safe Admin List / Read

- Tenant scoped list
- Tenant scoped read
- Cross-tenant list isolation
- Cross-tenant read rejected
- Provider/app filter
- Status filter
- Audit-safe result model

### 7-8P.11.3 Ops Action Contract

- ASSIGN action
- RETRY action
- IGNORE action
- RESOLVE action
- REJECT action
- Actor required
- Reason required
- Invalid transition guard
- Cross-tenant action rejected

### 7-8P.11.4 Audit Trail / Observability

- Admin action audit event
- Queue metric snapshot
- Open review count
- Retry requested count
- Resolved count
- Ignored count
- Rejected count
- Correlation trace
- Source event trace

### 7-8P.11.5 Retry / Provider Gate Safety

- Retry action only requests retry
- Real retry job disabled
- Real provider API disabled
- Real ERP write disabled
- Real webhook endpoint disabled
- Manual review queue handoff marker

### 7-8P.11.6 Final Closure

- Docs readiness
- Config readiness
- Code readiness
- Tests readiness
- Real implementation audit readiness
- Admin ops manual review readiness
- Real provider API remains closed
- Real ERP write remains closed

## Bilinçli sınır

Bu modül şunları yapmaz:

- Gerçek admin UI açmaz
- Gerçek retry worker çalıştırmaz
- Gerçek Paraşüt API çağrısı yapmaz
- Gerçek ERP write yapmaz
- Gerçek webhook endpoint açmaz
- Production ops permission sistemi açmaz

Bu adım canlı ops/admin ekranı öncesi runtime contract ve test readiness katmanıdır.

## Final kapanış şartı

FAZ 7-8P.11 ancak aşağıdaki kontroller geçtiğinde PASS olur:

- Go testleri PASS
- Manual review queue contract mevcut
- Tenant-safe admin list/read mevcut
- Ops action contract mevcut
- Audit trail / observability mevcut
- Retry/provider gate safety mevcut
- Real implementation audit PASS
- Real provider API kapalı
- Real ERP write kapalı
