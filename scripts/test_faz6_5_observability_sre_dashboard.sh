#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_5_OBSERVABILITY_EARLY_WARNING_SRE_DASHBOARD.md"
CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_5_OBSERVABILITY_VISIBLE_CHECKPOINTS.md"
RUNTIME_AUDIT_SCRIPT="scripts/audit_faz6_5_observability_runtime.sh"
REAL_AUDIT_SCRIPT="scripts/audit_faz6_5_real_implementation.sh"
RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_5_OBSERVABILITY_RUNTIME_AUDIT.md"
REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_5_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-5 OBSERVABILITY SRE DASHBOARD TEST BASLADI ====="

check_file "6-5 master dokumani mevcut" "$DOC_FILE"
check_file "6-5 visible checkpoint dosyasi mevcut" "$CHECKPOINT_FILE"
check_file "6-5 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
check_file "6-5 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"
check_exec "6-5 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
check_exec "6-5 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"

check_grep "6-5.1 Prometheus Metric Standardi tanimli" "$DOC_FILE" "6-5.1 Prometheus Metric Standardi"
check_grep "6-5.2 Grafana Dashboard Seti tanimli" "$DOC_FILE" "6-5.2 Grafana Dashboard Seti"
check_grep "6-5.3 Exporters System Metrics tanimli" "$DOC_FILE" "6-5.3 Exporters / System Metrics"
check_grep "6-5.4 Early Warning Alarm Matrix tanimli" "$DOC_FILE" "6-5.4 Early Warning Alarm Matrix"
check_grep "6-5.5 Service Health Mission Control tanimli" "$DOC_FILE" "6-5.5 Service Health / Mission Control"
check_grep "6-5.6 DB Event Gateway Signals tanimli" "$DOC_FILE" "6-5.6 DB / Event / Gateway Signals"
check_grep "6-5.7 Tenant-level Observability tanimli" "$DOC_FILE" "6-5.7 Tenant-level Observability"
check_grep "6-5.8 Log Trace Correlation tanimli" "$DOC_FILE" "6-5.8 Log / Trace / Correlation"
check_grep "6-5.9 SRE Dashboard Closure Gate tanimli" "$DOC_FILE" "6-5.9 SRE Dashboard Closure Gate"

check_grep "6-5.1 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_5_1_PROMETHEUS_METRIC_STATUS=READY"
check_grep "6-5.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_5_2_GRAFANA_DASHBOARD_STATUS=READY"
check_grep "6-5.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_5_3_EXPORTERS_STATUS=READY"
check_grep "6-5.4 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_5_4_EARLY_WARNING_STATUS=READY"
check_grep "6-5.5 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_5_5_SERVICE_HEALTH_STATUS=READY"
check_grep "6-5.6 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_5_6_DB_EVENT_GATEWAY_SIGNALS_STATUS=READY"
check_grep "6-5.7 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_5_7_TENANT_OBSERVABILITY_STATUS=READY"
check_grep "6-5.8 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_5_8_LOG_TRACE_CORRELATION_STATUS=READY"
check_grep "6-5.9 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_5_9_SRE_DASHBOARD_CLOSURE_GATE_STATUS=READY"

echo
echo "===== 6-5 RUNTIME AUDIT CALISTIRILIYOR ====="
bash "$RUNTIME_AUDIT_SCRIPT"

check_file "6-5 runtime evidence dosyasi mevcut" "$RUNTIME_EVIDENCE_FILE"
check_grep "6-5 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_5_RUNTIME_AUDIT=COMPLETE"
check_grep "6-5 runtime docker inventory var" "$RUNTIME_EVIDENCE_FILE" "6-5.2 Observability Docker Containers"
check_grep "6-5 runtime systemd inventory var" "$RUNTIME_EVIDENCE_FILE" "6-5.3 Observability Systemd Services"
check_grep "6-5 runtime port inventory var" "$RUNTIME_EVIDENCE_FILE" "6-5.4 Observability Listening Ports"
check_grep "6-5 runtime prometheus ready probe var" "$RUNTIME_EVIDENCE_FILE" "6-5.5 Prometheus Ready Probe"
check_grep "6-5 runtime grafana health probe var" "$RUNTIME_EVIDENCE_FILE" "6-5.7 Grafana Health Probe"
check_grep "6-5 runtime node exporter probe var" "$RUNTIME_EVIDENCE_FILE" "6-5.8 Node Exporter Metrics Probe"
check_grep "6-5 runtime cadvisor probe var" "$RUNTIME_EVIDENCE_FILE" "6-5.9 cAdvisor Metrics Probe"
check_grep "6-5 runtime alert inventory var" "$RUNTIME_EVIDENCE_FILE" "6-5.12 Alert / Rule Inventory"

echo
echo "===== 6-5 REAL IMPLEMENTATION AUDIT CALISTIRILIYOR ====="
bash "$REAL_AUDIT_SCRIPT"

check_file "6-5 real implementation evidence dosyasi mevcut" "$REAL_EVIDENCE_FILE"
check_grep "6-5.1 Prometheus real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.1 Prometheus / metrics"
check_grep "6-5.2 Grafana real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.2 Grafana / dashboard"
check_grep "6-5.3.1 node_exporter real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.3.1 node_exporter"
check_grep "6-5.3.2 cAdvisor real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.3.2 cAdvisor"
check_grep "6-5.4 Early warning real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.4 Early warning"
check_grep "6-5.5 Service health real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.5 Service health"
check_grep "6-5.6.1 DB observability real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.6.1 DB observability"
check_grep "6-5.6.2 Event bus observability real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.6.2 Event bus observability"
check_grep "6-5.6.3 Gateway observability real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.6.3 Gateway observability"
check_grep "6-5.7 Tenant-level observability real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.7 Tenant-level observability"
check_grep "6-5.8.1 request correlation trace real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.8.1 request_id / correlation_id"
check_grep "6-5.8.2 log standard real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.8.2 log standard"
check_grep "6-5 final interpretation var" "$REAL_EVIDENCE_FILE" "Final Runtime Implementation Interpretation"
check_grep "6-5 real audit complete muhru var" "$REAL_EVIDENCE_FILE" "FAZ_6_5_REAL_IMPLEMENTATION_AUDIT=COMPLETE"

echo
echo "===== FAZ 6-5 OBSERVABILITY SRE DASHBOARD TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_5_DOC_STATUS=READY ✅"
  echo "FAZ_6_5_VISIBLE_CHECKPOINTS_STATUS=READY ✅"
  echo "FAZ_6_5_RUNTIME_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_5_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_5_TEST_STATUS=PASS ✅"

  if grep -Fq "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_5_FINAL_STATUS=PASS ✅"
    echo "FAZ_6_6_READY=YES ✅"
  elif grep -Fq "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_5_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_6_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_5_FINAL_STATUS=NEEDS_IMPLEMENTATION_REVIEW ❌"
    echo "FAZ_6_6_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "OK ✅ FAZ 6-5 Observability / Early Warning / SRE Dashboard testi tamamlandi"
  exit 0
else
  echo "FAZ_6_5_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-5 testlerinde eksik var"
  exit 1
fi
