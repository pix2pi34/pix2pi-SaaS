#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_docker_compose_hardening.sh"
PY_SCRIPT="scripts/phase4b_docker_compose_hardening.py"
REPORT="docs/phase4/20_5_docker_compose_hardening_report.md"
MATRIX="docs/phase4/20_5_docker_compose_hardening_matrix.tsv"
CONTAINERS="docs/phase4/20_5_docker_container_inventory.tsv"
COMPOSE="docs/phase4/20_5_docker_compose_inventory.tsv"
NETWORKS="docs/phase4/20_5_docker_network_inventory.tsv"
VOLUMES="docs/phase4/20_5_docker_volume_inventory.tsv"
PORT_POLICY="docs/phase4/20_5_docker_public_port_policy.tsv"
POLICY="docs/phase4/20_5_docker_compose_hardening_policy.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ docker compose hardening wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ docker compose hardening python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_20_5_docker_compose_hardening.log 2>&1 || {
  echo "TEST_FAIL ❌ docker compose hardening script hata verdi"
  cat /tmp/pix2pi_20_5_docker_compose_hardening.log || true
  sed -n '1,2700p' "$REPORT" || true
  exit 1
}

for required in \
  "DOCKER_COMPOSE_HARDENING=PASS" \
  "FAZ4B_20_5_FINAL_STATUS=PASS" \
  "DOCKER_COMPOSE_PREVIOUS_20_4=PASS" \
  "DOCKER_CONTAINER_INVENTORY=PASS" \
  "DOCKER_COMPOSE_INVENTORY=PASS" \
  "DOCKER_NETWORK_INVENTORY=PASS" \
  "DOCKER_VOLUME_INVENTORY=PASS" \
  "DOCKER_PUBLIC_PORT_POLICY=PASS" \
  "DOCKER_HARDENING_MATRIX=PASS" \
  "DOCKER_NO_RUNTIME_CHANGE=PASS" \
  "DOCKER_NO_DEPLOY=PASS" \
  "DOCKER_SECRET_SAFE=PASS" \
  "CONTAINER_RESTARTED=NO" \
  "CONTAINER_STARTED=NO" \
  "CONTAINER_STOPPED=NO" \
  "CONTAINER_REMOVED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "DOCKER_NETWORK_CHANGED=NO" \
  "DOCKER_VOLUME_CHANGED=NO" \
  "DOCKER_PORT_CHANGED=NO" \
  "DOCKER_PRUNE_EXECUTED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "FILE_PERMISSION_CHANGED=NO" \
  "FIREWALL_CHANGED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
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
    sed -n '1,2700p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$CONTAINERS" "$COMPOSE" "$NETWORKS" "$VOLUMES" "$PORT_POLICY" "$POLICY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_20_4 \
  container_inventory \
  compose_inventory \
  network_inventory \
  volume_inventory \
  public_port_policy \
  internal_should_not_public \
  container_hardening_candidates \
  no_runtime_change \
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
  "container_name" \
  "restart_policy" \
  "privileged" \
  "healthcheck_present" \
  "risk"
do
  grep -q "$header" "$CONTAINERS" || {
    echo "TEST_FAIL ❌ container inventory header eksik: $header"
    cat "$CONTAINERS" || true
    exit 1
  }
done

for header in \
  "compose_path" \
  "ports_count" \
  "secret_key_name_count" \
  "risk"
do
  grep -q "$header" "$COMPOSE" || {
    echo "TEST_FAIL ❌ compose inventory header eksik: $header"
    cat "$COMPOSE" || true
    exit 1
  }
done

for header in \
  "host_port" \
  "container_port" \
  "port_policy" \
  "recommended_surface" \
  "risk"
do
  grep -q "$header" "$PORT_POLICY" || {
    echo "TEST_FAIL ❌ public port policy header eksik: $header"
    cat "$PORT_POLICY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$CONTAINERS" "$COMPOSE" "$NETWORKS" "$VOLUMES" "$PORT_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$CONTAINERS" "$COMPOSE" "$NETWORKS" "$VOLUMES" "$PORT_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$CONTAINERS" "$COMPOSE" "$NETWORKS" "$VOLUMES" "$PORT_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_DOCKER_COMPOSE_HARDENING_TEST=PASS ✅"
echo "PHASE4B_DOCKER_CONTAINER_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_DOCKER_COMPOSE_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_DOCKER_NETWORK_VOLUME_TEST=PASS ✅"
echo "PHASE4B_DOCKER_PUBLIC_PORT_POLICY_TEST=PASS ✅"
echo "PHASE4B_DOCKER_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_DOCKER_SECRET_TEST=PASS ✅"
