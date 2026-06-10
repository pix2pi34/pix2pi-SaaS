#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import json
import glob
from dataclasses import dataclass, field
from typing import List, Dict, Any, Tuple

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
REPORT_DIR = os.path.join(ROOT, "reports")
JSON_REPORT = os.path.join(REPORT_DIR, "master_progress_report.json")
MD_REPORT = os.path.join(REPORT_DIR, "master_progress_report.md")

STATUS_DONE = "done"
STATUS_PARTIAL = "partial"
STATUS_TODO = "todo"

STATUS_ICON = {
    STATUS_DONE: "✅",
    STATUS_PARTIAL: "🟡",
    STATUS_TODO: "⏳",
}

@dataclass
class TaskNode:
    code: str
    title: str
    evidence: List[str] = field(default_factory=list)
    children: List["TaskNode"] = field(default_factory=list)

def relpath(path: str) -> str:
    return os.path.relpath(path, ROOT).replace("\\", "/")

def all_files() -> List[str]:
    files = []
    for base, _, names in os.walk(ROOT):
        for n in names:
            files.append(relpath(os.path.join(base, n)))
    return sorted(files)

FILES = all_files()

def find_matches(patterns: List[str], limit: int = 8) -> List[str]:
    hits = []
    for f in FILES:
        lf = f.lower()
        for p in patterns:
            if p.lower() in lf:
                hits.append(f)
                break
        if len(hits) >= limit:
            break
    return hits

def score_leaf(patterns: List[str]) -> Tuple[str, List[str], int]:
    hits = find_matches(patterns, limit=10)

    strong = 0
    medium = 0

    for h in hits:
        name = os.path.basename(h).lower()

        if any(k in name for k in [
            "test", "verify", "full", "apply", "run_", "run-", "restart",
            "rewrite", "create_", "create-", "enable_", "enable-", "audit",
            "replay", "idempotency", "dlq", "rls", "journal", "ledger"
        ]):
            strong += 1
        else:
            medium += 1

    score = strong * 2 + medium

    if score >= 4:
        return STATUS_DONE, hits, score
    if score >= 1:
        return STATUS_PARTIAL, hits, score
    return STATUS_TODO, [], 0

def aggregate(children_results: List[Dict[str, Any]]) -> Tuple[str, int]:
    if not children_results:
        return STATUS_TODO, 0

    total = len(children_results)
    done = sum(1 for c in children_results if c["status"] == STATUS_DONE)
    partial = sum(1 for c in children_results if c["status"] == STATUS_PARTIAL)

    percent = round(((done + partial * 0.5) / total) * 100)

    if done == total:
        return STATUS_DONE, percent
    if done > 0 or partial > 0:
        return STATUS_PARTIAL, percent
    return STATUS_TODO, percent

def evaluate(node: TaskNode) -> Dict[str, Any]:
    if node.children:
        child_results = [evaluate(c) for c in node.children]
        status, percent = aggregate(child_results)
        return {
            "code": node.code,
            "title": node.title,
            "status": status,
            "percent": percent,
            "children": child_results,
            "evidence": [],
        }

    status, hits, score = score_leaf(node.evidence)
    percent = 100 if status == STATUS_DONE else 50 if status == STATUS_PARTIAL else 0
    return {
        "code": node.code,
        "title": node.title,
        "status": status,
        "percent": percent,
        "score": score,
        "children": [],
        "evidence": hits,
    }

def count_stats(node: Dict[str, Any]) -> Dict[str, int]:
    stats = {"done": 0, "partial": 0, "todo": 0, "total": 0}
    if not node["children"]:
        stats[node["status"]] += 1
        stats["total"] += 1
        return stats

    for c in node["children"]:
        s = count_stats(c)
        for k, v in s.items():
            stats[k] += v
    return stats

