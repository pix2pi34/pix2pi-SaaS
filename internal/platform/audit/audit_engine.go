package audit

import (
	"errors"

	journal "github.com/divrigili/pix2pi-SaaS/internal/platform/journal"
)

type AuditEngine struct{}

func NewAuditEngine() *AuditEngine {
	return &AuditEngine{}
}

func (a *AuditEngine) Validate(entry journal.JournalEntry) error {

	if entry.EventID == "" {
		return errors.New("event id bos")
	}

	if entry.TenantID == "" {
		return errors.New("tenant id bos")
	}

	if len(entry.Lines) < 2 {
		return errors.New("yetersiz satir")
	}

	var borc float64
	var alacak float64

	for _, l := range entry.Lines {

		if l.HesapKodu == "" {
			return errors.New("hesap kodu bos")
		}

		if l.Borc < 0 || l.Alacak < 0 {
			return errors.New("negatif olamaz")
		}

		borc += l.Borc
		alacak += l.Alacak
	}

	if borc != alacak {
		return errors.New("denge bozuk")
	}

	return nil
}
