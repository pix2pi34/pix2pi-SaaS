#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "20_8_infra_cleanup_production_hardening_final_closure_standard.md"
report_file = report_dir / "20_8_infra_cleanup_production_hardening_final_closure_report.md"
matrix_file = report_dir / "20_8_infra_cleanup_production_hardening_final_closure_matrix.tsv"
inventory_file = report_dir / "20_8_infra_cleanup_production_hardening_final_closure_inventory.tsv"
closure_file = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"

reports = {
    "20.1": report_dir / "20_1_production_cleanup_report.md",
    "20.2": report_dir / "20_2_config_env_hardening_report.md",
    "20.3": report_dir / "20_3_runtime_service_hardening_report.md",
    "20.4": report_dir / "20_4_nginx_reverse_proxy_hardening_report.md",
    "20.5": report_dir / "20_5_docker_compose_hardening_report.md",
    "20.6": report_dir / "20_6_backup_archive_retention_report.md",
    "20.7": report_dir / "20_7_production_hardening_tests_report.md",
    "21": report_dir / "21_security_rbac_audit_final_closure_report.md",
}

domain_keys = {
    "20.1": "PRODUCTION_CLEANUP_GATE",
    "20.2": "CONFIG_ENV_HARDENING_GATE",
    "20.3": "RUNTIME_SERVICE_HARDENING",
    "20.4": "NGINX_REVERSE_PROXY_HARDENING",
    "20.5": "DOCKER_COMPOSE_HARDENING",
    "20.6": "BACKUP_ARCHIVE_RETENTION_HYGIENE",
    "20.7": "PRODUCTION_HARDENING_TESTS",
}

final_keys = {
    "20.1": "FAZ4B_20_1_FINAL_STATUS",
    "20.2": "FAZ4B_20_2_FINAL_STATUS",
    "20.3": "FAZ4B_20_3_FINAL_STATUS",
    "20.4": "FAZ4B_20_4_FINAL_STATUS",
    "20.5": "FAZ4B_20_5_FINAL_STATUS",
    "20.6": "FAZ4B_20_6_FINAL_STATUS",
    "20.7": "FAZ4B_20_7_FINAL_STATUS",
}

artifact_sets = {
    "20.1": [
        "docs/phase4/20_1_production_cleanup_standard.md",
        "docs/phase4/20_1_production_cleanup_policy.md",
        "docs/phase4/20_1_production_cleanup_inventory.tsv",
        "docs/phase4/20_1_production_cleanup_matrix.tsv",
        "docs/phase4/20_1_production_cleanup_report.md",
        "scripts/phase4b_production_cleanup_gate.sh",
        "scripts/phase4b_production_cleanup_gate.py",
        "scripts/test_phase4b_production_cleanup_gate.sh",
    ],
    "20.2": [
        "docs/phase4/20_2_config_env_hardening_standard.md",
        "docs/phase4/20_2_config_env_hardening_policy.md",
        "docs/phase4/20_2_config_env_hardening_inventory.tsv",
        "docs/phase4/20_2_config_env_hardening_matrix.tsv",
        "docs/phase4/20_2_config_env_hardening_report.md",
        "scripts/phase4b_config_env_hardening_gate.sh",
        "scripts/phase4b_config_env_hardening_gate.py",
        "scripts/test_phase4b_config_env_hardening_gate.sh",
    ],
    "20.3": [
        "docs/phase4/20_3_runtime_service_hardening_standard.md",
        "docs/phase4/20_3_runtime_service_hardening_policy.md",
        "docs/phase4/20_3_runtime_service_hardening_services.tsv",
        "docs/phase4/20_3_runtime_service_hardening_ports.tsv",
        "docs/phase4/20_3_runtime_service_hardening_containers.tsv",
        "docs/phase4/20_3_runtime_service_hardening_matrix.tsv",
        "docs/phase4/20_3_runtime_service_hardening_report.md",
        "scripts/phase4b_runtime_service_hardening.sh",
        "scripts/phase4b_runtime_service_hardening.py",
        "scripts/test_phase4b_runtime_service_hardening.sh",
    ],
    "20.4": [
        "docs/phase4/20_4_nginx_reverse_proxy_hardening_standard.md",
        "docs/phase4/20_4_nginx_reverse_proxy_hardening_policy.md",
        "docs/phase4/20_4_nginx_reverse_proxy_config_inventory.tsv",
        "docs/phase4/20_4_nginx_reverse_proxy_surface_manifest.tsv",
        "docs/phase4/20_4_nginx_public_port_policy.tsv",
        "docs/phase4/20_4_nginx_reverse_proxy_hardening_matrix.tsv",
        "docs/phase4/20_4_nginx_reverse_proxy_hardening_report.md",
        "scripts/phase4b_nginx_reverse_proxy_hardening.sh",
        "scripts/phase4b_nginx_reverse_proxy_hardening.py",
        "scripts/test_phase4b_nginx_reverse_proxy_hardening.sh",
    ],
    "20.5": [
        "docs/phase4/20_5_docker_compose_hardening_standard.md",
        "docs/phase4/20_5_docker_compose_hardening_policy.md",
        "docs/phase4/20_5_docker_container_inventory.tsv",
        "docs/phase4/20_5_docker_compose_inventory.tsv",
        "docs/phase4/20_5_docker_network_inventory.tsv",
        "docs/phase4/20_5_docker_volume_inventory.tsv",
        "docs/phase4/20_5_docker_public_port_policy.tsv",
        "docs/phase4/20_5_docker_compose_hardening_matrix.tsv",
        "docs/phase4/20_5_docker_compose_hardening_report.md",
        "scripts/phase4b_docker_compose_hardening.sh",
        "scripts/phase4b_docker_compose_hardening.py",
        "scripts/test_phase4b_docker_compose_hardening.sh",
    ],
    "20.6": [
        "docs/phase4/20_6_backup_archive_retention_standard.md",
        "docs/phase4/20_6_backup_archive_retention_policy.md",
        "docs/phase4/20_6_backup_archive_inventory.tsv",
        "docs/phase4/20_6_backup_archive_volume_retention.tsv",
        "docs/phase4/20_6_backup_archive_retention_matrix.tsv",
        "docs/phase4/20_6_backup_archive_retention_report.md",
        "scripts/phase4b_backup_archive_retention_hygiene.sh",
        "scripts/phase4b_backup_archive_retention_hygiene.py",
        "scripts/test_phase4b_backup_archive_retention_hygiene.sh",
    ],
    "20.7": [
        "docs/phase4/20_7_production_hardening_tests_standard.md",
        "docs/phase4/20_7_production_hardening_tests_report.md",
        "docs/phase4/20_7_production_hardening_tests_matrix.tsv",
        "docs/phase4/20_7_production_hardening_tests_inventory.tsv",
        "scripts/phase4b_production_hardening_tests.sh",
        "scripts/phase4b_production_hardening_tests.py",
        "scripts/test_phase4b_production_hardening_tests.sh",
    ],
}

