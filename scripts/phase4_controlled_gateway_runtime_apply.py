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
apply_runtime = os.environ.get("APPLY_REPORTING_RUNTIME", "1").strip()

report_dir = root / "docs/phase4"
report_dir.mkdir(parents=True, exist_ok=True)

standard_file = report_dir / "18_4_controlled_gateway_runtime_apply_standard.md"
report_file = report_dir / "18_4_controlled_gateway_runtime_apply_report.md"
inventory_file = report_dir / "18_4_controlled_gateway_runtime_apply_inventory.tsv"
matrix_file = report_dir / "18_4_controlled_gateway_runtime_apply_matrix.tsv"

r183 = report_dir / "18_3_gateway_route_controlled_apply_gate_report.md"
r18_3_candidate = report_dir / "18_3_gateway_route_controlled_apply_candidate_execution.sh"
r17 = report_dir / "17_reporting_api_final_closure_report.md"

target_rel = "cmd/api-gateway/api_gateway_main.go"
target = root / target_rel
runtime_reg = root / "internal/platform/reporting/runtime/registration.go"
go_mod = root / "go.mod"

backup_stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = root / "backups" / f"faz4_18_4_runtime_apply_file_backup_{backup_stamp}"
backup_target = backup_dir / target_rel

go_test_file = Path("/tmp/pix2pi_18_4_controlled_gateway_runtime_apply_go_test.log")

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
    return len(re.findall(pattern, path.read_text(errors="ignore"), re.MULTILINE))

