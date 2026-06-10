#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_admin_dashboard_cards.sh"
PY_SCRIPT="scripts/phase4b_admin_dashboard_cards.py"
REPORT="docs/phase4/19_3_admin_dashboard_cards_report.md"
MATRIX="docs/phase4/19_3_admin_dashboard_cards_matrix.tsv"
CONTRACT="docs/phase4/19_3_admin_dashboard_cards_contract.md"
CARDS="docs/phase4/19_3_admin_dashboard_cards_manifest.tsv"
METRICS="docs/phase4/19_3_admin_dashboard_metrics_manifest.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ admin dashboard cards wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ admin dashboard cards python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_19_3_admin_dashboard_cards.log 2>&1 || {
  echo "TEST_FAIL ❌ admin dashboard cards script hata verdi"
  cat /tmp/pix2pi_19_3_admin_dashboard_cards.log || true
  sed -n '1,1600p' "$REPORT" || true
  exit 1
}

for required in \
  "ADMIN_DASHBOARD_CARDS=PASS" \
  "FAZ4B_19_3_FINAL_STATUS=PASS" \
  "ADMIN_DASHBOARD_PREVIOUS_19_2=PASS" \
  "ADMIN_DASHBOARD_CARDS_CONTRACT=PASS" \
  "ADMIN_DASHBOARD_CARD_MANIFEST=PASS" \
  "ADMIN_DASHBOARD_METRIC_MANIFEST=PASS" \
  "ADMIN_DASHBOARD_TENANT_SAFETY=PASS" \
  "ADMIN_DASHBOARD_DRILLDOWN_STATUS=PASS" \
  "ADMIN_DASHBOARD_NO_APPLY=PASS" \
  "ADMIN_DASHBOARD_SECRET_SAFETY=PASS" \
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
    sed -n '1,1600p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$CONTRACT" "$CARDS" "$METRICS"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for card in \
  RuntimeFlowSummaryCard \
  RuntimeErrorCard \
  ImportStatusCard \
  InventoryHealthCard \
  StockReservationCard \
  NegativeStockPolicyCard \
  ReportingHealthCard \
  TenantSafetyCard \
  RecentActivityCard \
  UATReadinessCard
do
  grep -q "$card" "$CARDS" || {
    echo "TEST_FAIL ❌ card eksik: $card"
    exit 1
  }
done

for metric in \
  runtime_flow_total \
  open_error_count \
  import_batch_total \
  stock_movement_count \
  active_reservation_count \
  negative_policy_block_count \
  reporting_freshness_seconds \
  tenant_scope_warning_count \
  recent_activity_count \
  uat_readiness_percent
do
  grep -q "$metric" "$METRICS" || {
    echo "TEST_FAIL ❌ metric eksik: $metric"
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$CONTRACT" "$CARDS" "$METRICS"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$CONTRACT" "$CARDS" "$METRICS"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$CONTRACT" "$CARDS" "$METRICS"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_ADMIN_DASHBOARD_CARDS_TEST=PASS ✅"
echo "PHASE4B_ADMIN_DASHBOARD_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_ADMIN_DASHBOARD_CARD_MANIFEST_TEST=PASS ✅"
echo "PHASE4B_ADMIN_DASHBOARD_METRIC_MANIFEST_TEST=PASS ✅"
echo "PHASE4B_ADMIN_DASHBOARD_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_ADMIN_DASHBOARD_SECRET_TEST=PASS ✅"
