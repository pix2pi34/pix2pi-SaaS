#!/usr/bin/env python3
import hashlib
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()

report_dir = root / "docs/phase4"
report_dir.mkdir(parents=True, exist_ok=True)

standard_file = report_dir / "18_3_gateway_route_controlled_apply_gate_standard.md"
report_file = report_dir / "18_3_gateway_route_controlled_apply_gate_report.md"
inventory_file = report_dir / "18_3_gateway_route_apply_gate_inventory.tsv"
matrix_file = report_dir / "18_3_gateway_route_apply_gate_matrix.tsv"
execution_file = report_dir / "18_3_gateway_route_controlled_apply_candidate_execution.sh"

r181 = report_dir / "18_1_gateway_runtime_apply_readiness_report.md"
r182 = report_dir / "18_2_reporting_runtime_service_entry_apply_plan_report.md"
r17 = report_dir / "17_reporting_api_final_closure_report.md"

selected_entry_target = "cmd/api-gateway/api_gateway_main.go"
selected_entry_target_abs = root / selected_entry_target
runtime_registration_file = root / "internal/platform/reporting/runtime/registration.go"

failures = []
warnings = []
details = []
tools = []

go_test_file = Path("/tmp/pix2pi_18_3_gateway_route_apply_gate_go_test.log")

def now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")

def detail(line):
    details.append(line)

def fail(msg):
    failures.append(f"FAIL ❌ {msg}")

def warn(msg):
    warnings.append(f"WARN ⚠️ {msg}")

def tool_status(name):
    status = "FOUND" if shutil.which(name) else "NOT_FOUND"
    tools.append(f"TOOL_{name}={status}")
    return status == "FOUND"

def get_value(path, key):
    if not path.exists():
        return ""
    value = ""
    pattern = re.compile(rf"^{re.escape(key)}=(.*)$")
    for line in path.read_text(errors="ignore").splitlines():
        m = pattern.match(line.strip())
        if m:
            value = m.group(1).strip().strip('"')
    return value

def path_status(path):
    return "FOUND" if path.exists() else "NOT_FOUND"

def sha256(path):
    if not path.exists() or not path.is_file():
        return "NA"
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def count_pattern(path, pattern):
    if not path.exists():
        return 0
    text = path.read_text(errors="ignore")
    return len(re.findall(pattern, text, re.MULTILINE))

def run_go_test(args, outfile, append=False):
    mode = "a" if append else "w"
    with outfile.open(mode) as f:
        proc = subprocess.run(
            args,
            cwd=root,
            stdout=f,
            stderr=subprocess.STDOUT,
            text=True,
        )
    return proc.returncode == 0

