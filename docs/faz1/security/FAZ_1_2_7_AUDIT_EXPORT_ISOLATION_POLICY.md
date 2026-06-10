# FAZ 1-2.7 Audit / Export Isolation Policy

## Kapsam

- Tenant-safe audit
- Legal entity-safe audit
- Branch-safe audit
- Tenant-safe export
- Cross-tenant export guard
- Export evidence

## Strict Reseal

Bu strict reseal adımı audit/event/log tablolarını, tenant_id / legal_entity_id / branch_id kapsamını, audit RLS/policy izlerini, export guard repo kanıtlarını, cross-tenant export guard izlerini ve export evidence dosyalarını doğrular.

## Final Status

- FAZ_1_2_7_TENANT_SAFE_AUDIT_STATUS=PASS
- FAZ_1_2_7_LEGAL_ENTITY_SAFE_AUDIT_STATUS=PASS
- FAZ_1_2_7_BRANCH_SAFE_AUDIT_STATUS=PASS
- FAZ_1_2_7_TENANT_SAFE_EXPORT_STATUS=PASS
- FAZ_1_2_7_CROSS_TENANT_EXPORT_GUARD_STATUS=PASS
- FAZ_1_2_7_EXPORT_EVIDENCE_STATUS=PASS
- FAZ_1_2_7_AUDIT_EXPORT_ISOLATION_SEAL_STATUS=SEALED
