# FAZ 6-6 Real Implementation Audit

Generated At: 2026-05-01T14:45:40+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit, FAZ 6-6 Backup / Restore / Disaster Recovery maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

## Scanned Files

```text
3013 /tmp/tmp.DU9XYhZ4qT/files.txt

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

## 6-6.1.1 Database backup script izi

Pattern:

```text
pg_dump|pg_basebackup|POSTGRES|DB_BACKUP|database.*backup|backup.*database|docker exec.*postgres|psql.*dump
```

Match Count: 410

```text
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:15:  grep -E '^(DB_NAME|DB_USER|DB_HOST|DB_PORT|POSTGRES_DB|POSTGRES_USER|POSTGRES_HOST|POSTGRES_PORT)=' .env || true
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:21:echo "=== 3 POSTGRES PROCESS / CONTAINER KONTROL ==="
./1_archive/root_sh/step_23_check_postgres_runtime.sh:9:  grep -E '^(DB_NAME|DB_USER|DB_HOST|DB_PORT|POSTGRES_DB|POSTGRES_USER|POSTGRES_HOST|POSTGRES_PORT)=' .env || true
./1_archive/root_sh/step_23_check_postgres_runtime.sh:27:echo "=== 5 SYSTEMD POSTGRES ==="
./1_archive/root_sh/step_24_start_postgres_runtime.sh:29:echo "=== 2 SYSTEM POSTGRES ILE DENE ==="
./1_archive/root_sh/step_25_check_postgres_password.sh:6:echo "=== POSTGRES CONTAINER ENV ==="
./1_archive/root_sh/step_25_check_postgres_password.sh:7:docker exec pix2pi_pg env | grep -E 'POSTGRES_(USER|PASSWORD|DB)' || true
./1_archive/root_sh/step_25_check_postgres_password.sh:11:grep -E '^(DB_HOST|DB_PORT|DB_USER|DB_NAME|DB_PASSWORD|POSTGRES_USER|POSTGRES_PASSWORD|POSTGRES_DB)=' .env || true
./1_archive/root_sh/step_27_check_postgres_container_user.sh:6:echo "=== CONTAINER POSTGRES ENV ==="
./1_archive/root_sh/step_27_check_postgres_container_user.sh:7:docker exec pix2pi_pg env | grep -E 'POSTGRES_(USER|PASSWORD|DB)' || true
./1_archive/root_sh/step_404_scan_db_entrypoints.sh:19:grep -RniE 'DB_|DATABASE_URL|POSTGRES|PGHOST|PGPORT|PGUSER|PGDATABASE' \
./1_archive/root_sh/step_423c_db_auth_probe.sh:85:    add_candidate "${line#POSTGRES_PASSWORD=***MASKED***
./1_archive/root_sh/step_423c_db_auth_probe.sh:86:  done < <(grep -Rho '^POSTGRES_PASSWORD=***MASKED***
./1_archive/root_sh/step_423c_db_auth_probe.sh:91:    add_candidate "${line#POSTGRES_PASSWORD=***MASKED***
./1_archive/root_sh/step_423c_db_auth_probe.sh:92:  done < <(grep -Rho '^POSTGRES_PASSWORD=***MASKED***
./1_archive/root_sh/step_423c_db_auth_probe.sh:103:      POSTGRES_PASSWORD=***MASKED***
./1_archive/root_sh/step_423c_db_auth_probe.sh:104:        add_candidate "${line#POSTGRES_PASSWORD=***MASKED***
./1_archive/root_sh/step_423d2_container_probe.sh:4:echo "=== STEP 423D-5 / CONTAINER POSTGRES PROBE ==="
./1_archive/root_sh/step_423d2_container_probe.sh:35:docker exec "$DB_CONTAINER" sh -lc 'id postgres || true'
./1_archive/root_sh/step_423d2_container_probe.sh:37:docker exec "$DB_CONTAINER" sh -lc 'getent passwd postgres || cat /etc/passwd | grep postgres || true'
./1_archive/root_sh/step_423d2_container_probe.sh:48:docker exec -u postgres "$DB_CONTAINER" psql -d postgres -Atqc "select current_user;" >/tmp/step_423d2_psql.out 2>/tmp/step_423d2_psql.err
./1_archive/root_sh/step_423d2_container_probe.sh:61:docker exec "$DB_CONTAINER" sh -lc 'psql -U postgres -d postgres -Atqc "select current_user;"' >/tmp/step_423d2_default_psql.out 2>/tmp/step_423d2_default_psql.err
./1_archive/root_sh/step_423d2_container_probe.sh:73:docker inspect "$DB_CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -E 'POSTGRES_|PGDATA|POSTGRES_DB' || true
./1_archive/root_sh/step_423d_reset_db_password.sh:76:  docker exec -u postgres "$DB_CONTAINER" \
./1_archive/root_sh/step_423d_reset_db_password.sh:79:  docker exec -u postgres "$DB_CONTAINER" \
./1_archive/root_sh/step_44c_audit_pg_topology.sh:8:  sed -E 's/(password=***MASKED*** ]+/\1***/g; s/(POSTGRES_PASSWORD=***MASKED***
./1_archive/root_sh/step_44c_audit_pg_topology.sh:30:  echo "===== 4) POSTGRES CONTAINER ADAYLARI ====="
./1_archive/root_sh/step_44c_replica_fix.sh:35:docker exec "$PRIMARY_CONTAINER" bash -lc "grep -n 'host replication $REPL_USER' /var/lib/postgresql/data/pg_hba.conf || true"
./1_archive/root_sh/step_44c_replica_fix.sh:45:docker exec "$PRIMARY_CONTAINER" bash -lc "PGPASSWORD=***MASKED***
./1_archive/root_sh/step_44c_replica_fix.sh:62:echo "7. pg_basebackup one-shot container ile aliniyor..."
./1_archive/root_sh/step_44c_replica_fix.sh:68:  bash -lc "pg_basebackup -h $PRIMARY_HOST -U $REPL_USER -D /var/lib/postgresql/data -P -R"
./1_archive/root_sh/step_44c_replica_fix.sh:69:echo "OK ✅ pg_basebackup tamam"
./deploy/dev/docker-compose.pg.yml:7:      POSTGRES_DB: pix2pi
./deploy/dev/docker-compose.pg.yml:8:      POSTGRES_USER: pix2pi
./deploy/dev/docker-compose.pg.yml:9:      POSTGRES_PASSWORD: pix2pi
./deploy/docker-compose.yml:8:      POSTGRES_USER: tellioglu
./deploy/docker-compose.yml:9:      POSTGRES_PASSWORD: password123
./deploy/docker-compose.yml:10:      POSTGRES_DB: pix2pi_saas
./internal/platform/eventstore/service/event_store_postgres_service.go:80:	host := envFirst("EVENT_STORE_PG_HOST", "DB_HOST", "POSTGRES_HOST")
./internal/platform/eventstore/service/event_store_postgres_service.go:85:	port := envFirst("EVENT_STORE_PG_PORT", "DB_PORT", "POSTGRES_PORT")
./internal/platform/eventstore/service/event_store_postgres_service.go:90:	user := envFirst("EVENT_STORE_PG_USER", "DB_USER", "POSTGRES_USER")
./internal/platform/eventstore/service/event_store_postgres_service.go:95:	password := envFirst("EVENT_STORE_PG_PASSWORD", "DB_PASSWORD", "POSTGRES_PASSWORD")
./internal/platform/eventstore/service/event_store_postgres_service.go:100:	dbname := envFirst("EVENT_STORE_PG_DBNAME", "DB_NAME", "POSTGRES_DB")
./scripts/audit_faz6_2_real_implementation.sh:184:write_check "6-2.5" "PITR / backup / restore script izi" "archive_mode|archive_command|wal_level|pg_basebackup|pg_dump|pg_restore|restic|restore" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_3_real_implementation.sh:162:write_check "6-3.2" "Stateful / stateless ayrimi kod/config izi" "DB_|DATABASE|POSTGRES|REDIS|NATS|JETSTREAM|JWT|SESSION|tenant|Tenant|stateless|stateful" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_6_backup_restore_runtime.sh:74:write_cmd_block "6-6.4 Backup / Restore Scripts Inventory" bash -lc "find . /opt/pix2pi /etc/pix2pi -maxdepth 6 -type f 2>/dev/null | grep -Ei 'backup|restore|restic|retention|snapshot|pg_dump|pg_restore|disaster|dr|pitr|wal' | sort | head -n 200 || true"
./scripts/audit_faz6_6_backup_restore_runtime.sh:78:grep -RInE 'backup|restore|restic|retention|pg_dump|snapshot|pix2pi' /etc/cron.d 2>/dev/null || true
./scripts/audit_faz6_6_backup_restore_runtime.sh:80:crontab -l 2>/dev/null | grep -Ei 'backup|restore|restic|retention|pg_dump|snapshot|pix2pi' || true
./scripts/audit_faz6_6_backup_restore_runtime.sh:94:    grep -Ei 'backup|restore|restic|retention|snapshot|pg_dump|pg_restore|error|fail|ok' \"\$f\" 2>/dev/null | tail -n 80 || true
./scripts/audit_faz6_6_backup_restore_runtime.sh:129:    docker exec \"\$c\" sh -lc \"pg_isready; psql -U postgres -d postgres -Atc \\\"show wal_level; show archive_mode; show archive_command;\\\"\" 2>/dev/null || true
./scripts/audit_faz6_6_backup_restore_runtime.sh:141:    grep -E 'RESTIC|BACKUP|RESTORE|RETENTION|PG|POSTGRES|DB_|WAL|PITR' \"\$f\" | head -n 120
./scripts/audit_faz6_6_real_implementation.sh:162:write_check "6-6.1.1" "Database backup script izi" "pg_dump|pg_basebackup|POSTGRES|DB_BACKUP|database.*backup|backup.*database|docker exec.*postgres|psql.*dump" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_6_real_implementation.sh:184:write_check "6-6.6" "PITR / WAL readiness izi" "archive_mode|archive_command|wal_level|WAL|PITR|pg_wal|recovery_target_time|restore_command|basebackup|pg_basebackup" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/event_platform_final_suite.sh:128:run_step "POSTGRES PERSIST TEST" \
./scripts/phase4_db_backup_pitr_readiness.sh:133:if tool_status "pg_dump"; then PG_DUMP_FOUND=1; fi
./scripts/phase4_db_backup_pitr_readiness.sh:142:  warn "pg_dump bulunamadi; logical backup readiness eksik"
./scripts/phase4_db_backup_pitr_readiness.sh:210:  detail "POSTGRES_WAL_LEVEL=$WAL_LEVEL"
./scripts/phase4_db_backup_pitr_readiness.sh:211:  detail "POSTGRES_ARCHIVE_MODE=$ARCHIVE_MODE"
./scripts/phase4_db_backup_pitr_readiness.sh:212:  detail "POSTGRES_ARCHIVE_COMMAND_STATUS=$(if [ "$ARCHIVE_COMMAND" = "(disabled)" ] || [ -z "$ARCHIVE_COMMAND" ]; then echo DISABLED; else echo CONFIGURED; fi)"
./scripts/phase4_db_backup_pitr_readiness.sh:213:  detail "POSTGRES_MAX_WAL_SENDERS=$MAX_WAL_SENDERS"
./scripts/phase4_db_backup_pitr_readiness.sh:214:  detail "POSTGRES_WAL_KEEP_SIZE=$WAL_KEEP_SIZE"
./scripts/phase4_db_backup_pitr_readiness.sh:215:  detail "POSTGRES_DATA_DIRECTORY=$DATA_DIRECTORY"
./scripts/phase4_db_backup_pitr_readiness.sh:251:path_status "POSTGRES_DATA_DIRECTORY" "$DATA_DIRECTORY"
./scripts/phase4_db_backup_pitr_readiness.sh:287:    echo "DB_BACKUP_PITR_READINESS_ASSESSMENT=PASS"
./scripts/phase4_db_backup_pitr_readiness.sh:289:    echo "DB_BACKUP_PITR_READINESS_ASSESSMENT=FAIL"
./scripts/phase4_db_backup_pitr_readiness.sh:330:  echo "DB_BACKUP_PITR_READINESS_ASSESSMENT=FAIL ❌"
./scripts/phase4_db_backup_pitr_readiness.sh:334:echo "DB_BACKUP_PITR_READINESS_ASSESSMENT=PASS ✅"
./scripts/phase4_db_connection_evidence.sh:147:  POSTGRES_DSN
./scripts/phase4_db_connection_evidence.sh:148:  POSTGRES_URL
./scripts/phase4_db_env_discovery.sh:97:  POSTGRES_DSN
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.1.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.1.2 File / config backup izi

Pattern:

```text
tar |tar -|rsync|cp -a|backup.*etc|backup.*nginx|backup.*systemd|backup.*env|/etc/pix2pi|/opt/pix2pi|backups/
```

Match Count: 1306

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
./1_archive/root_sh/step_130_backup_nginx_before_rate_limit.sh:6:cp /etc/nginx/nginx.conf ~/pix2pi/nginx-backups/nginx.conf.before_rate_limit.bak
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh:6:cp -a /etc/fail2ban /root/pix2pi/fail2ban-backups/fail2ban_before_nginx_jail_$(date +%Y%m%d_%H%M%S)
./1_archive/root_sh/step_13_backup_redis_tenant_namespace.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_13_backup_redis_tenant_namespace.sh:9:  backups/app/manual/playground_main.go.redis_tenant_namespace.bak 2>/dev/null || true
./1_archive/root_sh/step_16_backup_super_admin_policy.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_16_backup_super_admin_policy.sh:9:  backups/app/manual/playground_main.go.super_admin_policy.bak 2>/dev/null || true
./1_archive/root_sh/step_184_backup_panel_before_service_monitor.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/panel
./1_archive/root_sh/step_184_backup_panel_before_service_monitor.sh:6:cp /opt/pix2pi/nginx/panel_index.html \
./1_archive/root_sh/step_184_backup_panel_before_service_monitor.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/panel/panel_index.html.before_service_monitor.bak
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:8:DOSYA="/opt/pix2pi/nginx/service_status.json"
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:4:cat <<'HTML' > /opt/pix2pi/nginx/panel_index.html
./1_archive/root_sh/step_194_panel_html_reporting_service_ekle.sh:4:panel_dosya="/opt/pix2pi/nginx/panel_index.html"
./1_archive/root_sh/step_194_panel_html_reporting_service_ekle.sh:30:dosya = Path("/opt/pix2pi/nginx/panel_index.html")
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:8:PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:9:NGINX_KOK="/opt/pix2pi/nginx"
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:72:kok = Path("/opt/pix2pi/nginx")
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:8:PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:31:find /opt/pix2pi/nginx -maxdepth 3 -type f \( -name "*.html" -o -name "*.js" -o -name "*.json" \) | sort
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:35:grep -RIn "reporting_service\|UNKNOWN\|accounting_service" /opt/pix2pi/nginx /usr/local/bin 2>/dev/null || true
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:108:        for anahtar in ["api_gateway", "identity", "auth", "stock_service", "accounting_service", "nats", "redis", "nginx", "reporting_service"]:
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:109:            if anahtar in data:
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:163:grep -RIn "reporting_service" /opt/pix2pi/nginx 2>/dev/null || true
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:8:json_dosya="/opt/pix2pi/nginx/service_status.json"
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:99:sabit_json_dosya="/opt/pix2pi/nginx/service_status.json"
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:4:panel_dosya="/opt/pix2pi/nginx/panel_index.html"
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:28:cat <<'HTML' > /opt/pix2pi/nginx/panel_index.html
./1_archive/root_sh/step_19_backup_postgres_rls.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_19_backup_postgres_rls.sh:9:  backups/app/manual/rls_tenant_policy.sql.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_account_mapping.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_account_mapping.sh:9:  backups/app/manual/erp_account_mapping_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_account_mapping.sh:12:  backups/app/manual/erp_ufk_main.go.mapping.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_accounts_import.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_accounts_import.sh:9:  backups/app/manual/erp_chart_of_accounts_import_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_accounts_import.sh:12:  backups/app/manual/erp_ufk_main.go.import.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_accounts_seed.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_accounts_seed.sh:9:  backups/app/manual/erp_account.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_accounts_seed.sh:12:  backups/app/manual/erp_ufk_main.go.accounts.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_accounts_seed.sh:15:  backups/app/manual/erp_chart_of_accounts_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_alis_faturasi_engine.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_alis_faturasi_engine.sh:9:  backups/app/manual/erp_alis_fatura.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_alis_faturasi_engine.sh:12:  backups/app/manual/erp_alis_fatura_satir.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_alis_faturasi_engine.sh:15:  backups/app/manual/erp_alis_fatura_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_alis_faturasi_engine.sh:18:  backups/app/manual/erp_ufk_main.go.alis_faturasi.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_auto_rules.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_auto_rules.sh:9:  backups/app/manual/erp_accounting_rule.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_auto_rules.sh:12:  backups/app/manual/erp_accounting_rule_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_auto_rules.sh:15:  backups/app/manual/erp_ufk_main.go.auto_rules.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_balance_sheet.sh:6:mkdir -p backups/app/manual
./1_archive/root_sh/step_1_backup_balance_sheet.sh:9:  backups/app/manual/erp_balance_sheet_service.go.bak 2>/dev/null || true
./1_archive/root_sh/step_1_backup_balance_sheet.sh:12:  backups/app/manual/erp_ufk_main.go.balance_sheet.bak 2>/dev/null || true
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.1.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.1.3 Restic / backup repository izi

Pattern:

```text
restic|RESTIC|snapshot|snapshots|RESTIC_REPOSITORY|pix2pi-restic-repo|backup repo|repository
```

Match Count: 1380

```text
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:4:cat <<'BASH' > /usr/local/bin/pix2pi_service_snapshot.sh
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:93:chmod +x /usr/local/bin/pix2pi_service_snapshot.sh
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:95:/usr/local/bin/pix2pi_service_snapshot.sh
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:97:echo "OK ✅ service snapshot script hazir"
./1_archive/root_sh/step_187_create_service_status_cron.sh:5:* * * * * root /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_187_create_service_status_cron.sh:6:* * * * * root sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_187_create_service_status_cron.sh:7:* * * * * root sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_187_create_service_status_cron.sh:8:* * * * * root sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_187_create_service_status_cron.sh:9:* * * * * root sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_187_create_service_status_cron.sh:10:* * * * * root sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_188_verify_done_items.sh:142:if [ -f "/usr/local/bin/pix2pi_service_snapshot.sh" ]; then
./1_archive/root_sh/step_188_verify_done_items.sh:143:  yaz "OK ✅ service snapshot scripti var"
./1_archive/root_sh/step_188_verify_done_items.sh:145:  yaz "UYARI ⚠ service snapshot scripti yok"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:18:snapshot_script="/usr/local/bin/pix2pi_service_snapshot.sh"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:19:snapshot_yedek="$yedek_klasor/pix2pi_service_snapshot.sh.$zaman.bak"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:35:if [ -f "$snapshot_script" ]; then
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:36:  cp "$snapshot_script" "$snapshot_yedek"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:37:  echo "OK ✅ pix2pi_service_snapshot.sh yedegi alindi"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:39:  echo "OK ✅ snapshot script bulunamadi, patch adimi kontrollu gececek"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:216:if [ -f "$snapshot_script" ]; then
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:217:  if grep -q "REPORTING_SERVICE_PATCH_V1" "$snapshot_script"; then
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:218:    echo "OK ✅ snapshot script daha once patch edilmis"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:220:    cat <<'PATCHEOF' >> "$snapshot_script"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:234:en_yeni_json="$(ls -1t /tmp/pix2pi*service*.json /tmp/*snapshot*.json 2>/dev/null | head -n 1 || true)"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:260:    echo "OK ✅ snapshot script patch edildi"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:265:  "$snapshot_script" || true
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:266:  echo "OK ✅ snapshot tetiklendi"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:268:  echo "UYARI ⚠ snapshot script bulunamadi, panel entegrasyonu bu adimda atlandi"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:281:echo "OK ✅ panel snapshot entegrasyonu denendi"
./1_archive/root_sh/step_192_reporting_service_panelde_goster.sh:7:SNAPSHOT_SCRIPT="/usr/local/bin/pix2pi_service_snapshot.sh"
./1_archive/root_sh/step_192_reporting_service_panelde_goster.sh:139:  echo "OK ✅ snapshot script calisti"
./1_archive/root_sh/step_192_reporting_service_panelde_goster.sh:141:  echo "UYARI ⚠ snapshot script bulunamadi"
./1_archive/root_sh/step_192_reporting_service_panelde_goster.sh:146:EN_YENI_JSON="$(ls -1t /tmp/pix2pi*service*.json /tmp/*snapshot*.json 2>/dev/null | head -n 1 || true)"
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:42:EN_YENI_JSON="$(ls -1t /tmp/pix2pi*service*.json /tmp/*snapshot*.json 2>/dev/null | head -n 1 || true)"
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:9:SNAPSHOT_SCRIPT="/usr/local/bin/pix2pi_service_snapshot.sh"
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:15:[ -f "$SNAPSHOT_SCRIPT" ] || { echo "HATA ❌ snapshot script yok: $SNAPSHOT_SCRIPT"; exit 1; }
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:17:echo "OK ✅ snapshot script bulundu"
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:22:cp "$SNAPSHOT_SCRIPT" "$YEDEK_DIZINI/pix2pi_service_snapshot.sh.$ZAMAN.bak"
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:39:EN_YENI_JSON="$(ls -1t /tmp/pix2pi*service*.json /tmp/*snapshot*.json 2>/dev/null | head -n 1 || true)"
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:76:echo "8) reporting_service status mapping snapshot scriptine ekleniyor..."
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:90:en_yeni_json_fix="$(ls -1t /tmp/pix2pi*service*.json /tmp/*snapshot*.json 2>/dev/null | head -n 1 || true)"
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:130:  echo "OK ✅ snapshot script patch edildi"
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:137:echo "OK ✅ snapshot tetiklendi"
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:168:echo "OK ✅ snapshot patch edildi"
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:9:snapshot_script="/usr/local/bin/pix2pi_service_snapshot.sh"
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:20:if [ ! -f "$snapshot_script" ]; then
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:21:  echo "HATA ❌ snapshot script yok: $snapshot_script"
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:35:cp "$snapshot_script" "$yedek_dizini/pix2pi_service_snapshot.sh.$zaman.bak"
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:93:if grep -q "REPORTING_JSON_FIX_V3" "$snapshot_script"; then
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:96:  cat <<'PATCHEOF' >> "$snapshot_script"
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:144:  echo "OK ✅ snapshot script patch edildi"
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:149:"$snapshot_script" || true
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:150:echo "OK ✅ snapshot tetiklendi"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:10:snapshot_script="/usr/local/bin/pix2pi_service_snapshot.sh"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:19:for f in "$panel_dosya" "$json_dosya" "$snapshot_script" "$service_discovery_status" "$query_read_model_status"; do
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:31:cp "$snapshot_script" "$yedek_klasor/pix2pi_service_snapshot.sh.$zaman.bak"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:170:if grep -q "QUERY_READ_AND_DISCOVERY_PATCH_V1" "$snapshot_script"; then
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:171:  echo "OK ✅ snapshot patch zaten var"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:173:  cat <<'PATCHEOF' >> "$snapshot_script"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:249:  echo "OK ✅ snapshot patch eklendi"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:321:"$snapshot_script" || true
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:322:echo "OK ✅ snapshot tetiklendi"
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:6:snapshot_script="/usr/local/bin/pix2pi_service_snapshot.sh"
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:16:if [ -f "$snapshot_script" ]; then
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:17:  cp "$snapshot_script" "$yedek_klasor/pix2pi_service_snapshot.sh.$zaman.bak"
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:18:  echo "OK ✅ snapshot yedegi alindi"
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:20:  echo "UYARI ⚠ snapshot script yok, yeni yazilacak"
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:25:cat <<'SCRIPTEOF' > "$snapshot_script"
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:112:chmod +x "$snapshot_script"
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:113:echo "OK ✅ snapshot script yazildi"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.1.3 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.2.1 Restore script / prosedur izi

Pattern:

```text
restore|Restore|pg_restore|restic.*restore|RESTORE|recovery|recover|rollback.*backup
```

Match Count: 614

```text
./1_archive/root_sh/step_355d_restore_clean.sh:8:echo "=== STEP 355D / RESTORE CLEAN ==="
./1_archive/root_sh/step_355d_restore_clean.sh:11:echo "1. restore..."
./1_archive/root_sh/step_355d_restore_clean.sh:13:echo "OK ✅ restore edildi"
./1_archive/root_sh/step_367_restore_clean_panel_engine.sh:4:echo "=== STEP 367 / RESTORE CLEAN PANEL ENGINE ==="
./1_archive/root_sh/step_367_restore_clean_panel_engine.sh:10:cp "$PANEL_HTML" "${PANEL_HTML}.bak_restore_$(date +%s)"
./1_archive/root_sh/step_418_fix_gateway_panic.sh:10:# handler içine recover ekle
./1_archive/root_sh/step_418_fix_gateway_panic.sh:14:			if rec := recover(); rec != nil {\
./1_archive/root_sh/step_420_rewrite_gateway.sh:30:			if rec := recover(); rec != nil {
./1_archive/root_sh/step_422_rewrite_gateway_with_db_init.sh:30:			if rec := recover(); rec != nil {
./1_archive/root_sh/step_44c_replica_fix.sh:86:echo "10. replica recovery durumu..."
./1_archive/root_sh/step_44c_replica_fix.sh:87:docker exec "$REPLICA_CONTAINER" psql -U "$PRIMARY_DB_USER" -d "$PRIMARY_DB_NAME" -Atqc "select pg_is_in_recovery();"
./1_archive/root_sh/step_44c_replica_fix.sh:88:echo "OK ✅ recovery kontrol bitti"
./.backups/step_422_20260323_080757/cmd/api-gateway/api_gateway_main.go:20:			if rec := recover(); rec != nil {
./cmd/api-gateway/api_gateway_main.go:333:	if err := readDB.Raw("select pg_is_in_recovery()").Scan(&inRecovery).Error; err != nil {
./cmd/api-gateway/api_gateway_main.go:968:		recoverMiddleware,
./cmd/api-gateway/gateway_config_security_test.go:21:		if r := recover(); r == nil {
./cmd/api-gateway/gateway_middleware.go:201:func recoverMiddleware(next http.Handler) http.Handler {
./cmd/api-gateway/gateway_middleware.go:204:			if rec := recover(); rec != nil {
./cmd/api-gateway/gateway_middleware.go:209:					"panic_recovered",
./cmd/api-gateway/gateway_middleware.go:212:						"middleware": "recover",
./configs/faz5/subscription_billing_policy_v1.json:80:      "entitlement_effect": "restore_package_rights"
./db/migrations/001_phase1_foundation.up.sql:25:CREATE TYPE auth.break_glass_reason AS ENUM ('incident_response', 'security_investigation', 'data_recovery', 'support_exception');
./db/migrations/20260425_099001_erp_tax.up.sql:23:    is_recoverable BOOLEAN NOT NULL DEFAULT false,
./db/migrations/20260425_099001_erp_tax.up.sql:171:    recoverable_amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
./db/migrations/20260425_099001_erp_tax.up.sql:201:        CHECK (direction IN ('payable', 'recoverable', 'neutral')),
./db/migrations/20260425_099001_erp_tax.up.sql:211:            AND recoverable_amount >= 0
./install_phase1_scaffold.sh:49:CREATE TYPE auth.break_glass_reason AS ENUM ('incident_response', 'security_investigation', 'data_recovery', 'support_exception');
./internal/erp/persistence/tax/model.go:54:	TaxDirectionRecoverable TaxDirection = "recoverable"
./internal/erp/persistence/tax/postgres_tax_code_repository.go:41:    is_recoverable,
./internal/erp/persistence/tax/postgres_tax_code_repository.go:72:    is_recoverable,
./internal/erp/persistence/tax/postgres_tax_code_repository.go:129:    is_recoverable,
./internal/erp/persistence/tax/postgres_tax_code_repository.go:181:    is_recoverable,
./internal/erp/persistence/tax/postgres_tax_code_repository.go:239:    is_recoverable,
./internal/erp/persistence/tax/postgres_tax_code_repository.go:252:  AND ($3::boolean IS NULL OR is_recoverable = $3)
./internal/erp/persistence/tax/postgres_tax_rate_repository_integration_test.go:178:    is_recoverable,
./internal/erp/persistence/tax/postgres_tax_transaction_repository.go:74:    recoverable_amount,
./internal/erp/persistence/tax/postgres_tax_transaction_repository.go:145:    recoverable_amount::float8,
./internal/erp/persistence/tax/postgres_tax_transaction_repository.go:243:    recoverable_amount::float8,
./internal/erp/persistence/tax/postgres_tax_transaction_repository.go:321:    recoverable_amount::float8,
./internal/erp/persistence/tax/postgres_tax_transaction_repository_integration_test.go:183:    is_recoverable,
./internal/erp/persistence/tax/tax_db_integration_test.go:181:    recoverable_amount,
./internal/erp/persistence/tax/tax_db_integration_test.go:330:    recoverable_amount,
./internal/erp/persistence/tax/tax_db_integration_test.go:398:    is_recoverable,
./internal/erp/persistence/tax/tax_db_integration_test.go:431:    is_recoverable,
./internal/erp/persistence/tax/tax_schema_test.go:93:		"is_recoverable BOOLEAN NOT NULL DEFAULT false",
./internal/erp/persistence/tax/tax_schema_test.go:140:		"recoverable_amount NUMERIC(18, 2) NOT NULL DEFAULT 0",
./internal/erp/persistence/tax/tax_schema_test.go:159:		"direction IN ('payable', 'recoverable', 'neutral')",
./internal/erp/runtime/taxcalc/postgres_store.go:381:		return "recoverable"
./internal/platform/backup/service/backup_service.go:75:func (s *BackupService) RestoreHazirla(
./internal/platform/jobsqueue/recovery_service.go:46:		return RecoverJobResponse{}, errors.New("recover job usecase hazir degil")
./internal/platform/jobsqueue/recovery_service_test.go:10:type recoverJobStoreMock struct {
./internal/platform/jobsqueue/recovery_service_test.go:17:func (m *recoverJobStoreMock) RecoverJob(_ context.Context, cmd RecoverJobCommand) (RecoverJobResult, error) {
./internal/platform/jobsqueue/recovery_service_test.go:75:	store := &recoverJobStoreMock{
./internal/platform/jobsqueue/recovery_service_test.go:124:	store := &recoverJobStoreMock{
./internal/platform/jobsqueue/recovery_service_test.go:152:	store := &recoverJobStoreMock{}
./internal/platform/jobsqueue/recovery_service_test.go:170:	store := &recoverJobStoreMock{
./internal/platform/jobsqueue/recovery_service_test.go:171:		err: errors.New("recover failed"),
./internal/platform/jobsqueue/recovery_store.go:21:		return RecoverJobResult{}, errors.New("recover sql store hazir degil")
./internal/platform/jobsqueue/recovery_store_test.go:10:type recoveryRowMock struct {
./internal/platform/jobsqueue/recovery_store_test.go:15:func (r *recoveryRowMock) Scan(dest ...any) error {
./internal/platform/jobsqueue/recovery_store_test.go:36:type recoveryQueryRowProviderMock struct {
./internal/platform/jobsqueue/recovery_store_test.go:42:func (m *recoveryQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
./internal/platform/jobsqueue/recovery_store_test.go:49:	db := &recoveryQueryRowProviderMock{
./internal/platform/jobsqueue/recovery_store_test.go:50:		row: &recoveryRowMock{
./internal/platform/jobsqueue/recovery_store_test.go:103:	db := &recoveryQueryRowProviderMock{
./internal/platform/jobsqueue/recovery_store_test.go:104:		row: &recoveryRowMock{
./internal/platform/jobsqueue/recovery_store_test.go:130:	db := &recoveryQueryRowProviderMock{
./internal/platform/jobsqueue/recovery_store_test.go:131:		row: &recoveryRowMock{
./internal/platform/jobsqueue/recovery_store_test.go:165:	db := &recoveryQueryRowProviderMock{
./internal/platform/jobsqueue/recovery_store_test.go:166:		row: &recoveryRowMock{
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.2.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.2.2 Restore smoke test izi

Pattern:

```text
smoke|Smoke|health.*check|/health|curl.*health|post.*restore|restore.*test|test.*restore|pg_isready
```

Match Count: 831

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
./1_archive/root_sh/step_188_verify_done_items.sh:112:    *test*.sh|check_*files.sh|check_*runtime.sh|check_*env.sh|check_*login.sh|check_*health.sh|check_*source.sh|check_*names.sh|check_*ports.sh)
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
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:32:if command -v pg_isready >/dev/null 2>&1; then
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:37:  pg_isready -h "$DB_HOST_VAL" -p "$DB_PORT_VAL" || true
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:39:  echo "pg_isready yok"
./1_archive/root_sh/step_23_check_postgres_runtime.sh:32:if command -v pg_isready >/dev/null 2>&1; then
./1_archive/root_sh/step_23_check_postgres_runtime.sh:37:  pg_isready -h "$DB_HOST_VAL" -p "$DB_PORT_VAL" || true
./1_archive/root_sh/step_23_check_postgres_runtime.sh:39:  echo "pg_isready yok"
./1_archive/root_sh/step_24_start_postgres_runtime.sh:43:if command -v pg_isready >/dev/null 2>&1; then
./1_archive/root_sh/step_24_start_postgres_runtime.sh:48:  pg_isready -h "$DB_HOST_VAL" -p "$DB_PORT_VAL" || true
./1_archive/root_sh/step_24_start_postgres_runtime.sh:50:  echo "pg_isready yok"
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
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.2.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.2.3 Restore safety / guard izi

Pattern:

```text
DRY_RUN|dry-run|dry run|CONFIRM|confirm|guard|safety|PRODUCTION|staging|restore.*target|target.*restore
```

Match Count: 839

```text
./1_archive/root_sh/step_365_hard_fix_panel_render_engine.sh:24:    // JSON safety parse
./1_archive/root_sh/step_392_production_hardening.sh:4:echo "=== STEP 392 / PRODUCTION HARDENING ==="
./1_archive/root_sh/step_392_production_hardening.sh:17:# === PRODUCTION HARDENING ===
./1_archive/root_sh/step_78_test_production_server_ready.sh:16:echo "=== PRODUCTION DIRS ==="
./cmd/erp/core/ufk/scripts/pilot/run_4c_6d_uat_execution_evidence.sh:24:STAGING_TABLE="tenant_uzmanparcaci.pilot_product_import_staging"
./cmd/erp/core/ufk/scripts/pilot/run_4c_6d_uat_execution_evidence.sh:197:  and table_name='pilot_product_import_staging'
./cmd/erp/core/ufk/scripts/pilot/run_4c_6d_uat_execution_evidence.sh:456:| UAT-11 | $UAT_11_STATUS | MARKETPLACE_PHASE=FAZ_4D | Pazaryeri scope guard |
./cmd/event-concurrency-test/event_concurrency_test_main.go:29:	fmt.Println("STEP concurrency — thread safety testi basliyor")
./cmd/event-concurrency-test/event_concurrency_test_main.go:143:	fmt.Println("OK ✅ STEP concurrency thread safety testi bitti")
./configs/faz5/entitlement_matrix_v1.json:7:  "tenant_safety": "tenant_aware_required",
./db/migrations/20260425_094001_erp_sales_documents.up.sql:179:        CHECK (status IN ('draft', 'confirmed', 'partially_delivered', 'delivered', 'partially_invoiced', 'invoiced', 'cancelled', 'closed')),
./db/migrations/20260425_095001_erp_procurement_documents.up.sql:44:        CHECK (status IN ('draft', 'confirmed', 'partially_received', 'received', 'partially_invoiced', 'invoiced', 'cancelled', 'closed')),
./db/migrations/20260426_0911001_erp_fiscal_sequence.up.sql:194:    confirmed_at TIMESTAMPTZ,
./db/migrations/20260426_0911001_erp_fiscal_sequence.up.sql:195:    confirmed_by TEXT,
./db/migrations/20260426_0911001_erp_fiscal_sequence.up.sql:214:        CHECK (allocation_status IN ('allocated', 'confirmed', 'cancelled'))
./db/migrations/20260428_143001_import_staging_tables.down.sql:3:DROP TABLE IF EXISTS import_pipeline.import_price_lists_staging;
./db/migrations/20260428_143001_import_staging_tables.down.sql:4:DROP TABLE IF EXISTS import_pipeline.import_opening_stocks_staging;
./db/migrations/20260428_143001_import_staging_tables.down.sql:5:DROP TABLE IF EXISTS import_pipeline.import_products_staging;
./db/migrations/20260428_143001_import_staging_tables.down.sql:6:DROP TABLE IF EXISTS import_pipeline.import_vendors_staging;
./db/migrations/20260428_143001_import_staging_tables.down.sql:7:DROP TABLE IF EXISTS import_pipeline.import_customers_staging;
./db/migrations/20260428_143001_import_staging_tables.up.sql:50:CREATE TABLE IF NOT EXISTS import_pipeline.import_customers_staging (
./db/migrations/20260428_143001_import_staging_tables.up.sql:51:    staging_customer_id text PRIMARY KEY,
./db/migrations/20260428_143001_import_staging_tables.up.sql:75:CREATE TABLE IF NOT EXISTS import_pipeline.import_vendors_staging (
./db/migrations/20260428_143001_import_staging_tables.up.sql:76:    staging_vendor_id text PRIMARY KEY,
./db/migrations/20260428_143001_import_staging_tables.up.sql:100:CREATE TABLE IF NOT EXISTS import_pipeline.import_products_staging (
./db/migrations/20260428_143001_import_staging_tables.up.sql:101:    staging_product_id text PRIMARY KEY,
./db/migrations/20260428_143001_import_staging_tables.up.sql:126:CREATE TABLE IF NOT EXISTS import_pipeline.import_opening_stocks_staging (
./db/migrations/20260428_143001_import_staging_tables.up.sql:127:    staging_opening_stock_id text PRIMARY KEY,
./db/migrations/20260428_143001_import_staging_tables.up.sql:149:CREATE TABLE IF NOT EXISTS import_pipeline.import_price_lists_staging (
./db/migrations/20260428_143001_import_staging_tables.up.sql:150:    staging_price_list_id text PRIMARY KEY,
./db/migrations/20260428_143001_import_staging_tables.up.sql:176:    staging_table text NOT NULL,
./db/migrations/20260428_143001_import_staging_tables.up.sql:177:    staging_row_id text NOT NULL,
./db/migrations/20260428_143001_import_staging_tables.up.sql:194:    staging_table text NOT NULL,
./db/migrations/20260428_143001_import_staging_tables.up.sql:195:    staging_row_id text NOT NULL,
./db/migrations/20260428_143001_import_staging_tables.up.sql:215:    ON import_pipeline.import_customers_staging (tenant_id, import_batch_id);
./db/migrations/20260428_143001_import_staging_tables.up.sql:218:    ON import_pipeline.import_customers_staging (tenant_id, customer_code);
./db/migrations/20260428_143001_import_staging_tables.up.sql:221:    ON import_pipeline.import_vendors_staging (tenant_id, import_batch_id);
./db/migrations/20260428_143001_import_staging_tables.up.sql:224:    ON import_pipeline.import_vendors_staging (tenant_id, vendor_code);
./db/migrations/20260428_143001_import_staging_tables.up.sql:227:    ON import_pipeline.import_products_staging (tenant_id, import_batch_id);
./db/migrations/20260428_143001_import_staging_tables.up.sql:230:    ON import_pipeline.import_products_staging (tenant_id, product_code);
./db/migrations/20260428_143001_import_staging_tables.up.sql:233:    ON import_pipeline.import_opening_stocks_staging (tenant_id, import_batch_id);
./db/migrations/20260428_143001_import_staging_tables.up.sql:236:    ON import_pipeline.import_opening_stocks_staging (tenant_id, product_code, location_code);
./db/migrations/20260428_143001_import_staging_tables.up.sql:239:    ON import_pipeline.import_price_lists_staging (tenant_id, import_batch_id);
./db/migrations/20260428_143001_import_staging_tables.up.sql:244:CREATE INDEX IF NOT EXISTS idx_import_validation_errors_staging_row
./db/migrations/20260428_143001_import_staging_tables.up.sql:245:    ON import_pipeline.import_validation_errors (tenant_id, staging_table, staging_row_id);
./db/migrations/20260428_143001_import_staging_tables.up.sql:250:CREATE INDEX IF NOT EXISTS idx_import_row_status_events_staging_row
./db/migrations/20260428_143001_import_staging_tables.up.sql:251:    ON import_pipeline.import_row_status_events (tenant_id, staging_table, staging_row_id);
./db/migrations/20260429_213001_security_audit_event_model.up.sql:118:    decision_source text NOT NULL DEFAULT 'permission_guard',
./deploy/observability/scripts/lvl11_delivery_validation_smoke.sh:40:echo "OK ✅ dry-run validation render edildi"
./deploy/observability/scripts/render_lvl11_delivery_validation.sh:44:  DRY_RUN_MODE
./deploy/observability/scripts/render_lvl11_delivery_validation.sh:81:  -e "s|__DRY_RUN_MODE__|${DRY_RUN_MODE}|g" \
./deploy/observability/scripts/render_lvl11_delivery_validation.sh:111:- Dry run mode: ${DRY_RUN_MODE}
./deploy/quality/scripts/render_lvl14_performance_release.sh:50:  FINAL_PRODUCTION_READINESS_MODE
./deploy/quality/scripts/render_lvl14_performance_release.sh:73:  -e "s|__FINAL_PRODUCTION_READINESS_MODE__|${FINAL_PRODUCTION_READINESS_MODE}|g" \
./deploy/quality/scripts/render_lvl14_performance_release.sh:96:- Final production readiness mode: ${FINAL_PRODUCTION_READINESS_MODE}
./guard/import_guard.sh:19:echo "OK ✅ import guard geçti (kernel -> services yok)"
./guard/pix2pi_guard.sh:5:GATES_FILE="guard/quality_gates.env"
./guard/pix2pi_guard.sh:51:# ---------- Gate B: Shared safety ----------
./guard/pix2pi_guard.sh:151:  go mod tidy >/tmp/go_mod_tidy_guard.log 2>&1 || (tail -n 80 /tmp/go_mod_tidy_guard.log && fail "go mod tidy hata")
./guard/pix2pi_guard.sh:157:go test ./... >/tmp/go_test_guard.log 2>&1 || (tail -n 120 /tmp/go_test_guard.log && fail "go test ./... hata")
./install_phase1_scaffold.sh:1370:      <span className="small">Role-aware menu ve guard bu ekranda devreye giriyor.</span>
./internal/erp/core/audit/service/erp_financial_flow_suite_test.go:73:	safetySvc, err := ledgerservice.NewPostingSafetyService(tracker)
./internal/erp/core/audit/service/erp_financial_flow_suite_test.go:122:	decision, err := safetySvc.Evaluate(context.Background(), ledgerservice.PostingSafetyRequest{
./internal/erp/core/audit/service/erp_financial_flow_suite_test.go:136:	if err := safetySvc.MarkRunning(context.Background(), decision); err != nil {
./internal/erp/core/audit/service/erp_financial_flow_suite_test.go:139:	if err := safetySvc.MarkCompleted(context.Background(), decision); err != nil {
./internal/erp/core/audit/service/erp_financial_flow_suite_test.go:167:	safetySvc, err := ledgerservice.NewPostingSafetyService(tracker)
./internal/erp/core/audit/service/erp_financial_flow_suite_test.go:215:	decision, err := safetySvc.Evaluate(context.Background(), ledgerservice.PostingSafetyRequest{
./internal/erp/core/audit/service/erp_financial_flow_suite_test.go:244:	safetySvc, err := ledgerservice.NewPostingSafetyService(tracker)
./internal/erp/core/audit/service/erp_financial_flow_suite_test.go:292:	decision, err := safetySvc.Evaluate(context.Background(), ledgerservice.PostingSafetyRequest{
./internal/erp/core/ledger/service/erp_posting_safety_service.go:65:		return PostingSafetyDecision{}, fmt.Errorf("posting safety service cannot be nil")
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.2.3 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.3 RPO / RTO hedef veya olcum izi

Pattern:

```text
RPO|RTO|recovery point|recovery time|restore.*duration|backup.*duration|recovery.*duration
```

Match Count: 12

```text
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:2248:      "integrity": "sha512-Uhdk5sfqcee/9H/rCOJikYz67o0a2Tw2hGRPOG2Y1R2dg7brRe1uG0yaNQDHu+TO/uQPF/5eCapvYSmHUjt7JQ==",
./scripts/audit_faz6_6_real_implementation.sh:174:write_check "6-6.3" "RPO / RTO hedef veya olcum izi" "RPO|RTO|recovery point|recovery time|restore.*duration|backup.*duration|recovery.*duration" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/test_faz6_1_scope_freeze.sh:84:check_grep "6-6.3 RPO RTO hedefleri tanimli" "$DOC_FILE" "6-6.3 RPO / RTO hedefleri"
./scripts/test_faz6_6_backup_restore_dr.sh:72:check_grep "6-6.3 RPO / RTO Hedefleri tanimli" "$DOC_FILE" "6-6.3 RPO / RTO Hedefleri"
./scripts/test_faz6_6_backup_restore_dr.sh:81:check_grep "6-6.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_6_3_RPO_RTO_STATUS=READY"
./scripts/test_faz6_6_backup_restore_dr.sh:113:check_grep "6-6.3 RPO RTO real audit evidence var" "$REAL_EVIDENCE_FILE" "6-6.3 RPO / RTO"
./web/node_modules/typescript/lib/fr/diagnosticMessages.generated.json:542:  "DIRECTORY_6038": "RÉPERTOIRE",
./web/node_modules/typescript/lib/fr/diagnosticMessages.generated.json:782:  "FILE_OR_DIRECTORY_6040": "FICHIER OU RÉPERTOIRE",
./web/panel/node_modules.bak_20260423_071809/.package-lock.json:1948:      "integrity": "sha512-Uhdk5sfqcee/9H/rCOJikYz67o0a2Tw2hGRPOG2Y1R2dg7brRe1uG0yaNQDHu+TO/uQPF/5eCapvYSmHUjt7JQ==",
./web/panel/node_modules.bak_20260423_071809/typescript/lib/fr/diagnosticMessages.generated.json:543:  "DIRECTORY_6038": "RÉPERTOIRE",
./web/panel/node_modules.bak_20260423_071809/typescript/lib/fr/diagnosticMessages.generated.json:784:  "FILE_OR_DIRECTORY_6040": "FICHIER OU RÉPERTOIRE",
./web/panel/package-lock.json:2262:      "integrity": "sha512-Uhdk5sfqcee/9H/rCOJikYz67o0a2Tw2hGRPOG2Y1R2dg7brRe1uG0yaNQDHu+TO/uQPF/5eCapvYSmHUjt7JQ==",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.3 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.4 Disaster scenario / DR runbook izi

Pattern:

```text
disaster|Disaster|DR|runbook|incident|disk.*full|node.*loss|DB.*loss|config.*restore|event.*restore
```

Match Count: 1418

```text
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:10:DROP POLICY IF EXISTS snapshots_tenant_policy ON snapshots;
./1_archive/root_sh/step_244_fix_app_user.sh:6:DROP ROLE IF EXISTS pix2pi_app;
./1_archive/root_sql/step_240_enable_rls_snapshots.sql:4:DROP POLICY IF EXISTS snapshots_tenant_policy ON snapshots;
./.backup/lvl10_2_10_5_edge_security_cert_ops_20260422_061143/deploy/edge/scripts/render_edge_config.sh:33:  HEALTH_ALLOW_CIDR
./.backup/lvl10_2_10_5_edge_security_cert_ops_20260422_061143/deploy/edge/scripts/render_edge_config.sh:53:  -e "s|__HEALTH_ALLOW_CIDR__|${HEALTH_ALLOW_CIDR}|g" \
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:614:      "integrity": "sha512-4IlJx0X0qftVsN5E+/vGujTRIFtwuLbNsVUe7TO6zYPDR1O6nFwvwhIKEKSrl6dZchmYBITazxKoUYOjdtjlRg==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1091:      "integrity": "sha512-PH5DRZT+F4f2PTXRXR8uJxnBq2po/xFtddyabTJVJs/ZYVHqXPEgNIr35IHTEa6bpa0Q8Awg+ymkTaGnKITw4g==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:1561:      "integrity": "sha512-tD40eHxA35h0PEIZNeIjkHoDR4YjjJp34biM0mDvplBe//mB+IHCqHDGV7pxF+7MklTvighcCPPZC7ynWyjdTA==",
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:3496:      "integrity": "sha512-7++dFhtcx3353uBaq8DDR4NuxBetBzC7ZQOhmTQInHEd6bSrXdiEyzCvG07Z44UYdLShWUyXt5M/yhz8ekcb1A==",
./cmd/api-gateway/api_gateway_main.go:976:	bindAddr := strings.TrimSpace(os.Getenv("GATEWAY_BIND_ADDR"))
./cmd/api-gateway/api_gateway_main_test.go:768:	t.Setenv("GATEWAY_BIND_ADDR", "")
./cmd/api-gateway/api_gateway_main_test.go:777:	t.Setenv("GATEWAY_BIND_ADDR", "127.0.0.1")
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
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.4 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.5.1 Cron / systemd backup-retention izi

Pattern:

```text
cron|crontab|/etc/cron|systemd.*timer|OnCalendar|retention|run_ops_retention|backup.*daily|daily.*backup
```

Match Count: 292

```text
./1_archive/root_sh/step_172_create_jetstream_stream.sh:8:  --retention limits \
./1_archive/root_sh/step_187_create_service_status_cron.sh:4:cat <<'CRON' > /etc/cron.d/pix2pi_service_status
./1_archive/root_sh/step_187_create_service_status_cron.sh:5:* * * * * root /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_187_create_service_status_cron.sh:6:* * * * * root sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_187_create_service_status_cron.sh:7:* * * * * root sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_187_create_service_status_cron.sh:8:* * * * * root sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_187_create_service_status_cron.sh:9:* * * * * root sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_187_create_service_status_cron.sh:10:* * * * * root sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_187_create_service_status_cron.sh:13:chmod 644 /etc/cron.d/pix2pi_service_status
./1_archive/root_sh/step_187_create_service_status_cron.sh:14:systemctl restart cron
./1_archive/root_sh/step_187_create_service_status_cron.sh:16:echo "OK ✅ service status cron aktif"
./1_archive/root_sh/step_188_verify_done_items.sh:136:if [ -f "/etc/cron.d/pix2pi_service_status" ]; then
./1_archive/root_sh/step_188_verify_done_items.sh:137:  yaz "OK ✅ service monitor cron dosyasi var"
./1_archive/root_sh/step_188_verify_done_items.sh:139:  yaz "UYARI ⚠ service monitor cron dosyasi yok"
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:13:cron_dosya="/etc/cron.d/pix2pi_reporting_service"
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:24:for f in "$start_script" "$stop_script" "$status_script" "$ensure_script" "$cron_dosya"; do
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:143:cat <<CRONEOF > "$cron_dosya"
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:146:chmod 644 "$cron_dosya"
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:147:systemctl restart cron
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:148:echo "OK ✅ cron watchdog aktif"
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:175:echo "OK ✅ duserse cron watchdog yeniden kaldiracak"
./1_archive/root_sh/step_277_fix_snapshot_frequency.sh:4:echo "Snapshot cron log spam azaltiliyor..."
./1_archive/root_sh/step_277_fix_snapshot_frequency.sh:6:CRON_FILE=~/pix2pi/pix2pi-SaaS/snapshot_cron.conf
./1_archive/root_sh/step_277_fix_snapshot_frequency.sh:12:*/1 * * * * /usr/bin/bash ~/pix2pi/run_snapshot.sh >> /tmp/pix2pi_service_snapshot_cron.log 2>&1
./1_archive/root_sh/step_279_find_snapshot_source.sh:5:crontab -l || true
./1_archive/root_sh/step_279_find_snapshot_source.sh:17:lsof | grep pix2pi_service_snapshot_cron.log || true
./1_archive/root_sh/step_280_fix_snapshot_logging.sh:12:sed -i 's/> \/tmp\/pix2pi_service_snapshot_cron.log/>> \/tmp\/pix2pi_service_snapshot_cron.log/g' $RUN_FILE
./1_archive/root_sh/step_281_logrotate_snapshot.sh:5:/tmp/pix2pi_service_snapshot_cron.log {
./1_archive/root_sh/step_282_fix_promtail_paths.sh:44:          __path__: /tmp/pix2pi_service_snapshot_cron.log
./1_archive/root_sh/step_283_disable_snapshot_logging.sh:9:sed -i 's/>> \/tmp\/pix2pi_service_snapshot_cron.log//g' $RUN_FILE
./1_archive/root_sh/step_314_find_kong_starter.sh:5:crontab -l || true
./1_archive/root_sh/step_314_find_kong_starter.sh:8:echo "=== /etc/crontab ==="
./1_archive/root_sh/step_314_find_kong_starter.sh:9:cat /etc/crontab || true
./1_archive/root_sh/step_373_add_early_warning_cron.sh:9:echo "1. mevcut cron aliniyor..."
./1_archive/root_sh/step_373_add_early_warning_cron.sh:11:crontab -l 2>/dev/null > "$TMP_CRON" || true
./1_archive/root_sh/step_373_add_early_warning_cron.sh:12:echo "OK ✅ cron alindi"
./1_archive/root_sh/step_373_add_early_warning_cron.sh:17:  echo "OK ✅ cron zaten var"
./1_archive/root_sh/step_373_add_early_warning_cron.sh:20:  crontab "$TMP_CRON"
./1_archive/root_sh/step_373_add_early_warning_cron.sh:21:  echo "OK ✅ cron eklendi"
./1_archive/root_sh/step_373_add_early_warning_cron.sh:27:echo "3. aktif cron gosteriliyor..."
./1_archive/root_sh/step_373_add_early_warning_cron.sh:28:crontab -l
./1_archive/root_sh/step_375_add_auto_heal_cron.sh:9:crontab -l 2>/dev/null > "$TMP" || true
./1_archive/root_sh/step_375_add_auto_heal_cron.sh:15:  crontab "$TMP"
./1_archive/root_sh/step_375_add_auto_heal_cron.sh:16:  echo "OK ✅ cron eklendi"
./1_archive/root_sh/step_375_add_auto_heal_cron.sh:22:crontab -l
./1_archive/root_sh/step_380_bind_all_crons.sh:7:crontab -l 2>/dev/null > "$TMP" || true
./1_archive/root_sh/step_380_bind_all_crons.sh:20:echo "1. cron satirlari ekleniyor..."
./1_archive/root_sh/step_380_bind_all_crons.sh:26:crontab "$TMP"
./1_archive/root_sh/step_380_bind_all_crons.sh:30:echo "2. aktif cron:"
./1_archive/root_sh/step_380_bind_all_crons.sh:31:crontab -l
./configs/faz5/entitlement_matrix_v1.json:196:    "cancelled": "access_closed_with_data_retention_policy",
./configs/faz5/legal_compliance_policy_v1.json:63:    "retention_policy_required": true,
./configs/faz5/legal_compliance_policy_v1.json:66:    "backup_retention_alignment_required": true,
./configs/faz5/revenue_metrics_policy_v1.json:51:      "code": "net_revenue_retention",
./configs/faz5/revenue_metrics_policy_v1.json:54:      "category": "retention"
./configs/faz5/revenue_metrics_policy_v1.json:57:      "code": "gross_revenue_retention",
./configs/faz5/revenue_metrics_policy_v1.json:60:      "category": "retention"
./configs/faz5/revenue_metrics_policy_v1.json:76:    "net_revenue_retention": "(starting_mrr + expansion_revenue - contraction_revenue - churned_mrr) / starting_mrr",
./configs/faz5/revenue_metrics_policy_v1.json:77:    "gross_revenue_retention": "(starting_mrr - contraction_revenue - churned_mrr) / starting_mrr",
./configs/faz5/tenant_lifecycle_policy_v1.json:113:    "data_retention_policy_source": "FAZ_5_6_LEGAL_COMPLIANCE",
./db/migrations/002_phase2_db_l4_service_registry.up.sql:17:      'cron',
./db/migrations/20260429_213001_security_audit_event_model.up.sql:13:    retention_policy_code text NOT NULL DEFAULT 'security_audit_default',
./deploy/edge/scripts/install_certbot_renew_foundation.sh:36:OnCalendar=*-*-* ${CERT_RENEW_HOUR}:${CERT_RENEW_MINUTE}:00
./deploy/edge/scripts/lvl10_edge_security_smoke.sh:15:TIMER_FILE="${ROOT_DIR}/deploy/edge/systemd/generated/pix2pi-cert-renew.timer"
./deploy/edge/scripts/lvl10_edge_security_smoke.sh:46:grep -q 'OnCalendar=' "${TIMER_FILE}"
./deploy/edge/scripts/lvl10_ops_validation.sh:14:TIMER_FILE="${ROOT_DIR}/deploy/edge/systemd/generated/pix2pi-cert-renew.timer"
./deploy/edge/scripts/lvl10_ops_validation.sh:98:check_grep "${TIMER_FILE}" "OnCalendar=" "cert renew timer var" || CERT_OPS_FOUNDATION_PASS=***MASKED***
./deploy/event-bus/init/create_stream.sh:8:--retention limits \
./deploy/observability/loki/loki.yml:29:  retention_period: 168h
./deploy/observability/tempo/tempo.yml:18:    block_retention: 24h
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.5.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.5.2 Backup / retention log izi

Pattern:

```text
ops_retention_cleanup\.log|backup\.log|restore\.log|LOG_FILE|REPORT_FILE|/var/log/pix2pi|retention.*log
```

Match Count: 1496

```text
./1_archive/root_sh/step_377_advanced_auto_heal.sh:30:LOG_FILE="$BASE/logs/auto_heal.log"
./1_archive/root_sh/step_377_advanced_auto_heal.sh:44:  echo "[$(timestamp)] $1" >> "$LOG_FILE"
./1_archive/root_sh/step_378_add_alert_engine.sh:31:LOG_FILE="/opt/pix2pi/runtime/auto_heal/logs/alert_engine.log"
./1_archive/root_sh/step_378_add_alert_engine.sh:40:  echo "[$(timestamp)] $1" >> "$LOG_FILE"
./1_archive/root_sh/step_379_add_scale_hook.sh:16:LOG_FILE="/opt/pix2pi/runtime/auto_heal/logs/scale_hook.log"
./1_archive/root_sh/step_379_add_scale_hook.sh:23:  echo "[$(timestamp)] $1" >> "$LOG_FILE"
./1_archive/root_sh/step_390_rewrite_early_warning_clean.sh:22:LOG_FILE="/opt/pix2pi/runtime/auto_heal/logs/early_warning.log"
./1_archive/root_sh/step_390_rewrite_early_warning_clean.sh:29:touch "$LOG_FILE"
./1_archive/root_sh/step_390_rewrite_early_warning_clean.sh:32:  echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh:6:CATALOG_FILE="${ROOT_DIR}/config/lvl11_signal_catalog.yaml"
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh:15:grep -q 'id: infra' "${CATALOG_FILE}"
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh:18:grep -q 'id: app' "${CATALOG_FILE}"
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh:21:grep -q 'id: db' "${CATALOG_FILE}"
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh:24:grep -q 'id: event_bus' "${CATALOG_FILE}"
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh:27:grep -q 'id: cache' "${CATALOG_FILE}"
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh:30:grep -q 'id: tenant_security' "${CATALOG_FILE}"
./cmd/erp/core/ufk/scripts/pilot/run_4c_6d_uat_execution_evidence.sh:14:REPORT_FILE="reports/pilot/faz4c/4c_6d_uat_execution_evidence_report.md"
./cmd/erp/core/ufk/scripts/pilot/run_4c_6d_uat_execution_evidence.sh:564:cat > "$REPORT_FILE" <<REPORT_EOF
./cmd/erp/core/ufk/scripts/pilot/run_4c_6d_uat_execution_evidence.sh:627:echo "OK ✅ UAT evidence report olusturuldu: $REPORT_FILE"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:10:REPORT_FILE="reports/pilot/faz4c/4c_6d_uat_execution_evidence_report.md"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:43:[ -f "$REPORT_FILE" ] || fail "4C-6D report yok"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:52:grep -q "4C_6D_UAT_EVIDENCE_CAPTURE_STATUS=PASS" "$REPORT_FILE" || fail "Evidence capture PASS degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:55:grep -q "4C_6D_TECHNICAL_UAT_STATUS=PASS" "$REPORT_FILE" || fail "Technical UAT PASS degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:58:grep -q "4C_6D_TECHNICAL_FAIL_COUNT=0" "$REPORT_FILE" || fail "Technical fail count 0 degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:61:grep -q "4C_6D_API_GATEWAY_HEALTH_HTTP=200" "$REPORT_FILE" || fail "Gateway health 200 degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:64:grep -q "4C_6D_IDENTITY_HEALTH_HTTP=200" "$REPORT_FILE" || fail "Identity health 200 degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:67:grep -q "4C_6D_DB_CONNECT_STATUS=PASS" "$REPORT_FILE" || fail "DB connect PASS degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:70:grep -q "4C_6D_STAGING_ROW_COUNT=5" "$REPORT_FILE" || fail "Staging row count 5 degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:73:grep -q "4C_6D_DUPLICATE_SKU_COUNT=0" "$REPORT_FILE" || fail "Duplicate SKU count 0 degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:76:grep -q "4C_6D_TENANT_MISMATCH_COUNT=0" "$REPORT_FILE" || fail "Tenant mismatch count 0 degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:79:grep -q "4C_6D_OEM_FIELD_COUNT=5" "$REPORT_FILE" || fail "OEM field count 5 degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:82:grep -q "4C_6D_EQUIVALENT_FIELD_COUNT=5" "$REPORT_FILE" || fail "Equivalent field count 5 degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:85:grep -q "4C_6D_FITMENT_FIELD_COUNT=5" "$REPORT_FILE" || fail "Fitment field count 5 degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:89:  grep -q "UAT_${n}_STATUS=PASS" "$REPORT_FILE" || fail "UAT_${n}_STATUS PASS degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:93:grep -q "UAT_12_STATUS=PENDING_BUSINESS_ACCEPTANCE" "$REPORT_FILE" || fail "UAT-12 business acceptance pending yok"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:96:grep -q "4C_6D_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:99:grep -q "4C_6D_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:102:grep -q "4C_6E_READY=YES" "$REPORT_FILE" || fail "4C-6E ready YES yok"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:105:WARNING_COUNT="$(grep '^4C_6D_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
./cmd/erp/core/ufk/scripts/pilot/test_4c_6d_uat_execution_evidence.sh:106:BARCODE_BLANK_COUNT="$(grep '^4C_6D_BARCODE_BLANK_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
./deploy/edge/scripts/lvl10_ops_validation.sh:42:REPORT_FILE="${REPORT_DIR_ABS}/lvl10_ops_validation_report.md"
./deploy/edge/scripts/lvl10_ops_validation.sh:145:cat <<REPORT > "${REPORT_FILE}"
./deploy/edge/scripts/lvl10_ops_validation.sh:163:echo "OK ✅ ops validation raporu hazir: ${REPORT_FILE}"
./deploy/edge/scripts/lvl10_phase_closure_check.sh:21:PHASE_REPORT_FILE="${REPORT_DIR_ABS}/lvl10_phase_closure_report.md"
./deploy/edge/scripts/lvl10_phase_closure_check.sh:46:cat <<REPORT > "${PHASE_REPORT_FILE}"
./deploy/edge/scripts/lvl10_phase_closure_check.sh:68:  echo "HATA ❌ rapor: ${PHASE_REPORT_FILE}"
./deploy/edge/scripts/lvl10_phase_closure_check.sh:74:  echo "OK ✅ rapor: ${PHASE_REPORT_FILE}"
./deploy/edge/scripts/lvl10_phase_closure_check.sh:79:echo "OK ✅ rapor: ${PHASE_REPORT_FILE}"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:6:ACCOUNTANT_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_accountant_portal_catalog.yaml"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:7:DOCUMENT_AI_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_document_ai_catalog.yaml"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:17:grep -q 'multi_company_access:' "${ACCOUNTANT_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:20:grep -q 'company_scoped_permissions:' "${ACCOUNTANT_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:23:grep -q 'export_surfaces:' "${ACCOUNTANT_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:26:grep -q 'subscription_model:' "${ACCOUNTANT_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:29:grep -q 'company_visibility:' "${ACCOUNTANT_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:32:grep -q 'test_suite:' "${ACCOUNTANT_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:35:grep -q 'ocr_lens_flow:' "${DOCUMENT_AI_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:38:grep -q 'tax_field_extraction:' "${DOCUMENT_AI_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:41:grep -q 'contact_field_extraction:' "${DOCUMENT_AI_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:44:grep -q 'confidence_and_review:' "${DOCUMENT_AI_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_accountant_portal_document_ai_smoke.sh:47:grep -q 'test_suite:' "${DOCUMENT_AI_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_ebelge_export_smoke.sh:6:EBELGE_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_ebelge_catalog.yaml"
./deploy/erp-tr/scripts/lvl13_ebelge_export_smoke.sh:7:EXPORT_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_export_catalog.yaml"
./deploy/erp-tr/scripts/lvl13_ebelge_export_smoke.sh:17:grep -q 'efatura:' "${EBELGE_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_ebelge_export_smoke.sh:20:grep -q 'earsiv:' "${EBELGE_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_ebelge_export_smoke.sh:23:grep -q 'eadisyon:' "${EBELGE_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_ebelge_export_smoke.sh:26:grep -q 'status_sync:' "${EBELGE_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_ebelge_export_smoke.sh:29:grep -q 'error_cancel_retry:' "${EBELGE_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_ebelge_export_smoke.sh:32:grep -q 'validation_suite:' "${EBELGE_CATALOG_FILE}"
./deploy/erp-tr/scripts/lvl13_ebelge_export_smoke.sh:35:grep -q 'logo:' "${EXPORT_CATALOG_FILE}"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.5.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.5.3 Retention guard / cleanup izi

Pattern:

```text
retention|Retention|KEEP|keep|delete|cleanup|archive|protected|guard|APPLY=|APPLY\:\-
```

Match Count: 2191

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:5:    keepalive 64;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:10:    keepalive 32;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:15:    keepalive 32;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:20:    keepalive 32;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:5:    keepalive 64;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:10:    keepalive 32;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:15:    keepalive 32;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:20:    keepalive 32;
./1_archive/root_sh/step_172_create_jetstream_stream.sh:8:  --retention limits \
./1_archive/root_sh/step_188_verify_done_items.sh:109:    *install*|*backup*|*prepare*|*create*|*restart*|*reload*|*cleanup*|*fix*|*start*|*stop*)
./1_archive/root_sh/step_231_snapshot_full.sh:110:		t.Fatalf("snapshot cleanup hatasi: %v", err)
./1_archive/root_sh/step_301_orchestrator_foundation.sh:5:mkdir -p ~/pix2pi/pix2pi-SaaS/_backup_archive/orchestrator
./1_archive/root_sh/step_351_clean_nginx_duplicates_and_fix_monitor.sh:15:find /etc/nginx/sites-enabled -maxdepth 1 \( -name "*.bak" -o -name "*.bak_*" \) -print -delete || true
./1_archive/root_sh/step_377_advanced_auto_heal.sh:59:cleanup() {
./1_archive/root_sh/step_377_advanced_auto_heal.sh:62:trap cleanup EXIT
./1_archive/root_sh/step_423c_db_auth_probe.sh:5:cleanup() {
./1_archive/root_sh/step_423c_db_auth_probe.sh:11:trap cleanup EXIT
./1_archive/root_sh/step_423d_reset_db_password.sh:10:cleanup() {
./1_archive/root_sh/step_423d_reset_db_password.sh:17:trap cleanup EXIT
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:10:cleanup() {
./1_archive/root_sh/step_423e_fix_gateway_dsn.sh:17:trap cleanup EXIT
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:5:    keepalive 64;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:10:    keepalive 32;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:15:    keepalive 32;
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf:20:    keepalive 32;
./cmd/api-gateway/api_gateway_main.go:49:	routeScopeProtected routeScope = "protected"
./cmd/api-gateway/api_gateway_main.go:188:			Description:    "protected self route",
./cmd/api-gateway/api_gateway_main.go:198:			Description:    "protected user count route",
./cmd/api-gateway/api_gateway_main.go:208:			Description:    "protected user list route",
./cmd/api-gateway/api_gateway_main.go:218:			Description:    "protected user detail prefix",
./cmd/api-gateway/api_gateway_main.go:687:			"message":        "protected route ok",
./cmd/api-gateway/api_gateway_main.go:849:	protectedMux := http.NewServeMux()
./cmd/api-gateway/api_gateway_main.go:850:	registerProtectedRoutes(protectedMux)
./cmd/api-gateway/api_gateway_main.go:854:		if err := registerERPRuntimeUnavailableProtectedRoute(protectedMux, erpRuntimeErr); err != nil {
./cmd/api-gateway/api_gateway_main.go:858:		if _, err := registerERPRuntimeProtectedRoutes(protectedMux, erpRuntimeBundle.service); err != nil {
./cmd/api-gateway/api_gateway_main.go:859:			log.Printf("WARN ⚠️ ERP Runtime protected route mount basarisiz: %v", err)
./cmd/api-gateway/api_gateway_main.go:860:			if fallbackErr := registerERPRuntimeUnavailableProtectedRoute(protectedMux, err); fallbackErr != nil {
./cmd/api-gateway/api_gateway_main.go:864:			log.Printf("OK ✅ ERP Runtime protected route mounted: %s", erpRuntimeGatewayRouteRule().Path)
./cmd/api-gateway/api_gateway_main.go:868:	protectedDispatch := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
./cmd/api-gateway/api_gateway_main.go:898:		handler, pattern := protectedMux.Handler(r)
./cmd/api-gateway/api_gateway_main.go:917:	protectedHandler := chain(
./cmd/api-gateway/api_gateway_main.go:918:		protectedDispatch,
./cmd/api-gateway/api_gateway_main.go:925:	rootMux.Handle("/api/", protectedHandler)
./cmd/api-gateway/erp_runtime_live_mount_wiring_test.go:50:		"registerERPRuntimeProtectedRoutes(protectedMux, erpRuntimeBundle.service)",
./cmd/api-gateway/erp_runtime_live_mount_wiring_test.go:51:		"registerERPRuntimeUnavailableProtectedRoute(protectedMux, erpRuntimeErr)",
./cmd/api-gateway/erp_runtime_live_mount_wiring_test.go:52:		"ERP Runtime protected route mounted",
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:34:	cleanupGatewayProtectedERPRuntimeSmokeFlow(t, pool, tenantID, sourceNo)
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:35:	defer cleanupGatewayProtectedERPRuntimeSmokeFlow(t, pool, tenantID, sourceNo)
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:50:	apiReq.RequestID = "req-gw-protected-" + unique
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:51:	apiReq.ActorID = "user-gateway-protected"
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:61:	apiReq.CorrelationID = "corr-gw-protected-" + unique
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:207:		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping gateway protected ERP runtime smoke test")
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:213:func cleanupGatewayProtectedERPRuntimeSmokeFlow(t *testing.T, pool *pgxpool.Pool, tenantID string, sourceNo string) {
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:221:		t.Logf("cleanup begin failed: %v", err)
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:227:		t.Logf("cleanup set tenant failed: %v", err)
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:236:		t.Logf("cleanup flow failed: %v", err)
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:241:		t.Logf("cleanup commit failed: %v", err)
./cmd/api-gateway/erp_runtime_route_catalog_wiring_test.go:27:			t.Fatalf("expected protected scope, got %s", rule.Scope)
./cmd/api-gateway/erp_runtime_route_catalog_wiring_test.go:63:		t.Fatalf("expected protected scope, got %s", rule.Scope)
./cmd/api-gateway/erp_runtime_route_policy.go:35:	protectedMux *http.ServeMux,
./cmd/api-gateway/erp_runtime_route_policy.go:38:	return mountERPRuntimeGatewayRoutes(protectedMux, service)
./cmd/api-gateway/erp_runtime_route_policy.go:41:func registerERPRuntimeUnavailableProtectedRoute(protectedMux *http.ServeMux, cause error) error {
./cmd/api-gateway/erp_runtime_route_policy.go:42:	if protectedMux == nil {
./cmd/api-gateway/erp_runtime_route_policy.go:53:	protectedMux.HandleFunc(apisurface.RuntimeFlowAPIPath, func(w http.ResponseWriter, r *http.Request) {
./cmd/api-gateway/erp_runtime_route_policy_test.go:25:		t.Fatalf("expected protected scope, got %s", rule.Scope)
./cmd/api-gateway/erp_runtime_route_policy_test.go:87:	protectedMux := http.NewServeMux()
./cmd/api-gateway/erp_runtime_route_policy_test.go:90:	binding, err := registerERPRuntimeProtectedRoutes(protectedMux, service)
./cmd/api-gateway/erp_runtime_route_policy_test.go:111:	protectedMux.ServeHTTP(rec, req)
./cmd/api-gateway/erp_runtime_route_policy_test.go:145:	protectedMux := http.NewServeMux()
./cmd/api-gateway/erp_runtime_route_policy_test.go:147:	_, err := registerERPRuntimeProtectedRoutes(protectedMux, nil)
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.5.3 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.6 PITR / WAL readiness izi

Pattern:

```text
archive_mode|archive_command|wal_level|WAL|PITR|pg_wal|recovery_target_time|restore_command|basebackup|pg_basebackup
```

Match Count: 378

```text
./1_archive/root_sh/step_44c_audit_pg_topology.sh:73:    docker exec pix2pi_pg sh -lc 'psql -U pix2pi -d pix2pi -Atqc "show wal_level;"'
./1_archive/root_sh/step_44c_replica_fix.sh:62:echo "7. pg_basebackup one-shot container ile aliniyor..."
./1_archive/root_sh/step_44c_replica_fix.sh:68:  bash -lc "pg_basebackup -h $PRIMARY_HOST -U $REPL_USER -D /var/lib/postgresql/data -P -R"
./1_archive/root_sh/step_44c_replica_fix.sh:69:echo "OK ✅ pg_basebackup tamam"
./1_archive/root_sh/step_78_test_production_server_ready.sh:12:echo "=== FIREWALL ==="
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:236:      "integrity": "sha512-qSs4ifwzKJSV39ucNjsvc6WVHs6b7S03sOh2OcHF9UHfVPqWWALUsNUVzhSBiItjRZoLHx7nIarVjqKVusUZ1Q==",
./scripts/audit_faz6_2_db_l8_readiness.sh:171:  echo "6-2.5 PITR/restore readiness checklist checked OK ✅"
./scripts/audit_faz6_2_real_implementation.sh:184:write_check "6-2.5" "PITR / backup / restore script izi" "archive_mode|archive_command|wal_level|pg_basebackup|pg_dump|pg_restore|restic|restore" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_6_backup_restore_runtime.sh:122:  write_cmd_block "6-6.10 PostgreSQL WAL / Archive Runtime Probe" bash -lc "
./scripts/audit_faz6_6_backup_restore_runtime.sh:129:    docker exec \"\$c\" sh -lc \"pg_isready; psql -U postgres -d postgres -Atc \\\"show wal_level; show archive_mode; show archive_command;\\\"\" 2>/dev/null || true
./scripts/audit_faz6_6_backup_restore_runtime.sh:141:    grep -E 'RESTIC|BACKUP|RESTORE|RETENTION|PG|POSTGRES|DB_|WAL|PITR' \"\$f\" | head -n 120
./scripts/audit_faz6_6_backup_restore_runtime.sh:165:  echo "6-6.8 PostgreSQL runtime backup/WAL probe collected OK ✅"
./scripts/audit_faz6_6_real_implementation.sh:162:write_check "6-6.1.1" "Database backup script izi" "pg_dump|pg_basebackup|POSTGRES|DB_BACKUP|database.*backup|backup.*database|docker exec.*postgres|psql.*dump" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_6_real_implementation.sh:184:write_check "6-6.6" "PITR / WAL readiness izi" "archive_mode|archive_command|wal_level|WAL|PITR|pg_wal|recovery_target_time|restore_command|basebackup|pg_basebackup" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/phase4_db_backup_pitr_readiness.sh:108:detail "PITR_CONFIG_CHANGE=NO"
./scripts/phase4_db_backup_pitr_readiness.sh:195:WAL_LEVEL="unknown"
./scripts/phase4_db_backup_pitr_readiness.sh:198:MAX_WAL_SENDERS="unknown"
./scripts/phase4_db_backup_pitr_readiness.sh:199:WAL_KEEP_SIZE="unknown"
./scripts/phase4_db_backup_pitr_readiness.sh:203:  WAL_LEVEL="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show wal_level;" 2>/dev/null || echo "error")"
./scripts/phase4_db_backup_pitr_readiness.sh:204:  ARCHIVE_MODE="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show archive_mode;" 2>/dev/null || echo "error")"
./scripts/phase4_db_backup_pitr_readiness.sh:205:  ARCHIVE_COMMAND="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show archive_command;" 2>/dev/null || echo "error")"
./scripts/phase4_db_backup_pitr_readiness.sh:206:  MAX_WAL_SENDERS="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show max_wal_senders;" 2>/dev/null || echo "error")"
./scripts/phase4_db_backup_pitr_readiness.sh:207:  WAL_KEEP_SIZE="$(PGCONNECT_TIMEOUT=3 psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show wal_keep_size;" 2>/dev/null || echo "error")"
./scripts/phase4_db_backup_pitr_readiness.sh:210:  detail "POSTGRES_WAL_LEVEL=$WAL_LEVEL"
./scripts/phase4_db_backup_pitr_readiness.sh:213:  detail "POSTGRES_MAX_WAL_SENDERS=$MAX_WAL_SENDERS"
./scripts/phase4_db_backup_pitr_readiness.sh:214:  detail "POSTGRES_WAL_KEEP_SIZE=$WAL_KEEP_SIZE"
./scripts/phase4_db_backup_pitr_readiness.sh:218:PITR_READY="NO"
./scripts/phase4_db_backup_pitr_readiness.sh:231:if [ "$WAL_LEVEL" = "replica" ] || [ "$WAL_LEVEL" = "logical" ]; then
./scripts/phase4_db_backup_pitr_readiness.sh:232:  WAL_LEVEL_READY="YES"
./scripts/phase4_db_backup_pitr_readiness.sh:234:  WAL_LEVEL_READY="NO"
./scripts/phase4_db_backup_pitr_readiness.sh:243:if [ "$WAL_LEVEL_READY" = "YES" ] && [ "$ARCHIVE_MODE_READY" = "YES" ] && [ "$ARCHIVE_COMMAND" != "(disabled)" ] && [ -n "$ARCHIVE_COMMAND" ]; then
./scripts/phase4_db_backup_pitr_readiness.sh:244:  PITR_READY="YES"
./scripts/phase4_db_backup_pitr_readiness.sh:259:detail "WAL_LEVEL_READY=$WAL_LEVEL_READY"
./scripts/phase4_db_backup_pitr_readiness.sh:261:detail "PITR_READY=$PITR_READY"
./scripts/phase4_db_backup_pitr_readiness.sh:264:if [ "$PITR_READY" != "YES" ]; then
./scripts/phase4_db_backup_pitr_readiness.sh:265:  warn "PITR tam hazir degil; archive_mode/archive_command kontrol edilmeli"
./scripts/phase4_db_backup_pitr_readiness.sh:277:  echo "# FAZ 4 / 14.2.1 - DB Backup / Restore / PITR Readiness Report"
./scripts/phase4_db_backup_pitr_readiness.sh:287:    echo "DB_BACKUP_PITR_READINESS_ASSESSMENT=PASS"
./scripts/phase4_db_backup_pitr_readiness.sh:289:    echo "DB_BACKUP_PITR_READINESS_ASSESSMENT=FAIL"
./scripts/phase4_db_backup_pitr_readiness.sh:327:echo "PITR_READY=$PITR_READY"
./scripts/phase4_db_backup_pitr_readiness.sh:330:  echo "DB_BACKUP_PITR_READINESS_ASSESSMENT=FAIL ❌"
./scripts/phase4_db_backup_pitr_readiness.sh:334:echo "DB_BACKUP_PITR_READINESS_ASSESSMENT=PASS ✅"
./scripts/phase4_db_final_closure_gate.sh:145:require_file "14.2.1 backup/PITR readiness" "$R_1421" || true
./scripts/phase4_db_final_closure_gate.sh:148:require_file "14.2.5 PITR design" "$R_1425" || true
./scripts/phase4_db_final_closure_gate.sh:149:require_file "14.2.6 PITR enable gate" "$R_1426" || true
./scripts/phase4_db_final_closure_gate.sh:160:S_1421="$(get_report_value "$R_1421" "DB_BACKUP_PITR_READINESS_ASSESSMENT")"
./scripts/phase4_db_final_closure_gate.sh:163:S_1425="$(get_report_value "$R_1425" "PITR_DESIGN_WAL_ARCHIVE_PLAN")"
./scripts/phase4_db_final_closure_gate.sh:164:S_1426="$(get_report_value "$R_1426" "PITR_ENABLE_GATE")"
./scripts/phase4_db_final_closure_gate.sh:182:PITR_CURRENT_READY="$(get_report_value "$R_1426" "PITR_CURRENT_READY")"
./scripts/phase4_db_final_closure_gate.sh:183:PITR_ENABLE_DECISION="$(get_report_value "$R_1426" "PITR_ENABLE_DECISION")"
./scripts/phase4_db_final_closure_gate.sh:186:HOST_WAL_ARCHIVE_DIR_STATUS="$(get_report_value "$R_1426" "HOST_WAL_ARCHIVE_DIR_STATUS")"
./scripts/phase4_db_final_closure_gate.sh:187:WAL_ARCHIVE_MOUNT_STATUS="$(get_report_value "$R_1426" "WAL_ARCHIVE_MOUNT_STATUS")"
./scripts/phase4_db_final_closure_gate.sh:195:detail "14_2_1_DB_BACKUP_PITR_READINESS_ASSESSMENT=$S_1421"
./scripts/phase4_db_final_closure_gate.sh:198:detail "14_2_5_PITR_DESIGN_WAL_ARCHIVE_PLAN=$S_1425"
./scripts/phase4_db_final_closure_gate.sh:199:detail "14_2_6_PITR_ENABLE_GATE=$S_1426"
./scripts/phase4_db_final_closure_gate.sh:216:detail "PITR_CURRENT_READY=$PITR_CURRENT_READY"
./scripts/phase4_db_final_closure_gate.sh:217:detail "PITR_ENABLE_DECISION=$PITR_ENABLE_DECISION"
./scripts/phase4_db_final_closure_gate.sh:220:detail "HOST_WAL_ARCHIVE_DIR_STATUS=$HOST_WAL_ARCHIVE_DIR_STATUS"
./scripts/phase4_db_final_closure_gate.sh:221:detail "WAL_ARCHIVE_MOUNT_STATUS=$WAL_ARCHIVE_MOUNT_STATUS"
./scripts/phase4_db_final_closure_gate.sh:232:if [ "$S_1425" != "PASS" ]; then fail "14.2.5 PITR design PASS degil"; fi
./scripts/phase4_db_final_closure_gate.sh:233:if [ "$S_1426" != "PASS" ]; then fail "14.2.6 PITR enable gate PASS degil"; fi
./scripts/phase4_db_final_closure_gate.sh:244:if [ "$PITR_CURRENT_READY" = "NO" ]; then
./scripts/phase4_db_final_closure_gate.sh:245:  warn "PITR current ready NO; final status READY_WITH_DEFERRED_ACTIONS olarak muhurlenecek"
./scripts/phase4_db_final_closure_gate.sh:246:  risk "RISK_PITR_DEFERRED=PITR aktif degil; WAL archive maintenance bekliyor"
./scripts/phase4_db_final_closure_gate.sh:347:closure "14.2 Backup/Restore/PITR Gate=PASS"
./scripts/phase4_db_final_closure_gate.sh:362:closure "PITR Current Ready=${PITR_CURRENT_READY}"
./scripts/phase4_db_final_closure_gate.sh:442:  echo "PITR_CURRENT_READY=$PITR_CURRENT_READY"
./scripts/phase4_db_final_closure_gate.sh:448:  echo "PITR enable deferred: PITR_CURRENT_READY=$PITR_CURRENT_READY"
./scripts/phase4_db_final_closure_gate.sh:449:  echo "WAL archive mount/status: HOST_WAL_ARCHIVE_DIR_STATUS=$HOST_WAL_ARCHIVE_DIR_STATUS / WAL_ARCHIVE_MOUNT_STATUS=$WAL_ARCHIVE_MOUNT_STATUS"
./scripts/phase4_db_final_closure_gate.sh:450:  echo "archive_mode/archive_command: ARCHIVE_MODE_READY=$ARCHIVE_MODE_READY / ARCHIVE_COMMAND_READY=$ARCHIVE_COMMAND_READY"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.6 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.7 Backup security / secret masking izi

Pattern:

```text
RESTIC_PASSWORD|mask_secret|MASKED|chmod|chown|600|secret|SECRET|password|PASSWORD
```

Match Count: 1934

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
./1_archive/root_sh/step_210_audit_full.sh:82:			{HesapKodu: "600", Alacak: 1000},
./1_archive/root_sh/step_210_audit_full.sh:100:			{HesapKodu: "600", Alacak: 900},
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:15:DB_PASSWORD=***MASKED***
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:19:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:24:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:31:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_230_snapshot_schema.sh:21:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_231_snapshot_full.sh:100:	connStr := "host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
./1_archive/root_sh/step_232_run_snapshot_flow.sh:18:PGPASSWORD=***MASKED***
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
./1_archive/root_sh/step_245_fix_password.sh:10:echo "OK ✅ password reset"
./1_archive/root_sh/step_246_grant_snapshot_sequence.sh:4:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:5:cikti_1=$(PGPASSWORD=***MASKED***
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:30:cikti_2=$(PGPASSWORD=***MASKED***
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:56:cikti_3=$(PGPASSWORD=***MASKED***
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:83:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:100:cikti_5=$(PGPASSWORD=***MASKED***
./1_archive/root_sh/step_251_fix_verification.sh:6:cikti=$(PGPASSWORD=***MASKED***
./1_archive/root_sh/step_25_check_postgres_password.sh:7:docker exec pix2pi_pg env | grep -E 'POSTGRES_(USER|PASSWORD|DB)' || true
./1_archive/root_sh/step_25_check_postgres_password.sh:11:grep -E '^(DB_HOST|DB_PORT|DB_USER|DB_NAME|DB_PASSWORD|POSTGRES_USER|POSTGRES_PASSWORD|POSTGRES_DB)=' .env || true
./1_archive/root_sh/step_260_audit_schema.sh:30:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_261_audit_full.sh:84:	connStr := "host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
./1_archive/root_sh/step_262_run_audit_flow.sh:18:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_270_observability_stack.sh:61:      - GF_SECURITY_ADMIN_PASSWORD=***MASKED***
./1_archive/root_sh/step_273_fix_promtail_positions.sh:86:      - GF_SECURITY_ADMIN_PASSWORD=***MASKED***
./1_archive/root_sh/step_27_check_postgres_container_user.sh:7:docker exec pix2pi_pg env | grep -E 'POSTGRES_(USER|PASSWORD|DB)' || true
./1_archive/root_sh/step_301_orchestrator_foundation.sh:32:chmod +x /opt/pix2pi/orchestrator/bin/run_api_gateway.sh
./1_archive/root_sh/step_301_orchestrator_foundation.sh:44:chmod +x /opt/pix2pi/orchestrator/bin/run_accounting_service.sh
./1_archive/root_sh/step_301_orchestrator_foundation.sh:56:chmod +x /opt/pix2pi/orchestrator/bin/run_query_read_model.sh
./1_archive/root_sh/step_301_orchestrator_foundation.sh:68:chmod +x /opt/pix2pi/orchestrator/bin/run_service_discovery.sh
./1_archive/root_sh/step_315_block_openresty.sh:12:  chmod -x /usr/local/openresty/nginx/sbin/nginx
./1_archive/root_sh/step_320_rewrite_panel_index.sh:210:      font-weight:600;
./1_archive/root_sh/step_352_force_monitor_from_static_root.sh:31:chmod 644 "$STATIC_FILE"
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:210:      font-weight:600;
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:461:chmod 644 "$MONITOR_FILE"
./1_archive/root_sh/step_371_add_early_warning_collector.sh:93:chmod +x "$SCRIPT_PATH"
./1_archive/root_sh/step_374_add_auto_heal_engine.sh:58:chmod +x "$SCRIPT"
./1_archive/root_sh/step_376_prepare_heal_state.sh:21:chmod 700 "$STATE_DIR" "$LOCK_DIR" "$FAIL_DIR" "$ALERT_DIR" "$SCALE_DIR" "$LOG_DIR"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.7 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-6.8 Backup / restore test script izi

Pattern:

```text
test.*backup|backup.*test|test.*restore|restore.*test|audit.*backup|backup.*audit|FAZ_6_6|backup_restore
```

Match Count: 110

```text
./1_archive/root_sh/step_1_backup_tenant_test.sh:9:  backups/app/manual/playground_main.go.tenant_test.bak 2>/dev/null || true
./1_archive/root_sh/step_28_backup_audit_log_engine.sh:9:  backups/app/manual/playground_main.go.audit_log_engine.bak 2>/dev/null || true
./1_archive/root_sh/step_36_run_backup_isolation_test.sh:8:echo "OK ✅ backup isolation test calistirma bitti"
./1_archive/root_sh/step_78_test_production_server_ready.sh:20:test -d /opt/pix2pi/backups && echo "OK ✅ /opt/pix2pi/backups var"
./reports/master_progress_report.json:1497:                "step_36_run_backup_isolation_test.sh"
./reports/master_progress_report.json:2426:        "step_36_run_backup_isolation_test.sh"
./reports/master_progress_report_v2.json:1579:              "step_36_run_backup_isolation_test.sh"
./reports/master_progress_report_v2.json:2368:          "step_36_run_backup_isolation_test.sh"
./scripts/audit_faz6_5_real_implementation.sh:211:    echo "FAZ_6_6_READY=YES ✅"
./scripts/audit_faz6_5_real_implementation.sh:214:    echo "FAZ_6_6_READY=YES_WITH_WARNINGS ⚠️"
./scripts/audit_faz6_5_real_implementation.sh:217:    echo "FAZ_6_6_READY=NO_REVIEW_REQUIRED ❌"
./scripts/audit_faz6_5_real_implementation.sh:243:  echo "FAZ_6_6_READY=YES ✅"
./scripts/audit_faz6_5_real_implementation.sh:246:  echo "FAZ_6_6_READY=YES_WITH_WARNINGS ⚠️"
./scripts/audit_faz6_5_real_implementation.sh:249:  echo "FAZ_6_6_READY=NO_REVIEW_REQUIRED ❌"
./scripts/audit_faz6_6_backup_restore_runtime.sh:7:EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_6_BACKUP_RESTORE_RUNTIME_AUDIT.md"
./scripts/audit_faz6_6_backup_restore_runtime.sh:41:Bu audit runtime ortaminda backup / restore / disaster recovery izlerini toplar. Destructive restore yapmaz.
./scripts/audit_faz6_6_backup_restore_runtime.sh:43:FAZ_6_6_RUNTIME_AUDIT=STARTED ✅
./scripts/audit_faz6_6_backup_restore_runtime.sh:168:  echo "FAZ_6_6_RUNTIME_AUDIT=COMPLETE ✅"
./scripts/audit_faz6_6_backup_restore_runtime.sh:172:echo "FAZ_6_6_RUNTIME_AUDIT=COMPLETE ✅"
./scripts/audit_faz6_6_real_implementation.sh:7:EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_6_REAL_IMPLEMENTATION_AUDIT.md"
./scripts/audit_faz6_6_real_implementation.sh:170:write_check "6-6.2.2" "Restore smoke test izi" "smoke|Smoke|health.*check|/health|curl.*health|post.*restore|restore.*test|test.*restore|pg_isready" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_6_real_implementation.sh:188:write_check "6-6.8" "Backup / restore test script izi" "test.*backup|backup.*test|test.*restore|restore.*test|audit.*backup|backup.*audit|FAZ_6_6|backup_restore" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/audit_faz6_6_real_implementation.sh:199:    echo "FAZ_6_6_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_6_real_implementation.sh:201:    echo "FAZ_6_6_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
./scripts/audit_faz6_6_real_implementation.sh:205:    echo "FAZ_6_6_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_6_real_implementation.sh:207:    echo "FAZ_6_6_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
./scripts/audit_faz6_6_real_implementation.sh:211:    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_6_real_implementation.sh:214:    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
./scripts/audit_faz6_6_real_implementation.sh:217:    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
./scripts/audit_faz6_6_real_implementation.sh:221:  echo "FAZ_6_6_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
./scripts/audit_faz6_6_real_implementation.sh:231:  echo "FAZ_6_6_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_6_real_implementation.sh:233:  echo "FAZ_6_6_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
./scripts/audit_faz6_6_real_implementation.sh:237:  echo "FAZ_6_6_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_6_real_implementation.sh:239:  echo "FAZ_6_6_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
./scripts/audit_faz6_6_real_implementation.sh:243:  echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
./scripts/audit_faz6_6_real_implementation.sh:246:  echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
./scripts/audit_faz6_6_real_implementation.sh:249:  echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
./scripts/audit_faz6_6_real_implementation.sh:253:echo "FAZ_6_6_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
./scripts/faz4d/test_4d_15_release_rollback_backup_gate.sh:21:  BACKUP_DIR="backups/faz4d/$(date +%Y%m%d_%H%M%S)_before_4d_15_test_rerun"
./scripts/phase4b_backup_restore_verification.sh:7:python3 "$SCRIPT_DIR/phase4b_backup_restore_verification.py" "$ROOT_DIR"
./scripts/phase4_db_final_closure_gate.sh:14:R_1424="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
./scripts/phase4_db_final_closure_gate.sh:147:require_file "14.2.4 restore drill test" "$R_1424" || true
./scripts/phase4_db_master_evidence_collector.sh:193:R_1424="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
./scripts/phase4_db_master_evidence_collector.sh:208:require_file "14.2.4 restore drill test" "$R_1424" || true
./scripts/phase4_db_production_readiness_scorecard.sh:15:R_1424="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
./scripts/phase4_db_production_readiness_scorecard.sh:226:  add_score "backup_restore_readiness" "$BACKUP_SCORE" "20" "PASS" "$BACKUP_NOTE"
./scripts/phase4_db_production_readiness_scorecard.sh:228:  add_score "backup_restore_readiness" "$BACKUP_SCORE" "20" "REVIEW" "$BACKUP_NOTE"
./scripts/phase4_db_runbook_incident_checklist.sh:15:R_1424="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
./scripts/phase4_db_runbook_incident_checklist.sh:93:require_file "14.2.4 restore drill test" "$R_1424" || true
./scripts/phase4_db_runbook_incident_checklist.sh:162:  fail "restore drill test PASS degil"
./scripts/phase4_db_runbook_incident_checklist.sh:247:bash scripts/phase4_restore_drill_test.sh .
./scripts/phase4_db_runbook_incident_checklist.sh:253:  docs/phase4/14_2_4_restore_drill_test_report.md
./scripts/phase4_pitr_design_wal_archive_plan.sh:12:RESTORE_REPORT="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
./scripts/phase4_pitr_design_wal_archive_plan.sh:158:detail "RESTORE_REPORT=docs/phase4/14_2_4_restore_drill_test_report.md"
./scripts/phase4_pitr_enable_gate.sh:12:RESTORE_REPORT="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
./scripts/phase4_restore_drill_test.sh:7:REPORT_FILE="$REPORT_DIR/14_2_4_restore_drill_test_report.md"
./scripts/step_gw_rate_quota_restore_fix_1.sh:112:ln -sf "$REPORT_FILE" "$ROOT/reports/gw_rate_quota_restore_fix_1_latest.txt"
./scripts/step_gw_rate_quota_restore_fix_1.sh:115:echo "OK ✅ latest rapor: $ROOT/reports/gw_rate_quota_restore_fix_1_latest.txt"
./scripts/step_gw_rate_quota_restore_fix_2.sh:10:LATEST_LINK="$ROOT/reports/gw_rate_quota_restore_fix_2_latest.txt"
./scripts/test_faz6_5_observability_sre_dashboard.sh:140:    echo "FAZ_6_6_READY=YES ✅"
./scripts/test_faz6_5_observability_sre_dashboard.sh:144:    echo "FAZ_6_6_READY=YES_WITH_WARNINGS ⚠️"
./scripts/test_faz6_5_observability_sre_dashboard.sh:148:    echo "FAZ_6_6_READY=NO_REVIEW_REQUIRED ❌"
./scripts/test_faz6_6_backup_restore_dr.sh:7:DOC_FILE="docs/faz6/FAZ_6_6_BACKUP_RESTORE_DISASTER_RECOVERY.md"
./scripts/test_faz6_6_backup_restore_dr.sh:8:CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_6_BACKUP_RESTORE_VISIBLE_CHECKPOINTS.md"
./scripts/test_faz6_6_backup_restore_dr.sh:9:RUNTIME_AUDIT_SCRIPT="scripts/audit_faz6_6_backup_restore_runtime.sh"
./scripts/test_faz6_6_backup_restore_dr.sh:11:RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_6_BACKUP_RESTORE_RUNTIME_AUDIT.md"
./scripts/test_faz6_6_backup_restore_dr.sh:12:REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_6_REAL_IMPLEMENTATION_AUDIT.md"
./scripts/test_faz6_6_backup_restore_dr.sh:79:check_grep "6-6.1 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_6_1_BACKUP_INVENTORY_STATUS=READY"
./scripts/test_faz6_6_backup_restore_dr.sh:80:check_grep "6-6.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_6_2_RESTORE_DRILL_STATUS=READY"
./scripts/test_faz6_6_backup_restore_dr.sh:81:check_grep "6-6.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_6_3_RPO_RTO_STATUS=READY"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-6.8 STATUS=IMPLEMENTED_OR_PRESENT ✅

# Final Runtime Implementation Interpretation

```text
REQUIRED_FAIL=0
OPTIONAL_WARN=0
FAZ_6_6_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_6_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_7_READY=YES ✅
FAZ_6_6_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅
```
