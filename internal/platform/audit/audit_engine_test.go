package audit

import (
	"testing"

	journal "github.com/divrigili/pix2pi-SaaS/internal/platform/journal"
)

func TestAudit_OK(t *testing.T) {

	engine := NewAuditEngine()

	entry := journal.JournalEntry{
		EventID:  "S1",
		TenantID: "tenant-1",
		Lines: []journal.JournalLine{
			{HesapKodu: "120", Borc: 1000},
			{HesapKodu: "600", Alacak: 1000},
		},
	}

	if engine.Validate(entry) != nil {
		t.Fatal("hata olmamali")
	}
}

func TestAudit_Fail(t *testing.T) {

	engine := NewAuditEngine()

	entry := journal.JournalEntry{
		EventID:  "S2",
		TenantID: "tenant-1",
		Lines: []journal.JournalLine{
			{HesapKodu: "120", Borc: 1000},
			{HesapKodu: "600", Alacak: 900},
		},
	}

	if engine.Validate(entry) == nil {
		t.Fatal("hata bekleniyor")
	}
}
