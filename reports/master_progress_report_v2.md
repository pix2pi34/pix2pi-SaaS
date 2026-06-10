# Pix2pi Master Progress Report v2

- Scanned files: **36195**
- Overall progress: **%66**
- Done: **30**
- Partial: **48**
- Todo: **4**

## Phase Summary

- 🟡 **1 FOUNDATION / PROJE TEMELİ** → %67 (confidence=62)
- 🟡 **2 SAAS CORE** → %64 (confidence=64)
- 🟡 **3 SERVİS / OPS** → %67 (confidence=57)
- 🟡 **4 API GATEWAY** → %55 (confidence=51)
- 🟡 **5 EVENT PLATFORM** → %69 (confidence=68)
- 🟡 **6 ERP / UFK** → %93 (confidence=83)
- 🟡 **7 REDIS / CACHE / REPORT** → %62 (confidence=68)
- 🟡 **8 TENANT SECURITY** → %56 (confidence=54)
- ✅ **9 QUERY / REPORTING** → %100 (confidence=90)
- 🟡 **10 INFRA / EDGE** → %33 (confidence=40)
- 🟡 **11 OBSERVABILITY / EARLY WARNING** → %70 (confidence=66)
- 🟡 **12 PLATFORM SERVISLERI** → %50 (confidence=50)
- 🟡 **13 ERP TURKIYE DERINLESME** → %50 (confidence=50)
- 🟡 **14 TEST / QUALITY GATE** → %50 (confidence=57)

## Detailed Tree

## 🟡 1 — FOUNDATION / PROJE TEMELİ (67%, confidence=62)

### 🟡 1.1.1 — Ana repo yapısı (50%, confidence=40)

Eksik Kanıt:
- test evidence
- run/live/ops evidence

Kanıt Özeti:
- code:
  - `.backups/import_fix_20260323_072726/internal/services/query_read_model/service.go`
  - `.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go`
  - `.backups/step_417_20260323_074642/internal/services/query_read_model/routes.go`
- config:
  - `PORTS.md`
  - `README.md`

### 🟡 1.1.2 — Entry point standardı (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go`
  - `.backups/step_422_20260323_080757/cmd/api-gateway/api_gateway_main.go`
  - `cmd/api-gateway/api_gateway_main.go`
- test:
  - `step_188_verify_done_items.sh`

### 🟡 1.2.1 — Config standardı (50%, confidence=40)

Eksik Kanıt:
- test evidence
- run/live/ops evidence

Kanıt Özeti:
- code:
  - `internal/common/config/config.go`
  - `internal/common/config/config.go.ok_bind_secret_20260228_073805`
  - `internal/common/config/config.go.ok_l23_jwtsecret_20260228_071958`
- config:
  - `configs/config.docker.yaml`
  - `configs/config.local.yaml`
  - `deploy/ports.env`

### ✅ 1.3.1 — PostgreSQL temel bağlantı (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/migrate/main.go`
  - `internal/db/migrations.bak_20260301_131246/0001_init.down.sql`
  - `internal/db/migrations.bak_20260301_131246/0001_init.up.sql`
- test:
  - `step_26_test_postgres_login.sh`
- run:
  - `step_24_start_postgres_runtime.sh`

### ✅ 1.4.1 — Docker temel çalışma (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `.backups/2026/04/06/.__Dockerfile_144849.bak`
  - `.backups/2026/04/06/.__Dockerfile_150238.bak`
  - `.backups/2026/04/06/.__Dockerfile_150828.bak`
- test:
  - `step_78_test_production_server_ready.sh`
- run:
  - `step_75_install_or_verify_docker.sh`

### 🟡 1.4.3 — Nginx temel kurulum (50%, confidence=50)

Eksik Kanıt:
- code/service evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `step_88_test_split_routes.sh`
  - `step_89_test_server_ssl.sh`
- run:
  - `step_79_install_nginx.sh`
  - `step_85_reload_nginx_split.sh`

## 🟡 2 — SAAS CORE (64%, confidence=64)

### ✅ 2.1.1 — Identity service (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `.backups/2026/04/06/.__cmd__identity-api__identity_main.go_152057.bak`
  - `.backups/2026/04/06/.__cmd__identity-api__identity_main.go_221249.bak`
  - `.backups/2026/04/06/.__cmd__identity-api__identity_main.go_221846.bak`
- test:
  - `step_101_test_identity_gateway_ports.sh`
- run:
  - `devtools/run_identity.sh`

### ✅ 2.1.2 — Login / auth akışı (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/auth-api/auth_api_main.go`
- test:
  - `step_123_test_auth_api_local.sh`
  - `step_124_test_auth_via_gateway.sh`
- run:
  - `step_122_run_auth_api.sh`

### 🟡 2.1.3 — JWT üretimi (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/identity/domain/tenant.go`
  - `internal/identity/domain/user.go`
  - `internal/identity/repository/memory_repo.go`
- test:
  - `step_5_run_jwt_tenant_test.sh`
  - `step_8_run_jwt_middleware_test.sh`

### 🟡 2.1.4 — JWT doğrulama (50%, confidence=30)

Eksik Kanıt:
- code/service evidence
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `step_132_test_gateway_bearer_tenant_match.sh`
- backup:
  - `step_130_backup_gateway_before_authz_layer.sh`

### 🟡 2.2.1 — Tenant context (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/platform/kernel/tenant_context.go`
  - `internal/platform/kernel/tenant_context.go.errscope_20260301_140741`
  - `internal/platform/kernel/tenant_context.go.fixerr_20260301_140437`
- test:
  - `step_10_run_tenant_event_pipeline_test.sh`
  - `step_2_run_tenant_test.sh`

### 🟡 2.2.2 — Tenant middleware (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/platform/kernel/tenant_context.go`
  - `internal/platform/kernel/tenant_context.go.errscope_20260301_140741`
  - `internal/platform/kernel/tenant_context.go.fixerr_20260301_140437`
