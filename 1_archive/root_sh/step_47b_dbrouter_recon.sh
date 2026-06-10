#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/pix2pi/pix2pi-SaaS"
OUT="$ROOT/step_47b_dbrouter_recon.txt"

{
  echo "=== STEP 47B / DBROUTER RECON ==="
  echo

  echo "==== 1) query_read_model service.go ===="
  nl -ba "$ROOT/internal/services/query_read_model/service.go" | sed -n '1,120p'
  echo

  echo "==== 2) dbrouter kelimesi nerelerde geciyor ===="
  grep -Rni "dbrouter" "$ROOT/cmd" "$ROOT/internal" || true
  echo

  echo "==== 3) GetReadDB / readDB / DB_READ_DSN / fallback ===="
  grep -RniE "GetReadDB|GetWriteDB|readDB|DB_READ_DSN|fallback primary|Init.*dbrouter|Init.*read|Open.*read" "$ROOT/cmd" "$ROOT/internal" || true
  echo

  echo "==== 4) api gateway main ===="
  if [ -f "$ROOT/cmd/api-gateway/api_gateway_main.go" ]; then
    nl -ba "$ROOT/cmd/api-gateway/api_gateway_main.go" | sed -n '1,260p'
  else
    echo "api_gateway_main.go bulunamadi"
  fi
  echo

  echo "==== 5) dbrouter dosyalari ===="
  if [ -d "$ROOT/internal/platform/dbrouter" ]; then
    find "$ROOT/internal/platform/dbrouter" -maxdepth 1 -type f | sort
    echo
    for f in "$ROOT"/internal/platform/dbrouter/*.go; do
      [ -f "$f" ] || continue
      echo "----- FILE: $f -----"
      nl -ba "$f" | sed -n '1,260p'
      echo
    done
  else
    echo "internal/platform/dbrouter klasoru bulunamadi"
  fi
  echo

  echo "==== 6) systemd service dosyasi ===="
  systemctl cat pix2pi-api-gateway.service || true
  echo

  echo "==== 7) runtime env snapshot ===="
  if [ -f /opt/pix2pi/orchestrator/env/common.env ]; then
    set +u
    source /opt/pix2pi/orchestrator/env/common.env
    printf 'DB_WRITE_DSN=%s\n' "${DB_WRITE_DSN:-}"
    printf 'DB_READ_DSN=%s\n' "${DB_READ_DSN:-}"
    set -u
  else
    echo "/opt/pix2pi/orchestrator/env/common.env yok"
  fi
  echo

  echo "OK ✅ STEP 47B rapor tamamladi"
} > "$OUT"

echo "OK ✅ rapor olustu -> $OUT"
sed -n '1,260p' "$OUT"
