# 227 — FAZ 4-16.7.2 Cutover Checklist

## Amaç

226 Dry-run Canlıya Geçiş PASS olduktan sonra gerçek canlıya geçiş öncesi cutover checklist standardını hazırlar.

Bu adım canlıya geçiş yapmaz. Sadece cutover için gerekli checklist maddelerini, owner sorumluluklarını, evidence bağlantılarını, backup/rollback hazırlığını, iletişim hazırlığını, runtime/monitoring kontrollerini ve dış provider policy kapılarını doğrular.

## Kapsam

- Cutover kickoff checklist
- Dry-run result link
- Tenant readiness confirmation
- Import freeze confirmation
- Readmodel/reporting confirmation
- UAT closure confirmation
- Backup snapshot confirmation
- Rollback package confirmation
- Route/DNS/Nginx plan confirmation
- Runtime health confirmation
- Monitoring watch confirmation
- Support watch confirmation
- Communication plan confirmation
- Approval owner confirmation
- External provider policy closed confirmation
- Final checklist report

## Ana Kural

Bu adım production launch yapmaz.

Bu adım DNS, Nginx, SSL, provider, GIB, banka, POS, ödeme sağlayıcı veya production route değişikliği yapmaz.

Bu adım gerçek rollback çalıştırmaz.

Bu adım sadece cutover checklist hazırlığı ve validasyonu yapar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Cutover checklist PASS sayılırsa:

- cutover_checklist_status = READY olmalıdır.
- cutover_checklist_mode = CONTROLLED_PILOT olmalıdır.
- required checklist item'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_item_count gerçek item sayısıyla eşleşmelidir.
- ready_item_count gerçek READY sayısıyla eşleşmelidir.
- missing_item_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- open_blocker_count = 0 olmalıdır.
- dry_run_go_live_status = PASS olmalıdır.
- backup_snapshot_status = READY olmalıdır.
- rollback_package_status = READY olmalıdır.
- route_plan_status = READY olmalıdır.
- runtime_health_status = READY olmalıdır.
- monitoring_watch_status = READY olmalıdır.
- support_watch_status = READY olmalıdır.
- communication_plan_status = READY olmalıdır.
- approval_owner_status = READY olmalıdır.
- no_production_launch = true olmalıdır.
- no_dns_change = true olmalıdır.
- no_nginx_change = true olmalıdır.
- no_ssl_change = true olmalıdır.
- no_live_external_provider_activation = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Cutover checklist dokümanı vardır.
- Master config artifact vardır.
- Cutover checklist artifact vardır.
- Checklist item kanıt dokümanları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid checklist fixture PASS döner.
- Invalid checklist fixture FAIL döner.
- Required item guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Backup/rollback/route/runtime/monitoring/support/approval guard doğrulanır.
- No production launch / no DNS / no Nginx / no SSL / no provider activation guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
