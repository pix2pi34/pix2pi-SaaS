# FAZ 1-2.3 RLS Base Policy Pre-Audit

- Tarih: 2026-05-04T18:33:24+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_3_rls_pre_audit_20260504_183324

## Repo Relevant Files Manifest

- /root/pix2pi/pix2pi-SaaS/1_archive/root_sql/step_200_create_event_store_table.sql
- /root/pix2pi/pix2pi-SaaS/1_archive/root_sql/step_203_create_journal_tables.sql
- /root/pix2pi/pix2pi-SaaS/1_archive/root_sql/step_230_create_snapshot_tables.sql
- /root/pix2pi/pix2pi-SaaS/1_archive/root_sql/step_240_enable_rls_snapshots.sql
- /root/pix2pi/pix2pi-SaaS/1_archive/root_sql/step_260_create_audit_tables.sql
- /root/pix2pi/pix2pi-SaaS/.backup/lvl8_1_app_shell_fix_20260420_210518/tsconfig.app.json
- /root/pix2pi/pix2pi-SaaS/.backup/lvl8_6_route_structure_20260420_222229/package.json
- /root/pix2pi/pix2pi-SaaS/.backup/lvl8_6_route_structure_20260420_222229/package-lock.json
- /root/pix2pi/pix2pi-SaaS/backups/20260412_221957/user_created_consumer_main.go
- /root/pix2pi/pix2pi-SaaS/backups/20260412_221957/user_created_consumer_main_test.go
- /root/pix2pi/pix2pi-SaaS/backups/faz3_13_2b_gateway_build_restart_live_verify_20260426_230109/make_gateway_test_token.go
- /root/pix2pi/pix2pi-SaaS/backups/faz3_13_2c_gateway_live_negative_final_muhur_20260426_230410/make_gateway_test_token.go
- /root/pix2pi/pix2pi-SaaS/backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/make_gateway_observability_token.go
- /root/pix2pi/pix2pi-SaaS/backups/faz3_13_4a_step13_gateway_final_muhur_20260426_232851/make_step13_final_token.go
- /root/pix2pi/pix2pi-SaaS/backups/faz3_14_2b_panel_live_positive_api_muhur_20260427_000449/make_panel_live_token.go
- /root/pix2pi/pix2pi-SaaS/backups/faz3_14_2c_panel_ui_final_muhur_20260427_000653/make_panel_final_token.go
- /root/pix2pi/pix2pi-SaaS/backups/faz3_14_3a_content_type_header_diagnose_20260427_001443/make_header_test_token.go
- /root/pix2pi/pix2pi-SaaS/backups/faz3_14_3b_fix1_panel_api_content_type_cleanup_resume_20260427_002000/make_header_cleanup_token.go
- /root/pix2pi/pix2pi-SaaS/backups/faz3_14_3b_fix2_content_type_cleanup_muhur_20260427_002326/make_header_cleanup_token.go
- /root/pix2pi/pix2pi-SaaS/backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/make_header_cleanup_final_token.go
- /root/pix2pi/pix2pi-SaaS/backups/faz3_14_4a_faz3_final_muhur_20260427_002901/make_faz3_final_token.go
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_10_1c_cashbank_apply_20260426_060613/schema_before_cashbank.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_11_1c_fiscal_sequence_apply_20260426_061855/schema_before_fiscal_sequence.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_1_2a2_schema_backup_primary_20260425_075916/schema_before_master_party.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_1_2a_schema_backup_20260425_075810/schema_before_master_party.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_1_2_master_party_db_apply_20260425_075533/schema_before_master_party.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_2_1c_product_catalog_apply_20260425_082946/schema_before_product_catalog.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_3_1c_inventory_apply_20260425_194955/schema_before_inventory.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_4_1c_sales_documents_apply_20260425_201143/schema_before_sales_documents.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_5_1c_procurement_documents_apply_20260425_205307/schema_before_procurement_documents.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_6_1c_journal_apply_20260425_211413/schema_before_journal.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_7_1c_ledger_apply_20260425_213255/schema_before_ledger.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_8_1c_chart_of_accounts_apply_20260425_214845/schema_before_chart_of_accounts.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz3_9_9_1c_tax_apply_20260425_220354/schema_before_tax.sql
- /root/pix2pi/pix2pi-SaaS/backups/faz4_14_1_4A_real_dsn_repair_20260427_074950/.env
- /root/pix2pi/pix2pi-SaaS/backups/faz4_14_1_4A_real_dsn_repair_20260427_075042/.env
- /root/pix2pi/pix2pi-SaaS/backups/faz4_14_1_4B_primary_write_dsn_guard_20260427_075227/.env
- /root/pix2pi/pix2pi-SaaS/backups/faz6_9_nats_monitoring_fix_20260501_152330/pix2pi_nats_inspect.json
- /root/pix2pi/pix2pi-SaaS/cmd/accounting-service/accounting_service_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/erp_runtime_live_mount_wiring_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/erp_runtime_mount.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/erp_runtime_mount_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/erp_runtime_route_catalog_visibility_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/erp_runtime_route_catalog_wiring_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/erp_runtime_route_policy.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/erp_runtime_route_policy_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/erp_runtime_service_factory.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/erp_runtime_service_factory_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/gateway_config.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/gateway_config_security_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/gateway_entry_contract_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/gateway_middleware.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/gateway_routes.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/gateway_routes_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/gateway_s2s_policy_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/api-gateway/user_detail_route.go
- /root/pix2pi/pix2pi-SaaS/cmd/auth-api/auth_api_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/cache-pattern-clean-test/cache_pattern_clean_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/cache-service/cache_service_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/cache-test/cache_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/control-panel/control_panel.go
- /root/pix2pi/pix2pi-SaaS/cmd/early-warning-runtime/early_warning_runtime_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/early-warning-runtime/early_warning_runtime_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/event-bus/event_bus_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/event-bus-store-lifecycle-test/event_bus_store_lifecycle_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/event-concurrency-test/event_concurrency_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/event-consumer/event_consumer_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/event-idempotency-test/event_idempotency_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/event-metadata-test/event_metadata_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/event-replay-test/event_replay_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/event-schema-test/event_schema_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/event-store-postgres-test/event_store_postgres_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/gateway-quota-redis-test/gateway_quota_redis_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/gateway-rate-limit-redis-test/gateway_rate_limit_redis_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/identity-api/dev_token.go
- /root/pix2pi/pix2pi-SaaS/cmd/identity-api/dev_token_patch.go
- /root/pix2pi/pix2pi-SaaS/cmd/identity-api/identity_api_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/incident-audit-runtime/incident_audit_runtime_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/incident-audit-runtime/incident_audit_runtime_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/jobs-runtime/jobs_runtime_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/jobs-runtime/jobs_runtime_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/migrate/main.go
- /root/pix2pi/pix2pi-SaaS/cmd/mission-control/mission_control_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/nats-publisher/nats_publisher_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/nats-subscriber/nats_subscriber_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/notification-runtime/notification_runtime_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/notification-runtime/notification_runtime_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/ops-console-smoke/ops_console_smoke_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/ops-console-smoke/ops_console_smoke_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/playground/main.go
- /root/pix2pi/pix2pi-SaaS/cmd/playground/playground_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/plugin-discovery-test/plugin_discovery_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/plugin-erp/plugin_erp_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/plugin-health-test/plugin_health_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/plugin-registry-http-test/plugin_registry_http_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/plugin-registry-test/plugin_registry_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/plugin-runtime/plugin_runtime_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/plugin-runtime/plugin_runtime_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/policy-cache-hybrid-test/policy_cache_hybrid_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/publicapi-runtime/publicapi_runtime_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/publicapi-runtime/publicapi_runtime_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/query-read-model/query_read_model_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/query-read-model/query_read_model_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/realtime-runtime/realtime_runtime_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/realtime-runtime/realtime_runtime_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/redis-test/redis_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/replay-service/replay_service_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/reporting_service_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/reporting-service/reporting_service_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/reporting-service/reporting_service_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/runtime-topology/runtime_topology_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/runtime-topology/runtime_topology_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/service-discovery/service_discovery_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/service-discovery/service_discovery_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/service-registry/service_registry_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/service-watchdog/net_compat.go
- /root/pix2pi/pix2pi-SaaS/cmd/service-watchdog/service_watchdog_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/stock-service/stock_service_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/tenant-plugin-test/tenant_plugin_test_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/test_commission/main.go
- /root/pix2pi/pix2pi-SaaS/cmd/user-created-consumer/user_created_consumer_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/user-created-consumer/user_created_consumer_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/webhook-runtime/webhook_runtime_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/webhook-runtime/webhook_runtime_main_test.go
- /root/pix2pi/pix2pi-SaaS/cmd/workflow-runtime/workflow_runtime_main.go
- /root/pix2pi/pix2pi-SaaS/cmd/workflow-runtime/workflow_runtime_main_test.go
- /root/pix2pi/pix2pi-SaaS/config/service_watchdog_services.json
- /root/pix2pi/pix2pi-SaaS/configs/faz5/commercial_readiness_suite_v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz5/entitlement_matrix_v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz5/faz5_final_closure_v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz5/legal_compliance_policy_v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz5/packages_pricing_v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz5/public_pricing_developer_surface_v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz5/revenue_metrics_policy_v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz5/sales_demo_crm_policy_v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz5/subscription_billing_policy_v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz5/support_sla_incident_policy_v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz5/tenant_lifecycle_policy_v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/accountant_billing_live_ready_runtime.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/accountant_portal_access_runtime.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/accountant_portal_commercial_surface.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/accountant_portal_final_closure.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/accountant_portal_reporting_export_preview.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/billing_readiness.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/commercial_live_ready_control_plane.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/commercial_master_closure.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/entitlement_feature_gate.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/erp_sync_worker_live_ready_runtime.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/export_live_ready_pipeline.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/integration_catalog.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/integration_runtime_foundation.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/live_activation_guard_approval_matrix.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/logo_admin_ops_manual_review.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/logo_connector_foundation.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/logo_credential_secret_reference.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/logo_e2e_dry_run_flow.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/logo_export_mapping_contract.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/logo_file_generation_dry_run.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/logo_final_closure_provider_live_handoff.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/logo_import_delivery_contract.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/logo_live_contract.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/logo_validation_retry_dlq.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/marketplace_integration_catalog.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_admin_ops.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_api_client.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_connector_final_closure.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_connector.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_credential_ui.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_data_mapping.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_e2e_dry_run.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_live_contract.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_oauth_flow.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_sync_worker.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_token_exchange.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_token_vault.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/parasut_webhook_sync_trigger.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_admin_ops_manual_review.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_attempt_transaction_state.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_capture_live_ready_runtime.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_failure_retry_idempotency.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_module_final_closure.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_observability_metrics_audit_trail.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_persistence_repository_contract.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_postgres_repository.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_provider_adapter.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_provider_contract.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_provider_simulation_adapter.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_sandbox_e2e_roundtrip.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_service_orchestration.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/payment_webhook_intake.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/product_plan_catalog.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/provider_live_adapter_readiness.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/public_demo_flow.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/subscription_runtime.v1.json
- /root/pix2pi/pix2pi-SaaS/configs/faz7/tenant_onboarding.v1.json
- /root/pix2pi/pix2pi-SaaS/CONTROL_PANEL.md
- /root/pix2pi/pix2pi-SaaS/db/migrations/001_phase1_foundation.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/001_phase1_foundation.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/002_phase2_db_l4_service_registry.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/002_phase2_db_l4_service_registry.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/003_phase2_db_l4_mission_control.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/003_phase2_db_l4_mission_control.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/004_phase2_db_l4_jobs_queue.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/004_phase2_db_l4_jobs_queue.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/005_phase2_db_l4_idempotency.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/005_phase2_db_l4_idempotency.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/006_phase2_db_l4_notifications.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/006_phase2_db_l4_notifications.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/007_phase2_db_l4_webhooks.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/007_phase2_db_l4_webhooks.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/008_phase2_db_l4_workflows.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/008_phase2_db_l4_workflows.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/009_phase2_db_l4_api_keys.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/009_phase2_db_l4_api_keys.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/010_phase2_db_l4_plugins.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/010_phase2_db_l4_plugins.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_090101_erp_master_party.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_090101_erp_master_party.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_0910001_erp_cashbank.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_0910001_erp_cashbank.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_092001_erp_product_catalog.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_092001_erp_product_catalog.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_093001_erp_inventory.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_093001_erp_inventory.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_094001_erp_sales_documents.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_094001_erp_sales_documents.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_095001_erp_procurement_documents.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_095001_erp_procurement_documents.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_096001_erp_journal.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_096001_erp_journal.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_097001_erp_ledger.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_097001_erp_ledger.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_098001_erp_chart_of_accounts.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_098001_erp_chart_of_accounts.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_099001_erp_tax.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260425_099001_erp_tax.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260426_0911001_erp_fiscal_sequence.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260426_0911001_erp_fiscal_sequence.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260426_111001_erp_runtime_e2e_flow.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260427_151001_readmodel_operational_tables.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260427_151001_readmodel_operational_tables.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_143001_import_staging_tables.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_143001_import_staging_tables.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_152001_finance_reporting_mart.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_152001_finance_reporting_mart.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_153001_ebelge_export_reporting_mart.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_153001_ebelge_export_reporting_mart.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_154001_payment_reconciliation_reporting_mart.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_154001_payment_reconciliation_reporting_mart.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_155001_search_index_projection_tables.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_155001_search_index_projection_tables.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_181001_inventory_opening_stock.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_181001_inventory_opening_stock.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_182001_inventory_stock_movement_engine.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_182001_inventory_stock_movement_engine.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_183001_inventory_sales_stock_decrement.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_183001_inventory_sales_stock_decrement.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_184001_inventory_purchase_stock_increment.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_184001_inventory_purchase_stock_increment.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_185001_inventory_stock_reservation.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_185001_inventory_stock_reservation.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_186001_inventory_negative_stock_policy.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_186001_inventory_negative_stock_policy.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_187001_inventory_stock_valuation.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_187001_inventory_stock_valuation.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_191001_panel_runtime_flow_history.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260428_191001_panel_runtime_flow_history.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260429_211001_security_role_matrix.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260429_211001_security_role_matrix.up.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260429_213001_security_audit_event_model.down.sql
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260429_213001_security_audit_event_model.up.sql
- /root/pix2pi/pix2pi-SaaS/db/tests/001_phase1_cross_tenant_security.sql
- /root/pix2pi/pix2pi-SaaS/db/tests/002_phase1_org_graph.sql
- /root/pix2pi/pix2pi-SaaS/db/tests/004_phase2_service_registry.sql
- /root/pix2pi/pix2pi-SaaS/db/tests/005_phase2_mission_control.sql
- /root/pix2pi/pix2pi-SaaS/db/tests/006_phase2_jobs_queue.sql
- /root/pix2pi/pix2pi-SaaS/db/tests/007_phase2_idempotency.sql
- /root/pix2pi/pix2pi-SaaS/db/tests/008_phase2_notifications.sql
- /root/pix2pi/pix2pi-SaaS/db/tests/009_phase2_webhooks.sql
- /root/pix2pi/pix2pi-SaaS/db/tests/010_phase2_workflows.sql
- /root/pix2pi/pix2pi-SaaS/db/tests/011_phase2_api_keys.sql
- /root/pix2pi/pix2pi-SaaS/db/tests/012_phase2_plugins.sql
- /root/pix2pi/pix2pi-SaaS/deploy/ports.env
- /root/pix2pi/pix2pi-SaaS/deploy/sql/rls_tenant_policy.sql
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step12_2_gateway_route_binding.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step12_2_gateway_route_binding_mux_smoke.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step12_2_gateway_route_manifest.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step12_3_gateway_mount_binding.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step12_3_gateway_mount_binding_mux_smoke.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step12_3_gateway_mount_plan.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step13_1b_gateway_erp_runtime_mount_adapter.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step13_1d_gateway_erp_runtime_route_policy_helper.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step13_1e_gateway_erp_runtime_route_catalog_wiring.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step13_1f_gateway_erp_runtime_service_factory.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step13_1g_gateway_erp_runtime_live_mount_wiring.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step13_1i_gateway_protected_erp_runtime_endpoint_smoke.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step13_3a_fix_gateway_route_catalog_visibility.md
- /root/pix2pi/pix2pi-SaaS/docs/api/faz3_step14_1b_erp_runtime_panel_contract.md
- /root/pix2pi/pix2pi-SaaS/docs/api/lvl7_ui_error_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/api/lvl7_ui_surface_contracts.md
- /root/pix2pi/pix2pi-SaaS/docs/api/lvl7_ui_surface_manifest.md
- /root/pix2pi/pix2pi-SaaS/docs/api/lvl7_ui_tenant_auth_matrix.md
- /root/pix2pi/pix2pi-SaaS/docs/architecture/redis_cache_strategy.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_final_muhur_raporu.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step10_10a_runtime_toplu_smoke_raporu.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step10_10b_runtime_final_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step10_1_runtime_kernel_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step10_2_runtime_fiscal_guard_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step10_3_runtime_docnumber_allocator_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step10_4_runtime_journalpost_orchestrator_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step10_5_runtime_ledgerpost_orchestrator_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step10_6_runtime_cashbankpay_orchestrator_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step10_7_runtime_taxcalc_orchestrator_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step10_8_runtime_salesinvoice_orchestrator_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step10_9_runtime_purchaseinvoice_orchestrator_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step11_2_runtime_e2eflow_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step11_3_runtime_e2eflow_adapter_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step11_4_runtime_e2eflow_bridge_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step11_5a_runtime_e2e_final_toplu_smoke_raporu.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step11_5b_runtime_e2e_final_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step12_1_runtime_api_surface_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step12_2_gateway_route_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step12_3_gateway_mount_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step12_4a_runtime_api_gateway_final_smoke_raporu.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step12_4b_runtime_api_gateway_final_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step13_1a_gateway_integration_discovery.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step13_1_gateway_erp_runtime_integration_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step13_2a_gateway_live_readiness_inspect.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step13_2b_gateway_build_restart_live_verify.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step13_2c_gateway_live_negative_final_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step13_2_gateway_live_final_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step13_3a_fix_gateway_route_catalog_visibility.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step13_3b_gateway_observability_log_visibility.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step13_3_gateway_observability_final_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step13_gateway_final_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step14_1a_admin_panel_discovery.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step14_1b_panel_target_contract.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step14_2a_fix2_panel_host_cache_diagnose.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step14_2a_fix3_nginx_effective_served_file_find.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step14_2a_fix4_real_panel_dist_patch.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step14_2a_fix_panel_live_served_file_inspect.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step14_2b_panel_live_positive_api_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step14_2_panel_ui_final_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step14_3a_content_type_header_diagnose.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step14_3b_panel_api_content_type_cleanup.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step14_3_header_cleanup_final_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp/faz3_step9_db_l5_persistence_muhur.md
- /root/pix2pi/pix2pi-SaaS/docs/erp-tr/lvl13_accountant_portal_document_ai_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/erp-tr/lvl13_ebelge_export_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/erp-tr/lvl13_payment_closure_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/erp-tr/lvl13_tdhp_tax_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_10_PARASUT_DISCOVERY.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_11_CONTROLLED_PILOT_GO_LIVE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_12_PILOT_MONITORING_STABILIZATION.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_13_SUPPORT_FEEDBACK_LOOP.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_14_MOBILE_READY_PWA_BUSINESS_SURFACE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_15_RELEASE_ROLLBACK_BACKUP_GATE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_16_FINAL_CLOSURE_SEAL.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_1_CARRY_FORWARD_INTAKE_SCOPE_FREEZE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_2_SECURITY_TENANT_ISOLATION_FINAL_PILOT_CHECK.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_3_BUSINESS_CHAIN_FINAL_VALIDATION.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_4_ERP_CORE_PRODUCT_APPLY_STAGING_CORE_DECISIONS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_5_PILOT_ACCESS_PASSWORD_RESET_INVITE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_6_PILOT_BUSINESS_UI_SURFACE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_7_AUTO_PARTS_UI_OEM_EQUIVALENT_VEHICLE_COMPATIBILITY.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_8_BARCODE_OPTIONAL_UI_NOTE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_9_MARKETPLACE_DISCOVERY.md
- /root/pix2pi/pix2pi-SaaS/docs/faz4d/FAZ_4D_MASTER_PLAN.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/5_10_public_pricing_developer_surfaces.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/5_11_commercial_readiness_test_suite.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/5_12_faz5_final_closure_seal.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/5_1_commercial_master_plan_scope_freeze.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/5_2_packages_pricing_architecture.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/5_3_entitlement_matrix_module_rights.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/5_4_subscription_billing_payment_ops.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/5_5_tenant_lifecycle_commercial_ops.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/5_6_legal_compliance_kvkk_terms.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/5_7_support_sla_incident_escalation.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/5_8_sales_demo_crm_operations.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/5_9_revenue_metrics_mrr_arr_churn.md
- /root/pix2pi/pix2pi-SaaS/docs/faz5/faz5_master_plan.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_10_CDN_WAF_DNS_EDGE_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_11_OPS_CONSOLE_INCIDENT_RUNBOOK_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_2_DB_L8_HA_SCALE_OPS_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_3_MULTI_NODE_FOUNDATION_SCALE_OUT_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_4_EVENT_BUS_QUEUE_BACKLOG_SRE_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_5_OBSERVABILITY_EARLY_WARNING_SRE_DASHBOARD.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_6_BACKUP_RESTORE_DISASTER_RECOVERY.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_7_SECURITY_HARDENING_PRODUCTION_GUARDRAILS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_8_PERFORMANCE_LOAD_STRESS_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_9_RELEASE_ROLLBACK_DEPLOY_SAFETY.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_FINAL_CLOSURE_MANIFEST.md
- /root/pix2pi/pix2pi-SaaS/docs/faz6/FAZ_6_MASTER_PLAN_SCOPE_FREEZE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5_BILLING_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_10_PAYMENT_OBSERVABILITY_METRICS_AUDIT_TRAIL.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_11_PAYMENT_ADMIN_OPS_MANUAL_REVIEW.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_12_PAYMENT_MODULE_FINAL_CLOSURE_PRODUCTION_PROVIDER_HANDOFF_GATE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_1_PROVIDER_OPERATION_CONTRACT_HARDENING.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_2_PAYMENT_ATTEMPT_TRANSACTION_STATE_MODEL.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_3_PAYMENT_PERSISTENCE_REPOSITORY_CONTRACT.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_4_PAYMENT_DB_MIGRATION_POSTGRES_REPOSITORY.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_5_PAYMENT_SERVICE_ORCHESTRATION.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_6_PAYMENT_WEBHOOK_INTAKE_VERIFICATION_RUNTIME.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_7_PAYMENT_PROVIDER_SIMULATION_ADAPTER.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_8_PAYMENT_SANDBOX_E2E_WEBHOOK_ROUNDTRIP.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_9_PAYMENT_FAILURE_RETRY_IDEMPOTENCY_HARDENING.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_5P_PAYMENT_PROVIDER_ADAPTER_MODULE_FOUNDATION.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8I_INTEGRATION_RUNTIME_FOUNDATION.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8L_10_LOGO_CONNECTOR_FINAL_CLOSURE_PROVIDER_LIVE_HANDOFF_GATE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8L_1_LOGO_CONNECTOR_FOUNDATION.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8L_2_LOGO_LIVE_CONTRACT_API_FILE_CONTRACT_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8L_3_LOGO_CREDENTIAL_SECRET_REFERENCE_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8L_4_LOGO_EXPORT_MAPPING_CONTRACT.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8L_5_LOGO_FILE_GENERATION_DRY_RUN.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8L_6_LOGO_IMPORT_PACKAGE_DELIVERY_CONTRACT.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8L_7_LOGO_VALIDATION_ERROR_MAPPING_RETRY_DLQ.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8L_8_LOGO_ADMIN_OPS_MANUAL_REVIEW.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8L_9_LOGO_E2E_DRY_RUN_FLOW.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8M_1_MIKRO_EXPORT_MAPPING_ERP_OBJECT_CONTRACT.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8M_2_MIKRO_FILE_GENERATION_DRY_RUN_CONTRACT.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8M_3_MIKRO_IMPORT_PACKAGE_DELIVERY_CONTRACT.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8M_4_MIKRO_VALIDATION_ERROR_MAPPING_RETRY_DLQ.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8M_5_MIKRO_ADMIN_OPS_MANUAL_REVIEW.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8M_6_MIKRO_E2E_DRY_RUN_FLOW.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8M_7_MIKRO_CONNECTOR_FINAL_CLOSURE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8M_MIKRO_CONNECTOR_MODULE_FOUNDATION.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_10_PARASUT_E2E_DRY_RUN_CONNECTOR_FLOW_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_11_PARASUT_ADMIN_OPS_MANUAL_REVIEW_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_12_PARASUT_CONNECTOR_FINAL_CLOSURE_HANDOFF_GATE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_1_PARASUT_LIVE_CONTRACT_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_2_PARASUT_TOKEN_VAULT_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_4_PARASUT_OAUTH_CALLBACK_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE_REFRESH_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_6_PARASUT_API_CLIENT_OPERATION_RUNTIME_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_7_PARASUT_DATA_MAPPING_ERP_SYNC_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_8_PARASUT_SYNC_WORKER_DRY_RUN_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER_READINESS.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_8P_PARASUT_CONNECTOR_MODULE.md
- /root/pix2pi/pix2pi-SaaS/docs/faz7/FAZ_7_MASTER_PLAN.md
- /root/pix2pi/pix2pi-SaaS/docs/infra/lvl10_edge_domain_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/infra/lvl10_edge_security_and_cert_ops.md
- /root/pix2pi/pix2pi-SaaS/docs/infra/lvl10_ops_validation_and_phase_closure.md
- /root/pix2pi/pix2pi-SaaS/docs/infra/lvl10_ssl_nginx_hardening.md
- /root/pix2pi/pix2pi-SaaS/docs/KERNEL_RULES.md
- /root/pix2pi/pix2pi-SaaS/docs/observability/lvl11_correlation_scale_trigger_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/observability/lvl11_delivery_validation_phase_closure.md
- /root/pix2pi/pix2pi-SaaS/docs/observability/lvl11_signal_threshold_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_1_migration_chain_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_1_migration_chain_validation.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_2_migration_apply_dry_run_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_2_migration_apply_gate_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_3_migration_db_env_discovery_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_3_migration_db_env_dsn_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_4A_real_dsn_repair_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_4B_primary_write_dsn_guard_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_4B_primary_write_dsn_guard_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_4_db_connection_evidence_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_4_db_connection_evidence_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_5A_migration_version_normalization_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_5A_migration_version_normalization_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_5B_migration_timestamp_order_guard_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_5B_migration_timestamp_order_guard_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_5_migration_status_evidence_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_5_migration_status_evidence_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_6A_index_parser_correction_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_6B_drift_classification_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_6B_drift_classification_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_6_migration_drift_evidence_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_6_migration_drift_evidence_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_7_index_reconciliation_plan.sql
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_7_index_reconciliation_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_7_index_reconciliation_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_8_migration_reconciliation_final_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_8_migration_reconciliation_final_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_migration_chain_discovery.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_pilot_migration_chain_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_1_pilot_migration_chain_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_1_db_backup_pitr_readiness_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_1_db_backup_pitr_readiness_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_2_logical_backup_smoke_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_2_logical_backup_smoke_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_3_restore_drill_sandbox_plan_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_3_restore_drill_sandbox_plan_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_4_restore_drill_test_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_4_restore_drill_test_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_5_pitr_design_wal_archive_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_5_pitr_design_wal_archive_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_6_pitr_enable_gate_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_6_pitr_enable_gate_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_reference_seed_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_2_reference_seed_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_1_db_observability_performance_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_1_db_observability_performance_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_2_db_observability_enable_gate_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_2_db_observability_enable_gate_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_3_db_observability_apply_readiness_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_3_db_observability_apply_readiness_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_4_db_observability_controlled_apply_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_4_db_observability_controlled_apply_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_5_db_observability_final_baseline_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_5_db_observability_final_baseline_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_final_db_observability_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_import_staging_tables_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_3_import_staging_tables_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_1_query_performance_baseline_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_1_query_performance_baseline_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_2_index_usage_baseline_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_2_index_usage_baseline_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_3_vacuum_bloat_readiness_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_3_vacuum_bloat_readiness_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_4_db_health_baseline_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_4_db_health_baseline_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_5_db_performance_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_5_db_performance_final_closure_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_backfill_rebuild_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_backfill_rebuild_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_4_final_db_performance_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_1_db_master_evidence_collector_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_1_db_master_evidence_collector_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_2_db_production_readiness_scorecard_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_2_db_production_readiness_scorecard_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_3_db_known_risks_deferred_register_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_3_db_known_risks_deferred_register_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_4_db_operations_runbook.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_4_db_runbook_incident_checklist_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_4_db_runbook_incident_checklist_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_5_db_final_closure_gate_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_5_db_final_closure_gate_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_archive_partition_retention_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_5_archive_partition_retention_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_6_backup_restore_verification_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_6_backup_restore_verification_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_7_migration_lifecycle_import_tests_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_7_migration_lifecycle_import_tests_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/14_migration_lifecycle_import_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_1_operational_readmodel_tables_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_1_operational_readmodel_tables_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_2_finance_reporting_mart_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_2_finance_reporting_mart_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_2_readmodel_apply_gate_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_2_readmodel_apply_gate_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_3_ebelge_export_reporting_mart_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_3_ebelge_export_reporting_mart_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_3_readmodel_controlled_apply_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_3_readmodel_controlled_apply_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_4_payment_reconciliation_reporting_mart_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_4_payment_reconciliation_reporting_mart_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_4_readmodel_contract_query_evidence_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_4_readmodel_contract_query_evidence_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_5_search_index_projection_tables_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_5_search_index_projection_tables_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_6_materialized_cache_projection_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_6_materialized_cache_projection_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_7_readmodel_reporting_tests_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_7_readmodel_reporting_tests_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_readmodel_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/15_readmodel_reporting_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_1_pilot_uat_onboarding_baseline_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_1_pilot_uat_onboarding_baseline_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_1_pilot_uat_onboarding_baseline_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_1_reporting_query_contract_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_1_reporting_query_contracts.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_1_reporting_query_contract_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_1_reporting_query_endpoint_manifest.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_2_pilot_tenant_readiness_contract_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_2_pilot_tenant_readiness_contract_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_2_pilot_tenant_readiness_contract_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_2_readmodel_repository_layer_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_2_readmodel_repository_layer_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_3_reporting_service_layer_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_3_reporting_service_layer_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_3_uat_scenario_execution_contract_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_3_uat_scenario_execution_contract_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_3_uat_scenario_execution_contract_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_4_pilot_data_readiness_contract_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_4_pilot_data_readiness_contract_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_4_pilot_data_readiness_contract_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_4_reporting_api_endpoint_skeleton_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_4_reporting_api_endpoint_skeleton_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_5_go_no_go_rollout_gate_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_5_go_no_go_rollout_gate_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_5_go_no_go_rollout_gate_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_5_reporting_query_smoke_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_5_reporting_query_smoke_final_closure_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_6_pilot_uat_onboarding_tests_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_6_pilot_uat_onboarding_tests_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_7_pilot_uat_onboarding_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_7_pilot_uat_onboarding_final_closure_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_pilot_uat_onboarding_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/16_reporting_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_1_reporting_gateway_route_premanifest.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_1_reporting_runtime_wiring_plan.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_1_reporting_runtime_wiring_plan_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_1_reporting_runtime_wiring_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_1_reporting_service_entry_contract.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_1_workflow_realtime_baseline_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_1_workflow_realtime_baseline_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_1_workflow_realtime_baseline_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_2_reporting_api_route_registration_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_2_reporting_api_route_registration_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_2_reporting_route_registration_manifest.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_2_workflow_state_machine_contract_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_2_workflow_state_machine_contract_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_2_workflow_state_machine_contract_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_3_gateway_route_manifest_auth_tenant_gate_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_3_gateway_route_manifest_auth_tenant_gate_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_3_reporting_auth_tenant_gate_contract.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_3_reporting_gateway_route_manifest.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_3_workflow_action_approval_contract_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_3_workflow_action_approval_contract_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_3_workflow_action_approval_contract_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_4_realtime_channel_contract_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_4_realtime_channel_contract_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_4_realtime_channel_contract_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_4_reporting_runtime_smoke_test_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_4_reporting_runtime_smoke_test_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_5_reporting_api_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_5_reporting_api_final_closure_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_5_ui_api_implementation_plan_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_5_ui_api_implementation_plan_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_5_ui_api_implementation_plan_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_6_workflow_realtime_tests_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_6_workflow_realtime_tests_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_7_workflow_realtime_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_7_workflow_realtime_final_closure_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_reporting_api_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/17_workflow_realtime_ui_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_1_gateway_runtime_apply_readiness_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_1_gateway_runtime_apply_readiness_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_1_opening_stock_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_1_opening_stock_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_2_reporting_runtime_service_entry_apply_plan_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_2_reporting_runtime_service_entry_apply_plan_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_2_stock_movement_engine_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_2_stock_movement_engine_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_3_gateway_route_controlled_apply_gate_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_3_gateway_route_controlled_apply_gate_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_3_sales_stock_decrement_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_3_sales_stock_decrement_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_4_controlled_gateway_runtime_apply_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_4_controlled_gateway_runtime_apply_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_4_purchase_stock_increment_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_4_purchase_stock_increment_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_5_live_http_smoke_auth_tenant_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_5_live_http_smoke_auth_tenant_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_5_stock_reservation_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_5_stock_reservation_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_6_negative_stock_policy_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_6_negative_stock_policy_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_6_reporting_live_route_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_6_reporting_live_route_final_closure_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_7_stock_valuation_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_7_stock_valuation_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_8_inventory_tests_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_8_inventory_tests_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_inventory_pilot_motor_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/18_reporting_live_route_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_1_runtime_flow_history_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_1_runtime_flow_history_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_2_flow_detail_page_contract.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_2_flow_detail_page_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_2_flow_detail_page_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_3_admin_dashboard_cards_contract.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_3_admin_dashboard_cards_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_3_admin_dashboard_cards_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_4_import_wizard_ui_contract.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_4_import_wizard_ui_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_4_import_wizard_ui_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_5_uat_checklist_ui_contract.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_5_uat_checklist_ui_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_5_uat_checklist_ui_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_6_issue_feedback_ui_contract.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_6_issue_feedback_ui_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_6_issue_feedback_ui_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_7_panel_ux_tests_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_7_panel_ux_tests_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_panel_admin_professionalization_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_phase4_final_master_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/19_phase4_final_master_closure_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_1_production_cleanup_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_1_production_cleanup_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_1_production_cleanup_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_2_config_env_hardening_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_2_config_env_hardening_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_2_config_env_hardening_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_3_runtime_service_hardening_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_3_runtime_service_hardening_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_3_runtime_service_hardening_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_4_nginx_reverse_proxy_hardening_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_4_nginx_reverse_proxy_hardening_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_4_nginx_reverse_proxy_hardening_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_5_docker_compose_hardening_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_5_docker_compose_hardening_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_5_docker_compose_hardening_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_6_backup_archive_retention_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_6_backup_archive_retention_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_6_backup_archive_retention_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_7_production_hardening_tests_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_7_production_hardening_tests_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_8_infra_cleanup_production_hardening_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_8_infra_cleanup_production_hardening_final_closure_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/20_infra_cleanup_production_hardening_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_1_role_matrix_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_1_role_matrix_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_2_permission_guard_contract.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_2_permission_guard_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_2_permission_guard_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_3_audit_event_model_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_3_audit_event_model_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_4_tenant_access_checks_contract.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_4_tenant_access_checks_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_4_tenant_access_checks_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_5_support_super_admin_boundary_contract.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_5_support_super_admin_boundary_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_5_support_super_admin_boundary_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_6_security_tests_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_6_security_tests_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_7_security_rbac_audit_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_7_security_rbac_audit_final_closure_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/21_security_rbac_audit_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_1_observability_baseline_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_1_observability_baseline_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_1_observability_baseline_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_2_metrics_scrape_readiness_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_2_metrics_scrape_readiness_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_2_metrics_scrape_readiness_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_3_logs_loki_readiness_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_3_logs_loki_readiness_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_3_logs_loki_readiness_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_4_traces_tempo_readiness_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_4_traces_tempo_readiness_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_4_traces_tempo_readiness_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_5_alert_rule_catalog_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_5_alert_rule_catalog_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_5_alert_rule_catalog_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_6_ops_console_signal_contract_policy.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_6_ops_console_signal_contract_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_6_ops_console_signal_contract_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_7_observability_ops_console_tests_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_7_observability_ops_console_tests_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_8_observability_ops_console_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_8_observability_ops_console_final_closure_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/22_observability_ops_console_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/faz4b_final_master_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/faz4b_final_master_closure_standard.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/faz4b_to_faz5_transition_readiness.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/faz4_db_final_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/phase4/phase4_final_master_closure_report.md
- /root/pix2pi/pix2pi-SaaS/docs/platform/lvl12_jobs_notifications_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/platform/lvl12_plugin_public_api_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/platform/lvl12_realtime_workflow_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/platform/lvl12_registry_mission_control_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/quality/lvl14_e2e_security_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/quality/lvl14_performance_release_closure.md
- /root/pix2pi/pix2pi-SaaS/docs/quality/lvl14_test_contract_foundation.md
- /root/pix2pi/pix2pi-SaaS/docs/SHARED_RULES.md
- /root/pix2pi/pix2pi-SaaS/.env
- /root/pix2pi/pix2pi-SaaS/grafana/dashboards/docker-monitoring.json
- /root/pix2pi/pix2pi-SaaS/grafana/dashboards/node-exporter-full.json
- /root/pix2pi/pix2pi-SaaS/grafana/dashboards/node.json
- /root/pix2pi/pix2pi-SaaS/guard/quality_gates.env
- /root/pix2pi/pix2pi-SaaS/internal/platform/dlq.go
- /root/pix2pi/pix2pi-SaaS/internal/platform/dlq_test.go
- /root/pix2pi/pix2pi-SaaS/internal/platform/idempotency.go
- /root/pix2pi/pix2pi-SaaS/internal/platform/idempotency_test.go
- /root/pix2pi/pix2pi-SaaS/internal/platform/retry.go
- /root/pix2pi/pix2pi-SaaS/internal/platform/retry_test.go
- /root/pix2pi/pix2pi-SaaS/migrations/faz7/20260501_075p4_payment_attempts.sql
- /root/pix2pi/pix2pi-SaaS/pkg/erpcore/erpcore.go
- /root/pix2pi/pix2pi-SaaS/PORTS.md
- /root/pix2pi/pix2pi-SaaS/README.md
- /root/pix2pi/pix2pi-SaaS/reports/api_gateway_final_close_20260417_195108.md
- /root/pix2pi/pix2pi-SaaS/reports/api_gateway_final_close_latest.md
- /root/pix2pi/pix2pi-SaaS/reports/api_gateway_final_suite_20260417_080541.md
- /root/pix2pi/pix2pi-SaaS/reports/api_gateway_final_suite_latest.md
- /root/pix2pi/pix2pi-SaaS/reports/event_platform_final_close_20260418_100817.md
- /root/pix2pi/pix2pi-SaaS/reports/event_platform_final_close_latest.md
- /root/pix2pi/pix2pi-SaaS/reports/event_platform_final_suite_20260416_215947.md
- /root/pix2pi/pix2pi-SaaS/reports/event_platform_final_suite_latest.md
- /root/pix2pi/pix2pi-SaaS/reports/event_platform_final_suite_run_20260418_095021.md
- /root/pix2pi/pix2pi-SaaS/reports/event_platform_final_suite_run_latest.md
- /root/pix2pi/pix2pi-SaaS/reports/gw_edge_3_20260418_080622.md
- /root/pix2pi/pix2pi-SaaS/reports/gw_edge_3_latest.md
- /root/pix2pi/pix2pi-SaaS/reports/gw_master_close_20260418_091655.md
- /root/pix2pi/pix2pi-SaaS/reports/gw_master_close_latest.md
- /root/pix2pi/pix2pi-SaaS/reports/master_progress_report.json
- /root/pix2pi/pix2pi-SaaS/reports/master_progress_report.md
- /root/pix2pi/pix2pi-SaaS/reports/master_progress_report_v2.json
- /root/pix2pi/pix2pi-SaaS/reports/master_progress_report_v2.md
- /root/pix2pi/pix2pi-SaaS/scripts/ci/quality_gates.env
- /root/pix2pi/pix2pi-SaaS/test/gemini_test/erpcore_test.go
- /root/pix2pi/pix2pi-SaaS/tmp/gw_jwt_default_probe_body.json
- /root/pix2pi/pix2pi-SaaS/tmp/gw_jwt_default_probe_main.go
- /root/pix2pi/pix2pi-SaaS/tmp/gw_jwt_default_probe_winner.env
- /root/pix2pi/pix2pi-SaaS/tmp/gw_jwt_matrix_body.json
- /root/pix2pi/pix2pi-SaaS/tmp/gw_jwt_matrix_main.go
- /root/pix2pi/pix2pi-SaaS/tmp/gw_manual_bearer.env
- /root/pix2pi/pix2pi-SaaS/tmp/gw_manual_jwt_main.go
- /root/pix2pi/pix2pi-SaaS/tmp/gw_manual_me_body.json
- /root/pix2pi/pix2pi-SaaS/web/node_modules/.package-lock.json
- /root/pix2pi/pix2pi-SaaS/web/package.json
- /root/pix2pi/pix2pi-SaaS/web/package-lock.json
- /root/pix2pi/pix2pi-SaaS/web/panel/package.json
- /root/pix2pi/pix2pi-SaaS/web/panel/package-lock.json
- /root/pix2pi/pix2pi-SaaS/web/panel/README.md
- /root/pix2pi/pix2pi-SaaS/web/panel/tsconfig.app.json
- /root/pix2pi/pix2pi-SaaS/web/panel/tsconfig.json
- /root/pix2pi/pix2pi-SaaS/web/panel/tsconfig.node.json
- /root/pix2pi/pix2pi-SaaS/web/tsconfig.json