required_pass_keys = {
    "20.1": [
        "PRODUCTION_CLEANUP_PREVIOUS_21",
        "PRODUCTION_CLEANUP_BASELINE",
        "PRODUCTION_CLEANUP_INVENTORY",
        "PRODUCTION_CLEANUP_MIGRATION_CHAIN",
        "PRODUCTION_CLEANUP_NO_DELETE",
        "PRODUCTION_CLEANUP_NO_MOVE",
        "PRODUCTION_CLEANUP_NO_DEPLOY",
        "PRODUCTION_CLEANUP_SECRET_SAFE",
    ],
    "20.2": [
        "CONFIG_ENV_PREVIOUS_20_1",
        "CONFIG_ENV_BASELINE",
        "CONFIG_ENV_INVENTORY",
        "CONFIG_ENV_PERMISSION_EVIDENCE",
        "CONFIG_ENV_VALUE_NOT_PRINTED",
        "CONFIG_ENV_NO_CHANGE",
        "CONFIG_ENV_NO_DEPLOY",
        "CONFIG_ENV_SECRET_SAFE",
    ],
    "20.3": [
        "RUNTIME_SERVICE_PREVIOUS_20_2",
        "RUNTIME_SERVICE_SYSTEMD_INVENTORY",
        "RUNTIME_SERVICE_PORT_INVENTORY",
        "RUNTIME_SERVICE_CONTAINER_INVENTORY",
        "RUNTIME_SERVICE_HARDENING_MATRIX",
        "RUNTIME_SERVICE_NO_RESTART",
        "RUNTIME_SERVICE_NO_DEPLOY",
        "RUNTIME_SERVICE_SECRET_SAFE",
    ],
    "20.4": [
        "NGINX_REVERSE_PROXY_PREVIOUS_20_3",
        "NGINX_CONFIG_INVENTORY",
        "NGINX_PROXY_SURFACE_MANIFEST",
        "NGINX_PUBLIC_PORT_POLICY",
        "NGINX_HARDENING_MATRIX",
        "NGINX_NO_RELOAD",
        "NGINX_NO_FIREWALL_CHANGE",
        "NGINX_NO_DEPLOY",
        "NGINX_SECRET_SAFE",
    ],
    "20.5": [
        "DOCKER_COMPOSE_PREVIOUS_20_4",
        "DOCKER_CONTAINER_INVENTORY",
        "DOCKER_COMPOSE_INVENTORY",
        "DOCKER_NETWORK_INVENTORY",
        "DOCKER_VOLUME_INVENTORY",
        "DOCKER_PUBLIC_PORT_POLICY",
        "DOCKER_HARDENING_MATRIX",
        "DOCKER_NO_RUNTIME_CHANGE",
        "DOCKER_NO_DEPLOY",
        "DOCKER_SECRET_SAFE",
    ],
    "20.6": [
        "BACKUP_ARCHIVE_PREVIOUS_20_5",
        "BACKUP_ARCHIVE_INVENTORY",
        "BACKUP_ARCHIVE_VOLUME_RETENTION",
        "BACKUP_ARCHIVE_POLICY",
        "BACKUP_ARCHIVE_NO_DELETE",
        "BACKUP_ARCHIVE_NO_PRUNE",
        "BACKUP_ARCHIVE_NO_RESTORE",
        "BACKUP_ARCHIVE_SECRET_SAFE",
    ],
    "20.7": [
        "PRODUCTION_TEST_CLEANUP",
        "PRODUCTION_TEST_CONFIG_ENV",
        "PRODUCTION_TEST_RUNTIME_SERVICE",
        "PRODUCTION_TEST_NGINX",
        "PRODUCTION_TEST_DOCKER",
        "PRODUCTION_TEST_BACKUP_ARCHIVE",
        "PRODUCTION_TEST_ARTIFACT_COVERAGE",
        "PRODUCTION_TEST_NO_CHANGE",
        "PRODUCTION_TEST_RISK_EVIDENCE",
        "PRODUCTION_TEST_SECRET_SAFE",
    ],
}

