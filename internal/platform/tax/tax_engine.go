package tax

type TaxResult struct {
	Rate float64
}

type TaxEngine struct{}

func NewTaxEngine() *TaxEngine {
	return &TaxEngine{}
}

// basit kural motoru (ilerde büyüyecek)
func (t *TaxEngine) Resolve(eventType string, tenantID string, amount int) TaxResult {

	// default TR KDV
	return TaxResult{
		Rate: 0.20,
	}
}
