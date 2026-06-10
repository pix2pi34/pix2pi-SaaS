# FAZ 6-9 Predeploy Check Evidence

Generated At: 2026-05-01T15:23:34+03:00  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu script deploy yapmaz. Sadece deploy oncesi guvenli kontrol evidence uretir.

FAZ_6_9_PREDEPLOY_CHECK=STARTED ✅

---


## 6-9.2.1 Git Status

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

## 6-9.2.2 Disk / Memory

```text
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              1.6G  2.6M  1.6G   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  194G   84G  103G  45% /
tmpfs                              7.9G     0  7.9G   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          2.0G  260M  1.6G  15% /boot
/dev/sda1                          1.1G  6.1M  1.1G   1% /boot/efi
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/a8c3a18b0bd7e3de5d16d40100386d3ea08be31a9810e6f7c0888575e194319a/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/d2932c2de6ce9849cf1091484ac56e35a51cc13c76e2ecfc9f0337e1a48f8bdd/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/8e08d680875fd05f703a251bf86f471dff08b636dcf1c9f11386c42bd2c24c2a/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/5c7f998b4dfbd13c2a7746b255680a765350c04797323ec2f012f335d88f2a10/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/8db4dd7c772b223317245d437f04d93b54e7dff83a28924b026aa4627dbf09c3/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/0713c8fded3b70688d57dcd396c223c0547a1f773f4847a502a4d6b7246c5a62/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/a8acca0ccd95879440af9d725b532fbb26c051fce5a1700f2481cc9ad33c4e15/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/ad8c87cdb8b4f80befbcc3dd291ca4d726c951396bcdc55ff9b5cb279f918fc1/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/03df9e174d4b9325cf011fbb9cc235042c975aa75040a3b00c4a88b6270db15d/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/ec0df24be1f5a11d4a24faf42aa85bdcf0b6808a1e34a6f6dc73fb82a7fd426d/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/df7635e5431a5d93c6dc51e99f5faac9068e89525f34d11b88abd011bee20604/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/cbb651d2b94ebdbd40d0804976c0fe595932a653b969cf4bad29ca1bbb9a079c/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/9f2858e2f2174c8b3375b3fca4a15fe528511e09b5fa301b98c83dc6d10ec113/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/5ad97030659f8f15bcba1b3f2ab1258e09f777dfa94adcc129003791dd8b588a/merged
tmpfs                              1.6G  4.0K  1.6G   1% /run/user/0
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/9a7b7828e46f3f9d05283f70d7f7be7bf4aab326248f53881f69a27a60eaf9e0/merged

               total        used        free      shared  buff/cache   available
Mem:            15Gi       2.0Gi       9.6Gi        55Mi       4.0Gi        13Gi
Swap:          2.0Gi        13Mi       2.0Gi

 15:23:34 up 9 days,  8:42,  2 users,  load average: 0.47, 0.53, 0.56
```

## 6-9.2.3 Backup Directory Check

```text
drwxr-xr-x 591 root root 61440 May  1 15:23 backups
drwxr-xr-x   2 root root  4096 May  1 15:23 docs/faz6/evidence
backups/faz3_9_6_4b_postgres_journal_posting_repository_test_20260425_212826
backups/faz3_9_5_3a_postgres_purchase_order_repository_20260425_210203
backups/faz3_9_11_1a_fiscal_sequence_contract_20260426_061739
backups/faz3_9_10_6a_cashbank_full_smoke_20260426_061613
backups/faz4b_16_5_go_no_go_rollout_gate_20260430_065256
backups/faz4b_16_5_go_no_go_rollout_gate_20260430_065256/docs
backups/faz4b_16_5_go_no_go_rollout_gate_20260430_065256/scripts
backups/faz4_14_2_1_db_backup_pitr_readiness_20260427_133811
backups/faz4_14_2_1_db_backup_pitr_readiness_20260427_133811/docs
backups/faz4_14_2_1_db_backup_pitr_readiness_20260427_133811/scripts
backups/faz3_9_4_1a_sales_documents_contract_20260425_200950
backups/faz4_17_1_reporting_runtime_wiring_plan_20260427_184628
backups/faz4_17_1_reporting_runtime_wiring_plan_20260427_184628/docs
backups/faz4_17_1_reporting_runtime_wiring_plan_20260427_184628/scripts
backups/faz4_15_3R_dry_run_exit_fix_20260427_175809
backups/faz4_15_3R_dry_run_exit_fix_20260427_175809/docs
backups/faz4_15_3R_dry_run_exit_fix_20260427_175809/scripts
backups/faz3_9_1_3a_master_party_contract_20260425_080715
backups/event_replay_real
backups/faz6_2_real_implementation_audit_20260501_142210
```

