#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_issue_feedback_ui.sh"
PY_SCRIPT="scripts/phase4b_issue_feedback_ui.py"
REPORT="docs/phase4/19_6_issue_feedback_ui_report.md"
MATRIX="docs/phase4/19_6_issue_feedback_ui_matrix.tsv"
CONTRACT="docs/phase4/19_6_issue_feedback_ui_contract.md"
ROUTES="docs/phase4/19_6_issue_feedback_ui_route_manifest.tsv"
TYPES="docs/phase4/19_6_issue_feedback_ui_type_manifest.tsv"
COMPONENTS="docs/phase4/19_6_issue_feedback_ui_component_manifest.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ issue feedback wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ issue feedback python executable degil"
  exit 1
fi

bash -n "$SCRIPT" || {
  echo "TEST_FAIL ❌ wrapper bash syntax hatali"
  exit 1
}

python3 -m py_compile "$PY_SCRIPT" || {
  echo "TEST_FAIL ❌ python validator syntax hatali"
  exit 1
}

bash "$SCRIPT" . >/tmp/pix2pi_19_6_issue_feedback_ui.log 2>&1 || {
  echo "TEST_FAIL ❌ issue feedback ui script hata verdi"
  cat /tmp/pix2pi_19_6_issue_feedback_ui.log || true
  sed -n '1,1900p' "$REPORT" || true
  exit 1
}

for required in \
  "ISSUE_FEEDBACK_UI=PASS" \
  "FAZ4B_19_6_FINAL_STATUS=PASS" \
  "ISSUE_FEEDBACK_PREVIOUS_19_5=PASS" \
  "ISSUE_FEEDBACK_CONTRACT=PASS" \
  "ISSUE_FEEDBACK_ROUTE_MANIFEST=PASS" \
  "ISSUE_FEEDBACK_TYPE_MANIFEST=PASS" \
  "ISSUE_FEEDBACK_COMPONENT_MANIFEST=PASS" \
  "ISSUE_FEEDBACK_TENANT_SAFETY=PASS" \
  "ISSUE_FEEDBACK_LINKAGE_STATUS=PASS" \
  "ISSUE_FEEDBACK_CLASSIFICATION_STATUS=PASS" \
  "ISSUE_FEEDBACK_NO_APPLY=PASS" \
  "ISSUE_FEEDBACK_SECRET_SAFETY=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "ISSUE_RUNTIME_EXECUTED=NO" \
  "ISSUE_CREATE_EXECUTED=NO" \
  "FEEDBACK_CREATE_EXECUTED=NO" \
  "ISSUE_STATUS_UPDATE_EXECUTED=NO" \
  "ISSUE_EVIDENCE_UPLOAD_EXECUTED=NO" \
  "PANEL_ROUTE_DEPLOYED=NO" \
  "PANEL_BUILD_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1900p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$CONTRACT" "$ROUTES" "$TYPES" "$COMPONENTS"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for route in \
  "/api/v1/admin/issues/summary" \
  "/api/v1/admin/issues" \
  "/api/v1/admin/issues/:issue_id" \
  "/api/v1/admin/issues/:issue_id/comments" \
  "/api/v1/admin/issues/:issue_id/evidence" \
  "/api/v1/admin/issues/:issue_id/status" \
  "/api/v1/admin/feedback"
do
  grep -q "$route" "$ROUTES" || {
    echo "TEST_FAIL ❌ route eksik: $route"
    exit 1
  }
done

for issue_type in \
  bug \
  feedback \
  feature_request \
  data_issue \
  import_issue \
  inventory_issue \
  reporting_issue \
  security_concern \
  uat_blocker
do
  grep -q "$issue_type" "$TYPES" || {
    echo "TEST_FAIL ❌ type eksik: $issue_type"
    exit 1
  }
done

for component in \
  IssueFeedbackShell \
  IssueSummaryCards \
  IssueCreateForm \
  FeedbackCreateForm \
  IssueRuntimeFlowLinkPanel \
  IssueUATLinkPanel \
  IssueImportLinkPanel \
  IssueEvidencePanel \
  IssueStatusTimeline \
  FeedbackListTable
do
  grep -q "$component" "$COMPONENTS" || {
    echo "TEST_FAIL ❌ component eksik: $component"
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$CONTRACT" "$ROUTES" "$TYPES" "$COMPONENTS"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$CONTRACT" "$ROUTES" "$TYPES" "$COMPONENTS"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$CONTRACT" "$ROUTES" "$TYPES" "$COMPONENTS"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_ISSUE_FEEDBACK_UI_TEST=PASS ✅"
echo "PHASE4B_ISSUE_FEEDBACK_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_ISSUE_FEEDBACK_ROUTE_MANIFEST_TEST=PASS ✅"
echo "PHASE4B_ISSUE_FEEDBACK_TYPE_MANIFEST_TEST=PASS ✅"
echo "PHASE4B_ISSUE_FEEDBACK_COMPONENT_TEST=PASS ✅"
echo "PHASE4B_ISSUE_FEEDBACK_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_ISSUE_FEEDBACK_SECRET_TEST=PASS ✅"
