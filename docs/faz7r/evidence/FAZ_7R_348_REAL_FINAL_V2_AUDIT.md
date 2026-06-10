# FAZ 7-R / 348 REAL FINAL V2 AUDIT

- PASS_COUNT=33
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS

## Send response
```json
{"ok": true, "invite_id": "invite-ef7ada73-df12-49f0-8974-9e645604077a", "tenant_id": "tenant-api-e2e-success", "email": "surucukursu58@gmail.com", "role_code": "owner", "accept_url": "https://panel.pix2pi.com.tr/user-invite/accept/?token=Za2_hkmsk-j8AeudJGrzer_q1wWabnDDGle-ISpDgxc", "token": "Za2_hkmsk-j8AeudJGrzer_q1wWabnDDGle-ISpDgxc", "mail_status": "sent"}
```
## Send DB SELECT
```
invites=1
mail_deliveries=1
audit_events=1
```
## Accept response
```json
{"ok": true, "user_id": "user-348-accepted", "next_url": "/password-login/"}
```
## Accept DB SELECT
```
accepted_invite=1
tenant_users=1
tenant_user_roles=1
accept_audit=1
```
## Duplicate response
```json
{"ok": false, "error": "duplicate_pending_invite", "detail": "DETAIL:  Key (tenant_id, lower(email))=(tenant-api-e2e-success, surucukursu58@gmail.com) already exists."}
```
## Validation response
```json
{"ok": false, "error": "validation_error", "fields": {"email": "required"}}
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback DB SELECT
```
rollback_invites=0
rollback_mail=0
rollback_audit=0
```
## Check log
```
SMTP env present / OK ✅
SMTP env file written / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: tenant_identity.tenant_users / OK ✅
table exists: tenant_identity.tenant_user_invites / OK ✅
table exists: tenant_identity.invite_mail_deliveries / OK ✅
table exists: tenant_identity.invite_audit_events / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx route bind / OK ✅
send route reaches API 422 / OK ✅
frontend written / OK ✅
test data cleanup / OK ✅
REAL_CURL_INVITE_SEND_STATUS HTTP 201 / OK ✅
REAL_MAIL_SEND_STATUS SMTP sent / OK ✅
REAL_INVITE_TOKEN_STATUS token returned / OK ✅
REAL_DB_SELECT_STATUS invites=1 / OK ✅
REAL_DB_SELECT_STATUS mail_deliveries=1 / OK ✅
REAL_DB_SELECT_STATUS audit_events=1 / OK ✅
DUPLICATE_CASE_STATUS HTTP 409 / OK ✅
INVITE_ACCEPTANCE_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS accepted_invite=1 / OK ✅
REAL_DB_SELECT_STATUS tenant_users=1 / OK ✅
REAL_DB_SELECT_STATUS tenant_user_roles=1 / OK ✅
REAL_DB_SELECT_STATUS accept_audit=1 / OK ✅
VALIDATION_ERROR_STATUS HTTP 422 / OK ✅
INVITE_ACCEPTANCE_DUPLICATE_STATUS HTTP 409 / OK ✅
ROLLBACK_STATUS HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_invites=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_mail=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
config semantic validation / OK ✅
```
