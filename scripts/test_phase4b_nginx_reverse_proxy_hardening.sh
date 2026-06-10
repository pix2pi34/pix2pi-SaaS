#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_nginx_reverse_proxy_hardening.sh"
PY_SCRIPT="scripts/phase4b_nginx_reverse_proxy_hardening.py"
REPORT="docs/phase4/20_4_nginx_reverse_proxy_hardening_report.md"
MATRIX="docs/phase4/20_4_nginx_reverse_proxy_hardening_matrix.tsv"
CONFIG_INV="docs/phase4/20_4_nginx_reverse_proxy_config_inventory.tsv"
PROXY_SURFACE="docs/phase4/20_4_nginx_reverse_proxy_surface_manifest.tsv"
PORT_POLICY="docs/phase4/20_4_nginx_public_port_policy.tsv"
POLICY="docs/phase4/20_4_nginx_reverse_proxy_hardening_policy.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ nginx reverse proxy wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ nginx reverse proxy python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_20_4_nginx_reverse_proxy_hardening.log 2>&1 || {
  echo "TEST_FAIL ❌ nginx reverse proxy hardening script hata verdi"
  cat /tmp/pix2pi_20_4_nginx_reverse_proxy_hardening.log || true
  sed -n '1,2600p' "$REPORT" || true
  exit 1
}

for required in \
  "NGINX_REVERSE_PROXY_HARDENING=PASS" \
  "FAZ4B_20_4_FINAL_STATUS=PASS" \
  "NGINX_REVERSE_PROXY_PREVIOUS_20_3=PASS" \
  "NGINX_CONFIG_INVENTORY=PASS" \
  "NGINX_PROXY_SURFACE_MANIFEST=PASS" \
  "NGINX_PUBLIC_PORT_POLICY=PASS" \
  "NGINX_HARDENING_MATRIX=PASS" \
  "NGINX_NO_RELOAD=PASS" \
  "NGINX_NO_FIREWALL_CHANGE=PASS" \
  "NGINX_NO_DEPLOY=PASS" \
  "NGINX_SECRET_SAFE=PASS" \
  "NGINX_CONFIG_CHANGED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "NGINX_RESTARTED=NO" \
  "FIREWALL_CHANGED=NO" \
  "PORT_CHANGED=NO" \
  "DOCKER_PORT_CHANGED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "SERVICE_RESTARTED=NO" \
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
    sed -n '1,2600p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$CONFIG_INV" "$PROXY_SURFACE" "$PORT_POLICY" "$POLICY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_20_3 \
  config_inventory \
  proxy_surface_manifest \
  public_port_policy \
  allowed_public_ports \
  management_public_ports \
  internal_should_not_public \
  unknown_public_review \
  no_reload \
  no_firewall_change \
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
  "config_path" \
  "proxy_pass_count" \
  "security_header_count" \
  "ssl_marker_count"
do
  grep -q "$header" "$CONFIG_INV" || {
    echo "TEST_FAIL ❌ config inventory header eksik: $header"
    cat "$CONFIG_INV" || true
    exit 1
  }
done

for header in \
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

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$CONFIG_INV" "$PROXY_SURFACE" "$PORT_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$CONFIG_INV" "$PROXY_SURFACE" "$PORT_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$CONFIG_INV" "$PROXY_SURFACE" "$PORT_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_NGINX_REVERSE_PROXY_HARDENING_TEST=PASS ✅"
echo "PHASE4B_NGINX_CONFIG_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_NGINX_PROXY_SURFACE_TEST=PASS ✅"
echo "PHASE4B_NGINX_PUBLIC_PORT_POLICY_TEST=PASS ✅"
echo "PHASE4B_NGINX_NO_RELOAD_TEST=PASS ✅"
echo "PHASE4B_NGINX_SECRET_TEST=PASS ✅"
