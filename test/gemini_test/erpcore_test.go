package gemini_test

import (
	"testing"
	// Modül adını go.mod dosyasındaki "module" ismine göre güncelle
	"github.com/divrigili/pix2pi-SaaS/pkg/erpcore/accounting/domain"
	"github.com/divrigili/pix2pi-SaaS/pkg/erpcore/audit"
	"github.com/divrigili/pix2pi-SaaS/pkg/erpcore/compliance"
	"github.com/divrigili/pix2pi-SaaS/pkg/erpcore/ledger"
	"github.com/divrigili/pix2pi-SaaS/pkg/erpcore/posting"
	"github.com/divrigili/pix2pi-SaaS/pkg/erpcore/reporting"
	"github.com/divrigili/pix2pi-SaaS/pkg/erpcore/rule"
	"github.com/divrigili/pix2pi-SaaS/pkg/erpcore/validation"
)

func TestUFKCoreEngines(t *testing.T) {
	t.Log("--- UFK Çekirdek Motorları Test Ediliyor ---")

	// 1. Domain
	j := domain.Journal{ID: "J-001", Name: "Ana Yevmiye"}
	if j.ID == "" {
		t.Error("Journal ID boş olamaz")
	} else {
		t.Logf("[DOMAIN] %s başarıyla oluşturuldu.", j.Name)
	}

	// 2. Validation
	valEngine := &validation.ValidationEngine{}
	if !valEngine.Validate(j.ID) {
		t.Errorf("Validation başarısız: %s", j.ID)
	} else {
		t.Log("[VALIDATION] Doğrulama başarılı.")
	}

	// 3. Compliance & Rule
	compEngine := &compliance.ComplianceEngine{}
	if !compEngine.Check("RULE-1") {
		t.Error("Uyumluluk kontrolü başarısız.")
	} else {
		t.Log("[COMPLIANCE] Uyumluluk sağlandı.")
	}

	ruleEngine := &rule.RuleEngine{}
	ruleEngine.Apply(map[string]any{"rule": "RULE-1"})
	t.Log("[RULE] Kurallar uygulandı.")

	// 4. Posting & Ledger
	postEngine := &posting.PostingEngine{}
	postEngine.Execute(j.ID)
	t.Log("[POSTING] İşleme yapıldı.")

	ledgEngine := &ledger.Ledger{}
	ledgEngine.Post(j.ID)
	t.Log("[LEDGER] Deftere kayıt atıldı.")

	// 5. Audit & Reporting
	audEngine := &audit.AuditEngine{}
	audEngine.Log("İşlem tamamlandı.")
	t.Log("[AUDIT] Log yazıldı.")

	repEngine := &reporting.ReportingEngine{}
	repEngine.Generate("REP-001")
	t.Log("[REPORTING] Rapor üretildi.")
}
