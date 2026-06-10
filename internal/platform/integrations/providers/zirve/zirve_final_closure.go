package zirve

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

const (
	ZirveFinalClosureModuleCode = "FAZ_7_8Z_7"
	ZirveFinalClosureMode       = "CONNECTOR_FINAL_CLOSURE_DRY_RUN_MODULE_ONLY"
	ZirveFinalClosureStatus     = "PASS"

	ZirveConnectorModuleFinalSealStatus = "SEALED"
	ZirveDryRunModuleFinalStatus        = "SEALED"

	ZirveProviderLiveHandoffGate         = "READY_FOR_PROVIDER_LIVE_MODULE"
	ZirveProviderLiveModuleFinalStatus   = "NOT_STARTED"
	ZirveProviderLiveRealOperationStatus = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"

	ZirveFinalClosureEvidencePolicy = "ALL_DRY_RUN_MODULES_TESTED_AND_AUDITED"
	ZirveFinalClosureRealOpsPolicy  = "REAL_PROVIDER_API_FILE_DELIVERY_ERP_WRITE_REMAIN_CLOSED"
	ZirveFinalClosureNextGate       = "READY_FOR_PROVIDER_LIVE_MODULE"
)

type ZirveClosureModuleEvidence struct {
	StepCode      string
	ModuleCode    string
	ModuleName    string
	FinalStatus   string
	RuntimeFile   string
	TestFile      string
	ConfigFile    string
	DocFile       string
	EvidenceFile  string
	RequiredPass  bool
	RequiredAudit bool
}

type ZirveFinalClosureReport struct {
	ProviderID                        string
	ProviderDisplayName               string
	ModuleCode                        string
	Mode                              string
	FinalStatus                       string
	ConnectorModuleFinalSealStatus    string
	DryRunModuleFinalStatus           string
	ProviderLiveHandoffGate           string
	ProviderLiveModuleStatus          string
	ProviderLiveRealOperationStatus   string
	EvidencePolicy                    string
	RealOpsPolicy                     string
	NextGate                          string
	RequiredModuleCount               int
	RequiredModules                   []ZirveClosureModuleEvidence
	AllRequiredModulesSealed          bool
	HandoffReady                      bool
	RealProviderAPIAllowed            bool
	RealFileDeliveryAllowed           bool
	RealDeliveryChannelAllowed        bool
	RealERPWriteAllowed               bool
	RealOperatorProviderActionAllowed bool
	CreatedAtUTC                      time.Time
}

func NewZirveFinalClosureReport(now time.Time) ZirveFinalClosureReport {
	if now.IsZero() {
		now = time.Now().UTC()
	}

	modules := DefaultZirveClosureModuleEvidence()

	return ZirveFinalClosureReport{
		ProviderID:                        ProviderID,
		ProviderDisplayName:               DisplayName,
		ModuleCode:                        ZirveFinalClosureModuleCode,
		Mode:                              ZirveFinalClosureMode,
		FinalStatus:                       ZirveFinalClosureStatus,
		ConnectorModuleFinalSealStatus:    ZirveConnectorModuleFinalSealStatus,
		DryRunModuleFinalStatus:           ZirveDryRunModuleFinalStatus,
		ProviderLiveHandoffGate:           ZirveProviderLiveHandoffGate,
		ProviderLiveModuleStatus:          ZirveProviderLiveModuleFinalStatus,
		ProviderLiveRealOperationStatus:   ZirveProviderLiveRealOperationStatus,
		EvidencePolicy:                    ZirveFinalClosureEvidencePolicy,
		RealOpsPolicy:                     ZirveFinalClosureRealOpsPolicy,
		NextGate:                          ZirveFinalClosureNextGate,
		RequiredModuleCount:               len(modules),
		RequiredModules:                   modules,
		AllRequiredModulesSealed:          true,
		HandoffReady:                      true,
		RealProviderAPIAllowed:            false,
		RealFileDeliveryAllowed:           false,
		RealDeliveryChannelAllowed:        false,
		RealERPWriteAllowed:               false,
		RealOperatorProviderActionAllowed: false,
		CreatedAtUTC:                      now.UTC(),
	}
}

