# 239 — FAZ 4-17.6 Workflow / Realtime UI Testleri

## Amaç

236 Approval Inbox, 237 Workflow Monitor ve 238 WebSocket / SSE Bağlantı Sağlığı Görünümü adımlarından sonra WEB-L7 Workflow / Realtime UI yüzeylerinin ortak test setini kurar.

Bu adım yeni canlı özellik açmaz. Gerçek approve/reject/retry/cancel/escalate işlemi yapmaz. Gerçek WebSocket/SSE bağlantısı açmaz. Event publish/subscribe yapmaz. Sadece üretilmiş UI checkpoint dosyalarının, config artifact'lerinin, tenant-safe guard'ların, no-mutation guard'ların ve realtime placeholder guard'ların birlikte doğrulanmasını sağlar.

## Kapsam

- Approval Inbox UI test
- Workflow Monitor UI test
- Realtime Health UI test
- Cross navigation marker test
- Tenant scope test
- Status badge test
- Empty state test
- Error state test
- No workflow mutation test
- No real approval execution test
- No real workflow execution test
- No live WebSocket test
- No live SSE test
- No event stream publish test
- External policy closed gate test
- Final workflow realtime UI test report

## Ana Kural

Bu adım gerçek workflow state değiştirmez.

Bu adım gerçek approval action çalıştırmaz.

Bu adım gerçek WebSocket/SSE bağlantısı açmaz.

Bu adım event stream publish/subscribe yapmaz.

Bu adım production launch yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Workflow / realtime UI testleri PASS sayılırsa:

- workflow_realtime_ui_test_status = READY olmalıdır.
- workflow_realtime_ui_test_mode = CONTROLLED_PILOT olmalıdır.
- required test item'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_item_count gerçek item sayısıyla eşleşmelidir.
- ready_item_count gerçek READY sayısıyla eşleşmelidir.
- missing_item_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- approval_inbox_status = PASS olmalıdır.
- workflow_monitor_status = PASS olmalıdır.
- realtime_health_status = PASS olmalıdır.
- tenant_scope = SINGLE_TENANT olmalıdır.
- approval_web_checkpoint_status = PASS olmalıdır.
- workflow_web_checkpoint_status = PASS olmalıdır.
- realtime_web_checkpoint_status = PASS olmalıdır.
- no_workflow_mutation = true olmalıdır.
- no_real_approval_execution = true olmalıdır.
- no_real_workflow_execution = true olmalıdır.
- no_live_websocket_connection = true olmalıdır.
- no_live_sse_connection = true olmalıdır.
- no_event_stream_publish = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Workflow / realtime UI test dokümanı vardır.
- Master config artifact vardır.
- UI test artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid UI test fixture PASS döner.
- Invalid UI test fixture FAIL döner.
- Approval Inbox HTML marker doğrulanır.
- Workflow Monitor HTML marker doğrulanır.
- Realtime Health HTML marker doğrulanır.
- Cross dependency guard doğrulanır.
- Tenant scope guard doğrulanır.
- No mutation / no live socket / no event publish guard doğrulanır.
- Closed policy marker doğrulanır.
- FAZ_4_17_3_READY=YES üretilir.
