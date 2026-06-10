# FAZ 6-9 Rollback Readiness Evidence

Generated At: 2026-05-01T15:23:35+03:00  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu script rollback calistirmaz. Sadece rollback icin gerekli kanit ve geri donus kaynaklarini listeler.

FAZ_6_9_ROLLBACK_READINESS=STARTED ✅

---


## 6-9.4.1 Git Rollback Points

```text
719fc92 clean start: production-ready code only

```

## 6-9.4.2 Backup Directories

```text
backups/gateway_edge_bind/20260418_075211
backups/gateway_edge_bind/20260418_075258
backups/gateway_edge_bind_fix
backups/gateway_edge_bind_fix/20260418_075913
backups/gateway_env
backups/gateway_jwt_default_fix
backups/gateway_jwt_default_fix/20260418_091157
backups/gateway_rate_quota_live
backups/gateway_rate_quota_live/20260418_081643
backups/gateway_rate_quota_live/20260418_083056
backups/gateway_rate_quota_live/20260418_084536
backups/gateway_rate_quota_live/20260418_090114
backups/gateway_rate_quota_restore_fix
backups/gateway_rate_quota_restore_fix_2
backups/gateway_rate_quota_restore_fix/20260418_085010
backups/gateway_rate_quota_restore_fix/20260418_085023
backups/gateway_rate_quota_restore_fix_2/20260418_085438
backups/gateway_reports
backups/gw_ingress_scan
backups/gw_ingress_scan/20260417_201007
backups/nginx
backups/nginx/faz4d
backups/nginx_gateway_ingress
backups/nginx_gateway_ingress/20260417_205007
backups/nginx_gateway_ingress/20260417_205115
backups/nginx_gateway_ingress_active
backups/nginx_gateway_ingress_active/20260417_205443
backups/nginx_gateway_internal_block
backups/nginx_gateway_internal_block/20260417_211013
backups/nginx_gateway_internal_fix
backups/nginx_gateway_internal_fix/20260417_211957
backups/panel
backups/policy_cache_hybrid
backups/redis_cache_contract
backups/redis_gateway_rate_limit
backups/redis_standardization
backups/script_backups
backups/scripts
backups/step_50
backups/step_51
```

## 6-9.4.3 Config Backup Candidates

