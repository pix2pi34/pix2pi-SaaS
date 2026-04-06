#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p cmd/test_commission

cat <<'GOEOF' > cmd/test_commission/main.go
package main

import (
	"fmt"

	commissionservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/finance/service"
)

func main() {

	service := commissionservice.NewCommissionService()

	result := service.Calculate(
		1200.00,
		20,
		10,
	)

	fmt.Println("OK ✅ commission engine worked")
	fmt.Println("Gross:", result.GrossAmount)
	fmt.Println("Tax:", result.TaxAmount)
	fmt.Println("Net:", result.NetAmount)
	fmt.Println("Platform:", result.PlatformRevenue)
	fmt.Println("Merchant:", result.MerchantRevenue)
}
GOEOF

go run cmd/test_commission/main.go

echo "OK ✅ commission engine run finished"
