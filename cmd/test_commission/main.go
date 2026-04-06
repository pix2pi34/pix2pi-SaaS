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