- test:
  - `step_110_test_gateway_tenant_middleware.sh`
- backup:
  - `step_108_backup_api_gateway_before_tenant_middleware.sh`

### 🟡 2.2.4 — Tenant-aware request processing (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `.backups/import_fix_20260323_072726/internal/services/query_read_model/service.go`
  - `.backups/step_417_20260323_074642/internal/services/query_read_model/routes.go`
  - `.backups/step_417_20260323_074642/internal/services/query_read_model/service.go`
- test:
  - `step_12_run_tenant_service_filter_test.sh`
  - `step_250_tenant_isolation_verification.sh`

## 🟡 3 — SERVİS / OPS (67%, confidence=57)

### 🟡 3.2.1 — Service registry (50%, confidence=60)

Eksik Kanıt:
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/service-registry/service_registry_main.go`
- run:
  - `step_206_servis_yoneticisi_kur.sh`
- ops:
  - `config/service_watchdog_services.json`

### 🟡 3.3.1 — Backup mantığı (50%, confidence=30)

Eksik Kanıt:
- test evidence
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `.backups/2026/04/06/.__.gitignore_070441.bak`
  - `.backups/2026/04/06/.__.gitignore_143254.bak`
  - `.backups/2026/04/06/.__.gitignore_143424.bak`

### ✅ 3.3.2 — Retention (100%, confidence=80)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `scripts/ops_retention_cleanup.sh`
  - `scripts/run_ops_retention_daily.sh`
- test:
  - `scripts/test_ops_daily_alert_chain.sh`
- ops:
  - `reports/ops_health_latest.txt`

## 🟡 4 — API GATEWAY (55%, confidence=51)

### ✅ 4.1.1 — Tek giriş kapısı mimarisi (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go`
  - `.backups/step_422_20260323_080757/cmd/api-gateway/api_gateway_main.go`
  - `_backup/step_423h/pix2pi-api-gateway.service.2026-04-11_064622.bak`
- test:
  - `step_128_test_combined_gateway.sh`
- run:
  - `step_127_restart_combined_gateway.sh`
  - `step_99_run_api_gateway.sh`

### 🟡 4.1.2 — JWT enforce (50%, confidence=30)

Eksik Kanıt:
- code/service evidence
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `step_132_test_gateway_bearer_tenant_match.sh`

### 🟡 4.1.3 — Tenant enforce (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/platform/kernel/tenant_context.go`
  - `internal/platform/kernel/tenant_context.go.errscope_20260301_140741`
  - `internal/platform/kernel/tenant_context.go.fixerr_20260301_140437`
- test:
  - `step_110_test_gateway_tenant_middleware.sh`

### ✅ 4.1.6 — Gateway error mapping (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `step_420_rewrite_gateway.sh`
- test:
  - `step_414_test_api_gateway_local.sh`
- run:
  - `step_418_fix_gateway_panic.sh`
  - `step_422_rewrite_gateway_with_db_init.sh`

### ⏳ 4.2.1 — Request trace (0%, confidence=10)

Eksik Kanıt:
- code/service evidence
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- ops:
  - `step_423i_dump_runner_trace.sh`
  - `step_423j_dump_only_trace.sh`
  - `step_423j_trace_dump.txt`

### ✅ 4.2.3 — Health aggregation (100%, confidence=80)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `step_334_add_global_health_engine.sh`
- test:
  - `step_370_real_global_status.sh`
- ops:
  - `reports/ops_health_latest.txt`

### ✅ 4.2.4 — Rate limit (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `deploy/redis/docker-compose.yml`
- test:
  - `step_107_test_api_gateway_rate_limit.sh`
  - `step_115_test_gateway_redis_rate_limit.sh`
  - `step_71_run_rate_limit_test.sh`
- run:
  - `step_131_add_nginx_global_rate_limit.sh`

### ⏳ 4.2.5 — Kota yönetimi (0%, confidence=0)

Eksik Kanıt:
- code/service evidence
- test evidence
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- backup:
  - `step_69_backup_rate_limit.sh`

### ⏳ 4.2.6 — Request id / correlation (0%, confidence=10)

Eksik Kanıt:
- code/service evidence
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- ops:
  - `step_423i_dump_runner_trace.sh`

### 🟡 4.2.7 — Timeout / upstream policy (50%, confidence=50)

Eksik Kanıt:
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `step_420_rewrite_gateway.sh`
- run:
  - `step_409_fix_gateway.sh`
  - `step_422_rewrite_gateway_with_db_init.sh`

## 🟡 5 — EVENT PLATFORM (69%, confidence=68)

### 🟡 5.1.1 — Event publish standardı (50%, confidence=50)

Eksik Kanıt:
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/nats-publisher/nats_publisher_main.go`
  - `kernel/events/model/event.go`
  - `kernel/events/publisher/noop.go`
- run:
  - `step_166_run_nats_publisher.sh`

### ✅ 5.1.2 — Event consume standardı (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/event-consumer/event_consumer_main.go`
  - `cmd/nats-subscriber/nats_subscriber_main.go`
- test:
  - `step_39_run_event_bus_test.sh`
- run:
  - `step_165_run_nats_subscriber.sh`

### ✅ 5.2.1 — NATS / JetStream omurgası (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/event-bus/event_bus_main.go`
  - `deploy/nats/docker-compose.yml`
- test:
  - `step_170_check_jetstream.sh`
  - `step_173_check_jetstream_stream.sh`
- run:
  - `step_160_install_nats_event_bus.sh`
  - `step_172_create_jetstream_stream.sh`

### 🟡 5.2.3 — Consumer durability (50%, confidence=60)

Eksik Kanıt:
- code/service evidence

Kanıt Özeti:
- test:
  - `step_175_check_sale_consumer.sh`
