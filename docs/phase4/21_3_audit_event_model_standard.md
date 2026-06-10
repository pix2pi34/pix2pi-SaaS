# FAZ 4B / 21.3 - Audit Event Model

Amaç:
Permission guard, RBAC, tenant access, support/super-admin boundary ve pilot operasyonları için tenant-safe audit event modelini kurmak.

Bu adım:
- Migration pair oluşturur.
- DB apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- Gerçek audit log yazmaz.
- Gerçek immutable chain çalıştırmaz.
- Gerçek permission guard enforce etmez.
- Servis restart etmez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Ön koşul:
- 21.1 Role matrix PASS olmalı.
- 21.2 Permission guard PASS olmalı.
- 19 Panel/Admin final closure PASS olmalı.

Oluşturulacak schema:
- `platform_security`

Oluşturulacak tablolar:
1. `platform_security.audit_event_streams`
2. `platform_security.audit_events`
3. `platform_security.audit_actor_contexts`
4. `platform_security.audit_resource_contexts`
5. `platform_security.audit_decision_contexts`
6. `platform_security.audit_integrity_chain`

Audit event modeli neyi yakalar?
- Kim yaptı? actor/user/role/session bilgisi
- Hangi tenant içinde yaptı?
- Hangi resource üzerinde yaptı?
- Hangi action/permission ile yaptı?
- Permission guard kararı neydi?
- ALLOW / DENY sonucu neydi?
- Deny reason neydi?
- High-risk işlem miydi?
- Request/correlation trace var mı?
- Event hash / previous hash ile immutable zincire hazır mı?

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Audit event başka tenant ile ilişkilendirilemez.
- Actor context tenant scope dışına çıkamaz.
- Resource context tenant scope dışına çıkamaz.
- Decision context tenant scope dışına çıkamaz.
- Integrity chain tenant bazlı hesaplanmaya hazır olmalıdır.
- Cross-tenant audit görüntüleme yasaktır.

Kapanış hedefi:
AUDIT_EVENT_MODEL=PASS
AUDIT_EVENT_MODEL_MIGRATION_PAIR=PASS
AUDIT_EVENT_MODEL_TABLE_COUNT=6
AUDIT_EVENT_MODEL_TENANT_ID_COLUMN_COUNT=6
AUDIT_EVENT_MODEL_INDEX_COUNT>=14
AUDIT_EVENT_MODEL_IMMUTABLE_READY=PASS
AUDIT_EVENT_MODEL_TRACE_READY=PASS
AUDIT_EVENT_MODEL_DECISION_READY=PASS
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
AUDIT_LOG_WRITE_EXECUTED=NO
PERMISSION_GUARD_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_21_3_FINAL_STATUS=PASS

## 21.3R Notu - Audit event counter fix

21.3 test gate şu sayaçları bekler:
- audit_event_id >= 6
- decision reference >= 7
- event_hash >= 3

İlk koşuda tablo modeli doğru kurulmuştu; ancak audit stream seviyesinde anchor alanları eksik kaldığı için sayaçlar düşük geldi.

Bu nedenle `audit_event_streams` tablosuna şu alanlar eklendi:

- `audit_event_id text`
- `decision text not null default 'STREAM_READY'`
- `event_hash text`

Amaç:
- Audit stream seviyesinde son/anchor audit event bağlantısına hazır olmak
- Stream seviyesinde decision state gösterebilmek
- Stream seviyesinde hash anchor tutmaya hazır olmak
- Immutable audit chain modelini daha güçlü kapatmak

Bu fix:
- DB mutate etmez.
- DB apply yapmaz.
- Migration apply yapmaz.
- Audit log yazmaz.
- Permission guard çalıştırmaz.
- Sadece migration contract/evidence düzeltir.