## 6-9.2.4 Nginx Syntax Check

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

## 6-9.2.5 Docker / Systemd Inventory

```text
NAMES                     IMAGE                             STATUS                PORTS
pix2pi_nats               nats:2.10-alpine                  Up 4 seconds          0.0.0.0:4222->4222/tcp, [::]:4222->4222/tcp, 0.0.0.0:8222->8222/tcp, [::]:8222->8222/tcp, 6222/tcp
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
```

## 6-9.2.6 Env File Presence

```text
OK ✅ .env
-rw------- 1 root root 410 Apr 27 07:52 .env
WARN ⚠️ missing .env.production
OK ✅ /etc/pix2pi/ports.env
-rw------- 1 root root 1023 Apr 25 00:43 /etc/pix2pi/ports.env
OK ✅ /opt/pix2pi/orchestrator/env/common.env
-rw-r--r-- 1 root root 398 Apr 18 09:11 /opt/pix2pi/orchestrator/env/common.env
```

## 6-9.2.7 Listening Ports

```text
LISTEN 0      4096         0.0.0.0:6379       0.0.0.0:*    users:(("docker-proxy",pid=3788,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096       127.0.0.1:9010       0.0.0.0:*    users:(("pix2pi-api-gate",pid=4016338,fd=7))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:8080       0.0.0.0:*    users:(("docker-proxy",pid=4033,fd=8))                                                                                                                                                                                                                     
LISTEN 0      511          0.0.0.0:8002       0.0.0.0:*    users:(("nginx",pid=4520,fd=12),("nginx",pid=4519,fd=12),("nginx",pid=4518,fd=12),("nginx",pid=4517,fd=12),("nginx",pid=4516,fd=12),("nginx",pid=4515,fd=12),("nginx",pid=4514,fd=12),("nginx",pid=4513,fd=12),("nginx",pid=2172,fd=12))                   
LISTEN 0      511          0.0.0.0:8000       0.0.0.0:*    users:(("nginx",pid=4520,fd=9),("nginx",pid=4519,fd=9),("nginx",pid=4518,fd=9),("nginx",pid=4517,fd=9),("nginx",pid=4516,fd=9),("nginx",pid=4515,fd=9),("nginx",pid=4514,fd=9),("nginx",pid=4513,fd=9),("nginx",pid=2172,fd=9))                            
LISTEN 0      511          0.0.0.0:8001       0.0.0.0:*    users:(("nginx",pid=4520,fd=10),("nginx",pid=4519,fd=10),("nginx",pid=4518,fd=10),("nginx",pid=4517,fd=10),("nginx",pid=4516,fd=10),("nginx",pid=4515,fd=10),("nginx",pid=4514,fd=10),("nginx",pid=4513,fd=10),("nginx",pid=2172,fd=10))                   
LISTEN 0      4096         0.0.0.0:4222       0.0.0.0:*    users:(("docker-proxy",pid=1036365,fd=8))                                                                                                                                                                                                                  
LISTEN 0      4096         0.0.0.0:5433       0.0.0.0:*    users:(("docker-proxy",pid=1294029,fd=8))                                                                                                                                                                                                                  
LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=2611616,fd=9),("nginx",pid=308628,fd=9),("nginx",pid=308626,fd=9),("nginx",pid=308625,fd=9),("nginx",pid=308624,fd=9),("nginx",pid=308623,fd=9),("nginx",pid=308621,fd=9),("nginx",pid=308620,fd=9),("nginx",pid=308619,fd=9))         
LISTEN 0      4096         0.0.0.0:8222       0.0.0.0:*    users:(("docker-proxy",pid=1036391,fd=8))                                                                                                                                                                                                                  
LISTEN 0      511          0.0.0.0:443        0.0.0.0:*    users:(("nginx",pid=2611616,fd=10),("nginx",pid=308628,fd=10),("nginx",pid=308626,fd=10),("nginx",pid=308625,fd=10),("nginx",pid=308624,fd=10),("nginx",pid=308623,fd=10),("nginx",pid=308621,fd=10),("nginx",pid=308620,fd=10),("nginx",pid=308619,fd=10))
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4520,fd=21),("nginx",pid=2172,fd=21))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4519,fd=20),("nginx",pid=2172,fd=20))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4518,fd=19),("nginx",pid=2172,fd=19))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4517,fd=18),("nginx",pid=2172,fd=18))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4516,fd=17),("nginx",pid=2172,fd=17))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4515,fd=16),("nginx",pid=2172,fd=16))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4514,fd=15),("nginx",pid=2172,fd=15))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4513,fd=11),("nginx",pid=2172,fd=11))                                                                                                                                                                                                  
LISTEN 0      511        127.0.0.1:8099       0.0.0.0:*    users:(("nginx",pid=2611616,fd=8),("nginx",pid=308628,fd=8),("nginx",pid=308626,fd=8),("nginx",pid=308625,fd=8),("nginx",pid=308624,fd=8),("nginx",pid=308623,fd=8),("nginx",pid=308621,fd=8),("nginx",pid=308620,fd=8),("nginx",pid=308619,fd=8))         
LISTEN 0      4096         0.0.0.0:9090       0.0.0.0:*    users:(("docker-proxy",pid=2893,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:9100       0.0.0.0:*    users:(("docker-proxy",pid=3938,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:6379          [::]:*    users:(("docker-proxy",pid=3795,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:8080          [::]:*    users:(("docker-proxy",pid=4051,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096               *:8091             *:*    users:(("query-read-mode",pid=6735,fd=3))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:4222          [::]:*    users:(("docker-proxy",pid=1036374,fd=8))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:5433          [::]:*    users:(("docker-proxy",pid=1294037,fd=8))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:8222          [::]:*    users:(("docker-proxy",pid=1036398,fd=8))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:9090          [::]:*    users:(("docker-proxy",pid=2902,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:9100          [::]:*    users:(("docker-proxy",pid=3958,fd=8))                                                                                                                                                                                                                     
```

## 6-9.2.8 Health Timing Probe

```text
===== http://127.0.0.1:9001/health =====
curl: (7) Failed to connect to 127.0.0.1 port 9001 after 0 ms: Connection refused
http_code=000 time_total=0.000273
WARN ⚠️ probe failed
===== http://127.0.0.1:9010/health =====
http_code=200 time_total=0.000710
===== http://127.0.0.1:9090/-/ready =====
http_code=200 time_total=0.001081
===== http://127.0.0.1:3000/api/health =====
curl: (7) Failed to connect to 127.0.0.1 port 3000 after 0 ms: Connection refused
http_code=000 time_total=0.000503
WARN ⚠️ probe failed
===== http://127.0.0.1:8222/varz =====
http_code=200 time_total=0.001548
```

## Predeploy Final Seal

```text
FAZ_6_9_PREDEPLOY_CHECK_STATUS=COMPLETE ✅
PREDEPLOY_DESTRUCTIVE_ACTION=NO ✅
```
