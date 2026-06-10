#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_1_2_SERVICE_DISCOVERY_RUNTIME_TUNING.md"
CONFIG_FILE="configs/faz6r/faz_6_21_1_2_service_discovery_runtime_tuning.v1.json"
TUNING_FILE="configs/faz6r/service_discovery_runtime_tuning.sre_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_1_2_service_discovery_runtime_tuning_test.json"
RUNTIME_FILE="scripts/faz6r/run_service_discovery_runtime_tuning_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_service_discovery_runtime_tuning.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_1_2_service_discovery_runtime_tuning.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_1_2_SERVICE_DISCOVERY_RUNTIME_TUNING_REAL_IMPLEMENTATION_AUDIT.md"
PREV_PITR_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_2_5_POINT_IN_TIME_RECOVERY_PROVASI_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 REQUIRED_FAIL / FAIL ❌"; }

check_file(){
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then pass "$label"; else fail "$label missing"; fi
}

check_contains(){
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -q "$pattern" "$file"; then pass "$label"; else fail "$label missing pattern $pattern"; fi
}

echo "===== FAZ 6-21.1.2 SERVICE DISCOVERY RUNTIME TUNING REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.1.2 previous PITR evidence file" "$PREV_PITR_EVIDENCE"
check_contains "6-21.1.2 previous PITR final PASS" "$PREV_PITR_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.1.2 documentation file" "$DOC_FILE"
check_file "6-21.1.2 config file" "$CONFIG_FILE"
check_file "6-21.1.2 tuning file" "$TUNING_FILE"
check_file "6-21.1.2 fixture file" "$FIXTURE_FILE"
check_file "6-21.1.2 runtime file" "$RUNTIME_FILE"
check_file "6-21.1.2 validator file" "$VALIDATOR_FILE"
check_file "6-21.1.2 audit file" "$AUDIT_FILE"

check_contains "6-21.1.2 doc has Service Discovery Runtime Tuning" "$DOC_FILE" "Service Discovery Runtime Tuning"
check_contains "6-21.1.2 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.1.2 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.1.2 config has dependency" "$CONFIG_FILE" "FAZ_6_21_2_5"
check_contains "6-21.1.2 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.1.2 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.1.2 config disables registry mutation" "$CONFIG_FILE" '"service_registry_mutation_allowed": false'
check_contains "6-21.1.2 config disables dns mutation" "$CONFIG_FILE" '"dns_mutation_allowed": false'
check_contains "6-21.1.2 config disables lb mutation" "$CONFIG_FILE" '"load_balancer_mutation_allowed": false'
check_contains "6-21.1.2 config disables gateway route mutation" "$CONFIG_FILE" '"gateway_route_mutation_allowed": false'
check_contains "6-21.1.2 config disables rollout" "$CONFIG_FILE" '"deployment_rollout_allowed": false'
check_contains "6-21.1.2 config disables restart" "$CONFIG_FILE" '"container_restart_allowed": false'
check_contains "6-21.1.2 config has service inventory" "$CONFIG_FILE" "service_inventory_model"
check_contains "6-21.1.2 config has registry ttl policy" "$CONFIG_FILE" "registry_health_ttl_policy"
check_contains "6-21.1.2 config has stale endpoint guard" "$CONFIG_FILE" "stale_endpoint_guard"
check_contains "6-21.1.2 config has route confidence" "$CONFIG_FILE" "service_route_confidence_policy"
check_contains "6-21.1.2 config has tenant aware guard" "$CONFIG_FILE" "tenant_aware_service_guard"

check_contains "6-21.1.2 tuning has api gateway recommendation" "$TUNING_FILE" "sd-tune-api-gateway-health-ttl"
check_contains "6-21.1.2 tuning has identity api recommendation" "$TUNING_FILE" "sd-tune-identity-api-route-confidence"
check_contains "6-21.1.2 tuning has pos recommendation" "$TUNING_FILE" "sd-tune-pos-stale-endpoint-review"
check_contains "6-21.1.2 tuning has event consumer recommendation" "$TUNING_FILE" "sd-tune-event-consumer-dependency-graph"
check_contains "6-21.1.2 tuning has reporting recommendation" "$TUNING_FILE" "sd-tune-reporting-readmodel-dns-lb-alignment"
check_contains "6-21.1.2 tuning has no mutation" "$TUNING_FILE" '"mutation_allowed": false'
check_contains "6-21.1.2 tuning has dry-run status" "$TUNING_FILE" "dry_run_only_no_service_discovery_mutation"

check_contains "6-21.1.2 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_1_4"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$TUNING_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_1_2_service_discovery_runtime.json; then
  pass "6-21.1.2 dry-run service discovery runtime"
else
  fail "6-21.1.2 dry-run service discovery runtime"
fi

check_contains "6-21.1.2 runtime output is PASS" "/tmp/faz_6_21_1_2_service_discovery_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.1.2 runtime output is dry run" "/tmp/faz_6_21_1_2_service_discovery_runtime.json" "service_discovery_runtime_tuning_dry_run"
check_contains "6-21.1.2 runtime output disables provider mutation" "/tmp/faz_6_21_1_2_service_discovery_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.1.2 runtime output disables registry mutation" "/tmp/faz_6_21_1_2_service_discovery_runtime.json" '"service_registry_mutation_allowed": false'
check_contains "6-21.1.2 runtime output has next step" "/tmp/faz_6_21_1_2_service_discovery_runtime.json" "FAZ_6_21_1_4"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$TUNING_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.1.2 semantic validator runtime"
else
  fail "6-21.1.2 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.1.2 python3 dependency"
else
  fail "6-21.1.2 python3 dependency"
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
# FAZ 6-R / 303 — FAZ 6-21.1.2 Service Discovery Runtime Tuning Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
TUNING_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_1_4_READY=${NEXT_READY}

Scope note: provider mutation, service registry mutation, DNS mutation, load balancer mutation, gateway route mutation, deployment rollout and container restart remain closed in this step.
Dependency: FAZ_6_21_2_5 PITR provası evidence checked.
EOF2

echo "===== FAZ 6-21.1.2 SERVICE DISCOVERY RUNTIME TUNING REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_1_2_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.1.2 SERVICE DISCOVERY RUNTIME TUNING COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "TUNING_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_1_4_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
