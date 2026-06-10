# 238 — FAZ 4-17.5 WebSocket / SSE Bağlantı Sağlığı Görünümü

## Amaç

237 Workflow Monitor PASS olduktan sonra WEB-L7 Workflow / Realtime UI bloğunda realtime bağlantı sağlığı görünümünü kurar.

Bu adım gerçek WebSocket veya SSE bağlantısı açmaz. Sadece controlled pilot için bağlantı sağlığı modelini, UI checkpoint artifact'ini, bağlantı durumu rozetlerini, heartbeat/latency/reconnect göstergelerini, tenant-safe görünüm kurallarını ve no-live-connection guard'larını üretir.

## Kapsam

- Realtime health shell
- Tenant scoped realtime health
- WebSocket health placeholder
- SSE health placeholder
- Connection status badge model
- Heartbeat age indicator
- Last event id placeholder
- Reconnect attempt counter
- Latency indicator
- Subscription channel list
- Workflow monitor link
- Event feed placeholder
- Notification center placeholder
- Empty state
- Error state
- No live socket guard
- No live SSE guard
- External policy closed gate
- UI checkpoint HTML
- Final realtime health readiness report

## Ana Kural

Bu adım gerçek WebSocket bağlantısı açmaz.

Bu adım gerçek SSE bağlantısı açmaz.

Bu adım event stream subscribe/publish yapmaz.

Bu adım production launch yapmaz.

Bu adım canlı provider, GIB, banka, POS, ödeme sağlayıcı, DNS, Nginx veya SSL değişikliği yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Realtime connection health PASS sayılırsa:

- realtime_health_status = READY olmalıdır.
- realtime_health_mode = CONTROLLED_PILOT olmalıdır.
- required health item'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_item_count gerçek item sayısıyla eşleşmelidir.
- ready_item_count gerçek READY sayısıyla eşleşmelidir.
- missing_item_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- tenant_scope = SINGLE_TENANT olmalıdır.
- workflow_monitor_status = PASS olmalıdır.
- websocket_health_status = READY olmalıdır.
- sse_health_status = READY olmalıdır.
- connection_status_badge_status = READY olmalıdır.
- heartbeat_indicator_status = READY olmalıdır.
- reconnect_indicator_status = READY olmalıdır.
- latency_indicator_status = READY olmalıdır.
- web_checkpoint_status = READY olmalıdır.
- no_live_websocket_connection = true olmalıdır.
- no_live_sse_connection = true olmalıdır.
- no_event_stream_publish = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- WebSocket / SSE bağlantı sağlığı dokümanı vardır.
- Master config artifact vardır.
- Realtime health artifact vardır.
- UI checkpoint HTML vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid health fixture PASS döner.
- Invalid health fixture FAIL döner.
- Required item guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Tenant scope guard doğrulanır.
- WebSocket/SSE/heartbeat/reconnect/latency guard doğrulanır.
- No live socket / no live SSE / no event stream publish guard doğrulanır.
- UI checkpoint marker doğrulanır.
- Closed policy marker doğrulanır.
- FAZ_4_17_6_READY=YES üretilir.
