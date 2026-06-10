# 237 — FAZ 4-17.2 Workflow Monitor

## Amaç

236 Approval Inbox PASS olduktan sonra WEB-L7 Workflow / Realtime UI bloğunda workflow durumlarını izlemek için monitor standardını kurar.

Bu adım workflow state değiştirmez. Approve / reject / retry / cancel / escalate işlemi çalıştırmaz. Sadece tenant scoped workflow monitor modelini, UI checkpoint artifact'ini, instance özetlerini, durum sayaçlarını, SLA/age göstergelerini, no-mutation guard'larını ve policy kapılarını üretir.

## Kapsam

- Workflow monitor shell
- Tenant scoped monitor
- Workflow instance summary
- Pending approval counter
- Running workflow counter
- Completed workflow counter
- Failed workflow counter
- SLA / age indicator
- Workflow status badge model
- Approval inbox link
- Audit trace placeholder
- Realtime placeholder
- Monitor filter model
- Monitor sort model
- Empty state
- Error state
- No mutation guard
- External policy closed gate
- UI checkpoint HTML
- Final workflow monitor readiness report

## Ana Kural

Bu adım workflow engine state değiştirmez.

Bu adım approve/reject/retry/cancel/escalate işlemi yapmaz.

Bu adım WebSocket/SSE bağlantısı açmaz.

Bu adım production launch yapmaz.

Bu adım canlı provider, GIB, banka, POS, ödeme sağlayıcı, DNS, Nginx veya SSL değişikliği yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Workflow Monitor PASS sayılırsa:

- workflow_monitor_status = READY olmalıdır.
- workflow_monitor_mode = CONTROLLED_PILOT olmalıdır.
- required monitor item'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_item_count gerçek item sayısıyla eşleşmelidir.
- ready_item_count gerçek READY sayısıyla eşleşmelidir.
- missing_item_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- tenant_scope = SINGLE_TENANT olmalıdır.
- approval_inbox_status = PASS olmalıdır.
- workflow_summary_status = READY olmalıdır.
- status_counter_status = READY olmalıdır.
- sla_indicator_status = READY olmalıdır.
- web_checkpoint_status = READY olmalıdır.
- no_workflow_mutation = true olmalıdır.
- no_real_workflow_execution = true olmalıdır.
- no_realtime_socket_connection = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Workflow Monitor dokümanı vardır.
- Master config artifact vardır.
- Workflow Monitor artifact vardır.
- UI checkpoint HTML vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid monitor fixture PASS döner.
- Invalid monitor fixture FAIL döner.
- Required item guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Tenant scope guard doğrulanır.
- Workflow status/counter/SLA guard doğrulanır.
- No mutation / no real workflow execution / no socket guard doğrulanır.
- UI checkpoint marker doğrulanır.
- Closed policy marker doğrulanır.
- FAZ_4_17_5_READY=YES üretilir.
