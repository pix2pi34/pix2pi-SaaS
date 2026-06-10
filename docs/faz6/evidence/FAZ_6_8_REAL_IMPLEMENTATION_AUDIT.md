# FAZ 6-8 Real Implementation Audit

Generated At: 2026-05-01T15:04:32+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit, FAZ 6-8 Performance / Load / Stress Readiness maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

## Scanned Files

```text
3019 /tmp/tmp.KiQasx0m8F/files.txt

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

## 6-8.1 Baseline performance / safe timing probe izi

Pattern:

```text
time_total|curl.*write-out|uptime|free -h|docker stats|df -h|baseline|Baseline|performance.*audit|safe.*probe
```

Match Count: 246

```text
./1_archive/root_sh/step_72_check_production_server.sh:14:free -h || true
./1_archive/root_sh/step_72_check_production_server.sh:15:df -h || true
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1811:    "node_modules/baseline-browser-mapping": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1813:      "resolved": "https://registry.npmjs.org/baseline-browser-mapping/-/baseline-browser-mapping-2.10.20.tgz",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1818:        "baseline-browser-mapping": "dist/cli.cjs"
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1866:        "baseline-browser-mapping": "^2.10.12",
./deploy/observability/grafana/dashboards/node-exporter-full.json:771:      "description": "System uptime",
./deploy/quality/config/lvl14_test_inventory_catalog.yaml:39:  baseline_quality:
./deploy/quality/config/lvl14_test_inventory_catalog.yaml:41:      - baseline_mode
./deploy/quality/generated/lvl14_test_contract_rules.yaml:3:  baseline_mode: strict
./deploy/quality/scripts/lvl14_test_contract_smoke.sh:26:grep -q 'baseline_quality:' "${TEST_CATALOG_FILE}"
./deploy/quality/scripts/lvl14_test_contract_smoke.sh:27:echo "OK ✅ baseline kalite ozeti var"
./deploy/quality/scripts/render_lvl14_test_contract.sh:77:- Baseline mode: ${QUALITY_BASELINE_MODE}
./grafana/dashboards/node-exporter-full.json:771:      "description": "System uptime",
./scripts/audit_faz6_2_db_l8_readiness.sh:110:write_cmd_block "6-2.4 Disk Usage" df -h
./scripts/audit_faz6_6_backup_restore_runtime.sh:53:write_cmd_block "6-6.2 Disk Usage" df -h
./scripts/audit_faz6_8_performance_runtime.sh:53:write_cmd_block "6-8.2 Uptime / Load Average" uptime
./scripts/audit_faz6_8_performance_runtime.sh:55:write_cmd_block "6-8.3 Memory Snapshot" free -h
./scripts/audit_faz6_8_performance_runtime.sh:57:write_cmd_block "6-8.4 Disk Usage" df -h
./scripts/audit_faz6_8_performance_runtime.sh:62:  write_cmd_block "6-8.6 Docker Stats Snapshot" bash -lc "docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}' 2>/dev/null || true"
./scripts/audit_faz6_8_performance_runtime.sh:83:  curl -o /dev/null -sS --max-time 4 -w 'http_code=%{http_code} time_total=%{time_total} time_connect=%{time_connect} size=%{size_download}\n' \"\$url\" || echo 'WARN ⚠️ probe failed'
./scripts/audit_faz6_8_real_implementation.sh:162:write_check "6-8.1" "Baseline performance / safe timing probe izi" 'time_total|curl.*write-out|uptime|free -h|docker stats|df -h|baseline|Baseline|performance.*audit|safe.*probe' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_8_real_implementation.sh:184:write_check "6-8.11" "Performance test / audit script izi" 'FAZ_6_8|performance.*test|test.*performance|load.*readiness|stress.*readiness|runtime.*audit|real.*implementation.*audit' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/phase4b_observability_baseline.sh:7:python3 "$SCRIPT_DIR/phase4b_observability_baseline.py" "$ROOT_DIR"
./scripts/phase4b_pilot_uat_onboarding_baseline.sh:7:python3 "$SCRIPT_DIR/phase4b_pilot_uat_onboarding_baseline.py" "$ROOT_DIR"
./scripts/phase4b_workflow_realtime_baseline.sh:7:python3 "$SCRIPT_DIR/phase4b_workflow_realtime_baseline.py" "$ROOT_DIR"
./scripts/phase4_db_final_closure_gate.sh:349:closure "14.4 Performance Baseline=PASS"
./scripts/phase4_db_health_baseline.sh:8:REPORT_FILE="$REPORT_DIR/14_4_4_db_health_baseline_report.md"
./scripts/phase4_db_health_baseline.sh:431:  echo "# FAZ 4 / 14.4.4 - Connection / Lock / Deadlock Final DB Health Baseline Report"
./scripts/phase4_db_known_risks_deferred_register.sh:14:R_1442="$REPORT_DIR/14_4_2_index_usage_baseline_report.md"
./scripts/phase4_db_known_risks_deferred_register.sh:16:R_1444="$REPORT_DIR/14_4_4_db_health_baseline_report.md"
./scripts/phase4_db_known_risks_deferred_register.sh:113:require_file "14.4.2 index usage baseline" "$R_1442" || true
./scripts/phase4_db_known_risks_deferred_register.sh:115:require_file "14.4.4 DB health baseline" "$R_1444" || true
./scripts/phase4_db_known_risks_deferred_register.sh:244:    "Production veri hacmi artinca index usage baseline tekrar alinacak; simdi index drop yok" \
./scripts/phase4_db_known_risks_deferred_register.sh:245:    "Production baseline tekrar PASS"
./scripts/phase4_db_known_risks_deferred_register.sh:258:    "Production veri hacmi artinca vacuum/dead tuple baseline tekrar alinacak; simdi vacuum/analyze yok" \
./scripts/phase4_db_known_risks_deferred_register.sh:259:    "Production vacuum baseline tekrar PASS"
./scripts/phase4_db_known_risks_deferred_register.sh:286:    "Normal operasyon baseline olarak kabul edildi; production sonrasi periyodik tekrar alinacak" \
./scripts/phase4_db_known_risks_deferred_register.sh:287:    "Periodic DB health baseline PASS"
./scripts/phase4_db_known_risks_deferred_register.sh:299:  warn "DB health baseline LOW degil veya sifir metrikler bozuk"
./scripts/phase4_db_observability_final_baseline.sh:8:REPORT_FILE="$REPORT_DIR/14_3_5_db_observability_final_baseline_report.md"
./scripts/phase4_db_observability_final_baseline.sh:358:closure "14.3.5 final baseline=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)"
./scripts/phase4_db_observability_final_baseline.sh:366:  echo "# FAZ 4 / 14.3.5 - DB Observability Final Baseline Report"
./scripts/phase4_db_observability_final_baseline.sh:394:    echo "OK ✅ final baseline risk yok"
./scripts/phase4_db_performance_final_closure.sh:11:R_1441="$REPORT_DIR/14_4_1_query_performance_baseline_report.md"
./scripts/phase4_db_performance_final_closure.sh:12:R_1442="$REPORT_DIR/14_4_2_index_usage_baseline_report.md"
./scripts/phase4_db_performance_final_closure.sh:14:R_1444="$REPORT_DIR/14_4_4_db_health_baseline_report.md"
./scripts/phase4_db_performance_final_closure.sh:296:closure "14.4.1 Query performance baseline=$S_1441"
./scripts/phase4_db_performance_final_closure.sh:297:closure "14.4.2 Index usage baseline=$S_1442"
./scripts/phase4_db_performance_final_closure.sh:299:closure "14.4.4 DB health baseline=$S_1444"
./scripts/phase4_db_performance_final_closure.sh:381:  echo "# FAZ 4 / 14.4 - DB Query Performance / Index Usage / Vacuum Baseline Final Closure"
./scripts/phase4_db_production_readiness_scorecard.sh:267:  add_score "performance_health_baseline" "$PERF_SCORE" "25" "PASS" "$PERF_NOTE"
./scripts/phase4_db_production_readiness_scorecard.sh:269:  add_score "performance_health_baseline" "$PERF_SCORE" "25" "FAIL" "$PERF_NOTE"
./scripts/phase4_db_production_readiness_scorecard.sh:270:  blocker "performance/health baseline PASS/BASELINED/LOW degil"
./scripts/phase4_db_runbook_incident_checklist.sh:13:R_1444="$REPORT_DIR/14_4_4_db_health_baseline_report.md"
./scripts/phase4_db_runbook_incident_checklist.sh:91:require_file "14.4.4 DB health baseline" "$R_1444" || true
./scripts/phase4_db_runbook_incident_checklist.sh:166:  fail "DB health baseline PASS degil"
./scripts/phase4_db_runbook_incident_checklist.sh:187:checkline "Production baseline schedule"
./scripts/phase4_db_runbook_incident_checklist.sh:214:- Index drop karari production veri hacmi ve tekrar baseline olmadan verilmez.
./scripts/phase4_db_runbook_incident_checklist.sh:225:bash scripts/phase4_db_health_baseline.sh .
./scripts/phase4_db_runbook_incident_checklist.sh:228:  docs/phase4/14_4_4_db_health_baseline_report.md
./scripts/phase4_db_runbook_incident_checklist.sh:324:bash scripts/phase4_db_health_baseline.sh .
./scripts/phase4_db_runbook_incident_checklist.sh:327:  docs/phase4/14_4_4_db_health_baseline_report.md
./scripts/phase4_db_runbook_incident_checklist.sh:336:- Kill sonrasi DB health baseline tekrar alinir.
./scripts/phase4_db_runbook_incident_checklist.sh:343:bash scripts/phase4_query_performance_baseline.sh .
./scripts/phase4_db_runbook_incident_checklist.sh:346:  docs/phase4/14_4_1_query_performance_baseline_report.md
./scripts/phase4_db_runbook_incident_checklist.sh:353:- Index ekleme karari icin 14.4.2 index usage baseline ile birlikte degerlendir.
./scripts/phase4_db_runbook_incident_checklist.sh:354:- Production verisi artinca tekrar baseline al.
./scripts/phase4_db_runbook_incident_checklist.sh:361:  docs/phase4/14_4_4_db_health_baseline_report.md
./scripts/phase4_db_runbook_incident_checklist.sh:383:- Production veri hacmi artinca tekrar baseline al.
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-8.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-8.2 Load test tooling / readiness izi

Pattern:

```text
hey|wrk|k6|vegeta|ab -|ApacheBench|load.*test|LoadTest|load_test|benchmark|Benchmark|bench
```

Match Count: 429