func DefaultZirveClosureModuleEvidence() []ZirveClosureModuleEvidence {
	return []ZirveClosureModuleEvidence{
		{
			StepCode:      "7-8Z",
			ModuleCode:    ModuleCode,
			ModuleName:    "Zirve Connector Module Foundation",
			FinalStatus:   "PASS",
			RuntimeFile:   "internal/platform/integrations/providers/zirve/zirve_foundation.go",
			TestFile:      "internal/platform/integrations/providers/zirve/zirve_foundation_test.go",
			ConfigFile:    "configs/faz7/integrations/zirve_connector_foundation.json",
			DocFile:       "docs/faz7/integrations/zirve/FAZ_7_8Z_ZIRVE_CONNECTOR_FOUNDATION.md",
			EvidenceFile:  "docs/faz7/evidence/FAZ_7_8Z_ZIRVE_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_AUDIT.md",
			RequiredPass:  true,
			RequiredAudit: true,
		},
		{
			StepCode:      "7-8Z.2",
			ModuleCode:    ZirveFileGenerationModuleCode,
			ModuleName:    "Zirve File Generation Dry-Run Contract",
			FinalStatus:   "PASS",
			RuntimeFile:   "internal/platform/integrations/providers/zirve/zirve_file_generation.go",
			TestFile:      "internal/platform/integrations/providers/zirve/zirve_file_generation_test.go",
			ConfigFile:    "configs/faz7/integrations/zirve_file_generation_dry_run.json",
			DocFile:       "docs/faz7/integrations/zirve/FAZ_7_8Z_2_ZIRVE_FILE_GENERATION_DRY_RUN.md",
			EvidenceFile:  "docs/faz7/evidence/FAZ_7_8Z_2_ZIRVE_FILE_GENERATION_DRY_RUN_REAL_IMPLEMENTATION_AUDIT.md",
			RequiredPass:  true,
			RequiredAudit: true,
		},
		{
			StepCode:      "7-8Z.3",
			ModuleCode:    ZirveImportDeliveryModuleCode,
			ModuleName:    "Zirve Import Package / Delivery Contract",
			FinalStatus:   "PASS",
			RuntimeFile:   "internal/platform/integrations/providers/zirve/zirve_import_delivery.go",
			TestFile:      "internal/platform/integrations/providers/zirve/zirve_import_delivery_test.go",
			ConfigFile:    "configs/faz7/integrations/zirve_import_delivery_contract.json",
			DocFile:       "docs/faz7/integrations/zirve/FAZ_7_8Z_3_ZIRVE_IMPORT_DELIVERY_CONTRACT.md",
			EvidenceFile:  "docs/faz7/evidence/FAZ_7_8Z_3_ZIRVE_IMPORT_DELIVERY_CONTRACT_REAL_IMPLEMENTATION_AUDIT.md",
			RequiredPass:  true,
			RequiredAudit: true,
		},
		{
			StepCode:      "7-8Z.4",
			ModuleCode:    ZirveValidationRetryDLQModuleCode,
			ModuleName:    "Zirve Validation / Error Mapping / Retry-DLQ",
			FinalStatus:   "PASS",
			RuntimeFile:   "internal/platform/integrations/providers/zirve/zirve_validation_retry_dlq.go",
			TestFile:      "internal/platform/integrations/providers/zirve/zirve_validation_retry_dlq_test.go",
			ConfigFile:    "configs/faz7/integrations/zirve_validation_retry_dlq.json",
			DocFile:       "docs/faz7/integrations/zirve/FAZ_7_8Z_4_ZIRVE_VALIDATION_RETRY_DLQ.md",
			EvidenceFile:  "docs/faz7/evidence/FAZ_7_8Z_4_ZIRVE_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_AUDIT.md",
			RequiredPass:  true,
			RequiredAudit: true,
		},
		{
			StepCode:      "7-8Z.5",
			ModuleCode:    ZirveAdminOpsModuleCode,
			ModuleName:    "Zirve Admin / Ops / Manual Review",
			FinalStatus:   "PASS",
			RuntimeFile:   "internal/platform/integrations/providers/zirve/zirve_admin_ops.go",
			TestFile:      "internal/platform/integrations/providers/zirve/zirve_admin_ops_test.go",
			ConfigFile:    "configs/faz7/integrations/zirve_admin_ops_manual_review.json",
			DocFile:       "docs/faz7/integrations/zirve/FAZ_7_8Z_5_ZIRVE_ADMIN_OPS_MANUAL_REVIEW.md",
			EvidenceFile:  "docs/faz7/evidence/FAZ_7_8Z_5_ZIRVE_ADMIN_OPS_MANUAL_REVIEW_REAL_IMPLEMENTATION_AUDIT.md",
			RequiredPass:  true,
			RequiredAudit: true,
		},
		{
			StepCode:      "7-8Z.6",
			ModuleCode:    ZirveE2EDryRunModuleCode,
			ModuleName:    "Zirve E2E Dry-Run Flow",
			FinalStatus:   "PASS",
			RuntimeFile:   "internal/platform/integrations/providers/zirve/zirve_e2e_dry_run.go",
			TestFile:      "internal/platform/integrations/providers/zirve/zirve_e2e_dry_run_test.go",
			ConfigFile:    "configs/faz7/integrations/zirve_e2e_dry_run_flow.json",
			DocFile:       "docs/faz7/integrations/zirve/FAZ_7_8Z_6_ZIRVE_E2E_DRY_RUN_FLOW.md",
			EvidenceFile:  "docs/faz7/evidence/FAZ_7_8Z_6_ZIRVE_E2E_DRY_RUN_FLOW_REAL_IMPLEMENTATION_AUDIT.md",
			RequiredPass:  true,
			RequiredAudit: true,
		},
	}
}

