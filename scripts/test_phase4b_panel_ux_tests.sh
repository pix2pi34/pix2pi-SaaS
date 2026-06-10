#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_panel_ux_tests.sh"
PY_SCRIPT="scripts/phase4b_panel_ux_tests.py"
REPORT="docs/phase4/19_7_panel_ux_tests_report.md"
MATRIX="docs/phase4/19_7_panel_ux_tests_matrix.tsv"
INVENTORY="docs/phase4/19_7_panel_ux_tests_inventory.tsv"
CLOSURE="docs/phase4/19_panel_admin_professionalization_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ panel UX tests wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ panel UX tests python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_19_7_panel_ux_tests.log 2>&1 || {
  echo "TEST_FAIL ❌ panel UX tests script hata verdi"
  cat /tmp/pix2pi_19_7_panel_ux_tests.log || true
  sed -n '1,2200p' "$REPORT" || true
  exit 1
}

for required in \
  "PANEL_UX_TEST_SET=PASS" \
  "PANEL_ADMIN_FINAL_CLOSURE=PASS" \
  "FAZ4B_19_7_FINAL_STATUS=PASS" \
  "FAZ4B_19_FINAL_STATUS=PASS" \
  "RUNTIME_FLOW_HISTORY_TEST=PASS" \
  "FLOW_DETAIL_PAGE_TEST=PASS" \
  "ADMIN_DASHBOARD_CARDS_TEST=PASS" \
  "IMPORT_WIZARD_UI_TEST=PASS" \
  "UAT_CHECKLIST_UI_TEST=PASS" \
  "ISSUE_FEEDBACK_UI_TEST=PASS" \
  "PANEL_CONTRACT_ARTIFACT_TEST=PASS" \
  "PANEL_MANIFEST_COVERAGE_TEST=PASS" \
  "PANEL_TENANT_SAFETY_TEST=PASS" \
  "PANEL_UX_LINKAGE_TEST=PASS" \
  "PANEL_MIGRATION_CHAIN_TEST=PASS" \
  "PANEL_NO_APPLY_TEST=PASS" \
  "PANEL_SECRET_SAFETY_TEST=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "PANEL_ROUTE_DEPLOYED=NO" \
  "PANEL_BUILD_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,2200p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY" "$CLOSURE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

grep -q "FAZ4B_19_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ 19 final closure PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

for gate in \
  runtime_flow_history_test \
  flow_detail_page_test \
  admin_dashboard_cards_test \
  import_wizard_ui_test \
  uat_checklist_ui_test \
  issue_feedback_ui_test \
  panel_contract_artifact_test \
  panel_manifest_coverage_test \
  panel_tenant_safety_test \
  panel_ux_linkage_test \
  panel_no_apply_test \
  panel_secret_safety_test
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for block in \
  "19.1" \
  "19.2" \
  "19.3" \
  "19.4" \
  "19.5" \
  "19.6"
do
  grep -q "$block" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory block eksik: $block"
    cat "$INVENTORY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_19_7_PANEL_UX_TEST_SET=PASS ✅"
echo "PHASE4B_19_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4B_19_CONTRACT_ARTIFACT_TEST=PASS ✅"
echo "PHASE4B_19_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_19_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4B_19_SECRET_SAFETY_TEST=PASS ✅"
