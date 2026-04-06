package service

import (
	"math"

	financedomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/finance/domain"
)

type CommissionService struct{}

func NewCommissionService() *CommissionService {
	return &CommissionService{}
}

func (s *CommissionService) Calculate(
	gross float64,
	taxRate float64,
	commissionRate float64,
) financedomain.CommissionResult {

	divisor := 1.0 + (taxRate / 100.0)

	net := round2(gross / divisor)
	taxAmount := round2(gross - net)

	platform := round2(net * commissionRate / 100.0)
	merchant := round2(net - platform)

	return financedomain.CommissionResult{
		GrossAmount:     round2(gross),
		TaxAmount:       taxAmount,
		NetAmount:       net,
		CommissionRate:  commissionRate,
		PlatformRevenue: platform,
		MerchantRevenue: merchant,
	}
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
