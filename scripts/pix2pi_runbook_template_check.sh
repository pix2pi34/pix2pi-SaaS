#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

RUNBOOK_FILE="docs/faz6/runbooks/FAZ_6_11_INCIDENT_RUNBOOK_TEMPLATE.md"
OPS_RUNBOOK_FILE="docs/faz6/runbooks/FAZ_6_11_OPS_CONSOLE_RUNBOOK.md"
EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_EVIDENCE.md"

mkdir -p docs/faz6/evidence

PASS_COUNT=0
FAIL_COUNT=0

ok() {
  echo "$1 OK ✅" | tee -a "$EVIDENCE_FILE"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "$1 HATA ❌" | tee -a "$EVIDENCE_FILE"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-11 Runbook Template Check Evidence

Generated At: $(date -Is)  
Repo: $ROOT_DIR  

FAZ_6_11_RUNBOOK_TEMPLATE_CHECK=STARTED ✅

---

EOF2

echo "===== PIX2PI RUNBOOK TEMPLATE CHECK BASLADI ====="

check_grep "incident_id alani var" "$RUNBOOK_FILE" "incident_id"
check_grep "severity alani var" "$RUNBOOK_FILE" "severity"
check_grep "priority alani var" "$RUNBOOK_FILE" "priority"
check_grep "status alani var" "$RUNBOOK_FILE" "status"
check_grep "owner alani var" "$RUNBOOK_FILE" "owner"
check_grep "affected_service alani var" "$RUNBOOK_FILE" "affected_service"
check_grep "affected_tenant alani var" "$RUNBOOK_FILE" "affected_tenant"
check_grep "customer impact var" "$RUNBOOK_FILE" "Customer Impact"
check_grep "technical impact var" "$RUNBOOK_FILE" "Technical Impact"
check_grep "first safe diagnostics var" "$RUNBOOK_FILE" "First Safe Diagnostics"
check_grep "do not do var" "$RUNBOOK_FILE" "Do Not Do"
check_grep "mitigation steps var" "$RUNBOOK_FILE" "Mitigation Steps"
check_grep "recovery smoke var" "$RUNBOOK_FILE" "Recovery Smoke"
check_grep "timeline var" "$RUNBOOK_FILE" "Timeline"
check_grep "closure var" "$RUNBOOK_FILE" "Closure"

check_grep "ops console purpose var" "$OPS_RUNBOOK_FILE" "Purpose"
check_grep "minimum cards var" "$OPS_RUNBOOK_FILE" "Minimum Cards"
check_grep "safe probe commands var" "$OPS_RUNBOOK_FILE" "Safe Probe Commands"
check_grep "status meaning var" "$OPS_RUNBOOK_FILE" "Status Meaning"
check_grep "escalation var" "$OPS_RUNBOOK_FILE" "Escalation"

{
  echo
  echo "## Runbook Template Check Final Seal"
  echo
  echo '~~~text'
  echo "PASS_COUNT=$PASS_COUNT"
  echo "FAIL_COUNT=$FAIL_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_STATUS=PASS ✅"
  else
    echo "FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_STATUS=FAIL ❌"
  fi
  echo '~~~'
} >> "$EVIDENCE_FILE"

echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_STATUS=PASS ✅"
  exit 0
else
  echo "FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_STATUS=FAIL ❌"
  exit 1
fi
