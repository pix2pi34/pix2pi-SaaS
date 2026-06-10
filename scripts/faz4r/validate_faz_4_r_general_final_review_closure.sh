#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_r_general_final_review_closure.v1.json}"
CLOSURE_FILE="${CLOSURE_FILE:-configs/faz4r/faz_4_r_general_final_review_closure_manifest.v1.json}"
LIVE_HTML_EVIDENCE="${LIVE_HTML_EVIDENCE:-docs/faz4r/evidence/FAZ_4_R_LIVE_HTML_PUBLISH_AUDIT.md}"
LIVE_HTML_MANIFEST="${LIVE_HTML_MANIFEST:-configs/faz4r/faz4r_live_html_publish_manifest.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "FAZ_4_R_GENERAL_FINAL_REVIEW_ERROR=$1"
  exit 1
}

[ -f "$CONFIG_FILE" ] || fail "CONFIG_FILE_NOT_FOUND"
[ -f "$CLOSURE_FILE" ] || fail "CLOSURE_FILE_NOT_FOUND"
[ -f "$LIVE_HTML_EVIDENCE" ] || fail "LIVE_HTML_EVIDENCE_NOT_FOUND"
[ -f "$LIVE_HTML_MANIFEST" ] || fail "LIVE_HTML_MANIFEST_NOT_FOUND"

if [ -z "$INPUT_FILE" ]; then INPUT_FILE="$CLOSURE_FILE"; fi
[ -f "$INPUT_FILE" ] || fail "INPUT_FILE_NOT_FOUND"
command -v python3 >/dev/null 2>&1 || fail "PYTHON3_NOT_FOUND"

python3 - "$CONFIG_FILE" "$INPUT_FILE" "$LIVE_HTML_EVIDENCE" "$LIVE_HTML_MANIFEST" <<'PY_EOF'
import json
import sys
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text())
payload = json.loads(Path(sys.argv[2]).read_text())
live_evidence = Path(sys.argv[3]).read_text(errors="ignore")
live_manifest = json.loads(Path(sys.argv[4]).read_text())
errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

policy = config.get("closure_policy", {})

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("step") == "GENERAL_FINAL_REVIEW_CLOSURE", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CONFIG_CLOSED_POLICY_MISSING")

require(payload.get("phase") == "FAZ_4_R", "PAYLOAD_PHASE_INVALID")
require(payload.get("closure_status") == "SEALED", "CLOSURE_STATUS_NOT_SEALED")
require(payload.get("closure_mode") == "GENERAL_FINAL_REVIEW", "CLOSURE_MODE_INVALID")

groups = payload.get("priority_groups", [])
require(isinstance(groups, list), "PRIORITY_GROUPS_NOT_LIST")
require(len(groups) == 4, "PRIORITY_GROUP_COUNT_INVALID")

all_items = []
for group in groups:
    require(group.get("status") == policy.get("priority_status_required"), f"PRIORITY_{group.get('priority')}_NOT_SEALED")
    items = group.get("items", [])
    require(isinstance(items, list), f"PRIORITY_{group.get('priority')}_ITEMS_NOT_LIST")
    require(group.get("item_count") == len(items), f"PRIORITY_{group.get('priority')}_ITEM_COUNT_MISMATCH")
    for item in items:
        all_items.append(item)
        require(item.get("status") == "SEALED", f"ITEM_NOT_SEALED:{item.get('no')}_{item.get('code')}")
        require(isinstance(item.get("no"), int), f"ITEM_NO_INVALID:{item}")
        require(isinstance(item.get("code"), str) and item.get("code").startswith("FAZ_4_"), f"ITEM_CODE_INVALID:{item}")

item_numbers = [item.get("no") for item in all_items]
require(len(all_items) == policy.get("total_item_count_required"), "TOTAL_ITEM_COUNT_INVALID")
require(len(set(item_numbers)) == len(item_numbers), "DUPLICATE_ITEM_NO_FOUND")
require(min(item_numbers) == 180, "MIN_ITEM_NO_INVALID")
require(max(item_numbers) == 241, "MAX_ITEM_NO_INVALID")

summary = payload.get("summary", {})
remaining = payload.get("remaining_work", {})
quality = payload.get("quality_gates", {})
closed = payload.get("closed_policy_gates", {})
live_html = payload.get("live_html", {})

require(summary.get("total_item_count") == policy.get("total_item_count_required"), "SUMMARY_TOTAL_ITEM_COUNT_INVALID")
require(summary.get("sealed_item_count") == policy.get("sealed_item_count_required"), "SUMMARY_SEALED_ITEM_COUNT_INVALID")
require(summary.get("partial_item_count") == policy.get("partial_item_count_required"), "SUMMARY_PARTIAL_ITEM_COUNT_NOT_ZERO")
require(summary.get("pending_item_count") == policy.get("pending_item_count_required"), "SUMMARY_PENDING_ITEM_COUNT_NOT_ZERO")
require(summary.get("fail_item_count") == policy.get("fail_item_count_required"), "SUMMARY_FAIL_ITEM_COUNT_NOT_ZERO")
require(summary.get("faz_4_r_general_final_review_status") == "PASS", "FINAL_REVIEW_STATUS_NOT_PASS")
require(summary.get("faz_4_r_final_closure_status") == "SEALED", "FINAL_CLOSURE_STATUS_NOT_SEALED")
require(summary.get("faz_4_r_ready_for_next_phase") == "YES", "NEXT_PHASE_READY_NOT_YES")

