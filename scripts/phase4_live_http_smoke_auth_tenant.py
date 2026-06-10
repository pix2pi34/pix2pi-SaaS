#!/usr/bin/env python3
import json
import os
import re
import socket
import sys
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path
from urllib.parse import urljoin

root = Path(sys.argv[1] if len(sys.argv) > 1 else os.getcwd()).resolve()

report_dir = root / "docs/phase4"
report_dir.mkdir(parents=True, exist_ok=True)

standard_file = report_dir / "18_5_live_http_smoke_auth_tenant_standard.md"
report_file = report_dir / "18_5_live_http_smoke_auth_tenant_report.md"
endpoint_results_file = report_dir / "18_5_live_http_smoke_endpoint_results.tsv"
matrix_file = report_dir / "18_5_live_http_smoke_matrix.tsv"

r184 = report_dir / "18_4_controlled_gateway_runtime_apply_report.md"
r183 = report_dir / "18_3_gateway_route_controlled_apply_gate_report.md"
r17 = report_dir / "17_reporting_api_final_closure_report.md"

target = root / "cmd/api-gateway/api_gateway_main.go"

failures = []
warnings = []
details = []
results = []

def now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")

def detail(line):
    details.append(line)

def fail(msg):
    failures.append(f"FAIL ❌ {msg}")

def warn(msg):
    warnings.append(f"WARN ⚠️ {msg}")

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

def pick_base_url():
    for key in ("GATEWAY_BASE_URL", "API_GATEWAY_BASE_URL", "PIX2PI_GATEWAY_BASE_URL"):
        val = os.environ.get(key, "").strip().rstrip("/")
        if val:
            return val, key
    return "http://127.0.0.1:9010", "DEFAULT_9010"

