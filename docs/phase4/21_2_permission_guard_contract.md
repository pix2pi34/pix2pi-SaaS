# FAZ 4B / 21.2 - Permission Guard Contract

## Guard

GUARD_ID=platform_permission_guard
GUARD_SCOPE=tenant_api_panel
GUARD_STATUS=contract_only
ENFORCEMENT_STATUS=not_executed

## Required Guard Inputs

- tenant_id
- tenant_uuid
- user_id
- role_code
- permission_code
- resource_area
- resource_name
- action_code
- request_id
- correlation_id
- source_route
- http_method
- jwt_tenant_id
- header_tenant_id
- support_access_reason
- super_admin_boundary_mode
- cross_tenant_boundary_mode

## Required Guard Outputs

- decision_id
- tenant_id
- user_id
- role_code
- permission_code
- resource_area
- action_code
- decision
- deny_reason
- boundary_status
- audit_required
- high_risk
- request_id
- correlation_id
- decided_at

## Decision Values

- ALLOW
- DENY
- DENY_NO_TENANT
- DENY_TENANT_MISMATCH
- DENY_ROLE_MISSING
- DENY_PERMISSION_MISSING
- DENY_SCOPE_MISMATCH
- DENY_CROSS_TENANT
- DENY_SUPPORT_BOUNDARY
- DENY_SUPER_ADMIN_BOUNDARY
- DENY_HIGH_RISK_APPROVAL_REQUIRED

## Guard Middleware Order

1. RequestIdMiddleware
2. AuthMiddleware
3. TenantContextMiddleware
4. RoleContextMiddleware
5. PermissionGuardMiddleware
6. BoundaryGuardMiddleware
7. AuditReadyMiddleware
8. Handler

## Guard Surfaces

- panel_route_guard
- api_route_guard
- import_action_guard
- inventory_action_guard
- reporting_access_guard
- uat_action_guard
- issue_feedback_guard
- security_admin_guard
- support_boundary_guard
- super_admin_boundary_guard

## Tenant Boundary Rules

- tenant_id zorunludur.
- jwt_tenant_id zorunludur.
- header_tenant_id varsa jwt_tenant_id ile uyumlu olmalıdır.
- Tenant context yoksa DENY_NO_TENANT döner.
- Tenant mismatch varsa DENY_TENANT_MISMATCH döner.
- Cross-tenant access varsayılan DENY_CROSS_TENANT döner.
- Support access sadece support boundary içinde değerlendirilebilir.
- Super-admin access sadece super_admin_boundary_mode ile değerlendirilebilir.
- Permission guard tenant scope dışına veri sızdırmaz.
- Permission guard query text basmaz.
- Permission guard token basmaz.
- Permission guard raw DSN veya password basmaz.

## Audit Ready Rules

- Her high_risk permission audit_required=true olmalıdır.
- DENY kararları audit-ready event payload'a hazırlanır ama bu adımda audit yazılmaz.
- ALLOW kararları audit-ready olabilir ama bu adımda audit yazılmaz.
- Audit event model 21.3 adımında kurulacaktır.

## Safety

DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
PERMISSION_GUARD_EXECUTED=NO
RBAC_ENFORCEMENT_EXECUTED=NO
AUDIT_LOG_WRITE_EXECUTED=NO
PANEL_ROUTE_DEPLOYED=NO
API_ROUTE_DEPLOYED=NO
SERVICE_RESTARTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
