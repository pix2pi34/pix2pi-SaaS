# FAZ 6-10 Real Implementation Audit

Generated At: 2026-05-01T15:52:53+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit, FAZ 6-10 CDN / WAF / DNS / Edge maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

## Scanned Files

```text
3031 /tmp/tmp.Ay20M02Ao6/files.txt

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

## 6-10.1 DNS readiness implementation izi

Pattern:

```text
dig|DNS|dns|CNAME|AAAA|TTL|getent hosts|pix2pi_edge_dns_probe|PIX2PI_DOMAIN|SUBDOMAINS
```

Match Count: 704

```text
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:39:redis-cli TTL tenant:tenant-redis-001:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:43:redis-cli TTL tenant:tenant-redis-002:gateway:rate_limit || true
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:99:echo "=== TEST 5: tenant-001 yazdigi kaydi gorebilmeli ==="
./1_archive/root_sh/step_82_fix_dns_resolver.sh:9:echo "OK ✅ DNS resolver duzeltildi"
./1_archive/root_sh/step_89_test_server_ssl.sh:4:echo "=== SERVER DNS ==="
./1_archive/root_sh/step_89_test_server_ssl.sh:5:dig server.pix2pi.com.tr +short
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2526:      "integrity": "sha512-hsBTNUqQTDwkWtcdYI2i06Y/nUBEsNEDJKjWdigLvegy8kDuJAS8uRlpkkcQpyEXL0Z/pjDy5HBmMjRCJ2gq+g==",
./cmd/api-gateway/api_gateway_main_test.go:436:		t.Fatalf("rate limit asildiginda next cagrilmamali")
./cmd/api-gateway/api_gateway_main_test.go:494:		t.Fatalf("quota asildiginda next cagrilmamali")
./cmd/cache-pattern-clean-test/cache_pattern_clean_test_main.go:95:	fmt.Println("OK ✅ diger namespace'ler korunuyor")
./cmd/cache-service/cache_service_main.go:30:	TTLSeconds int    `json:"ttl_seconds"`
./cmd/cache-service/cache_service_main.go:97:		ttlSeconds := int(cacheSvc.DefaultTTL().Seconds())
./cmd/cache-service/cache_service_main.go:138:			TTLSeconds: ttlSeconds,
./cmd/policy-cache-hybrid-test/policy_cache_hybrid_test_main.go:43:	kernel.SetPolicyCacheTTL(120 * time.Second)
./deploy/edge/scripts/lvl10_ops_validation.sh:104:    if getent hosts "${domain}" >/dev/null 2>&1; then
./deploy/edge/scripts/lvl10_ops_validation.sh:105:      echo "OK ✅ dns resolve: ${domain}"
./deploy/edge/scripts/lvl10_ops_validation.sh:107:      echo "HATA ❌ dns resolve: ${domain}"
./deploy/erp-tr/scripts/render_lvl13_payment_closure.sh:35:  PAYMENT_BANK_SETTLEMENT_MODE
./deploy/erp-tr/scripts/render_lvl13_payment_closure.sh:62:  bank_settlement_mode: ${PAYMENT_BANK_SETTLEMENT_MODE}
./deploy/erp-tr/scripts/render_lvl13_payment_closure.sh:74:  -e "s|__PAYMENT_BANK_SETTLEMENT_MODE__|${PAYMENT_BANK_SETTLEMENT_MODE}|g" \
./deploy/erp-tr/scripts/render_lvl13_payment_closure.sh:94:- Bank settlement mode: ${PAYMENT_BANK_SETTLEMENT_MODE}
./deploy/observability/scripts/render_lvl11_correlation_scale.sh:31:  DB_BOTTLENECK_WARN_MS
./deploy/observability/scripts/render_lvl11_correlation_scale.sh:32:  DB_BOTTLENECK_CRIT_MS
./deploy/observability/scripts/render_lvl11_correlation_scale.sh:53:  -e "s|__DB_BOTTLENECK_WARN_MS__|${DB_BOTTLENECK_WARN_MS}|g" \
./deploy/observability/scripts/render_lvl11_correlation_scale.sh:54:  -e "s|__DB_BOTTLENECK_CRIT_MS__|${DB_BOTTLENECK_CRIT_MS}|g" \
./deploy/observability/scripts/render_lvl11_correlation_scale.sh:78:- DB bottleneck: warn=${DB_BOTTLENECK_WARN_MS}ms crit=${DB_BOTTLENECK_CRIT_MS}ms
./deploy/platform/scripts/render_lvl12_jobs_notifications.sh:40:  JOB_IDEMPOTENCY_TTL_SECONDS
./deploy/platform/scripts/render_lvl12_jobs_notifications.sh:64:  -e "s|__JOB_IDEMPOTENCY_TTL_SECONDS__|${JOB_IDEMPOTENCY_TTL_SECONDS}|g" \
./deploy/platform/scripts/render_lvl12_jobs_notifications.sh:82:- Idempotency TTL: ${JOB_IDEMPOTENCY_TTL_SECONDS} sec
./deploy/platform/scripts/render_lvl12_registry_mission_control.sh:38:  REGISTRY_HEALTH_TTL_SECONDS
./deploy/platform/scripts/render_lvl12_registry_mission_control.sh:57:  -e "s|__REGISTRY_HEALTH_TTL_SECONDS__|${REGISTRY_HEALTH_TTL_SECONDS}|g" \
./deploy/platform/scripts/render_lvl12_registry_mission_control.sh:71:- Health TTL: ${REGISTRY_HEALTH_TTL_SECONDS} sec
./internal/platform/cache/service/redis_cache_service.go:29:	DefaultTTL   time.Duration
./internal/platform/cache/service/redis_cache_service.go:47:		DefaultTTL:   5 * time.Minute,
./internal/platform/cache/service/redis_cache_service.go:99:	if cfg.DefaultTTL <= 0 {
./internal/platform/cache/service/redis_cache_service.go:100:		cfg.DefaultTTL = def.DefaultTTL
./internal/platform/cache/service/redis_cache_service.go:158:		DefaultTTL:   envSecondsOrDefault("REDIS_DEFAULT_TTL_SECONDS", def.DefaultTTL),
./internal/platform/cache/service/redis_cache_service.go:183:func (s *RedisCacheService) DefaultTTL() time.Duration {
./internal/platform/cache/service/redis_cache_service.go:184:	return s.cfg.DefaultTTL
./internal/platform/cache/service/redis_cache_service.go:265:		ttl = s.cfg.DefaultTTL
./internal/platform/cache/service/redis_cache_service.go:378:func (s *RedisCacheService) TTLGetir(
./internal/platform/cache/service/redis_cache_service.go:392:	ttl, err := s.client.TTL(s.ctx, cacheKey).Result()
./internal/platform/cache/service/redis_cache_service.go:443:func (s *RedisCacheService) IncrWithTTLOnFirst(
./internal/platform/cache/service/redis_cache_service.go:459:		ttl = s.cfg.DefaultTTL
./internal/platform/gateway/service/quota_service.go:117:	kullanilan, err := s.redisSvc.IncrWithTTLOnFirst(
./internal/platform/gateway/service/rate_limit_service.go:117:	kullanilan, err := s.redisSvc.IncrWithTTLOnFirst(
./internal/platform/idempotency/dedupe_reserve_contract.go:22:	TTLSeconds  int    `json:"ttl_seconds"`
./internal/platform/idempotency/dedupe_reserve_contract.go:61:	if r.TTLSeconds < 60 || r.TTLSeconds > 604800 {
./internal/platform/idempotency/dedupe_reserve_service.go:17:	TTLSeconds  int
./internal/platform/idempotency/dedupe_reserve_service.go:66:		TTLSeconds:  req.TTLSeconds,
./internal/platform/idempotency/dedupe_reserve_service.go:85:		t := now.Add(time.Duration(req.TTLSeconds) * time.Second)
./internal/platform/idempotency/dedupe_reserve_service_test.go:29:		TTLSeconds:  300,
./internal/platform/idempotency/dedupe_reserve_service_test.go:43:		TTLSeconds:  300,
./internal/platform/idempotency/dedupe_reserve_service_test.go:52:func TestReserveDedupeRecordRequestValidate_InvalidTTL(t *testing.T) {
./internal/platform/idempotency/dedupe_reserve_service_test.go:57:		TTLSeconds:  10,
./internal/platform/idempotency/dedupe_reserve_service_test.go:71:		TTLSeconds:  300,
./internal/platform/idempotency/dedupe_reserve_service_test.go:101:		TTLSeconds:  300,
./internal/platform/idempotency/dedupe_reserve_service_test.go:151:		TTLSeconds:  300,
./internal/platform/idempotency/dedupe_reserve_service_test.go:175:		TTLSeconds:  300,
./internal/platform/idempotency/dedupe_reserve_service_test.go:197:		TTLSeconds:  300,
./internal/platform/idempotency/dedupe_reserve_store.go:94:		cmd.TTLSeconds,
./internal/platform/idempotency/dedupe_reserve_store_test.go:63:		TTLSeconds:  300,
./internal/platform/idempotency/dedupe_reserve_store_test.go:115:		TTLSeconds:  300,
./internal/platform/idempotency/dedupe_reserve_store_test.go:147:		TTLSeconds:  300,
./internal/platform/idempotency/dedupe_reserve_store_test.go:182:		TTLSeconds:  300,
./internal/platform/idempotency/reserve_contract.go:52:	TTLSeconds     int    `json:"ttl_seconds"`
./internal/platform/idempotency/reserve_contract.go:91:	if r.TTLSeconds < 60 || r.TTLSeconds > 604800 {
./internal/platform/idempotency/reserve_service.go:17:	TTLSeconds     int
./internal/platform/idempotency/reserve_service.go:66:		TTLSeconds:     req.TTLSeconds,
./internal/platform/idempotency/reserve_service.go:85:		t := now.Add(time.Duration(req.TTLSeconds) * time.Second)
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-10.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-10.2 TLS / HTTPS implementation izi

Pattern:

```text
https://|openssl s_client|ssl_certificate|TLS|HTTPS|Strict-Transport|HSTS|443|certificate|cert
```

Match Count: 4495

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:30:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_certbot_acme.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:34:        return 301 https://$host$request_uri;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:39:    listen 443 ssl http2;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:42:    ssl_certificate     /etc/letsencrypt/live/api.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:43:    ssl_certificate_key /etc/letsencrypt/live/api.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:72:    listen 443 ssl http2;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:75:    ssl_certificate     /etc/letsencrypt/live/api.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:76:    ssl_certificate_key /etc/letsencrypt/live/api.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:98:    listen 443 ssl http2;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:101:    ssl_certificate     /etc/letsencrypt/live/api.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:102:    ssl_certificate_key /etc/letsencrypt/live/api.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:131:    listen 443 ssl http2;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:134:    ssl_certificate     /etc/letsencrypt/live/api.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:135:    ssl_certificate_key /etc/letsencrypt/live/api.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:30:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_certbot_acme.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:34:        return 301 https://$host$request_uri;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:39:    listen 443 ssl http2;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:42:    ssl_certificate     /etc/letsencrypt/live/api.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:43:    ssl_certificate_key /etc/letsencrypt/live/api.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:72:    listen 443 ssl http2;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:75:    ssl_certificate     /etc/letsencrypt/live/panel.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:76:    ssl_certificate_key /etc/letsencrypt/live/panel.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:98:    listen 443 ssl http2;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:101:    ssl_certificate     /etc/letsencrypt/live/auth.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:102:    ssl_certificate_key /etc/letsencrypt/live/auth.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:131:    listen 443 ssl http2;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:134:    ssl_certificate     /etc/letsencrypt/live/pos.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:135:    ssl_certificate_key /etc/letsencrypt/live/pos.pix2pi.com.tr/privkey.pem;
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh:17:curl -s https://api.pix2pi.com.tr/api/identity/health || true
./1_archive/root_sh/step_107_test_api_gateway_rate_limit.sh:4:URL="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:4:URL="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:4:URL="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_124_test_auth_via_gateway.sh:4:curl -i -H "X-Tenant-ID: tenant-auth-test" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:5:curl -s -i https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:10:curl -s -i -H "X-Tenant-ID: tenant-combined-identity" https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:15:curl -s -i https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:20:curl -s -i -H "X-Tenant-ID: tenant-combined-auth" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_129_test_scope_separation.sh:5:curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_129_test_scope_separation.sh:10:curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:4:URL_IDENTITY="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:5:URL_AUTH="https://api.pix2pi.com.tr/api/auth/health"
./1_archive/root_sh/step_134_check_503_source.sh:21:curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/auth/health || true
./1_archive/root_sh/step_134_check_503_source.sh:25:curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/identity/health || true
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:46:      <li><a href="https://server.pix2pi.com.tr/containers/">Server Monitor</a></li>
./1_archive/root_sh/step_188_verify_done_items.sh:148:if curl -k -s --max-time 5 https://panel.pix2pi.com.tr >/dev/null 2>&1; then
./1_archive/root_sh/step_188_verify_done_items.sh:154:if curl -k -s --max-time 5 https://api.pix2pi.com.tr >/dev/null 2>&1; then
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:70:      <li><a href="https://server.pix2pi.com.tr/containers/">Server Monitor</a></li>
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:77:      <li><a href="https://server.pix2pi.com.tr/containers/">Server Monitor</a></li>
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:9:    listen 443 ssl;
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:12:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:13:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:15:    ssl_protocols TLSv1.2 TLSv1.3;
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:58:    listen 443 ssl;
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:61:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:62:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:64:    ssl_protocols TLSv1.2 TLSv1.3;
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:67:        return 301 https://server.pix2pi.com.tr/containers/;
./1_archive/root_sh/step_308_hard_restart_nginx.sh:15:ss -ltnp | grep -E '8002|8007|8080|443|80' || true
./1_archive/root_sh/step_308_hard_restart_nginx.sh:28:ss -ltnp | grep -E '8002|8007|8080|443|80' || true
./1_archive/root_sh/step_320_rewrite_panel_index.sh:304:        <li><a href="https://server.pix2pi.com.tr/containers/" target="_blank">Server Monitor</a></li>
./1_archive/root_sh/step_350_fix_nginx_monitor.sh:51:curl -I https://pix2pi.com.tr/monitor
./1_archive/root_sh/step_351_clean_nginx_duplicates_and_fix_monitor.sh:31:start_marker = "server {\n    listen 443 ssl;\n    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;"
./1_archive/root_sh/step_351_clean_nginx_duplicates_and_fix_monitor.sh:53:insert_after = '    ssl_protocols TLSv1.2 TLSv1.3;\n'
./1_archive/root_sh/step_351_clean_nginx_duplicates_and_fix_monitor.sh:100:curl -k -I https://127.0.0.1/monitor || true
./1_archive/root_sh/step_352_force_monitor_from_static_root.sh:44:    listen 443 ssl;
./1_archive/root_sh/step_352_force_monitor_from_static_root.sh:67:insert_after = """    ssl_protocols TLSv1.2 TLSv1.3;
./1_archive/root_sh/step_352_force_monitor_from_static_root.sh:91:curl -k -I https://127.0.0.1/monitor || true
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:477:curl -k -I https://127.0.0.1/monitor || true
./1_archive/root_sh/step_356_fix_monitor_json_compat.sh:79:curl -k -I https://127.0.0.1/monitor
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:371:curl -k -I https://127.0.0.1/monitor || true
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-10.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-10.3 CDN / cache implementation izi

Pattern:

```text
CDN|cdn|Cache-Control|CF-Cache-Status|cf-cache-status|Cloudflare|cloudflare|cache|purge|static asset
```

Match Count: 939

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:49:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:82:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:108:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:141:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:49:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:82:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:108:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:141:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./1_archive/root_sh/step_14_prepare_cache_dir.sh:6:mkdir -p internal/platform/cache/service
./1_archive/root_sh/step_14_prepare_cache_dir.sh:8:echo "OK ✅ cache klasoru hazir"
./1_archive/root_sh/step_188_prepare_cache_service_folder.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/cmd/cache-service
./1_archive/root_sh/step_188_prepare_cache_service_folder.sh:6:echo "OK ✅ cache-service klasoru hazir"
./1_archive/root_sh/step_189_run_cache_service.sh:6:nohup go run cmd/cache-service/cache_service_main.go >/tmp/pix2pi_cache_service.log 2>&1 &
./1_archive/root_sh/step_189_run_cache_service.sh:10:cat /tmp/pix2pi_cache_service.log || true
./1_archive/root_sh/step_189_run_cache_service.sh:12:echo "OK ✅ cache service baslatildi"
./1_archive/root_sh/step_190_test_cache_service.sh:10:curl -s "http://127.0.0.1:9011/cache/set?key=urun:1001&value=1250"
./1_archive/root_sh/step_190_test_cache_service.sh:15:curl -s "http://127.0.0.1:9011/cache/get?key=urun:1001"
./1_archive/root_sh/step_190_test_cache_service.sh:20:cat /tmp/pix2pi_cache_service.log || true
./1_archive/root_sh/step_190_test_cache_service.sh:23:echo "OK ✅ cache service test bitti"
./1_archive/root_sh/step_278_loki_limit.sh:29:    cache_location: /tmp/loki/cache
./1_archive/root_sh/step_320_rewrite_panel_index.sh:430:          cache: "no-store"
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:430:          cache: "no-store"
./1_archive/root_sh/step_360_rewrite_monitor_hardening.sh:387:          cache: "no-store"
./1_archive/root_sh/step_361_fix_panel_status_manual.sh:30:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
./1_archive/root_sh/step_361_fix_panel_status_source.sh:49:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
./1_archive/root_sh/step_362_fix_panel_ssl_service_status.sh:50:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
./1_archive/root_sh/step_363_clean_panel_ssl_routes.sh:51:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
./1_archive/root_sh/step_365_hard_fix_panel_render_engine.sh:21:    const res = await fetch("/service-status.json", { cache: "no-store" });
./1_archive/root_sh/step_367_restore_clean_panel_engine.sh:29:    const res = await fetch("/service-status.json", { cache: "no-store" });
./1_archive/root_sh/step_368_panel_final_logic_fix.sh:129:        cache: "no-store",
./1_archive/root_sh/step_60_backup_real_redis_cache.sh:9:  backups/app/manual/playground_main.go.real_redis_cache.bak 2>/dev/null || true
./1_archive/root_sh/step_60_backup_real_redis_cache.sh:11:cp -f internal/platform/cache/service/redis_cache_service.go \
./1_archive/root_sh/step_60_backup_real_redis_cache.sh:12:  backups/app/manual/redis_cache_service.go.real_redis_cache.bak 2>/dev/null || true
./1_archive/root_sh/step_60_backup_real_redis_cache.sh:14:echo "OK ✅ real redis cache yedegi alindi"
./1_archive/root_sh/step_62_run_real_redis_cache_test.sh:8:echo "OK ✅ real redis cache test calistirma bitti"
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:49:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:82:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:108:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:141:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh:27:grep -q 'id: cache' "${CATALOG_FILE}"
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh:28:echo "OK ✅ cache signal grubu var"
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:47:        "@asamuzakjp/generational-cache": "^1.0.1",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:64:        "@asamuzakjp/generational-cache": "^1.0.1",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:74:    "node_modules/@asamuzakjp/generational-cache": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:76:      "resolved": "https://registry.npmjs.org/@asamuzakjp/generational-cache/-/generational-cache-1.0.1.tgz",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:174:        "lru-cache": "^5.1.1",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2168:        "file-entry-cache": "^8.0.0",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2381:    "node_modules/file-entry-cache": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2383:      "resolved": "https://registry.npmjs.org/file-entry-cache/-/file-entry-cache-8.0.0.tgz",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2388:        "flat-cache": "^4.0.0"
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2411:    "node_modules/flat-cache": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2413:      "resolved": "https://registry.npmjs.org/flat-cache/-/flat-cache-4.0.1.tgz",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2644:        "lru-cache": "^11.2.7",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2668:    "node_modules/jsdom/node_modules/lru-cache": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2670:      "resolved": "https://registry.npmjs.org/lru-cache/-/lru-cache-11.3.5.tgz",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:3033:    "node_modules/lru-cache": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:3035:      "resolved": "https://registry.npmjs.org/lru-cache/-/lru-cache-5.1.1.tgz",
./cmd/api-gateway/api_gateway_main.go:393:		{Name: "cache_service", URL: strings.TrimSpace(os.Getenv("CACHE_HEALTH_URL"))},
./cmd/cache-pattern-clean-test/cache_pattern_clean_test_main.go:8:	cacheservice "github.com/divrigili/pix2pi-SaaS/internal/platform/cache/service"
./cmd/cache-pattern-clean-test/cache_pattern_clean_test_main.go:18:	fmt.Println("STEP cache pattern clean testi basliyor")
./cmd/cache-pattern-clean-test/cache_pattern_clean_test_main.go:21:	svc := cacheservice.NewRedisCacheServiceFromEnv()
./cmd/cache-pattern-clean-test/cache_pattern_clean_test_main.go:78:	zorunlu(errors.Is(err, cacheservice.ErrCacheKeyBulunamadi), "t1 product p1 silinmis olmali")
./cmd/cache-pattern-clean-test/cache_pattern_clean_test_main.go:81:	zorunlu(errors.Is(err, cacheservice.ErrCacheKeyBulunamadi), "t1 product p2 silinmis olmali")
./cmd/cache-pattern-clean-test/cache_pattern_clean_test_main.go:104:	fmt.Println("OK ✅ STEP cache pattern clean testi bitti")
./cmd/cache-service/cache_service_main.go:12:	cacheservice "github.com/divrigili/pix2pi-SaaS/internal/platform/cache/service"
./cmd/cache-service/cache_service_main.go:61:	cacheSvc := cacheservice.NewRedisCacheServiceFromEnv()
./cmd/cache-service/cache_service_main.go:63:		if err := cacheSvc.Close(); err != nil {
./cmd/cache-service/cache_service_main.go:64:			log.Printf("WARN cache close hatasi: %v\n", err)
./cmd/cache-service/cache_service_main.go:71:		if err := cacheSvc.Ping(); err == nil {
./cmd/cache-service/cache_service_main.go:78:			Service: "cache",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-10.3 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-10.4 WAF / DDoS / bot guardrail izi

Pattern:

```text
WAF|waf|DDoS|ddos|bot|scanner|Cloudflare|cloudflare|rate.*limit|limit_req|limit_conn|blocked|deny|fail2ban
```

Match Count: 1056

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:1:limit_req_zone $binary_remote_addr zone=pix2pi_edge:20m rate=20r/s;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:30:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_certbot_acme.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:50:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:53:        deny all;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:59:        deny all;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:65:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:83:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:86:        deny all;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:91:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:109:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:112:        deny all;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:118:        deny all;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:124:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:142:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:145:        deny all;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:150:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:1:limit_req_zone $binary_remote_addr zone=pix2pi_edge:20m rate=20r/s;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:30:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_certbot_acme.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:50:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:53:        deny all;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:59:        deny all;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:65:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:83:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:86:        deny all;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:91:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:109:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:112:        deny all;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:118:        deny all;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:124:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:142:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:145:        deny all;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:150:        limit_req zone=pix2pi_edge burst=40 nodelay;
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_rate_limit.bak
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh:9:echo "OK ✅ api gateway rate limit oncesi yedek alindi"
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh:14:echo "OK ✅ api gateway rate limitli restart bitti"
./1_archive/root_sh/step_107_test_api_gateway_rate_limit.sh:23:echo "OK ✅ api gateway rate limit test bitti"
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:16:echo "=== TEST 3 tenant-001 rate limit ==="
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_redis_rate_limit.bak
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh:9:echo "OK ✅ redis rate limit oncesi api gateway yedegi alindi"
./1_archive/root_sh/step_114_restart_api_gateway_after_redis_rate_limit.sh:14:echo "OK ✅ redis rate limit sonrasi api gateway restart bitti"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:16:echo "=== TEST 3 tenant-redis-001 rate limit ==="
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:37:redis-cli GET tenant:tenant-redis-001:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:39:redis-cli TTL tenant:tenant-redis-001:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:41:redis-cli GET tenant:tenant-redis-002:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:43:redis-cli TTL tenant:tenant-redis-002:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:46:echo "OK ✅ redis tenant rate limit test bitti"
./1_archive/root_sh/step_128_test_combined_gateway.sh:25:redis-cli GET tenant:tenant-combined-identity:gateway:identity:rate_limit || true
./1_archive/root_sh/step_128_test_combined_gateway.sh:27:redis-cli GET tenant:tenant-combined-auth:gateway:auth:rate_limit || true
./1_archive/root_sh/step_129_test_scope_separation.sh:15:redis-cli GET tenant:tenant-scope-001:gateway:auth:rate_limit || true
./1_archive/root_sh/step_129_test_scope_separation.sh:19:redis-cli GET tenant:tenant-scope-001:gateway:identity:rate_limit || true
./1_archive/root_sh/step_130_backup_nginx_before_rate_limit.sh:6:cp /etc/nginx/nginx.conf ~/pix2pi/nginx-backups/nginx.conf.before_rate_limit.bak
./1_archive/root_sh/step_131_add_nginx_global_rate_limit.sh:7:    limit_req_zone $binary_remote_addr zone=pix2pi_limit_zone:10m rate=20r/s;' $CONF
./1_archive/root_sh/step_131_add_nginx_global_rate_limit.sh:9:echo "OK ✅ nginx global rate limit zone eklendi"
./1_archive/root_sh/step_132_enable_rate_limit_api_domain.sh:7:        limit_req zone=pix2pi_limit_zone burst=40 nodelay;' $CONF
./1_archive/root_sh/step_132_enable_rate_limit_api_domain.sh:9:echo "OK ✅ api domain rate limit aktif"
./1_archive/root_sh/step_133_reload_nginx_after_rate_limit.sh:7:echo "OK ✅ nginx rate limit aktif"
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh:4:mkdir -p ~/pix2pi/fail2ban-backups
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh:6:cp -a /etc/fail2ban /root/pix2pi/fail2ban-backups/fail2ban_before_nginx_jail_$(date +%Y%m%d_%H%M%S)
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh:8:echo "OK ✅ fail2ban yedegi alindi"
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:23:    .service-name{font-weight:700;margin-bottom:6px}
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:47:    .service-name{font-weight:700;margin-bottom:6px}
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:54:    .service-name{font-weight:700;margin-bottom:6px}
./1_archive/root_sh/step_270_observability_stack.sh:229:          "placement": "bottom"
./1_archive/root_sh/step_320_rewrite_panel_index.sh:35:      font-family:system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Arial,sans-serif;
./1_archive/root_sh/step_320_rewrite_panel_index.sh:58:      margin-bottom:18px;
./1_archive/root_sh/step_320_rewrite_panel_index.sh:89:      margin-bottom:6px;
./1_archive/root_sh/step_320_rewrite_panel_index.sh:146:      margin-bottom:10px;
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:52:      font-family:system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Arial,sans-serif;
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:73:      margin-bottom:18px;
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:93:      margin-bottom:14px;
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-10.4 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-10.5 Nginx edge / reverse proxy izi

Pattern:

```text
nginx|server_name|proxy_pass|proxy_set_header|X-Forwarded|X-Request-ID|add_header|client_max_body_size|proxy_read_timeout|reverse proxy
```

Match Count: 957

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:25:    server_name api.pix2pi.com.tr panel.pix2pi.com.tr auth.pix2pi.com.tr pos.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:27:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:30:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_certbot_acme.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:40:    server_name api.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:45:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:46:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_request_limits.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:47:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:48:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_error_handling.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:49:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:50:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:60:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:66:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:67:        proxy_pass http://pix2pi_api_upstream;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:73:    server_name panel.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:78:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:79:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_request_limits.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:80:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:81:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_error_handling.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:82:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:83:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:92:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:93:        proxy_pass http://pix2pi_panel_upstream;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:99:    server_name auth.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:104:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:105:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_request_limits.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:106:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:107:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_error_handling.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:108:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:109:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:119:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:120:        proxy_pass http://pix2pi_auth_upstream/health;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:125:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:126:        proxy_pass http://pix2pi_auth_upstream;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:132:    server_name pos.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:137:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:138:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_request_limits.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:139:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:140:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_error_handling.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:141:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:142:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:151:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:152:        proxy_pass http://pix2pi_pos_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:25:    server_name api.pix2pi.com.tr panel.pix2pi.com.tr auth.pix2pi.com.tr pos.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:27:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:30:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_certbot_acme.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:40:    server_name api.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:45:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:46:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_request_limits.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:47:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:48:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_error_handling.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:49:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:50:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:60:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:66:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:67:        proxy_pass http://pix2pi_api_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:73:    server_name panel.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:78:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:79:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_request_limits.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:80:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:81:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_error_handling.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:82:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:83:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:92:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:93:        proxy_pass http://pix2pi_panel_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:99:    server_name auth.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:104:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:105:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_request_limits.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:106:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-10.5 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-10.6 Public route GET content smoke izi

Pattern:

```text
curl -L|GET|HTTP_STATUS|size_download|time_total|public.*GET|content check|pix2pi_edge_http_smoke|/faz4d/pilot-go-live
```

Match Count: 313

```text
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:37:redis-cli GET tenant:tenant-redis-001:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:41:redis-cli GET tenant:tenant-redis-002:gateway:rate_limit || true
./1_archive/root_sh/step_128_test_combined_gateway.sh:25:redis-cli GET tenant:tenant-combined-identity:gateway:identity:rate_limit || true
./1_archive/root_sh/step_128_test_combined_gateway.sh:27:redis-cli GET tenant:tenant-combined-auth:gateway:auth:rate_limit || true
./1_archive/root_sh/step_129_test_scope_separation.sh:15:redis-cli GET tenant:tenant-scope-001:gateway:auth:rate_limit || true
./1_archive/root_sh/step_129_test_scope_separation.sh:19:redis-cli GET tenant:tenant-scope-001:gateway:identity:rate_limit || true
./1_archive/root_sh/step_190_test_cache_service.sh:14:echo "=== CACHE GET ==="
./1_archive/root_sh/step_297_fix_nginx_monitor_route_proper.sh:4:TARGET="/etc/nginx/sites-enabled/pix2pi_ssl"
./1_archive/root_sh/step_297_fix_nginx_monitor_route_proper.sh:7:cp "$TARGET" "$BACKUP"
./1_archive/root_sh/step_320_rewrite_panel_index.sh:429:          method: "GET",
./1_archive/root_sh/step_323_find_status_engine.sh:13:grep -RniE '"/status"|"/health"|"/internal/service-monitor"|HandleFunc|http.HandleFunc|gin.*GET' \
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:429:          method: "GET",
./1_archive/root_sh/step_355e_find_last_buildable_watchdog_backup.sh:6:TARGET="$SRC_DIR/service_watchdog_main.go"
./1_archive/root_sh/step_355e_find_last_buildable_watchdog_backup.sh:13:cp "$TARGET" "${TARGET}.before_find_$(date +%Y%m%d_%H%M%S)" || true
./1_archive/root_sh/step_355e_find_last_buildable_watchdog_backup.sh:29:  cp "$CANDIDATE" "$TARGET"
./1_archive/root_sh/step_355e_find_last_buildable_watchdog_backup.sh:48:cp "$FOUND" "$TARGET"
./1_archive/root_sh/step_360_rewrite_monitor_hardening.sh:385:          method: "GET",
./1_archive/root_sh/step_390_rewrite_early_warning_clean.sh:56:AUTO_HEAL_TARGETS() {
./1_archive/root_sh/step_390_rewrite_early_warning_clean.sh:148:    AUTO_HEAL_TARGETS | while IFS='|' read -r logical_name unit_name; do
./1_archive/root_sh/step_421_patch_kernel_safe.sh:4:echo "=== STEP 421B / PATCH KERNEL SAFE GETTERS ==="
./cmd/api-gateway/erp_runtime_route_catalog_wiring_test.go:71:		t.Fatal("expected GET to be rejected")
./cmd/policy-cache-hybrid-test/policy_cache_hybrid_test_main.go:45:	kernel.InvalidatePolicyCache("admin", "GET", "/users")
./cmd/policy-cache-hybrid-test/policy_cache_hybrid_test_main.go:50:	allow := kernel.ResolveWithCache(resolverTrue, "admin", "GET", "/users")
./cmd/policy-cache-hybrid-test/policy_cache_hybrid_test_main.go:55:	allow = kernel.ResolveWithCache(resolverTrue, "admin", "GET", "/users")
./cmd/policy-cache-hybrid-test/policy_cache_hybrid_test_main.go:64:	allow = kernel.ResolveWithCache(resolverFalse, "admin", "GET", "/users")
./cmd/policy-cache-hybrid-test/policy_cache_hybrid_test_main.go:69:	kernel.InvalidatePolicyCache("admin", "GET", "/users")
./cmd/policy-cache-hybrid-test/policy_cache_hybrid_test_main.go:72:	allow = kernel.ResolveWithCache(resolverFalse, "admin", "GET", "/users")
./deploy/edge/nginx/includes/pix2pi_waf_foundation.conf:1:if ($request_method !~ ^(GET|POST|PUT|PATCH|DELETE|OPTIONS|HEAD)$) {
./deploy/quality/scripts/render_lvl14_performance_release.sh:39:  PERF_ERROR_BUDGET_PERCENT
./deploy/quality/scripts/render_lvl14_performance_release.sh:62:  -e "s|__PERF_ERROR_BUDGET_PERCENT__|${PERF_ERROR_BUDGET_PERCENT}|g" \
./deploy/quality/scripts/render_lvl14_performance_release.sh:80:- Error budget: ${PERF_ERROR_BUDGET_PERCENT}%
./internal/platform/kernel/model_policy_rule.go:9:	Route     string `gorm:"size:200;index;not null"` // ör: "GET /admin/ping" veya "GET /admin/*"
./internal/platform/kernel/policy_db.go:12:// 1) exact: "GET /admin/ping"
./internal/platform/kernel/policy_db.go:13:// 2) wildcard: "GET /admin/*"
./internal/platform/kernel/policy_db.go:37:	// path prefix üret: "/admin" => "GET /admin/*"
./internal/platform/kernel/policy_resolver_iface.go:4:// method: "GET", "POST" ...
./internal/platform/kernel/policy_static.go:6:// Key format: "GET /path" veya "GET /admin/*"
./internal/platform/kernel/policy_static.go:22:	// 2) wildcard match (GET /admin/* gibi)
./internal/platform/publicapi/gateway_contract.go:16:	"GET":    {},
./internal/platform/publicapi/gateway_service_test.go:29:		Method:      "GET",
./internal/platform/publicapi/gateway_service_test.go:60:		Method:      "GET",
./internal/platform/publicapi/gateway_service_test.go:75:		Method:      "GET",
./internal/platform/publicapi/gateway_service_test.go:91:			Method:        "GET",
./internal/platform/publicapi/gateway_service_test.go:123:	if store.lastCmd.Method != "GET" {
./internal/platform/publicapi/gateway_service_test.go:124:		t.Fatalf("beklenen method GET, alinan: %s", store.lastCmd.Method)
./internal/platform/publicapi/gateway_service_test.go:249:		Method:      "GET",
./internal/platform/publicapi/gateway_service_test.go:263:		Method:        "GET",
./internal/platform/publicapi/gateway_store_test.go:53:				"GET",
./internal/platform/publicapi/gateway_store_test.go:92:	if result.Method != "GET" {
./internal/platform/publicapi/gateway_store_test.go:93:		t.Fatalf("beklenen method GET, alinan: %s", result.Method)
./internal/platform/publicapi/gateway_store_test.go:140:	if db.lastArgs[4] != "GET" {
./internal/platform/publicapi/gateway_store_test.go:255:		Method:      "GET",
./internal/platform/publicapi/runtime_integration_test.go:109:	if strings.HasPrefix(path, "/v1/erp") && (method == "GET" || method == "POST") {
./internal/platform/publicapi/runtime_integration_test.go:123:	if strings.HasPrefix(path, "/v1/developer") && (method == "GET" || method == "POST") {
./internal/platform/publicapi/runtime_integration_test.go:445:		Method:      "GET",
./internal/platform/rbac/rbac.go:84:// - Rules: routeKey -> role allow map (örn: "GET /admin/*": {"admin":true})
./internal/platform/rbac/rbac.go:85:// - Permissions: routeKey -> required permission (örn: "GET /admin/ping": "identity:admin:ping")
./internal/platform/rbac/rbac.go:229:				// wildcard: "GET /admin/*" gibi
./internal/platform/rbac/rbac.go:299:		// wildcard: "GET /admin/*"
./internal/platform/reporting/runtime/registration_test.go:34:			t.Fatalf("expected GET method, got %s for %s", route.Method, route.Path)
./internal/platform/reporting/runtime/runtime_smoke_test.go:192:func TestReportingRuntimeSmoke_RoutesAreReadOnlyGET(t *testing.T) {
./internal/platform/reporting/runtime/runtime_smoke_test.go:197:			t.Fatalf("expected GET route, got %s for %s", route.Method, route.Path)
./scripts/audit_faz6_10_edge_runtime.sh:75:curl -L -I -sS --max-time 10 https://'$DOMAIN'/ 2>/dev/null | head -n 120 || true
./scripts/audit_faz6_10_edge_runtime.sh:78:write_cmd_block "6-10.5 Public GET Content Probe" bash -lc "
./scripts/audit_faz6_10_edge_runtime.sh:79:curl -L -sS --max-time 10 -w '\nHTTP_STATUS=%{http_code} SIZE=%{size_download} TIME=%{time_total} REMOTE_IP=%{remote_ip}\n' https://'$DOMAIN'/ | head -c 1600 || true
./scripts/audit_faz6_10_edge_runtime.sh:82:write_cmd_block "6-10.6 Public Pilot GET Content Probe" bash -lc "
./scripts/audit_faz6_10_edge_runtime.sh:83:curl -L -sS --max-time 10 -w '\nHTTP_STATUS=%{http_code} SIZE=%{size_download} TIME=%{time_total} REMOTE_IP=%{remote_ip}\n' https://'$DOMAIN'/faz4d/pilot-go-live/ | head -c 2000 || true
./scripts/audit_faz6_10_edge_runtime.sh:114:bash scripts/pix2pi_edge_http_smoke.sh 2>&1 || true
./scripts/audit_faz6_10_edge_runtime.sh:126:  echo "6-10.5 Public GET content probe collected OK ✅"
./scripts/audit_faz6_10_edge_runtime.sh:127:  echo "6-10.6 Public pilot GET content probe collected OK ✅"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-10.6 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-10.7 Origin exposure / internal port safety izi

Pattern:

```text
origin|internal.*port|5432|5433|6379|4222|8222|9090|3001|public.*port|exposure|ss -lntp
```

Match Count: 1274

```text
./1_archive/root_sh/step_160_install_nats_event_bus.sh:18:      - "4222:4222"
./1_archive/root_sh/step_160_install_nats_event_bus.sh:19:      - "8222:8222"
./1_archive/root_sh/step_161_check_nats_health.sh:4:echo "=== NATS 4222 ==="
./1_archive/root_sh/step_161_check_nats_health.sh:5:ss -lntp | grep 4222 || true
./1_archive/root_sh/step_161_check_nats_health.sh:8:echo "=== NATS MONITOR 8222 ==="
./1_archive/root_sh/step_161_check_nats_health.sh:9:curl -s http://127.0.0.1:8222/healthz || true
./1_archive/root_sh/step_170_check_jetstream.sh:6:curl -s http://127.0.0.1:8222/jsz | head -20
./1_archive/root_sh/step_172_create_jetstream_stream.sh:5:nats --server nats://127.0.0.1:4222 stream add PIX2PI_EVENTS \
./1_archive/root_sh/step_173_check_jetstream_stream.sh:5:nats --server nats://127.0.0.1:4222 stream info PIX2PI_EVENTS
./1_archive/root_sh/step_174_create_sale_consumer.sh:5:nats --server nats://127.0.0.1:4222 consumer rm PIX2PI_EVENTS SALE_PROCESSOR -f >/dev/null 2>&1 || true
./1_archive/root_sh/step_174_create_sale_consumer.sh:7:nats --server nats://127.0.0.1:4222 consumer add PIX2PI_EVENTS SALE_PROCESSOR \
./1_archive/root_sh/step_175_check_sale_consumer.sh:5:nats --server nats://127.0.0.1:4222 consumer info PIX2PI_EVENTS SALE_PROCESSOR
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:62:REDIS=$(durum_http_text "redis" "http://127.0.0.1:6379" "" || true)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:44:	nc, err := nats.Connect("nats://localhost:4222")
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:61:	nc, err := nats.Connect("nats://localhost:4222")
./1_archive/root_sh/step_192_reporting_service_panelde_goster.sh:46:    original = text
./1_archive/root_sh/step_1_backup_accounts_import.sh:8:cp -f internal/erp/core/finance/service/erp_chart_of_accounts_import_service.go \
./1_archive/root_sh/step_1_backup_balance_sheet.sh:8:cp -f internal/erp/operations/reporting/service/erp_balance_sheet_service.go \
./1_archive/root_sh/step_1_backup_cash_flow.sh:8:cp -f internal/erp/operations/reporting/service/erp_cash_flow_service.go \
./1_archive/root_sh/step_1_backup_general_ledger.sh:8:cp -f internal/erp/operations/reporting/service/erp_general_ledger_service.go \
./1_archive/root_sh/step_1_backup_income_statement.sh:8:cp -f internal/erp/operations/reporting/service/erp_income_statement_service.go \
./1_archive/root_sh/step_1_backup_trial_balance.sh:8:cp -f internal/erp/operations/reporting/service/erp_trial_balance_service.go \
./1_archive/root_sh/step_201_apply_event_store.sh:4:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -f step_200_create_event_store_table.sql
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:157:		natsURL = "nats://localhost:4222"
./1_archive/root_sh/step_202_test_event_store.sh:4:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -c "SELECT * FROM event_store LIMIT 5;"
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:467:		natsURL = "nats://localhost:4222"
./1_archive/root_sh/step_204_apply_journal_tables.sh:6:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -f step_203_create_journal_tables.sql
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:13:DB_PORT="${DB_PORT:-5433}"
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:27:echo "=== 4 PORT 5432 KONTROL ==="
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:28:ss -ltnp | grep 5432 || true
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:36:  DB_PORT_VAL="${DB_PORT_VAL:-5432}"
./1_archive/root_sh/step_230_snapshot_schema.sh:21:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -f step_230_create_snapshot_tables.sql
./1_archive/root_sh/step_231_snapshot_full.sh:100:	connStr := "host=localhost port=5433 user=pix2pi password=pix2pi dbname=pix2pi sslmode=disable"
./1_archive/root_sh/step_232_run_snapshot_flow.sh:18:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -c "SELECT tenant_id, aggregate_type, aggregate_id, version, state FROM snapshots ORDER BY id DESC LIMIT 3;"
./1_archive/root_sh/step_23_check_postgres_runtime.sh:15:echo "=== 2 PORT 5432 ==="
./1_archive/root_sh/step_23_check_postgres_runtime.sh:16:ss -ltnp | grep 5432 || true
./1_archive/root_sh/step_23_check_postgres_runtime.sh:36:  DB_PORT_VAL="${DB_PORT_VAL:-5432}"
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:18:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -f step_240_enable_rls_snapshots.sql
./1_archive/root_sh/step_241_test_rls_snapshots.sh:5:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'
./1_archive/root_sh/step_241_test_rls_snapshots.sh:16:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'
./1_archive/root_sh/step_241_test_rls_snapshots.sh:27:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'
./1_archive/root_sh/step_242_create_app_user.sh:4:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'
./1_archive/root_sh/step_243_test_rls_real.sh:5:PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi <<'SQLEOF'
./1_archive/root_sh/step_243_test_rls_real.sh:14:PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi <<'SQLEOF'
./1_archive/root_sh/step_243_test_rls_real.sh:23:PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi <<'SQLEOF'
./1_archive/root_sh/step_244_fix_app_user.sh:4:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'
./1_archive/root_sh/step_245_fix_password.sh:4:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'
./1_archive/root_sh/step_246_grant_snapshot_sequence.sh:4:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'
./1_archive/root_sh/step_24_start_postgres_runtime.sh:39:ss -ltnp | grep 5432 || true
./1_archive/root_sh/step_24_start_postgres_runtime.sh:47:  DB_PORT_VAL="${DB_PORT_VAL:-5432}"
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:5:cikti_1=$(PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi -t -A <<'SQLEOF'
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:30:cikti_2=$(PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi -t -A <<'SQLEOF'
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:56:cikti_3=$(PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi 2>&1 <<'SQLEOF'
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:83:PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi <<'SQLEOF'
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:100:cikti_5=$(PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi -t -A <<'SQLEOF'
./1_archive/root_sh/step_251_fix_verification.sh:6:cikti=$(PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi 2>&1 <<'SQLEOF'
./1_archive/root_sh/step_260_audit_schema.sh:30:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -f step_260_create_audit_tables.sql
./1_archive/root_sh/step_261_audit_full.sh:84:	connStr := "host=localhost port=5433 user=pix2pi password=pix2pi dbname=pix2pi sslmode=disable"
./1_archive/root_sh/step_262_run_audit_flow.sh:18:PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -c "SELECT tenant_id, actor_id, action, entity_id, status FROM audit_logs ORDER BY id DESC LIMIT 5;"
./1_archive/root_sh/step_26_test_postgres_login.sh:13:DB_PORT="${DB_PORT:-5433}"
./1_archive/root_sh/step_270_observability_stack.sh:25:      - "9090:9090"
./1_archive/root_sh/step_270_observability_stack.sh:67:      - "3001:3000"
./1_archive/root_sh/step_270_observability_stack.sh:100:      - targets: ["prometheus:9090"]
./1_archive/root_sh/step_270_observability_stack.sh:176:    url: http://prometheus:9090
./1_archive/root_sh/step_272_test_observability_stack.sh:5:curl -s http://127.0.0.1:9090/-/healthy
./1_archive/root_sh/step_272_test_observability_stack.sh:15:curl -s http://127.0.0.1:3001/api/health
./1_archive/root_sh/step_273_fix_promtail_positions.sh:49:      - "9090:9090"
./1_archive/root_sh/step_273_fix_promtail_positions.sh:92:      - "3001:3000"
./1_archive/root_sh/step_291_watchdog_service.sh:43:    "port": 6379,
./1_archive/root_sh/step_291_watchdog_service.sh:53:    "port": 4222,
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-10.7 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-10.8 Edge observability izi

Pattern:

```text
access.log|error.log|cf-ray|CF-Ray|upstream|timeout|4xx|5xx|status code|latency|edge.*log|WAF.*log|rate.*hit
```

Match Count: 523

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:3:upstream pix2pi_api_upstream {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:8:upstream pix2pi_panel_upstream {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:13:upstream pix2pi_auth_upstream {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:18:upstream pix2pi_pos_upstream {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:27:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:47:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:67:        proxy_pass http://pix2pi_api_upstream;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:80:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:93:        proxy_pass http://pix2pi_panel_upstream;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:106:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:120:        proxy_pass http://pix2pi_auth_upstream/health;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:126:        proxy_pass http://pix2pi_auth_upstream;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:139:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:152:        proxy_pass http://pix2pi_pos_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:3:upstream pix2pi_api_upstream {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:8:upstream pix2pi_panel_upstream {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:13:upstream pix2pi_auth_upstream {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:18:upstream pix2pi_pos_upstream {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:27:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:47:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:67:        proxy_pass http://pix2pi_api_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:80:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:93:        proxy_pass http://pix2pi_panel_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:106:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:120:        proxy_pass http://pix2pi_auth_upstream/health;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:126:        proxy_pass http://pix2pi_auth_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:139:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:152:        proxy_pass http://pix2pi_pos_upstream;
./1_archive/root_sh/step_135_check_nginx_error_log.sh:5:tail -n 50 /var/log/nginx/error.log || true
./1_archive/root_sh/step_135_check_nginx_error_log.sh:8:echo "OK ✅ nginx error log kontrol bitti"
./1_archive/root_sh/step_290_monitor_core.sh:36:func NewChecker(timeout time.Duration) *Checker {
./1_archive/root_sh/step_290_monitor_core.sh:38:		Client: &http.Client{Timeout: timeout},
./1_archive/root_sh/step_331_rewrite_watchdog_advanced_state_engine.sh:394:func netDialTimeout(addr string, timeout time.Duration) (dummyConn, error) {
./1_archive/root_sh/step_331_rewrite_watchdog_advanced_state_engine.sh:395:	return (&netDialer{}).DialTimeout("tcp", addr, timeout)
./1_archive/root_sh/step_331_rewrite_watchdog_advanced_state_engine.sh:409:func (d *netDialer) DialTimeout(network, address string, timeout time.Duration) (net.Conn, error) {
./1_archive/root_sh/step_331_rewrite_watchdog_advanced_state_engine.sh:410:	return net.DialTimeout(network, address, timeout)
./1_archive/root_sh/step_358_add_nginx_status_proxy.sh:16:    proxy_connect_timeout 2s;
./1_archive/root_sh/step_358_add_nginx_status_proxy.sh:17:    proxy_read_timeout 5s;
./1_archive/root_sh/step_361_fix_panel_status_manual.sh:29:        proxy_read_timeout 5s;
./1_archive/root_sh/step_361_fix_panel_status_source.sh:48:        proxy_read_timeout 5s;
./1_archive/root_sh/step_362_fix_panel_ssl_service_status.sh:49:        proxy_read_timeout 5s;
./1_archive/root_sh/step_363_clean_panel_ssl_routes.sh:50:        proxy_read_timeout 5s;
./1_archive/root_sh/step_423h_systemd_real_error.sh:97:echo "NOT: 15 saniye timeout var. Hemen duserse gerçek hata görünecek."
./1_archive/root_sh/step_423h_systemd_real_error.sh:99:timeout 15s bash -x "$RUNNER" > "$TRACE_OUT" 2>&1
./1_archive/root_sh/step_423h_systemd_real_error.sh:108:  echo "OK ✅ runner 15 saniye boyunca ayakta kaldi (timeout)"
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:3:upstream pix2pi_api_upstream {
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:8:upstream pix2pi_panel_upstream {
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:13:upstream pix2pi_auth_upstream {
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:18:upstream pix2pi_pos_upstream {
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:27:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:47:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:67:        proxy_pass http://pix2pi_api_upstream;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:80:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:93:        proxy_pass http://pix2pi_panel_upstream;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:106:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:120:        proxy_pass http://pix2pi_auth_upstream/health;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:126:        proxy_pass http://pix2pi_auth_upstream;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:139:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:152:        proxy_pass http://pix2pi_pos_upstream;
./.backup/lvl10_fix_log_format_order_20260422_072447/pix2pi_log_format.conf:5:  'rt=$request_time uct=$upstream_connect_time '
./.backup/lvl10_fix_log_format_order_20260422_072447/pix2pi_log_format.conf:6:  'uht=$upstream_header_time urt=$upstream_response_time '
./.backup/lvl10_fix_log_format_order_20260422_072447/pix2pi_log_format.conf:7:  'ua="$upstream_addr" us="$upstream_status"';
./.backup/lvl10_fix_nginx_logging_context_20260422_072340/pix2pi_logging.conf:5:  'rt=$request_time uct=$upstream_connect_time '
./.backup/lvl10_fix_nginx_logging_context_20260422_072340/pix2pi_logging.conf:6:  'uht=$upstream_header_time urt=$upstream_response_time '
./.backup/lvl10_fix_nginx_logging_context_20260422_072340/pix2pi_logging.conf:7:  'ua="$upstream_addr" us="$upstream_status"';
./.backup/lvl10_fix_nginx_logging_context_20260422_072340/pix2pi_logging.conf:9:access_log /var/log/nginx/pix2pi_edge_access.log pix2pi_edge_main;
./.backup/lvl10_fix_nginx_logging_context_20260422_072340/pix2pi_logging.conf:10:error_log /var/log/nginx/pix2pi_edge_error.log warn;
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-10.8 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-10.9 Edge incident / runbook izi

Pattern:

```text
incident|runbook|DNS.*incident|SSL.*incident|CDN.*incident|WAF.*incident|public.*404|timeout.*incident|edge.*incident
```

Match Count: 507

```text
./cmd/control-panel/control_panel.go:127:	incidentAuditRuntimePort := normalizePort(envOrDefault("INCIDENT_AUDIT_RUNTIME_PORT", "5950"))
./cmd/control-panel/control_panel.go:142:		incidentAuditRuntime := check("http://127.0.0.1:" + incidentAuditRuntimePort + "/health")
./cmd/control-panel/control_panel.go:159:			"incident_audit_runtime":   incidentAuditRuntime,
./cmd/control-panel/control_panel.go:174:	app.All("/incident-audit-runtime/*", proxyToTarget("http://127.0.0.1:"+incidentAuditRuntimePort, "/incident-audit-runtime"))
./cmd/early-warning-runtime/early_warning_runtime_main.go:73:	IncidentCount    int    `json:"incident_count"`
./cmd/early-warning-runtime/early_warning_runtime_main.go:490:	incidentCount := countTable(db, "runtime.mission_control_incidents")
./cmd/early-warning-runtime/early_warning_runtime_main.go:491:	incidentLevel := "ok"
./cmd/early-warning-runtime/early_warning_runtime_main.go:492:	incidentStatus := "ok"
./cmd/early-warning-runtime/early_warning_runtime_main.go:493:	message := "acik incident sayisi izleniyor"
./cmd/early-warning-runtime/early_warning_runtime_main.go:495:	if incidentCount > 0 {
./cmd/early-warning-runtime/early_warning_runtime_main.go:496:		incidentLevel = "warning"
./cmd/early-warning-runtime/early_warning_runtime_main.go:497:		incidentStatus = "warning"
./cmd/early-warning-runtime/early_warning_runtime_main.go:498:		message = fmt.Sprintf("incident kaydi var: %d", incidentCount)
./cmd/early-warning-runtime/early_warning_runtime_main.go:502:		SignalKey:   "mission_control_incidents",
./cmd/early-warning-runtime/early_warning_runtime_main.go:503:		Category:    "incident",
./cmd/early-warning-runtime/early_warning_runtime_main.go:504:		Level:       incidentLevel,
./cmd/early-warning-runtime/early_warning_runtime_main.go:505:		Status:      incidentStatus,
./cmd/early-warning-runtime/early_warning_runtime_main.go:551:		IncidentCount:    countTable(db, "runtime.mission_control_incidents"),
./cmd/early-warning-runtime/early_warning_runtime_main.go:626:	app.Get("/api/early-warning/incidents", func(c *fiber.Ctx) error {
./cmd/early-warning-runtime/early_warning_runtime_main.go:632:					TableName:   "runtime.mission_control_incidents",
./cmd/early-warning-runtime/early_warning_runtime_main.go:633:					Count:       countTable(db, "runtime.mission_control_incidents"),
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:22:	IncidentCount         int    `json:"incident_count"`
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:23:	OpenIncidentCount     int    `json:"open_incident_count"`
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:24:	CriticalIncidentCount int    `json:"critical_incident_count"`
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:32:	IncidentID     string `json:"incident_id"`
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:35:	IncidentKey    string `json:"incident_key"`
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:186:				"service": "incident-audit-runtime",
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:195:				"service": "incident-audit-runtime",
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:203:			"service": "incident-audit-runtime",
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:209:	app.Get("/api/incident-audit/summary", func(c *fiber.Ctx) error {
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:212:  (SELECT count(*)::int FROM runtime.mission_control_incidents) AS incident_count,
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:215:    FROM runtime.mission_control_incidents
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:217:  ) AS open_incident_count,
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:220:    FROM runtime.mission_control_incidents
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:223:  ) AS critical_incident_count,
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:246:				"error": "incident audit summary okunamadi",
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:258:	app.Get("/api/incident-audit/incidents", func(c *fiber.Ctx) error {
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:266:  incident_key,
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:282:FROM runtime.mission_control_incidents
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:283:ORDER BY created_at DESC, incident_key
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:289:				"error": "incidents okunamadi",
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:326:					"error": "incidents parse edilemedi",
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:342:	app.Get("/api/incident-audit/audit-events", func(c *fiber.Ctx) error {
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:396:	app.Get("/api/incident-audit/audit-logs", func(c *fiber.Ctx) error {
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:452:	app.Get("/api/incident-audit/timeline", func(c *fiber.Ctx) error {
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:459:    'incident' AS source,
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:467:  FROM runtime.mission_control_incidents
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:501:				"error": "incident audit timeline okunamadi",
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:522:					"error": "incident audit timeline parse edilemedi",
./cmd/ops-console-smoke/ops_console_smoke_main.go:208:			Key:      "incident_audit_runtime_health",
./cmd/ops-console-smoke/ops_console_smoke_main.go:210:			URL:      proxyURL("/incident-audit-runtime/health"),
./cmd/ops-console-smoke/ops_console_smoke_main.go:211:			Expect:   `"service":"incident-audit-runtime"`,
./cmd/ops-console-smoke/ops_console_smoke_main.go:215:			Key:      "incident_audit_runtime_summary",
./cmd/ops-console-smoke/ops_console_smoke_main.go:217:			URL:      proxyURL("/incident-audit-runtime/api/incident-audit/summary"),
./cmd/ops-console-smoke/ops_console_smoke_main_test.go:39:		"incident_audit_runtime_summary",
./cmd/runtime-topology/runtime_topology_main.go:134:	incidentAuditRuntimePort := normalizePort(envOrDefault("INCIDENT_AUDIT_RUNTIME_PORT", "5950"))
./cmd/runtime-topology/runtime_topology_main.go:150:		{NodeKey: "incident_audit_runtime", Display: "Incident Audit Runtime", NodeType: "runtime", Layer: "observability", CheckMode: "http", Port: incidentAuditRuntimePort, URL: "http://127.0.0.1:" + incidentAuditRuntimePort + "/health"},
./cmd/runtime-topology/runtime_topology_main.go:165:		{FromNode: "control_panel", ToNode: "incident_audit_runtime", Relation: "proxies", Protocol: "http"},
./cmd/runtime-topology/runtime_topology_main.go:169:		{FromNode: "incident_audit_runtime", ToNode: "mission_control", Relation: "reads incidents", Protocol: "sql"},
./cmd/runtime-topology/runtime_topology_main.go:170:		{FromNode: "incident_audit_runtime", ToNode: "postgres_db", Relation: "reads audit", Protocol: "sql"},
./configs/faz5/commercial_readiness_suite_v1.json:11:    "pix2pi_support_sla_incident_policy_v1",
./configs/faz5/commercial_readiness_suite_v1.json:70:        "incident_classes",
./configs/faz5/commercial_readiness_suite_v1.json:106:    "docs/faz5/5_7_support_sla_incident_escalation.md",
./configs/faz5/commercial_readiness_suite_v1.json:117:    "configs/faz5/support_sla_incident_policy_v1.json",
./configs/faz5/faz5_final_closure_v1.json:12:    "pix2pi_support_sla_incident_policy_v1",
./configs/faz5/faz5_final_closure_v1.json:48:    "support_sla_incident",
./configs/faz5/revenue_metrics_policy_v1.json:126:      "incident_class",
./configs/faz5/revenue_metrics_policy_v1.json:129:      "p0_p1_incident_count"
./configs/faz5/sales_demo_crm_policy_v1.json:11:    "pix2pi_support_sla_incident_policy_v1"
./configs/faz5/support_sla_incident_policy_v1.json:2:  "catalog_code": "pix2pi_support_sla_incident_policy_v1",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-10.9 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-10.10 Edge test / audit script izi

Pattern:

```text
FAZ_6_10|edge.*test|test.*edge|dns.*probe|http.*smoke|runtime.*audit|real.*implementation.*audit
```

Match Count: 282

```text
./1_archive/root_sh/step_57_run_ledger_posting_test.sh:8:echo "OK ✅ ledger posting test calistirma bitti"
./cmd/control-panel/control_panel.go:174:	app.All("/incident-audit-runtime/*", proxyToTarget("http://127.0.0.1:"+incidentAuditRuntimePort, "/incident-audit-runtime"))
./cmd/ops-console-smoke/ops_console_smoke_main.go:217:			URL:      proxyURL("/incident-audit-runtime/api/incident-audit/summary"),
./cmd/runtime-topology/runtime_topology_main.go:170:		{FromNode: "incident_audit_runtime", ToNode: "postgres_db", Relation: "reads audit", Protocol: "sql"},
./internal/erp/core/audit/service/erp_financial_consistency_service_test.go:118:func TestFinancialConsistencyService_Check_JournalLedgerMismatch(t *testing.T) {
./internal/erp/core/ledger/service/erp_ledger_posting_service_test.go:38:func TestLedgerPostingService_BuildFromJournal_Success(t *testing.T) {
./internal/erp/core/ledger/service/erp_ledger_posting_service_test.go:60:func TestLedgerPostingService_BuildFromJournal_Balanced(t *testing.T) {
./internal/erp/core/ledger/service/erp_ledger_posting_service_test.go:81:func TestLedgerPostingService_BuildFromJournal_InvalidJournalID(t *testing.T) {
./internal/erp/core/ledger/service/erp_ledger_posting_service_test.go:93:func TestLedgerPostingService_BuildFromJournal_InvalidEventID(t *testing.T) {
./internal/erp/core/ledger/service/erp_ledger_posting_service_test.go:105:func TestLedgerPostingService_BuildFromJournal_InvalidLine(t *testing.T) {
./internal/erp/core/ledger/service/erp_ledger_posting_service_test.go:117:func TestLedgerPostingService_BuildFromJournal_Unbalanced(t *testing.T) {
./internal/erp/core/ufk/service/erp_ledger_posting_service_test.go:5:func TestLedgerPostingService_Post_AyniHesapBakiye(t *testing.T) {
./internal/erp/core/ufk/service/erp_ledger_posting_service_test.go:21:func TestLedgerPostingService_Post_FarkliHesaplar(t *testing.T) {
./internal/erp/persistence/ledger/ledger_db_integration_test.go:1:package ledger_test
./internal/erp/persistence/ledger/ledger_db_integration_test.go:12:func ledgerIntegrationDSN(t *testing.T) string {
./internal/erp/persistence/ledger/ledger_db_integration_test.go:29:func ledgerPSQL(t *testing.T, dsn string, sql string) string {
./internal/erp/persistence/ledger/ledger_db_integration_test.go:41:func ledgerPSQLMustFail(t *testing.T, dsn string, sql string) {
./internal/erp/persistence/ledger/ledger_db_integration_test.go:51:func TestLedgerDBTablesExist(t *testing.T) {
./internal/erp/persistence/ledger/ledger_db_integration_test.go:69:func TestLedgerDBIndexesExist(t *testing.T) {
./internal/erp/persistence/ledger/ledger_db_integration_test.go:104:func TestLedgerDBRLSEnabledAndForced(t *testing.T) {
./internal/erp/persistence/ledger/ledger_db_integration_test.go:125:func TestLedgerDBTenantPoliciesExist(t *testing.T) {
./internal/erp/persistence/ledger/ledger_db_integration_test.go:145:func TestLedgerDBAccountingChecksWork(t *testing.T) {
./internal/erp/persistence/ledger/ledger_db_integration_test.go:201:    'faz3_ledger_test'
./internal/erp/persistence/ledger/ledger_db_integration_test.go:253:    'faz3_ledger_test'
./internal/erp/persistence/ledger/ledger_db_integration_test.go:301:    'faz3_ledger_test'
./internal/erp/persistence/ledger/ledger_db_integration_test.go:363:func TestLedgerDBTenantIsolationWorks(t *testing.T) {
./internal/erp/persistence/ledger/ledger_db_integration_test.go:429:    'faz3_ledger_rls_test'
./internal/erp/persistence/ledger/ledger_db_integration_test.go:480:func createLedgerJournalFixture(t *testing.T, dsn string, unique string) (string, string, string) {
./internal/erp/persistence/ledger/ledger_db_integration_test.go:518:    'faz3_ledger_test'
./internal/erp/persistence/ledger/ledger_db_integration_test.go:556:    'faz3_ledger_test'
./internal/erp/persistence/ledger/ledger_db_integration_test.go:594:    'faz3_ledger_test'
./internal/erp/persistence/ledger/ledger_db_integration_test.go:602:func cleanupLedgerFixture(t *testing.T, dsn string, journalEntryID string) {
./internal/erp/persistence/ledger/ledger_schema_test.go:1:package ledger_test
./internal/erp/persistence/ledger/ledger_schema_test.go:53:func TestLedgerMigrationCreatesCoreTables(t *testing.T) {
./internal/erp/persistence/ledger/ledger_schema_test.go:66:func TestLedgerMigrationHasTenantAndAuditColumns(t *testing.T) {
./internal/erp/persistence/ledger/ledger_schema_test.go:83:func TestLedgerMigrationHasMovementFields(t *testing.T) {
./internal/erp/persistence/ledger/ledger_schema_test.go:109:func TestLedgerMigrationHasBalanceFields(t *testing.T) {
./internal/erp/persistence/ledger/ledger_schema_test.go:129:func TestLedgerMigrationHasAccountingChecks(t *testing.T) {
./internal/erp/persistence/ledger/ledger_schema_test.go:148:func TestLedgerMigrationHasTenantIndexes(t *testing.T) {
./internal/erp/persistence/ledger/ledger_schema_test.go:173:func TestLedgerMigrationEnablesForcedRLS(t *testing.T) {
./internal/erp/persistence/ledger/ledger_schema_test.go:188:func TestLedgerMigrationHasTenantIsolationPolicies(t *testing.T) {
./internal/erp/persistence/ledger/ledger_schema_test.go:202:func TestLedgerRollbackDropsTablesInSafeOrder(t *testing.T) {
./internal/erp/persistence/ledger/model_test.go:130:func TestValidateCreateLedgerBalanceInputDebitSuccess(t *testing.T) {
./internal/erp/persistence/ledger/model_test.go:148:func TestValidateCreateLedgerBalanceInputZeroSuccess(t *testing.T) {
./internal/erp/persistence/ledger/model_test.go:164:func TestValidateCreateLedgerBalanceInputFiscalPeriodRequired(t *testing.T) {
./internal/erp/persistence/ledger/model_test.go:177:func TestValidateCreateLedgerBalanceInputAccountCodeRequired(t *testing.T) {
./internal/erp/persistence/ledger/model_test.go:190:func TestValidateCreateLedgerBalanceInputBalanceSideInvalid(t *testing.T) {
./internal/erp/persistence/ledger/model_test.go:205:func TestValidateCreateLedgerBalanceInputZeroMustHaveZeroAmount(t *testing.T) {
./internal/erp/persistence/ledger/postgres_ledger_balance_repository_integration_test.go:14:func postgresLedgerBalanceRepositoryTestDSN(t *testing.T) string {
./internal/erp/persistence/ledger/postgres_ledger_balance_repository_integration_test.go:25:		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping ledger balance repository integration test")
./internal/erp/persistence/ledger/postgres_ledger_balance_repository_integration_test.go:31:func TestPostgresLedgerBalanceRepositoryCreateGetList(t *testing.T) {
./internal/erp/persistence/ledger/postgres_ledger_balance_repository_integration_test.go:126:func TestPostgresLedgerBalanceRepositoryValidation(t *testing.T) {
./internal/erp/persistence/ledger/postgres_ledger_balance_repository_integration_test.go:150:func cleanupLedgerBalanceFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, ledgerBalanceID string) {
./internal/erp/runtime/apisurface/e2e_http_smoke_integration_test.go:44:		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping api e2e http smoke test")
./internal/erp/runtime/e2eflow/step_adapters_test.go:214:func TestPostLedgerStepAdapterSuccess(t *testing.T) {
./internal/erp/runtime/ledgerpost/default_orchestrator_test.go:80:func TestDefaultLedgerPostingDraftBuilderSuccess(t *testing.T) {
./internal/erp/runtime/ledgerpost/default_orchestrator_test.go:101:func TestDefaultLedgerPostingOrchestratorSuccess(t *testing.T) {
./internal/erp/runtime/ledgerpost/default_orchestrator_test.go:145:func TestDefaultLedgerPostingOrchestratorValidationFailure(t *testing.T) {
./internal/erp/runtime/ledgerpost/default_orchestrator_test.go:173:func TestDefaultLedgerPostingOrchestratorStoreRequired(t *testing.T) {
./internal/erp/runtime/ledgerpost/default_orchestrator_test.go:182:func TestDefaultLedgerPostingOrchestratorBuilderError(t *testing.T) {
./internal/erp/runtime/ledgerpost/default_orchestrator_test.go:210:func TestDefaultLedgerPostingOrchestratorPersistError(t *testing.T) {
./internal/erp/runtime/ledgerpost/default_orchestrator_test.go:237:func TestDefaultLedgerPostingOrchestratorMarkError(t *testing.T) {
./internal/erp/runtime/ledgerpost/default_orchestrator_test.go:264:func TestDefaultLedgerPostingOrchestratorPublisherError(t *testing.T) {
./internal/erp/runtime/ledgerpost/default_orchestrator_test.go:286:func TestDefaultLedgerPostingOrchestratorContextCancelled(t *testing.T) {
./internal/erp/runtime/ledgerpost/model_test.go:27:		Description: "Ledger posting test",
./internal/erp/runtime/ledgerpost/model_test.go:63:func TestValidateLedgerPostingRequestSuccess(t *testing.T) {
./internal/erp/runtime/ledgerpost/model_test.go:71:func TestValidateLedgerPostingRequestTenantRequired(t *testing.T) {
./internal/erp/runtime/ledgerpost/model_test.go:81:func TestValidateLedgerPostingRequestJournalRefRequired(t *testing.T) {
./internal/erp/runtime/ledgerpost/model_test.go:92:func TestValidateLedgerPostingRequestJournalStatusInvalid(t *testing.T) {
./internal/erp/runtime/ledgerpost/model_test.go:102:func TestValidateLedgerPostingRequestFiscalYearInvalid(t *testing.T) {
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-10.10 STATUS=IMPLEMENTED_OR_PRESENT ✅

# Final Runtime Implementation Interpretation

```text
REQUIRED_FAIL=0
OPTIONAL_WARN=0
FAZ_6_10_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_10_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_11_READY=YES ✅
FAZ_6_10_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅
```