```text
===== /etc/nginx =====
/etc/nginx/sites-available/pix2pi.bak_20260320_080106
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805
/etc/nginx/sites-available/pix2pi
/etc/nginx/sites-available/pix2pi_api_gateway
/etc/nginx/sites-available/default.bak.2026-03-19-061610
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713
/etc/nginx/sites-available/pix2pi_ssl
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931
/etc/nginx/sites-available/pix2pi.bak_20260304_115445
/etc/nginx/sites-available/pix2pi.bak_20260320_083246
/etc/nginx/sites-available/pix2pi_http_redirect
/etc/nginx/sites-available/default
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317
/etc/nginx/sites-available/pix2pi.bak_20260320_075537
/etc/nginx/sites-available/pix2pi.bak_20260320_083604
/etc/nginx/koi-utf
/etc/nginx/win-utf
/etc/nginx/koi-win
/etc/nginx/fastcgi_params
/etc/nginx/scgi_params
/etc/nginx/nginx.conf
/etc/nginx/snippets/snakeoil.conf
/etc/nginx/snippets/pix2pi_watchdog.conf
/etc/nginx/snippets/fastcgi-php.conf
/etc/nginx/snippets/pix2pi_gateway_public.conf
/etc/nginx/snippets/pix2pi_gateway_proxy_headers.conf
/etc/nginx/snippets/pix2pi_gateway_internal_block.conf
/etc/nginx/snippets/pix2pi_api.conf.bak_2026-03-15
/etc/nginx/conf.d/pix2pi_faz4d_static.conf
/etc/nginx/conf.d/pix2pi_edge_live.conf
/etc/nginx/conf.d/00_pix2pi_log_format.conf
/etc/nginx/conf.d/health.conf
/etc/nginx/mime.types
/etc/nginx/uwsgi_params
/etc/nginx/fastcgi.conf
/etc/nginx/proxy_params
===== /etc/systemd/system =====
/etc/systemd/system/pix2pi-api-gateway.service.bak
/etc/systemd/system/pix2pi-hourly-snapshot.timer
/etc/systemd/system/pix2pi-accounting.service
/etc/systemd/system/pix2pi-service-discovery.service
/etc/systemd/system/snap-core20-2769.mount
/etc/systemd/system/pix2pi-service-discovery.service.bak
/etc/systemd/system/pix2pi-query-read-model.service
/etc/systemd/system/snap.lxd.daemon.unix.socket
/etc/systemd/system/pix2pi-accounting.service.bak
/etc/systemd/system/snap.lxd.user-daemon.service
/etc/systemd/system/snap-lxd-38469.mount
/etc/systemd/system/pix2pi-query-read-model.service.bak
/etc/systemd/system/snap-snapd-26865.mount
/etc/systemd/system/pix2pi-watchdog.service
/etc/systemd/system/pix2pi-realtime-runtime.service
/etc/systemd/system/pix2pi-auth.service
/etc/systemd/system/pix2pi-backup-retention.service
/etc/systemd/system/pix2pi-user-created-consumer.service
/etc/systemd/system/snap.lxd.user-daemon.unix.socket
/etc/systemd/system/snap-snapd-26382.mount
/etc/systemd/system/pix2pi-daily-backup.service
/etc/systemd/system/pix2pi-incident-audit-runtime.service
/etc/systemd/system/pix2pi-runtime-topology.service
/etc/systemd/system/snap-ngrok-380.mount
/etc/systemd/system/snap.lxd.activate.service
/etc/systemd/system/pix2pi-hourly-snapshot.service
/etc/systemd/system/pix2pi-identity.service
/etc/systemd/system/snap-ngrok-385.mount
/etc/systemd/system/snap-core22-2411.mount
/etc/systemd/system/pix2pi-early-warning-runtime.service
/etc/systemd/system/pix2pi-webhook-runtime.service
/etc/systemd/system/pix2pi-identity.service.bak_20260304_163601
/etc/systemd/system/pix2pi-cleanup.timer
/etc/systemd/system/pix2pi-cleanup.service
/etc/systemd/system/pix2pi-notification-runtime.service
/etc/systemd/system/ollama.service
/etc/systemd/system/snap-lxd-38800.mount
/etc/systemd/system/snap-tree-54.mount
/etc/systemd/system/snap-core22-2339.mount
/etc/systemd/system/pix2pi-panel.service
/etc/systemd/system/pix2pi-jobs-runtime.service
/etc/systemd/system/pix2pi-plugin-runtime.service
/etc/systemd/system/pix2pi-api-gateway.service
/etc/systemd/system/pix2pi-workflow-runtime.service
/etc/systemd/system/pix2pi-publicapi-runtime.service
/etc/systemd/system/pix2pi-backup-retention.timer
/etc/systemd/system/pix2pi-daily-backup.timer
/etc/systemd/system/sshd-keygen@.service.d/disable-sshd-keygen-if-cloud-init-active.conf
/etc/systemd/system/snap.lxd.daemon.service
/etc/systemd/system/pix2pi-mission-control.service.bak_20260424_122839
/etc/systemd/system/pix2pi-panel.service.bak_20260304_165847
/etc/systemd/system/pix2pi-service-registry.service
/etc/systemd/system/pix2pi-backup.service
/etc/systemd/system/pix2pi-mission-control.service
/etc/systemd/system/pix2pi-accounting.service.bak_20260413_225444
/etc/systemd/system/snap-core20-2717.mount
===== /etc/pix2pi =====
/etc/pix2pi/ports.env.bak_publicapi_runtime_20260424_150957
/etc/pix2pi/ports.env.bak_plugin_runtime_20260424_145033
/etc/pix2pi/ports.env.bak_jobs_runtime_20260424_125407
/etc/pix2pi/ports.env.bak_jobs_runtime_20260424_125308
/etc/pix2pi/ports.env.bak_early_warning_runtime_20260424_231800
/etc/pix2pi/ports.env.save
/etc/pix2pi/ports.env
/etc/pix2pi/ports.env.bak_mission_20260424_122839
/etc/pix2pi/ports.env.bak_early_warning_runtime_20260424_231928
/etc/pix2pi/ports.env.bak_runtime_topology_20260425_001225
/etc/pix2pi/ports.env.bak_incident_audit_runtime_20260424_234731
/etc/pix2pi/ports.env.bak_20260424_120249
/etc/pix2pi/ports.env.bak_realtime_runtime_20260425_004354
/etc/pix2pi/ports.env.bak_webhook_runtime_20260424_135224
/etc/pix2pi/ports.env.bak_workflow_runtime_20260424_141956
/etc/pix2pi/ports.env.bak_notification_runtime_20260424_163946
/etc/pix2pi/ports.env.bak_20260304_170000
===== /opt/pix2pi/orchestrator/env =====
/opt/pix2pi/orchestrator/env/common.env.bak.2026-04-11_070403
/opt/pix2pi/orchestrator/env/common.env
/opt/pix2pi/orchestrator/env/common.env.bak.2026-04-11_135332
/opt/pix2pi/orchestrator/env/common.env.bak_2026-04-12_173627
```

