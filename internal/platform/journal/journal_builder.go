package journal

import (
	"fmt"

	tax "github.com/divrigili/pix2pi-SaaS/internal/platform/tax"
)

type SaleEvent struct {
	Event    string `json:"event"`
	SaleID   string `json:"sale_id"`
	TenantID string `json:"tenant_id"`
	Amount   int    `json:"amount"`
}

type JournalLine struct {
	HesapKodu string
	HesapAdi  string
	Borc      float64
	Alacak    float64
}

type JournalEntry struct {
	EventID   string
	TenantID  string
	BelgeTipi string
	Aciklama  string
	Lines     []JournalLine
}

type JournalBuilder struct {
	taxEngine *tax.TaxEngine
}

func NewJournalBuilder() *JournalBuilder {
	return &JournalBuilder{
		taxEngine: tax.NewTaxEngine(),
	}
}

func (b *JournalBuilder) BuildSaleJournal(event SaleEvent) JournalEntry {

	brut := float64(event.Amount)

	// 🔴 VERGİ MOTORU
	taxResult := b.taxEngine.Resolve(event.Event, event.TenantID, event.Amount)

	rate := taxResult.Rate

	net := brut / (1 + rate)
	kdv := brut - net

	return JournalEntry{
		EventID:   event.SaleID,
		TenantID:  event.TenantID,
		BelgeTipi: "SALE",
		Aciklama:  fmt.Sprintf("Satis %s", event.SaleID),
		Lines: []JournalLine{
			{
				HesapKodu: "120",
				HesapAdi:  "Alicilar",
				Borc:      brut,
			},
			{
				HesapKodu: "600",
				HesapAdi:  "Yurtici Satislar",
				Alacak:    net,
			},
			{
				HesapKodu: "391",
				HesapAdi:  "Hesaplanan KDV",
				Alacak:    kdv,
			},
		},
	}
}
