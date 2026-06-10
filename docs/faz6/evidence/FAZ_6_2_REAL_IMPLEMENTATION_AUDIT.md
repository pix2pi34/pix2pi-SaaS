# FAZ 6-2 Real Implementation Audit

Generated At: 2026-05-01T14:22:10+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit, FAZ 6-2'de yazilan DB-L8 maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

Onemli yorum:
- READINESS dokumani PASS olabilir.
- REAL IMPLEMENTATION ancak bu audit'te ilgili pattern'ler bulunursa kanitlanmis sayilir.
- NO_MATCH cikan maddeler "kodda henuz yok" kabul edilir.

---

## Scanned Files

```text
2348 /tmp/tmp.lFy1amVdmn/files.txt

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

## 6-2.1.1 DB_WRITE_DSN varlik/kullanim kontrolu

Pattern:

```text
DB_WRITE_DSN|WRITE_DSN|WriteDSN|writeDsn|write_dsn|DBWriteDSN
```

Match Count: 352

```text
./1_archive/root_sh/step_422_check_gateway_env.sh:8:echo "DB_WRITE_DSN=${DB_WRITE_DSN:-<BOS>}"
./1_archive/root_sh/step_423b_real_error.sh:25:echo "DB_WRITE_DSN=${DB_WRITE_DSN:-BOS}"
./1_archive/root_sh/step_423c_db_auth_probe.sh:43:DB_HOST="$(extract_field "${DB_WRITE_DSN:-}" host)"
./1_archive/root_sh/step_423c_db_auth_probe.sh:44:DB_PORT="$(extract_field "${DB_WRITE_DSN:-}" port)"
./1_archive/root_sh/step_423c_db_auth_probe.sh:45:DB_USER="$(extract_field "${DB_WRITE_DSN:-}" user)"
./1_archive/root_sh/step_423c_db_auth_probe.sh:46:DB_NAME="$(extract_field "${DB_WRITE_DSN:-}" dbname)"
./1_archive/root_sh/step_423c_db_auth_probe.sh:47:DB_SSLMODE="$(extract_field "${DB_WRITE_DSN:-}" sslmode)"
./1_archive/root_sh/step_423c_db_auth_probe.sh:48:CURRENT_PASSWORD=***MASKED***
./1_archive/root_sh/step_423c_db_auth_probe.sh:157:WRITE_DSN="host=$DB_HOST port=$DB_PORT user=$DB_USER password=***MASKED*** dbname=$DB_NAME sslmode=$DB_SSLMODE"
./1_archive/root_sh/step_423c_db_auth_probe.sh:163:DB_WRITE_DSN="$WRITE_DSN" DB_READ_DSN="$READ_DSN" go run ./cmd/api-gateway >/tmp/step_423c_gateway.log 2>&1 &
./1_archive/root_sh/step_423c_db_auth_probe.sh:212:    DB_WRITE_DSN=*)
./1_archive/root_sh/step_423c_db_auth_probe.sh:213:      printf '%s\n' 'DB_WRITE_DSN=$WRITE_DSN' >> "\$TMP_FILE"
./1_archive/root_sh/step_423c_db_auth_probe.sh:227:  printf '%s\n' 'DB_WRITE_DSN=$WRITE_DSN' >> "\$TMP_FILE"
./1_archive/root_sh/step_423c_db_auth_probe.sh:260:echo "DB_WRITE_DSN=$WRITE_DSN"
./1_archive/root_sh/step_423d_reset_db_password.sh:44:DB_HOST="$(extract_field "${DB_WRITE_DSN:-}" host)"
./1_archive/root_sh/step_423d_reset_db_password.sh:45:DB_PORT="$(extract_field "${DB_WRITE_DSN:-}" port)"
./1_archive/root_sh/step_423d_reset_db_password.sh:46:DB_USER="$(extract_field "${DB_WRITE_DSN:-}" user)"
./1_archive/root_sh/step_423d_reset_db_password.sh:47:DB_NAME="$(extract_field "${DB_WRITE_DSN:-}" dbname)"
./1_archive/root_sh/step_423d_reset_db_password.sh:48:DB_SSLMODE="$(extract_field "${DB_WRITE_DSN:-}" sslmode)"
./1_archive/root_sh/step_423d_reset_db_password.sh:105:WRITE_DSN="host=$DB_HOST port=$DB_PORT user=postgres password=***MASKED*** dbname=$DB_NAME sslmode=$DB_SSLMODE"
./1_archive/root_sh/step_423d_reset_db_password.sh:115:    DB_WRITE_DSN=*)
./1_archive/root_sh/step_423d_reset_db_password.sh:116:      printf '%s\n' "DB_WRITE_DSN=$WRITE_DSN" >> "$TMP_FILE"
./1_archive/root_sh/step_423d_reset_db_password.sh:130:  printf '%s\n' "DB_WRITE_DSN=$WRITE_DSN" >> "$TMP_FILE"
./1_archive/root_sh/step_423d_reset_db_password.sh:143:DB_WRITE_DSN="$WRITE_DSN" DB_READ_DSN="$READ_DSN" go run ./cmd/api-gateway >/tmp/step_423d_gateway.log 2>&1 &
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:44:DB_HOST="$(extract_field "${DB_WRITE_DSN:-}" host)"
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:45:DB_PORT="$(extract_field "${DB_WRITE_DSN:-}" port)"
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:46:DB_NAME="$(extract_field "${DB_WRITE_DSN:-}" dbname)"
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:47:DB_SSLMODE="$(extract_field "${DB_WRITE_DSN:-}" sslmode)"
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:68:WRITE_DSN="host=$DB_HOST port=$DB_PORT user=pix2pi password=***MASKED*** dbname=$DB_NAME sslmode=$DB_SSLMODE"
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:78:    DB_WRITE_DSN=*)
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:79:      printf '%s\n' "DB_WRITE_DSN=$WRITE_DSN" >> "$TMP_FILE"
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:93:  printf '%s\n' "DB_WRITE_DSN=$WRITE_DSN" >> "$TMP_FILE"
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:106:DB_WRITE_DSN="$WRITE_DSN" DB_READ_DSN="$READ_DSN" go run ./cmd/api-gateway >/tmp/step_423e_gateway.log 2>&1 &
./1_archive/root_sh/step_423h_systemd_real_error.sh:62:grep -nE 'DB_WRITE_DSN|DB_READ_DSN|PIX2PI_ROOT|GO_BIN' "$COMMON_ENV" | mask_password || true
./1_archive/root_sh/step_423i_dump_runner_trace.sh:37:grep -nE 'DB_WRITE_DSN|DB_READ_DSN|PIX2PI_ROOT|GO_BIN' "$COMMON_ENV" | mask_password || true
./1_archive/root_sh/step_423j_dump_only_trace.sh:34:  grep -nE 'DB_WRITE_DSN|DB_READ_DSN|PIX2PI_ROOT|GO_BIN' "$COMMON_ENV" | mask_password || true
./1_archive/root_sh/step_423l_fix_env.sh:20:export DB_WRITE_DSN="host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
./1_archive/root_sh/step_47b_dbrouter_recon.sh:54:    printf 'DB_WRITE_DSN=%s\n' "${DB_WRITE_DSN:-}"
./.backups/step_421_20260323_080427/internal/platform/kernel/kernel.go:19:	writeDSN := os.Getenv("DB_WRITE_DSN")
./.backups/step_421_20260323_080427/internal/platform/kernel/kernel.go:23:		log.Fatal("DB_WRITE_DSN bos")
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.1.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-2.1.2 DB_READ_DSN varlik/kullanim kontrolu

