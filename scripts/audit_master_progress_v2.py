#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json
from dataclasses import dataclass, field
from typing import List, Dict, Any, Tuple

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
REPORT_DIR = os.path.join(ROOT, "reports")
JSON_REPORT = os.path.join(REPORT_DIR, "master_progress_report_v2.json")
MD_REPORT = os.path.join(REPORT_DIR, "master_progress_report_v2.md")

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
    evidence: Dict[str, List[str]] = field(default_factory=dict)
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

def find_matches(patterns: List[str], limit: int = 12) -> List[str]:
    hits = []
    lowered = [p.lower() for p in patterns]
    for f in FILES:
        lf = f.lower()
        for p in lowered:
            if p in lf:
                hits.append(f)
                break
        if len(hits) >= limit:
            break
    return hits

def normalize_group_hits(evidence: Dict[str, List[str]]) -> Dict[str, List[str]]:
    result = {}
    for group, patterns in evidence.items():
        result[group] = find_matches(patterns, limit=12)
    return result

def score_leaf(evidence: Dict[str, List[str]]) -> Tuple[str, int, Dict[str, Any]]:
    """
    Grup mantığı:
    - code/service: gerçek kod/servis izi
    - test: test/verify/recon/smoke
    - run: run/apply/restart/enable/live
    - config: config/sql/contracts
    - ops: rapor/log/cron/monitor
    - backup: sadece yedek; done puanına sayılmaz
    """

    hits = normalize_group_hits(evidence)

    has_code = len(hits.get("code", [])) > 0
    has_test = len(hits.get("test", [])) > 0
    has_run = len(hits.get("run", [])) > 0
    has_config = len(hits.get("config", [])) > 0
    has_ops = len(hits.get("ops", [])) > 0
    has_backup = len(hits.get("backup", [])) > 0

    score = 0
    if has_code:
        score += 3
    if has_test:
        score += 3
    if has_run:
        score += 2
    if has_config:
        score += 1
    if has_ops:
        score += 1

    # backup sadece bilgi, puan değil
    required_for_done = has_code and has_test and (has_run or has_ops)

    if required_for_done and score >= 7:
        status = STATUS_DONE
    elif score >= 3:
        status = STATUS_PARTIAL
    else:
        status = STATUS_TODO

    confidence = min(100, score * 10 + (10 if required_for_done else 0))

    missing = []
    if not has_code:
        missing.append("code/service evidence")
    if not has_test:
        missing.append("test evidence")
    if not has_run and not has_ops:
        missing.append("run/live/ops evidence")
    if not has_config:
        missing.append("config/schema/contract evidence")

    summary = {
        "hits": hits,
        "has_code": has_code,
        "has_test": has_test,
        "has_run": has_run,
        "has_config": has_config,
        "has_ops": has_ops,
        "has_backup": has_backup,
        "missing": missing,
    }

    return status, confidence, summary

def aggregate(children_results: List[Dict[str, Any]]) -> Tuple[str, int, int]:
    if not children_results:
        return STATUS_TODO, 0, 0

    total = len(children_results)
    done = sum(1 for c in children_results if c["status"] == STATUS_DONE)
    partial = sum(1 for c in children_results if c["status"] == STATUS_PARTIAL)

    percent = round(((done + partial * 0.5) / total) * 100)
    confidence = round(sum(c.get("confidence", 0) for c in children_results) / total)

    if done == total:
        return STATUS_DONE, percent, confidence
    if done > 0 or partial > 0:
        return STATUS_PARTIAL, percent, confidence
    return STATUS_TODO, percent, confidence