func (r ZirveFinalClosureReport) Validate() error {
	if strings.TrimSpace(r.ProviderID) != ProviderID {
		return fmt.Errorf("provider id must be %s", ProviderID)
	}
	if strings.TrimSpace(r.ProviderDisplayName) != DisplayName {
		return fmt.Errorf("provider display name must be %s", DisplayName)
	}
	if strings.TrimSpace(r.ModuleCode) != ZirveFinalClosureModuleCode {
		return fmt.Errorf("module code must be %s", ZirveFinalClosureModuleCode)
	}
	if r.Mode != ZirveFinalClosureMode {
		return fmt.Errorf("final closure mode must be %s", ZirveFinalClosureMode)
	}
	if r.FinalStatus != ZirveFinalClosureStatus {
		return fmt.Errorf("final closure status must be %s", ZirveFinalClosureStatus)
	}
	if r.ConnectorModuleFinalSealStatus != ZirveConnectorModuleFinalSealStatus {
		return fmt.Errorf("connector module seal status must be %s", ZirveConnectorModuleFinalSealStatus)
	}
	if r.DryRunModuleFinalStatus != ZirveDryRunModuleFinalStatus {
		return fmt.Errorf("dry-run module status must be %s", ZirveDryRunModuleFinalStatus)
	}
	if r.ProviderLiveHandoffGate != ZirveProviderLiveHandoffGate {
		return fmt.Errorf("provider live handoff gate must be %s", ZirveProviderLiveHandoffGate)
	}
	if r.ProviderLiveModuleStatus != ZirveProviderLiveModuleFinalStatus {
		return fmt.Errorf("provider live module status must remain %s", ZirveProviderLiveModuleFinalStatus)
	}
	if r.ProviderLiveRealOperationStatus != ZirveProviderLiveRealOperationStatus {
		return fmt.Errorf("provider live real operation status must remain %s", ZirveProviderLiveRealOperationStatus)
	}
	if r.RequiredModuleCount != len(r.RequiredModules) {
		return errors.New("required module count mismatch")
	}
	if r.RequiredModuleCount != 6 {
		return errors.New("Zirve final closure requires exactly 6 completed dry-run modules")
	}
	if !r.AllRequiredModulesSealed {
		return errors.New("all required modules must be sealed")
	}
	if !r.HandoffReady {
		return errors.New("handoff must be ready")
	}
	if r.RealProviderAPIAllowed {
		return errors.New("real provider API must remain closed")
	}
	if r.RealFileDeliveryAllowed {
		return errors.New("real file delivery must remain closed")
	}
	if r.RealDeliveryChannelAllowed {
		return errors.New("real delivery channel must remain closed")
	}
	if r.RealERPWriteAllowed {
		return errors.New("real ERP write must remain closed")
	}
	if r.RealOperatorProviderActionAllowed {
		return errors.New("real operator provider action must remain closed")
	}

	for _, module := range r.RequiredModules {
		if err := module.Validate(); err != nil {
			return err
		}
	}

	return nil
}

