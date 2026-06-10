package family

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

const (
	IntegrationFamilyMasterModuleCode = "FAZ_7_8F"
	IntegrationFamilyMasterMode       = "INTEGRATION_FAMILY_MASTER_CLOSURE"
	IntegrationFamilyMasterStatus     = "PASS"

	IntegrationFamilyFinalStatus       = "PASS"
	IntegrationFamilySealStatus        = "SEALED"
	IntegrationFamilyReviewStatus      = "COMPLETE"
	IntegrationFamilyRealOpsStatus     = "CLOSED_UNTIL_PROVIDER_LIVE_MODULES"
	IntegrationFamilyProviderLiveGate  = "READY_FOR_PROVIDER_SPECIFIC_LIVE_MODULES"
	IntegrationFamilyProviderDryRunSet = "PARASUT_LOGO_MIKRO_ZIRVE"

	Faz79HoldReleaseStatus = "READY_TO_RELEASE"
	Faz79ReadyStatus       = "YES"

	ProviderParasut = "parasut"
	ProviderLogo    = "logo"
	ProviderMikro   = "mikro"
	ProviderZirve   = "zirve"
)

type ProviderFamilySeal struct {
	ProviderID                 string
	ProviderDisplayName        string
	FinalClosureStepCode       string
	FinalClosureModuleCode     string
	ConnectorModuleSealStatus  string
	DryRunModuleStatus         string
	ProviderLiveHandoffGate    string
	ProviderLiveModuleStatus   string
	RealProviderAPIStatus      string
	RealFileDeliveryStatus     string
	RealDeliveryChannelStatus  string
	RealERPWriteStatus         string
	RealOperatorActionStatus   string
	RequiredEvidenceFile       string
	RequiredProviderDirectory  string
	RequiredFinalClosureConfig string
	RequiredFinalClosureDoc    string
}

type IntegrationFamilyMasterClosureReport struct {
	ModuleCode                        string
	Mode                              string
	FinalStatus                       string
	FamilySealStatus                  string
	FamilyReviewStatus                string
	FamilyRealOpsStatus               string
	ProviderLiveGate                  string
	ProviderDryRunSet                 string
	RequiredProviderCount             int
	Providers                         []ProviderFamilySeal
	AllProvidersSealed                bool
	AllRealProviderAPIsClosed         bool
	AllRealFileDeliveriesClosed       bool
	AllRealDeliveryChannelsClosed     bool
	AllRealERPWritesClosed            bool
	AllRealOperatorActionsClosed      bool
	Faz79HoldStatus                   string
	Faz79Ready                        string
	ProviderSpecificLiveModulesStatus string
	CreatedAtUTC                      time.Time
}

func NewIntegrationFamilyMasterClosureReport(now time.Time) IntegrationFamilyMasterClosureReport {
	if now.IsZero() {
		now = time.Now().UTC()
	}

	providers := DefaultProviderFamilySeals()

	return IntegrationFamilyMasterClosureReport{
		ModuleCode:                        IntegrationFamilyMasterModuleCode,
		Mode:                              IntegrationFamilyMasterMode,
		FinalStatus:                       IntegrationFamilyFinalStatus,
		FamilySealStatus:                  IntegrationFamilySealStatus,
		FamilyReviewStatus:                IntegrationFamilyReviewStatus,
		FamilyRealOpsStatus:               IntegrationFamilyRealOpsStatus,
		ProviderLiveGate:                  IntegrationFamilyProviderLiveGate,
		ProviderDryRunSet:                 IntegrationFamilyProviderDryRunSet,
		RequiredProviderCount:             len(providers),
		Providers:                         providers,
		AllProvidersSealed:                true,
		AllRealProviderAPIsClosed:         true,
		AllRealFileDeliveriesClosed:       true,
		AllRealDeliveryChannelsClosed:     true,
		AllRealERPWritesClosed:            true,
		AllRealOperatorActionsClosed:      true,
		Faz79HoldStatus:                   Faz79HoldReleaseStatus,
		Faz79Ready:                        Faz79ReadyStatus,
		ProviderSpecificLiveModulesStatus: "NOT_STARTED",
		CreatedAtUTC:                      now.UTC(),
	}
}