def run_cmd(cmd, outfile=None, append=False):
    if outfile:
        mode = "a" if append else "w"
        with outfile.open(mode) as f:
            proc = subprocess.run(cmd, cwd=root, stdout=f, stderr=subprocess.STDOUT, text=True)
    else:
        proc = subprocess.run(cmd, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    return proc.returncode == 0

def module_path():
    if not go_mod.exists():
        return ""
    for line in go_mod.read_text(errors="ignore").splitlines():
        line = line.strip()
        if line.startswith("module "):
            return line.split(None, 1)[1].strip()
    return ""

def add_import(src, import_line):
    if import_line in src:
        return src, False

    if re.search(r'import\s*\(', src):
        src2 = re.sub(r'import\s*\(', 'import (\n\t' + import_line, src, count=1)
        return src2, True

    single = re.search(r'(?m)^import\s+"([^"]+)"\s*$', src)
    if single:
        old = single.group(0)
        existing = single.group(1)
        new = f'import (\n\t"{existing}"\n\t{import_line}\n)'
        return src.replace(old, new, 1), True

    pkg = re.search(r'(?m)^package\s+main\s*$', src)
    if pkg:
        insert_at = pkg.end()
        src2 = src[:insert_at] + "\n\nimport (\n\t" + import_line + "\n)" + src[insert_at:]
        return src2, True

    return src, False

def insert_register_call(src):
    if "reportingruntime.RegisterReportingRoutes" in src:
        return src, False, "ALREADY_APPLIED", ""

    patterns = [
        r'(?m)^(\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:=\s*http\.NewServeMux\(\)\s*$',
        r'(?m)^(\s*)var\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*http\.NewServeMux\(\)\s*$',
        r'(?m)^(\s*)([A-Za-z_][A-Za-z0-9_]*)\s*=\s*http\.NewServeMux\(\)\s*$',
    ]

    for pat in patterns:
        m = re.search(pat, src)
        if m:
            indent = m.group(1)
            mux_var = m.group(2)
            line_end = src.find("\n", m.end())
            if line_end == -1:
                line_end = len(src)
            snippet = (
                f"\n{indent}if err := reportingruntime.RegisterReportingRoutes({mux_var}); err != nil {{\n"
                f"{indent}\tpanic(err)\n"
                f"{indent}}}\n"
            )
            return src[:line_end] + snippet + src[line_end:], True, "MUX_VAR", mux_var

    if "http.HandleFunc(" in src or "http.DefaultServeMux" in src:
        m = re.search(r'(?m)^(\s*)func\s+main\s*\(\)\s*\{\s*$', src)
        if m:
            indent = m.group(1) + "\t"
            line_end = src.find("\n", m.end())
            if line_end == -1:
                line_end = len(src)
            snippet = (
                f"\n{indent}if err := reportingruntime.RegisterReportingRoutes(http.DefaultServeMux); err != nil {{\n"
                f"{indent}\tpanic(err)\n"
                f"{indent}}}\n"
            )
            return src[:line_end] + snippet + src[line_end:], True, "DEFAULT_SERVEMUX", "http.DefaultServeMux"

    return src, False, "NO_SAFE_INSERTION_POINT", ""

def report_and_exit():
    inventory_lines = [
        "item\tstatus\tnote",
        f"target_file\t{'FOUND' if target.exists() else 'NOT_FOUND'}\t{target_rel}",
        f"runtime_registration\t{'FOUND' if runtime_reg.exists() else 'NOT_FOUND'}\tinternal/platform/reporting/runtime/registration.go",
        f"backup_file\t{'CREATED' if backup_target.exists() else 'NOT_CREATED'}\t{backup_target.relative_to(root) if backup_target.exists() else 'NA'}",
        f"module_path\t{'FOUND' if module else 'NOT_FOUND'}\t{module}",
        f"import_path\t{'SET' if import_path else 'NOT_SET'}\t{import_path}",
        f"patch_mode\t{patch_mode}\tinsert_strategy={insert_strategy}",
        f"gateway_code_changed\t{gateway_code_changed}\tbefore={target_sha_before} after={target_sha_after}",
        f"reporting_import_count_after\t{import_count_after}\texpected=1",
        f"reporting_register_call_count_after\t{register_call_count_after}\texpected=1",
        f"gofmt_status\t{gofmt_status}\ttarget={target_rel}",
        f"reporting_go_test_suite\t{reporting_go_test_suite}\tinternal/platform/reporting",
        f"api_gateway_go_test_status\t{api_gateway_go_test_status}\tcmd/api-gateway",
        f"rollback_ready\t{'YES' if backup_target.exists() else 'NO'}\trestore backup target file",
    ]
    inventory_file.write_text("\n".join(inventory_lines) + "\n")
    detail(f"CONTROLLED_APPLY_INVENTORY_LINE_COUNT={len(inventory_lines)}")

    matrix_lines = [
        "gate\tstatus\tnote",
        f"previous_18_3_gate\t{r183_gate}\tapply_gate_ready={r183_ready}",
        f"previous_17_final\t{r17_final}\treporting api closure",
        f"target_file\t{'FOUND' if target.exists() else 'NOT_FOUND'}\t{target_rel}",
        f"backup_created\t{'YES' if backup_target.exists() else 'NO'}\t{backup_target.relative_to(root) if backup_target.exists() else 'NA'}",
        f"patch_applied\t{patch_applied}\tmode={patch_mode}",
        f"reporting_import_after\t{import_count_after}\texpected=1",
        f"reporting_register_call_after\t{register_call_count_after}\texpected=1",
        f"gofmt\t{gofmt_status}\tgo format target",
        f"reporting_go_test_suite\t{reporting_go_test_suite}\tinternal reporting tests",
        f"api_gateway_go_test\t{api_gateway_go_test_status}\tapi gateway tests",
        "runtime_started\tNO\tno live runtime start in 18.4",
        "gateway_config_changed\tNO\tcode only, no nginx/gateway config",
        "db_mutation\tNO\tno database mutation",
        f"controlled_apply\t{'PASS' if not failures else 'FAIL'}\tfailures={len(failures)} warnings={len(warnings)}",
    ]
    matrix_file.write_text("\n".join(matrix_lines) + "\n")
    detail(f"CONTROLLED_APPLY_MATRIX_LINE_COUNT={len(matrix_lines)}")

    detail(f"CONTROLLED_GATEWAY_RUNTIME_APPLY={'PASS' if not failures else 'FAIL'}")

    report_lines = [
        "# FAZ 4 / 18.4 - Controlled Gateway Runtime Apply Report",
        "",
        f"Generated at: {now()}",
        "",
        "## Summary",
        *details,
        f"FAIL_COUNT={len(failures)}",
        f"WARN_COUNT={len(warnings)}",
        f"CONTROLLED_GATEWAY_RUNTIME_APPLY={'PASS' if not failures else 'FAIL'}",
        "",
        "## Tool Status",
        *tools,
        "",
        "## Controlled Apply Inventory",
        "INVENTORY_FILE=docs/phase4/18_4_controlled_gateway_runtime_apply_inventory.tsv",
        inventory_file.read_text(errors="ignore").rstrip(),
        "",
        "## Controlled Apply Matrix",
        "MATRIX_FILE=docs/phase4/18_4_controlled_gateway_runtime_apply_matrix.tsv",
        matrix_file.read_text(errors="ignore").rstrip(),
        "",
        "## Go Test Output",
        "\n".join(go_test_file.read_text(errors="ignore").splitlines()[:520]) if go_test_file.exists() else "go test output yok",
        "",
        "## Rollback Plan",
        f"ROLLBACK_SOURCE={backup_target.relative_to(root) if backup_target.exists() else 'NA'}",
        f"ROLLBACK_TARGET={target_rel}",
        "ROLLBACK_COMMAND=cp -a \"$ROLLBACK_SOURCE\" \"$ROLLBACK_TARGET\" && gofmt -w \"$ROLLBACK_TARGET\"",
        "",
        "## Safety Decision",
        "APPLY_EXECUTED=YES",
        f"APPLY_REPORTING_RUNTIME={apply_runtime}",
        "DB_MUTATION=NO",
        "DB_MIGRATION_CREATED=NO",
        "DB_APPLY_EXECUTED=NO",
        f"SERVICE_CODE_CHANGED={gateway_code_changed}",
        "HTTP_HANDLER_CREATED=NO_NEW_HANDLER",
        f"ROUTE_REGISTRATION_CREATED={patch_applied}",
        "REPORTING_RUNTIME_STARTED=NO",
        "SERVICE_RUNTIME_STARTED=NO",
        "PORT_OPENED=NO",
        "LISTEN_AND_SERVE_USED=NO_NEW_LISTEN",
        "GATEWAY_CONFIG_CHANGED=NO",
        "NGINX_CONFIG_CHANGED=NO",
        "POSTGRES_CONFIG_CHANGED=NO",
        "CONTAINER_RESTARTED=NO",
        "QUERY_TEXT_PRINTED=NO",
        "APPLY_MODE=CONTROLLED_CODE_PATCH_ONLY",
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
    print(f"FAIL_COUNT={len(failures)}")
    print(f"WARN_COUNT={len(warnings)}")
    print(f"PATCH_MODE={patch_mode}")
    print(f"PATCH_APPLIED={patch_applied}")
    print(f"GATEWAY_CODE_CHANGED={gateway_code_changed}")
    print(f"REPORTING_RUNTIME_IMPORT_COUNT_AFTER={import_count_after}")
    print(f"REPORTING_RUNTIME_REGISTER_CALL_COUNT_AFTER={register_call_count_after}")
    print(f"GOFMT_STATUS={gofmt_status}")
    print(f"REPORTING_GO_TEST_SUITE={reporting_go_test_suite}")
    print(f"API_GATEWAY_GO_TEST_STATUS={api_gateway_go_test_status}")
    print("REPORTING_RUNTIME_STARTED=NO")
    print("GATEWAY_CONFIG_CHANGED=NO")
    print("DB_MUTATION=NO")

    if failures:
        print("CONTROLLED_GATEWAY_RUNTIME_APPLY=FAIL ❌")
        sys.exit(1)

    print("CONTROLLED_GATEWAY_RUNTIME_APPLY=PASS ✅")

detail(f"ROOT_DIR={root}")
detail(f"APPLY_REPORTING_RUNTIME={apply_runtime}")
detail("APPLY_EXECUTED=YES")
detail("DB_MUTATION=NO")
detail("DB_MIGRATION_CREATED=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("REPORTING_RUNTIME_STARTED=NO")
detail("SERVICE_RUNTIME_STARTED=NO")
detail("PORT_OPENED=NO")
detail("GATEWAY_CONFIG_CHANGED=NO")
detail("NGINX_CONFIG_CHANGED=NO")
detail("POSTGRES_CONFIG_CHANGED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("QUERY_TEXT_PRINTED=NO")
detail("APPLY_MODE=CONTROLLED_CODE_PATCH_ONLY")

tool_status("go")
tool_status("gofmt")
tool_status("python3")
tool_status("grep")
tool_status("sha256sum")

if not standard_file.exists():
    fail("18.4 standard doc yok")

r183_gate = get_value(r183, "GATEWAY_ROUTE_CONTROLLED_APPLY_GATE")
r183_ready = get_value(r183, "APPLY_GATE_READY")
r183_target = get_value(r183, "SELECTED_ENTRY_TARGET")
r183_kind = get_value(r183, "SELECTED_ENTRY_TARGET_KIND")
r183_reporting_test = get_value(r183, "REPORTING_GO_TEST_SUITE")
r183_api_gateway_test = get_value(r183, "API_GATEWAY_GO_TEST_STATUS")
r183_apply_executed = get_value(r183, "APPLY_EXECUTED")
r183_runtime_started = get_value(r183, "REPORTING_RUNTIME_STARTED")
r183_gateway_changed = get_value(r183, "GATEWAY_CONFIG_CHANGED")
r183_db_mutation = get_value(r183, "DB_MUTATION")

r17_final = get_value(r17, "FAZ4_17_FINAL_STATUS")
r17_closure = get_value(r17, "REPORTING_API_FINAL_CLOSURE")

detail(f"PREVIOUS_18_3_GATEWAY_ROUTE_CONTROLLED_APPLY_GATE={r183_gate}")
detail(f"PREVIOUS_18_3_APPLY_GATE_READY={r183_ready}")
detail(f"PREVIOUS_18_3_SELECTED_ENTRY_TARGET={r183_target}")
detail(f"PREVIOUS_18_3_SELECTED_ENTRY_TARGET_KIND={r183_kind}")
detail(f"PREVIOUS_18_3_REPORTING_GO_TEST_SUITE={r183_reporting_test}")
detail(f"PREVIOUS_18_3_API_GATEWAY_GO_TEST_STATUS={r183_api_gateway_test}")
detail(f"PREVIOUS_18_3_APPLY_EXECUTED={r183_apply_executed}")
detail(f"PREVIOUS_18_3_REPORTING_RUNTIME_STARTED={r183_runtime_started}")
detail(f"PREVIOUS_18_3_GATEWAY_CONFIG_CHANGED={r183_gateway_changed}")
detail(f"PREVIOUS_18_3_DB_MUTATION={r183_db_mutation}")
detail(f"PREVIOUS_17_FINAL_STATUS={r17_final}")
detail(f"PREVIOUS_17_REPORTING_API_FINAL_CLOSURE={r17_closure}")

checks = [
    (r183_gate == "PASS", "18.3 apply gate PASS degil"),
    (r183_ready == "YES", "18.3 apply gate ready YES degil"),
    (r183_target == target_rel, "18.3 selected target beklenen api-gateway degil"),
    (r183_kind == "API_GATEWAY", "18.3 selected target kind API_GATEWAY degil"),
    (r183_reporting_test == "PASS", "18.3 reporting go test PASS degil"),
    (r183_api_gateway_test == "PASS", "18.3 api gateway go test PASS degil"),
    (r183_apply_executed == "NO", "18.3 apply executed NO degil"),
    (r183_runtime_started == "NO", "18.3 runtime started NO degil"),
    (r183_gateway_changed == "NO", "18.3 gateway config changed NO degil"),
    (r183_db_mutation == "NO", "18.3 DB mutation NO degil"),
    (r17_final == "PASS", "17 final status PASS degil"),
    (r17_closure == "PASS", "17 closure PASS degil"),
]
for ok, msg in checks:
    if not ok:
        fail(msg)

module = module_path()
import_path = f'{module}/internal/platform/reporting/runtime' if module else ""
import_line = f'reportingruntime "{import_path}"' if import_path else ""

target_sha_before = sha256(target)
target_sha_after = "NA"
patch_mode = "NOT_RUN"
patch_applied = "NO"
gateway_code_changed = "NO"
insert_strategy = "NA"
gofmt_status = "SKIPPED"
reporting_go_test_suite = "SKIPPED"
api_gateway_go_test_status = "SKIPPED"
import_count_after = 0
register_call_count_after = 0

detail(f"SELECTED_ENTRY_TARGET={target_rel}")
detail("SELECTED_ENTRY_TARGET_KIND=API_GATEWAY")
detail(f"TARGET_FILE_STATUS={'FOUND' if target.exists() else 'NOT_FOUND'}")
detail(f"RUNTIME_REGISTRATION_FILE_STATUS={'FOUND' if runtime_reg.exists() else 'NOT_FOUND'}")
detail(f"TARGET_SHA256_BEFORE={target_sha_before}")
detail(f"MODULE_PATH={module}")
detail(f"REPORTING_RUNTIME_IMPORT_PATH={import_path}")

if apply_runtime != "1":
    fail("APPLY_REPORTING_RUNTIME 1 degil; controlled apply calistirilmadi")

if not module:
    fail("go.mod module path bulunamadi")
if not target.exists():
    fail("api gateway target dosyasi yok")
if not runtime_reg.exists():
    fail("reporting runtime registration dosyasi yok")
if not import_path:
    fail("reporting runtime import path uretilemedi")

if failures:
    report_and_exit()

backup_target.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(target, backup_target)
detail(f"BACKUP_FILE={backup_target.relative_to(root)}")
detail(f"BACKUP_CREATED=YES")

src_before = target.read_text(errors="ignore")
src = src_before

already_import = import_path in src
already_call = "reportingruntime.RegisterReportingRoutes" in src

if already_import and already_call:
    patch_mode = "NOOP_ALREADY_APPLIED"
    patch_applied = "NOOP_ALREADY_APPLIED"
    insert_strategy = "ALREADY_APPLIED"
else:
    src, import_added = add_import(src, import_line)
    src, call_added, insert_strategy, mux_symbol = insert_register_call(src)

    if not call_added and insert_strategy != "ALREADY_APPLIED":
        fail("api-gateway icinde guvenli mux/http.DefaultServeMux insertion point bulunamadi")
        patch_mode = "FAILED_NO_SAFE_INSERTION_POINT"
    else:
        patch_mode = "PATCHED"
        patch_applied = "YES"
        detail(f"INSERT_STRATEGY={insert_strategy}")
        detail(f"INSERT_SYMBOL={mux_symbol}")
        target.write_text(src)

if not failures:
    if run_cmd(["gofmt", "-w", str(target)]):
        gofmt_status = "PASS"
    else:
        gofmt_status = "FAIL"
        fail("gofmt failed")

target_sha_after = sha256(target)
gateway_code_changed = "YES" if target_sha_after != target_sha_before else "NO"
detail(f"TARGET_SHA256_AFTER={target_sha_after}")
detail(f"PATCH_MODE={patch_mode}")
detail(f"PATCH_APPLIED={patch_applied}")
detail(f"GATEWAY_CODE_CHANGED={gateway_code_changed}")
detail(f"GOFMT_STATUS={gofmt_status}")

import_count_after = count_pattern(target, re.escape(import_path))
register_call_count_after = count_pattern(target, r"reportingruntime\.RegisterReportingRoutes")

detail(f"REPORTING_RUNTIME_IMPORT_COUNT_AFTER={import_count_after}")
detail(f"REPORTING_RUNTIME_REGISTER_CALL_COUNT_AFTER={register_call_count_after}")

if import_count_after != 1:
    fail("reporting runtime import count after 1 degil")
if register_call_count_after != 1:
    fail("reporting runtime register call count after 1 degil")

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

report_and_exit()
