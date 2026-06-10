#!/usr/bin/env python3
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()
report_dir = root / "docs/phase4"
report_dir.mkdir(parents=True, exist_ok=True)

standard_file = report_dir / "19_phase4_final_master_closure_standard.md"
report_file = report_dir / "19_phase4_final_master_closure_report.md"
inventory_file = report_dir / "19_phase4_final_master_closure_inventory.tsv"
transition_file = report_dir / "19_phase4_to_phase5_transition_gate.tsv"
master_file = report_dir / "phase4_final_master_closure_report.md"

files = {
    "14.3": report_dir / "14_3_final_db_observability_closure_report.md",
    "14.4": report_dir / "14_4_final_db_performance_closure_report.md",
    "14.5": report_dir / "14_5_2_db_production_readiness_scorecard_report.md",
    "15": report_dir / "15_readmodel_final_closure_report.md",
    "16": report_dir / "16_reporting_final_closure_report.md",
    "17": report_dir / "17_reporting_api_final_closure_report.md",
    "18": report_dir / "18_reporting_live_route_final_closure_report.md",
}

target_gateway = root / "cmd/api-gateway/api_gateway_main.go"
go_test_file = Path("/tmp/pix2pi_19_phase4_final_master_closure_go_test.log")

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

def warn(msg):
    warnings.append(f"WARN ⚠️ {msg}")

def tool_status(name):
    status = "FOUND" if which(name) else "NOT_FOUND"
    tools.append(f"TOOL_{name}={status}")
    return status == "FOUND"

def read_text(path):
    if not path.exists():
        return ""
    return path.read_text(errors="ignore")

def get_value(path, key):
    text = read_text(path)
    value = ""
    pattern = re.compile(rf"^{re.escape(key)}=(.*)$")
    for line in text.splitlines():
        m = pattern.match(line.strip())
        if m:
            value = m.group(1).strip().strip('"')
    return value

def count_pattern(path, pattern):
    text = read_text(path)
    return len(re.findall(pattern, text, re.MULTILINE))

def any_pass(path, keys):
    for key in keys:
        if get_value(path, key) == "PASS":
            return "PASS", key
    text = read_text(path)
    if re.search(r"(FINAL_STATUS|FINAL_CLOSURE|CLOSURE|STATUS)=PASS", text):
        return "PASS", "GENERIC_PASS"
    return "FAIL", "NOT_FOUND"

def run_cmd(cmd, outfile, append=False):
    mode = "a" if append else "w"
    with outfile.open(mode) as f:
        proc = subprocess.run(
            cmd,
            cwd=root,
            stdout=f,
            stderr=subprocess.STDOUT,
            text=True,
        )
    return proc.returncode == 0

