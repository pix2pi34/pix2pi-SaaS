#!/usr/bin/env bash
set -e

OUT=~/pix2pi/pix2pi-SaaS/step_56c_finance_flow_recon.txt

echo "===== STEP 56C / FINANCE FLOW RECON =====" > "$OUT"
echo >> "$OUT"

echo "===== 1) ACCOUNTING SERVICE MAIN =====" >> "$OUT"
cat -n ~/pix2pi/pix2pi-SaaS/cmd/accounting-service/accounting_service_main.go >> "$OUT" 2>/dev/null || true
echo >> "$OUT"

echo "===== 2) FINANCIAL EVENT SERVICE =====" >> "$OUT"
cat -n ~/pix2pi/pix2pi-SaaS/internal/erp/core/events/service/erp_financial_event_service.go >> "$OUT" 2>/dev/null || true
echo >> "$OUT"

echo "===== 3) JOURNAL BUILDER =====" >> "$OUT"
cat -n ~/pix2pi/pix2pi-SaaS/internal/erp/core/journal/service/erp_journal_builder_service.go >> "$OUT" 2>/dev/null || true
echo >> "$OUT"

echo "===== 4) LEDGER POSTING SERVICE =====" >> "$OUT"
cat -n ~/pix2pi/pix2pi-SaaS/internal/erp/core/ufk/service/erp_ledger_posting_service.go >> "$OUT" 2>/dev/null || true
echo >> "$OUT"

echo "===== 5) CAGRI ZINCIRI ARAMA =====" >> "$OUT"
grep -R -n -E 'sale.created|Build\(|Apply|Post\(|NewJournalBuilderService|NewLedgerPostingService|NewFinancialEventService' \
  ~/pix2pi/pix2pi-SaaS/cmd/accounting-service \
  ~/pix2pi/pix2pi-SaaS/internal/erp/core \
  >> "$OUT" 2>/dev/null || true
echo >> "$OUT"

echo "OK ✅ rapor olustu -> $OUT"
sed -n '1,260p' "$OUT"