- run:
  - `step_174_create_sale_consumer.sh`
- config:
  - `deploy/nats/docker-compose.yml`

### 🟡 5.3.1 — Retry politikası (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/replay-service/replay_service_main.go`
  - `kernel/events/model/event.go`
  - `kernel/events/publisher/noop.go`
- test:
  - `step_194_test_retry.sh`
  - `step_41_run_event_retry_test.sh`
- backup:
  - `step_40_backup_event_retry.sh`

### 🟡 5.3.2 — Idempotency (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `kernel/events/model/event.go`
  - `kernel/events/publisher/noop.go`
  - `kernel/events/publisher/publisher.go`
- test:
  - `step_193_test_idempotency.sh`
  - `step_43_run_event_idempotency_test.sh`
- backup:
  - `step_42_backup_event_idempotency.sh`

### 🟡 5.3.3 — DLQ (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `kernel/events/model/event.go`
  - `kernel/events/publisher/noop.go`
  - `kernel/events/publisher/publisher.go`
- test:
  - `step_195_test_dlq.sh`
  - `step_45_run_event_dlq_test.sh`
- backup:
  - `step_44_backup_event_dlq.sh`

### 🟡 5.3.4 — Poison message yönetimi (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `kernel/events/model/event.go`
  - `kernel/events/publisher/noop.go`
  - `kernel/events/publisher/publisher.go`
- test:
  - `step_195_test_dlq.sh`
  - `step_45_run_event_dlq_test.sh`

### ✅ 5.3.5 — Replay (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/replay-service/replay_service_main.go`
- test:
  - `step_50_run_event_replay_test.sh`
- run:
  - `step_196_run_replay_service.sh`

### ✅ 5.3.8 — Event audit trail (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `step_210_prepare_audit_folder.sh`
- test:
  - `step_211_test_audit_engine.sh`
- run:
  - `step_210_audit_full.sh`
  - `step_261_audit_full.sh`

### ✅ 5.4.1 — Event store (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `step_200_create_event_store_table.sql`
- test:
  - `step_202_test_event_store.sh`
- run:
  - `step_201_apply_event_store.sh`

### 🟡 5.4.2 — Bus-store integration (50%, confidence=30)

Eksik Kanıt:
- code/service evidence
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `step_52_run_event_bus_store_integration_test.sh`
- backup:
  - `step_51_backup_event_bus_store_integration.sh`

### 🟡 5.4.3 — Event platform test suite (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `test/internal/finance/test/accounts/accounts_test.go`
  - `test/internal/finance/test/ledger/intercompany_test.go`
  - `test/internal/finance/test/ledger/ledger_event_test.go`
- test:
  - `step_202_test_event_store.sh`
  - `step_39_run_event_bus_test.sh`

## 🟡 6 — ERP / UFK (93%, confidence=83)

### ✅ 6.1.2 — UFK çekirdeği (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/erp/core/ufk/erp_ufk_main.go`
  - `internal/ufk/domain/journal_line.go`
  - `internal/ufk/domain/ledger_account.go`
- test:
  - `scripts/prod_finance_smoke.sh`
- run:
  - `step_5_run_ufk_engine.sh`
  - `step_run_ufk_journal_ledger.sh`

### ✅ 6.2.1 — Journal builder (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/erp/core/alis/domain/erp_alis_fatura.go`
  - `internal/erp/core/alis/domain/erp_alis_fatura_satir.go`
  - `internal/erp/core/alis/service/erp_alis_fatura_service.go`
- test:
  - `step_206_test_journal_builder.sh`
  - `step_55_run_journal_builder_test.sh`
- run:
  - `step_6_run_journal_builder.sh`

### ✅ 6.2.2 — Journal repository (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `step_203_create_journal_tables.sql`
- test:
  - `step_207_test_journal_repository.sh`
- run:
  - `step_204_apply_journal_tables.sh`

### ✅ 6.2.3 — Ledger posting pipeline (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/erp/core/alis/domain/erp_alis_fatura.go`
  - `internal/erp/core/alis/domain/erp_alis_fatura_satir.go`
  - `internal/erp/core/alis/service/erp_alis_fatura_service.go`
- test:
  - `step_57_run_ledger_posting_test.sh`
- run:
  - `step_7_run_ledger_posting.sh`
- backup:
  - `step_56_backup_ledger_posting.sh`

### 🟡 6.2.4 — Financial flow recon (50%, confidence=40)

Eksik Kanıt:
- code/service evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `step_56a_finance_recon.sh`
  - `step_56c_finance_flow_recon.sh`
- ops:
  - `step_56a_finance_recon.txt`
  - `step_56c_finance_flow_recon.txt`

### ✅ 6.3.1 — Tax engine (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/finance/domain/account.go`
  - `test/internal/finance/test/accounts/accounts_test.go`
  - `test/internal/finance/test/ledger/intercompany_test.go`
- test:
  - `step_6_check_tax_engine_files.sh`
- run:
  - `step_220_tax_engine_full.sh`
  - `step_7_run_tax_engine.sh`

### ✅ 6.3.2 — Audit engine (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `step_260_create_audit_tables.sql`
- test:
  - `step_211_test_audit_engine.sh`
- run:
  - `step_261_audit_full.sh`
  - `step_262_run_audit_flow.sh`

## 🟡 7 — REDIS / CACHE / REPORT (62%, confidence=68)

### ✅ 7.1.1 — Redis entegrasyonu (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/cache-service/cache_service_main.go`
  - `cmd/redis-test/redis_test_main.go`
  - `deploy/redis/docker-compose.yml`
- test:
  - `step_190_test_cache_service.sh`
  - `step_62_run_real_redis_cache_test.sh`
- run:
  - `step_189_run_cache_service.sh`
  - `step_61_add_redis_module.sh`