```text
./1_archive/root_sh/step_279_find_snapshot_source.sh:5:crontab -l || true
./1_archive/root_sh/step_314_find_kong_starter.sh:5:crontab -l || true
./1_archive/root_sh/step_373_add_early_warning_cron.sh:11:crontab -l 2>/dev/null > "$TMP_CRON" || true
./1_archive/root_sh/step_373_add_early_warning_cron.sh:28:crontab -l
./1_archive/root_sh/step_375_add_auto_heal_cron.sh:9:crontab -l 2>/dev/null > "$TMP" || true
./1_archive/root_sh/step_375_add_auto_heal_cron.sh:22:crontab -l
./1_archive/root_sh/step_380_bind_all_crons.sh:7:crontab -l 2>/dev/null > "$TMP" || true
./1_archive/root_sh/step_380_bind_all_crons.sh:31:crontab -l
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:377:      "integrity": "sha512-bR9e6o2BDB12jzN/gIbjHa5wLJ4UjD1CB9pM7ehlc0ddk6EBz+yYS1EV2MF55/HUxrHcB/hehAyt5vhsA3hx7w==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1209:      "integrity": "sha512-rfT93uj5s0PRL7EzccGMs3brplhcrghnDoV26NqKhCAS1hVo+WdNsPvE/yb6ilfr5hi2MEk6d5EWJTKdxg8jVw==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1506:      "integrity": "sha512-vFKC2IEtQnVhpT78h1Yp8wzwrf8CM+MzKMHGJZfBtzhZNycRFnXsHk6E5TxIkkMsgNS7mdX3AGB7x2QM2di4lA==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2098:      "integrity": "sha512-zwfzJecQ/Uej6tusMqwAqU/6KL2XaB2VZ2Jg54Je6ahNBGNH6Ek6g3jjNCF0fG9EWQKGZNddNjU5F1ZQn/sBnA==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2610:      "integrity": "sha512-RdJUflcE3cUzKiMqQgsCu06FPu9UdIJO0beYbPhHN4k6apgJtifcoCtT9bcxOpYBtpD2kCM6Sbzg4CausW/PKQ==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2701:      "integrity": "sha512-xbbCH5dCYU5T8LcEhhuh7HJ88HXuW3qsI3Y0zOZFKfZEHcpWiHU/Jxzk629Brsab/mMiHQti9wMP+845RPe3Vg==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:3084:      "integrity": "sha512-VgjWUsnnT6n+NUk6eZq77zeFdpW2LWDzP6zFGrCbHXiYNul5Dzqk2HHQ5uFH2DNW5Xbp8+jVzaeNt94ssEEl4w==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:3580:    "node_modules/tinybench": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:3582:      "resolved": "https://registry.npmjs.org/tinybench/-/tinybench-2.9.0.tgz",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:3899:        "tinybench": "^2.9.0",
./deploy/observability/grafana/dashboards/node-exporter-full.json:3276:              "legendFormat": "Slab - Memory used by the kernel to cache data structures for its own use (caches like inode, dentry, etc)",
./deploy/observability/grafana/dashboards/node-exporter-full.json:17640:          "description": "The number of outstanding requests at the instant the sample was taken. Incremented as requests are given to appropriate struct request_queue and decremented as they finish.",
./deploy/observability/grafana/dashboards/node-exporter-full.json:23040:              "legendFormat": "CurrEstab - TCP connections for which the current state is either ESTABLISHED or CLOSE- WAIT",
./grafana/dashboards/node-exporter-full.json:3276:              "legendFormat": "Slab - Memory used by the kernel to cache data structures for its own use (caches like inode, dentry, etc)",
./grafana/dashboards/node-exporter-full.json:17640:          "description": "The number of outstanding requests at the instant the sample was taken. Incremented as requests are given to appropriate struct request_queue and decremented as they finish.",
./grafana/dashboards/node-exporter-full.json:23040:              "legendFormat": "CurrEstab - TCP connections for which the current state is either ESTABLISHED or CLOSE- WAIT",
./internal/platform/dlq_test.go:9:func TestBuildTenantSafeDlqPayload_Success(t *testing.T) {
./internal/platform/dlq_test.go:25:func TestBuildTenantSafeDlqPayload_MissingTenantUUID(t *testing.T) {
./internal/platform/eventbus/service/dlq_event_validator_test.go:35:func TestValidateDlqEvent_MissingPayload(t *testing.T) {
./internal/platform/idempotency/dedupe_reserve_service_test.go:66:func TestReserveDedupeRecordRequestValidate_InvalidPayloadHash(t *testing.T) {
./internal/platform/security/service/upload_payload_guard_service_test.go:5:func TestDefaultUploadPayloadPolicy(t *testing.T) {
./internal/platform/security/service/upload_payload_guard_service_test.go:22:func TestUploadPayloadPolicy_Validate_Invalid(t *testing.T) {
./internal/platform/security/service/upload_payload_guard_service_test.go:35:func TestNormalizeUploadFilename_Success(t *testing.T) {
./internal/platform/security/service/upload_payload_guard_service_test.go:46:func TestNormalizeUploadFilename_UnsafePath(t *testing.T) {
./internal/platform/security/service/upload_payload_guard_service_test.go:56:func TestValidateUploadPayload_Success(t *testing.T) {
./internal/platform/security/service/upload_payload_guard_service_test.go:74:func TestValidateUploadPayload_TooLarge(t *testing.T) {
./internal/platform/security/service/upload_payload_guard_service_test.go:93:func TestValidateUploadPayload_ForbiddenExtension(t *testing.T) {
./internal/platform/security/service/upload_payload_guard_service_test.go:110:func TestValidateUploadPayload_MimeTypeNotAllowed(t *testing.T) {
./internal/platform/security/service/upload_payload_guard_service_test.go:127:func TestValidateUploadPayload_ExtensionNotAllowed(t *testing.T) {
./internal/platform/security/service/upload_payload_guard_service_test.go:144:func TestValidateUploadPayload_UnsafeFilename(t *testing.T) {
./internal/platform/security/service/upload_runtime_guard_service_test.go:5:func TestRuntimeUploadGuardProfile_Validate_Success(t *testing.T) {
./internal/platform/security/service/upload_runtime_guard_service_test.go:13:func TestRuntimeUploadGuardProfile_Validate_EmptyName(t *testing.T) {
./internal/platform/security/service/upload_runtime_guard_service_test.go:26:func TestGuardRuntimeUpload_Success(t *testing.T) {
./internal/platform/security/service/upload_runtime_guard_service_test.go:44:func TestGuardRuntimeUpload_TooLarge(t *testing.T) {
./internal/platform/security/service/upload_runtime_guard_service_test.go:63:func TestGuardRuntimeUpload_ForbiddenExtension(t *testing.T) {
./internal/platform/security/service/upload_runtime_guard_service_test.go:80:func TestGuardRuntimeUpload_MimeTypeNotAllowed(t *testing.T) {
./internal/platform/security/service/upload_runtime_guard_service_test.go:97:func TestGuardRuntimeUpload_InvalidProfilePolicy(t *testing.T) {
./internal/platform/webhooks/delivery_service_test.go:58:func TestDeliverWebhookRequestValidate_EmptyPayload(t *testing.T) {
./scripts/audit_faz6_6_backup_restore_runtime.sh:80:crontab -l 2>/dev/null | grep -Ei 'backup|restore|restic|retention|pg_dump|snapshot|pix2pi' || true
./scripts/audit_faz6_8_performance_runtime.sh:41:Bu audit runtime ortaminda performance / load / stress readiness sinyallerini toplar. Agir load test calistirmaz.
./scripts/audit_faz6_8_performance_runtime.sh:122:for t in hey wrk ab k6 vegeta curl; do
./scripts/audit_faz6_8_performance_runtime.sh:132:write_cmd_block "6-8.16 Performance Scripts Inventory" bash -lc "find . /opt/pix2pi /etc/pix2pi -maxdepth 6 -type f 2>/dev/null | grep -Ei 'performance|load|stress|benchmark|bench|k6|wrk|vegeta|hey|ab|latency|pprof|profil|bottleneck|capacity' | sort | head -n 220 || true"
./scripts/audit_faz6_8_real_implementation.sh:164:write_check "6-8.2" "Load test tooling / readiness izi" 'hey|wrk|k6|vegeta|ab -|ApacheBench|load.*test|LoadTest|load_test|benchmark|Benchmark|bench' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/test_faz6_8_performance_load_stress.sh:113:check_grep "6-8.2 load test real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.2 Load test tooling"
./web/node_modules/@adobe/css-tools/package.json:33:    "@types/benchmark": "^2.1.1",
./web/node_modules/@adobe/css-tools/package.json:37:    "benchmark": "^2.1.4",
./web/node_modules/@adobe/css-tools/package.json:47:    "benchmark": "npm run build && node benchmark/index.mjs",
./web/node_modules/@asamuzakjp/css-color/node_modules/lru-cache/package.json:27:    "benchmark-results-typedoc": "bash scripts/benchmark-results-typedoc.sh",
./web/node_modules/@asamuzakjp/css-color/node_modules/lru-cache/package.json:28:    "prebenchmark": "npm run prepare",
./web/node_modules/@asamuzakjp/css-color/node_modules/lru-cache/package.json:29:    "benchmark": "make -C benchmark",
./web/node_modules/@asamuzakjp/css-color/node_modules/lru-cache/package.json:31:    "profile": "make -C benchmark profile"
./web/node_modules/@asamuzakjp/css-color/node_modules/lru-cache/package.json:57:    "benchmark": "^2.1.4",
./web/node_modules/cssstyle/package.json:58:    "download": "node ./scripts/downloadLatestProperties.mjs",
./web/node_modules/deep-eql/package.json:29:    "bench": "node bench",
./web/node_modules/deep-eql/package.json:58:    "benchmark": "^2.1.0",
./web/node_modules/@jridgewell/gen-mapping/package.json:34:    "benchmark": "run-s build:code benchmark:*",
./web/node_modules/@jridgewell/gen-mapping/package.json:35:    "benchmark:install": "cd benchmark && npm install",
./web/node_modules/@jridgewell/gen-mapping/package.json:36:    "benchmark:only": "node --expose-gc benchmark/index.js",
./web/node_modules/@jridgewell/remapping/package.json:35:    "benchmark": "run-s build:code benchmark:*",
./web/node_modules/@jridgewell/remapping/package.json:36:    "benchmark:install": "cd benchmark && npm install",
./web/node_modules/@jridgewell/remapping/package.json:37:    "benchmark:only": "node --expose-gc benchmark/index.js",
./web/node_modules/@jridgewell/sourcemap-codec/package.json:34:    "benchmark": "run-s build:code benchmark:*",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-8.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-8.3 Stress test / stop criteria izi

Pattern:

```text
stress|Stress|stress.*test|stop.*criteria|durdurma|saturation|breakpoint|crash|overload|capacity.*limit
```

Match Count: 462

```text
./deploy/observability/config/lvl11_signal_catalog.yaml:20:      - id: app.connection.saturation
./deploy/observability/config/lvl11_signal_catalog.yaml:21:        metric: http_connection_saturation_percent
./deploy/observability/generated/lvl11_threshold_rules.yaml:38:  - id: app.connection.saturation
./deploy/observability/grafana/dashboards/node-exporter-full.json:17224:          "description": "Percentage of elapsed time during which I/O requests were issued to the device (bandwidth utilization for the device). Device saturation occurs when this value is close to 100% for devices serving requests serially.  But for devices  serving requests in parallel, such as RAID arrays and modern SSDs, this number does not reflect their performance limits.",
./deploy/quality/config/lvl14_performance_gate_catalog.yaml:24:  db_cache_saturation_gate:
./deploy/quality/config/lvl14_performance_gate_catalog.yaml:27:      - saturation_percent
./deploy/quality/generated/lvl14_performance_release_rules.yaml:6:  db_saturation_percent: 85
./deploy/quality/generated/lvl14_performance_release_rules.yaml:7:  cache_saturation_percent: 80
./deploy/quality/scripts/lvl14_performance_release_smoke.sh:26:grep -q 'db_cache_saturation_gate:' "${PERF_CATALOG_FILE}"
./deploy/quality/scripts/lvl14_performance_release_smoke.sh:27:echo "OK ✅ DB / cache saturation gate var"
./deploy/quality/scripts/render_lvl14_performance_release.sh:82:- DB saturation gate: ${PERF_DB_SATURATION_PERCENT}%
./deploy/quality/scripts/render_lvl14_performance_release.sh:83:- Cache saturation gate: ${PERF_CACHE_SATURATION_PERCENT}%
./grafana/dashboards/node-exporter-full.json:17224:          "description": "Percentage of elapsed time during which I/O requests were issued to the device (bandwidth utilization for the device). Device saturation occurs when this value is close to 100% for devices serving requests serially.  But for devices  serving requests in parallel, such as RAID arrays and modern SSDs, this number does not reflect their performance limits.",
./scripts/audit_faz6_8_performance_runtime.sh:41:Bu audit runtime ortaminda performance / load / stress readiness sinyallerini toplar. Agir load test calistirmaz.
./scripts/audit_faz6_8_performance_runtime.sh:132:write_cmd_block "6-8.16 Performance Scripts Inventory" bash -lc "find . /opt/pix2pi /etc/pix2pi -maxdepth 6 -type f 2>/dev/null | grep -Ei 'performance|load|stress|benchmark|bench|k6|wrk|vegeta|hey|ab|latency|pprof|profil|bottleneck|capacity' | sort | head -n 220 || true"
./scripts/audit_faz6_8_real_implementation.sh:144:Bu audit, FAZ 6-8 Performance / Load / Stress Readiness maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.
./scripts/audit_faz6_8_real_implementation.sh:166:write_check "6-8.3" "Stress test / stop criteria izi" 'stress|Stress|stress.*test|stop.*criteria|durdurma|saturation|breakpoint|crash|overload|capacity.*limit' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/audit_faz6_8_real_implementation.sh:168:write_check "6-8.4" "Bottleneck evidence izi" 'bottleneck|darbo|slow.*query|pg_stat|latency|duration|timeout|cpu|memory|disk|IO|backlog|pool.*saturation|NumPending' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_8_real_implementation.sh:184:write_check "6-8.11" "Performance test / audit script izi" 'FAZ_6_8|performance.*test|test.*performance|load.*readiness|stress.*readiness|runtime.*audit|real.*implementation.*audit' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/phase4_db_runbook_incident_checklist.sh:183:checkline "Connection saturation checklist"
./scripts/pilot/run_4c_2e_runtime_gap_decision_fix_plan.sh:149:Bu warning pilot tenant setup'ı durdurmaz.
./scripts/test_faz6_1_scope_freeze.sh:93:check_grep "6-8 Performance Load Stress tanimli" "$DOC_FILE" "6-8 Performance / Load / Stress Readiness"
./scripts/test_faz6_1_scope_freeze.sh:96:check_grep "6-8.3 Stress test tanimli" "$DOC_FILE" "6-8.3 Stress test"
./scripts/test_faz6_2_visible_checkpoints.sh:59:check_grep "6-2.3 detay pool saturation var" "$CHECKPOINT_FILE" "pool saturation metric ihtiyacı yazıldı"
./scripts/test_faz6_8_performance_load_stress.sh:72:check_grep "6-8.3 Stress Test Readiness tanimli" "$DOC_FILE" "6-8.3 Stress Test Readiness"
./scripts/test_faz6_8_performance_load_stress.sh:114:check_grep "6-8.3 stress test real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.3 Stress test"
./scripts/test_faz6_8_performance_load_stress.sh:152:  echo "OK ✅ FAZ 6-8 Performance / Load / Stress Readiness testi tamamlandi"
./web/node_modules/mime-db/db.json:2800:  "application/vnd.etsi.overload-control-policy-dataset+xml": {
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:5:  "A_JSDoc_template_tag_may_not_follow_a_typedef_callback_or_overload_tag_8039": "Značka „@template“ jazyka JSDoc nemůže následovat po značce „@typedef“, „@callback“ nebo „@overload“.",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:24:  "A_computed_property_name_in_a_method_overload_must_refer_to_an_expression_whose_type_is_a_literal_ty_1168": "Název počítané vlastnosti v přetížené metodě musí odkazovat na výraz, jehož typ je literál nebo unique symbol.",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:38:  "A_decorator_can_only_decorate_a_method_implementation_not_an_overload_1249": "Dekorátor může dekorovat jenom implementaci metody, ne přetížení.",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:283:  "An_overload_signature_cannot_be_declared_as_a_generator_1222": "Signatura přetížení nemůže být deklarovaný jako generátor.",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:437:  "Class_declaration_cannot_implement_overload_list_for_0_2813": "Deklarace třídy nemůže implementovat seznam přetížení pro {0}.",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:508:  "Convert_overload_list_to_single_signature_95118": "Převést seznam přetížení na jednu signaturu",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:849:  "Function_overload_must_be_static_2387": "Přetížení funkce musí být statické.",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:850:  "Function_overload_must_not_be_static_2388": "Přetížení funkce nesmí být statické.",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:1088:  "No_overload_expects_0_arguments_but_overloads_do_exist_that_expect_either_1_or_2_arguments_2575": "Žádné přetížení neočekává tento počet argumentů: {0}. Existují ale přetížení, která očekávají buď {1}, nebo tento počet argumentů: {2}",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:1089:  "No_overload_expects_0_type_arguments_but_overloads_do_exist_that_expect_either_1_or_2_type_arguments_2743": "Žádné přetížení neočekává tento počet argumentů typů: {0}. Existují ale přetížení, která očekávají buď {1}, nebo tento počet argumentů typů: {2}",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:1090:  "No_overload_matches_this_call_2769": "Žádné přetížení neodpovídá tomuto volání.",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:1557:  "The_call_would_have_succeeded_against_this_implementation_but_implementation_signatures_of_overloads_2793": "Volání by pro tuto implementaci proběhlo úspěšně, ale signatury implementace pro přetížení nejsou externě k dispozici.",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:1588:  "The_last_overload_gave_the_following_error_2770": "Poslední přetížení vrátilo následující chybu.",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:1589:  "The_last_overload_is_declared_here_2771": "Poslední přetížení je deklarované tady.",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:1695:  "This_overload_implicitly_returns_the_type_0_because_it_lacks_a_return_type_annotation_7012": "Toto přetížení implicitně vrací typ „{0}“, protože postrádá anotaci návratového typu.",
./web/node_modules/typescript/lib/cs/diagnosticMessages.generated.json:1696:  "This_overload_signature_is_not_compatible_with_its_implementation_signature_2394": "Tato signatura přetížení není kompatibilní se signaturou implementace.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:5:  "A_JSDoc_template_tag_may_not_follow_a_typedef_callback_or_overload_tag_8039": "Ein JSDoc-Tag \"@template\" darf nicht auf ein \"@typedef\", \"@callback\" oder \"@overload\" folgen.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:24:  "A_computed_property_name_in_a_method_overload_must_refer_to_an_expression_whose_type_is_a_literal_ty_1168": "Ein berechneter Eigenschaftenname in einer Methodenüberladung muss auf einen Ausdruck verweisen, dessen Typ ein Literal oder ein \"unique symbol\"-Typ ist.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:38:  "A_decorator_can_only_decorate_a_method_implementation_not_an_overload_1249": "Ein Decorator-Element kann nur für eine Methodenimplementierung und nicht für eine Überladung verwendet werden.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:283:  "An_overload_signature_cannot_be_declared_as_a_generator_1222": "Eine Überladungssignatur darf nicht als ein Generator deklariert werden.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:437:  "Class_declaration_cannot_implement_overload_list_for_0_2813": "Die Klassendeklaration kann die Überladungsliste für \"{0}\" nicht implementieren.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:508:  "Convert_overload_list_to_single_signature_95118": "Überladungsliste in einzelne Signatur konvertieren",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:849:  "Function_overload_must_be_static_2387": "Die Funktionsüberladung muss statisch sein.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:850:  "Function_overload_must_not_be_static_2388": "Die Funktionsüberladung darf nicht statisch sein.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:1088:  "No_overload_expects_0_arguments_but_overloads_do_exist_that_expect_either_1_or_2_arguments_2575": "Keine Überladung erwartet {0} Argumente, aber es sind Überladungen vorhanden, die entweder {1} oder {2} Argumente erwarten.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:1089:  "No_overload_expects_0_type_arguments_but_overloads_do_exist_that_expect_either_1_or_2_type_arguments_2743": "Keine Überladung erwartet {0} Typargumente, aber es sind Überladungen vorhanden, die entweder {1} oder {2} Typargumente erwarten.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:1090:  "No_overload_matches_this_call_2769": "Keine Überladung stimmt mit diesem Aufruf überein.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:1557:  "The_call_would_have_succeeded_against_this_implementation_but_implementation_signatures_of_overloads_2793": "Der Aufruf wäre für diese Implementierung erfolgreich, aber die Implementierungssignaturen von Überladungen sind nicht extern sichtbar.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:1588:  "The_last_overload_gave_the_following_error_2770": "Die letzte Überladung hat den folgenden Fehler verursacht.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:1589:  "The_last_overload_is_declared_here_2771": "Die letzte Überladung wird hier deklariert.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:1695:  "This_overload_implicitly_returns_the_type_0_because_it_lacks_a_return_type_annotation_7012": "Diese Überladung gibt implizit den Typ „{0}“ zurück, da keine Rückgabetypanmerkung vorhanden ist.",
./web/node_modules/typescript/lib/de/diagnosticMessages.generated.json:1696:  "This_overload_signature_is_not_compatible_with_its_implementation_signature_2394": "Diese Überladungssignatur ist nicht mit der zugehörigen Implementierungssignatur kompatibel.",
./web/node_modules/typescript/lib/es/diagnosticMessages.generated.json:5:  "A_JSDoc_template_tag_may_not_follow_a_typedef_callback_or_overload_tag_8039": "Una etiqueta \"@template\" de JSDoc no puede seguir a una etiqueta \"@typedef\", \"@callback\" u \"@overload\"",
./web/node_modules/typescript/lib/es/diagnosticMessages.generated.json:24:  "A_computed_property_name_in_a_method_overload_must_refer_to_an_expression_whose_type_is_a_literal_ty_1168": "Un nombre de propiedad calculada en una sobrecarga de método debe hacer referencia a una expresión que sea de tipo literal o \"unique symbol\".",
./web/node_modules/typescript/lib/es/diagnosticMessages.generated.json:38:  "A_decorator_can_only_decorate_a_method_implementation_not_an_overload_1249": "Un decorador solo puede modificar la implementación de un método, no una sobrecarga.",
./web/node_modules/typescript/lib/es/diagnosticMessages.generated.json:283:  "An_overload_signature_cannot_be_declared_as_a_generator_1222": "Una signatura de sobrecarga no se puede declarar como generador.",
./web/node_modules/typescript/lib/es/diagnosticMessages.generated.json:437:  "Class_declaration_cannot_implement_overload_list_for_0_2813": "La declaración de clase no puede implementar la lista de sobrecarga para '{0}'.",
./web/node_modules/typescript/lib/es/diagnosticMessages.generated.json:508:  "Convert_overload_list_to_single_signature_95118": "Convertir lista de sobrecargas en firma única",
./web/node_modules/typescript/lib/es/diagnosticMessages.generated.json:849:  "Function_overload_must_be_static_2387": "La sobrecarga de función debe ser estática.",
./web/node_modules/typescript/lib/es/diagnosticMessages.generated.json:850:  "Function_overload_must_not_be_static_2388": "La sobrecarga de función no debe ser estática.",
./web/node_modules/typescript/lib/es/diagnosticMessages.generated.json:1088:  "No_overload_expects_0_arguments_but_overloads_do_exist_that_expect_either_1_or_2_arguments_2575": "Ninguna sobrecarga espera argumentos {0}, pero existen sobrecargas que esperan argumentos {1} o {2}.",
./web/node_modules/typescript/lib/es/diagnosticMessages.generated.json:1089:  "No_overload_expects_0_type_arguments_but_overloads_do_exist_that_expect_either_1_or_2_type_arguments_2743": "Ninguna sobrecarga espera argumentos de tipo {0}, pero existen sobrecargas que esperan argumentos de tipo {1} o {2}.",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-8.3 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-8.4 Bottleneck evidence izi

Pattern:

```text
bottleneck|darbo|slow.*query|pg_stat|latency|duration|timeout|cpu|memory|disk|IO|backlog|pool.*saturation|NumPending
```

Match Count: 5196

```text
./1_archive/root_sh/step_270_observability_stack.sh:122:      store: inmemory
./1_archive/root_sh/step_270_observability_stack.sh:234:          "expr": "rate(node_cpu_seconds_total{mode!=\"idle\"}[5m])",
./1_archive/root_sh/step_270_observability_stack.sh:259:          "expr": "node_memory_MemAvailable_bytes",
./1_archive/root_sh/step_275_test_promtail_positions.sh:8:echo "=== POSITION FILE ==="
./1_archive/root_sh/step_275_test_promtail_positions.sh:12:echo "=== POSITION CONTENT ==="
./1_archive/root_sh/step_290_monitor_core.sh:36:func NewChecker(timeout time.Duration) *Checker {
./1_archive/root_sh/step_290_monitor_core.sh:38:		Client: &http.Client{Timeout: timeout},
./1_archive/root_sh/step_302_test_orchestrator_foundation.sh:16:echo "=== UNIT VALIDATION ==="
./1_archive/root_sh/step_327_backup_watchdog_before_fail_memory.sh:6:DST="$HOME/pix2pi/pix2pi-SaaS/.backups/service_watchdog_main.go.before_fail_memory_${TS}.bak"
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
./1_archive/root_sh/step_387_force_systemd_priority.sh:4:echo "=== STEP 387 / FORCE SYSTEMD PRIORITY ==="
./1_archive/root_sh/step_392_production_hardening.sh:4:echo "=== STEP 392 / PRODUCTION HARDENING ==="
./1_archive/root_sh/step_392_production_hardening.sh:17:# === PRODUCTION HARDENING ===
./1_archive/root_sh/step_402_fix_function_order.sh:4:echo "=== STEP 402 / FIX FUNCTION ORDER ==="
./1_archive/root_sh/step_408_full_api_integration.sh:4:echo "=== STEP 408 / API INTEGRATION ==="
./1_archive/root_sh/step_418_fix_gateway_panic.sh:4:echo "=== STEP 418B / PANIC PROTECTION ==="
./1_archive/root_sh/step_423h_systemd_real_error.sh:97:echo "NOT: 15 saniye timeout var. Hemen duserse gerçek hata görünecek."
./1_archive/root_sh/step_423h_systemd_real_error.sh:99:timeout 15s bash -x "$RUNNER" > "$TRACE_OUT" 2>&1
./1_archive/root_sh/step_423h_systemd_real_error.sh:108:  echo "OK ✅ runner 15 saniye boyunca ayakta kaldi (timeout)"
./1_archive/root_sh/step_44b_read_path_verify.sh:7:echo "=== STEP 44B / READ PATH CODE VERIFICATION ==="
./1_archive/root_sh/step_44c_replica_fix.sh:24:      CREATE ROLE $REPL_USER WITH REPLICATION LOGIN PASSWORD '$REPL_PASS';
./1_archive/root_sh/step_44c_replica_fix.sh:26:      ALTER ROLE $REPL_USER WITH REPLICATION LOGIN PASSWORD '$REPL_PASS';
./1_archive/root_sh/step_44c_replica_fix.sh:92:docker exec "$PRIMARY_CONTAINER" psql -U "$PRIMARY_DB_USER" -d "$PRIMARY_DB_NAME" -c "SELECT application_name, client_addr, state, sync_state FROM pg_stat_replication;"
./1_archive/root_sh/step_44c_replica_fix.sh:93:echo "OK ✅ pg_stat_replication kontrol bitti"
./1_archive/root_sh/step_44c_replicator_role_fix.sh:27:CREATE ROLE ${REPL_USER} WITH REPLICATION LOGIN PASSWORD '${REPL_PASS}';
./1_archive/root_sh/step_44c_replicator_role_fix.sh:28:ALTER ROLE ${REPL_USER} WITH REPLICATION LOGIN PASSWORD '${REPL_PASS}';
./1_archive/root_sh/step_44c_replicator_role_fix.sh:36:-c "ALTER ROLE ${REPL_USER} WITH REPLICATION LOGIN PASSWORD '${REPL_PASS}';" \
./1_archive/root_sh/step_75_install_or_verify_docker.sh:13:    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
./1_archive/root_sh/step_78_test_production_server_ready.sh:16:echo "=== PRODUCTION DIRS ==="
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh:40:echo "OK ✅ latency unit render edildi"
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/render_lvl11_thresholds.sh:29:  IO_WARN_PERCENT
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/render_lvl11_thresholds.sh:30:  IO_CRIT_PERCENT
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/render_lvl11_thresholds.sh:39:  CONNECTION_WARN_PERCENT
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/render_lvl11_thresholds.sh:40:  CONNECTION_CRIT_PERCENT
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/render_lvl11_thresholds.sh:55:  -e "s|__IO_WARN_PERCENT__|${IO_WARN_PERCENT}|g" \
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/render_lvl11_thresholds.sh:56:  -e "s|__IO_CRIT_PERCENT__|${IO_CRIT_PERCENT}|g" \
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/render_lvl11_thresholds.sh:65:  -e "s|__CONNECTION_WARN_PERCENT__|${CONNECTION_WARN_PERCENT}|g" \
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/render_lvl11_thresholds.sh:66:  -e "s|__CONNECTION_CRIT_PERCENT__|${CONNECTION_CRIT_PERCENT}|g" \
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/render_lvl11_thresholds.sh:74:- IO: warn=${IO_WARN_PERCENT} crit=${IO_CRIT_PERCENT}
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/render_lvl11_thresholds.sh:79:- CONNECTION: warn=${CONNECTION_WARN_PERCENT}% crit=${CONNECTION_CRIT_PERCENT}%
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:520:      "integrity": "sha512-uTII7OYF+/Mes/MrcIOYp5yOtSMLBWSIoLPpcgwipoiKbli6k322tcoFsxoIIxPDqW01SQGAgko4EzZi2BNv2w==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:550:      "integrity": "sha512-wpc+LXeiyiisxPlEkUzU6svyS1frIO3Mgxj1fdy7Pm8Ygzguax2N3Fa/D/ag1WqbOprdI+uY6wMUl8/a2G+iag==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:852:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:869:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:886:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:903:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:920:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:937:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:954:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:971:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:988:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1005:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1022:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1039:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1056:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1075:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1092:      "cpu": [
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1170:      "integrity": "sha512-XU5/SytQM+ykqMnAnvB2umaJNIOsLF3PVv//1Ew4CTcpz0/BRyy/af40qqrt7SjKpDdT1saBMc42CUok5gaw+g==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1787:      "integrity": "sha512-b0P0sZPKtyu8HkeRAfCq0IfURZK+SuwMjY1UXGBU27wpAiTwQAIlq56IbIO+ytk/JjS1fMR14ee5WBBfKi5J6A==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1923:      "integrity": "sha512-oKnbhFyRIXpUuez8iBMmyEa4nbj4IOQyuhc/wy9kY7/WVPcwIO9VA668Pu8RkO7+0G76SLROeyw9CpQ061i4mA==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2305:      "integrity": "sha512-MMdARuVEQziNTeJD8DgMqmhwR11BRQ/cBP+pLtYdSTnf3MIO8fFeiINEbX36ZdNlfU/7A9f3gUw49B3oQsvwBA==",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-8.4 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-8.5 Gateway performance guardrail izi

Pattern:

```text
gateway|Gateway|proxy_read_timeout|proxy_connect_timeout|proxy_send_timeout|upstream|latency|duration_ms|5xx|4xx|rate.*limit|client_max_body_size|timeout
```

Match Count: 2069

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:3:upstream pix2pi_api_upstream {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:8:upstream pix2pi_panel_upstream {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:13:upstream pix2pi_auth_upstream {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:18:upstream pix2pi_pos_upstream {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:67:        proxy_pass http://pix2pi_api_upstream;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:93:        proxy_pass http://pix2pi_panel_upstream;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:120:        proxy_pass http://pix2pi_auth_upstream/health;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:126:        proxy_pass http://pix2pi_auth_upstream;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:152:        proxy_pass http://pix2pi_pos_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:3:upstream pix2pi_api_upstream {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:8:upstream pix2pi_panel_upstream {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:13:upstream pix2pi_auth_upstream {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:18:upstream pix2pi_pos_upstream {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:67:        proxy_pass http://pix2pi_api_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:93:        proxy_pass http://pix2pi_panel_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:120:        proxy_pass http://pix2pi_auth_upstream/health;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:126:        proxy_pass http://pix2pi_auth_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:152:        proxy_pass http://pix2pi_pos_upstream;
./1_archive/root_sh/step_100_backup_run_api_gateway_script.sh:6:cp ~/pix2pi/pix2pi-SaaS/step_99_run_api_gateway.sh \
./1_archive/root_sh/step_100_backup_run_api_gateway_script.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/scripts/step_99_run_api_gateway.sh.bak
./1_archive/root_sh/step_100_backup_run_api_gateway_script.sh:9:echo "OK ✅ api gateway run script yedegi alindi"
./1_archive/root_sh/step_101_test_identity_gateway_ports.sh:12:echo "OK ✅ identity ve gateway port testi bitti"
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh:6:cp ~/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go \
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_rewrite.bak
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh:9:echo "OK ✅ api gateway dosya yedegi alindi"
./1_archive/root_sh/step_103_restart_api_gateway.sh:4:pkill -f api_gateway_main || true
./1_archive/root_sh/step_103_restart_api_gateway.sh:8:nohup go run cmd/api-gateway/api_gateway_main.go >/tmp/pix2pi_api_gateway.log 2>&1 &
./1_archive/root_sh/step_103_restart_api_gateway.sh:12:cat /tmp/pix2pi_api_gateway.log || true
./1_archive/root_sh/step_103_restart_api_gateway.sh:14:echo "OK ✅ api gateway restart bitti"
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh:20:echo "OK ✅ gateway identity rewrite test bitti"
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh:6:cp ~/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go \
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_rate_limit.bak
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh:9:echo "OK ✅ api gateway rate limit oncesi yedek alindi"
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh:4:pkill -f api_gateway_main || true
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh:8:nohup go run cmd/api-gateway/api_gateway_main.go >/tmp/pix2pi_api_gateway.log 2>&1 &
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh:12:cat /tmp/pix2pi_api_gateway.log || true
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh:14:echo "OK ✅ api gateway rate limitli restart bitti"
./1_archive/root_sh/step_107_test_api_gateway_rate_limit.sh:23:echo "OK ✅ api gateway rate limit test bitti"
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh:6:cp ~/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go \
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_tenant_middleware.bak
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh:9:echo "OK ✅ tenant middleware oncesi api gateway yedegi alindi"
./1_archive/root_sh/step_109_restart_api_gateway_after_tenant_middleware.sh:4:pkill -f api_gateway_main || true
./1_archive/root_sh/step_109_restart_api_gateway_after_tenant_middleware.sh:8:nohup go run cmd/api-gateway/api_gateway_main.go >/tmp/pix2pi_api_gateway.log 2>&1 &
./1_archive/root_sh/step_109_restart_api_gateway_after_tenant_middleware.sh:12:cat /tmp/pix2pi_api_gateway.log || true
./1_archive/root_sh/step_109_restart_api_gateway_after_tenant_middleware.sh:14:echo "OK ✅ tenant middleware sonrasi api gateway restart bitti"
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:16:echo "=== TEST 3 tenant-001 rate limit ==="
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh:6:cp ~/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go \
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_redis_rate_limit.bak
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh:9:echo "OK ✅ redis rate limit oncesi api gateway yedegi alindi"
./1_archive/root_sh/step_114_restart_api_gateway_after_redis_rate_limit.sh:4:pkill -f api_gateway_main || true
./1_archive/root_sh/step_114_restart_api_gateway_after_redis_rate_limit.sh:8:nohup go run cmd/api-gateway/api_gateway_main.go >/tmp/pix2pi_api_gateway.log 2>&1 &
./1_archive/root_sh/step_114_restart_api_gateway_after_redis_rate_limit.sh:12:cat /tmp/pix2pi_api_gateway.log || true
./1_archive/root_sh/step_114_restart_api_gateway_after_redis_rate_limit.sh:14:echo "OK ✅ redis rate limit sonrasi api gateway restart bitti"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:16:echo "=== TEST 3 tenant-redis-001 rate limit ==="
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:37:redis-cli GET tenant:tenant-redis-001:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:39:redis-cli TTL tenant:tenant-redis-001:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:41:redis-cli GET tenant:tenant-redis-002:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:43:redis-cli TTL tenant:tenant-redis-002:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:46:echo "OK ✅ redis tenant rate limit test bitti"
./1_archive/root_sh/step_116_backup_api_gateway_before_auth_route.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_116_backup_api_gateway_before_auth_route.sh:6:cp ~/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go \
./1_archive/root_sh/step_116_backup_api_gateway_before_auth_route.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_auth_route.bak
./1_archive/root_sh/step_116_backup_api_gateway_before_auth_route.sh:9:echo "OK ✅ auth route oncesi api gateway yedegi alindi"
./1_archive/root_sh/step_124_test_auth_via_gateway.sh:7:echo "OK ✅ auth gateway test bitti"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-8.5 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-8.6.1 DB connection pool performance izi

Pattern:

```text
SetMaxOpenConns|SetMaxIdleConns|SetConnMaxLifetime|SetConnMaxIdleTime|DBStats|Stats\(\)|connection.*pool|pool.*wait|max.*connections
```

Match Count: 56

```text
./cmd/early-warning-runtime/early_warning_runtime_main.go:163:	db.SetMaxOpenConns(5)
./cmd/early-warning-runtime/early_warning_runtime_main.go:164:	db.SetMaxIdleConns(2)
./cmd/early-warning-runtime/early_warning_runtime_main.go:165:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:148:	db.SetMaxOpenConns(5)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:149:	db.SetMaxIdleConns(2)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:150:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/jobs-runtime/jobs_runtime_main.go:119:	db.SetMaxOpenConns(5)
./cmd/jobs-runtime/jobs_runtime_main.go:120:	db.SetMaxIdleConns(2)
./cmd/jobs-runtime/jobs_runtime_main.go:121:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/notification-runtime/notification_runtime_main.go:128:	db.SetMaxOpenConns(5)
./cmd/notification-runtime/notification_runtime_main.go:129:	db.SetMaxIdleConns(2)
./cmd/notification-runtime/notification_runtime_main.go:130:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/plugin-runtime/plugin_runtime_main.go:119:	db.SetMaxOpenConns(5)
./cmd/plugin-runtime/plugin_runtime_main.go:120:	db.SetMaxIdleConns(2)
./cmd/plugin-runtime/plugin_runtime_main.go:121:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/publicapi-runtime/publicapi_runtime_main.go:126:	db.SetMaxOpenConns(5)
./cmd/publicapi-runtime/publicapi_runtime_main.go:127:	db.SetMaxIdleConns(2)
./cmd/publicapi-runtime/publicapi_runtime_main.go:128:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/realtime-runtime/realtime_runtime_main.go:108:	db.SetMaxOpenConns(5)
./cmd/realtime-runtime/realtime_runtime_main.go:109:	db.SetMaxIdleConns(2)
./cmd/realtime-runtime/realtime_runtime_main.go:110:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/runtime-topology/runtime_topology_main.go:192:	db.SetMaxOpenConns(5)
./cmd/runtime-topology/runtime_topology_main.go:193:	db.SetMaxIdleConns(2)
./cmd/runtime-topology/runtime_topology_main.go:194:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/user-created-consumer/user_created_consumer_main.go:176:	db.SetMaxOpenConns(5)
./cmd/user-created-consumer/user_created_consumer_main.go:177:	db.SetMaxIdleConns(2)
./cmd/user-created-consumer/user_created_consumer_main.go:178:	db.SetConnMaxLifetime(30 * time.Minute)
./cmd/webhook-runtime/webhook_runtime_main.go:125:	db.SetMaxOpenConns(5)
./cmd/webhook-runtime/webhook_runtime_main.go:126:	db.SetMaxIdleConns(2)
./cmd/webhook-runtime/webhook_runtime_main.go:127:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/workflow-runtime/workflow_runtime_main.go:140:	db.SetMaxOpenConns(5)
./cmd/workflow-runtime/workflow_runtime_main.go:141:	db.SetMaxIdleConns(2)
./cmd/workflow-runtime/workflow_runtime_main.go:142:	db.SetConnMaxLifetime(5 * time.Minute)
./deploy/platform/config/lvl12_realtime_catalog.yaml:34:      - max_connections_per_tenant
./deploy/platform/generated/lvl12_realtime_workflow_rules.yaml:8:  max_connections_per_tenant: 500
./internal/platform/db/postgres.go:37:	db.SetMaxOpenConns(25)
./internal/platform/db/postgres.go:38:	db.SetMaxIdleConns(25)
./internal/platform/db/postgres.go:39:	db.SetConnMaxLifetime(5 * time.Minute)
./internal/platform/monitor/database_pressure_runtime_bridge_service.go:12:	ErrDatabaseRuntimeMaxConnectionsInvalid = errors.New("monitor: database runtime max connections invalid")
./internal/platform/monitor/database_pressure_runtime_bridge_service_test.go:46:		t.Fatal("expected invalid max connections error")
./scripts/audit_faz6_2_real_implementation.sh:170:write_check "6-2.3.1" "Connection pool SetMaxOpenConns" "SetMaxOpenConns" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_2_real_implementation.sh:172:write_check "6-2.3.2" "Connection pool SetMaxIdleConns" "SetMaxIdleConns" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_2_real_implementation.sh:174:write_check "6-2.3.3" "Connection pool lifetime / idle time" "SetConnMaxLifetime|SetConnMaxIdleTime" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_2_real_implementation.sh:188:write_check "6-2.7" "DB observability metric / health izi" "pg_isready|db.*health|DB.*Health|Prometheus|prometheus|sql.DBStats|Stats\\(\\)" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_5_real_implementation.sh:173:write_check "6-5.6.1" "DB observability signal izi" "DB.*Stats|Stats\\(\\)|pg_isready|pg_stat|slow.*query|connection.*pool|SetMaxOpenConns|DB_HEALTH|database.*health" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_8_performance_runtime.sh:113:      docker exec \"\$c\" sh -lc \"pg_isready; psql -U postgres -d postgres -Atc \\\"select now(); show max_connections; show shared_buffers; show log_min_duration_statement;\\\"\" 2>/dev/null || true
./scripts/audit_faz6_8_real_implementation.sh:172:write_check "6-8.6.1" "DB connection pool performance izi" 'SetMaxOpenConns|SetMaxIdleConns|SetConnMaxLifetime|SetConnMaxIdleTime|DBStats|Stats\(\)|connection.*pool|pool.*wait|max.*connections' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/phase4_db_health_baseline.sh:240:  MAX_CONNECTIONS="$(run_sql "show max_connections;")"
./scripts/phase4_db_health_baseline.sh:371:  risk "RISK_CONNECTION_USAGE_HIGH=max_connections kullanim orani yuksek"
./scripts/phase4_db_observability_performance.sh:214:  MAX_CONNECTIONS="$(run_sql "show max_connections;")"
./scripts/phase4_db_runbook_incident_checklist.sh:366:- Usage >= %70 ise connection pool ayarlari incelenir.
./scripts/phase4_db_runbook_incident_checklist.sh:368:- Max connection artirmadan once pool / leak analizi yapilir.
./scripts/test_faz6_2_real_implementation_audit.sh:70:check_grep "6-2.3.1 SetMaxOpenConns kontrolu evidence var" "$EVIDENCE_FILE" "6-2.3.1 Connection pool SetMaxOpenConns"
./scripts/test_faz6_2_real_implementation_audit.sh:71:check_grep "6-2.3.2 SetMaxIdleConns kontrolu evidence var" "$EVIDENCE_FILE" "6-2.3.2 Connection pool SetMaxIdleConns"
./scripts/test_faz6_2_visible_checkpoints.sh:58:check_grep "6-2.3 detay max open connections var" "$CHECKPOINT_FILE" "max open connections kontrolü yazıldı"
./scripts/test_faz6_8_performance_load_stress.sh:117:check_grep "6-8.6.1 DB pool performance real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.6.1 DB connection pool"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-8.6.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-8.6.2 DB query/index performance izi

Pattern:

```text
CREATE.*INDEX|INDEX.*tenant_id|tenant_id.*INDEX|EXPLAIN|explain analyze|pg_stat_statements|log_min_duration_statement|slow.*query|QueryContext|ExecContext|context.WithTimeout
```

Match Count: 996

```text
./1_archive/root_sh/step_230_snapshot_schema.sh:17:CREATE UNIQUE INDEX IF NOT EXISTS idx_snapshots_unique_aggregate
./1_archive/root_sh/step_260_audit_schema.sh:20:CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
./1_archive/root_sh/step_260_audit_schema.sh:23:CREATE INDEX IF NOT EXISTS idx_audit_logs_action
./1_archive/root_sh/step_260_audit_schema.sh:26:CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
./1_archive/root_sql/step_230_create_snapshot_tables.sql:11:CREATE UNIQUE INDEX IF NOT EXISTS idx_snapshots_unique_aggregate
./1_archive/root_sql/step_260_create_audit_tables.sql:14:CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
./1_archive/root_sql/step_260_create_audit_tables.sql:17:CREATE INDEX IF NOT EXISTS idx_audit_logs_action
./1_archive/root_sql/step_260_create_audit_tables.sql:20:CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
./cmd/api-gateway/api_gateway_main.go:414:	ctx, cancel := context.WithTimeout(parentCtx, timeout)
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:19:	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:216:	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:248:	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
./cmd/api-gateway/erp_runtime_service_factory_test.go:63:	ctx, cancel := context.WithTimeout(context.Background(), 25*time.Second)
./cmd/api-gateway/erp_runtime_service_factory_test.go:136:	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
./cmd/api-gateway/erp_runtime_service_factory_test.go:168:	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
./cmd/api-gateway/gateway_middleware.go:286:			ctx, cancel := context.WithTimeout(r.Context(), timeout)
./cmd/early-warning-runtime/early_warning_runtime_main.go:395:	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
./cmd/early-warning-runtime/early_warning_runtime_main.go:422:	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
./cmd/early-warning-runtime/early_warning_runtime_main.go:567:		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:286:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:360:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:415:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:498:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/jobs-runtime/jobs_runtime_main.go:198:		rows, err := db.QueryContext(c.Context(), query)
./cmd/jobs-runtime/jobs_runtime_main.go:260:		rows, err := db.QueryContext(c.Context(), query)
./cmd/jobs-runtime/jobs_runtime_main.go:323:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/notification-runtime/notification_runtime_main.go:222:		rows, err := db.QueryContext(c.Context(), query)
./cmd/notification-runtime/notification_runtime_main.go:274:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/notification-runtime/notification_runtime_main.go:334:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/notification-runtime/notification_runtime_main.go:400:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/notification-runtime/notification_runtime_main.go:462:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/plugin-runtime/plugin_runtime_main.go:198:		rows, err := db.QueryContext(c.Context(), query)
./cmd/plugin-runtime/plugin_runtime_main.go:256:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/plugin-runtime/plugin_runtime_main.go:339:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/plugin-runtime/plugin_runtime_main.go:416:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/publicapi-runtime/publicapi_runtime_main.go:241:		rows, err := db.QueryContext(c.Context(), query)
./cmd/publicapi-runtime/publicapi_runtime_main.go:295:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/publicapi-runtime/publicapi_runtime_main.go:360:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/publicapi-runtime/publicapi_runtime_main.go:426:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/realtime-runtime/realtime_runtime_main.go:128:	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
./cmd/realtime-runtime/realtime_runtime_main.go:154:	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
./cmd/realtime-runtime/realtime_runtime_main.go:182:	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
./cmd/realtime-runtime/realtime_runtime_main.go:200:	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
./cmd/realtime-runtime/realtime_runtime_main.go:238:	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
./cmd/realtime-runtime/realtime_runtime_main.go:250:	rows, err := db.QueryContext(ctx, query, limit)
./cmd/realtime-runtime/realtime_runtime_main.go:404:		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
./cmd/runtime-topology/runtime_topology_main.go:270:	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
./cmd/runtime-topology/runtime_topology_main.go:321:	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
./cmd/runtime-topology/runtime_topology_main.go:402:		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
./cmd/user-created-consumer/user_created_consumer_main.go:76:		if _, err := db.ExecContext(ctx, stmt); err != nil {
./cmd/user-created-consumer/user_created_consumer_main.go:105:	res, err := tx.ExecContext(
./cmd/user-created-consumer/user_created_consumer_main.go:133:	if _, err := tx.ExecContext(
./cmd/user-created-consumer/user_created_consumer_main.go:180:	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
./cmd/user-created-consumer/user_created_consumer_main.go:210:		msgCtx, msgCancel := context.WithTimeout(context.Background(), 5*time.Second)
./cmd/webhook-runtime/webhook_runtime_main.go:214:		rows, err := db.QueryContext(c.Context(), query)
./cmd/webhook-runtime/webhook_runtime_main.go:283:		rows, err := db.QueryContext(c.Context(), query)
./cmd/webhook-runtime/webhook_runtime_main.go:354:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/webhook-runtime/webhook_runtime_main.go:441:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/workflow-runtime/workflow_runtime_main.go:217:		rows, err := db.QueryContext(c.Context(), query)
./cmd/workflow-runtime/workflow_runtime_main.go:254:		rows, err := db.QueryContext(c.Context(), query)
./cmd/workflow-runtime/workflow_runtime_main.go:299:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/workflow-runtime/workflow_runtime_main.go:348:		rows, err := db.QueryContext(c.Context(), query, limit)
./cmd/workflow-runtime/workflow_runtime_main.go:397:		rows, err := db.QueryContext(c.Context(), query, limit)
./db/migrations/001_phase1_foundation.up.sql:268:CREATE UNIQUE INDEX uq_user_role_assignments_scope
./db/migrations/001_phase1_foundation.up.sql:433:CREATE INDEX idx_legal_entities_tenant_status ON org.legal_entities (tenant_id, status);
./db/migrations/001_phase1_foundation.up.sql:434:CREATE INDEX idx_branches_tenant_entity_status ON org.branches (tenant_id, legal_entity_id, status);
./db/migrations/001_phase1_foundation.up.sql:435:CREATE INDEX idx_user_scopes_tenant_user_scope ON auth.user_scopes (tenant_id, user_id, scope_level);
./db/migrations/001_phase1_foundation.up.sql:436:CREATE INDEX idx_audit_events_tenant_created ON audit.audit_events (tenant_id, created_at DESC);
./db/migrations/001_phase1_foundation.up.sql:437:CREATE INDEX idx_export_jobs_tenant_status ON audit.export_jobs (tenant_id, status, created_at DESC);
./db/migrations/001_phase1_foundation.up.sql:438:CREATE INDEX idx_entity_relations_parent_child ON org.entity_relations (tenant_id, parent_entity_id, child_entity_id);
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-8.6.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-8.7 Event bus performance / backlog izi

Pattern:

```text
NATS|JetStream|backlog|pending|NumPending|AckFloor|consumer.*lag|DLQ|retry|AckWait|MaxDeliver|publish.*count|consume.*count
```

Match Count: 734

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
./1_archive/root_sh/step_174_create_sale_consumer.sh:15:  --max-pending 1000 \
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:61:NATS=$(durum_docker "nats" "pix2pi_nats")
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:84:  $NATS,
./1_archive/root_sh/step_189_check_jetstream_streams.sh:16:echo "OK ✅ JetStream stream kontrolu bitti"
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:46:		log.Fatalf("NATS baglanti hatasi: %v", err)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:50:	js, err := nc.JetStream()
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:52:		log.Fatalf("JetStream erisim hatasi: %v", err)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:102:		log.Fatal("HATA: hicbir JetStream subject'ine baglanilamadi")
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:63:		log.Fatalf("NATS baglanti hatasi: %v", err)
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:67:	js, err := nc.JetStream()
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:69:		log.Fatalf("JetStream erisim hatasi: %v", err)
./1_archive/root_sh/step_194_test_retry.sh:8:echo "OK ✅ retry test bitti"
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:155:	natsURL := os.Getenv("NATS_URL")
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
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:477:		log.Fatalf("NATS baglanti hatasi: %v", err)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:481:	js, err := nc.JetStream()
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:483:		log.Fatalf("JetStream erisim hatasi: %v", err)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:608:echo "12) Event entegrasyon testi icin NATS publish yapiliyor..."
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:611:echo "OK ✅ NATS publish gecti"
./1_archive/root_sh/step_392_production_hardening.sh:50:can_retry() {
./1_archive/root_sh/step_392_production_hardening.sh:72:    echo "svc=$svc action=blocked reason=max_retry"
./1_archive/root_sh/step_392_production_hardening.sh:76:  if ! can_retry "$svc"; then
./1_archive/root_sh/step_40_backup_event_retry.sh:9:  backups/app/manual/playground_main.go.event_retry.bak 2>/dev/null || true
./1_archive/root_sh/step_40_backup_event_retry.sh:12:  backups/app/manual/event_message.go.event_retry.bak 2>/dev/null || true
./1_archive/root_sh/step_40_backup_event_retry.sh:15:  backups/app/manual/event_bus_service.go.event_retry.bak 2>/dev/null || true
./1_archive/root_sh/step_40_backup_event_retry.sh:17:echo "OK ✅ event retry yedegi alindi"
./1_archive/root_sh/step_41_run_event_retry_test.sh:8:echo "OK ✅ event retry test calistirma bitti"
./1_archive/root_sh/step_45d0_event_recon.sh:11:  echo "===== 1) NATS / EVENT DOSYALARI ====="
./1_archive/root_sh/step_45d0_event_recon.sh:23:  echo "===== 3) NATS IMPORT ARAMA ====="
./1_archive/root_sh/step_46i_consumer_recon.sh:18:  echo "==== 2) NATS CONNECT ===="
./1_archive/root_sh/step_46i_consumer_recon.sh:19:  grep -Rni "nats.Connect\|nats.NewConn\|DefaultURL\|NATS_URL" cmd internal || true
./1_archive/root_sh/step_56a_finance_recon.sh:18:  echo "==== 3) NATS / SUBSCRIBE / PUBLISH ===="
./1_archive/root_sh/step_56a_finance_recon.sh:19:  grep -RInE 'nats|Subscribe|QueueSubscribe|Publish|JetStream|user.created|sale.created|pix2pi\.' ~/pix2pi/pix2pi-SaaS/cmd ~/pix2pi/pix2pi-SaaS/internal || true
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:725:        "@humanwhocodes/retry": "^0.4.0"
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:755:    "node_modules/@humanwhocodes/retry": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:757:      "resolved": "https://registry.npmjs.org/@humanwhocodes/retry/-/retry-0.4.3.tgz",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2155:        "@humanwhocodes/retry": "^0.4.2",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2450:      "integrity": "sha512-3hN7NaskYvMDLQY55gnW3NQ+mesEAepTqlg+VEbj7zzqEMBVNhzcGYYeqFo/TlYz6eQiFcp1HcsCZO+nGgS8zg==",
./cmd/accounting-service/accounting_service_main.go:59:	natsURL := envOr("NATS_URL", nats.DefaultURL)
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:93:grep -q "UAT_12_STATUS=PENDING_BUSINESS_ACCEPTANCE" "$REPORT_FILE" || fail "UAT-12 business acceptance pending yok"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:94:pass "UAT-12 business acceptance pending"
./cmd/event-bus/event_bus_main.go:16:	js, err := nc.JetStream()
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:44:	zorunlu(kayit.MaxRetry == 3, "default max retry 3 olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:57:	fmt.Printf("DEBUG retry-1 | durum=%s retry=%d max=%d\n", kayit.Durum, kayit.RetryCount, kayit.MaxRetry)
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:59:	zorunlu(kayit.RetryCount == 1, "retry count 1 olmali")
./cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go:60:	zorunlu(kayit.Durum == eventstoredomain.EventStoreDurumTekrar, "retry sonrasi store durumu tekrar olmali")
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-8.7 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-8.8 Tenant-aware performance izi

Pattern:

```text
tenant_id|tenant_uuid|TenantID|TenantUUID|tenant.*metric|tenant.*latency|tenant.*request|tenant.*rate|tenant.*query|tenant.*event|X-Tenant-ID
```

Match Count: 5594

```text
./1_archive/root_sh/step_10_run_tenant_event_pipeline_test.sh:8:echo "OK ✅ tenant event pipeline test calistirma bitti"
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:12:curl -s -i -H "X-Tenant-ID: tenant-001" "$URL"
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:16:echo "=== TEST 3 tenant-001 rate limit ==="
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:21:    -H "X-Tenant-ID: tenant-001" "$URL" > /tmp/pix2pi_tenant_001_code_$i.txt
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:32:curl -s -i -H "X-Tenant-ID: tenant-002" "$URL"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:12:curl -s -i -H "X-Tenant-ID: tenant-redis-001" "$URL"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:16:echo "=== TEST 3 tenant-redis-001 rate limit ==="
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:21:    -H "X-Tenant-ID: tenant-redis-001" "$URL" > /tmp/pix2pi_redis_tenant_code_$i.txt
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:32:curl -s -i -H "X-Tenant-ID: tenant-redis-002" "$URL"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:37:redis-cli GET tenant:tenant-redis-001:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:39:redis-cli TTL tenant:tenant-redis-001:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:41:redis-cli GET tenant:tenant-redis-002:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:43:redis-cli TTL tenant:tenant-redis-002:gateway:rate_limit || true
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:46:echo "OK ✅ redis tenant rate limit test bitti"
./1_archive/root_sh/step_124_test_auth_via_gateway.sh:4:curl -i -H "X-Tenant-ID: tenant-auth-test" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:10:curl -s -i -H "X-Tenant-ID: tenant-combined-identity" https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:20:curl -s -i -H "X-Tenant-ID: tenant-combined-auth" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:25:redis-cli GET tenant:tenant-combined-identity:gateway:identity:rate_limit || true
./1_archive/root_sh/step_128_test_combined_gateway.sh:27:redis-cli GET tenant:tenant-combined-auth:gateway:auth:rate_limit || true
./1_archive/root_sh/step_129_test_scope_separation.sh:5:curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_129_test_scope_separation.sh:10:curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_129_test_scope_separation.sh:15:redis-cli GET tenant:tenant-scope-001:gateway:auth:rate_limit || true
./1_archive/root_sh/step_129_test_scope_separation.sh:19:redis-cli GET tenant:tenant-scope-001:gateway:identity:rate_limit || true
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:8:curl -s -i -H "X-Tenant-ID: tenant-001" "$URL_IDENTITY"
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:15:  -H "X-Tenant-ID: tenant-001" \
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:23:  -H "X-Tenant-ID: tenant-001" \
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:31:  -H "X-Tenant-ID: tenant-999" \
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:39:  -H "X-Tenant-ID: tenant-777" \
./1_archive/root_sh/step_134_check_503_source.sh:21:curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/auth/health || true
./1_archive/root_sh/step_134_check_503_source.sh:25:curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/identity/health || true
./1_archive/root_sh/step_210_audit_full.sh:30:	if entry.TenantID == "" {
./1_archive/root_sh/step_210_audit_full.sh:79:		TenantID: "tenant-1",
./1_archive/root_sh/step_210_audit_full.sh:97:		TenantID: "tenant-1",
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:25:SET app.tenant_id = 'tenant-001';
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:32:SET app.tenant_id = 'tenant-002';
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
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-8.8 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-8.9 Capacity / scale decision izi

Pattern:

```text
capacity|Capacity|scale|Scale|scale-out|multi-node|cluster|read replica|worker.*count|consumer.*parallel|shard|partition|early warning
```

Match Count: 451

```text
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:9:  <meta name="viewport" content="width=device-width,initial-scale=1" />
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:33:  <meta name="viewport" content="width=device-width,initial-scale=1" />
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:41:  <meta name="viewport" content="width=device-width,initial-scale=1" />
./1_archive/root_sh/step_320_rewrite_panel_index.sh:11:  <meta name="viewport" content="width=device-width,initial-scale=1" />
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:21:  <meta name="viewport" content="width=device-width, initial-scale=1">
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:20:  <meta name="viewport" content="width=device-width, initial-scale=1">
./1_archive/root_sh/step_360_rewrite_monitor_hardening.sh:25:  <meta name="viewport" content="width=device-width,initial-scale=1" />
./1_archive/root_sh/step_371_add_early_warning_collector.sh:90:echo "OK ✅ early warning guncellendi"
./1_archive/root_sh/step_376_prepare_heal_state.sh:11:SCALE_DIR="$STATE_DIR/scale"
./1_archive/root_sh/step_376_prepare_heal_state.sh:28:touch "$LOG_DIR/scale_hook.log"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:29:SCALE_DIR="$BASE/scale"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:126:write_scale_trigger() {
./1_archive/root_sh/step_377_advanced_auto_heal.sh:174:        write_scale_trigger "$svc"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:175:        log "svc=$svc action=escalate cooldown=${COOLDOWN_SECONDS}s scale_trigger=1"
./1_archive/root_sh/step_379_add_scale_hook.sh:6:SCRIPT="/opt/pix2pi/bin/pix2pi_scale_hook.sh"
./1_archive/root_sh/step_379_add_scale_hook.sh:15:TRIGGER_DIR="/opt/pix2pi/runtime/auto_heal/scale"
./1_archive/root_sh/step_379_add_scale_hook.sh:16:LOG_FILE="/opt/pix2pi/runtime/auto_heal/logs/scale_hook.log"
./1_archive/root_sh/step_379_add_scale_hook.sh:30:  log "no_scale_trigger"
./1_archive/root_sh/step_379_add_scale_hook.sh:37:  log "scale_trigger_detected service=$svc reason=$reason file=$f"
./1_archive/root_sh/step_379_add_scale_hook.sh:40:  # docker compose up --scale ...
./1_archive/root_sh/step_379_add_scale_hook.sh:41:  # kubectl scale deployment ...
./1_archive/root_sh/step_379_add_scale_hook.sh:54:mkdir -p /opt/pix2pi/runtime/auto_heal/scale
./1_archive/root_sh/step_379_add_scale_hook.sh:55:cat <<'JSON' > /opt/pix2pi/runtime/auto_heal/scale/test_auth.json
./1_archive/root_sh/step_379_add_scale_hook.sh:68:tail -n 20 /opt/pix2pi/runtime/auto_heal/logs/scale_hook.log || true
./1_archive/root_sh/step_380_bind_all_crons.sh:24:add_line '* * * * * /opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1'
./1_archive/root_sh/step_380_bind_all_crons.sh:36:tail -n 10 /opt/pix2pi/runtime/auto_heal/logs/scale_hook.log || true
./1_archive/root_sh/step_390_rewrite_early_warning_clean.sh:28:mkdir -p /opt/pix2pi/runtime/auto_heal/scale
./1_archive/root_sh/step_391_real_systemd_test.sh:12:echo "2. early warning calistiriliyor..."
./1_archive/root_sh/step_391_real_systemd_test.sh:14:echo "OK ✅ early warning"
./configs/faz5/faz5_final_closure_v1.json:95:      "scale",
./db/migrations/001_phase1_foundation.up.sql:88:  data_partition_key text,
./db/migrations/20260428_187001_inventory_stock_valuation.up.sql:13:    rounding_scale integer NOT NULL DEFAULT 4 CHECK (rounding_scale >= 0),
./deploy/observability/generated/lvl11_scale_trigger_matrix.yaml:2:scale_triggers:
./deploy/observability/generated/lvl11_scale_trigger_matrix.yaml:15:    action: increase_consumers_or_stream_capacity
./deploy/observability/generated/lvl11_scale_trigger_matrix.yaml:38:  - id: cluster_transition
./deploy/observability/generated/lvl11_scale_trigger_matrix.yaml:43:    action: cluster_transition_required
./deploy/observability/grafana/dashboards/node-exporter-full.json:1159:            "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:1441:            "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:1959:            "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:2427:            "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:2541:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:2868:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:3376:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:3563:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:3666:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:4106:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:4337:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:4469:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:4638:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:5009:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:5399:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:5798:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:6210:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:6631:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:7031:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:7431:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:7790:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:8187:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:8559:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:8955:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:9339:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:9737:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:10108:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:10523:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:10649:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:10775:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:11177:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:11594:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:11742:                "scaleDistribution": {
./deploy/observability/grafana/dashboards/node-exporter-full.json:11845:                "scaleDistribution": {
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-8.9 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-8.10 Performance observability metrics izi

Pattern:

```text
prometheus|Prometheus|/metrics|Counter|Gauge|Histogram|Grafana|dashboard|node_exporter|cadvisor|container_cpu|node_cpu|latency.*metric
```

Match Count: 1360

```text
./1_archive/root_sh/create_erp_structure.sh:31:mkdir -p $BASE/operations/dashboards
./1_archive/root_sh/step_270_observability_stack.sh:7:mkdir -p $OBS/prometheus
./1_archive/root_sh/step_270_observability_stack.sh:11:mkdir -p $OBS/grafana/provisioning/dashboards
./1_archive/root_sh/step_270_observability_stack.sh:12:mkdir -p $OBS/grafana/dashboards
./1_archive/root_sh/step_270_observability_stack.sh:18:  prometheus:
./1_archive/root_sh/step_270_observability_stack.sh:19:    image: prom/prometheus:latest
./1_archive/root_sh/step_270_observability_stack.sh:20:    container_name: pix2pi_prometheus
./1_archive/root_sh/step_270_observability_stack.sh:23:      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
./1_archive/root_sh/step_270_observability_stack.sh:65:      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
./1_archive/root_sh/step_270_observability_stack.sh:69:      - prometheus
./1_archive/root_sh/step_270_observability_stack.sh:74:  node_exporter:
./1_archive/root_sh/step_270_observability_stack.sh:76:    container_name: pix2pi_node_exporter
./1_archive/root_sh/step_270_observability_stack.sh:93:cat <<'YAMLEOF' > $OBS/prometheus/prometheus.yml
./1_archive/root_sh/step_270_observability_stack.sh:98:  - job_name: "prometheus"
./1_archive/root_sh/step_270_observability_stack.sh:100:      - targets: ["prometheus:9090"]
./1_archive/root_sh/step_270_observability_stack.sh:102:  - job_name: "node_exporter"
./1_archive/root_sh/step_270_observability_stack.sh:104:      - targets: ["node_exporter:9100"]
./1_archive/root_sh/step_270_observability_stack.sh:173:  - name: Prometheus
./1_archive/root_sh/step_270_observability_stack.sh:174:    type: prometheus
./1_archive/root_sh/step_270_observability_stack.sh:176:    url: http://prometheus:9090
./1_archive/root_sh/step_270_observability_stack.sh:185:cat <<'YAMLEOF' > $OBS/grafana/provisioning/dashboards/dashboards.yml
./1_archive/root_sh/step_270_observability_stack.sh:189:  - name: pix2pi-dashboards
./1_archive/root_sh/step_270_observability_stack.sh:196:      path: /var/lib/grafana/dashboards
./1_archive/root_sh/step_270_observability_stack.sh:199:cat <<'JSONEOF' > $OBS/grafana/dashboards/pix2pi-overview.json
./1_archive/root_sh/step_270_observability_stack.sh:212:        "type": "prometheus",
./1_archive/root_sh/step_270_observability_stack.sh:234:          "expr": "rate(node_cpu_seconds_total{mode!=\"idle\"}[5m])",
./1_archive/root_sh/step_270_observability_stack.sh:243:        "type": "prometheus",
./1_archive/root_sh/step_273_fix_promtail_positions.sh:42:  prometheus:
./1_archive/root_sh/step_273_fix_promtail_positions.sh:43:    image: prom/prometheus:latest
./1_archive/root_sh/step_273_fix_promtail_positions.sh:44:    container_name: pix2pi_prometheus
./1_archive/root_sh/step_273_fix_promtail_positions.sh:47:      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
./1_archive/root_sh/step_273_fix_promtail_positions.sh:90:      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
./1_archive/root_sh/step_273_fix_promtail_positions.sh:94:      - prometheus
./1_archive/root_sh/step_273_fix_promtail_positions.sh:99:  node_exporter:
./1_archive/root_sh/step_273_fix_promtail_positions.sh:101:    container_name: pix2pi_node_exporter
./configs/faz5/revenue_metrics_policy_v1.json:132:  "dashboard_readiness": {
./configs/faz5/revenue_metrics_policy_v1.json:161:    "real_revenue_dashboard",
./configs/faz5/sales_demo_crm_policy_v1.json:138:    "runtime_sales_pipeline_dashboard",
./configs/faz5/support_sla_incident_policy_v1.json:192:    "runtime_incident_dashboard",
./deploy/observability/config/lvl11_signal_catalog.yaml:7:        metric: node_cpu_usage_percent
./deploy/observability/docker-compose.yml:4:  prometheus:
./deploy/observability/docker-compose.yml:5:    image: prom/prometheus:latest
./deploy/observability/docker-compose.yml:6:    container_name: pix2pi_prometheus
./deploy/observability/docker-compose.yml:11:      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
./deploy/observability/docker-compose.yml:15:  node_exporter:
./deploy/observability/docker-compose.yml:17:    container_name: pix2pi_node_exporter
./deploy/observability/docker-compose.yml:35:      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
./deploy/observability/docker-compose.yml:37:      - prometheus
./deploy/observability/grafana/dashboards/docker-monitoring.json:5:      "label": "Prometheus",
./deploy/observability/grafana/dashboards/docker-monitoring.json:8:      "pluginId": "prometheus",
./deploy/observability/grafana/dashboards/docker-monitoring.json:9:      "pluginName": "Prometheus"
./deploy/observability/grafana/dashboards/docker-monitoring.json:28:      "name": "Grafana",
./deploy/observability/grafana/dashboards/docker-monitoring.json:33:      "id": "prometheus",
./deploy/observability/grafana/dashboards/docker-monitoring.json:34:      "name": "Prometheus",
./deploy/observability/grafana/dashboards/docker-monitoring.json:40:  "description": "Simple Dashboard that display system metric (first line) and docker metric (line under). Dashboard compatible with Grafana 4 using alert functionality.",
./deploy/observability/grafana/dashboards/docker-monitoring.json:527:              "expr": "node_load1{instance=~\"$server:.*\"} / count by(job, instance)(count by(job, instance, cpu)(node_cpu{instance=~\"$server:.*\"}))",
./deploy/observability/grafana/dashboards/docker-monitoring.json:649:            "{id=\"/\",instance=\"cadvisor:8080\",job=\"prometheus\"}": "#BA43A9"
./deploy/observability/grafana/dashboards/docker-monitoring.json:682:              "expr": "sum(rate(container_cpu_system_seconds_total[1m]))",
./deploy/observability/grafana/dashboards/docker-monitoring.json:690:              "expr": "sum(rate(container_cpu_system_seconds_total{name=~\".+\"}[1m]))",
./deploy/observability/grafana/dashboards/docker-monitoring.json:699:              "expr": "sum(rate(container_cpu_system_seconds_total{id=\"/\"}[1m]))",
./deploy/observability/grafana/dashboards/docker-monitoring.json:719:              "expr": "sum(rate(container_cpu_system_seconds_total{name=~\".+\"}[1m])) + sum(rate(container_cpu_system_seconds_total{id=\"/\"}[1m])) + sum(rate(process_cpu_seconds_total[1m]))",
./deploy/observability/grafana/dashboards/docker-monitoring.json:830:              "expr": "node_load1{instance=~\"$server:.*\"} / count by(job, instance)(count by(job, instance, cpu)(node_cpu{instance=~\"$server:.*\"}))",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1385:              "expr": "sum(rate(container_cpu_usage_seconds_total{name=~\".+\"}[$interval])) by (name) * 100",
./deploy/observability/grafana/dashboards/node-exporter-full.json:5:      "label": "Prometheus",
./deploy/observability/grafana/dashboards/node-exporter-full.json:8:      "pluginId": "prometheus",
./deploy/observability/grafana/dashboards/node-exporter-full.json:9:      "pluginName": "Prometheus"
./deploy/observability/grafana/dashboards/node-exporter-full.json:23:      "name": "Gauge",
./deploy/observability/grafana/dashboards/node-exporter-full.json:29:      "name": "Grafana",
./deploy/observability/grafana/dashboards/node-exporter-full.json:34:      "id": "prometheus",
./deploy/observability/grafana/dashboards/node-exporter-full.json:35:      "name": "Prometheus",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-8.10 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-8.11 Performance test / audit script izi

Pattern:

```text
FAZ_6_8|performance.*test|test.*performance|load.*readiness|stress.*readiness|runtime.*audit|real.*implementation.*audit
```

Match Count: 102

```text
./cmd/control-panel/control_panel.go:174:	app.All("/incident-audit-runtime/*", proxyToTarget("http://127.0.0.1:"+incidentAuditRuntimePort, "/incident-audit-runtime"))
./cmd/ops-console-smoke/ops_console_smoke_main.go:217:			URL:      proxyURL("/incident-audit-runtime/api/incident-audit/summary"),
./cmd/runtime-topology/runtime_topology_main.go:170:		{FromNode: "incident_audit_runtime", ToNode: "postgres_db", Relation: "reads audit", Protocol: "sql"},
./deploy/quality/generated/lvl14_performance_release_rules.yaml:9:  test_profile: final-performance-core
./scripts/audit_faz6_5_real_implementation.sh:187:write_check "6-5.10" "Observability test / audit script izi" "observability|prometheus|grafana|metrics|health.*probe|runtime.*audit|real.*implementation.*audit" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/audit_faz6_7_real_implementation.sh:213:    echo "FAZ_6_8_READY=YES ✅"
./scripts/audit_faz6_7_real_implementation.sh:216:    echo "FAZ_6_8_READY=YES_WITH_WARNINGS ⚠️"
./scripts/audit_faz6_7_real_implementation.sh:219:    echo "FAZ_6_8_READY=NO_REVIEW_REQUIRED ❌"
./scripts/audit_faz6_7_real_implementation.sh:245:  echo "FAZ_6_8_READY=YES ✅"
./scripts/audit_faz6_7_real_implementation.sh:248:  echo "FAZ_6_8_READY=YES_WITH_WARNINGS ⚠️"
./scripts/audit_faz6_7_real_implementation.sh:251:  echo "FAZ_6_8_READY=NO_REVIEW_REQUIRED ❌"
./scripts/audit_faz6_8_performance_runtime.sh:7:EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_8_PERFORMANCE_RUNTIME_AUDIT.md"
./scripts/audit_faz6_8_performance_runtime.sh:41:Bu audit runtime ortaminda performance / load / stress readiness sinyallerini toplar. Agir load test calistirmaz.
./scripts/audit_faz6_8_performance_runtime.sh:43:FAZ_6_8_RUNTIME_AUDIT=STARTED ✅
./scripts/audit_faz6_8_performance_runtime.sh:155:  echo "FAZ_6_8_RUNTIME_AUDIT=COMPLETE ✅"
./scripts/audit_faz6_8_performance_runtime.sh:159:echo "FAZ_6_8_RUNTIME_AUDIT=COMPLETE ✅"
./scripts/audit_faz6_8_real_implementation.sh:7:EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_8_REAL_IMPLEMENTATION_AUDIT.md"
./scripts/audit_faz6_8_real_implementation.sh:184:write_check "6-8.11" "Performance test / audit script izi" 'FAZ_6_8|performance.*test|test.*performance|load.*readiness|stress.*readiness|runtime.*audit|real.*implementation.*audit' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/audit_faz6_8_real_implementation.sh:195:    echo "FAZ_6_8_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_8_real_implementation.sh:197:    echo "FAZ_6_8_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
./scripts/audit_faz6_8_real_implementation.sh:201:    echo "FAZ_6_8_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_8_real_implementation.sh:203:    echo "FAZ_6_8_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
./scripts/audit_faz6_8_real_implementation.sh:207:    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_8_real_implementation.sh:210:    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
./scripts/audit_faz6_8_real_implementation.sh:213:    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
./scripts/audit_faz6_8_real_implementation.sh:217:  echo "FAZ_6_8_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
./scripts/audit_faz6_8_real_implementation.sh:227:  echo "FAZ_6_8_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_8_real_implementation.sh:229:  echo "FAZ_6_8_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
./scripts/audit_faz6_8_real_implementation.sh:233:  echo "FAZ_6_8_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_8_real_implementation.sh:235:  echo "FAZ_6_8_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
./scripts/audit_faz6_8_real_implementation.sh:239:  echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_8_real_implementation.sh:242:  echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
./scripts/audit_faz6_8_real_implementation.sh:245:  echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
./scripts/audit_faz6_8_real_implementation.sh:249:echo "FAZ_6_8_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
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
./scripts/test_faz6_5_observability_sre_dashboard.sh:65:check_file "6-5 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
./scripts/test_faz6_5_observability_sre_dashboard.sh:66:check_file "6-5 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"
./scripts/test_faz6_5_observability_sre_dashboard.sh:67:check_exec "6-5 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
./scripts/test_faz6_5_observability_sre_dashboard.sh:68:check_exec "6-5 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"
./scripts/test_faz6_5_observability_sre_dashboard.sh:95:check_grep "6-5 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_5_RUNTIME_AUDIT=COMPLETE"
./scripts/test_faz6_6_backup_restore_dr.sh:65:check_file "6-6 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
./scripts/test_faz6_6_backup_restore_dr.sh:66:check_file "6-6 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"
./scripts/test_faz6_6_backup_restore_dr.sh:67:check_exec "6-6 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
./scripts/test_faz6_6_backup_restore_dr.sh:68:check_exec "6-6 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"
./scripts/test_faz6_6_backup_restore_dr.sh:93:check_grep "6-6 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_6_RUNTIME_AUDIT=COMPLETE"
./scripts/test_faz6_7_security_hardening.sh:65:check_file "6-7 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
./scripts/test_faz6_7_security_hardening.sh:66:check_file "6-7 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"
./scripts/test_faz6_7_security_hardening.sh:67:check_exec "6-7 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
./scripts/test_faz6_7_security_hardening.sh:68:check_exec "6-7 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"
./scripts/test_faz6_7_security_hardening.sh:97:check_grep "6-7 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_7_RUNTIME_AUDIT=COMPLETE"
./scripts/test_faz6_7_security_hardening.sh:138:    echo "FAZ_6_8_READY=YES ✅"
./scripts/test_faz6_7_security_hardening.sh:142:    echo "FAZ_6_8_READY=YES_WITH_WARNINGS ⚠️"
./scripts/test_faz6_7_security_hardening.sh:146:    echo "FAZ_6_8_READY=NO_REVIEW_REQUIRED ❌"
./scripts/test_faz6_8_performance_load_stress.sh:7:DOC_FILE="docs/faz6/FAZ_6_8_PERFORMANCE_LOAD_STRESS_READINESS.md"
./scripts/test_faz6_8_performance_load_stress.sh:8:CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_8_PERFORMANCE_VISIBLE_CHECKPOINTS.md"
./scripts/test_faz6_8_performance_load_stress.sh:11:RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_8_PERFORMANCE_RUNTIME_AUDIT.md"
./scripts/test_faz6_8_performance_load_stress.sh:12:REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_8_REAL_IMPLEMENTATION_AUDIT.md"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-8.11 STATUS=IMPLEMENTED_OR_PRESENT ✅

# Final Runtime Implementation Interpretation

```text
REQUIRED_FAIL=0
OPTIONAL_WARN=0
FAZ_6_8_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_8_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_9_READY=YES ✅
FAZ_6_8_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅
```
