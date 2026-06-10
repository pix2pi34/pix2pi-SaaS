# 191 — FAZ 4-15.1 Operational Readmodel Tabloları

## Amaç

FAZ 4-R DB-L6 Reporting / Readmodel bloğunun son parçası olarak operasyonel readmodel tablolarını kurar.

## Kapsam

Bu adım aşağıdaki tabloları kurar:

- operational_readmodel_snapshots
- operational_tenant_health_readmodel
- operational_user_activity_readmodel
- operational_import_queue_readmodel
- operational_task_queue_readmodel
- operational_service_health_readmodel
- operational_readmodel_projection_offsets
- operational_readmodel_audit_events

## Mimari Karar

Operational readmodel transactional domain tablolarından ayrıdır.

Amaç:

- Pilot operasyon dashboardları
- Tenant health görünümü
- Kullanıcı aktivite görünümü
- Import queue görünümü
- Task / UAT / support queue görünümü
- Service health görünümü
- Projection offset ve audit izi

## Tenant Güvenliği

Tüm tablolarda tenant_id zorunludur.

Primary key ve index tasarımları tenant_id ile başlar.

## Dış Provider Policy

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Migration dosyası vardır.
- Rollback dosyası vardır.
- Config artifact vardır.
- SQL test artifact vardır.
- Audit script vardır.
- PostgreSQL temporary schema içinde migration uygulanır.
- Required operational readmodel tabloları metadata üzerinden doğrulanır.
- Required FK / index yapıları doğrulanır.
- Tenant health, user activity, import queue, task queue, service health behavior testleri geçer.
- Final status gerçek test/audit sayaçlarından türetilir.