## Database Schemas

     schema_name     
---------------------
 audit
 auth
 core
 franchise
 meta
 org
 partner
 platform
 public
 readmodel
 runtime
 security
 tenant_uzmanparcaci
(13 rows)


## Tables With tenant_id Candidate

    table_schema     |           table_name            
---------------------+---------------------------------
 audit               | audit_events
 audit               | export_jobs
 auth                | break_glass_sessions
 auth                | roles
 auth                | user_role_assignments
 auth                | user_scopes
 auth                | users
 franchise           | agreements
 org                 | branches
 org                 | entity_branch_visibility_rules
 org                 | entity_relations
 org                 | entity_shareholders
 org                 | legal_entities
 org                 | locations
 partner             | company_relations
 public              | audit_logs
 public              | cari_hesaplar
 public              | erp_account_mapping_rules
 public              | erp_account_movements
 public              | erp_addresses
 public              | erp_bank_accounts
 public              | erp_cash_accounts
 public              | erp_chart_accounts
 public              | erp_contacts
 public              | erp_customers
 public              | erp_document_number_allocations
 public              | erp_document_sequences
 public              | erp_fiscal_periods
 public              | erp_fiscal_years
 public              | erp_items
 public              | erp_journal_entries
 public              | erp_journal_lines
 public              | erp_ledger_balances
 public              | erp_parties
 public              | erp_payment_transactions
 public              | erp_product_categories
 public              | erp_products
 public              | erp_purchase_invoice_lines
 public              | erp_purchase_invoices
 public              | erp_purchase_order_lines
 public              | erp_purchase_orders
 public              | erp_purchase_receipt_lines
 public              | erp_purchase_receipts
 public              | erp_runtime_flow_steps
 public              | erp_runtime_flows
 public              | erp_sales_deliveries
 public              | erp_sales_delivery_lines
 public              | erp_sales_invoice_lines
 public              | erp_sales_invoices
 public              | erp_sales_order_lines
 public              | erp_sales_orders
 public              | erp_sales_quotation_lines
 public              | erp_sales_quotations
 public              | erp_stock_movements
 public              | erp_tax_codes
 public              | erp_tax_rates
 public              | erp_tax_transactions
 public              | erp_units
 public              | erp_vendors
 public              | erp_warehouse_balances
 public              | erp_warehouses
 public              | event_store
 public              | event_store_records_pg_test
 public              | journal_entries
 public              | org_nodes
 public              | roles
 public              | snapshots
 public              | users
 readmodel           | daily_operational_metrics
 readmodel           | document_work_queue
 readmodel           | inventory_status_snapshot
 readmodel           | projection_state
 readmodel           | reconciliation_status_snapshot
 readmodel           | tenant_operational_snapshot
 runtime             | api_key_usage
 runtime             | api_keys
 runtime             | api_quota_policies
 runtime             | dedupe_records
 runtime             | idempotency_keys
 runtime             | job_attempts
 runtime             | job_queues
 runtime             | jobs
 runtime             | mission_control_actions
 runtime             | mission_control_incidents
 runtime             | notification_channels
 runtime             | notification_recipients
 runtime             | notifications
 runtime             | plugin_states
 runtime             | plugins
 runtime             | service_registry_heartbeats
 runtime             | service_registry_instances
 runtime             | service_registry_services
 runtime             | webhook_deliveries
 runtime             | webhook_delivery_attempts
 runtime             | webhook_endpoints
 runtime             | workflow_approvals
 runtime             | workflow_definitions
 runtime             | workflow_instances
 runtime             | workflow_steps
 tenant_uzmanparcaci | pilot_product_import_staging