func DefaultProviderFamilySeals() []ProviderFamilySeal {
	return []ProviderFamilySeal{
		{
			ProviderID:                 ProviderParasut,
			ProviderDisplayName:        "Paraşüt",
			FinalClosureStepCode:       "7-8P.12",
			FinalClosureModuleCode:     "FAZ_7_8P_12",
			ConnectorModuleSealStatus:  "SEALED",
			DryRunModuleStatus:         "SEALED",
			ProviderLiveHandoffGate:    "READY_FOR_PROVIDER_LIVE_MODULE",
			ProviderLiveModuleStatus:   "NOT_STARTED",
			RealProviderAPIStatus:      "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RealFileDeliveryStatus:     "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RealDeliveryChannelStatus:  "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RealERPWriteStatus:         "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE",
			RealOperatorActionStatus:   "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RequiredEvidenceFile:       "docs/faz7/evidence/FAZ_7_8P_12_PARASUT_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md",
			RequiredProviderDirectory:  "internal/platform/integrations/providers/parasut",
			RequiredFinalClosureConfig: "configs/faz7/integrations/parasut_final_closure.json",
			RequiredFinalClosureDoc:    "docs/faz7/integrations/parasut/FAZ_7_8P_12_PARASUT_FINAL_CLOSURE.md",
		},
		{
			ProviderID:                 ProviderLogo,
			ProviderDisplayName:        "Logo",
			FinalClosureStepCode:       "7-8L.10",
			FinalClosureModuleCode:     "FAZ_7_8L_10",
			ConnectorModuleSealStatus:  "SEALED",
			DryRunModuleStatus:         "SEALED",
			ProviderLiveHandoffGate:    "READY_FOR_PROVIDER_LIVE_MODULE",
			ProviderLiveModuleStatus:   "NOT_STARTED",
			RealProviderAPIStatus:      "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RealFileDeliveryStatus:     "CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE",
			RealDeliveryChannelStatus:  "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RealERPWriteStatus:         "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE",
			RealOperatorActionStatus:   "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RequiredEvidenceFile:       "docs/faz7/evidence/FAZ_7_8L_10_LOGO_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md",
			RequiredProviderDirectory:  "internal/platform/integrations/providers/logo",
			RequiredFinalClosureConfig: "configs/faz7/integrations/logo_final_closure.json",
			RequiredFinalClosureDoc:    "docs/faz7/integrations/logo/FAZ_7_8L_10_LOGO_FINAL_CLOSURE.md",
		},
		{
			ProviderID:                 ProviderMikro,
			ProviderDisplayName:        "Mikro",
			FinalClosureStepCode:       "7-8M.7",
			FinalClosureModuleCode:     "FAZ_7_8M_7",
			ConnectorModuleSealStatus:  "SEALED",
			DryRunModuleStatus:         "SEALED",
			ProviderLiveHandoffGate:    "READY_FOR_PROVIDER_LIVE_MODULE",
			ProviderLiveModuleStatus:   "NOT_STARTED",
			RealProviderAPIStatus:      "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RealFileDeliveryStatus:     "CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE",
			RealDeliveryChannelStatus:  "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RealERPWriteStatus:         "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE",
			RealOperatorActionStatus:   "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RequiredEvidenceFile:       "docs/faz7/evidence/FAZ_7_8M_7_MIKRO_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md",
			RequiredProviderDirectory:  "internal/platform/integrations/providers/mikro",
			RequiredFinalClosureConfig: "configs/faz7/integrations/mikro_final_closure.json",
			RequiredFinalClosureDoc:    "docs/faz7/integrations/mikro/FAZ_7_8M_7_MIKRO_FINAL_CLOSURE.md",
		},
		{
			ProviderID:                 ProviderZirve,
			ProviderDisplayName:        "Zirve",
			FinalClosureStepCode:       "7-8Z.7",
			FinalClosureModuleCode:     "FAZ_7_8Z_7",
			ConnectorModuleSealStatus:  "SEALED",
			DryRunModuleStatus:         "SEALED",
			ProviderLiveHandoffGate:    "READY_FOR_PROVIDER_LIVE_MODULE",
			ProviderLiveModuleStatus:   "NOT_STARTED",
			RealProviderAPIStatus:      "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RealFileDeliveryStatus:     "CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE",
			RealDeliveryChannelStatus:  "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RealERPWriteStatus:         "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE",
			RealOperatorActionStatus:   "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
			RequiredEvidenceFile:       "docs/faz7/evidence/FAZ_7_8Z_7_ZIRVE_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md",
			RequiredProviderDirectory:  "internal/platform/integrations/providers/zirve",
			RequiredFinalClosureConfig: "configs/faz7/integrations/zirve_final_closure.json",
			RequiredFinalClosureDoc:    "docs/faz7/integrations/zirve/FAZ_7_8Z_7_ZIRVE_FINAL_CLOSURE.md",
		},
	}
}