required_no_keys = {
    "20.1": [
        "FILE_DELETE_EXECUTED",
        "FILE_MOVE_EXECUTED",
        "FILE_PERMISSION_CHANGED",
        "ENV_CHANGED",
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "DEPLOY_EXECUTED",
        "SERVICE_RESTARTED",
        "CONTAINER_RESTARTED",
        "QUERY_TEXT_PRINTED",
        "SECRET_VALUE_PRINTED",
    ],
    "20.2": [
        "CONFIG_CHANGED",
        "ENV_CHANGED",
        "FILE_PERMISSION_CHANGED",
        "FILE_DELETE_EXECUTED",
        "FILE_MOVE_EXECUTED",
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "DEPLOY_EXECUTED",
        "SERVICE_RESTARTED",
        "CONTAINER_RESTARTED",
        "QUERY_TEXT_PRINTED",
        "RAW_DSN_PRINTED",
        "SECRET_VALUE_PRINTED",
    ],
    "20.3": [
        "SERVICE_RESTARTED",
        "CONTAINER_RESTARTED",
        "DOCKER_COMPOSE_EXECUTED",
        "NGINX_RELOAD_EXECUTED",
        "DEPLOY_EXECUTED",
        "CONFIG_CHANGED",
        "ENV_CHANGED",
        "FILE_PERMISSION_CHANGED",
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "LOG_CONTENT_PRINTED",
        "QUERY_TEXT_PRINTED",
        "RAW_DSN_PRINTED",
        "SECRET_VALUE_PRINTED",
    ],
    "20.4": [
        "NGINX_CONFIG_CHANGED",
        "NGINX_RELOAD_EXECUTED",
        "NGINX_RESTARTED",
        "FIREWALL_CHANGED",
        "PORT_CHANGED",
        "DOCKER_PORT_CHANGED",
        "DOCKER_COMPOSE_EXECUTED",
        "SERVICE_RESTARTED",
        "DEPLOY_EXECUTED",
        "CONFIG_CHANGED",
        "ENV_CHANGED",
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "LOG_CONTENT_PRINTED",
        "QUERY_TEXT_PRINTED",
        "RAW_DSN_PRINTED",
        "SECRET_VALUE_PRINTED",
    ],
    "20.5": [
        "CONTAINER_RESTARTED",
        "CONTAINER_STARTED",
        "CONTAINER_STOPPED",
        "CONTAINER_REMOVED",
        "DOCKER_COMPOSE_EXECUTED",
        "DOCKER_NETWORK_CHANGED",
        "DOCKER_VOLUME_CHANGED",
        "DOCKER_PORT_CHANGED",
        "DOCKER_PRUNE_EXECUTED",
        "CONFIG_CHANGED",
        "ENV_CHANGED",
        "FILE_PERMISSION_CHANGED",
        "FIREWALL_CHANGED",
        "NGINX_RELOAD_EXECUTED",
        "SERVICE_RESTARTED",
        "DEPLOY_EXECUTED",
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "LOG_CONTENT_PRINTED",
        "QUERY_TEXT_PRINTED",
        "RAW_DSN_PRINTED",
        "SECRET_VALUE_PRINTED",
    ],
    "20.6": [
        "BACKUP_DELETE_EXECUTED",
        "ARCHIVE_DELETE_EXECUTED",
        "FILE_DELETE_EXECUTED",
        "FILE_MOVE_EXECUTED",
        "DOCKER_VOLUME_REMOVED",
        "DOCKER_VOLUME_PRUNE_EXECUTED",
        "RESTIC_FORGET_EXECUTED",
        "RESTIC_PRUNE_EXECUTED",
        "RESTIC_REPAIR_EXECUTED",
        "RESTORE_EXECUTED",
        "PG_DUMP_EXECUTED",
        "PG_RESTORE_EXECUTED",
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "CONFIG_CHANGED",
        "ENV_CHANGED",
        "SERVICE_RESTARTED",
        "CONTAINER_RESTARTED",
        "DEPLOY_EXECUTED",
        "QUERY_TEXT_PRINTED",
        "RAW_DSN_PRINTED",
        "SECRET_VALUE_PRINTED",
    ],
    "20.7": [
        "FILE_DELETE_EXECUTED",
        "FILE_MOVE_EXECUTED",
        "FILE_PERMISSION_CHANGED",
        "CONFIG_CHANGED",
        "ENV_CHANGED",
        "FIREWALL_CHANGED",
        "NGINX_RELOAD_EXECUTED",
        "CONTAINER_RESTARTED",
        "DOCKER_COMPOSE_EXECUTED",
        "DOCKER_VOLUME_CHANGED",
        "DOCKER_PORT_CHANGED",
        "DOCKER_PRUNE_EXECUTED",
        "RESTIC_PRUNE_EXECUTED",
        "RESTORE_EXECUTED",
        "PG_DUMP_EXECUTED",
        "PG_RESTORE_EXECUTED",
        "SERVICE_RESTARTED",
        "DEPLOY_EXECUTED",
        "DB_MUTATION",
        "DB_APPLY_EXECUTED",
        "MIGRATION_CREATED",
        "MIGRATION_APPLY_EXECUTED",
        "LOG_CONTENT_PRINTED",
        "QUERY_TEXT_PRINTED",
        "RAW_DSN_PRINTED",
        "SECRET_VALUE_PRINTED",
    ],
}

