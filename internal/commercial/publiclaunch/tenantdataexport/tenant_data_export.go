package tenantdataexport

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type StepStatus string

const (
	StatusReady       StepStatus = "READY"
	StatusPendingNext StepStatus = "PENDING_NEXT"
	StatusBlocked     StepStatus = "BLOCKED"
)

type ExportEvent string

const (
	EventExportRequestReceived      ExportEvent = "EXPORT_REQUEST_RECEIVED"
	EventOwnerVerified              ExportEvent = "OWNER_VERIFIED"
	EventLegalHoldChecked           ExportEvent = "LEGAL_HOLD_CHECKED"
	EventDataScopeSelected          ExportEvent = "DATA_SCOPE_SELECTED"
	EventKVKKMaskingApplied         ExportEvent = "KVKK_MASKING_APPLIED"
	EventExportBundlePrepared       ExportEvent = "EXPORT_BUNDLE_PREPARED"
	EventChecksumManifestCreated    ExportEvent = "CHECKSUM_MANIFEST_CREATED"
	EventSecureDownloadReady        ExportEvent = "SECURE_DOWNLOAD_READY"
	EventHandoverAcceptanceRecorded ExportEvent = "HANDOVER_ACCEPTANCE_RECORDED"
	EventDeletionDeferred           ExportEvent = "DATA_DELETION_DEFERRED"
)

type ExportStep struct {
	Key                          string
	Event                        ExportEvent
	Title                        string
	Owner                        string
	Status                       StepStatus
	Required                     bool
	InternalReady                bool
	HasEvidence                  bool
	HasCounterBasedAudit         bool
	RequiredFailCount            int
	OptionalWarnCount            int
	ProductionExportEnabled      bool
	RealCustomerExportEnabled    bool
	DataDeletionEnabled          bool
	AutoTransferEnabled          bool
	RequiresTenantID             bool
	RequiresExportRequestID      bool
	RequiresOwnerApproval        bool
	RequiresLegalHoldCheck       bool
	RequiresDataScope            bool
	RequiresKVKKMasking          bool
	RequiresDataClassification   bool
	RequiresFormatPolicy         bool
	RequiresChecksumManifest     bool
	RequiresEncryption           bool
	RequiresSecureDownload       bool
	RequiresAuditTrail           bool
	RequiresRetentionPolicy      bool
	RequiresHandoverAcceptance   bool
	RequiresSupportHandoff       bool
	BlocksProductionExport       bool
	BlocksRealCustomerExport     bool
	BlocksDataDeletion           bool
	BlocksAutoTransfer           bool
	DeferredToProductionApproval bool
	DeferredToTenantShutdown     bool
	DeferredReason               string
}

