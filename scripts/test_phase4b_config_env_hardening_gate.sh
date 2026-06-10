#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_config_env_hardening_gate.sh"
PY_SCRIPT="scripts/phase4b_config_env_hardening_gate.py"
REPORT="docs/phase4/20_2_config_env_hardening_report.md"
MATRIX="docs/phase4/20_2_config_env_hardening_matrix.tsv"
INVENTORY="docs/phase4/20_2_config_env_hardening_inventory.tsv"
POLICY="docs/phase4/20_2_config_env_hardening_policy.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ config/env hardening wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ config/env hardening python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_20_2_config_env_hardening_gate.log 2>&1 || {
  echo "TEST_FAIL ❌ config/env hardening gate script hata verdi"
  cat /tmp/pix2pi_20_2_config_env_hardening_gate.log || true
  sed -n '1,2400p' "$REPORT" || true
  exit 1
}

for required in \
  "CONFIG_ENV_HARDENING_GATE=PASS" \
  "FAZ4B_20_2_FINAL_STATUS=PASS" \
  "CONFIG_ENV_PREVIOUS_20_1=PASS" \
  "CONFIG_ENV_BASELINE=PASS" \
  "CONFIG_ENV_INVENTORY=PASS" \
  "CONFIG_ENV_PERMISSION_EVIDENCE=PASS" \
  "CONFIG_ENV_VALUE_NOT_PRINTED=PASS" \
  "CONFIG_ENV_NO_CHANGE=PASS" \
  "CONFIG_ENV_NO_DEPLOY=PASS" \
  "CONFIG_ENV_SECRET_SAFE=PASS" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "FILE_PERMISSION_CHANGED=NO" \
  "FILE_DELETE_EXECUTED=NO" \
  "FILE_MOVE_EXECUTED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "DEPLOY_EXECUTED=NO" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "QUERY_TEXT_PRINTED=NO" \
  "RAW_DSN_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,2400p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY" "$POLICY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_20_1 \
  baseline \
  inventory \
  permission_evidence \
  env_files \
  config_files \
  potential_secret_paths \
  secret_key_names \
  dsn_key_names \
  value_not_printed \
  no_change \
  no_deploy \
  secret_safe
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for header in \
  "path" \
  "category" \
  "permission_category" \
  "risk" \
  "mode" \
  "secret_key_name_count" \
  "dsn_key_name_count"
do
  grep -q "$header" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory header eksik: $header"
    cat "$INVENTORY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$INVENTORY" "$POLICY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$INVENTORY" "$POLICY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$INVENTORY" "$POLICY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_CONFIG_ENV_HARDENING_GATE_TEST=PASS ✅"
echo "PHASE4B_CONFIG_ENV_BASELINE_TEST=PASS ✅"
echo "PHASE4B_CONFIG_ENV_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_CONFIG_ENV_PERMISSION_EVIDENCE_TEST=PASS ✅"
echo "PHASE4B_CONFIG_ENV_NO_CHANGE_TEST=PASS ✅"
echo "PHASE4B_CONFIG_ENV_SECRET_TEST=PASS ✅"
