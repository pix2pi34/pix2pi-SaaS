#!/bin/bash
set -e

BASE=~/pix2pi/pix2pi-SaaS

mkdir -p $BASE/internal/platform/audit

# AUDIT ENGINE
cat <<'GOEOF' > $BASE/internal/platform/audit/audit_engine.go
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
GOEOF

# TEST
cat <<'GOEOF' > $BASE/internal/platform/audit/audit_engine_test.go
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
GOEOF

# TEST RUN
cd $BASE
go test ./internal/platform/audit -v

echo "OK ✅ audit FULL tamam"
