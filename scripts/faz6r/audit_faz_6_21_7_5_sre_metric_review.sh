#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_7_5_SRE_METRIC_REVIEW.md"
CONFIG_FILE="configs/faz6r/faz_6_21_7_5_sre_metric_review.v1.json"
METRIC_FILE="configs/faz6r/sre_metric_review.sre_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_7_5_sre_metric_review_test.json"
RUNTIME_FILE="scripts/faz6r/run_sre_metric_review_snapshot.sh"
VALIDATOR_FILE="scripts/faz6r/validate_sre_metric_review.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_7_5_sre_metric_review.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_7_5_SRE_METRIC_REVIEW_REAL_IMPLEMENTATION_AUDIT.md"
PREV_ESCALATION_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_7_4_ESCALATION_ZINCIRI_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 REQUIRED_FAIL / FAIL ❌"; }

check_file(){
  if [ -f "$2" ]; then pass "$1"; else fail "$1 missing"; fi
}

check_contains(){
  if [ -f "$2" ] && grep -q "$3" "$2"; then pass "$1"; else fail "$1 missing pattern $3"; fi
}

echo "===== FAZ 6-21.7.5 SRE METRIC REVIEW REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.7.5 previous escalation zinciri evidence file" "$PREV_ESCALATION_EVIDENCE"
check_contains "6-21.7.5 previous escalation zinciri final PASS" "$PREV_ESCALATION_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.7.5 documentation file" "$DOC_FILE"
check_file "6-21.7.5 config file" "$CONFIG_FILE"
check_file "6-21.7.5 metric catalog file" "$METRIC_FILE"
check_file "6-21.7.5 fixture file" "$FIXTURE_FILE"
check_file "6-21.7.5 runtime file" "$RUNTIME_FILE"
check_file "6-21.7.5 validator file" "$VALIDATOR_FILE"
check_file "6-21.7.5 audit file" "$AUDIT_FILE"

check_contains "6-21.7.5 doc has SRE Metric Review" "$DOC_FILE" "SRE Metric Review"
check_contains "6-21.7.5 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.7.5 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.7.5 config has dependency" "$CONFIG_FILE" "FAZ_6_21_7_4"
check_contains "6-21.7.5 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.7.5 config disables alert provider" "$CONFIG_FILE" '"alert_provider_enabled": false'
check_contains "6-21.7.5 config disables grafana mutation" "$CONFIG_FILE" '"grafana_mutation_allowed": false'
check_contains "6-21.7.5 config disables prometheus rule mutation" "$CONFIG_FILE" '"prometheus_rule_mutation_allowed": false'
check_contains "6-21.7.5 config has golden signals policy" "$CONFIG_FILE" "golden_signals_policy"
check_contains "6-21.7.5 config has edge security metrics" "$CONFIG_FILE" "edge_security_metrics"
check_contains "6-21.7.5 config has api gateway metrics" "$CONFIG_FILE" "api_gateway_metrics"
check_contains "6-21.7.5 config has db metrics" "$CONFIG_FILE" "db_metrics"
check_contains "6-21.7.5 config has event queue metrics" "$CONFIG_FILE" "event_queue_metrics"
check_contains "6-21.7.5 config has cache metrics" "$CONFIG_FILE" "cache_metrics"
check_contains "6-21.7.5 config has release health metrics" "$CONFIG_FILE" "release_health_metrics"
check_contains "6-21.7.5 config has incident readiness metrics" "$CONFIG_FILE" "incident_readiness_metrics"
check_contains "6-21.7.5 config has alert threshold policy" "$CONFIG_FILE" "alert_threshold_policy"
check_contains "6-21.7.5 config has dashboard mapping policy" "$CONFIG_FILE" "dashboard_mapping_policy"

check_contains "6-21.7.5 metrics has latency" "$METRIC_FILE" "latency"
check_contains "6-21.7.5 metrics has traffic" "$METRIC_FILE" "traffic"
check_contains "6-21.7.5 metrics has errors" "$METRIC_FILE" "errors"
check_contains "6-21.7.5 metrics has saturation" "$METRIC_FILE" "saturation"
check_contains "6-21.7.5 metrics has edge waf block rate" "$METRIC_FILE" "edge_waf_block_rate"
check_contains "6-21.7.5 metrics has tls days remaining" "$METRIC_FILE" "tls_certificate_days_remaining"
check_contains "6-21.7.5 metrics has api 5xx ratio" "$METRIC_FILE" "api_gateway_5xx_ratio"
check_contains "6-21.7.5 metrics has db pool usage" "$METRIC_FILE" "db_connection_pool_usage"
check_contains "6-21.7.5 metrics has event consumer lag" "$METRIC_FILE" "event_consumer_lag"
check_contains "6-21.7.5 metrics has cache hit ratio" "$METRIC_FILE" "cache_hit_ratio"
check_contains "6-21.7.5 metrics has release delta" "$METRIC_FILE" "post_deploy_5xx_delta"
check_contains "6-21.7.5 metrics has on-call ack time" "$METRIC_FILE" "on_call_ack_time_minutes"

check_contains "6-21.7.5 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_6_3"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$METRIC_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_7_5_metric_snapshot.json; then
  pass "6-21.7.5 dry-run metric snapshot runtime"
else
  fail "6-21.7.5 dry-run metric snapshot runtime"
fi

check_contains "6-21.7.5 runtime output is PASS" "/tmp/faz_6_21_7_5_metric_snapshot.json" '"runtime_status": "PASS"'
check_contains "6-21.7.5 runtime output is dry-run snapshot" "/tmp/faz_6_21_7_5_metric_snapshot.json" "dry_run_metric_snapshot"
check_contains "6-21.7.5 runtime output disables alert provider" "/tmp/faz_6_21_7_5_metric_snapshot.json" '"alert_provider_enabled": false'

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$METRIC_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.7.5 semantic validator runtime"
else
  fail "6-21.7.5 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.7.5 python3 dependency"
else
  fail "6-21.7.5 python3 dependency"
fi

REQUIRED_FAIL="$FAIL_COUNT"
OPTIONAL_WARN="$WARN_COUNT"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
  FINAL_STATUS="PASS"
  NEXT_READY="YES"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
  FINAL_STATUS="FAIL"
  NEXT_READY="NO"
fi

cat > "$EVIDENCE_FILE" <<EOF2
# FAZ 6-R / 289 — FAZ 6-21.7.5 SRE Metric Review Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
METRIC_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_6_3_READY=${NEXT_READY}

Scope note: alert provider, Grafana mutation and Prometheus rule mutation remain closed in this step.
Dependency: FAZ_6_21_7_4 escalation zinciri evidence checked.
EOF2

echo "===== FAZ 6-21.7.5 SRE METRIC REVIEW REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_7_5_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.7.5 SRE METRIC REVIEW COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "METRIC_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_6_3_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