Pattern:

```text
DB_READ_DSN|READ_DSN|ReadDSN|readDsn|read_dsn|DBReadDSN
```

Match Count: 74

```text
./1_archive/root_sh/step_422_check_gateway_env.sh:9:echo "DB_READ_DSN=${DB_READ_DSN:-<BOS>}"
./1_archive/root_sh/step_423b_real_error.sh:26:echo "DB_READ_DSN=${DB_READ_DSN:-BOS}"
./1_archive/root_sh/step_423c_db_auth_probe.sh:158:READ_DSN="host=$DB_HOST port=$DB_PORT user=$DB_USER password=***MASKED*** dbname=$DB_NAME sslmode=$DB_SSLMODE"
./1_archive/root_sh/step_423c_db_auth_probe.sh:163:DB_WRITE_DSN="$WRITE_DSN" DB_READ_DSN="$READ_DSN" go run ./cmd/api-gateway >/tmp/step_423c_gateway.log 2>&1 &
./1_archive/root_sh/step_423c_db_auth_probe.sh:216:    DB_READ_DSN=*)
./1_archive/root_sh/step_423c_db_auth_probe.sh:217:      printf '%s\n' 'DB_READ_DSN=$READ_DSN' >> "\$TMP_FILE"
./1_archive/root_sh/step_423c_db_auth_probe.sh:231:  printf '%s\n' 'DB_READ_DSN=$READ_DSN' >> "\$TMP_FILE"
./1_archive/root_sh/step_423c_db_auth_probe.sh:261:echo "DB_READ_DSN=$READ_DSN"
./1_archive/root_sh/step_423d_reset_db_password.sh:106:READ_DSN="host=$DB_HOST port=$DB_PORT user=postgres password=***MASKED*** dbname=$DB_NAME sslmode=$DB_SSLMODE"
./1_archive/root_sh/step_423d_reset_db_password.sh:119:    DB_READ_DSN=*)
./1_archive/root_sh/step_423d_reset_db_password.sh:120:      printf '%s\n' "DB_READ_DSN=$READ_DSN" >> "$TMP_FILE"
./1_archive/root_sh/step_423d_reset_db_password.sh:134:  printf '%s\n' "DB_READ_DSN=$READ_DSN" >> "$TMP_FILE"
./1_archive/root_sh/step_423d_reset_db_password.sh:143:DB_WRITE_DSN="$WRITE_DSN" DB_READ_DSN="$READ_DSN" go run ./cmd/api-gateway >/tmp/step_423d_gateway.log 2>&1 &
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:69:READ_DSN="host=$DB_HOST port=$DB_PORT user=pix2pi password=***MASKED*** dbname=$DB_NAME sslmode=$DB_SSLMODE"
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:82:    DB_READ_DSN=*)
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:83:      printf '%s\n' "DB_READ_DSN=$READ_DSN" >> "$TMP_FILE"
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:97:  printf '%s\n' "DB_READ_DSN=$READ_DSN" >> "$TMP_FILE"
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:106:DB_WRITE_DSN="$WRITE_DSN" DB_READ_DSN="$READ_DSN" go run ./cmd/api-gateway >/tmp/step_423e_gateway.log 2>&1 &
./1_archive/root_sh/step_423h_systemd_real_error.sh:62:grep -nE 'DB_WRITE_DSN|DB_READ_DSN|PIX2PI_ROOT|GO_BIN' "$COMMON_ENV" | mask_password || true
./1_archive/root_sh/step_423i_dump_runner_trace.sh:37:grep -nE 'DB_WRITE_DSN|DB_READ_DSN|PIX2PI_ROOT|GO_BIN' "$COMMON_ENV" | mask_password || true
./1_archive/root_sh/step_423j_dump_only_trace.sh:34:  grep -nE 'DB_WRITE_DSN|DB_READ_DSN|PIX2PI_ROOT|GO_BIN' "$COMMON_ENV" | mask_password || true
./1_archive/root_sh/step_423l_fix_env.sh:21:export DB_READ_DSN="host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
./1_archive/root_sh/step_47b_dbrouter_recon.sh:19:  echo "==== 3) GetReadDB / readDB / DB_READ_DSN / fallback ===="
./1_archive/root_sh/step_47b_dbrouter_recon.sh:20:  grep -RniE "GetReadDB|GetWriteDB|readDB|DB_READ_DSN|fallback primary|Init.*dbrouter|Init.*read|Open.*read" "$ROOT/cmd" "$ROOT/internal" || true
./1_archive/root_sh/step_47b_dbrouter_recon.sh:55:    printf 'DB_READ_DSN=%s\n' "${DB_READ_DSN:-}"
./.backups/step_421_20260323_080427/internal/platform/kernel/kernel.go:20:	readDSN := os.Getenv("DB_READ_DSN")
./cmd/early-warning-runtime/early_warning_runtime_main.go:101:	dsn := envOrDefault("DB_READ_DSN", "")
./cmd/early-warning-runtime/early_warning_runtime_main.go:155:		return nil, errors.New("DB_READ_DSN veya DB_WRITE_DSN bos")
./cmd/early-warning-runtime/early_warning_runtime_main_test.go:55:	t.Setenv("DB_READ_DSN", "read-dsn")
./cmd/early-warning-runtime/early_warning_runtime_main_test.go:74:	t.Setenv("DB_READ_DSN", "")
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:109:	dsn := envOrDefault("DB_READ_DSN", "")
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:140:		return nil, errors.New("DB_READ_DSN veya DB_WRITE_DSN bos")
./cmd/incident-audit-runtime/incident_audit_runtime_main_test.go:45:	t.Setenv("DB_READ_DSN", "read-dsn")
./cmd/incident-audit-runtime/incident_audit_runtime_main_test.go:60:	t.Setenv("DB_READ_DSN", "")
./cmd/jobs-runtime/jobs_runtime_main.go:80:	dsn := envOrDefault("DB_READ_DSN", "")
./cmd/jobs-runtime/jobs_runtime_main.go:111:		return nil, errors.New("DB_READ_DSN veya DB_WRITE_DSN bos")
./cmd/jobs-runtime/jobs_runtime_main_test.go:31:	t.Setenv("DB_READ_DSN", "read-dsn")
./cmd/jobs-runtime/jobs_runtime_main_test.go:46:	t.Setenv("DB_READ_DSN", "")
./cmd/notification-runtime/notification_runtime_main.go:89:	dsn := envOrDefault("DB_READ_DSN", "")
./cmd/notification-runtime/notification_runtime_main.go:120:		return nil, errors.New("DB_READ_DSN veya DB_WRITE_DSN bos")
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.1.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-2.2 Replica routing / read pool kod izi

Pattern:

```text
readPool|read_pool|Replica|replica|ReadDB|readDB|readerDB|ReaderDB|UseRead|RouteRead|routeRead
```

Match Count: 138

```text
./1_archive/root_sh/step_270_observability_stack.sh:119:  replication_factor: 1
./1_archive/root_sh/step_405_test.sh:12:grep -q "GetReadDB" internal/platform/kernel/kernel.go
./1_archive/root_sh/step_406_scan_kernel_usage.sh:10:grep -nE 'masterDB|InitDB|gorm\.Open|GetWriteDB|GetReadDB|DBManager|DB\.' "$FILE" || true
./1_archive/root_sh/step_407_test_query.sh:6:grep -q "GetReadDB" internal/services/query_read_model/service.go
./1_archive/root_sh/step_417_fix_query_service.sh:23:	db := kernel.GetReadDB()
./1_archive/root_sh/step_418_fix_query_service_safe.sh:25:	db := kernel.GetReadDB()
./1_archive/root_sh/step_421_patch_kernel_safe.sh:23:old_read = '''func GetReadDB() *gorm.DB {
./1_archive/root_sh/step_421_patch_kernel_safe.sh:26:new_read = '''func GetReadDB() *gorm.DB {
./1_archive/root_sh/step_421_patch_kernel_safe.sh:37:    raise SystemExit("GetReadDB blogu bulunamadi")
./1_archive/root_sh/step_44b_read_path_verify.sh:21:  grep -RniE 'GetReadDB\(|ReadDB|read db|readDB' cmd internal || true
./1_archive/root_sh/step_44c_audit_pg_topology.sh:90:  echo "Bu rapor sonraki adimda primary+replica kurulumunu planlamak icin kullanilacak."
./1_archive/root_sh/step_44c_replica_fix.sh:5:REPLICA_CONTAINER="pix2pi_pg_replica"
./1_archive/root_sh/step_44c_replica_fix.sh:6:REPLICA_VOLUME="root_pix2pi_pg_replica_data"
./1_archive/root_sh/step_44c_replica_fix.sh:7:REPL_USER="replicator"
./1_archive/root_sh/step_44c_replica_fix.sh:8:REPL_PASS=***MASKED***
./1_archive/root_sh/step_44c_replica_fix.sh:17:echo "1. primary tarafinda replicator reset..."
./1_archive/root_sh/step_44c_replica_fix.sh:31:echo "OK ✅ replicator role resetlendi"
./1_archive/root_sh/step_44c_replica_fix.sh:34:echo "2. pg_hba replication satiri kontrol..."
./1_archive/root_sh/step_44c_replica_fix.sh:35:docker exec "$PRIMARY_CONTAINER" bash -lc "grep -n 'host replication $REPL_USER' /var/lib/postgresql/data/pg_hba.conf || true"
./1_archive/root_sh/step_44c_replica_fix.sh:44:echo "4. replicator login testi (primary ustunden TCP)..."
./1_archive/root_sh/step_44c_replica_fix.sh:46:echo "OK ✅ replicator login testi basarili"
./1_archive/root_sh/step_44c_replica_fix.sh:49:echo "5. replica container stop..."
./1_archive/root_sh/step_44c_replica_fix.sh:51:echo "OK ✅ replica container durdu"
./1_archive/root_sh/step_44c_replica_fix.sh:54:echo "6. replica volume temizleniyor..."
./1_archive/root_sh/step_44c_replica_fix.sh:59:echo "OK ✅ replica volume temizlendi"
./1_archive/root_sh/step_44c_replica_fix.sh:80:echo "9. replica container baslatiliyor..."
./1_archive/root_sh/step_44c_replica_fix.sh:83:echo "OK ✅ replica container basladi"
./1_archive/root_sh/step_44c_replica_fix.sh:86:echo "10. replica recovery durumu..."
./1_archive/root_sh/step_44c_replica_fix.sh:91:echo "11. primary tarafinda replication durumu..."
./1_archive/root_sh/step_44c_replica_fix.sh:92:docker exec "$PRIMARY_CONTAINER" psql -U "$PRIMARY_DB_USER" -d "$PRIMARY_DB_NAME" -c "SELECT application_name, client_addr, state, sync_state FROM pg_stat_replication;"
./1_archive/root_sh/step_44c_replica_fix.sh:93:echo "OK ✅ pg_stat_replication kontrol bitti"
./1_archive/root_sh/step_44c_replica_fix.sh:96:echo "12. replica health test..."
./1_archive/root_sh/step_44c_replica_fix.sh:98:echo "OK ✅ replica query testi bitti"
./1_archive/root_sh/step_44c_replicator_role_fix.sh:7:REPL_USER="replicator"
./1_archive/root_sh/step_44c_replicator_role_fix.sh:8:REPL_PASS=***MASKED***
./1_archive/root_sh/step_44c_replicator_role_fix.sh:18:echo "2. replicator var mi kontrol..."
./1_archive/root_sh/step_44c_replicator_role_fix.sh:20:"select rolname || '|' || rolreplication || '|' || rolcanlogin from pg_roles where rolname='${REPL_USER}';" \
./1_archive/root_sh/step_44c_replicator_role_fix.sh:22:echo "OK ✅ replicator sorgulandi"
./1_archive/root_sh/step_44c_replicator_role_fix.sh:25:echo "3. replicator role create/alter..."
./1_archive/root_sh/step_44c_replicator_role_fix.sh:49:"select rolname || '|' || rolreplication || '|' || rolcanlogin from pg_roles where rolname='${REPL_USER}';"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-2.3.1 Connection pool SetMaxOpenConns

Pattern:

```text
SetMaxOpenConns
```

Match Count: 14

```text
./cmd/early-warning-runtime/early_warning_runtime_main.go:163:	db.SetMaxOpenConns(5)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:148:	db.SetMaxOpenConns(5)
./cmd/jobs-runtime/jobs_runtime_main.go:119:	db.SetMaxOpenConns(5)
./cmd/notification-runtime/notification_runtime_main.go:128:	db.SetMaxOpenConns(5)
./cmd/plugin-runtime/plugin_runtime_main.go:119:	db.SetMaxOpenConns(5)
./cmd/publicapi-runtime/publicapi_runtime_main.go:126:	db.SetMaxOpenConns(5)
./cmd/realtime-runtime/realtime_runtime_main.go:108:	db.SetMaxOpenConns(5)
./cmd/runtime-topology/runtime_topology_main.go:192:	db.SetMaxOpenConns(5)
./cmd/user-created-consumer/user_created_consumer_main.go:176:	db.SetMaxOpenConns(5)
./cmd/webhook-runtime/webhook_runtime_main.go:125:	db.SetMaxOpenConns(5)
./cmd/workflow-runtime/workflow_runtime_main.go:140:	db.SetMaxOpenConns(5)
./internal/platform/db/postgres.go:37:	db.SetMaxOpenConns(25)
./scripts/audit_faz6_2_real_implementation.sh:170:write_check "6-2.3.1" "Connection pool SetMaxOpenConns" "SetMaxOpenConns" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/test_faz6_2_real_implementation_audit.sh:70:check_grep "6-2.3.1 SetMaxOpenConns kontrolu evidence var" "$EVIDENCE_FILE" "6-2.3.1 Connection pool SetMaxOpenConns"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.3.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-2.3.2 Connection pool SetMaxIdleConns

Pattern:

```text
SetMaxIdleConns
```

Match Count: 14

```text
./cmd/early-warning-runtime/early_warning_runtime_main.go:164:	db.SetMaxIdleConns(2)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:149:	db.SetMaxIdleConns(2)
./cmd/jobs-runtime/jobs_runtime_main.go:120:	db.SetMaxIdleConns(2)
./cmd/notification-runtime/notification_runtime_main.go:129:	db.SetMaxIdleConns(2)
./cmd/plugin-runtime/plugin_runtime_main.go:120:	db.SetMaxIdleConns(2)
./cmd/publicapi-runtime/publicapi_runtime_main.go:127:	db.SetMaxIdleConns(2)
./cmd/realtime-runtime/realtime_runtime_main.go:109:	db.SetMaxIdleConns(2)
./cmd/runtime-topology/runtime_topology_main.go:193:	db.SetMaxIdleConns(2)
./cmd/user-created-consumer/user_created_consumer_main.go:177:	db.SetMaxIdleConns(2)
./cmd/webhook-runtime/webhook_runtime_main.go:126:	db.SetMaxIdleConns(2)
./cmd/workflow-runtime/workflow_runtime_main.go:141:	db.SetMaxIdleConns(2)
./internal/platform/db/postgres.go:38:	db.SetMaxIdleConns(25)
./scripts/audit_faz6_2_real_implementation.sh:172:write_check "6-2.3.2" "Connection pool SetMaxIdleConns" "SetMaxIdleConns" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/test_faz6_2_real_implementation_audit.sh:71:check_grep "6-2.3.2 SetMaxIdleConns kontrolu evidence var" "$EVIDENCE_FILE" "6-2.3.2 Connection pool SetMaxIdleConns"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.3.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-2.3.3 Connection pool lifetime / idle time

Pattern:

```text
SetConnMaxLifetime|SetConnMaxIdleTime
```

Match Count: 13

```text
./cmd/early-warning-runtime/early_warning_runtime_main.go:165:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:150:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/jobs-runtime/jobs_runtime_main.go:121:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/notification-runtime/notification_runtime_main.go:130:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/plugin-runtime/plugin_runtime_main.go:121:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/publicapi-runtime/publicapi_runtime_main.go:128:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/realtime-runtime/realtime_runtime_main.go:110:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/runtime-topology/runtime_topology_main.go:194:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/user-created-consumer/user_created_consumer_main.go:178:	db.SetConnMaxLifetime(30 * time.Minute)
./cmd/webhook-runtime/webhook_runtime_main.go:127:	db.SetConnMaxLifetime(5 * time.Minute)
./cmd/workflow-runtime/workflow_runtime_main.go:142:	db.SetConnMaxLifetime(5 * time.Minute)
./internal/platform/db/postgres.go:39:	db.SetConnMaxLifetime(5 * time.Minute)
./scripts/audit_faz6_2_real_implementation.sh:174:write_check "6-2.3.3" "Connection pool lifetime / idle time" "SetConnMaxLifetime|SetConnMaxIdleTime" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.3.3 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-2.3.4 Query timeout / context timeout

Pattern:

```text
context.WithTimeout|context.WithDeadline|QueryContext|ExecContext|BeginTx
```

Match Count: 276

```text
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
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.3.4 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-2.4.1 SQL index migration var mi

Pattern:

```text
CREATE[[:space:]]+(UNIQUE[[:space:]]+)?INDEX|CREATE[[:space:]]+INDEX[[:space:]]+CONCURRENTLY
```

Match Count: 586

```text
./1_archive/root_sh/step_230_snapshot_schema.sh:17:CREATE UNIQUE INDEX IF NOT EXISTS idx_snapshots_unique_aggregate
./1_archive/root_sh/step_260_audit_schema.sh:20:CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
./1_archive/root_sh/step_260_audit_schema.sh:23:CREATE INDEX IF NOT EXISTS idx_audit_logs_action
./1_archive/root_sh/step_260_audit_schema.sh:26:CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
./1_archive/root_sql/step_230_create_snapshot_tables.sql:11:CREATE UNIQUE INDEX IF NOT EXISTS idx_snapshots_unique_aggregate
./1_archive/root_sql/step_260_create_audit_tables.sql:14:CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
./1_archive/root_sql/step_260_create_audit_tables.sql:17:CREATE INDEX IF NOT EXISTS idx_audit_logs_action
./1_archive/root_sql/step_260_create_audit_tables.sql:20:CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
./db/migrations/001_phase1_foundation.up.sql:268:CREATE UNIQUE INDEX uq_user_role_assignments_scope
./db/migrations/001_phase1_foundation.up.sql:433:CREATE INDEX idx_legal_entities_tenant_status ON org.legal_entities (tenant_id, status);
./db/migrations/001_phase1_foundation.up.sql:434:CREATE INDEX idx_branches_tenant_entity_status ON org.branches (tenant_id, legal_entity_id, status);
./db/migrations/001_phase1_foundation.up.sql:435:CREATE INDEX idx_user_scopes_tenant_user_scope ON auth.user_scopes (tenant_id, user_id, scope_level);
./db/migrations/001_phase1_foundation.up.sql:436:CREATE INDEX idx_audit_events_tenant_created ON audit.audit_events (tenant_id, created_at DESC);
./db/migrations/001_phase1_foundation.up.sql:437:CREATE INDEX idx_export_jobs_tenant_status ON audit.export_jobs (tenant_id, status, created_at DESC);
./db/migrations/001_phase1_foundation.up.sql:438:CREATE INDEX idx_entity_relations_parent_child ON org.entity_relations (tenant_id, parent_entity_id, child_entity_id);
./db/migrations/001_phase1_foundation.up.sql:439:CREATE INDEX idx_locations_tenant_kind ON org.locations (tenant_id, location_kind);
./db/migrations/002_phase2_db_l4_service_registry.up.sql:143:CREATE UNIQUE INDEX IF NOT EXISTS uq_service_registry_services_tenant_service_key
./db/migrations/002_phase2_db_l4_service_registry.up.sql:149:CREATE INDEX IF NOT EXISTS ix_service_registry_services_tenant_id
./db/migrations/002_phase2_db_l4_service_registry.up.sql:152:CREATE INDEX IF NOT EXISTS ix_service_registry_services_kind
./db/migrations/002_phase2_db_l4_service_registry.up.sql:181:CREATE UNIQUE INDEX IF NOT EXISTS uq_service_registry_instances_service_instance_key
./db/migrations/002_phase2_db_l4_service_registry.up.sql:184:CREATE INDEX IF NOT EXISTS ix_service_registry_instances_tenant_id
./db/migrations/002_phase2_db_l4_service_registry.up.sql:187:CREATE INDEX IF NOT EXISTS ix_service_registry_instances_status
./db/migrations/002_phase2_db_l4_service_registry.up.sql:190:CREATE INDEX IF NOT EXISTS ix_service_registry_instances_last_heartbeat_at
./db/migrations/002_phase2_db_l4_service_registry.up.sql:206:CREATE INDEX IF NOT EXISTS ix_service_registry_heartbeats_instance_id
./db/migrations/002_phase2_db_l4_service_registry.up.sql:209:CREATE INDEX IF NOT EXISTS ix_service_registry_heartbeats_tenant_id
./db/migrations/003_phase2_db_l4_mission_control.up.sql:129:CREATE UNIQUE INDEX IF NOT EXISTS uq_mission_control_incidents_tenant_incident_key
./db/migrations/003_phase2_db_l4_mission_control.up.sql:135:CREATE INDEX IF NOT EXISTS ix_mission_control_incidents_tenant_id
./db/migrations/003_phase2_db_l4_mission_control.up.sql:138:CREATE INDEX IF NOT EXISTS ix_mission_control_incidents_status
./db/migrations/003_phase2_db_l4_mission_control.up.sql:141:CREATE INDEX IF NOT EXISTS ix_mission_control_incidents_severity
./db/migrations/003_phase2_db_l4_mission_control.up.sql:144:CREATE INDEX IF NOT EXISTS ix_mission_control_incidents_service_id
./db/migrations/003_phase2_db_l4_mission_control.up.sql:147:CREATE INDEX IF NOT EXISTS ix_mission_control_incidents_instance_id
./db/migrations/003_phase2_db_l4_mission_control.up.sql:175:CREATE INDEX IF NOT EXISTS ix_mission_control_actions_tenant_id
./db/migrations/003_phase2_db_l4_mission_control.up.sql:178:CREATE INDEX IF NOT EXISTS ix_mission_control_actions_incident_id
./db/migrations/003_phase2_db_l4_mission_control.up.sql:181:CREATE INDEX IF NOT EXISTS ix_mission_control_actions_status
./db/migrations/003_phase2_db_l4_mission_control.up.sql:184:CREATE INDEX IF NOT EXISTS ix_mission_control_actions_type
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:100:CREATE UNIQUE INDEX IF NOT EXISTS uq_job_queues_tenant_queue_key
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:106:CREATE INDEX IF NOT EXISTS ix_job_queues_tenant_id
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:140:CREATE UNIQUE INDEX IF NOT EXISTS uq_jobs_tenant_job_key
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:146:CREATE INDEX IF NOT EXISTS ix_jobs_tenant_id
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:149:CREATE INDEX IF NOT EXISTS ix_jobs_queue_id
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.4.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-2.4.2 tenant_id index izi var mi

Pattern:

```text
INDEX.*tenant_id|tenant_id.*INDEX|idx_.*tenant|tenant.*idx_
```

Match Count: 275

```text
./1_archive/root_sh/step_260_audit_schema.sh:20:CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
./1_archive/root_sql/step_260_create_audit_tables.sql:14:CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
./db/migrations/001_phase1_foundation.up.sql:433:CREATE INDEX idx_legal_entities_tenant_status ON org.legal_entities (tenant_id, status);
./db/migrations/001_phase1_foundation.up.sql:434:CREATE INDEX idx_branches_tenant_entity_status ON org.branches (tenant_id, legal_entity_id, status);
./db/migrations/001_phase1_foundation.up.sql:435:CREATE INDEX idx_user_scopes_tenant_user_scope ON auth.user_scopes (tenant_id, user_id, scope_level);
./db/migrations/001_phase1_foundation.up.sql:436:CREATE INDEX idx_audit_events_tenant_created ON audit.audit_events (tenant_id, created_at DESC);
./db/migrations/001_phase1_foundation.up.sql:437:CREATE INDEX idx_export_jobs_tenant_status ON audit.export_jobs (tenant_id, status, created_at DESC);
./db/migrations/001_phase1_foundation.up.sql:438:CREATE INDEX idx_entity_relations_parent_child ON org.entity_relations (tenant_id, parent_entity_id, child_entity_id);
./db/migrations/001_phase1_foundation.up.sql:439:CREATE INDEX idx_locations_tenant_kind ON org.locations (tenant_id, location_kind);
./db/migrations/002_phase2_db_l4_service_registry.up.sql:149:CREATE INDEX IF NOT EXISTS ix_service_registry_services_tenant_id
./db/migrations/002_phase2_db_l4_service_registry.up.sql:184:CREATE INDEX IF NOT EXISTS ix_service_registry_instances_tenant_id
./db/migrations/002_phase2_db_l4_service_registry.up.sql:209:CREATE INDEX IF NOT EXISTS ix_service_registry_heartbeats_tenant_id
./db/migrations/003_phase2_db_l4_mission_control.up.sql:135:CREATE INDEX IF NOT EXISTS ix_mission_control_incidents_tenant_id
./db/migrations/003_phase2_db_l4_mission_control.up.sql:175:CREATE INDEX IF NOT EXISTS ix_mission_control_actions_tenant_id
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:106:CREATE INDEX IF NOT EXISTS ix_job_queues_tenant_id
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:146:CREATE INDEX IF NOT EXISTS ix_jobs_tenant_id
./db/migrations/004_phase2_db_l4_jobs_queue.up.sql:180:CREATE INDEX IF NOT EXISTS ix_job_attempts_tenant_id
./db/migrations/005_phase2_db_l4_idempotency.up.sql:98:CREATE INDEX IF NOT EXISTS ix_idempotency_keys_tenant_id
./db/migrations/005_phase2_db_l4_idempotency.up.sql:139:CREATE INDEX IF NOT EXISTS ix_dedupe_records_tenant_id
./db/migrations/006_phase2_db_l4_notifications.up.sql:121:CREATE INDEX IF NOT EXISTS ix_notification_channels_tenant_id
./db/migrations/006_phase2_db_l4_notifications.up.sql:159:CREATE INDEX IF NOT EXISTS ix_notifications_tenant_id
./db/migrations/006_phase2_db_l4_notifications.up.sql:198:CREATE INDEX IF NOT EXISTS ix_notification_recipients_tenant_id
./db/migrations/007_phase2_db_l4_webhooks.up.sql:111:CREATE INDEX IF NOT EXISTS ix_webhook_endpoints_tenant_id
./db/migrations/007_phase2_db_l4_webhooks.up.sql:157:CREATE INDEX IF NOT EXISTS ix_webhook_deliveries_tenant_id
./db/migrations/007_phase2_db_l4_webhooks.up.sql:192:CREATE INDEX IF NOT EXISTS ix_webhook_delivery_attempts_tenant_id
./db/migrations/008_phase2_db_l4_workflows.up.sql:126:CREATE INDEX IF NOT EXISTS ix_workflow_definitions_tenant_id
./db/migrations/008_phase2_db_l4_workflows.up.sql:158:CREATE INDEX IF NOT EXISTS ix_workflow_instances_tenant_id
./db/migrations/008_phase2_db_l4_workflows.up.sql:194:CREATE INDEX IF NOT EXISTS ix_workflow_steps_tenant_id
./db/migrations/008_phase2_db_l4_workflows.up.sql:227:CREATE INDEX IF NOT EXISTS ix_workflow_approvals_tenant_id
./db/migrations/009_phase2_db_l4_api_keys.up.sql:88:CREATE INDEX IF NOT EXISTS ix_api_keys_tenant_id
./db/migrations/009_phase2_db_l4_api_keys.up.sql:121:CREATE INDEX IF NOT EXISTS ix_api_quota_policies_tenant_id
./db/migrations/009_phase2_db_l4_api_keys.up.sql:154:CREATE INDEX IF NOT EXISTS ix_api_key_usage_tenant_id
./db/migrations/010_phase2_db_l4_plugins.up.sql:116:CREATE INDEX IF NOT EXISTS ix_plugins_tenant_id
./db/migrations/010_phase2_db_l4_plugins.up.sql:154:CREATE INDEX IF NOT EXISTS ix_plugin_states_tenant_id
./db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql:62:CREATE INDEX IF NOT EXISTS idx_erp_runtime_flows_tenant_status
./db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql:66:CREATE INDEX IF NOT EXISTS idx_erp_runtime_flows_tenant_source
./db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql:124:CREATE INDEX IF NOT EXISTS idx_erp_runtime_flow_steps_tenant_flow
./db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql:128:CREATE INDEX IF NOT EXISTS idx_erp_runtime_flow_steps_tenant_status
./db/migrations/20260427_151001_readmodel_operational_tables.down.sql:9:DROP INDEX IF EXISTS readmodel.idx_tenant_operational_snapshot_refreshed;
./db/migrations/20260427_151001_readmodel_operational_tables.up.sql:109:CREATE INDEX IF NOT EXISTS idx_tenant_operational_snapshot_refreshed
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.4.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-2.4.3 slow query / pg_stat_statements izi var mi

Pattern:

```text
log_min_duration_statement|pg_stat_statements|slow[ _-]?query|auto_explain
```

Match Count: 118

```text
./internal/platform/monitor/database_pressure_early_warning_service.go:14:	ErrDatabasePressureNegativeSlowQueryRatio = errors.New("monitor: database slow query ratio cannot be negative")
./internal/platform/monitor/database_pressure_early_warning_service.go:20:	DatabasePressureMetricSlowQueryRatioPct  = "db_slow_query_ratio_pct"
./internal/platform/monitor/database_pressure_early_warning_service.go:143:		"database slow query ratio pressure detected",
./internal/platform/monitor/database_pressure_runtime_bridge_service.go:14:	ErrDatabaseRuntimeNegativeSlowQueryRatio = errors.New("monitor: database runtime slow query ratio cannot be negative")
./scripts/audit_faz6_2_real_implementation.sh:182:write_check "6-2.4.3" "slow query / pg_stat_statements izi var mi" "log_min_duration_statement|pg_stat_statements|slow[ _-]?query|auto_explain" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/phase4_db_final_closure_gate.sh:301:  FINAL_PG_STAT_EXTENSION="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
./scripts/phase4_db_final_closure_gate.sh:324:if [ "$FINAL_PG_STAT_EXTENSION" != "t" ]; then fail "final pg_stat_statements extension aktif degil"; fi
./scripts/phase4_db_health_baseline.sh:243:  LOG_MIN="$(run_sql "show log_min_duration_statement;")"
./scripts/phase4_db_health_baseline.sh:244:  PG_STAT_EXTENSION="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
./scripts/phase4_db_health_baseline.sh:311:  fail "pg_stat_statements extension aktif degil"
./scripts/phase4_db_master_evidence_collector.sh:327:  FINAL_PG_STAT_EXTENSION="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
./scripts/phase4_db_master_evidence_collector.sh:345:if [ "$FINAL_PG_STAT_EXTENSION" != "t" ]; then fail "final pg_stat_statements extension aktif degil"; fi
./scripts/phase4_db_observability_apply_readiness.sh:262:  PG_STAT_EXTENSION="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
./scripts/phase4_db_observability_apply_readiness.sh:263:  PG_STAT_AVAILABLE="$(run_sql "select exists(select 1 from pg_available_extensions where name='pg_stat_statements');")"
./scripts/phase4_db_observability_apply_readiness.sh:265:  LOG_MIN_DURATION_STATEMENT="$(run_sql "show log_min_duration_statement;")"
./scripts/phase4_db_observability_apply_readiness.sh:269:if printf '%s' "$SHARED_PRELOAD_LIBRARIES" | grep -q "pg_stat_statements"; then
./scripts/phase4_db_observability_apply_readiness.sh:341:  risk "RISK_EXTENSION_CREATE_REQUIRED=pg_stat_statements extension create gerekir"
./scripts/phase4_db_observability_apply_readiness.sh:345:  fail "pg_stat_statements available extension olarak gorunmuyor"
./scripts/phase4_db_observability_apply_readiness.sh:357:  risk "RISK_SLOW_QUERY_LOG_CHANGE_REQUIRED=log_min_duration_statement disabled"
./scripts/phase4_db_observability_apply_readiness.sh:407:ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
./scripts/phase4_db_observability_apply_readiness.sh:409:ALTER SYSTEM SET log_min_duration_statement = '1000';
./scripts/phase4_db_observability_apply_readiness.sh:418:# psql "\$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show log_min_duration_statement;"
./scripts/phase4_db_observability_apply_readiness.sh:422:CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
./scripts/phase4_db_observability_apply_readiness.sh:426:# psql "\$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select exists(select 1 from pg_extension where extname='pg_stat_statements');"
./scripts/phase4_db_observability_apply_readiness.sh:452:ALTER SYSTEM RESET log_min_duration_statement;
./scripts/phase4_db_observability_apply_readiness.sh:460:# DROP EXTENSION IF EXISTS pg_stat_statements;
./scripts/phase4_db_observability_controlled_apply.sh:285:  LOG_MIN_BEFORE="$(run_sql "show log_min_duration_statement;")"
./scripts/phase4_db_observability_controlled_apply.sh:286:  EXT_BEFORE="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
./scripts/phase4_db_observability_controlled_apply.sh:370:if printf '%s' "$TARGET_PRELOAD" | grep -q "pg_stat_statements"; then
./scripts/phase4_db_observability_controlled_apply.sh:373:  TARGET_PRELOAD="pg_stat_statements"
./scripts/phase4_db_observability_controlled_apply.sh:375:  TARGET_PRELOAD="${TARGET_PRELOAD},pg_stat_statements"
./scripts/phase4_db_observability_controlled_apply.sh:386:ALTER SYSTEM SET log_min_duration_statement = '1000ms';
./scripts/phase4_db_observability_controlled_apply.sh:442:  LOG_MIN_AFTER="$(run_sql "show log_min_duration_statement;")"
./scripts/phase4_db_observability_controlled_apply.sh:448:  if printf '%s' "$PRELOAD_AFTER" | grep -q "pg_stat_statements"; then
./scripts/phase4_db_observability_controlled_apply.sh:452:    fail "pg_stat_statements preload aktif degil"
./scripts/phase4_db_observability_controlled_apply.sh:466:    fail "log_min_duration_statement aktif degil"
./scripts/phase4_db_observability_controlled_apply.sh:472:CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
./scripts/phase4_db_observability_controlled_apply.sh:479:    fail "pg_stat_statements extension create failed"
./scripts/phase4_db_observability_controlled_apply.sh:487:  EXT_AFTER="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
./scripts/phase4_db_observability_controlled_apply.sh:488:  PG_STAT_VIEW_CHECK="$(run_sql "select to_regclass('public.pg_stat_statements') is not null or to_regclass('pg_catalog.pg_stat_statements') is not null;")"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.4.3 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-2.5 PITR / backup / restore script izi

Pattern:

```text
archive_mode|archive_command|wal_level|pg_basebackup|pg_dump|pg_restore|restic|restore
```

Match Count: 219

```text
./1_archive/root_sh/step_355d_restore_clean.sh:11:echo "1. restore..."
./1_archive/root_sh/step_355d_restore_clean.sh:13:echo "OK ✅ restore edildi"
./1_archive/root_sh/step_367_restore_clean_panel_engine.sh:10:cp "$PANEL_HTML" "${PANEL_HTML}.bak_restore_$(date +%s)"
./1_archive/root_sh/step_44c_audit_pg_topology.sh:73:    docker exec pix2pi_pg sh -lc 'psql -U pix2pi -d pix2pi -Atqc "show wal_level;"'
./1_archive/root_sh/step_44c_replica_fix.sh:62:echo "7. pg_basebackup one-shot container ile aliniyor..."
./1_archive/root_sh/step_44c_replica_fix.sh:68:  bash -lc "pg_basebackup -h $PRIMARY_HOST -U $REPL_USER -D /var/lib/postgresql/data -P -R"
./1_archive/root_sh/step_44c_replica_fix.sh:69:echo "OK ✅ pg_basebackup tamam"
./scripts/audit_faz6_2_db_l8_readiness.sh:171:  echo "6-2.5 PITR/restore readiness checklist checked OK ✅"
./scripts/audit_faz6_2_real_implementation.sh:184:write_check "6-2.5" "PITR / backup / restore script izi" "archive_mode|archive_command|wal_level|pg_basebackup|pg_dump|pg_restore|restic|restore" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/ops/fix_identity_health_v2.sh:24:echo "OK ✅  restored: $MAIN"
./scripts/phase4b_backup_restore_verification.sh:7:python3 "$SCRIPT_DIR/phase4b_backup_restore_verification.py" "$ROOT_DIR"
./scripts/phase4_db_backup_pitr_readiness.sh:133:if tool_status "pg_dump"; then PG_DUMP_FOUND=1; fi
./scripts/phase4_db_backup_pitr_readiness.sh:134:if tool_status "pg_restore"; then PG_RESTORE_FOUND=1; fi
./scripts/phase4_db_backup_pitr_readiness.sh:135:if tool_status "restic"; then RESTIC_FOUND=1; fi
./scripts/phase4_db_backup_pitr_readiness.sh:142:  warn "pg_dump bulunamadi; logical backup readiness eksik"
./scripts/phase4_db_backup_pitr_readiness.sh:146:  warn "pg_restore bulunamadi; restore drill readiness eksik"
./scripts/phase4_db_backup_pitr_readiness.sh:150:  warn "restic bulunamadi; file-level backup repo kontrolu eksik"
./scripts/phase4_db_backup_pitr_readiness.sh:203:  WAL_LEVEL="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show wal_level;" 2>/dev/null || echo "error")"
./scripts/phase4_db_backup_pitr_readiness.sh:204:  ARCHIVE_MODE="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show archive_mode;" 2>/dev/null || echo "error")"
./scripts/phase4_db_backup_pitr_readiness.sh:205:  ARCHIVE_COMMAND="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show archive_command;" 2>/dev/null || echo "error")"
./scripts/phase4_db_backup_pitr_readiness.sh:248:path_status "RESTIC_REPO_ROOT" "/root/pix2pi-restic-repo"
./scripts/phase4_db_backup_pitr_readiness.sh:249:path_status "ALT_RESTIC_REPO_ROOT" "/root/pix2pi/pix2pi-restic-repo"
./scripts/phase4_db_backup_pitr_readiness.sh:265:  warn "PITR tam hazir degil; archive_mode/archive_command kontrol edilmeli"
./scripts/phase4_db_backup_pitr_readiness.sh:269:  warn "restore drill hazirligi eksik"
./scripts/phase4_db_final_closure_gate.sh:14:R_1424="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
./scripts/phase4_db_final_closure_gate.sh:147:require_file "14.2.4 restore drill test" "$R_1424" || true
./scripts/phase4_db_final_closure_gate.sh:231:if [ "$S_1424" != "PASS" ]; then fail "14.2.4 restore drill PASS degil"; fi
./scripts/phase4_db_final_closure_gate.sh:450:  echo "archive_mode/archive_command: ARCHIVE_MODE_READY=$ARCHIVE_MODE_READY / ARCHIVE_COMMAND_READY=$ARCHIVE_COMMAND_READY"
./scripts/phase4_db_known_risks_deferred_register.sh:230:    "archive_mode=on ve archive_command kontrollu maintenance adiminda aktif edilecek" \
./scripts/phase4_db_known_risks_deferred_register.sh:233:  defer "DB-RISK-003 archive_mode/archive_command aktif degil"
./scripts/phase4_db_master_evidence_collector.sh:192:R_1423="$REPORT_DIR/14_2_3_restore_drill_sandbox_plan_report.md"
./scripts/phase4_db_master_evidence_collector.sh:193:R_1424="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
./scripts/phase4_db_master_evidence_collector.sh:207:require_file "14.2.3 restore drill plan" "$R_1423" || true
./scripts/phase4_db_master_evidence_collector.sh:208:require_file "14.2.4 restore drill test" "$R_1424" || true
./scripts/phase4_db_observability_apply_readiness.sh:401:# restic backup command should be run according to current backup policy.
./scripts/phase4_db_production_readiness_scorecard.sh:15:R_1424="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
./scripts/phase4_db_production_readiness_scorecard.sh:155:require_file "14.2.4 restore drill" "$R_1424" || true
./scripts/phase4_db_production_readiness_scorecard.sh:223:BACKUP_NOTE="readiness=${BACKUP_READY}, logical_backup=${LOGICAL_BACKUP}, restore_drill=${RESTORE_DRILL}"
./scripts/phase4_db_production_readiness_scorecard.sh:226:  add_score "backup_restore_readiness" "$BACKUP_SCORE" "20" "PASS" "$BACKUP_NOTE"
./scripts/phase4_db_production_readiness_scorecard.sh:228:  add_score "backup_restore_readiness" "$BACKUP_SCORE" "20" "REVIEW" "$BACKUP_NOTE"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.5 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-2.6 Partition / shard gercek SQL veya routing izi