detail(f"ROOT_DIR={root}")
detail("APPLY_EXECUTED=NO")
detail("RUNTIME_RESTART_EXECUTED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("DB_MUTATION=NO")
detail("DB_MIGRATION_CREATED=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("GATEWAY_CONFIG_CHANGED=NO")
detail("NGINX_CONFIG_CHANGED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("AUTH_TOKEN_PRINTED=NO")
detail("FINAL_MASTER_CLOSURE_MODE=EVIDENCE_ONLY")

tool_status("go")
tool_status("python3")
tool_status("grep")
tool_status("wc")

if not standard_file.exists():
    fail("19 standard doc yok")

block_specs = {
    "14.3": ["FAZ4_14_3_FINAL_STATUS", "DB_OBSERVABILITY_FINAL_BASELINE", "DB_OBSERVABILITY_CONTROLLED_APPLY"],
    "14.4": ["FAZ4_14_4_FINAL_STATUS", "DB_PERFORMANCE_FINAL_CLOSURE"],
    "14.5": ["DB_PRODUCTION_READINESS_SCORECARD"],
    "15": ["FAZ4_15_FINAL_STATUS", "READMODEL_FINAL_CLOSURE", "READMODEL_CONTRACT_QUERY_EVIDENCE"],
    "16": ["FAZ4_16_FINAL_STATUS", "REPORTING_FINAL_CLOSURE"],
    "17": ["FAZ4_17_FINAL_STATUS", "REPORTING_API_FINAL_CLOSURE"],
    "18": ["FAZ4_18_FINAL_STATUS", "REPORTING_LIVE_ROUTE_FINAL_CLOSURE"],
}

block_results = {}
for block, path in files.items():
    exists = "YES" if path.exists() else "NO"
    status, evidence_key = any_pass(path, block_specs[block])
    block_results[block] = {
        "file": path,
        "exists": exists,
        "status": status,
        "evidence_key": evidence_key,
    }

    detail(f"BLOCK_{block.replace('.', '_')}_FILE_EXISTS={exists}")
    detail(f"BLOCK_{block.replace('.', '_')}_STATUS={status}")
    detail(f"BLOCK_{block.replace('.', '_')}_EVIDENCE_KEY={evidence_key}")

    if exists != "YES":
        fail(f"{block} closure report yok: {path.relative_to(root)}")
    if status != "PASS":
        fail(f"{block} closure PASS degil")

# Important extracted evidence
db_readiness_score = get_value(files["14.5"], "DB_PRODUCTION_READINESS_SCORE")
db_readiness_grade = get_value(files["14.5"], "DB_PRODUCTION_READINESS_GRADE")
db_readiness_status = get_value(files["14.5"], "DB_PRODUCTION_READINESS_STATUS")
pitr_deferred_count = get_value(files["14.5"], "DEFERRED_ACTION_COUNT")

phase18_live_security = get_value(files["18"], "LIVE_ROUTE_SECURITY_STATUS")
phase18_real_token = get_value(files["18"], "REAL_TOKEN_FULL_SMOKE_STATUS")
phase18_auth_401 = get_value(files["18"], "LIVE_REPORTING_AUTH_PROTECTED_401_COUNT")
phase18_route_404 = get_value(files["18"], "LIVE_REPORTING_ROUTE_404_COUNT")
phase18_query_leak = get_value(files["18"], "QUERY_TEXT_LEAK_CHECK")

reporting_import_count = count_pattern(target_gateway, r"internal/platform/reporting/runtime")
reporting_register_count = count_pattern(target_gateway, r"reportingruntime\.RegisterReportingRoutes")

detail(f"DB_PRODUCTION_READINESS_SCORE={db_readiness_score}")
detail(f"DB_PRODUCTION_READINESS_GRADE={db_readiness_grade}")
detail(f"DB_PRODUCTION_READINESS_STATUS={db_readiness_status}")
detail(f"PITR_DEFERRED_ACTION_COUNT={pitr_deferred_count}")

detail(f"LIVE_ROUTE_SECURITY_STATUS={phase18_live_security}")
detail(f"REAL_TOKEN_FULL_SMOKE_STATUS={phase18_real_token}")
detail(f"LIVE_REPORTING_AUTH_PROTECTED_401_COUNT={phase18_auth_401}")
detail(f"LIVE_REPORTING_ROUTE_404_COUNT={phase18_route_404}")
detail(f"QUERY_TEXT_LEAK_CHECK={phase18_query_leak}")

detail(f"GATEWAY_REPORTING_RUNTIME_IMPORT_COUNT={reporting_import_count}")
detail(f"GATEWAY_REPORTING_RUNTIME_REGISTER_CALL_COUNT={reporting_register_count}")

if reporting_import_count != 1:
    fail("gateway reporting runtime import count 1 degil")
if reporting_register_count != 1:
    fail("gateway reporting runtime register call count 1 degil")

if db_readiness_status not in ("READY", "READY_WITH_DEFERRED_ACTIONS"):
    fail("DB production readiness status READY / READY_WITH_DEFERRED_ACTIONS degil")

if phase18_live_security != "AUTH_PROTECTED":
    fail("18 live route security status AUTH_PROTECTED degil")

if phase18_real_token != "DEFERRED_NO_VALID_TOKEN":
    warn("real token full smoke deferred disinda bir durum raporlanmis; kontrol edilmeli")

if phase18_route_404 != "0":
    fail("live reporting route 404 count 0 degil")

if phase18_query_leak != "PASS":
    fail("query text leak check PASS degil")

reporting_go_test_suite = "SKIPPED"
api_gateway_go_test_status = "SKIPPED"

if not failures:
    if run_cmd(["go", "test", "./internal/platform/reporting/...", "-v"], go_test_file, append=False):
        reporting_go_test_suite = "PASS"
    else:
        reporting_go_test_suite = "FAIL"
        fail("go test ./internal/platform/reporting/... failed")

detail(f"REPORTING_GO_TEST_SUITE={reporting_go_test_suite}")

if not failures:
    if run_cmd(["go", "test", "./cmd/api-gateway", "-run", "TestGateway|Test.*Route|Test.*Runtime|Test.*Entry|Test.*Mount|Test.*Policy", "-v"], go_test_file, append=True):
        api_gateway_go_test_status = "PASS"
    else:
        api_gateway_go_test_status = "FAIL"
        fail("go test ./cmd/api-gateway selected tests failed")

detail(f"API_GATEWAY_GO_TEST_STATUS={api_gateway_go_test_status}")

deferred_items = []
if db_readiness_status == "READY_WITH_DEFERRED_ACTIONS" or pitr_deferred_count not in ("", "0"):
    deferred_items.append(("PITR", "DEFERRED", "PITR aktiflestirme bakim penceresine erteli"))

if phase18_real_token == "DEFERRED_NO_VALID_TOKEN":
    deferred_items.append(("REAL_JWT_LIVE_SMOKE", "DEFERRED", "Gecerli JWT ile full 200/tenant/method smoke daha sonra kosulacak"))

blocker_count = len(failures)
deferred_count = len(deferred_items)
phase5_gate = "BLOCKED" if blocker_count else ("READY_WITH_DEFERRED_ACTIONS" if deferred_count else "READY")
phase4_final_status = "FAIL" if blocker_count else "PASS"

detail(f"PHASE4_BLOCKER_COUNT={blocker_count}")
detail(f"PHASE4_DEFERRED_ACTION_COUNT={deferred_count}")
detail(f"FAZ5_TRANSITION_GATE={phase5_gate}")
detail(f"PHASE4_FINAL_MASTER_CLOSURE={phase4_final_status}")
detail(f"FAZ4_FINAL_STATUS={phase4_final_status}")

inventory_lines = [
    "block\tstatus\tevidence_file\tevidence_key",
]
for block in ["14.3", "14.4", "14.5", "15", "16", "17", "18"]:
    info = block_results[block]
    inventory_lines.append(
        f"{block}\t{info['status']}\t{info['file'].relative_to(root)}\t{info['evidence_key']}"
    )

inventory_lines.extend([
    f"gateway_reporting_import\t{'PASS' if reporting_import_count == 1 else 'FAIL'}\tcmd/api-gateway/api_gateway_main.go\tcount={reporting_import_count}",
    f"gateway_reporting_register_call\t{'PASS' if reporting_register_count == 1 else 'FAIL'}\tcmd/api-gateway/api_gateway_main.go\tcount={reporting_register_count}",
    f"reporting_go_test_suite\t{reporting_go_test_suite}\tgo test ./internal/platform/reporting/...\tfinal verification",
    f"api_gateway_go_test\t{api_gateway_go_test_status}\tgo test ./cmd/api-gateway selected tests\tfinal verification",
    f"db_production_readiness\t{db_readiness_status}\tdocs/phase4/14_5_2_db_production_readiness_scorecard_report.md\tscore={db_readiness_score} grade={db_readiness_grade}",
    f"live_route_security\t{phase18_live_security}\tdocs/phase4/18_reporting_live_route_final_closure_report.md\tauth_401={phase18_auth_401} route_404={phase18_route_404}",
])
inventory_file.write_text("\n".join(inventory_lines) + "\n")

transition_lines = [
    "item\tstatus\tnote",
    f"phase4_final_status\t{phase4_final_status}\tblockers={blocker_count}",
    f"faz5_transition_gate\t{phase5_gate}\tdeferred_actions={deferred_count}",
    f"db_readiness\t{db_readiness_status}\tscore={db_readiness_score} grade={db_readiness_grade}",
    f"gateway_reporting_live_route\t{phase18_live_security}\tauth protected route verified",
    f"real_jwt_live_smoke\t{phase18_real_token}\toptional follow-up with LIVE_SMOKE_AUTH_TOKEN",
    "runtime_restart_executed\tNO\tfinal master closure only",
    "gateway_config_changed\tNO\tfinal master closure only",
    "nginx_config_changed\tNO\tfinal master closure only",
    "db_mutation\tNO\tfinal master closure only",
]
for name, status, note in deferred_items:
    transition_lines.append(f"deferred_{name.lower()}\t{status}\t{note}")

transition_file.write_text("\n".join(transition_lines) + "\n")

detail(f"FINAL_MASTER_INVENTORY_LINE_COUNT={len(inventory_lines)}")
detail(f"PHASE5_TRANSITION_GATE_LINE_COUNT={len(transition_lines)}")

report_lines = [
    "# FAZ 4 / 19 - Final Master Closure / Faz 5 Transition Gate Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"PHASE4_FINAL_MASTER_CLOSURE={phase4_final_status}",
    f"FAZ4_FINAL_STATUS={phase4_final_status}",
    f"FAZ5_TRANSITION_GATE={phase5_gate}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Final Master Inventory",
    "INVENTORY_FILE=docs/phase4/19_phase4_final_master_closure_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Phase 5 Transition Gate",
    "TRANSITION_FILE=docs/phase4/19_phase4_to_phase5_transition_gate.tsv",
    transition_file.read_text(errors="ignore").rstrip(),
    "",
    "## Go Test Output",
    "\n".join(go_test_file.read_text(errors="ignore").splitlines()[:520]) if go_test_file.exists() else "go test output yok",
    "",
    "## Deferred Actions",
    *(["OK ✅ deferred action yok"] if not deferred_items else [f"{name}={status} — {note}" for name, status, note in deferred_items]),
    "",
    "## Safety Decision",
    "APPLY_EXECUTED=NO",
    "RUNTIME_RESTART_EXECUTED=NO",
    "CONTAINER_RESTARTED=NO",
    "DB_MUTATION=NO",
    "DB_MIGRATION_CREATED=NO",
    "DB_APPLY_EXECUTED=NO",
    "GATEWAY_CONFIG_CHANGED=NO",
    "NGINX_CONFIG_CHANGED=NO",
    "POSTGRES_CONFIG_CHANGED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "AUTH_TOKEN_PRINTED=NO",
    "FINAL_MASTER_CLOSURE_MODE=EVIDENCE_ONLY",
    "",
    "## Issues",
    *(failures + warnings if failures or warnings else ["OK ✅ issue yok"]),
    "",
    "## Secret Safety",
    "RAW_DSN_PRINTED=NO",
    "POSTGRES_PASSWORD_PRINTED=NO",
    "AUTH_TOKEN_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

master_lines = [
    "# FAZ 4 - Final Master Closure",
    "",
    f"Generated at: {now()}",
    "",
    f"PHASE4_FINAL_MASTER_CLOSURE={phase4_final_status}",
    f"FAZ4_FINAL_STATUS={phase4_final_status}",
    f"FAZ5_TRANSITION_GATE={phase5_gate}",
    f"PHASE4_BLOCKER_COUNT={blocker_count}",
    f"PHASE4_DEFERRED_ACTION_COUNT={deferred_count}",
    "",
    "## Closed Blocks",
]
for block in ["14.3", "14.4", "14.5", "15", "16", "17", "18"]:
    info = block_results[block]
    master_lines.append(f"{block}={info['status']} ({info['evidence_key']})")

master_lines.extend([
    "",
    "## Final Evidence",
    f"DB_PRODUCTION_READINESS_STATUS={db_readiness_status}",
    f"DB_PRODUCTION_READINESS_SCORE={db_readiness_score}",
    f"DB_PRODUCTION_READINESS_GRADE={db_readiness_grade}",
    f"GATEWAY_REPORTING_RUNTIME_IMPORT_COUNT={reporting_import_count}",
    f"GATEWAY_REPORTING_RUNTIME_REGISTER_CALL_COUNT={reporting_register_count}",
    f"LIVE_ROUTE_SECURITY_STATUS={phase18_live_security}",
    f"REAL_TOKEN_FULL_SMOKE_STATUS={phase18_real_token}",
    f"REPORTING_GO_TEST_SUITE={reporting_go_test_suite}",
    f"API_GATEWAY_GO_TEST_STATUS={api_gateway_go_test_status}",
    "RUNTIME_RESTART_EXECUTED=NO",
    "GATEWAY_CONFIG_CHANGED=NO",
    "NGINX_CONFIG_CHANGED=NO",
    "DB_MUTATION=NO",
    "QUERY_TEXT_PRINTED=NO",
])
master_file.write_text("\n".join(master_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"INVENTORY_FILE={inventory_file}")
print(f"TRANSITION_FILE={transition_file}")
print(f"MASTER_FILE={master_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"PHASE4_FINAL_MASTER_CLOSURE={phase4_final_status}")
print(f"FAZ4_FINAL_STATUS={phase4_final_status}")
print(f"FAZ5_TRANSITION_GATE={phase5_gate}")
print(f"PHASE4_DEFERRED_ACTION_COUNT={deferred_count}")
print(f"REPORTING_GO_TEST_SUITE={reporting_go_test_suite}")
print(f"API_GATEWAY_GO_TEST_STATUS={api_gateway_go_test_status}")
print("RUNTIME_RESTART_EXECUTED=NO")
print("GATEWAY_CONFIG_CHANGED=NO")
print("NGINX_CONFIG_CHANGED=NO")
print("DB_MUTATION=NO")

if failures:
    sys.exit(1)
