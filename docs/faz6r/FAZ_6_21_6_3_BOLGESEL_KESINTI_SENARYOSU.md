# FAZ 6-R / 290 — FAZ 6-21.6.3 Bölgesel Kesinti Senaryosu

## Amaç

Pix2pi için bölgesel kesinti durumunda izlenecek DR senaryosunu tanımlar.

Bu adım canlı DNS, Cloudflare, database, object storage, queue veya compute failover yapmaz. Önce provider-neutral bölgesel kesinti senaryosu, dry-run karar modeli, fixture, validator, audit ve evidence üretir.

## Bağımlılık

- FAZ 6-21.7.5 SRE metric review

## Required Controls

- sre_metric_review_dependency_gate
- regional_outage_scope_model
- affected_surface_inventory
- rto_rpo_policy
- failover_decision_policy
- dns_failover_guard
- db_failover_guard
- queue_failover_guard
- storage_failover_guard
- read_only_degradation_policy
- manual_approval_policy
- communication_handoff_policy
- dry_run_scenario_runtime
- provider_mutation_closed_policy
- evidence_capture_policy
- final_status_policy

## DR İlkeleri

1. Canlı failover bu adımda çalıştırılmaz.
2. DNS, DB, queue, storage ve compute mutation kapalıdır.
3. Bölgesel kesinti önce scope ve etki yüzeyi ile sınıflandırılır.
4. RTO/RPO hedefleri karar modeline yazılır.
5. Read-only degrade mode karar modeli oluşturulur.
6. P0/P1 olaylarda manual approval gerekir.
7. Operasyonel iletişim planı sonraki adımda detaylanır.
8. Evidence olmadan DR rehearsal aşamasına geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- SCENARIO_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

