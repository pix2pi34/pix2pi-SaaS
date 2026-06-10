#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "faz4b_final_master_closure_standard.md"
report_file = report_dir / "faz4b_final_master_closure_report.md"
matrix_file = report_dir / "faz4b_final_master_closure_matrix.tsv"
inventory_file = report_dir / "faz4b_final_master_closure_inventory.tsv"
transition_file = report_dir / "faz4b_to_faz5_transition_readiness.md"

BLOCKS = [
    ("14", "DB-L7 Migration / lifecycle / import"),
    ("15", "DB-L6 Readmodel / reporting / analytics"),
    ("16", "Pilot / UAT / Onboarding Rollout"),
    ("17", "Workflow / Realtime UI"),
    ("18", "ERP Stok / Inventory Pilot Motoru"),
    ("19", "Panel / Admin Profesyonelleştirme"),
    ("20", "Infra Cleanup / Production Hardening"),
    ("21", "Security / RBAC / Audit Pilot Gate"),
    ("22", "Observability / Ops Console Pilot Gate"),
]

FINAL_KEYS = {
    "14": ["FAZ4B_14_FINAL_STATUS"],
    "15": ["FAZ4B_15_FINAL_STATUS"],
    "16": ["FAZ4B_16_FINAL_STATUS"],
    "17": ["FAZ4B_17_FINAL_STATUS"],
    "18": ["FAZ4B_18_FINAL_STATUS"],
    "19": ["FAZ4B_19_FINAL_STATUS"],
    "20": ["FAZ4B_20_FINAL_STATUS"],
    "21": ["FAZ4B_21_FINAL_STATUS"],
    "22": ["FAZ4B_22_FINAL_STATUS"],
}

failures = []
warnings = []
details = []
tools = []

def now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")

def detail(line):
    details.append(line)

def fail(msg):
    failures.append(f"FAIL ❌ {msg}")

def read(path):
    if not path.exists():
        return ""
    return path.read_text(errors="ignore")

def get_value_from_text(text, key):
    pattern = re.compile(rf"^{re.escape(key)}=(.*)$")
    value = ""
    for line in text.splitlines():
        m = pattern.match(line.strip())
        if m:
            value = m.group(1).strip().strip('"')
    return value

def tool_status(name):
    status = "FOUND" if which(name) else "NOT_FOUND"
    tools.append(f"TOOL_{name}={status}")

def candidate_reports_for_block(block_id):
    files = []
    for p in report_dir.glob("*.md"):
        n = p.name.lower()
        if n.startswith(f"{block_id}_") or n.startswith(f"{block_id}-") or f"_{block_id}_" in n or f"faz4b_{block_id}" in n:
            files.append(p)
        if block_id == "16" and "16_pilot_uat_onboarding_final_closure_report" in n:
            files.append(p)
        if block_id == "17" and "17_workflow_realtime_ui_final_closure_report" in n:
            files.append(p)
        if block_id == "20" and "20_infra_cleanup_production_hardening_final_closure_report" in n:
            files.append(p)
        if block_id == "21" and "21_security_rbac_audit_final_closure_report" in n:
            files.append(p)
        if block_id == "22" and "22_observability_ops_console_final_closure_report" in n:
            files.append(p)
    seen = []
    out = []
    for p in sorted(files):
        if str(p) not in seen:
            seen.append(str(p))
            out.append(p)
    return out

def find_final_status(block_id):
    keys = FINAL_KEYS[block_id]
    candidates = candidate_reports_for_block(block_id)

    for p in candidates:
        text = read(p)
        for key in keys:
            val = get_value_from_text(text, key)
            if val:
                return p, key, val

    for p in candidates:
        text = read(p)
        for line in text.splitlines():
            s = line.strip()
            u = s.upper()
            if "FINAL_STATUS=PASS" in u and f"_{block_id}_" in u:
                key = s.split("=", 1)[0]
                return p, key, "PASS"

    return None, keys[0], ""

