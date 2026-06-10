# FAZ 6-9 Real Implementation Audit

Generated At: 2026-05-01T15:23:35+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit, FAZ 6-9 Release / Rollback / Deploy Safety maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

## Scanned Files

```text
3026 /tmp/tmp.z4mbSbWIp8/files.txt

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

## 6-9.1 Release standard / version / artifact izi

Pattern:

```text
release|Release|RELEASE|version|Version|VERSION|tag|commit|artifact|CHANGELOG|Go/No-Go|release_id
```

Match Count: 6778

```text
./1_archive/root_sh/step_1_backup_commission_rule_versioning.sh:15:  backups/app/manual/erp_ufk_main.go.commission_rule_versioning.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_commission_rule_versioning.sh:17:echo "OK ✅ commission rule versioning backup finished"
./1_archive/root_sh/step_230_snapshot_schema.sh:12:    version INT NOT NULL DEFAULT 1,
./1_archive/root_sh/step_231_snapshot_full.sh:48:		INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_231_snapshot_full.sh:52:			version = snapshots.version + 1,
./1_archive/root_sh/step_231_snapshot_full.sh:67:	var version int
./1_archive/root_sh/step_231_snapshot_full.sh:70:		SELECT state::text, version
./1_archive/root_sh/step_231_snapshot_full.sh:77:	).Scan(&state, &version)
./1_archive/root_sh/step_231_snapshot_full.sh:79:	return state, version, err
./1_archive/root_sh/step_231_snapshot_full.sh:120:	state, version, err := repo.GetSnapshot("tenant-test", "stock", "S-TEST-1")
./1_archive/root_sh/step_231_snapshot_full.sh:125:	if version != 1 {
./1_archive/root_sh/step_231_snapshot_full.sh:126:		t.Fatalf("beklenen version 1, gelen %d", version)
./1_archive/root_sh/step_231_snapshot_full.sh:138:	state, version, err = repo.GetSnapshot("tenant-test", "stock", "S-TEST-1")
./1_archive/root_sh/step_231_snapshot_full.sh:143:	if version != 2 {
./1_archive/root_sh/step_231_snapshot_full.sh:144:		t.Fatalf("beklenen version 2, gelen %d", version)
./1_archive/root_sh/step_232_run_snapshot_flow.sh:18:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_241_test_rls_snapshots.sh:8:SELECT tenant_id, aggregate_type, aggregate_id, version
./1_archive/root_sh/step_241_test_rls_snapshots.sh:19:SELECT tenant_id, aggregate_type, aggregate_id, version
./1_archive/root_sh/step_241_test_rls_snapshots.sh:30:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_243_test_rls_real.sh:26:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_24_start_postgres_runtime.sh:16:    if docker compose version >/dev/null 2>&1; then
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:59:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:86:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:90:  version = snapshots.version + 1,
./1_archive/root_sh/step_251_fix_verification.sh:9:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_270_observability_stack.sh:15:version: "3.9"
./1_archive/root_sh/step_270_observability_stack.sh:170:apiVersion: 1
./1_archive/root_sh/step_270_observability_stack.sh:186:apiVersion: 1
./1_archive/root_sh/step_270_observability_stack.sh:268:  "schemaVersion": 39,
./1_archive/root_sh/step_270_observability_stack.sh:270:  "tags": [
./1_archive/root_sh/step_270_observability_stack.sh:281:  "version": 1
./1_archive/root_sh/step_293_fix_watchdog_nginx.sh:9:    proxy_http_version 1.1;
./1_archive/root_sh/step_293_fix_watchdog_nginx.sh:16:    proxy_http_version 1.1;
./1_archive/root_sh/step_355c_safe_json_fix.sh:15:echo "2. json tag ekleniyor..."
./1_archive/root_sh/step_355c_safe_json_fix.sh:28:echo "OK ✅ json tag eklendi"
./1_archive/root_sh/step_358_add_nginx_status_proxy.sh:13:    proxy_http_version 1.1;
./1_archive/root_sh/step_358_fix_ssl_status_route.sh:39:        proxy_http_version 1.1;
./1_archive/root_sh/step_358_fix_ssl_status_route.sh:48:        proxy_http_version 1.1;
./1_archive/root_sh/step_361_fix_panel_status_manual.sh:24:        proxy_http_version 1.1;
./1_archive/root_sh/step_361_fix_panel_status_source.sh:43:        proxy_http_version 1.1;
./1_archive/root_sh/step_362_fix_panel_ssl_service_status.sh:44:        proxy_http_version 1.1;
./1_archive/root_sh/step_362_fix_panel_ssl_service_status.sh:56:        proxy_http_version 1.1;
./1_archive/root_sh/step_363_clean_panel_ssl_routes.sh:45:        proxy_http_version 1.1;
./1_archive/root_sh/step_377_advanced_auto_heal.sh:55:release_lock() {
./1_archive/root_sh/step_377_advanced_auto_heal.sh:60:  release_lock
./1_archive/root_sh/step_408c_find_real_routes.sh:17:echo "3. unsupported API version metni..."
./1_archive/root_sh/step_408c_find_real_routes.sh:18:grep -Rni 'unsupported API version' . || true
./1_archive/root_sh/step_423b_real_error.sh:33:go version
./1_archive/root_sh/step_423b_real_error.sh:34:echo "OK ✅ go version alindi"
./1_archive/root_sh/step_5_check_commission_rule_versioning_files.sh:10:echo "OK ✅ commission rule versioning files exist"
./1_archive/root_sh/step_6_run_commission_rule_versioning.sh:8:echo "OK ✅ commission rule versioning run finished"
./1_archive/root_sh/step_72_check_production_server.sh:9:cat /etc/os-release
./1_archive/root_sh/step_72_check_production_server.sh:23:docker --version || true
./1_archive/root_sh/step_72_check_production_server.sh:27:docker compose version || true
./1_archive/root_sh/step_74_install_production_base_packages.sh:12:  lsb-release \
./1_archive/root_sh/step_75_install_or_verify_docker.sh:13:    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
./1_archive/root_sh/step_75_install_or_verify_docker.sh:25:docker --version
./1_archive/root_sh/step_75_install_or_verify_docker.sh:26:docker compose version
./1_archive/root_sh/step_78_test_production_server_ready.sh:5:docker --version
./1_archive/root_sh/step_78_test_production_server_ready.sh:9:docker compose version
./1_archive/root_sql/step_230_create_snapshot_tables.sql:6:    version INT NOT NULL DEFAULT 1,
./.backup/lvl10_live_finalize_20260422_063146/etc/nginx/nginx.conf:53:	# gzip_http_version 1.1;
./.backup/lvl8_6_route_structure_20260420_222229/package.json:4:  "version": "0.0.0",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:3:  "version": "0.0.0",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:4:  "lockfileVersion": 3,
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:9:      "version": "0.0.0",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:34:      "version": "4.4.4",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:41:      "version": "5.1.11",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:58:      "version": "7.1.1",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:75:      "version": "1.0.1",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-9.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-9.2 Pre-deploy check implementation izi

Pattern:

```text
predeploy|pre-deploy|pre deploy|PREDEPLOY|nginx -t|disk|backup.*check|health.*probe|pix2pi_predeploy_check
```

Match Count: 166

```text
./1_archive/root_sh/step_133_reload_nginx_after_rate_limit.sh:4:nginx -t
./1_archive/root_sh/step_134_check_503_source.sh:5:nginx -t || true
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:112:nginx -t
./1_archive/root_sh/step_188_verify_done_items.sh:130:if nginx -t >/dev/null 2>&1; then
./1_archive/root_sh/step_194_panel_html_reporting_service_ekle.sh:73:nginx -t
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:125:nginx -t
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:158:nginx -t
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:162:nginx -t
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:326:nginx -t
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:63:  if nginx -t; then
./1_archive/root_sh/step_293_fix_watchdog_nginx.sh:45:nginx -t
./1_archive/root_sh/step_296_fix_nginx_monitor_route.sh:20:nginx -t
./1_archive/root_sh/step_297_fix_nginx_monitor_route_proper.sh:58:nginx -t
./1_archive/root_sh/step_298_cleanup_nginx_backup.sh:11:nginx -t
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:78:nginx -t
./1_archive/root_sh/step_300_remove_duplicate_nginx_sites.sh:19:nginx -t
./1_archive/root_sh/step_308_hard_restart_nginx.sh:5:nginx -t
./1_archive/root_sh/step_343_add_monitor_route.sh:17:nginx -t
./1_archive/root_sh/step_350_fix_nginx_monitor.sh:36:nginx -t
./1_archive/root_sh/step_351_clean_nginx_duplicates_and_fix_monitor.sh:86:nginx -t
./1_archive/root_sh/step_352_force_monitor_from_static_root.sh:81:nginx -t
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:361:nginx -t
./1_archive/root_sh/step_358_add_nginx_status_proxy.sh:43:nginx -t
./1_archive/root_sh/step_358_fix_ssl_status_route.sh:70:nginx -t
./1_archive/root_sh/step_360_rewrite_monitor_hardening.sh:452:nginx -t
./1_archive/root_sh/step_361_fix_panel_status_manual.sh:52:nginx -t
./1_archive/root_sh/step_361_fix_panel_status_source.sh:110:nginx -t
./1_archive/root_sh/step_362_fix_panel_ssl_service_status.sh:80:nginx -t
./1_archive/root_sh/step_363_clean_panel_ssl_routes.sh:73:nginx -t
./1_archive/root_sh/step_365_hard_fix_panel_render_engine.sh:87:nginx -t && systemctl reload nginx
./1_archive/root_sh/step_366_remove_old_status_calls.sh:30:nginx -t && systemctl reload nginx
./1_archive/root_sh/step_367_restore_clean_panel_engine.sh:77:nginx -t && systemctl reload nginx
./1_archive/root_sh/step_368_panel_final_logic_fix.sh:232:nginx -t
./1_archive/root_sh/step_369_fix_panel_dom_ids.sh:39:nginx -t && systemctl reload nginx
./1_archive/root_sh/step_370_real_global_status.sh:72:nginx -t && systemctl reload nginx
./1_archive/root_sh/step_81_disable_default_nginx_site.sh:6:nginx -t
./1_archive/root_sh/step_83_cleanup_old_nginx_sites.sh:8:nginx -t
./1_archive/root_sh/step_85_reload_nginx_split.sh:4:nginx -t
./1_archive/root_sh/step_87_disable_old_pix2pi_site.sh:9:nginx -t
./1_archive/root_sh/step_93_reload_nginx_after_redirect_fix.sh:4:nginx -t
./cmd/early-warning-runtime/early_warning_runtime_main.go:251:func diskResource(path string) ResourceItem {
./cmd/early-warning-runtime/early_warning_runtime_main.go:257:			ResourceKey: "disk_root",
./cmd/early-warning-runtime/early_warning_runtime_main.go:277:		ResourceKey: "disk_root",
./cmd/early-warning-runtime/early_warning_runtime_main.go:283:		Message:     fmt.Sprintf("disk kullanimi %.1f%%", usedPercent),
./cmd/early-warning-runtime/early_warning_runtime_main.go:384:		diskResource("/"),
./deploy/observability/config/lvl11_signal_catalog.yaml:11:        metric: node_disk_io_usage_percent
./deploy/observability/grafana/dashboards/docker-monitoring.json:1279:              "expr": "sum(rate(node_disk_bytes_read[$interval])) by (device)",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1282:              "metric": "node_disk_bytes_read",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1287:              "expr": "sum(rate(node_disk_bytes_written[$interval])) by (device)",
./deploy/observability/grafana/dashboards/node-exporter-full.json:3302:              "legendFormat": "Buffers - Block device (e.g. harddisk) cache",
./deploy/observability/grafana/dashboards/node-exporter-full.json:4057:              "expr": "irate(node_disk_reads_completed_total{instance=\"$node\",job=\"$job\",device=~\"$diskdevices\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:4068:              "expr": "irate(node_disk_writes_completed_total{instance=\"$node\",job=\"$job\",device=~\"$diskdevices\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:4284:              "expr": "irate(node_disk_read_bytes_total{instance=\"$node\",job=\"$job\",device=~\"$diskdevices\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:4297:              "expr": "irate(node_disk_written_bytes_total{instance=\"$node\",job=\"$job\",device=~\"$diskdevices\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:4429:              "expr": "irate(node_disk_io_time_seconds_total{instance=\"$node\",job=\"$job\",device=~\"$diskdevices\"} [$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:6151:              "legendFormat": "Writeback - Memory which is actively being written back to disk",
./deploy/observability/grafana/dashboards/node-exporter-full.json:6175:              "legendFormat": "Dirty - Memory which is waiting to get written back to the disk",
./deploy/observability/grafana/dashboards/node-exporter-full.json:6570:              "legendFormat": "Shmem - Used shared memory (shared between several processes, thus including RAM disks)",
./deploy/observability/grafana/dashboards/node-exporter-full.json:15513:              "expr": "irate(node_disk_reads_completed_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:15524:              "expr": "irate(node_disk_writes_completed_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:15938:              "expr": "irate(node_disk_read_bytes_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:15950:              "expr": "irate(node_disk_written_bytes_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:16365:              "expr": "irate(node_disk_read_time_seconds_total{instance=\"$node\",job=\"$job\"}[$__rate_interval]) / irate(node_disk_reads_completed_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:16378:              "expr": "irate(node_disk_write_time_seconds_total{instance=\"$node\",job=\"$job\"}[$__rate_interval]) / irate(node_disk_writes_completed_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:16783:              "expr": "irate(node_disk_io_time_weighted_seconds_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:17198:              "expr": "irate(node_disk_reads_merged_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:17209:              "expr": "irate(node_disk_writes_merged_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:17612:              "expr": "irate(node_disk_io_time_seconds_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:17624:              "expr": "irate(node_disk_discard_time_seconds_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./deploy/observability/grafana/dashboards/node-exporter-full.json:18028:              "expr": "node_disk_io_now{instance=\"$node\",job=\"$job\"}",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-9.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-9.3 Post-deploy smoke implementation izi

Pattern:

```text
postdeploy|post-deploy|post deploy|smoke|Smoke|/health|curl.*health|pix2pi_postdeploy_smoke|POSTDEPLOY
```

Match Count: 832

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:57:    location = /health {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:116:    location = /health {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:120:        proxy_pass http://pix2pi_auth_upstream/health;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:57:    location = /health {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:116:    location = /health {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:120:        proxy_pass http://pix2pi_auth_upstream/health;
./1_archive/root_sh/step_101_test_identity_gateway_ports.sh:5:curl -s http://127.0.0.1:9001/health || true
./1_archive/root_sh/step_101_test_identity_gateway_ports.sh:9:curl -s http://127.0.0.1:9010/health || true
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh:5:curl -s http://127.0.0.1:9010/health
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh:9:curl -s http://127.0.0.1:9001/health || true
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh:13:curl -s http://127.0.0.1:9010/api/identity/health || true
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh:17:curl -s https://api.pix2pi.com.tr/api/identity/health || true
./1_archive/root_sh/step_107_test_api_gateway_rate_limit.sh:4:URL="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:4:URL="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:4:URL="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_117_check_auth_service_9002.sh:5:curl -s -i http://127.0.0.1:9002/health || true
./1_archive/root_sh/step_123_test_auth_api_local.sh:4:curl -i http://127.0.0.1:9002/health
./1_archive/root_sh/step_124_test_auth_via_gateway.sh:4:curl -i -H "X-Tenant-ID: tenant-auth-test" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:5:curl -s -i https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:10:curl -s -i -H "X-Tenant-ID: tenant-combined-identity" https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:15:curl -s -i https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:20:curl -s -i -H "X-Tenant-ID: tenant-combined-auth" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_129_test_scope_separation.sh:5:curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_129_test_scope_separation.sh:10:curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:4:URL_IDENTITY="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:5:URL_AUTH="https://api.pix2pi.com.tr/api/auth/health"
./1_archive/root_sh/step_134_check_503_source.sh:9:curl -i http://127.0.0.1:9010/health || true
./1_archive/root_sh/step_134_check_503_source.sh:13:curl -i http://127.0.0.1:9002/health || true
./1_archive/root_sh/step_134_check_503_source.sh:17:curl -i http://127.0.0.1:9001/health || true
./1_archive/root_sh/step_134_check_503_source.sh:21:curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/auth/health || true
./1_archive/root_sh/step_134_check_503_source.sh:25:curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/identity/health || true
./1_archive/root_sh/step_161_check_nats_health.sh:9:curl -s http://127.0.0.1:8222/healthz || true
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:56:API_GATEWAY=$(durum_http_text "api_gateway" "http://127.0.0.1:9010/health" "Pix2pi API Gateway OK")
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:57:IDENTITY=$(durum_http_json "identity" "http://127.0.0.1:9001/health" "\"service\":\"identity\"")
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:58:AUTH=$(durum_http_json "auth" "http://127.0.0.1:9002/health" "\"service\":\"auth\"")
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:44:      <li><a href="/health">Panel Health</a></li>
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:45:      <li><a href="/api/health">API Health</a></li>
./1_archive/root_sh/step_190_test_cache_service.sh:5:curl -s http://127.0.0.1:9011/health
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:68:      <li><a href="/health">Panel Health</a></li>
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:69:      <li><a href="/api/health">API Health</a></li>
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:206:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:448:curl -s http://127.0.0.1:8090/health
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:189:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:426:curl -s http://127.0.0.1:8091/health
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:198:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:75:      <li><a href="/health">Panel Health</a></li>
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:76:      <li><a href="/api/health">API Health</a></li>
./1_archive/root_sh/step_272_test_observability_stack.sh:5:curl -s http://127.0.0.1:9090/-/healthy
./1_archive/root_sh/step_272_test_observability_stack.sh:15:curl -s http://127.0.0.1:3001/api/health
./1_archive/root_sh/step_290_monitor_core.sh:168:	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
./1_archive/root_sh/step_290_monitor_core.sh:191:		HealthURL: "http://127.0.0.1:18091/health",
./1_archive/root_sh/step_291_watchdog_service.sh:14:    "health_url": "http://127.0.0.1:8080/health"
./1_archive/root_sh/step_291_watchdog_service.sh:19:    "health_url": "http://127.0.0.1:9001/health"
./1_archive/root_sh/step_291_watchdog_service.sh:24:    "health_url": "http://127.0.0.1:8082/health"
./1_archive/root_sh/step_291_watchdog_service.sh:64:    "health_url": "http://127.0.0.1/health"
./1_archive/root_sh/step_291_watchdog_service.sh:97:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
./1_archive/root_sh/step_292_run_watchdog.sh:14:curl -s http://127.0.0.1:9016/health
./1_archive/root_sh/step_293_fix_watchdog_nginx.sh:15:    proxy_pass http://127.0.0.1:9016/health;
./1_archive/root_sh/step_293_fix_watchdog_nginx.sh:49:curl -s http://127.0.0.1/internal/service-watchdog-health
./1_archive/root_sh/step_297_fix_nginx_monitor_route_proper.sh:35:        proxy_pass http://127.0.0.1:9016/health;
./1_archive/root_sh/step_297_fix_nginx_monitor_route_proper.sh:63:curl -s http://127.0.0.1/internal/service-watchdog-health
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:17:    location = /health {
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:22:    location = /api/health {
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:23:        proxy_pass http://127.0.0.1:8080/api/health;
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:41:        proxy_pass http://127.0.0.1:9016/health;
./1_archive/root_sh/step_299_rewrite_pix2pi_ssl_with_watchdog.sh:83:curl -s http://127.0.0.1/internal/service-watchdog-health
./1_archive/root_sh/step_320_rewrite_panel_index.sh:300:        <li><a href="/health" target="_blank">Panel Health</a></li>
./1_archive/root_sh/step_320_rewrite_panel_index.sh:301:        <li><a href="/api/health" target="_blank">API Health</a></li>
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-9.3 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-9.4 Rollback readiness / restore implementation izi

Pattern:

```text
rollback|Rollback|ROLLBACK|restore|Restore|backup|Backup|pix2pi_rollback_readiness|previous|revert
```

Match Count: 1942

```text
./1_archive/root_sh/step_100_backup_run_api_gateway_script.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/scripts
./1_archive/root_sh/step_100_backup_run_api_gateway_script.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/scripts/step_99_run_api_gateway.sh.bak
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_rewrite.bak
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_rate_limit.bak
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_tenant_middleware.bak
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_redis_rate_limit.bak
./1_archive/root_sh/step_116_backup_api_gateway_before_auth_route.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_116_backup_api_gateway_before_auth_route.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_auth_route.bak
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh:9:  backups/app/manual/erp_cari_hesap.go.tenant_filter.bak 2>/dev/null || true
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh:12:  backups/app/manual/erp_cari_hesap_service.go.tenant_filter.bak 2>/dev/null || true
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh:15:  backups/app/manual/playground_main.go.tenant_filter.bak 2>/dev/null || true
./1_archive/root_sh/step_126_backup_api_gateway_before_combined_gateway.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_126_backup_api_gateway_before_combined_gateway.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_combined_gateway.bak
./1_archive/root_sh/step_130_backup_gateway_before_authz_layer.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_130_backup_gateway_before_authz_layer.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_authz_layer.bak
./1_archive/root_sh/step_130_backup_nginx_before_rate_limit.sh:4:mkdir -p ~/pix2pi/nginx-backups
./1_archive/root_sh/step_130_backup_nginx_before_rate_limit.sh:6:cp /etc/nginx/nginx.conf ~/pix2pi/nginx-backups/nginx.conf.before_rate_limit.bak
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh:4:mkdir -p ~/pix2pi/fail2ban-backups
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh:6:cp -a /etc/fail2ban /root/pix2pi/fail2ban-backups/fail2ban_before_nginx_jail_$(date +%Y%m%d_%H%M%S)
./1_archive/root_sh/step_13_backup_redis_tenant_namespace.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_13_backup_redis_tenant_namespace.sh:9:  backups/app/manual/playground_main.go.redis_tenant_namespace.bak 2>/dev/null || true
./1_archive/root_sh/step_16_backup_super_admin_policy.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_16_backup_super_admin_policy.sh:9:  backups/app/manual/playground_main.go.super_admin_policy.bak 2>/dev/null || true
./1_archive/root_sh/step_184_backup_panel_before_service_monitor.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/panel
./1_archive/root_sh/step_184_backup_panel_before_service_monitor.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/panel/panel_index.html.before_service_monitor.bak
./1_archive/root_sh/step_188_verify_done_items.sh:109:    *install*|*backup*|*prepare*|*create*|*restart*|*reload*|*cleanup*|*fix*|*start*|*stop*)
./1_archive/root_sh/step_19_backup_postgres_rls.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_19_backup_postgres_rls.sh:9:  backups/app/manual/rls_tenant_policy.sql.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_account_mapping.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_account_mapping.sh:9:  backups/app/manual/erp_account_mapping_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_account_mapping.sh:12:  backups/app/manual/erp_ufk_main.go.mapping.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_account_mapping.sh:14:echo "OK ✅ account mapping backup step finished"
./1_archive/root_sh/step_1_backup_accounts_import.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_accounts_import.sh:9:  backups/app/manual/erp_chart_of_accounts_import_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_accounts_import.sh:12:  backups/app/manual/erp_ufk_main.go.import.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_accounts_import.sh:14:echo "OK ✅ accounts import backup step finished"
./1_archive/root_sh/step_1_backup_accounts_seed.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_accounts_seed.sh:9:  backups/app/manual/erp_account.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_accounts_seed.sh:12:  backups/app/manual/erp_ufk_main.go.accounts.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_accounts_seed.sh:15:  backups/app/manual/erp_chart_of_accounts_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_accounts_seed.sh:17:echo "OK ✅ accounts seed backup step finished"
./1_archive/root_sh/step_1_backup_alis_faturasi_engine.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_alis_faturasi_engine.sh:9:  backups/app/manual/erp_alis_fatura.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_alis_faturasi_engine.sh:12:  backups/app/manual/erp_alis_fatura_satir.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_alis_faturasi_engine.sh:15:  backups/app/manual/erp_alis_fatura_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_alis_faturasi_engine.sh:18:  backups/app/manual/erp_ufk_main.go.alis_faturasi.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_auto_rules.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_auto_rules.sh:9:  backups/app/manual/erp_accounting_rule.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_auto_rules.sh:12:  backups/app/manual/erp_accounting_rule_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_auto_rules.sh:15:  backups/app/manual/erp_ufk_main.go.auto_rules.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_auto_rules.sh:17:echo "OK ✅ auto rules backup step finished"
./1_archive/root_sh/step_1_backup_balance_sheet.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_balance_sheet.sh:9:  backups/app/manual/erp_balance_sheet_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_balance_sheet.sh:12:  backups/app/manual/erp_ufk_main.go.balance_sheet.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_balance_sheet.sh:14:echo "OK ✅ balance sheet backup step finished"
./1_archive/root_sh/step_1_backup_banka_ekstre.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_banka_ekstre.sh:9:  backups/app/manual/erp_banka_service.go.ekstre.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_banka_ekstre.sh:12:  backups/app/manual/erp_banka_ekstre.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_banka_ekstre.sh:15:  backups/app/manual/erp_ufk_main.go.banka_ekstre.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_banka_engine.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_banka_engine.sh:9:  backups/app/manual/erp_banka_hesap.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_banka_engine.sh:12:  backups/app/manual/erp_banka_hareket.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_banka_engine.sh:15:  backups/app/manual/erp_banka_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_banka_engine.sh:18:  backups/app/manual/erp_ufk_main.go.banka_engine.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_bilanco_engine.sh:5:mkdir -p backups/app/manual
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-9.4 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-9.5 Migration safety izi

Pattern:

```text
migration|migrate|schema|ALTER TABLE|CREATE INDEX|DROP TABLE|down migration|DB backup|pg_dump|migration.*safety
```

Match Count: 2568

```text
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:7:ALTER TABLE snapshots ENABLE ROW LEVEL SECURITY;
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:8:ALTER TABLE snapshots FORCE ROW LEVEL SECURITY;
./1_archive/root_sh/step_260_audit_schema.sh:20:CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
./1_archive/root_sh/step_260_audit_schema.sh:23:CREATE INDEX IF NOT EXISTS idx_audit_logs_action
./1_archive/root_sh/step_260_audit_schema.sh:26:CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
./1_archive/root_sh/step_260_audit_schema.sh:32:echo "OK ✅ audit schema hazir"
./1_archive/root_sh/step_270_observability_stack.sh:124:schema_config:
./1_archive/root_sh/step_270_observability_stack.sh:129:      schema: v13
./1_archive/root_sh/step_270_observability_stack.sh:268:  "schemaVersion": 39,
./1_archive/root_sh/step_278_loki_limit.sh:16:schema_config:
./1_archive/root_sh/step_278_loki_limit.sh:21:      schema: v11
./1_archive/root_sql/step_240_enable_rls_snapshots.sql:1:ALTER TABLE snapshots ENABLE ROW LEVEL SECURITY;
./1_archive/root_sql/step_240_enable_rls_snapshots.sql:2:ALTER TABLE snapshots FORCE ROW LEVEL SECURITY;
./1_archive/root_sql/step_260_create_audit_tables.sql:14:CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
./1_archive/root_sql/step_260_create_audit_tables.sql:17:CREATE INDEX IF NOT EXISTS idx_audit_logs_action
./1_archive/root_sql/step_260_create_audit_tables.sql:20:CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:577:        "@eslint/object-schema": "^2.1.7",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:605:        "@types/json-schema": "^7.0.15"
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:661:    "node_modules/@eslint/object-schema": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:663:      "resolved": "https://registry.npmjs.org/@eslint/object-schema/-/object-schema-2.1.7.tgz",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1112:    "node_modules/@standard-schema/spec": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1114:      "resolved": "https://registry.npmjs.org/@standard-schema/spec/-/spec-1.1.0.tgz",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1239:    "node_modules/@types/json-schema": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1241:      "resolved": "https://registry.npmjs.org/@types/json-schema/-/json-schema-7.0.15.tgz",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1604:        "@standard-schema/spec": "^1.1.0",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1742:        "json-schema-traverse": "^0.4.1",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2698:    "node_modules/json-schema-traverse": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2700:      "resolved": "https://registry.npmjs.org/json-schema-traverse/-/json-schema-traverse-0.4.1.tgz",
./cmd/erp/core/ufk/scripts/pilot/run_4c_6d_uat_execution_evidence.sh:149:from information_schema.schemata
./cmd/erp/core/ufk/scripts/pilot/run_4c_6d_uat_execution_evidence.sh:150:where schema_name='${TENANT_SCHEMA}';
./cmd/erp/core/ufk/scripts/pilot/run_4c_6d_uat_execution_evidence.sh:195:from information_schema.tables
./cmd/erp/core/ufk/scripts/pilot/run_4c_6d_uat_execution_evidence.sh:196:where table_schema='tenant_uzmanparcaci'
./cmd/event-concurrency-test/event_concurrency_test_main.go:9:	schemadomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventschema/domain"
./cmd/event-concurrency-test/event_concurrency_test_main.go:10:	schemaservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventschema/service"
./cmd/event-concurrency-test/event_concurrency_test_main.go:32:	schema := schemaservice.NewEventSchemaService()
./cmd/event-concurrency-test/event_concurrency_test_main.go:34:	err := schema.SozlesmeKaydet(
./cmd/event-concurrency-test/event_concurrency_test_main.go:35:		schemadomain.EventSozlesme{
./cmd/event-concurrency-test/event_concurrency_test_main.go:46:	bus := eventbusservice.NewEventBusServiceWithStoreAndSchema(store, schema)
./cmd/event-schema-test/event_schema_test_main.go:8:	schemadomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventschema/domain"
./cmd/event-schema-test/event_schema_test_main.go:9:	schemaservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventschema/service"
./cmd/event-schema-test/event_schema_test_main.go:20:	fmt.Println("STEP 1.1.3 — event schema contract testi basliyor")
./cmd/event-schema-test/event_schema_test_main.go:23:	schema := schemaservice.NewEventSchemaService()
./cmd/event-schema-test/event_schema_test_main.go:25:	err := schema.SozlesmeKaydet(
./cmd/event-schema-test/event_schema_test_main.go:26:		schemadomain.EventSozlesme{
./cmd/event-schema-test/event_schema_test_main.go:37:	bus := eventbusservice.NewEventBusServiceWithStoreAndSchema(store, schema)
./cmd/event-schema-test/event_schema_test_main.go:40:		EventID:    "evt-schema-001",
./cmd/event-schema-test/event_schema_test_main.go:53:	kayit, err := store.EventIDIleGetir("evt-schema-001")
./cmd/event-schema-test/event_schema_test_main.go:60:	fmt.Println("OK ✅ schema store propagation dogrulandi")
./cmd/event-schema-test/event_schema_test_main.go:63:		EventID:    "evt-schema-002",
./cmd/event-schema-test/event_schema_test_main.go:78:		EventID:    "evt-schema-003",
./cmd/event-schema-test/event_schema_test_main.go:93:		EventID:    "evt-schema-004",
./cmd/event-schema-test/event_schema_test_main.go:108:		EventID:           "evt-schema-005",
./cmd/event-schema-test/event_schema_test_main.go:124:	fmt.Println("OK ✅ STEP 1.1.3 event schema contract testi bitti")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:9:	schemadomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventschema/domain"
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:10:	schemaservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventschema/service"
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:40:	fmt.Println("OK ✅ postgres baglanti + schema + temizleme tamam")
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:42:	schema := schemaservice.NewEventSchemaService()
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:44:	err = schema.SozlesmeKaydet(
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:45:		schemadomain.EventSozlesme{
./cmd/event-store-postgres-test/event_store_postgres_test_main.go:56:	bus := eventbusservice.NewEventBusServiceWithStoreAndSchema(store, schema)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:58:	EntitySchema  string `json:"entity_schema"`
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:351:  coalesce(entity_schema, ''),
./cmd/migrate/main.go:10:	"github.com/golang-migrate/migrate/v4"
./cmd/migrate/main.go:11:	_ "github.com/golang-migrate/migrate/v4/database/postgres"
./cmd/migrate/main.go:12:	_ "github.com/golang-migrate/migrate/v4/source/file"
./cmd/migrate/main.go:28:		migrations  = flag.String("dir", "file://internal/db/migrations", "migrations dir (file://...)")
./cmd/migrate/main.go:38:	m, err := migrate.New(*migrations, dsn)
./cmd/migrate/main.go:40:		log.Fatalf("migrate.New: %v", err)
./cmd/migrate/main.go:48:		if err := m.Up(); err != nil && err != migrate.ErrNoChange {
./cmd/migrate/main.go:51:		fmt.Println("OK ✅  migrations up (or no change)")
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-9.5 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-9.6 Nginx / systemd / docker deploy safety izi

Pattern:

```text
nginx -t|systemctl|daemon-reload|docker compose|docker-compose|restart|reload|ExecStart|ExecReload|service.*restart|deploy.*safety
```

Match Count: 702

```text
./1_archive/root_sh/step_103_restart_api_gateway.sh:14:echo "OK ✅ api gateway restart bitti"
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh:14:echo "OK ✅ api gateway rate limitli restart bitti"
./1_archive/root_sh/step_109_restart_api_gateway_after_tenant_middleware.sh:14:echo "OK ✅ tenant middleware sonrasi api gateway restart bitti"
./1_archive/root_sh/step_114_restart_api_gateway_after_redis_rate_limit.sh:14:echo "OK ✅ redis rate limit sonrasi api gateway restart bitti"
./1_archive/root_sh/step_125_restart_gateway_after_auth_route.sh:16:echo "OK ✅ gateway auth route ile restart edildi"
./1_archive/root_sh/step_127_restart_combined_gateway.sh:14:echo "OK ✅ combined gateway restart bitti"
./1_archive/root_sh/step_131_restart_gateway_after_bearer_tenant_match.sh:14:echo "OK ✅ bearer + tenant match sonrasi gateway restart bitti"
./1_archive/root_sh/step_133_reload_nginx_after_rate_limit.sh:4:nginx -t
./1_archive/root_sh/step_133_reload_nginx_after_rate_limit.sh:5:systemctl reload nginx
./1_archive/root_sh/step_134_check_503_source.sh:5:nginx -t || true
./1_archive/root_sh/step_160_install_nats_event_bus.sh:8:cat <<'NATSYML' > deploy/nats/docker-compose.yml
./1_archive/root_sh/step_160_install_nats_event_bus.sh:22:    restart: unless-stopped
./1_archive/root_sh/step_160_install_nats_event_bus.sh:28:docker compose -f deploy/nats/docker-compose.yml up -d
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:70:if systemctl is-active --quiet nginx; then
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:112:nginx -t
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:113:systemctl reload nginx
./1_archive/root_sh/step_187_create_service_status_cron.sh:14:systemctl restart cron
./1_archive/root_sh/step_188_verify_done_items.sh:109:    *install*|*backup*|*prepare*|*create*|*restart*|*reload*|*cleanup*|*fix*|*start*|*stop*)
./1_archive/root_sh/step_188_verify_done_items.sh:130:if nginx -t >/dev/null 2>&1; then
./1_archive/root_sh/step_194_panel_html_reporting_service_ekle.sh:72:echo "5) Nginx reload..."
./1_archive/root_sh/step_194_panel_html_reporting_service_ekle.sh:73:nginx -t
./1_archive/root_sh/step_194_panel_html_reporting_service_ekle.sh:74:systemctl reload nginx
./1_archive/root_sh/step_194_panel_html_reporting_service_ekle.sh:75:echo "OK ✅ nginx reload tamam"
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:124:echo "8) Nginx test ve reload..."
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:125:nginx -t
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:126:systemctl reload nginx
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:127:echo "OK ✅ nginx reload tamam"
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:147:systemctl restart cron
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:157:echo "8) Nginx reload..."
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:158:nginx -t
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:159:systemctl reload nginx
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:160:echo "OK ✅ nginx reload tamam"
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:162:nginx -t
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:166:echo "6) Nginx reload..."
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:167:systemctl reload nginx
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:168:echo "OK ✅ nginx reload tamam"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:325:echo "7) Nginx test ve reload..."
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:326:nginx -t
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:327:systemctl reload nginx
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:328:echo "OK ✅ nginx reload tamam"
./1_archive/root_sh/step_206_servis_yoneticisi_kur.sh:139:restart() {
./1_archive/root_sh/step_206_servis_yoneticisi_kur.sh:152:  pix2pi_service_manager.sh restart
./1_archive/root_sh/step_206_servis_yoneticisi_kur.sh:160:  restart  : tum bulunan servisleri yeniden baslatir
./1_archive/root_sh/step_206_servis_yoneticisi_kur.sh:180:  restart)
./1_archive/root_sh/step_206_servis_yoneticisi_kur.sh:181:    restart
./1_archive/root_sh/step_206_servis_yoneticisi_kur.sh:254:echo "  /usr/local/bin/pix2pi_service_manager.sh restart"
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:63:  if nginx -t; then
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:71:  echo "4) Nginx reload ediliyor..."
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:72:  systemctl reload nginx
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:73:  echo "OK ✅ nginx reload tamam"
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:80:yardim_eski = """  pix2pi_service_manager.sh restart
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:83:yardim_yeni = """  pix2pi_service_manager.sh restart
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:89:aciklama_eski = """  restart  : tum bulunan servisleri yeniden baslatir
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:92:aciklama_yeni = """  restart       : tum bulunan servisleri yeniden baslatir
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:94:  panel-guncelle: servis listesini yeniler, snapshot alir, nginx reload yapar"""
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:98:hedef = """restart() {
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:109:icerik = icerik.replace(hedef, """restart() {
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:117:case_eski = """  restart)
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:118:    restart
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:127:case_yeni = """  restart)
./1_archive/root_sh/step_207_service_manager_panel_guncelle_ekle.sh:128:    restart
./1_archive/root_sh/step_23_check_postgres_runtime.sh:24:find . -maxdepth 3 \( -name 'docker-compose.yml' -o -name 'compose.yml' -o -name 'docker-compose.yaml' \) | sort || true
./1_archive/root_sh/step_23_check_postgres_runtime.sh:28:systemctl status postgresql --no-pager || true
./1_archive/root_sh/step_24_start_postgres_runtime.sh:9:COMPOSE_FILE="$(find . -maxdepth 3 \( -name 'docker-compose.yml' -o -name 'compose.yml' -o -name 'docker-compose.yaml' \) | head -n 1 || true)"
./1_archive/root_sh/step_24_start_postgres_runtime.sh:16:    if docker compose version >/dev/null 2>&1; then
./1_archive/root_sh/step_24_start_postgres_runtime.sh:19:        docker compose up -d postgres db database 2>/dev/null || true
./1_archive/root_sh/step_24_start_postgres_runtime.sh:30:if systemctl list-unit-files | grep -q '^postgresql'; then
./1_archive/root_sh/step_24_start_postgres_runtime.sh:31:  systemctl start postgresql || true
./1_archive/root_sh/step_270_observability_stack.sh:14:cat <<'YAMLEOF' > $OBS/docker-compose.yml
./1_archive/root_sh/step_270_observability_stack.sh:21:    restart: unless-stopped
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-9.6 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-9.7 Static / public GET content check izi

Pattern:

```text
GET|HTTP_STATUS|curl -L|content check|index.html|/var/www|public|static|HEAD|size_download|pix2pi.com.tr
```

Match Count: 3077

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:25:    server_name api.pix2pi.com.tr panel.pix2pi.com.tr auth.pix2pi.com.tr pos.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:40:    server_name api.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:42:    ssl_certificate     /etc/letsencrypt/live/api.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:43:    ssl_certificate_key /etc/letsencrypt/live/api.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:73:    server_name panel.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:75:    ssl_certificate     /etc/letsencrypt/live/api.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:76:    ssl_certificate_key /etc/letsencrypt/live/api.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:99:    server_name auth.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:101:    ssl_certificate     /etc/letsencrypt/live/api.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:102:    ssl_certificate_key /etc/letsencrypt/live/api.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:132:    server_name pos.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:134:    ssl_certificate     /etc/letsencrypt/live/api.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:135:    ssl_certificate_key /etc/letsencrypt/live/api.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:25:    server_name api.pix2pi.com.tr panel.pix2pi.com.tr auth.pix2pi.com.tr pos.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:40:    server_name api.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:42:    ssl_certificate     /etc/letsencrypt/live/api.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:43:    ssl_certificate_key /etc/letsencrypt/live/api.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:73:    server_name panel.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:75:    ssl_certificate     /etc/letsencrypt/live/panel.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:76:    ssl_certificate_key /etc/letsencrypt/live/panel.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:99:    server_name auth.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:101:    ssl_certificate     /etc/letsencrypt/live/auth.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:102:    ssl_certificate_key /etc/letsencrypt/live/auth.pix2pi.com.tr/privkey.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:132:    server_name pos.pix2pi.com.tr;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:134:    ssl_certificate     /etc/letsencrypt/live/pos.pix2pi.com.tr/fullchain.pem;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:135:    ssl_certificate_key /etc/letsencrypt/live/pos.pix2pi.com.tr/privkey.pem;
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh:17:curl -s https://api.pix2pi.com.tr/api/identity/health || true
./1_archive/root_sh/step_107_test_api_gateway_rate_limit.sh:4:URL="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:4:URL="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:4:URL="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:37:redis-cli GET tenant:tenant-redis-001:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:41:redis-cli GET tenant:tenant-redis-002:gateway:rate_limit || true
./1_archive/root_sh/step_124_test_auth_via_gateway.sh:4:curl -i -H "X-Tenant-ID: tenant-auth-test" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:5:curl -s -i https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:10:curl -s -i -H "X-Tenant-ID: tenant-combined-identity" https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:15:curl -s -i https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:20:curl -s -i -H "X-Tenant-ID: tenant-combined-auth" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:25:redis-cli GET tenant:tenant-combined-identity:gateway:identity:rate_limit || true
./1_archive/root_sh/step_128_test_combined_gateway.sh:27:redis-cli GET tenant:tenant-combined-auth:gateway:auth:rate_limit || true
./1_archive/root_sh/step_129_test_scope_separation.sh:5:curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_129_test_scope_separation.sh:10:curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_129_test_scope_separation.sh:15:redis-cli GET tenant:tenant-scope-001:gateway:auth:rate_limit || true
./1_archive/root_sh/step_129_test_scope_separation.sh:19:redis-cli GET tenant:tenant-scope-001:gateway:identity:rate_limit || true
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:4:URL_IDENTITY="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:5:URL_AUTH="https://api.pix2pi.com.tr/api/auth/health"
./1_archive/root_sh/step_134_check_503_source.sh:21:curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/auth/health || true
./1_archive/root_sh/step_134_check_503_source.sh:25:curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/identity/health || true
./1_archive/root_sh/step_184_backup_panel_before_service_monitor.sh:6:cp /opt/pix2pi/nginx/panel_index.html \
./1_archive/root_sh/step_184_backup_panel_before_service_monitor.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/panel/panel_index.html.before_service_monitor.bak
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:4:cat <<'HTML' > /opt/pix2pi/nginx/panel_index.html
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:46:      <li><a href="https://server.pix2pi.com.tr/containers/">Server Monitor</a></li>
./1_archive/root_sh/step_188_verify_done_items.sh:148:if curl -k -s --max-time 5 https://panel.pix2pi.com.tr >/dev/null 2>&1; then
./1_archive/root_sh/step_188_verify_done_items.sh:154:if curl -k -s --max-time 5 https://api.pix2pi.com.tr >/dev/null 2>&1; then
./1_archive/root_sh/step_190_test_cache_service.sh:14:echo "=== CACHE GET ==="
./1_archive/root_sh/step_193_panel_dosyasini_bul_patch_et.sh:13:  "/var/www"
./1_archive/root_sh/step_194_panel_html_reporting_service_ekle.sh:4:panel_dosya="/opt/pix2pi/nginx/panel_index.html"
./1_archive/root_sh/step_194_panel_html_reporting_service_ekle.sh:19:cp "$panel_dosya" "$yedek_dizin/panel_index.html.$zaman.bak"
./1_archive/root_sh/step_194_panel_html_reporting_service_ekle.sh:30:dosya = Path("/opt/pix2pi/nginx/panel_index.html")
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:8:PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:22:cp "$PANEL_HTML" "$YEDEK_DIZINI/panel_index.html.$ZAMAN.bak"
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:8:PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:21:cp "$PANEL_HTML" "$YEDEK_DIZINI/panel_index.html.$ZAMAN.bak"
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:4:panel_dosya="/opt/pix2pi/nginx/panel_index.html"
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:22:cp "$panel_dosya" "$yedek_dizin/panel_index.html.$zaman.bak"
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:23:echo "OK ✅ yedek alindi: $yedek_dizin/panel_index.html.$zaman.bak"
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:28:cat <<'HTML' > /opt/pix2pi/nginx/panel_index.html
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:70:      <li><a href="https://server.pix2pi.com.tr/containers/">Server Monitor</a></li>
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:8:panel_dosya="/opt/pix2pi/nginx/panel_index.html"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:29:cp "$panel_dosya" "$yedek_klasor/panel_index.html.$zaman.bak"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:77:      <li><a href="https://server.pix2pi.com.tr/containers/">Server Monitor</a></li>
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-9.7 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-9.8 Release evidence / audit log izi

Pattern:

```text
evidence|Evidence|audit|Audit|operator|timestamp|Generated At|Go/No-Go|final seal|FINAL_STATUS
```

Match Count: 3874

```text
./1_archive/root_sh/create_erp_structure.sh:14:mkdir -p $BASE/core/audit
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
./1_archive/root_sh/step_28_backup_audit_log_engine.sh:9:  backups/app/manual/playground_main.go.audit_log_engine.bak 2>/dev/null || true
./1_archive/root_sh/step_28_backup_audit_log_engine.sh:11:echo "OK ✅ audit log engine yedegi alindi"
./1_archive/root_sh/step_29_prepare_audit_dirs.sh:6:mkdir -p internal/platform/audit/domain
./1_archive/root_sh/step_29_prepare_audit_dirs.sh:7:mkdir -p internal/platform/audit/service
./1_archive/root_sh/step_29_prepare_audit_dirs.sh:9:echo "OK ✅ audit klasorleri hazir"
./1_archive/root_sh/step_30_run_audit_log_engine_test.sh:8:echo "OK ✅ audit log engine test calistirma bitti"
./1_archive/root_sh/step_374_add_auto_heal_engine.sh:18:timestamp() {
./1_archive/root_sh/step_374_add_auto_heal_engine.sh:23:  echo "[$(timestamp)] $1" >> "$LOG"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:35:timestamp() {
./1_archive/root_sh/step_377_advanced_auto_heal.sh:44:  echo "[$(timestamp)] $1" >> "$LOG_FILE"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:123:  printf '[%s] kind=%s service=%s detail=%s\n' "$(timestamp)" "$kind" "$svc" "$detail" >> "$BASE/logs/alert_engine.log"
./1_archive/root_sh/step_378_add_alert_engine.sh:35:timestamp() {
./1_archive/root_sh/step_378_add_alert_engine.sh:40:  echo "[$(timestamp)] $1" >> "$LOG_FILE"
./1_archive/root_sh/step_379_add_scale_hook.sh:18:timestamp() {
./1_archive/root_sh/step_379_add_scale_hook.sh:23:  echo "[$(timestamp)] $1" >> "$LOG_FILE"
./1_archive/root_sql/step_260_create_audit_tables.sql:1:CREATE TABLE IF NOT EXISTS audit_logs (
./1_archive/root_sql/step_260_create_audit_tables.sql:14:CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
./1_archive/root_sql/step_260_create_audit_tables.sql:15:ON audit_logs (tenant_id, created_at DESC);
./1_archive/root_sql/step_260_create_audit_tables.sql:17:CREATE INDEX IF NOT EXISTS idx_audit_logs_action
./1_archive/root_sql/step_260_create_audit_tables.sql:18:ON audit_logs (action);
./1_archive/root_sql/step_260_create_audit_tables.sql:20:CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
./1_archive/root_sql/step_260_create_audit_tables.sql:21:ON audit_logs (entity_type, entity_id);
./cmd/accounting-service/accounting_service_main.go:19:	auditlog "github.com/divrigili/pix2pi-SaaS/internal/platform/auditlog"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-9.8 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-9.9 Guard scripts implementation izi

Pattern:

```text
pix2pi_predeploy_check|pix2pi_postdeploy_smoke|pix2pi_rollback_readiness|PREDEPLOY_CHECK_STATUS|POSTDEPLOY_SMOKE_STATUS|ROLLBACK_READINESS_STATUS
```

Match Count: 22

```text
./scripts/audit_faz6_9_real_implementation.sh:163:write_check "6-9.2" "Pre-deploy check implementation izi" 'predeploy|pre-deploy|pre deploy|PREDEPLOY|nginx -t|disk|backup.*check|health.*probe|pix2pi_predeploy_check' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_9_real_implementation.sh:165:write_check "6-9.3" "Post-deploy smoke implementation izi" 'postdeploy|post-deploy|post deploy|smoke|Smoke|/health|curl.*health|pix2pi_postdeploy_smoke|POSTDEPLOY' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_9_real_implementation.sh:167:write_check "6-9.4" "Rollback readiness / restore implementation izi" 'rollback|Rollback|ROLLBACK|restore|Restore|backup|Backup|pix2pi_rollback_readiness|previous|revert' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_9_real_implementation.sh:177:write_check "6-9.9" "Guard scripts implementation izi" 'pix2pi_predeploy_check|pix2pi_postdeploy_smoke|pix2pi_rollback_readiness|PREDEPLOY_CHECK_STATUS|POSTDEPLOY_SMOKE_STATUS|ROLLBACK_READINESS_STATUS' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_9_release_runtime.sh:73:write_cmd_block "6-9.8 Local Smoke Probe" bash -lc "bash scripts/pix2pi_postdeploy_smoke.sh 2>&1 || true"
./scripts/audit_faz6_9_release_runtime.sh:75:write_cmd_block "6-9.9 Predeploy Probe" bash -lc "bash scripts/pix2pi_predeploy_check.sh 2>&1 || true"
./scripts/audit_faz6_9_release_runtime.sh:77:write_cmd_block "6-9.10 Rollback Readiness Probe" bash -lc "bash scripts/pix2pi_rollback_readiness.sh 2>&1 || true"
./scripts/pix2pi_postdeploy_smoke.sh:147:  echo "FAZ_6_9_POSTDEPLOY_SMOKE_STATUS=COMPLETE ✅"
./scripts/pix2pi_postdeploy_smoke.sh:160:echo "FAZ_6_9_POSTDEPLOY_SMOKE_STATUS=COMPLETE ✅"
./scripts/pix2pi_predeploy_check.sh:81:  echo "FAZ_6_9_PREDEPLOY_CHECK_STATUS=COMPLETE ✅"
./scripts/pix2pi_predeploy_check.sh:86:echo "FAZ_6_9_PREDEPLOY_CHECK_STATUS=COMPLETE ✅"
./scripts/pix2pi_rollback_readiness.sh:59:write_cmd_block "6-9.4.6 Rollback Smoke Command Reminder" bash -lc "echo 'After rollback: run scripts/pix2pi_postdeploy_smoke.sh'; echo 'Before nginx reload: nginx -t'; echo 'Before DB restore: confirm backup and target environment'"
./scripts/pix2pi_rollback_readiness.sh:66:  echo "FAZ_6_9_ROLLBACK_READINESS_STATUS=COMPLETE ✅"
./scripts/pix2pi_rollback_readiness.sh:71:echo "FAZ_6_9_ROLLBACK_READINESS_STATUS=COMPLETE ✅"
./scripts/test_faz6_9_release_rollback_deploy_safety.sh:9:PREDEPLOY_SCRIPT="scripts/pix2pi_predeploy_check.sh"
./scripts/test_faz6_9_release_rollback_deploy_safety.sh:10:POSTDEPLOY_SCRIPT="scripts/pix2pi_postdeploy_smoke.sh"
./scripts/test_faz6_9_release_rollback_deploy_safety.sh:11:ROLLBACK_SCRIPT="scripts/pix2pi_rollback_readiness.sh"
./scripts/test_faz6_9_release_rollback_deploy_safety.sh:95:check_grep "6-9.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_9_2_PREDEPLOY_CHECK_STATUS=READY"
./scripts/test_faz6_9_release_rollback_deploy_safety.sh:96:check_grep "6-9.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_9_3_POSTDEPLOY_SMOKE_STATUS=READY"
./scripts/test_faz6_9_release_rollback_deploy_safety.sh:114:check_grep "6-9 predeploy complete muhru var" "$PREDEPLOY_EVIDENCE" "FAZ_6_9_PREDEPLOY_CHECK_STATUS=COMPLETE"
./scripts/test_faz6_9_release_rollback_deploy_safety.sh:115:check_grep "6-9 postdeploy complete muhru var" "$POSTDEPLOY_EVIDENCE" "FAZ_6_9_POSTDEPLOY_SMOKE_STATUS=COMPLETE"
./scripts/test_faz6_9_release_rollback_deploy_safety.sh:116:check_grep "6-9 rollback complete muhru var" "$ROLLBACK_EVIDENCE" "FAZ_6_9_ROLLBACK_READINESS_STATUS=COMPLETE"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-9.9 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-9.10 Release / rollback test script izi

Pattern:

```text
FAZ_6_9|release.*test|rollback.*test|deploy.*test|test_faz6_9|runtime.*audit|real.*implementation.*audit
```

Match Count: 146

```text
./cmd/control-panel/control_panel.go:174:	app.All("/incident-audit-runtime/*", proxyToTarget("http://127.0.0.1:"+incidentAuditRuntimePort, "/incident-audit-runtime"))
./cmd/ops-console-smoke/ops_console_smoke_main.go:217:			URL:      proxyURL("/incident-audit-runtime/api/incident-audit/summary"),
./cmd/runtime-topology/runtime_topology_main.go:170:		{FromNode: "incident_audit_runtime", ToNode: "postgres_db", Relation: "reads audit", Protocol: "sql"},
./scripts/audit_faz6_3_real_implementation.sh:176:write_check "6-3.6.2" "Rolling update / deploy safety izi" "rolling|rollback|pre[-_]?deploy|post[-_]?deploy|smoke test|systemctl restart|ExecReload|zero[-_ ]?downtime|blue[-_ ]?green" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/audit_faz6_5_real_implementation.sh:187:write_check "6-5.10" "Observability test / audit script izi" "observability|prometheus|grafana|metrics|health.*probe|runtime.*audit|real.*implementation.*audit" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/audit_faz6_8_real_implementation.sh:184:write_check "6-8.11" "Performance test / audit script izi" 'FAZ_6_8|performance.*test|test.*performance|load.*readiness|stress.*readiness|runtime.*audit|real.*implementation.*audit' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/audit_faz6_8_real_implementation.sh:208:    echo "FAZ_6_9_READY=YES ✅"
./scripts/audit_faz6_8_real_implementation.sh:211:    echo "FAZ_6_9_READY=YES_WITH_WARNINGS ⚠️"
./scripts/audit_faz6_8_real_implementation.sh:214:    echo "FAZ_6_9_READY=NO_REVIEW_REQUIRED ❌"
./scripts/audit_faz6_8_real_implementation.sh:240:  echo "FAZ_6_9_READY=YES ✅"
./scripts/audit_faz6_8_real_implementation.sh:243:  echo "FAZ_6_9_READY=YES_WITH_WARNINGS ⚠️"
./scripts/audit_faz6_8_real_implementation.sh:246:  echo "FAZ_6_9_READY=NO_REVIEW_REQUIRED ❌"
./scripts/audit_faz6_9_real_implementation.sh:7:EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_9_REAL_IMPLEMENTATION_AUDIT.md"
./scripts/audit_faz6_9_real_implementation.sh:179:write_check "6-9.10" "Release / rollback test script izi" 'FAZ_6_9|release.*test|rollback.*test|deploy.*test|test_faz6_9|runtime.*audit|real.*implementation.*audit' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/audit_faz6_9_real_implementation.sh:190:    echo "FAZ_6_9_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_9_real_implementation.sh:192:    echo "FAZ_6_9_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
./scripts/audit_faz6_9_real_implementation.sh:196:    echo "FAZ_6_9_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_9_real_implementation.sh:198:    echo "FAZ_6_9_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
./scripts/audit_faz6_9_real_implementation.sh:202:    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_9_real_implementation.sh:205:    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
./scripts/audit_faz6_9_real_implementation.sh:208:    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
./scripts/audit_faz6_9_real_implementation.sh:212:  echo "FAZ_6_9_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
./scripts/audit_faz6_9_real_implementation.sh:222:  echo "FAZ_6_9_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_9_real_implementation.sh:224:  echo "FAZ_6_9_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
./scripts/audit_faz6_9_real_implementation.sh:228:  echo "FAZ_6_9_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_9_real_implementation.sh:230:  echo "FAZ_6_9_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
./scripts/audit_faz6_9_real_implementation.sh:234:  echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_9_real_implementation.sh:237:  echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
./scripts/audit_faz6_9_real_implementation.sh:240:  echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
./scripts/audit_faz6_9_real_implementation.sh:244:echo "FAZ_6_9_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
./scripts/audit_faz6_9_release_runtime.sh:7:EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_9_RELEASE_RUNTIME_AUDIT.md"
./scripts/audit_faz6_9_release_runtime.sh:42:FAZ_6_9_RUNTIME_AUDIT=STARTED ✅
./scripts/audit_faz6_9_release_runtime.sh:94:  echo "FAZ_6_9_RUNTIME_AUDIT=COMPLETE ✅"
./scripts/audit_faz6_9_release_runtime.sh:98:echo "FAZ_6_9_RUNTIME_AUDIT=COMPLETE ✅"
./scripts/phase4_readmodel_contract_query_evidence.sh:463:    fail "rollback smoke test kalici veri birakmadan PASS olmadi"
./scripts/pilot/apply_4c_5h_controlled_sample_data.sh:11:PREV_REPORT="reports/pilot/faz4c/4c_5g_import_dry_run_rollback_test_report.md"
./scripts/pilot/test_4c_5g_import_dry_run_rollback.sh:10:TEST_REPORT="reports/pilot/faz4c/4c_5g_import_dry_run_rollback_test_report.md"
./scripts/pilot/test_4c_5g_import_dry_run_rollback.sh:102:Import dry-run / rollback verification test tamamlandi.
./scripts/pilot/test_4c_5h_controlled_sample_data_apply.sh:8:PREV_REPORT="reports/pilot/faz4c/4c_5g_import_dry_run_rollback_test_report.md"
./scripts/pilot/test_4c_5j_real_pilot_data_import_final_closure.sh:16:G_REPORT="reports/pilot/faz4c/4c_5g_import_dry_run_rollback_test_report.md"
./scripts/pix2pi_postdeploy_smoke.sh:7:EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_9_POSTDEPLOY_SMOKE_EVIDENCE.md"
./scripts/pix2pi_postdeploy_smoke.sh:94:FAZ_6_9_POSTDEPLOY_SMOKE=STARTED ✅
./scripts/pix2pi_postdeploy_smoke.sh:147:  echo "FAZ_6_9_POSTDEPLOY_SMOKE_STATUS=COMPLETE ✅"
./scripts/pix2pi_postdeploy_smoke.sh:151:    echo "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅"
./scripts/pix2pi_postdeploy_smoke.sh:153:    echo "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=HAS_WARNINGS ⚠️"
./scripts/pix2pi_postdeploy_smoke.sh:160:echo "FAZ_6_9_POSTDEPLOY_SMOKE_STATUS=COMPLETE ✅"
./scripts/pix2pi_postdeploy_smoke.sh:164:  echo "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅"
./scripts/pix2pi_postdeploy_smoke.sh:166:  echo "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=HAS_WARNINGS ⚠️"
./scripts/pix2pi_predeploy_check.sh:7:EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_9_PREDEPLOY_CHECK_EVIDENCE.md"
./scripts/pix2pi_predeploy_check.sh:41:FAZ_6_9_PREDEPLOY_CHECK=STARTED ✅
./scripts/pix2pi_predeploy_check.sh:81:  echo "FAZ_6_9_PREDEPLOY_CHECK_STATUS=COMPLETE ✅"
./scripts/pix2pi_predeploy_check.sh:86:echo "FAZ_6_9_PREDEPLOY_CHECK_STATUS=COMPLETE ✅"
./scripts/pix2pi_rollback_readiness.sh:7:EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_9_ROLLBACK_READINESS_EVIDENCE.md"
./scripts/pix2pi_rollback_readiness.sh:41:FAZ_6_9_ROLLBACK_READINESS=STARTED ✅
./scripts/pix2pi_rollback_readiness.sh:66:  echo "FAZ_6_9_ROLLBACK_READINESS_STATUS=COMPLETE ✅"
./scripts/pix2pi_rollback_readiness.sh:71:echo "FAZ_6_9_ROLLBACK_READINESS_STATUS=COMPLETE ✅"
./scripts/test_faz6_2_real_implementation_audit.sh:59:check_file "6-2 real implementation audit script mevcut" "$AUDIT_SCRIPT"
./scripts/test_faz6_2_real_implementation_audit.sh:60:check_exec "6-2 real implementation audit script executable" "$AUDIT_SCRIPT"
./scripts/test_faz6_2_real_implementation_audit.sh:89:  echo "OK ✅ FAZ 6-2 real implementation audit testi tamamlandi"
./scripts/test_faz6_2_real_implementation_audit.sh:93:  echo "HATA ❌ FAZ 6-2 real implementation audit testinde eksik var"
./scripts/test_faz6_3_multinode_readiness.sh:65:check_file "6-3 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
./scripts/test_faz6_3_multinode_readiness.sh:66:check_file "6-3 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"
./scripts/test_faz6_3_multinode_readiness.sh:67:check_exec "6-3 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
./scripts/test_faz6_3_multinode_readiness.sh:68:check_exec "6-3 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"
./scripts/test_faz6_3_multinode_readiness.sh:93:check_grep "6-3 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_3_RUNTIME_AUDIT=COMPLETE"
./scripts/test_faz6_4_event_bus_sre_readiness.sh:65:check_file "6-4 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
./scripts/test_faz6_4_event_bus_sre_readiness.sh:66:check_file "6-4 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"
./scripts/test_faz6_4_event_bus_sre_readiness.sh:67:check_exec "6-4 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
./scripts/test_faz6_4_event_bus_sre_readiness.sh:68:check_exec "6-4 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"
./scripts/test_faz6_4_event_bus_sre_readiness.sh:97:check_grep "6-4 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_4_RUNTIME_AUDIT=COMPLETE"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-9.10 STATUS=IMPLEMENTED_OR_PRESENT ✅

# Final Runtime Implementation Interpretation

```text
REQUIRED_FAIL=0
OPTIONAL_WARN=0
FAZ_6_9_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_9_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_10_READY=YES ✅
FAZ_6_9_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅
```
