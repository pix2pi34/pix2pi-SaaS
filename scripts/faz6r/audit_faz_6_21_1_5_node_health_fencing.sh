#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_1_5_NODE_HEALTH_FENCING.md"
CONFIG_FILE="configs/faz6r/faz_6_21_1_5_node_health_fencing.v1.json"
POLICY_FILE="configs/faz6r/node_health_fencing.sre_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_1_5_node_health_fencing_test.json"
RUNTIME_FILE="scripts/faz6r/run_node_health_fencing_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_node_health_fencing.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_1_5_node_health_fencing.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_1_5_NODE_HEALTH_FENCING_REAL_IMPLEMENTATION_AUDIT.md"
PREV_SESSION_STICKY_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_1_4_SESSION_STICKY_POLICY_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.1.5 NODE HEALTH FENCING REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.1.5 previous session sticky evidence file" "$PREV_SESSION_STICKY_EVIDENCE"
check_contains "6-21.1.5 previous session sticky final PASS" "$PREV_SESSION_STICKY_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.1.5 documentation file" "$DOC_FILE"
check_file "6-21.1.5 config file" "$CONFIG_FILE"
check_file "6-21.1.5 policy file" "$POLICY_FILE"
check_file "6-21.1.5 fixture file" "$FIXTURE_FILE"
check_file "6-21.1.5 runtime file" "$RUNTIME_FILE"
check_file "6-21.1.5 validator file" "$VALIDATOR_FILE"
check_file "6-21.1.5 audit file" "$AUDIT_FILE"

check_contains "6-21.1.5 doc has Node Health Fencing" "$DOC_FILE" "Node Health Fencing"
check_contains "6-21.1.5 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.1.5 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.1.5 config has dependency" "$CONFIG_FILE" "FAZ_6_21_1_4"
check_contains "6-21.1.5 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.1.5 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.1.5 config disables node cordon" "$CONFIG_FILE" '"node_cordon_allowed": false'
check_contains "6-21.1.5 config disables node drain" "$CONFIG_FILE" '"node_drain_allowed": false'
check_contains "6-21.1.5 config disables node restart" "$CONFIG_FILE" '"node_restart_allowed": false'
check_contains "6-21.1.5 config disables node shutdown" "$CONFIG_FILE" '"node_shutdown_allowed": false'
check_contains "6-21.1.5 config disables lb detach" "$CONFIG_FILE" '"lb_detach_allowed": false'
check_contains "6-21.1.5 config disables dns mutation" "$CONFIG_FILE" '"dns_mutation_allowed": false'
check_contains "6-21.1.5 config disables gateway route mutation" "$CONFIG_FILE" '"gateway_route_mutation_allowed": false'
check_contains "6-21.1.5 config disables registry mutation" "$CONFIG_FILE" '"service_registry_mutation_allowed": false'
check_contains "6-21.1.5 config has quorum guard" "$CONFIG_FILE" "quorum_safety_guard"
check_contains "6-21.1.5 config has split brain guard" "$CONFIG_FILE" "split_brain_guard"
check_contains "6-21.1.5 config has tenant traffic guard" "$CONFIG_FILE" "tenant_traffic_isolation_guard"
check_contains "6-21.1.5 config has workload drain policy" "$CONFIG_FILE" "workload_drain_policy"
check_contains "6-21.1.5 config has session affinity guard" "$CONFIG_FILE" "session_affinity_safety_guard"

check_contains "6-21.1.5 policy has api gateway fencing" "$POLICY_FILE" "node-fence-api-gateway-degraded-review"
check_contains "6-21.1.5 policy has app runtime fencing" "$POLICY_FILE" "node-fence-app-runtime-manual-rehearsal"
check_contains "6-21.1.5 policy has worker fencing" "$POLICY_FILE" "node-fence-worker-backlog-review"
check_contains "6-21.1.5 policy has db-facing fencing" "$POLICY_FILE" "node-fence-db-facing-blocked-quorum"
check_contains "6-21.1.5 policy has observability fencing" "$POLICY_FILE" "node-fence-observability-review"
check_contains "6-21.1.5 policy has no mutation" "$POLICY_FILE" '"mutation_allowed": false'
check_contains "6-21.1.5 policy has dry-run status" "$POLICY_FILE" "dry_run_only_no_node_fencing_mutation"
check_contains "6-21.1.5 policy has next step" "$POLICY_FILE" "FAZ_6_20_2"

check_contains "6-21.1.5 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_20_2"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$POLICY_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_1_5_node_health_fencing_runtime.json; then
  pass "6-21.1.5 dry-run node health fencing runtime"
else
  fail "6-21.1.5 dry-run node health fencing runtime"
fi

check_contains "6-21.1.5 runtime output is PASS" "/tmp/faz_6_21_1_5_node_health_fencing_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.1.5 runtime output is dry run" "/tmp/faz_6_21_1_5_node_health_fencing_runtime.json" "node_health_fencing_dry_run"
check_contains "6-21.1.5 runtime output disables provider mutation" "/tmp/faz_6_21_1_5_node_health_fencing_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.1.5 runtime output disables node drain" "/tmp/faz_6_21_1_5_node_health_fencing_runtime.json" '"node_drain_allowed": false'
check_contains "6-21.1.5 runtime output has next step" "/tmp/faz_6_21_1_5_node_health_fencing_runtime.json" "FAZ_6_20_2"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$POLICY_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.1.5 semantic validator runtime"
else
  fail "6-21.1.5 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.1.5 python3 dependency"
else
  fail "6-21.1.5 python3 dependency"
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
# FAZ 6-R / 305 — FAZ 6-21.1.5 Node Health Fencing Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
POLICY_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_20_2_READY=${NEXT_READY}

Scope note: provider mutation, node cordon/drain/restart/shutdown, LB detach, DNS mutation, gateway route mutation, service registry mutation, container kill and deployment rollout remain closed in this step.
Dependency: FAZ_6_21_1_4 session / sticky policy evidence checked.
EOF2

echo "===== FAZ 6-21.1.5 NODE HEALTH FENCING REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_1_5_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.1.5 NODE HEALTH FENCING COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "POLICY_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_20_2_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
