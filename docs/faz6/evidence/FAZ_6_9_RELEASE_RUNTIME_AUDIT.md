# FAZ 6-9 Release Runtime Audit Evidence

Generated At: 2026-05-01T15:23:33+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit release / rollback / deploy safety runtime izlerini toplar. Deploy veya rollback yapmaz.

FAZ_6_9_RUNTIME_AUDIT=STARTED ✅

---


## 6-9.1 Host / Kernel

```text
Linux vm12827.ovadns.com 5.15.0-176-generic #186-Ubuntu SMP Fri Mar 13 11:01:42 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
```

## 6-9.2 Git / Release Inventory

```text
719fc92
 M .env
 M cmd/accounting-service/accounting_service_main.go
 M cmd/api-gateway/api_gateway_main.go
 M cmd/cache-service/cache_service_main.go
 M cmd/control-panel/control_panel.go
 M cmd/control-panel/ui/index.html
 D cmd/control-panel/ui/mission-control.html
 M cmd/event-consumer/event_consumer_main.go
 D cmd/identity-api/identity_main.go
 M cmd/mission-control/mission_control_main.go
 D create_erp_structure.sh
 M go.mod
 M go.sum
 M identity-api
 M infra/observability/promtail/data/positions.yaml
 M internal/erp/core/audit/service/erp_financial_consistency_service.go
 M internal/erp/core/journal/service/erp_journal_builder_service.go
 M internal/erp/core/ledger/service/erp_ledger_posting_service.go
 M internal/erp/core/reconciliation/service/erp_reconciliation_service.go
 M internal/erp/core/rules/service/erp_accounting_rule_service.go
 M internal/erp/core/ufk/domain/erp_ledger_account.go
 M internal/erp/core/ufk/service/erp_ledger_posting_service.go
 M internal/platform/audit/domain/audit_log.go
 M internal/platform/audit/service/audit_log_service.go
 M internal/platform/auth/middleware/jwt_middleware.go
 M internal/platform/auth/service/jwt_service.go
 M internal/platform/cache/service/redis_cache_service.go
 M internal/platform/db/migrator.go
 M internal/platform/db/tenant_db.go
 M internal/platform/db/tenant_tx.go
 M internal/platform/dlq.go
 M internal/platform/dlq_test.go
 M internal/platform/eventbus/domain/event_message.go
 M internal/platform/eventbus/service/event_bus_service.go
 M internal/platform/eventstore/domain/event_store_record.go
 D internal/platform/eventstore/service/event_replay_service.go
 M internal/platform/eventstore/service/event_store_service.go
 M internal/platform/gateway/service/rate_limit_service.go
 M internal/platform/kernel/policy_cache.go
 M internal/platform/kernel/tenant_context.go
 M internal/platform/kernel/tenant_guard.go
 M internal/services/query_read_model/service.go
 M pix2pi-api-gateway
 D step_100_backup_run_api_gateway_script.sh
 D step_101_test_identity_gateway_ports.sh
 D step_102_backup_api_gateway_before_rewrite.sh
 D step_103_restart_api_gateway.sh
 D step_104_test_gateway_identity_rewrite.sh
 D step_105_backup_api_gateway_before_rate_limit.sh
 D step_106_restart_api_gateway_after_rate_limit.sh
 D step_107_test_api_gateway_rate_limit.sh
 D step_108_backup_api_gateway_before_tenant_middleware.sh
 D step_109_restart_api_gateway_after_tenant_middleware.sh
 D step_10_run_tenant_event_pipeline_test.sh
 D step_110_test_gateway_tenant_middleware.sh
 D step_111_backup_api_gateway_before_redis_rate_limit.sh
 D step_112_check_redis_before_gateway_limit.sh
 D step_112a_install_redis_tools.sh
 D step_113_add_go_redis_dependency.sh
 D step_114_restart_api_gateway_after_redis_rate_limit.sh
 D step_115_test_gateway_redis_rate_limit.sh
 D step_116_backup_api_gateway_before_auth_route.sh
 D step_117_check_auth_service_9002.sh
 D step_11_backup_tenant_service_filter.sh
 D step_121_create_auth_api_dir.sh
 D step_122_run_auth_api.sh
 D step_123_test_auth_api_local.sh
 D step_124_test_auth_via_gateway.sh
 D step_125_restart_gateway_after_auth_route.sh
 D step_126_backup_api_gateway_before_combined_gateway.sh
 D step_127_restart_combined_gateway.sh
 D step_128_test_combined_gateway.sh
 D step_129_test_scope_separation.sh
 D step_12_run_tenant_service_filter_test.sh
 D step_130_backup_gateway_before_authz_layer.sh
 D step_130_backup_nginx_before_rate_limit.sh
 D step_131_add_nginx_global_rate_limit.sh
 D step_131_restart_gateway_after_bearer_tenant_match.sh
 D step_132_enable_rate_limit_api_domain.sh
 D step_132_test_gateway_bearer_tenant_match.sh
 D step_133_reload_nginx_after_rate_limit.sh
 D step_134_check_503_source.sh
 D step_135_check_nginx_error_log.sh
 D step_136_backup_fail2ban_before_nginx_jail.sh
 D step_13_backup_redis_tenant_namespace.sh
 D step_14_prepare_cache_dir.sh
 D step_15_run_redis_tenant_namespace_test.sh
 D step_160_install_nats_event_bus.sh
 D step_161_check_nats_health.sh
 D step_162_add_nats_go_client.sh
 D step_163_prepare_nats_publisher_folder.sh
 D step_164_prepare_nats_subscriber_folder.sh
 D step_165_run_nats_subscriber.sh
 D step_166_run_nats_publisher.sh
 D step_16_backup_super_admin_policy.sh
 D step_170_check_jetstream.sh
 D step_171_run_nats_cli.sh
 D step_172_create_jetstream_stream.sh
 D step_173_check_jetstream_stream.sh
 D step_174_create_sale_consumer.sh
 D step_175_check_sale_consumer.sh
 D step_17_prepare_security_dir.sh
 D step_181_prepare_stock_service_folder.sh
 D step_181_stok_servisi_klasor.sh
 D step_182_run_stock_service.sh
 D step_183_run_accounting_service.sh
 D step_184_backup_panel_before_service_monitor.sh
 D step_185_create_service_status_snapshot_script.sh
 D step_186_rewrite_panel_with_service_monitor.sh
 D step_187_create_service_status_cron.sh
 D step_188_list_sh_files.sh
 D step_188_prepare_cache_service_folder.sh
 D step_188_verify_done_items.sh
 D step_189_check_jetstream_streams.sh
 D step_189_run_cache_service.sh
 D step_18_run_super_admin_policy_test.sh
 D step_190_reporting_subscriber_kur_ve_calistir.sh
 D step_190_test_cache_service.sh
 D step_191_prepare_idempotency_folder.sh
 D step_191_reporting_service_arka_plan_panel.sh
 D step_192_add_idempotency_test_deps.sh
 D step_192_reporting_service_panelde_goster.sh
 D step_193_panel_dosyasini_bul_patch_et.sh
 D step_193_test_idempotency.sh
 D step_194_panel_html_reporting_service_ekle.sh
 D step_194_test_retry.sh
 D step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh
 D step_195_test_dlq.sh
 D step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh
 D step_196_run_replay_service.sh
 D step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh
 D step_198_reporting_service_json_sabitle.sh
 D step_199_fix_panel_reporting_service.sh
 D step_19_backup_postgres_rls.sh
 D step_1_backup_account_mapping.sh
 D step_1_backup_accounts_import.sh
 D step_1_backup_accounts_seed.sh
 D step_1_backup_alis_faturasi_engine.sh
 D step_1_backup_auto_rules.sh
 D step_1_backup_balance_sheet.sh
 D step_1_backup_banka_ekstre.sh
 D step_1_backup_banka_engine.sh
 D step_1_backup_bilanco_engine.sh
 D step_1_backup_cari_ekstre.sh
 D step_1_backup_cash_flow.sh
 D step_1_backup_chart_intelligence.sh
 D step_1_backup_commission_engine.sh
 D step_1_backup_commission_rule_versioning.sh
 D step_1_backup_current_account_engine.sh
 D step_1_backup_financial_consistency.sh
 D step_1_backup_financial_event_engine.sh
 D step_1_backup_gelir_tablosu_engine.sh
 D step_1_backup_general_ledger.sh
 D step_1_backup_income_statement.sh
 D step_1_backup_journal_builder.sh
 D step_1_backup_journal_engine.sh
 D step_1_backup_kasa_ekstre.sh
 D step_1_backup_kasa_engine.sh
 D step_1_backup_ledger_balance_engine.sh
 D step_1_backup_ledger_engine.sh
 D step_1_backup_ledger_posting_engine.sh
 D step_1_backup_merchant_payout_engine.sh
 D step_1_backup_mizan_engine.sh
 D step_1_backup_multi_account_ledger.sh
 D step_1_backup_payment_engine.sh
 D step_1_backup_period_closing.sh
 D step_1_backup_reconciliation_engine.sh
 D step_1_backup_satis_fatura_engine.sh
 D step_1_backup_settlement_engine.sh
 D step_1_backup_tahsilat_odeme_engine.sh
 D step_1_backup_tahsilat_odeme_v2.sh
 D step_1_backup_tax_engine.sh
 D step_1_backup_tenant_test.sh
 D step_1_backup_trial_balance.sh
 D step_1_backup_ufk_engine.sh
 D step_1_backup_ufk_event_engine.sh
 D step_1_backup_ufk_event_journal.sh
 D step_1_backup_wallet_transfer_engine.sh
 D step_200_create_event_store_table.sql
 D step_201_apply_event_store.sh
 D step_201_hybrid_service_discovery_kur.sh
 D step_202_query_read_model_kur_ve_test_et.sh
 D step_202_test_event_store.sh
 D step_203_create_journal_tables.sql
 D step_203_reporting_to_query_read_model_bagla.sh
 D step_204_apply_journal_tables.sh
 D step_204_panel_service_discovery_query_read_model_ekle.sh
 D step_205_fix_snapshot_process_bazli.sh
 D step_205_prepare_journal_builder_folder.sh
 D step_206_servis_yoneticisi_kur.sh
 D step_206_test_journal_builder.sh
 D step_207_service_manager_panel_guncelle_ekle.sh
 D step_207_test_journal_repository.sh
 D step_20_prepare_sql_dir.sh
 D step_210_audit_full.sh
 D step_210_prepare_audit_folder.sh
 D step_211_test_audit_engine.sh
 D step_21_run_postgres_rls_test.sh
 D step_220_tax_engine_full.sh
 D step_22_check_postgres_rls_env.sh
 D step_230_create_snapshot_tables.sql
 D step_230_snapshot_schema.sh
 D step_231_snapshot_full.sh
 D step_232_run_snapshot_flow.sh
 D step_23_check_postgres_runtime.sh
 D step_240_enable_rls_snapshots.sh
 D step_240_enable_rls_snapshots.sql
 D step_241_test_rls_snapshots.sh
 D step_242_create_app_user.sh
 D step_243_test_rls_real.sh
 D step_244_fix_app_user.sh
 D step_245_fix_password.sh
 D step_246_grant_snapshot_sequence.sh
 D step_24_start_postgres_runtime.sh
 D step_250_tenant_isolation_verification.sh
 D step_251_fix_verification.sh
 D step_25_check_postgres_password.sh
 D step_260_audit_schema.sh
 D step_260_create_audit_tables.sql
 D step_261_audit_full.sh
 D step_262_run_audit_flow.sh
 D step_26_test_postgres_login.sh
 D step_270_observability_stack.sh
 D step_271_run_observability_stack.sh
 D step_272_test_observability_stack.sh
 D step_273_fix_promtail_positions.sh
 D step_274_restart_observability.sh
 D step_275_test_promtail_positions.sh
 D step_276_reduce_log_noise.sh
 D step_277_fix_snapshot_frequency.sh
 D step_278_loki_limit.sh
 D step_279_find_snapshot_source.sh
 D step_27_check_postgres_container_user.sh
 D step_280_fix_snapshot_logging.sh
 D step_281_logrotate_snapshot.sh
 D step_282_fix_promtail_paths.sh
 D step_283_disable_snapshot_logging.sh
 D step_284_remove_snapshot_from_promtail.sh
 D step_28_backup_audit_log_engine.sh
 D step_290_monitor_core.sh
 D step_291_watchdog_service.sh
 D step_292_run_watchdog.sh
 D step_293_fix_watchdog_nginx.sh
 D step_294_find_real_nginx_route.sh
 D step_295_find_panel_monitor_source.sh
 D step_296_fix_nginx_monitor_route.sh
 D step_297_fix_nginx_monitor_route_proper.sh
 D step_298_cleanup_nginx_backup.sh
 D step_299_rewrite_pix2pi_ssl_with_watchdog.sh
 D step_29_prepare_audit_dirs.sh
 D step_2_prepare_account_mapping_dir.sh
 D step_2_prepare_alis_dirs.sh
 D step_2_prepare_banka_dirs.sh
 D step_2_prepare_cari_dirs.sh
 D step_2_prepare_chart_intelligence_dir.sh
 D step_2_prepare_events_dirs.sh
 D step_2_prepare_finance_service_dir.sh
 D step_2_prepare_journal_dirs.sh
 D step_2_prepare_journal_service_dir.sh
 D step_2_prepare_kasa_dirs.sh
 D step_2_prepare_ledger_dirs.sh
 D step_2_prepare_ledger_service_dir.sh
 D step_2_prepare_payment_dir.sh
 D step_2_prepare_payments_dirs.sh
 D step_2_prepare_rapor_dirs.sh
 D step_2_prepare_reconciliation_dir.sh
 D step_2_prepare_reporting_dir.sh
 D step_2_prepare_rules_dirs.sh
 D step_2_prepare_satis_dirs.sh
 D step_2_prepare_tahsilat_dirs.sh
 D step_2_prepare_tax_dir.sh
 D step_2_run_commission_engine.sh
 D step_2_run_tenant_test.sh
 D step_300_remove_duplicate_nginx_sites.sh
 D step_301_orchestrator_foundation.sh
 D step_302_test_orchestrator_foundation.sh
 D step_303_fix_systemd_units.sh
 D step_304_start_all_services.sh
 D step_305_detect_running_processes.sh
 D step_306_kill_legacy_strict.sh
 D step_307_check_nginx_master_workers.sh
 D step_308_hard_restart_nginx.sh
 D step_309_find_real_nginx_listens.sh
 D step_30_run_audit_log_engine_test.sh
 D step_310_find_source_files.sh
 D step_311_nginx_hard_reset.sh
 D step_312_remove_openresty.sh
 D step_313_kill_kong.sh
 D step_314_find_kong_starter.sh
 D step_315_block_openresty.sh
 D step_316_full_nginx_port_scan.sh
 D step_317_trace_real_nginx_runtime.sh
 D step_318_kill_openresty_runtime.sh
 D step_319_backup_panel_before_rewrite.sh
 D step_31_backup_export_isolation.sh
 D step_320_rewrite_panel_index.sh
 D step_321_check_panel_file.sh
 D step_323_find_status_engine.sh
 D step_324_backup_status_engine.sh
 D step_325_find_watchdog_unit.sh
 D step_326_find_watchdog_process.sh
 D step_327_backup_watchdog_before_fail_memory.sh
 D step_328_build_watchdog_fail_memory.sh
 D step_329_restart_watchdog_fail_memory.sh
 D step_32_prepare_export_dirs.sh
 D step_330_test_watchdog_status_fail_memory.sh
 D step_331_rewrite_watchdog_advanced_state_engine.sh
 D step_332_build_restart_watchdog_advanced.sh
 D step_333_test_watchdog_degraded_logic.sh
 D step_334_add_global_health_engine.sh
 D step_335_fix_hook_global_status_response.sh
 D step_335_hook_global_status_response.sh
 D step_336_force_hook_global_status_response.sh
 D step_337_inspect_watchdog_status_handler.sh
 D step_338_full_override_status_handler.sh
 D step_339_fix_status_handler_clean.sh
 D step_339_rewrite_watchdog_main.sh
 D step_33_run_export_isolation_test.sh
 D step_340_rewrite_watchdog_main_fixed_path.sh
 D step_341_fix_global_status_logic.sh
 D step_343_add_monitor_route.sh
 D step_34_backup_backup_isolation.sh
 D step_350_fix_nginx_monitor.sh
 D step_351_clean_nginx_duplicates_and_fix_monitor.sh
 D step_352_force_monitor_from_static_root.sh
 D step_353_rewrite_monitor_v2.sh
 D step_354_fix_monitor_endpoint.sh
 D step_355_fix_status_json.sh
 D step_355a_find_watchdog.sh
 D step_355b_clean_json_fix.sh
 D step_355c_safe_json_fix.sh
 D step_355d_restore_clean.sh
 D step_355e_find_last_buildable_watchdog_backup.sh
 D step_356_fix_monitor_json_compat.sh
 D step_356b_force_monitor_fix.sh
 D step_356c_safe_monitor_fix.sh
 D step_356d_force_top_fix.sh
 D step_357_rewrite_monitor_clean.sh
 D step_358_add_nginx_status_proxy.sh
 D step_358_fix_ssl_status_route.sh
 D step_35_prepare_backup_dirs.sh
 D step_360_rewrite_monitor_hardening.sh
 D step_361_fix_panel_status_manual.sh
 D step_361_fix_panel_status_source.sh
 D step_362_fix_panel_ssl_service_status.sh
 D step_363_clean_panel_ssl_routes.sh
 D step_364_bind_panel_to_service_status_json.sh
 D step_365_hard_fix_panel_render_engine.sh
 D step_366_remove_old_status_calls.sh
 D step_367_restore_clean_panel_engine.sh
 D step_368_panel_final_logic_fix.sh
 D step_369_fix_panel_dom_ids.sh
 D step_36_run_backup_isolation_test.sh
 D step_370_real_global_status.sh
 D step_371_add_early_warning_collector.sh
 D step_372_test_early_warning_collector.sh
 D step_373_add_early_warning_cron.sh
 D step_374_add_auto_heal_engine.sh
 D step_375_add_auto_heal_cron.sh
 D step_376_prepare_heal_state.sh
 D step_377_advanced_auto_heal.sh
 D step_378_add_alert_engine.sh
 D step_379_add_scale_hook.sh
 D step_37_backup_event_bus.sh
 D step_380_bind_all_crons.sh
 D step_382_dynamic_restart_patch.sh
 D step_384_create_auth_service.sh
 D step_385_systemd_health_patch.sh
 D step_386_fix_pipeline_json.sh
 D step_387_force_systemd_priority.sh
 D step_388_fix_unbound_variable.sh
 D step_389_show_early_warning_error_zone.sh
 D step_38_prepare_event_bus_dirs.sh
 D step_390_rewrite_early_warning_clean.sh
 D step_391_real_systemd_test.sh
 D step_392_production_hardening.sh
 D step_393_fix_systemd_pipeline.sh
 D step_394_force_override.sh
 D step_396_inspect_auto_heal.sh
 D step_397_fix_auto_heal_source.sh
 D step_399_fix_status_path.sh
 D step_39_run_event_bus_test.sh
 D step_3_backup_jwt_tenant.sh
 D step_3_check_period_closing.sh
 D step_3_check_ufk_engine.sh
 D step_400_verify_status_json.sh
 D step_401_enable_all_services.sh
 D step_402_fix_function_order.sh
 D step_403_fix_service_map.sh
 D step_404_scan_db_entrypoints.sh
 D step_405_backup_kernel.sh
 D step_405_test.sh
 D step_406_scan_kernel_usage.sh
 D step_407_create_query_service.sh
 D step_407_scan_db_usage.sh
 D step_407_test_query.sh
 D step_408_fix_api_gateway_nethttp_full.sh
 D step_408_full_api_integration.sh
 D step_408_test_api_gateway_nethttp.sh
 D step_408c_find_real_routes.sh
 D step_408d_verify_query_service.sh
 D step_408e_patch_gateway.sh
 D step_409_fix_gateway.sh
 D step_40_backup_event_retry.sh
 D step_410_fix_go_module.sh
 D step_411_fix_import.sh
 D step_412_fix_all_pix2pi_imports.sh
 D step_413_build_api_gateway_again.sh
 D step_414_test_api_gateway_local.sh
 D step_415_debug_query_endpoint.sh
 D step_416_inspect_query_route.sh
 D step_417_backup_query_gateway.sh
 D step_417_build_restart_test.sh
 D step_417_fix_api_gateway_main.sh
 D step_417_fix_query_service.sh
 D step_418_fix_gateway_panic.sh
 D step_418_fix_query_service_safe.sh
 D step_418_test_debug.sh
 D step_419_build_test.sh
 D step_419_fix_main_go.sh
 D step_41_run_event_retry_test.sh
 D step_420_build_test.sh
 D step_420_rewrite_gateway.sh
 D step_421_backup_kernel_safe.sh
 D step_421_patch_kernel_safe.sh
 D step_421_test_safe_kernel.sh
 D step_422_backup_gateway_db_init.sh
 D step_422_build_restart_test.sh
 D step_422_check_gateway_env.sh
 D step_422_rewrite_gateway_with_db_init.sh
 D step_42_backup_event_idempotency.sh
 D step_43_run_event_idempotency_test.sh
 D step_44_backup_event_dlq.sh
 D step_45_run_event_dlq_test.sh
 D step_46_backup_event_store.sh
 D step_47_prepare_event_store_dirs.sh
 D step_48_run_event_store_test.sh
 D step_49_backup_event_replay.sh
 D step_4_add_banka_giris_before_odeme.sh
 D step_4_check_balance_sheet_files.sh
 D step_4_check_cash_flow_files.sh
 D step_4_check_financial_consistency_files.sh
 D step_4_check_general_ledger_files.sh
 D step_4_check_income_statement_files.sh
 D step_4_prepare_auth_dirs.sh
 D step_4_run_ledger_balance.sh
 D step_4_run_period_closing.sh
 D step_50_run_event_replay_test.sh
 D step_51_backup_event_bus_store_integration.sh
 D step_52_run_event_bus_store_integration_test.sh
 D step_53_backup_journal_builder.sh
 D step_54_prepare_ufk_dirs.sh
 D step_55_run_journal_builder_test.sh
 D step_56_backup_ledger_posting.sh
 D step_57_run_ledger_posting_test.sh
 D step_58_backup_snapshot_engine.sh
 D step_59_run_snapshot_engine_test.sh
 D step_5_check_accounts_import_files.sh
 D step_5_check_chart_intelligence_files.sh
 D step_5_check_commission_rule_versioning_files.sh
 D step_5_check_journal_files.sh
 D step_5_check_ledger_files.sh
 D step_5_check_multi_account_ledger_files.sh
 D step_5_check_settlement_files.sh
 D step_5_check_trial_balance_files.sh
 D step_5_check_wallet_transfer_files.sh
 D step_5_run_balance_sheet.sh
 D step_5_run_cash_flow.sh
 D step_5_run_financial_consistency.sh
 D step_5_run_general_ledger.sh
 D step_5_run_income_statement.sh
 D step_5_run_jwt_tenant_test.sh
 D step_5_run_payment_engine.sh
 D step_5_run_tahsilat_odeme_v2.sh
 D step_5_run_ufk_engine.sh
 D step_60_backup_real_redis_cache.sh
 D step_61_add_redis_module.sh
 D step_62_run_real_redis_cache_test.sh
 D step_63_backup_read_write_split.sh
 D step_64_prepare_read_write_dirs.sh
 D step_65_run_read_write_split_test.sh
 D step_66_backup_reporting_store.sh
 D step_67_prepare_reporting_store_dirs.sh
 D step_68_run_reporting_store_test.sh
 D step_69_backup_rate_limit.sh
 D step_6_backup_jwt_middleware.sh
 D step_6_check_account_mapping_files.sh
 D step_6_check_accounts_seed_files.sh
 D step_6_check_auto_rules_files.sh
 D step_6_check_financial_event_files.sh
 D step_6_check_ledger_posting_files.sh
 D step_6_check_merchant_payout_files.sh
 D step_6_check_reconciliation_files.sh
 D step_6_check_tax_engine_files.sh
 D step_6_run_accounts_import.sh
 D step_6_run_chart_intelligence.sh
 D step_6_run_commission_rule_versioning.sh
 D step_6_run_journal_builder.sh
 D step_6_run_journal_engine.sh
 D step_6_run_ledger_engine.sh
 D step_6_run_multi_account_ledger.sh
 D step_6_run_settlement_engine.sh
 D step_6_run_trial_balance.sh
 D step_6_run_wallet_transfer_engine.sh
 D step_70_prepare_gateway_dirs.sh
 D step_71_run_rate_limit_test.sh
 D step_72_check_production_server.sh
 D step_73_update_production_server.sh
 D step_74_install_production_base_packages.sh
 D step_75_install_or_verify_docker.sh
 D step_76_configure_production_firewall.sh
 D step_77_prepare_production_dirs.sh
 D step_78_test_production_server_ready.sh
 D step_79_install_nginx.sh
 D step_7_check_alis_faturasi_files.sh
 D step_7_check_banka_files.sh
 D step_7_check_cari_hesap_files.sh
 D step_7_check_kasa_files.sh
 D step_7_check_satis_faturasi_files.sh
 D step_7_prepare_auth_middleware_dir.sh
 D step_7_run_account_mapping.sh
 D step_7_run_accounts_seed.sh
 D step_7_run_auto_rules.sh
 D step_7_run_financial_event.sh
 D step_7_run_ledger_posting.sh
 D step_7_run_merchant_payout_engine.sh
 D step_7_run_reconciliation_engine.sh
 D step_7_run_tax_engine.sh
 D step_80_prepare_nginx_dirs.sh
 D step_81_disable_default_nginx_site.sh
 D step_82_fix_dns_resolver.sh
 D step_83_cleanup_old_nginx_sites.sh
 D step_84_backup_nginx_ssl_split.sh
 D step_85_reload_nginx_split.sh
 D step_86_extend_ssl_server_subdomain.sh
 D step_87_disable_old_pix2pi_site.sh
 D step_88_test_split_routes.sh
 D step_89_test_server_ssl.sh
 D step_8_run_alis_faturasi_engine.sh
 D step_8_run_banka_engine.sh
 D step_8_run_cari_hesap_engine.sh
 D step_8_run_jwt_middleware_test.sh
 D step_8_run_kasa_engine.sh
 D step_8_run_satis_faturasi_engine.sh
 D step_8_run_tahsilat_engine.sh
 D step_90_check_server_cert_names.sh
 D step_91_test_server_ssl_strict.sh
 D step_92_backup_nginx_before_redirect_fix.sh
 D step_93_reload_nginx_after_redirect_fix.sh
 D step_95_find_duplicate_443_sites.sh
 D step_98_create_api_gateway_dirs.sh
 D step_99_run_api_gateway.sh
 D step_9_backup_tenant_event_pipeline.sh
 D step_final_check_banka_files.sh
 D step_fix_1_backup_cari_service.sh
 D step_fix_1_backup_cari_v2.sh
 D step_fix_3_update_satis_fatura_service.sh
 D step_fix_backup_banka_swift.sh
 D step_fix_backup_cari_service_ekstre.sh
 D step_fix_backup_kasa_parabirimi.sh
 D step_fix_backup_satis_iskonto.sh
 D step_fix_prepare_banka_dirs.sh
 D step_fix_prepare_finance_domain_dir.sh
 D step_fix_stok_paketini_kontrol_et.sh
 D step_fix_stok_paketini_kur.sh
 D step_fix_write_banka_files.sh
 D step_run_banka_ekstre.sh
 D step_run_bilanco_engine.sh
 D step_run_cari_ekstre.sh
 D step_run_gelir_tablosu_engine.sh
 D step_run_kasa_ekstre.sh
 D step_run_mizan_engine.sh
 D step_run_satis_iskonto.sh
 D step_run_ufk_event_engine.sh
 D step_run_ufk_event_journal.sh
 D step_run_ufk_journal_ledger.sh
?? ${BACKUP_DIR}/
?? ${PATCHED_FILES_LIST}
?? .backup/
?? 1_archive/
?? Dockerfile
?? Dockerfile.identity
?? Dockerfile.mission
?? Dockerfile.registry
?? accounting-service
?? api-gateway
?? backups/
?? cache-pattern-clean-test
?? cache-service
?? cmd/api-gateway/api_gateway_main_test.go
?? cmd/api-gateway/erp_runtime_live_mount_wiring_test.go
?? cmd/api-gateway/erp_runtime_mount.go
?? cmd/api-gateway/erp_runtime_mount_test.go
?? cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go
?? cmd/api-gateway/erp_runtime_route_catalog_visibility_test.go
?? cmd/api-gateway/erp_runtime_route_catalog_wiring_test.go
?? cmd/api-gateway/erp_runtime_route_policy.go
?? cmd/api-gateway/erp_runtime_route_policy_test.go
?? cmd/api-gateway/erp_runtime_service_factory.go
?? cmd/api-gateway/erp_runtime_service_factory_test.go
?? cmd/api-gateway/gateway_config.go
?? cmd/api-gateway/gateway_config_security_test.go
?? cmd/api-gateway/gateway_entry_contract_test.go
?? cmd/api-gateway/gateway_middleware.go
?? cmd/api-gateway/gateway_routes.go
?? cmd/api-gateway/gateway_routes_test.go
?? cmd/api-gateway/gateway_s2s_policy_test.go
?? cmd/api-gateway/user_detail_route.go
?? cmd/cache-pattern-clean-test/
?? cmd/control-panel/ui/assets/
?? cmd/early-warning-runtime/
?? cmd/erp/core/ufk/scripts/
?? cmd/event-bus-store-lifecycle-test/
?? cmd/event-concurrency-test/
?? cmd/event-idempotency-test/
?? cmd/event-metadata-test/
?? cmd/event-replay-test/
?? cmd/event-schema-test/
?? cmd/event-store-postgres-test/
?? cmd/gateway-quota-redis-test/
?? cmd/gateway-rate-limit-redis-test/
?? cmd/identity-api/identity_api_main.go
?? cmd/incident-audit-runtime/
?? cmd/jobs-runtime/
?? cmd/notification-runtime/
?? cmd/ops-console-smoke/
?? cmd/plugin-runtime/
?? cmd/policy-cache-hybrid-test/
?? cmd/publicapi-runtime/
?? cmd/realtime-runtime/
?? cmd/runtime-topology/
?? cmd/user-created-consumer/
?? cmd/webhook-runtime/
?? cmd/workflow-runtime/
?? config/backfill/
?? config/backup/
?? config/projection/
?? config/reference-data/
?? config/retention/
?? configs/faz5/
?? db/
?? deploy/edge/
?? deploy/erp-tr/
?? deploy/nats/docker-compose.nats-monitoring.override.yml
?? deploy/observability/config/
?? deploy/observability/env/
?? deploy/observability/generated/
?? deploy/observability/scripts/
?? deploy/platform/
?? deploy/quality/
?? deploy/smoke/
?? docs/api/
?? docs/architecture/
?? docs/erp-tr/
?? docs/erp/
?? docs/faz4d/
?? docs/faz5/
?? docs/faz6/
?? docs/infra/
?? docs/observability/
?? docs/phase4/
?? docs/pilot/
?? docs/platform/
?? docs/quality/
?? event-bus-store-lifecycle-test
?? event-concurrency-test
?? event-consumer
?? event-idempotency-test
?? event-metadata-test
?? event-replay-test
?? event-schema-test
?? event-store-postgres-test
?? gateway-rate-limit-redis-test
?? handoff/
?? imports/
?? install_phase1_scaffold.sh
?? internal/erp/core/audit/service/erp_financial_consistency_service_test.go
?? internal/erp/core/audit/service/erp_financial_flow_suite_test.go
?? internal/erp/core/events/service/erp_event_intake_service.go
?? internal/erp/core/events/service/erp_event_intake_service_test.go
?? internal/erp/core/journal/service/erp_journal_builder_service_test.go
?? internal/erp/core/kernel/ufk/domain/erp_ledger_account.go
?? internal/erp/core/ledger/service/erp_ledger_posting_service_test.go
?? internal/erp/core/ledger/service/erp_posting_safety_service.go
?? internal/erp/core/ledger/service/erp_posting_safety_service_test.go
?? internal/erp/core/reconciliation/service/erp_reconciliation_service_test.go
?? internal/erp/core/rules/service/erp_accounting_rule_service_test.go
?? internal/erp/core/ufk/service/erp_ledger_posting_service_test.go
?? internal/erp/persistence/
?? internal/erp/runtime/
?? internal/platform/audit/domain/audit_log_test.go
?? internal/platform/audit/service/audit_log_service_test.go
?? internal/platform/auth/domain/jwt_claim_contract.go
?? internal/platform/auth/domain/jwt_claim_contract_test.go
?? internal/platform/auth/middleware/jwt_middleware_test.go
?? internal/platform/auth/service/jwt_service_test.go
?? internal/platform/db/tenant_query_scope.go
?? internal/platform/db/tenant_query_scope_test.go
?? internal/platform/db/tenant_rls.go
?? internal/platform/db/tenant_rls_guard.go
?? internal/platform/db/tenant_rls_guard_test.go
?? internal/platform/db/tenant_rls_migrate.go
?? internal/platform/db/tenant_rls_migrate_test.go
?? internal/platform/db/tenant_rls_targets.go
?? internal/platform/db/tenant_rls_targets_test.go
?? internal/platform/db/tenant_rls_test.go
?? internal/platform/db/tenant_session.go
?? internal/platform/db/tenant_session_test.go
?? internal/platform/dbrouter/
?? internal/platform/eventbus/domain/event_message_test.go
?? internal/platform/eventbus/service/dlq_event_validator.go
?? internal/platform/eventbus/service/dlq_event_validator_test.go
?? internal/platform/eventbus/service/event_bus_service_integration_test.go
?? internal/platform/eventbus/service/tenant_safe_event_bus.go
?? internal/platform/eventbus/service/tenant_safe_event_bus_test.go
?? internal/platform/eventreplay/
?? internal/platform/eventschema/
?? internal/platform/eventstore/domain/event_store_record_test.go
?? internal/platform/eventstore/service/event_store_port.go
?? internal/platform/eventstore/service/event_store_postgres_service.go
?? internal/platform/eventstore/service/event_store_service_integration_test.go
?? internal/platform/eventstore/service/postgres_event_store_validation.go
?? internal/platform/eventstore/service/postgres_event_store_validation_test.go
?? internal/platform/eventstore/service/tenant_safe_event_store.go
?? internal/platform/eventstore/service/tenant_safe_event_store_test.go
?? internal/platform/gateway/domain/quota_record.go
?? internal/platform/gateway/service/quota_service.go
?? internal/platform/idempotency/
?? internal/platform/jobsqueue/
?? internal/platform/kernel/tenant_guard_test.go
?? internal/platform/kernel/tenant_identity_bridge.go
?? internal/platform/kernel/tenant_identity_bridge_test.go
?? internal/platform/missioncontrol/
?? internal/platform/monitor/database_pressure_early_warning_service.go
?? internal/platform/monitor/database_pressure_early_warning_service_test.go
?? internal/platform/monitor/database_pressure_runtime_bridge_service.go
?? internal/platform/monitor/database_pressure_runtime_bridge_service_test.go
?? internal/platform/monitor/early_warning_signal_service.go
?? internal/platform/monitor/early_warning_signal_service_test.go
?? internal/platform/monitor/early_warning_threshold_service.go
?? internal/platform/monitor/early_warning_threshold_service_test.go
?? internal/platform/monitor/event_backlog_early_warning_service.go
?? internal/platform/monitor/event_backlog_early_warning_service_test.go
?? internal/platform/monitor/event_backlog_runtime_bridge_service.go
?? internal/platform/monitor/event_backlog_runtime_bridge_service_test.go
?? internal/platform/monitor/infra_pressure_early_warning_service.go
?? internal/platform/monitor/infra_pressure_early_warning_service_test.go
?? internal/platform/monitor/infra_pressure_runtime_bridge_service.go
?? internal/platform/monitor/infra_pressure_runtime_bridge_service_test.go
?? internal/platform/monitor/observability_alarm_bridge_service.go
?? internal/platform/monitor/observability_alarm_bridge_service_test.go
?? internal/platform/monitor/observability_ops_security_bridge_service.go
?? internal/platform/monitor/observability_ops_security_bridge_service_test.go
?? internal/platform/monitor/reporting_pressure_early_warning_service.go
?? internal/platform/monitor/reporting_pressure_early_warning_service_test.go
?? internal/platform/monitor/reporting_pressure_runtime_bridge_service.go
?? internal/platform/monitor/reporting_pressure_runtime_bridge_service_test.go
?? internal/platform/monitor/scale_levelup_decision_service.go
?? internal/platform/monitor/scale_levelup_decision_service_test.go
?? internal/platform/monitor/scale_levelup_matrix_service.go
?? internal/platform/monitor/scale_levelup_matrix_service_test.go
?? internal/platform/monitor/service_health_early_warning_service.go
?? internal/platform/monitor/service_health_early_warning_service_test.go
?? internal/platform/monitor/service_health_runtime_bridge_service.go
?? internal/platform/monitor/service_health_runtime_bridge_service_test.go
?? internal/platform/notifications/
?? internal/platform/plugins/lifecycle_contract.go
?? internal/platform/plugins/lifecycle_service.go
?? internal/platform/plugins/lifecycle_service_test.go
?? internal/platform/plugins/lifecycle_store.go
?? internal/platform/plugins/lifecycle_store_test.go
?? internal/platform/plugins/loader_contract.go
?? internal/platform/plugins/loader_service.go
?? internal/platform/plugins/loader_service_test.go
?? internal/platform/plugins/loader_store.go
?? internal/platform/plugins/loader_store_test.go
?? internal/platform/plugins/permission_contract.go
?? internal/platform/plugins/permission_service.go
?? internal/platform/plugins/permission_service_test.go
?? internal/platform/plugins/permission_store.go
?? internal/platform/plugins/permission_store_test.go
?? internal/platform/plugins/row_provider.go
?? internal/platform/plugins/runtime_integration_test.go
?? internal/platform/plugins/sandbox_contract.go
?? internal/platform/plugins/sandbox_service.go
?? internal/platform/plugins/sandbox_service_test.go
?? internal/platform/plugins/sandbox_store.go
?? internal/platform/plugins/sandbox_store_test.go
?? internal/platform/plugins/version_contract.go
?? internal/platform/plugins/version_service.go
?? internal/platform/plugins/version_service_test.go
?? internal/platform/plugins/version_store.go
?? internal/platform/plugins/version_store_test.go
?? internal/platform/publicapi/
?? internal/platform/readcache/
?? internal/platform/readmodel/dashboard_query_security_test.go
?? internal/platform/readmodel/dashboard_query_source.go
?? internal/platform/readmodel/dashboard_query_source_test.go
?? internal/platform/readmodel/dashboard_sql_repository.go
?? internal/platform/readmodel/dashboard_sql_repository_strict_test.go
?? internal/platform/readmodel/dashboard_sql_repository_test.go
?? internal/platform/readmodel/export_query_security_test.go
?? internal/platform/readmodel/export_query_source.go
?? internal/platform/readmodel/export_query_source_test.go
?? internal/platform/readmodel/export_sql_repository.go
?? internal/platform/readmodel/export_sql_repository_strict_test.go
?? internal/platform/readmodel/export_sql_repository_test.go
?? internal/platform/readmodel/projection_contract.go
?? internal/platform/readmodel/projection_contract_test.go
?? internal/platform/readmodel/projection_rebuild.go
?? internal/platform/readmodel/projection_rebuild_access.go
?? internal/platform/readmodel/projection_rebuild_access_test.go
?? internal/platform/readmodel/projection_rebuild_test.go
?? internal/platform/readmodel/reporting_store.go
?? internal/platform/readmodel/reporting_store_tenant_query_test.go
?? internal/platform/readmodel/reporting_store_test.go
?? internal/platform/readmodel/service/read_write_split_access.go
?? internal/platform/readmodel/service/read_write_split_access_test.go
?? internal/platform/readmodel/subscriber_access.go
?? internal/platform/readmodel/subscriber_access_test.go
?? internal/platform/readmodel/subscriber_pipeline.go
?? internal/platform/readmodel/subscriber_pipeline_test.go
?? internal/platform/readmodel/tenant_quality_gate.go
?? internal/platform/readmodel/tenant_quality_gate_access_plan_test.go
?? internal/platform/readmodel/tenant_quality_gate_legacy_test.go
?? internal/platform/readmodel/tenant_quality_gate_test.go
?? internal/platform/readmodel/tenant_query_contract.go
?? internal/platform/readmodel/tenant_query_contract_test.go
?? internal/platform/readmodel/tenant_repo_query_builder.go
?? internal/platform/readmodel/tenant_repo_query_builder_test.go
?? internal/platform/realtime/
?? internal/platform/reporting/api/
?? internal/platform/reporting/repository/
?? internal/platform/reporting/runtime/
?? internal/platform/reporting/service/service.go
?? internal/platform/reporting/service/service_test.go
?? internal/platform/reporting/service/types.go
?? internal/platform/security/service/incident_readiness_service.go
?? internal/platform/security/service/incident_readiness_service_test.go
?? internal/platform/security/service/request_guard_service.go
?? internal/platform/security/service/request_guard_service_test.go
?? internal/platform/security/service/request_runtime_guard_service.go
?? internal/platform/security/service/request_runtime_guard_service_test.go
?? internal/platform/security/service/secret_contract_service.go
?? internal/platform/security/service/secret_contract_service_test.go
?? internal/platform/security/service/secret_log_redaction_service.go
?? internal/platform/security/service/secret_log_redaction_service_test.go
?? internal/platform/security/service/secret_runtime_env_service.go
?? internal/platform/security/service/secret_runtime_env_service_test.go
?? internal/platform/security/service/security_alarm_bridge_service.go
?? internal/platform/security/service/security_alarm_bridge_service_test.go
?? internal/platform/security/service/security_audit_event_service.go
?? internal/platform/security/service/security_audit_event_service_test.go
?? internal/platform/security/service/security_audit_sink_service.go
?? internal/platform/security/service/security_audit_sink_service_test.go
?? internal/platform/security/service/security_time_helper.go
?? internal/platform/security/service/upload_payload_guard_service.go
?? internal/platform/security/service/upload_payload_guard_service_test.go
?? internal/platform/security/service/upload_runtime_guard_service.go
?? internal/platform/security/service/upload_runtime_guard_service_test.go
?? internal/platform/security/service/webhook_replay_guard_service.go
?? internal/platform/security/service/webhook_replay_guard_service_test.go
?? internal/platform/security/service/webhook_signature_service.go
?? internal/platform/security/service/webhook_signature_service_test.go
?? internal/platform/serviceregistry/
?? internal/platform/tenancy/tenant_identity.go
?? internal/platform/tenancy/tenant_identity_test.go
?? internal/platform/webhooks/
?? internal/platform/workflow/
?? internal/services/query_read_model/handler.go
?? internal/services/query_read_model/service_test.go
?? policy-cache-hybrid-test
?? reports/
?? scripts/__pycache__/
?? scripts/api_gateway_entry_check.sh
?? scripts/api_gateway_final_suite.sh
?? scripts/audit_faz6_2_db_l8_readiness.sh
?? scripts/audit_faz6_2_real_implementation.sh
?? scripts/audit_faz6_3_multinode_runtime.sh
?? scripts/audit_faz6_3_real_implementation.sh
?? scripts/audit_faz6_4_event_bus_runtime.sh
?? scripts/audit_faz6_4_real_implementation.sh
?? scripts/audit_faz6_5_observability_runtime.sh
?? scripts/audit_faz6_5_real_implementation.sh
?? scripts/audit_faz6_6_backup_restore_runtime.sh
?? scripts/audit_faz6_6_real_implementation.sh
?? scripts/audit_faz6_7_real_implementation.sh
?? scripts/audit_faz6_7_security_runtime.sh
?? scripts/audit_faz6_8_performance_runtime.sh
?? scripts/audit_faz6_8_real_implementation.sh
?? scripts/audit_faz6_9_real_implementation.sh
?? scripts/audit_faz6_9_release_runtime.sh
?? scripts/audit_master_progress.py
?? scripts/audit_master_progress_v2.py
?? scripts/check_ops_health_watchdog.sh
?? scripts/check_ops_service_failures.sh
?? scripts/diagnostics/
?? scripts/event_platform_final_suite.sh
?? scripts/faz4d/
?? scripts/faz5/
?? scripts/mock_webhook_server.py
?? scripts/mock_webhook_server_57q.py
?? scripts/mock_webhook_server_57s.py
?? scripts/mock_webhook_server_57t.py
?? scripts/mock_webhook_server_once.py
?? scripts/ops_health_alert.sh
?? scripts/ops_health_alert_core.sh
?? scripts/ops_health_report.sh
?? scripts/ops_log_hygiene_once.sh
?? scripts/ops_notify_webhook.sh
?? scripts/ops_retention_cleanup.sh
?? scripts/phase4_controlled_gateway_runtime_apply.py
?? scripts/phase4_controlled_gateway_runtime_apply.sh
?? scripts/phase4_db_backup_pitr_readiness.sh
?? scripts/phase4_db_connection_evidence.sh
?? scripts/phase4_db_env_discovery.sh
?? scripts/phase4_db_final_closure_gate.sh
?? scripts/phase4_db_health_baseline.sh
?? scripts/phase4_db_known_risks_deferred_register.sh
?? scripts/phase4_db_master_evidence_collector.sh
?? scripts/phase4_db_observability_apply_readiness.sh
?? scripts/phase4_db_observability_controlled_apply.sh
?? scripts/phase4_db_observability_enable_gate.sh
?? scripts/phase4_db_observability_final_baseline.sh
?? scripts/phase4_db_observability_performance.sh
?? scripts/phase4_db_performance_final_closure.sh
?? scripts/phase4_db_production_readiness_scorecard.sh
?? scripts/phase4_db_runbook_incident_checklist.sh
?? scripts/phase4_discover_migration_chain.sh
?? scripts/phase4_drift_classification.sh
?? scripts/phase4_final_master_closure.py
?? scripts/phase4_final_master_closure.sh
?? scripts/phase4_gateway_route_controlled_apply_gate.py
?? scripts/phase4_gateway_route_controlled_apply_gate.sh
?? scripts/phase4_gateway_route_manifest_auth_tenant_gate.sh
?? scripts/phase4_gateway_runtime_apply_readiness.sh
?? scripts/phase4_index_reconciliation_plan.sh
?? scripts/phase4_index_usage_baseline.sh
?? scripts/phase4_live_http_smoke_auth_tenant.py
?? scripts/phase4_live_http_smoke_auth_tenant.sh
?? scripts/phase4_logical_backup_smoke.sh
?? scripts/phase4_migration_apply_gate.sh
?? scripts/phase4_migration_drift_evidence.sh
?? scripts/phase4_migration_reconciliation_final.sh
?? scripts/phase4_migration_status_evidence.sh
?? scripts/phase4_migration_timestamp_order_guard.sh
?? scripts/phase4_migration_version_normalization.sh
?? scripts/phase4_operational_readmodel_tables.sh
?? scripts/phase4_pitr_design_wal_archive_plan.sh
?? scripts/phase4_pitr_enable_gate.sh
?? scripts/phase4_primary_write_dsn_guard.sh
?? scripts/phase4_query_performance_baseline.sh
?? scripts/phase4_readmodel_apply_gate.sh
?? scripts/phase4_readmodel_contract_query_evidence.sh
?? scripts/phase4_readmodel_controlled_apply.sh
?? scripts/phase4_readmodel_repository_layer.sh
?? scripts/phase4_real_dsn_repair.sh
?? scripts/phase4_reporting_api_endpoint_skeleton.sh
?? scripts/phase4_reporting_api_final_closure.sh
?? scripts/phase4_reporting_api_route_registration.sh
?? scripts/phase4_reporting_live_route_final_closure.py
?? scripts/phase4_reporting_live_route_final_closure.sh
?? scripts/phase4_reporting_query_contract.sh
?? scripts/phase4_reporting_query_smoke_final_closure.sh
?? scripts/phase4_reporting_runtime_service_entry_apply_plan.sh
?? scripts/phase4_reporting_runtime_smoke_test.sh
?? scripts/phase4_reporting_runtime_wiring_plan.sh
?? scripts/phase4_reporting_service_layer.sh
?? scripts/phase4_restore_drill_sandbox_plan.sh
?? scripts/phase4_restore_drill_test.sh
?? scripts/phase4_vacuum_bloat_readiness.sh
?? scripts/phase4_validate_migration_chain.sh
?? scripts/phase4b_admin_dashboard_cards.py
?? scripts/phase4b_admin_dashboard_cards.sh
?? scripts/phase4b_alert_rule_catalog.py
?? scripts/phase4b_alert_rule_catalog.sh
?? scripts/phase4b_archive_partition_retention.py
?? scripts/phase4b_archive_partition_retention.sh
?? scripts/phase4b_audit_event_model.py
?? scripts/phase4b_audit_event_model.sh
?? scripts/phase4b_backfill_rebuild_standard.py
?? scripts/phase4b_backfill_rebuild_standard.sh
?? scripts/phase4b_backup_archive_retention_hygiene.py
?? scripts/phase4b_backup_archive_retention_hygiene.sh
?? scripts/phase4b_backup_restore_verification.py
?? scripts/phase4b_backup_restore_verification.sh
?? scripts/phase4b_config_env_hardening_gate.py
?? scripts/phase4b_config_env_hardening_gate.sh
?? scripts/phase4b_docker_compose_hardening.py
?? scripts/phase4b_docker_compose_hardening.sh
?? scripts/phase4b_ebelge_export_reporting_mart.py
?? scripts/phase4b_ebelge_export_reporting_mart.sh
?? scripts/phase4b_final_master_closure.py
?? scripts/phase4b_final_master_closure.sh
?? scripts/phase4b_finance_reporting_mart.py
?? scripts/phase4b_finance_reporting_mart.sh
?? scripts/phase4b_flow_detail_page.py
?? scripts/phase4b_flow_detail_page.sh
?? scripts/phase4b_go_no_go_rollout_gate.py
?? scripts/phase4b_go_no_go_rollout_gate.sh
?? scripts/phase4b_import_staging_tables.py
?? scripts/phase4b_import_staging_tables.sh
?? scripts/phase4b_import_wizard_ui.py
?? scripts/phase4b_import_wizard_ui.sh
?? scripts/phase4b_infra_cleanup_production_hardening_final_closure.py
?? scripts/phase4b_infra_cleanup_production_hardening_final_closure.sh
?? scripts/phase4b_inventory_tests.py
?? scripts/phase4b_inventory_tests.sh
?? scripts/phase4b_issue_feedback_ui.py
?? scripts/phase4b_issue_feedback_ui.sh
?? scripts/phase4b_logs_loki_readiness.py
?? scripts/phase4b_logs_loki_readiness.sh
?? scripts/phase4b_materialized_cache_projection_standard.py
?? scripts/phase4b_materialized_cache_projection_standard.sh
?? scripts/phase4b_metrics_scrape_readiness.py
?? scripts/phase4b_metrics_scrape_readiness.sh
?? scripts/phase4b_migration_chain_standard.py
?? scripts/phase4b_migration_chain_standard.sh
?? scripts/phase4b_migration_lifecycle_import_tests.py
?? scripts/phase4b_migration_lifecycle_import_tests.sh
?? scripts/phase4b_negative_stock_policy.py
?? scripts/phase4b_negative_stock_policy.sh
?? scripts/phase4b_nginx_reverse_proxy_hardening.py
?? scripts/phase4b_nginx_reverse_proxy_hardening.sh
?? scripts/phase4b_observability_baseline.py
?? scripts/phase4b_observability_baseline.sh
?? scripts/phase4b_observability_ops_console_final_closure.py
?? scripts/phase4b_observability_ops_console_final_closure.sh
?? scripts/phase4b_observability_ops_console_tests.py
?? scripts/phase4b_observability_ops_console_tests.sh
?? scripts/phase4b_opening_stock.py
?? scripts/phase4b_opening_stock.sh
?? scripts/phase4b_ops_console_signal_contract.py
?? scripts/phase4b_ops_console_signal_contract.sh
?? scripts/phase4b_panel_ux_tests.py
?? scripts/phase4b_panel_ux_tests.sh
?? scripts/phase4b_payment_reconciliation_reporting_mart.py
?? scripts/phase4b_payment_reconciliation_reporting_mart.sh
?? scripts/phase4b_permission_guard.py
?? scripts/phase4b_permission_guard.sh
?? scripts/phase4b_pilot_data_readiness_contract.py
?? scripts/phase4b_pilot_data_readiness_contract.sh
?? scripts/phase4b_pilot_tenant_readiness_contract.py
?? scripts/phase4b_pilot_tenant_readiness_contract.sh
?? scripts/phase4b_pilot_uat_onboarding_baseline.py
?? scripts/phase4b_pilot_uat_onboarding_baseline.sh
?? scripts/phase4b_pilot_uat_onboarding_final_closure.py
?? scripts/phase4b_pilot_uat_onboarding_final_closure.sh
?? scripts/phase4b_pilot_uat_onboarding_tests.py
?? scripts/phase4b_pilot_uat_onboarding_tests.sh
?? scripts/phase4b_production_cleanup_gate.py
?? scripts/phase4b_production_cleanup_gate.sh
?? scripts/phase4b_production_hardening_tests.py
?? scripts/phase4b_production_hardening_tests.sh
?? scripts/phase4b_purchase_stock_increment.py
?? scripts/phase4b_purchase_stock_increment.sh
?? scripts/phase4b_readmodel_reporting_tests.py
?? scripts/phase4b_readmodel_reporting_tests.sh
?? scripts/phase4b_realtime_channel_contract.py
?? scripts/phase4b_realtime_channel_contract.sh
?? scripts/phase4b_reference_seed_standard.py
?? scripts/phase4b_reference_seed_standard.sh
?? scripts/phase4b_role_matrix.py
?? scripts/phase4b_role_matrix.sh
?? scripts/phase4b_runtime_flow_history.py
?? scripts/phase4b_runtime_flow_history.sh
?? scripts/phase4b_runtime_service_hardening.py
?? scripts/phase4b_runtime_service_hardening.sh
?? scripts/phase4b_sales_stock_decrement.py
?? scripts/phase4b_sales_stock_decrement.sh
?? scripts/phase4b_search_index_projection_tables.py
?? scripts/phase4b_search_index_projection_tables.sh
?? scripts/phase4b_security_rbac_audit_final_closure.py
?? scripts/phase4b_security_rbac_audit_final_closure.sh
?? scripts/phase4b_security_tests.py
?? scripts/phase4b_security_tests.sh
?? scripts/phase4b_stock_movement_engine.py
?? scripts/phase4b_stock_movement_engine.sh
?? scripts/phase4b_stock_reservation.py
?? scripts/phase4b_stock_reservation.sh
?? scripts/phase4b_stock_valuation.py
?? scripts/phase4b_stock_valuation.sh
?? scripts/phase4b_support_super_admin_boundary.py
?? scripts/phase4b_support_super_admin_boundary.sh
?? scripts/phase4b_tenant_access_checks.py
?? scripts/phase4b_tenant_access_checks.sh
?? scripts/phase4b_traces_tempo_readiness.py
?? scripts/phase4b_traces_tempo_readiness.sh
?? scripts/phase4b_uat_checklist_ui.py
?? scripts/phase4b_uat_checklist_ui.sh
?? scripts/phase4b_uat_scenario_execution_contract.py
?? scripts/phase4b_uat_scenario_execution_contract.sh
?? scripts/phase4b_ui_api_implementation_plan.py
?? scripts/phase4b_ui_api_implementation_plan.sh
?? scripts/phase4b_workflow_action_approval_contract.py
?? scripts/phase4b_workflow_action_approval_contract.sh
?? scripts/phase4b_workflow_realtime_baseline.py
?? scripts/phase4b_workflow_realtime_baseline.sh
?? scripts/phase4b_workflow_realtime_final_closure.py
?? scripts/phase4b_workflow_realtime_final_closure.sh
?? scripts/phase4b_workflow_realtime_tests.py
?? scripts/phase4b_workflow_realtime_tests.sh
?? scripts/phase4b_workflow_state_machine_contract.py
?? scripts/phase4b_workflow_state_machine_contract.sh
?? scripts/pilot/
?? scripts/pix2pi_postdeploy_smoke.sh
?? scripts/pix2pi_predeploy_check.sh
?? scripts/pix2pi_rollback_readiness.sh
?? scripts/prod_e2e_user_created_check.sh
?? scripts/prod_finance_post_restart_check.sh
?? scripts/prod_finance_smoke.sh
?? scripts/prod_ops_suite.sh
?? scripts/prod_service_failure_drill.sh
?? scripts/query_deploy_verify.sh
?? scripts/query_ops_suite.sh
?? scripts/query_post_restart_check.sh
?? scripts/query_smoke_prod.sh
?? scripts/rebuild_read_users_projection.sh
?? scripts/run_ops_health_daily.sh
?? scripts/run_ops_retention_daily.sh
?? scripts/step_52a_query_smoke.sh
?? scripts/step_52b_query_post_restart_check.sh
?? scripts/step_55a_e2e_prod_smoke.sh
?? scripts/step_event_platform_final_close_1.sh
?? scripts/step_event_platform_final_suite_inventory_1.sh
?? scripts/step_event_platform_final_suite_run_1.sh
?? scripts/step_gw_close_master_1.sh
?? scripts/step_gw_edge_1.sh
?? scripts/step_gw_edge_2.sh
?? scripts/step_gw_edge_2_fix.sh
?? scripts/step_gw_edge_3.sh
?? scripts/step_gw_final_close_1.sh
?? scripts/step_gw_ingress_1b.sh
?? scripts/step_gw_ingress_2.sh
?? scripts/step_gw_ingress_3.sh
?? scripts/step_gw_ingress_4.sh
?? scripts/step_gw_ingress_4_fix.sh
?? scripts/step_gw_internal_key_fix_1.sh
?? scripts/step_gw_jwt_default_fix_1.sh
?? scripts/step_gw_jwt_default_probe_1.sh
?? scripts/step_gw_jwt_manual_1.sh
?? scripts/step_gw_jwt_matrix_1.sh
?? scripts/step_gw_rate_quota_live_1.sh
?? scripts/step_gw_rate_quota_restore_fix_1.sh
?? scripts/step_gw_rate_quota_restore_fix_2.sh
?? scripts/step_gw_token_probe_1.sh
?? scripts/test/
?? scripts/test_faz6_1_scope_freeze.sh
?? scripts/test_faz6_2_db_l8_readiness.sh
?? scripts/test_faz6_2_real_implementation_audit.sh
?? scripts/test_faz6_2_visible_checkpoints.sh
?? scripts/test_faz6_3_multinode_readiness.sh
?? scripts/test_faz6_4_event_bus_sre_readiness.sh
?? scripts/test_faz6_5_observability_sre_dashboard.sh
?? scripts/test_faz6_6_backup_restore_dr.sh
?? scripts/test_faz6_7_security_hardening.sh
?? scripts/test_faz6_8_performance_load_stress.sh
?? scripts/test_faz6_9_release_rollback_deploy_safety.sh
?? scripts/test_ops_daily_alert_chain.sh
?? scripts/test_ops_health_alarm_chain.sh
?? scripts/test_ops_health_watchdog_fail.sh
?? scripts/test_ops_service_alarm_chain.sh
?? scripts/test_ops_service_alarm_fail.sh
?? scripts/test_phase4_controlled_gateway_runtime_apply.sh
?? scripts/test_phase4_db_backup_pitr_readiness.sh
?? scripts/test_phase4_db_connection_evidence.sh
?? scripts/test_phase4_db_env_discovery.sh
?? scripts/test_phase4_db_final_closure_gate.sh
?? scripts/test_phase4_db_health_baseline.sh
?? scripts/test_phase4_db_known_risks_deferred_register.sh
?? scripts/test_phase4_db_master_evidence_collector.sh
?? scripts/test_phase4_db_observability_apply_readiness.sh
?? scripts/test_phase4_db_observability_controlled_apply.sh
?? scripts/test_phase4_db_observability_enable_gate.sh
?? scripts/test_phase4_db_observability_final_baseline.sh
?? scripts/test_phase4_db_observability_performance.sh
?? scripts/test_phase4_db_performance_final_closure.sh
?? scripts/test_phase4_db_production_readiness_scorecard.sh
?? scripts/test_phase4_db_runbook_incident_checklist.sh
?? scripts/test_phase4_drift_classification.sh
?? scripts/test_phase4_final_master_closure.sh
?? scripts/test_phase4_gateway_route_controlled_apply_gate.sh
?? scripts/test_phase4_gateway_route_manifest_auth_tenant_gate.sh
?? scripts/test_phase4_gateway_runtime_apply_readiness.sh
?? scripts/test_phase4_index_parser_correction.sh
?? scripts/test_phase4_index_reconciliation_plan.sh
?? scripts/test_phase4_index_usage_baseline.sh
?? scripts/test_phase4_live_http_smoke_auth_tenant.sh
?? scripts/test_phase4_logical_backup_smoke.sh
?? scripts/test_phase4_migration_apply_gate.sh
?? scripts/test_phase4_migration_chain_standard.sh
?? scripts/test_phase4_migration_discovery.sh
?? scripts/test_phase4_migration_drift_evidence.sh
?? scripts/test_phase4_migration_reconciliation_final.sh
?? scripts/test_phase4_migration_status_evidence.sh
?? scripts/test_phase4_migration_timestamp_order_guard.sh
?? scripts/test_phase4_migration_version_normalization.sh
?? scripts/test_phase4_operational_readmodel_tables.sh
?? scripts/test_phase4_pitr_design_wal_archive_plan.sh
?? scripts/test_phase4_pitr_enable_gate.sh
?? scripts/test_phase4_primary_write_dsn_guard.sh
?? scripts/test_phase4_query_performance_baseline.sh
?? scripts/test_phase4_readmodel_apply_gate.sh
?? scripts/test_phase4_readmodel_contract_query_evidence.sh
?? scripts/test_phase4_readmodel_controlled_apply.sh
?? scripts/test_phase4_readmodel_repository_layer.sh
?? scripts/test_phase4_real_dsn_repair.sh
?? scripts/test_phase4_reporting_api_endpoint_skeleton.sh
?? scripts/test_phase4_reporting_api_final_closure.sh
?? scripts/test_phase4_reporting_api_route_registration.sh
?? scripts/test_phase4_reporting_live_route_final_closure.sh
?? scripts/test_phase4_reporting_query_contract.sh
?? scripts/test_phase4_reporting_query_smoke_final_closure.sh
?? scripts/test_phase4_reporting_runtime_service_entry_apply_plan.sh
?? scripts/test_phase4_reporting_runtime_smoke_test.sh
?? scripts/test_phase4_reporting_runtime_wiring_plan.sh
?? scripts/test_phase4_reporting_service_layer.sh
?? scripts/test_phase4_restore_drill_sandbox_plan.sh
?? scripts/test_phase4_restore_drill_test.sh
?? scripts/test_phase4_vacuum_bloat_readiness.sh
?? scripts/test_phase4b_admin_dashboard_cards.sh
?? scripts/test_phase4b_alert_rule_catalog.sh
?? scripts/test_phase4b_archive_partition_retention.sh
?? scripts/test_phase4b_audit_event_model.sh
?? scripts/test_phase4b_backfill_rebuild_standard.sh
?? scripts/test_phase4b_backup_archive_retention_hygiene.sh
?? scripts/test_phase4b_backup_restore_verification.sh
?? scripts/test_phase4b_config_env_hardening_gate.sh
?? scripts/test_phase4b_docker_compose_hardening.sh
?? scripts/test_phase4b_ebelge_export_reporting_mart.sh
?? scripts/test_phase4b_final_master_closure.sh
?? scripts/test_phase4b_finance_reporting_mart.sh
?? scripts/test_phase4b_flow_detail_page.sh
?? scripts/test_phase4b_go_no_go_rollout_gate.sh
?? scripts/test_phase4b_import_staging_tables.sh
?? scripts/test_phase4b_import_wizard_ui.sh
?? scripts/test_phase4b_infra_cleanup_production_hardening_final_closure.sh
?? scripts/test_phase4b_inventory_tests.sh
?? scripts/test_phase4b_issue_feedback_ui.sh
?? scripts/test_phase4b_logs_loki_readiness.sh
?? scripts/test_phase4b_materialized_cache_projection_standard.sh
?? scripts/test_phase4b_metrics_scrape_readiness.sh
?? scripts/test_phase4b_migration_chain_standard.sh
?? scripts/test_phase4b_migration_lifecycle_import_tests.sh
?? scripts/test_phase4b_negative_stock_policy.sh
?? scripts/test_phase4b_nginx_reverse_proxy_hardening.sh
?? scripts/test_phase4b_observability_baseline.sh
?? scripts/test_phase4b_observability_ops_console_final_closure.sh
?? scripts/test_phase4b_observability_ops_console_tests.sh
?? scripts/test_phase4b_opening_stock.sh
?? scripts/test_phase4b_ops_console_signal_contract.sh
?? scripts/test_phase4b_panel_ux_tests.sh
?? scripts/test_phase4b_payment_reconciliation_reporting_mart.sh
?? scripts/test_phase4b_permission_guard.sh
?? scripts/test_phase4b_pilot_data_readiness_contract.sh
?? scripts/test_phase4b_pilot_tenant_readiness_contract.sh
?? scripts/test_phase4b_pilot_uat_onboarding_baseline.sh
?? scripts/test_phase4b_pilot_uat_onboarding_final_closure.sh
?? scripts/test_phase4b_pilot_uat_onboarding_tests.sh
?? scripts/test_phase4b_production_cleanup_gate.sh
?? scripts/test_phase4b_production_hardening_tests.sh
?? scripts/test_phase4b_purchase_stock_increment.sh
?? scripts/test_phase4b_readmodel_reporting_tests.sh
?? scripts/test_phase4b_realtime_channel_contract.sh
?? scripts/test_phase4b_reference_seed_standard.sh
?? scripts/test_phase4b_role_matrix.sh
?? scripts/test_phase4b_runtime_flow_history.sh
?? scripts/test_phase4b_runtime_service_hardening.sh
?? scripts/test_phase4b_sales_stock_decrement.sh
?? scripts/test_phase4b_search_index_projection_tables.sh
?? scripts/test_phase4b_security_rbac_audit_final_closure.sh
?? scripts/test_phase4b_security_tests.sh
?? scripts/test_phase4b_stock_movement_engine.sh
?? scripts/test_phase4b_stock_reservation.sh
?? scripts/test_phase4b_stock_valuation.sh
?? scripts/test_phase4b_support_super_admin_boundary.sh
?? scripts/test_phase4b_tenant_access_checks.sh
?? scripts/test_phase4b_traces_tempo_readiness.sh
?? scripts/test_phase4b_uat_checklist_ui.sh
?? scripts/test_phase4b_uat_scenario_execution_contract.sh
?? scripts/test_phase4b_ui_api_implementation_plan.sh
?? scripts/test_phase4b_workflow_action_approval_contract.sh
?? scripts/test_phase4b_workflow_realtime_baseline.sh
?? scripts/test_phase4b_workflow_realtime_final_closure.sh
?? scripts/test_phase4b_workflow_realtime_tests.sh
?? scripts/test_phase4b_workflow_state_machine_contract.sh
?? sql/
?? step_gw_entry_live_sync_1.sh
?? step_gw_internal_key_live_1.sh
?? step_gw_internal_key_source_1.sh
?? tests/
?? tmp/
?? uat/
?? user-created-consumer
?? web/auto-parts-ui/
?? web/dist/
?? web/faz4d-final-closure/
?? web/faz5/
?? web/index.html
?? web/marketplace-discovery/
?? web/mobile-ready-pwa/
?? web/node_modules/
?? web/package-lock.json
?? web/package.json
?? web/panel/
?? web/parasut-discovery/
?? web/pilot-business-ui/
?? web/pilot-go-live/
?? web/pilot-monitoring/
?? web/pilot-support-feedback/
?? web/release-rollback-gate/
?? web/src/
?? web/tsconfig.json
?? web/tsconfig.tsbuildinfo
?? web/vite.config.ts
?? "| tenant_id          | uuid"
```

