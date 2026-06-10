#!/usr/bin/env bash
set -euo pipefail

cd ~/pix2pi/pix2pi-SaaS

set -a
source /opt/pix2pi/orchestrator/env/common.env
set +a

echo "===== STEP 56G / PROD FINANCE SMOKE ====="

echo
echo "===== 1) SERVICE CHECK ====="
systemctl is-active pix2pi-accounting.service
echo "OK ✅ accounting service active"

START_TS="$(date '+%Y-%m-%d %H:%M:%S')"
SALE_ID="S-56G-$(date +%s)"

echo
echo "===== 2) PUBLISH SALE ====="
cat <<GOEOF > /tmp/step_56g_publish_sale.go
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/nats-io/nats.go"
)

func envOr(key, fallback string) string {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return fallback
	}
	return v
}

func main() {
	natsURL := envOr("NATS_URL", nats.DefaultURL)

	nc, err := nats.Connect(natsURL, nats.Name("step-56g-sale-publisher"))
	if err != nil {
		panic(err)
	}
	defer nc.Close()

	payload := map[string]interface{}{
		"event":          "sale.created",
		"sale_id":        "${SALE_ID}",
		"tenant_id":      "tenant-001",
		"amount":         1200,
		"payment_method": "cash",
		"currency":       "TRY",
		"document_no":    "DOC-${SALE_ID}",
		"reference_id":   "REF-${SALE_ID}",
		"tax_rate":       20,
	}

	data, err := json.Marshal(payload)
	if err != nil {
		panic(err)
	}

	if err := nc.Publish("pix2pi.sale.created", data); err != nil {
		panic(err)
	}

	if err := nc.Flush(); err != nil {
		panic(err)
	}

	fmt.Println("OK ✅ sale.created publish edildi")
	fmt.Println(string(data))
}
GOEOF

go run /tmp/step_56g_publish_sale.go

echo
echo "===== 3) WAIT ====="
sleep 2
echo "OK ✅ event islenmesi beklendi"

echo
echo "===== 4) ACCOUNTING LOG CHECK ====="
LOGS="$(journalctl -u pix2pi-accounting.service --since "$START_TS" --no-pager)"
printf '%s\n' "$LOGS"

echo
echo "===== 5) ASSERT ====="
printf '%s\n' "$LOGS" | grep -q "financial event hazir | sale_id=${SALE_ID}"
echo "OK ✅ financial event log bulundu"

printf '%s\n' "$LOGS" | grep -q "journal build tamam"
echo "OK ✅ journal build log bulundu"

printf '%s\n' "$LOGS" | grep -q "ledger build tamam"
echo "OK ✅ ledger build log bulundu"

echo
echo "OK ✅ step_56g_prod_finance_smoke gecti"
