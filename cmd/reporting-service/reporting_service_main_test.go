package main

import "testing"

func TestBuildSaleProjection(t *testing.T) {
	e := Event{
		Type: "sale.created",
		Data: map[string]interface{}{
			"order_id": "ORD-X1",
			"customer": "Test Musteri",
			"amount":   450.0,
			"status":   "PAID",
		},
	}

	sale, ok := buildSaleProjection(e)
	if !ok {
		t.Fatal("projection false dondu")
	}

	if sale.OrderID != "ORD-X1" {
		t.Fatalf("beklenen ORD-X1, gelen %s", sale.OrderID)
	}

	if sale.Customer != "Test Musteri" {
		t.Fatalf("beklenen Test Musteri, gelen %s", sale.Customer)
	}
}

func TestBuildSaleProjectionRejectsUnknown(t *testing.T) {
	e := Event{
		Type: "stock.updated",
		Data: map[string]interface{}{
			"order_id": "ORD-X2",
		},
	}

	_, ok := buildSaleProjection(e)
	if ok {
		t.Fatal("beklenmeyen event kabul edildi")
	}
}