## 6-9.3 Deploy / Rollback Script Inventory

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf
./1_archive/root_sh/step_100_backup_run_api_gateway_script.sh
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh
./1_archive/root_sh/step_116_backup_api_gateway_before_auth_route.sh
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh
./1_archive/root_sh/step_126_backup_api_gateway_before_combined_gateway.sh
./1_archive/root_sh/step_130_backup_gateway_before_authz_layer.sh
./1_archive/root_sh/step_130_backup_nginx_before_rate_limit.sh
./1_archive/root_sh/step_131_add_nginx_global_rate_limit.sh
./1_archive/root_sh/step_133_reload_nginx_after_rate_limit.sh
./1_archive/root_sh/step_135_check_nginx_error_log.sh
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh
./1_archive/root_sh/step_13_backup_redis_tenant_namespace.sh
./1_archive/root_sh/step_16_backup_super_admin_policy.sh
./1_archive/root_sh/step_184_backup_panel_before_service_monitor.sh
./1_archive/root_sh/step_19_backup_postgres_rls.sh
./1_archive/root_sh/step_1_backup_account_mapping.sh
./1_archive/root_sh/step_1_backup_accounts_import.sh
./1_archive/root_sh/step_1_backup_accounts_seed.sh
./1_archive/root_sh/step_1_backup_alis_faturasi_engine.sh
./1_archive/root_sh/step_1_backup_auto_rules.sh
./1_archive/root_sh/step_1_backup_balance_sheet.sh
./1_archive/root_sh/step_1_backup_banka_ekstre.sh
./1_archive/root_sh/step_1_backup_banka_engine.sh
./1_archive/root_sh/step_1_backup_bilanco_engine.sh
./1_archive/root_sh/step_1_backup_cari_ekstre.sh
./1_archive/root_sh/step_1_backup_cash_flow.sh
./1_archive/root_sh/step_1_backup_chart_intelligence.sh
./1_archive/root_sh/step_1_backup_commission_engine.sh
./1_archive/root_sh/step_1_backup_commission_rule_versioning.sh
./1_archive/root_sh/step_1_backup_current_account_engine.sh
./1_archive/root_sh/step_1_backup_financial_consistency.sh
./1_archive/root_sh/step_1_backup_financial_event_engine.sh
./1_archive/root_sh/step_1_backup_gelir_tablosu_engine.sh
./1_archive/root_sh/step_1_backup_general_ledger.sh
./1_archive/root_sh/step_1_backup_income_statement.sh
./1_archive/root_sh/step_1_backup_journal_builder.sh
./1_archive/root_sh/step_1_backup_journal_engine.sh
./1_archive/root_sh/step_1_backup_kasa_ekstre.sh
./1_archive/root_sh/step_1_backup_kasa_engine.sh
./1_archive/root_sh/step_1_backup_ledger_balance_engine.sh
./1_archive/root_sh/step_1_backup_ledger_engine.sh
./1_archive/root_sh/step_1_backup_ledger_posting_engine.sh
./1_archive/root_sh/step_1_backup_merchant_payout_engine.sh
./1_archive/root_sh/step_1_backup_mizan_engine.sh
./1_archive/root_sh/step_1_backup_multi_account_ledger.sh
./1_archive/root_sh/step_1_backup_payment_engine.sh
./1_archive/root_sh/step_1_backup_period_closing.sh
./1_archive/root_sh/step_1_backup_reconciliation_engine.sh
./1_archive/root_sh/step_1_backup_satis_fatura_engine.sh
./1_archive/root_sh/step_1_backup_settlement_engine.sh
./1_archive/root_sh/step_1_backup_tahsilat_odeme_engine.sh
./1_archive/root_sh/step_1_backup_tahsilat_odeme_v2.sh
./1_archive/root_sh/step_1_backup_tax_engine.sh
./1_archive/root_sh/step_1_backup_tenant_test.sh
./1_archive/root_sh/step_1_backup_trial_balance.sh
./1_archive/root_sh/step_1_backup_ufk_engine.sh
./1_archive/root_sh/step_1_backup_ufk_event_engine.sh
./1_archive/root_sh/step_1_backup_ufk_event_journal.sh
./1_archive/root_sh/step_1_backup_wallet_transfer_engine.sh
./1_archive/root_sh/step_28_backup_audit_log_engine.sh
./1_archive/root_sh/step_293_fix_watchdog_nginx.sh
./1_archive/root_sh/step_294_find_real_nginx_route.sh
./1_archive/root_sh/step_296_fix_nginx_monitor_route.sh
./1_archive/root_sh/step_297_fix_nginx_monitor_route_proper.sh
./1_archive/root_sh/step_298_cleanup_nginx_backup.sh
./1_archive/root_sh/step_300_remove_duplicate_nginx_sites.sh
./1_archive/root_sh/step_303_fix_systemd_units.sh
./1_archive/root_sh/step_307_check_nginx_master_workers.sh
./1_archive/root_sh/step_308_hard_restart_nginx.sh
./1_archive/root_sh/step_309_find_real_nginx_listens.sh
./1_archive/root_sh/step_311_nginx_hard_reset.sh
./1_archive/root_sh/step_316_full_nginx_port_scan.sh
./1_archive/root_sh/step_317_trace_real_nginx_runtime.sh
./1_archive/root_sh/step_319_backup_panel_before_rewrite.sh
./1_archive/root_sh/step_31_backup_export_isolation.sh
./1_archive/root_sh/step_324_backup_status_engine.sh
./1_archive/root_sh/step_327_backup_watchdog_before_fail_memory.sh
./1_archive/root_sh/step_34_backup_backup_isolation.sh
./1_archive/root_sh/step_350_fix_nginx_monitor.sh
./1_archive/root_sh/step_351_clean_nginx_duplicates_and_fix_monitor.sh
./1_archive/root_sh/step_355d_restore_clean.sh
./1_archive/root_sh/step_355e_find_last_buildable_watchdog_backup.sh
./1_archive/root_sh/step_358_add_nginx_status_proxy.sh
./1_archive/root_sh/step_35_prepare_backup_dirs.sh
./1_archive/root_sh/step_367_restore_clean_panel_engine.sh
./1_archive/root_sh/step_36_run_backup_isolation_test.sh
./1_archive/root_sh/step_37_backup_event_bus.sh
./1_archive/root_sh/step_385_systemd_health_patch.sh
./1_archive/root_sh/step_387_force_systemd_priority.sh
./1_archive/root_sh/step_391_real_systemd_test.sh
./1_archive/root_sh/step_393_fix_systemd_pipeline.sh
./1_archive/root_sh/step_3_backup_jwt_tenant.sh
./1_archive/root_sh/step_405_backup_kernel.sh
./1_archive/root_sh/step_40_backup_event_retry.sh
./1_archive/root_sh/step_417_backup_query_gateway.sh
./1_archive/root_sh/step_421_backup_kernel_safe.sh
./1_archive/root_sh/step_422_backup_gateway_db_init.sh
./1_archive/root_sh/step_423h_systemd_real_error.sh
./1_archive/root_sh/step_42_backup_event_idempotency.sh
./1_archive/root_sh/step_44_backup_event_dlq.sh
./1_archive/root_sh/step_46_backup_event_store.sh
./1_archive/root_sh/step_49_backup_event_replay.sh
./1_archive/root_sh/step_51_backup_event_bus_store_integration.sh
./1_archive/root_sh/step_53_backup_journal_builder.sh
./1_archive/root_sh/step_56_backup_ledger_posting.sh
./1_archive/root_sh/step_58_backup_snapshot_engine.sh
./1_archive/root_sh/step_60_backup_real_redis_cache.sh
./1_archive/root_sh/step_63_backup_read_write_split.sh
./1_archive/root_sh/step_66_backup_reporting_store.sh
./1_archive/root_sh/step_69_backup_rate_limit.sh
./1_archive/root_sh/step_6_backup_jwt_middleware.sh
./1_archive/root_sh/step_79_install_nginx.sh
./1_archive/root_sh/step_80_prepare_nginx_dirs.sh
./1_archive/root_sh/step_81_disable_default_nginx_site.sh
./1_archive/root_sh/step_83_cleanup_old_nginx_sites.sh
./1_archive/root_sh/step_84_backup_nginx_ssl_split.sh
./1_archive/root_sh/step_85_reload_nginx_split.sh
./1_archive/root_sh/step_92_backup_nginx_before_redirect_fix.sh
./1_archive/root_sh/step_93_reload_nginx_after_redirect_fix.sh
./1_archive/root_sh/step_9_backup_tenant_event_pipeline.sh
./1_archive/root_sh/step_fix_1_backup_cari_service.sh
./1_archive/root_sh/step_fix_1_backup_cari_v2.sh
./1_archive/root_sh/step_fix_backup_banka_swift.sh
./1_archive/root_sh/step_fix_backup_cari_service_ekstre.sh
./1_archive/root_sh/step_fix_backup_kasa_parabirimi.sh
./1_archive/root_sh/step_fix_backup_satis_iskonto.sh
./_backup_archive/005_phase2_mission_control.sql.bak_20260423_081245
./_backup_archive/005_phase2_mission_control.sql.bak_20260423_081410
./_backup_archive/005_phase2_mission_control.sql.bak_20260423_081608
./_backup_archive/009_phase2_webhooks.sql.bak_20260423_155635
./_backup_archive/4c_1_1b_2_marketplace_scope_guard_report.md.bak
./_backup_archive/4c_1_1c_real_pilot_business_info.md.bak
./_backup_archive/4c_1_1d_scope_freeze_final_decision.md.bak
./_backup_archive/4c_1_1e_real_business_confirmation.md.bak
./_backup_archive/4c_1_1e_real_business_confirmation_report.md.bak
./_backup_archive/4c_1_1_pilot_isletme_secimi.md.bak
./_backup_archive/4d_marketplace_integrations_phase_registry.md.bak
./_backup_archive/AppShell.tsx.bak_early_warning_20260424_233046
./_backup_archive/AppShell.tsx.bak_incident_audit_20260424_235550
./_backup_archive/AppShell.tsx.bak_jobs_queue_20260424_130156
./_backup_archive/AppShell.tsx.bak_mission_20260424_123649
./_backup_archive/AppShell.tsx.bak_notification_monitor_20260424_164932
./_backup_archive/AppShell.tsx.bak_plugin_monitor_20260424_145939
./_backup_archive/AppShell.tsx.bak_publicapi_monitor_20260424_151728
./_backup_archive/AppShell.tsx.bak_realtime_monitor_20260425_005438
./_backup_archive/AppShell.tsx.bak_runtime_topology_20260425_002216
./_backup_archive/AppShell.tsx.bak_webhook_monitor_20260424_135929
./_backup_archive/AppShell.tsx.bak_webhook_monitor_20260424_135950
./_backup_archive/AppShell.tsx.bak_workflow_monitor_20260424_142635
./_backup_archive/App.tsx.bak_early_warning_20260424_233046
./_backup_archive/App.tsx.bak_incident_audit_20260424_235550
./_backup_archive/App.tsx.bak_jobs_queue_20260424_130156
./_backup_archive/App.tsx.bak_mission_20260424_123649
./_backup_archive/App.tsx.bak_notification_monitor_20260424_164932
./_backup_archive/App.tsx.bak_plugin_monitor_20260424_145939
./_backup_archive/App.tsx.bak_publicapi_monitor_20260424_151728
./_backup_archive/App.tsx.bak_realtime_monitor_20260425_005438
./_backup_archive/App.tsx.bak_runtime_topology_20260425_002216
./_backup_archive/App.tsx.bak_webhook_monitor_20260424_135929
./_backup_archive/App.tsx.bak_webhook_monitor_20260424_135950
./_backup_archive/App.tsx.bak_workflow_monitor_20260424_142635
./_backup_archive/claim_store.go.bak_20260423_221143
./_backup_archive/claim_store_test.go.bak_20260423_221143
./_backup_archive/control_panel.go.bak_early_warning_runtime_proxy_20260424_232711
./_backup_archive/control_panel.go.bak_fix_20260424_120626
./_backup_archive/control_panel.go.bak_incident_audit_runtime_proxy_20260424_235140
./_backup_archive/control_panel.go.bak_jobs_runtime_proxy_20260424_125918
./_backup_archive/control_panel.go.bak_mission_proxy_20260424_123233
./_backup_archive/control_panel.go.bak_notification_runtime_proxy_20260424_164510
./_backup_archive/control_panel.go.bak_plugin_runtime_proxy_20260424_145657
./_backup_archive/control_panel.go.bak_publicapi_runtime_proxy_20260424_151410
./_backup_archive/control_panel.go.bak_realtime_runtime_proxy_20260425_005153
./_backup_archive/control_panel.go.bak_runtime_topology_proxy_20260425_001731
./_backup_archive/control_panel.go.bak_webhook_runtime_proxy_20260424_135702
./_backup_archive/control_panel.go.bak_workflow_runtime_proxy_20260424_142345
./_backup_archive/EarlyWarningPage.test.tsx.bak_database_multi_fix_20260424_233625
./_backup_archive/early_warning_runtime_main.go.bak_20260424_231928
./_backup_archive/early_warning_runtime_main_test.go.bak_20260424_231928
./_backup_archive/enqueue_store.go.bak_20260423_221143
./_backup_archive/IncidentAuditPage.test.tsx.bak_multi_match_fix_20260425_000033
./_backup_archive/IncidentAuditPage.test.tsx.bak_multi_match_fix_20260425_000101
./_backup_archive/IncidentAuditPage.test.tsx.bak_multi_match_fix_20260425_000113
./_backup_archive/IncidentAuditPage.test.tsx.bak_multi_match_fix_20260425_000131
./_backup_archive/incident_timeline_store.go.bak_20260423_212947
./_backup_archive/JobsQueuePage.test.tsx.bak_default_fix_20260424_130444
./_backup_archive/jobs_runtime_main.go.bak_20260424_125407
./_backup_archive/jobs_runtime_main_test.go.bak_20260424_125407
./_backup_archive/ops_console_smoke_main.go.bak_realtime_targets_20260425_012718
./_backup_archive/ops_console_smoke_main_test.go.bak_realtime_targets_20260425_012718
./_backup_archive/RealtimeMonitorPage.test.tsx.bak_multi_match_fix_20260425_010045
./_backup_archive/register_handler_test.go.bak_20260423_162528
./_backup_archive/register_service.go.bak_20260423_162022
./_backup_archive/register_service_test.go.bak_20260423_162022
./_backup_archive/runtime_integration_test.go.bak_20260423_213619
./_backup_archive/runtime_integration_test.go.bak_20260424_080635
./_backup_archive/runtime_integration_test.go.bak_20260424_093211
./_backup_archive/service-registry-api.ts.bak_auth_20260424_121253
./_backup_archive/ServiceRegistryPage.test.tsx.bak_20260424_114546
./_backup_archive/ServiceRegistryPage.test.tsx.bak_auth_20260424_121253
./_backup_archive/ServiceRegistryPage.test.tsx.bak_session_20260424_121356
./_backup_archive/ServiceRegistryPage.test.tsx.bak_tsfix_20260424_121654
./_backup_archive/ServiceRegistryPage.test.tsx.bak_vifn_20260424_121915
./_backup_archive/ServiceRegistryPage.tsx.bak_20260424_114546
./_backup_archive/ServiceRegistryPage.tsx.bak_auth_20260424_121253
./_backup_archive/status_panel_store.go.bak_20260423_212947
./_backup_archive/types.ts.bak_20260424_135950
./_backup_archive/version_store.go.bak_20260424_080029
./_backup_archive/version_store_test.go.bak_20260424_080029
./_backup_archive/webhook-monitor-api.ts.bak_20260424_135950
./_backup_archive/WorkflowMonitorPage.test.tsx.bak_multi_text_fix_20260424_143033
./.backup/lvl10_2_10_5_edge_security_cert_ops_20260422_061143/deploy/edge/scripts/render_edge_config.sh
./.backup/lvl10_fix_cert_paths_20260422_072601/pix2pi_edge_live.conf
./.backup/lvl10_fix_log_format_order_20260422_072447/pix2pi_log_format.conf
./.backup/lvl10_fix_nginx_logging_context_20260422_072340/pix2pi_logging.conf
./.backup/lvl10_live_finalize_20260422_063146/etc/nginx/nginx.conf
./.backup/lvl10_live_finalize_20260422_063146/etc/nginx/sites-available/default
```

## 6-9.4 Nginx Syntax

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

## 6-9.5 Systemd / Docker Runtime Inventory

```text
  dm-event.service                                                                          loaded    inactive dead    Device-mapper event daemon
  docker.service                                                                            loaded    active   running Docker Application Container Engine
  lvm2-monitor.service                                                                      loaded    active   exited  Monitoring of LVM2 mirrors, snapshots etc. using dmeventd or progress polling
  lvm2-pvscan@8:3.service                                                                   loaded    active   exited  LVM event activation on device 8:3
  lvm2-pvscan@8:4.service                                                                   loaded    active   exited  LVM event activation on device 8:4
  nginx.service                                                                             loaded    active   running A high performance web server and a reverse proxy server
  pix2pi-accounting.service                                                                 loaded    active   running Pix2pi Accounting Service
  pix2pi-api-gateway.service                                                                loaded    active   running Pix2pi API Gateway
  pix2pi-auth.service                                                                       loaded    active   running Pix2pi Auth Service
  pix2pi-early-warning-runtime.service                                                      loaded    active   running Pix2pi Early Warning Runtime Monitor
  pix2pi-identity.service                                                                   loaded    active   running Pix2pi Identity Service
  pix2pi-incident-audit-runtime.service                                                     loaded    active   running Pix2pi Incident Audit Runtime Monitor
  pix2pi-jobs-runtime.service                                                               loaded    active   running Pix2pi Jobs Runtime Monitor
  pix2pi-mission-control.service                                                            loaded    active   running Pix2pi Mission Control
  pix2pi-notification-runtime.service                                                       loaded    active   running Pix2pi Notification Runtime Monitor
  pix2pi-panel.service                                                                      loaded    active   running Pix2pi Control Panel
  pix2pi-plugin-runtime.service                                                             loaded    active   running Pix2pi Plugin Runtime Monitor
  pix2pi-publicapi-runtime.service                                                          loaded    active   running Pix2pi Public API Runtime Monitor
  pix2pi-query-read-model.service                                                           loaded    active   running Pix2pi Query Read Model
  pix2pi-realtime-runtime.service                                                           loaded    active   running Pix2pi Realtime Channel Runtime Monitor
  pix2pi-runtime-topology.service                                                           loaded    active   running Pix2pi Runtime Health Topology Monitor
  pix2pi-service-registry.service                                                           loaded    active   running Pix2pi Service Registry
  pix2pi-user-created-consumer.service                                                      loaded    active   running Pix2pi User Created Consumer
  pix2pi-webhook-runtime.service                                                            loaded    active   running Pix2pi Webhook Runtime Monitor
  pix2pi-workflow-runtime.service                                                           loaded    active   running Pix2pi Workflow Runtime Monitor
  snapd.core-fixup.service                                                                  loaded    inactive dead    Automatically repair incorrect owner/permissions on core devices
  systemd-udevd.service                                                                     loaded    active   running Rule-based Manager for Device Events and Files

