#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_production_hardening_tests.sh"
PY_SCRIPT="scripts/phase4b_production_hardening_tests.py"
REPORT="docs/phase4/20_7_production_hardening_tests_report.md"
MATRIX="docs/phase4/20_7_production_hardening_tests_matrix.tsv"
INVENTORY="docs/phase4/20_7_production_hardening_tests_inventory.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ production hardening tests wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ production hardening tests python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_20_7_production_hardening_tests.log 2>&1 || {
  echo "TEST_FAIL ❌ production hardening tests script hata verdi"
  cat /tmp/pix2pi_20_7_production_hardening_tests.log || true
  sed -n '1,2800p' "$REPORT" || true
  exit 1
}

for required in \
  "PRODUCTION_HARDENING_TESTS=PASS" \
  "FAZ4B_20_7_FINAL_STATUS=PASS" \
  "PRODUCTION_TEST_CLEANUP=PASS" \
  "PRODUCTION_TEST_CONFIG_ENV=PASS" \
  "PRODUCTION_TEST_RUNTIME_SERVICE=PASS" \
  "PRODUCTION_TEST_NGINX=PASS" \
  "PRODUCTION_TEST_DOCKER=PASS" \
  "PRODUCTION_TEST_BACKUP_ARCHIVE=PASS" \
  "PRODUCTION_TEST_ARTIFACT_COVERAGE=PASS" \
  "PRODUCTION_TEST_NO_CHANGE=PASS" \
  "PRODUCTION_TEST_RISK_EVIDENCE=PASS" \
  "PRODUCTION_TEST_SECRET_SAFE=PASS" \
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
    sed -n '1,2800p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  cleanup \
  config_env \
  runtime_service \
  nginx_reverse_proxy \
  docker_compose \
  backup_archive \
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
  "20.6"
do
  grep -q "$block" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory block eksik: $block"
    cat "$INVENTORY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$INVENTORY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$INVENTORY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$INVENTORY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_PRODUCTION_HARDENING_TESTS_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_HARDENING_CLEANUP_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_HARDENING_CONFIG_ENV_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_HARDENING_RUNTIME_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_HARDENING_NGINX_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_HARDENING_DOCKER_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_HARDENING_BACKUP_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_HARDENING_NO_CHANGE_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_HARDENING_SECRET_TEST=PASS ✅"