## 6-9.4.4 DB Backup / Restore Candidates

```text
./kernel_legacy_file_backup
./backups/faz3_9_11_1f_fiscal_sequence_rls_test_20260426_062149/fiscal_before_rls_test.tar.gz
./backups/faz3_12_3a_erp_runtime_gateway_mount_plan_20260426_191023/apisurface_before_gateway_mount_plan.tar.gz
./backups/faz3_12_3a_erp_runtime_gateway_mount_plan_20260426_191023/docs_api_before_gateway_mount_plan.tar.gz
./backups/faz3_10_3d_erp_runtime_docnumber_muhur_20260426_064310/docs_erp_before_docnumber_muhur.tar.gz
./backups/faz3_10_3d_erp_runtime_docnumber_muhur_20260426_064310/docnumber_before_muhur.tar.gz
./backups/faz3_11_3b_erp_runtime_e2e_flow_step_adapters_20260426_081359/e2eflow_before_step_adapters.tar.gz
./backups/faz3_9_7_4b_ledger_balance_repository_test_20260425_214337/ledger_before_balance_repository_test.tar.gz
./backups/faz3_9_1_2a_schema_backup_20260425_075810/schema_before_master_party.sql
./backups/faz3_10_1b_erp_runtime_kernel_default_impl_20260426_063447/erp_runtime_kernel_before_default_impl.tar.gz
./backups/faz3_12_4a_erp_runtime_api_gateway_final_smoke_20260426_193123/runtime_before_12_4a_final_smoke.tar.gz
./backups/faz3_12_4a_erp_runtime_api_gateway_final_smoke_20260426_193123/docs_api_before_12_4a_final_smoke.tar.gz
./backups/faz3_12_4a_erp_runtime_api_gateway_final_smoke_20260426_193123/docs_erp_before_12_4a_final_smoke.tar.gz
./backups/faz3_12_4a_erp_runtime_api_gateway_final_smoke_20260426_193123/test_logs/critical_e2eflow_store_bridge_smoke.log
./backups/faz3_12_4a_erp_runtime_api_gateway_final_smoke_20260426_193123/test_logs/apisurface_full.log
./backups/faz3_12_4a_erp_runtime_api_gateway_final_smoke_20260426_193123/test_logs/critical_api_gateway_smoke.log
./backups/faz3_12_4a_erp_runtime_api_gateway_final_smoke_20260426_193123/test_logs/e2eflow_full.log
./backups/faz3_9_1_6a_postgres_contact_repository_20260425_081956/masterparty_before_contact_repository.tar.gz
./backups/gw_ingress_scan/20260417_201007/sites-available/pix2pi
./backups/gw_ingress_scan/20260417_201007/sites-available/pix2pi_api_gateway
./backups/gw_ingress_scan/20260417_201007/sites-available/pix2pi_ssl
./backups/gw_ingress_scan/20260417_201007/sites-available/pix2pi_http_redirect
./backups/gw_ingress_scan/20260417_201007/sites-available/default
./backups/gw_ingress_scan/20260417_201007/nginx.conf
./backups/gw_ingress_scan/20260417_201007/snippets/snakeoil.conf
./backups/gw_ingress_scan/20260417_201007/snippets/pix2pi_watchdog.conf
./backups/gw_ingress_scan/20260417_201007/snippets/fastcgi-php.conf
./backups/gw_ingress_scan/20260417_201007/conf.d/health.conf
./backups/faz3_9_5_6a_procurement_full_smoke_20260425_210832/procurement_migrations_before_full_smoke.tar.gz
./backups/faz3_9_5_6a_procurement_full_smoke_20260425_210832/procurement_before_full_smoke.tar.gz
./backups/faz3_9_10_5b_payment_transaction_repository_test_20260426_061544/cashbank_before_payment_transaction_repository_test.tar.gz
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/etc_nginx_before_fix2.tar.gz
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/logs/local_panel_sha256.txt
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/logs/local_http_host_panel_headers.txt
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/logs/asset_candidates.txt
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/logs/public_panel.html
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/logs/public_panel_headers.txt
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/logs/sites_enabled_active.log
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/logs/body_compare.log
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/logs/local_https_host_panel.html
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/logs/local_http_host_panel.html
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/logs/local_https_host_panel_headers.txt
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/docs_before_fix2.tar.gz
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/opt_pix2pi_nginx_before_fix2.tar.gz
./backups/faz3_9_7_1d_ledger_db_test_20260425_213403/ledger_before_db_test.tar.gz
./backups/faz3_9_1_4b_customer_repository_test_20260425_081609/masterparty_before_customer_repository_test.tar.gz
./backups/nginx_gateway_ingress/20260417_205007/sites-available.bak/pix2pi
./backups/nginx_gateway_ingress/20260417_205007/sites-available.bak/pix2pi_api_gateway
./backups/nginx_gateway_ingress/20260417_205007/sites-available.bak/pix2pi_ssl
./backups/nginx_gateway_ingress/20260417_205007/sites-available.bak/pix2pi_http_redirect
./backups/nginx_gateway_ingress/20260417_205007/sites-available.bak/default
./backups/nginx_gateway_ingress/20260417_205007/snippets.bak/snakeoil.conf
./backups/nginx_gateway_ingress/20260417_205007/snippets.bak/pix2pi_watchdog.conf
./backups/nginx_gateway_ingress/20260417_205007/snippets.bak/fastcgi-php.conf
./backups/nginx_gateway_ingress/20260417_205115/sites-available.bak/pix2pi
./backups/nginx_gateway_ingress/20260417_205115/sites-available.bak/pix2pi_api_gateway
./backups/nginx_gateway_ingress/20260417_205115/sites-available.bak/pix2pi_ssl
./backups/nginx_gateway_ingress/20260417_205115/sites-available.bak/pix2pi_http_redirect
./backups/nginx_gateway_ingress/20260417_205115/sites-available.bak/default
./backups/nginx_gateway_ingress/20260417_205115/snippets.bak/snakeoil.conf
./backups/nginx_gateway_ingress/20260417_205115/snippets.bak/pix2pi_watchdog.conf
./backups/nginx_gateway_ingress/20260417_205115/snippets.bak/fastcgi-php.conf
./backups/faz4_14_1_1_step24_20260427_072751/scripts/test_phase4_migration_chain_standard.sh
./backups/event_bus_lifecycle_sync/event_bus_store_lifecycle_test_main.go.retryfix_20260416_194728
./backups/event_bus_lifecycle_sync/event_bus_service.go.retryfix_20260416_194513
./backups/event_bus_lifecycle_sync/event_bus_store_lifecycle_test_main.go.retryfix_20260416_194710
./backups/faz3_13_1b_gateway_erp_runtime_mount_adapter_20260426_222905/docs_before_erp_runtime_mount_adapter.tar.gz
./backups/faz3_13_1b_gateway_erp_runtime_mount_adapter_20260426_222905/cmd_api_gateway_before_erp_runtime_mount_adapter.tar.gz
./backups/faz3_13_1b_gateway_erp_runtime_mount_adapter_20260426_222905/apisurface_before_erp_runtime_mount_adapter.tar.gz
./backups/faz4b_16_1_pilot_uat_onboarding_baseline_20260430_061051/docs/phase4/16_1_pilot_uat_onboarding_baseline_policy.md
./backups/faz4b_16_1_pilot_uat_onboarding_baseline_20260430_061051/docs/phase4/16_1_pilot_uat_onboarding_baseline_standard.md
./backups/faz4b_16_1_pilot_uat_onboarding_baseline_20260430_061051/docs/phase4/16_1_onboarding_checklist.tsv
./backups/faz4b_16_1_pilot_uat_onboarding_baseline_20260430_061051/docs/phase4/16_1_pilot_scope_inventory.tsv
./backups/faz4b_16_1_pilot_uat_onboarding_baseline_20260430_061051/docs/phase4/16_1_rollout_gate_matrix.tsv
./backups/faz4b_16_1_pilot_uat_onboarding_baseline_20260430_061051/docs/phase4/16_1_pilot_uat_onboarding_baseline_matrix.tsv
./backups/faz4b_16_1_pilot_uat_onboarding_baseline_20260430_061051/docs/phase4/16_1_uat_scenario_catalog.tsv
./backups/faz4b_16_1_pilot_uat_onboarding_baseline_20260430_061051/docs/phase4/16_1_pilot_uat_onboarding_baseline_report.md
./backups/faz4b_16_1_pilot_uat_onboarding_baseline_20260430_061051/scripts/phase4b_pilot_uat_onboarding_baseline.py
./backups/faz4b_16_1_pilot_uat_onboarding_baseline_20260430_061051/scripts/test_phase4b_pilot_uat_onboarding_baseline.sh
./backups/faz4b_16_1_pilot_uat_onboarding_baseline_20260430_061051/scripts/phase4b_pilot_uat_onboarding_baseline.sh
./backups/faz4b_15_6_materialized_cache_projection_standard_20260428_075747/docs/phase4/15_6_materialized_cache_projection_report.md
./backups/faz4b_15_6_materialized_cache_projection_standard_20260428_075747/docs/phase4/15_6_materialized_cache_projection_standard.md
./backups/faz4b_15_6_materialized_cache_projection_standard_20260428_075747/docs/phase4/15_6_materialized_cache_projection_candidate_execution.sh
./backups/faz4b_15_6_materialized_cache_projection_standard_20260428_075747/docs/phase4/15_6_materialized_cache_projection_matrix.tsv
./backups/faz4b_15_6_materialized_cache_projection_standard_20260428_075747/docs/phase4/15_6_materialized_cache_projection_manifest.tsv
./backups/faz4b_15_6_materialized_cache_projection_standard_20260428_075747/scripts/test_phase4b_materialized_cache_projection_standard.sh
./backups/faz4b_15_6_materialized_cache_projection_standard_20260428_075747/scripts/phase4b_materialized_cache_projection_standard.sh
./backups/faz4b_15_6_materialized_cache_projection_standard_20260428_075747/scripts/phase4b_materialized_cache_projection_standard.py
./backups/faz4b_15_6_materialized_cache_projection_standard_20260428_075747/config/projection/materialized_cache_projection_manifest.tsv
./backups/faz3_9_6_5a_journal_full_smoke_20260425_213005/journal_migrations_before_full_smoke.tar.gz
./backups/faz3_9_6_5a_journal_full_smoke_20260425_213005/journal_before_full_smoke.tar.gz
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/docs/phase4/21_5_support_super_admin_boundary_rule_manifest.tsv
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/docs/phase4/21_5_support_super_admin_boundary_reason_manifest.tsv
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/docs/phase4/21_5_support_super_admin_boundary_matrix.tsv
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/docs/phase4/21_5_support_super_admin_boundary_standard.md
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/docs/phase4/21_5_support_super_admin_boundary_decision_manifest.tsv
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/docs/phase4/21_5_support_super_admin_boundary_report.md
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/docs/phase4/21_5_support_super_admin_boundary_contract.md
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/scripts/phase4b_support_super_admin_boundary.py
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/scripts/test_phase4b_support_super_admin_boundary.sh
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/scripts/phase4b_support_super_admin_boundary.sh
./backups/faz3_9_10_4a_postgres_bank_account_repository_20260426_061330/cashbank_before_bank_account_repository.tar.gz
./backups/faz3_9_5_3b_purchase_order_repository_test_20260425_210314/procurement_before_purchase_order_repository_test.tar.gz
./backups/faz3_9_11_3b_fiscal_year_repository_test_20260426_062629/fiscal_before_fiscal_year_repository_test.tar.gz
./backups/faz3_9_10_1b_cashbank_contract_test_20260426_060537/cashbank_before_contract_test.tar.gz
./backups/faz3_9_10_1b_cashbank_contract_test_20260426_060537/cashbank_migrations_before_contract_test.tar.gz
./backups/faz3_9_6_4c_journal_posting_cleanup_fix_20260425_212920/journal_before_cleanup_fix.tar.gz
./backups/faz3_11_1f_erp_runtime_e2e_flow_db_rls_test_20260426_080448/e2eflow_before_db_rls_test.tar.gz
./backups/faz4_15_3R_dry_run_exit_fix_20260427_180030/docs/phase4/15_3_readmodel_controlled_apply_report.md
./backups/faz4_15_3R_dry_run_exit_fix_20260427_180030/scripts/test_phase4_readmodel_controlled_apply.sh
./backups/faz4_15_3R_dry_run_exit_fix_20260427_180030/scripts/phase4_readmodel_controlled_apply.sh
./backups/faz4_14_1_1_step9_20260427_071244/scripts/phase4_validate_migration_chain.sh
./backups/faz3_9_8_1f_chart_of_accounts_rls_test_20260425_215106/chartofaccounts_before_rls_test.tar.gz
./backups/faz4_14_1_1_step15_20260427_071539/scripts/phase4_validate_migration_chain.sh
./backups/faz3_9_3_2b_inventory_validation_test_20260425_195936/inventory_before_validation_test.tar.gz
./backups/faz3_9_11_6a_postgres_document_number_allocation_repository_20260426_063039/fiscal_before_document_number_allocation_repository.tar.gz
./backups/faz3_10_7c_erp_runtime_tax_postgres_store_20260426_071825/taxcalc_before_postgres_store.tar.gz
./backups/faz3_11_1d_erp_runtime_e2e_flow_migration_apply_20260426_080209/e2eflow_before_e2e_flow_apply.tar.gz
./backups/faz3_11_1d_erp_runtime_e2e_flow_migration_apply_20260426_080209/migrations_before_e2e_flow_apply.tar.gz
./backups/faz3_9_10_3b_cash_account_repository_test_20260426_061217/cashbank_before_cash_account_repository_test.tar.gz
./backups/faz4_14_1_4A_real_dsn_repair_20260427_074950/.env
./backups/faz4b_18_3R_sales_document_line_trace_fix_20260428_082012/docs/phase4/18_3_sales_stock_decrement_inventory.tsv
./backups/faz4b_18_3R_sales_document_line_trace_fix_20260428_082012/docs/phase4/18_3_sales_stock_decrement_report.md
./backups/faz4b_18_3R_sales_document_line_trace_fix_20260428_082012/docs/phase4/18_3_sales_stock_decrement_matrix.tsv
./backups/faz4b_18_3R_sales_document_line_trace_fix_20260428_082012/docs/phase4/18_3_sales_stock_decrement_standard.md
./backups/faz4b_18_3R_sales_document_line_trace_fix_20260428_082012/scripts/phase4b_sales_stock_decrement.sh
./backups/faz4b_18_3R_sales_document_line_trace_fix_20260428_082012/scripts/test_phase4b_sales_stock_decrement.sh
./backups/faz4b_18_3R_sales_document_line_trace_fix_20260428_082012/scripts/phase4b_sales_stock_decrement.py
./backups/faz4b_18_3R_sales_document_line_trace_fix_20260428_082012/db/migrations/20260428_183001_inventory_sales_stock_decrement.up.sql
./backups/faz4b_18_3R_sales_document_line_trace_fix_20260428_082012/db/migrations/20260428_183001_inventory_sales_stock_decrement.down.sql
./backups/faz4_15_2R_dirty_bool_fix_20260427_175250/docs/phase4/15_2_readmodel_apply_gate_report.md
./backups/faz4_15_2R_dirty_bool_fix_20260427_175250/scripts/phase4_readmodel_apply_gate.sh
./backups/faz4_15_2R_dirty_bool_fix_20260427_175250/scripts/test_phase4_readmodel_apply_gate.sh
./backups/faz5/20260501_112407_fix_5_2_test_script/test_5_2_packages_pricing_architecture.sh
./backups/faz5/20260501_111842_faz5_master_plan/test_faz5_master_plan.sh
./backups/faz5/20260501_111842_faz5_master_plan/faz5_master_plan.md
./backups/faz5/20260501_111905_faz5_master_plan/test_faz5_master_plan.sh
./backups/faz5/20260501_111905_faz5_master_plan/faz5_master_plan.md
./backups/faz3_10_3b_erp_runtime_document_number_allocator_default_impl_20260426_064049/docnumber_before_default_impl.tar.gz
./backups/faz3_9_11_5b_document_sequence_repository_test_20260426_062942/fiscal_before_document_sequence_repository_test.tar.gz
./backups/faz3_10_6b_erp_runtime_cashbank_payment_default_impl_20260426_070419/cashbankpay_before_default_impl.tar.gz
./backups/faz3_9_4_3b_sales_quotation_repository_test_20260425_202004/sales_before_quotation_repository_test.tar.gz
./backups/faz3_9_10_1d_cashbank_db_test_20260426_060705/cashbank_before_db_test.tar.gz
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/control_panel_ui_before_14_3c.tar.gz
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/apisurface_contract_final.log
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/panel_headers.txt
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/direct_payload.json
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/direct_headers.txt
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/direct_body.json
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/panel_payload.json
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/gateway_health_live.json
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/panel_body.json
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/panel_live_html.html
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/gateway_contract_final.log
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/token.txt
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/post_health.json
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/panel_live_headers.txt
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/make_header_cleanup_final_token.go
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/runtime_before_14_3c.tar.gz
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/etc_nginx_before_14_3c.tar.gz
```