def flatten_open_items(node: Dict[str, Any], out: List[Dict[str, Any]]) -> None:
    if not node["children"]:
        if node["status"] != STATUS_DONE:
            out.append({
                "code": node["code"],
                "title": node["title"],
                "status": node["status"],
                "evidence": node.get("evidence", []),
            })
        return
    for c in node["children"]:
        flatten_open_items(c, out)

def md_node(node: Dict[str, Any], level: int = 1) -> str:
    prefix = "#" * min(level, 6)
    lines = [f"{prefix} {STATUS_ICON[node['status']]} {node['code']} — {node['title']} ({node['percent']}%)"]
    if node["evidence"]:
        lines.append("")
        lines.append("Kanıt:")
        for e in node["evidence"][:6]:
            lines.append(f"- `{e}`")
    for c in node["children"]:
        lines.append("")
        lines.append(md_node(c, level + 1))
    return "\n".join(lines)

TASKS = [
    TaskNode("1", "FOUNDATION / PROJE TEMELİ", children=[
        TaskNode("1.1", "Proje omurgası", children=[
            TaskNode("1.1.1", "Ana repo yapısı", evidence=["cmd/", "internal/", "pkg/", "deploy/", "docs/"]),
            TaskNode("1.1.2", "Entry point standardı", evidence=["cmd/identity-api", "cmd/api-gateway", "cmd/reporting-service", "cmd/service-watchdog"]),
            TaskNode("1.1.3", "Katman standardı", evidence=["internal/common", "internal/identity", "internal/gateway", "internal/platform"]),
        ]),
        TaskNode("1.2", "Ortak teknik standartlar", children=[
            TaskNode("1.2.1", "Config standardı", evidence=["configs/config.local.yaml", "configs/config.docker.yaml", "deploy/ports.env"]),
            TaskNode("1.2.2", "Logger standardı", evidence=["pkg/logger", "logs/", "reports/ops_health_latest.txt"]),
            TaskNode("1.2.3", "Error / response contract", evidence=["kernel/http", "internal/common", "step_420_rewrite_gateway.sh"]),
        ]),
        TaskNode("1.3", "Database foundation", children=[
            TaskNode("1.3.1", "PostgreSQL temel bağlantı", evidence=["migrations/", "internal/db", "step_24_start_postgres_runtime.sh"]),
            TaskNode("1.3.2", "Migration standardı", evidence=["migrate", "migrations/kernel", "migrations/services", "cmd/migrate"]),
            TaskNode("1.3.3", "Sağlık kontrolleri", evidence=["devtools/health.sh", "step_161_check_nats_health.sh", "step_78_test_production_server_ready.sh"]),
        ]),
        TaskNode("1.4", "Local / server çalışma zemini", children=[
            TaskNode("1.4.1", "Docker temel çalışma", evidence=["Dockerfile", "deploy/docker-compose.yml", "deploy/docker/"]),
            TaskNode("1.4.2", "Ubuntu / systemd çalışma zemini", evidence=["step_303_fix_systemd_units.sh", "step_391_real_systemd_test.sh", "step_401_enable_all_services.sh"]),
            TaskNode("1.4.3", "Nginx temel kurulum", evidence=["step_79_install_nginx.sh", "nginx_backups/", "nginx-backups/"]),
        ]),
    ]),
    TaskNode("2", "SAAS CORE", children=[
        TaskNode("2.1", "Identity / auth çekirdeği", children=[
            TaskNode("2.1.1", "Identity service", evidence=["cmd/identity-api", "identity-api", "internal/identity"]),
            TaskNode("2.1.2", "Login / auth akışı", evidence=["cmd/auth-api", "step_121_create_auth_api_dir.sh", "step_123_test_auth_api_local.sh"]),
            TaskNode("2.1.3", "JWT üretimi", evidence=["step_5_run_jwt_tenant_test.sh", "step_8_run_jwt_middleware_test.sh", "kernel/authz"]),
            TaskNode("2.1.4", "JWT doğrulama", evidence=["step_132_test_gateway_bearer_tenant_match.sh", "step_130_backup_gateway_before_authz_layer.sh", "kernel/authz"]),
            TaskNode("2.1.5", "User / role temel modeli", evidence=["internal/identity", "kernel/policy", "step_16_backup_super_admin_policy.sh"]),
        ]),
        TaskNode("2.2", "Tenant çekirdeği", children=[
            TaskNode("2.2.1", "Tenant context", evidence=["kernel/tenant", "step_2_run_tenant_test.sh", "step_10_run_tenant_event_pipeline_test.sh"]),
            TaskNode("2.2.2", "Tenant middleware", evidence=["step_108_backup_api_gateway_before_tenant_middleware.sh", "step_110_test_gateway_tenant_middleware.sh"]),
            TaskNode("2.2.3", "Tenant taşıma mantığı", evidence=["step_3_backup_jwt_tenant.sh", "step_5_run_jwt_tenant_test.sh", "step_250_tenant_isolation_verification.sh"]),
            TaskNode("2.2.4", "Tenant-aware request processing", evidence=["step_12_run_tenant_service_filter_test.sh", "step_250_tenant_isolation_verification.sh"]),
        ]),
    ]),
    TaskNode("3", "SERVİS AYAĞA KALDIRMA / OPS", children=[
        TaskNode("3.1", "Servis çalışma düzeni", children=[
            TaskNode("3.1.1", "Servisler ayağa kalkıyor", evidence=["devtools/run_all.sh", "step_304_start_all_services.sh", "bin/identity-api"]),
            TaskNode("3.1.2", "Health doğrulamaları", evidence=["reports/ops_health_latest.txt", "scripts/prod_ops_suite.sh", "scripts/query_smoke_prod.sh"]),
        ]),
        TaskNode("3.2", "Operasyon araçları", children=[
            TaskNode("3.2.1", "Service registry", evidence=["cmd/service-registry", "step_206_servis_yoneticisi_kur.sh"]),
            TaskNode("3.2.2", "Mission control", evidence=["cmd/mission-control", "mission-control", "CONTROL_PANEL.md"]),
            TaskNode("3.2.3", "Service watchdog", evidence=["cmd/service-watchdog", "bin/service-watchdog", "scripts/check_ops_health_watchdog.sh"]),
        ]),
        TaskNode("3.3", "Backup / retention", children=[
            TaskNode("3.3.1", "Backup mantığı", evidence=["Back-Up/", "scripts/backup", "backups/"]),
            TaskNode("3.3.2", "Retention", evidence=["scripts/ops_retention_cleanup.sh", "scripts/run_ops_retention_daily.sh", "step_57z"]),
            TaskNode("3.3.3", "Ops health raporları", evidence=["scripts/run_ops_health_daily.sh", "reports/ops_health_latest.txt", "reports/ops_alert_latest.txt"]),
        ]),
    ]),
    TaskNode("4", "API / ACCESS LAYER", children=[
        TaskNode("4.1", "API Gateway çekirdeği", children=[
            TaskNode("4.1.1", "Tek giriş kapısı mimarisi", evidence=["cmd/api-gateway", "pix2pi-api-gateway", "step_128_test_combined_gateway.sh"]),
            TaskNode("4.1.2", "JWT enforce", evidence=["step_132_test_gateway_bearer_tenant_match.sh", "step_130_backup_gateway_before_authz_layer.sh"]),
            TaskNode("4.1.3", "Tenant enforce", evidence=["step_110_test_gateway_tenant_middleware.sh", "step_108_backup_api_gateway_before_tenant_middleware.sh"]),
            TaskNode("4.1.4", "Route standardı", evidence=["step_124_test_auth_via_gateway.sh", "step_408_full_api_integration.sh", "step_414_test_api_gateway_local.sh"]),
            TaskNode("4.1.5", "Service-to-service route policy", evidence=["cmd/service-discovery", "step_201_hybrid_service_discovery_kur.sh"]),
            TaskNode("4.1.6", "Gateway error mapping", evidence=["step_418_fix_gateway_panic.sh", "step_420_rewrite_gateway.sh"]),
        ]),
        TaskNode("4.2", "Gateway güvenilirlik ve gözlem", children=[
            TaskNode("4.2.1", "Request trace", evidence=["step_423i_dump_runner_trace.sh", "step_423j_dump_only_trace.sh", "step_423j_trace_dump.txt"]),
            TaskNode("4.2.2", "Gateway audit", evidence=["step_210_audit_full.sh", "step_261_audit_full.sh"]),
            TaskNode("4.2.3", "Health aggregation", evidence=["step_334_add_global_health_engine.sh", "step_370_real_global_status.sh"]),
            TaskNode("4.2.4", "Rate limit", evidence=["step_107_test_api_gateway_rate_limit.sh", "step_115_test_gateway_redis_rate_limit.sh", "step_131_add_nginx_global_rate_limit.sh"]),
            TaskNode("4.2.5", "Kota yönetimi", evidence=["step_69_backup_rate_limit.sh"]),
            TaskNode("4.2.6", "Request id / correlation", evidence=["kernel/http", "step_423i_dump_runner_trace.sh"]),
            TaskNode("4.2.7", "Timeout / upstream policy", evidence=["step_409_fix_gateway.sh", "step_422_rewrite_gateway_with_db_init.sh"]),
        ]),
    ]),
    TaskNode("5", "EVENT PLATFORM", children=[
        TaskNode("5.1", "Event sözleşmesi", children=[
            TaskNode("5.1.1", "Event publish standardı", evidence=["cmd/nats-publisher", "publish_event.go", "step_166_run_nats_publisher.sh"]),
            TaskNode("5.1.2", "Event consume standardı", evidence=["cmd/nats-subscriber", "cmd/event-consumer", "step_165_run_nats_subscriber.sh"]),
            TaskNode("5.1.3", "Event schema contract", evidence=["shared/contracts", "kernel/events"]),
            TaskNode("5.1.4", "Event metadata standardı", evidence=["kernel/events", "shared/contracts"]),
            TaskNode("5.1.5", "Event payload tenant zorunluluğu", evidence=["step_10_run_tenant_event_pipeline_test.sh", "step_250_tenant_isolation_verification.sh"]),
        ]),
        TaskNode("5.2", "Kalıcı Event Bus çekirdeği", children=[
            TaskNode("5.2.1", "NATS / JetStream omurgası", evidence=["deploy/nats", "step_160_install_nats_event_bus.sh", "step_172_create_jetstream_stream.sh"]),
            TaskNode("5.2.2", "Persistence", evidence=["step_170_check_jetstream.sh", "step_173_check_jetstream_stream.sh"]),
            TaskNode("5.2.3", "Consumer durability", evidence=["step_174_create_sale_consumer.sh", "step_175_check_sale_consumer.sh"]),
            TaskNode("5.2.4", "Ack policy", evidence=["step_174_create_sale_consumer.sh"]),
            TaskNode("5.2.5", "Stream retention policy", evidence=["step_172_create_jetstream_stream.sh", "scripts/ops_retention_cleanup.sh"]),
        ]),
        TaskNode("5.3", "Güvenilir tüketim", children=[
            TaskNode("5.3.1", "Retry politikası", evidence=["step_40_backup_event_retry.sh", "step_41_run_event_retry_test.sh", "step_194_test_retry.sh"]),
            TaskNode("5.3.2", "Idempotency", evidence=["step_42_backup_event_idempotency.sh", "step_43_run_event_idempotency_test.sh", "step_193_test_idempotency.sh"]),
            TaskNode("5.3.3", "DLQ", evidence=["step_44_backup_event_dlq.sh", "step_45_run_event_dlq_test.sh", "step_195_test_dlq.sh"]),
            TaskNode("5.3.4", "Poison message yönetimi", evidence=["step_45_run_event_dlq_test.sh", "step_195_test_dlq.sh"]),
            TaskNode("5.3.5", "Replay", evidence=["cmd/replay-service", "step_49_backup_event_replay.sh", "step_50_run_event_replay_test.sh"]),
            TaskNode("5.3.6", "Event versioning hazırlığı", evidence=["shared/contracts", "kernel/events"]),
            TaskNode("5.3.7", "Tenant-aware event validation", evidence=["step_10_run_tenant_event_pipeline_test.sh", "step_250_tenant_isolation_verification.sh"]),
            TaskNode("5.3.8", "Event audit trail", evidence=["step_210_audit_full.sh", "step_261_audit_full.sh", "step_45d0_event_recon.sh"]),
        ]),
        TaskNode("5.4", "Event test ve operasyon", children=[
            TaskNode("5.4.1", "Event store", evidence=["step_200_create_event_store_table.sql", "step_201_apply_event_store.sh", "step_202_test_event_store.sh"]),
            TaskNode("5.4.2", "Bus-store integration", evidence=["step_51_backup_event_bus_store_integration.sh", "step_52_run_event_bus_store_integration_test.sh"]),
            TaskNode("5.4.3", "Event platform test suite", evidence=["test_event.sh", "step_39_run_event_bus_test.sh", "step_202_test_event_store.sh"]),
        ]),
    ]),
    TaskNode("6", "ERP CORE / UFK", children=[
        TaskNode("6.1", "ERP çekirdeği", children=[
            TaskNode("6.1.1", "ERP core ayrımı", evidence=["internal/erp", "cmd/erp", "create_erp_structure.sh"]),
            TaskNode("6.1.2", "UFK çekirdeği", evidence=["internal/ufk", "step_5_run_ufk_engine.sh", "step_run_ufk_journal_ledger.sh"]),
            TaskNode("6.1.3", "Event-driven ERP", evidence=["step_run_ufk_event_engine.sh", "step_run_ufk_event_journal.sh"]),
        ]),
        TaskNode("6.2", "Journal ve ledger", children=[
            TaskNode("6.2.1", "Journal builder", evidence=["step_53_backup_journal_builder.sh", "step_55_run_journal_builder_test.sh", "step_206_test_journal_builder.sh"]),
            TaskNode("6.2.2", "Journal repository", evidence=["step_207_test_journal_repository.sh", "step_203_create_journal_tables.sql", "step_204_apply_journal_tables.sh"]),
            TaskNode("6.2.3", "Ledger posting pipeline", evidence=["step_56_backup_ledger_posting.sh", "step_57_run_ledger_posting_test.sh", "step_7_run_ledger_posting.sh"]),
            TaskNode("6.2.4", "Financial flow recon", evidence=["step_56a_finance_recon.sh", "step_56c_finance_flow_recon.sh"]),
        ]),
        TaskNode("6.3", "Muhasebe motorları", children=[
            TaskNode("6.3.1", "Tax engine", evidence=["step_7_run_tax_engine.sh", "step_220_tax_engine_full.sh"]),
            TaskNode("6.3.2", "Audit engine", evidence=["step_210_audit_full.sh", "step_211_test_audit_engine.sh", "step_262_run_audit_flow.sh"]),
            TaskNode("6.3.3", "Financial consistency", evidence=["step_5_run_financial_consistency.sh", "step_4_check_financial_consistency_files.sh"]),
            TaskNode("6.3.4", "Reporting engines", evidence=["step_run_bilanco_engine.sh", "step_run_gelir_tablosu_engine.sh", "step_run_mizan_engine.sh"]),
        ]),
    ]),
    TaskNode("7", "CACHE / PERFORMANCE", children=[
        TaskNode("7.1", "Redis çekirdeği", children=[
            TaskNode("7.1.1", "Redis entegrasyonu", evidence=["deploy/redis", "step_61_add_redis_module.sh", "cmd/redis-test"]),
            TaskNode("7.1.2", "Cache service", evidence=["cmd/cache-service", "step_189_run_cache_service.sh", "step_190_test_cache_service.sh"]),
            TaskNode("7.1.3", "Redis namespace tenant ayrımı", evidence=["step_13_backup_redis_tenant_namespace.sh", "step_15_run_redis_tenant_namespace_test.sh"]),
            TaskNode("7.1.4", "Read/write split", evidence=["step_63_backup_read_write_split.sh", "step_65_run_read_write_split_test.sh"]),
            TaskNode("7.1.5", "Reporting store", evidence=["step_66_backup_reporting_store.sh", "step_68_run_reporting_store_test.sh"]),
        ]),
    ]),
    TaskNode("8", "TENANT SECURITY / İZOLASYON", children=[
        TaskNode("8.1", "Tenant taşıma ve doğrulama", children=[
            TaskNode("8.1.1", "JWT tenant standardı", evidence=["step_3_backup_jwt_tenant.sh", "step_5_run_jwt_tenant_test.sh"]),
            TaskNode("8.1.2", "Event payload tenant zorunluluğu", evidence=["step_10_run_tenant_event_pipeline_test.sh"]),
            TaskNode("8.1.3", "Redis namespace tenant ayrımı", evidence=["step_15_run_redis_tenant_namespace_test.sh"]),
            TaskNode("8.1.4", "Audit trail tenant zorunluluğu", evidence=["step_260_create_audit_tables.sql", "step_262_run_audit_flow.sh"]),
            TaskNode("8.1.5", "Tüm servislerde tenant filter", evidence=["step_11_backup_tenant_service_filter.sh", "step_12_run_tenant_service_filter_test.sh"]),
            TaskNode("8.1.6", "Super-admin erişim sınırları", evidence=["step_16_backup_super_admin_policy.sh", "step_18_run_super_admin_policy_test.sh"]),
        ]),
        TaskNode("8.2", "Database isolation", children=[
            TaskNode("8.2.1", "PostgreSQL RLS policy", evidence=["step_19_backup_postgres_rls.sh", "step_21_run_postgres_rls_test.sh", "step_243_test_rls_real.sh"]),
            TaskNode("8.2.2", "RLS snapshots", evidence=["step_240_enable_rls_snapshots.sql", "step_241_test_rls_snapshots.sh"]),
            TaskNode("8.2.3", "Tenant isolation verification", evidence=["step_250_tenant_isolation_verification.sh", "step_251_fix_verification.sh"]),
        ]),
        TaskNode("8.3", "Operasyonel izolasyon", children=[
            TaskNode("8.3.1", "Export izolasyonu", evidence=["step_31_backup_export_isolation.sh", "step_33_run_export_isolation_test.sh"]),
            TaskNode("8.3.2", "Backup izolasyonu", evidence=["step_34_backup_backup_isolation.sh", "step_36_run_backup_isolation_test.sh"]),
        ]),
    ]),
    TaskNode("9", "READ MODEL / REPORTING", children=[
        TaskNode("9.1", "Query / projection", children=[
            TaskNode("9.1.1", "Query read model", evidence=["cmd/query-read-model", "step_202_query_read_model_kur_ve_test_et.sh", "scripts/rebuild_read_users_projection.sh"]),
            TaskNode("9.1.2", "Projection rebuild", evidence=["scripts/rebuild_read_users_projection.sh", "scripts/query_ops_suite.sh"]),
            TaskNode("9.1.3", "Query service gateway entegrasyonu", evidence=["step_407_create_query_service.sh", "step_408_full_api_integration.sh", "step_408d_verify_query_service.sh"]),
        ]),
        TaskNode("9.2", "Reporting", children=[
            TaskNode("9.2.1", "Reporting service", evidence=["cmd/reporting-service", "step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh"]),
            TaskNode("9.2.2", "Reporting subscriber", evidence=["step_190_reporting_subscriber_kur_ve_calistir.sh", "step_203_reporting_to_query_read_model_bagla.sh"]),
            TaskNode("9.2.3", "Panel entegrasyonu", evidence=["step_192_reporting_service_panelde_goster.sh", "step_199_fix_panel_reporting_service.sh"]),
        ]),
    ]),
    TaskNode("10", "INFRA / EDGE / DOMAIN", children=[
        TaskNode("10.1", "Server ve nginx", children=[
            TaskNode("10.1.1", "Production server hazırlığı", evidence=["step_72_check_production_server.sh", "step_78_test_production_server_ready.sh"]),
            TaskNode("10.1.2", "Firewall", evidence=["step_76_configure_production_firewall.sh"]),
            TaskNode("10.1.3", "Nginx", evidence=["step_79_install_nginx.sh", "step_88_test_split_routes.sh", "step_91_test_server_ssl_strict.sh"]),
            TaskNode("10.1.4", "SSL / routing", evidence=["step_84_backup_nginx_ssl_split.sh", "step_86_extend_ssl_server_subdomain.sh", "step_93_reload_nginx_after_redirect_fix.sh"]),
            TaskNode("10.1.5", "Monitor route", evidence=["step_343_add_monitor_route.sh", "web/monitor.html", "step_360_rewrite_monitor_hardening.sh"]),
        ]),
    ]),
    TaskNode("11", "OBSERVABILITY / OPS CONTROL", children=[
        TaskNode("11.1", "Observability stack", children=[
            TaskNode("11.1.1", "Prometheus/Grafana/Loki", evidence=["deploy/observability", "grafana/dashboards", "step_270_observability_stack.sh", "step_272_test_observability_stack.sh"]),
            TaskNode("11.1.2", "Promtail / log hygiene", evidence=["step_273_fix_promtail_positions.sh", "step_281_logrotate_snapshot.sh", "step_284_remove_snapshot_from_promtail.sh"]),
        ]),
        TaskNode("11.2", "Watchdog / monitor", children=[
            TaskNode("11.2.1", "Watchdog", evidence=["cmd/service-watchdog", "step_291_watchdog_service.sh", "step_333_test_watchdog_degraded_logic.sh"]),
            TaskNode("11.2.2", "Panel monitor", evidence=["step_320_rewrite_panel_index.sh", "step_368_panel_final_logic_fix.sh", "step_364_bind_panel_to_service_status_json.sh"]),
            TaskNode("11.2.3", "Global health", evidence=["step_334_add_global_health_engine.sh", "step_370_real_global_status.sh"]),
        ]),
        TaskNode("11.3", "Early warning / auto heal", children=[
            TaskNode("11.3.1", "Early warning collector", evidence=["step_371_add_early_warning_collector.sh", "step_372_test_early_warning_collector.sh", "step_390_rewrite_early_warning_clean.sh"]),
            TaskNode("11.3.2", "Auto heal", evidence=["step_374_add_auto_heal_engine.sh", "step_377_advanced_auto_heal.sh", "step_397_fix_auto_heal_source.sh"]),
            TaskNode("11.3.3", "Alert engine", evidence=["step_378_add_alert_engine.sh", "scripts/test_ops_health_alarm_chain.sh", "scripts/test_ops_service_alarm_chain.sh"]),
        ]),
    ]),
    TaskNode("12", "PLATFORM SERVİSLERİ", children=[
        TaskNode("12.1", "Stock / accounting / services", children=[
            TaskNode("12.1.1", "Stock service", evidence=["cmd/stock-service", "step_182_run_stock_service.sh"]),
            TaskNode("12.1.2", "Accounting service", evidence=["cmd/accounting-service", "step_183_run_accounting_service.sh"]),
            TaskNode("12.1.3", "Service discovery", evidence=["cmd/service-discovery", "step_201_hybrid_service_discovery_kur.sh"]),
        ]),
    ]),
    TaskNode("13", "ERP DERİNLEŞME / TÜRKİYE", children=[
        TaskNode("13.1", "Rapor ve finans modülleri", children=[
            TaskNode("13.1.1", "Bilanço / gelir / mizan", evidence=["step_run_bilanco_engine.sh", "step_run_gelir_tablosu_engine.sh", "step_run_mizan_engine.sh"]),
            TaskNode("13.1.2", "Cari / kasa / banka ekstre", evidence=["step_run_cari_ekstre.sh", "step_run_kasa_ekstre.sh", "step_run_banka_ekstre.sh"]),
            TaskNode("13.1.3", "Tahsilat / ödeme / settlement", evidence=["step_5_run_tahsilat_odeme_v2.sh", "step_6_run_settlement_engine.sh", "step_5_run_payment_engine.sh"]),
            TaskNode("13.1.4", "Commission / payout / wallet", evidence=["step_2_run_commission_engine.sh", "step_7_run_merchant_payout_engine.sh", "step_6_run_wallet_transfer_engine.sh"]),
        ]),
    ]),
    TaskNode("14", "TEST / QUALITY GATE", children=[
        TaskNode("14.1", "Test katmanları", children=[
            TaskNode("14.1.1", "Unit/integration test izi", evidence=["coverage.out", "test/internal", "test/e2e"]),
            TaskNode("14.1.2", "Prod smoke / ops suite", evidence=["scripts/prod_finance_smoke.sh", "scripts/prod_ops_suite.sh", "scripts/query_smoke_prod.sh"]),
            TaskNode("14.1.3", "Guard / quality gates", evidence=["guard/pix2pi_guard.sh", "guard/quality_gates.env", "guard/import_guard.sh"]),
        ]),
    ]),
]