require(remaining.get("partial_item_count") == 0, "PARTIAL_ITEM_COUNT_NOT_ZERO")
require(remaining.get("pending_item_count") == 0, "PENDING_ITEM_COUNT_NOT_ZERO")
require(remaining.get("fail_item_count") == 0, "FAIL_ITEM_COUNT_NOT_ZERO")
require(remaining.get("partial_remaining") == "NO", "PARTIAL_REMAINING_NOT_NO")
require(remaining.get("pending_remaining") == "NO", "PENDING_REMAINING_NOT_NO")
require(remaining.get("fail_remaining") == "NO", "FAIL_REMAINING_NOT_NO")

require(quality.get("required_fail_count") == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
require(quality.get("optional_warn_count") == policy.get("optional_warn_count_required"), "OPTIONAL_WARN_COUNT_NOT_ZERO")
for key in ["priority_1_status", "priority_2_status", "priority_3_status", "priority_4_status"]:
    require(quality.get(key) == "SEALED", f"{key.upper()}_NOT_SEALED")

require(live_html.get("publish_status") == policy.get("live_html_publish_status_required"), "LIVE_HTML_PUBLISH_STATUS_NOT_PASS")
require(live_html.get("html_live_ready") == policy.get("live_html_ready_required"), "LIVE_HTML_READY_NOT_YES")
require(live_html.get("required_live_html_count", 0) >= policy.get("minimum_required_live_html_count"), "REQUIRED_LIVE_HTML_COUNT_TOO_LOW")
require(live_html.get("published_count", 0) >= policy.get("minimum_required_live_html_count"), "PUBLISHED_COUNT_TOO_LOW")

require("FAZ_4_R_LIVE_HTML_PUBLISH_STATUS=PASS" in live_evidence, "LIVE_HTML_EVIDENCE_PASS_MARKER_MISSING")
require("FAZ_4_R_HTML_LIVE_READY=YES" in live_evidence, "LIVE_HTML_READY_MARKER_MISSING")
require(live_manifest.get("status") == "READY", "LIVE_HTML_MANIFEST_STATUS_NOT_READY")
require(live_manifest.get("missing_required_html") == [], "LIVE_HTML_MANIFEST_MISSING_REQUIRED_HTML")
require(live_manifest.get("published_count", 0) >= policy.get("minimum_required_live_html_count"), "LIVE_HTML_MANIFEST_PUBLISHED_COUNT_TOO_LOW")

require(closed.get("closed_policy_reference") == policy.get("closed_policy_reference_required"), "CLOSED_POLICY_REFERENCE_INVALID")
require(closed.get("production_launch_status") == policy.get("production_launch_status_required"), "PRODUCTION_LAUNCH_NOT_CLOSED")
require(closed.get("live_external_provider_status") == policy.get("live_external_provider_status_required"), "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(closed.get("gib_live_status") == policy.get("gib_live_status_required"), "GIB_LIVE_NOT_CLOSED")
require(closed.get("bank_live_status") == policy.get("bank_live_status_required"), "BANK_LIVE_NOT_CLOSED")
require(closed.get("pos_live_status") == policy.get("pos_live_status_required"), "POS_LIVE_NOT_CLOSED")
require(closed.get("payment_live_status") == policy.get("payment_live_status_required"), "PAYMENT_LIVE_NOT_CLOSED")

# Evidence code coverage scan: closure evidence itself is not needed here; existing phase evidence must contain each code.
evidence_dir = Path("docs/faz4r/evidence")
evidence_corpus = ""
if evidence_dir.exists():
    for p in sorted(evidence_dir.glob("*.md")):
        if p.name == "FAZ_4_R_GENERAL_FINAL_REVIEW_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md":
            continue
        evidence_corpus += "\n" + p.name + "\n" + p.read_text(errors="ignore")

missing_codes = []
for item in all_items:
    code = item["code"]
    if code not in evidence_corpus:
        missing_codes.append(f"{item['no']}:{code}")

require(not missing_codes, "MISSING_PHASE_EVIDENCE_CODES:" + ",".join(missing_codes[:20]))

if errors:
    print("FAZ_4_R_GENERAL_FINAL_REVIEW_STATUS=FAIL")
    print(f"FAZ_4_R_GENERAL_FINAL_REVIEW_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"FAZ_4_R_GENERAL_FINAL_REVIEW_FAIL={error}")
    sys.exit(1)

print("FAZ_4_R_GENERAL_FINAL_REVIEW_STATUS=PASS")
print("FAZ_4_R_FINAL_CLOSURE_STATUS=SEALED")
print(f"FAZ_4_R_TOTAL_ITEM_COUNT={summary.get('total_item_count')}")
print(f"FAZ_4_R_SEALED_ITEM_COUNT={summary.get('sealed_item_count')}")
print("FAZ_4_R_PARTIAL_ITEM_COUNT=0")
print("FAZ_4_R_PENDING_ITEM_COUNT=0")
print("FAZ_4_R_FAIL_ITEM_COUNT=0")
print("FAZ_4_R_PRIORITY_1_STATUS=SEALED")
print("FAZ_4_R_PRIORITY_2_STATUS=SEALED")
print("FAZ_4_R_PRIORITY_3_STATUS=SEALED")
print("FAZ_4_R_PRIORITY_4_STATUS=SEALED")
print("FAZ_4_R_LIVE_HTML_PUBLISH_STATUS=PASS")
print("FAZ_4_R_HTML_LIVE_READY=YES")
print("FAZ_4_R_PARTIAL_REMAINING=NO")
print("FAZ_4_R_PENDING_REMAINING=NO")
print("FAZ_4_R_FAIL_REMAINING=NO")
print("FAZ_4_R_READY_FOR_NEXT_PHASE=YES")
print("FAZ_4_R_CLOSED_POLICY_REFERENCE=CLOSED_POLICY_GATE_REFERENCE_ONLY")
PY_EOF