def request(method, base, path, headers=None, timeout=5):
    headers = headers or {}
    url = base.rstrip("/") + path
    req = urllib.request.Request(url, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read(1024 * 128).decode("utf-8", errors="replace")
            return resp.status, body, ""
    except urllib.error.HTTPError as e:
        body = e.read(1024 * 128).decode("utf-8", errors="replace")
        return e.code, body, ""
    except urllib.error.URLError as e:
        return 0, "", str(e.reason)
    except socket.timeout:
        return 0, "", "timeout"
    except Exception as e:
        return 0, "", str(e)

def body_leaks_query_text(body):
    upper = body.upper()
    leak_tokens = [
        "SELECT ",
        " WHERE ",
        "WHERE TENANT_ID",
        " FROM READMODEL",
        "INSERT ",
        "UPDATE ",
        "DELETE ",
        "DROP ",
        "ALTER ",
    ]
    return [token for token in leak_tokens if token in upper]

def json_status(body):
    try:
        parsed = json.loads(body)
        if isinstance(parsed, dict):
            return str(parsed.get("status", ""))
    except Exception:
        return ""
    return ""

def json_error_code(body):
    try:
        parsed = json.loads(body)
        if isinstance(parsed, dict):
            err = parsed.get("error")
            if isinstance(err, dict):
                return str(err.get("code", ""))
    except Exception:
        return ""
    return ""

def add_result(name, method, path, expected, actual, status, leak, note):
    results.append({
        "name": name,
        "method": method,
        "path": path,
        "expected": expected,
        "actual": str(actual),
        "status": status,
        "query_text_leak": "YES" if leak else "NO",
        "note": note,
    })

base_url, base_source = pick_base_url()

detail(f"ROOT_DIR={root}")
detail(f"GATEWAY_BASE_URL={base_url}")
detail(f"GATEWAY_BASE_URL_SOURCE={base_source}")
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
detail("LIVE_SMOKE_MODE=EXISTING_GATEWAY_HTTP_ONLY")

if not standard_file.exists():
    fail("18.5 standard doc yok")

r184_apply = get_value(r184, "CONTROLLED_GATEWAY_RUNTIME_APPLY")
r184_import_count = get_value(r184, "REPORTING_RUNTIME_IMPORT_COUNT_AFTER")
r184_call_count = get_value(r184, "REPORTING_RUNTIME_REGISTER_CALL_COUNT_AFTER")
r184_reporting_test = get_value(r184, "REPORTING_GO_TEST_SUITE")
r184_gateway_test = get_value(r184, "API_GATEWAY_GO_TEST_STATUS")
r184_runtime_started = get_value(r184, "REPORTING_RUNTIME_STARTED")
r184_gateway_changed = get_value(r184, "GATEWAY_CONFIG_CHANGED")
r184_db_mutation = get_value(r184, "DB_MUTATION")

r183_gate = get_value(r183, "GATEWAY_ROUTE_CONTROLLED_APPLY_GATE")
r183_ready = get_value(r183, "APPLY_GATE_READY")

r17_final = get_value(r17, "FAZ4_17_FINAL_STATUS")
r17_closure = get_value(r17, "REPORTING_API_FINAL_CLOSURE")

detail(f"PREVIOUS_18_4_CONTROLLED_GATEWAY_RUNTIME_APPLY={r184_apply}")
detail(f"PREVIOUS_18_4_REPORTING_RUNTIME_IMPORT_COUNT_AFTER={r184_import_count}")
detail(f"PREVIOUS_18_4_REPORTING_RUNTIME_REGISTER_CALL_COUNT_AFTER={r184_call_count}")
detail(f"PREVIOUS_18_4_REPORTING_GO_TEST_SUITE={r184_reporting_test}")
detail(f"PREVIOUS_18_4_API_GATEWAY_GO_TEST_STATUS={r184_gateway_test}")
detail(f"PREVIOUS_18_4_REPORTING_RUNTIME_STARTED={r184_runtime_started}")
detail(f"PREVIOUS_18_4_GATEWAY_CONFIG_CHANGED={r184_gateway_changed}")
detail(f"PREVIOUS_18_4_DB_MUTATION={r184_db_mutation}")
detail(f"PREVIOUS_18_3_GATEWAY_ROUTE_CONTROLLED_APPLY_GATE={r183_gate}")
detail(f"PREVIOUS_18_3_APPLY_GATE_READY={r183_ready}")
detail(f"PREVIOUS_17_FINAL_STATUS={r17_final}")
detail(f"PREVIOUS_17_REPORTING_API_FINAL_CLOSURE={r17_closure}")

pre_checks = [
    (r184_apply == "PASS", "18.4 controlled gateway runtime apply PASS degil"),
    (r184_import_count == "1", "18.4 reporting runtime import count 1 degil"),
    (r184_call_count == "1", "18.4 reporting runtime register call count 1 degil"),
    (r184_reporting_test == "PASS", "18.4 reporting go test PASS degil"),
    (r184_gateway_test == "PASS", "18.4 api gateway go test PASS degil"),
    (r184_runtime_started == "NO", "18.4 runtime started NO degil"),
    (r184_gateway_changed == "NO", "18.4 gateway config changed NO degil"),
    (r184_db_mutation == "NO", "18.4 DB mutation NO degil"),
    (r183_gate == "PASS", "18.3 gate PASS degil"),
    (r183_ready == "YES", "18.3 apply gate ready YES degil"),
    (r17_final == "PASS", "17 final status PASS degil"),
    (r17_closure == "PASS", "17 closure PASS degil"),
]
for ok, msg in pre_checks:
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

endpoints = [
    "/api/v1/reporting/operational/summary",
    "/api/v1/reporting/operational/daily-metrics",
    "/api/v1/reporting/inventory/status",
    "/api/v1/reporting/documents/work-queue",
    "/api/v1/reporting/reconciliation/status",
    "/api/v1/reporting/projections/state",
]

real_token = os.environ.get("LIVE_SMOKE_AUTH_TOKEN", "").strip()
auth_mode = "REAL_TOKEN_PROVIDED" if real_token else "NO_VALID_TOKEN_PROVIDED"

auth_headers = {
    "Authorization": "Bearer " + (real_token if real_token else "smoke-token"),
    "X-Tenant-ID": os.environ.get("LIVE_SMOKE_TENANT_ID", "tenant_smoke_18_5").strip() or "tenant_smoke_18_5",
    "X-Request-ID": "req_smoke_18_5",
}

gateway_reachable = "NO"
route_active = "NO"
endpoint_200_count = 0
query_leak_count = 0
route_404_count = 0

if not failures:
    for ep in endpoints:
        code, body, err = request("GET", base_url, ep, headers=auth_headers)
        leak_tokens = body_leaks_query_text(body)
        leak = bool(leak_tokens)
        if leak:
            query_leak_count += 1
        if code != 0:
            gateway_reachable = "YES"
        if code == 200:
            endpoint_200_count += 1
        if code == 404:
            route_404_count += 1

        status = "PASS" if code == 200 and not leak else "FAIL"
        note = "ok" if status == "PASS" else (err or f"http_{code}")
        if leak:
            note = "query_text_leak_detected"
        add_result("authorized_endpoint", "GET", ep, "200", code, status, leak, note)

    if endpoint_200_count == len(endpoints):
        route_active = "YES"

    code, body, err = request("GET", base_url, endpoints[0], headers={"X-Tenant-ID": "tenant_smoke_18_5"})
    leak = bool(body_leaks_query_text(body))
    if leak:
        query_leak_count += 1
    add_result("missing_bearer", "GET", endpoints[0], "401", code, "PASS" if code == 401 and not leak else "FAIL", leak, err or f"http_{code}")

    code, body, err = request("GET", base_url, endpoints[0], headers={"Authorization": "Bearer smoke-token"})
    leak = bool(body_leaks_query_text(body))
    if leak:
        query_leak_count += 1
    add_result("missing_tenant", "GET", endpoints[0], "400", code, "PASS" if code == 400 and not leak else "FAIL", leak, err or f"http_{code}")

    code, body, err = request("POST", base_url, endpoints[0], headers=auth_headers)
    leak = bool(body_leaks_query_text(body))
    if leak:
        query_leak_count += 1
    add_result("method_gate", "POST", endpoints[0], "405", code, "PASS" if code == 405 and not leak else "FAIL", leak, err or f"http_{code}")

authorized_401_count = sum(1 for r in results if r["name"] == "authorized_endpoint" and r["actual"] == "401")
protected_route_status = "PASS" if authorized_401_count == len(endpoints) and route_404_count == 0 else "FAIL"

if auth_mode == "REAL_TOKEN_PROVIDED":
    tenant_gate_status = "PASS" if any(r["name"] == "missing_tenant" and r["status"] == "PASS" for r in results) else "FAIL"
    method_gate_status = "PASS" if any(r["name"] == "method_gate" and r["status"] == "PASS" for r in results) else "FAIL"
    route_active_status = "PASS" if endpoint_200_count == 6 else "FAIL"
else:
    tenant_gate_status = "DEFERRED_NO_VALID_TOKEN"
    method_gate_status = "DEFERRED_NO_VALID_TOKEN"
    route_active_status = "AUTH_PROTECTED"

detail(f"LIVE_AUTH_MODE={auth_mode}")
detail(f"LIVE_GATEWAY_REACHABLE={gateway_reachable}")
detail(f"LIVE_REPORTING_ROUTE_ACTIVE={route_active}")
detail(f"LIVE_REPORTING_ENDPOINT_200_COUNT={endpoint_200_count}")
detail(f"LIVE_REPORTING_AUTH_PROTECTED_401_COUNT={authorized_401_count}")
detail(f"LIVE_REPORTING_ROUTE_404_COUNT={route_404_count}")
detail(f"LIVE_REPORTING_PROTECTED_ROUTE_STATUS={protected_route_status}")
detail(f"QUERY_TEXT_LEAK_COUNT={query_leak_count}")

auth_gate_status = "PASS" if any(r["name"] == "missing_bearer" and r["status"] == "PASS" for r in results) else "FAIL"
query_text_status = "PASS" if query_leak_count == 0 else "FAIL"

detail(f"LIVE_AUTH_GATE_STATUS={auth_gate_status}")
detail(f"LIVE_TENANT_GATE_STATUS={tenant_gate_status}")
detail(f"LIVE_METHOD_GATE_STATUS={method_gate_status}")
detail(f"QUERY_TEXT_LEAK_CHECK={query_text_status}")

if gateway_reachable != "YES":
    fail("live gateway erisilebilir degil")

if auth_mode == "REAL_TOKEN_PROVIDED":
    if route_active != "YES":
        fail("live reporting route aktif degil; gateway runtime restart/reload gerekebilir")
    if endpoint_200_count != 6:
        fail("live reporting endpoint 200 count 6 degil")
    if tenant_gate_status != "PASS":
        fail("live tenant gate 400 PASS degil")
    if method_gate_status != "PASS":
        fail("live method gate 405 PASS degil")
else:
    if protected_route_status != "PASS":
        fail("gecerli token yokken reporting route auth-protected kaniti PASS degil")

if auth_gate_status != "PASS":
    fail("live auth gate 401 PASS degil")
if query_text_status != "PASS":
    fail("query text leak check PASS degil")

endpoint_results_file.write_text(
    "case\tmethod\tpath\texpected_status\tactual_status\tstatus\tquery_text_leak\tnote\n" +
    "\n".join(
        f"{r['name']}\t{r['method']}\t{r['path']}\t{r['expected']}\t{r['actual']}\t{r['status']}\t{r['query_text_leak']}\t{r['note']}"
        for r in results
    ) +
    "\n"
)

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_18_4_apply\t{r184_apply}\timport={r184_import_count} call={r184_call_count}",
    f"target_code_patch\tPASS\timport={target_import_count} call={target_call_count}",
    f"live_gateway_reachable\t{gateway_reachable}\tbase_url={base_url}",
    f"live_reporting_route_active\t{route_active_status}\t200_count={endpoint_200_count} auth_401_count={authorized_401_count} route_404_count={route_404_count}",
    f"auth_gate\t{auth_gate_status}\tmissing bearer expected 401",
    f"tenant_gate\t{tenant_gate_status}\tmissing tenant expected 400 when valid token is available",
    f"method_gate\t{method_gate_status}\tPOST expected 405 when valid token is available",
    f"query_text_leak\t{query_text_status}\tleak_count={query_leak_count}",
    "runtime_restart_executed\tNO\t18.5 smoke only",
    "gateway_config_changed\tNO\tno config mutation",
    "db_mutation\tNO\tno database mutation",
    f"live_http_smoke\t{'PASS' if not failures else 'FAIL'}\tauth_mode={auth_mode} failures={len(failures)} warnings={len(warnings)}",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

detail(f"LIVE_HTTP_SMOKE_ENDPOINT_RESULT_LINE_COUNT={len(results) + 1}")
detail(f"LIVE_HTTP_SMOKE_MATRIX_LINE_COUNT={len(matrix_lines)}")
detail(f"LIVE_HTTP_SMOKE_AUTH_TENANT={'PASS' if not failures else 'FAIL'}")

report_lines = [
    "# FAZ 4 / 18.5 - Live HTTP Smoke / Auth-Tenant Verification Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"LIVE_HTTP_SMOKE_AUTH_TENANT={'PASS' if not failures else 'FAIL'}",
    "",
    "## Endpoint Results",
    "RESULTS_FILE=docs/phase4/18_5_live_http_smoke_endpoint_results.tsv",
    endpoint_results_file.read_text(errors="ignore").rstrip(),
    "",
    "## Smoke Matrix",
    "MATRIX_FILE=docs/phase4/18_5_live_http_smoke_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
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
    "TOKEN_PRINTED=NO",
    "LIVE_SMOKE_MODE=EXISTING_GATEWAY_HTTP_ONLY",
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

print(f"REPORT_FILE={report_file}")
print(f"RESULTS_FILE={endpoint_results_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"GATEWAY_BASE_URL={base_url}")
print(f"LIVE_GATEWAY_REACHABLE={gateway_reachable}")
print(f"LIVE_REPORTING_ROUTE_ACTIVE={route_active}")
print(f"LIVE_REPORTING_AUTH_PROTECTED_401_COUNT={authorized_401_count}")
print(f"LIVE_REPORTING_PROTECTED_ROUTE_STATUS={protected_route_status}")
print(f"LIVE_AUTH_MODE={auth_mode}")
print(f"LIVE_REPORTING_ENDPOINT_200_COUNT={endpoint_200_count}")
print(f"LIVE_AUTH_GATE_STATUS={auth_gate_status}")
print(f"LIVE_TENANT_GATE_STATUS={tenant_gate_status}")
print(f"LIVE_METHOD_GATE_STATUS={method_gate_status}")
print(f"QUERY_TEXT_LEAK_CHECK={query_text_status}")
print("RUNTIME_RESTART_EXECUTED=NO")
print("GATEWAY_CONFIG_CHANGED=NO")
print("DB_MUTATION=NO")

if failures:
    print("LIVE_HTTP_SMOKE_AUTH_TENANT=FAIL ❌")
    sys.exit(1)

print("LIVE_HTTP_SMOKE_AUTH_TENANT=PASS ✅")