type FlowInput struct {
	Phase                           string
	Target                          string
	InternalDataExportFlowReady     bool
	ProductionExportEnabled         bool
	RealCustomerExportEnabled       bool
	DataDeletionEnabled             bool
	AutoTransferEnabled             bool
	RequiredStepKeys                []string
	RequiredEvents                  []ExportEvent
	Steps                           []ExportStep
	RequireInternalReady            bool
	RequireEvidence                 bool
	RequireCounterBasedAudit        bool
	RequireNoRequiredFail           bool
	RequireNoOptionalWarn           bool
	RequireTenantID                 bool
	RequireExportRequestID          bool
	RequireOwnerApproval            bool
	RequireLegalHoldCheck           bool
	RequireDataScope                bool
	RequireKVKKMasking              bool
	RequireDataClassification       bool
	RequireFormatPolicy             bool
	RequireChecksumManifest         bool
	RequireEncryption               bool
	RequireSecureDownload           bool
	RequireAuditTrail               bool
	RequireRetentionPolicy          bool
	RequireHandoverAcceptance       bool
	RequireSupportHandoff           bool
	RequireProductionExportBlock    bool
	RequireRealCustomerExportBlock  bool
	RequireDataDeletionBlock        bool
	RequireAutoTransferBlock        bool
	AllowProductionApprovalDeferred bool
	AllowTenantShutdownDeferred     bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type FlowReport struct {
	Status                      string
	InternalDataExportFlowReady bool
	ProductionExportEnabled     bool
	RealCustomerExportEnabled   bool
	DataDeletionEnabled         bool
	AutoTransferEnabled         bool
	RequiredFailCount           int
	OptionalWarnCount           int
	PassCount                   int
	Findings                    []Finding
}

func Evaluate(input FlowInput) (FlowReport, error) {
	report := FlowReport{
		Status:                      "PASS",
		InternalDataExportFlowReady: false,
		ProductionExportEnabled:     false,
		RealCustomerExportEnabled:   false,
		DataDeletionEnabled:         false,
		AutoTransferEnabled:         false,
		Findings:                    []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionExportEnabled {
		addFail(&report, "PRODUCTION_EXPORT_BLOCKED", "bu fazda production export açılamaz")
	}

	if input.RealCustomerExportEnabled {
		addFail(&report, "REAL_CUSTOMER_EXPORT_BLOCKED", "bu fazda gerçek müşteri export açılamaz")
	}

	if input.DataDeletionEnabled {
		addFail(&report, "DATA_DELETION_BLOCKED", "bu fazda veri silme açılamaz")
	}

	if input.AutoTransferEnabled {
		addFail(&report, "AUTO_TRANSFER_BLOCKED", "bu fazda otomatik devir açılamaz")
	}

	stepByKey := map[string]ExportStep{}
	eventCoverage := map[ExportEvent]bool{}

	for _, step := range input.Steps {
		key := strings.TrimSpace(step.Key)
		if key == "" {
			addFail(&report, "EXPORT_STEP_KEY_MISSING", "export step key boş olamaz")
			continue
		}

		if _, exists := stepByKey[key]; exists {
			addFail(&report, "EXPORT_STEP_DUPLICATE", fmt.Sprintf("export step duplicate: %s", key))
			continue
		}

		stepByKey[key] = step
		eventCoverage[step.Event] = true

		if step.Required && step.Status != StatusReady {
			if isAllowedDeferred(step, input) {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_STEP_NOT_READY", fmt.Sprintf("required export step READY değil: %s", key))
			}
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireInternalReady && step.Required && !step.InternalReady {
			if isAllowedDeferred(step, input) {
				report.PassCount++
			} else {
				addFail(&report, "INTERNAL_READY_REQUIRED", fmt.Sprintf("internal ready eksik: %s", key))
			}
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireEvidence && step.Required && !step.HasEvidence {
			addFail(&report, "EVIDENCE_REQUIRED", fmt.Sprintf("evidence eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireCounterBasedAudit && step.Required && !step.HasCounterBasedAudit {
			addFail(&report, "COUNTER_BASED_AUDIT_REQUIRED", fmt.Sprintf("counter based audit eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireNoRequiredFail && step.Required && step.RequiredFailCount != 0 {
			addFail(&report, "REQUIRED_FAIL_MUST_BE_ZERO", fmt.Sprintf("required fail sıfır değil: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireNoOptionalWarn && step.Required && step.OptionalWarnCount != 0 {
			addFail(&report, "OPTIONAL_WARN_MUST_BE_ZERO", fmt.Sprintf("optional warn sıfır değil: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireTenantID && step.Required && !step.RequiresTenantID {
			addFail(&report, "TENANT_ID_REQUIRED", fmt.Sprintf("tenant_id requirement eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireExportRequestID && step.Required && !step.RequiresExportRequestID {
			addFail(&report, "EXPORT_REQUEST_ID_REQUIRED", fmt.Sprintf("export_request_id requirement eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireOwnerApproval && step.Required && !step.RequiresOwnerApproval {
			addFail(&report, "OWNER_APPROVAL_REQUIRED", fmt.Sprintf("owner approval eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireLegalHoldCheck && step.Required && !step.RequiresLegalHoldCheck {
			addFail(&report, "LEGAL_HOLD_CHECK_REQUIRED", fmt.Sprintf("legal hold check eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireDataScope && step.Required && !step.RequiresDataScope {
			addFail(&report, "DATA_SCOPE_REQUIRED", fmt.Sprintf("data scope eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireKVKKMasking && step.Required && !step.RequiresKVKKMasking {
			addFail(&report, "KVKK_MASKING_REQUIRED", fmt.Sprintf("KVKK masking eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireDataClassification && step.Required && !step.RequiresDataClassification {
			addFail(&report, "DATA_CLASSIFICATION_REQUIRED", fmt.Sprintf("data classification eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireFormatPolicy && step.Required && !step.RequiresFormatPolicy {
			addFail(&report, "FORMAT_POLICY_REQUIRED", fmt.Sprintf("format policy eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireChecksumManifest && step.Required && !step.RequiresChecksumManifest {
			addFail(&report, "CHECKSUM_MANIFEST_REQUIRED", fmt.Sprintf("checksum manifest eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireEncryption && step.Required && !step.RequiresEncryption {
			addFail(&report, "ENCRYPTION_REQUIRED", fmt.Sprintf("encryption eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireSecureDownload && step.Required && !step.RequiresSecureDownload {
			addFail(&report, "SECURE_DOWNLOAD_REQUIRED", fmt.Sprintf("secure download eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && step.Required && !step.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRetentionPolicy && step.Required && !step.RequiresRetentionPolicy {
			addFail(&report, "RETENTION_POLICY_REQUIRED", fmt.Sprintf("retention policy eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireHandoverAcceptance && step.Required && !step.RequiresHandoverAcceptance {
			addFail(&report, "HANDOVER_ACCEPTANCE_REQUIRED", fmt.Sprintf("handover acceptance eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireSupportHandoff && step.Required && !step.RequiresSupportHandoff {
			addFail(&report, "SUPPORT_HANDOFF_REQUIRED", fmt.Sprintf("support handoff eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireProductionExportBlock && step.Required && !step.BlocksProductionExport {
			addFail(&report, "PRODUCTION_EXPORT_BLOCK_REQUIRED", fmt.Sprintf("production export block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireRealCustomerExportBlock && step.Required && !step.BlocksRealCustomerExport {
			addFail(&report, "REAL_CUSTOMER_EXPORT_BLOCK_REQUIRED", fmt.Sprintf("real customer export block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireDataDeletionBlock && step.Required && !step.BlocksDataDeletion {
			addFail(&report, "DATA_DELETION_BLOCK_REQUIRED", fmt.Sprintf("data deletion block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if input.RequireAutoTransferBlock && step.Required && !step.BlocksAutoTransfer {
			addFail(&report, "AUTO_TRANSFER_BLOCK_REQUIRED", fmt.Sprintf("auto transfer block eksik: %s", key))
		} else if step.Required {
			report.PassCount++
		}

		if step.ProductionExportEnabled {
			addFail(&report, "STEP_PRODUCTION_EXPORT_ENABLED_BLOCKED", fmt.Sprintf("production export enabled açık olamaz: %s", key))
		}

		if step.RealCustomerExportEnabled {
			addFail(&report, "STEP_REAL_CUSTOMER_EXPORT_ENABLED_BLOCKED", fmt.Sprintf("real customer export enabled açık olamaz: %s", key))
		}

		if step.DataDeletionEnabled {
			addFail(&report, "STEP_DATA_DELETION_ENABLED_BLOCKED", fmt.Sprintf("data deletion enabled açık olamaz: %s", key))
		}

		if step.AutoTransferEnabled {
			addFail(&report, "STEP_AUTO_TRANSFER_ENABLED_BLOCKED", fmt.Sprintf("auto transfer enabled açık olamaz: %s", key))
		}

		if (step.DeferredToProductionApproval || step.DeferredToTenantShutdown) && strings.TrimSpace(step.DeferredReason) == "" {
			addFail(&report, "DEFERRED_REASON_REQUIRED", fmt.Sprintf("deferred reason eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredStepKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		step, exists := stepByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_STEP_NOT_REGISTERED", fmt.Sprintf("required listesinde olup flow içinde yok: %s", requiredKey))
			continue
		}

		if !step.Required {
			addFail(&report, "REQUIRED_STEP_FLAG_FALSE", fmt.Sprintf("required listesinde ama step required=false: %s", requiredKey))
			continue
		}

		report.PassCount++
	}

	for _, event := range input.RequiredEvents {
		if !eventCoverage[event] {
			addFail(&report, "REQUIRED_EVENT_MISSING", fmt.Sprintf("tenant data export event eksik: %s", event))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalDataExportFlowReady = false
		report.ProductionExportEnabled = false
		report.RealCustomerExportEnabled = false
		report.DataDeletionEnabled = false
		report.AutoTransferEnabled = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalDataExportFlowReady = input.InternalDataExportFlowReady
	report.ProductionExportEnabled = false
	report.RealCustomerExportEnabled = false
	report.DataDeletionEnabled = false
	report.AutoTransferEnabled = false
	return report, nil
}

func RequiredStepKeys(input FlowInput) []string {
	keys := make([]string, 0, len(input.RequiredStepKeys))
	keys = append(keys, input.RequiredStepKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report FlowReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("tenant data export handover flow failed")
	}
	return nil
}

func isAllowedDeferred(step ExportStep, input FlowInput) bool {
	if step.DeferredToProductionApproval && input.AllowProductionApprovalDeferred {
		return true
	}
	if step.DeferredToTenantShutdown && input.AllowTenantShutdownDeferred {
		return true
	}
	return false
}

func addFail(report *FlowReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
