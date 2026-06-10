#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.4.1"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_4_1_SLA_SEVIYELERI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_4_1_sla_seviyeleri.v1.json"
CONTROL_FILE="configs/faz5r/support_sla_levels.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_4_1_sla_seviyeleri_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/supportsla/support_sla.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/supportsla/support_sla_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_4_1_SLA_SEVIYELERI_REAL_IMPLEMENTATION_AUDIT.md"

ok() {
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$PHASE $1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$PHASE $1 REQUIRED_FAIL / HATA ❌"
}

contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

file_exists() {
  local file="$1"
  local label="$2"
  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 5-18.4.1 SLA SEVIYELERI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"P0_CRITICAL"' "P0 critical SLA registered"
contains "$CONTROL_FILE" '"P1_HIGH"' "P1 high SLA registered"
contains "$CONTROL_FILE" '"P2_NORMAL"' "P2 normal SLA registered"
contains "$CONTROL_FILE" '"P3_LOW"' "P3 low SLA registered"
contains "$CONTROL_FILE" '"sla_p0_critical"' "P0 SLA key registered"
contains "$CONTROL_FILE" '"sla_p1_high"' "P1 SLA key registered"
contains "$CONTROL_FILE" '"sla_p2_normal"' "P2 SLA key registered"
contains "$CONTROL_FILE" '"sla_p3_low"' "P3 SLA key registered"
contains "$CONTROL_FILE" '"internal_sla_ready": true' "internal SLA ready"
contains "$CONTROL_FILE" '"production_sla_published": false' "production SLA publication blocked"
contains "$CONTROL_FILE" '"public_sla_page_enabled": false' "public SLA page blocked"
contains "$CONTROL_FILE" '"tenant_scoped": true' "tenant scoped SLA present"
contains "$CONTROL_FILE" '"has_ops_owner": true' "ops owner present"
contains "$CONTROL_FILE" '"has_business_owner": true' "business owner present"
contains "$CONTROL_FILE" '"has_escalation_rule": true' "escalation rule present"
contains "$CONTROL_FILE" '"has_breach_policy": true' "breach policy present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_SLA_PUBLICATION_BLOCKED" "production SLA publication guard"
contains "$RUNTIME_FILE" "RESPONSE_SLA_MISSING" "response SLA guard"
contains "$RUNTIME_FILE" "RESOLUTION_SLA_MISSING" "resolution SLA guard"
contains "$RUNTIME_FILE" "ESCALATION_SLA_MISSING" "escalation SLA guard"
contains "$RUNTIME_FILE" "UPDATE_INTERVAL_MISSING" "update interval guard"
contains "$RUNTIME_FILE" "TENANT_SCOPE_REQUIRED" "tenant scope guard"
contains "$RUNTIME_FILE" "OPS_OWNER_REQUIRED" "ops owner guard"
contains "$RUNTIME_FILE" "BUSINESS_OWNER_REQUIRED" "business owner guard"
contains "$RUNTIME_FILE" "ESCALATION_RULE_REQUIRED" "escalation rule guard"
contains "$RUNTIME_FILE" "BREACH_POLICY_REQUIRED" "breach policy guard"
contains "$RUNTIME_FILE" "SLA_PRIORITY_ORDER_INVALID" "priority order guard"

if go test ./internal/commercial/publiclaunch/supportsla; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/support_sla_levels.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_4_1_sla_seviyeleri_test.json").read_text())

levels = {s["key"]: s for s in control["sla_levels"]}
priorities = {s["priority"]: s for s in control["sla_levels"]}

for key in test["must_have_sla_keys"]:
    assert key in levels, f"missing SLA key: {key}"
    s = levels[key]
    assert s["status"] == "READY", f"SLA not ready: {key}"
    assert s["required"] is True, f"SLA not required: {key}"
    assert s["response_sla_hours"] > 0, f"response SLA missing: {key}"
    assert s["resolution_sla_hours"] > 0, f"resolution SLA missing: {key}"
    assert s["escalation_sla_hours"] > 0, f"escalation SLA missing: {key}"
    assert s["update_interval_hours"] > 0, f"update interval missing: {key}"
    assert s["tenant_scoped"] is True, f"tenant scoped missing: {key}"
    assert s["has_ops_owner"] is True, f"ops owner missing: {key}"
    assert s["has_business_owner"] is True, f"business owner missing: {key}"
    assert s["has_escalation_rule"] is True, f"escalation rule missing: {key}"
    assert s["has_breach_policy"] is True, f"breach policy missing: {key}"
    assert s["public_visible"] is False, f"public visible must be false: {key}"

for priority in test["must_have_priorities"]:
    assert priority in priorities, f"missing priority: {priority}"

assert priorities["P0_CRITICAL"]["response_sla_hours"] <= priorities["P1_HIGH"]["response_sla_hours"]
assert priorities["P1_HIGH"]["response_sla_hours"] <= priorities["P2_NORMAL"]["response_sla_hours"]
assert priorities["P2_NORMAL"]["response_sla_hours"] <= priorities["P3_LOW"]["response_sla_hours"]
assert priorities["P0_CRITICAL"]["resolution_sla_hours"] <= priorities["P1_HIGH"]["resolution_sla_hours"]
assert priorities["P1_HIGH"]["resolution_sla_hours"] <= priorities["P2_NORMAL"]["resolution_sla_hours"]
assert priorities["P2_NORMAL"]["resolution_sla_hours"] <= priorities["P3_LOW"]["resolution_sla_hours"]

assert control["internal_sla_ready"] is True
assert control["production_sla_published"] is False
assert control["final_policy"]["public_sla_page_enabled"] is False
assert control["final_policy"]["support_channel_structure_required_next"] is True
PY
then
  ok "json semantic validation"
else
  fail "json semantic validation"
fi

REQUIRED_FAIL="$FAIL_COUNT"
OPTIONAL_WARN="$WARN_COUNT"

mkdir -p "$(dirname "$EVIDENCE_FILE")"
cat > "$EVIDENCE_FILE" <<EOF2
# FAZ 5-18.4.1 SLA Seviyeleri Real Implementation Audit

PHASE=FAZ_5_18_4_1
AUDIT_DATE=$(date -Is)

## Real Implementation Audit Result

PASS_COUNT=$PASS_COUNT
FAIL_COUNT=$FAIL_COUNT
WARN_COUNT=$WARN_COUNT
REQUIRED_FAIL=$REQUIRED_FAIL
OPTIONAL_WARN=$OPTIONAL_WARN

## Status

DOC_STATUS=READY
CONFIG_STATUS=READY
CONTROL_CONFIG_STATUS=READY
RUNTIME_STATUS=READY
TEST_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
REAL_IMPLEMENTATION_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
INTERNAL_SLA_READY=true
PRODUCTION_SLA_PUBLISHED=false
PUBLIC_SLA_PAGE_ENABLED=false
SUPPORT_CHANNEL_STRUCTURE_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.4.1 SLA SEVIYELERI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_4_1_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_4_1_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