### 🟡 7.1.3 — Redis namespace tenant ayrımı (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/cache-service/cache_service_main.go`
- test:
  - `step_15_run_redis_tenant_namespace_test.sh`
- backup:
  - `step_13_backup_redis_tenant_namespace.sh`

### 🟡 7.1.4 — Read/write split (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/query-read-model/query_read_model_main.go`
  - `cmd/query-read-model/query_read_model_main_test.go`
- test:
  - `step_65_run_read_write_split_test.sh`
- backup:
  - `step_63_backup_read_write_split.sh`

### 🟡 7.1.5 — Reporting store (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/reporting-service/reporting_service_main.go`
  - `cmd/reporting-service/reporting_service_main_test.go`
- test:
  - `step_68_run_reporting_store_test.sh`
- backup:
  - `step_66_backup_reporting_store.sh`

## 🟡 8 — TENANT SECURITY (56%, confidence=54)

### 🟡 8.1.1 — JWT tenant standardı (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/platform/kernel/tenant_context.go`
  - `internal/platform/kernel/tenant_context.go.errscope_20260301_140741`
  - `internal/platform/kernel/tenant_context.go.fixerr_20260301_140437`
- test:
  - `step_5_run_jwt_tenant_test.sh`
- backup:
  - `step_3_backup_jwt_tenant.sh`

### 🟡 8.1.2 — Event payload tenant zorunluluğu (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `kernel/events/model/event.go`
  - `kernel/events/publisher/noop.go`
  - `kernel/events/publisher/publisher.go`
- test:
  - `step_10_run_tenant_event_pipeline_test.sh`

### 🟡 8.1.4 — Audit trail tenant zorunluluğu (50%, confidence=50)

Eksik Kanıt:
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `step_260_create_audit_tables.sql`
- run:
  - `step_262_run_audit_flow.sh`

### 🟡 8.1.5 — Tüm servislerde tenant filter (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `.backups/import_fix_20260323_072726/internal/services/query_read_model/service.go`
  - `.backups/step_417_20260323_074642/internal/services/query_read_model/routes.go`
  - `.backups/step_417_20260323_074642/internal/services/query_read_model/service.go`
- test:
  - `step_12_run_tenant_service_filter_test.sh`
- backup:
  - `step_11_backup_tenant_service_filter.sh`

### 🟡 8.1.6 — Super-admin erişim sınırları (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/platform/kernel/policy_cache.go`
  - `internal/platform/kernel/policy_cache.go.ok_20260225_214931`
  - `internal/platform/kernel/policy_cache.go.ok_20260225_215042`
- test:
  - `step_18_run_super_admin_policy_test.sh`
- backup:
  - `step_16_backup_super_admin_policy.sh`

### ✅ 8.2.1 — PostgreSQL RLS policy (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/db/migrations/0001_init.down.sql`
  - `internal/db/migrations/0001_init.up.sql`
  - `internal/db/migrations/0002_tenant_meta.down.sql`
- test:
  - `step_21_run_postgres_rls_test.sh`
  - `step_243_test_rls_real.sh`
- run:
  - `step_240_enable_rls_snapshots.sh`

### 🟡 8.2.3 — Tenant isolation verification (50%, confidence=50)

Eksik Kanıt:
- code/service evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `step_250_tenant_isolation_verification.sh`
- run:
  - `step_251_fix_verification.sh`

### 🟡 8.3.1 — Export izolasyonu (50%, confidence=30)

Eksik Kanıt:
- code/service evidence
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `step_33_run_export_isolation_test.sh`
- backup:
  - `step_31_backup_export_isolation.sh`

### 🟡 8.3.2 — Backup izolasyonu (50%, confidence=30)

Eksik Kanıt:
- code/service evidence
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `step_36_run_backup_isolation_test.sh`
- backup:
  - `step_34_backup_backup_isolation.sh`

## ✅ 9 — QUERY / REPORTING (100%, confidence=90)

### ✅ 9.1.1 — Query read model (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/query-read-model/query_read_model_main.go`
  - `cmd/query-read-model/query_read_model_main_test.go`
- test:
  - `step_407_test_query.sh`
  - `step_408d_verify_query_service.sh`
- run:
  - `step_202_query_read_model_kur_ve_test_et.sh`
  - `step_407_create_query_service.sh`

### ✅ 9.1.2 — Projection rebuild (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `scripts/rebuild_read_users_projection.sh`
- test:
  - `scripts/query_post_restart_check.sh`
- run:
  - `scripts/query_ops_suite.sh`

### ✅ 9.1.3 — Query service gateway entegrasyonu (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go`
  - `.backups/step_422_20260323_080757/cmd/api-gateway/api_gateway_main.go`
  - `cmd/api-gateway/api_gateway_main.go`
- test:
  - `step_408_test_api_gateway_nethttp.sh`
- run:
  - `step_408_full_api_integration.sh`
  - `step_408e_patch_gateway.sh`

### ✅ 9.2.1 — Reporting service (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/reporting-service/reporting_service_main.go`
  - `cmd/reporting-service/reporting_service_main_test.go`
  - `cmd/reporting_service_main.go`
- test:
  - `step_198_reporting_service_json_sabitle.sh`
- run:
  - `step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh`

### ✅ 9.2.2 — Reporting subscriber (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/reporting-service/reporting_service_main.go`
  - `cmd/reporting-service/reporting_service_main_test.go`
- test:
  - `step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh`
- run:
  - `step_190_reporting_subscriber_kur_ve_calistir.sh`
  - `step_203_reporting_to_query_read_model_bagla.sh`

### ✅ 9.2.3 — Panel entegrasyonu (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/control-panel/control_panel.go`
  - `cmd/control-panel/ui/index.html`
  - `cmd/control-panel/ui/mission-control.html`
- test:
  - `step_199_fix_panel_reporting_service.sh`
