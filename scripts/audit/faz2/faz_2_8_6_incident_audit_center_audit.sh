#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_8_6_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_8_6_INCIDENT_AUDIT_CENTER_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-8.6 INCIDENT / AUDIT CENTER REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 runtime file"
check_file "internal/platform/ops/console/incident_audit_center_console_test.go" "2-8.6 test file"
check_file "web/ops-console/incident-audit-center/index.html" "2-8.6 html screen file"
check_file "configs/faz2/ops_console/incident_audit_center.v1.json" "2-8.6 config file"
check_file "docs/faz2/ops_console/FAZ_2_8_6_INCIDENT_AUDIT_CENTER.md" "2-8.6 documentation file"

check_grep "IncidentAuditCenterConsoleRuntime" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 console runtime type"
check_grep "IncidentCenterRecord" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 incident record model"
check_grep "AuditCenterRecord" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 audit record model"
check_grep "IncidentAuditCenterSnapshot" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 snapshot model"
check_grep "UpsertIncident" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 upsert incident function"
check_grep "ResolveIncident" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 resolve incident function"
check_grep "RecordAuditEvent" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 record audit event function"
check_grep "BuildSnapshot" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 build snapshot function"
check_grep "IncidentAuditSeverityCritical" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 critical severity"
check_grep "IncidentStatusOpen" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 open status"
check_grep "IncidentStatusResolved" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 resolved status"
check_grep "AuditActionSecurityEvent" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 security audit action"
check_grep "AuditActionOperatorAction" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 operator audit action"
check_grep "ErrIncidentAuditCrossTenant" "internal/platform/ops/console/incident_audit_center_console.go" "2-8.6 cross tenant guard"

check_grep "TestIncidentAuditCenterConsoleRuntimeBuildsSnapshot" "internal/platform/ops/console/incident_audit_center_console_test.go" "2-8.6 build snapshot test"
check_grep "TestIncidentAuditCenterConsoleRuntimeFiltersSeverity" "internal/platform/ops/console/incident_audit_center_console_test.go" "2-8.6 severity filter test"
check_grep "TestIncidentAuditCenterConsoleRuntimeFiltersStatus" "internal/platform/ops/console/incident_audit_center_console_test.go" "2-8.6 status filter test"
check_grep "TestIncidentAuditCenterConsoleRuntimeHidesResolvedWhenDisabled" "internal/platform/ops/console/incident_audit_center_console_test.go" "2-8.6 resolved visibility test"
check_grep "TestIncidentAuditCenterConsoleRuntimeResolveIncident" "internal/platform/ops/console/incident_audit_center_console_test.go" "2-8.6 resolve incident test"
check_grep "TestIncidentAuditCenterConsoleRuntimeRejectsMissingTenant" "internal/platform/ops/console/incident_audit_center_console_test.go" "2-8.6 missing tenant test"
check_grep "TestIncidentAuditCenterConsoleRuntimeRejectsCrossTenantViewer" "internal/platform/ops/console/incident_audit_center_console_test.go" "2-8.6 cross tenant viewer test"
check_grep "TestIncidentAuditCenterConsoleRuntimeRejectsInvalidSeverity" "internal/platform/ops/console/incident_audit_center_console_test.go" "2-8.6 invalid severity test"
check_grep "TestIncidentAuditCenterConsoleRuntimeRejectsInvalidStatus" "internal/platform/ops/console/incident_audit_center_console_test.go" "2-8.6 invalid status test"
check_grep "TestIncidentAuditCenterConsoleRuntimeRejectsInvalidActionType" "internal/platform/ops/console/incident_audit_center_console_test.go" "2-8.6 invalid action type test"
check_grep "TestIncidentAuditCenterConsoleRuntimeRejectsMissingAuditActor" "internal/platform/ops/console/incident_audit_center_console_test.go" "2-8.6 missing audit actor test"

check_grep "Incident / Audit Center" "web/ops-console/incident-audit-center/index.html" "2-8.6 html title"
check_grep "Tenant:" "web/ops-console/incident-audit-center/index.html" "2-8.6 tenant indicator"
check_grep "Open Incidents" "web/ops-console/incident-audit-center/index.html" "2-8.6 open incidents metric"
check_grep "Critical" "web/ops-console/incident-audit-center/index.html" "2-8.6 critical metric"
check_grep "Audit Events" "web/ops-console/incident-audit-center/index.html" "2-8.6 audit events metric"
check_grep "Resolved" "web/ops-console/incident-audit-center/index.html" "2-8.6 resolved metric"
check_grep "Incidents" "web/ops-console/incident-audit-center/index.html" "2-8.6 incident table"
check_grep "Audit Stream" "web/ops-console/incident-audit-center/index.html" "2-8.6 audit stream table"
check_grep "responsive" "docs/faz2/ops_console/FAZ_2_8_6_INCIDENT_AUDIT_CENTER.md" "2-8.6 responsive documentation trace"

echo "===== FAZ 2-8.6 GO TEST ====="
if go test ./internal/platform/ops/console; then
  GO_TEST_STATUS="PASS"
  pass_check "2-8.6 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-8.6 go test"
fi

echo "===== FAZ 2-8.6 INCIDENT / AUDIT CENTER REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_8_6_INCIDENT_AUDIT_CENTER_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_8_6_INCIDENT_AUDIT_CENTER_TEST_STATUS=PASS"
  echo "FAZ_2_8_6_INCIDENT_AUDIT_CENTER_FINAL_STATUS=PASS"
  echo "FAZ_2_8_6_INCIDENT_AUDIT_CENTER_SEAL_STATUS=SEALED"
  echo "FAZ_2_8_7_READY=YES"
  exit 0
else
  echo "FAZ_2_8_6_INCIDENT_AUDIT_CENTER_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_8_6_INCIDENT_AUDIT_CENTER_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_8_6_INCIDENT_AUDIT_CENTER_FINAL_STATUS=FAIL"
  echo "FAZ_2_8_6_INCIDENT_AUDIT_CENTER_SEAL_STATUS=OPEN"
  echo "FAZ_2_8_7_READY=NO"
  exit 1
fi
