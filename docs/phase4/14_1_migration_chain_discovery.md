# FAZ 4 / 14.1 — Migration Chain Discovery Report

Generated at: 2026-04-27 06:57:28 +0300

## 1. Ozet

```text
MIGRATION_DIR_COUNT=8
ALL_SQL_COUNT=67
MIGRATION_SQL_COUNT=62
CODE_REF_COUNT=649
MAKE_REF_COUNT=77
```

## 2. Migration dizin adaylari

```text
./db
./db/migrations
./db/tests
./internal/db/migrations
./internal/db/migrations.bak_20260301_131246
./internal/platform/db
./migrations
./test/internal/finance/test/migrations
```

## 3. Migration SQL adaylari

```text
./db/migrations/001_phase1_foundation.down.sql
./db/migrations/001_phase1_foundation.up.sql
./db/migrations/002_phase2_db_l4_service_registry.down.sql
./db/migrations/002_phase2_db_l4_service_registry.up.sql
./db/migrations/003_phase2_db_l4_mission_control.down.sql
./db/migrations/003_phase2_db_l4_mission_control.up.sql
./db/migrations/004_phase2_db_l4_jobs_queue.down.sql
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql
./db/migrations/005_phase2_db_l4_idempotency.down.sql
./db/migrations/005_phase2_db_l4_idempotency.up.sql
./db/migrations/006_phase2_db_l4_notifications.down.sql
./db/migrations/006_phase2_db_l4_notifications.up.sql
./db/migrations/007_phase2_db_l4_webhooks.down.sql
./db/migrations/007_phase2_db_l4_webhooks.up.sql
./db/migrations/008_phase2_db_l4_workflows.down.sql
./db/migrations/008_phase2_db_l4_workflows.up.sql
./db/migrations/009_phase2_db_l4_api_keys.down.sql
./db/migrations/009_phase2_db_l4_api_keys.up.sql
./db/migrations/010_phase2_db_l4_plugins.down.sql
./db/migrations/010_phase2_db_l4_plugins.up.sql
./db/migrations/20260425_090101_erp_master_party.down.sql
./db/migrations/20260425_090101_erp_master_party.up.sql
./db/migrations/20260425_0910001_erp_cashbank.down.sql
./db/migrations/20260425_0910001_erp_cashbank.up.sql
./db/migrations/20260425_092001_erp_product_catalog.down.sql
./db/migrations/20260425_092001_erp_product_catalog.up.sql
./db/migrations/20260425_093001_erp_inventory.down.sql
./db/migrations/20260425_093001_erp_inventory.up.sql
./db/migrations/20260425_094001_erp_sales_documents.down.sql
./db/migrations/20260425_094001_erp_sales_documents.up.sql
./db/migrations/20260425_095001_erp_procurement_documents.down.sql
./db/migrations/20260425_095001_erp_procurement_documents.up.sql
./db/migrations/20260425_096001_erp_journal.down.sql
./db/migrations/20260425_096001_erp_journal.up.sql
./db/migrations/20260425_097001_erp_ledger.down.sql
./db/migrations/20260425_097001_erp_ledger.up.sql
./db/migrations/20260425_098001_erp_chart_of_accounts.down.sql
./db/migrations/20260425_098001_erp_chart_of_accounts.up.sql
./db/migrations/20260425_099001_erp_tax.down.sql
./db/migrations/20260425_099001_erp_tax.up.sql
./db/migrations/20260426_0911001_erp_fiscal_sequence.down.sql
./db/migrations/20260426_0911001_erp_fiscal_sequence.up.sql
./db/migrations/20260426_111001_erp_runtime_e2e_flow.down.sql
./db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql
./db/tests/001_phase1_cross_tenant_security.sql
./db/tests/002_phase1_org_graph.sql
./db/tests/004_phase2_service_registry.sql
./db/tests/005_phase2_mission_control.sql
./db/tests/006_phase2_jobs_queue.sql
./db/tests/007_phase2_idempotency.sql
./db/tests/008_phase2_notifications.sql
./db/tests/009_phase2_webhooks.sql
./db/tests/010_phase2_workflows.sql
./db/tests/011_phase2_api_keys.sql
./db/tests/012_phase2_plugins.sql
./deploy/sql/rls_tenant_policy.sql
./internal/db/migrations/0001_init.down.sql
./internal/db/migrations/0001_init.up.sql
./internal/db/migrations/0002_tenant_meta.down.sql
./internal/db/migrations/0002_tenant_meta.up.sql
./internal/db/migrations.bak_20260301_131246/0001_init.down.sql
./internal/db/migrations.bak_20260301_131246/0001_init.up.sql
```

## 4. Duplicate numeric version kontrolu