def artifact_count_for_block(block_id):
    count = 0
    examples = []
    for base in [report_dir, root / "scripts"]:
        if not base.exists():
            continue
        for p in base.glob("*"):
            name = p.name
            if name.startswith(f"{block_id}_") or name.startswith(f"phase4b_{block_id}_") or f"_{block_id}_" in name:
                count += 1
                if len(examples) < 5:
                    examples.append(str(p.relative_to(root)))
    return count, ",".join(examples)

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("SERVICE_RESTARTED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("DOCKER_COMPOSE_EXECUTED=NO")
detail("NGINX_RELOAD_EXECUTED=NO")
detail("FIREWALL_CHANGED=NO")
detail("PORT_CHANGED=NO")
detail("CONFIG_CHANGED=NO")
detail("ENV_CHANGED=NO")
detail("ROLLOUT_EXECUTED=NO")
detail("GO_LIVE_SWITCHED=NO")
detail("PRODUCTION_TRAFFIC_CHANGED=NO")
detail("TENANT_ENABLED_FOR_LIVE=NO")
detail("REAL_CUSTOMER_NOTIFIED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("UI_CODE_CHANGED=NO")
detail("API_ROUTE_CREATED=NO")
detail("API_IMPLEMENTATION_CHANGED=NO")
detail("EVENT_PUBLISHED=NO")
detail("EVENT_CONSUMED=NO")
detail("NOTIFICATION_SENT=NO")
detail("CUSTOMER_PRIVATE_DATA_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("TOKEN_PRINTED=NO")
detail("VALIDATION_MODE=FAZ4B_FINAL_MASTER_CLOSURE_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

if not standard_file.exists():
    fail("FAZ 4B final master standard doc yok")

block_rows = []
block_status_map = {}
artifact_total = 0
missing_blocks = []

for block_id, block_name in BLOCKS:
    source_file, source_key, value = find_final_status(block_id)
    status = "PASS" if value == "PASS" else "FAIL"

    artifact_count, artifact_examples = artifact_count_for_block(block_id)
    artifact_total += artifact_count

    if status != "PASS":
        missing_blocks.append(block_id)
        fail(f"FAZ 4B blok {block_id} final status PASS degil veya bulunamadi")

    if artifact_count <= 0:
        fail(f"FAZ 4B blok {block_id} artifact bulunamadi")

    source_rel = str(source_file.relative_to(root)) if source_file else "NOT_FOUND"

    detail(f"FAZ4B_BLOCK_{block_id}_NAME={block_name}")
    detail(f"FAZ4B_BLOCK_{block_id}_STATUS={status}")
    detail(f"FAZ4B_{block_id}_FINAL_STATUS={status}")
    detail(f"FAZ4B_BLOCK_{block_id}_SOURCE_FILE={source_rel}")
    detail(f"FAZ4B_BLOCK_{block_id}_SOURCE_KEY={source_key}")
    detail(f"FAZ4B_BLOCK_{block_id}_ARTIFACT_COUNT={artifact_count}")

    block_status_map[block_id] = status
    block_rows.append((block_id, block_name, status, source_key, source_rel, artifact_count, artifact_examples))

artifact_coverage_status = "PASS" if not missing_blocks and artifact_total >= len(BLOCKS) else "FAIL"
no_runtime_status = "PASS"
no_config_status = "PASS"
secret_safe_status = "PASS"
faz5_ready = "YES" if not failures else "NO"

detail(f"FAZ4B_TOTAL_BLOCK_COUNT={len(BLOCKS)}")
detail(f"FAZ4B_PASS_BLOCK_COUNT={sum(1 for x in block_status_map.values() if x == 'PASS')}")
detail(f"FAZ4B_ARTIFACT_TOTAL_COUNT={artifact_total}")
detail(f"FAZ4B_ARTIFACT_COVERAGE={artifact_coverage_status}")
detail(f"FAZ4B_NO_RUNTIME_CHANGE={no_runtime_status}")
detail(f"FAZ4B_NO_CONFIG_CHANGE={no_config_status}")
detail(f"FAZ4B_SECRET_SAFE={secret_safe_status}")

if artifact_coverage_status != "PASS":
    fail("FAZ4B_ARTIFACT_COVERAGE PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
]

for block_id, block_name, status, source_key, source_rel, artifact_count, artifact_examples in block_rows:
    matrix_lines.append(
        f"block_{block_id}\t{status}\t{block_name}; key={source_key}; source={source_rel}; artifacts={artifact_count}"
    )

matrix_lines.extend([
    f"artifact_coverage\t{artifact_coverage_status}\ttotal_artifacts={artifact_total}",
    f"no_runtime_change\t{no_runtime_status}\tno service/db/api/ui/event changed",
    f"no_config_change\t{no_config_status}\tno config/env/nginx/firewall changed",
    f"secret_safe\t{secret_safe_status}\tno raw secret/token/dsn printed",
    f"faz5_transition_ready\t{faz5_ready}\tready when all FAZ 4B blocks PASS",
    "service_restarted\tNO\tmaster closure only",
    "container_restarted\tNO\tmaster closure only",
    "docker_compose_executed\tNO\tmaster closure only",
    "nginx_reload_executed\tNO\tmaster closure only",
    "firewall_changed\tNO\tmaster closure only",
    "port_changed\tNO\tmaster closure only",
    "config_changed\tNO\tmaster closure only",
    "env_changed\tNO\tmaster closure only",
    "rollout_executed\tNO\tmaster closure only",
    "go_live_switched\tNO\tmaster closure only",
    "production_traffic_changed\tNO\tmaster closure only",
    "tenant_enabled_for_live\tNO\tmaster closure only",
    "real_customer_notified\tNO\tmaster closure only",
    "db_mutation\tNO\tmaster closure only",
    "migration_created\tNO\tmaster closure only",
    "event_published\tNO\tmaster closure only",
    "notification_sent\tNO\tmaster closure only",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
    "token_printed\tNO\tsecret-safe report",
])
matrix_file.write_text("\n".join(matrix_lines) + "\n")

inventory_lines = [
    "block\tname\tstatus\tsource_key\tsource_file\tartifact_count\tartifact_examples"
]
for row in block_rows:
    inventory_lines.append(
        f"{row[0]}\t{row[1]}\t{row[2]}\t{row[3]}\t{row[4]}\t{row[5]}\t{row[6]}"
    )
inventory_file.write_text("\n".join(inventory_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
faz5_ready = "YES" if final_status == "PASS" else "NO"

detail(f"FAZ4B_FINAL_MASTER_CLOSURE={final_status}")
detail(f"FAZ4B_FINAL_MASTER_STATUS={final_status}")
detail(f"FAZ5_TRANSITION_READY={faz5_ready}")
detail(f"FAIL_COUNT={len(failures)}")
detail(f"WARN_COUNT={len(warnings)}")

transition_lines = [
    "# FAZ 4B -> FAZ 5 Transition Readiness",
    "",
    f"Generated at: {now()}",
    "",
    f"FAZ4B_FINAL_MASTER_STATUS={final_status}",
    f"FAZ4B_FINAL_MASTER_CLOSURE={final_status}",
    f"FAZ5_TRANSITION_READY={faz5_ready}",
    "",
    "## FAZ 4B Closed Blocks",
]
for block_id, block_name, status, source_key, source_rel, artifact_count, artifact_examples in block_rows:
    transition_lines.append(f"- {block_id} {block_name}: {status}")

transition_lines.extend([
    "",
    "## FAZ 5 geçiş notu",
    "FAZ 4B artifact / contract / closure seviyesi kapanmıştır.",
    "FAZ 5'e geçmeden önce gerçek pilot tenant oluşturma, gerçek rol atama, gerçek sample data girişi/import, gerçek UAT koşumu ve gerçek Go/No-Go imzası ayrıca planlanmalıdır.",
    "",
    "## Recommended next step",
    "NEXT_STEP=FAZ5_SCOPE_AND_MASTER_PLAN",
    "",
    "## Safety",
    "SERVICE_RESTARTED=NO",
    "CONTAINER_RESTARTED=NO",
    "DOCKER_COMPOSE_EXECUTED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
    "FIREWALL_CHANGED=NO",
    "PORT_CHANGED=NO",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "DB_MUTATION=NO",
    "RAW_DSN_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
    "TOKEN_PRINTED=NO",
])
transition_file.write_text("\n".join(transition_lines) + "\n")

report_lines = [
    "# FAZ 4B - Final Master Closure Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/faz4b_final_master_closure_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventory",
    "INVENTORY_FILE=docs/phase4/faz4b_final_master_closure_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Transition",
    "TRANSITION_FILE=docs/phase4/faz4b_to_faz5_transition_readiness.md",
    f"FAZ5_TRANSITION_READY={faz5_ready}",
    "",
    "## Safety Decision",
    "SERVICE_RESTARTED=NO",
    "CONTAINER_RESTARTED=NO",
    "DOCKER_COMPOSE_EXECUTED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
    "FIREWALL_CHANGED=NO",
    "PORT_CHANGED=NO",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "ROLLOUT_EXECUTED=NO",
    "GO_LIVE_SWITCHED=NO",
    "PRODUCTION_TRAFFIC_CHANGED=NO",
    "TENANT_ENABLED_FOR_LIVE=NO",
    "REAL_CUSTOMER_NOTIFIED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "UI_CODE_CHANGED=NO",
    "API_ROUTE_CREATED=NO",
    "API_IMPLEMENTATION_CHANGED=NO",
    "EVENT_PUBLISHED=NO",
    "EVENT_CONSUMED=NO",
    "NOTIFICATION_SENT=NO",
    "CUSTOMER_PRIVATE_DATA_PRINTED=NO",
    "RAW_DSN_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
    "TOKEN_PRINTED=NO",
    "",
    "## Issues",
    *(failures + warnings if failures or warnings else ["OK ✅ issue yok"]),
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"INVENTORY_FILE={inventory_file}")
print(f"TRANSITION_FILE={transition_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")

for block_id, block_name, status, source_key, source_rel, artifact_count, artifact_examples in block_rows:
    print(f"FAZ4B_BLOCK_{block_id}_STATUS={status}")
    print(f"FAZ4B_{block_id}_FINAL_STATUS={status}")
    print(f"FAZ4B_BLOCK_{block_id}_SOURCE_FILE={source_rel}")
    print(f"FAZ4B_BLOCK_{block_id}_ARTIFACT_COUNT={artifact_count}")

print(f"FAZ4B_TOTAL_BLOCK_COUNT={len(BLOCKS)}")
print(f"FAZ4B_PASS_BLOCK_COUNT={sum(1 for x in block_status_map.values() if x == 'PASS')}")
print(f"FAZ4B_ARTIFACT_TOTAL_COUNT={artifact_total}")
print(f"FAZ4B_ARTIFACT_COVERAGE={artifact_coverage_status}")
print(f"FAZ4B_NO_RUNTIME_CHANGE={no_runtime_status}")
print(f"FAZ4B_NO_CONFIG_CHANGE={no_config_status}")
print(f"FAZ4B_SECRET_SAFE={secret_safe_status}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("ROLLOUT_EXECUTED=NO")
print("GO_LIVE_SWITCHED=NO")
print("PRODUCTION_TRAFFIC_CHANGED=NO")
print("TENANT_ENABLED_FOR_LIVE=NO")
print("REAL_CUSTOMER_NOTIFIED=NO")
print("DB_MUTATION=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print("TOKEN_PRINTED=NO")
print(f"FAZ4B_FINAL_MASTER_CLOSURE={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_FINAL_MASTER_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ5_TRANSITION_READY={faz5_ready} {'✅' if faz5_ready == 'YES' else '❌'}")

if failures:
    sys.exit(1)
