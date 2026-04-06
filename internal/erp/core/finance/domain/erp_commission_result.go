package domain

type CommissionResult struct {
	GrossAmount     float64
	TaxAmount       float64
	NetAmount       float64
	CommissionRate  float64
	PlatformRevenue float64
	MerchantRevenue float64
}
