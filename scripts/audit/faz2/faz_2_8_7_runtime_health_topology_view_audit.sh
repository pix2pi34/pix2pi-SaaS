#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_8_7_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW_REAL_IMPLEMENTATION_AUDIT.md}"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

exec > >(tee "$EVIDENCE_FILE") 2>&1

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0
GO_TEST_STATUS="NOT_RUN"

pass_check() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail_check() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_INVALID / FAIL ❌"
}

check_file() {
  local file="$1"
  local label="$2"
  if [ -s "$file" ]; then
    pass_check "$label"
  else
    fail_check "$label"
  fi
}

check_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if grep -Eq "$pattern" "$file"; then
    pass_check "$label"
  else
    fail_check "$label"
  fi
}

echo "===== FAZ 2-8.7 RUNTIME HEALTH / TOPOLOGY VIEW REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 runtime file"
check_file "internal/platform/ops/console/runtime_health_topology_console_test.go" "2-8.7 test file"
check_file "web/ops-console/runtime-health-topology/index.html" "2-8.7 html screen file"
check_file "configs/faz2/ops_console/runtime_health_topology_view.v1.json" "2-8.7 config file"
check_file "docs/faz2/ops_console/FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW.md" "2-8.7 documentation file"

check_grep "RuntimeHealthTopologyConsoleRuntime" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 console runtime type"
check_grep "RuntimeTopologyNode" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 topology node model"
check_grep "RuntimeTopologyEdge" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 topology edge model"
check_grep "RuntimeHealthTopologySnapshot" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 topology snapshot model"
check_grep "UpsertNode" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 upsert node function"
check_grep "UpsertEdge" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 upsert edge function"
check_grep "BuildSnapshot" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 build snapshot function"
check_grep "RuntimeTopologyNodeKindGateway" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 gateway node kind"
check_grep "RuntimeTopologyNodeKindDatabase" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 database node kind"
check_grep "RuntimeTopologyNodeKindWorker" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 worker node kind"
check_grep "RuntimeTopologyNodeStatusHealthy" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 healthy status"
check_grep "RuntimeTopologyNodeStatusDegraded" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 degraded status"
check_grep "RuntimeTopologyNodeStatusDown" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 down status"
check_grep "RuntimeTopologyEdgeStatusBroken" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 broken edge status"
check_grep "ErrRuntimeTopologyCrossTenant" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 cross tenant guard"
check_grep "isTopologyNodeStale" "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.7 stale node helper"

check_grep "TestRuntimeHealthTopologyConsoleRuntimeBuildsSnapshot" "internal/platform/ops/console/runtime_health_topology_console_test.go" "2-8.7 build snapshot test"
check_grep "TestRuntimeHealthTopologyConsoleRuntimeKindFilter" "internal/platform/ops/console/runtime_health_topology_console_test.go" "2-8.7 kind filter test"
check_grep "TestRuntimeHealthTopologyConsoleRuntimeStatusFilter" "internal/platform/ops/console/runtime_health_topology_console_test.go" "2-8.7 status filter test"
check_grep "TestRuntimeHealthTopologyConsoleRuntimeDetectsStaleNode" "internal/platform/ops/console/runtime_health_topology_console_test.go" "2-8.7 stale node test"
check_grep "TestRuntimeHealthTopologyConsoleRuntimeRejectsMissingTenant" "internal/platform/ops/console/runtime_health_topology_console_test.go" "2-8.7 missing tenant test"
check_grep "TestRuntimeHealthTopologyConsoleRuntimeRejectsCrossTenantViewer" "internal/platform/ops/console/runtime_health_topology_console_test.go" "2-8.7 cross tenant viewer test"
check_grep "TestRuntimeHealthTopologyConsoleRuntimeRejectsInvalidNodeKind" "internal/platform/ops/console/runtime_health_topology_console_test.go" "2-8.7 invalid node kind test"
check_grep "TestRuntimeHealthTopologyConsoleRuntimeRejectsInvalidNodeStatus" "internal/platform/ops/console/runtime_health_topology_console_test.go" "2-8.7 invalid node status test"
check_grep "TestRuntimeHealthTopologyConsoleRuntimeRejectsInvalidEdgeStatus" "internal/platform/ops/console/runtime_health_topology_console_test.go" "2-8.7 invalid edge status test"
check_grep "TestRuntimeHealthTopologyConsoleRuntimeRejectsMissingEdgeNode" "internal/platform/ops/console/runtime_health_topology_console_test.go" "2-8.7 missing edge node test"

check_grep "Runtime Health / Topology" "web/ops-console/runtime-health-topology/index.html" "2-8.7 html title"
check_grep "Tenant:" "web/ops-console/runtime-health-topology/index.html" "2-8.7 tenant indicator"
check_grep "Healthy Nodes" "web/ops-console/runtime-health-topology/index.html" "2-8.7 healthy nodes metric"
check_grep "Degraded" "web/ops-console/runtime-health-topology/index.html" "2-8.7 degraded metric"
check_grep "Down" "web/ops-console/runtime-health-topology/index.html" "2-8.7 down metric"
check_grep "Broken Edges" "web/ops-console/runtime-health-topology/index.html" "2-8.7 broken edges metric"
check_grep "Topology Map" "web/ops-console/runtime-health-topology/index.html" "2-8.7 topology map"
check_grep "Topology Edges" "web/ops-console/runtime-health-topology/index.html" "2-8.7 topology edges table"
check_grep "responsive" "docs/faz2/ops_console/FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW.md" "2-8.7 responsive documentation trace"

echo "===== FAZ 2-8.7 GO TEST ====="
if go test ./internal/platform/ops/console; then
  GO_TEST_STATUS="PASS"
  pass_check "2-8.7 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-8.7 go test"
fi

echo "===== FAZ 2-8.7 RUNTIME HEALTH / TOPOLOGY VIEW REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW_TEST_STATUS=PASS"
  echo "FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW_FINAL_STATUS=PASS"
  echo "FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW_SEAL_STATUS=SEALED"
  echo "FAZ_2_8_8_READY=YES"
  exit 0
else
  echo "FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW_FINAL_STATUS=FAIL"
  echo "FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW_SEAL_STATUS=OPEN"
  echo "FAZ_2_8_8_READY=NO"
  exit 1
fi
