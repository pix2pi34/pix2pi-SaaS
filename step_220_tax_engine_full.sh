#!/bin/bash
set -e

BASE=~/pix2pi/pix2pi-SaaS

mkdir -p $BASE/internal/platform/tax

# TAX ENGINE
cat <<'GOEOF' > $BASE/internal/platform/tax/tax_engine.go
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
GOEOF

# TEST
cat <<'GOEOF' > $BASE/internal/platform/tax/tax_engine_test.go
package tax

import "testing"

func TestTax_Default(t *testing.T) {

	engine := NewTaxEngine()

	res := engine.Resolve("sale.created", "tenant-001", 1000)

	if res.Rate != 0.20 {
		t.Fatalf("beklenen 0.20, gelen %v", res.Rate)
	}
}
GOEOF

# RUN TEST
cd $BASE
go test ./internal/platform/tax -v

echo "OK ✅ tax engine hazir"