- run:
  - `step_192_reporting_service_panelde_goster.sh`
  - `step_194_panel_html_reporting_service_ekle.sh`

## 🟡 10 — INFRA / EDGE (33%, confidence=40)

### 🟡 10.1.1 — Production server hazırlığı (50%, confidence=50)

Eksik Kanıt:
- code/service evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `step_78_test_production_server_ready.sh`
- run:
  - `step_72_check_production_server.sh`
  - `step_73_update_production_server.sh`
  - `step_74_install_production_base_packages.sh`

### ⏳ 10.1.2 — Firewall (0%, confidence=20)

Eksik Kanıt:
- code/service evidence
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- run:
  - `step_76_configure_production_firewall.sh`

### 🟡 10.1.4 — SSL / routing (50%, confidence=50)

Eksik Kanıt:
- code/service evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `step_91_test_server_ssl_strict.sh`
- run:
  - `step_84_backup_nginx_ssl_split.sh`
  - `step_86_extend_ssl_server_subdomain.sh`
  - `step_93_reload_nginx_after_redirect_fix.sh`

## 🟡 11 — OBSERVABILITY / EARLY WARNING (70%, confidence=66)

### ✅ 11.1.1 — Prometheus/Grafana/Loki (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `deploy/observability/docker-compose.yml`
  - `deploy/observability/grafana/dashboards/docker-monitoring.json`
  - `deploy/observability/grafana/dashboards/node-exporter-full.json`
- test:
  - `step_272_test_observability_stack.sh`
- run:
  - `step_270_observability_stack.sh`
  - `step_271_run_observability_stack.sh`

### 🟡 11.1.2 — Promtail / log hygiene (50%, confidence=30)

Eksik Kanıt:
- code/service evidence
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- run:
  - `step_273_fix_promtail_positions.sh`
  - `step_281_logrotate_snapshot.sh`
  - `step_284_remove_snapshot_from_promtail.sh`
- ops:
  - `reports/ops_health_latest.txt`

### ✅ 11.2.3 — Global health (100%, confidence=90)

Eksik Kanıt:
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/service-watchdog/net_compat.go`
  - `cmd/service-watchdog/service_watchdog_main.go`
  - `cmd/service-watchdog/service_watchdog_main.go.before_find_20260320_001815`
- test:
  - `step_370_real_global_status.sh`
- run:
  - `step_334_add_global_health_engine.sh`

### 🟡 11.3.1 — Early warning collector (50%, confidence=60)

Eksik Kanıt:
- code/service evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `step_372_test_early_warning_collector.sh`
- run:
  - `step_371_add_early_warning_collector.sh`
  - `step_390_rewrite_early_warning_clean.sh`
- ops:
  - `scripts/test_ops_health_alarm_chain.sh`

### 🟡 11.3.2 — Auto heal (50%, confidence=60)

Eksik Kanıt:
- code/service evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `step_397_fix_auto_heal_source.sh`
- run:
  - `step_374_add_auto_heal_engine.sh`
  - `step_377_advanced_auto_heal.sh`
- ops:
  - `scripts/test_ops_service_alarm_chain.sh`

## 🟡 12 — PLATFORM SERVISLERI (50%, confidence=50)

### 🟡 12.1.1 — Stock service (50%, confidence=50)

Eksik Kanıt:
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `cmd/stock-service/stock_service_main.go`
- run:
  - `step_182_run_stock_service.sh`

### 🟡 12.1.2 — Accounting service (50%, confidence=50)

Eksik Kanıt:
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `accounting-service`
  - `cmd/accounting-service/accounting_service_main.go`
  - `cmd/accounting-service/accounting_service_main.go.bak_20260413_082633`
- run:
  - `step_183_run_accounting_service.sh`

## 🟡 13 — ERP TURKIYE DERINLESME (50%, confidence=50)

### 🟡 13.1.1 — Bilanço / gelir / mizan (50%, confidence=50)

Eksik Kanıt:
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/erp/core/alis/domain/erp_alis_fatura.go`
  - `internal/erp/core/alis/domain/erp_alis_fatura_satir.go`
  - `internal/erp/core/alis/service/erp_alis_fatura_service.go`
- run:
  - `step_run_bilanco_engine.sh`
  - `step_run_gelir_tablosu_engine.sh`
  - `step_run_mizan_engine.sh`

### 🟡 13.1.2 — Cari / kasa / banka ekstre (50%, confidence=50)

Eksik Kanıt:
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/finance/domain/account.go`
  - `test/internal/finance/test/accounts/accounts_test.go`
  - `test/internal/finance/test/ledger/intercompany_test.go`
- run:
  - `step_run_banka_ekstre.sh`
  - `step_run_cari_ekstre.sh`
  - `step_run_kasa_ekstre.sh`

### 🟡 13.1.3 — Tahsilat / ödeme / settlement (50%, confidence=50)

Eksik Kanıt:
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/finance/domain/account.go`
  - `test/internal/finance/test/accounts/accounts_test.go`
  - `test/internal/finance/test/ledger/intercompany_test.go`
- run:
  - `step_5_run_payment_engine.sh`
  - `step_5_run_tahsilat_odeme_v2.sh`
  - `step_6_run_settlement_engine.sh`

### 🟡 13.1.4 — Commission / payout / wallet (50%, confidence=50)

Eksik Kanıt:
- test evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `internal/finance/domain/account.go`
  - `test/internal/finance/test/accounts/accounts_test.go`
  - `test/internal/finance/test/ledger/intercompany_test.go`
- run:
  - `step_2_run_commission_engine.sh`
  - `step_6_run_wallet_transfer_engine.sh`
  - `step_7_run_merchant_payout_engine.sh`

## 🟡 14 — TEST / QUALITY GATE (50%, confidence=57)

### 🟡 14.1.1 — Unit/integration test izi (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `coverage.out`
  - `test/internal/finance/test/accounts/accounts_test.go`
  - `test/internal/finance/test/ledger/intercompany_test.go`
