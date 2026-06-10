#!/usr/bin/env python3
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()

report_dir = root / "docs/phase4"
report_dir.mkdir(parents=True, exist_ok=True)

standard_file = report_dir / "18_6_reporting_live_route_final_closure_standard.md"
report_file = report_dir / "18_6_reporting_live_route_final_closure_report.md"
inventory_file = report_dir / "18_6_reporting_live_route_final_closure_inventory.tsv"
matrix_file = report_dir / "18_6_reporting_live_route_final_closure_matrix.tsv"
closure_file = report_dir / "18_reporting_live_route_final_closure_report.md"

r181 = report_dir / "18_1_gateway_runtime_apply_readiness_report.md"
r182 = report_dir / "18_2_reporting_runtime_service_entry_apply_plan_report.md"
r183 = report_dir / "18_3_gateway_route_controlled_apply_gate_report.md"
r184 = report_dir / "18_4_controlled_gateway_runtime_apply_report.md"
r185 = report_dir / "18_5_live_http_smoke_auth_tenant_report.md"
r17 = report_dir / "17_reporting_api_final_closure_report.md"

target = root / "cmd/api-gateway/api_gateway_main.go"
go_test_file = Path("/tmp/pix2pi_18_6_reporting_live_route_final_closure_go_test.log")

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
    from shutil import which
    status = "FOUND" if which(name) else "NOT_FOUND"
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

def count_pattern(path, pattern):
    if not path.exists():
        return 0
    return len(re.findall(pattern, path.read_text(errors="ignore"), re.MULTILINE))

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

