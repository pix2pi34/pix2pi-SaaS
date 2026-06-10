# 241 — FAZ 4-17.4 Canlı Bildirim Merkezi

## Amaç

240 Realtime Event Feed PASS olduktan sonra WEB-L7 Workflow / Realtime UI bloğunun son yüzeyi olan canlı bildirim merkezi standardını kurar.

Bu adım gerçek push notification, email, SMS, WebSocket veya SSE teslimatı yapmaz. Sadece controlled pilot için tenant-scoped notification center modelini, UI checkpoint artifact'ini, bildirim listesi görünümünü, okunma durumu placeholder'ını, unread counter modelini, kanal/severity rozetlerini ve no-live-delivery guard'larını üretir.

## Kapsam

- Notification center shell
- Tenant scoped notification center
- Notification list
- Notification metadata model
- Unread counter model
- Read state placeholder
- Severity badge model
- Channel badge model
- Delivery preference placeholder
- Event feed link
- Workflow monitor link
- Realtime health link
- Filter / sort model
- Empty state
- Error state
- No push delivery guard
- No email / SMS delivery guard
- No live socket guard
- External policy closed gate
- UI checkpoint HTML
- Final notification center readiness report

## Ana Kural

Bu adım gerçek push bildirimi göndermez.

Bu adım gerçek email/SMS göndermez.

Bu adım gerçek WebSocket/SSE bağlantısı açmaz.

Bu adım event stream subscribe/publish yapmaz.

Bu adım bildirim okunma state'ini gerçek runtime üzerinde değiştirmez.

Bu adım production launch yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Canlı bildirim merkezi PASS sayılırsa:

- notification_center_status = READY olmalıdır.
- notification_center_mode = CONTROLLED_PILOT olmalıdır.
- required notification item'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_item_count gerçek item sayısıyla eşleşmelidir.
- ready_item_count gerçek READY sayısıyla eşleşmelidir.
- missing_item_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- tenant_scope = SINGLE_TENANT olmalıdır.
- realtime_event_feed_status = PASS olmalıdır.
- notification_list_status = READY olmalıdır.
- unread_counter_status = READY olmalıdır.
- read_state_placeholder_status = READY olmalıdır.
- severity_badge_status = READY olmalıdır.
- channel_badge_status = READY olmalıdır.
- web_checkpoint_status = READY olmalıdır.
- no_push_delivery = true olmalıdır.
- no_email_delivery = true olmalıdır.
- no_sms_delivery = true olmalıdır.
- no_live_websocket_connection = true olmalıdır.
- no_live_sse_connection = true olmalıdır.
- no_event_stream_subscribe = true olmalıdır.
- no_event_stream_publish = true olmalıdır.
- no_notification_mutation = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Canlı Bildirim Merkezi dokümanı vardır.
- Master config artifact vardır.
- Notification center artifact vardır.
- UI checkpoint HTML vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid notification fixture PASS döner.
- Invalid notification fixture FAIL döner.
- Required item guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Tenant scope guard doğrulanır.
- Notification list/unread/read-state/severity/channel guard doğrulanır.
- No push/email/SMS/socket/event/mutation guard doğrulanır.
- UI checkpoint marker doğrulanır.
- Closed policy marker doğrulanır.
- WEB_L7_WORKFLOW_REALTIME_UI_COMPLETE=YES üretilir.
