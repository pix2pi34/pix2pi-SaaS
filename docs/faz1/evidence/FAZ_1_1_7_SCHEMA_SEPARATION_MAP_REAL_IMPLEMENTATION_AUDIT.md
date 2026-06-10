# FAZ 1-1.7 Schema Separation Map Real Implementation Audit

- Tarih: 2026-05-05T08:24:18+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Migration file: /root/pix2pi/pix2pi-SaaS/db/migrations/faz1/20260505_082415_faz_1_1_7_schema_separation_map.sql
- Strict suite file: /root/pix2pi/pix2pi-SaaS/scripts/db/faz_1_1_7_schema_separation_map_strict_suite.sh
- Doc file: /root/pix2pi/pix2pi-SaaS/docs/faz1/db/FAZ_1_1_7_SCHEMA_SEPARATION_MAP.md
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_1_7_schema_separation_map_20260505_082415/suite_runtime

## Evidence Snapshots
- Schema inventory CSV: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_1_7_schema_separation_map_20260505_082415/suite_runtime/schema_inventory.csv
- Table inventory CSV: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_1_7_schema_separation_map_20260505_082415/suite_runtime/schema_table_inventory.csv
- Boundary map CSV: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_1_7_schema_separation_map_20260505_082415/suite_runtime/schema_boundary_map.csv
- Migration path inventory: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_1_7_schema_separation_map_20260505_082415/suite_runtime/migration_path_inventory.txt

## Counters
- MIGRATION_FILE_COUNT=107
- FAZ1_MIGRATION_FILE_COUNT=31
- BOUNDARY_MAP_TABLE_COUNT=1
- BOUNDARY_MAP_ROW_COUNT=6
- BOUNDARY_REQUIRED_ROW_COUNT=6
- BOUNDARY_ACTIVE_ROW_COUNT=6
- AUTH_SCHEMA_COUNT=3
- TENANT_SCHEMA_COUNT=3
- ERP_SCHEMA_COUNT=2
- OPS_SCHEMA_COUNT=4
- REPORTING_SCHEMA_COUNT=1
- AUTH_BOUNDARY_COUNT=1
- TENANT_BOUNDARY_COUNT=1
- ERP_BOUNDARY_COUNT=1
- OPS_BOUNDARY_COUNT=1
- REPORTING_BOUNDARY_COUNT=1
- MIGRATION_PATH_BOUNDARY_COUNT=1
- BOUNDARY_CONSTRAINT_COUNT=2
- BOUNDARY_INDEX_COUNT=4
- BOUNDARY_TRIGGER_COUNT=1
- STRICT_SUITE_PASS_COUNT=25
- STRICT_SUITE_FAIL_COUNT=0
- STRICT_SUITE_WARN_COUNT=0
- STRICT_SUITE_STATUS=PASS
- STRICT_SUITE_SEAL_STATUS=SEALED

## Apply Counters
- PASS_COUNT=37
- FAIL_COUNT=0
- WARN_COUNT=3
