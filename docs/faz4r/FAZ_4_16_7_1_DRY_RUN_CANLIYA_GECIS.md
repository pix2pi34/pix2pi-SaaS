# 226 — FAZ 4-16.7.1 Dry-run Canlıya Geçiş

## Amaç

Controlled pilot sonrası gerçek canlıya geçmeden önce bütün cutover akışının kuru prova olarak doğrulanmasını sağlar.

Bu adım production launch yapmaz. Sadece geçiş adımlarının sırasını, sorumlularını, rollback hazırlığını, iletişim hazırlığını, tenant durumunu, veri/import kapanışını, UAT kapanışını, destek/feedback kapanışını ve external policy kapılarını dry-run seviyesinde kontrol eder.

## Kapsam

- Dry-run kickoff
- Tenant readiness gate
- Import closure gate
- Readmodel/reporting readiness gate
- UAT closure gate
- Support/feedback closure gate
- Backup snapshot readiness
- Rollback readiness
- Cutover owner assignment
- Communication draft readiness
- DNS/Nginx route dry-run check
- Runtime health dry-run check
- Monitoring dashboard dry-run check
- External provider policy closed gate
- Dry-run final report

## Ana Kural

Bu adım gerçek canlıya geçiş yapmaz.

Bu adım DNS, Nginx, SSL, provider, GIB, banka, POS, ödeme sağlayıcı veya production route değişikliği yapmaz.

Bu adım sadece dry-run validasyonu yapar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Dry-run canlıya geçiş PASS sayılırsa:

- dry_run_status = READY olmalıdır.
- dry_run_mode = CONTROLLED_PILOT olmalıdır.
- required dry-run rule'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_rule_count gerçek rule sayısıyla eşleşmelidir.
- ready_rule_count gerçek READY sayısıyla eşleşmelidir.
- missing_rule_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- open_blocker_count = 0 olmalıdır.
- feedback_closure_status = PASS olmalıdır.
- tenant_readiness_status = READY olmalıdır.
- import_closure_status = READY olmalıdır.
- uat_closure_status = READY olmalıdır.
- backup_snapshot_status = READY olmalıdır.
- rollback_readiness_status = READY olmalıdır.
- monitoring_status = READY olmalıdır.
- no_production_launch = true olmalıdır.
- no_dns_change = true olmalıdır.
- no_nginx_change = true olmalıdır.
- no_live_external_provider_activation = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Dry-run canlıya geçiş dokümanı vardır.
- Master config artifact vardır.
- Dry-run artifact vardır.
- Dry-run rule kanıt dokümanları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid dry-run fixture PASS döner.
- Invalid dry-run fixture FAIL döner.
- Required rule guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Readiness/status guard doğrulanır.
- No production launch / no DNS / no Nginx / no provider activation guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
