package main

import "testing"

func TestUpsertAndGetSale(t *testing.T) {
	store := NewReadStore()

	store.UpsertSale(SaleSummary{
		OrderID:  "ORD-1",
		Customer: "Test Cari",
		Amount:   100,
		Status:   "PAID",
	})

	item, ok := store.GetSale("ORD-1")
	if !ok {
		t.Fatal("kayit bulunamadi")
	}

	if item.Customer != "Test Cari" {
		t.Fatalf("beklenen Test Cari, gelen %s", item.Customer)
	}
}

func TestSearchSales(t *testing.T) {
	store := NewReadStore()

	store.UpsertSale(SaleSummary{
		OrderID:  "ORD-2",
		Customer: "Alpha",
		Amount:   200,
		Status:   "PAID",
	})
	store.UpsertSale(SaleSummary{
		OrderID:  "ORD-3",
		Customer: "Beta",
		Amount:   300,
		Status:   "PENDING",
	})

	result := store.SearchSales("beta")
	if len(result) != 1 {
		t.Fatalf("beklenen 1 sonuc, gelen %d", len(result))
	}

	if result[0].OrderID != "ORD-3" {
		t.Fatalf("beklenen ORD-3, gelen %s", result[0].OrderID)
	}
}
