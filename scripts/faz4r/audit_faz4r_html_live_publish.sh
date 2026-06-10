#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

WEB_ROOT="${WEB_ROOT:-/var/www/pix2pi/live}"
DEST="${WEB_ROOT}/faz4r"
MANIFEST_FILE="configs/faz4r/faz4r_live_html_publish_manifest.json"
EVIDENCE_FILE="docs/faz4r/evidence/FAZ_4_R_LIVE_HTML_PUBLISH_AUDIT.md"

mkdir -p "docs/faz4r/evidence"

record_pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
record_fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo "$1 REQUIRED_FAIL / FAIL ❌"; }
record_warn() { WARN_COUNT=$((WARN_COUNT + 1)); echo "$1 OPTIONAL_WARN / WARN ⚠️"; }

check_file() {
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then record_pass "$label"; else record_fail "$label"; fi
}

check_dir() {
  local label="$1"
  local dir="$2"
  if [ -d "$dir" ]; then record_pass "$label"; else record_fail "$label"; fi
}

check_contains() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then record_pass "$label"; else record_fail "$label"; fi
}

check_manifest() {
  python3 - "$MANIFEST_FILE" <<'PY_EOF'
import json, sys
from pathlib import Path

p = Path(sys.argv[1])
if not p.exists():
    print("MANIFEST_CHECK=FAIL")
    print("MANIFEST_FAIL=FILE_NOT_FOUND")
    raise SystemExit(1)

data = json.loads(p.read_text())
errors = []

def req(cond, code):
    if not cond:
        errors.append(code)

req(data.get("phase") == "FAZ_4_R", "PHASE_INVALID")
req(data.get("status") == "READY", "STATUS_NOT_READY")
req(data.get("artifact") == "LIVE_HTML_PUBLISH_MANIFEST", "ARTIFACT_INVALID")
req(data.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_MISSING")
req(isinstance(data.get("published_count"), int) and data["published_count"] >= 5, "PUBLISHED_COUNT_TOO_LOW")
req(data.get("missing_required_html") == [], "MISSING_REQUIRED_HTML_NOT_EMPTY")

if errors:
    print("MANIFEST_CHECK=FAIL")
    for e in errors:
        print(f"MANIFEST_FAIL={e}")
    raise SystemExit(1)

print("MANIFEST_CHECK=PASS")
print(f"MANIFEST_PUBLISHED_COUNT={data.get('published_count')}")
PY_EOF
}

{
  echo "===== FAZ 4-R LIVE HTML PUBLISH AUDIT START ====="

  check_dir "web root directory exists" "$WEB_ROOT"
  check_dir "faz4r live directory exists" "$DEST"

  check_file "live index exists" "$DEST/index.html"
  check_file "manifest exists" "$MANIFEST_FILE"

  check_file "approval inbox live html exists" "$DEST/approval-inbox/index.html"
  check_file "workflow monitor live html exists" "$DEST/workflow-monitor/index.html"
  check_file "realtime health live html exists" "$DEST/realtime-health/index.html"
  check_file "realtime event feed live html exists" "$DEST/realtime-event-feed/index.html"
  check_file "notification center live html exists" "$DEST/notification-center/index.html"

  check_contains "live index marker" "$DEST/index.html" "FAZ_4_R_LIVE_HTML_INDEX"
  check_contains "live index closed policy marker" "$DEST/index.html" "CLOSED_POLICY_GATE_REFERENCE_ONLY"

  check_contains "approval inbox marker" "$DEST/approval-inbox/index.html" "FAZ_4_17_1_APPROVAL_INBOX_UI_CHECKPOINT"
  check_contains "workflow monitor marker" "$DEST/workflow-monitor/index.html" "FAZ_4_17_2_WORKFLOW_MONITOR_UI_CHECKPOINT"
  check_contains "realtime health marker" "$DEST/realtime-health/index.html" "FAZ_4_17_5_WEBSOCKET_SSE_HEALTH_UI_CHECKPOINT"
  check_contains "realtime event feed marker" "$DEST/realtime-event-feed/index.html" "FAZ_4_17_3_REALTIME_EVENT_FEED_UI_CHECKPOINT"
  check_contains "notification center marker" "$DEST/notification-center/index.html" "FAZ_4_17_4_NOTIFICATION_CENTER_UI_CHECKPOINT"

  check_contains "approval inbox title" "$DEST/approval-inbox/index.html" "Approval Inbox"
  check_contains "workflow monitor title" "$DEST/workflow-monitor/index.html" "Workflow Monitor"
  check_contains "realtime health title" "$DEST/realtime-health/index.html" "WebSocket / SSE Health"
  check_contains "realtime event feed title" "$DEST/realtime-event-feed/index.html" "Realtime Event Feed"
  check_contains "notification center title" "$DEST/notification-center/index.html" "Canlı Bildirim Merkezi"

  if check_manifest; then
    record_pass "manifest semantic validation"
  else
    record_fail "manifest semantic validation"
  fi

  if command -v curl >/dev/null 2>&1; then
    if curl -fsS --max-time 5 "http://127.0.0.1/faz4r/" >/tmp/faz4r_live_index_check.out 2>/tmp/faz4r_live_index_check.err; then
      record_pass "local nginx/http faz4r index reachable"
    else
      record_warn "local nginx/http faz4r index not reachable via 127.0.0.1, file publish still completed"
    fi
  else
    record_warn "curl not installed for optional local http check"
  fi

  echo "===== FAZ 4-R LIVE HTML PUBLISH COUNTER BASED FINAL STATUS ====="
  echo "PASS_COUNT=${PASS_COUNT}"
  echo "FAIL_COUNT=${FAIL_COUNT}"
  echo "WARN_COUNT=${WARN_COUNT}"
  echo "REQUIRED_FAIL=${FAIL_COUNT}"
  echo "OPTIONAL_WARN=${WARN_COUNT}"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_4_R_LIVE_HTML_PUBLISH_STATUS=PASS"
    echo "FAZ_4_R_HTML_LIVE_READY=YES"
    echo "FAZ_4_R_FINAL_REVIEW_CLOSURE_READY=YES"
    echo "PUBLIC_URL_INDEX=https://www.pix2pi.com.tr/faz4r/"
    echo "PUBLIC_URL_APPROVAL_INBOX=https://www.pix2pi.com.tr/faz4r/approval-inbox/"
    echo "PUBLIC_URL_WORKFLOW_MONITOR=https://www.pix2pi.com.tr/faz4r/workflow-monitor/"
    echo "PUBLIC_URL_REALTIME_HEALTH=https://www.pix2pi.com.tr/faz4r/realtime-health/"
    echo "PUBLIC_URL_REALTIME_EVENT_FEED=https://www.pix2pi.com.tr/faz4r/realtime-event-feed/"
    echo "PUBLIC_URL_NOTIFICATION_CENTER=https://www.pix2pi.com.tr/faz4r/notification-center/"
    AUDIT_RESULT=0
  else
    echo "FAZ_4_R_LIVE_HTML_PUBLISH_STATUS=FAIL"
    echo "FAZ_4_R_HTML_LIVE_READY=NO"
    echo "FAZ_4_R_FINAL_REVIEW_CLOSURE_READY=NO"
    AUDIT_RESULT=1
  fi

  exit "$AUDIT_RESULT"
} | tee "$EVIDENCE_FILE"

exit "${PIPESTATUS[0]}"
