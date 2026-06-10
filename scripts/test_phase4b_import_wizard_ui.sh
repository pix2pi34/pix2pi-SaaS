#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_import_wizard_ui.sh"
PY_SCRIPT="scripts/phase4b_import_wizard_ui.py"
REPORT="docs/phase4/19_4_import_wizard_ui_report.md"
MATRIX="docs/phase4/19_4_import_wizard_ui_matrix.tsv"
CONTRACT="docs/phase4/19_4_import_wizard_ui_contract.md"
ROUTES="docs/phase4/19_4_import_wizard_ui_route_manifest.tsv"
STEPS="docs/phase4/19_4_import_wizard_ui_step_manifest.tsv"
COMPONENTS="docs/phase4/19_4_import_wizard_ui_component_manifest.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ import wizard wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ import wizard python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_19_4_import_wizard_ui.log 2>&1 || {
  echo "TEST_FAIL ❌ import wizard ui script hata verdi"
  cat /tmp/pix2pi_19_4_import_wizard_ui.log || true
  sed -n '1,1700p' "$REPORT" || true
  exit 1
}

for required in \
  "IMPORT_WIZARD_UI=PASS" \
  "FAZ4B_19_4_FINAL_STATUS=PASS" \
  "IMPORT_WIZARD_PREVIOUS_19_3=PASS" \
  "IMPORT_WIZARD_CONTRACT=PASS" \
  "IMPORT_WIZARD_ROUTE_MANIFEST=PASS" \
  "IMPORT_WIZARD_STEP_MANIFEST=PASS" \
  "IMPORT_WIZARD_COMPONENT_MANIFEST=PASS" \
  "IMPORT_WIZARD_TENANT_SAFETY=PASS" \
  "IMPORT_WIZARD_FLOW_LINK_STATUS=PASS" \
  "IMPORT_WIZARD_NO_APPLY=PASS" \
  "IMPORT_WIZARD_SECRET_SAFETY=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "FILE_UPLOAD_EXECUTED=NO" \
  "IMPORT_RUNTIME_EXECUTED=NO" \
  "IMPORT_COMMIT_EXECUTED=NO" \
  "PANEL_ROUTE_DEPLOYED=NO" \
  "PANEL_BUILD_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1700p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$CONTRACT" "$ROUTES" "$STEPS" "$COMPONENTS"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for route in \
  "/api/v1/admin/imports/templates" \
  "/api/v1/admin/imports/upload" \
  "/api/v1/admin/imports/:import_batch_id/mapping" \
  "/api/v1/admin/imports/:import_batch_id/validate" \
  "/api/v1/admin/imports/:import_batch_id/preview" \
  "/api/v1/admin/imports/:import_batch_id/errors" \
  "/api/v1/admin/imports/:import_batch_id/commit-plan" \
  "/api/v1/admin/imports/history"
do
  grep -q "$route" "$ROUTES" || {
    echo "TEST_FAIL ❌ route eksik: $route"
    exit 1
  }
done

for step in \
  ImportTemplateStep \
  ImportUploadStep \
  ImportMappingStep \
  ImportValidationStep \
  ImportPreviewStep \
  ImportErrorDownloadStep \
  ImportCommitPlanStep \
  ImportHistoryLinkStep
do
  grep -q "$step" "$STEPS" || {
    echo "TEST_FAIL ❌ step eksik: $step"
    exit 1
  }
done

for component in \
  ImportWizardShell \
  ImportStepIndicator \
  ImportTemplateSelector \
  ImportFileDropzone \
  ImportFileSummary \
  ImportColumnMapper \
  ImportValidationPanel \
  ImportPreviewTable \
  ImportErrorDownloadPanel \
  ImportCommitPlanPanel \
  ImportHistoryLinkPanel \
  ImportFlowLinkPanel \
  ImportEmptyState \
  ImportLoadingState \
  ImportErrorState
do
  grep -q "$component" "$COMPONENTS" || {
    echo "TEST_FAIL ❌ component eksik: $component"
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$CONTRACT" "$ROUTES" "$STEPS" "$COMPONENTS"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$CONTRACT" "$ROUTES" "$STEPS" "$COMPONENTS"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$CONTRACT" "$ROUTES" "$STEPS" "$COMPONENTS"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_IMPORT_WIZARD_UI_TEST=PASS ✅"
echo "PHASE4B_IMPORT_WIZARD_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_IMPORT_WIZARD_ROUTE_MANIFEST_TEST=PASS ✅"
echo "PHASE4B_IMPORT_WIZARD_STEP_MANIFEST_TEST=PASS ✅"
echo "PHASE4B_IMPORT_WIZARD_COMPONENT_TEST=PASS ✅"
echo "PHASE4B_IMPORT_WIZARD_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_IMPORT_WIZARD_SECRET_TEST=PASS ✅"