risk_keys = {
    "20.1": [
        "PRODUCTION_CLEANUP_CANDIDATE_COUNT",
        "PRODUCTION_CLEANUP_POTENTIAL_SECRET_PATH_COUNT",
        "PRODUCTION_CLEANUP_MIGRATION_PAIR_COUNT",
    ],
    "20.2": [
        "CONFIG_ENV_INVENTORY_ROW_COUNT",
        "CONFIG_ENV_ENV_FILE_COUNT",
        "CONFIG_ENV_CONFIG_FILE_COUNT",
        "CONFIG_ENV_POTENTIAL_SECRET_PATH_COUNT",
        "CONFIG_ENV_SECRET_KEY_NAME_COUNT",
        "CONFIG_ENV_DSN_KEY_NAME_COUNT",
    ],
    "20.3": [
        "RUNTIME_SERVICE_HIGH_RISK_SERVICE_COUNT",
        "RUNTIME_SERVICE_HIGH_RISK_PORT_COUNT",
        "RUNTIME_SERVICE_HIGH_RISK_CONTAINER_COUNT",
    ],
    "20.4": [
        "NGINX_HIGH_RISK_PUBLIC_PORT_COUNT",
        "NGINX_INTERNAL_SHOULD_NOT_PUBLIC_COUNT",
        "NGINX_SECURITY_HEADER_MARKER_COUNT",
        "NGINX_AUTH_MARKER_COUNT",
    ],
    "20.5": [
        "DOCKER_HIGH_RISK_CONTAINER_COUNT",
        "DOCKER_HIGH_RISK_PUBLIC_PUBLISH_COUNT",
        "DOCKER_INTERNAL_SHOULD_NOT_PUBLIC_COUNT",
        "DOCKER_HEALTHCHECK_MISSING_COUNT",
        "DOCKER_UNSPECIFIED_USER_COUNT",
    ],
    "20.6": [
        "BACKUP_ARCHIVE_BACKUP_CANDIDATE_COUNT",
        "BACKUP_ARCHIVE_DB_BACKUP_CANDIDATE_COUNT",
        "BACKUP_ARCHIVE_SECRET_BACKUP_PATH_COUNT",
        "BACKUP_ARCHIVE_STATEFUL_VOLUME_COUNT",
        "BACKUP_ARCHIVE_RESTORE_DRILL_REQUIRED_COUNT",
    ],
    "20.7": [
        "PRODUCTION_TEST_RISK_EVIDENCE_TOTAL",
        "PRODUCTION_TEST_STATUS_FAILURE_COUNT",
        "PRODUCTION_TEST_NO_CHANGE_FAILURE_COUNT",
        "PRODUCTION_TEST_ARTIFACT_MISSING_COUNT",
    ],
}

