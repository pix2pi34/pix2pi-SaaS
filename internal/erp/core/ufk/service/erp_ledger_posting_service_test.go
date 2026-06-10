package service

import "testing"

func TestLedgerPostingService_Post_AyniHesapBakiye(t *testing.T) {
	svc := NewLedgerPostingService()

	svc.Post("100", 1250, 0)
	svc.Post("100", 0, 250)

	h := svc.Hesaplar()["100"]
	if h == nil {
		t.Fatal("100 hesabi olusmadi")
	}

	if h.Bakiye != 1000 {
		t.Fatalf("beklenen bakiye 1000, gelen %v", h.Bakiye)
	}
}

func TestLedgerPostingService_Post_FarkliHesaplar(t *testing.T) {
	svc := NewLedgerPostingService()

	svc.Post("100", 500, 0)
	svc.Post("320", 0, 500)

	kasa := svc.Hesaplar()["100"]
	satici := svc.Hesaplar()["320"]

	if kasa == nil {
		t.Fatal("100 hesabi yok")
	}

	if satici == nil {
		t.Fatal("320 hesabi yok")
	}

	if kasa.Bakiye != 500 {
		t.Fatalf("100 hesap beklenen 500, gelen %v", kasa.Bakiye)
	}

	if satici.Bakiye != -500 {
		t.Fatalf("320 hesap beklenen -500, gelen %v", satici.Bakiye)
	}
}
