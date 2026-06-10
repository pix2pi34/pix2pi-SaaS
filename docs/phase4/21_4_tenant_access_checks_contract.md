# FAZ 4B / 21.4 - Tenant Access Checks Contract

## Contract

CONTRACT_ID=tenant_access_checks
CONTRACT_SCOPE=tenant_api_panel_security
CONTRACT_STATUS=contract_only
ENFORCEMENT_STATUS=not_executed

## Required Inputs

- tenant_id
- tenant_uuid
- jwt_tenant_id
- header_tenant_id
- actor_tenant_id
- actor_user_id
- actor_role_code
- resource_tenant_id
- resource_area
- resource_name
- resource_id
- role_code
- permission_code
- action_code
- source_route
- http_method
- request_id
- correlation_id
- support_access_reason
- super_admin_boundary_mode
- cross_tenant_boundary_mode

## Required Outputs

- tenant_access_check_id
- tenant_id
- actor_user_id
- resource_tenant_id
- role_code
- permission_code
- action_code
- decision
- deny_reason
- deny_reason_code
- boundary_status
- audit_required
- high_risk
- request_id
- correlation_id
- checked_at

## Decision Values

- ALLOW_TENANT_MATCH
- DENY_NO_TENANT
- DENY_JWT_TENANT_MISSING
- DENY_HEADER_TENANT_MISMATCH
- DENY_ACTOR_TENANT_MISMATCH
- DENY_RESOURCE_TENANT_MISMATCH
- DENY_ROUTE_TENANT_SCOPE
- DENY_ROLE_TENANT_SCOPE
- DENY_PERMISSION_TENANT_SCOPE
- DENY_AUDIT_TENANT_SCOPE
- DENY_CROSS_TENANT
- DENY_SUPPORT_BOUNDARY_TENANT
- DENY_SUPER_ADMIN_BOUNDARY_TENANT

## Check Rules

- tenant_context_required: tenant_id ve tenant_uuid olmadan geçiş yok.
- jwt_tenant_required: jwt_tenant_id olmadan geçiş yok.
- header_tenant_match: header_tenant_id varsa jwt_tenant_id ile eşleşmeli.
- actor_tenant_match: actor_tenant_id request tenant ile eşleşmeli.
- resource_tenant_match: resource_tenant_id request tenant ile eşleşmeli.
- route_tenant_scope: route tenant scope dışına çıkmamalı.
- permission_tenant_scope: permission_code tenant scope içinde olmalı.
- role_tenant_scope: role_code tenant scope içinde olmalı.
- audit_tenant_scope: audit payload tenant scope içinde hazırlanmalı.
- support_boundary_tenant_scope: support erişimi boundary olmadan kapalı olmalı.
- super_admin_boundary_tenant_scope: super-admin erişimi boundary olmadan kapalı olmalı.
- cross_tenant_default_deny: cross-tenant erişim varsayılan DENY olmalı.

## Audit Ready Rules

- Tüm DENY kararları audit_required=true olmalıdır.
- Cross-tenant DENY kararları high_risk=true olmalıdır.
- Support boundary DENY kararları high_risk=true olmalıdır.
- Super-admin boundary DENY kararları high_risk=true olmalıdır.
- Bu adım audit log yazmaz; 21.3 Audit event modeline uygun payload contract üretir.

## Safety

DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
TENANT_ACCESS_CHECK_EXECUTED=NO
PERMISSION_GUARD_EXECUTED=NO
RBAC_ENFORCEMENT_EXECUTED=NO
AUDIT_LOG_WRITE_EXECUTED=NO
PANEL_ROUTE_DEPLOYED=NO
API_ROUTE_DEPLOYED=NO
SERVICE_RESTARTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