- test:
  - `step_405_test.sh`
  - `step_419_build_test.sh`
  - `step_420_build_test.sh`

### 🟡 14.1.2 — Prod smoke / ops suite (50%, confidence=50)

Eksik Kanıt:
- code/service evidence
- config/schema/contract evidence

Kanıt Özeti:
- test:
  - `scripts/prod_e2e_user_created_check.sh`
  - `scripts/prod_finance_post_restart_check.sh`
  - `scripts/query_post_restart_check.sh`
- run:
  - `scripts/prod_finance_smoke.sh`
  - `scripts/prod_ops_suite.sh`
  - `scripts/query_smoke_prod.sh`

### 🟡 14.1.3 — Guard / quality gates (50%, confidence=60)

Eksik Kanıt:
- run/live/ops evidence
- config/schema/contract evidence

Kanıt Özeti:
- code:
  - `guard/import_guard.sh`
  - `guard/pix2pi_guard.sh`
  - `guard/quality_gates.env`
- test:
  - `scripts/test_ops_daily_alert_chain.sh`

## Open Items

- 🟡 **11.1.2 Promtail / log hygiene** (confidence=30)
  - eksik:
    - code/service evidence
    - test evidence
    - config/schema/contract evidence
  - run:
    - `step_273_fix_promtail_positions.sh`
    - `step_281_logrotate_snapshot.sh`
  - ops:
    - `reports/ops_health_latest.txt`
- 🟡 **2.1.4 JWT doğrulama** (confidence=30)
  - eksik:
    - code/service evidence
    - run/live/ops evidence
    - config/schema/contract evidence
  - test:
    - `step_132_test_gateway_bearer_tenant_match.sh`
  - backup:
    - `step_130_backup_gateway_before_authz_layer.sh`
- 🟡 **3.3.1 Backup mantığı** (confidence=30)
  - eksik:
    - test evidence
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `.backups/2026/04/06/.__.gitignore_070441.bak`
    - `.backups/2026/04/06/.__.gitignore_143254.bak`
- 🟡 **4.1.2 JWT enforce** (confidence=30)
  - eksik:
    - code/service evidence
    - run/live/ops evidence
    - config/schema/contract evidence
  - test:
    - `step_132_test_gateway_bearer_tenant_match.sh`
- 🟡 **5.4.2 Bus-store integration** (confidence=30)
  - eksik:
    - code/service evidence
    - run/live/ops evidence
    - config/schema/contract evidence
  - test:
    - `step_52_run_event_bus_store_integration_test.sh`
  - backup:
    - `step_51_backup_event_bus_store_integration.sh`
- 🟡 **8.3.1 Export izolasyonu** (confidence=30)
  - eksik:
    - code/service evidence
    - run/live/ops evidence
    - config/schema/contract evidence
  - test:
    - `step_33_run_export_isolation_test.sh`
  - backup:
    - `step_31_backup_export_isolation.sh`
- 🟡 **8.3.2 Backup izolasyonu** (confidence=30)
  - eksik:
    - code/service evidence
    - run/live/ops evidence
    - config/schema/contract evidence
  - test:
    - `step_36_run_backup_isolation_test.sh`
  - backup:
    - `step_34_backup_backup_isolation.sh`
- 🟡 **1.1.1 Ana repo yapısı** (confidence=40)
  - eksik:
    - test evidence
    - run/live/ops evidence
  - code:
    - `.backups/import_fix_20260323_072726/internal/services/query_read_model/service.go`
    - `.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go`
  - config:
    - `PORTS.md`
    - `README.md`
- 🟡 **1.2.1 Config standardı** (confidence=40)
  - eksik:
    - test evidence
    - run/live/ops evidence
  - code:
    - `internal/common/config/config.go`
    - `internal/common/config/config.go.ok_bind_secret_20260228_073805`
  - config:
    - `configs/config.docker.yaml`
    - `configs/config.local.yaml`
- 🟡 **6.2.4 Financial flow recon** (confidence=40)
  - eksik:
    - code/service evidence
    - config/schema/contract evidence
  - test:
    - `step_56a_finance_recon.sh`
    - `step_56c_finance_flow_recon.sh`
  - ops:
    - `step_56a_finance_recon.txt`
    - `step_56c_finance_flow_recon.txt`
- 🟡 **1.4.3 Nginx temel kurulum** (confidence=50)
  - eksik:
    - code/service evidence
    - config/schema/contract evidence
  - test:
    - `step_88_test_split_routes.sh`
    - `step_89_test_server_ssl.sh`
  - run:
    - `step_79_install_nginx.sh`
    - `step_85_reload_nginx_split.sh`
- 🟡 **10.1.1 Production server hazırlığı** (confidence=50)
  - eksik:
    - code/service evidence
    - config/schema/contract evidence
  - test:
    - `step_78_test_production_server_ready.sh`
  - run:
    - `step_72_check_production_server.sh`
    - `step_73_update_production_server.sh`
- 🟡 **10.1.4 SSL / routing** (confidence=50)
  - eksik:
    - code/service evidence
    - config/schema/contract evidence
  - test:
    - `step_91_test_server_ssl_strict.sh`
  - run:
    - `step_84_backup_nginx_ssl_split.sh`
    - `step_86_extend_ssl_server_subdomain.sh`
- 🟡 **12.1.1 Stock service** (confidence=50)
  - eksik:
    - test evidence
    - config/schema/contract evidence
  - code:
    - `cmd/stock-service/stock_service_main.go`
  - run:
    - `step_182_run_stock_service.sh`
- 🟡 **12.1.2 Accounting service** (confidence=50)
  - eksik:
    - test evidence
    - config/schema/contract evidence
  - code:
    - `accounting-service`
    - `cmd/accounting-service/accounting_service_main.go`
  - run:
    - `step_183_run_accounting_service.sh`
