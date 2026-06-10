#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_flow_detail_page.sh"
PY_SCRIPT="scripts/phase4b_flow_detail_page.py"
REPORT="docs/phase4/19_2_flow_detail_page_report.md"
MATRIX="docs/phase4/19_2_flow_detail_page_matrix.tsv"
CONTRACT="docs/phase4/19_2_flow_detail_page_contract.md"
ROUTES="docs/phase4/19_2_flow_detail_page_route_manifest.tsv"
COMPONENTS="docs/phase4/19_2_flow_detail_page_component_manifest.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ flow detail page wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ flow detail page python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_19_2_flow_detail_page.log 2>&1 || {
  echo "TEST_FAIL ❌ flow detail page script hata verdi"
  cat /tmp/pix2pi_19_2_flow_detail_page.log || true
  sed -n '1,1400p' "$REPORT" || true
  exit 1
}

for required in \
  "FLOW_DETAIL_PAGE=PASS" \
  "FAZ4B_19_2_FINAL_STATUS=PASS" \
  "FLOW_DETAIL_PAGE_PREVIOUS_19_1=PASS" \
  "FLOW_DETAIL_PAGE_CONTRACT=PASS" \
  "FLOW_DETAIL_PAGE_ROUTE_MANIFEST=PASS" \
  "FLOW_DETAIL_PAGE_COMPONENT_MANIFEST=PASS" \
  "FLOW_DETAIL_PAGE_TENANT_SAFETY=PASS" \
  "FLOW_DETAIL_PAGE_NO_APPLY=PASS" \
  "FLOW_DETAIL_PAGE_SECRET_SAFETY=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "PANEL_ROUTE_DEPLOYED=NO" \
  "PANEL_BUILD_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1400p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$CONTRACT" "$ROUTES" "$COMPONENTS"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for route in \
  "/api/v1/admin/runtime-flows/:flow_run_id" \
  "/api/v1/admin/runtime-flows/:flow_run_id/steps" \
  "/api/v1/admin/runtime-flows/:flow_run_id/events" \
  "/api/v1/admin/runtime-flows/:flow_run_id/timeline" \
  "/api/v1/admin/runtime-flows/:flow_run_id/errors" \
  "/api/v1/admin/runtime-flows/:flow_run_id/snapshots"
do
  grep -q "$route" "$ROUTES" || {
    echo "TEST_FAIL ❌ route eksik: $route"
    exit 1
  }
done

for component in \
  FlowSummaryHeader \
  FlowStatusBadge \
  FlowTraceBar \
  FlowTimeline \
  FlowStepList \
  FlowEventList \
  FlowErrorPanel \
  FlowSnapshotPanel \
  FlowActionBar \
  FlowEmptyState \
  FlowLoadingState \
  FlowErrorState
do
  grep -q "$component" "$COMPONENTS" || {
    echo "TEST_FAIL ❌ component eksik: $component"
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$CONTRACT" "$ROUTES" "$COMPONENTS"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$CONTRACT" "$ROUTES" "$COMPONENTS"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$CONTRACT" "$ROUTES" "$COMPONENTS"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_FLOW_DETAIL_PAGE_TEST=PASS ✅"
echo "PHASE4B_FLOW_DETAIL_PAGE_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_FLOW_DETAIL_PAGE_ROUTE_MANIFEST_TEST=PASS ✅"
echo "PHASE4B_FLOW_DETAIL_PAGE_COMPONENT_TEST=PASS ✅"
echo "PHASE4B_FLOW_DETAIL_PAGE_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_FLOW_DETAIL_PAGE_SECRET_TEST=PASS ✅"
