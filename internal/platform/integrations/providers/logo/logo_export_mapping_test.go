package logo

import "testing"

func TestLogoExportMappingContractReadiness(t *testing.T) {
	contract := NewLogoExportMappingContract()

	if err := contract.Validate(); err != nil {
		t.Fatalf("Logo export mapping contract must validate: %v", err)
	}

	if contract.Step != StepFAZ78L4 {
		t.Fatalf("step mismatch: got %s", contract.Step)
	}

	if contract.MappingMode != LogoExportMappingMode {
		t.Fatalf("mapping mode mismatch: got %s", contract.MappingMode)
	}

	t.Log("7-8L IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4 IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.1 export mapping contract readiness IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.2 credential dependency validation IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoExportMappingKeepsRealIntegrationsClosed(t *testing.T) {
	contract := NewLogoExportMappingContract()

	if !contract.RealIntegrationsClosed() {
		t.Fatal("real provider API, file generation, file delivery, and ERP write must remain closed")
	}

	for _, operation := range contract.Operations {
		if operation.ExternalCallAllowed {
			t.Fatalf("operation %s must not allow external calls", operation.Name)
		}
		if operation.FileGenerationAllowed {
			t.Fatalf("operation %s must not allow file generation", operation.Name)
		}
		if operation.FileDeliveryAllowed {
			t.Fatalf("operation %s must not allow file delivery", operation.Name)
		}
		if operation.ERPWriteAllowed {
			t.Fatalf("operation %s must not allow ERP writes", operation.Name)
		}
	}

	t.Log("7-8L.4.3 real Logo provider API closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.4 real Logo file generation closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.5 real Logo file delivery closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.6 real ERP write closed IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoExportEntityMappingsDeclared(t *testing.T) {
	contract := NewLogoExportMappingContract()

	if err := contract.ValidateEntityMappings(); err != nil {
		t.Fatalf("entity mappings must validate: %v", err)
	}

	requiredEntities := []string{
		"PIX2PI_JOURNAL_HEADER",
		"PIX2PI_JOURNAL_LINE",
		"PIX2PI_PARTY_ACCOUNT",
		"PIX2PI_TAX_DETAIL",
		"PIX2PI_INVOICE_SUMMARY",
	}

	for _, entity := range requiredEntities {
		if _, ok := contract.EntityMapping(entity); !ok {
			t.Fatalf("missing entity mapping: %s", entity)
		}
	}

	if !contract.HasRequiredSourceField("PIX2PI_JOURNAL_HEADER", "tenant_id") {
		t.Fatal("tenant_id required mapping missing")
	}

	if !contract.HasRequiredSourceField("PIX2PI_JOURNAL_HEADER", "correlation_id") {
		t.Fatal("correlation_id required mapping missing")
	}

	if !contract.HasRequiredSourceField("PIX2PI_JOURNAL_HEADER", "idempotency_key") {
		t.Fatal("idempotency_key required mapping missing")
	}

	t.Log("7-8L.4.7 journal header mapping IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.8 journal line mapping IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.9 party/cari mapping IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.10 tax detail mapping IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.11 invoice summary mapping IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.12 tenant/correlation/idempotency mapping IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoTDHPMappingsDeclared(t *testing.T) {
	contract := NewLogoExportMappingContract()

	if err := contract.ValidateTDHPMappings(); err != nil {
		t.Fatalf("TDHP mappings must validate: %v", err)
	}

	requiredRules := []string{
		"SATIS_FATURASI",
		"ALIS_FATURASI",
		"TAHSILAT",
		"ODEME",
	}

	for _, rule := range requiredRules {
		if _, ok := contract.TDHPMapping(rule); !ok {
			t.Fatalf("missing TDHP rule: %s", rule)
		}
	}

	sales, ok := contract.TDHPMapping("SATIS_FATURASI")
	if !ok {
		t.Fatal("missing sales mapping")
	}
	if sales.DebitAccount != "120" || sales.CreditAccount != "600" || sales.TaxAccount != "391" {
		t.Fatalf("sales mapping mismatch: %+v", sales)
	}

	purchase, ok := contract.TDHPMapping("ALIS_FATURASI")
	if !ok {
		t.Fatal("missing purchase mapping")
	}
	if purchase.DebitAccount != "153" || purchase.CreditAccount != "320" || purchase.TaxAccount != "191" {
		t.Fatalf("purchase mapping mismatch: %+v", purchase)
	}

	t.Log("7-8L.4.13 TDHP sales mapping IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.14 TDHP purchase mapping IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.15 TDHP collection mapping IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.4.16 TDHP payment mapping IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoExportMappingRejectsOpenProviderAPI(t *testing.T) {
	contract := NewLogoExportMappingContract()
	contract.RealProviderAPIStatus = "OPEN"

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when real provider API is open")
	}

	t.Log("7-8L.4.17 open real provider API rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoExportMappingRejectsFileGeneration(t *testing.T) {
	contract := NewLogoExportMappingContract()
	contract.Operations[0].FileGenerationAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when real file generation is allowed")
	}

	t.Log("7-8L.4.18 file generation guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoExportMappingRejectsMissingTenantMapping(t *testing.T) {
	contract := NewLogoExportMappingContract()

	for entityIndex, entity := range contract.EntityMappings {
		if entity.SourceEntity != "PIX2PI_JOURNAL_HEADER" {
			continue
		}
		filtered := make([]LogoFieldMapping, 0, len(entity.FieldMappings))
		for _, field := range entity.FieldMappings {
			if field.SourceField != "tenant_id" {
				filtered = append(filtered, field)
			}
		}
		contract.EntityMappings[entityIndex].FieldMappings = filtered
	}

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when tenant_id mapping is missing")
	}

	t.Log("7-8L.4.19 missing tenant mapping rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoExportMappingRejectsExternalOperation(t *testing.T) {
	contract := NewLogoExportMappingContract()
	contract.Operations[0].ExternalCallAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when external call is allowed")
	}

	t.Log("7-8L.4.20 external call guard IMPLEMENTED_OR_PRESENT / OK ✅")
}