def main() -> None:
    os.makedirs(REPORT_DIR, exist_ok=True)

    results = [evaluate(t) for t in TASKS]

    all_stats = {"done": 0, "partial": 0, "todo": 0, "total": 0}
    for r in results:
        s = count_stats(r)
        for k, v in s.items():
            all_stats[k] += v

    overall_percent = round(
        ((all_stats["done"] + all_stats["partial"] * 0.5) / max(all_stats["total"], 1)) * 100
    )

    open_items = []
    for r in results:
        flatten_open_items(r, open_items)

    payload = {
        "root": ROOT,
        "files_scanned": len(FILES),
        "overall_percent": overall_percent,
        "stats": all_stats,
        "results": results,
        "open_items": sorted(open_items, key=lambda x: (x["status"], x["code"])),
    }

    with open(JSON_REPORT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    md_lines = []
    md_lines.append("# Pix2pi Master Progress Report")
    md_lines.append("")
    md_lines.append(f"- Scanned files: **{len(FILES)}**")
    md_lines.append(f"- Overall progress: **%{overall_percent}**")
    md_lines.append(f"- Done: **{all_stats['done']}**")
    md_lines.append(f"- Partial: **{all_stats['partial']}**")
    md_lines.append(f"- Todo: **{all_stats['todo']}**")
    md_lines.append("")

    md_lines.append("## Phase Summary")
    md_lines.append("")
    for r in results:
        md_lines.append(f"- {STATUS_ICON[r['status']]} **{r['code']} {r['title']}** → %{r['percent']}")
    md_lines.append("")

    md_lines.append("## Detailed Tree")
    md_lines.append("")
    for r in results:
        md_lines.append(md_node(r, level=2))
        md_lines.append("")

    md_lines.append("## Open Items")
    md_lines.append("")
    for item in payload["open_items"]:
        md_lines.append(f"- {STATUS_ICON[item['status']]} **{item['code']} {item['title']}**")
        for e in item["evidence"][:3]:
            md_lines.append(f"  - kanıt: `{e}`")

    with open(MD_REPORT, "w", encoding="utf-8") as f:
        f.write("\n".join(md_lines))

    print("OK ✅ audit tamam")
    print(f"Scanned files      : {len(FILES)}")
    print(f"Overall progress   : %{overall_percent}")
    print(f"Done               : {all_stats['done']}")
    print(f"Partial            : {all_stats['partial']}")
    print(f"Todo               : {all_stats['todo']}")
    print(f"JSON report        : {JSON_REPORT}")
    print(f"Markdown report    : {MD_REPORT}")

if __name__ == "__main__":
    main()
