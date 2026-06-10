package dbrouter

import (
	"context"
	"testing"
)

func TestTransactionFlag(t *testing.T) {
	ctx := context.Background()
	ctx = WithTransaction(ctx)

	if !isTx(ctx) {
		t.Fatalf("tx flag calismiyor")
	}
}
