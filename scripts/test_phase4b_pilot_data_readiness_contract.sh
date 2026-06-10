#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_pilot_data_readiness_contract.sh"
PY_SCRIPT="scripts/phase4b_pilot_data_readiness_contract.py"
REPORT="docs/phase4/16_4_pilot_data_readiness_contract_report.md"
MATRIX="docs/phase4/16_4_pilot_data_readiness_contract_matrix.tsv"
PRODUCTS="docs/phase4/16_4_pilot_sample_product_dataset.tsv"
STOCK="docs/phase4/16_4_pilot_sample_stock_dataset.tsv"
PARTY="docs/phase4/16_4_pilot_sample_party_dataset.tsv"
SALES="docs/phase4/16_4_pilot_sample_sales_accounting_dataset.tsv"
QUALITY="docs/phase4/16_4_pilot_data_quality_gate_matrix.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ pilot data readiness wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ pilot data readiness python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_16_4_pilot_data_readiness_contract.log 2>&1 || {
  echo "TEST_FAIL ❌ pilot data readiness contract script hata verdi"
  cat /tmp/pix2pi_16_4_pilot_data_readiness_contract.log || true
  sed -n '1,3400p' "$REPORT" || true
  exit 1
}

for required in \
  "PILOT_DATA_READINESS_CONTRACT=PASS" \
  "FAZ4B_16_4_FINAL_STATUS=PASS" \
  "PILOT_DATA_PREVIOUS_16_3=PASS" \
  "PILOT_PRODUCT_SAMPLE_DATASET=PASS" \
  "PILOT_STOCK_SAMPLE_DATASET=PASS" \
  "PILOT_PARTY_SAMPLE_DATASET=PASS" \
  "PILOT_SALES_ACCOUNTING_SAMPLE_DATASET=PASS" \
  "PILOT_DATA_QUALITY_GATE_MATRIX=PASS" \
  "PILOT_DATA_NO_RUNTIME_CHANGE=PASS" \
  "PILOT_DATA_NO_CONFIG_CHANGE=PASS" \
  "PILOT_DATA_SECRET_SAFE=PASS" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "FIREWALL_CHANGED=NO" \
  "PORT_CHANGED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "SAMPLE_DATA_INSERTED=NO" \
  "REAL_CUSTOMER_DATA_CREATED=NO" \
  "REAL_PRODUCT_CREATED=NO" \
  "REAL_STOCK_MUTATED=NO" \
  "REAL_SALE_CREATED=NO" \
  "REAL_ACCOUNTING_ENTRY_CREATED=NO" \
  "DATA_IMPORT_EXECUTED=NO" \
  "FILE_EXPORT_EXECUTED=NO" \
  "UI_CODE_CHANGED=NO" \
  "API_ROUTE_CREATED=NO" \
  "API_IMPLEMENTATION_CHANGED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "EVENT_PUBLISHED=NO" \
  "EVENT_CONSUMED=NO" \
  "NOTIFICATION_SENT=NO" \
  "CUSTOMER_PRIVATE_DATA_PRINTED=NO" \
  "RAW_DSN_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO" \
  "TOKEN_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,3400p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$PRODUCTS" "$STOCK" "$PARTY" "$SALES" "$QUALITY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_16_3 \
  product_sample_dataset \
  stock_sample_dataset \
  party_sample_dataset \
  sales_accounting_sample_dataset \
  data_quality_gate_matrix \
  no_runtime_change \
  no_config_change \
  secret_safe
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for product in \
  sample_product_barcode_standard \
  sample_product_weighted \
  sample_product_vat_10 \
  sample_product_vat_20 \
  sample_product_zero_stock \
  sample_product_refundable \
  sample_service_item
do
  grep -q "$product" "$PRODUCTS" || {
    echo "TEST_FAIL ❌ product sample eksik: $product"
    cat "$PRODUCTS" || true
    exit 1
  }
done

for stock_case in \
  opening_stock_positive \
  sale_stock_decrease \
  refund_stock_increase \
  cancel_reversal \
  low_stock_threshold_cross \
  negative_stock_guard
do
  grep -q "$stock_case" "$STOCK" || {
    echo "TEST_FAIL ❌ stock case eksik: $stock_case"
    cat "$STOCK" || true
    exit 1
  }
done

for party in \
  sample_cash_customer \
  sample_registered_customer \
  sample_corporate_customer \
  sample_vendor \
  sample_branch_cashdesk
do
  grep -q "$party" "$PARTY" || {
    echo "TEST_FAIL ❌ party sample eksik: $party"
    cat "$PARTY" || true
    exit 1
  }
done

for flow in \
  cash_sale_standard \
  card_sale_standard \
  registered_customer_sale \
  refund_cash_sale \
  cancel_sale_reversal \
  daily_cash_report \
  audit_report_after_mutation
do
  grep -q "$flow" "$SALES" || {
    echo "TEST_FAIL ❌ sales/accounting flow eksik: $flow"
    cat "$SALES" || true
    exit 1
  }
done

for quality in \
  synthetic_data_only \
  no_real_customer_private_data \
  tenant_scope_required \
  sale_stock_accounting_chain_ready \
  refund_cancel_chain_ready \
  tdhp_accounting_review_ready \
  negative_stock_guard_ready \
  go_no_go_data_ready
do
  grep -q "$quality" "$QUALITY" || {
    echo "TEST_FAIL ❌ quality gate eksik: $quality"
    cat "$QUALITY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$PRODUCTS" "$STOCK" "$PARTY" "$SALES" "$QUALITY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$PRODUCTS" "$STOCK" "$PARTY" "$SALES" "$QUALITY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$PRODUCTS" "$STOCK" "$PARTY" "$SALES" "$QUALITY"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_PILOT_DATA_READINESS_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_PILOT_PRODUCT_SAMPLE_DATASET_TEST=PASS ✅"
echo "PHASE4B_PILOT_STOCK_SAMPLE_DATASET_TEST=PASS ✅"
echo "PHASE4B_PILOT_PARTY_SAMPLE_DATASET_TEST=PASS ✅"
echo "PHASE4B_PILOT_SALES_ACCOUNTING_SAMPLE_DATASET_TEST=PASS ✅"
echo "PHASE4B_PILOT_DATA_QUALITY_GATE_MATRIX_TEST=PASS ✅"
echo "PHASE4B_PILOT_DATA_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_PILOT_DATA_SECRET_TEST=PASS ✅"
