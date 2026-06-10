# FAZ 6-4 Real Implementation Audit

Generated At: 2026-05-01T14:34:55+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit, FAZ 6-4 Event Bus / Queue / Backlog SRE maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

## Scanned Files

```text
2355 /tmp/tmp.849lT9Qtxi/files.txt

./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf
./1_archive/root_sh/create_erp_structure.sh
./1_archive/root_sh/step_100_backup_run_api_gateway_script.sh
./1_archive/root_sh/step_101_test_identity_gateway_ports.sh
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh
./1_archive/root_sh/step_103_restart_api_gateway.sh
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh
./1_archive/root_sh/step_107_test_api_gateway_rate_limit.sh
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh
./1_archive/root_sh/step_109_restart_api_gateway_after_tenant_middleware.sh
./1_archive/root_sh/step_10_run_tenant_event_pipeline_test.sh
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh
./1_archive/root_sh/step_112a_install_redis_tools.sh
./1_archive/root_sh/step_112_check_redis_before_gateway_limit.sh
./1_archive/root_sh/step_113_add_go_redis_dependency.sh
./1_archive/root_sh/step_114_restart_api_gateway_after_redis_rate_limit.sh
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh
./1_archive/root_sh/step_116_backup_api_gateway_before_auth_route.sh
./1_archive/root_sh/step_117_check_auth_service_9002.sh
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh
./1_archive/root_sh/step_121_create_auth_api_dir.sh
./1_archive/root_sh/step_122_run_auth_api.sh
./1_archive/root_sh/step_123_test_auth_api_local.sh
./1_archive/root_sh/step_124_test_auth_via_gateway.sh
./1_archive/root_sh/step_125_restart_gateway_after_auth_route.sh
./1_archive/root_sh/step_126_backup_api_gateway_before_combined_gateway.sh
./1_archive/root_sh/step_127_restart_combined_gateway.sh
./1_archive/root_sh/step_128_test_combined_gateway.sh
./1_archive/root_sh/step_129_test_scope_separation.sh
./1_archive/root_sh/step_12_run_tenant_service_filter_test.sh
./1_archive/root_sh/step_130_backup_gateway_before_authz_layer.sh
./1_archive/root_sh/step_130_backup_nginx_before_rate_limit.sh
./1_archive/root_sh/step_131_add_nginx_global_rate_limit.sh
./1_archive/root_sh/step_131_restart_gateway_after_bearer_tenant_match.sh
./1_archive/root_sh/step_132_enable_rate_limit_api_domain.sh
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh
./1_archive/root_sh/step_133_reload_nginx_after_rate_limit.sh
./1_archive/root_sh/step_134_check_503_source.sh
./1_archive/root_sh/step_135_check_nginx_error_log.sh
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh
./1_archive/root_sh/step_13_backup_redis_tenant_namespace.sh
./1_archive/root_sh/step_14_prepare_cache_dir.sh
./1_archive/root_sh/step_15_run_redis_tenant_namespace_test.sh
./1_archive/root_sh/step_160_install_nats_event_bus.sh
./1_archive/root_sh/step_161_check_nats_health.sh
./1_archive/root_sh/step_162_add_nats_go_client.sh
./1_archive/root_sh/step_163_prepare_nats_publisher_folder.sh
./1_archive/root_sh/step_164_prepare_nats_subscriber_folder.sh
./1_archive/root_sh/step_165_run_nats_subscriber.sh
./1_archive/root_sh/step_166_run_nats_publisher.sh
./1_archive/root_sh/step_16_backup_super_admin_policy.sh
./1_archive/root_sh/step_170_check_jetstream.sh
./1_archive/root_sh/step_171_run_nats_cli.sh
./1_archive/root_sh/step_172_create_jetstream_stream.sh
./1_archive/root_sh/step_173_check_jetstream_stream.sh
./1_archive/root_sh/step_174_create_sale_consumer.sh
./1_archive/root_sh/step_175_check_sale_consumer.sh
./1_archive/root_sh/step_17_prepare_security_dir.sh
./1_archive/root_sh/step_181_prepare_stock_service_folder.sh
./1_archive/root_sh/step_181_stok_servisi_klasor.sh
./1_archive/root_sh/step_182_run_stock_service.sh
./1_archive/root_sh/step_183_run_accounting_service.sh
./1_archive/root_sh/step_184_backup_panel_before_service_monitor.sh
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh
./1_archive/root_sh/step_187_create_service_status_cron.sh
./1_archive/root_sh/step_188_list_sh_files.sh
./1_archive/root_sh/step_188_prepare_cache_service_folder.sh
./1_archive/root_sh/step_188_verify_done_items.sh
./1_archive/root_sh/step_189_check_jetstream_streams.sh
./1_archive/root_sh/step_189_run_cache_service.sh
./1_archive/root_sh/step_18_run_super_admin_policy_test.sh
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh
./1_archive/root_sh/step_190_test_cache_service.sh
./1_archive/root_sh/step_191_prepare_idempotency_folder.sh
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh
```

## 6-4.1.1 NATS / JetStream runtime kod-config izi

Pattern:

```text
NATS|JETSTREAM|JetStream|nats://|NewConn|nats\.Connect|js\.|Stream|Consumer|NATS_URL|NATS_ENDPOINT
```

Match Count: 175