(100 rows)


## Current Row Security Status

     schema_name     |           table_name            | rls_enabled | rls_forced 
---------------------+---------------------------------+-------------+------------
 audit               | audit_events                    | t           | t
 audit               | export_jobs                     | t           | t
 auth                | break_glass_sessions            | t           | t
 auth                | permissions                     | f           | f
 auth                | role_permissions                | f           | f
 auth                | roles                           | t           | t
 auth                | user_role_assignments           | t           | t
 auth                | user_scopes                     | t           | t
 auth                | users                           | t           | t
 core                | schema_registry                 | f           | f
 franchise           | agreements                      | t           | t
 meta                | field_contracts                 | f           | f
 meta                | table_column_standards          | f           | f
 org                 | branches                        | t           | t
 org                 | entity_branch_visibility_rules  | t           | t
 org                 | entity_relations                | t           | t
 org                 | entity_shareholders             | t           | t
 org                 | legal_entities                  | t           | t
 org                 | locations                       | t           | t
 partner             | company_relations               | t           | t
 platform            | tenants                         | t           | f
 public              | audit_logs                      | f           | f
 public              | cari_hesaplar                   | t           | t
 public              | erp_account_mapping_rules       | t           | t
 public              | erp_account_movements           | t           | t
 public              | erp_addresses                   | t           | t
 public              | erp_bank_accounts               | t           | t
 public              | erp_cash_accounts               | t           | t
 public              | erp_chart_accounts              | t           | t
 public              | erp_contacts                    | t           | t
 public              | erp_customers                   | t           | t
 public              | erp_document_number_allocations | t           | t
 public              | erp_document_sequences          | t           | t
 public              | erp_fiscal_periods              | t           | t
 public              | erp_fiscal_years                | t           | t
 public              | erp_items                       | t           | t
 public              | erp_journal_entries             | t           | t
 public              | erp_journal_lines               | t           | t
 public              | erp_ledger_balances             | t           | t
 public              | erp_parties                     | t           | t
 public              | erp_payment_transactions        | t           | t
 public              | erp_product_categories          | t           | t
 public              | erp_products                    | t           | t
 public              | erp_purchase_invoice_lines      | t           | t
 public              | erp_purchase_invoices           | t           | t
 public              | erp_purchase_order_lines        | t           | t
 public              | erp_purchase_orders             | t           | t
 public              | erp_purchase_receipt_lines      | t           | t
 public              | erp_purchase_receipts           | t           | t
 public              | erp_runtime_flow_steps          | t           | t
 public              | erp_runtime_flows               | t           | t
 public              | erp_sales_deliveries            | t           | t
 public              | erp_sales_delivery_lines        | t           | t
 public              | erp_sales_invoice_lines         | t           | t
 public              | erp_sales_invoices              | t           | t
 public              | erp_sales_order_lines           | t           | t
 public              | erp_sales_orders                | t           | t
 public              | erp_sales_quotation_lines       | t           | t
 public              | erp_sales_quotations            | t           | t
 public              | erp_stock_movements             | t           | t
 public              | erp_tax_codes                   | t           | t
 public              | erp_tax_rates                   | t           | t
 public              | erp_tax_transactions            | t           | t
 public              | erp_units                       | t           | t
 public              | erp_vendors                     | t           | t
 public              | erp_warehouse_balances          | t           | t
 public              | erp_warehouses                  | t           | t
 public              | event_store                     | f           | f
 public              | event_store_records_pg_test     | f           | f
 public              | journal_entries                 | f           | f
 public              | journal_lines                   | f           | f
 public              | org_nodes                       | f           | f
 public              | pix2pi_schema_migrations        | f           | f
 public              | read_user_projection            | f           | f
 public              | read_users                      | f           | f
 public              | role_permissions                | f           | f
 public              | roles                           | f           | f
 public              | schema_migrations               | f           | f
 public              | snapshots                       | t           | t
 public              | tenants                         | f           | f
 public              | users                           | f           | f
 readmodel           | daily_operational_metrics       | f           | f
 readmodel           | document_work_queue             | f           | f
 readmodel           | inventory_status_snapshot       | f           | f
 readmodel           | projection_state                | f           | f
 readmodel           | reconciliation_status_snapshot  | f           | f
 readmodel           | tenant_operational_snapshot     | f           | f
 runtime             | api_key_usage                   | t           | t
 runtime             | api_keys                        | t           | t
 runtime             | api_quota_policies              | t           | t
 runtime             | dedupe_records                  | t           | t
 runtime             | idempotency_keys                | t           | t
 runtime             | job_attempts                    | t           | t
 runtime             | job_queues                      | t           | t
 runtime             | jobs                            | t           | t
 runtime             | mission_control_actions         | t           | t
 runtime             | mission_control_incidents       | t           | t
 runtime             | notification_channels           | t           | t
 runtime             | notification_recipients         | t           | t
 runtime             | notifications                   | t           | t
 runtime             | plugin_states                   | t           | t
 runtime             | plugins                         | t           | t
 runtime             | service_registry_heartbeats     | t           | t
 runtime             | service_registry_instances      | t           | t
 runtime             | service_registry_services       | t           | t
 runtime             | webhook_deliveries              | t           | t
 runtime             | webhook_delivery_attempts       | t           | t
 runtime             | webhook_endpoints               | t           | t
 runtime             | workflow_approvals              | t           | t
 runtime             | workflow_definitions            | t           | t
 runtime             | workflow_instances              | t           | t
 runtime             | workflow_steps                  | t           | t
 tenant_uzmanparcaci | pilot_product_import_staging    | f           | f
