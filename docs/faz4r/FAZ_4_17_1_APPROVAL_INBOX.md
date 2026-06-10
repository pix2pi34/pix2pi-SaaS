# 236 — FAZ 4-17.1 Approval Inbox

## Amaç

235 Pilot Closure Report PASS olduktan sonra WEB-L7 Workflow / Realtime UI bloğunun ilk yüzeyi olan Approval Inbox standardını kurar.

Bu adım canlı workflow mutation yapmaz. Onay işlemi çalıştırmaz. Sadece approval inbox modelini, UI checkpoint artifact'ini, tenant-safe görünüm kurallarını, filtre/sıralama modelini, durum rozetlerini, role/action guard'larını ve policy kapılarını üretir.

## Kapsam

- Approval inbox shell
- Tenant scoped inbox
- Pending approval list
- Approval item metadata
- Priority / SLA indicator
- Status badge model
- Actor role visibility
- Action button state model
- Approval detail link placeholder
- Empty state
- Error state
- Realtime placeholder
- Audit trace placeholder
- No mutation guard
- External policy closed gate
- UI checkpoint HTML
- Final approval inbox readiness report

## Ana Kural

Bu adım gerçek approve/reject işlemi yapmaz.

Bu adım workflow engine state değiştirmez.

Bu adım production launch yapmaz.

Bu adım canlı provider, GIB, banka, POS, ödeme sağlayıcı, DNS, Nginx veya SSL değişikliği yapmaz.

Bu adım sadece Approval Inbox readiness artifact'i ve UI checkpoint üretir.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Approval Inbox PASS sayılırsa:

- approval_inbox_status = READY olmalıdır.
- approval_inbox_mode = CONTROLLED_PILOT olmalıdır.
- required inbox item'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_item_count gerçek item sayısıyla eşleşmelidir.
- ready_item_count gerçek READY sayısıyla eşleşmelidir.
- missing_item_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- tenant_scope = SINGLE_TENANT olmalıdır.
- role_visibility_status = READY olmalıdır.
- action_state_status = READY olmalıdır.
- no_workflow_mutation = true olmalıdır.
- no_real_approval_execution = true olmalıdır.
- no_realtime_socket_connection = true olmalıdır.
- web_checkpoint_status = READY olmalıdır.
- pilot_closure_status = PASS olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Approval Inbox dokümanı vardır.
- Master config artifact vardır.
- Approval Inbox artifact vardır.
- UI checkpoint HTML vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid inbox fixture PASS döner.
- Invalid inbox fixture FAIL döner.
- Required item guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Tenant scope guard doğrulanır.
- Role/action state guard doğrulanır.
- No mutation / no real approval / no socket guard doğrulanır.
- UI checkpoint marker doğrulanır.
- Closed policy marker doğrulanır.
- FAZ_4_17_2_READY=YES üretilir.