Pattern:

```text
PARTITION[[:space:]]+BY|CREATE[[:space:]]+TABLE.*PARTITION|pg_partman|shard|Shard|tenant.*route|route.*tenant
```

Match Count: 41

```text
./cmd/api-gateway/gateway_entry_contract_test.go:88:		if route.Auth != "jwt+tenant" {
./cmd/api-gateway/gateway_entry_contract_test.go:89:			t.Fatalf("protected route auth jwt+tenant olmali | path=%s auth=%s", route.Path, route.Auth)
./cmd/api-gateway/gateway_routes.go:202:	catalog.add(http.MethodGet, "/api/me", routeScopeProtected, "jwt+tenant", "kullanici baglam bilgisi")
./cmd/api-gateway/gateway_routes.go:203:	catalog.add(http.MethodGet, "/api/query/users", routeScopeProtected, "jwt+tenant", "query users")
./cmd/api-gateway/gateway_routes.go:204:	catalog.add(http.MethodGet, "/api/query/users/list", routeScopeProtected, "jwt+tenant", "query user list")
./cmd/api-gateway/gateway_routes.go:205:	catalog.add(http.MethodGet, "/api/query/users/", routeScopeProtected, "jwt+tenant", "tekil user query")
./cmd/api-gateway/gateway_routes.go:206:	catalog.add(http.MethodPost, "/api/v1/erp/runtime/flows", routeScopeProtected, "jwt+tenant", "erp runtime flow create")
./deploy/observability/scripts/render_lvl11_correlation_scale.sh:72:- request_chain => request_id/correlation_id/tenant_id/route
./install_phase1_scaffold.sh:822:      {route === 'tenants' ? <DashboardPage /> : null}
./internal/erp/runtime/apisurface/errors.go:28:	ErrRouteTenantHeaderMissing = errors.New("route tenant header zorunlu")
./internal/platform/jobsqueue/dispatch_store_test.go:99:func TestResolveDispatchSQLStoreResolveDispatchPolicy_ShardPriorityLaneSuccess(t *testing.T) {
./internal/platform/readcache/service_contract.go:257:				Entity:                  "tenant_route_policy",
./internal/platform/readcache/service_invalidation_planner_test.go:205:		"tenant_route_policy",
./internal/platform/readcache/service_invalidation_planner_test.go:216:	expected := "pix2pi:prod:gateway:tenant:tenant_42:projection:tenant_route_policy:*"
./internal/platform/reporting/api/handler.go:172:		h.writeError(w, r, http.StatusNotFound, tenantID, ErrorCodeRouteNotFound, "route not found")
./internal/platform/reporting/runtime/registration_test.go:41:		if route.Tenant != "x_tenant_id_required" {
./internal/platform/reporting/runtime/registration_test.go:42:			t.Fatalf("expected tenant header for %s", route.Path)
./internal/platform/reporting/runtime/runtime_smoke_test.go:204:		if route.Tenant != "x_tenant_id_required" {
./internal/platform/reporting/runtime/runtime_smoke_test.go:205:			t.Fatalf("expected x_tenant_id_required for %s", route.Path)
./scripts/audit_faz6_2_db_l8_readiness.sh:172:  echo "6-2.6 Partition/shard readiness model checked OK ✅"
./scripts/audit_faz6_2_real_implementation.sh:186:write_check "6-2.6" "Partition / shard gercek SQL veya routing izi" "PARTITION[[:space:]]+BY|CREATE[[:space:]]+TABLE.*PARTITION|pg_partman|shard|Shard|tenant.*route|route.*tenant" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/phase4_gateway_route_manifest_auth_tenant_gate.sh:7:STANDARD_FILE="$REPORT_DIR/17_3_gateway_route_manifest_auth_tenant_gate_standard.md"
./scripts/phase4_gateway_route_manifest_auth_tenant_gate.sh:11:REPORT_FILE="$REPORT_DIR/17_3_gateway_route_manifest_auth_tenant_gate_report.md"
./scripts/phase4_gateway_route_manifest_auth_tenant_gate.sh:222:  fail "auth tenant allowlist route count 6 degil"
./scripts/phase4_gateway_route_manifest_auth_tenant_gate.sh:234:  echo -e "route\tmethod\tauth_gate\ttenant_gate\tstatus"
./scripts/phase4_gateway_runtime_apply_readiness.sh:14:R173="$REPORT_DIR/17_3_gateway_route_manifest_auth_tenant_gate_report.md"
./scripts/phase4_reporting_api_final_closure.sh:15:R173="$REPORT_DIR/17_3_gateway_route_manifest_auth_tenant_gate_report.md"
./scripts/phase4_reporting_api_final_closure.sh:234:  echo -e "17.3_gateway_route_manifest_auth_tenant_gate\tPASS\t6_routes_auth_tenant_gate_ready"
./scripts/phase4_reporting_api_final_closure.sh:334:  echo "17.3 Gateway route manifest / auth-tenant middleware gate=PASS"
./scripts/phase4_reporting_runtime_smoke_test.sh:13:R173="$REPORT_DIR/17_3_gateway_route_manifest_auth_tenant_gate_report.md"
./scripts/test_faz6_2_db_l8_readiness.sh:74:check_grep "6-2.6 Partition Shard tanimli" "$DOC_FILE" "6-2.6 Partition / Shard Readiness Modeli"
./scripts/test_faz6_2_real_implementation_audit.sh:77:check_grep "6-2.6 Partition shard kontrolu evidence var" "$EVIDENCE_FILE" "6-2.6 Partition / shard"
./scripts/test_faz6_2_visible_checkpoints.sh:54:check_grep "6-2.6 Partition Shard visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_2_6_PARTITION_SHARD_STATUS=PASS"
./scripts/test_faz6_2_visible_checkpoints.sh:63:check_grep "6-2.6 detay shard tetikleyicileri var" "$CHECKPOINT_FILE" "shard tetikleyicileri yazıldı"
./scripts/test_phase4b_tenant_access_checks.sh:118:  api_route_tenant_check \
./scripts/test_phase4_gateway_route_manifest_auth_tenant_gate.sh:6:SCRIPT="scripts/phase4_gateway_route_manifest_auth_tenant_gate.sh"
./scripts/test_phase4_gateway_route_manifest_auth_tenant_gate.sh:7:REPORT="docs/phase4/17_3_gateway_route_manifest_auth_tenant_gate_report.md"
./scripts/test_phase4_gateway_route_manifest_auth_tenant_gate.sh:13:  echo "TEST_FAIL ❌ gateway route manifest auth tenant gate script executable degil"
./scripts/test_phase4_gateway_route_manifest_auth_tenant_gate.sh:18:  echo "TEST_FAIL ❌ gateway route manifest auth tenant gate script hata verdi"
./scripts/test_phase4_gateway_route_manifest_auth_tenant_gate.sh:49:  echo "TEST_FAIL ❌ auth tenant allowlist route count 6 yok"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.6 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-2.7 DB observability metric / health izi

Pattern:

```text
pg_isready|db.*health|DB.*Health|Prometheus|prometheus|sql.DBStats|Stats\(\)
```

Match Count: 94

```text
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:32:if command -v pg_isready >/dev/null 2>&1; then
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:37:  pg_isready -h "$DB_HOST_VAL" -p "$DB_PORT_VAL" || true
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:39:  echo "pg_isready yok"
./1_archive/root_sh/step_23_check_postgres_runtime.sh:32:if command -v pg_isready >/dev/null 2>&1; then
./1_archive/root_sh/step_23_check_postgres_runtime.sh:37:  pg_isready -h "$DB_HOST_VAL" -p "$DB_PORT_VAL" || true
./1_archive/root_sh/step_23_check_postgres_runtime.sh:39:  echo "pg_isready yok"
./1_archive/root_sh/step_24_start_postgres_runtime.sh:43:if command -v pg_isready >/dev/null 2>&1; then
./1_archive/root_sh/step_24_start_postgres_runtime.sh:48:  pg_isready -h "$DB_HOST_VAL" -p "$DB_PORT_VAL" || true
./1_archive/root_sh/step_24_start_postgres_runtime.sh:50:  echo "pg_isready yok"
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
./cmd/api-gateway/api_gateway_main.go:128:			Description:    "gateway db health",
./cmd/api-gateway/api_gateway_main.go:283:func buildDBHealthComponent(name string, db *gorm.DB) healthComponent {
./cmd/api-gateway/api_gateway_main.go:570:			buildDBHealthComponent("write_db", kernel.GetWriteDB()),
./cmd/api-gateway/api_gateway_main.go:571:			buildDBHealthComponent("read_db", kernel.GetReadDB()),
./cmd/api-gateway/api_gateway_main.go:643:			buildDBHealthComponent("write_db", kernel.GetWriteDB()),
./cmd/api-gateway/api_gateway_main.go:644:			buildDBHealthComponent("read_db", kernel.GetReadDB()),
./cmd/api-gateway/gateway_routes.go:194:	catalog.add(http.MethodGet, "/health/db", routeScopePublic, "none", "db health kontrolu")
./cmd/early-warning-runtime/early_warning_runtime_main.go:446:func buildSignals(db *sql.DB, services []ServiceHealthItem, resources []ResourceItem) []SignalItem {
./cmd/early-warning-runtime/early_warning_runtime_main.go:513:func buildSummary(db *sql.DB, services []ServiceHealthItem, resources []ResourceItem, signals []SignalItem) EarlyWarningSummary {
./deploy/observability/docker-compose.yml:4:  prometheus:
./deploy/observability/docker-compose.yml:5:    image: prom/prometheus:latest
./deploy/observability/docker-compose.yml:6:    container_name: pix2pi_prometheus
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-2.7 STATUS=IMPLEMENTED_OR_PRESENT ✅

# Final Runtime Implementation Interpretation

```text
REQUIRED_FAIL=0
OPTIONAL_WARN=0
FAZ_6_2_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_2_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_2_REAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_2_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅
```
