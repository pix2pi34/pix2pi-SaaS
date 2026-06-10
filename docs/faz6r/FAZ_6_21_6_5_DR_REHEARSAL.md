# FAZ 6-R / 292 — FAZ 6-21.6.5 DR Rehearsal

## Amaç

Pix2pi için DR rehearsal standardını kurar.

Bu adım canlı DNS, DB, queue, storage, compute, customer notification veya provider mutation çalıştırmaz. DR rehearsal yalnızca dry-run / evidence-first şekilde uygulanır.

## Bağımlılık

- FAZ 6-21.6.4 Operasyonel iletişim planı

## Required Controls

- operational_communication_dependency_gate
- rehearsal_scope_model
- rehearsal_step_catalog
- preflight_check_policy
- rto_rpo_measurement_policy
- backup_restore_readiness_check
- regional_outage_scenario_link
- communication_plan_link
- rollback_readiness_check
- no_live_failover_policy
- no_provider_mutation_policy
- dry_run_rehearsal_runtime
- evidence_capture_policy
- final_status_policy

## DR Rehearsal İlkeleri

1. Rehearsal canlı failover değildir.
2. DNS, DB promotion, queue migration, storage failover ve compute failover kapalıdır.
3. RTO/RPO ölçümü dry-run olarak yapılır.
4. Backup/restore readiness sadece kanıt kontrolü olarak geçer.
5. Operasyonel iletişim planı ile bağlantı kurulur.
6. Rollback readiness doğrulanır.
7. Rehearsal sonrası evidence üretilir.
8. Canlı mutasyon olmadan rehearsal PASS olabilir.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- REHEARSAL_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