## 6-9.4.5 Public Static Backup Candidates

```text
/var/www/pix2pi/faz5/pricing/index.html
/var/www/pix2pi/faz5/developer/index.html
/var/www/pix2pi/faz5/index.html
/var/www/pix2pi/faz4d/pilot-go-live/index.html
/opt/pix2pi/scripts/backup/pix2pi_restic_verify.sh
/opt/pix2pi/runtime/auto_heal/backups/pix2pi_auto_heal.sh.bak_20260320_093907
/opt/pix2pi/nginx/panel_index.html.bak_2026-03-15_links.bak_20260320_083246
/opt/pix2pi/nginx/panel_index.html.bak_restore_1773986596
/opt/pix2pi/nginx/panel_index.html.bak_step_368_20260320_091157
/opt/pix2pi/nginx/panel_index.html.bak_dom_fix_1773987236
/opt/pix2pi/nginx/panel_index.html.bak_20260320_084747
/opt/pix2pi/nginx/panel_index.html.bak_20260320_083604
/opt/pix2pi/nginx/panel_index.html.bak_2026-03-15_links
/opt/pix2pi/nginx/panel_index.html
/opt/pix2pi/nginx/panel_index.html.bak_render_fix_1773985752
/opt/pix2pi/nginx/panel_index.html.bak_clean_1773985983
/opt/pix2pi/nginx/panel_index.html.bak_status_engine_1773987607
```

## 6-9.4.6 Rollback Smoke Command Reminder

```text
After rollback: run scripts/pix2pi_postdeploy_smoke.sh
Before nginx reload: nginx -t
Before DB restore: confirm backup and target environment
```

## Rollback Readiness Final Seal

```text
FAZ_6_9_ROLLBACK_READINESS_STATUS=COMPLETE ✅
ROLLBACK_DESTRUCTIVE_ACTION=NO ✅
```