NAMES                     IMAGE                             STATUS                PORTS
pix2pi_nats               nats:2.10-alpine                  Up 3 seconds          0.0.0.0:4222->4222/tcp, [::]:4222->4222/tcp, 0.0.0.0:8222->8222/tcp, [::]:8222->8222/tcp, 6222/tcp
pix2pi-redis              redis:7-alpine                    Up 9 days             0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp
pix2pi_pg_replica         postgres:16                       Up 9 days             0.0.0.0:5434->5432/tcp, [::]:5434->5432/tcp
pix2pi-mission-control    deploy-mission-control            Up 9 days             9001/tcp, 0.0.0.0:9101->5860/tcp, [::]:9101->5860/tcp
pix2pi-service-registry   deploy-service-registry           Up 9 days             
pix2pi-identity-api       deploy-identity-api               Up 9 days             0.0.0.0:9002->9002/tcp, [::]:9002->9002/tcp
pix2pi_grafana            grafana/grafana:latest            Up 9 days             0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp
pix2pi_promtail           grafana/promtail:2.9.8            Up 9 days             
pix2pi_loki               grafana/loki:2.9.8                Up 9 days             0.0.0.0:3100->3100/tcp, [::]:3100->3100/tcp
pix2pi_prometheus         prom/prometheus:latest            Up 9 days             0.0.0.0:9090->9090/tcp, [::]:9090->9090/tcp
pix2pi_node_exporter      prom/node-exporter:latest         Up 9 days             0.0.0.0:9100->9100/tcp, [::]:9100->9100/tcp
pix2pi_tempo              grafana/tempo:2.6.1               Up 9 days             0.0.0.0:3200->3200/tcp, [::]:3200->3200/tcp, 0.0.0.0:4317-4318->4317-4318/tcp, [::]:4317-4318->4317-4318/tcp
pix2pi-api-gateway        kong:3.7                          Up 9 days (healthy)   
pix2pi_pg                 postgres:16                       Up 3 days             0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
pix2pi_cadvisor           gcr.io/cadvisor/cadvisor:latest   Up 9 days (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

## 6-9.6 Backup / Release Evidence Directory Inventory

```text
backups/faz3_9_5_1d_procurement_documents_db_test_20260425_205525/procurement_before_db_test.tar.gz
backups/faz3_9_5_1e_procurement_documents_db_test_run_20260425_205555/procurement_before_db_test_run.tar.gz
backups/faz3_9_5_1e_procurement_documents_db_test_run_20260425_205555/procurement_documents_migrations_before_db_test_run.tar.gz
backups/faz3_9_5_1f_procurement_documents_rls_test_20260425_205705/procurement_before_rls_test.tar.gz
backups/faz3_9_5_1f_procurement_documents_rls_test_20260425_211056/procurement_before_rls_test.tar.gz
backups/faz3_9_5_2a_procurement_contract_20260425_205922/procurement_before_contract.tar.gz
backups/faz3_9_5_2b_procurement_validation_test_20260425_210017/procurement_before_validation_test.tar.gz
backups/faz3_9_5_3a_postgres_purchase_order_repository_20260425_210203/procurement_before_purchase_order_repository.tar.gz
backups/faz3_9_5_3b_purchase_order_repository_test_20260425_210314/procurement_before_purchase_order_repository_test.tar.gz
backups/faz3_9_5_4a_postgres_purchase_receipt_repository_20260425_210458/procurement_before_purchase_receipt_repository.tar.gz
backups/faz3_9_5_4b_purchase_receipt_repository_test_20260425_210610/procurement_before_purchase_receipt_repository_test.tar.gz
backups/faz3_9_5_5a_postgres_purchase_invoice_repository_20260425_210729/procurement_before_purchase_invoice_repository.tar.gz
backups/faz3_9_5_5b_purchase_invoice_repository_test_20260425_210803/procurement_before_purchase_invoice_repository_test.tar.gz
backups/faz3_9_5_6a_procurement_full_smoke_20260425_210832/procurement_before_full_smoke.tar.gz
backups/faz3_9_5_6a_procurement_full_smoke_20260425_210832/procurement_migrations_before_full_smoke.tar.gz
backups/faz3_9_6_1a_journal_contract_20260425_210932/db_migrations_before_journal.tar.gz
backups/faz3_9_6_1b_journal_contract_test_20260425_211339/journal_before_contract_test.tar.gz
backups/faz3_9_6_1b_journal_contract_test_20260425_211339/journal_migrations_before_contract_test.tar.gz
backups/faz3_9_6_1c_journal_apply_20260425_211413/db_migrations_before_journal_apply.tar.gz
backups/faz3_9_6_1c_journal_apply_20260425_211413/journal_before_apply.tar.gz
backups/faz3_9_6_1c_journal_apply_20260425_211413/schema_before_journal.sql
backups/faz3_9_6_1d_journal_db_test_20260425_211547/journal_before_db_test.tar.gz
backups/faz3_9_6_1e_journal_db_test_run_20260425_211614/journal_before_db_test_run.tar.gz
backups/faz3_9_6_1e_journal_db_test_run_20260425_211614/journal_migrations_before_db_test_run.tar.gz
backups/faz3_9_6_1f_journal_rls_test_20260425_212230/journal_before_rls_test.tar.gz
backups/faz3_9_6_2a_journal_contract_20260425_212347/journal_before_contract.tar.gz
backups/faz3_9_6_2b_journal_validation_test_20260425_212428/journal_before_validation_test.tar.gz
backups/faz3_9_6_3a_postgres_journal_repository_20260425_212558/journal_before_repository.tar.gz
backups/faz3_9_6_3b_postgres_journal_repository_test_20260425_212645/journal_before_repository_test.tar.gz
backups/faz3_9_6_4a_postgres_journal_posting_repository_20260425_212745/journal_before_posting_repository.tar.gz
backups/faz3_9_6_4b_postgres_journal_posting_repository_test_20260425_212826/journal_before_posting_repository_test.tar.gz
backups/faz3_9_6_4c_journal_posting_cleanup_fix_20260425_212920/journal_before_cleanup_fix.tar.gz
backups/faz3_9_6_5a_journal_full_smoke_20260425_213005/journal_before_full_smoke.tar.gz
backups/faz3_9_6_5a_journal_full_smoke_20260425_213005/journal_migrations_before_full_smoke.tar.gz
backups/faz3_9_7_1a_ledger_contract_20260425_213133/db_migrations_before_ledger.tar.gz
backups/faz3_9_7_1b_ledger_contract_test_20260425_213215/ledger_before_contract_test.tar.gz
backups/faz3_9_7_1b_ledger_contract_test_20260425_213215/ledger_migrations_before_contract_test.tar.gz
backups/faz3_9_7_1c_ledger_apply_20260425_213255/db_migrations_before_ledger_apply.tar.gz
backups/faz3_9_7_1c_ledger_apply_20260425_213255/ledger_before_apply.tar.gz
backups/faz3_9_7_1c_ledger_apply_20260425_213255/schema_before_ledger.sql
backups/faz3_9_7_1d_ledger_db_test_20260425_213403/ledger_before_db_test.tar.gz
backups/faz3_9_7_1e_fix_ledger_fmt_20260425_213537/ledger_before_fmt_fix.tar.gz
backups/faz3_9_7_1e_ledger_db_test_run_20260425_213440/ledger_before_db_test_run.tar.gz
backups/faz3_9_7_1e_ledger_db_test_run_20260425_213440/ledger_migrations_before_db_test_run.tar.gz
backups/faz3_9_7_1f_ledger_rls_test_20260425_213622/ledger_before_rls_test.tar.gz
backups/faz3_9_7_2a_ledger_contract_20260425_213729/ledger_before_contract.tar.gz
backups/faz3_9_7_2b_ledger_validation_test_20260425_213809/ledger_before_validation_test.tar.gz
backups/faz3_9_7_3a_postgres_account_movement_repository_20260425_213931/ledger_before_account_movement_repository.tar.gz
backups/faz3_9_7_3b_account_movement_repository_test_20260425_214031/ledger_before_account_movement_repository_test.tar.gz
backups/faz3_9_7_4a_postgres_ledger_balance_repository_20260425_214231/ledger_before_balance_repository.tar.gz
backups/faz3_9_7_4b_ledger_balance_repository_test_20260425_214337/ledger_before_balance_repository_test.tar.gz
backups/faz3_9_7_5a_ledger_full_smoke_20260425_214445/ledger_before_full_smoke.tar.gz
backups/faz3_9_7_5a_ledger_full_smoke_20260425_214445/ledger_migrations_before_full_smoke.tar.gz
backups/faz3_9_8_1a_chart_of_accounts_contract_20260425_214552/db_migrations_before_chart_of_accounts.tar.gz
backups/faz3_9_8_1b_chart_of_accounts_contract_test_20260425_214808/chartofaccounts_before_contract_test.tar.gz
backups/faz3_9_8_1b_chart_of_accounts_contract_test_20260425_214808/chart_of_accounts_migrations_before_contract_test.tar.gz
backups/faz3_9_8_1c_chart_of_accounts_apply_20260425_214845/chartofaccounts_before_apply.tar.gz
backups/faz3_9_8_1c_chart_of_accounts_apply_20260425_214845/db_migrations_before_chart_of_accounts_apply.tar.gz
backups/faz3_9_8_1c_chart_of_accounts_apply_20260425_214845/schema_before_chart_of_accounts.sql
backups/faz3_9_8_1d_chart_of_accounts_db_test_20260425_214938/chartofaccounts_before_db_test.tar.gz
backups/faz3_9_8_1e_chart_of_accounts_db_test_run_20260425_215037/chartofaccounts_before_db_test_run.tar.gz
backups/faz3_9_8_1e_chart_of_accounts_db_test_run_20260425_215037/chart_of_accounts_migrations_before_db_test_run.tar.gz
backups/faz3_9_8_1f_chart_of_accounts_rls_test_20260425_215106/chartofaccounts_before_rls_test.tar.gz
backups/faz3_9_8_1f_chart_of_accounts_rls_test_20260425_215141/chartofaccounts_before_rls_test.tar.gz
backups/faz3_9_8_2a_chart_of_accounts_contract_20260425_215329/chartofaccounts_before_contract.tar.gz
backups/faz3_9_8_2b_chart_of_accounts_validation_test_20260425_215648/chartofaccounts_before_validation_test.tar.gz
backups/faz3_9_8_3a_postgres_chart_account_repository_20260425_215759/chartofaccounts_before_chart_account_repository.tar.gz
backups/faz3_9_8_3b_chart_account_repository_test_20260425_215851/chartofaccounts_before_chart_account_repository_test.tar.gz
backups/faz3_9_8_4a_postgres_account_mapping_rule_repository_20260425_215954/chartofaccounts_before_mapping_rule_repository.tar.gz
backups/faz3_9_8_4b_account_mapping_rule_repository_test_20260425_220053/chartofaccounts_before_mapping_rule_repository_test.tar.gz
backups/faz3_9_8_5a_chart_of_accounts_full_smoke_20260425_220130/chartofaccounts_before_full_smoke.tar.gz
backups/faz3_9_8_5a_chart_of_accounts_full_smoke_20260425_220130/chart_of_accounts_migrations_before_full_smoke.tar.gz
backups/faz3_9_9_1a_tax_contract_20260425_220240/db_migrations_before_tax.tar.gz
backups/faz3_9_9_1b_tax_contract_test_20260425_220318/tax_before_contract_test.tar.gz
backups/faz3_9_9_1b_tax_contract_test_20260425_220318/tax_migrations_before_contract_test.tar.gz
backups/faz3_9_9_1c_tax_apply_20260425_220354/db_migrations_before_tax_apply.tar.gz
backups/faz3_9_9_1c_tax_apply_20260425_220354/schema_before_tax.sql
backups/faz3_9_9_1c_tax_apply_20260425_220354/tax_before_apply.tar.gz
backups/faz3_9_9_1d_tax_db_test_20260425_220500/tax_before_db_test.tar.gz
backups/faz3_9_9_1e_tax_db_test_run_20260425_220528/tax_before_db_test_run.tar.gz
backups/faz3_9_9_1e_tax_db_test_run_20260425_220528/tax_migrations_before_db_test_run.tar.gz
backups/faz3_9_9_1f_tax_rls_test_20260425_220601/tax_before_rls_test.tar.gz
backups/faz3_9_9_2a_tax_contract_20260425_220709/tax_before_contract.tar.gz
backups/faz3_9_9_2b_tax_validation_test_20260425_220739/tax_before_validation_test.tar.gz
backups/faz3_9_9_3a_postgres_tax_code_repository_20260425_220837/tax_before_tax_code_repository.tar.gz
backups/faz3_9_9_3b_tax_code_repository_test_20260425_220916/tax_before_tax_code_repository_test.tar.gz
backups/faz3_9_9_4a_postgres_tax_rate_repository_20260425_221024/tax_before_tax_rate_repository.tar.gz
backups/faz3_9_9_4b_tax_rate_repository_test_20260425_221102/tax_before_tax_rate_repository_test.tar.gz
backups/faz3_9_9_5a_postgres_tax_transaction_repository_20260425_221209/tax_before_tax_transaction_repository.tar.gz
backups/faz3_9_9_5b_tax_transaction_repository_test_20260425_221308/tax_before_tax_transaction_repository_test.tar.gz
backups/faz3_9_9_6a_tax_full_smoke_20260425_221334/tax_before_full_smoke.tar.gz
backups/faz3_9_9_6a_tax_full_smoke_20260425_221334/tax_migrations_before_full_smoke.tar.gz
backups/faz4_14_1_4A_real_dsn_repair_20260427_074950/.env
backups/faz4_14_1_4A_real_dsn_repair_20260427_075042/.env
backups/faz4_14_1_4B_primary_write_dsn_guard_20260427_075227/.env
backups/faz6_7_real_audit_fix_20260501_145840/audit_faz6_7_real_implementation.sh.backup
backups/faz6_9_nats_monitoring_fix_20260501_152330/docker-compose.yml.backup
backups/faz6_9_nats_monitoring_fix_20260501_152330/pix2pi_nats_inspect.json
backups/faz6_9_nats_monitoring_fix_20260501_152330/pix2pi_nats_logs_tail_200.log
backups/faz6_9_smoke_port_correction_20260501_151902/pix2pi_postdeploy_smoke.sh.backup
docs/faz6/evidence/FAZ_6_2_DB_L8_AUDIT_EVIDENCE.md
docs/faz6/evidence/FAZ_6_2_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_3_MULTI_NODE_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_3_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_4_EVENT_BUS_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_4_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_5_OBSERVABILITY_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_5_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_6_BACKUP_RESTORE_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_6_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_7_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_7_SECURITY_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_8_PERFORMANCE_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_8_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_9_NATS_MONITORING_FIX_EVIDENCE.md
docs/faz6/evidence/FAZ_6_9_POSTDEPLOY_SMOKE_EVIDENCE.md
docs/faz6/evidence/FAZ_6_9_PREDEPLOY_CHECK_EVIDENCE.md
docs/faz6/evidence/FAZ_6_9_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_9_RELEASE_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_9_ROLLBACK_READINESS_EVIDENCE.md
```

## 6-9.7 Public GET Content Check Candidates

```text
===== https://pix2pi.com.tr/faz4d/pilot-go-live/ =====
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi Controlled Pilot Go-Live</title>
  <style>
    :root {
      --bg: #07111f;
      --card: #101d31;
      --card-2: #152640;
      --text: #eef6ff;
      --muted: #a8b8cc;
      --line: rgba(255, 255, 255, 0.12);
      --accent: #41b8ff;
      --ok: #38d996;
      --warn: #ffcf5a;
      --danger: #ff7d7d;
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      font-family: Arial, Helvetica, sans-serif;
      color: var(--text);
      background: radial-gradient(circle at top left, #193f66, var(--bg) 54%);
    }

    .page {
      width: min(1180px, calc(100% - 32px));
      margin: 0 auto;
      padding: 28px 0 38px;
    }

    .hero {
      padding: 26px;
      border: 1px solid var(--line);
      border-radius: 22px;
      background: linear-gradient(135deg, rgba(56, 217, 150, 0.16), rgba(16, 29, 49, 0.94));
      box-shadow: 0 18px 40px rgba(0, 0, 0, 0.28);
    }

    .eyebrow {
      color: var(--ok);
      font-weight: 700;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      font-si
===== https://pix2pi.com.tr/ =====
Pix2pi OK

HTTP_STATUS=200 SIZE=10 TIME=0.114544

```

## 6-9.8 Local Smoke Probe

```text
===== PIX2PI POSTDEPLOY SMOKE BASLADI =====
===== identity health =====
TRY_1=http://127.0.0.1:9002/health
http_code=200 time_total=0.001789 size=33
identity health OK ✅

===== api gateway health =====
TRY_1=http://127.0.0.1:9010/health
http_code=200 time_total=0.000840 size=21
api gateway health OK ✅

===== prometheus ready =====
TRY_1=http://127.0.0.1:9090/-/ready
http_code=200 time_total=0.002118 size=28
prometheus ready OK ✅

===== grafana health =====
TRY_1=http://127.0.0.1:3001/api/health
http_code=200 time_total=0.001623 size=101
grafana health OK ✅

===== node exporter metrics =====
TRY_1=http://127.0.0.1:9100/metrics
http_code=200 time_total=0.018127 size=73755
node exporter metrics OK ✅

===== cadvisor metrics =====
TRY_1=http://127.0.0.1:8080/metrics
http_code=200 time_total=0.275835 size=7731192
cadvisor metrics OK ✅

===== nats monitoring varz =====
TRY_1=http://127.0.0.1:8222/varz
http_code=200 time_total=0.002943 size=1694
nats monitoring varz OK ✅

PASS_COUNT=7
WARN_COUNT=0
FAZ_6_9_POSTDEPLOY_SMOKE_STATUS=COMPLETE ✅
POSTDEPLOY_DESTRUCTIVE_ACTION=NO ✅
FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_9_POSTDEPLOY_SMOKE_EVIDENCE.md
```

## 6-9.9 Predeploy Probe

```text
===== PIX2PI PREDEPLOY CHECK BASLADI =====
FAZ_6_9_PREDEPLOY_CHECK_STATUS=COMPLETE ✅
PREDEPLOY_DESTRUCTIVE_ACTION=NO ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_9_PREDEPLOY_CHECK_EVIDENCE.md
```

## 6-9.10 Rollback Readiness Probe

```text
===== PIX2PI ROLLBACK READINESS BASLADI =====
FAZ_6_9_ROLLBACK_READINESS_STATUS=COMPLETE ✅
ROLLBACK_DESTRUCTIVE_ACTION=NO ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_9_ROLLBACK_READINESS_EVIDENCE.md
```

## 6-9.11 Runtime Audit Interpretation

```text
6-9.1 Host inventory collected OK ✅
6-9.2 Git/release inventory collected OK ✅
6-9.3 Deploy/rollback script inventory collected OK ✅
6-9.4 Nginx syntax collected OK ✅
6-9.5 Systemd/docker runtime inventory collected OK ✅
6-9.6 Backup/release evidence directory inventory collected OK ✅
6-9.7 Public GET content check candidates collected OK ✅
6-9.8 Local smoke probe collected OK ✅
6-9.9 Predeploy probe collected OK ✅
6-9.10 Rollback readiness probe collected OK ✅
FAZ_6_9_RUNTIME_AUDIT=COMPLETE ✅
```