def write_outputs():
    inventory_lines = [
        "item\tstatus\tnote",
        f"18.1_readiness\t{r181_status}\treadiness={r181_ready} blockers={r181_blockers}",
        f"18.2_service_entry_plan\t{r182_status}\ttarget={r182_target} kind={r182_kind}",
        f"18.3_apply_gate\t{r183_gate}\tready={r183_ready}",
        f"18.4_controlled_apply\t{r184_apply}\timport={r184_import_count} call={r184_call_count}",
        f"18.5_live_smoke\t{r185_smoke}\tauth_mode={r185_auth_mode} protected={r185_protected_status}",
        f"gateway_target_file\t{'FOUND' if target.exists() else 'NOT_FOUND'}\tcmd/api-gateway/api_gateway_main.go",
        f"target_reporting_import_count\t{target_import_count}\texpected=1",
        f"target_reporting_register_call_count\t{target_call_count}\texpected=1",
        f"live_gateway_reachable\t{r185_gateway_reachable}\tbase_url={r185_base_url}",
        f"live_route_security_status\t{live_route_security_status}\t200_count={r185_200_count} auth_401_count={r185_auth_401_count}",
        f"real_token_full_smoke_status\t{real_token_full_smoke_status}\tauth_mode={r185_auth_mode}",
        f"reporting_go_test_suite\t{reporting_go_test_suite}\tinternal/platform/reporting",
        f"api_gateway_go_test_status\t{api_gateway_go_test_status}\tcmd/api-gateway",
        "runtime_restart_executed\tNO\tclosure only",
        "gateway_config_changed\tNO\tclosure only",
        "nginx_config_changed\tNO\tclosure only",
        "db_mutation\tNO\tclosure only",
        "query_text_printed\tNO\tclosure only",
    ]
    inventory_file.write_text("\n".join(inventory_lines) + "\n")

    matrix_lines = [
        "gate\tstatus\tnote",
        f"previous_17_final\t{r17_final}\treporting api prerequisite",
        f"18.1_readiness\t{r181_status}\tready={r181_ready}",
        f"18.2_service_entry_plan\t{r182_status}\ttarget_kind={r182_kind}",
        f"18.3_apply_gate\t{r183_gate}\tapply_gate_ready={r183_ready}",
        f"18.4_controlled_apply\t{r184_apply}\tcode patch applied",
        f"18.5_live_http_smoke\t{r185_smoke}\tauth-protected live route evidence",
        f"target_code_patch\tPASS\timport={target_import_count} call={target_call_count}",
        f"live_gateway_reachable\t{r185_gateway_reachable}\tbase_url={r185_base_url}",
        f"live_route_security\t{live_route_security_status}\tauth_mode={r185_auth_mode}",
        f"query_text_leak\t{r185_query_leak}\tno query text leak",
        f"reporting_go_test_suite\t{reporting_go_test_suite}\tfinal verification",
        f"api_gateway_go_test\t{api_gateway_go_test_status}\tfinal verification",
        "runtime_restart_executed\tNO\tfinal closure only",
        "gateway_config_changed\tNO\tfinal closure only",
        "nginx_config_changed\tNO\tfinal closure only",
        "db_mutation\tNO\tfinal closure only",
        f"reporting_live_route_final_closure\t{'PASS' if not failures else 'FAIL'}\tfailures={len(failures)} warnings={len(warnings)}",
    ]
    matrix_file.write_text("\n".join(matrix_lines) + "\n")

    detail(f"FINAL_CLOSURE_INVENTORY_LINE_COUNT={len(inventory_lines)}")
    detail(f"FINAL_CLOSURE_MATRIX_LINE_COUNT={len(matrix_lines)}")
    detail(f"REPORTING_LIVE_ROUTE_FINAL_CLOSURE={'PASS' if not failures else 'FAIL'}")
    detail(f"FAZ4_18_FINAL_STATUS={'PASS' if not failures else 'FAIL'}")

    report_lines = [
        "# FAZ 4 / 18.6 - Reporting Live Route Final Closure Report",
        "",
        f"Generated at: {now()}",
        "",
        "## Summary",
        *details,
        f"FAIL_COUNT={len(failures)}",
        f"WARN_COUNT={len(warnings)}",
        f"REPORTING_LIVE_ROUTE_FINAL_CLOSURE={'PASS' if not failures else 'FAIL'}",
        f"FAZ4_18_FINAL_STATUS={'PASS' if not failures else 'FAIL'}",
        "",
        "## Tool Status",
        *tools,
        "",
        "## Final Closure Inventory",
        "INVENTORY_FILE=docs/phase4/18_6_reporting_live_route_final_closure_inventory.tsv",
        inventory_file.read_text(errors="ignore").rstrip(),
        "",
        "## Final Closure Matrix",
        "MATRIX_FILE=docs/phase4/18_6_reporting_live_route_final_closure_matrix.tsv",
        matrix_file.read_text(errors="ignore").rstrip(),
        "",
        "## Go Test Output",
        "\n".join(go_test_file.read_text(errors="ignore").splitlines()[:520]) if go_test_file.exists() else "go test output yok",
        "",
        "## Deferred / Follow-up",
        f"REAL_TOKEN_FULL_SMOKE_STATUS={real_token_full_smoke_status}",
        f"LIVE_AUTH_MODE={r185_auth_mode}",
        "NOTE=Gecerli JWT saglandiginda 18.5 scripti LIVE_SMOKE_AUTH_TOKEN ve LIVE_SMOKE_TENANT_ID ile tekrar kosulabilir.",
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
        "FINAL_CLOSURE_MODE=EVIDENCE_ONLY",
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

    closure_lines = [
        "# FAZ 4 / 18 - Gateway / Reporting Runtime Apply Final Closure",
        "",
        f"Generated at: {now()}",
        "",
        f"18.1 Gateway/runtime apply readiness discovery={r181_status}",
        f"18.2 Reporting runtime service entry apply plan={r182_status}",
        f"18.3 Gateway route controlled apply gate={r183_gate}",
        f"18.4 Controlled gateway runtime apply={r184_apply}",
        f"18.5 Live HTTP smoke / auth-tenant verification={r185_smoke}",
        f"18.6 Reporting live route final closure={'PASS' if not failures else 'FAIL'}",
        "",
        f"REPORTING_LIVE_ROUTE_FINAL_CLOSURE={'PASS' if not failures else 'FAIL'}",
        f"FAZ4_18_FINAL_STATUS={'PASS' if not failures else 'FAIL'}",
        f"SELECTED_ENTRY_TARGET=cmd/api-gateway/api_gateway_main.go",
        f"SELECTED_ENTRY_TARGET_KIND=API_GATEWAY",
        f"REPORTING_RUNTIME_IMPORT_COUNT={target_import_count}",
        f"REPORTING_RUNTIME_REGISTER_CALL_COUNT={target_call_count}",
        f"LIVE_GATEWAY_REACHABLE={r185_gateway_reachable}",
        f"LIVE_AUTH_MODE={r185_auth_mode}",
        f"LIVE_ROUTE_SECURITY_STATUS={live_route_security_status}",
        f"LIVE_REPORTING_AUTH_PROTECTED_401_COUNT={r185_auth_401_count}",
        f"LIVE_REPORTING_ROUTE_404_COUNT={r185_404_count}",
        f"QUERY_TEXT_LEAK_CHECK={r185_query_leak}",
        f"REAL_TOKEN_FULL_SMOKE_STATUS={real_token_full_smoke_status}",
        f"REPORTING_GO_TEST_SUITE={reporting_go_test_suite}",
        f"API_GATEWAY_GO_TEST_STATUS={api_gateway_go_test_status}",
        "RUNTIME_RESTART_EXECUTED=NO",
        "GATEWAY_CONFIG_CHANGED=NO",
        "NGINX_CONFIG_CHANGED=NO",
        "DB_MUTATION=NO",
        "QUERY_TEXT_PRINTED=NO",
    ]
    closure_file.write_text("\n".join(closure_lines) + "\n")

    print(f"REPORT_FILE={report_file}")
    print(f"INVENTORY_FILE={inventory_file}")
    print(f"MATRIX_FILE={matrix_file}")
    print(f"CLOSURE_FILE={closure_file}")
    print(f"FAIL_COUNT={len(failures)}")
    print(f"WARN_COUNT={len(warnings)}")
    print(f"REPORTING_LIVE_ROUTE_FINAL_CLOSURE={'PASS' if not failures else 'FAIL'}")
    print(f"FAZ4_18_FINAL_STATUS={'PASS' if not failures else 'FAIL'}")
    print(f"LIVE_ROUTE_SECURITY_STATUS={live_route_security_status}")
    print(f"REAL_TOKEN_FULL_SMOKE_STATUS={real_token_full_smoke_status}")
    print(f"REPORTING_RUNTIME_IMPORT_COUNT={target_import_count}")
    print(f"REPORTING_RUNTIME_REGISTER_CALL_COUNT={target_call_count}")
    print(f"REPORTING_GO_TEST_SUITE={reporting_go_test_suite}")
    print(f"API_GATEWAY_GO_TEST_STATUS={api_gateway_go_test_status}")
    print("RUNTIME_RESTART_EXECUTED=NO")
    print("GATEWAY_CONFIG_CHANGED=NO")
    print("NGINX_CONFIG_CHANGED=NO")
    print("DB_MUTATION=NO")

    if failures:
        sys.exit(1)

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
detail("FINAL_CLOSURE_MODE=EVIDENCE_ONLY")

tool_status("go")
tool_status("python3")
tool_status("grep")
tool_status("wc")

if not standard_file.exists():
    fail("18.6 standard doc yok")

r17_final = get_value(r17, "FAZ4_17_FINAL_STATUS")
r17_closure = get_value(r17, "REPORTING_API_FINAL_CLOSURE")

r181_status = get_value(r181, "GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY")
r181_ready = get_value(r181, "APPLY_READINESS_STATUS")
r181_blockers = get_value(r181, "APPLY_READINESS_BLOCKER_COUNT")

r182_status = get_value(r182, "REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN")
r182_target = get_value(r182, "SELECTED_ENTRY_TARGET")
r182_kind = get_value(r182, "SELECTED_ENTRY_TARGET_KIND")

r183_gate = get_value(r183, "GATEWAY_ROUTE_CONTROLLED_APPLY_GATE")
r183_ready = get_value(r183, "APPLY_GATE_READY")

r184_apply = get_value(r184, "CONTROLLED_GATEWAY_RUNTIME_APPLY")
r184_import_count = get_value(r184, "REPORTING_RUNTIME_IMPORT_COUNT_AFTER")
r184_call_count = get_value(r184, "REPORTING_RUNTIME_REGISTER_CALL_COUNT_AFTER")
r184_reporting_test = get_value(r184, "REPORTING_GO_TEST_SUITE")
r184_api_gateway_test = get_value(r184, "API_GATEWAY_GO_TEST_STATUS")
r184_runtime_started = get_value(r184, "REPORTING_RUNTIME_STARTED")
r184_gateway_changed = get_value(r184, "GATEWAY_CONFIG_CHANGED")
r184_db_mutation = get_value(r184, "DB_MUTATION")

r185_smoke = get_value(r185, "LIVE_HTTP_SMOKE_AUTH_TENANT")
r185_gateway_reachable = get_value(r185, "LIVE_GATEWAY_REACHABLE")
r185_auth_mode = get_value(r185, "LIVE_AUTH_MODE")
r185_200_count = get_value(r185, "LIVE_REPORTING_ENDPOINT_200_COUNT")
r185_auth_401_count = get_value(r185, "LIVE_REPORTING_AUTH_PROTECTED_401_COUNT")
r185_404_count = get_value(r185, "LIVE_REPORTING_ROUTE_404_COUNT")
r185_protected_status = get_value(r185, "LIVE_REPORTING_PROTECTED_ROUTE_STATUS")
r185_auth_gate = get_value(r185, "LIVE_AUTH_GATE_STATUS")
r185_tenant_gate = get_value(r185, "LIVE_TENANT_GATE_STATUS")
r185_method_gate = get_value(r185, "LIVE_METHOD_GATE_STATUS")
r185_query_leak = get_value(r185, "QUERY_TEXT_LEAK_CHECK")
r185_restart = get_value(r185, "RUNTIME_RESTART_EXECUTED")
r185_gateway_changed = get_value(r185, "GATEWAY_CONFIG_CHANGED")
r185_nginx_changed = get_value(r185, "NGINX_CONFIG_CHANGED")
r185_db_mutation = get_value(r185, "DB_MUTATION")
r185_base_url = get_value(r185, "GATEWAY_BASE_URL")

detail(f"PREVIOUS_17_FINAL_STATUS={r17_final}")
detail(f"PREVIOUS_17_REPORTING_API_FINAL_CLOSURE={r17_closure}")

detail(f"18_1_GATEWAY_RUNTIME_APPLY_READINESS_DISCOVERY={r181_status}")
detail(f"18_1_APPLY_READINESS_STATUS={r181_ready}")
detail(f"18_1_APPLY_READINESS_BLOCKER_COUNT={r181_blockers}")

detail(f"18_2_REPORTING_RUNTIME_SERVICE_ENTRY_APPLY_PLAN={r182_status}")
detail(f"18_2_SELECTED_ENTRY_TARGET={r182_target}")
detail(f"18_2_SELECTED_ENTRY_TARGET_KIND={r182_kind}")

detail(f"18_3_GATEWAY_ROUTE_CONTROLLED_APPLY_GATE={r183_gate}")
detail(f"18_3_APPLY_GATE_READY={r183_ready}")

detail(f"18_4_CONTROLLED_GATEWAY_RUNTIME_APPLY={r184_apply}")
detail(f"18_4_REPORTING_RUNTIME_IMPORT_COUNT_AFTER={r184_import_count}")
detail(f"18_4_REPORTING_RUNTIME_REGISTER_CALL_COUNT_AFTER={r184_call_count}")
detail(f"18_4_REPORTING_GO_TEST_SUITE={r184_reporting_test}")
detail(f"18_4_API_GATEWAY_GO_TEST_STATUS={r184_api_gateway_test}")
detail(f"18_4_REPORTING_RUNTIME_STARTED={r184_runtime_started}")
detail(f"18_4_GATEWAY_CONFIG_CHANGED={r184_gateway_changed}")
detail(f"18_4_DB_MUTATION={r184_db_mutation}")

detail(f"18_5_LIVE_HTTP_SMOKE_AUTH_TENANT={r185_smoke}")
detail(f"18_5_GATEWAY_BASE_URL={r185_base_url}")
detail(f"18_5_LIVE_GATEWAY_REACHABLE={r185_gateway_reachable}")
detail(f"18_5_LIVE_AUTH_MODE={r185_auth_mode}")
detail(f"18_5_LIVE_REPORTING_ENDPOINT_200_COUNT={r185_200_count}")
detail(f"18_5_LIVE_REPORTING_AUTH_PROTECTED_401_COUNT={r185_auth_401_count}")
detail(f"18_5_LIVE_REPORTING_ROUTE_404_COUNT={r185_404_count}")
detail(f"18_5_LIVE_REPORTING_PROTECTED_ROUTE_STATUS={r185_protected_status}")
detail(f"18_5_LIVE_AUTH_GATE_STATUS={r185_auth_gate}")
detail(f"18_5_LIVE_TENANT_GATE_STATUS={r185_tenant_gate}")
detail(f"18_5_LIVE_METHOD_GATE_STATUS={r185_method_gate}")
detail(f"18_5_QUERY_TEXT_LEAK_CHECK={r185_query_leak}")
detail(f"18_5_RUNTIME_RESTART_EXECUTED={r185_restart}")
detail(f"18_5_GATEWAY_CONFIG_CHANGED={r185_gateway_changed}")
detail(f"18_5_NGINX_CONFIG_CHANGED={r185_nginx_changed}")
detail(f"18_5_DB_MUTATION={r185_db_mutation}")

checks = [
    (r17_final == "PASS", "17 final status PASS degil"),
    (r17_closure == "PASS", "17 reporting api closure PASS degil"),
    (r181_status == "PASS", "18.1 readiness discovery PASS degil"),
    (r181_ready == "READY", "18.1 readiness READY degil"),
    (r181_blockers == "0", "18.1 blocker count 0 degil"),
    (r182_status == "PASS", "18.2 service entry plan PASS degil"),
    (r182_target == "cmd/api-gateway/api_gateway_main.go", "18.2 selected target api-gateway degil"),
    (r182_kind == "API_GATEWAY", "18.2 selected target kind API_GATEWAY degil"),
    (r183_gate == "PASS", "18.3 gate PASS degil"),
    (r183_ready == "YES", "18.3 apply gate ready YES degil"),
    (r184_apply == "PASS", "18.4 controlled apply PASS degil"),
    (r184_import_count == "1", "18.4 import count 1 degil"),
    (r184_call_count == "1", "18.4 register call count 1 degil"),
    (r184_reporting_test == "PASS", "18.4 reporting go test PASS degil"),
    (r184_api_gateway_test == "PASS", "18.4 api gateway go test PASS degil"),
    (r184_runtime_started == "NO", "18.4 runtime started NO degil"),
    (r184_gateway_changed == "NO", "18.4 gateway config changed NO degil"),
    (r184_db_mutation == "NO", "18.4 DB mutation NO degil"),
    (r185_smoke == "PASS", "18.5 live http smoke PASS degil"),
    (r185_gateway_reachable == "YES", "18.5 live gateway reachable YES degil"),
    (r185_auth_gate == "PASS", "18.5 auth gate PASS degil"),
    (r185_query_leak == "PASS", "18.5 query text leak PASS degil"),
    (r185_restart == "NO", "18.5 runtime restart NO degil"),
    (r185_gateway_changed == "NO", "18.5 gateway config changed NO degil"),
    (r185_nginx_changed == "NO", "18.5 nginx config changed NO degil"),
    (r185_db_mutation == "NO", "18.5 DB mutation NO degil"),
]

for ok, msg in checks:
    if not ok:
        fail(msg)

target_import_count = count_pattern(target, r"internal/platform/reporting/runtime")
target_call_count = count_pattern(target, r"reportingruntime\.RegisterReportingRoutes")

detail(f"TARGET_REPORTING_IMPORT_COUNT={target_import_count}")
detail(f"TARGET_REPORTING_REGISTER_CALL_COUNT={target_call_count}")

if target_import_count != 1:
    fail("target reporting import count 1 degil")
if target_call_count != 1:
    fail("target reporting register call count 1 degil")

if r185_auth_mode == "REAL_TOKEN_PROVIDED":
    if r185_200_count == "6" and r185_tenant_gate == "PASS" and r185_method_gate == "PASS":
        real_token_full_smoke_status = "PASS"
        live_route_security_status = "FULL_200_VERIFIED"
    else:
        real_token_full_smoke_status = "FAIL"
        live_route_security_status = "REAL_TOKEN_SMOKE_FAILED"
        fail("real token ile full 200/tenant/method smoke PASS degil")
else:
    if r185_protected_status == "PASS" and r185_auth_401_count == "6" and r185_404_count == "0":
        real_token_full_smoke_status = "DEFERRED_NO_VALID_TOKEN"
        live_route_security_status = "AUTH_PROTECTED"
    else:
        real_token_full_smoke_status = "FAIL"
        live_route_security_status = "AUTH_PROTECTED_EVIDENCE_FAILED"
        fail("token yokken auth-protected live route kaniti PASS degil")

detail(f"LIVE_ROUTE_SECURITY_STATUS={live_route_security_status}")
detail(f"REAL_TOKEN_FULL_SMOKE_STATUS={real_token_full_smoke_status}")

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

write_outputs()