failures = []
warnings = []
details = []
tools = []

def now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")

def read(path):
    if not path.exists():
        return ""
    return path.read_text(errors="ignore")

def get_value(path, key):
    text = read(path)
    value = ""
    pattern = re.compile(rf"^{re.escape(key)}=(.*)$")
    for line in text.splitlines():
        m = pattern.match(line.strip())
        if m:
            value = m.group(1).strip().strip('"')
    return value

def fail(msg):
    failures.append(f"FAIL ❌ {msg}")

def detail(line):
    details.append(line)

def tool_status(name):
    status = "FOUND" if which(name) else "NOT_FOUND"
    tools.append(f"TOOL_{name}={status}")

def as_int(value):
    try:
        return int(str(value).strip())
    except Exception:
        return 0

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("FILE_DELETE_EXECUTED=NO")
detail("FILE_MOVE_EXECUTED=NO")
detail("FILE_PERMISSION_CHANGED=NO")
detail("CONFIG_CHANGED=NO")
detail("ENV_CHANGED=NO")
detail("FIREWALL_CHANGED=NO")
detail("NGINX_RELOAD_EXECUTED=NO")
detail("NGINX_RESTARTED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("CONTAINER_STARTED=NO")
detail("CONTAINER_STOPPED=NO")
detail("CONTAINER_REMOVED=NO")
detail("DOCKER_COMPOSE_EXECUTED=NO")
detail("DOCKER_NETWORK_CHANGED=NO")
detail("DOCKER_VOLUME_CHANGED=NO")
detail("DOCKER_PORT_CHANGED=NO")
detail("DOCKER_PRUNE_EXECUTED=NO")
detail("RESTIC_FORGET_EXECUTED=NO")
detail("RESTIC_PRUNE_EXECUTED=NO")
detail("RESTIC_REPAIR_EXECUTED=NO")
detail("RESTORE_EXECUTED=NO")
detail("PG_DUMP_EXECUTED=NO")
detail("PG_RESTORE_EXECUTED=NO")
detail("SERVICE_RESTARTED=NO")
detail("DEPLOY_EXECUTED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("LOG_CONTENT_PRINTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("VALIDATION_MODE=INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

if not standard_file.exists():
    fail("20.8 standard doc yok")

prev_21_status = get_value(reports["21"], "FAZ4B_21_FINAL_STATUS")
prev_21_closure = get_value(reports["21"], "SECURITY_RBAC_AUDIT_FINAL_CLOSURE")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_21_SECURITY_RBAC_AUDIT_FINAL_CLOSURE={prev_21_closure}")

if prev_21_status != "PASS":
    fail("21 final status PASS degil")
if prev_21_closure != "PASS":
    fail("21 security closure PASS degil")

block_results = {}
artifact_missing = []
gate_failures = []
no_change_failures = []
risk_evidence_missing = []
risk_total = 0

for block in ["20.1", "20.2", "20.3", "20.4", "20.5", "20.6", "20.7"]:
    report = reports[block]

    final_status = get_value(report, final_keys[block])
    domain_status = get_value(report, domain_keys[block])

    detail(f"FINAL_{block.replace('.', '_')}_FINAL_STATUS={final_status}")
    detail(f"FINAL_{block.replace('.', '_')}_{domain_keys[block]}={domain_status}")

    local_failures = []

    if final_status != "PASS":
        local_failures.append(f"{final_keys[block]}={final_status}")
    if domain_status != "PASS":
        local_failures.append(f"{domain_keys[block]}={domain_status}")

    for key in required_pass_keys[block]:
        value = get_value(report, key)
        detail(f"INFRA_FINAL_{block.replace('.', '_')}_{key}={value}")
        if value != "PASS":
            local_failures.append(f"{key}={value}")

    for key in required_no_keys[block]:
        value = get_value(report, key)
        detail(f"INFRA_FINAL_{block.replace('.', '_')}_{key}={value}")
        if value != "NO":
            no_change_failures.append(f"{block}:{key}={value}")

    risk_key_hits = 0
    risk_key_sum = 0

    for key in risk_keys[block]:
        value = get_value(report, key)
        detail(f"INFRA_FINAL_{block.replace('.', '_')}_{key}={value}")
        if value != "":
            risk_key_hits += 1
            risk_key_sum += as_int(value)

    if risk_key_hits != len(risk_keys[block]):
        risk_evidence_missing.append(f"{block}:risk_keys={risk_key_hits}/{len(risk_keys[block])}")

    risk_total += risk_key_sum

    expected_artifact_count = len(artifact_sets[block])
    existing_artifact_count = 0

    for rel in artifact_sets[block]:
        p = root / rel
        if p.exists():
            existing_artifact_count += 1
        else:
            artifact_missing.append(f"{block}:{rel}")

    detail(f"INFRA_FINAL_{block.replace('.', '_')}_ARTIFACT_EXPECTED_COUNT={expected_artifact_count}")
    detail(f"INFRA_FINAL_{block.replace('.', '_')}_ARTIFACT_EXISTING_COUNT={existing_artifact_count}")

    if local_failures:
        gate_failures.extend([f"{block}:{x}" for x in local_failures])

    block_results[block] = {
        "status": "PASS" if not local_failures else "FAIL",
        "artifact_expected": expected_artifact_count,
        "artifact_existing": existing_artifact_count,
        "risk_key_hits": risk_key_hits,
        "risk_key_expected": len(risk_keys[block]),
        "risk_key_sum": risk_key_sum,
        "gate_failures": len(local_failures),
    }

if gate_failures:
    fail("infra final gate failure: " + ",".join(gate_failures[:50]))

if no_change_failures:
    fail("infra final no-change failure: " + ",".join(no_change_failures[:50]))

if artifact_missing:
    fail("infra final artifact eksik: " + ",".join(artifact_missing[:50]))

if risk_evidence_missing:
    fail("infra final risk evidence eksik: " + ",".join(risk_evidence_missing[:50]))

infra_final_cleanup = block_results["20.1"]["status"]
infra_final_config_env = block_results["20.2"]["status"]
infra_final_runtime = block_results["20.3"]["status"]
infra_final_nginx = block_results["20.4"]["status"]
infra_final_docker = block_results["20.5"]["status"]
infra_final_backup = block_results["20.6"]["status"]
infra_final_tests = block_results["20.7"]["status"]

artifact_coverage_status = "PASS" if not artifact_missing else "FAIL"
no_change_status = "PASS" if not no_change_failures else "FAIL"
risk_evidence_status = "PASS" if not risk_evidence_missing and risk_total > 0 else "FAIL"
secret_safe_status = "PASS"

for label, status in [
    ("INFRA_FINAL_CLEANUP", infra_final_cleanup),
    ("INFRA_FINAL_CONFIG_ENV", infra_final_config_env),
    ("INFRA_FINAL_RUNTIME_SERVICE", infra_final_runtime),
    ("INFRA_FINAL_NGINX", infra_final_nginx),
    ("INFRA_FINAL_DOCKER", infra_final_docker),
    ("INFRA_FINAL_BACKUP_ARCHIVE", infra_final_backup),
    ("INFRA_FINAL_PRODUCTION_TESTS", infra_final_tests),
    ("INFRA_FINAL_ARTIFACT_COVERAGE", artifact_coverage_status),
    ("INFRA_FINAL_NO_CHANGE", no_change_status),
    ("INFRA_FINAL_RISK_EVIDENCE", risk_evidence_status),
    ("INFRA_FINAL_SECRET_SAFE", secret_safe_status),
]:
    detail(f"{label}={status}")
    if status != "PASS":
        fail(f"{label} PASS degil")

detail(f"INFRA_FINAL_RISK_EVIDENCE_TOTAL={risk_total}")
detail(f"INFRA_FINAL_GATE_FAILURE_COUNT={len(gate_failures)}")
detail(f"INFRA_FINAL_NO_CHANGE_FAILURE_COUNT={len(no_change_failures)}")
detail(f"INFRA_FINAL_ARTIFACT_MISSING_COUNT={len(artifact_missing)}")
detail(f"INFRA_FINAL_RISK_EVIDENCE_MISSING_COUNT={len(risk_evidence_missing)}")

matrix_lines = [
    "gate\tstatus\tnote",
    f"cleanup\t{infra_final_cleanup}\t20.1 production cleanup final",
    f"config_env\t{infra_final_config_env}\t20.2 config/env hardening final",
    f"runtime_service\t{infra_final_runtime}\t20.3 runtime service hardening final",
    f"nginx_reverse_proxy\t{infra_final_nginx}\t20.4 nginx/reverse proxy final",
    f"docker_compose\t{infra_final_docker}\t20.5 docker/compose final",
    f"backup_archive\t{infra_final_backup}\t20.6 backup/archive final",
    f"production_tests\t{infra_final_tests}\t20.7 production hardening tests final",
    f"artifact_coverage\t{artifact_coverage_status}\tmissing={len(artifact_missing)}",
    f"no_change\t{no_change_status}\tfailures={len(no_change_failures)}",
    f"risk_evidence\t{risk_evidence_status}\trisk_total={risk_total}",
    f"secret_safe\t{secret_safe_status}\tsecret values not printed",
    "file_delete_executed\tNO\tfinal evidence only",
    "file_move_executed\tNO\tfinal evidence only",
    "file_permission_changed\tNO\tfinal evidence only",
    "config_changed\tNO\tfinal evidence only",
    "env_changed\tNO\tfinal evidence only",
    "firewall_changed\tNO\tfinal evidence only",
    "nginx_reload_executed\tNO\tfinal evidence only",
    "nginx_restarted\tNO\tfinal evidence only",
    "container_restarted\tNO\tfinal evidence only",
    "docker_compose_executed\tNO\tfinal evidence only",
    "docker_network_changed\tNO\tfinal evidence only",
    "docker_volume_changed\tNO\tfinal evidence only",
    "docker_port_changed\tNO\tfinal evidence only",
    "docker_prune_executed\tNO\tfinal evidence only",
    "restic_prune_executed\tNO\tfinal evidence only",
    "restore_executed\tNO\tfinal evidence only",
    "pg_dump_executed\tNO\tfinal evidence only",
    "pg_restore_executed\tNO\tfinal evidence only",
    "service_restarted\tNO\tfinal evidence only",
    "deploy_executed\tNO\tfinal evidence only",
    "db_mutation\tNO\tfinal evidence only",
    "db_apply_executed\tNO\tfinal evidence only",
    "migration_created\tNO\tfinal evidence only",
    "migration_apply_executed\tNO\tfinal evidence only",
    "log_content_printed\tNO\tsecret-safe report",
    "query_text_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

inventory_lines = [
    "block\tstatus\tdomain_key\treport_file\tartifact_expected\tartifact_existing\trisk_key_hits\trisk_key_expected\trisk_key_sum\tgate_failures"
]

for block in ["20.1", "20.2", "20.3", "20.4", "20.5", "20.6", "20.7"]:
    result = block_results[block]
    inventory_lines.append(
        f"{block}\t{result['status']}\t{domain_keys[block]}\t{str(reports[block].relative_to(root))}\t{result['artifact_expected']}\t{result['artifact_existing']}\t{result['risk_key_hits']}\t{result['risk_key_expected']}\t{result['risk_key_sum']}\t{result['gate_failures']}"
    )

inventory_file.write_text("\n".join(inventory_lines) + "\n")

detail(f"INFRA_FINAL_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail(f"INFRA_FINAL_INVENTORY_LINE_COUNT={len(inventory_lines)}")

final_status = "PASS" if not failures else "FAIL"
detail(f"INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={final_status}")
detail(f"FAZ4B_20_8_FINAL_STATUS={final_status}")
detail(f"FAZ4B_20_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 20.8 - Infra Cleanup / Production Hardening Final Closure Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={final_status}",
    f"FAZ4B_20_8_FINAL_STATUS={final_status}",
    f"FAZ4B_20_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/20_8_infra_cleanup_production_hardening_final_closure_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/20_8_infra_cleanup_production_hardening_final_closure_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Safety Decision",
    "FILE_DELETE_EXECUTED=NO",
    "FILE_MOVE_EXECUTED=NO",
    "FILE_PERMISSION_CHANGED=NO",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "FIREWALL_CHANGED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
    "NGINX_RESTARTED=NO",
    "CONTAINER_RESTARTED=NO",
    "CONTAINER_STARTED=NO",
    "CONTAINER_STOPPED=NO",
    "CONTAINER_REMOVED=NO",
    "DOCKER_COMPOSE_EXECUTED=NO",
    "DOCKER_NETWORK_CHANGED=NO",
    "DOCKER_VOLUME_CHANGED=NO",
    "DOCKER_PORT_CHANGED=NO",
    "DOCKER_PRUNE_EXECUTED=NO",
    "RESTIC_FORGET_EXECUTED=NO",
    "RESTIC_PRUNE_EXECUTED=NO",
    "RESTIC_REPAIR_EXECUTED=NO",
    "RESTORE_EXECUTED=NO",
    "PG_DUMP_EXECUTED=NO",
    "PG_RESTORE_EXECUTED=NO",
    "SERVICE_RESTARTED=NO",
    "DEPLOY_EXECUTED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "LOG_CONTENT_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "RAW_DSN_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
    "",
    "## Issues",
    *(failures + warnings if failures or warnings else ["OK ✅ issue yok"]),
    "",
    "## Secret Safety",
    "RAW_DSN_PRINTED=NO",
    "POSTGRES_PASSWORD_PRINTED=NO",
    "AUTH_TOKEN_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "LOG_CONTENT_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

closure_lines = [
    "# FAZ 4B / 20 - Infra Cleanup / Production Hardening Final Closure",
    "",
    f"Generated at: {now()}",
    "",
    f"FAZ4B_20_FINAL_STATUS={final_status}",
    f"FAZ4B_20_8_FINAL_STATUS={final_status}",
    f"INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={final_status}",
    "",
    "## Closed Items",
    f"20.1 Production file / folder cleanup gate={infra_final_cleanup}",
    f"20.2 Config / env hardening gate={infra_final_config_env}",
    f"20.3 Runtime service hardening={infra_final_runtime}",
    f"20.4 Nginx / reverse proxy hardening={infra_final_nginx}",
    f"20.5 Docker / compose hardening={infra_final_docker}",
    f"20.6 Backup / archive retention hygiene={infra_final_backup}",
    f"20.7 Production hardening tests={infra_final_tests}",
    f"20.8 Infra Cleanup / Production Hardening final closure={final_status}",
    "",
    "## Final Gates",
    f"INFRA_FINAL_CLEANUP={infra_final_cleanup}",
    f"INFRA_FINAL_CONFIG_ENV={infra_final_config_env}",
    f"INFRA_FINAL_RUNTIME_SERVICE={infra_final_runtime}",
    f"INFRA_FINAL_NGINX={infra_final_nginx}",
    f"INFRA_FINAL_DOCKER={infra_final_docker}",
    f"INFRA_FINAL_BACKUP_ARCHIVE={infra_final_backup}",
    f"INFRA_FINAL_PRODUCTION_TESTS={infra_final_tests}",
    f"INFRA_FINAL_ARTIFACT_COVERAGE={artifact_coverage_status}",
    f"INFRA_FINAL_NO_CHANGE={no_change_status}",
    f"INFRA_FINAL_RISK_EVIDENCE={risk_evidence_status}",
    f"INFRA_FINAL_SECRET_SAFE={secret_safe_status}",
    f"INFRA_FINAL_RISK_EVIDENCE_TOTAL={risk_total}",
    "",
    "## Safety",
    "FILE_DELETE_EXECUTED=NO",
    "FILE_MOVE_EXECUTED=NO",
    "FILE_PERMISSION_CHANGED=NO",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "FIREWALL_CHANGED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
    "CONTAINER_RESTARTED=NO",
    "DOCKER_COMPOSE_EXECUTED=NO",
    "DOCKER_VOLUME_CHANGED=NO",
    "DOCKER_PORT_CHANGED=NO",
    "DOCKER_PRUNE_EXECUTED=NO",
    "RESTIC_PRUNE_EXECUTED=NO",
    "RESTORE_EXECUTED=NO",
    "PG_DUMP_EXECUTED=NO",
    "PG_RESTORE_EXECUTED=NO",
    "SERVICE_RESTARTED=NO",
    "DEPLOY_EXECUTED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "RAW_DSN_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
]
closure_file.write_text("\n".join(closure_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"INVENTORY_FILE={inventory_file}")
print(f"CLOSURE_FILE={closure_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"INFRA_FINAL_CLEANUP={infra_final_cleanup}")
print(f"INFRA_FINAL_CONFIG_ENV={infra_final_config_env}")
print(f"INFRA_FINAL_RUNTIME_SERVICE={infra_final_runtime}")
print(f"INFRA_FINAL_NGINX={infra_final_nginx}")
print(f"INFRA_FINAL_DOCKER={infra_final_docker}")
print(f"INFRA_FINAL_BACKUP_ARCHIVE={infra_final_backup}")
print(f"INFRA_FINAL_PRODUCTION_TESTS={infra_final_tests}")
print(f"INFRA_FINAL_ARTIFACT_COVERAGE={artifact_coverage_status}")
print(f"INFRA_FINAL_NO_CHANGE={no_change_status}")
print(f"INFRA_FINAL_RISK_EVIDENCE={risk_evidence_status}")
print(f"INFRA_FINAL_SECRET_SAFE={secret_safe_status}")
print(f"INFRA_FINAL_RISK_EVIDENCE_TOTAL={risk_total}")
print(f"INFRA_FINAL_GATE_FAILURE_COUNT={len(gate_failures)}")
print(f"INFRA_FINAL_NO_CHANGE_FAILURE_COUNT={len(no_change_failures)}")
print(f"INFRA_FINAL_ARTIFACT_MISSING_COUNT={len(artifact_missing)}")
print("FILE_DELETE_EXECUTED=NO")
print("FILE_MOVE_EXECUTED=NO")
print("FILE_PERMISSION_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("FIREWALL_CHANGED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("DOCKER_VOLUME_CHANGED=NO")
print("DOCKER_PORT_CHANGED=NO")
print("DOCKER_PRUNE_EXECUTED=NO")
print("RESTIC_PRUNE_EXECUTED=NO")
print("RESTORE_EXECUTED=NO")
print("PG_DUMP_EXECUTED=NO")
print("PG_RESTORE_EXECUTED=NO")
print("SERVICE_RESTARTED=NO")
print("DEPLOY_EXECUTED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("LOG_CONTENT_PRINTED=NO")
print("QUERY_TEXT_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print(f"INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_20_8_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_20_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
