#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_uat_checklist_ui.sh"
PY_SCRIPT="scripts/phase4b_uat_checklist_ui.py"
REPORT="docs/phase4/19_5_uat_checklist_ui_report.md"
MATRIX="docs/phase4/19_5_uat_checklist_ui_matrix.tsv"
CONTRACT="docs/phase4/19_5_uat_checklist_ui_contract.md"
ROUTES="docs/phase4/19_5_uat_checklist_ui_route_manifest.tsv"
SCENARIOS="docs/phase4/19_5_uat_checklist_ui_scenario_manifest.tsv"
COMPONENTS="docs/phase4/19_5_uat_checklist_ui_component_manifest.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ UAT checklist wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ UAT checklist python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_19_5_uat_checklist_ui.log 2>&1 || {
  echo "TEST_FAIL ❌ UAT checklist ui script hata verdi"
  cat /tmp/pix2pi_19_5_uat_checklist_ui.log || true
  sed -n '1,1800p' "$REPORT" || true
  exit 1
}

for required in \
  "UAT_CHECKLIST_UI=PASS" \
  "FAZ4B_19_5_FINAL_STATUS=PASS" \
  "UAT_CHECKLIST_PREVIOUS_19_4=PASS" \
  "UAT_CHECKLIST_CONTRACT=PASS" \
  "UAT_CHECKLIST_ROUTE_MANIFEST=PASS" \
  "UAT_CHECKLIST_SCENARIO_MANIFEST=PASS" \
  "UAT_CHECKLIST_COMPONENT_MANIFEST=PASS" \
  "UAT_CHECKLIST_TENANT_SAFETY=PASS" \
  "UAT_CHECKLIST_READINESS_STATUS=PASS" \
  "UAT_CHECKLIST_FLOW_ISSUE_STATUS=PASS" \
  "UAT_CHECKLIST_NO_APPLY=PASS" \
  "UAT_CHECKLIST_SECRET_SAFETY=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "UAT_RUNTIME_EXECUTED=NO" \
  "UAT_STATUS_UPDATE_EXECUTED=NO" \
  "UAT_EVIDENCE_UPLOAD_EXECUTED=NO" \
  "GO_LIVE_APPROVAL_EXECUTED=NO" \
  "PANEL_ROUTE_DEPLOYED=NO" \
  "PANEL_BUILD_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1800p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$CONTRACT" "$ROUTES" "$SCENARIOS" "$COMPONENTS"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for route in \
  "/api/v1/admin/uat/checklists" \
  "/api/v1/admin/uat/checklists/:checklist_id" \
  "/api/v1/admin/uat/checklists/:checklist_id/items" \
  "/api/v1/admin/uat/checklists/:checklist_id/items/:item_id/status" \
  "/api/v1/admin/uat/checklists/:checklist_id/evidence" \
  "/api/v1/admin/uat/checklists/:checklist_id/readiness" \
  "/api/v1/admin/uat/checklists/:checklist_id/blockers" \
  "/api/v1/admin/uat/history"
do
  grep -q "$route" "$ROUTES" || {
    echo "TEST_FAIL ❌ route eksik: $route"
    exit 1
  }
done

for scenario in \
  tenant_login_context \
  opening_stock_import \
  sales_stock_decrement \
  purchase_stock_increment \
  stock_reservation_release \
  negative_stock_policy \
  stock_valuation \
  runtime_flow_trace \
  admin_dashboard_visibility
do
  grep -q "$scenario" "$SCENARIOS" || {
    echo "TEST_FAIL ❌ scenario eksik: $scenario"
    exit 1
  }
done

for component in \
  UATChecklistShell \
  UATReadinessSummary \
  UATScenarioList \
  UATScenarioDetailPanel \
  UATEvidenceLinkPanel \
  UATBlockingItemsPanel \
  UATGoLiveReadinessGate \
  UATFlowLinkPanel \
  UATIssueLinkPanel
do
  grep -q "$component" "$COMPONENTS" || {
    echo "TEST_FAIL ❌ component eksik: $component"
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$CONTRACT" "$ROUTES" "$SCENARIOS" "$COMPONENTS"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$CONTRACT" "$ROUTES" "$SCENARIOS" "$COMPONENTS"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$CONTRACT" "$ROUTES" "$SCENARIOS" "$COMPONENTS"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_UAT_CHECKLIST_UI_TEST=PASS ✅"
echo "PHASE4B_UAT_CHECKLIST_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_UAT_CHECKLIST_ROUTE_MANIFEST_TEST=PASS ✅"
echo "PHASE4B_UAT_CHECKLIST_SCENARIO_MANIFEST_TEST=PASS ✅"
echo "PHASE4B_UAT_CHECKLIST_COMPONENT_TEST=PASS ✅"
echo "PHASE4B_UAT_CHECKLIST_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_UAT_CHECKLIST_SECRET_TEST=PASS ✅"