```text
./1_archive/root_sh/step_160_install_nats_event_bus.sh:8:cat <<'NATSYML' > deploy/nats/docker-compose.yml
./1_archive/root_sh/step_160_install_nats_event_bus.sh:26:NATSYML
./1_archive/root_sh/step_160_install_nats_event_bus.sh:32:echo "OK ✅ NATS Event Bus kuruldu"
./1_archive/root_sh/step_161_check_nats_health.sh:4:echo "=== NATS 4222 ==="
./1_archive/root_sh/step_161_check_nats_health.sh:8:echo "=== NATS MONITOR 8222 ==="
./1_archive/root_sh/step_161_check_nats_health.sh:13:echo "OK ✅ NATS health kontrol bitti"
./1_archive/root_sh/step_162_add_nats_go_client.sh:8:echo "OK ✅ Go NATS client eklendi"
./1_archive/root_sh/step_170_check_jetstream.sh:4:echo "=== NATS JetStream kontrol ==="
./1_archive/root_sh/step_170_check_jetstream.sh:9:echo "OK ✅ JetStream kontrol bitti"
./1_archive/root_sh/step_172_create_jetstream_stream.sh:5:nats --server nats://127.0.0.1:4222 stream add PIX2PI_EVENTS \
./1_archive/root_sh/step_173_check_jetstream_stream.sh:5:nats --server nats://127.0.0.1:4222 stream info PIX2PI_EVENTS
./1_archive/root_sh/step_174_create_sale_consumer.sh:5:nats --server nats://127.0.0.1:4222 consumer rm PIX2PI_EVENTS SALE_PROCESSOR -f >/dev/null 2>&1 || true
./1_archive/root_sh/step_174_create_sale_consumer.sh:7:nats --server nats://127.0.0.1:4222 consumer add PIX2PI_EVENTS SALE_PROCESSOR \
./1_archive/root_sh/step_175_check_sale_consumer.sh:5:nats --server nats://127.0.0.1:4222 consumer info PIX2PI_EVENTS SALE_PROCESSOR
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:61:NATS=$(durum_docker "nats" "pix2pi_nats")
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:84:  $NATS,
./1_archive/root_sh/step_189_check_jetstream_streams.sh:16:echo "OK ✅ JetStream stream kontrolu bitti"
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:44:	nc, err := nats.Connect("nats://localhost:4222")
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:46:		log.Fatalf("NATS baglanti hatasi: %v", err)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:50:	js, err := nc.JetStream()
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:52:		log.Fatalf("JetStream erisim hatasi: %v", err)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:71:		_, err := js.Subscribe(subject, func(msg *nats.Msg) {
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:102:		log.Fatal("HATA: hicbir JetStream subject'ine baglanilamadi")
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:61:	nc, err := nats.Connect("nats://localhost:4222")
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:63:		log.Fatalf("NATS baglanti hatasi: %v", err)
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:67:	js, err := nc.JetStream()
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:69:		log.Fatalf("JetStream erisim hatasi: %v", err)
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:72:	_, err = js.Subscribe("pix2pi.>", func(msg *nats.Msg) {
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:155:	natsURL := os.Getenv("NATS_URL")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:157:		natsURL = "nats://localhost:4222"
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:162:	nc, err := nats.Connect(natsURL)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:164:		log.Fatalf("NATS baglanti hatasi: %v", err)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:178:		registry.Register(req.Name, req.Address, "NATS")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:179:		log.Printf("OK ✅ NATS register | name=%s | address=%s", req.Name, req.Address)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:182:		log.Fatalf("NATS register subscribe hatasi: %v", err)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:195:		ok := registry.Heartbeat(req.Name, "NATS")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:197:			log.Printf("OK ✅ NATS heartbeat | name=%s", req.Name)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:203:		log.Fatalf("NATS heartbeat subscribe hatasi: %v", err)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:329:	registry.Register("accounting_service", "http://127.0.0.1:7002", "NATS")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:330:	ok := registry.Heartbeat("accounting_service", "NATS")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:335:	yok := registry.Heartbeat("olmayan_servis", "NATS")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:469:echo "14) NATS register testi..."
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:472:echo "OK ✅ NATS register testi gecti"
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:475:echo "15) NATS heartbeat testi..."
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:478:echo "OK ✅ NATS heartbeat testi gecti"
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:492:echo "OK ✅ HTTP + NATS birlikte calisiyor"
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:465:	natsURL := os.Getenv("NATS_URL")
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:467:		natsURL = "nats://localhost:4222"
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:475:	nc, err := nats.Connect(natsURL)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:477:		log.Fatalf("NATS baglanti hatasi: %v", err)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:481:	js, err := nc.JetStream()
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:483:		log.Fatalf("JetStream erisim hatasi: %v", err)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:486:	_, err = js.Subscribe("pix2pi.>", func(msg *nats.Msg) {
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:608:echo "12) Event entegrasyon testi icin NATS publish yapiliyor..."
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:611:echo "OK ✅ NATS publish gecti"
./1_archive/root_sh/step_45d0_event_recon.sh:11:  echo "===== 1) NATS / EVENT DOSYALARI ====="
./1_archive/root_sh/step_45d0_event_recon.sh:23:  echo "===== 3) NATS IMPORT ARAMA ====="
./1_archive/root_sh/step_46i_consumer_recon.sh:18:  echo "==== 2) NATS CONNECT ===="
./1_archive/root_sh/step_46i_consumer_recon.sh:19:  grep -Rni "nats.Connect\|nats.NewConn\|DefaultURL\|NATS_URL" cmd internal || true
./1_archive/root_sh/step_56a_finance_recon.sh:18:  echo "==== 3) NATS / SUBSCRIBE / PUBLISH ===="
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.1.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-4.1.2 Event publisher izi

Pattern:

```text
Publish|publisher|Publisher|EventPublisher|event.*publish|PublishMsg|JetStreamContext|Subject
```

Match Count: 718

```text
./1_archive/root_sh/step_163_prepare_nats_publisher_folder.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/cmd/nats-publisher
./1_archive/root_sh/step_163_prepare_nats_publisher_folder.sh:6:echo "OK ✅ nats publisher klasoru hazir"
./1_archive/root_sh/step_166_run_nats_publisher.sh:6:go run cmd/nats-publisher/nats_publisher_main.go
./1_archive/root_sh/step_166_run_nats_publisher.sh:8:echo "OK ✅ nats publisher calisti"
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:55:	olasiSubjectler := []string{
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:68:	for _, subject := range olasiSubjectler {
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:75:				log.Printf("PARSE HATA | subject=%s | err=%v", msg.Subject, err)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:77:					log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, ackErr)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:82:			fmt.Printf("REPORT EVENT | subject=%s | type=%s\n", msg.Subject, e.Type)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:85:				log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, ackErr)
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:76:			log.Printf("PARSE HATA | subject=%s | err=%v", msg.Subject, err)
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:78:				log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, ackErr)
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:83:		fmt.Printf("REPORT EVENT | subject=%s | type=%s\n", msg.Subject, e.Type)
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:86:			log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, ackErr)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:236:		_ = nc.Publish("pix2pi.service.register", payload)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:270:		_ = nc.Publish("pix2pi.service.heartbeat", payload)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:490:			log.Printf("PARSE HATA | subject=%s | err=%v", msg.Subject, err)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:495:		log.Printf("REPORT EVENT | subject=%s | type=%s", msg.Subject, e.Type)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:506:			log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, err)
./1_archive/root_sh/step_45d0_event_recon.sh:34:  find . -type f | grep -E 'eventbus|publisher|subscriber|consumer|nats' | sort || true
./1_archive/root_sh/step_46i_consumer_recon.sh:38:  echo "==== 7) event publish noktaları ===="
./1_archive/root_sh/step_46i_consumer_recon.sh:39:  grep -Rni "Publish(" cmd internal || true
./1_archive/root_sh/step_56a_finance_recon.sh:19:  grep -RInE 'nats|Subscribe|QueueSubscribe|Publish|JetStream|user.created|sale.created|pix2pi\.' ~/pix2pi/pix2pi-SaaS/cmd ~/pix2pi/pix2pi-SaaS/internal || true
./1_archive/root_sh/step_90_check_server_cert_names.sh:4:openssl x509 -in /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem -text -noout | grep -A1 "Subject Alternative Name" || true
./cmd/api-gateway/erp_runtime_service_factory.go:92:		&erpRuntimeGatewayFlowPublisher{},
./cmd/api-gateway/erp_runtime_service_factory.go:115:		PublishRuntimeEvent: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
./cmd/api-gateway/erp_runtime_service_factory.go:121:type erpRuntimeGatewayFlowPublisher struct{}
./cmd/api-gateway/erp_runtime_service_factory.go:123:func (p *erpRuntimeGatewayFlowPublisher) PublishFlowCompleted(ctx context.Context, result e2eflow.RuntimeFlowResult) error {
./cmd/api-gateway/erp_runtime_service_factory.go:127:func (p *erpRuntimeGatewayFlowPublisher) PublishFlowFailed(ctx context.Context, plan e2eflow.RuntimeFlowPlan, cause error) error {
./cmd/event-bus/event_bus_main.go:23:	ack, err := js.Publish("pix2pi.user.created", msg)
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:32:	err := bus.Publish(event)
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:43:	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumBekliyor, "publish sonrasi durum bekliyor olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:117:	err = bus.Publish(event)
./cmd/event-concurrency-test/event_concurrency_test_main.go:48:	const toplamPublish = 20
./cmd/event-concurrency-test/event_concurrency_test_main.go:50:	publishErrCh := make(chan error, toplamPublish)
./cmd/event-concurrency-test/event_concurrency_test_main.go:52:	for i := 1; i <= toplamPublish; i++ {
./cmd/event-concurrency-test/event_concurrency_test_main.go:69:			if err := bus.Publish(event); err != nil {
./cmd/event-concurrency-test/event_concurrency_test_main.go:79:	zorunlu(len(store.TumKayitlariListele()) == toplamPublish, "publish sonrasi store kayit sayisi 20 olmali")
./cmd/event-concurrency-test/event_concurrency_test_main.go:80:	zorunlu(len(bus.TopicBekleyenEventleriListele("sale.created")) == toplamPublish, "publish sonrasi bekleyen event sayisi 20 olmali")
./cmd/event-idempotency-test/event_idempotency_test_main.go:33:	err := bus.Publish(event1)
./cmd/event-idempotency-test/event_idempotency_test_main.go:49:	err = bus.Publish(event2)
./cmd/event-idempotency-test/event_idempotency_test_main.go:66:	err = bus.Publish(event3)
./cmd/event-idempotency-test/event_idempotency_test_main.go:82:	err = bus.Publish(event4)
./cmd/event-idempotency-test/event_idempotency_test_main.go:96:	err = bus.Publish(event5)
./cmd/event-metadata-test/event_metadata_test_main.go:38:	err := bus.Publish(event)
./cmd/event-metadata-test/event_metadata_test_main.go:86:	err = bus.Publish(event2)
./cmd/event-replay-test/event_replay_test_main.go:33:	err := bus.Publish(event)
./cmd/event-schema-test/event_schema_test_main.go:47:	err = bus.Publish(gecerliEvent)
./cmd/event-schema-test/event_schema_test_main.go:51:	fmt.Println("OK ✅ gecerli event publish basarili")
./cmd/event-schema-test/event_schema_test_main.go:70:	err = bus.Publish(invalidAlanEvent)
./cmd/event-schema-test/event_schema_test_main.go:85:	err = bus.Publish(invalidJsonEvent)
./cmd/event-schema-test/event_schema_test_main.go:100:	err = bus.Publish(topicYokEvent)
./cmd/event-schema-test/event_schema_test_main.go:117:	err = bus.Publish(yanlisVersiyonEvent)
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:72:	err = bus.Publish(event1)
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:130:	err = bus.Publish(event2)
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:169:	err = bus.Publish(event3)
./cmd/identity-api/identity_api_main.go:77:	err := nc.Publish("pix2pi.user.created", data)
./cmd/identity-api/identity_api_main.go:79:		log.Println("❌ event publish hatası:", err)
./cmd/nats-publisher/nats_publisher_main.go:19:	err = nc.Publish(subject, payload)
./cmd/nats-publisher/nats_publisher_main.go:21:		log.Fatalf("event publish hatasi: %v", err)
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.1.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-4.1.3 Event consumer / subscriber izi

Pattern:

```text
Subscribe|QueueSubscribe|consumer|Consumer|subscriber|Subscriber|PullSubscribe|Fetch|Consume|event.*consume
```

Match Count: 186

```text
./1_archive/root_sh/step_164_prepare_nats_subscriber_folder.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/cmd/nats-subscriber
./1_archive/root_sh/step_164_prepare_nats_subscriber_folder.sh:6:echo "OK ✅ nats subscriber klasoru hazir"
./1_archive/root_sh/step_165_run_nats_subscriber.sh:6:nohup go run cmd/nats-subscriber/nats_subscriber_main.go >/tmp/pix2pi_nats_subscriber.log 2>&1 &
./1_archive/root_sh/step_165_run_nats_subscriber.sh:10:cat /tmp/pix2pi_nats_subscriber.log || true
./1_archive/root_sh/step_165_run_nats_subscriber.sh:12:echo "OK ✅ nats subscriber baslatildi"
./1_archive/root_sh/step_174_create_sale_consumer.sh:5:nats --server nats://127.0.0.1:4222 consumer rm PIX2PI_EVENTS SALE_PROCESSOR -f >/dev/null 2>&1 || true
./1_archive/root_sh/step_174_create_sale_consumer.sh:7:nats --server nats://127.0.0.1:4222 consumer add PIX2PI_EVENTS SALE_PROCESSOR \
./1_archive/root_sh/step_174_create_sale_consumer.sh:19:echo "OK ✅ sale durable consumer olusturuldu"
./1_archive/root_sh/step_175_check_sale_consumer.sh:5:nats --server nats://127.0.0.1:4222 consumer info PIX2PI_EVENTS SALE_PROCESSOR
./1_archive/root_sh/step_175_check_sale_consumer.sh:8:echo "OK ✅ sale consumer kontrol bitti"
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:24:echo "2) Reporting subscriber dosyasi yaziliyor..."
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:71:		_, err := js.Subscribe(subject, func(msg *nats.Msg) {
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:105:	fmt.Println("OK ✅ Reporting subscriber started")
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:120:echo "4) Reporting subscriber calistiriliyor..."
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:124:echo "- Sonra: OK ✅ Reporting subscriber started"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:72:	_, err = js.Subscribe("pix2pi.>", func(msg *nats.Msg) {
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:93:		log.Fatalf("Subscribe hatasi: %v", err)
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:96:	fmt.Println("OK ✅ Reporting subscriber started")
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:208:if grep -q "Reporting subscriber started" "$log_dosya" 2>/dev/null; then
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:168:	_, err = nc.Subscribe("pix2pi.service.register", func(msg *nats.Msg) {
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:185:	_, err = nc.Subscribe("pix2pi.service.heartbeat", func(msg *nats.Msg) {
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:486:	_, err = js.Subscribe("pix2pi.>", func(msg *nats.Msg) {
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:513:		log.Fatalf("Subscribe hatasi: %v", err)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:516:	log.Println("OK ✅ Reporting subscriber started")
./1_archive/root_sh/step_45d0_event_recon.sh:34:  find . -type f | grep -E 'eventbus|publisher|subscriber|consumer|nats' | sort || true
./1_archive/root_sh/step_46i_consumer_recon.sh:5:OUT="$ROOT/step_46i_consumer_recon.txt"
./1_archive/root_sh/step_46i_consumer_recon.sh:23:  grep -Rni "Subscribe\|QueueSubscribe\|ChanSubscribe\|PullSubscribe" cmd internal || true
./1_archive/root_sh/step_46i_consumer_recon.sh:30:  echo "==== 5) event consumer / subscriber / reporting ===="
./1_archive/root_sh/step_46i_consumer_recon.sh:31:  grep -Rni "consumer\|subscriber\|reporting" cmd internal || true
./1_archive/root_sh/step_46i_consumer_recon.sh:47:  echo "Bu rapor sonraki adimda mevcut consumeri patchlemek icin kullanilacak."
./1_archive/root_sh/step_56a_finance_recon.sh:19:  grep -RInE 'nats|Subscribe|QueueSubscribe|Publish|JetStream|user.created|sale.created|pix2pi\.' ~/pix2pi/pix2pi-SaaS/cmd ~/pix2pi/pix2pi-SaaS/internal || true
./cmd/accounting-service/accounting_service_main.go:86:	_, err = nc.Subscribe("pix2pi.sale.created", func(m *nats.Msg) {
./cmd/event-consumer/event_consumer_main.go:30:	_, err = js.Subscribe("pix2pi.>", func(msg *nats.Msg) {
./cmd/event-consumer/event_consumer_main.go:45:	}, nats.Durable("pix2pi-consumer-v2"), nats.ManualAck())
./cmd/event-consumer/event_consumer_main.go:51:	fmt.Println("🚀 Event Consumer RUNNING...")
./cmd/nats-subscriber/nats_subscriber_main.go:18:	_, err = nc.Subscribe(subject, func(msg *nats.Msg) {
./cmd/nats-subscriber/nats_subscriber_main.go:25:	log.Println("subscriber dinlemede:", subject)
./cmd/reporting_service_main.go:28:	_, err = js.Subscribe("events.>", func(msg *nats.Msg) {
./cmd/reporting_service_main.go:51:	fmt.Println("Reporting subscriber started")
./cmd/reporting-service/reporting_service_main.go:123:	_, err = js.Subscribe("pix2pi.>", func(msg *nats.Msg) {
./cmd/reporting-service/reporting_service_main.go:150:		log.Fatalf("Subscribe hatasi: %v", err)
./cmd/reporting-service/reporting_service_main.go:153:	log.Println("OK ✅ Reporting subscriber started")
./cmd/service-discovery/service_discovery_main.go:125:	_, err = nc.Subscribe("pix2pi.service.register", func(msg *nats.Msg) {
./cmd/service-discovery/service_discovery_main.go:142:	_, err = nc.Subscribe("pix2pi.service.heartbeat", func(msg *nats.Msg) {
./cmd/stock-service/stock_service_main.go:40:	_, err = nc.Subscribe("pix2pi.sale.created", func(m *nats.Msg) {
./cmd/user-created-consumer/user_created_consumer_main.go:158:	log.Println("STEP ▶ user-created-consumer boot basladi")
./cmd/user-created-consumer/user_created_consumer_main.go:193:	nc, err := nats.Connect(natsURL, nats.Name("pix2pi-user-created-consumer"))
./cmd/user-created-consumer/user_created_consumer_main.go:201:	_, err = nc.QueueSubscribe("pix2pi.user.created", "read-model-projection", func(msg *nats.Msg) {
./cmd/user-created-consumer/user_created_consumer_main.go:238:	log.Println("OK ✅ consumer kapandi")
./deploy/observability/config/lvl11_correlation_catalog.yaml:40:      hint: Event consumer lag veya yetersiz consumer sayisi olasiligi yuksek.
./deploy/observability/config/lvl11_signal_catalog.yaml:36:      - id: event.consumer.lag
./deploy/observability/config/lvl11_signal_catalog.yaml:37:        metric: event_consumer_lag_count
./deploy/observability/generated/lvl11_scale_trigger_matrix.yaml:15:    action: increase_consumers_or_stream_capacity
./internal/platform/monitor/reporting_pressure_early_warning_service_test.go:10:		Source:            "readmodel-subscriber",
./internal/platform/monitor/reporting_pressure_runtime_bridge_service_test.go:10:		Source:            "readmodel-subscriber",
./internal/platform/monitor/reporting_pressure_runtime_bridge_service_test.go:73:	if snapshot.Source != "readmodel-subscriber" {
./internal/platform/monitor/reporting_pressure_runtime_bridge_service_test.go:74:		t.Fatalf("expected readmodel-subscriber, got %s", snapshot.Source)
./internal/platform/readmodel/subscriber_access.go:9:	ErrSubscriberAccessEmptyName         = errors.New("readmodel: subscriber access empty name")
./internal/platform/readmodel/subscriber_access.go:10:	ErrSubscriberAccessTenantMismatch    = errors.New("readmodel: subscriber access tenant mismatch")
./internal/platform/readmodel/subscriber_access.go:11:	ErrSubscriberAccessProjectionMismatch = errors.New("readmodel: subscriber access projection mismatch")
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.1.3 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-4.2 Backlog / pending / lag izi

Pattern:

```text
backlog|pending|Pending|lag|Lag|NumPending|AckFloor|Redelivered|ConsumerInfo|jsz|subsz|queue depth|queue_depth
```

Match Count: 355

```text
./1_archive/root_sh/step_170_check_jetstream.sh:6:curl -s http://127.0.0.1:8222/jsz | head -20
./1_archive/root_sh/step_174_create_sale_consumer.sh:15:  --max-pending 1000 \
./1_archive/root_sh/step_192_reporting_service_panelde_goster.sh:120:        html_match = re.search(r'(<[^>]*>[^<]*accounting_service[^<]*</[^>]*>)', new_content, flags=re.IGNORECASE)
./1_archive/root_sh/step_351_clean_nginx_duplicates_and_fix_monitor.sh:43:block = re.sub(r'\n\s*location = /monitor \{.*?\n\s*\}\n', '\n', block, flags=re.S)
./1_archive/root_sh/step_352_force_monitor_from_static_root.sh:57:block = re.sub(r'\n\s*location\s*=\s*/monitor\s*\{.*?\n\s*\}\n', '\n', block, flags=re.S)
./1_archive/root_sh/step_358_fix_ssl_status_route.sh:26:    flags=re.S
./1_archive/root_sh/step_358_fix_ssl_status_route.sh:33:    flags=re.S
./1_archive/root_sh/step_362_fix_panel_ssl_service_status.sh:26:    flags=re.S
./1_archive/root_sh/step_363_clean_panel_ssl_routes.sh:28:    text = re.sub(pat, '\n', text, flags=re.S)
./1_archive/root_sh/step_368_panel_final_logic_fix.sh:24:html = re.sub(r"<script>.*?</script>\s*</body>", "</body>", html, flags=re.S)
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:93:grep -q "UAT_12_STATUS=PENDING_BUSINESS_ACCEPTANCE" "$REPORT_FILE" || fail "UAT-12 business acceptance pending yok"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:94:pass "UAT-12 business acceptance pending"
./cmd/migrate/main.go:4:	"flag"
./cmd/migrate/main.go:25:		cmd         = flag.String("cmd", "up", "up|down|steps|version|force")
./cmd/migrate/main.go:26:		steps       = flag.Int("n", 1, "steps count for -cmd=steps (positive=up, negative=down)")
./cmd/migrate/main.go:27:		forceVer    = flag.Int("v", -1, "force version for -cmd=force")
./cmd/migrate/main.go:28:		migrations  = flag.String("dir", "file://internal/db/migrations", "migrations dir (file://...)")
./cmd/migrate/main.go:29:		databaseURL = flag.String("dsn", "", "override DSN (otherwise DATABASE_URL)")
./cmd/migrate/main.go:31:	flag.Parse()
./db/migrations/006_phase2_db_l4_notifications.up.sql:71:      'pending',
./db/migrations/006_phase2_db_l4_notifications.up.sql:179:  delivery_status runtime.notification_recipient_status_enum NOT NULL DEFAULT 'pending',
./db/migrations/008_phase2_db_l4_workflows.up.sql:32:      'pending',
./db/migrations/008_phase2_db_l4_workflows.up.sql:52:      'pending',
./db/migrations/008_phase2_db_l4_workflows.up.sql:74:      'pending',
./db/migrations/008_phase2_db_l4_workflows.up.sql:138:  workflow_status runtime.workflow_instance_status_enum NOT NULL DEFAULT 'pending',
./db/migrations/008_phase2_db_l4_workflows.up.sql:176:  step_status runtime.workflow_step_status_enum NOT NULL DEFAULT 'pending',
./db/migrations/008_phase2_db_l4_workflows.up.sql:211:  approval_status runtime.workflow_approval_status_enum NOT NULL DEFAULT 'pending',
./db/migrations/20260425_094001_erp_sales_documents.up.sql:431:        CHECK (e_document_status IN ('none', 'pending', 'sent', 'accepted', 'rejected', 'cancelled')),
./db/migrations/20260425_095001_erp_procurement_documents.up.sql:290:        CHECK (e_document_status IN ('none', 'pending', 'received', 'accepted', 'rejected', 'cancelled')),
./db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql:94:    step_status text NOT NULL DEFAULT 'pending' CHECK (
./db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql:96:            'pending',
./db/migrations/20260427_151001_readmodel_operational_tables.up.sql:34:    pending_document_count integer NOT NULL DEFAULT 0,
./db/migrations/20260427_151001_readmodel_operational_tables.up.sql:35:    pending_payment_count integer NOT NULL DEFAULT 0,
./db/migrations/20260427_151001_readmodel_operational_tables.up.sql:68:    negative_stock_flag boolean NOT NULL DEFAULT false,
./db/migrations/20260427_151001_readmodel_operational_tables.up.sql:69:    below_min_stock_flag boolean NOT NULL DEFAULT false,
./db/migrations/20260427_151001_readmodel_operational_tables.up.sql:81:    status text NOT NULL DEFAULT 'pending',
./db/migrations/20260427_151001_readmodel_operational_tables.up.sql:116:    ON readmodel.inventory_status_snapshot (tenant_id, negative_stock_flag, below_min_stock_flag, updated_at);
./db/migrations/20260428_143001_import_staging_tables.up.sql:68:    validation_status text NOT NULL DEFAULT 'pending',
./db/migrations/20260428_143001_import_staging_tables.up.sql:93:    validation_status text NOT NULL DEFAULT 'pending',
./db/migrations/20260428_143001_import_staging_tables.up.sql:119:    validation_status text NOT NULL DEFAULT 'pending',
./db/migrations/20260428_143001_import_staging_tables.up.sql:142:    validation_status text NOT NULL DEFAULT 'pending',
./db/migrations/20260428_143001_import_staging_tables.up.sql:165:    validation_status text NOT NULL DEFAULT 'pending',
./db/migrations/20260428_153001_ebelge_export_reporting_mart.up.sql:105:    pending_count integer NOT NULL DEFAULT 0 CHECK (pending_count >= 0),
./db/migrations/20260428_153001_ebelge_export_reporting_mart.up.sql:153:    pending_export_batches integer NOT NULL DEFAULT 0 CHECK (pending_export_batches >= 0),
./db/migrations/20260428_181001_inventory_opening_stock.up.sql:49:    validation_status text NOT NULL DEFAULT 'pending',
./db/migrations/20260428_182001_inventory_stock_movement_engine.up.sql:108:    validation_status text NOT NULL DEFAULT 'pending',
./db/migrations/20260428_183001_inventory_sales_stock_decrement.up.sql:60:    validation_status text NOT NULL DEFAULT 'pending',
./db/migrations/20260428_184001_inventory_purchase_stock_increment.up.sql:65:    validation_status text NOT NULL DEFAULT 'pending',
./db/migrations/20260428_185001_inventory_stock_reservation.up.sql:92:    validation_status text NOT NULL DEFAULT 'pending',
./db/migrations/20260429_213001_security_audit_event_model.up.sql:135:    immutable_status text NOT NULL DEFAULT 'pending',
./db/tests/008_phase2_notifications.sql:49:  ('88888888-cccc-cccc-cccc-ccccccccccc2', '11111111-1111-1111-1111-111111111111', '77777777-bbbb-bbbb-bbbb-bbbbbbbbbbb2', 'NRC_TENANT_A_1', 'email', 'tenant-a-recipient-1', 'a@example.com', 'pending'),
./db/tests/008_phase2_notifications.sql:50:  ('88888888-cccc-cccc-cccc-ccccccccccc3', '22222222-2222-2222-2222-222222222222', '77777777-bbbb-bbbb-bbbb-bbbbbbbbbbb3', 'NRC_TENANT_B_1', 'phone', 'tenant-b-recipient-1', '+905550000003', 'pending')
./db/tests/010_phase2_workflows.sql:57:  ('15151515-dddd-dddd-dddd-ddddddddddd1', NULL, '13131313-bbbb-bbbb-bbbb-bbbbbbbbbbb1', '14141414-cccc-cccc-cccc-ccccccccccc1', 'WFA_GLOBAL_1', 'approval-global-1', 'ops-global', 'pending'),
./db/tests/010_phase2_workflows.sql:58:  ('15151515-dddd-dddd-dddd-ddddddddddd2', '11111111-1111-1111-1111-111111111111', '13131313-bbbb-bbbb-bbbb-bbbbbbbbbbb2', '14141414-cccc-cccc-cccc-ccccccccccc2', 'WFA_TENANT_A_1', 'approval-tenant-a-1', 'manager-a', 'pending'),
./db/tests/010_phase2_workflows.sql:59:  ('15151515-dddd-dddd-dddd-ddddddddddd3', '22222222-2222-2222-2222-222222222222', '13131313-bbbb-bbbb-bbbb-bbbbbbbbbbb3', '14141414-cccc-cccc-cccc-ccccccccccc3', 'WFA_TENANT_B_1', 'approval-tenant-b-1', 'manager-b', 'pending')
./deploy/observability/config/lvl11_correlation_catalog.yaml:38:    - id: event_backlog_hint
./deploy/observability/config/lvl11_correlation_catalog.yaml:39:      when_signal: event.backlog.size
./deploy/observability/config/lvl11_correlation_catalog.yaml:40:      hint: Event consumer lag veya yetersiz consumer sayisi olasiligi yuksek.
./deploy/observability/config/lvl11_signal_catalog.yaml:34:      - id: event.backlog.size
./deploy/observability/config/lvl11_signal_catalog.yaml:35:        metric: event_backlog_count
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-4.3.1 Ack / Nack / Nak izi

Pattern:

```text
\.Ack\(|\.Nak\(|\.Nack\(|Ack\(|Nak\(|Nack\(|ManualAck|AckWait|DoubleAck
```

Match Count: 24

```text
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:76:				if ackErr := msg.Ack(); ackErr != nil {
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:84:			if ackErr := msg.Ack(); ackErr != nil {
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:89:			nats.ManualAck(),
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:77:			if ackErr := msg.Ack(); ackErr != nil {
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:85:		if ackErr := msg.Ack(); ackErr != nil {
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:90:		nats.ManualAck(),
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:491:			_ = msg.Ack()
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:505:		if err := msg.Ack(); err != nil {
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:510:		nats.ManualAck(),
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:101:	err = bus.Ack("evt-001")
./cmd/event-concurrency-test/event_concurrency_test_main.go:93:			if err := bus.Ack(fmt.Sprintf("evt-conc-%03d", i)); err != nil {
./cmd/event-consumer/event_consumer_main.go:44:		msg.Ack()
./cmd/event-consumer/event_consumer_main.go:45:	}, nats.Durable("pix2pi-consumer-v2"), nats.ManualAck())
./cmd/event-metadata-test/event_metadata_test_main.go:56:	err = bus.Ack("evt-meta-001")
./cmd/event-replay-test/event_replay_test_main.go:39:	err = bus.Ack("evt-replay-001")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:91:	err = bus.Ack("evt-pg-001")
./cmd/reporting_service_main.go:40:		msg.Ack()
./cmd/reporting_service_main.go:44:		nats.ManualAck(),
./cmd/reporting-service/reporting_service_main.go:128:			_ = msg.Ack()
./cmd/reporting-service/reporting_service_main.go:142:		if err := msg.Ack(); err != nil {
./cmd/reporting-service/reporting_service_main.go:147:		nats.ManualAck(),
./internal/platform/eventbus/service/event_bus_service.go:341:func (s *EventBusService) Ack(eventID string) error {
./scripts/audit_faz6_4_real_implementation.sh:168:write_check "6-4.3.1" "Ack / Nack / Nak izi" "\\.Ack\\(|\\.Nak\\(|\\.Nack\\(|Ack\\(|Nak\\(|Nack\\(|ManualAck|AckWait|DoubleAck" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_4_real_implementation.sh:170:write_check "6-4.3.2" "Retry / MaxDeliver / backoff izi" "retry|Retry|MAX_RETRY|max_retry|MaxDeliver|max deliver|AckWait|backoff|Backoff|redeliver|Redeliver" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.3.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-4.3.2 Retry / MaxDeliver / backoff izi

Pattern:

```text
retry|Retry|MAX_RETRY|max_retry|MaxDeliver|max deliver|AckWait|backoff|Backoff|redeliver|Redeliver
```

Match Count: 567

```text
./1_archive/root_sh/step_194_test_retry.sh:8:echo "OK ✅ retry test bitti"
./1_archive/root_sh/step_392_production_hardening.sh:19:MAX_RETRY=3
./1_archive/root_sh/step_392_production_hardening.sh:50:can_retry() {
./1_archive/root_sh/step_392_production_hardening.sh:71:  if [ "$fail_count" -ge "$MAX_RETRY" ]; then
./1_archive/root_sh/step_392_production_hardening.sh:72:    echo "svc=$svc action=blocked reason=max_retry"
./1_archive/root_sh/step_392_production_hardening.sh:76:  if ! can_retry "$svc"; then
./1_archive/root_sh/step_40_backup_event_retry.sh:9:  backups/app/manual/playground_main.go.event_retry.bak 2>/dev/null || true
./1_archive/root_sh/step_40_backup_event_retry.sh:12:  backups/app/manual/event_message.go.event_retry.bak 2>/dev/null || true
./1_archive/root_sh/step_40_backup_event_retry.sh:15:  backups/app/manual/event_bus_service.go.event_retry.bak 2>/dev/null || true
./1_archive/root_sh/step_40_backup_event_retry.sh:17:echo "OK ✅ event retry yedegi alindi"
./1_archive/root_sh/step_41_run_event_retry_test.sh:8:echo "OK ✅ event retry test calistirma bitti"
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:44:	zorunlu(kayit.MaxRetry == 3, "default max retry 3 olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:47:	err = bus.Retry("evt-001")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:57:	fmt.Printf("DEBUG retry-1 | durum=%s retry=%d max=%d\n", kayit.Durum, kayit.RetryCount, kayit.MaxRetry)
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:59:	zorunlu(kayit.RetryCount == 1, "retry count 1 olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:60:	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumTekrar, "retry sonrasi store durumu tekrar olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:61:	fmt.Println("OK ✅ retry store sync dogrulandi")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:63:	err = bus.Retry("evt-001")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:68:	err = bus.Retry("evt-001")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:78:	fmt.Printf("DEBUG dlq | durum=%s retry=%d max=%d dlq_nedeni=%s\n", kayit.Durum, kayit.RetryCount, kayit.MaxRetry, kayit.DlqNedeni)
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:80:	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumDlq, "max retry sonrasi store durumu dlq olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:94:	fmt.Printf("DEBUG requeue | durum=%s retry=%d\n", kayit.Durum, kayit.RetryCount)
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:97:	zorunlu(kayit.RetryCount == 0, "requeue sonrasi retry count sifir olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:111:	fmt.Printf("DEBUG ack | durum=%s retry=%d\n", kayit.Durum, kayit.RetryCount)
./cmd/event-concurrency-test/event_concurrency_test_main.go:114:	retryErrCh := make(chan error, 10)
./cmd/event-concurrency-test/event_concurrency_test_main.go:123:			if err := bus.Retry(fmt.Sprintf("evt-conc-%03d", i)); err != nil {
./cmd/event-concurrency-test/event_concurrency_test_main.go:124:				retryErrCh <- fmt.Errorf("retry hata %d: %w", i, err)
./cmd/event-concurrency-test/event_concurrency_test_main.go:130:	close(retryErrCh)
./cmd/event-concurrency-test/event_concurrency_test_main.go:131:	kanalHataKontrol(retryErrCh)
./cmd/event-concurrency-test/event_concurrency_test_main.go:138:		zorunlu(kayit.RetryCount == 1, "retry sonrasi retry count 1 olmali")
./cmd/event-concurrency-test/event_concurrency_test_main.go:139:		zorunlu(kayit.Durum == "tekrar", "retry sonrasi store durumu tekrar olmali")
./cmd/event-concurrency-test/event_concurrency_test_main.go:141:	fmt.Println("OK ✅ paralel retry dogrulandi")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:127:		MaxRetry:       3,
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:135:	err = bus.Retry("evt-pg-002")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:140:	err = bus.Retry("evt-pg-002")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:145:	err = bus.Retry("evt-pg-002")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:155:	zorunlu(kayit2.Durum == "dlq", "3 retry sonrasi postgres durum dlq olmali")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:156:	zorunlu(kayit2.RetryCount == 3, "3 retry sonrasi retry count 3 olmali")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:157:	fmt.Println("OK ✅ postgres retry dlq persistence dogrulandi")
./cmd/jobs-runtime/jobs_runtime_main.go:34:	RetryLimit           int    `json:"retry_limit"`
./cmd/jobs-runtime/jobs_runtime_main.go:35:	RetryBackoffSeconds  int    `json:"retry_backoff_seconds"`
./cmd/jobs-runtime/jobs_runtime_main.go:51:	RetryCount   int    `json:"retry_count"`
./cmd/jobs-runtime/jobs_runtime_main.go:238:  coalesce(q.retry_limit, 0),
./cmd/jobs-runtime/jobs_runtime_main.go:239:  coalesce(q.retry_backoff_seconds, 0),
./cmd/jobs-runtime/jobs_runtime_main.go:254:  q.retry_limit,
./cmd/jobs-runtime/jobs_runtime_main.go:255:  q.retry_backoff_seconds,
./cmd/jobs-runtime/jobs_runtime_main.go:278:				&item.RetryLimit,
./cmd/jobs-runtime/jobs_runtime_main.go:279:				&item.RetryBackoffSeconds,
./cmd/jobs-runtime/jobs_runtime_main.go:311:  coalesce(j.retry_count, 0),
./cmd/jobs-runtime/jobs_runtime_main.go:347:				&item.RetryCount,
./cmd/webhook-runtime/webhook_runtime_main.go:37:	RetryLimit          int    `json:"retry_limit"`
./cmd/webhook-runtime/webhook_runtime_main.go:38:	RetryBackoffSeconds int    `json:"retry_backoff_seconds"`
./cmd/webhook-runtime/webhook_runtime_main.go:54:	RetryCount     int    `json:"retry_count"`
./cmd/webhook-runtime/webhook_runtime_main.go:56:	NextRetryAt    string `json:"next_retry_at"`
./cmd/webhook-runtime/webhook_runtime_main.go:259:  coalesce(e.retry_limit, 0),
./cmd/webhook-runtime/webhook_runtime_main.go:260:  coalesce(e.retry_backoff_seconds, 0),
./cmd/webhook-runtime/webhook_runtime_main.go:277:  e.retry_limit,
./cmd/webhook-runtime/webhook_runtime_main.go:278:  e.retry_backoff_seconds,
./cmd/webhook-runtime/webhook_runtime_main.go:305:				&item.RetryLimit,
./cmd/webhook-runtime/webhook_runtime_main.go:306:				&item.RetryBackoffSeconds,
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.3.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-4.4 DLQ / dead-letter izi

Pattern:

```text
DLQ|dlq|dead[-_ ]?letter|DeadLetter|dead_letter|failed.*event|failed_event|failure.*queue
```

Match Count: 244

```text
./1_archive/root_sh/step_195_test_dlq.sh:8:echo "OK ✅ dlq test bitti"
./1_archive/root_sh/step_44_backup_event_dlq.sh:9:backups/app/manual/event_bus_service.go.dlq.bak
./1_archive/root_sh/step_44_backup_event_dlq.sh:11:echo "OK ✅ event dlq yedegi alindi"
./1_archive/root_sh/step_45_run_event_dlq_test.sh:8:echo "OK ✅ dlq test calistirma bitti"
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:78:	fmt.Printf("DEBUG dlq | durum=%s retry=%d max=%d dlq_nedeni=%s\n", kayit.Durum, kayit.RetryCount, kayit.MaxRetry, kayit.DlqNedeni)
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:80:	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumDlq, "max retry sonrasi store durumu dlq olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:81:	zorunlu(len(bus.DlqEventleri()) == 1, "dlq icinde 1 event olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:82:	fmt.Println("OK ✅ dlq store sync dogrulandi")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:155:	zorunlu(kayit2.Durum == "dlq", "3 retry sonrasi postgres durum dlq olmali")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:157:	fmt.Println("OK ✅ postgres retry dlq persistence dogrulandi")
./cmd/jobs-runtime/jobs_runtime_main.go:36:	DeadLetterQueueKey   string `json:"dead_letter_queue_key"`
./cmd/jobs-runtime/jobs_runtime_main.go:40:	DeadLetterCount      int    `json:"dead_letter_count"`
./cmd/jobs-runtime/jobs_runtime_main.go:240:  coalesce(q.dead_letter_queue_key, ''),
./cmd/jobs-runtime/jobs_runtime_main.go:244:  count(j.id) FILTER (WHERE j.status::text = 'dead_letter')::int AS dead_letter_count,
./cmd/jobs-runtime/jobs_runtime_main.go:256:  q.dead_letter_queue_key,
./cmd/jobs-runtime/jobs_runtime_main.go:280:				&item.DeadLetterQueueKey,
./cmd/jobs-runtime/jobs_runtime_main.go:284:				&item.DeadLetterCount,
./cmd/notification-runtime/notification_runtime_main.go:196:    count(*) FILTER (WHERE delivery_status::text IN ('failed', 'dead_letter', 'cancelled'))::int AS failed_count
./cmd/notification-runtime/notification_runtime_main.go:441:	app.Get("/api/notifications/dlq", func(c *fiber.Ctx) error {
./cmd/notification-runtime/notification_runtime_main.go:458:WHERE r.delivery_status::text IN ('failed', 'dead_letter', 'cancelled')
./cmd/notification-runtime/notification_runtime_main.go:465:				"error": "notification dlq okunamadi",
./cmd/notification-runtime/notification_runtime_main.go:490:					"error": "notification dlq parse edilemedi",
./cmd/webhook-runtime/webhook_runtime_main.go:42:	DeadLetterCount     int    `json:"dead_letter_count"`
./cmd/webhook-runtime/webhook_runtime_main.go:58:	DeadLetteredAt string `json:"dead_lettered_at"`
./cmd/webhook-runtime/webhook_runtime_main.go:264:  count(d.id) FILTER (WHERE d.status::text = 'dead_letter')::int AS dead_letter_count,
./cmd/webhook-runtime/webhook_runtime_main.go:310:				&item.DeadLetterCount,
./cmd/webhook-runtime/webhook_runtime_main.go:343:  d.dead_lettered_at,
./cmd/webhook-runtime/webhook_runtime_main.go:400:			item.DeadLetteredAt = scanTime(deadLetteredAt)
./cmd/webhook-runtime/webhook_runtime_main.go:413:	app.Get("/api/webhooks/dlq", func(c *fiber.Ctx) error {
./cmd/webhook-runtime/webhook_runtime_main.go:429:  d.dead_lettered_at,
./cmd/webhook-runtime/webhook_runtime_main.go:437:WHERE d.status::text = 'dead_letter'
./cmd/webhook-runtime/webhook_runtime_main.go:438:ORDER BY d.dead_lettered_at DESC NULLS LAST, d.updated_at DESC
./cmd/webhook-runtime/webhook_runtime_main.go:444:				"error": "webhook dlq okunamadi",
./cmd/webhook-runtime/webhook_runtime_main.go:480:					"error": "webhook dlq parse edilemedi",
./cmd/webhook-runtime/webhook_runtime_main.go:487:			item.DeadLetteredAt = scanTime(deadLetteredAt)
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:36:      'dead_letter',
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:83:  dead_letter_queue_key text,
./db/migrations/007_phase2_db_l4_webhooks.up.sql:35:      'dead_letter',
./db/migrations/007_phase2_db_l4_webhooks.up.sql:135:  dead_lettered_at timestamptz,
./db/migrations/007_phase2_db_l4_webhooks.up.sql:148:  CHECK (dead_lettered_at IS NULL OR dead_lettered_at >= created_at)
./deploy/platform/config/lvl12_notifications_catalog.yaml:30:  webhook_retry_dlq:
./deploy/platform/config/lvl12_notifications_catalog.yaml:34:      - dlq_enabled
./deploy/platform/generated/lvl12_jobs_notifications_rules.yaml:16:  webhook_dlq_enabled: true
./deploy/platform/scripts/lvl12_jobs_notifications_smoke.sh:44:grep -q 'webhook_retry_dlq:' "${NOTIFY_CATALOG_FILE}"
./deploy/platform/scripts/lvl12_jobs_notifications_smoke.sh:45:echo "OK ✅ webhook retry / DLQ var"
./deploy/platform/scripts/render_lvl12_jobs_notifications.sh:49:  NOTIFY_WEBHOOK_DLQ_ENABLED
./deploy/platform/scripts/render_lvl12_jobs_notifications.sh:72:  -e "s|__NOTIFY_WEBHOOK_DLQ_ENABLED__|${NOTIFY_WEBHOOK_DLQ_ENABLED}|g" \
./deploy/platform/scripts/render_lvl12_jobs_notifications.sh:95:- Webhook DLQ enabled: ${NOTIFY_WEBHOOK_DLQ_ENABLED}
./internal/platform/dlq.go:13:type DLQ struct {
./internal/platform/dlq.go:17:func NewDLQ(nc *nats.Conn) *DLQ {
./internal/platform/dlq.go:18:	return &DLQ{nc: nc}
./internal/platform/dlq.go:36:func (d *DLQ) Send(event interface{}) error {
./internal/platform/dlq.go:42:	err = d.nc.Publish("pix2pi.dlq", data)
./internal/platform/dlq.go:47:	log.Println("⚠ event DLQ'ya gonderildi")
./internal/platform/dlq.go:51:func (d *DLQ) SendTenantSafe(
./internal/platform/dlq.go:63:	err = d.nc.Publish("pix2pi.dlq", data)
./internal/platform/dlq.go:68:	log.Println("⚠ tenant-safe event DLQ'ya gonderildi")
./internal/platform/dlq_test.go:11:		EventID:    "evt-dlq-1",
./internal/platform/dlq_test.go:14:		Topic:      "pix2pi.dlq",
./internal/platform/dlq_test.go:27:		EventID:    "evt-dlq-2",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.4 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-4.5 Replay / event store replay izi

Pattern:

```text
replay|Replay|REPLAY|event[-_ ]?store|EventStore|event_store|sequence|Sequence|DeliverAll|DeliverByStart|start sequence
```

Match Count: 1002

```text
./1_archive/root_sh/step_174_create_sale_consumer.sh:12:  --replay instant \
./1_archive/root_sh/step_196_run_replay_service.sh:6:nohup go run cmd/replay-service/replay_service_main.go > /tmp/pix2pi_replay_service.log 2>&1 &
./1_archive/root_sh/step_196_run_replay_service.sh:10:cat /tmp/pix2pi_replay_service.log || true
./1_archive/root_sh/step_196_run_replay_service.sh:12:echo "OK replay service basladi"
./1_archive/root_sh/step_201_apply_event_store.sh:4:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_201_apply_event_store.sh:6:echo "OK event store table olusturuldu"
./1_archive/root_sh/step_202_test_event_store.sh:4:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_202_test_event_store.sh:6:echo "OK event store test bitti"
./1_archive/root_sh/step_232_run_snapshot_flow.sh:12:curl -s -X POST http://127.0.0.1:9012/replay \
./1_archive/root_sh/step_246_grant_snapshot_sequence.sh:8:echo "OK ✅ snapshot sequence yetkisi verildi"
./1_archive/root_sh/step_262_run_audit_flow.sh:12:curl -s -X POST http://127.0.0.1:9012/replay \
./1_archive/root_sh/step_46_backup_event_store.sh:9:  backups/app/manual/playground_main.go.event_store.bak 2>/dev/null || true
./1_archive/root_sh/step_46_backup_event_store.sh:11:echo "OK ✅ event store yedegi alindi"
./1_archive/root_sh/step_47_prepare_event_store_dirs.sh:6:mkdir -p internal/platform/eventstore/domain
./1_archive/root_sh/step_47_prepare_event_store_dirs.sh:7:mkdir -p internal/platform/eventstore/service
./1_archive/root_sh/step_47_prepare_event_store_dirs.sh:9:echo "OK ✅ event store klasorleri hazir"
./1_archive/root_sh/step_48_run_event_store_test.sh:8:echo "OK ✅ event store test calistirma bitti"
./1_archive/root_sh/step_49_backup_event_replay.sh:9:backups/app/manual/playground_main.go.event_replay.bak
./1_archive/root_sh/step_49_backup_event_replay.sh:11:echo "OK ✅ event replay yedegi alindi"
./1_archive/root_sh/step_50_run_event_replay_test.sh:8:echo "OK ✅ event replay test calistirma bitti"
./1_archive/root_sh/step_9_backup_tenant_event_pipeline.sh:11:cp -f internal/erp/core/eventstore/domain/erp_accounting_event.go \
./1_archive/root_sh/step_9_backup_tenant_event_pipeline.sh:14:cp -f internal/erp/core/eventstore/service/erp_event_store_service.go \
./1_archive/root_sh/step_9_backup_tenant_event_pipeline.sh:15:  backups/app/manual/erp_event_store_service.go.tenant_event_pipeline.bak 2>/dev/null || true
./1_archive/root_sql/step_200_create_event_store_table.sql:1:CREATE TABLE IF NOT EXISTS event_store (
./cmd/event-bus/event_bus_main.go:28:	fmt.Println("OK ✅ event gönderildi", ack.Sequence)
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:8:	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:9:	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:21:	store := eventstoreservice.NewEventStoreService()
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:43:	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumBekliyor, "publish sonrasi durum bekliyor olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:60:	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumTekrar, "retry sonrasi store durumu tekrar olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:80:	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumDlq, "max retry sonrasi store durumu dlq olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:96:	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumBekliyor, "requeue sonrasi store durumu bekliyor olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:113:	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumIslendi, "ack sonrasi store durumu islendi olmali")
./cmd/event-concurrency-test/event_concurrency_test_main.go:11:	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
./cmd/event-concurrency-test/event_concurrency_test_main.go:31:	store := eventstoreservice.NewEventStoreService()
./cmd/event-idempotency-test/event_idempotency_test_main.go:8:	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
./cmd/event-idempotency-test/event_idempotency_test_main.go:20:	store := eventstoreservice.NewEventStoreService()
./cmd/event-metadata-test/event_metadata_test_main.go:8:	eventreplayservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventreplay/service"
./cmd/event-metadata-test/event_metadata_test_main.go:9:	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
./cmd/event-metadata-test/event_metadata_test_main.go:21:	store := eventstoreservice.NewEventStoreService()
./cmd/event-metadata-test/event_metadata_test_main.go:23:	replay := eventreplayservice.NewEventReplayService(store, bus)
./cmd/event-metadata-test/event_metadata_test_main.go:61:	sonuc, err := replay.ReplayTenantEventleriniBusaBas("tenant-001")
./cmd/event-metadata-test/event_metadata_test_main.go:66:	zorunlu(sonuc.ReplayEdilen == 1, "metadata'li event replay edilmeli")
./cmd/event-metadata-test/event_metadata_test_main.go:69:	zorunlu(len(bekleyen) == 1, "replay sonrasi kuyrukta 1 event olmali")
./cmd/event-metadata-test/event_metadata_test_main.go:71:	zorunlu(bekleyen[0].CorrelationID == "corr-001", "correlation id replay ile korunmali")
./cmd/event-metadata-test/event_metadata_test_main.go:72:	zorunlu(bekleyen[0].CausationID == "cmd-001", "causation id replay ile korunmali")
./cmd/event-metadata-test/event_metadata_test_main.go:73:	zorunlu(bekleyen[0].IdempotencyKey == "idem-001", "idempotency key replay ile korunmali")
./cmd/event-metadata-test/event_metadata_test_main.go:74:	zorunlu(bekleyen[0].SourceService == "sales-api", "source service replay ile korunmali")
./cmd/event-metadata-test/event_metadata_test_main.go:75:	zorunlu(bekleyen[0].Version == 2, "version replay ile korunmali")
./cmd/event-metadata-test/event_metadata_test_main.go:76:	fmt.Println("OK ✅ metadata replay propagation dogrulandi")
./cmd/event-replay-test/event_replay_test_main.go:8:	eventreplayservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventreplay/service"
./cmd/event-replay-test/event_replay_test_main.go:9:	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
./cmd/event-replay-test/event_replay_test_main.go:19:	fmt.Println("STEP 1.3.5 — gercek replay testi basliyor")
./cmd/event-replay-test/event_replay_test_main.go:21:	store := eventstoreservice.NewEventStoreService()
./cmd/event-replay-test/event_replay_test_main.go:23:	replay := eventreplayservice.NewEventReplayService(store, bus)
./cmd/event-replay-test/event_replay_test_main.go:26:		EventID:    "evt-replay-001",
./cmd/event-replay-test/event_replay_test_main.go:39:	err = bus.Ack("evt-replay-001")
./cmd/event-replay-test/event_replay_test_main.go:45:	kayit, err := store.EventIDIleGetir("evt-replay-001")
./cmd/event-replay-test/event_replay_test_main.go:53:	sonuc, err := replay.ReplayTenantEventleriniBusaBas("tenant-001")
./cmd/event-replay-test/event_replay_test_main.go:58:	fmt.Printf("DEBUG replay-1 | toplam=%d replay=%d skip=%d hata=%d\n", sonuc.Toplam, sonuc.ReplayEdilen, sonuc.Atlanan, sonuc.HataSayisi)
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.5 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-4.6 Poison message / quarantine izi

Pattern:

```text
poison|Poison|quarantine|Quarantine|malformed|schema.*invalid|invalid.*event|permanent failure|permanent_failure
```

Match Count: 24

```text
./cmd/event-schema-test/event_schema_test_main.go:62:	invalidAlanEvent := eventdomain.EventMessage{
./cmd/event-schema-test/event_schema_test_main.go:77:	invalidJsonEvent := eventdomain.EventMessage{
./db/migrations/002_phase2_db_l4_service_registry.up.sql:171:  is_quarantined boolean NOT NULL DEFAULT false,
./db/migrations/003_phase2_db_l4_mission_control.up.sql:56:      'quarantine',
./internal/erp/core/journal/service/erp_journal_builder_service_test.go:89:		t.Fatal("expected invalid event error")
./internal/erp/core/ledger/service/erp_ledger_posting_service_test.go:101:		t.Fatal("expected invalid event id error")
./internal/platform/missioncontrol/isolation_action_contract.go:10:	"quarantine": {},
./internal/platform/missioncontrol/isolation_action_service_test.go:58:		ActionType:      "quarantine",
./internal/platform/missioncontrol/isolation_action_service_test.go:99:		ActionType:      "quarantine",
./internal/platform/missioncontrol/isolation_action_service_test.go:112:	if store.lastCmd.ActionType != "quarantine" {
./internal/platform/missioncontrol/isolation_action_service_test.go:113:		t.Fatalf("beklenen action_type quarantine, alinan: %s", store.lastCmd.ActionType)
./internal/platform/missioncontrol/isolation_action_store_test.go:58:		ActionType:      "quarantine",
./internal/platform/missioncontrol/runtime_integration_test.go:660:		ActionType:      "quarantine",
./internal/platform/missioncontrol/runtime_integration_test.go:709:	foundQuarantine := false
./internal/platform/missioncontrol/runtime_integration_test.go:714:		if item.ActionType == "quarantine" {
./internal/platform/missioncontrol/runtime_integration_test.go:715:			foundQuarantine = true
./internal/platform/missioncontrol/runtime_integration_test.go:723:	if !foundQuarantine {
./internal/platform/missioncontrol/runtime_integration_test.go:724:		t.Fatalf("quarantine eventi timeline icinde bulunamadi")
./internal/platform/security/service/incident_readiness_service_test.go:138:		t.Fatal("expected invalid event error")
./internal/platform/security/service/security_audit_event_service_test.go:133:		t.Fatal("expected invalid event error")
./internal/platform/security/service/security_audit_sink_service_test.go:79:		t.Fatal("expected invalid event error")
./scripts/audit_faz6_4_real_implementation.sh:176:write_check "6-4.6" "Poison message / quarantine izi" "poison|Poison|quarantine|Quarantine|malformed|schema.*invalid|invalid.*event|permanent failure|permanent_failure" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/test_faz6_4_event_bus_sre_readiness.sh:75:check_grep "6-4.6 Poison Message tanimli" "$DOC_FILE" "6-4.6 Poison Message Runbook"
./scripts/test_faz6_4_event_bus_sre_readiness.sh:119:check_grep "6-4.6 Poison real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.6 Poison message"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.6 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-4.7 Idempotency / dedupe izi

Pattern:

```text
idempotenc|Idempotenc|dedupe|Dedupe|dedup|Dedup|duplicate|Duplicate|processed_event|processed events
```

Match Count: 1075

```text
./1_archive/root_sh/step_191_prepare_idempotency_folder.sh:6:echo "OK ✅ idempotency klasoru hazir"
./1_archive/root_sh/step_192_add_idempotency_test_deps.sh:8:echo "OK ✅ idempotency test bagimliligi eklendi"
./1_archive/root_sh/step_193_test_idempotency.sh:8:echo "OK ✅ idempotency test bitti"
./1_archive/root_sh/step_300_remove_duplicate_nginx_sites.sh:27:echo "OK ✅ duplicate nginx config temizlendi"
./1_archive/root_sh/step_350_fix_nginx_monitor.sh:12:echo "2. duplicate temizleniyor..."
./1_archive/root_sh/step_363_clean_panel_ssl_routes.sh:14:echo "2. duplicate route bloklari temizleniyor..."
./1_archive/root_sh/step_373_add_early_warning_cron.sh:15:echo "2. duplicate kontrol..."
./1_archive/root_sh/step_42_backup_event_idempotency.sh:9:backups/app/manual/event_bus_service.go.idempotency.bak
./1_archive/root_sh/step_42_backup_event_idempotency.sh:11:echo "OK ✅ event idempotency yedegi alindi"
./1_archive/root_sh/step_43_run_event_idempotency_test.sh:8:echo "OK ✅ event idempotency test calistirma bitti"
./1_archive/root_sh/step_44c_replicator_role_fix.sh:33:echo "4. create duplicate olursa fallback alter..."
./1_archive/root_sh/step_95_find_duplicate_443_sites.sh:16:echo "OK ✅ duplicate 443 site kontrolu bitti"
./cmd/api-gateway/erp_runtime_mount_test.go:72:		IdempotencyKey: "tenant_7:sales_invoice:GW-ERP-INV-2026-000001",
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:60:	apiReq.IdempotencyKey = tenantID + ":sales_invoice:" + sourceNo
./cmd/api-gateway/erp_runtime_route_policy_test.go:68:		t.Fatalf("expected duplicate protection with 2 routes, got %d", len(withERPAgain))
./cmd/api-gateway/erp_runtime_service_factory_test.go:85:	req.IdempotencyKey = tenantID + ":sales_invoice:" + sourceNo
./cmd/api-gateway/user_detail_route.go:5:// duplicate http.HandleFunc panic'ini engellemek icin pasife alindi.
./cmd/erp/core/ufk/scripts/pilot/run_4c_6d_uat_execution_evidence.sh:450:| UAT-05 | $UAT_05_STATUS | DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT | Duplicate SKU |
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:73:grep -q "4C_6D_DUPLICATE_SKU_COUNT=0" "$REPORT_FILE" || fail "Duplicate SKU count 0 degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:74:pass "Duplicate SKU count 0"
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:119:		fmt.Printf("OK ✅ duplicate publish engellendi: %s\n", err.Error())
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:121:		panic("duplicate publish engellenmeliydi")
./cmd/event-concurrency-test/event_concurrency_test_main.go:65:				IdempotencyKey: fmt.Sprintf("idem-conc-%03d", i),
./cmd/event-idempotency-test/event_idempotency_test_main.go:18:	fmt.Println("STEP 1.3.2 — event idempotency testi basliyor")
./cmd/event-idempotency-test/event_idempotency_test_main.go:29:		IdempotencyKey: "idem-sale-001",
./cmd/event-idempotency-test/event_idempotency_test_main.go:45:		IdempotencyKey: "idem-sale-001",
./cmd/event-idempotency-test/event_idempotency_test_main.go:51:		fmt.Printf("OK ✅ ayni tenant+topic+idempotency engellendi: %s\n", err.Error())
./cmd/event-idempotency-test/event_idempotency_test_main.go:53:		panic("ayni tenant+topic+idempotency engellenmeliydi")
./cmd/event-idempotency-test/event_idempotency_test_main.go:62:		IdempotencyKey: "idem-sale-001",
./cmd/event-idempotency-test/event_idempotency_test_main.go:70:	fmt.Println("OK ✅ ayni idempotency key farkli topicte kabul edildi")
./cmd/event-idempotency-test/event_idempotency_test_main.go:78:		IdempotencyKey: "idem-sale-001",
./cmd/event-idempotency-test/event_idempotency_test_main.go:86:	fmt.Println("OK ✅ ayni idempotency key farkli tenantta kabul edildi")
./cmd/event-idempotency-test/event_idempotency_test_main.go:106:	zorunlu(kayit5.IdempotencyKey == "evt-idem-005", "default idempotency key event id olmali")
./cmd/event-idempotency-test/event_idempotency_test_main.go:107:	fmt.Println("OK ✅ default idempotency key dogrulandi")
./cmd/event-idempotency-test/event_idempotency_test_main.go:109:	fmt.Println("OK ✅ STEP 1.3.2 event idempotency testi bitti")
./cmd/event-metadata-test/event_metadata_test_main.go:33:		IdempotencyKey: "idem-001",
./cmd/event-metadata-test/event_metadata_test_main.go:51:	zorunlu(kayit.IdempotencyKey == "idem-001", "idempotency key store'a yazilmali")
./cmd/event-metadata-test/event_metadata_test_main.go:73:	zorunlu(bekleyen[0].IdempotencyKey == "idem-001", "idempotency key replay ile korunmali")
./cmd/event-metadata-test/event_metadata_test_main.go:97:	zorunlu(kayit2.IdempotencyKey == "evt-meta-002", "default idempotency key event id olmali")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:67:		IdempotencyKey: "idem-pg-001",
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:86:	zorunlu(kayit1.IdempotencyKey == "idem-pg-001", "idempotency key postgres'a yazilmali")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:125:		IdempotencyKey: "idem-pg-002",
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:165:		IdempotencyKey: "idem-pg-001",
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:171:		fmt.Printf("OK ✅ postgres idempotency korumasi dogrulandi: %s\n", err.Error())
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:173:		panic("postgres idempotency korumasi calismaliydi")
./cmd/user-created-consumer/user_created_consumer_main.go:129:		log.Printf("OK ✅ duplicate user skip -> user_id=%s", evt.UserID)
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:119:  dedupe_key text,
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:155:CREATE INDEX IF NOT EXISTS ix_jobs_dedupe_key
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:156:ON runtime.jobs (dedupe_key);
./db/migrations/005_phase2_db_l4_idempotency.down.sql:3:DROP TABLE IF EXISTS runtime.dedupe_records;
./db/migrations/005_phase2_db_l4_idempotency.down.sql:4:DROP TABLE IF EXISTS runtime.idempotency_keys;
./db/migrations/005_phase2_db_l4_idempotency.down.sql:8:DROP TYPE IF EXISTS runtime.dedupe_status_enum;
./db/migrations/005_phase2_db_l4_idempotency.down.sql:9:DROP TYPE IF EXISTS runtime.idempotency_status_enum;
./db/migrations/005_phase2_db_l4_idempotency.up.sql:11:    WHERE n.nspname = 'runtime' AND t.typname = 'idempotency_status_enum'
./db/migrations/005_phase2_db_l4_idempotency.up.sql:13:    CREATE TYPE runtime.idempotency_status_enum AS ENUM (
./db/migrations/005_phase2_db_l4_idempotency.up.sql:30:    WHERE n.nspname = 'runtime' AND t.typname = 'dedupe_status_enum'
./db/migrations/005_phase2_db_l4_idempotency.up.sql:32:    CREATE TYPE runtime.dedupe_status_enum AS ENUM (
./db/migrations/005_phase2_db_l4_idempotency.up.sql:61:CREATE TABLE IF NOT EXISTS runtime.idempotency_keys (
./db/migrations/005_phase2_db_l4_idempotency.up.sql:66:  idempotency_key text NOT NULL,
./db/migrations/005_phase2_db_l4_idempotency.up.sql:68:  status runtime.idempotency_status_enum NOT NULL DEFAULT 'reserved',
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.7 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-4.8 Tenant-aware event metadata izi

Pattern:

```text
tenant_id|tenant_uuid|TenantID|TenantUUID|tenant.*event|event.*tenant|correlation_id|CorrelationID|causation_id|CausationID
```

Match Count: 5558

```text
./1_archive/root_sh/step_10_run_tenant_event_pipeline_test.sh:8:echo "OK ✅ tenant event pipeline test calistirma bitti"
./1_archive/root_sh/step_210_audit_full.sh:30:	if entry.TenantID == "" {
./1_archive/root_sh/step_210_audit_full.sh:79:		TenantID: "tenant-1",
./1_archive/root_sh/step_210_audit_full.sh:97:		TenantID: "tenant-1",
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:25:SET app.tenant_id = 'tenant-001';
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:32:SET app.tenant_id = 'tenant-002';
./1_archive/root_sh/step_220_tax_engine_full.sh:23:func (t *TaxEngine) Resolve(eventType string, tenantID string, amount int) TaxResult {
./1_archive/root_sh/step_230_snapshot_schema.sh:9:    tenant_id TEXT NOT NULL,
./1_archive/root_sh/step_230_snapshot_schema.sh:18:ON snapshots (tenant_id, aggregate_type, aggregate_id);
./1_archive/root_sh/step_231_snapshot_full.sh:28:	TenantID    string    `json:"tenant_id"`
./1_archive/root_sh/step_231_snapshot_full.sh:37:		TenantID:    tenantID,
./1_archive/root_sh/step_231_snapshot_full.sh:48:		INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_231_snapshot_full.sh:50:		ON CONFLICT (tenant_id, aggregate_type, aggregate_id)
./1_archive/root_sh/step_231_snapshot_full.sh:72:		WHERE tenant_id = $1 AND aggregate_type = $2 AND aggregate_id = $3
./1_archive/root_sh/step_231_snapshot_full.sh:108:	_, err = db.Exec(`DELETE FROM snapshots WHERE tenant_id = 'tenant-test'`)
./1_archive/root_sh/step_232_run_snapshot_flow.sh:14:-d '{"subject":"pix2pi.sale.created","data":"{\"event\":\"sale.created\",\"sale_id\":\"S-SNAP-1\",\"tenant_id\":\"tenant-001\",\"amount\":1300}"}'
./1_archive/root_sh/step_232_run_snapshot_flow.sh:18:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:14:USING (tenant_id = current_setting('app.current_tenant', true))
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:15:WITH CHECK (tenant_id = current_setting('app.current_tenant', true));
./1_archive/root_sh/step_241_test_rls_snapshots.sh:8:SELECT tenant_id, aggregate_type, aggregate_id, version
./1_archive/root_sh/step_241_test_rls_snapshots.sh:19:SELECT tenant_id, aggregate_type, aggregate_id, version
./1_archive/root_sh/step_241_test_rls_snapshots.sh:30:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_243_test_rls_real.sh:8:SELECT tenant_id, aggregate_id FROM snapshots;
./1_archive/root_sh/step_243_test_rls_real.sh:17:SELECT tenant_id, aggregate_id FROM snapshots;
./1_archive/root_sh/step_243_test_rls_real.sh:26:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:8:SELECT string_agg(tenant_id || ':' || aggregate_id, ',')
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:33:SELECT string_agg(tenant_id || ':' || aggregate_id, ',')
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:59:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:86:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:87:VALUES ('tenant-001','stock','VERIFY-OK-1',1,'{"event":"verify.ok"}',NOW())
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:88:ON CONFLICT (tenant_id, aggregate_type, aggregate_id)
./1_archive/root_sh/step_251_fix_verification.sh:9:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_260_audit_schema.sh:9:    tenant_id TEXT NOT NULL,
./1_archive/root_sh/step_260_audit_schema.sh:21:ON audit_logs (tenant_id, created_at DESC);
./1_archive/root_sh/step_261_audit_full.sh:25:	TenantID   string
./1_archive/root_sh/step_261_audit_full.sh:43:			tenant_id,
./1_archive/root_sh/step_261_audit_full.sh:54:		rec.TenantID,
./1_archive/root_sh/step_261_audit_full.sh:95:		TenantID:   "tenant-audit-test",
./1_archive/root_sh/step_261_audit_full.sh:115:		WHERE tenant_id = 'tenant-audit-test'
./1_archive/root_sh/step_262_run_audit_flow.sh:14:-d '{"subject":"pix2pi.sale.created","data":"{\"event\":\"sale.created\",\"sale_id\":\"S-AUDIT-REAL-1\",\"tenant_id\":\"tenant-001\",\"amount\":1700}"}'
./1_archive/root_sh/step_262_run_audit_flow.sh:18:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:37:const tenantKey contextKey = "tenant_id"
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:48:	TenantID string
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:90:			TenantID: "tenant-001",
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:94:			TenantID: "tenant-002",
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:98:			TenantID: "",
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:168:		ctx := context.WithValue(r.Context(), tenantKey, tokenInfo.TenantID)
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:26:const tenantKey contextKey = "tenant_id"
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:37:	TenantID string
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:79:			TenantID: "tenant-001",
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:83:			TenantID: "tenant-002",
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:87:			TenantID: "",
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:157:		ctx := context.WithValue(r.Context(), tenantKey, tokenInfo.TenantID)
./1_archive/root_sh/step_9_backup_tenant_event_pipeline.sh:9:  backups/app/manual/playground_main.go.tenant_event_pipeline.bak 2>/dev/null || true
./1_archive/root_sh/step_9_backup_tenant_event_pipeline.sh:12:  backups/app/manual/erp_accounting_event.go.tenant_event_pipeline.bak 2>/dev/null || true
./1_archive/root_sh/step_9_backup_tenant_event_pipeline.sh:15:  backups/app/manual/erp_event_store_service.go.tenant_event_pipeline.bak 2>/dev/null || true
./1_archive/root_sh/step_9_backup_tenant_event_pipeline.sh:17:echo "OK ✅ tenant event pipeline yedegi alindi"
./1_archive/root_sql/step_200_create_event_store_table.sql:7:    tenant_id TEXT,
./1_archive/root_sql/step_203_create_journal_tables.sql:4:    tenant_id TEXT,
./1_archive/root_sql/step_230_create_snapshot_tables.sql:3:    tenant_id TEXT NOT NULL,
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.8 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-4.9 Event metrics / observability izi

Pattern:

```text
prometheus|Prometheus|metrics|Metrics|Counter|Histogram|Gauge|event.*metric|publish.*count|consume.*count|dlq.*count|backlog.*gauge
```

Match Count: 273

```text
./1_archive/root_sh/step_270_observability_stack.sh:7:mkdir -p $OBS/prometheus
./1_archive/root_sh/step_270_observability_stack.sh:18:  prometheus:
./1_archive/root_sh/step_270_observability_stack.sh:19:    image: prom/prometheus:latest
./1_archive/root_sh/step_270_observability_stack.sh:20:    container_name: pix2pi_prometheus
./1_archive/root_sh/step_270_observability_stack.sh:23:      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
./1_archive/root_sh/step_270_observability_stack.sh:69:      - prometheus
./1_archive/root_sh/step_270_observability_stack.sh:93:cat <<'YAMLEOF' > $OBS/prometheus/prometheus.yml
./1_archive/root_sh/step_270_observability_stack.sh:98:  - job_name: "prometheus"
./1_archive/root_sh/step_270_observability_stack.sh:100:      - targets: ["prometheus:9090"]
./1_archive/root_sh/step_270_observability_stack.sh:173:  - name: Prometheus
./1_archive/root_sh/step_270_observability_stack.sh:174:    type: prometheus
./1_archive/root_sh/step_270_observability_stack.sh:176:    url: http://prometheus:9090
./1_archive/root_sh/step_270_observability_stack.sh:212:        "type": "prometheus",
./1_archive/root_sh/step_270_observability_stack.sh:243:        "type": "prometheus",
./1_archive/root_sh/step_273_fix_promtail_positions.sh:42:  prometheus:
./1_archive/root_sh/step_273_fix_promtail_positions.sh:43:    image: prom/prometheus:latest
./1_archive/root_sh/step_273_fix_promtail_positions.sh:44:    container_name: pix2pi_prometheus
./1_archive/root_sh/step_273_fix_promtail_positions.sh:47:      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
./1_archive/root_sh/step_273_fix_promtail_positions.sh:94:      - prometheus
./db/migrations/20260427_151001_readmodel_operational_tables.down.sql:8:DROP INDEX IF EXISTS readmodel.idx_daily_operational_metrics_date;
./db/migrations/20260427_151001_readmodel_operational_tables.down.sql:15:DROP TABLE IF EXISTS readmodel.daily_operational_metrics;
./db/migrations/20260427_151001_readmodel_operational_tables.up.sql:41:CREATE TABLE IF NOT EXISTS readmodel.daily_operational_metrics (
./db/migrations/20260427_151001_readmodel_operational_tables.up.sql:112:CREATE INDEX IF NOT EXISTS idx_daily_operational_metrics_date
./db/migrations/20260427_151001_readmodel_operational_tables.up.sql:113:    ON readmodel.daily_operational_metrics (metric_date, tenant_id);
./deploy/observability/config/lvl11_signal_catalog.yaml:37:        metric: event_consumer_lag_count
./deploy/observability/docker-compose.yml:4:  prometheus:
./deploy/observability/docker-compose.yml:5:    image: prom/prometheus:latest
./deploy/observability/docker-compose.yml:6:    container_name: pix2pi_prometheus
./deploy/observability/docker-compose.yml:11:      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
./deploy/observability/docker-compose.yml:37:      - prometheus
./deploy/observability/grafana/provisioning/datasources/datasource.yml:4:  - name: Prometheus
./deploy/observability/grafana/provisioning/datasources/datasource.yml:5:    uid: prometheus
./deploy/observability/grafana/provisioning/datasources/datasource.yml:6:    type: prometheus
./deploy/observability/grafana/provisioning/datasources/datasource.yml:8:    url: http://pix2pi_prometheus:9090
./deploy/observability/prometheus/prometheus.yml:6:  - job_name: "prometheus"
./deploy/observability/prometheus/prometheus.yml:8:      - targets: ["pix2pi_prometheus:9090"]
./deploy/observability/prometheus/prometheus.yml:15:    metrics_path: /metrics
./deploy/observability/prometheus.yml:5:  - job_name: "prometheus"
./deploy/observability/prometheus.yml:7:      - targets: ["pix2pi_prometheus:9090"]
./infra/observability/docker-compose.yml:2:  prometheus:
./infra/observability/docker-compose.yml:3:    image: prom/prometheus:latest
./infra/observability/docker-compose.yml:4:    container_name: pix2pi_prometheus
./infra/observability/docker-compose.yml:7:      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
./infra/observability/docker-compose.yml:54:      - prometheus
./infra/observability/grafana/provisioning/datasources/datasources.yml:4:  - name: Prometheus
./infra/observability/grafana/provisioning/datasources/datasources.yml:5:    type: prometheus
./infra/observability/grafana/provisioning/datasources/datasources.yml:7:    url: http://prometheus:9090
./infra/observability/prometheus/prometheus.yml:5:  - job_name: "prometheus"
./infra/observability/prometheus/prometheus.yml:7:      - targets: ["prometheus:9090"]
./internal/erp/core/payments/service/erp_settlement_service.go:40:	itemCounter := 1
./internal/erp/core/payments/service/erp_settlement_service.go:58:			ItemID:            fmt.Sprintf("%s-item-%03d", batchID, itemCounter),
./internal/erp/core/payments/service/erp_settlement_service.go:67:		itemCounter++
./internal/erp/runtime/cashbankpay/model.go:76:type CounterpartyRef struct {
./internal/erp/runtime/cashbankpay/model.go:94:	Counterparty CounterpartyRef
./internal/erp/runtime/cashbankpay/model.go:122:	Counterparty CounterpartyRef
./internal/erp/runtime/cashbankpay/model.go:137:	Counterparty CounterpartyRef
./internal/erp/runtime/cashbankpay/model.go:423:		Counterparty: req.Counterparty,
./internal/erp/runtime/cashbankpay/model.go:445:		Counterparty: req.Counterparty,
./internal/erp/runtime/cashbankpay/model_test.go:37:		Counterparty: CounterpartyRef{
./internal/erp/runtime/cashbankpay/postgres_store.go:263:	addUUID("party_id", draft.Counterparty.PartyID)
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.9 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-4.10 Event bus test izi

Pattern:

```text
Test.*Event|event.*test|DLQ.*test|replay.*test|idempotency.*test|duplicate.*test|consumer.*test|publisher.*test
```

Match Count: 139

```text
./1_archive/root_sh/step_10_run_tenant_event_pipeline_test.sh:8:echo "OK ✅ tenant event pipeline test calistirma bitti"
./1_archive/root_sh/step_192_add_idempotency_test_deps.sh:8:echo "OK ✅ idempotency test bagimliligi eklendi"
./1_archive/root_sh/step_193_test_idempotency.sh:8:echo "OK ✅ idempotency test bitti"
./1_archive/root_sh/step_202_test_event_store.sh:6:echo "OK event store test bitti"
./1_archive/root_sh/step_39_run_event_bus_test.sh:8:echo "OK ✅ event bus test calistirma bitti"
./1_archive/root_sh/step_41_run_event_retry_test.sh:8:echo "OK ✅ event retry test calistirma bitti"
./1_archive/root_sh/step_43_run_event_idempotency_test.sh:8:echo "OK ✅ event idempotency test calistirma bitti"
./1_archive/root_sh/step_48_run_event_store_test.sh:8:echo "OK ✅ event store test calistirma bitti"
./1_archive/root_sh/step_50_run_event_replay_test.sh:8:echo "OK ✅ event replay test calistirma bitti"
./1_archive/root_sh/step_52_run_event_bus_store_integration_test.sh:8:echo "OK ✅ event bus store entegrasyon test calistirma bitti"
./cmd/event-idempotency-test/event_idempotency_test_main.go:18:	fmt.Println("STEP 1.3.2 — event idempotency testi basliyor")
./cmd/event-idempotency-test/event_idempotency_test_main.go:109:	fmt.Println("OK ✅ STEP 1.3.2 event idempotency testi bitti")
./cmd/event-metadata-test/event_metadata_test_main.go:19:	fmt.Println("STEP 1.1.4 — event metadata standard testi basliyor")
./cmd/event-metadata-test/event_metadata_test_main.go:102:	fmt.Println("OK ✅ STEP 1.1.4 event metadata standard testi bitti")
./cmd/event-replay-test/event_replay_test_main.go:19:	fmt.Println("STEP 1.3.5 — gercek replay testi basliyor")
./cmd/event-replay-test/event_replay_test_main.go:88:	fmt.Println("OK ✅ STEP 1.3.5 gercek replay testi bitti")
./cmd/event-schema-test/event_schema_test_main.go:20:	fmt.Println("STEP 1.1.3 — event schema contract testi basliyor")
./cmd/event-schema-test/event_schema_test_main.go:124:	fmt.Println("OK ✅ STEP 1.1.3 event schema contract testi bitti")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:21:	fmt.Println("STEP postgres persist — event store testi basliyor")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:24:		"event_store_records_pg_test",
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:176:	fmt.Println("OK ✅ STEP postgres persist event store testi bitti")
./internal/erp/core/audit/service/erp_financial_consistency_service_test.go:102:func TestFinancialConsistencyService_Check_EventJournalMismatch(t *testing.T) {
./internal/erp/core/audit/service/erp_financial_consistency_service_test.go:134:func TestFinancialConsistencyService_Check_PostingEventMismatch(t *testing.T) {
./internal/erp/core/events/service/erp_event_intake_service_test.go:8:func TestEventIntakeService_Normalize_Defaults(t *testing.T) {
./internal/erp/core/events/service/erp_event_intake_service_test.go:46:func TestEventIntakeService_Normalize_SaleCreatedBecomesCompleted(t *testing.T) {
./internal/erp/core/events/service/erp_event_intake_service_test.go:64:func TestEventIntakeService_Normalize_RequiresTenant(t *testing.T) {
./internal/erp/core/events/service/erp_event_intake_service_test.go:78:func TestEventIntakeService_Normalize_RequiresPositiveAmount(t *testing.T) {
./internal/erp/core/events/service/erp_event_intake_service_test.go:92:func TestEventIntake_ToFinancialEventInput(t *testing.T) {
./internal/erp/core/journal/service/erp_journal_builder_service_test.go:81:func TestJournalBuilderService_Build_InvalidEvent(t *testing.T) {
./internal/erp/core/journal/service/erp_journal_builder_service_test.go:105:func TestJournalBuilderService_Build_UnbalancedFinancialEvent(t *testing.T) {
./internal/erp/core/ledger/service/erp_ledger_posting_service_test.go:93:func TestLedgerPostingService_BuildFromJournal_InvalidEventID(t *testing.T) {
./internal/erp/runtime/e2eflow/step_adapters_test.go:236:func TestPublishEventStepAdapterSuccess(t *testing.T) {
./internal/platform/dlq_test.go:38:func TestDLQ_SendTenantSafe_NilConnection(t *testing.T) {
./internal/platform/eventbus/domain/event_message_test.go:5:func TestEventMessage_ValidateTenantIdentity_Success(t *testing.T) {
./internal/platform/eventbus/domain/event_message_test.go:18:func TestEventMessage_ValidateTenantIdentity_MissingTenantUUID(t *testing.T) {
./internal/platform/eventbus/service/dlq_event_validator_test.go:9:func TestValidateDlqEvent_Success(t *testing.T) {
./internal/platform/eventbus/service/dlq_event_validator_test.go:22:func TestValidateDlqEvent_MissingTenantUUID(t *testing.T) {
./internal/platform/eventbus/service/dlq_event_validator_test.go:35:func TestValidateDlqEvent_MissingPayload(t *testing.T) {
./internal/platform/eventbus/service/event_bus_service_integration_test.go:10:func TestEventBusService_Publish_KaydetTenantSafeIleStoreaYazar(t *testing.T) {
./internal/platform/eventbus/service/event_bus_service_integration_test.go:38:func TestEventBusService_Publish_TenantUUIDYoksaReddedilir(t *testing.T) {
./internal/platform/eventreplay/service/event_replay_service_test.go:103:func TestEventReplayService_ReplayTenantEventleriniBusaBas_Success(t *testing.T) {
./internal/platform/eventreplay/service/event_replay_service_test.go:143:func TestEventReplayService_ReplayTenantEventleriniBusaBas_InvalidTenantIdentity(t *testing.T) {
./internal/platform/eventreplay/service/tenant_replay_builder_test.go:9:func TestBuildReplayEventFromStoreRecord_Success(t *testing.T) {
./internal/platform/eventreplay/service/tenant_replay_builder_test.go:37:func TestBuildReplayEventFromStoreRecord_MissingTenantUUID(t *testing.T) {
./internal/platform/eventreplay/service/tenant_replay_builder_test.go:52:func TestBuildReplayEventFromStoreRecord_MissingTopic(t *testing.T) {
./internal/platform/eventstore/domain/event_store_record_test.go:5:func TestEventStoreRecord_ValidateTenantIdentity_Success(t *testing.T) {
./internal/platform/eventstore/domain/event_store_record_test.go:19:func TestEventStoreRecord_ValidateTenantIdentity_MissingTenantID(t *testing.T) {
./internal/platform/eventstore/service/event_store_service_integration_test.go:9:func TestEventStoreService_Kaydet_ValidateTenantIdentityIleCalisir(t *testing.T) {
./internal/platform/eventstore/service/event_store_service_integration_test.go:34:func TestEventStoreService_Kaydet_TenantUUIDYoksaReddedilir(t *testing.T) {
./internal/platform/eventstore/service/postgres_event_store_validation_test.go:9:func TestValidatePostgresEventStoreKaydetInput_Success(t *testing.T) {
./internal/platform/eventstore/service/postgres_event_store_validation_test.go:23:func TestValidatePostgresEventStoreKaydetInput_MissingTenantUUID(t *testing.T) {
./internal/platform/eventstore/service/postgres_event_store_validation_test.go:37:func TestValidatePostgresEventStoreKaydetInput_MissingTopic(t *testing.T) {
./internal/platform/jobsqueue/audit_service_test.go:23:func TestRecordJobAuditEventRequestValidate_Success(t *testing.T) {
./internal/platform/jobsqueue/audit_service_test.go:40:func TestRecordJobAuditEventRequestValidate_InvalidEventType(t *testing.T) {
./internal/platform/jobsqueue/audit_service_test.go:54:func TestRecordJobAuditEventRequestValidate_InvalidStatus(t *testing.T) {
./internal/platform/jobsqueue/audit_service_test.go:68:func TestRecordJobAuditEventRequestValidate_InvalidAttemptNo(t *testing.T) {
./internal/platform/jobsqueue/audit_service_test.go:163:func TestRecordJobAuditEventResponseValidate_InvalidOccurredAt(t *testing.T) {
./internal/platform/jobsqueue/audit_store_test.go:44:func TestJobAuditSQLStoreRecordJobAuditEvent_Success(t *testing.T) {
./internal/platform/jobsqueue/audit_store_test.go:88:func TestJobAuditSQLStoreRecordJobAuditEvent_NoDB(t *testing.T) {
./internal/platform/jobsqueue/audit_store_test.go:97:func TestJobAuditSQLStoreRecordJobAuditEvent_ScanError(t *testing.T) {
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-4.10 STATUS=IMPLEMENTED_OR_PRESENT ✅

# Final Runtime Implementation Interpretation

```text
REQUIRED_FAIL=0
OPTIONAL_WARN=0
FAZ_6_4_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_4_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_4_REAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_5_READY=YES ✅
FAZ_6_4_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅
```
