#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_11_OPS_CONSOLE_INCIDENT_RUNBOOK_READINESS.md"
CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_11_OPS_VISIBLE_CHECKPOINTS.md"
INCIDENT_RUNBOOK="docs/faz6/runbooks/FAZ_6_11_INCIDENT_RUNBOOK_TEMPLATE.md"
OPS_RUNBOOK="docs/faz6/runbooks/FAZ_6_11_OPS_CONSOLE_RUNBOOK.md"
OPS_PROBE_SCRIPT="scripts/pix2pi_ops_console_probe.sh"
RUNBOOK_CHECK_SCRIPT="scripts/pix2pi_runbook_template_check.sh"
RUNTIME_AUDIT_SCRIPT="scripts/audit_faz6_11_ops_runtime.sh"
REAL_AUDIT_SCRIPT="scripts/audit_faz6_11_real_implementation.sh"

OPS_PROBE_EVIDENCE="docs/faz6/evidence/FAZ_6_11_OPS_CONSOLE_PROBE_EVIDENCE.md"
RUNBOOK_CHECK_EVIDENCE="docs/faz6/evidence/FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_EVIDENCE.md"
RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_11_OPS_RUNTIME_AUDIT.md"
REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_11_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0

ok() {
  echo "$1 OK ✅"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "$1 HATA ❌"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_exec() {
  local label="$1"
  local file="$2"

  if [ -x "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
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

echo "===== FAZ 6-11 OPS CONSOLE / INCIDENT / RUNBOOK TEST BASLADI ====="

check_file "6-11 master dokumani mevcut" "$DOC_FILE"
check_file "6-11 visible checkpoint dosyasi mevcut" "$CHECKPOINT_FILE"
check_file "6-11 incident runbook mevcut" "$INCIDENT_RUNBOOK"
check_file "6-11 ops console runbook mevcut" "$OPS_RUNBOOK"
check_file "6-11 ops probe script mevcut" "$OPS_PROBE_SCRIPT"
check_file "6-11 runbook check script mevcut" "$RUNBOOK_CHECK_SCRIPT"
check_file "6-11 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
check_file "6-11 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"

check_exec "6-11 ops probe script executable" "$OPS_PROBE_SCRIPT"
check_exec "6-11 runbook check script executable" "$RUNBOOK_CHECK_SCRIPT"
check_exec "6-11 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
check_exec "6-11 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"

check_grep "6-11.1 Ops Console Readiness tanimli" "$DOC_FILE" "6-11.1 Ops Console Readiness"
check_grep "6-11.2 Service Health Summary tanimli" "$DOC_FILE" "6-11.2 Service Health Summary"
check_grep "6-11.3 Incident Lifecycle tanimli" "$DOC_FILE" "6-11.3 Incident Lifecycle"
check_grep "6-11.4 Severity Priority Matrix tanimli" "$DOC_FILE" "6-11.4 Severity / Priority Matrix"
check_grep "6-11.5 Runbook Standard tanimli" "$DOC_FILE" "6-11.5 Runbook Standard"
check_grep "6-11.6 On-call Escalation tanimli" "$DOC_FILE" "6-11.6 On-call / Escalation Flow"
check_grep "6-11.7 Incident Evidence tanimli" "$DOC_FILE" "6-11.7 Incident Evidence Standard"
check_grep "6-11.8 Postmortem tanimli" "$DOC_FILE" "6-11.8 Postmortem Standard"
check_grep "6-11.9 Ops Guard Scripts tanimli" "$DOC_FILE" "6-11.9 Ops Console Guard Scripts"
check_grep "6-11.10 Final Closure tanimli" "$DOC_FILE" "6-11.10 Ops Final Closure Gate"

check_grep "6-11.1 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_1_OPS_CONSOLE_STATUS=READY"
check_grep "6-11.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_2_SERVICE_HEALTH_SUMMARY_STATUS=READY"
check_grep "6-11.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_3_INCIDENT_LIFECYCLE_STATUS=READY"
check_grep "6-11.4 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_4_SEVERITY_PRIORITY_STATUS=READY"
check_grep "6-11.5 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_5_RUNBOOK_STANDARD_STATUS=READY"
check_grep "6-11.6 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_6_ONCALL_ESCALATION_STATUS=READY"
check_grep "6-11.7 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_7_INCIDENT_EVIDENCE_STATUS=READY"
check_grep "6-11.8 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_8_POSTMORTEM_STATUS=READY"
check_grep "6-11.9 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_9_OPS_GUARD_SCRIPTS_STATUS=READY"
check_grep "6-11.10 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_10_OPS_FINAL_CLOSURE_GATE_STATUS=READY"

echo
echo "===== 6-11 OPS GUARD SCRIPTS CALISTIRILIYOR ====="
bash "$OPS_PROBE_SCRIPT"
bash "$RUNBOOK_CHECK_SCRIPT"

check_file "6-11 ops probe evidence mevcut" "$OPS_PROBE_EVIDENCE"
check_file "6-11 runbook check evidence mevcut" "$RUNBOOK_CHECK_EVIDENCE"
check_grep "6-11 ops probe complete muhru var" "$OPS_PROBE_EVIDENCE" "FAZ_6_11_OPS_CONSOLE_PROBE_STATUS=COMPLETE"
check_grep "6-11 runbook check pass muhru var" "$RUNBOOK_CHECK_EVIDENCE" "FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_STATUS=PASS"

echo
echo "===== 6-11 RUNTIME AUDIT CALISTIRILIYOR ====="
bash "$RUNTIME_AUDIT_SCRIPT"

check_file "6-11 runtime evidence dosyasi mevcut" "$RUNTIME_EVIDENCE_FILE"
check_grep "6-11 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_11_RUNTIME_AUDIT=COMPLETE"
check_grep "6-11 runtime docker snapshot var" "$RUNTIME_EVIDENCE_FILE" "6-11.2 Docker Services Snapshot"
check_grep "6-11 runtime systemd snapshot var" "$RUNTIME_EVIDENCE_FILE" "6-11.3 Systemd Services Snapshot"
check_grep "6-11 runtime health probe var" "$RUNTIME_EVIDENCE_FILE" "6-11.4 Health / Metrics Probe"
check_grep "6-11 runtime runbook probe var" "$RUNTIME_EVIDENCE_FILE" "6-11.5 Runbook Template Check Probe"
check_grep "6-11 runtime incident files inventory var" "$RUNTIME_EVIDENCE_FILE" "6-11.6 Incident / Runbook Files Inventory"

echo
echo "===== 6-11 REAL IMPLEMENTATION AUDIT CALISTIRILIYOR ====="
bash "$REAL_AUDIT_SCRIPT"

check_file "6-11 real implementation evidence dosyasi mevcut" "$REAL_EVIDENCE_FILE"
check_grep "6-11.1 ops console real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.1 Ops console"
check_grep "6-11.2 service health real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.2 Service health"
check_grep "6-11.3 incident lifecycle real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.3 Incident lifecycle"
check_grep "6-11.4 severity priority real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.4 Severity / priority"
check_grep "6-11.5 runbook real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.5 Runbook standard"
check_grep "6-11.6 escalation real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.6 On-call / escalation"
check_grep "6-11.7 evidence standard real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.7 Incident evidence"
check_grep "6-11.8 postmortem real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.8 Postmortem standard"
check_grep "6-11.9 guard scripts real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.9 Ops guard scripts"
check_grep "6-11 final interpretation var" "$REAL_EVIDENCE_FILE" "Final Runtime Implementation Interpretation"
check_grep "6-11 real audit complete muhru var" "$REAL_EVIDENCE_FILE" "FAZ_6_11_REAL_IMPLEMENTATION_AUDIT=COMPLETE"

echo
echo "===== FAZ 6-11 OPS CONSOLE / INCIDENT / RUNBOOK TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_11_DOC_STATUS=READY ✅"
  echo "FAZ_6_11_VISIBLE_CHECKPOINTS_STATUS=READY ✅"
  echo "FAZ_6_11_RUNBOOK_STATUS=READY ✅"
  echo "FAZ_6_11_OPS_GUARD_SCRIPTS_STATUS=READY ✅"
  echo "FAZ_6_11_RUNTIME_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_11_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_11_TEST_STATUS=PASS ✅"

  if grep -Fq "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_11_FINAL_STATUS=PASS ✅"
    echo "FAZ_6_12_READY=YES ✅"
  elif grep -Fq "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_11_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_12_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_11_FINAL_STATUS=NEEDS_IMPLEMENTATION_REVIEW ❌"
    echo "FAZ_6_12_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "OK ✅ FAZ 6-11 Ops Console / Incident / Runbook Readiness testi tamamlandi"
  exit 0
else
  echo "FAZ_6_11_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-11 testlerinde eksik var"
  exit 1
fi

echo
echo "===== FAZ 6-11 ISLEM BITTI ====="
#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_11_OPS_CONSOLE_INCIDENT_RUNBOOK_READINESS.md"
CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_11_OPS_VISIBLE_CHECKPOINTS.md"
INCIDENT_RUNBOOK="docs/faz6/runbooks/FAZ_6_11_INCIDENT_RUNBOOK_TEMPLATE.md"
OPS_RUNBOOK="docs/faz6/runbooks/FAZ_6_11_OPS_CONSOLE_RUNBOOK.md"
OPS_PROBE_SCRIPT="scripts/pix2pi_ops_console_probe.sh"
RUNBOOK_CHECK_SCRIPT="scripts/pix2pi_runbook_template_check.sh"
RUNTIME_AUDIT_SCRIPT="scripts/audit_faz6_11_ops_runtime.sh"
REAL_AUDIT_SCRIPT="scripts/audit_faz6_11_real_implementation.sh"

OPS_PROBE_EVIDENCE="docs/faz6/evidence/FAZ_6_11_OPS_CONSOLE_PROBE_EVIDENCE.md"
RUNBOOK_CHECK_EVIDENCE="docs/faz6/evidence/FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_EVIDENCE.md"
RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_11_OPS_RUNTIME_AUDIT.md"
REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_11_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0

ok() {
  echo "$1 OK ✅"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "$1 HATA ❌"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_exec() {
  local label="$1"
  local file="$2"

  if [ -x "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
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

echo "===== FAZ 6-11 OPS CONSOLE / INCIDENT / RUNBOOK TEST BASLADI ====="

check_file "6-11 master dokumani mevcut" "$DOC_FILE"
check_file "6-11 visible checkpoint dosyasi mevcut" "$CHECKPOINT_FILE"
check_file "6-11 incident runbook mevcut" "$INCIDENT_RUNBOOK"
check_file "6-11 ops console runbook mevcut" "$OPS_RUNBOOK"
check_file "6-11 ops probe script mevcut" "$OPS_PROBE_SCRIPT"
check_file "6-11 runbook check script mevcut" "$RUNBOOK_CHECK_SCRIPT"
check_file "6-11 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
check_file "6-11 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"

check_exec "6-11 ops probe script executable" "$OPS_PROBE_SCRIPT"
check_exec "6-11 runbook check script executable" "$RUNBOOK_CHECK_SCRIPT"
check_exec "6-11 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
check_exec "6-11 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"

check_grep "6-11.1 Ops Console Readiness tanimli" "$DOC_FILE" "6-11.1 Ops Console Readiness"
check_grep "6-11.2 Service Health Summary tanimli" "$DOC_FILE" "6-11.2 Service Health Summary"
check_grep "6-11.3 Incident Lifecycle tanimli" "$DOC_FILE" "6-11.3 Incident Lifecycle"
check_grep "6-11.4 Severity Priority Matrix tanimli" "$DOC_FILE" "6-11.4 Severity / Priority Matrix"
check_grep "6-11.5 Runbook Standard tanimli" "$DOC_FILE" "6-11.5 Runbook Standard"
check_grep "6-11.6 On-call Escalation tanimli" "$DOC_FILE" "6-11.6 On-call / Escalation Flow"
check_grep "6-11.7 Incident Evidence tanimli" "$DOC_FILE" "6-11.7 Incident Evidence Standard"
check_grep "6-11.8 Postmortem tanimli" "$DOC_FILE" "6-11.8 Postmortem Standard"
check_grep "6-11.9 Ops Guard Scripts tanimli" "$DOC_FILE" "6-11.9 Ops Console Guard Scripts"
check_grep "6-11.10 Final Closure tanimli" "$DOC_FILE" "6-11.10 Ops Final Closure Gate"

check_grep "6-11.1 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_1_OPS_CONSOLE_STATUS=READY"
check_grep "6-11.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_2_SERVICE_HEALTH_SUMMARY_STATUS=READY"
check_grep "6-11.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_3_INCIDENT_LIFECYCLE_STATUS=READY"
check_grep "6-11.4 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_4_SEVERITY_PRIORITY_STATUS=READY"
check_grep "6-11.5 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_5_RUNBOOK_STANDARD_STATUS=READY"
check_grep "6-11.6 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_6_ONCALL_ESCALATION_STATUS=READY"
check_grep "6-11.7 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_7_INCIDENT_EVIDENCE_STATUS=READY"
check_grep "6-11.8 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_8_POSTMORTEM_STATUS=READY"
check_grep "6-11.9 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_9_OPS_GUARD_SCRIPTS_STATUS=READY"
check_grep "6-11.10 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_11_10_OPS_FINAL_CLOSURE_GATE_STATUS=READY"

echo
echo "===== 6-11 OPS GUARD SCRIPTS CALISTIRILIYOR ====="
bash "$OPS_PROBE_SCRIPT"
bash "$RUNBOOK_CHECK_SCRIPT"

check_file "6-11 ops probe evidence mevcut" "$OPS_PROBE_EVIDENCE"
check_file "6-11 runbook check evidence mevcut" "$RUNBOOK_CHECK_EVIDENCE"
check_grep "6-11 ops probe complete muhru var" "$OPS_PROBE_EVIDENCE" "FAZ_6_11_OPS_CONSOLE_PROBE_STATUS=COMPLETE"
check_grep "6-11 runbook check pass muhru var" "$RUNBOOK_CHECK_EVIDENCE" "FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_STATUS=PASS"

echo
echo "===== 6-11 RUNTIME AUDIT CALISTIRILIYOR ====="
bash "$RUNTIME_AUDIT_SCRIPT"

check_file "6-11 runtime evidence dosyasi mevcut" "$RUNTIME_EVIDENCE_FILE"
check_grep "6-11 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_11_RUNTIME_AUDIT=COMPLETE"
check_grep "6-11 runtime docker snapshot var" "$RUNTIME_EVIDENCE_FILE" "6-11.2 Docker Services Snapshot"
check_grep "6-11 runtime systemd snapshot var" "$RUNTIME_EVIDENCE_FILE" "6-11.3 Systemd Services Snapshot"
check_grep "6-11 runtime health probe var" "$RUNTIME_EVIDENCE_FILE" "6-11.4 Health / Metrics Probe"
check_grep "6-11 runtime runbook probe var" "$RUNTIME_EVIDENCE_FILE" "6-11.5 Runbook Template Check Probe"
check_grep "6-11 runtime incident files inventory var" "$RUNTIME_EVIDENCE_FILE" "6-11.6 Incident / Runbook Files Inventory"

echo
echo "===== 6-11 REAL IMPLEMENTATION AUDIT CALISTIRILIYOR ====="
bash "$REAL_AUDIT_SCRIPT"

check_file "6-11 real implementation evidence dosyasi mevcut" "$REAL_EVIDENCE_FILE"
check_grep "6-11.1 ops console real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.1 Ops console"
check_grep "6-11.2 service health real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.2 Service health"
check_grep "6-11.3 incident lifecycle real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.3 Incident lifecycle"
check_grep "6-11.4 severity priority real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.4 Severity / priority"
check_grep "6-11.5 runbook real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.5 Runbook standard"
check_grep "6-11.6 escalation real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.6 On-call / escalation"
check_grep "6-11.7 evidence standard real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.7 Incident evidence"
check_grep "6-11.8 postmortem real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.8 Postmortem standard"
check_grep "6-11.9 guard scripts real audit evidence var" "$REAL_EVIDENCE_FILE" "6-11.9 Ops guard scripts"
check_grep "6-11 final interpretation var" "$REAL_EVIDENCE_FILE" "Final Runtime Implementation Interpretation"
check_grep "6-11 real audit complete muhru var" "$REAL_EVIDENCE_FILE" "FAZ_6_11_REAL_IMPLEMENTATION_AUDIT=COMPLETE"

echo
echo "===== FAZ 6-11 OPS CONSOLE / INCIDENT / RUNBOOK TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_11_DOC_STATUS=READY ✅"
  echo "FAZ_6_11_VISIBLE_CHECKPOINTS_STATUS=READY ✅"
  echo "FAZ_6_11_RUNBOOK_STATUS=READY ✅"
  echo "FAZ_6_11_OPS_GUARD_SCRIPTS_STATUS=READY ✅"
  echo "FAZ_6_11_RUNTIME_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_11_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_11_TEST_STATUS=PASS ✅"

  if grep -Fq "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_11_FINAL_STATUS=PASS ✅"
    echo "FAZ_6_12_READY=YES ✅"
  elif grep -Fq "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_11_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_12_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_11_FINAL_STATUS=NEEDS_IMPLEMENTATION_REVIEW ❌"
    echo "FAZ_6_12_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "OK ✅ FAZ 6-11 Ops Console / Incident / Runbook Readiness testi tamamlandi"
  exit 0
else
  echo "FAZ_6_11_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-11 testlerinde eksik var"
  exit 1
fi
