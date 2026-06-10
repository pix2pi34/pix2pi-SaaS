# FAZ 6-7 Real Implementation Audit

Generated At: 2026-05-01T14:58:41+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit, FAZ 6-7 Security Hardening / Production Guardrails maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

Fix note:
- Onceki audit scriptinde regex icindeki dollar parametreleri bash tarafindan $1 / $2 degiskeni saniliyordu.
- Bu surumde injection kontrol pattern'i guvenli hale getirildi.
- set -u aktif kalmaya devam eder.

---

## Scanned Files

```text
3016 /tmp/tmp.aHlf6nX81q/files.txt

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

## 6-7.1 Secret / env hardening izi

Pattern:

```text
SECRET|JWT_SECRET|PASSWORD|TOKEN|RESTIC_PASSWORD|mask_secret|MASKED|chmod|chown|\.env|ports\.env|common\.env|secret.*policy|SecretPolicy
```

Match Count: 1399

```text
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:93:chmod +x /usr/local/bin/pix2pi_service_snapshot.sh
./1_archive/root_sh/step_187_create_service_status_cron.sh:13:chmod 644 /etc/cron.d/pix2pi_service_status
./1_archive/root_sh/step_188_verify_done_items.sh:36:  chmod +x "$dosya" 2>/dev/null || true
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:107:chmod +x "$binary_dosya"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:191:chmod +x "$start_script" "$stop_script" "$status_script"
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:38:chmod +x "$binary_dosya"
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:138:chmod +x "$start_script" "$stop_script" "$status_script" "$ensure_script"
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:146:chmod 644 "$cron_dosya"
./1_archive/root_sh/step_201_apply_event_store.sh:4:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:352:chmod +x "$binary_dosya"
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:430:chmod +x "$start_script" "$stop_script" "$status_script"
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:329:chmod +x "$binary_dosya"
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:408:chmod +x "$start_script" "$stop_script" "$status_script"
./1_archive/root_sh/step_202_test_event_store.sh:4:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:582:chmod +x "$query_binary" "$reporting_binary"
./1_archive/root_sh/step_204_apply_journal_tables.sh:6:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:112:chmod +x "$snapshot_script"
./1_archive/root_sh/step_206_servis_yoneticisi_kur.sh:191:chmod +x "$manager_dosya"
./1_archive/root_sh/step_206_servis_yoneticisi_kur.sh:226:chmod +x "$test_dosya"
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:146:chmod +x "$manager_dosya"
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:6:if [ -f .env ]; then
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:8:  . ./.env
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:15:DB_PASSWORD=***MASKED***
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:19:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:24:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:31:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:13:if [ -f .env ]; then
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:14:  echo "OK ✅ .env bulundu"
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:15:  grep -E '^(DB_NAME|DB_USER|DB_HOST|DB_PORT|POSTGRES_DB|POSTGRES_USER|POSTGRES_HOST|POSTGRES_PORT)=' .env || true
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:17:  echo "HATA ❌ .env bulunamadi"
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:33:  DB_HOST_VAL="$(grep -E '^DB_HOST=' .env 2>/dev/null | tail -n1 | cut -d= -f2-)"
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:34:  DB_PORT_VAL="$(grep -E '^DB_PORT=' .env 2>/dev/null | tail -n1 | cut -d= -f2-)"
./1_archive/root_sh/step_230_snapshot_schema.sh:21:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_232_run_snapshot_flow.sh:18:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_23_check_postgres_runtime.sh:7:if [ -f .env ]; then
./1_archive/root_sh/step_23_check_postgres_runtime.sh:8:  echo "OK ✅ .env bulundu"
./1_archive/root_sh/step_23_check_postgres_runtime.sh:9:  grep -E '^(DB_NAME|DB_USER|DB_HOST|DB_PORT|POSTGRES_DB|POSTGRES_USER|POSTGRES_HOST|POSTGRES_PORT)=' .env || true
./1_archive/root_sh/step_23_check_postgres_runtime.sh:11:  echo "HATA ❌ .env bulunamadi"
./1_archive/root_sh/step_23_check_postgres_runtime.sh:33:  DB_HOST_VAL="$(grep -E '^DB_HOST=' .env 2>/dev/null | tail -n1 | cut -d= -f2-)"
./1_archive/root_sh/step_23_check_postgres_runtime.sh:34:  DB_PORT_VAL="$(grep -E '^DB_PORT=' .env 2>/dev/null | tail -n1 | cut -d= -f2-)"
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:18:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_241_test_rls_snapshots.sh:5:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_241_test_rls_snapshots.sh:16:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_241_test_rls_snapshots.sh:27:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_242_create_app_user.sh:4:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_242_create_app_user.sh:11:      CREATE ROLE pix2pi_app LOGIN PASSWORD 'pix2pi_app_pass';
./1_archive/root_sh/step_243_test_rls_real.sh:5:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_243_test_rls_real.sh:14:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_243_test_rls_real.sh:23:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_244_fix_app_user.sh:4:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_244_fix_app_user.sh:8:CREATE ROLE pix2pi_app LOGIN PASSWORD 'pix2pi_app_pass';
./1_archive/root_sh/step_245_fix_password.sh:4:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_245_fix_password.sh:6:ALTER ROLE pix2pi_app WITH PASSWORD 'pix2pi_app_pass';
./1_archive/root_sh/step_246_grant_snapshot_sequence.sh:4:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_24_start_postgres_runtime.sh:44:  DB_HOST_VAL="$(grep -E '^DB_HOST=' .env 2>/dev/null | tail -n1 | cut -d= -f2-)"
./1_archive/root_sh/step_24_start_postgres_runtime.sh:45:  DB_PORT_VAL="$(grep -E '^DB_PORT=' .env 2>/dev/null | tail -n1 | cut -d= -f2-)"
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:5:cikti_1=$(PGPASSWORD=***MASKED***
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:30:cikti_2=$(PGPASSWORD=***MASKED***
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:56:cikti_3=$(PGPASSWORD=***MASKED***
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:83:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:100:cikti_5=$(PGPASSWORD=***MASKED***
./1_archive/root_sh/step_251_fix_verification.sh:6:cikti=$(PGPASSWORD=***MASKED***
./1_archive/root_sh/step_25_check_postgres_password.sh:7:docker exec pix2pi_pg env | grep -E 'POSTGRES_(USER|PASSWORD|DB)' || true
./1_archive/root_sh/step_25_check_postgres_password.sh:10:echo "=== .env DB BILGILERI ==="
./1_archive/root_sh/step_25_check_postgres_password.sh:11:grep -E '^(DB_HOST|DB_PORT|DB_USER|DB_NAME|DB_PASSWORD|POSTGRES_USER|POSTGRES_PASSWORD|POSTGRES_DB)=' .env || true
./1_archive/root_sh/step_260_audit_schema.sh:30:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_262_run_audit_flow.sh:18:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_26_test_postgres_login.sh:6:if [ -f .env ]; then
./1_archive/root_sh/step_26_test_postgres_login.sh:8:  . ./.env
./1_archive/root_sh/step_270_observability_stack.sh:61:      - GF_SECURITY_ADMIN_PASSWORD=***MASKED***
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-7.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-7.2 Nginx / edge hardening izi

Pattern:

```text
nginx|server_name|ssl_protocols|ssl_ciphers|add_header|Strict-Transport|X-Frame|X-Content|Referrer|Content-Security|client_max_body_size|proxy_set_header|limit_req|limit_conn|deny|allow
```

Match Count: 3665

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:1:limit_req_zone $binary_remote_addr zone=pix2pi_edge:20m rate=20r/s;
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
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:53:        deny all;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:58:        allow 127.0.0.1/32;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:59:        deny all;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:60:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:65:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:66:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:73:    server_name panel.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:78:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:79:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_request_limits.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:80:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:81:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_error_handling.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:82:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:83:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:86:        deny all;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:91:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:92:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:99:    server_name auth.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:104:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:105:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_request_limits.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:106:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:107:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_error_handling.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:108:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:109:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:112:        deny all;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:117:        allow 127.0.0.1/32;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:118:        deny all;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:119:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:124:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:125:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:132:    server_name pos.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:137:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:138:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_request_limits.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:139:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_logging.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:140:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_error_handling.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:141:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:142:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_waf_foundation.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:145:        deny all;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:150:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:151:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:1:limit_req_zone $binary_remote_addr zone=pix2pi_edge:20m rate=20r/s;
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
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:53:        deny all;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:58:        allow 127.0.0.1/32;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:59:        deny all;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:60:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:65:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:66:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:73:    server_name panel.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:78:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:79:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_request_limits.conf;
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-7.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-7.3 Firewall / port policy izi

Pattern:

```text
ufw|iptables|firewall|fail2ban|Fail2Ban|ports\.env|ss -lntp|netstat|allowed.*port|deny.*port|port.*policy
```

Match Count: 629

```text
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh:4:mkdir -p ~/pix2pi/fail2ban-backups
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh:6:cp -a /etc/fail2ban /root/pix2pi/fail2ban-backups/fail2ban_before_nginx_jail_$(date +%Y%m%d_%H%M%S)
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh:8:echo "OK ✅ fail2ban yedegi alindi"
./1_archive/root_sh/step_161_check_nats_health.sh:5:ss -lntp | grep 4222 || true
./1_archive/root_sh/step_423d_reset_db_password.sh:65:ss -lntp | grep ":$DB_PORT" || true
./1_archive/root_sh/step_423f_port_9010_probe.sh:13:ss -lntp | grep ':9010' || echo "9010 dinleyen proses yok"
./1_archive/root_sh/step_423f_port_9010_probe.sh:18:PIDS="$(ss -lntp | awk '/:9010/ {for(i=1;i<=NF;i++) if($i ~ /pid=/){gsub(/.*pid=/,"",$i); gsub(/,.*/,"",$i); print $i}}' | sort -u)"
./1_archive/root_sh/step_423f_port_9010_probe.sh:71:if ss -lntp | grep -q ':9010'; then
./1_archive/root_sh/step_423g_fix_9010_conflict.sh:10:  ss -lntp 2>/dev/null | awk -v p=":$PORT" '
./1_archive/root_sh/step_423g_fix_9010_conflict.sh:70:if ss -lntp | grep -q ":$PORT"; then
./1_archive/root_sh/step_423g_fix_9010_conflict.sh:72:  ss -lntp | grep ":$PORT" || true
./1_archive/root_sh/step_423g_fix_9010_conflict.sh:128:if ss -lntp | grep -q ":$PORT"; then
./1_archive/root_sh/step_423h_systemd_real_error.sh:16:  ss -lntp 2>/dev/null | awk '/:9010/ {
./1_archive/root_sh/step_423h_systemd_real_error.sh:88:if ss -lntp | grep -q ':9010'; then
./1_archive/root_sh/step_423h_systemd_real_error.sh:90:  ss -lntp | grep ':9010' || true
./1_archive/root_sh/step_72_check_production_server.sh:31:ufw status || true
./1_archive/root_sh/step_74_install_production_base_packages.sh:9:  ufw \
./1_archive/root_sh/step_76_configure_production_firewall.sh:4:ufw allow OpenSSH
./1_archive/root_sh/step_76_configure_production_firewall.sh:5:ufw allow 80/tcp
./1_archive/root_sh/step_76_configure_production_firewall.sh:6:ufw allow 443/tcp
./1_archive/root_sh/step_76_configure_production_firewall.sh:8:ufw --force enable
./1_archive/root_sh/step_76_configure_production_firewall.sh:9:ufw status verbose
./1_archive/root_sh/step_76_configure_production_firewall.sh:11:echo "OK ✅ production firewall ayari bitti"
./1_archive/root_sh/step_78_test_production_server_ready.sh:13:ufw status
./configs/faz5/commercial_readiness_suite_v1.json:11:    "pix2pi_support_sla_incident_policy_v1",
./configs/faz5/commercial_readiness_suite_v1.json:117:    "configs/faz5/support_sla_incident_policy_v1.json",
./configs/faz5/faz5_final_closure_v1.json:12:    "pix2pi_support_sla_incident_policy_v1",
./configs/faz5/legal_compliance_policy_v1.json:65:    "export_policy_required": true,
./configs/faz5/sales_demo_crm_policy_v1.json:11:    "pix2pi_support_sla_incident_policy_v1"
./configs/faz5/support_sla_incident_policy_v1.json:2:  "catalog_code": "pix2pi_support_sla_incident_policy_v1",
./deploy/observability/grafana/dashboards/node-exporter-full.json:21925:              "expr": "irate(node_netstat_IpExt_InOctets{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:21938:              "expr": "irate(node_netstat_IpExt_OutOctets{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22042:              "expr": "irate(node_netstat_Ip_Forwarding{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22158:              "expr": "irate(node_netstat_Icmp_InMsgs{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22171:              "expr": "irate(node_netstat_Icmp_OutMsgs{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22287:              "expr": "irate(node_netstat_Icmp_InErrors{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22415:              "expr": "irate(node_netstat_Udp_InDatagrams{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22428:              "expr": "irate(node_netstat_Udp_OutDatagrams{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22531:              "expr": "irate(node_netstat_Udp_InErrors{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22544:              "expr": "irate(node_netstat_Udp_NoPorts{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22557:              "expr": "irate(node_netstat_UdpLite_InErrors{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22567:              "expr": "irate(node_netstat_Udp_RcvbufErrors{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22580:              "expr": "irate(node_netstat_Udp_SndbufErrors{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22708:              "expr": "irate(node_netstat_Tcp_InSegs{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22722:              "expr": "irate(node_netstat_Tcp_OutSegs{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22827:              "expr": "irate(node_netstat_TcpExt_ListenOverflows{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22841:              "expr": "irate(node_netstat_TcpExt_ListenDrops{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22855:              "expr": "irate(node_netstat_TcpExt_TCPSynRetrans{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22868:              "expr": "irate(node_netstat_Tcp_RetransSegs{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22878:              "expr": "irate(node_netstat_Tcp_InErrs{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22888:              "expr": "irate(node_netstat_Tcp_OutRsts{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22899:              "expr": "irate(node_netstat_TcpExt_TCPRcvQDrop{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:22912:              "expr": "irate(node_netstat_TcpExt_TCPOFOQueue{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:23035:              "expr": "node_netstat_Tcp_CurrEstab{instance=\"$node\",job=\"$job\"}",
./deploy/observability/grafana/dashboards/node-exporter-full.json:23049:              "expr": "node_netstat_Tcp_MaxConn{instance=\"$node\",job=\"$job\"}",
./deploy/observability/grafana/dashboards/node-exporter-full.json:23167:              "expr": "irate(node_netstat_TcpExt_SyncookiesFailed{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:23181:              "expr": "irate(node_netstat_TcpExt_SyncookiesRecv{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:23195:              "expr": "irate(node_netstat_TcpExt_SyncookiesSent{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:23300:              "expr": "irate(node_netstat_Tcp_ActiveOpens{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:23313:              "expr": "irate(node_netstat_Tcp_PassiveOpens{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/smoke/ops_console_general_smoke.sh:9:source /etc/pix2pi/ports.env
./devtools/run_all.sh:63:ss -lntp | grep -E ':(9001|9002|9003)\b' || true
./grafana/dashboards/node-exporter-full.json:21925:              "expr": "irate(node_netstat_IpExt_InOctets{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:21938:              "expr": "irate(node_netstat_IpExt_OutOctets{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:22042:              "expr": "irate(node_netstat_Ip_Forwarding{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:22158:              "expr": "irate(node_netstat_Icmp_InMsgs{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:22171:              "expr": "irate(node_netstat_Icmp_OutMsgs{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:22287:              "expr": "irate(node_netstat_Icmp_InErrors{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:22415:              "expr": "irate(node_netstat_Udp_InDatagrams{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:22428:              "expr": "irate(node_netstat_Udp_OutDatagrams{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-7.3 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-7.4 Auth / JWT / API guardrail izi

Pattern:

```text
Authorization|Bearer|JWT|jwt|ValidateToken|ParseToken|auth.*middleware|AuthMiddleware|protected|Unauthorized|401|Forbidden|403|token.*expiry
```

Match Count: 1797

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:54:        return 403;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:87:        return 403;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:113:        return 403;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:146:        return 403;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:54:        return 403;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:87:        return 403;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:113:        return 403;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:146:        return 403;
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:14:  -H "Authorization: Bearer invalid-token" \
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:22:  -H "Authorization: Bearer pix2pi-token-tenant-001" \
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:30:  -H "Authorization: Bearer pix2pi-token-tenant-001" \
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:38:  -H "Authorization: Bearer pix2pi-admin-token" \
./1_archive/root_sh/step_3_backup_jwt_tenant.sh:9:  backups/app/manual/playground_main.go.jwt_tenant.bak 2>/dev/null || true
./1_archive/root_sh/step_3_backup_jwt_tenant.sh:11:echo "OK ✅ jwt tenant yedegi alindi"
./1_archive/root_sh/step_401_enable_all_services.sh:4:echo "=== STEP 401 / ENABLE ALL SERVICES ==="
./1_archive/root_sh/step_401_enable_all_services.sh:25:echo "=== STEP 401 TAMAM ✅ ==="
./1_archive/root_sh/step_403_fix_service_map.sh:4:echo "=== STEP 403 / FIX SERVICE MAP ==="
./1_archive/root_sh/step_403_fix_service_map.sh:58:echo "=== STEP 403 TAMAM ✅ ==="
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:143:func withBearerAuth(next http.Handler) http.Handler {
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:147:		authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:149:			w.WriteHeader(http.StatusUnauthorized)
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:154:		if !strings.HasPrefix(authHeader, "Bearer ") {
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:155:			w.WriteHeader(http.StatusUnauthorized)
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:160:		token := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:163:			w.WriteHeader(http.StatusUnauthorized)
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:199:			w.WriteHeader(http.StatusUnauthorized)
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:205:			w.WriteHeader(http.StatusForbidden)
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:264:			func(next http.Handler) http.Handler { return withBearerAuth(next) },
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:274:			func(next http.Handler) http.Handler { return withBearerAuth(next) },
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:132:func withBearerAuth(next http.Handler) http.Handler {
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:136:		authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:138:			w.WriteHeader(http.StatusUnauthorized)
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:143:		if !strings.HasPrefix(authHeader, "Bearer ") {
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:144:			w.WriteHeader(http.StatusUnauthorized)
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:149:		token := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:152:			w.WriteHeader(http.StatusUnauthorized)
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:188:			w.WriteHeader(http.StatusUnauthorized)
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:194:			w.WriteHeader(http.StatusForbidden)
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:253:			func(next http.Handler) http.Handler { return withBearerAuth(next) },
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:263:			func(next http.Handler) http.Handler { return withBearerAuth(next) },
./1_archive/root_sh/step_5_run_jwt_tenant_test.sh:8:echo "OK ✅ jwt tenant test calistirma bitti"
./1_archive/root_sh/step_6_backup_jwt_middleware.sh:9:  backups/app/manual/playground_main.go.jwt_middleware.bak 2>/dev/null || true
./1_archive/root_sh/step_6_backup_jwt_middleware.sh:11:echo "OK ✅ jwt middleware yedegi alindi"
./1_archive/root_sh/step_7_prepare_auth_middleware_dir.sh:6:mkdir -p internal/platform/auth/middleware
./1_archive/root_sh/step_7_prepare_auth_middleware_dir.sh:8:echo "OK ✅ auth middleware klasoru hazir"
./1_archive/root_sh/step_8_run_jwt_middleware_test.sh:8:echo "OK ✅ jwt middleware test calistirma bitti"
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:54:        return 403;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:87:        return 403;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:113:        return 403;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:146:        return 403;
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:194:      "integrity": "sha512-l5XkZK7r7wa9LucGw9LwZyyCUscb4x37JWTPz7swwFE/0FMQAGpiWUZn8u9DzkSBWEcK25jmvubfpw2dnAMdbw==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1383:      "integrity": "sha512-91Sbl3s4Kb3SybliIY6muFBmHVv+pYXfybC4Oolp3dvk8BvIE3wOPc+403CWIT7mJNkfQRGtdqghzs2+Z91Tqg==",
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:126:func withBearerAuth(next http.Handler) http.Handler {
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:130:		authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:132:			w.WriteHeader(http.StatusUnauthorized)
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:137:		if !strings.HasPrefix(authHeader, "Bearer ") {
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:138:			w.WriteHeader(http.StatusUnauthorized)
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:143:		token := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:146:			w.WriteHeader(http.StatusUnauthorized)
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:182:			w.WriteHeader(http.StatusUnauthorized)
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:188:			w.WriteHeader(http.StatusForbidden)
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:247:			func(next http.Handler) http.Handler { return withBearerAuth(next) },
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:257:			func(next http.Handler) http.Handler { return withBearerAuth(next) },
./cmd/api-gateway/api_gateway_main.go:49:	routeScopeProtected routeScope = "protected"
./cmd/api-gateway/api_gateway_main.go:188:			Description:    "protected self route",
./cmd/api-gateway/api_gateway_main.go:198:			Description:    "protected user count route",
./cmd/api-gateway/api_gateway_main.go:208:			Description:    "protected user list route",
./cmd/api-gateway/api_gateway_main.go:218:			Description:    "protected user detail prefix",
./cmd/api-gateway/api_gateway_main.go:687:			"message":        "protected route ok",
./cmd/api-gateway/api_gateway_main.go:849:	protectedMux := http.NewServeMux()
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-7.4 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-7.5 Tenant isolation guardrail izi

Pattern:

```text
X-Tenant-ID|tenant_id|tenant_uuid|TenantID|TenantUUID|tenant.*middleware|TenantMiddleware|tenant.*filter|RLS|row level|policy|cross-tenant|tenant.*mismatch
```

Match Count: 6828

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:45:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:78:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:104:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:137:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:45:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:78:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:104:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:137:    include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_tls_policy.conf;
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_tenant_middleware.bak
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh:9:echo "OK ✅ tenant middleware oncesi api gateway yedegi alindi"
./1_archive/root_sh/step_109_restart_api_gateway_after_tenant_middleware.sh:14:echo "OK ✅ tenant middleware sonrasi api gateway restart bitti"
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:12:curl -s -i -H "X-Tenant-ID: tenant-001" "$URL"
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:21:    -H "X-Tenant-ID: tenant-001" "$URL" > /tmp/pix2pi_tenant_001_code_$i.txt
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:32:curl -s -i -H "X-Tenant-ID: tenant-002" "$URL"
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:36:echo "OK ✅ tenant middleware test bitti"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:12:curl -s -i -H "X-Tenant-ID: tenant-redis-001" "$URL"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:21:    -H "X-Tenant-ID: tenant-redis-001" "$URL" > /tmp/pix2pi_redis_tenant_code_$i.txt
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:32:curl -s -i -H "X-Tenant-ID: tenant-redis-002" "$URL"
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh:9:  backups/app/manual/erp_cari_hesap.go.tenant_filter.bak 2>/dev/null || true
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh:12:  backups/app/manual/erp_cari_hesap_service.go.tenant_filter.bak 2>/dev/null || true
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh:15:  backups/app/manual/playground_main.go.tenant_filter.bak 2>/dev/null || true
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh:17:echo "OK ✅ tenant service filter yedegi alindi"
./1_archive/root_sh/step_124_test_auth_via_gateway.sh:4:curl -i -H "X-Tenant-ID: tenant-auth-test" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:10:curl -s -i -H "X-Tenant-ID: tenant-combined-identity" https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:20:curl -s -i -H "X-Tenant-ID: tenant-combined-auth" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_129_test_scope_separation.sh:5:curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_129_test_scope_separation.sh:10:curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_12_run_tenant_service_filter_test.sh:8:echo "OK ✅ tenant service filter test calistirma bitti"
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:8:curl -s -i -H "X-Tenant-ID: tenant-001" "$URL_IDENTITY"
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:15:  -H "X-Tenant-ID: tenant-001" \
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:23:  -H "X-Tenant-ID: tenant-001" \
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:31:  -H "X-Tenant-ID: tenant-999" \
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:39:  -H "X-Tenant-ID: tenant-777" \
./1_archive/root_sh/step_134_check_503_source.sh:21:curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/auth/health || true
./1_archive/root_sh/step_134_check_503_source.sh:25:curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/identity/health || true
./1_archive/root_sh/step_16_backup_super_admin_policy.sh:9:  backups/app/manual/playground_main.go.super_admin_policy.bak 2>/dev/null || true
./1_archive/root_sh/step_16_backup_super_admin_policy.sh:11:echo "OK ✅ super admin policy yedegi alindi"
./1_archive/root_sh/step_18_run_super_admin_policy_test.sh:8:echo "OK ✅ super admin policy test calistirma bitti"
./1_archive/root_sh/step_19_backup_postgres_rls.sh:8:cp -f deploy/sql/rls_tenant_policy.sql \
./1_archive/root_sh/step_19_backup_postgres_rls.sh:9:  backups/app/manual/rls_tenant_policy.sql.bak 2>/dev/null || true
./1_archive/root_sh/step_210_audit_full.sh:30:	if entry.TenantID == "" {
./1_archive/root_sh/step_210_audit_full.sh:79:		TenantID: "tenant-1",
./1_archive/root_sh/step_210_audit_full.sh:97:		TenantID: "tenant-1",
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:18:echo "=== RLS SQL APPLY ==="
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:20:  -f deploy/sql/rls_tenant_policy.sql
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:25:SET app.tenant_id = 'tenant-001';
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:32:SET app.tenant_id = 'tenant-002';
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:7:ls -lah deploy/sql/rls_tenant_policy.sql
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:9:sed -n '1,220p' deploy/sql/rls_tenant_policy.sql
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
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:10:DROP POLICY IF EXISTS snapshots_tenant_policy ON snapshots;
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:12:CREATE POLICY snapshots_tenant_policy
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:14:USING (tenant_id = current_setting('app.current_tenant', true))
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:15:WITH CHECK (tenant_id = current_setting('app.current_tenant', true));
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:20:echo "OK ✅ snapshots RLS aktif"
./1_archive/root_sh/step_241_test_rls_snapshots.sh:8:SELECT tenant_id, aggregate_type, aggregate_id, version
./1_archive/root_sh/step_241_test_rls_snapshots.sh:19:SELECT tenant_id, aggregate_type, aggregate_id, version
./1_archive/root_sh/step_241_test_rls_snapshots.sh:30:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_243_test_rls_real.sh:8:SELECT tenant_id, aggregate_id FROM snapshots;
./1_archive/root_sh/step_243_test_rls_real.sh:17:SELECT tenant_id, aggregate_id FROM snapshots;
./1_archive/root_sh/step_243_test_rls_real.sh:26:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-7.5 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-7.6 Input validation / injection protection izi

Pattern:

```text
validate|Validate|validation|binding|Bind|Parse|sanitize|Sanitize|QueryContext|ExecContext|\$[0-9]+|prepared|parameter|sql injection|injection
```

Match Count: 11097

```text
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:11:  local ad="$1"
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:12:  local desen="$2"
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:22:  local ad="$1"
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:23:  local url="$2"
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:24:  local expected="$3"
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:34:  local ad="$1"
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:35:  local url="$2"
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:36:  local expected="$3"
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:46:  local ad="$1"
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:47:  local container="$2"
./1_archive/root_sh/step_188_verify_done_items.sh:17:  echo "$1" | tee -a "$RAPOR_DOSYASI"
./1_archive/root_sh/step_188_verify_done_items.sh:21:  echo "$1" >> "$DETAY_DOSYASI"
./1_archive/root_sh/step_188_verify_done_items.sh:25:  local dosya="$1"
./1_archive/root_sh/step_188_verify_done_items.sh:49:  local dosya="$1"
./1_archive/root_sh/step_189_check_jetstream_streams.sh:9:for s in $(docker exec -it pix2pi_nats_cli nats stream ls 2>/dev/null | awk 'NR>1 {print $1}'); do
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:32:  pattern="$1"
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:41:  pattern="$1"
./1_archive/root_sh/step_210_audit_full.sh:24:func (a *AuditEngine) Validate(entry journal.JournalEntry) error {
./1_archive/root_sh/step_210_audit_full.sh:86:	if engine.Validate(entry) != nil {
./1_archive/root_sh/step_210_audit_full.sh:104:	if engine.Validate(entry) == nil {
./1_archive/root_sh/step_231_snapshot_full.sh:49:		VALUES ($1, $2, $3, 1, $4, NOW())
./1_archive/root_sh/step_231_snapshot_full.sh:72:		WHERE tenant_id = $1 AND aggregate_type = $2 AND aggregate_id = $3
./1_archive/root_sh/step_261_audit_full.sh:52:		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
./1_archive/root_sh/step_303_fix_systemd_units.sh:13:  FILE=$1
./1_archive/root_sh/step_306_kill_legacy_strict.sh:4:SYSTEMD_PIDS=$(systemctl status pix2pi-* | grep Main | awk '{print $3}')
./1_archive/root_sh/step_306_kill_legacy_strict.sh:12:  PID=$(echo $line | awk '{print $2}')
./1_archive/root_sh/step_317_trace_real_nginx_runtime.sh:8:MASTER_PID="$(ps -ef | grep 'nginx: master process' | grep -v grep | awk 'NR==1{print $2}')"
./1_archive/root_sh/step_318_kill_openresty_runtime.sh:7:PIDS=$(ps -ef | grep "/usr/local/openresty/nginx" | grep -v grep | awk '{print $2}')
./1_archive/root_sh/step_324_backup_status_engine.sh:4:FILE="$1"
./1_archive/root_sh/step_361_fix_panel_status_manual.sh:30:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
./1_archive/root_sh/step_361_fix_panel_status_source.sh:49:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
./1_archive/root_sh/step_362_fix_panel_ssl_service_status.sh:50:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
./1_archive/root_sh/step_363_clean_panel_ssl_routes.sh:51:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
./1_archive/root_sh/step_374_add_auto_heal_engine.sh:23:  echo "[$(timestamp)] $1" >> "$LOG"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:44:  echo "[$(timestamp)] $1" >> "$LOG_FILE"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:65:  local svc="$1"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:75:  local svc="$1"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:76:  local val="$2"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:81:  local svc="$1"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:86:  local svc="$1"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:91:  local svc="$1"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:113:  local svc="$1"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:120:  local kind="$1"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:121:  local svc="$2"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:122:  local detail="$3"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:127:  local svc="$1"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:145:  local svc="$1"
./1_archive/root_sh/step_378_add_alert_engine.sh:40:  echo "[$(timestamp)] $1" >> "$LOG_FILE"
./1_archive/root_sh/step_379_add_scale_hook.sh:23:  echo "[$(timestamp)] $1" >> "$LOG_FILE"
./1_archive/root_sh/step_380_bind_all_crons.sh:10:  local line="$1"
./1_archive/root_sh/step_382_dynamic_restart_patch.sh:20:  local svc="$1"
./1_archive/root_sh/step_390_rewrite_early_warning_clean.sh:69:  local logical_name="$1"
./1_archive/root_sh/step_390_rewrite_early_warning_clean.sh:70:  local unit_name="$2"
./1_archive/root_sh/step_392_production_hardening.sh:27:  file="/opt/pix2pi/runtime/auto_heal/lock/$1.lock"
./1_archive/root_sh/step_392_production_hardening.sh:32:  echo "$(now_ts)" > "/opt/pix2pi/runtime/auto_heal/lock/$1.lock"
./1_archive/root_sh/step_392_production_hardening.sh:36:  file="/opt/pix2pi/runtime/auto_heal/fail_counts/$1.count"
./1_archive/root_sh/step_392_production_hardening.sh:41:  file="/opt/pix2pi/runtime/auto_heal/fail_counts/$1.count"
./1_archive/root_sh/step_392_production_hardening.sh:42:  count=$(get_fail_count "$1")
./1_archive/root_sh/step_392_production_hardening.sh:47:  echo 0 > "/opt/pix2pi/runtime/auto_heal/fail_counts/$1.count"
./1_archive/root_sh/step_392_production_hardening.sh:51:  svc="$1"
./1_archive/root_sh/step_392_production_hardening.sh:66:  svc="$1"
./1_archive/root_sh/step_392_production_hardening.sh:67:  unit="$2"
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:105:	u, err := url.Parse(target)
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:94:	u, err := url.Parse(target)
./1_archive/root_sh/step_423c_db_auth_probe.sh:31:  local dsn="$1"
./1_archive/root_sh/step_423c_db_auth_probe.sh:32:  local key="$2"
./1_archive/root_sh/step_423c_db_auth_probe.sh:33:  printf '%s\n' "$dsn" | tr ' ' '\n' | awk -F= -v k="$key" '$1==k {sub($1"=",""); print; exit}'
./1_archive/root_sh/step_423c_db_auth_probe.sh:95:DB_CONTAINER="$(docker ps --format '{{.Names}} {{.Ports}}' | awk '/5433->5432/ {print $1; exit}')"
./1_archive/root_sh/step_423c_db_auth_probe.sh:117:  local password=***MASKED***
./1_archive/root_sh/step_423c_db_auth_probe.sh:122:  local password=***MASKED***
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-7.6 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-7.7 Rate limit / WAF / DDoS guardrail izi

Pattern:

```text
rate.*limit|RateLimit|limit_req|limit_conn|WAF|Cloudflare|cloudflare|DDoS|ddos|brute force|throttle|Throttle|Too Many Requests|429
```

Match Count: 300

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:1:limit_req_zone $binary_remote_addr zone=pix2pi_edge:20m rate=20r/s;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:65:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:91:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:124:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:150:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:1:limit_req_zone $binary_remote_addr zone=pix2pi_edge:20m rate=20r/s;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:65:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:91:        limit_req zone=pix2pi_edge burst=40 nodelay;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:124:        limit_req zone=pix2pi_edge burst=40 nodelay;
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
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:40:type RedisRateLimiter struct {
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:52:func NewRedisRateLimiter(addr string, limit int64, interval time.Duration) *RedisRateLimiter {
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:57:	return &RedisRateLimiter{
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:65:func (rl *RedisRateLimiter) Allow(tenantID string, scope string) (bool, int64, error) {
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:66:	key := "tenant:" + tenantID + ":gateway:" + scope + ":rate_limit"
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:214:func withTenantRedisRateLimit(rl *RedisRateLimiter, scope string, next http.Handler) http.Handler {
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:225:			log.Printf("redis rate limit hatasi tenant=%s scope=%s err=%v", tenantID, scope, err)
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:227:			_, _ = w.Write([]byte("redis rate limit hatasi"))
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:231:		w.Header().Set("X-RateLimit-Count", strconv.FormatInt(count, 10))
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:235:			_, _ = w.Write([]byte("tenant redis rate limit asildi"))
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:255:	redisLimiter := NewRedisRateLimiter("127.0.0.1:6379", 5, time.Minute)
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:266:			func(next http.Handler) http.Handler { return withTenantRedisRateLimit(redisLimiter, "identity", next) },
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:276:			func(next http.Handler) http.Handler { return withTenantRedisRateLimit(redisLimiter, "auth", next) },
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:29:type RedisRateLimiter struct {
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:41:func NewRedisRateLimiter(addr string, limit int64, interval time.Duration) *RedisRateLimiter {
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:46:	return &RedisRateLimiter{
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:54:func (rl *RedisRateLimiter) Allow(tenantID string, scope string) (bool, int64, error) {
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:55:	key := "tenant:" + tenantID + ":gateway:" + scope + ":rate_limit"
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:203:func withTenantRedisRateLimit(rl *RedisRateLimiter, scope string, next http.Handler) http.Handler {
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:214:			log.Printf("redis rate limit hatasi tenant=%s scope=%s err=%v", tenantID, scope, err)
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:216:			_, _ = w.Write([]byte("redis rate limit hatasi"))
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:220:		w.Header().Set("X-RateLimit-Count", strconv.FormatInt(count, 10))
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:224:			_, _ = w.Write([]byte("tenant redis rate limit asildi"))
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:244:	redisLimiter := NewRedisRateLimiter("127.0.0.1:6379", 5, time.Minute)
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:255:			func(next http.Handler) http.Handler { return withTenantRedisRateLimit(redisLimiter, "identity", next) },
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:265:			func(next http.Handler) http.Handler { return withTenantRedisRateLimit(redisLimiter, "auth", next) },
./1_archive/root_sh/step_69_backup_rate_limit.sh:9:  backups/app/manual/playground_main.go.rate_limit.bak 2>/dev/null || true
./1_archive/root_sh/step_69_backup_rate_limit.sh:11:echo "OK ✅ rate limit yedegi alindi"
./1_archive/root_sh/step_71_run_rate_limit_test.sh:8:echo "OK ✅ rate limit test calistirma bitti"
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:1:limit_req_zone $binary_remote_addr zone=pix2pi_edge:20m rate=20r/s;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:65:        limit_req zone=pix2pi_edge burst=40 nodelay;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:91:        limit_req zone=pix2pi_edge burst=40 nodelay;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:124:        limit_req zone=pix2pi_edge burst=40 nodelay;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:150:        limit_req zone=pix2pi_edge burst=40 nodelay;
./.backup/lvl10_live_finalize_20260422_063146/etc/nginx/nginx.conf:12:    limit_req_zone $binary_remote_addr zone=pix2pi_limit_zone:10m rate=20r/s;
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:23:type RedisRateLimiter struct {
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-7.7 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-7.8 Dependency / supply-chain security izi

Pattern:

```text
go\.sum|package-lock|yarn\.lock|pnpm-lock|govulncheck|npm audit|vulnerab|CVE|Dockerfile|image:|latest|supply.*chain|dependency.*scan
```

Match Count: 303

```text
./1_archive/root_sh/step_160_install_nats_event_bus.sh:11:    image: nats:2.10-alpine
./1_archive/root_sh/step_171_run_nats_cli.sh:9:  natsio/nats-box:latest \
./1_archive/root_sh/step_270_observability_stack.sh:19:    image: prom/prometheus:latest
./1_archive/root_sh/step_270_observability_stack.sh:30:    image: grafana/loki:2.9.8
./1_archive/root_sh/step_270_observability_stack.sh:42:    image: grafana/promtail:2.9.8
./1_archive/root_sh/step_270_observability_stack.sh:56:    image: grafana/grafana:latest
./1_archive/root_sh/step_270_observability_stack.sh:75:    image: prom/node-exporter:latest
./1_archive/root_sh/step_273_fix_promtail_positions.sh:43:    image: prom/prometheus:latest
./1_archive/root_sh/step_273_fix_promtail_positions.sh:54:    image: grafana/loki:2.9.8
./1_archive/root_sh/step_273_fix_promtail_positions.sh:66:    image: grafana/promtail:2.9.8
./1_archive/root_sh/step_273_fix_promtail_positions.sh:81:    image: grafana/grafana:latest
./1_archive/root_sh/step_273_fix_promtail_positions.sh:100:    image: prom/node-exporter:latest
./deploy/api-gateway/docker-compose.yml:3:    image: kong:3.7
./deploy/dev/docker-compose.pg.yml:3:    image: postgres:16
./deploy/docker-compose.yml:5:    image: postgres:15-alpine
./deploy/event-bus/docker-compose.yml:3:    image: nats:2.10
./deploy/nats/docker-compose.yml:3:    image: nats:2.10-alpine
./deploy/observability/docker-compose.yml:5:    image: prom/prometheus:latest
./deploy/observability/docker-compose.yml:16:    image: prom/node-exporter:latest
./deploy/observability/docker-compose.yml:25:    image: grafana/grafana:latest
./deploy/observability/docker-compose.yml:44:    image: grafana/loki:3.1.0
./deploy/observability/docker-compose.yml:57:    image: grafana/promtail:3.1.0
./deploy/observability/docker-compose.yml:71:    image: grafana/tempo:2.6.1
./deploy/redis/docker-compose.yml:3:    image: redis:7-alpine
./infra/observability/docker-compose.yml:3:    image: prom/prometheus:latest
./infra/observability/docker-compose.yml:14:    image: grafana/loki:2.9.8
./infra/observability/docker-compose.yml:26:    image: grafana/promtail:2.9.8
./infra/observability/docker-compose.yml:41:    image: grafana/grafana:latest
./infra/observability/docker-compose.yml:60:    image: prom/node-exporter:latest
./internal/erp/runtime/e2eflow/model.go:362:		CompletedAt:     latestStepCompletedAt(plan.Steps),
./internal/erp/runtime/e2eflow/model.go:367:func latestStepCompletedAt(steps []RuntimeFlowStep) time.Time {
./internal/erp/runtime/e2eflow/model.go:368:	var latest time.Time
./internal/erp/runtime/e2eflow/model.go:371:		if step.CompletedAt.After(latest) {
./internal/erp/runtime/e2eflow/model.go:372:			latest = step.CompletedAt
./internal/erp/runtime/e2eflow/model.go:376:	if latest.IsZero() {
./internal/erp/runtime/e2eflow/model.go:380:	return latest
./internal/platform/readcache/query_bridge_test.go:253:		t.Fatalf("expected latest loader result 7, got %d", second.Data.Count)
./internal/platform/readcache/rebuild_guard_test.go:277:		t.Fatalf("expected latest loader result 33, got %d", second.Data.Count)
./internal/platform/readcache/reporting_bridge_test.go:402:		t.Fatalf("expected latest loader result 2, got %d", second.Data.Count)
./reports/master_progress_report.json:117:                "reports/ops_health_latest.txt"
./reports/master_progress_report.json:210:                ".backups/2026/04/06/.__Dockerfile_144849.bak",
./reports/master_progress_report.json:211:                ".backups/2026/04/06/.__Dockerfile_150238.bak",
./reports/master_progress_report.json:212:                ".backups/2026/04/06/.__Dockerfile_150828.bak",
./reports/master_progress_report.json:213:                ".backups/2026/04/06/.__Dockerfile_152111.bak",
./reports/master_progress_report.json:214:                ".backups/2026/04/06/.__Dockerfile_225940.bak",
./reports/master_progress_report.json:215:                ".backups/2026/04/06/.__Dockerfile_232435.bak",
./reports/master_progress_report.json:216:                ".backups/2026/04/07/.__Dockerfile.identity_062900.bak",
./reports/master_progress_report.json:217:                ".backups/2026/04/07/.__Dockerfile.mission_062914.bak",
./reports/master_progress_report.json:218:                ".backups/2026/04/07/.__Dockerfile.mission_062916.bak",
./reports/master_progress_report.json:219:                ".backups/2026/04/07/.__Dockerfile.mission_062957.bak"
./reports/master_progress_report.json:444:                "reports/ops_health_latest.txt",
./reports/master_progress_report.json:525:                ".backups/2026/04/06/.__Dockerfile_144849.bak",
./reports/master_progress_report.json:526:                ".backups/2026/04/06/.__Dockerfile_150238.bak",
./reports/master_progress_report.json:527:                ".backups/2026/04/06/.__Dockerfile_150828.bak",
./reports/master_progress_report.json:528:                ".backups/2026/04/06/.__Dockerfile_152111.bak",
./reports/master_progress_report.json:529:                ".backups/2026/04/06/.__Dockerfile_225940.bak",
./reports/master_progress_report.json:530:                ".backups/2026/04/06/.__Dockerfile_232435.bak",
./reports/master_progress_report.json:554:                "reports/ops_alert_latest.txt",
./reports/master_progress_report.json:555:                "reports/ops_health_latest.txt",
./reports/master_progress_report_v2.json:146:              ".backups/2026/04/06/.__Dockerfile_144849.bak",
./reports/master_progress_report_v2.json:147:              ".backups/2026/04/06/.__Dockerfile_150238.bak",
./reports/master_progress_report_v2.json:148:              ".backups/2026/04/06/.__Dockerfile_150828.bak",
./reports/master_progress_report_v2.json:149:              ".backups/2026/04/06/.__Dockerfile_152111.bak",
./reports/master_progress_report_v2.json:150:              ".backups/2026/04/06/.__Dockerfile_225940.bak",
./reports/master_progress_report_v2.json:151:              ".backups/2026/04/06/.__Dockerfile_232435.bak",
./reports/master_progress_report_v2.json:152:              ".backups/2026/04/07/.__Dockerfile.identity_062900.bak",
./reports/master_progress_report_v2.json:153:              ".backups/2026/04/07/.__Dockerfile.mission_062914.bak",
./reports/master_progress_report_v2.json:154:              ".backups/2026/04/07/.__Dockerfile.mission_062916.bak",
./reports/master_progress_report_v2.json:155:              ".backups/2026/04/07/.__Dockerfile.mission_062957.bak",
./reports/master_progress_report_v2.json:156:              ".backups/2026/04/07/.__Dockerfile.registry_201553.bak",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-7.8 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-7.9 Audit / security logging izi

Pattern:

```text
audit|Audit|security|Security|unauthorized|forbidden|access denied|AccessDenied|tenant.*mismatch|auth.*fail|request_id|correlation_id|logger|slog|zap|logrus
```

Match Count: 1948

```text
./1_archive/root_sh/create_erp_structure.sh:14:mkdir -p $BASE/core/audit
./1_archive/root_sh/step_17_prepare_security_dir.sh:6:mkdir -p internal/platform/security/service
./1_archive/root_sh/step_17_prepare_security_dir.sh:8:echo "OK ✅ security klasoru hazir"
./1_archive/root_sh/step_210_audit_full.sh:6:mkdir -p $BASE/internal/platform/audit
./1_archive/root_sh/step_210_audit_full.sh:9:cat <<'GOEOF' > $BASE/internal/platform/audit/audit_engine.go
./1_archive/root_sh/step_210_audit_full.sh:10:package audit
./1_archive/root_sh/step_210_audit_full.sh:18:type AuditEngine struct{}
./1_archive/root_sh/step_210_audit_full.sh:20:func NewAuditEngine() *AuditEngine {
./1_archive/root_sh/step_210_audit_full.sh:21:	return &AuditEngine{}
./1_archive/root_sh/step_210_audit_full.sh:24:func (a *AuditEngine) Validate(entry journal.JournalEntry) error {
./1_archive/root_sh/step_210_audit_full.sh:64:cat <<'GOEOF' > $BASE/internal/platform/audit/audit_engine_test.go
./1_archive/root_sh/step_210_audit_full.sh:65:package audit
./1_archive/root_sh/step_210_audit_full.sh:73:func TestAudit_OK(t *testing.T) {
./1_archive/root_sh/step_210_audit_full.sh:75:	engine := NewAuditEngine()
./1_archive/root_sh/step_210_audit_full.sh:91:func TestAudit_Fail(t *testing.T) {
./1_archive/root_sh/step_210_audit_full.sh:93:	engine := NewAuditEngine()
./1_archive/root_sh/step_210_audit_full.sh:112:go test ./internal/platform/audit -v
./1_archive/root_sh/step_210_audit_full.sh:114:echo "OK ✅ audit FULL tamam"
./1_archive/root_sh/step_210_prepare_audit_folder.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/internal/platform/audit
./1_archive/root_sh/step_210_prepare_audit_folder.sh:6:echo "OK ✅ audit klasoru hazir"
./1_archive/root_sh/step_211_test_audit_engine.sh:6:go test ./internal/platform/audit -v
./1_archive/root_sh/step_211_test_audit_engine.sh:8:echo "OK ✅ audit test bitti"
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:74:if ! echo "$cikti_3" | grep -qi "row-level security"; then
./1_archive/root_sh/step_251_fix_verification.sh:17:if echo "$cikti" | grep -qi "row-level security"; then
./1_archive/root_sh/step_260_audit_schema.sh:6:cat <<'SQLEOF' > step_260_create_audit_tables.sql
./1_archive/root_sh/step_260_audit_schema.sh:7:CREATE TABLE IF NOT EXISTS audit_logs (
./1_archive/root_sh/step_260_audit_schema.sh:20:CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
./1_archive/root_sh/step_260_audit_schema.sh:21:ON audit_logs (tenant_id, created_at DESC);
./1_archive/root_sh/step_260_audit_schema.sh:23:CREATE INDEX IF NOT EXISTS idx_audit_logs_action
./1_archive/root_sh/step_260_audit_schema.sh:24:ON audit_logs (action);
./1_archive/root_sh/step_260_audit_schema.sh:26:CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
./1_archive/root_sh/step_260_audit_schema.sh:27:ON audit_logs (entity_type, entity_id);
./1_archive/root_sh/step_260_audit_schema.sh:30:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_260_audit_schema.sh:32:echo "OK ✅ audit schema hazir"
./1_archive/root_sh/step_261_audit_full.sh:6:mkdir -p $BASE/internal/platform/auditlog
./1_archive/root_sh/step_261_audit_full.sh:8:cat <<'GOEOF' > $BASE/internal/platform/auditlog/auditlog.go
./1_archive/root_sh/step_261_audit_full.sh:9:package auditlog
./1_archive/root_sh/step_261_audit_full.sh:42:		INSERT INTO audit_logs (
./1_archive/root_sh/step_261_audit_full.sh:68:cat <<'GOEOF' > $BASE/internal/platform/auditlog/auditlog_test.go
./1_archive/root_sh/step_261_audit_full.sh:69:package auditlog
./1_archive/root_sh/step_261_audit_full.sh:79:func TestAuditLogRepositoryIntegration(t *testing.T) {
./1_archive/root_sh/step_261_audit_full.sh:95:		TenantID:   "tenant-audit-test",
./1_archive/root_sh/step_261_audit_full.sh:108:		t.Fatalf("audit write hatasi: %v", err)
./1_archive/root_sh/step_261_audit_full.sh:114:		FROM audit_logs
./1_archive/root_sh/step_261_audit_full.sh:115:		WHERE tenant_id = 'tenant-audit-test'
./1_archive/root_sh/step_261_audit_full.sh:120:		t.Fatalf("audit read hatasi: %v", err)
./1_archive/root_sh/step_261_audit_full.sh:124:		t.Fatalf("audit kaydi bulunamadi")
./1_archive/root_sh/step_261_audit_full.sh:130:PIX2PI_DB_TEST=1 go test ./internal/platform/auditlog -v
./1_archive/root_sh/step_261_audit_full.sh:132:echo "OK ✅ audit log engine hazir"
./1_archive/root_sh/step_262_run_audit_flow.sh:18:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_262_run_audit_flow.sh:20:echo "OK ✅ audit flow bitti"
./1_archive/root_sh/step_276_reduce_log_noise.sh:35:          __path__: /var/log/syslog
./1_archive/root_sh/step_28_backup_audit_log_engine.sh:9:  backups/app/manual/playground_main.go.audit_log_engine.bak 2>/dev/null || true
./1_archive/root_sh/step_28_backup_audit_log_engine.sh:11:echo "OK ✅ audit log engine yedegi alindi"
./1_archive/root_sh/step_29_prepare_audit_dirs.sh:6:mkdir -p internal/platform/audit/domain
./1_archive/root_sh/step_29_prepare_audit_dirs.sh:7:mkdir -p internal/platform/audit/service
./1_archive/root_sh/step_29_prepare_audit_dirs.sh:9:echo "OK ✅ audit klasorleri hazir"
./1_archive/root_sh/step_30_run_audit_log_engine_test.sh:8:echo "OK ✅ audit log engine test calistirma bitti"
./1_archive/root_sh/step_374_add_auto_heal_engine.sh:47:      systemctl restart pix2pi-auth || log "auth restart fail"
./1_archive/root_sql/step_260_create_audit_tables.sql:1:CREATE TABLE IF NOT EXISTS audit_logs (
./1_archive/root_sql/step_260_create_audit_tables.sql:14:CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
./1_archive/root_sql/step_260_create_audit_tables.sql:15:ON audit_logs (tenant_id, created_at DESC);
./1_archive/root_sql/step_260_create_audit_tables.sql:17:CREATE INDEX IF NOT EXISTS idx_audit_logs_action
./1_archive/root_sql/step_260_create_audit_tables.sql:18:ON audit_logs (action);
./1_archive/root_sql/step_260_create_audit_tables.sql:20:CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
./1_archive/root_sql/step_260_create_audit_tables.sql:21:ON audit_logs (entity_type, entity_id);
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh:30:grep -q 'id: tenant_security' "${CATALOG_FILE}"
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh:31:echo "OK ✅ tenant/security signal grubu var"
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2049:      "integrity": "sha512-YpgQiITW3JXGntzdUmyUR1V812Hn8T1YVXhCu+wO3OpS4eU9l4YdD3qjyiKdV6mvV29zapkMeD390UVEf2lkUg==",
./cmd/accounting-service/accounting_service_main.go:19:	auditlog "github.com/divrigili/pix2pi-SaaS/internal/platform/auditlog"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-7.9 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-7.10 Security test / audit script izi

Pattern:

```text
security.*test|test.*security|hardening|guardrail|audit.*security|security.*audit|FAZ_6_7|tenant.*test|auth.*test|jwt.*test
```

Match Count: 331

```text
./1_archive/root_sh/step_10_run_tenant_event_pipeline_test.sh:8:echo "OK ✅ tenant event pipeline test calistirma bitti"
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:36:echo "OK ✅ tenant middleware test bitti"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:46:echo "OK ✅ redis tenant rate limit test bitti"
./1_archive/root_sh/step_123_test_auth_api_local.sh:7:echo "OK ✅ auth api local test bitti"
./1_archive/root_sh/step_124_test_auth_via_gateway.sh:4:curl -i -H "X-Tenant-ID: tenant-auth-test" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_124_test_auth_via_gateway.sh:7:echo "OK ✅ auth gateway test bitti"
./1_archive/root_sh/step_12_run_tenant_service_filter_test.sh:8:echo "OK ✅ tenant service filter test calistirma bitti"
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:44:echo "OK ✅ bearer tenant match test bitti"
./1_archive/root_sh/step_15_run_redis_tenant_namespace_test.sh:8:echo "OK ✅ redis tenant namespace test calistirma bitti"
./1_archive/root_sh/step_1_backup_tenant_test.sh:9:  backups/app/manual/playground_main.go.tenant_test.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_tenant_test.sh:11:echo "OK ✅ tenant test yedegi alindi"
./1_archive/root_sh/step_231_snapshot_full.sh:108:	_, err = db.Exec(`DELETE FROM snapshots WHERE tenant_id = 'tenant-test'`)
./1_archive/root_sh/step_231_snapshot_full.sh:115:	err = repo.UpsertStockSaleSnapshot("tenant-test", "S-TEST-1", 1200)
./1_archive/root_sh/step_231_snapshot_full.sh:120:	state, version, err := repo.GetSnapshot("tenant-test", "stock", "S-TEST-1")
./1_archive/root_sh/step_231_snapshot_full.sh:133:	err = repo.UpsertStockSaleSnapshot("tenant-test", "S-TEST-1", 1500)
./1_archive/root_sh/step_231_snapshot_full.sh:138:	state, version, err = repo.GetSnapshot("tenant-test", "stock", "S-TEST-1")
./1_archive/root_sh/step_241_test_rls_snapshots.sh:15:echo "=== tenant-test goruntuleme ==="
./1_archive/root_sh/step_241_test_rls_snapshots.sh:18:SET LOCAL app.current_tenant = 'tenant-test';
./1_archive/root_sh/step_243_test_rls_real.sh:13:echo "=== tenant-test ==="
./1_archive/root_sh/step_243_test_rls_real.sh:16:SET LOCAL app.current_tenant = 'tenant-test';
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:16:if echo "$cikti_1" | grep -q "tenant-test"; then
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:17:  echo "HATA ❌ tenant-001, tenant-test verisini gordu"
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:29:echo "=== TEST 2: tenant-test sadece kendini gorebilir ==="
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:32:SET LOCAL app.current_tenant = 'tenant-test';
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:42:  echo "HATA ❌ tenant-test, tenant-001 verisini gordu"
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:46:if ! echo "$cikti_2" | grep -q "tenant-test"; then
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:47:  echo "HATA ❌ tenant-test kendi verisini goremedi"
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:51:echo "OK ✅ tenant-test izolasyonu dogru"
./1_archive/root_sh/step_261_audit_full.sh:95:		TenantID:   "tenant-audit-test",
./1_archive/root_sh/step_261_audit_full.sh:115:		WHERE tenant_id = 'tenant-audit-test'
./1_archive/root_sh/step_2_run_tenant_test.sh:8:echo "OK ✅ tenant test calistirma bitti"
./1_archive/root_sh/step_392_production_hardening.sh:13:echo "2. hardening logic ekleniyor..."
./1_archive/root_sh/step_392_production_hardening.sh:96:echo "OK ✅ hardening eklendi"
./1_archive/root_sh/step_5_run_jwt_tenant_test.sh:8:echo "OK ✅ jwt tenant test calistirma bitti"
./1_archive/root_sh/step_8_run_jwt_middleware_test.sh:8:echo "OK ✅ jwt middleware test calistirma bitti"
./configs/faz5/faz5_final_closure_v1.json:98:      "production_hardening",
./db/migrations/001_phase1_foundation.up.sql:113:  ('audit', 'audit events and export records', 'tenant', 'security'),
./db/migrations/20260429_213001_security_audit_event_model.down.sql:1:DROP TABLE IF EXISTS platform_security.audit_integrity_chain;
./db/migrations/20260429_213001_security_audit_event_model.down.sql:2:DROP TABLE IF EXISTS platform_security.audit_decision_contexts;
./db/migrations/20260429_213001_security_audit_event_model.down.sql:3:DROP TABLE IF EXISTS platform_security.audit_resource_contexts;
./db/migrations/20260429_213001_security_audit_event_model.down.sql:4:DROP TABLE IF EXISTS platform_security.audit_actor_contexts;
./db/migrations/20260429_213001_security_audit_event_model.down.sql:5:DROP TABLE IF EXISTS platform_security.audit_events;
./db/migrations/20260429_213001_security_audit_event_model.down.sql:6:DROP TABLE IF EXISTS platform_security.audit_event_streams;
./db/migrations/20260429_213001_security_audit_event_model.up.sql:3:CREATE TABLE IF NOT EXISTS platform_security.audit_event_streams (
./db/migrations/20260429_213001_security_audit_event_model.up.sql:13:    retention_policy_code text NOT NULL DEFAULT 'security_audit_default',
./db/migrations/20260429_213001_security_audit_event_model.up.sql:22:CREATE TABLE IF NOT EXISTS platform_security.audit_events (
./db/migrations/20260429_213001_security_audit_event_model.up.sql:60:CREATE TABLE IF NOT EXISTS platform_security.audit_actor_contexts (
./db/migrations/20260429_213001_security_audit_event_model.up.sql:81:CREATE TABLE IF NOT EXISTS platform_security.audit_resource_contexts (
./db/migrations/20260429_213001_security_audit_event_model.up.sql:102:CREATE TABLE IF NOT EXISTS platform_security.audit_decision_contexts (
./db/migrations/20260429_213001_security_audit_event_model.up.sql:125:CREATE TABLE IF NOT EXISTS platform_security.audit_integrity_chain (
./db/migrations/20260429_213001_security_audit_event_model.up.sql:145:    ON platform_security.audit_event_streams (tenant_id, stream_code);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:148:    ON platform_security.audit_event_streams (tenant_id, status_code);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:151:    ON platform_security.audit_events (tenant_id, audit_event_stream_id);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:154:    ON platform_security.audit_events (tenant_id, occurred_at);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:157:    ON platform_security.audit_events (tenant_id, actor_user_id);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:160:    ON platform_security.audit_events (tenant_id, permission_code);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:163:    ON platform_security.audit_events (tenant_id, resource_area, resource_name);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:166:    ON platform_security.audit_events (tenant_id, decision);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:169:    ON platform_security.audit_events (tenant_id, request_id);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:172:    ON platform_security.audit_actor_contexts (tenant_id, audit_event_id);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:175:    ON platform_security.audit_actor_contexts (tenant_id, actor_user_id);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:178:    ON platform_security.audit_resource_contexts (tenant_id, audit_event_id);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:181:    ON platform_security.audit_resource_contexts (tenant_id, resource_area, resource_name);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:184:    ON platform_security.audit_decision_contexts (tenant_id, audit_event_id);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:187:    ON platform_security.audit_decision_contexts (tenant_id, decision);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:190:    ON platform_security.audit_integrity_chain (tenant_id, audit_event_stream_id);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:193:    ON platform_security.audit_integrity_chain (tenant_id, audit_event_stream_id, chain_no);
./deploy/edge/scripts/lvl10_hardening_smoke.sh:15:echo "OK ✅ tls protocols hardening var"
./install_phase1_scaffold.sh:137:  ('audit', 'audit events and export records', 'tenant', 'security'),
./install_phase1_scaffold.sh:637:cat > "$ROOT_DIR/db/tests/001_phase1_cross_tenant_security.sql" <<'EOF'
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-7.10 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-7.11 CORS / header policy izi

Pattern:

```text
CORS|cors|Access-Control-Allow|Access-Control|allowed_origins|origin|Origin|security header|add_header
```

Match Count: 411

```text
./1_archive/root_sh/step_192_reporting_service_panelde_goster.sh:46:    original = text
./1_archive/root_sh/step_361_fix_panel_status_manual.sh:30:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
./1_archive/root_sh/step_361_fix_panel_status_source.sh:49:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
./1_archive/root_sh/step_362_fix_panel_ssl_service_status.sh:50:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
./1_archive/root_sh/step_363_clean_panel_ssl_routes.sh:51:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:111:	originalDirector := p.Director
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:114:		originalDirector(r)
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:100:	originalDirector := p.Director
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:103:		originalDirector(r)
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:94:	originalDirector := p.Director
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:97:		originalDirector(r)
./cmd/control-panel/control_panel.go:55:		originalURL := c.OriginalURL()
./cmd/control-panel/control_panel.go:56:		targetPath := originalURL
./db/migrations/20260428_143001_import_staging_tables.up.sql:40:    original_file_name text NOT NULL,
./deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf:5:add_header X-Edge-Trusted-Proxy "127.0.0.1/32" always;
./deploy/edge/nginx/includes/pix2pi_security_headers.conf:1:add_header X-Frame-Options "SAMEORIGIN" always;
./deploy/edge/nginx/includes/pix2pi_security_headers.conf:2:add_header X-Content-Type-Options "nosniff" always;
./deploy/edge/nginx/includes/pix2pi_security_headers.conf:3:add_header Referrer-Policy "strict-origin-when-cross-origin" always;
./deploy/edge/nginx/includes/pix2pi_security_headers.conf:4:add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
./deploy/edge/nginx/includes/pix2pi_security_headers.conf:5:add_header X-XSS-Protection "1; mode=block" always;
./deploy/edge/nginx/includes/pix2pi_tls_policy.conf:9:add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
./deploy/edge/nginx/includes/pix2pi_tls_policy.conf:10:add_header X-Frame-Options "SAMEORIGIN" always;
./deploy/edge/nginx/includes/pix2pi_tls_policy.conf:11:add_header X-Content-Type-Options "nosniff" always;
./deploy/edge/nginx/includes/pix2pi_tls_policy.conf:12:add_header Referrer-Policy "strict-origin-when-cross-origin" always;
./deploy/edge/nginx/includes/pix2pi_tls_policy.conf:13:add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
./deploy/edge/nginx/includes/pix2pi_tls_policy.conf:14:add_header X-XSS-Protection "1; mode=block" always;
./deploy/edge/scripts/lvl10_edge_smoke.sh:36:grep -q 'add_header X-Frame-Options "SAMEORIGIN" always;' \
./deploy/edge/scripts/lvl10_edge_smoke.sh:38:echo "OK ✅ security headers include hazir"
./internal/platform/publicapi/gateway_contract.go:60:	Origin      string `json:"origin,omitempty"`
./internal/platform/publicapi/gateway_contract.go:102:	origin := strings.TrimSpace(r.Origin)
./internal/platform/publicapi/gateway_contract.go:103:	if origin != "" && !(strings.HasPrefix(origin, "https://") || strings.HasPrefix(origin, "http://")) {
./internal/platform/publicapi/gateway_contract.go:104:		errs = append(errs, ValidationError{Field: "origin", Message: "http veya https URL olmali"})
./internal/platform/publicapi/gateway_service.go:17:	Origin      string
./internal/platform/publicapi/gateway_service.go:61:	req.Origin = strings.TrimSpace(req.Origin)
./internal/platform/publicapi/gateway_service.go:75:		Origin:      req.Origin,
./internal/platform/publicapi/gateway_service_test.go:31:		Origin:      "https://developer.pix2pi.com.tr",
./internal/platform/publicapi/gateway_service_test.go:112:		Origin:      "https://developer.pix2pi.com.tr",
./internal/platform/publicapi/gateway_store.go:52:    origin,
./internal/platform/publicapi/gateway_store.go:113:		strings.TrimSpace(cmd.Origin),
./internal/platform/publicapi/gateway_store_test.go:73:		Origin:      "https://developer.pix2pi.com.tr",
./internal/platform/realtime/runtime_integration_test.go:21:	Origin           string
./internal/platform/realtime/runtime_integration_test.go:66:		Origin:           strings.TrimSpace(cmd.Origin),
./internal/platform/realtime/runtime_integration_test.go:106:		Origin:           strings.TrimSpace(cmd.Origin),
./internal/platform/realtime/runtime_integration_test.go:281:		Origin:       "https://panel.pix2pi.com.tr",
./internal/platform/realtime/runtime_integration_test.go:379:		Origin:       "https://panel.pix2pi.com.tr",
./internal/platform/realtime/sse_contract.go:26:	Origin        string `json:"origin,omitempty"`
./internal/platform/realtime/sse_contract.go:75:	origin := strings.TrimSpace(r.Origin)
./internal/platform/realtime/sse_contract.go:76:	if origin != "" && !(strings.HasPrefix(origin, "https://") || strings.HasPrefix(origin, "http://")) {
./internal/platform/realtime/sse_contract.go:77:		errs = append(errs, ValidationError{Field: "origin", Message: "http veya https URL olmali"})
./internal/platform/realtime/sse_service.go:19:	Origin       string
./internal/platform/realtime/sse_service.go:65:	req.Origin = strings.TrimSpace(req.Origin)
./internal/platform/realtime/sse_service.go:81:		Origin:       req.Origin,
./internal/platform/realtime/sse_service_test.go:33:		Origin:       "https://panel.pix2pi.com.tr",
./internal/platform/realtime/sse_service_test.go:120:		Origin:       "https://panel.pix2pi.com.tr",
./internal/platform/realtime/sse_store.go:35:    origin,
./internal/platform/realtime/sse_store.go:75:    origin = EXCLUDED.origin,
./internal/platform/realtime/sse_store.go:121:		strings.TrimSpace(cmd.Origin),
./internal/platform/realtime/sse_store_test.go:75:		Origin:       "https://panel.pix2pi.com.tr",
./internal/platform/realtime/sse_store_test.go:209:		Origin:       "https://panel.pix2pi.com.tr",
./internal/platform/realtime/websocket_contract.go:57:	Origin       string `json:"origin,omitempty"`
./internal/platform/realtime/websocket_contract.go:101:	origin := strings.TrimSpace(r.Origin)
./internal/platform/realtime/websocket_contract.go:102:	if origin != "" && !(strings.HasPrefix(origin, "https://") || strings.HasPrefix(origin, "http://")) {
./internal/platform/realtime/websocket_contract.go:103:		errs = append(errs, ValidationError{Field: "origin", Message: "http veya https URL olmali"})
./internal/platform/realtime/websocket_service.go:18:	Origin       string
./internal/platform/realtime/websocket_service.go:62:	req.Origin = strings.TrimSpace(req.Origin)
./internal/platform/realtime/websocket_service.go:77:		Origin:       req.Origin,
./internal/platform/realtime/websocket_service_test.go:32:		Origin:       "https://panel.pix2pi.com.tr",
./internal/platform/realtime/websocket_service_test.go:116:		Origin:       "https://panel.pix2pi.com.tr",
./internal/platform/realtime/websocket_store.go:34:    origin,
./internal/platform/realtime/websocket_store.go:72:    origin = EXCLUDED.origin,
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-7.11 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-7.12 File upload / content validation izi

Pattern:

```text
multipart|file upload|upload|Content-Type|content type|mime|MIME|max file|file size|virus|scan
```

Match Count: 661

```text
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:144:	w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:455:  -H "Content-Type: application/json" \
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:463:  -H "Content-Type: application/json" \
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:165:	w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:174:	w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_232_run_snapshot_flow.sh:13:-H "Content-Type: application/json" \
./1_archive/root_sh/step_262_run_audit_flow.sh:13:-H "Content-Type: application/json" \
./1_archive/root_sh/step_291_watchdog_service.sh:112:		w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_331_rewrite_watchdog_advanced_state_engine.sh:385:	w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_339_rewrite_watchdog_main.sh:364:	w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_340_rewrite_watchdog_main_fixed_path.sh:212:	w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_378_add_alert_engine.sh:66:    -H "Content-Type: application/json" \
./1_archive/root_sh/step_404_scan_db_entrypoints.sh:23:echo "OK ✅ scan tamam"
./1_archive/root_sh/step_406_scan_kernel_usage.sh:17:echo "OK ✅ scan tamam"
./1_archive/root_sh/step_407_scan_db_usage.sh:15:echo "OK ✅ scan tamam"
./1_archive/root_sh/step_408c_find_real_routes.sh:25:echo "OK ✅ scan tamam"
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:283:		w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:274:			w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:284:		w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_418_fix_gateway_panic.sh:25:			w.Header().Set("Content-Type", "application/json")\
./1_archive/root_sh/step_418_fix_gateway_panic.sh:34:		w.Header().Set("Content-Type", "application/json")\
./1_archive/root_sh/step_420_rewrite_gateway.sh:41:			w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_420_rewrite_gateway.sh:50:		w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_422_rewrite_gateway_with_db_init.sh:41:			w.Header().Set("Content-Type", "application/json")
./1_archive/root_sh/step_422_rewrite_gateway_with_db_init.sh:50:		w.Header().Set("Content-Type", "application/json")
./.backup/lvl10_live_finalize_20260422_063146/etc/nginx/nginx.conf:26:	include /etc/nginx/mime.types;
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2021:        "whatwg-mimetype": "^5.0.0",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2652:        "whatwg-mimetype": "^5.0.0",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:3991:    "node_modules/whatwg-mimetype": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:3993:      "resolved": "https://registry.npmjs.org/whatwg-mimetype/-/whatwg-mimetype-5.0.0.tgz",
./.backups/step_417_20260323_074642/cmd/api-gateway/api_gateway_main.go:266:		w.Header().Set("Content-Type", "application/json")
./.backups/step_422_20260323_080757/cmd/api-gateway/api_gateway_main.go:31:			w.Header().Set("Content-Type", "application/json")
./.backups/step_422_20260323_080757/cmd/api-gateway/api_gateway_main.go:40:		w.Header().Set("Content-Type", "application/json")
./cmd/api-gateway/gateway_middleware.go:145:	w.Header().Set("Content-Type", "application/json")
./cmd/auth-api/auth_api_main.go:20:	w.Header().Set("Content-Type", "application/json")
./cmd/cache-service/cache_service_main.go:75:		w.Header().Set("Content-Type", "application/json")
./cmd/cache-service/cache_service_main.go:130:		w.Header().Set("Content-Type", "application/json")
./cmd/cache-service/cache_service_main.go:156:				w.Header().Set("Content-Type", "application/json")
./cmd/cache-service/cache_service_main.go:180:		w.Header().Set("Content-Type", "application/json")
./cmd/cache-service/cache_service_main.go:216:		w.Header().Set("Content-Type", "application/json")
./cmd/early-warning-runtime/early_warning_runtime_main.go:304:	scanner := bufio.NewScanner(file)
./cmd/early-warning-runtime/early_warning_runtime_main.go:306:	for scanner.Scan() {
./cmd/early-warning-runtime/early_warning_runtime_main.go:307:		fields := strings.Fields(scanner.Text())
./cmd/identity-api/identity_api_main.go:86:	w.Header().Set("Content-Type", "application/json")
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:155:func scanString(value sql.NullString) string {
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:162:func scanTime(value sql.NullTime) string {
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:330:			item.DetectedAt = scanTime(detectedAt)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:331:			item.AcknowledgedAt = scanTime(acknowledgedAt)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:332:			item.ResolvedAt = scanTime(resolvedAt)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:333:			item.ClosedAt = scanTime(closedAt)
./cmd/jobs-runtime/jobs_runtime_main.go:126:func scanString(value sql.NullString) string {
./cmd/jobs-runtime/jobs_runtime_main.go:133:func scanTime(value sql.NullTime) string {
./cmd/jobs-runtime/jobs_runtime_main.go:360:			item.LastError = scanString(lastError)
./cmd/jobs-runtime/jobs_runtime_main.go:361:			item.LockedBy = scanString(lockedBy)
./cmd/jobs-runtime/jobs_runtime_main.go:362:			item.AvailableAt = scanTime(availableAt)
./cmd/mission-control/mission_control_main.go:58:		w.Header().Set("Content-Type", "application/json")
./cmd/notification-runtime/notification_runtime_main.go:135:func scanString(value sql.NullString) string {
./cmd/notification-runtime/notification_runtime_main.go:142:func scanTime(value sql.NullTime) string {
./cmd/notification-runtime/notification_runtime_main.go:370:			item.ScheduledAt = scanTime(scheduledAt)
./cmd/notification-runtime/notification_runtime_main.go:371:			item.SentAt = scanTime(sentAt)
./cmd/notification-runtime/notification_runtime_main.go:432:			item.DeliveredAt = scanTime(deliveredAt)
./cmd/notification-runtime/notification_runtime_main.go:494:			item.DeliveredAt = scanTime(deliveredAt)
./cmd/plugin-runtime/plugin_runtime_main.go:126:func scanString(value sql.NullString) string {
./cmd/plugin-runtime/plugin_runtime_main.go:133:func scanTime(value sql.NullTime) string {
./cmd/plugin-runtime/plugin_runtime_main.go:298:			item.EntrypointRef = scanString(entrypointRef)
./cmd/plugin-runtime/plugin_runtime_main.go:299:			item.Checksum = scanString(checksum)
./cmd/plugin-runtime/plugin_runtime_main.go:300:			item.RequiredPlatformVersion = scanString(requiredPlatformVersion)
./cmd/plugin-runtime/plugin_runtime_main.go:301:			item.PublishedAt = scanTime(publishedAt)
./cmd/plugin-runtime/plugin_runtime_main.go:302:			item.DeprecatedAt = scanTime(deprecatedAt)
./cmd/plugin-runtime/plugin_runtime_main.go:303:			item.ArchivedAt = scanTime(archivedAt)
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-7.12 STATUS=IMPLEMENTED_OR_PRESENT ✅

# Final Runtime Implementation Interpretation

```text
REQUIRED_FAIL=0
OPTIONAL_WARN=0
FAZ_6_7_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_7_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_8_READY=YES ✅
FAZ_6_7_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅
```
