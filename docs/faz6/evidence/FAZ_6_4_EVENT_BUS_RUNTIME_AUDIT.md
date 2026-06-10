# FAZ 6-4 Event Bus Runtime Audit Evidence

Generated At: 2026-05-01T14:34:54+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit runtime ortaminda event bus / queue / backlog SRE izlerini toplar. Destructive islem yapmaz.

FAZ_6_4_RUNTIME_AUDIT=STARTED ✅

---


## 6-4.1 Host / Kernel

```text
Linux vm12827.ovadns.com 5.15.0-176-generic #186-Ubuntu SMP Fri Mar 13 11:01:42 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
```

## 6-4.2 Docker Event Bus Containers

```text
NAMES                     IMAGE                             STATUS                PORTS
pix2pi_nats               nats:2.10-alpine                  Up 9 days             0.0.0.0:4222->4222/tcp, [::]:4222->4222/tcp, 0.0.0.0:8222->8222/tcp, [::]:8222->8222/tcp, 6222/tcp
```

## 6-4.3 Event-related Systemd Services

```text
  dm-event.service                                                                          loaded    inactive dead    Device-mapper event daemon
  lvm2-monitor.service                                                                      loaded    active   exited  Monitoring of LVM2 mirrors, snapshots etc. using dmeventd or progress polling
  lvm2-pvscan@8:3.service                                                                   loaded    active   exited  LVM event activation on device 8:3
  lvm2-pvscan@8:4.service                                                                   loaded    active   exited  LVM event activation on device 8:4
● nats.service                                                                              not-found inactive dead    nats.service
  pix2pi-accounting.service                                                                 loaded    active   running Pix2pi Accounting Service
  pix2pi-api-gateway.service                                                                loaded    active   running Pix2pi API Gateway
  pix2pi-auth.service                                                                       loaded    active   running Pix2pi Auth Service
  pix2pi-early-warning-runtime.service                                                      loaded    active   running Pix2pi Early Warning Runtime Monitor
  pix2pi-identity.service                                                                   loaded    active   running Pix2pi Identity Service
  pix2pi-incident-audit-runtime.service                                                     loaded    active   running Pix2pi Incident Audit Runtime Monitor
  pix2pi-jobs-runtime.service                                                               loaded    active   running Pix2pi Jobs Runtime Monitor
  pix2pi-mission-control.service                                                            loaded    active   running Pix2pi Mission Control
  pix2pi-notification-runtime.service                                                       loaded    active   running Pix2pi Notification Runtime Monitor
  pix2pi-panel.service                                                                      loaded    active   running Pix2pi Control Panel
  pix2pi-plugin-runtime.service                                                             loaded    active   running Pix2pi Plugin Runtime Monitor
  pix2pi-publicapi-runtime.service                                                          loaded    active   running Pix2pi Public API Runtime Monitor
  pix2pi-query-read-model.service                                                           loaded    active   running Pix2pi Query Read Model
  pix2pi-realtime-runtime.service                                                           loaded    active   running Pix2pi Realtime Channel Runtime Monitor
  pix2pi-runtime-topology.service                                                           loaded    active   running Pix2pi Runtime Health Topology Monitor
  pix2pi-service-registry.service                                                           loaded    active   running Pix2pi Service Registry
  pix2pi-user-created-consumer.service                                                      loaded    active   running Pix2pi User Created Consumer
  pix2pi-webhook-runtime.service                                                            loaded    active   running Pix2pi Webhook Runtime Monitor
  pix2pi-workflow-runtime.service                                                           loaded    active   running Pix2pi Workflow Runtime Monitor
  systemd-udevd.service                                                                     loaded    active   running Rule-based Manager for Device Events and Files
```

## 6-4.4 NATS / Event Ports

```text
LISTEN 0      4096       127.0.0.1:9010       0.0.0.0:*    users:(("pix2pi-api-gate",pid=4016338,fd=7))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:8080       0.0.0.0:*    users:(("docker-proxy",pid=4033,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:4222       0.0.0.0:*    users:(("docker-proxy",pid=3151,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:8222       0.0.0.0:*    users:(("docker-proxy",pid=3226,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:9002       0.0.0.0:*    users:(("docker-proxy",pid=2986,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:8080          [::]:*    users:(("docker-proxy",pid=4051,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:4222          [::]:*    users:(("docker-proxy",pid=3165,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:8222          [::]:*    users:(("docker-proxy",pid=3256,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:9002          [::]:*    users:(("docker-proxy",pid=3006,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096               *:9012             *:*    users:(("identity-api",pid=6565,fd=6))                                                                                                                                                                                                                     
```

## 6-4.5 NATS Monitoring varz Probe

```text
```

## 6-4.6 NATS JetStream jsz Probe

```text
```

## 6-4.7 NATS Connection connz Probe

