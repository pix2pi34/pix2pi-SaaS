#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_infra_cleanup_production_hardening_final_closure.sh"
PY_SCRIPT="scripts/phase4b_infra_cleanup_production_hardening_final_closure.py"
REPORT="docs/phase4/20_8_infra_cleanup_production_hardening_final_closure_report.md"
MATRIX="docs/phase4/20_8_infra_cleanup_production_hardening_final_closure_matrix.tsv"
INVENTORY="docs/phase4/20_8_infra_cleanup_production_hardening_final_closure_inventory.tsv"
CLOSURE="docs/phase4/20_infra_cleanup_production_hardening_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ infra final closure wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ infra final closure python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_20_8_infra_final_closure.log 2>&1 || {
  echo "TEST_FAIL ❌ infra final closure script hata verdi"
  cat /tmp/pix2pi_20_8_infra_final_closure.log || true
  sed -n '1,3200p' "$REPORT" || true
  exit 1
}

for required in \
  "INFRA_PRODUCTION_HARDENING_FINAL_CLOSURE=PASS" \
  "FAZ4B_20_8_FINAL_STATUS=PASS" \
  "FAZ4B_20_FINAL_STATUS=PASS" \
  "INFRA_FINAL_CLEANUP=PASS" \
  "INFRA_FINAL_CONFIG_ENV=PASS" \
  "INFRA_FINAL_RUNTIME_SERVICE=PASS" \
  "INFRA_FINAL_NGINX=PASS" \
  "INFRA_FINAL_DOCKER=PASS" \
  "INFRA_FINAL_BACKUP_ARCHIVE=PASS" \
  "INFRA_FINAL_PRODUCTION_TESTS=PASS" \
  "INFRA_FINAL_ARTIFACT_COVERAGE=PASS" \
  "INFRA_FINAL_NO_CHANGE=PASS" \
  "INFRA_FINAL_RISK_EVIDENCE=PASS" \
  "INFRA_FINAL_SECRET_SAFE=PASS" \
  "FILE_DELETE_EXECUTED=NO" \
  "FILE_MOVE_EXECUTED=NO" \
  "FILE_PERMISSION_CHANGED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "FIREWALL_CHANGED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "DOCKER_VOLUME_CHANGED=NO" \
  "DOCKER_PORT_CHANGED=NO" \
  "DOCKER_PRUNE_EXECUTED=NO" \
  "RESTIC_PRUNE_EXECUTED=NO" \
  "RESTORE_EXECUTED=NO" \
  "PG_DUMP_EXECUTED=NO" \
  "PG_RESTORE_EXECUTED=NO" \
  "SERVICE_RESTARTED=NO" \
  "DEPLOY_EXECUTED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "LOG_CONTENT_PRINTED=NO" \
  "QUERY_TEXT_PRINTED=NO" \
  "RAW_DSN_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,3200p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY" "$CLOSURE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

grep -q "FAZ4B_20_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ closure report final status PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

for gate in \
  cleanup \
  config_env \
  runtime_service \
  nginx_reverse_proxy \
  docker_compose \
  backup_archive \
  production_tests \
  artifact_coverage \
  no_change \
  risk_evidence \
  secret_safe
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for block in \
  "20.1" \
  "20.2" \
  "20.3" \
  "20.4" \
  "20.5" \
  "20.6" \
  "20.7"
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

echo "PHASE4B_20_8_INFRA_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4B_20_FINAL_STATUS_TEST=PASS ✅"
echo "PHASE4B_20_INFRA_ARTIFACT_TEST=PASS ✅"
echo "PHASE4B_20_INFRA_NO_CHANGE_TEST=PASS ✅"
echo "PHASE4B_20_INFRA_RISK_EVIDENCE_TEST=PASS ✅"
echo "PHASE4B_20_INFRA_SECRET_TEST=PASS ✅"
