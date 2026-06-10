# 228 — FAZ 4-16.7.3 Geri Dönüş Provası

## Amaç

227 Cutover Checklist PASS olduktan sonra canlıya geçişte problem yaşanırsa geri dönüş akışının kuru prova seviyesinde hazır olduğunu doğrular.

Bu adım gerçek rollback çalıştırmaz. Sadece rollback senaryosu, owner, snapshot, veri geri dönüş sınırı, route geri alma planı, runtime health doğrulaması, monitoring, iletişim ve dış provider policy kapılarının hazır olduğunu kontrol eder.

## Kapsam

- Rollback rehearsal kickoff
- Cutover checklist link
- Backup snapshot link
- Rollback package link
- Rollback scope boundary
- Data restore dry-run plan
- App version restore dry-run plan
- Route/DNS/Nginx rollback plan
- Runtime health after rollback plan
- Monitoring watch after rollback plan
- Support communication rollback note
- Approval owner confirmation
- Rehearsal evidence attachment
- Rehearsal metrics
- External provider policy closed gate
- Final rollback rehearsal report

## Ana Kural

Bu adım gerçek rollback yapmaz.

Bu adım production launch yapmaz.

Bu adım DNS, Nginx, SSL, provider, GIB, banka, POS, ödeme sağlayıcı veya production route değişikliği yapmaz.

Bu adım sadece geri dönüş provası validasyonu yapar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Geri dönüş provası PASS sayılırsa:

- rollback_rehearsal_status = READY olmalıdır.
- rollback_rehearsal_mode = CONTROLLED_PILOT olmalıdır.
- required rehearsal item'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_item_count gerçek item sayısıyla eşleşmelidir.
- ready_item_count gerçek READY sayısıyla eşleşmelidir.
- missing_item_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- open_blocker_count = 0 olmalıdır.
- cutover_checklist_status = PASS olmalıdır.
- backup_snapshot_status = READY olmalıdır.
- rollback_package_status = READY olmalıdır.
- data_restore_plan_status = READY olmalıdır.
- app_restore_plan_status = READY olmalıdır.
- route_rollback_plan_status = READY olmalıdır.
- runtime_health_after_rollback_status = READY olmalıdır.
- monitoring_after_rollback_status = READY olmalıdır.
- support_communication_status = READY olmalıdır.
- approval_owner_status = READY olmalıdır.
- no_real_rollback_execution = true olmalıdır.
- no_production_launch = true olmalıdır.
- no_dns_change = true olmalıdır.
- no_nginx_change = true olmalıdır.
- no_ssl_change = true olmalıdır.
- no_live_external_provider_activation = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Geri dönüş provası dokümanı vardır.
- Master config artifact vardır.
- Rollback rehearsal artifact vardır.
- Rehearsal item kanıt dokümanları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid rehearsal fixture PASS döner.
- Invalid rehearsal fixture FAIL döner.
- Required item guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Backup/rollback/data/app/route/runtime/monitoring/support/approval guard doğrulanır.
- No real rollback / no production launch / no DNS / no Nginx / no SSL / no provider activation guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
