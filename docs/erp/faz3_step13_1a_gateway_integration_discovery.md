# FAZ 3 / STEP 13.1A — Gateway Integration Discovery Raporu

Tarih: 20260426_193621

## Amaç

STEP 13 gerçek gateway entegrasyonu öncesinde mevcut gateway/router yapısını keşfetmek ve ERP Runtime API mount hazırlığını doğrulamak.

## Mevcut ERP Runtime Endpoint

POST /api/v1/erp/runtime/flows

## Hazır Contract Dosyaları

- internal/erp/runtime/apisurface/http_handler.go ✅
- internal/erp/runtime/apisurface/route_manifest.go ✅
- internal/erp/runtime/apisurface/route_binding.go ✅
- internal/erp/runtime/apisurface/gateway_mount_plan.go ✅
- internal/erp/runtime/apisurface/gateway_mount_binding.go ✅

## Doğrulanan Testler

- Gateway mount readiness testleri: PASS ✅
- Mount binding mux smoke: PASS ✅
- API → E2E → DB quick smoke: PASS ✅

## Gateway Aday Dosyaları

```text
cmd/api-gateway/api_gateway_main.go
cmd/api-gateway/gateway_config_security_test.go
cmd/api-gateway/gateway_middleware.go
cmd/api-gateway/api_gateway_main_test.go
cmd/api-gateway/gateway_routes.go
cmd/api-gateway/gateway_routes_test.go
cmd/api-gateway/gateway_s2s_policy_test.go
cmd/api-gateway/user_detail_route.go
cmd/api-gateway/gateway_config.go
cmd/api-gateway/gateway_entry_contract_test.go
internal/erp/runtime/apisurface/http_handler.go
internal/erp/runtime/apisurface/http_handler_test.go
internal/erp/runtime/apisurface/route_manifest.go
internal/erp/runtime/apisurface/gateway_mount_plan_test.go
internal/erp/runtime/apisurface/gateway_mount_plan.go
internal/erp/runtime/apisurface/gateway_mount_binding.go
internal/erp/runtime/apisurface/gateway_mount_binding_mux_smoke_test.go
internal/erp/runtime/apisurface/route_binding_test.go
internal/erp/runtime/apisurface/e2e_http_smoke_integration_test.go
internal/erp/runtime/apisurface/route_binding_mux_smoke_test.go
internal/erp/runtime/apisurface/route_binding.go
internal/erp/runtime/apisurface/gateway_mount_binding_test.go
internal/erp/runtime/apisurface/route_manifest_test.go
internal/erp/core/kasa/domain/erp_kasa_ekstre.go
internal/erp/core/kasa/domain/erp_kasa_hareket.go
internal/erp/core/kasa/domain/erp_kasa_hesap.go
internal/erp/core/eventstore/domain/erp_accounting_event.go
internal/erp/core/cari/domain/erp_cari_hesap.go
internal/erp/core/cari/domain/erp_cari_hareket.go
internal/erp/core/cari/domain/erp_cari_ekstre.go
internal/erp/core/journal/domain/erp_journal_entry.go
internal/erp/core/finance/domain/erp_commission_result.go
internal/erp/core/finance/domain/erp_commission_rule.go
internal/erp/core/ledger/domain/erp_wallet_transfer.go
internal/erp/core/ledger/domain/erp_ledger_posting.go
internal/erp/core/ledger/domain/erp_multi_ledger_account.go
internal/erp/core/events/domain/erp_financial_event_record.go
internal/erp/core/stok/domain/erp_stok_hareket.go
internal/erp/core/stok/domain/erp_urun_kart.go
internal/erp/core/rules/domain/erp_accounting_rule.go
internal/erp/core/tahsilat/domain/erp_odeme.go
internal/erp/core/tahsilat/domain/erp_tahsilat.go
internal/erp/core/kernel/ufk/domain/erp_journal_entry.go
internal/erp/core/kernel/ufk/domain/erp_journal_line.go
internal/erp/core/kernel/ufk/domain/erp_account.go
internal/erp/core/kernel/ufk/domain/erp_financial_event.go
internal/erp/core/kernel/ufk/domain/erp_ledger_account.go
internal/erp/core/rapor/domain/erp_mizan_satir.go
internal/erp/core/rapor/domain/erp_gelir_tablosu.go
internal/erp/core/rapor/domain/erp_bilanco.go
internal/erp/core/ufk/domain/erp_ledger_account.go
internal/erp/core/payments/domain/erp_settlement_batch.go
internal/erp/core/payments/domain/erp_merchant_payout.go
internal/erp/core/vergi/domain/erp_vergi_kural.go
internal/erp/core/banka/domain/erp_banka_ekstre.go
internal/erp/core/banka/domain/erp_banka_hesap.go
internal/erp/core/banka/domain/erp_banka_hareket.go
internal/erp/core/alis/domain/erp_alis_fatura.go
internal/erp/core/alis/domain/erp_alis_fatura_satir.go
internal/erp/core/satis/domain/erp_satis_fatura.go
internal/erp/core/satis/domain/erp_satis_fatura_satir.go
internal/finance/domain/account.go
internal/services/query_read_model/routes.go
internal/identity/transport/http/handler/whoami.go
internal/identity/transport/http/routes.go
internal/identity/domain/user.go
internal/identity/domain/tenant.go
internal/platform/auth/domain/jwt_claim_contract.go
internal/platform/auth/domain/jwt_claims.go
internal/platform/auth/domain/jwt_claim_contract_test.go
internal/platform/eventstore/domain/event_store_record.go
internal/platform/eventstore/domain/event_store_record_test.go
internal/platform/eventschema/domain/event_schema.go
internal/platform/reporting/domain/report_record.go
internal/platform/plugins/http_handler.go
internal/platform/tenant/domain/tenant.go
internal/platform/gateway/service/quota_service.go
internal/platform/gateway/service/rate_limit_service.go
internal/platform/gateway/domain/rate_limit_record.go
internal/platform/gateway/domain/quota_record.go
internal/platform/export/domain/export_record.go
internal/platform/audit/domain/audit_log.go
internal/platform/audit/domain/audit_log_test.go
internal/platform/dbrouter/router.go
internal/platform/dbrouter/router_test.go
internal/platform/readmodel/domain/ledger_read_model.go
internal/platform/publicapi/gateway_store_test.go
internal/platform/publicapi/gateway_store.go
internal/platform/publicapi/gateway_service_test.go
internal/platform/publicapi/gateway_contract.go
internal/platform/publicapi/gateway_service.go
internal/platform/kernel/from_fiber.go
internal/platform/backup/domain/backup_record.go
internal/platform/missioncontrol/maintenance_action_store_test.go
internal/platform/missioncontrol/maintenance_action_service_test.go
internal/platform/missioncontrol/maintenance_action_contract.go
internal/platform/missioncontrol/maintenance_action_store.go
internal/platform/missioncontrol/maintenance_action_service.go
internal/platform/eventbus/domain/event_message_test.go
internal/platform/eventbus/domain/event_message.go
internal/ufk/domain/ledger_account.go
internal/ufk/domain/journal_line.go
internal/ufk/domain/ledger_snapshot.go
```

