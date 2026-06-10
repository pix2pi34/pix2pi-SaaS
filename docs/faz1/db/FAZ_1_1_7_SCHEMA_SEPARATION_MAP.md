# FAZ 1-1.7 Schema Separation Map

## Kapsam

- Auth schema
- Tenant schema
- ERP schema
- Ops schema
- Reporting schema
- Migration path

## Uygulama

Bu adım app_schema.schema_boundary_map tablosunu oluşturur ve sistemdeki ana schema sorumluluklarını kalıcı kontrat haline getirir.

## Boundary Kararları

| Boundary | Ana Sorumluluk |
|---|---|
| AUTH | Kimlik, rol, permission, user scope, super-admin, break-glass |
| TENANT | Tenant, legal entity, branch ve tenant scoped business kayıtları |
| ERP | ERP domainleri, muhasebe, stok, satış, ürün ve iş tabloları |
| OPS | Audit, ops, observability, incident, security alert |
| REPORTING | Read model, reporting store, analytics |
| MIGRATION_PATH | db/migrations, docs/evidence ve backups path standardı |

## Final Status

- FAZ_1_1_7_AUTH_SCHEMA_STATUS=PASS
- FAZ_1_1_7_TENANT_SCHEMA_STATUS=PASS
- FAZ_1_1_7_ERP_SCHEMA_STATUS=PASS
- FAZ_1_1_7_OPS_SCHEMA_STATUS=PASS
- FAZ_1_1_7_REPORTING_SCHEMA_STATUS=PASS
- FAZ_1_1_7_MIGRATION_PATH_STATUS=PASS
- FAZ_1_1_7_SCHEMA_SEPARATION_MAP_SEAL_STATUS=SEALED
