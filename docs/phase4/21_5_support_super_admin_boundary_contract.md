# FAZ 4B / 21.5 - Support / Super-admin Boundary Contract

## Contract

CONTRACT_ID=support_super_admin_boundary
CONTRACT_SCOPE=security_rbac_audit_tenant_boundary
CONTRACT_STATUS=contract_only
ENFORCEMENT_STATUS=not_executed

## Required Inputs

- tenant_id
- tenant_uuid
- actor_user_id
- actor_role_code
- actor_role_group
- target_tenant_id
- target_resource_area
- target_resource_name
- target_resource_id
- requested_action
- permission_code
- support_access_reason
- support_ticket_id
- support_access_mode
- super_admin_boundary_mode
- break_glass_reason_code
- break_glass_ticket_id
- approval_request_id
- approver_user_id
- approval_status
- access_timebox_minutes
- request_id
- correlation_id
- source_route
- http_method

## Required Outputs

- boundary_decision_id
- tenant_id
- actor_user_id
- actor_role_code
- target_tenant_id
- requested_action
- decision
- deny_reason
- deny_reason_code
- boundary_status
- support_access_allowed
- super_admin_access_allowed
- break_glass_required
- approval_required
- audit_required
- high_risk
- timebox_required
- request_id
- correlation_id
- decided_at

## Decision Values

- ALLOW_SUPPORT_READONLY_TIMEBOXED
- ALLOW_SUPPORT_OPERATOR_APPROVED
- ALLOW_SUPER_ADMIN_BREAK_GLASS_APPROVED
- DENY_SUPPORT_REASON_MISSING
- DENY_SUPPORT_TICKET_MISSING
- DENY_SUPPORT_TIMEBOX_MISSING
- DENY_SUPPORT_SECRET_ACCESS
- DENY_SUPPORT_EXPORT_ACCESS
- DENY_SUPPORT_TENANT_SCOPE
- DENY_SUPER_ADMIN_BREAK_GLASS_REQUIRED
- DENY_SUPER_ADMIN_APPROVAL_MISSING
- DENY_SUPER_ADMIN_SILENT_ACCESS
- DENY_SUPER_ADMIN_TIMEBOX_MISSING
- DENY_CROSS_TENANT_BOUNDARY
- DENY_BOUNDARY_AUDIT_REQUIRED
- DENY_EMERGENCY_REVOKED

## Boundary Rules

- support_readonly_requires_reason: support readonly access reason olmadan açılamaz.
- support_operator_requires_ticket: support operator access ticket olmadan açılamaz.
- support_timeboxed_access: support access timebox olmadan açılamaz.
- support_no_secret_access: support secret access her zaman deny.
- support_no_export_default: support export access varsayılan deny.
- support_tenant_scope_required: support access tenant scope içinde kalmalıdır.
- super_admin_break_glass_required: super-admin tenant access break-glass olarak işaretlenmelidir.
- super_admin_dual_approval_required: super-admin break-glass dual approval gerektirir.
- super_admin_timeboxed_access: super-admin break-glass timebox olmadan açılamaz.
- super_admin_no_silent_access: silent access yasaktır.
- cross_tenant_default_deny: cross-tenant boundary varsayılan deny.
- audit_required_for_all_boundary_access: tüm boundary kararları audit_required=true olmalıdır.
- emergency_revocation_required: emergency revoke geldiğinde erişim kapatılır.

## Audit Ready Rules

- Her support allow/deny kararı audit_required=true olmalıdır.
- Her super-admin allow/deny kararı audit_required=true olmalıdır.
- Her break-glass kararı high_risk=true olmalıdır.
- Cross-tenant deny high_risk=true olmalıdır.
- Secret/export deny high_risk=true olmalıdır.
- Audit event model 21.3 ile uyumlu request_id ve correlation_id taşınmalıdır.
- Bu adım audit log yazmaz; sadece audit-ready contract üretir.

## Safety

DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
SUPPORT_ACCESS_EXECUTED=NO
SUPER_ADMIN_ACCESS_EXECUTED=NO
BREAK_GLASS_EXECUTED=NO
PERMISSION_GUARD_EXECUTED=NO
RBAC_ENFORCEMENT_EXECUTED=NO
AUDIT_LOG_WRITE_EXECUTED=NO
PANEL_ROUTE_DEPLOYED=NO
API_ROUTE_DEPLOYED=NO
SERVICE_RESTARTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
AUTH_TOKEN_PRINTED=NO