def evaluate(node: TaskNode) -> Dict[str, Any]:
    if node.children:
        child_results = [evaluate(c) for c in node.children]
        status, percent, confidence = aggregate(child_results)
        return {
            "code": node.code,
            "title": node.title,
            "status": status,
            "percent": percent,
            "confidence": confidence,
            "children": child_results,
            "evidence": {},
            "missing": [],
        }

    status, confidence, summary = score_leaf(node.evidence)
    percent = 100 if status == STATUS_DONE else 50 if status == STATUS_PARTIAL else 0

    return {
        "code": node.code,
        "title": node.title,
        "status": status,
        "percent": percent,
        "confidence": confidence,
        "children": [],
        "evidence": summary["hits"],
        "missing": summary["missing"],
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

def flatten_non_done(node: Dict[str, Any], out: List[Dict[str, Any]]) -> None:
    if not node["children"]:
        if node["status"] != STATUS_DONE:
            out.append({
                "code": node["code"],
                "title": node["title"],
                "status": node["status"],
                "confidence": node.get("confidence", 0),
                "missing": node.get("missing", []),
                "evidence": node.get("evidence", {}),
            })
        return
    for c in node["children"]:
        flatten_non_done(c, out)

def md_leaf_evidence(ev: Dict[str, List[str]]) -> List[str]:
    lines = []
    for group in ["code", "test", "run", "config", "ops", "backup"]:
        vals = ev.get(group, [])
        if vals:
            lines.append(f"- {group}:")
            for v in vals[:3]:
                lines.append(f"  - `{v}`")
    return lines

def md_node(node: Dict[str, Any], level: int = 1) -> str:
    prefix = "#" * min(level, 6)
    lines = [f"{prefix} {STATUS_ICON[node['status']]} {node['code']} — {node['title']} ({node['percent']}%, confidence={node['confidence']})"]

    if node["missing"]:
        lines.append("")
        lines.append("Eksik Kanıt:")
        for m in node["missing"]:
            lines.append(f"- {m}")

    if node["evidence"]:
        lines.append("")
        lines.append("Kanıt Özeti:")
        lines.extend(md_leaf_evidence(node["evidence"]))

    for c in node["children"]:
        lines.append("")
        lines.append(md_node(c, level + 1))

    return "\n".join(lines)

TASKS = [
    TaskNode("1", "FOUNDATION / PROJE TEMELİ", children=[
        TaskNode("1.1.1", "Ana repo yapısı", evidence={
            "code": ["cmd/", "internal/", "pkg/", "deploy/", "docs/"],
            "config": ["README.md", "PORTS.md"],
        }),
        TaskNode("1.1.2", "Entry point standardı", evidence={
            "code": ["cmd/identity-api", "cmd/api-gateway", "cmd/reporting-service", "cmd/service-watchdog"],
            "test": ["step_188_verify_done_items.sh"],
        }),
        TaskNode("1.2.1", "Config standardı", evidence={
            "config": ["configs/config.local.yaml", "configs/config.docker.yaml", "deploy/ports.env"],
            "code": ["internal/common", "kernel/http"],
        }),
        TaskNode("1.3.1", "PostgreSQL temel bağlantı", evidence={
            "code": ["internal/db", "cmd/migrate", "migrations/"],
            "run": ["step_24_start_postgres_runtime.sh"],
            "test": ["step_26_test_postgres_login.sh"],
        }),
        TaskNode("1.4.1", "Docker temel çalışma", evidence={
            "code": ["Dockerfile", "deploy/docker-compose.yml", "deploy/docker/"],
            "run": ["step_75_install_or_verify_docker.sh"],
            "test": ["step_78_test_production_server_ready.sh"],
        }),
        TaskNode("1.4.3", "Nginx temel kurulum", evidence={
            "run": ["step_79_install_nginx.sh", "step_85_reload_nginx_split.sh"],
            "test": ["step_88_test_split_routes.sh", "step_89_test_server_ssl.sh"],
            "config": ["nginx_backups/", "nginx-backups/"],
        }),
    ]),
    TaskNode("2", "SAAS CORE", children=[
        TaskNode("2.1.1", "Identity service", evidence={
            "code": ["cmd/identity-api", "internal/identity", "identity-api"],
            "run": ["devtools/run_identity.sh"],
            "test": ["step_101_test_identity_gateway_ports.sh"],
        }),
        TaskNode("2.1.2", "Login / auth akışı", evidence={
            "code": ["cmd/auth-api"],
            "run": ["step_122_run_auth_api.sh"],
            "test": ["step_123_test_auth_api_local.sh", "step_124_test_auth_via_gateway.sh"],
        }),
        TaskNode("2.1.3", "JWT üretimi", evidence={
            "code": ["kernel/authz", "internal/identity"],
            "test": ["step_5_run_jwt_tenant_test.sh", "step_8_run_jwt_middleware_test.sh"],
        }),
        TaskNode("2.1.4", "JWT doğrulama", evidence={
            "code": ["kernel/authz"],
            "test": ["step_132_test_gateway_bearer_tenant_match.sh"],
            "backup": ["step_130_backup_gateway_before_authz_layer.sh"],
        }),
        TaskNode("2.2.1", "Tenant context", evidence={
            "code": ["kernel/tenant"],
            "test": ["step_2_run_tenant_test.sh", "step_10_run_tenant_event_pipeline_test.sh"],
        }),
        TaskNode("2.2.2", "Tenant middleware", evidence={
            "code": ["internal/gateway", "kernel/tenant"],
            "test": ["step_110_test_gateway_tenant_middleware.sh"],
            "backup": ["step_108_backup_api_gateway_before_tenant_middleware.sh"],
        }),
        TaskNode("2.2.4", "Tenant-aware request processing", evidence={
            "code": ["internal/services", "kernel/tenant"],
            "test": ["step_12_run_tenant_service_filter_test.sh", "step_250_tenant_isolation_verification.sh"],
        }),
    ]),
    TaskNode("3", "SERVİS / OPS", children=[
        TaskNode("3.2.1", "Service registry", evidence={
            "code": ["cmd/service-registry", "service-registry"],
            "run": ["step_206_servis_yoneticisi_kur.sh"],
            "ops": ["config/service_watchdog_services.json"],
        }),
        TaskNode("3.3.1", "Backup mantığı", evidence={
            "code": ["scripts/backup", "Back-Up/", "backups/"],
            "run": ["backup_pix2pi.sh", "restic_backup.sh"],
            "ops": ["restic_backup.log"],
        }),
        TaskNode("3.3.2", "Retention", evidence={
            "code": ["scripts/ops_retention_cleanup.sh", "scripts/run_ops_retention_daily.sh"],
            "test": ["test_ops_daily_alert_chain.sh"],
            "ops": ["reports/ops_health_latest.txt"],
        }),
    ]),
    TaskNode("4", "API GATEWAY", children=[
        TaskNode("4.1.1", "Tek giriş kapısı mimarisi", evidence={
            "code": ["cmd/api-gateway", "pix2pi-api-gateway"],
            "run": ["step_99_run_api_gateway.sh", "step_127_restart_combined_gateway.sh"],
            "test": ["step_128_test_combined_gateway.sh"],
        }),
        TaskNode("4.1.2", "JWT enforce", evidence={
            "code": ["kernel/authz", "internal/gateway"],
            "test": ["step_132_test_gateway_bearer_tenant_match.sh"],
        }),
        TaskNode("4.1.3", "Tenant enforce", evidence={
            "code": ["kernel/tenant", "internal/gateway"],
            "test": ["step_110_test_gateway_tenant_middleware.sh"],
        }),
        TaskNode("4.1.6", "Gateway error mapping", evidence={
            "code": ["step_420_rewrite_gateway.sh"],
            "run": ["step_418_fix_gateway_panic.sh", "step_422_rewrite_gateway_with_db_init.sh"],
            "test": ["step_414_test_api_gateway_local.sh"],
        }),
        TaskNode("4.2.1", "Request trace", evidence={
            "ops": ["step_423i_dump_runner_trace.sh", "step_423j_dump_only_trace.sh", "step_423j_trace_dump.txt"],
        }),
        TaskNode("4.2.3", "Health aggregation", evidence={
            "code": ["step_334_add_global_health_engine.sh"],
            "test": ["step_370_real_global_status.sh"],
            "ops": ["reports/ops_health_latest.txt"],
        }),
        TaskNode("4.2.4", "Rate limit", evidence={
            "code": ["deploy/redis", "internal/gateway"],
            "run": ["step_131_add_nginx_global_rate_limit.sh"],
            "test": ["step_107_test_api_gateway_rate_limit.sh", "step_115_test_gateway_redis_rate_limit.sh", "step_71_run_rate_limit_test.sh"],
        }),
        TaskNode("4.2.5", "Kota yönetimi", evidence={
            "backup": ["step_69_backup_rate_limit.sh"],
            "code": ["internal/gateway"],
        }),
        TaskNode("4.2.6", "Request id / correlation", evidence={
            "code": ["kernel/http"],
            "ops": ["step_423i_dump_runner_trace.sh"],
        }),
        TaskNode("4.2.7", "Timeout / upstream policy", evidence={
            "code": ["step_420_rewrite_gateway.sh"],
            "run": ["step_409_fix_gateway.sh", "step_422_rewrite_gateway_with_db_init.sh"],
        }),
    ]),
    TaskNode("5", "EVENT PLATFORM", children=[
        TaskNode("5.1.1", "Event publish standardı", evidence={
            "code": ["cmd/nats-publisher", "publish_event.go", "kernel/events"],
            "run": ["step_166_run_nats_publisher.sh"],
            "test": ["test_event.sh"],
        }),
        TaskNode("5.1.2", "Event consume standardı", evidence={
            "code": ["cmd/nats-subscriber", "cmd/event-consumer"],
            "run": ["step_165_run_nats_subscriber.sh"],
            "test": ["step_39_run_event_bus_test.sh"],
        }),
        TaskNode("5.2.1", "NATS / JetStream omurgası", evidence={
            "code": ["deploy/nats", "cmd/event-bus"],
            "run": ["step_160_install_nats_event_bus.sh", "step_172_create_jetstream_stream.sh"],
            "test": ["step_170_check_jetstream.sh", "step_173_check_jetstream_stream.sh"],
        }),
        TaskNode("5.2.3", "Consumer durability", evidence={
            "run": ["step_174_create_sale_consumer.sh"],
            "test": ["step_175_check_sale_consumer.sh"],
            "config": ["deploy/nats"],
        }),
        TaskNode("5.3.1", "Retry politikası", evidence={
            "code": ["cmd/replay-service", "kernel/events"],
            "test": ["step_41_run_event_retry_test.sh", "step_194_test_retry.sh"],
            "backup": ["step_40_backup_event_retry.sh"],
        }),
        TaskNode("5.3.2", "Idempotency", evidence={
            "code": ["step_191_prepare_idempotency_folder.sh", "kernel/events"],
            "test": ["step_43_run_event_idempotency_test.sh", "step_193_test_idempotency.sh"],
            "backup": ["step_42_backup_event_idempotency.sh"],
        }),
        TaskNode("5.3.3", "DLQ", evidence={
            "code": ["kernel/events"],
            "test": ["step_45_run_event_dlq_test.sh", "step_195_test_dlq.sh"],
            "backup": ["step_44_backup_event_dlq.sh"],
        }),
        TaskNode("5.3.4", "Poison message yönetimi", evidence={
            "test": ["step_45_run_event_dlq_test.sh", "step_195_test_dlq.sh"],
            "code": ["kernel/events"],
        }),
        TaskNode("5.3.5", "Replay", evidence={
            "code": ["cmd/replay-service"],
            "run": ["step_196_run_replay_service.sh"],
            "test": ["step_50_run_event_replay_test.sh"],
        }),
        TaskNode("5.3.8", "Event audit trail", evidence={
            "code": ["step_210_prepare_audit_folder.sh"],
            "run": ["step_210_audit_full.sh", "step_261_audit_full.sh"],
            "test": ["step_211_test_audit_engine.sh"],
        }),
        TaskNode("5.4.1", "Event store", evidence={
            "code": ["step_200_create_event_store_table.sql"],
            "run": ["step_201_apply_event_store.sh"],
            "test": ["step_202_test_event_store.sh"],
        }),
        TaskNode("5.4.2", "Bus-store integration", evidence={
            "test": ["step_52_run_event_bus_store_integration_test.sh"],
            "backup": ["step_51_backup_event_bus_store_integration.sh"],
        }),
        TaskNode("5.4.3", "Event platform test suite", evidence={
            "test": ["test_event.sh", "step_39_run_event_bus_test.sh", "step_202_test_event_store.sh"],
            "code": ["test/e2e", "test/internal"],
        }),
    ]),
    TaskNode("6", "ERP / UFK", children=[
        TaskNode("6.1.2", "UFK çekirdeği", evidence={
            "code": ["internal/ufk", "cmd/erp"],
            "run": ["step_5_run_ufk_engine.sh", "step_run_ufk_journal_ledger.sh"],
            "test": ["prod_finance_smoke.sh"],
        }),
        TaskNode("6.2.1", "Journal builder", evidence={
            "code": ["step_205_prepare_journal_builder_folder.sh", "internal/erp", "internal/ufk"],
            "run": ["step_6_run_journal_builder.sh"],
            "test": ["step_55_run_journal_builder_test.sh", "step_206_test_journal_builder.sh"],
        }),
        TaskNode("6.2.2", "Journal repository", evidence={
            "code": ["step_203_create_journal_tables.sql"],
            "run": ["step_204_apply_journal_tables.sh"],
            "test": ["step_207_test_journal_repository.sh"],
        }),
        TaskNode("6.2.3", "Ledger posting pipeline", evidence={
            "code": ["internal/ufk", "internal/erp"],
            "run": ["step_7_run_ledger_posting.sh"],
            "test": ["step_57_run_ledger_posting_test.sh"],
            "backup": ["step_56_backup_ledger_posting.sh"],
        }),
        TaskNode("6.2.4", "Financial flow recon", evidence={
            "test": ["step_56a_finance_recon.sh", "step_56c_finance_flow_recon.sh"],
            "ops": ["step_56a_finance_recon.txt", "step_56c_finance_flow_recon.txt"],
        }),
        TaskNode("6.3.1", "Tax engine", evidence={
            "code": ["internal/finance"],
            "run": ["step_7_run_tax_engine.sh", "step_220_tax_engine_full.sh"],
            "test": ["step_6_check_tax_engine_files.sh"],
        }),
        TaskNode("6.3.2", "Audit engine", evidence={
            "code": ["step_260_create_audit_tables.sql"],
            "run": ["step_261_audit_full.sh", "step_262_run_audit_flow.sh"],
            "test": ["step_211_test_audit_engine.sh"],
        }),
    ]),
    TaskNode("7", "REDIS / CACHE / REPORT", children=[
        TaskNode("7.1.1", "Redis entegrasyonu", evidence={
            "code": ["deploy/redis", "cmd/redis-test", "cmd/cache-service"],
            "run": ["step_61_add_redis_module.sh", "step_189_run_cache_service.sh"],
            "test": ["step_62_run_real_redis_cache_test.sh", "step_190_test_cache_service.sh"],
        }),
        TaskNode("7.1.3", "Redis namespace tenant ayrımı", evidence={
            "code": ["cmd/cache-service"],
            "test": ["step_15_run_redis_tenant_namespace_test.sh"],
            "backup": ["step_13_backup_redis_tenant_namespace.sh"],
        }),
        TaskNode("7.1.4", "Read/write split", evidence={
            "code": ["cmd/query-read-model"],
            "test": ["step_65_run_read_write_split_test.sh"],
            "backup": ["step_63_backup_read_write_split.sh"],
        }),
        TaskNode("7.1.5", "Reporting store", evidence={
            "code": ["cmd/reporting-service"],
            "test": ["step_68_run_reporting_store_test.sh"],
            "backup": ["step_66_backup_reporting_store.sh"],
        }),
    ]),
    TaskNode("8", "TENANT SECURITY", children=[
        TaskNode("8.1.1", "JWT tenant standardı", evidence={
            "code": ["kernel/tenant", "kernel/authz"],
            "test": ["step_5_run_jwt_tenant_test.sh"],
            "backup": ["step_3_backup_jwt_tenant.sh"],
        }),
        TaskNode("8.1.2", "Event payload tenant zorunluluğu", evidence={
            "code": ["kernel/events", "shared/contracts"],
            "test": ["step_10_run_tenant_event_pipeline_test.sh"],
        }),
        TaskNode("8.1.4", "Audit trail tenant zorunluluğu", evidence={
            "code": ["step_260_create_audit_tables.sql"],
            "run": ["step_262_run_audit_flow.sh"],
        }),
        TaskNode("8.1.5", "Tüm servislerde tenant filter", evidence={
            "code": ["kernel/tenant", "internal/services"],
            "test": ["step_12_run_tenant_service_filter_test.sh"],
            "backup": ["step_11_backup_tenant_service_filter.sh"],
        }),
        TaskNode("8.1.6", "Super-admin erişim sınırları", evidence={
            "code": ["kernel/policy"],
            "test": ["step_18_run_super_admin_policy_test.sh"],
            "backup": ["step_16_backup_super_admin_policy.sh"],
        }),
        TaskNode("8.2.1", "PostgreSQL RLS policy", evidence={
            "code": ["step_240_enable_rls_snapshots.sql", "migrations/"],
            "run": ["step_240_enable_rls_snapshots.sh"],
            "test": ["step_21_run_postgres_rls_test.sh", "step_243_test_rls_real.sh"],
        }),
        TaskNode("8.2.3", "Tenant isolation verification", evidence={
            "test": ["step_250_tenant_isolation_verification.sh"],
            "run": ["step_251_fix_verification.sh"],
        }),
        TaskNode("8.3.1", "Export izolasyonu", evidence={
            "test": ["step_33_run_export_isolation_test.sh"],
            "backup": ["step_31_backup_export_isolation.sh"],
        }),
        TaskNode("8.3.2", "Backup izolasyonu", evidence={
            "test": ["step_36_run_backup_isolation_test.sh"],
            "backup": ["step_34_backup_backup_isolation.sh"],
        }),
    ]),
    TaskNode("9", "QUERY / REPORTING", children=[
        TaskNode("9.1.1", "Query read model", evidence={
            "code": ["cmd/query-read-model"],
            "run": ["step_202_query_read_model_kur_ve_test_et.sh", "step_407_create_query_service.sh"],
            "test": ["step_407_test_query.sh", "step_408d_verify_query_service.sh"],
        }),
        TaskNode("9.1.2", "Projection rebuild", evidence={
            "code": ["scripts/rebuild_read_users_projection.sh"],
            "run": ["scripts/query_ops_suite.sh"],
            "test": ["scripts/query_post_restart_check.sh"],
        }),
        TaskNode("9.1.3", "Query service gateway entegrasyonu", evidence={
            "code": ["cmd/api-gateway", "cmd/query-read-model"],
            "run": ["step_408_full_api_integration.sh", "step_408e_patch_gateway.sh"],
            "test": ["step_408_test_api_gateway_nethttp.sh"],
        }),
        TaskNode("9.2.1", "Reporting service", evidence={
            "code": ["cmd/reporting-service", "cmd/reporting_service_main.go"],
            "run": ["step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh"],
            "test": ["step_198_reporting_service_json_sabitle.sh"],
        }),
        TaskNode("9.2.2", "Reporting subscriber", evidence={
            "code": ["cmd/reporting-service"],
            "run": ["step_190_reporting_subscriber_kur_ve_calistir.sh", "step_203_reporting_to_query_read_model_bagla.sh"],
            "test": ["step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh"],
        }),
        TaskNode("9.2.3", "Panel entegrasyonu", evidence={
            "code": ["cmd/control-panel", "web/monitor.html"],
            "run": ["step_192_reporting_service_panelde_goster.sh", "step_194_panel_html_reporting_service_ekle.sh"],
            "test": ["step_199_fix_panel_reporting_service.sh"],
        }),
    ]),
    TaskNode("10", "INFRA / EDGE", children=[
        TaskNode("10.1.1", "Production server hazırlığı", evidence={
            "run": ["step_72_check_production_server.sh", "step_73_update_production_server.sh", "step_74_install_production_base_packages.sh"],
            "test": ["step_78_test_production_server_ready.sh"],
        }),
        TaskNode("10.1.2", "Firewall", evidence={
            "run": ["step_76_configure_production_firewall.sh"],
        }),
        TaskNode("10.1.4", "SSL / routing", evidence={
            "config": ["nginx_backups/", "nginx-backups/"],
            "run": ["step_84_backup_nginx_ssl_split.sh", "step_86_extend_ssl_server_subdomain.sh", "step_93_reload_nginx_after_redirect_fix.sh"],
            "test": ["step_91_test_server_ssl_strict.sh"],
        }),
    ]),
    TaskNode("11", "OBSERVABILITY / EARLY WARNING", children=[
        TaskNode("11.1.1", "Prometheus/Grafana/Loki", evidence={
            "code": ["deploy/observability", "grafana/dashboards"],
            "run": ["step_270_observability_stack.sh", "step_271_run_observability_stack.sh"],
            "test": ["step_272_test_observability_stack.sh"],
        }),
        TaskNode("11.1.2", "Promtail / log hygiene", evidence={
            "run": ["step_273_fix_promtail_positions.sh", "step_281_logrotate_snapshot.sh", "step_284_remove_snapshot_from_promtail.sh"],
            "ops": ["reports/ops_health_latest.txt"],
        }),
        TaskNode("11.2.3", "Global health", evidence={
            "code": ["cmd/service-watchdog"],
            "run": ["step_334_add_global_health_engine.sh"],
            "test": ["step_370_real_global_status.sh"],
        }),
        TaskNode("11.3.1", "Early warning collector", evidence={
            "run": ["step_371_add_early_warning_collector.sh", "step_390_rewrite_early_warning_clean.sh"],
            "test": ["step_372_test_early_warning_collector.sh"],
            "ops": ["scripts/test_ops_health_alarm_chain.sh"],
        }),
        TaskNode("11.3.2", "Auto heal", evidence={
            "run": ["step_374_add_auto_heal_engine.sh", "step_377_advanced_auto_heal.sh"],
            "test": ["step_397_fix_auto_heal_source.sh"],
            "ops": ["scripts/test_ops_service_alarm_chain.sh"],
        }),
    ]),
    TaskNode("12", "PLATFORM SERVISLERI", children=[
        TaskNode("12.1.1", "Stock service", evidence={
            "code": ["cmd/stock-service", "cmd/stok-servisi"],
            "run": ["step_182_run_stock_service.sh"],
        }),
        TaskNode("12.1.2", "Accounting service", evidence={
            "code": ["cmd/accounting-service", "accounting-service"],
            "run": ["step_183_run_accounting_service.sh"],
        }),
    ]),
    TaskNode("13", "ERP TURKIYE DERINLESME", children=[
        TaskNode("13.1.1", "Bilanço / gelir / mizan", evidence={
            "code": ["internal/finance", "internal/erp"],
            "run": ["step_run_bilanco_engine.sh", "step_run_gelir_tablosu_engine.sh", "step_run_mizan_engine.sh"],
        }),
        TaskNode("13.1.2", "Cari / kasa / banka ekstre", evidence={
            "run": ["step_run_cari_ekstre.sh", "step_run_kasa_ekstre.sh", "step_run_banka_ekstre.sh"],
            "code": ["internal/finance"],
        }),
        TaskNode("13.1.3", "Tahsilat / ödeme / settlement", evidence={
            "run": ["step_5_run_tahsilat_odeme_v2.sh", "step_6_run_settlement_engine.sh", "step_5_run_payment_engine.sh"],
            "code": ["internal/finance"],
        }),
        TaskNode("13.1.4", "Commission / payout / wallet", evidence={
            "run": ["step_2_run_commission_engine.sh", "step_7_run_merchant_payout_engine.sh", "step_6_run_wallet_transfer_engine.sh"],
            "code": ["internal/finance"],
        }),
    ]),
    TaskNode("14", "TEST / QUALITY GATE", children=[
        TaskNode("14.1.1", "Unit/integration test izi", evidence={
            "code": ["test/internal", "test/e2e", "coverage.out"],
            "test": ["step_405_test.sh", "step_419_build_test.sh", "step_420_build_test.sh"],
        }),
        TaskNode("14.1.2", "Prod smoke / ops suite", evidence={
            "run": ["scripts/prod_finance_smoke.sh", "scripts/prod_ops_suite.sh", "scripts/query_smoke_prod.sh"],
            "test": ["scripts/prod_e2e_user_created_check.sh", "scripts/prod_finance_post_restart_check.sh", "scripts/query_post_restart_check.sh"],
        }),
        TaskNode("14.1.3", "Guard / quality gates", evidence={
            "code": ["guard/import_guard.sh", "guard/pix2pi_guard.sh", "guard/quality_gates.env"],
            "test": ["scripts/test_ops_daily_alert_chain.sh"],
        }),
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
        flatten_non_done(r, open_items)

    open_items = sorted(open_items, key=lambda x: (x["status"], x["confidence"], x["code"]))

    payload = {
        "root": ROOT,
        "files_scanned": len(FILES),
        "overall_percent": overall_percent,
        "stats": all_stats,
        "results": results,
        "open_items": open_items,
    }

    with open(JSON_REPORT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    md = []
    md.append("# Pix2pi Master Progress Report v2")
    md.append("")
    md.append(f"- Scanned files: **{len(FILES)}**")
    md.append(f"- Overall progress: **%{overall_percent}**")
    md.append(f"- Done: **{all_stats['done']}**")
    md.append(f"- Partial: **{all_stats['partial']}**")
    md.append(f"- Todo: **{all_stats['todo']}**")
    md.append("")

    md.append("## Phase Summary")
    md.append("")
    for r in results:
        md.append(f"- {STATUS_ICON[r['status']]} **{r['code']} {r['title']}** → %{r['percent']} (confidence={r['confidence']})")
    md.append("")

    md.append("## Detailed Tree")
    md.append("")
    for r in results:
        md.append(md_node(r, level=2))
        md.append("")

    md.append("## Open Items")
    md.append("")
    for item in open_items:
        md.append(f"- {STATUS_ICON[item['status']]} **{item['code']} {item['title']}** (confidence={item['confidence']})")
        if item["missing"]:
            md.append("  - eksik:")
            for m in item["missing"]:
                md.append(f"    - {m}")
        for group in ["code", "test", "run", "config", "ops", "backup"]:
            vals = item["evidence"].get(group, [])
            if vals:
                md.append(f"  - {group}:")
                for v in vals[:2]:
                    md.append(f"    - `{v}`")

    with open(MD_REPORT, "w", encoding="utf-8") as f:
        f.write("\n".join(md))

    print("OK ✅ v2 audit tamam")
    print(f"Scanned files      : {len(FILES)}")
    print(f"Overall progress   : %{overall_percent}")
    print(f"Done               : {all_stats['done']}")
    print(f"Partial            : {all_stats['partial']}")
    print(f"Todo               : {all_stats['todo']}")
    print(f"JSON report        : {JSON_REPORT}")
    print(f"Markdown report    : {MD_REPORT}")

if __name__ == "__main__":
    main()