```text
DUPLICATE_VERSION=002
  - ./db/migrations/002_phase2_db_l4_service_registry.down.sql
  - ./db/migrations/002_phase2_db_l4_service_registry.up.sql
  - ./db/tests/002_phase1_org_graph.sql

DUPLICATE_VERSION=003
  - ./db/migrations/003_phase2_db_l4_mission_control.down.sql
  - ./db/migrations/003_phase2_db_l4_mission_control.up.sql

DUPLICATE_VERSION=004
  - ./db/migrations/004_phase2_db_l4_jobs_queue.down.sql
  - ./db/migrations/004_phase2_db_l4_jobs_queue.up.sql
  - ./db/tests/004_phase2_service_registry.sql

DUPLICATE_VERSION=20260425
  - ./db/migrations/20260425_090101_erp_master_party.down.sql
  - ./db/migrations/20260425_090101_erp_master_party.up.sql
  - ./db/migrations/20260425_0910001_erp_cashbank.down.sql
  - ./db/migrations/20260425_0910001_erp_cashbank.up.sql
  - ./db/migrations/20260425_092001_erp_product_catalog.down.sql
  - ./db/migrations/20260425_092001_erp_product_catalog.up.sql
  - ./db/migrations/20260425_093001_erp_inventory.down.sql
  - ./db/migrations/20260425_093001_erp_inventory.up.sql
  - ./db/migrations/20260425_094001_erp_sales_documents.down.sql
  - ./db/migrations/20260425_094001_erp_sales_documents.up.sql
  - ./db/migrations/20260425_095001_erp_procurement_documents.down.sql
  - ./db/migrations/20260425_095001_erp_procurement_documents.up.sql
  - ./db/migrations/20260425_096001_erp_journal.down.sql
  - ./db/migrations/20260425_096001_erp_journal.up.sql
  - ./db/migrations/20260425_097001_erp_ledger.down.sql
  - ./db/migrations/20260425_097001_erp_ledger.up.sql
  - ./db/migrations/20260425_098001_erp_chart_of_accounts.down.sql
  - ./db/migrations/20260425_098001_erp_chart_of_accounts.up.sql
  - ./db/migrations/20260425_099001_erp_tax.down.sql
  - ./db/migrations/20260425_099001_erp_tax.up.sql

DUPLICATE_VERSION=005
  - ./db/migrations/005_phase2_db_l4_idempotency.down.sql
  - ./db/migrations/005_phase2_db_l4_idempotency.up.sql
  - ./db/tests/005_phase2_mission_control.sql

DUPLICATE_VERSION=20260426
  - ./db/migrations/20260426_0911001_erp_fiscal_sequence.down.sql
  - ./db/migrations/20260426_0911001_erp_fiscal_sequence.up.sql
  - ./db/migrations/20260426_111001_erp_runtime_e2e_flow.down.sql
  - ./db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql

DUPLICATE_VERSION=006
  - ./db/migrations/006_phase2_db_l4_notifications.down.sql
  - ./db/migrations/006_phase2_db_l4_notifications.up.sql
  - ./db/tests/006_phase2_jobs_queue.sql

DUPLICATE_VERSION=007
  - ./db/migrations/007_phase2_db_l4_webhooks.down.sql
  - ./db/migrations/007_phase2_db_l4_webhooks.up.sql
  - ./db/tests/007_phase2_idempotency.sql

DUPLICATE_VERSION=008
  - ./db/migrations/008_phase2_db_l4_workflows.down.sql
  - ./db/migrations/008_phase2_db_l4_workflows.up.sql
  - ./db/tests/008_phase2_notifications.sql

DUPLICATE_VERSION=009
  - ./db/migrations/009_phase2_db_l4_api_keys.down.sql
  - ./db/migrations/009_phase2_db_l4_api_keys.up.sql
  - ./db/tests/009_phase2_webhooks.sql

DUPLICATE_VERSION=0001
  - ./internal/db/migrations/0001_init.down.sql
  - ./internal/db/migrations/0001_init.up.sql
  - ./internal/db/migrations.bak_20260301_131246/0001_init.down.sql
  - ./internal/db/migrations.bak_20260301_131246/0001_init.up.sql

DUPLICATE_VERSION=0002
  - ./internal/db/migrations/0002_tenant_meta.down.sql
  - ./internal/db/migrations/0002_tenant_meta.up.sql

DUPLICATE_VERSION=010
  - ./db/migrations/010_phase2_db_l4_plugins.down.sql
  - ./db/migrations/010_phase2_db_l4_plugins.up.sql
  - ./db/tests/010_phase2_workflows.sql

DUPLICATE_VERSION=001
  - ./db/migrations/001_phase1_foundation.down.sql
  - ./db/migrations/001_phase1_foundation.up.sql
  - ./db/tests/001_phase1_cross_tenant_security.sql

```

## 5. Numeric prefixsiz / standart disi adaylar

```text
- ./deploy/sql/rls_tenant_policy.sql
```

## 6. Up / Down pair kontrolu

```text
PAIR_OK ✅ ./db/migrations/001_phase1_foundation.up.sql <-> ./db/migrations/001_phase1_foundation.down.sql
PAIR_OK ✅ ./db/migrations/002_phase2_db_l4_service_registry.up.sql <-> ./db/migrations/002_phase2_db_l4_service_registry.down.sql
PAIR_OK ✅ ./db/migrations/003_phase2_db_l4_mission_control.up.sql <-> ./db/migrations/003_phase2_db_l4_mission_control.down.sql
PAIR_OK ✅ ./db/migrations/004_phase2_db_l4_jobs_queue.up.sql <-> ./db/migrations/004_phase2_db_l4_jobs_queue.down.sql
PAIR_OK ✅ ./db/migrations/005_phase2_db_l4_idempotency.up.sql <-> ./db/migrations/005_phase2_db_l4_idempotency.down.sql
PAIR_OK ✅ ./db/migrations/006_phase2_db_l4_notifications.up.sql <-> ./db/migrations/006_phase2_db_l4_notifications.down.sql
PAIR_OK ✅ ./db/migrations/007_phase2_db_l4_webhooks.up.sql <-> ./db/migrations/007_phase2_db_l4_webhooks.down.sql
PAIR_OK ✅ ./db/migrations/008_phase2_db_l4_workflows.up.sql <-> ./db/migrations/008_phase2_db_l4_workflows.down.sql
PAIR_OK ✅ ./db/migrations/009_phase2_db_l4_api_keys.up.sql <-> ./db/migrations/009_phase2_db_l4_api_keys.down.sql
PAIR_OK ✅ ./db/migrations/010_phase2_db_l4_plugins.up.sql <-> ./db/migrations/010_phase2_db_l4_plugins.down.sql
PAIR_OK ✅ ./db/migrations/20260425_090101_erp_master_party.up.sql <-> ./db/migrations/20260425_090101_erp_master_party.down.sql
PAIR_OK ✅ ./db/migrations/20260425_0910001_erp_cashbank.up.sql <-> ./db/migrations/20260425_0910001_erp_cashbank.down.sql
PAIR_OK ✅ ./db/migrations/20260425_092001_erp_product_catalog.up.sql <-> ./db/migrations/20260425_092001_erp_product_catalog.down.sql
PAIR_OK ✅ ./db/migrations/20260425_093001_erp_inventory.up.sql <-> ./db/migrations/20260425_093001_erp_inventory.down.sql
PAIR_OK ✅ ./db/migrations/20260425_094001_erp_sales_documents.up.sql <-> ./db/migrations/20260425_094001_erp_sales_documents.down.sql
PAIR_OK ✅ ./db/migrations/20260425_095001_erp_procurement_documents.up.sql <-> ./db/migrations/20260425_095001_erp_procurement_documents.down.sql
PAIR_OK ✅ ./db/migrations/20260425_096001_erp_journal.up.sql <-> ./db/migrations/20260425_096001_erp_journal.down.sql
PAIR_OK ✅ ./db/migrations/20260425_097001_erp_ledger.up.sql <-> ./db/migrations/20260425_097001_erp_ledger.down.sql
PAIR_OK ✅ ./db/migrations/20260425_098001_erp_chart_of_accounts.up.sql <-> ./db/migrations/20260425_098001_erp_chart_of_accounts.down.sql
PAIR_OK ✅ ./db/migrations/20260425_099001_erp_tax.up.sql <-> ./db/migrations/20260425_099001_erp_tax.down.sql
PAIR_OK ✅ ./db/migrations/20260426_0911001_erp_fiscal_sequence.up.sql <-> ./db/migrations/20260426_0911001_erp_fiscal_sequence.down.sql
PAIR_OK ✅ ./db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql <-> ./db/migrations/20260426_111001_erp_runtime_e2e_flow.down.sql
PAIR_NOT_APPLICABLE ℹ️ ./db/tests/001_phase1_cross_tenant_security.sql
PAIR_NOT_APPLICABLE ℹ️ ./db/tests/002_phase1_org_graph.sql
PAIR_NOT_APPLICABLE ℹ️ ./db/tests/004_phase2_service_registry.sql
PAIR_NOT_APPLICABLE ℹ️ ./db/tests/005_phase2_mission_control.sql
PAIR_NOT_APPLICABLE ℹ️ ./db/tests/006_phase2_jobs_queue.sql
PAIR_NOT_APPLICABLE ℹ️ ./db/tests/007_phase2_idempotency.sql
PAIR_NOT_APPLICABLE ℹ️ ./db/tests/008_phase2_notifications.sql
PAIR_NOT_APPLICABLE ℹ️ ./db/tests/009_phase2_webhooks.sql
PAIR_NOT_APPLICABLE ℹ️ ./db/tests/010_phase2_workflows.sql
PAIR_NOT_APPLICABLE ℹ️ ./db/tests/011_phase2_api_keys.sql
PAIR_NOT_APPLICABLE ℹ️ ./db/tests/012_phase2_plugins.sql
PAIR_NOT_APPLICABLE ℹ️ ./deploy/sql/rls_tenant_policy.sql
PAIR_OK ✅ ./internal/db/migrations/0001_init.up.sql <-> ./internal/db/migrations/0001_init.down.sql
PAIR_OK ✅ ./internal/db/migrations/0002_tenant_meta.up.sql <-> ./internal/db/migrations/0002_tenant_meta.down.sql
PAIR_OK ✅ ./internal/db/migrations.bak_20260301_131246/0001_init.up.sql <-> ./internal/db/migrations.bak_20260301_131246/0001_init.down.sql
```

