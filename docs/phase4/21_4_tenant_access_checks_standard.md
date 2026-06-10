# FAZ 4B / 21.4 - Tenant Access Checks

Amaç:
Pilot öncesi tenant izolasyonunu permission guard ve audit event modeline bağlayacak tenant access check standardını kurmak.

Bu adım:
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Gerçek tenant access middleware çalıştırmaz.
- Gerçek RBAC enforce etmez.
- Gerçek audit log yazmaz.
- Panel/API route deploy etmez.
- Servis restart etmez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Ön koşul:
- 21.1 Role matrix PASS olmalı.
- 21.2 Permission guard PASS olmalı.
- 21.3 Audit event model PASS olmalı.
- 19 Panel/Admin final closure PASS olmalı.

Tenant access check ne yapacak?
- JWT tenant bilgisini kontrol eder.
- Header tenant bilgisini kontrol eder.
- Actor tenant bilgisini kontrol eder.
- Resource tenant bilgisini kontrol eder.
- Role tenant scope kontrolünü yapar.
- Permission tenant scope kontrolünü yapar.
- Audit tenant scope kontrolünü yapar.
- Cross-tenant erişimi varsayılan DENY yapar.
- Support erişimini boundary gate olmadan DENY yapar.
- Super-admin erişimini boundary gate olmadan DENY yapar.
- Deny kararlarını audit-ready payload olarak hazırlamaya uygun contract üretir.

Check IDs:
- tenant_context_required
- jwt_tenant_required
- header_tenant_match
- actor_tenant_match
- resource_tenant_match
- route_tenant_scope
- permission_tenant_scope
- role_tenant_scope
- audit_tenant_scope
- support_boundary_tenant_scope
- super_admin_boundary_tenant_scope
- cross_tenant_default_deny

Surface IDs:
- panel_admin_tenant_check
- api_route_tenant_check
- import_batch_tenant_check
- inventory_resource_tenant_check
- reporting_resource_tenant_check
- uat_checklist_tenant_check
- issue_feedback_tenant_check
- audit_event_tenant_check
- support_access_tenant_check
- super_admin_tenant_check

Tenant güvenliği:
- tenant context yoksa DENY.
- jwt_tenant_id yoksa DENY.
- header_tenant_id varsa jwt_tenant_id ile eşleşmeli.
- actor_tenant_id, request tenant ile eşleşmeli.
- resource_tenant_id, request tenant ile eşleşmeli.
- role tenant scope, request tenant ile eşleşmeli.
- permission tenant scope, request tenant ile eşleşmeli.
- audit tenant scope, request tenant ile eşleşmeli.
- Cross-tenant erişim varsayılan DENY.
- Support access boundary yoksa DENY.
- Super-admin access boundary yoksa DENY.

Kapanış hedefi:
TENANT_ACCESS_CHECKS=PASS
TENANT_ACCESS_CHECKS_CONTRACT=PASS
TENANT_ACCESS_CHECKS_CHECK_MANIFEST=PASS
TENANT_ACCESS_CHECKS_DECISION_MANIFEST=PASS
TENANT_ACCESS_CHECKS_SURFACE_MANIFEST=PASS
TENANT_ACCESS_CHECKS_PREVIOUS_21_3=PASS
TENANT_ACCESS_CHECKS_TENANT_SAFETY=PASS
TENANT_ACCESS_CHECKS_BOUNDARY_STATUS=PASS
TENANT_ACCESS_CHECKS_AUDIT_READY=PASS
TENANT_ACCESS_CHECKS_NO_APPLY=PASS
TENANT_ACCESS_CHECKS_SECRET_SAFETY=PASS
FAZ4B_21_4_FINAL_STATUS=PASS
