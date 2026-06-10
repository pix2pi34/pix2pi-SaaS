#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_runtime_service_hardening.sh"
PY_SCRIPT="scripts/phase4b_runtime_service_hardening.py"
REPORT="docs/phase4/20_3_runtime_service_hardening_report.md"
MATRIX="docs/phase4/20_3_runtime_service_hardening_matrix.tsv"
SERVICES="docs/phase4/20_3_runtime_service_hardening_services.tsv"
PORTS="docs/phase4/20_3_runtime_service_hardening_ports.tsv"
CONTAINERS="docs/phase4/20_3_runtime_service_hardening_containers.tsv"
POLICY="docs/phase4/20_3_runtime_service_hardening_policy.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ runtime hardening wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ runtime hardening python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_20_3_runtime_service_hardening.log 2>&1 || {
  echo "TEST_FAIL ❌ runtime service hardening script hata verdi"
  cat /tmp/pix2pi_20_3_runtime_service_hardening.log || true
  sed -n '1,2400p' "$REPORT" || true
  exit 1
}

for required in \
  "RUNTIME_SERVICE_HARDENING=PASS" \
  "FAZ4B_20_3_FINAL_STATUS=PASS" \
  "RUNTIME_SERVICE_PREVIOUS_20_2=PASS" \
  "RUNTIME_SERVICE_SYSTEMD_INVENTORY=PASS" \
  "RUNTIME_SERVICE_PORT_INVENTORY=PASS" \
  "RUNTIME_SERVICE_CONTAINER_INVENTORY=PASS" \
  "RUNTIME_SERVICE_HARDENING_MATRIX=PASS" \
  "RUNTIME_SERVICE_NO_RESTART=PASS" \
  "RUNTIME_SERVICE_NO_DEPLOY=PASS" \
  "RUNTIME_SERVICE_SECRET_SAFE=PASS" \
  "SERVICE_RESTARTED=NO" \
  "SERVICE_STARTED=NO" \
  "SERVICE_STOPPED=NO" \
  "SYSTEMD_UNIT_CHANGED=NO" \
  "SYSTEMD_ENABLE_CHANGED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "DEPLOY_EXECUTED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "FILE_PERMISSION_CHANGED=NO" \
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
    sed -n '1,2400p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$SERVICES" "$PORTS" "$CONTAINERS" "$POLICY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_20_2 \
  systemd_inventory \
  port_inventory \
  container_inventory \
  service_hardening_candidates \
  port_hardening_candidates \
  container_hardening_candidates \
  no_restart \
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
  "service_name" \
  "category" \
  "risk" \
  "active_state" \
  "restart_policy"
do
  grep -q "$header" "$SERVICES" || {
    echo "TEST_FAIL ❌ services header eksik: $header"
    cat "$SERVICES" || true
    exit 1
  }
done

for header in \
  "netid" \
  "local_address" \
  "port" \
  "bind_scope" \
  "risk"
do
  grep -q "$header" "$PORTS" || {
    echo "TEST_FAIL ❌ ports header eksik: $header"
    cat "$PORTS" || true
    exit 1
  }
done

for header in \
  "container_name" \
  "image" \
  "status" \
  "risk"
do
  grep -q "$header" "$CONTAINERS" || {
    echo "TEST_FAIL ❌ containers header eksik: $header"
    cat "$CONTAINERS" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$SERVICES" "$PORTS" "$CONTAINERS" "$POLICY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$SERVICES" "$PORTS" "$CONTAINERS" "$POLICY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$SERVICES" "$PORTS" "$CONTAINERS" "$POLICY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_RUNTIME_SERVICE_HARDENING_TEST=PASS ✅"
echo "PHASE4B_RUNTIME_SERVICE_SYSTEMD_TEST=PASS ✅"
echo "PHASE4B_RUNTIME_SERVICE_PORT_TEST=PASS ✅"
echo "PHASE4B_RUNTIME_SERVICE_CONTAINER_TEST=PASS ✅"
echo "PHASE4B_RUNTIME_SERVICE_NO_RESTART_TEST=PASS ✅"
echo "PHASE4B_RUNTIME_SERVICE_SECRET_TEST=PASS ✅"