detail(f"ROOT_DIR={root}")
detail("APPLY_EXECUTED=NO")
detail("APPLY_REPORTING_RUNTIME=0")
detail("DB_MUTATION=NO")
detail("DB_MIGRATION_CREATED=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("SERVICE_CODE_CREATED=NO")
detail("HTTP_HANDLER_CREATED=NO")
detail("ROUTE_REGISTRATION_CREATED=NO")
detail("REPORTING_RUNTIME_STARTED=NO")
detail("SERVICE_RUNTIME_STARTED=NO")
detail("PORT_OPENED=NO")
detail("LISTEN_AND_SERVE_USED=NO")
detail("GATEWAY_CONFIG_CHANGED=NO")
detail("NGINX_CONFIG_CHANGED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("GATE_MODE=CONTROLLED_APPLY_GATE_ONLY")

if not tool_status("go"):
    fail("go bulunamadi")
tool_status("grep")
tool_status("wc")
tool_status("sha256sum")
tool_status("gofmt")

if not standard_file.exists():
    fail("standard doc yok")

r181_status = get_value(r181, "GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY")
r181_ready = get_value(r181, "APPLY_READINESS_STATUS")
r181_blockers = get_value(r181, "APPLY_READINESS_BLOCKER_COUNT")
r181_go_test = get_value(r181, "REPORTING_GO_TEST_SUITE")

r182_status = get_value(r182, "REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN")
r182_selected_status = get_value(r182, "SELECTED_ENTRY_TARGET_STATUS")
r182_selected_kind = get_value(r182, "SELECTED_ENTRY_TARGET_KIND")
r182_selected_target = get_value(r182, "SELECTED_ENTRY_TARGET")
r182_candidate_created = get_value(r182, "CANDIDATE_EXECUTION_CREATED")
r182_candidate_blocked = get_value(r182, "CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT")
r182_go_test = get_value(r182, "REPORTING_GO_TEST_SUITE")
r182_apply_executed = get_value(r182, "APPLY_EXECUTED")
r182_gateway_changed = get_value(r182, "GATEWAY_CONFIG_CHANGED")
r182_runtime_started = get_value(r182, "REPORTING_RUNTIME_STARTED")
r182_db_mutation = get_value(r182, "DB_MUTATION")

r17_final = get_value(r17, "FAZ4_17_FINAL_STATUS")
r17_closure = get_value(r17, "REPORTING_API_FINAL_CLOSURE")
r17_route_count = get_value(r17, "GATEWAY_REPORTING_ROUTE_COUNT")
r17_go_test = get_value(r17, "REPORTING_GO_TEST_SUITE")
r17_runtime_started = get_value(r17, "REPORTING_RUNTIME_STARTED")
r17_gateway_changed = get_value(r17, "GATEWAY_CONFIG_CHANGED")
r17_db_mutation = get_value(r17, "DB_MUTATION")
r17_query_text = get_value(r17, "QUERY_TEXT_PRINTED")

detail(f"PREVIOUS_18_1_READINESS_DISCOVERY={r181_status}")
detail(f"PREVIOUS_18_1_APPLY_READINESS_STATUS={r181_ready}")
detail(f"PREVIOUS_18_1_APPLY_READINESS_BLOCKER_COUNT={r181_blockers}")
detail(f"PREVIOUS_18_1_REPORTING_GO_TEST_SUITE={r181_go_test}")

detail(f"PREVIOUS_18_2_SERVICE_ENTRY_APPLY_PLAN={r182_status}")
detail(f"PREVIOUS_18_2_SELECTED_ENTRY_TARGET_STATUS={r182_selected_status}")
detail(f"PREVIOUS_18_2_SELECTED_ENTRY_TARGET_KIND={r182_selected_kind}")
detail(f"PREVIOUS_18_2_SELECTED_ENTRY_TARGET={r182_selected_target}")
detail(f"PREVIOUS_18_2_CANDIDATE_EXECUTION_CREATED={r182_candidate_created}")
detail(f"PREVIOUS_18_2_CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT={r182_candidate_blocked}")
detail(f"PREVIOUS_18_2_REPORTING_GO_TEST_SUITE={r182_go_test}")
detail(f"PREVIOUS_18_2_APPLY_EXECUTED={r182_apply_executed}")
detail(f"PREVIOUS_18_2_GATEWAY_CONFIG_CHANGED={r182_gateway_changed}")
detail(f"PREVIOUS_18_2_REPORTING_RUNTIME_STARTED={r182_runtime_started}")
detail(f"PREVIOUS_18_2_DB_MUTATION={r182_db_mutation}")

detail(f"PREVIOUS_17_FINAL_STATUS={r17_final}")
detail(f"PREVIOUS_17_REPORTING_API_FINAL_CLOSURE={r17_closure}")
detail(f"PREVIOUS_17_GATEWAY_REPORTING_ROUTE_COUNT={r17_route_count}")
detail(f"PREVIOUS_17_REPORTING_GO_TEST_SUITE={r17_go_test}")
detail(f"PREVIOUS_17_REPORTING_RUNTIME_STARTED={r17_runtime_started}")
detail(f"PREVIOUS_17_GATEWAY_CONFIG_CHANGED={r17_gateway_changed}")
detail(f"PREVIOUS_17_DB_MUTATION={r17_db_mutation}")
detail(f"PREVIOUS_17_QUERY_TEXT_PRINTED={r17_query_text}")

checks = [
    (r181_status == "PASS", "18.1 readiness discovery PASS degil"),
    (r181_ready == "READY", "18.1 readiness READY degil"),
    (r181_blockers == "0", "18.1 blocker count 0 degil"),
    (r181_go_test == "PASS", "18.1 go test PASS degil"),
    (r182_status == "PASS", "18.2 service entry apply plan PASS degil"),
    (r182_selected_status == "SELECTED", "18.2 selected target SELECTED degil"),
    (r182_selected_kind == "API_GATEWAY", "18.2 selected target API_GATEWAY degil"),
    (r182_selected_target == selected_entry_target, "18.2 selected target beklenen api-gateway dosyasi degil"),
    (r182_candidate_created == "YES", "18.2 candidate execution created YES degil"),
    (r182_candidate_blocked == "YES", "18.2 candidate execution blocked YES degil"),
    (r182_go_test == "PASS", "18.2 reporting go test PASS degil"),
    (r182_apply_executed == "NO", "18.2 apply executed NO degil"),
    (r182_gateway_changed == "NO", "18.2 gateway config changed NO degil"),
    (r182_runtime_started == "NO", "18.2 runtime started NO degil"),
    (r182_db_mutation == "NO", "18.2 DB mutation NO degil"),
    (r17_final == "PASS", "17 final status PASS degil"),
    (r17_closure == "PASS", "17 reporting api closure PASS degil"),
    (r17_route_count == "6", "17 gateway route count 6 degil"),
    (r17_go_test == "PASS", "17 reporting go test PASS degil"),
    (r17_runtime_started == "NO", "17 runtime started NO degil"),
    (r17_gateway_changed == "NO", "17 gateway config changed NO degil"),
    (r17_db_mutation == "NO", "17 DB mutation NO degil"),
    (r17_query_text == "NO", "17 query text printed NO degil"),
]

for ok, msg in checks:
    if not ok:
        fail(msg)

selected_status = path_status(selected_entry_target_abs)
runtime_status = path_status(runtime_registration_file)
selected_hash = sha256(selected_entry_target_abs)
runtime_hash = sha256(runtime_registration_file)

detail(f"SELECTED_ENTRY_TARGET={selected_entry_target}")
detail("SELECTED_ENTRY_TARGET_KIND=API_GATEWAY")
detail(f"SELECTED_ENTRY_TARGET_STATUS={selected_status}")
detail(f"SELECTED_ENTRY_TARGET_SHA256={selected_hash}")
detail("RUNTIME_REGISTRATION_FILE=internal/platform/reporting/runtime/registration.go")
detail(f"RUNTIME_REGISTRATION_FILE_STATUS={runtime_status}")
detail(f"RUNTIME_REGISTRATION_SHA256={runtime_hash}")

if selected_status != "FOUND":
    fail("selected api-gateway target file yok")
if runtime_status != "FOUND":
    fail("runtime registration file yok")

target_package_main_count = count_pattern(selected_entry_target_abs, r"^package main")
target_main_func_count = count_pattern(selected_entry_target_abs, r"^func main\(")
target_mux_pattern_count = count_pattern(selected_entry_target_abs, r"http\.NewServeMux|ServeMux|mux|router|routes|Register")
target_listen_pattern_count = count_pattern(selected_entry_target_abs, r"ListenAndServe|\.Listen\(|app\.Listen")
target_reporting_import_count = count_pattern(selected_entry_target_abs, r"internal/platform/reporting/runtime")
target_reporting_register_call_count = count_pattern(selected_entry_target_abs, r"RegisterReportingRoutes")

register_function_count = count_pattern(runtime_registration_file, r"func RegisterReportingRoutes")
routes_function_count = count_pattern(runtime_registration_file, r"func Routes\(\)")
route_constant_usage_count = count_pattern(runtime_registration_file, r"Path(OperationalSummary|DailyMetrics|InventoryStatus|DocumentWorkQueue|ReconciliationStatus|ProjectionState)")

detail(f"TARGET_PACKAGE_MAIN_COUNT={target_package_main_count}")
detail(f"TARGET_MAIN_FUNC_COUNT={target_main_func_count}")
detail(f"TARGET_MUX_PATTERN_COUNT={target_mux_pattern_count}")
detail(f"TARGET_LISTEN_PATTERN_COUNT={target_listen_pattern_count}")
detail(f"TARGET_REPORTING_IMPORT_COUNT={target_reporting_import_count}")
detail(f"TARGET_REPORTING_REGISTER_CALL_COUNT={target_reporting_register_call_count}")
detail(f"REGISTER_REPORTING_ROUTES_FUNCTION_COUNT={register_function_count}")
detail(f"REPORTING_ROUTES_FUNCTION_COUNT={routes_function_count}")
detail(f"REPORTING_ROUTE_CONSTANT_USAGE_COUNT={route_constant_usage_count}")

if target_package_main_count < 1:
    fail("selected target package main degil")
if target_main_func_count < 1:
    warn("selected target main func bulunamadi; route registration baska dosyada olabilir")
if target_mux_pattern_count < 1:
    warn("selected target mux/router pattern net bulunamadi; 18.4 oncesi patch noktasi dogrulanmali")
if register_function_count < 1:
    fail("RegisterReportingRoutes fonksiyonu yok")
if routes_function_count < 1:
    fail("Routes fonksiyonu yok")
if route_constant_usage_count < 6:
    fail("reporting route constant count 6 altinda")

reporting_already_applied = "YES" if target_reporting_import_count > 0 or target_reporting_register_call_count > 0 else "NO"
if reporting_already_applied == "YES":
    warn("reporting runtime target icinde zaten gorunuyor; 18.4 live smoke oncesi idempotency kontrolu gerekir")

detail(f"REPORTING_RUNTIME_ALREADY_APPLIED={reporting_already_applied}")

reporting_go_test_suite = "SKIPPED"
api_gateway_go_test_status = "SKIPPED"

if not failures:
    if run_go_test(["go", "test", "./internal/platform/reporting/...", "-v"], go_test_file, append=False):
        reporting_go_test_suite = "PASS"
    else:
        reporting_go_test_suite = "FAIL"
        fail("go test ./internal/platform/reporting/... failed")

detail(f"REPORTING_GO_TEST_SUITE={reporting_go_test_suite}")

if not failures:
    if run_go_test(["go", "test", "./cmd/api-gateway", "-run", "TestGateway|Test.*Route|Test.*Runtime|Test.*Entry|Test.*Mount|Test.*Policy", "-v"], go_test_file, append=True):
        api_gateway_go_test_status = "PASS"
    else:
        api_gateway_go_test_status = "FAIL"
        fail("go test ./cmd/api-gateway selected tests failed")

detail(f"API_GATEWAY_GO_TEST_STATUS={api_gateway_go_test_status}")

execution_file.write_text(f"""#!/usr/bin/env bash
set -euo pipefail
echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 18.3 gateway route controlled apply candidate execution plan."
echo "18.3 does not apply runtime/gateway changes."
echo "Actual controlled apply belongs to 18.4 after explicit apply decision."
exit 99

# FAZ 4 / 18.3 - Gateway Route Controlled Apply Candidate Execution
# Generated at: {now()}
# This file is intentionally blocked by exit 99 above.

ROOT_DIR="."
SELECTED_ENTRY_TARGET="cmd/api-gateway/api_gateway_main.go"
SELECTED_ENTRY_TARGET_SHA256="{selected_hash}"
RUNTIME_REGISTRATION_FILE="internal/platform/reporting/runtime/registration.go"
RUNTIME_REGISTRATION_SHA256="{runtime_hash}"

# Proposed import:
# reportingruntime "github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/runtime"

# Proposed route registration call after mux/router creation:
# if err := reportingruntime.RegisterReportingRoutes(mux); err != nil {{
#   log.Fatalf("reporting route registration failed: %v", err)
# }}

# Idempotency rule:
# 1. If reportingruntime import already exists, do not add duplicate import.
# 2. If RegisterReportingRoutes call already exists, do not add duplicate call.
# 3. Patch only api-gateway target, never accounting-service or unrelated cmd.

# Controlled apply sequence for 18.4:
# 1. Backup cmd/api-gateway/api_gateway_main.go.
# 2. Detect mux/router symbol in api-gateway entry.
# 3. Add reportingruntime import if missing.
# 4. Add reportingruntime.RegisterReportingRoutes(mux) if missing.
# 5. Run gofmt on changed file.
# 6. Run go test ./internal/platform/reporting/... .
# 7. Run go test ./cmd/api-gateway with route/runtime tests.
# 8. Build or compile api-gateway if needed.
# 9. Restart only controlled gateway runtime if explicitly approved.
# 10. Run live HTTP smoke in 18.4/18.5.

# Rollback:
# 1. Restore backed-up cmd/api-gateway/api_gateway_main.go.
# 2. Run gofmt.
# 3. Run go test ./cmd/api-gateway.
# 4. Verify gateway returns to previous route set.
""")
execution_file.chmod(0o600)

candidate_execution_created = "YES" if execution_file.exists() else "NO"
candidate_text = execution_file.read_text(errors="ignore") if execution_file.exists() else ""
candidate_execution_blocked = "YES" if "exit 99" in candidate_text and "DO_NOT_RUN_AUTOMATICALLY=YES" in candidate_text else "NO"

detail("CANDIDATE_EXECUTION_FILE=docs/phase4/18_3_gateway_route_controlled_apply_candidate_execution.sh")
detail(f"CANDIDATE_EXECUTION_CREATED={candidate_execution_created}")
detail(f"CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT={candidate_execution_blocked}")

if candidate_execution_created != "YES":
    fail("candidate execution olusmadi")
if candidate_execution_blocked != "YES":
    fail("candidate execution blocked by default degil")

apply_gate_ready = "YES" if not failures else "NO"
detail(f"APPLY_GATE_READY={apply_gate_ready}")

inventory_lines = [
    "item\tstatus\tnote",
    f"selected_entry_target\t{selected_status}\t{selected_entry_target}",
    "selected_entry_kind\tAPI_GATEWAY\tapi gateway target enforced",
    f"target_sha256\tCAPTURED\t{selected_hash}",
    f"runtime_registration\t{runtime_status}\tinternal/platform/reporting/runtime/registration.go",
    f"register_function\tFOUND\tcount={register_function_count}",
    f"routes_function\tFOUND\tcount={routes_function_count}",
    f"route_constants\tFOUND\tcount={route_constant_usage_count}",
    f"target_package_main\tCHECKED\tcount={target_package_main_count}",
    f"target_main_func\tCHECKED\tcount={target_main_func_count}",
    f"target_mux_pattern\tCHECKED\tcount={target_mux_pattern_count}",
    f"reporting_already_applied\t{reporting_already_applied}\timport_count={target_reporting_import_count} call_count={target_reporting_register_call_count}",
    f"candidate_execution\t{candidate_execution_created}\tblocked_by_default={candidate_execution_blocked}",
    f"apply_gate_ready\t{apply_gate_ready}\tfailures={len(failures)} warnings={len(warnings)}",
]
inventory_file.write_text("\n".join(inventory_lines) + "\n")
detail(f"APPLY_GATE_INVENTORY_LINE_COUNT={len(inventory_lines)}")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_18_1_readiness\t{r181_status}\treadiness={r181_ready} blockers={r181_blockers}",
    f"previous_18_2_plan\t{r182_status}\tselected={r182_selected_target} kind={r182_selected_kind}",
    f"previous_17_final\t{r17_final}\treporting api closure",
    f"selected_target_api_gateway\t{selected_status}\t{selected_entry_target}",
    "runtime_registration\tPASS\tRegisterReportingRoutes available",
    f"reporting_go_test_suite\t{reporting_go_test_suite}\tinternal platform reporting",
    f"api_gateway_go_test\t{api_gateway_go_test_status}\tselected api-gateway tests",
    f"candidate_execution_created\t{candidate_execution_created}\tblocked_by_default={candidate_execution_blocked}",
    "apply_executed\tNO\tgate only",
    "gateway_config_changed\tNO\tgate only",
    "runtime_started\tNO\tgate only",
    "db_mutation\tNO\tgate only",
    f"apply_gate_ready\t{apply_gate_ready}\twarnings={len(warnings)}",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")
detail(f"APPLY_GATE_MATRIX_LINE_COUNT={len(matrix_lines)}")

if len(inventory_lines) < 10:
    fail("inventory line count 10 altinda")
if len(matrix_lines) < 10:
    fail("matrix line count 10 altinda")

detail(f"GATEWAY_ROUTE_CONTROLLED_APPLY_GATE={'PASS' if not failures else 'FAIL'}")

report_lines = [
    "# FAZ 4 / 18.3 - Gateway Route Controlled Apply Gate Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"GATEWAY_ROUTE_CONTROLLED_APPLY_GATE={'PASS' if not failures else 'FAIL'}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Apply Gate Inventory",
    "INVENTORY_FILE=docs/phase4/18_3_gateway_route_apply_gate_inventory.tsv",
    inventory_file.read_text(errors="ignore").rstrip(),
    "",
    "## Apply Gate Matrix",
    "MATRIX_FILE=docs/phase4/18_3_gateway_route_apply_gate_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Candidate Execution First 140 Lines",
    "\n".join(execution_file.read_text(errors="ignore").splitlines()[:140]),
    "",
    "## Go Test Output",
    "\n".join(go_test_file.read_text(errors="ignore").splitlines()[:520]) if go_test_file.exists() else "go test output yok",
    "",
    "## Safety Decision",
    "APPLY_EXECUTED=NO",
    "APPLY_REPORTING_RUNTIME=0",
    "DB_MUTATION=NO",
    "DB_MIGRATION_CREATED=NO",
    "DB_APPLY_EXECUTED=NO",
    "SERVICE_CODE_CREATED=NO",
    "HTTP_HANDLER_CREATED=NO",
    "ROUTE_REGISTRATION_CREATED=NO",
    "REPORTING_RUNTIME_STARTED=NO",
    "SERVICE_RUNTIME_STARTED=NO",
    "PORT_OPENED=NO",
    "LISTEN_AND_SERVE_USED=NO",
    "GATEWAY_CONFIG_CHANGED=NO",
    "NGINX_CONFIG_CHANGED=NO",
    "POSTGRES_CONFIG_CHANGED=NO",
    "CONTAINER_RESTARTED=NO",
    "QUERY_TEXT_PRINTED=NO",
    "GATE_MODE=CONTROLLED_APPLY_GATE_ONLY",
    "",
    "## Issues",
    *(failures + warnings if failures or warnings else ["OK ✅ issue yok"]),
    "",
    "## Secret Safety",
    "RAW_DSN_PRINTED=NO",
    "POSTGRES_PASSWORD_PRINTED=NO",
    "QUERY_TEXT_PRINTED=NO",
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"INVENTORY_FILE={inventory_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"EXECUTION_FILE={execution_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"APPLY_GATE_READY={apply_gate_ready}")
print(f"SELECTED_ENTRY_TARGET={selected_entry_target}")
print("SELECTED_ENTRY_TARGET_KIND=API_GATEWAY")
print(f"REPORTING_GO_TEST_SUITE={reporting_go_test_suite}")
print(f"API_GATEWAY_GO_TEST_STATUS={api_gateway_go_test_status}")
print(f"CANDIDATE_EXECUTION_CREATED={candidate_execution_created}")
print(f"CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT={candidate_execution_blocked}")

if failures:
    print("GATEWAY_ROUTE_CONTROLLED_APPLY_GATE=FAIL ❌")
    sys.exit(1)

print("GATEWAY_ROUTE_CONTROLLED_APPLY_GATE=PASS ✅")