- 🟡 **13.1.1 Bilanço / gelir / mizan** (confidence=50)
  - eksik:
    - test evidence
    - config/schema/contract evidence
  - code:
    - `internal/erp/core/alis/domain/erp_alis_fatura.go`
    - `internal/erp/core/alis/domain/erp_alis_fatura_satir.go`
  - run:
    - `step_run_bilanco_engine.sh`
    - `step_run_gelir_tablosu_engine.sh`
- 🟡 **13.1.2 Cari / kasa / banka ekstre** (confidence=50)
  - eksik:
    - test evidence
    - config/schema/contract evidence
  - code:
    - `internal/finance/domain/account.go`
    - `test/internal/finance/test/accounts/accounts_test.go`
  - run:
    - `step_run_banka_ekstre.sh`
    - `step_run_cari_ekstre.sh`
- 🟡 **13.1.3 Tahsilat / ödeme / settlement** (confidence=50)
  - eksik:
    - test evidence
    - config/schema/contract evidence
  - code:
    - `internal/finance/domain/account.go`
    - `test/internal/finance/test/accounts/accounts_test.go`
  - run:
    - `step_5_run_payment_engine.sh`
    - `step_5_run_tahsilat_odeme_v2.sh`
- 🟡 **13.1.4 Commission / payout / wallet** (confidence=50)
  - eksik:
    - test evidence
    - config/schema/contract evidence
  - code:
    - `internal/finance/domain/account.go`
    - `test/internal/finance/test/accounts/accounts_test.go`
  - run:
    - `step_2_run_commission_engine.sh`
    - `step_6_run_wallet_transfer_engine.sh`
- 🟡 **14.1.2 Prod smoke / ops suite** (confidence=50)
  - eksik:
    - code/service evidence
    - config/schema/contract evidence
  - test:
    - `scripts/prod_e2e_user_created_check.sh`
    - `scripts/prod_finance_post_restart_check.sh`
  - run:
    - `scripts/prod_finance_smoke.sh`
    - `scripts/prod_ops_suite.sh`
- 🟡 **4.2.7 Timeout / upstream policy** (confidence=50)
  - eksik:
    - test evidence
    - config/schema/contract evidence
  - code:
    - `step_420_rewrite_gateway.sh`
  - run:
    - `step_409_fix_gateway.sh`
    - `step_422_rewrite_gateway_with_db_init.sh`
- 🟡 **5.1.1 Event publish standardı** (confidence=50)
  - eksik:
    - test evidence
    - config/schema/contract evidence
  - code:
    - `cmd/nats-publisher/nats_publisher_main.go`
    - `kernel/events/model/event.go`
  - run:
    - `step_166_run_nats_publisher.sh`
- 🟡 **8.1.4 Audit trail tenant zorunluluğu** (confidence=50)
  - eksik:
    - test evidence
    - config/schema/contract evidence
  - code:
    - `step_260_create_audit_tables.sql`
  - run:
    - `step_262_run_audit_flow.sh`
- 🟡 **8.2.3 Tenant isolation verification** (confidence=50)
  - eksik:
    - code/service evidence
    - config/schema/contract evidence
  - test:
    - `step_250_tenant_isolation_verification.sh`
  - run:
    - `step_251_fix_verification.sh`
