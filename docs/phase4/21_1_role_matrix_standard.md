# FAZ 4B / 21.1 - Role Matrix

Amaç:
Pilot öncesi panel, API, import, UAT, issue/feedback ve admin operasyonları için tenant-safe RBAC rol/yetki matrisini kurmak.

Bu adım:
- Migration pair oluşturur.
- DB apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- Gerçek permission guard çalıştırmaz.
- Gerçek panel RBAC enforce etmez.
- Gerçek audit log yazmaz.
- Servis restart etmez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Oluşturulacak schema:
- `platform_security`

Oluşturulacak tablolar:
1. `platform_security.role_matrix_profiles`
2. `platform_security.role_definitions`
3. `platform_security.permission_definitions`
4. `platform_security.role_permission_matrix`
5. `platform_security.role_scope_rules`
6. `platform_security.role_matrix_validation_errors`

Pilot rol grupları:
- tenant_owner
- tenant_admin
- operator
- accountant
- support_readonly
- support_operator
- super_admin_boundary

Yetki alanları:
- panel
- api
- import
- inventory
- reporting
- uat
- issue_feedback
- security
- audit

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Rol ve permission kayıtları tenant scope içinde değerlendirilir.
- Cross-tenant role assignment yasaktır.
- Support / super-admin yetkileri ileride 21.5 boundary gate ile sınırlandırılır.
- Gerçek enforce işlemi 21.2 Permission guard adımından önce çalıştırılmaz.

Kapanış hedefi:
ROLE_MATRIX=PASS
ROLE_MATRIX_MIGRATION_PAIR=PASS
ROLE_MATRIX_TABLE_COUNT=6
ROLE_MATRIX_TENANT_ID_COLUMN_COUNT=6
ROLE_MATRIX_INDEX_COUNT>=12
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
RBAC_ENFORCEMENT_EXECUTED=NO
AUDIT_LOG_WRITE_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_21_1_FINAL_STATUS=PASS

## 21.1R Notu - Permission / boundary evidence fix

21.1 test gate şu sayaçları bekler:
- permission_code >= 4
- super_admin_boundary >= 2
- cross_tenant boundary >= 3

Bu nedenle `role_scope_rules` tablosuna şu alanlar eklendi:

- `permission_code text`
- `super_admin_boundary_mode text not null default 'tenant_locked'`
- `cross_tenant_boundary_mode text not null default 'deny'`

Amaç:
- Scope rule seviyesinde permission bağlamını görünür yapmak
- Super-admin boundary kuralını role scope seviyesinde de izlemek
- Cross-tenant erişimin varsayılan olarak kapalı olduğunu açık contract haline getirmek