func (r IntegrationFamilyMasterClosureReport) Validate() error {
	if strings.TrimSpace(r.ModuleCode) != IntegrationFamilyMasterModuleCode {
		return fmt.Errorf("module code must be %s", IntegrationFamilyMasterModuleCode)
	}
	if r.Mode != IntegrationFamilyMasterMode {
		return fmt.Errorf("mode must be %s", IntegrationFamilyMasterMode)
	}
	if r.FinalStatus != IntegrationFamilyFinalStatus {
		return fmt.Errorf("final status must be %s", IntegrationFamilyFinalStatus)
	}
	if r.FamilySealStatus != IntegrationFamilySealStatus {
		return fmt.Errorf("family seal status must be %s", IntegrationFamilySealStatus)
	}
	if r.FamilyReviewStatus != IntegrationFamilyReviewStatus {
		return fmt.Errorf("family review status must be %s", IntegrationFamilyReviewStatus)
	}
	if r.FamilyRealOpsStatus != IntegrationFamilyRealOpsStatus {
		return fmt.Errorf("family real ops status must be %s", IntegrationFamilyRealOpsStatus)
	}
	if r.ProviderLiveGate != IntegrationFamilyProviderLiveGate {
		return fmt.Errorf("provider live gate must be %s", IntegrationFamilyProviderLiveGate)
	}
	if r.RequiredProviderCount != 4 {
		return errors.New("integration family requires exactly 4 dry-run providers: Paraşüt, Logo, Mikro, Zirve")
	}
	if len(r.Providers) != r.RequiredProviderCount {
		return errors.New("provider count mismatch")
	}
	if !r.AllProvidersSealed {
		return errors.New("all providers must be sealed")
	}
	if !r.AllRealProviderAPIsClosed ||
		!r.AllRealFileDeliveriesClosed ||
		!r.AllRealDeliveryChannelsClosed ||
		!r.AllRealERPWritesClosed ||
		!r.AllRealOperatorActionsClosed {
		return errors.New("all real provider operations must remain closed")
	}
	if r.Faz79HoldStatus != Faz79HoldReleaseStatus {
		return fmt.Errorf("FAZ 7-9 hold status must be %s", Faz79HoldReleaseStatus)
	}
	if r.Faz79Ready != Faz79ReadyStatus {
		return fmt.Errorf("FAZ 7-9 ready status must be %s", Faz79ReadyStatus)
	}
	if r.ProviderSpecificLiveModulesStatus != "NOT_STARTED" {
		return errors.New("provider-specific live modules must remain NOT_STARTED")
	}

	seen := map[string]bool{}
	for _, provider := range r.Providers {
		if err := provider.Validate(); err != nil {
			return err
		}
		seen[provider.ProviderID] = true
	}

	for _, required := range []string{ProviderParasut, ProviderLogo, ProviderMikro, ProviderZirve} {
		if !seen[required] {
			return fmt.Errorf("required provider missing: %s", required)
		}
	}

	return nil
}

