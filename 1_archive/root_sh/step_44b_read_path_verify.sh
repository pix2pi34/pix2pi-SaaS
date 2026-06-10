#!/bin/bash
set -euo pipefail

ROOT="$HOME/pix2pi/pix2pi-SaaS"
OUT="$ROOT/step_44b_read_path_report.txt"

echo "=== STEP 44B / READ PATH CODE VERIFICATION ==="

cd "$ROOT"

{
  echo "===== A) QUERY ROUTE GECIYOR MU ====="
  grep -RniE 'api/query/users|/query/users|query/users' cmd internal || true
  echo

  echo "===== B) HANDLER / CONTROLLER ADAYLARI ====="
  grep -RniE 'user_count|status":"ok"|ListUsers|CountUsers|QueryUsers|GetUsers' cmd internal || true
  echo

  echo "===== C) READ DB KULLANIMI ====="
  grep -RniE 'GetReadDB\(|ReadDB|read db|readDB' cmd internal || true
  echo

  echo "===== D) WRITE DB KULLANIMI ====="
  grep -RniE 'GetWriteDB\(|WriteDB|write db|writeDB' cmd internal || true
  echo

  echo "===== E) KERNEL DOSYASI ====="
  if [ -f internal/platform/kernel/kernel.go ]; then
    nl -ba internal/platform/kernel/kernel.go | sed -n '1,220p'
  else
    echo "kernel.go bulunamadi"
  fi
  echo

  echo "===== F) API GATEWAY MAIN ====="
  if [ -f cmd/api-gateway/api_gateway_main.go ]; then
    nl -ba cmd/api-gateway/api_gateway_main.go | sed -n '1,260p'
  else
    echo "cmd/api-gateway/api_gateway_main.go bulunamadi"
  fi
  echo

  echo "===== G) QUERY / USER ILE ILGILI DOSYALAR ====="
  find cmd internal -type f | grep -Ei 'query|user' | sort || true
  echo

  echo "===== H) USER/QUERY DOSYALARININ ICERIGI ====="
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    echo "----- FILE: $f -----"
    nl -ba "$f" | sed -n '1,260p'
    echo
  done < <(find cmd internal -type f | grep -Ei 'query|user' | sort || true)

  echo "===== I) DERLEME TESTI ====="
  go test ./... >/tmp/step_44b_go_test.out 2>/tmp/step_44b_go_test.err || true
  echo "--- go test stdout ---"
  cat /tmp/step_44b_go_test.out || true
  echo
  echo "--- go test stderr ---"
  cat /tmp/step_44b_go_test.err || true
  echo

  echo "===== J) CANLI ENDPOINT KONTROL ====="
  curl -sS -i http://127.0.0.1:9010/health || true
  echo
  curl -sS -i http://127.0.0.1:9010/api/query/users || true
  echo
} > "$OUT"

echo "OK ✅ rapor olustu -> $OUT"
echo
echo "===== RAPOR EKRANA BASILIYOR ====="
cat "$OUT"
echo
echo "OK ✅ STEP 44B rapor üretimi tamam"
