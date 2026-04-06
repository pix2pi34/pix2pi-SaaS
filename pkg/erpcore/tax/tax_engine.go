package tax

type TaxEngine struct{}

func NewTaxEngine() *TaxEngine {
	return &TaxEngine{}
}

func (t *TaxEngine) Compute(amount float64, rate float64) float64 {
	return amount * rate / 100
}
