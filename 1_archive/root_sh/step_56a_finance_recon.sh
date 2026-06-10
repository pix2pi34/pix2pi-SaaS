#!/usr/bin/env bash
set -euo pipefail

OUT="$HOME/pix2pi/pix2pi-SaaS/step_56a_finance_recon.txt"

{
  echo "==== STEP 56A / FINANCE EVENT RECON ===="
  echo

  echo "==== 1) CMD DOSYALARI ===="
  find ~/pix2pi/pix2pi-SaaS/cmd -type f | grep -E 'finance|accounting|journal|ufk|event'
  echo

  echo "==== 2) FINANCE / ACCOUNTING / JOURNAL / UFK DOSYALARI ===="
  find ~/pix2pi/pix2pi-SaaS/internal -type f | grep -E 'finance|accounting|journal|ufk|event'
  echo

  echo "==== 3) NATS / SUBSCRIBE / PUBLISH ===="
  grep -RInE 'nats|Subscribe|QueueSubscribe|Publish|JetStream|user.created|sale.created|pix2pi\.' ~/pix2pi/pix2pi-SaaS/cmd ~/pix2pi/pix2pi-SaaS/internal || true
  echo

  echo "==== 4) FINANCIAL EVENT / JOURNAL BUILDER / ACCOUNTING ENGINE ===="
  grep -RInE 'FinancialEvent|Journal|journal|Accounting|accounting|UFK|ufk|Ledger|ledger' ~/pix2pi/pix2pi-SaaS/internal || true
  echo

  echo "==== 5) OLASI FINANCE MAIN DOSYASI ===="
  if [ -f ~/pix2pi/pix2pi-SaaS/cmd/accounting-service/accounting_service_main.go ]; then
    cat -n ~/pix2pi/pix2pi-SaaS/cmd/accounting-service/accounting_service_main.go
  fi
  echo

  echo "==== 6) OLASI UFK ENGINE ===="
  grep -RIl 'type.*Engine\|func.*Process\|func.*Handle' ~/pix2pi/pix2pi-SaaS/internal/erp 2>/dev/null | grep -E 'ufk|accounting|journal|event' | while read -r f; do
    echo "---- FILE: $f ----"
    cat -n "$f"
    echo
  done

  echo "OK ✅ STEP 56A recon tamam"
} > "$OUT"

echo "OK ✅ rapor olustu -> $OUT"
sed -n '1,260p' "$OUT"