## Route / Server String Hitleri

```text
cmd/service-discovery/service_discovery_main.go:163:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
cmd/service-discovery/service_discovery_main.go:173:	http.HandleFunc("/register", func(w http.ResponseWriter, r *http.Request) {
cmd/service-discovery/service_discovery_main.go:203:	http.HandleFunc("/heartbeat", func(w http.ResponseWriter, r *http.Request) {
cmd/service-discovery/service_discovery_main.go:236:	http.HandleFunc("/services", func(w http.ResponseWriter, r *http.Request) {
cmd/service-discovery/service_discovery_main.go:245:	log.Fatal(http.ListenAndServe(addr, nil))
cmd/realtime-runtime/realtime_runtime_main.go:394:	app.Get("/health", func(c *fiber.Ctx) error {
cmd/realtime-runtime/realtime_runtime_main.go:424:	app.Get("/api/realtime/summary", func(c *fiber.Ctx) error {
cmd/realtime-runtime/realtime_runtime_main.go:430:	app.Get("/api/realtime/tables", func(c *fiber.Ctx) error {
cmd/realtime-runtime/realtime_runtime_main.go:436:	app.Get("/api/realtime/channels", func(c *fiber.Ctx) error {
cmd/realtime-runtime/realtime_runtime_main.go:444:	app.Get("/api/realtime/connections", func(c *fiber.Ctx) error {
cmd/realtime-runtime/realtime_runtime_main.go:452:	app.Get("/api/realtime/presence", func(c *fiber.Ctx) error {
cmd/realtime-runtime/realtime_runtime_main.go:460:	app.Get("/api/realtime/permissions", func(c *fiber.Ctx) error {
cmd/realtime-runtime/realtime_runtime_main.go:478:	app := fiber.New()
cmd/cache-service/cache_service_main.go:68:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
cmd/cache-service/cache_service_main.go:85:	http.HandleFunc("/cache/set", func(w http.ResponseWriter, r *http.Request) {
cmd/cache-service/cache_service_main.go:142:	http.HandleFunc("/cache/get", func(w http.ResponseWriter, r *http.Request) {
cmd/cache-service/cache_service_main.go:192:	http.HandleFunc("/cache/delete", func(w http.ResponseWriter, r *http.Request) {
cmd/cache-service/cache_service_main.go:236:	err := http.ListenAndServe(":"+port, nil)
cmd/incident-audit-runtime/incident_audit_runtime_main.go:182:	app.Get("/health", func(c *fiber.Ctx) error {
cmd/incident-audit-runtime/incident_audit_runtime_main.go:209:	app.Get("/api/incident-audit/summary", func(c *fiber.Ctx) error {
cmd/incident-audit-runtime/incident_audit_runtime_main.go:258:	app.Get("/api/incident-audit/incidents", func(c *fiber.Ctx) error {
cmd/incident-audit-runtime/incident_audit_runtime_main.go:342:	app.Get("/api/incident-audit/audit-events", func(c *fiber.Ctx) error {
cmd/incident-audit-runtime/incident_audit_runtime_main.go:396:	app.Get("/api/incident-audit/audit-logs", func(c *fiber.Ctx) error {
cmd/incident-audit-runtime/incident_audit_runtime_main.go:452:	app.Get("/api/incident-audit/timeline", func(c *fiber.Ctx) error {
cmd/incident-audit-runtime/incident_audit_runtime_main.go:543:	app := fiber.New()
cmd/control-panel/control_panel.go:131:	app := fiber.New()
cmd/control-panel/control_panel.go:133:	app.Get("/health", func(c *fiber.Ctx) error {
cmd/control-panel/control_panel.go:180:	app.Get("/*", func(c *fiber.Ctx) error {
cmd/identity-api/dev_token.go:23:	app := fiber.New()
cmd/identity-api/dev_token.go:25:	app.Get("/dev/token", func(c *fiber.Ctx) error {
cmd/identity-api/identity_api_main.go:33:	http.HandleFunc("/register", registerHandler)
cmd/identity-api/identity_api_main.go:35:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
cmd/identity-api/identity_api_main.go:44:	err = http.ListenAndServe(":9012", nil)
cmd/early-warning-runtime/early_warning_runtime_main.go:557:	app.Get("/health", func(c *fiber.Ctx) error {
cmd/early-warning-runtime/early_warning_runtime_main.go:587:	app.Get("/api/early-warning/services", func(c *fiber.Ctx) error {
cmd/early-warning-runtime/early_warning_runtime_main.go:593:	app.Get("/api/early-warning/resources", func(c *fiber.Ctx) error {
cmd/early-warning-runtime/early_warning_runtime_main.go:599:	app.Get("/api/early-warning/signals", func(c *fiber.Ctx) error {
cmd/early-warning-runtime/early_warning_runtime_main.go:615:	app.Get("/api/early-warning/summary", func(c *fiber.Ctx) error {
cmd/early-warning-runtime/early_warning_runtime_main.go:626:	app.Get("/api/early-warning/incidents", func(c *fiber.Ctx) error {
cmd/early-warning-runtime/early_warning_runtime_main.go:660:	app := fiber.New()
cmd/runtime-topology/runtime_topology_main.go:392:	app.Get("/health", func(c *fiber.Ctx) error {
cmd/runtime-topology/runtime_topology_main.go:422:	app.Get("/api/runtime-topology/nodes", func(c *fiber.Ctx) error {
cmd/runtime-topology/runtime_topology_main.go:433:	app.Get("/api/runtime-topology/edges", func(c *fiber.Ctx) error {
cmd/runtime-topology/runtime_topology_main.go:437:	app.Get("/api/runtime-topology/summary", func(c *fiber.Ctx) error {
cmd/runtime-topology/runtime_topology_main.go:444:	app.Get("/api/runtime-topology/registry", func(c *fiber.Ctx) error {
cmd/runtime-topology/runtime_topology_main.go:458:	app := fiber.New()
cmd/mission-control/mission_control_main.go:37:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
cmd/mission-control/mission_control_main.go:44:	http.HandleFunc("/api/services", func(w http.ResponseWriter, r *http.Request) {
cmd/mission-control/mission_control_main.go:63:	_ = http.ListenAndServe(":"+missionPort, nil)
cmd/jobs-runtime/jobs_runtime_main.go:141:	app.Get("/health", func(c *fiber.Ctx) error {
cmd/jobs-runtime/jobs_runtime_main.go:168:	app.Get("/api/jobs/summary", func(c *fiber.Ctx) error {
cmd/jobs-runtime/jobs_runtime_main.go:230:	app.Get("/api/jobs/queues", func(c *fiber.Ctx) error {
cmd/jobs-runtime/jobs_runtime_main.go:300:	app.Get("/api/jobs/recent", func(c *fiber.Ctx) error {
cmd/jobs-runtime/jobs_runtime_main.go:384:	app := fiber.New()
cmd/auth-api/auth_api_main.go:25:	http.HandleFunc("/health", healthHandler)
cmd/auth-api/auth_api_main.go:31:	err := http.ListenAndServe(":"+port, nil)
cmd/workflow-runtime/workflow_runtime_main.go:155:	app.Get("/health", func(c *fiber.Ctx) error {
cmd/workflow-runtime/workflow_runtime_main.go:182:	app.Get("/api/workflows/summary", func(c *fiber.Ctx) error {
cmd/workflow-runtime/workflow_runtime_main.go:239:	app.Get("/api/workflows/definitions", func(c *fiber.Ctx) error {
cmd/workflow-runtime/workflow_runtime_main.go:278:	app.Get("/api/workflows/instances", func(c *fiber.Ctx) error {
cmd/workflow-runtime/workflow_runtime_main.go:327:	app.Get("/api/workflows/steps", func(c *fiber.Ctx) error {
cmd/workflow-runtime/workflow_runtime_main.go:376:	app.Get("/api/workflows/approvals", func(c *fiber.Ctx) error {
cmd/workflow-runtime/workflow_runtime_main.go:435:	app := fiber.New()
cmd/plugin-erp/plugin_erp_main.go:12:	http.HandleFunc("/health", handler.HealthHandler)
cmd/plugin-erp/plugin_erp_main.go:13:	http.HandleFunc("/plugin/info", handler.InfoHandler)
cmd/plugin-erp/plugin_erp_main.go:17:	log.Fatal(http.ListenAndServe(":9002", nil))
cmd/webhook-runtime/webhook_runtime_main.go:157:	app.Get("/health", func(c *fiber.Ctx) error {
cmd/webhook-runtime/webhook_runtime_main.go:184:	app.Get("/api/webhooks/summary", func(c *fiber.Ctx) error {
cmd/webhook-runtime/webhook_runtime_main.go:248:	app.Get("/api/webhooks/endpoints", func(c *fiber.Ctx) error {
cmd/webhook-runtime/webhook_runtime_main.go:327:	app.Get("/api/webhooks/deliveries", func(c *fiber.Ctx) error {
cmd/webhook-runtime/webhook_runtime_main.go:413:	app.Get("/api/webhooks/dlq", func(c *fiber.Ctx) error {
cmd/webhook-runtime/webhook_runtime_main.go:510:	app := fiber.New()
cmd/notification-runtime/notification_runtime_main.go:150:	app.Get("/health", func(c *fiber.Ctx) error {
cmd/notification-runtime/notification_runtime_main.go:177:	app.Get("/api/notifications/summary", func(c *fiber.Ctx) error {
cmd/notification-runtime/notification_runtime_main.go:257:	app.Get("/api/notifications/channels", func(c *fiber.Ctx) error {
cmd/notification-runtime/notification_runtime_main.go:311:	app.Get("/api/notifications/items", func(c *fiber.Ctx) error {
cmd/notification-runtime/notification_runtime_main.go:380:	app.Get("/api/notifications/recipients", func(c *fiber.Ctx) error {
cmd/notification-runtime/notification_runtime_main.go:441:	app.Get("/api/notifications/dlq", func(c *fiber.Ctx) error {
cmd/notification-runtime/notification_runtime_main.go:513:	app := fiber.New()
cmd/publicapi-runtime/publicapi_runtime_main.go:169:	app.Get("/health", func(c *fiber.Ctx) error {
cmd/publicapi-runtime/publicapi_runtime_main.go:196:	app.Get("/api/publicapi/summary", func(c *fiber.Ctx) error {
cmd/publicapi-runtime/publicapi_runtime_main.go:276:	app.Get("/api/publicapi/api-keys", func(c *fiber.Ctx) error {
cmd/publicapi-runtime/publicapi_runtime_main.go:341:	app.Get("/api/publicapi/quota-policies", func(c *fiber.Ctx) error {
cmd/publicapi-runtime/publicapi_runtime_main.go:405:	app.Get("/api/publicapi/usage", func(c *fiber.Ctx) error {
cmd/publicapi-runtime/publicapi_runtime_main.go:486:	app := fiber.New()
cmd/replay-service/replay_service_main.go:23:	http.HandleFunc("/replay", func(w http.ResponseWriter, r *http.Request) {
cmd/replay-service/replay_service_main.go:46:	http.ListenAndServe(":9012", nil)
cmd/service-registry/service_registry_main.go:24:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
cmd/service-registry/service_registry_main.go:28:	http.HandleFunc("/services", func(w http.ResponseWriter, r *http.Request) {
cmd/service-registry/service_registry_main.go:32:	http.HandleFunc("/register", func(w http.ResponseWriter, r *http.Request) {
cmd/service-registry/service_registry_main.go:51:	http.ListenAndServe(":"+port, nil)
cmd/service-watchdog/service_watchdog_main.go:74:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
cmd/service-watchdog/service_watchdog_main.go:80:	http.HandleFunc("/status", func(w http.ResponseWriter, r *http.Request) {
cmd/service-watchdog/service_watchdog_main.go:91:	_ = http.ListenAndServe("127.0.0.1:"+port, nil)
cmd/api-gateway/api_gateway_main.go:526:	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:530:	mux.HandleFunc("/health/live", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:540:	mux.HandleFunc("/health/ready", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:566:	mux.HandleFunc("/health/db", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:585:	mux.HandleFunc("/health/replica", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:606:	mux.HandleFunc("/health/gateway-policy", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:619:	mux.HandleFunc("/health/upstreams", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:636:	mux.HandleFunc("/health/aggregate", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:665:	mux.HandleFunc("/health/routes", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:681:	mux.HandleFunc("/api/me", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:691:	mux.HandleFunc("/api/query/users", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:716:	mux.HandleFunc("/api/query/users/list", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:782:	mux.HandleFunc("/api/query/users/", func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/api_gateway_main.go:838:	rootMux := http.NewServeMux()
cmd/api-gateway/api_gateway_main.go:843:	protectedMux := http.NewServeMux()
cmd/api-gateway/api_gateway_main.go:903:	rootMux.Handle("/api/", protectedHandler)
cmd/api-gateway/api_gateway_main.go:1005:	err := http.ListenAndServe(listenAddr, handler)
cmd/api-gateway/gateway_routes.go:168:	mux.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
cmd/api-gateway/gateway_s2s_policy_test.go:64:	mux := http.NewServeMux()
cmd/api-gateway/gateway_s2s_policy_test.go:102:	mux := http.NewServeMux()
cmd/api-gateway/gateway_s2s_policy_test.go:183:	mux := http.NewServeMux()
cmd/api-gateway/user_detail_route.go:5:// duplicate http.HandleFunc panic'ini engellemek icin pasife alindi.
cmd/api-gateway/gateway_entry_contract_test.go:24:	mux := http.NewServeMux()
cmd/api-gateway/gateway_entry_contract_test.go:118:	mux := http.NewServeMux()
cmd/plugin-registry-http-test/plugin_registry_http_test_main.go:22:	http.HandleFunc("/registry/plugins", plugins.RegistryHandler(reg))
cmd/plugin-registry-http-test/plugin_registry_http_test_main.go:26:	http.ListenAndServe(":7070", nil)
cmd/plugin-runtime/plugin_runtime_main.go:141:	app.Get("/health", func(c *fiber.Ctx) error {
cmd/plugin-runtime/plugin_runtime_main.go:168:	app.Get("/api/plugins/summary", func(c *fiber.Ctx) error {
cmd/plugin-runtime/plugin_runtime_main.go:232:	app.Get("/api/plugins/catalog", func(c *fiber.Ctx) error {
cmd/plugin-runtime/plugin_runtime_main.go:316:	app.Get("/api/plugins/states", func(c *fiber.Ctx) error {
cmd/plugin-runtime/plugin_runtime_main.go:393:	app.Get("/api/plugins/runtime", func(c *fiber.Ctx) error {
cmd/plugin-runtime/plugin_runtime_main.go:480:	app := fiber.New()
cmd/query-read-model/query_read_model_main.go:147:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
cmd/query-read-model/query_read_model_main.go:156:	http.HandleFunc("/seed", func(w http.ResponseWriter, r *http.Request) {
cmd/query-read-model/query_read_model_main.go:192:	http.HandleFunc("/upsert/sale", func(w http.ResponseWriter, r *http.Request) {
cmd/query-read-model/query_read_model_main.go:222:	http.HandleFunc("/sales", func(w http.ResponseWriter, r *http.Request) {
cmd/query-read-model/query_read_model_main.go:232:	http.HandleFunc("/sales/get", func(w http.ResponseWriter, r *http.Request) {
cmd/query-read-model/query_read_model_main.go:250:	log.Fatal(http.ListenAndServe(addr, nil))
internal/erp/runtime/apisurface/gateway_mount_binding.go:31:func MountRuntimeFlowGatewayRoutes(registrar RuntimeFlowRouteRegistrar, service RuntimeFlowAPIService) (RuntimeFlowGatewayMountBinding, error) {
internal/erp/runtime/apisurface/gateway_mount_binding.go:50:		if err := registrar.RegisterRoute(routeBinding.Manifest.Method, routeBinding.Manifest.Path, routeBinding.Handler); err != nil {
internal/erp/runtime/apisurface/gateway_mount_binding_mux_smoke_test.go:17:		mux: http.NewServeMux(),
internal/erp/runtime/apisurface/gateway_mount_binding_mux_smoke_test.go:21:func (r *gatewayMountMuxRegistrar) RegisterRoute(method string, path string, handler http.Handler) error {
internal/erp/runtime/apisurface/gateway_mount_binding_mux_smoke_test.go:23:		r.mux = http.NewServeMux()
internal/erp/runtime/apisurface/gateway_mount_binding_mux_smoke_test.go:26:	r.mux.Handle(path, handler)
internal/erp/runtime/apisurface/gateway_mount_binding_mux_smoke_test.go:34:	binding, err := MountRuntimeFlowGatewayRoutes(registrar, service)
internal/erp/runtime/apisurface/gateway_mount_binding_mux_smoke_test.go:84:	_, err := MountRuntimeFlowGatewayRoutes(registrar, service)
internal/erp/runtime/apisurface/gateway_mount_binding_mux_smoke_test.go:116:	_, err := MountRuntimeFlowGatewayRoutes(registrar, service)
internal/erp/runtime/apisurface/gateway_mount_binding_mux_smoke_test.go:138:	_, err := MountRuntimeFlowGatewayRoutes(registrar, nil)
internal/erp/runtime/apisurface/route_binding_test.go:18:func (r *fakeRuntimeFlowRouteRegistrar) RegisterRoute(method string, path string, handler http.Handler) error {
internal/erp/runtime/apisurface/route_binding_test.go:63:func TestBindRuntimeFlowRoutesSuccess(t *testing.T) {
internal/erp/runtime/apisurface/route_binding_test.go:67:	bindings, err := BindRuntimeFlowRoutes(registrar, service)
internal/erp/runtime/apisurface/route_binding_test.go:93:func TestBindRuntimeFlowRoutesRegistrarRequired(t *testing.T) {
internal/erp/runtime/apisurface/route_binding_test.go:96:	_, err := BindRuntimeFlowRoutes(nil, service)
internal/erp/runtime/apisurface/route_binding_test.go:102:func TestBindRuntimeFlowRoutesServiceRequired(t *testing.T) {
internal/erp/runtime/apisurface/route_binding_test.go:105:	_, err := BindRuntimeFlowRoutes(registrar, nil)
internal/erp/runtime/apisurface/route_binding_test.go:115:func TestBindRuntimeFlowRoutesRegistrationFailed(t *testing.T) {
internal/erp/runtime/apisurface/route_binding_test.go:121:	_, err := BindRuntimeFlowRoutes(registrar, service)
internal/erp/runtime/apisurface/route_binding_mux_smoke_test.go:17:		mux: http.NewServeMux(),
internal/erp/runtime/apisurface/route_binding_mux_smoke_test.go:21:func (r *muxRuntimeFlowRouteRegistrar) RegisterRoute(method string, path string, handler http.Handler) error {
internal/erp/runtime/apisurface/route_binding_mux_smoke_test.go:23:		r.mux = http.NewServeMux()
internal/erp/runtime/apisurface/route_binding_mux_smoke_test.go:26:	r.mux.Handle(path, handler)
internal/erp/runtime/apisurface/route_binding_mux_smoke_test.go:34:	bindings, err := BindRuntimeFlowRoutes(registrar, service)
internal/erp/runtime/apisurface/route_binding_mux_smoke_test.go:80:	_, err := BindRuntimeFlowRoutes(registrar, service)
internal/erp/runtime/apisurface/route_binding_mux_smoke_test.go:112:	_, err := BindRuntimeFlowRoutes(registrar, service)
internal/erp/runtime/apisurface/route_binding.go:8:	RegisterRoute(method string, path string, handler http.Handler) error
internal/erp/runtime/apisurface/route_binding.go:33:func BindRuntimeFlowRoutes(registrar RuntimeFlowRouteRegistrar, service RuntimeFlowAPIService) ([]RuntimeFlowRouteBinding, error) {
internal/erp/runtime/apisurface/route_binding.go:47:	if err := registrar.RegisterRoute(binding.Manifest.Method, binding.Manifest.Path, binding.Handler); err != nil {
internal/erp/runtime/apisurface/gateway_mount_binding_test.go:18:func (r *fakeRuntimeFlowGatewayMountRegistrar) RegisterRoute(method string, path string, handler http.Handler) error {
internal/erp/runtime/apisurface/gateway_mount_binding_test.go:71:func TestMountRuntimeFlowGatewayRoutesSuccess(t *testing.T) {
internal/erp/runtime/apisurface/gateway_mount_binding_test.go:75:	binding, err := MountRuntimeFlowGatewayRoutes(registrar, service)
internal/erp/runtime/apisurface/gateway_mount_binding_test.go:105:func TestMountRuntimeFlowGatewayRoutesRegistrarRequired(t *testing.T) {
internal/erp/runtime/apisurface/gateway_mount_binding_test.go:108:	_, err := MountRuntimeFlowGatewayRoutes(nil, service)
internal/erp/runtime/apisurface/gateway_mount_binding_test.go:114:func TestMountRuntimeFlowGatewayRoutesServiceRequired(t *testing.T) {
internal/erp/runtime/apisurface/gateway_mount_binding_test.go:117:	_, err := MountRuntimeFlowGatewayRoutes(registrar, nil)
internal/erp/runtime/apisurface/gateway_mount_binding_test.go:127:func TestMountRuntimeFlowGatewayRoutesRegistrationFailed(t *testing.T) {
internal/erp/runtime/apisurface/gateway_mount_binding_test.go:133:	_, err := MountRuntimeFlowGatewayRoutes(registrar, service)
internal/services/query_read_model/routes.go:9:	app.Get("/api/query/users", func(c *fiber.Ctx) error {
internal/identity/transport/http/routes.go:10:func RegisterRoutes(app *fiber.App) {
internal/identity/transport/http/routes.go:13:	app.Get("/health", func(c *fiber.Ctx) error {
internal/identity/transport/http/routes.go:34:	app.Get("/dev/token", func(c *fiber.Ctx) error {
internal/platform/monitor/monitor_test.go:47:	mux := http.NewServeMux()
internal/platform/monitor/monitor_test.go:48:	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
internal/platform/monitor/monitor_test.go:59:		_ = srv.ListenAndServe()
internal/platform/readmodel/subscriber_pipeline_test.go:119:	result, err := pipeline.Handle(context.Background(), sampleEvent())
internal/platform/readmodel/subscriber_pipeline_test.go:156:	result, err := pipeline.Handle(context.Background(), sampleEvent())
internal/platform/readmodel/subscriber_pipeline_test.go:178:	_, err = pipeline.Handle(context.Background(), sampleEvent())
internal/platform/readmodel/subscriber_pipeline_test.go:200:	result, err := pipeline.Handle(context.Background(), sampleEvent())
internal/platform/readmodel/subscriber_pipeline.go:234:func (p *SubscriberPipeline) Handle(ctx context.Context, event ReadModelEvent) (SubscriberHandleResult, error) {
internal/platform/serviceregistry/heartbeat_handler_test.go:24:	app := fiber.New()
internal/platform/serviceregistry/heartbeat_handler_test.go:61:	app := fiber.New()
internal/platform/serviceregistry/heartbeat_handler_test.go:82:	app := fiber.New()
internal/platform/serviceregistry/heartbeat_handler_test.go:113:	app := fiber.New()
internal/platform/serviceregistry/register_handler.go:62:func RegisterRoutes(app fiber.Router, handler *RegisterHandler) {
internal/platform/serviceregistry/register_handler.go:63:	app.Post("/internal/runtime/services/register", handler.Register)
internal/platform/serviceregistry/heartbeat_handler.go:19:func (h *HeartbeatHandler) Handle(c *fiber.Ctx) error {
internal/platform/serviceregistry/heartbeat_handler.go:59:	app.Post("/internal/runtime/services/heartbeat", handler.Handle)
internal/platform/serviceregistry/register_handler_test.go:24:	app := fiber.New()
internal/platform/serviceregistry/register_handler_test.go:37:	RegisterRoutes(app, handler)
internal/platform/serviceregistry/register_handler_test.go:71:	app := fiber.New()
internal/platform/serviceregistry/register_handler_test.go:76:	RegisterRoutes(app, handler)
internal/platform/serviceregistry/register_handler_test.go:92:	app := fiber.New()
internal/platform/serviceregistry/register_handler_test.go:97:	RegisterRoutes(app, handler)
internal/platform/serviceregistry/register_handler_test.go:131:	app := fiber.New()
internal/platform/serviceregistry/register_handler_test.go:139:	RegisterRoutes(app, handler)
internal/platform/kernel/tenant_guard_test.go:13:	app := fiber.New()
internal/platform/kernel/tenant_guard_test.go:15:	app.Use(func(c *fiber.Ctx) error {
internal/platform/kernel/tenant_guard_test.go:28:	app.Use(TenantGuardMiddleware())
internal/platform/kernel/tenant_guard_test.go:30:	app.Get("/health", func(c *fiber.Ctx) error {
internal/platform/kernel/tenant_guard_test.go:34:	app.Get("/orders", func(c *fiber.Ctx) error {
internal/platform/kernel/permissions.go:166:		return fiber.NewError(fiber.StatusUnauthorized, "missing tenant")
internal/platform/kernel/permissions.go:171:		return fiber.NewError(fiber.StatusForbidden, "missing role")
internal/platform/kernel/permissions.go:184:			return fiber.NewError(fiber.StatusForbidden, "permission denied")
internal/platform/kernel/require.go:10:// Example: app.Get("/whoami", kernel.Require("identity.whoami"), handler)
```

## Entegrasyon Kararı

STEP 13.1A başarıyla tamamlandı.

Bir sonraki adımda gerçek gateway entegrasyonuna geçilecek:

FAZ 3 / STEP 13.1B — Gateway wiring adapter / gerçek mount dosyası hazırlığı.

## Not

Bu adımda gerçek gateway main/router dosyasına dokunulmadı. Önce keşif ve readiness doğrulandı.
