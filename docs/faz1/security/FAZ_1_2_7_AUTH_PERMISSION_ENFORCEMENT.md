# FAZ 1-2.7 Auth / Permission Enforcement Test Set

## Amaç

Bu faz, FAZ 1-2.4 user scope ve FAZ 1-2.5 RBAC modelinin sadece var olduğunu değil, gerçek enforcement ürettiğini doğrular.

## Kapsam

- Permission denied before role link
- Permission denied before user role grant
- Role grant enforcement
- Permission grant enforcement
- Permission assertion
- Denied user forbidden path
- User scope grant enforcement
- User scope assertion
- Denied user scope forbidden path
- Revoke sonrası permission kapanışı
- RLS tenant boundary
- API/gateway/static guard trace audit
- Rollback cleanup

## FIX V2 Notu

İlk enforcement suite, `pix2pi_role_permission_verify_role` rolüyle `auth.user_scopes` üzerinde doğrudan RLS boundary sayımı yaparken `permission denied for table user_scopes` hatasına düştü. FIX V2, enforcement verify rolüne `auth.user_scopes` ve `auth.user_scope_audit` için minimum tablo izinlerini ve auth/app_security/security function execute yetkilerini verir.

## Kapanış Şartı

- `FAIL_COUNT=0`
- RBAC table count = 4
- RBAC RLS enabled count = 4
- RBAC RLS forced count = 4
- RBAC policy count = 8
- RBAC function count = 6
- RBAC bridge function count = 3
- User scope function count = 4
- DB enforcement lifecycle suite PASS
- Static API/gateway enforcement audit PASS
- Rollback cleanup PASS