## 7. Kod icindeki migration referanslari

```text
./cmd/migrate/main.go:10:	"github.com/golang-migrate/migrate/v4"
./cmd/migrate/main.go:11:	_ "github.com/golang-migrate/migrate/v4/database/postgres"
./cmd/migrate/main.go:12:	_ "github.com/golang-migrate/migrate/v4/source/file"
./cmd/migrate/main.go:28:		migrations  = flag.String("dir", "file://internal/db/migrations", "migrations dir (file://...)")
./cmd/migrate/main.go:38:	m, err := migrate.New(*migrations, dsn)
./cmd/migrate/main.go:40:		log.Fatalf("migrate.New: %v", err)
./cmd/migrate/main.go:48:		if err := m.Up(); err != nil && err != migrate.ErrNoChange {
./cmd/migrate/main.go:51:		fmt.Println("OK ✅  migrations up (or no change)")
./cmd/migrate/main.go:53:		if err := m.Down(); err != nil && err != migrate.ErrNoChange {
./cmd/migrate/main.go:56:		fmt.Println("OK ✅  migrations down (or no change)")
./cmd/migrate/main.go:61:		if err := m.Steps(*steps); err != nil && err != migrate.ErrNoChange {
./cmd/migrate/main.go:64:		fmt.Println("OK ✅  migrations steps:", *steps)
./cmd/migrate/main.go:66:		v, dirty, err := m.Version()
./cmd/migrate/main.go:67:		if err == migrate.ErrNilVersion {
./cmd/migrate/main.go:74:		fmt.Printf("version: %d dirty=%v\n", v, dirty)
./devtools/logs.sh:14:if [[ "$svc" == "migrate" ]]; then
./devtools/logs.sh:15:  file="logs/migrate.log"
./devtools/logs.sh:7:  echo "Kullanım: ./scripts/logs.sh identity-api|finance-api|gateway|migrate"
./devtools/run_all.sh:44:mig="$(find_main migrate)"
./devtools/run_all.sh:46:  go run "./$mig" | tee "logs/migrate.log"
./devtools/run_all.sh:48:  echo "⚠️  [migrate] cmd/migrate altında *main*.go yok → SKIP"
./devtools/run_migrate.sh:8:echo "🗄️  Running migrations..."
./devtools/run_migrate.sh:9:go run ./cmd/migrate
./docs/erp/faz3_final_muhur_raporu.md:45:| 11 | ERP Runtime E2E Flow | ✅ Tamamlandı | Flow migration, lifecycle, tenant isolation, store, bridge, adapter smoke geçti. |
./docs/erp/faz3_step11_2_runtime_e2eflow_muhur.md:25:- internal/erp/runtime/e2eflow/schema_migration_test.go
./docs/erp/faz3_step11_2_runtime_e2eflow_muhur.md:31:- db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql
./docs/erp/faz3_step11_2_runtime_e2eflow_muhur.md:32:- db/migrations/20260426_111001_erp_runtime_e2e_flow.down.sql
./docs/KERNEL_RULES.md:11:- DB schema değişimi expand→migrate→contract.
./docs/phase4/14_1_migration_chain_discovery.md:100:  - ./db/migrations/002_phase2_db_l4_service_registry.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:104:  - ./db/migrations/003_phase2_db_l4_mission_control.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:105:  - ./db/migrations/003_phase2_db_l4_mission_control.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:108:  - ./db/migrations/004_phase2_db_l4_jobs_queue.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:109:  - ./db/migrations/004_phase2_db_l4_jobs_queue.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:113:  - ./db/migrations/20260425_090101_erp_master_party.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:114:  - ./db/migrations/20260425_090101_erp_master_party.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:115:  - ./db/migrations/20260425_0910001_erp_cashbank.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:116:  - ./db/migrations/20260425_0910001_erp_cashbank.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:117:  - ./db/migrations/20260425_092001_erp_product_catalog.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:118:  - ./db/migrations/20260425_092001_erp_product_catalog.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:119:  - ./db/migrations/20260425_093001_erp_inventory.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:120:  - ./db/migrations/20260425_093001_erp_inventory.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:121:  - ./db/migrations/20260425_094001_erp_sales_documents.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:122:  - ./db/migrations/20260425_094001_erp_sales_documents.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:123:  - ./db/migrations/20260425_095001_erp_procurement_documents.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:124:  - ./db/migrations/20260425_095001_erp_procurement_documents.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:125:  - ./db/migrations/20260425_096001_erp_journal.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:126:  - ./db/migrations/20260425_096001_erp_journal.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:127:  - ./db/migrations/20260425_097001_erp_ledger.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:128:  - ./db/migrations/20260425_097001_erp_ledger.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:129:  - ./db/migrations/20260425_098001_erp_chart_of_accounts.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:130:  - ./db/migrations/20260425_098001_erp_chart_of_accounts.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:131:  - ./db/migrations/20260425_099001_erp_tax.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:132:  - ./db/migrations/20260425_099001_erp_tax.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:135:  - ./db/migrations/005_phase2_db_l4_idempotency.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:136:  - ./db/migrations/005_phase2_db_l4_idempotency.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:140:  - ./db/migrations/20260426_0911001_erp_fiscal_sequence.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:141:  - ./db/migrations/20260426_0911001_erp_fiscal_sequence.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:142:  - ./db/migrations/20260426_111001_erp_runtime_e2e_flow.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:143:  - ./db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:146:  - ./db/migrations/006_phase2_db_l4_notifications.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:147:  - ./db/migrations/006_phase2_db_l4_notifications.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:151:  - ./db/migrations/007_phase2_db_l4_webhooks.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:152:  - ./db/migrations/007_phase2_db_l4_webhooks.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:156:  - ./db/migrations/008_phase2_db_l4_workflows.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:157:  - ./db/migrations/008_phase2_db_l4_workflows.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:161:  - ./db/migrations/009_phase2_db_l4_api_keys.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:162:  - ./db/migrations/009_phase2_db_l4_api_keys.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:166:  - ./internal/db/migrations/0001_init.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:167:  - ./internal/db/migrations/0001_init.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:168:  - ./internal/db/migrations.bak_20260301_131246/0001_init.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:169:  - ./internal/db/migrations.bak_20260301_131246/0001_init.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:172:  - ./internal/db/migrations/0002_tenant_meta.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:173:  - ./internal/db/migrations/0002_tenant_meta.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:176:  - ./db/migrations/010_phase2_db_l4_plugins.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:177:  - ./db/migrations/010_phase2_db_l4_plugins.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:181:  - ./db/migrations/001_phase1_foundation.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:182:  - ./db/migrations/001_phase1_foundation.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:196:PAIR_OK ✅ ./db/migrations/001_phase1_foundation.up.sql <-> ./db/migrations/001_phase1_foundation.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:197:PAIR_OK ✅ ./db/migrations/002_phase2_db_l4_service_registry.up.sql <-> ./db/migrations/002_phase2_db_l4_service_registry.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:198:PAIR_OK ✅ ./db/migrations/003_phase2_db_l4_mission_control.up.sql <-> ./db/migrations/003_phase2_db_l4_mission_control.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:199:PAIR_OK ✅ ./db/migrations/004_phase2_db_l4_jobs_queue.up.sql <-> ./db/migrations/004_phase2_db_l4_jobs_queue.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:19:./db/migrations
./docs/phase4/14_1_migration_chain_discovery.md:200:PAIR_OK ✅ ./db/migrations/005_phase2_db_l4_idempotency.up.sql <-> ./db/migrations/005_phase2_db_l4_idempotency.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:201:PAIR_OK ✅ ./db/migrations/006_phase2_db_l4_notifications.up.sql <-> ./db/migrations/006_phase2_db_l4_notifications.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:202:PAIR_OK ✅ ./db/migrations/007_phase2_db_l4_webhooks.up.sql <-> ./db/migrations/007_phase2_db_l4_webhooks.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:203:PAIR_OK ✅ ./db/migrations/008_phase2_db_l4_workflows.up.sql <-> ./db/migrations/008_phase2_db_l4_workflows.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:204:PAIR_OK ✅ ./db/migrations/009_phase2_db_l4_api_keys.up.sql <-> ./db/migrations/009_phase2_db_l4_api_keys.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:205:PAIR_OK ✅ ./db/migrations/010_phase2_db_l4_plugins.up.sql <-> ./db/migrations/010_phase2_db_l4_plugins.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:206:PAIR_OK ✅ ./db/migrations/20260425_090101_erp_master_party.up.sql <-> ./db/migrations/20260425_090101_erp_master_party.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:207:PAIR_OK ✅ ./db/migrations/20260425_0910001_erp_cashbank.up.sql <-> ./db/migrations/20260425_0910001_erp_cashbank.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:208:PAIR_OK ✅ ./db/migrations/20260425_092001_erp_product_catalog.up.sql <-> ./db/migrations/20260425_092001_erp_product_catalog.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:209:PAIR_OK ✅ ./db/migrations/20260425_093001_erp_inventory.up.sql <-> ./db/migrations/20260425_093001_erp_inventory.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:210:PAIR_OK ✅ ./db/migrations/20260425_094001_erp_sales_documents.up.sql <-> ./db/migrations/20260425_094001_erp_sales_documents.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:211:PAIR_OK ✅ ./db/migrations/20260425_095001_erp_procurement_documents.up.sql <-> ./db/migrations/20260425_095001_erp_procurement_documents.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:212:PAIR_OK ✅ ./db/migrations/20260425_096001_erp_journal.up.sql <-> ./db/migrations/20260425_096001_erp_journal.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:213:PAIR_OK ✅ ./db/migrations/20260425_097001_erp_ledger.up.sql <-> ./db/migrations/20260425_097001_erp_ledger.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:214:PAIR_OK ✅ ./db/migrations/20260425_098001_erp_chart_of_accounts.up.sql <-> ./db/migrations/20260425_098001_erp_chart_of_accounts.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:215:PAIR_OK ✅ ./db/migrations/20260425_099001_erp_tax.up.sql <-> ./db/migrations/20260425_099001_erp_tax.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:216:PAIR_OK ✅ ./db/migrations/20260426_0911001_erp_fiscal_sequence.up.sql <-> ./db/migrations/20260426_0911001_erp_fiscal_sequence.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:217:PAIR_OK ✅ ./db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql <-> ./db/migrations/20260426_111001_erp_runtime_e2e_flow.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:21:./internal/db/migrations
./docs/phase4/14_1_migration_chain_discovery.md:22:./internal/db/migrations.bak_20260301_131246
./docs/phase4/14_1_migration_chain_discovery.md:230:PAIR_OK ✅ ./internal/db/migrations/0001_init.up.sql <-> ./internal/db/migrations/0001_init.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:231:PAIR_OK ✅ ./internal/db/migrations/0002_tenant_meta.up.sql <-> ./internal/db/migrations/0002_tenant_meta.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:232:PAIR_OK ✅ ./internal/db/migrations.bak_20260301_131246/0001_init.up.sql <-> ./internal/db/migrations.bak_20260301_131246/0001_init.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:235:## 7. Kod icindeki migration referanslari
./docs/phase4/14_1_migration_chain_discovery.md:238:./cmd/migrate/main.go:10:	"github.com/golang-migrate/migrate/v4"
./docs/phase4/14_1_migration_chain_discovery.md:239:./cmd/migrate/main.go:11:	_ "github.com/golang-migrate/migrate/v4/database/postgres"
./docs/phase4/14_1_migration_chain_discovery.md:240:./cmd/migrate/main.go:12:	_ "github.com/golang-migrate/migrate/v4/source/file"
./docs/phase4/14_1_migration_chain_discovery.md:241:./cmd/migrate/main.go:28:		migrations  = flag.String("dir", "file://internal/db/migrations", "migrations dir (file://...)")
./docs/phase4/14_1_migration_chain_discovery.md:242:./cmd/migrate/main.go:38:	m, err := migrate.New(*migrations, dsn)
./docs/phase4/14_1_migration_chain_discovery.md:243:./cmd/migrate/main.go:40:		log.Fatalf("migrate.New: %v", err)
./docs/phase4/14_1_migration_chain_discovery.md:244:./cmd/migrate/main.go:48:		if err := m.Up(); err != nil && err != migrate.ErrNoChange {
./docs/phase4/14_1_migration_chain_discovery.md:245:./cmd/migrate/main.go:51:		fmt.Println("OK ✅  migrations up (or no change)")
./docs/phase4/14_1_migration_chain_discovery.md:246:./cmd/migrate/main.go:53:		if err := m.Down(); err != nil && err != migrate.ErrNoChange {
./docs/phase4/14_1_migration_chain_discovery.md:247:./cmd/migrate/main.go:56:		fmt.Println("OK ✅  migrations down (or no change)")
./docs/phase4/14_1_migration_chain_discovery.md:248:./cmd/migrate/main.go:61:		if err := m.Steps(*steps); err != nil && err != migrate.ErrNoChange {
./docs/phase4/14_1_migration_chain_discovery.md:249:./cmd/migrate/main.go:64:		fmt.Println("OK ✅  migrations steps:", *steps)
./docs/phase4/14_1_migration_chain_discovery.md:24:./migrations
./docs/phase4/14_1_migration_chain_discovery.md:250:./cmd/migrate/main.go:66:		v, dirty, err := m.Version()
./docs/phase4/14_1_migration_chain_discovery.md:251:./cmd/migrate/main.go:67:		if err == migrate.ErrNilVersion {
./docs/phase4/14_1_migration_chain_discovery.md:252:./cmd/migrate/main.go:74:		fmt.Printf("version: %d dirty=%v\n", v, dirty)
./docs/phase4/14_1_migration_chain_discovery.md:253:./devtools/logs.sh:14:if [[ "$svc" == "migrate" ]]; then
./docs/phase4/14_1_migration_chain_discovery.md:254:./devtools/logs.sh:15:  file="logs/migrate.log"
./docs/phase4/14_1_migration_chain_discovery.md:255:./devtools/logs.sh:7:  echo "Kullanım: ./scripts/logs.sh identity-api|finance-api|gateway|migrate"
./docs/phase4/14_1_migration_chain_discovery.md:256:./devtools/run_all.sh:44:mig="$(find_main migrate)"
./docs/phase4/14_1_migration_chain_discovery.md:257:./devtools/run_all.sh:46:  go run "./$mig" | tee "logs/migrate.log"
./docs/phase4/14_1_migration_chain_discovery.md:258:./devtools/run_all.sh:48:  echo "⚠️  [migrate] cmd/migrate altında *main*.go yok → SKIP"
./docs/phase4/14_1_migration_chain_discovery.md:259:./devtools/run_migrate.sh:8:echo "🗄️  Running migrations..."
./docs/phase4/14_1_migration_chain_discovery.md:25:./test/internal/finance/test/migrations
./docs/phase4/14_1_migration_chain_discovery.md:260:./devtools/run_migrate.sh:9:go run ./cmd/migrate
./docs/phase4/14_1_migration_chain_discovery.md:261:./docs/erp/faz3_final_muhur_raporu.md:45:| 11 | ERP Runtime E2E Flow | ✅ Tamamlandı | Flow migration, lifecycle, tenant isolation, store, bridge, adapter smoke geçti. |
./docs/phase4/14_1_migration_chain_discovery.md:262:./docs/erp/faz3_step11_2_runtime_e2eflow_muhur.md:25:- internal/erp/runtime/e2eflow/schema_migration_test.go
./docs/phase4/14_1_migration_chain_discovery.md:263:./docs/erp/faz3_step11_2_runtime_e2eflow_muhur.md:31:- db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql
./docs/phase4/14_1_migration_chain_discovery.md:264:./docs/erp/faz3_step11_2_runtime_e2eflow_muhur.md:32:- db/migrations/20260426_111001_erp_runtime_e2e_flow.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:265:./docs/KERNEL_RULES.md:11:- DB schema değişimi expand→migrate→contract.
./docs/phase4/14_1_migration_chain_discovery.md:266:./guard/pix2pi_guard.sh:100:    if grep -RIn 'CREATE TABLE' migrations/services >/dev/null 2>&1; then
./docs/phase4/14_1_migration_chain_discovery.md:267:./guard/pix2pi_guard.sh:101:      if ! grep -RIn 'tenant_id' migrations/services >/dev/null 2>&1; then
./docs/phase4/14_1_migration_chain_discovery.md:268:./guard/pix2pi_guard.sh:125:  fail "Tenant isolation şüpheli: $SUSPECT > $MAX_SUSPECT_QUERIES (repo/migration kontrollerini gözden geçir)"
./docs/phase4/14_1_migration_chain_discovery.md:269:./guard/pix2pi_guard.sh:89:# 1) migrations/services içinde tenant_id yoksa şüpheli
./docs/phase4/14_1_migration_chain_discovery.md:270:./guard/pix2pi_guard.sh:90:if [ -d migrations/services ]; then
./docs/phase4/14_1_migration_chain_discovery.md:271:./guard/pix2pi_guard.sh:93:    if rg -n 'CREATE TABLE' migrations/services >/dev/null 2>&1; then
./docs/phase4/14_1_migration_chain_discovery.md:272:./guard/pix2pi_guard.sh:95:      if ! rg -n 'tenant_id' migrations/services >/dev/null 2>&1; then
./docs/phase4/14_1_migration_chain_discovery.md:273:./install_phase1_scaffold.sh:23:mkdir -p "$ROOT_DIR/db/migrations"
./docs/phase4/14_1_migration_chain_discovery.md:274:./install_phase1_scaffold.sh:24:cat > "$ROOT_DIR/db/migrations/001_phase1_foundation.up.sql" <<'EOF'
./docs/phase4/14_1_migration_chain_discovery.md:275:./install_phase1_scaffold.sh:7:mkdir -p "$ROOT_DIR/db/migrations"
./docs/phase4/14_1_migration_chain_discovery.md:276:./install_phase1_scaffold.sh:8:cat > "$ROOT_DIR/db/migrations/001_phase1_foundation.down.sql" <<'EOF'
./docs/phase4/14_1_migration_chain_discovery.md:277:./internal/db/migrator/migrator.go:10:	_ "github.com/golang-migrate/migrate/v4/database/postgres"
./docs/phase4/14_1_migration_chain_discovery.md:278:./internal/db/migrator/migrator.go:11:	_ "github.com/golang-migrate/migrate/v4/source/file"
./docs/phase4/14_1_migration_chain_discovery.md:279:./internal/db/migrator/migrator.go:51:	// Not: migrate "file://" ister. Workdir kökten çalıştırıyoruz.
./docs/phase4/14_1_migration_chain_discovery.md:280:./internal/db/migrator/migrator.go:52:	m, err := migrate.New("file://internal/db/migrations", dsn)
./docs/phase4/14_1_migration_chain_discovery.md:281:./internal/db/migrator/migrator.go:54:		return fmt.Errorf("migrate.New failed: %w", err)
./docs/phase4/14_1_migration_chain_discovery.md:282:./internal/db/migrator/migrator.go:64:			log.Println("✅ migrations applied (up)")
./docs/phase4/14_1_migration_chain_discovery.md:283:./internal/db/migrator/migrator.go:67:		if err == migrate.ErrNoChange {
./docs/phase4/14_1_migration_chain_discovery.md:284:./internal/db/migrator/migrator.go:68:			log.Println("✅ migrations already up-to-date (no change)")
./docs/phase4/14_1_migration_chain_discovery.md:285:./internal/db/migrator/migrator.go:72:		log.Printf("⏳ migrate attempt %d failed: %v", i, err)
./docs/phase4/14_1_migration_chain_discovery.md:286:./internal/db/migrator/migrator.go:76:	return fmt.Errorf("migration failed after retries: %w", err)
./docs/phase4/14_1_migration_chain_discovery.md:287:./internal/db/migrator/migrator.go:9:	"github.com/golang-migrate/migrate/v4"
./docs/phase4/14_1_migration_chain_discovery.md:288:./internal/erp/persistence/cashbank/cashbank_schema_test.go:106:	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:289:./internal/erp/persistence/cashbank/cashbank_schema_test.go:129:	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:290:./internal/erp/persistence/cashbank/cashbank_schema_test.go:147:	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:291:./internal/erp/persistence/cashbank/cashbank_schema_test.go:170:	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:292:./internal/erp/persistence/cashbank/cashbank_schema_test.go:187:	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:293:./internal/erp/persistence/cashbank/cashbank_schema_test.go:202:	sql := readMigration(t, "20260425_0910001_erp_cashbank.down.sql")
./docs/phase4/14_1_migration_chain_discovery.md:294:./internal/erp/persistence/cashbank/cashbank_schema_test.go:35:	path := filepath.Join(repoRoot(t), "db", "migrations", name)
./docs/phase4/14_1_migration_chain_discovery.md:295:./internal/erp/persistence/cashbank/cashbank_schema_test.go:39:		t.Fatalf("read migration %s: %v", name, err)
./docs/phase4/14_1_migration_chain_discovery.md:296:./internal/erp/persistence/cashbank/cashbank_schema_test.go:49:		t.Fatalf("migration missing expected SQL fragment:\n%s", expected)
./docs/phase4/14_1_migration_chain_discovery.md:297:./internal/erp/persistence/cashbank/cashbank_schema_test.go:54:	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:298:./internal/erp/persistence/cashbank/cashbank_schema_test.go:68:	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:299:./internal/erp/persistence/cashbank/cashbank_schema_test.go:85:	sql := readMigration(t, "20260425_0910001_erp_cashbank.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:300:./internal/erp/persistence/chartofaccounts/chart_of_accounts_schema_test.go:108:	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:301:./internal/erp/persistence/chartofaccounts/chart_of_accounts_schema_test.go:128:	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:302:./internal/erp/persistence/chartofaccounts/chart_of_accounts_schema_test.go:150:	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:303:./internal/erp/persistence/chartofaccounts/chart_of_accounts_schema_test.go:172:	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:304:./internal/erp/persistence/chartofaccounts/chart_of_accounts_schema_test.go:187:	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:305:./internal/erp/persistence/chartofaccounts/chart_of_accounts_schema_test.go:201:	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.down.sql")
./docs/phase4/14_1_migration_chain_discovery.md:306:./internal/erp/persistence/chartofaccounts/chart_of_accounts_schema_test.go:35:	path := filepath.Join(repoRoot(t), "db", "migrations", name)
./docs/phase4/14_1_migration_chain_discovery.md:307:./internal/erp/persistence/chartofaccounts/chart_of_accounts_schema_test.go:39:		t.Fatalf("read migration %s: %v", name, err)
./docs/phase4/14_1_migration_chain_discovery.md:308:./internal/erp/persistence/chartofaccounts/chart_of_accounts_schema_test.go:49:		t.Fatalf("migration missing expected SQL fragment:\n%s", expected)
./docs/phase4/14_1_migration_chain_discovery.md:309:./internal/erp/persistence/chartofaccounts/chart_of_accounts_schema_test.go:54:	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:310:./internal/erp/persistence/chartofaccounts/chart_of_accounts_schema_test.go:67:	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:311:./internal/erp/persistence/chartofaccounts/chart_of_accounts_schema_test.go:84:	sql := readMigration(t, "20260425_098001_erp_chart_of_accounts.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:312:./internal/erp/persistence/fiscal/fiscal_sequence_schema_test.go:106:	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:313:./internal/erp/persistence/fiscal/fiscal_sequence_schema_test.go:129:	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:314:./internal/erp/persistence/fiscal/fiscal_sequence_schema_test.go:150:	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:315:./internal/erp/persistence/fiscal/fiscal_sequence_schema_test.go:173:	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:316:./internal/erp/persistence/fiscal/fiscal_sequence_schema_test.go:192:	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:317:./internal/erp/persistence/fiscal/fiscal_sequence_schema_test.go:208:	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.down.sql")
./docs/phase4/14_1_migration_chain_discovery.md:318:./internal/erp/persistence/fiscal/fiscal_sequence_schema_test.go:35:	path := filepath.Join(repoRoot(t), "db", "migrations", name)
./docs/phase4/14_1_migration_chain_discovery.md:319:./internal/erp/persistence/fiscal/fiscal_sequence_schema_test.go:39:		t.Fatalf("read migration %s: %v", name, err)
./docs/phase4/14_1_migration_chain_discovery.md:31:./db/migrations/001_phase1_foundation.down.sql
./docs/phase4/14_1_migration_chain_discovery.md:320:./internal/erp/persistence/fiscal/fiscal_sequence_schema_test.go:49:		t.Fatalf("migration missing expected SQL fragment:\n%s", expected)
./docs/phase4/14_1_migration_chain_discovery.md:321:./internal/erp/persistence/fiscal/fiscal_sequence_schema_test.go:54:	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:322:./internal/erp/persistence/fiscal/fiscal_sequence_schema_test.go:69:	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:323:./internal/erp/persistence/fiscal/fiscal_sequence_schema_test.go:86:	sql := readMigration(t, "20260426_0911001_erp_fiscal_sequence.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:324:./internal/erp/persistence/inventory/inventory_schema_test.go:108:	sql := readMigration(t, "20260425_093001_erp_inventory.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:325:./internal/erp/persistence/inventory/inventory_schema_test.go:130:	sql := readMigration(t, "20260425_093001_erp_inventory.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:326:./internal/erp/persistence/inventory/inventory_schema_test.go:147:	sql := readMigration(t, "20260425_093001_erp_inventory.up.sql")
./docs/phase4/14_1_migration_chain_discovery.md:327:./internal/erp/persistence/inventory/inventory_schema_test.go:162:	sql := readMigration(t, "20260425_093001_erp_inventory.down.sql")
./docs/phase4/14_1_migration_chain_discovery.md:328:./internal/erp/persistence/inventory/inventory_schema_test.go:35:	path := filepath.Join(repoRoot(t), "db", "migrations", name)
```