func (m ZirveClosureModuleEvidence) Validate() error {
	if strings.TrimSpace(m.StepCode) == "" {
		return errors.New("module evidence step code is required")
	}
	if strings.TrimSpace(m.ModuleCode) == "" {
		return errors.New("module evidence module code is required")
	}
	if strings.TrimSpace(m.ModuleName) == "" {
		return errors.New("module evidence module name is required")
	}
	if m.RequiredPass && m.FinalStatus != "PASS" {
		return fmt.Errorf("module %s final status must be PASS", m.StepCode)
	}
	if m.RequiredAudit && strings.TrimSpace(m.EvidenceFile) == "" {
		return fmt.Errorf("module %s audit evidence file is required", m.StepCode)
	}
	if strings.TrimSpace(m.RuntimeFile) == "" {
		return fmt.Errorf("module %s runtime file is required", m.StepCode)
	}
	if strings.TrimSpace(m.TestFile) == "" {
		return fmt.Errorf("module %s test file is required", m.StepCode)
	}
	if strings.TrimSpace(m.ConfigFile) == "" {
		return fmt.Errorf("module %s config file is required", m.StepCode)
	}
	if strings.TrimSpace(m.DocFile) == "" {
		return fmt.Errorf("module %s doc file is required", m.StepCode)
	}
	return nil
}

func (r ZirveFinalClosureReport) CanStartRealProviderLiveModule() bool {
	return r.HandoffReady &&
		r.ProviderLiveHandoffGate == ZirveProviderLiveHandoffGate &&
		r.ProviderLiveModuleStatus == ZirveProviderLiveModuleFinalStatus &&
		!r.RealProviderAPIAllowed &&
		!r.RealFileDeliveryAllowed &&
		!r.RealDeliveryChannelAllowed &&
		!r.RealERPWriteAllowed &&
		!r.RealOperatorProviderActionAllowed
}

func (r ZirveFinalClosureReport) DecideFinalClosureOperation(operationCode string) OperationDecision {
	operationCode = strings.TrimSpace(operationCode)

	switch operationCode {
	case "DRY_RUN_FINAL_CLOSURE_SEAL",
		"DRY_RUN_PROVIDER_LIVE_HANDOFF_GATE_PREPARE":
		return OperationDecision{
			OperationCode: operationCode,
			Allowed:       true,
			Reason:        "dry-run module closure and provider live handoff preparation are allowed",
			RequiredGate:  ZirveProviderLiveHandoffGate,
		}
	default:
		return OperationDecision{
			OperationCode: operationCode,
			Allowed:       false,
			Reason:        "real provider operation remains closed until provider live module starts",
			RequiredGate:  ZirveProviderLiveHandoffGate,
		}
	}
}