(113 rows)


## Current RLS Policies

 schemaname |            tablename            |                       policyname                        | permissive |  roles   |  cmd   |                                 qual                                  |                              with_check                               
------------+---------------------------------+---------------------------------------------------------+------------+----------+--------+-----------------------------------------------------------------------+-----------------------------------------------------------------------
 audit      | audit_events                    | p_audit_events_rows_all                                 | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 audit      | export_jobs                     | p_export_jobs_rows_all                                  | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 auth       | break_glass_sessions            | p_break_glass_rows_all                                  | PERMISSIVE | {public} | ALL    | (security.is_super_admin() OR security.tenant_row_visible(tenant_id)) | (security.is_super_admin() OR security.tenant_row_visible(tenant_id))
 auth       | roles                           | p_auth_roles_rows_all                                   | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 auth       | user_role_assignments           | p_auth_role_assignments_rows_all                        | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 auth       | user_scopes                     | p_auth_scopes_rows_all                                  | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 auth       | users                           | p_auth_users_rows_all                                   | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 franchise  | agreements                      | p_franchise_rows_all                                    | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 org        | branches                        | p_branch_rows_all                                       | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 org        | entity_branch_visibility_rules  | p_visibility_rules_rows_all                             | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 org        | entity_relations                | p_entity_relations_rows_all                             | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 org        | entity_shareholders             | p_entity_shareholders_rows_all                          | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 org        | legal_entities                  | p_tenant_owned_rows_all                                 | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 org        | locations                       | p_locations_rows_all                                    | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 partner    | company_relations               | p_partner_relations_rows_all                            | PERMISSIVE | {public} | ALL    | security.tenant_row_visible(tenant_id)                                | security.tenant_row_visible(tenant_id)
 platform   | tenants                         | p_tenants_select                                        | PERMISSIVE | {public} | SELECT | security.tenant_row_visible(id)                                       | 
 public     | cari_hesaplar                   | tenant_isolation_policy                                 | PERMISSIVE | {public} | SELECT | (tenant_id = current_setting('app.tenant_id'::text, true))            | 
 public     | erp_account_mapping_rules       | erp_account_mapping_rules_tenant_isolation_policy       | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_account_movements           | erp_account_movements_tenant_isolation_policy           | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_addresses                   | erp_addresses_tenant_isolation_policy                   | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_bank_accounts               | erp_bank_accounts_tenant_isolation_policy               | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_cash_accounts               | erp_cash_accounts_tenant_isolation_policy               | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_chart_accounts              | erp_chart_accounts_tenant_isolation_policy              | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_contacts                    | erp_contacts_tenant_isolation_policy                    | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_customers                   | erp_customers_tenant_isolation_policy                   | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_document_number_allocations | erp_document_number_allocations_tenant_isolation_policy | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_document_sequences          | erp_document_sequences_tenant_isolation_policy          | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_fiscal_periods              | erp_fiscal_periods_tenant_isolation_policy              | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_fiscal_years                | erp_fiscal_years_tenant_isolation_policy                | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_items                       | erp_items_tenant_isolation_policy                       | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_journal_entries             | erp_journal_entries_tenant_isolation_policy             | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_journal_lines               | erp_journal_lines_tenant_isolation_policy               | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_ledger_balances             | erp_ledger_balances_tenant_isolation_policy             | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_parties                     | erp_parties_tenant_isolation_policy                     | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_payment_transactions        | erp_payment_transactions_tenant_isolation_policy        | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_product_categories          | erp_product_categories_tenant_isolation_policy          | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_products                    | erp_products_tenant_isolation_policy                    | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_purchase_invoice_lines      | erp_purchase_invoice_lines_tenant_isolation_policy      | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_purchase_invoices           | erp_purchase_invoices_tenant_isolation_policy           | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_purchase_order_lines        | erp_purchase_order_lines_tenant_isolation_policy        | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_purchase_orders             | erp_purchase_orders_tenant_isolation_policy             | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_purchase_receipt_lines      | erp_purchase_receipt_lines_tenant_isolation_policy      | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_purchase_receipts           | erp_purchase_receipts_tenant_isolation_policy           | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_runtime_flow_steps          | erp_runtime_flow_steps_tenant_isolation                 | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_runtime_flows               | erp_runtime_flows_tenant_isolation                      | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_sales_deliveries            | erp_sales_deliveries_tenant_isolation_policy            | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_sales_delivery_lines        | erp_sales_delivery_lines_tenant_isolation_policy        | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_sales_invoice_lines         | erp_sales_invoice_lines_tenant_isolation_policy         | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_sales_invoices              | erp_sales_invoices_tenant_isolation_policy              | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_sales_order_lines           | erp_sales_order_lines_tenant_isolation_policy           | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_sales_orders                | erp_sales_orders_tenant_isolation_policy                | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_sales_quotation_lines       | erp_sales_quotation_lines_tenant_isolation_policy       | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_sales_quotations            | erp_sales_quotations_tenant_isolation_policy            | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_stock_movements             | erp_stock_movements_tenant_isolation_policy             | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_tax_codes                   | erp_tax_codes_tenant_isolation_policy                   | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_tax_rates                   | erp_tax_rates_tenant_isolation_policy                   | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_tax_transactions            | erp_tax_transactions_tenant_isolation_policy            | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_units                       | erp_units_tenant_isolation_policy                       | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_vendors                     | erp_vendors_tenant_isolation_policy                     | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_warehouse_balances          | erp_warehouse_balances_tenant_isolation_policy          | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | erp_warehouses                  | erp_warehouses_tenant_isolation_policy                  | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.tenant_id'::text, true))            | (tenant_id = current_setting('app.tenant_id'::text, true))
 public     | snapshots                       | snapshots_tenant_policy                                 | PERMISSIVE | {public} | ALL    | (tenant_id = current_setting('app.current_tenant'::text, true))       | (tenant_id = current_setting('app.current_tenant'::text, true))
 runtime    | api_key_usage                   | p_api_key_usage_delete                                  | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | api_key_usage                   | p_api_key_usage_insert                                  | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | api_key_usage                   | p_api_key_usage_select                                  | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | api_key_usage                   | p_api_key_usage_update                                  | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | api_keys                        | p_api_keys_delete                                       | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | api_keys                        | p_api_keys_insert                                       | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | api_keys                        | p_api_keys_select                                       | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | api_keys                        | p_api_keys_update                                       | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | api_quota_policies              | p_api_quota_policies_delete                             | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | api_quota_policies              | p_api_quota_policies_insert                             | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | api_quota_policies              | p_api_quota_policies_select                             | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | api_quota_policies              | p_api_quota_policies_update                             | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | dedupe_records                  | p_dedupe_records_delete                                 | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | dedupe_records                  | p_dedupe_records_insert                                 | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | dedupe_records                  | p_dedupe_records_select                                 | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | dedupe_records                  | p_dedupe_records_update                                 | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | idempotency_keys                | p_idempotency_keys_delete                               | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | idempotency_keys                | p_idempotency_keys_insert                               | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | idempotency_keys                | p_idempotency_keys_select                               | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | idempotency_keys                | p_idempotency_keys_update                               | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | job_attempts                    | p_job_attempts_delete                                   | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | job_attempts                    | p_job_attempts_insert                                   | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | job_attempts                    | p_job_attempts_select                                   | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | job_queues                      | p_job_queues_delete                                     | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | job_queues                      | p_job_queues_insert                                     | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | job_queues                      | p_job_queues_select                                     | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | job_queues                      | p_job_queues_update                                     | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | jobs                            | p_jobs_delete                                           | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | jobs                            | p_jobs_insert                                           | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | jobs                            | p_jobs_select                                           | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | jobs                            | p_jobs_update                                           | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | mission_control_actions         | p_mission_control_actions_delete                        | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | mission_control_actions         | p_mission_control_actions_insert                        | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | mission_control_actions         | p_mission_control_actions_select                        | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | mission_control_actions         | p_mission_control_actions_update                        | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | mission_control_incidents       | p_mission_control_incidents_delete                      | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | mission_control_incidents       | p_mission_control_incidents_insert                      | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | mission_control_incidents       | p_mission_control_incidents_select                      | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | mission_control_incidents       | p_mission_control_incidents_update                      | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | notification_channels           | p_notification_channels_delete                          | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | notification_channels           | p_notification_channels_insert                          | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | notification_channels           | p_notification_channels_select                          | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | notification_channels           | p_notification_channels_update                          | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | notification_recipients         | p_notification_recipients_delete                        | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | notification_recipients         | p_notification_recipients_insert                        | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | notification_recipients         | p_notification_recipients_select                        | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | notification_recipients         | p_notification_recipients_update                        | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | notifications                   | p_notifications_delete                                  | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | notifications                   | p_notifications_insert                                  | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | notifications                   | p_notifications_select                                  | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | notifications                   | p_notifications_update                                  | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | plugin_states                   | p_plugin_states_delete                                  | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | plugin_states                   | p_plugin_states_insert                                  | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | plugin_states                   | p_plugin_states_select                                  | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | plugin_states                   | p_plugin_states_update                                  | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | plugins                         | p_plugins_delete                                        | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | plugins                         | p_plugins_insert                                        | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | plugins                         | p_plugins_select                                        | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | plugins                         | p_plugins_update                                        | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | service_registry_heartbeats     | p_service_registry_heartbeats_delete                    | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | service_registry_heartbeats     | p_service_registry_heartbeats_insert                    | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | service_registry_heartbeats     | p_service_registry_heartbeats_select                    | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | service_registry_instances      | p_service_registry_instances_delete                     | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | service_registry_instances      | p_service_registry_instances_insert                     | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | service_registry_instances      | p_service_registry_instances_select                     | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | service_registry_instances      | p_service_registry_instances_update                     | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | service_registry_services       | p_service_registry_services_delete                      | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | service_registry_services       | p_service_registry_services_insert                      | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | service_registry_services       | p_service_registry_services_select                      | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | service_registry_services       | p_service_registry_services_update                      | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | webhook_deliveries              | p_webhook_deliveries_delete                             | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | webhook_deliveries              | p_webhook_deliveries_insert                             | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | webhook_deliveries              | p_webhook_deliveries_select                             | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | webhook_deliveries              | p_webhook_deliveries_update                             | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | webhook_delivery_attempts       | p_webhook_delivery_attempts_delete                      | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | webhook_delivery_attempts       | p_webhook_delivery_attempts_insert                      | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | webhook_delivery_attempts       | p_webhook_delivery_attempts_select                      | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | webhook_endpoints               | p_webhook_endpoints_delete                              | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | webhook_endpoints               | p_webhook_endpoints_insert                              | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | webhook_endpoints               | p_webhook_endpoints_select                              | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | webhook_endpoints               | p_webhook_endpoints_update                              | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | workflow_approvals              | p_workflow_approvals_delete                             | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | workflow_approvals              | p_workflow_approvals_insert                             | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | workflow_approvals              | p_workflow_approvals_select                             | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | workflow_approvals              | p_workflow_approvals_update                             | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | workflow_definitions            | p_workflow_definitions_delete                           | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | workflow_definitions            | p_workflow_definitions_insert                           | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | workflow_definitions            | p_workflow_definitions_select                           | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | workflow_definitions            | p_workflow_definitions_update                           | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | workflow_instances              | p_workflow_instances_delete                             | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | workflow_instances              | p_workflow_instances_insert                             | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | workflow_instances              | p_workflow_instances_select                             | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | workflow_instances              | p_workflow_instances_update                             | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
 runtime    | workflow_steps                  | p_workflow_steps_delete                                 | PERMISSIVE | {public} | DELETE | security.tenant_only_row_mutable(tenant_id)                           | 
 runtime    | workflow_steps                  | p_workflow_steps_insert                                 | PERMISSIVE | {public} | INSERT |                                                                       | security.tenant_only_row_mutable(tenant_id)
 runtime    | workflow_steps                  | p_workflow_steps_select                                 | PERMISSIVE | {public} | SELECT | security.tenant_or_global_row_visible(tenant_id)                      | 
 runtime    | workflow_steps                  | p_workflow_steps_update                                 | PERMISSIVE | {public} | UPDATE | security.tenant_only_row_mutable(tenant_id)                           | security.tenant_only_row_mutable(tenant_id)
(159 rows)


## Counter Summary

- TENANT_TABLE_COUNT=100
- RLS_POLICY_COUNT=159
- RLS_ENABLED_TABLE_COUNT=87

## Pre-Audit Final Counters

- PASS_COUNT=8
- FAIL_COUNT=0
- WARN_COUNT=0