```text
```

## 6-4.8 NATS Subscription subsz Probe

```text
```

## 6-4.9 Event Env Inventory

```text
===== .env =====
DB_HOST=localhost
DB_PORT=5433
DB_USER=pix2pi
DB_PASSWORD=***MASKED***
DB_NAME=pix2pi
REDIS_HOST=localhost
REDIS_PORT=6379
DB_READ_DSN=postgres://user:pass@localhost:5433/dbname?sslmode=disable
DB_WRITE_DSN=postgres://pix2pi:pix2pi@127.0.0.1:5433/pix2pi?sslmode=disable
DB_DSN=postgres://pix2pi:pix2pi@127.0.0.1:5433/pix2pi?sslmode=disable
===== /etc/pix2pi/ports.env =====
===== /opt/pix2pi/orchestrator/env/common.env =====
DB_WRITE_DSN="host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
DB_READ_DSN="host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
```

## 6-4.10 Event Scripts Inventory

```text
cmd/event-bus/event_bus_main.go
cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go
cmd/event-concurrency-test/event_concurrency_test_main.go
cmd/event-consumer/event_consumer_main.go
cmd/event-idempotency-test/event_idempotency_test_main.go
cmd/event-metadata-test/event_metadata_test_main.go
cmd/event-replay-test/event_replay_test_main.go
cmd/event-schema-test/event_schema_test_main.go
cmd/event-store-postgres-test/event_store_postgres_test_main.go
cmd/nats-publisher/nats_publisher_main.go
cmd/nats-subscriber/nats_subscriber_main.go
cmd/replay-service/replay_service_main.go
cmd/user-created-consumer/user_created_consumer_main.go
cmd/user-created-consumer/user_created_consumer_main_test.go
internal/erp/core/events/domain/erp_financial_event_record.go
internal/erp/core/events/service/erp_event_intake_service.go
internal/erp/core/events/service/erp_event_intake_service_test.go
internal/erp/core/events/service/erp_financial_event_service.go
internal/erp/core/eventstore/domain/erp_accounting_event.go
internal/erp/core/eventstore/engine/erp_event_processor.go
internal/erp/core/eventstore/service/erp_event_store_service.go
internal/erp/core/kernel/ufk/domain/erp_financial_event.go
internal/platform/dlq.go
internal/platform/dlq_test.go
internal/platform/eventbus/domain/event_message.go
internal/platform/eventbus/domain/event_message_test.go
internal/platform/eventbus/service/dlq_event_validator.go
internal/platform/eventbus/service/dlq_event_validator_test.go
internal/platform/eventbus/service/event_bus_service.go
internal/platform/eventbus/service/event_bus_service_integration_test.go
internal/platform/eventbus/service/tenant_safe_event_bus.go
internal/platform/eventbus/service/tenant_safe_event_bus_test.go
internal/platform/eventreplay/service/event_replay_service.go
internal/platform/eventreplay/service/event_replay_service_test.go
internal/platform/eventreplay/service/tenant_replay_builder.go
internal/platform/eventreplay/service/tenant_replay_builder_test.go
internal/platform/eventschema/domain/event_schema.go
internal/platform/eventschema/service/event_schema_service.go
internal/platform/eventstore/domain/event_store_record.go
internal/platform/eventstore/domain/event_store_record_test.go
internal/platform/eventstore/event_store.go
internal/platform/eventstore/service/event_store_port.go
internal/platform/eventstore/service/event_store_postgres_service.go
internal/platform/eventstore/service/event_store_service.go
internal/platform/eventstore/service/event_store_service_integration_test.go
internal/platform/eventstore/service/postgres_event_store_validation.go
internal/platform/eventstore/service/postgres_event_store_validation_test.go
internal/platform/eventstore/service/tenant_safe_event_store.go
internal/platform/eventstore/service/tenant_safe_event_store_test.go
internal/platform/idempotency/dedupe_finalize_contract.go
internal/platform/idempotency/dedupe_finalize_service.go
internal/platform/idempotency/dedupe_finalize_service_test.go
internal/platform/idempotency/dedupe_finalize_store.go
internal/platform/idempotency/dedupe_finalize_store_test.go
internal/platform/idempotency/dedupe_reserve_contract.go
internal/platform/idempotency/dedupe_reserve_service.go
internal/platform/idempotency/dedupe_reserve_service_test.go
internal/platform/idempotency/dedupe_reserve_store.go
internal/platform/idempotency/dedupe_reserve_store_test.go
internal/platform/idempotency/finalize_contract.go
internal/platform/idempotency/finalize_service.go
internal/platform/idempotency/finalize_service_test.go
internal/platform/idempotency/finalize_store.go
internal/platform/idempotency/finalize_store_test.go
internal/platform/idempotency.go
internal/platform/idempotency/reserve_contract.go
internal/platform/idempotency/reserve_service.go
internal/platform/idempotency/reserve_service_test.go
internal/platform/idempotency/reserve_store.go
internal/platform/idempotency/reserve_store_test.go
internal/platform/idempotency/row_provider.go
internal/platform/idempotency/runtime_integration_test.go
internal/platform/idempotency_test.go
internal/platform/jobsqueue/audit_contract.go
internal/platform/jobsqueue/audit_service.go
internal/platform/jobsqueue/audit_service_test.go
internal/platform/jobsqueue/audit_store.go
internal/platform/jobsqueue/audit_store_test.go
internal/platform/jobsqueue/backoff_contract.go
internal/platform/jobsqueue/backoff_service.go
internal/platform/jobsqueue/backoff_service_test.go
internal/platform/jobsqueue/backoff_store.go
internal/platform/jobsqueue/backoff_store_test.go
internal/platform/jobsqueue/claim_contract.go
internal/platform/jobsqueue/claim_service.go
internal/platform/jobsqueue/claim_service_test.go
internal/platform/jobsqueue/claim_store.go
internal/platform/jobsqueue/claim_store_test.go
internal/platform/jobsqueue/complete_contract.go
internal/platform/jobsqueue/complete_service.go
internal/platform/jobsqueue/complete_service_test.go
internal/platform/jobsqueue/complete_store.go
internal/platform/jobsqueue/complete_store_test.go
internal/platform/jobsqueue/dispatch_contract.go
internal/platform/jobsqueue/dispatch_service.go
internal/platform/jobsqueue/dispatch_service_test.go
internal/platform/jobsqueue/dispatch_store.go
internal/platform/jobsqueue/dispatch_store_test.go
internal/platform/jobsqueue/enqueue_contract.go
internal/platform/jobsqueue/enqueue_service.go
internal/platform/jobsqueue/enqueue_service_test.go
internal/platform/jobsqueue/enqueue_store.go
internal/platform/jobsqueue/enqueue_store_test.go
internal/platform/jobsqueue/progress_contract.go
internal/platform/jobsqueue/progress_service.go
internal/platform/jobsqueue/progress_service_test.go
internal/platform/jobsqueue/progress_store.go
internal/platform/jobsqueue/progress_store_test.go
internal/platform/jobsqueue/recovery_contract.go
internal/platform/jobsqueue/recovery_service.go
internal/platform/jobsqueue/recovery_service_test.go
internal/platform/jobsqueue/recovery_store.go
internal/platform/jobsqueue/recovery_store_test.go
internal/platform/jobsqueue/row_provider.go
internal/platform/jobsqueue/runtime_extended_integration_test.go
internal/platform/jobsqueue/runtime_integration_test.go
internal/platform/monitor/event_backlog_early_warning_service.go
internal/platform/monitor/event_backlog_early_warning_service_test.go
internal/platform/monitor/event_backlog_runtime_bridge_service.go
internal/platform/monitor/event_backlog_runtime_bridge_service_test.go
internal/platform/security/service/security_audit_event_service.go
internal/platform/security/service/security_audit_event_service_test.go
internal/platform/security/service/webhook_replay_guard_service.go
internal/platform/security/service/webhook_replay_guard_service_test.go
scripts/audit_faz6_4_event_bus_runtime.sh
scripts/event_platform_final_suite.sh
scripts/ops/backup_event_consumer_again.sh
scripts/ops/backup_event_consumer.sh
scripts/phase4b_audit_event_model.py
scripts/phase4b_audit_event_model.sh
scripts/__pycache__/phase4b_audit_event_model.cpython-310.pyc
scripts/step_event_platform_final_close_1.sh
scripts/step_event_platform_final_suite_inventory_1.sh
scripts/step_event_platform_final_suite_run_1.sh
scripts/test_faz6_4_event_bus_sre_readiness.sh
scripts/test/lvl7_erp_event_core_final_suite.sh
scripts/test/lvl7_event_queue_final_suite.sh
scripts/test_phase4b_audit_event_model.sh
```

## 6-4.11 Runtime Audit Interpretation

```text
6-4.1 Host inventory collected OK ✅
6-4.2 Docker event bus inventory collected OK ✅
6-4.3 Systemd event service inventory collected OK ✅
6-4.4 NATS/event ports inventory collected OK ✅
6-4.5 NATS /varz probe collected OK ✅
6-4.6 NATS /jsz probe collected OK ✅
6-4.7 NATS /connz probe collected OK ✅
6-4.8 NATS /subsz probe collected OK ✅
6-4.9 Event env inventory collected OK ✅
6-4.10 Event scripts inventory collected OK ✅
FAZ_6_4_RUNTIME_AUDIT=COMPLETE ✅
```