- 🟡 **1.1.2 Entry point standardı** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go`
    - `.backups/step_422_20260323_080757/cmd/api-gateway/api_gateway_main.go`
  - test:
    - `step_188_verify_done_items.sh`
- 🟡 **11.3.1 Early warning collector** (confidence=60)
  - eksik:
    - code/service evidence
    - config/schema/contract evidence
  - test:
    - `step_372_test_early_warning_collector.sh`
  - run:
    - `step_371_add_early_warning_collector.sh`
    - `step_390_rewrite_early_warning_clean.sh`
  - ops:
    - `scripts/test_ops_health_alarm_chain.sh`
- 🟡 **11.3.2 Auto heal** (confidence=60)
  - eksik:
    - code/service evidence
    - config/schema/contract evidence
  - test:
    - `step_397_fix_auto_heal_source.sh`
  - run:
    - `step_374_add_auto_heal_engine.sh`
    - `step_377_advanced_auto_heal.sh`
  - ops:
    - `scripts/test_ops_service_alarm_chain.sh`
- 🟡 **14.1.1 Unit/integration test izi** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `coverage.out`
    - `test/internal/finance/test/accounts/accounts_test.go`
  - test:
    - `step_405_test.sh`
    - `step_419_build_test.sh`
- 🟡 **14.1.3 Guard / quality gates** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `guard/import_guard.sh`
    - `guard/pix2pi_guard.sh`
  - test:
    - `scripts/test_ops_daily_alert_chain.sh`
- 🟡 **2.1.3 JWT üretimi** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `internal/identity/domain/tenant.go`
    - `internal/identity/domain/user.go`
  - test:
    - `step_5_run_jwt_tenant_test.sh`
    - `step_8_run_jwt_middleware_test.sh`
- 🟡 **2.2.1 Tenant context** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `internal/platform/kernel/tenant_context.go`
    - `internal/platform/kernel/tenant_context.go.errscope_20260301_140741`
  - test:
    - `step_10_run_tenant_event_pipeline_test.sh`
    - `step_2_run_tenant_test.sh`
- 🟡 **2.2.2 Tenant middleware** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `internal/platform/kernel/tenant_context.go`
    - `internal/platform/kernel/tenant_context.go.errscope_20260301_140741`
  - test:
    - `step_110_test_gateway_tenant_middleware.sh`
  - backup:
    - `step_108_backup_api_gateway_before_tenant_middleware.sh`
- 🟡 **2.2.4 Tenant-aware request processing** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `.backups/import_fix_20260323_072726/internal/services/query_read_model/service.go`
    - `.backups/step_417_20260323_074642/internal/services/query_read_model/routes.go`
  - test:
    - `step_12_run_tenant_service_filter_test.sh`
    - `step_250_tenant_isolation_verification.sh`
- 🟡 **3.2.1 Service registry** (confidence=60)
  - eksik:
    - test evidence
    - config/schema/contract evidence
  - code:
    - `cmd/service-registry/service_registry_main.go`
  - run:
    - `step_206_servis_yoneticisi_kur.sh`
  - ops:
    - `config/service_watchdog_services.json`
- 🟡 **4.1.3 Tenant enforce** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `internal/platform/kernel/tenant_context.go`
    - `internal/platform/kernel/tenant_context.go.errscope_20260301_140741`
  - test:
    - `step_110_test_gateway_tenant_middleware.sh`
- 🟡 **5.2.3 Consumer durability** (confidence=60)
  - eksik:
    - code/service evidence
  - test:
    - `step_175_check_sale_consumer.sh`
  - run:
    - `step_174_create_sale_consumer.sh`
  - config:
    - `deploy/nats/docker-compose.yml`
- 🟡 **5.3.1 Retry politikası** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `cmd/replay-service/replay_service_main.go`
    - `kernel/events/model/event.go`
  - test:
    - `step_194_test_retry.sh`
    - `step_41_run_event_retry_test.sh`
  - backup:
    - `step_40_backup_event_retry.sh`
- 🟡 **5.3.2 Idempotency** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `kernel/events/model/event.go`
    - `kernel/events/publisher/noop.go`
  - test:
    - `step_193_test_idempotency.sh`
    - `step_43_run_event_idempotency_test.sh`
  - backup:
    - `step_42_backup_event_idempotency.sh`
- 🟡 **5.3.3 DLQ** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `kernel/events/model/event.go`
    - `kernel/events/publisher/noop.go`
  - test:
    - `step_195_test_dlq.sh`
    - `step_45_run_event_dlq_test.sh`
  - backup:
    - `step_44_backup_event_dlq.sh`
- 🟡 **5.3.4 Poison message yönetimi** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `kernel/events/model/event.go`
    - `kernel/events/publisher/noop.go`
  - test:
    - `step_195_test_dlq.sh`
    - `step_45_run_event_dlq_test.sh`
- 🟡 **5.4.3 Event platform test suite** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `test/internal/finance/test/accounts/accounts_test.go`
    - `test/internal/finance/test/ledger/intercompany_test.go`
  - test:
    - `step_202_test_event_store.sh`
    - `step_39_run_event_bus_test.sh`
- 🟡 **7.1.3 Redis namespace tenant ayrımı** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `cmd/cache-service/cache_service_main.go`
  - test:
    - `step_15_run_redis_tenant_namespace_test.sh`
  - backup:
    - `step_13_backup_redis_tenant_namespace.sh`
- 🟡 **7.1.4 Read/write split** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `cmd/query-read-model/query_read_model_main.go`
    - `cmd/query-read-model/query_read_model_main_test.go`
  - test:
    - `step_65_run_read_write_split_test.sh`
  - backup:
    - `step_63_backup_read_write_split.sh`
- 🟡 **7.1.5 Reporting store** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `cmd/reporting-service/reporting_service_main.go`
    - `cmd/reporting-service/reporting_service_main_test.go`
  - test:
    - `step_68_run_reporting_store_test.sh`
  - backup:
    - `step_66_backup_reporting_store.sh`
- 🟡 **8.1.1 JWT tenant standardı** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `internal/platform/kernel/tenant_context.go`
    - `internal/platform/kernel/tenant_context.go.errscope_20260301_140741`
  - test:
    - `step_5_run_jwt_tenant_test.sh`
  - backup:
    - `step_3_backup_jwt_tenant.sh`
- 🟡 **8.1.2 Event payload tenant zorunluluğu** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `kernel/events/model/event.go`
    - `kernel/events/publisher/noop.go`
  - test:
    - `step_10_run_tenant_event_pipeline_test.sh`
- 🟡 **8.1.5 Tüm servislerde tenant filter** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `.backups/import_fix_20260323_072726/internal/services/query_read_model/service.go`
    - `.backups/step_417_20260323_074642/internal/services/query_read_model/routes.go`
  - test:
    - `step_12_run_tenant_service_filter_test.sh`
  - backup:
    - `step_11_backup_tenant_service_filter.sh`
- 🟡 **8.1.6 Super-admin erişim sınırları** (confidence=60)
  - eksik:
    - run/live/ops evidence
    - config/schema/contract evidence
  - code:
    - `internal/platform/kernel/policy_cache.go`
    - `internal/platform/kernel/policy_cache.go.ok_20260225_214931`
  - test:
    - `step_18_run_super_admin_policy_test.sh`
  - backup:
    - `step_16_backup_super_admin_policy.sh`
- ⏳ **4.2.5 Kota yönetimi** (confidence=0)
  - eksik:
    - code/service evidence
    - test evidence
    - run/live/ops evidence
    - config/schema/contract evidence
  - backup:
    - `step_69_backup_rate_limit.sh`
- ⏳ **4.2.1 Request trace** (confidence=10)
  - eksik:
    - code/service evidence
    - test evidence
    - config/schema/contract evidence
  - ops:
    - `step_423i_dump_runner_trace.sh`
    - `step_423j_dump_only_trace.sh`
- ⏳ **4.2.6 Request id / correlation** (confidence=10)
  - eksik:
    - code/service evidence
    - test evidence
    - config/schema/contract evidence
  - ops:
    - `step_423i_dump_runner_trace.sh`
- ⏳ **10.1.2 Firewall** (confidence=20)
  - eksik:
    - code/service evidence
    - test evidence
    - config/schema/contract evidence
  - run:
    - `step_76_configure_production_firewall.sh`