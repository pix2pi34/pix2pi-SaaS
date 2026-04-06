package tax

import "testing"

func TestTax_Default(t *testing.T) {

	engine := NewTaxEngine()

	res := engine.Resolve("sale.created", "tenant-001", 1000)

	if res.Rate != 0.20 {
		t.Fatalf("beklenen 0.20, gelen %v", res.Rate)
	}
}