## 8. Make / script / compose migration referanslari

```text
./1_archive/root_sh/step_260_audit_schema.sh:32:echo "OK ✅ audit schema hazir"
./1_archive/root_sh/step_270_observability_stack.sh:124:schema_config:
./1_archive/root_sh/step_270_observability_stack.sh:129:      schema: v13
./1_archive/root_sh/step_270_observability_stack.sh:268:  "schemaVersion": 39,
./1_archive/root_sh/step_278_loki_limit.sh:16:schema_config:
./1_archive/root_sh/step_278_loki_limit.sh:21:      schema: v11
./deploy/erp-tr/config/lvl13_export_catalog.yaml:34:      - schema_version
./deploy/observability/loki/loki-config.yml:17:schema_config:
./deploy/observability/loki/loki-config.yml:22:      schema: v13
./deploy/observability/loki/loki.yml:17:schema_config:
./deploy/observability/loki/loki.yml:22:      schema: v13
./deploy/quality/config/lvl14_contract_gate_catalog.yaml:13:      - schema_version
./devtools/logs.sh:14:if [[ "$svc" == "migrate" ]]; then
./devtools/logs.sh:15:  file="logs/migrate.log"
./devtools/logs.sh:7:  echo "Kullanım: ./scripts/logs.sh identity-api|finance-api|gateway|migrate"
./devtools/run_all.sh:44:mig="$(find_main migrate)"
./devtools/run_all.sh:46:  go run "./$mig" | tee "logs/migrate.log"
./devtools/run_all.sh:48:  echo "⚠️  [migrate] cmd/migrate altında *main*.go yok → SKIP"
./devtools/run_migrate.sh:8:echo "🗄️  Running migrations..."
./devtools/run_migrate.sh:9:go run ./cmd/migrate
./guard/pix2pi_guard.sh:100:    if grep -RIn 'CREATE TABLE' migrations/services >/dev/null 2>&1; then
./guard/pix2pi_guard.sh:101:      if ! grep -RIn 'tenant_id' migrations/services >/dev/null 2>&1; then
./guard/pix2pi_guard.sh:125:  fail "Tenant isolation şüpheli: $SUSPECT > $MAX_SUSPECT_QUERIES (repo/migration kontrollerini gözden geçir)"
./guard/pix2pi_guard.sh:136:  fail "v1 event schema az: $SCHEMA_COUNT < $MIN_V1_SCHEMAS"
./guard/pix2pi_guard.sh:138:ok "Contracts v1 OK (schemas=$SCHEMA_COUNT)"
./guard/pix2pi_guard.sh:89:# 1) migrations/services içinde tenant_id yoksa şüpheli
./guard/pix2pi_guard.sh:90:if [ -d migrations/services ]; then
./guard/pix2pi_guard.sh:93:    if rg -n 'CREATE TABLE' migrations/services >/dev/null 2>&1; then
./guard/pix2pi_guard.sh:95:      if ! rg -n 'tenant_id' migrations/services >/dev/null 2>&1; then
./infra/observability/loki/loki-config.yml:17:schema_config:
./infra/observability/loki/loki-config.yml:22:      schema: v13
./install_phase1_scaffold.sh:122:CREATE TABLE core.schema_registry (
./install_phase1_scaffold.sh:124:  schema_name text NOT NULL UNIQUE,
./install_phase1_scaffold.sh:132:INSERT INTO core.schema_registry (schema_name, purpose, isolation_level, owner_domain)
./install_phase1_scaffold.sh:191:  table_schema text NOT NULL,
./install_phase1_scaffold.sh:198:  UNIQUE (table_schema, table_name, column_name)
./install_phase1_scaffold.sh:201:INSERT INTO meta.table_column_standards (table_schema, table_name, column_name, data_type, is_required, semantic_role, notes)
./install_phase1_scaffold.sh:215:  table_schema text NOT NULL,
./install_phase1_scaffold.sh:227:  UNIQUE (table_schema, table_name, field_name)
./install_phase1_scaffold.sh:230:INSERT INTO meta.field_contracts (table_schema, table_name, field_name, label_tr, data_type, nullable, domain_rule, ui_hint, api_contract)
./install_phase1_scaffold.sh:23:mkdir -p "$ROOT_DIR/db/migrations"
./install_phase1_scaffold.sh:24:cat > "$ROOT_DIR/db/migrations/001_phase1_foundation.up.sql" <<'EOF'
./install_phase1_scaffold.sh:341:  entity_schema text NOT NULL,
./install_phase1_scaffold.sh:7:mkdir -p "$ROOT_DIR/db/migrations"
./install_phase1_scaffold.sh:8:cat > "$ROOT_DIR/db/migrations/001_phase1_foundation.down.sql" <<'EOF'
./Makefile:14:	@echo "  make migrate    -> migration runner"
./Makefile:3:.PHONY: help tidy fmt vet test testcore check migrate identity finance gateway ports ps
./Makefile:40:migrate:
./Makefile:41:	@echo "🧱 Running migrations..."
./Makefile:42:	@go run ./cmd/migrate/migrate_main.go
./scripts/event_platform_final_suite.sh:111:  "go run ./cmd/event-schema-test"
./scripts/phase4_discover_migration_chain.sh:100:  | xargs -0 grep -InE 'migrate|migration|db-up|db-down|schema' \
./scripts/phase4_discover_migration_chain.sh:133:    print "OK ✅ duplicate numeric migration version bulunmadi"
./scripts/phase4_discover_migration_chain.sh:145:  echo "OK ✅ numeric prefixsiz migration adayi bulunmadi" > "$NON_STANDARD_FILE"
./scripts/phase4_discover_migration_chain.sh:18:MIGRATION_DIRS_FILE="$TMP_DIR/migration_dirs.txt"
./scripts/phase4_discover_migration_chain.sh:19:MIGRATION_SQL_FILE="$TMP_DIR/migration_sql_files.txt"
./scripts/phase4_discover_migration_chain.sh:21:CODE_REFS_FILE="$TMP_DIR/migration_code_refs.txt"
./scripts/phase4_discover_migration_chain.sh:22:MAKE_REFS_FILE="$TMP_DIR/migration_make_refs.txt"
./scripts/phase4_discover_migration_chain.sh:238:    echo "Pair kontrol edilecek migration SQL adayi yok."
./scripts/phase4_discover_migration_chain.sh:242:  echo "## 7. Kod icindeki migration referanslari"
./scripts/phase4_discover_migration_chain.sh:248:    echo "Kod icinde migration referansi bulunamadi."
./scripts/phase4_discover_migration_chain.sh:252:  echo "## 8. Make / script / compose migration referanslari"
./scripts/phase4_discover_migration_chain.sh:258:    echo "Make/script/compose icinde migration referansi bulunamadi."
./scripts/phase4_discover_migration_chain.sh:264:  echo "- Bu rapor migration chain standardi yazilmadan once mevcut durumu kanitlamak icin uretildi."
./scripts/phase4_discover_migration_chain.sh:265:  echo "- 14.1.1 adiminda bu rapora gore tek migration naming/version/pair standardi belirlenecek."
./scripts/phase4_discover_migration_chain.sh:266:  echo "- Bu adim migration dosyalarini degistirmez."
./scripts/phase4_discover_migration_chain.sh:270:echo "OK ✅ migration chain discovery raporu üretildi"
./scripts/phase4_discover_migration_chain.sh:38:  \( -iname '*migration*' \
./scripts/phase4_discover_migration_chain.sh:58:grep -Ei '(^|/)(migrations?|db|database|schema|tenant|rls|policy)(/|_)|migration' "$ALL_SQL_FILE" \
./scripts/phase4_discover_migration_chain.sh:6:REPORT_FILE="$REPORT_DIR/14_1_migration_chain_discovery.md"
./scripts/phase4_discover_migration_chain.sh:80:  | xargs -0 grep -InE 'golang-migrate|goose|atlas|schema_migrations|migration|migrate|dirty|up\.sql|down\.sql' \
./scripts/step_event_platform_final_suite_run_1.sh:48:test_kw = re.compile(r"(event|replay|idempot|dlq|retry|schema|metadata|lifecycle|concurr|persist|usercreated|user_created|consumer)", re.I)
./scripts/test_phase4_migration_discovery.sh:14:bash "$SCRIPT" >/tmp/pix2pi_phase4_migration_discovery_test.log 2>&1
./scripts/test_phase4_migration_discovery.sh:18:  cat /tmp/pix2pi_phase4_migration_discovery_test.log || true
./scripts/test_phase4_migration_discovery.sh:28:  echo "TEST_FAIL ❌ migration SQL adaylari bolumu eksik"
./scripts/test_phase4_migration_discovery.sh:6:SCRIPT="scripts/phase4_discover_migration_chain.sh"
./scripts/test_phase4_migration_discovery.sh:7:REPORT="docs/phase4/14_1_migration_chain_discovery.md"
```

## 9. Ilk karar notu

- Bu rapor migration chain standardi yazilmadan once mevcut durumu kanitlamak icin uretildi.
- 14.1.1 adiminda bu rapora gore tek migration naming/version/pair standardi belirlenecek.
- Bu adim migration dosyalarini degistirmez.
