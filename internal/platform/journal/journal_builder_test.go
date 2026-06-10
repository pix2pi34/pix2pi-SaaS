package journal

import "testing"

func TestBuildSaleJournal_Header(t *testing.T) {
	builder := NewJournalBuilder()

	entry := builder.BuildSaleJournal(SaleEvent{
		Event:    "sale.created",
		SaleID:   "S-5001",
		TenantID: "tenant-001",
		Amount:   2000,
	})

	if entry.EventID != "S-5001" {
		t.Fatalf("event id beklenen S-5001, gelen %s", entry.EventID)
	}

	if entry.TenantID != "tenant-001" {
		t.Fatalf("tenant id beklenen tenant-001, gelen %s", entry.TenantID)
	}

	if entry.BelgeTipi != "SALE" {
		t.Fatalf("belge tipi beklenen SALE, gelen %s", entry.BelgeTipi)
	}
}

func TestBuildSaleJournal_LineCount(t *testing.T) {
	builder := NewJournalBuilder()

	entry := builder.BuildSaleJournal(SaleEvent{
		Event:    "sale.created",
		SaleID:   "S-5001",
		TenantID: "tenant-001",
		Amount:   2000,
	})

	if len(entry.Lines) != 3 {
		t.Fatalf("3 satir bekleniyordu, gelen %d", len(entry.Lines))
	}
}

func TestBuildSaleJournal_DebitCreditBalanced(t *testing.T) {
	builder := NewJournalBuilder()

	entry := builder.BuildSaleJournal(SaleEvent{
		Event:    "sale.created",
		SaleID:   "S-5001",
		TenantID: "tenant-001",
		Amount:   2000,
	})

	var toplamBorc float64
	var toplamAlacak float64

	for _, line := range entry.Lines {
		toplamBorc += line.Borc
		toplamAlacak += line.Alacak
	}

	if toplamBorc != toplamAlacak {
		t.Fatalf("borc ve alacak esit degil, borc=%v alacak=%v", toplamBorc, toplamAlacak)
	}
}

func TestBuildSaleJournal_Accounts(t *testing.T) {
	builder := NewJournalBuilder()

	entry := builder.BuildSaleJournal(SaleEvent{
		Event:    "sale.created",
		SaleID:   "S-5001",
		TenantID: "tenant-001",
		Amount:   2000,
	})

	if entry.Lines[0].HesapKodu != "120" {
		t.Fatalf("ilk hesap 120 bekleniyordu, gelen %s", entry.Lines[0].HesapKodu)
	}

	if entry.Lines[1].HesapKodu != "600" {
		t.Fatalf("ikinci hesap 600 bekleniyordu, gelen %s", entry.Lines[1].HesapKodu)
	}
}