func (p ProviderFamilySeal) Validate() error {
	if strings.TrimSpace(p.ProviderID) == "" {
		return errors.New("provider id is required")
	}
	if strings.TrimSpace(p.ProviderDisplayName) == "" {
		return errors.New("provider display name is required")
	}
	if strings.TrimSpace(p.FinalClosureStepCode) == "" {
		return errors.New("final closure step code is required")
	}
	if strings.TrimSpace(p.FinalClosureModuleCode) == "" {
		return errors.New("final closure module code is required")
	}
	if p.ConnectorModuleSealStatus != "SEALED" {
		return fmt.Errorf("provider %s connector module must be SEALED", p.ProviderID)
	}
	if p.DryRunModuleStatus != "SEALED" {
		return fmt.Errorf("provider %s dry-run module must be SEALED", p.ProviderID)
	}
	if p.ProviderLiveHandoffGate != "READY_FOR_PROVIDER_LIVE_MODULE" {
		return fmt.Errorf("provider %s live handoff gate must be READY_FOR_PROVIDER_LIVE_MODULE", p.ProviderID)
	}
	if p.ProviderLiveModuleStatus != "NOT_STARTED" {
		return fmt.Errorf("provider %s live module must remain NOT_STARTED", p.ProviderID)
	}
	if !strings.HasPrefix(p.RealProviderAPIStatus, "CLOSED_UNTIL_") {
		return fmt.Errorf("provider %s real provider API must remain closed", p.ProviderID)
	}
	if !strings.HasPrefix(p.RealFileDeliveryStatus, "CLOSED_UNTIL_") {
		return fmt.Errorf("provider %s real file delivery must remain closed", p.ProviderID)
	}
	if !strings.HasPrefix(p.RealDeliveryChannelStatus, "CLOSED_UNTIL_") {
		return fmt.Errorf("provider %s real delivery channel must remain closed", p.ProviderID)
	}
	if !strings.HasPrefix(p.RealERPWriteStatus, "CLOSED_UNTIL_") {
		return fmt.Errorf("provider %s real ERP write must remain closed", p.ProviderID)
	}
	if !strings.HasPrefix(p.RealOperatorActionStatus, "CLOSED_UNTIL_") {
		return fmt.Errorf("provider %s real operator action must remain closed", p.ProviderID)
	}
	if strings.TrimSpace(p.RequiredEvidenceFile) == "" {
		return fmt.Errorf("provider %s required evidence file is required", p.ProviderID)
	}
	if strings.TrimSpace(p.RequiredProviderDirectory) == "" {
		return fmt.Errorf("provider %s required provider directory is required", p.ProviderID)
	}
	return nil
}

func (r IntegrationFamilyMasterClosureReport) CanReleaseFaz79Hold() bool {
	return r.FinalStatus == IntegrationFamilyFinalStatus &&
		r.FamilySealStatus == IntegrationFamilySealStatus &&
		r.FamilyReviewStatus == IntegrationFamilyReviewStatus &&
		r.RequiredProviderCount == 4 &&
		r.AllProvidersSealed &&
		r.AllRealProviderAPIsClosed &&
		r.AllRealFileDeliveriesClosed &&
		r.AllRealDeliveryChannelsClosed &&
		r.AllRealERPWritesClosed &&
		r.AllRealOperatorActionsClosed &&
		r.Faz79HoldStatus == Faz79HoldReleaseStatus &&
		r.Faz79Ready == Faz79ReadyStatus &&
		r.ProviderSpecificLiveModulesStatus == "NOT_STARTED"
}

func (r IntegrationFamilyMasterClosureReport) DecideIntegrationFamilyOperation(operationCode string) (allowed bool, reason string, requiredGate string) {
	operationCode = strings.TrimSpace(operationCode)

	switch operationCode {
	case "DRY_RUN_FAMILY_MASTER_CLOSURE_SEAL":
		return true, "integration family master closure can be sealed", "INTEGRATION_FAMILY_MASTER_CLOSURE"
	case "DRY_RUN_RELEASE_FAZ_7_9_HOLD":
		if r.CanReleaseFaz79Hold() {
			return true, "FAZ 7-9 hold can be released after family closure", "FAZ_7_9_RELEASE_GATE"
		}
		return false, "FAZ 7-9 hold cannot be released until family closure passes", "FAZ_7_9_RELEASE_GATE"
	default:
		return false, "real provider live operations are not part of master dry-run closure", IntegrationFamilyProviderLiveGate
	}
}
