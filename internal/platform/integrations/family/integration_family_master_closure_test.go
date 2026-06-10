package family

import (
	"strings"
	"testing"
	"time"
)

func TestIntegrationFamilyMasterClosureReportValidates(t *testing.T) {
	report := NewIntegrationFamilyMasterClosureReport(time.Date(2026, 5, 3, 19, 0, 0, 0, time.UTC))

	if err := report.Validate(); err != nil {
		t.Fatalf("expected family master closure report to validate, got error: %v", err)
	}

	if report.ModuleCode != "FAZ_7_8F" {
		t.Fatalf("unexpected module code: %s", report.ModuleCode)
	}
	if report.FinalStatus != "PASS" {
		t.Fatalf("unexpected final status: %s", report.FinalStatus)
	}
	if report.FamilySealStatus != "SEALED" {
		t.Fatalf("unexpected family seal status: %s", report.FamilySealStatus)
	}
	if report.RequiredProviderCount != 4 {
		t.Fatalf("expected 4 providers, got %d", report.RequiredProviderCount)
	}
}

func TestIntegrationFamilyMasterClosureRequiresAllProviders(t *testing.T) {
	report := NewIntegrationFamilyMasterClosureReport(time.Time{})

	expected := map[string]bool{
		"parasut": false,
		"logo":    false,
		"mikro":   false,
		"zirve":   false,
	}

	for _, provider := range report.Providers {
		expected[provider.ProviderID] = true
		if provider.ConnectorModuleSealStatus != "SEALED" {
			t.Fatalf("provider %s must be sealed", provider.ProviderID)
		}
		if provider.DryRunModuleStatus != "SEALED" {
			t.Fatalf("provider %s dry-run status must be sealed", provider.ProviderID)
		}
		if provider.ProviderLiveModuleStatus != "NOT_STARTED" {
			t.Fatalf("provider %s live module must not be started", provider.ProviderID)
		}
	}

	for provider, seen := range expected {
		if !seen {
			t.Fatalf("provider missing from master closure: %s", provider)
		}
	}
}

func TestIntegrationFamilyMasterClosureKeepsAllRealOperationsClosed(t *testing.T) {
	report := NewIntegrationFamilyMasterClosureReport(time.Time{})

	if !report.AllRealProviderAPIsClosed {
		t.Fatal("all real provider APIs must remain closed")
	}
	if !report.AllRealFileDeliveriesClosed {
		t.Fatal("all real file deliveries must remain closed")
	}
	if !report.AllRealDeliveryChannelsClosed {
		t.Fatal("all real delivery channels must remain closed")
	}
	if !report.AllRealERPWritesClosed {
		t.Fatal("all real ERP writes must remain closed")
	}
	if !report.AllRealOperatorActionsClosed {
		t.Fatal("all real operator actions must remain closed")
	}

	for _, provider := range report.Providers {
		if !strings.HasPrefix(provider.RealProviderAPIStatus, "CLOSED_UNTIL_") {
			t.Fatalf("provider %s real API must remain closed", provider.ProviderID)
		}
		if !strings.HasPrefix(provider.RealFileDeliveryStatus, "CLOSED_UNTIL_") {
			t.Fatalf("provider %s real file delivery must remain closed", provider.ProviderID)
		}
		if !strings.HasPrefix(provider.RealERPWriteStatus, "CLOSED_UNTIL_") {
			t.Fatalf("provider %s real ERP write must remain closed", provider.ProviderID)
		}
	}
}

func TestIntegrationFamilyMasterClosureCanReleaseFaz79Hold(t *testing.T) {
	report := NewIntegrationFamilyMasterClosureReport(time.Time{})

	if !report.CanReleaseFaz79Hold() {
		t.Fatal("FAZ 7-9 hold should be releasable after all integration family providers are sealed")
	}

	if report.Faz79HoldStatus != "READY_TO_RELEASE" {
		t.Fatalf("unexpected FAZ 7-9 hold status: %s", report.Faz79HoldStatus)
	}
	if report.Faz79Ready != "YES" {
		t.Fatalf("unexpected FAZ 7-9 ready status: %s", report.Faz79Ready)
	}
}

func TestIntegrationFamilyMasterClosureRejectsMissingProvider(t *testing.T) {
	report := NewIntegrationFamilyMasterClosureReport(time.Time{})
	report.Providers = report.Providers[:3]
	report.RequiredProviderCount = len(report.Providers)

	err := report.Validate()
	if err == nil {
		t.Fatal("expected missing provider to be rejected")
	}
	if !strings.Contains(err.Error(), "exactly 4 dry-run providers") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestIntegrationFamilyMasterClosureRejectsUnsealedProvider(t *testing.T) {
	report := NewIntegrationFamilyMasterClosureReport(time.Time{})
	report.Providers[0].ConnectorModuleSealStatus = "NOT_SEALED"

	err := report.Validate()
	if err == nil {
		t.Fatal("expected unsealed provider to be rejected")
	}
	if !strings.Contains(err.Error(), "connector module must be SEALED") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestIntegrationFamilyMasterClosureRejectsRealOperationsOpen(t *testing.T) {
	report := NewIntegrationFamilyMasterClosureReport(time.Time{})
	report.AllRealProviderAPIsClosed = false

	err := report.Validate()
	if err == nil {
		t.Fatal("expected open real provider API flag to be rejected")
	}
	if !strings.Contains(err.Error(), "all real provider operations must remain closed") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestIntegrationFamilyMasterClosureDecisionModel(t *testing.T) {
	report := NewIntegrationFamilyMasterClosureReport(time.Time{})

	allowed, reason, gate := report.DecideIntegrationFamilyOperation("DRY_RUN_FAMILY_MASTER_CLOSURE_SEAL")
	if !allowed {
		t.Fatalf("expected master closure seal to be allowed, reason=%s gate=%s", reason, gate)
	}

	allowed, reason, gate = report.DecideIntegrationFamilyOperation("DRY_RUN_RELEASE_FAZ_7_9_HOLD")
	if !allowed {
		t.Fatalf("expected FAZ 7-9 hold release to be allowed, reason=%s gate=%s", reason, gate)
	}

	allowed, _, gate = report.DecideIntegrationFamilyOperation("REAL_PROVIDER_LIVE_START")
	if allowed {
		t.Fatal("real provider live start must not be allowed by dry-run family closure")
	}
	if gate != "READY_FOR_PROVIDER_SPECIFIC_LIVE_MODULES" {
		t.Fatalf("unexpected gate for real provider live operation: %s", gate)
	}
}
