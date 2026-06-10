# FAZ 6-R / 285 — FAZ 6-21.7.1 Runbook Seti

## Amaç

Pix2pi SRE / Edge / Release operasyonları için standart runbook setini oluşturur.

Bu adım canlı sistemde remediation çalıştırmaz. Olay anında izlenecek SRE operasyon prosedürlerini, severity sınıflarını, komut güvenlik sınırlarını, rollback kriterlerini ve evidence zorunluluğunu tanımlar.

## Bağımlılık

- FAZ 6-21.4.5 Security edge audit

## Required Controls

- security_edge_audit_dependency_gate
- incident_severity_model
- runbook_index
- edge_security_incident_runbook
- tls_cert_incident_runbook
- api_outage_runbook
- db_degradation_runbook
- event_queue_backlog_runbook
- cache_degradation_runbook
- release_rollback_runbook
- evidence_capture_policy
- escalation_policy_placeholder
- manual_approval_policy
- no_destructive_default_policy
- final_status_policy

## Runbook İlkeleri

1. Önce teşhis, sonra aksiyon.
2. Destructive işlem varsayılan olarak kapalıdır.
3. Production müdahalesi için evidence ve owner şarttır.
4. Rollback kararı açık kriterle alınır.
5. SRE incident seviyesi P0/P1/P2/P3 olarak ayrılır.
6. Her runbook için: symptom, detection, first response, mitigation, rollback, evidence, owner alanları bulunur.
7. Otomatik remediation bu adımda çalıştırılmaz; sonraki adımda ele alınır.
8. Escalation zinciri bu adımda placeholder olarak tanımlanır; 288'de detaylanır.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- RUNBOOK_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

