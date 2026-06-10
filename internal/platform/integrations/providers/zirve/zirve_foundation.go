package zirve

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

const (
	ModuleCode  = "FAZ_7_8Z"
	ProviderID  = "zirve"
	DisplayName = "Zirve"

	ModuleStatusReady        = "READY"
	DryRunModuleStatus       = "FOUNDATION_READY_DRY_RUN_ONLY"
	ProviderLiveModuleStatus = "NOT_STARTED"

	RealProviderAPIStatus            = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	RealFileDeliveryStatus           = "CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
	RealERPWriteStatus               = "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
	RealDeliveryChannelStatus        = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	RealOperatorProviderActionStatus = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"

	HandoffGateStatus = "READY_FOR_PROVIDER_LIVE_MODULE"
	NoSecretPolicy    = "FORBIDDEN_IN_CODE_CONFIG_DOCS"
	TenantSafetyMode  = "TENANT_CONTEXT_REQUIRED"
	AuditPolicy       = "AUDIT_DECISION_REQUIRED_FOR_EVERY_OPERATION"
)

type CapabilityCode string

const (
	CapabilityProviderIdentity CapabilityCode = "PROVIDER_IDENTITY"
	CapabilityExportPackage    CapabilityCode = "EXPORT_PACKAGE_DRY_RUN_CONTRACT"
	CapabilityImportDelivery   CapabilityCode = "IMPORT_DELIVERY_CONTRACT_PLACEHOLDER"
	CapabilityValidation       CapabilityCode = "VALIDATION_ERROR_MAPPING_READY"
	CapabilityRetryDLQ         CapabilityCode = "RETRY_DLQ_POLICY_READY"
	CapabilityManualReview     CapabilityCode = "MANUAL_REVIEW_READY"
	CapabilityE2EDryRun        CapabilityCode = "E2E_DRY_RUN_READY"
)

type AuthMode string

const (
	AuthModeNoneDryRun        AuthMode = "NONE_DRY_RUN"
	AuthModeCredentialRefOnly AuthMode = "CREDENTIAL_REFERENCE_ONLY"
	AuthModeProviderLiveOnly  AuthMode = "PROVIDER_LIVE_MODULE_ONLY"
)

type DeliveryMode string

const (
	DeliveryModeNoneDryRun        DeliveryMode = "NONE_DRY_RUN"
	DeliveryModeFilePackageDryRun DeliveryMode = "FILE_PACKAGE_DRY_RUN"
	DeliveryModeProviderLiveOnly  DeliveryMode = "PROVIDER_LIVE_MODULE_ONLY"
)

type SyncDirection string

const (
	DirectionPix2piToZirve SyncDirection = "PIX2PI_TO_ZIRVE"
	DirectionZirveToPix2pi SyncDirection = "ZIRVE_TO_PIX2PI"
)

type ZirveProviderIdentity struct {
	ModuleCode                       string
	ProviderID                       string
	DisplayName                      string
	ModuleStatus                     string
	DryRunModuleStatus               string
	ProviderLiveModuleStatus         string
	HandoffGateStatus                string
	RealProviderAPIStatus            string
	RealFileDeliveryStatus           string
	RealERPWriteStatus               string
	RealDeliveryChannelStatus        string
	RealOperatorProviderActionStatus string
	NoSecretPolicy                   string
	TenantSafetyMode                 string
	AuditPolicy                      string
	SupportedCapabilities            []CapabilityCode
	SupportedAuthModes               []AuthMode
	SupportedDeliveryModes           []DeliveryMode
	SupportedSyncDirections          []SyncDirection
	ConfigFilePath                   string
	DocsPath                         string
	CreatedAtUTC                     time.Time
}

type OperationDecision struct {
	OperationCode string
	Allowed       bool
	Reason        string
	RequiredGate  string
}

type FoundationReadiness struct {
	ProviderID                        string
	ModuleCode                        string
	FoundationReady                   bool
	RealProviderAPIAllowed            bool
	RealFileDeliveryAllowed           bool
	RealERPWriteAllowed               bool
	RealDeliveryChannelAllowed        bool
	RealOperatorProviderActionAllowed bool
	HandoffGateStatus                 string
	ProviderLiveModuleStatus          string
}

func NewZirveProviderIdentity(now time.Time) ZirveProviderIdentity {
	if now.IsZero() {
		now = time.Now().UTC()
	}

	return ZirveProviderIdentity{
		ModuleCode:                       ModuleCode,
		ProviderID:                       ProviderID,
		DisplayName:                      DisplayName,
		ModuleStatus:                     ModuleStatusReady,
		DryRunModuleStatus:               DryRunModuleStatus,
		ProviderLiveModuleStatus:         ProviderLiveModuleStatus,
		HandoffGateStatus:                HandoffGateStatus,
		RealProviderAPIStatus:            RealProviderAPIStatus,
		RealFileDeliveryStatus:           RealFileDeliveryStatus,
		RealERPWriteStatus:               RealERPWriteStatus,
		RealDeliveryChannelStatus:        RealDeliveryChannelStatus,
		RealOperatorProviderActionStatus: RealOperatorProviderActionStatus,
		NoSecretPolicy:                   NoSecretPolicy,
		TenantSafetyMode:                 TenantSafetyMode,
		AuditPolicy:                      AuditPolicy,
		SupportedCapabilities: []CapabilityCode{
			CapabilityProviderIdentity,
			CapabilityExportPackage,
			CapabilityImportDelivery,
			CapabilityValidation,
			CapabilityRetryDLQ,
			CapabilityManualReview,
			CapabilityE2EDryRun,
		},
		SupportedAuthModes: []AuthMode{
			AuthModeNoneDryRun,
			AuthModeCredentialRefOnly,
			AuthModeProviderLiveOnly,
		},
		SupportedDeliveryModes: []DeliveryMode{
			DeliveryModeNoneDryRun,
			DeliveryModeFilePackageDryRun,
			DeliveryModeProviderLiveOnly,
		},
		SupportedSyncDirections: []SyncDirection{
			DirectionPix2piToZirve,
			DirectionZirveToPix2pi,
		},
		ConfigFilePath: "configs/faz7/integrations/zirve_connector_foundation.json",
		DocsPath:       "docs/faz7/integrations/zirve/FAZ_7_8Z_ZIRVE_CONNECTOR_FOUNDATION.md",
		CreatedAtUTC:   now.UTC(),
	}
}

func (z ZirveProviderIdentity) Validate() error {
	if strings.TrimSpace(z.ModuleCode) != ModuleCode {
		return fmt.Errorf("invalid module code: %s", z.ModuleCode)
	}
	if strings.TrimSpace(z.ProviderID) != ProviderID {
		return fmt.Errorf("invalid provider id: %s", z.ProviderID)
	}
	if strings.TrimSpace(z.DisplayName) != DisplayName {
		return fmt.Errorf("invalid display name: %s", z.DisplayName)
	}
	if z.ModuleStatus != ModuleStatusReady {
		return fmt.Errorf("module status must be %s", ModuleStatusReady)
	}
	if z.ProviderLiveModuleStatus != ProviderLiveModuleStatus {
		return fmt.Errorf("provider live module must remain %s", ProviderLiveModuleStatus)
	}
	if z.HandoffGateStatus != HandoffGateStatus {
		return fmt.Errorf("handoff gate must be %s", HandoffGateStatus)
	}
	if z.RealProviderAPIStatus != RealProviderAPIStatus {
		return errors.New("real provider API status is not closed")
	}
	if z.RealFileDeliveryStatus != RealFileDeliveryStatus {
		return errors.New("real file delivery status is not closed")
	}
	if z.RealERPWriteStatus != RealERPWriteStatus {
		return errors.New("real ERP write status is not closed")
	}
	if z.RealDeliveryChannelStatus != RealDeliveryChannelStatus {
		return errors.New("real delivery channel status is not closed")
	}
	if z.RealOperatorProviderActionStatus != RealOperatorProviderActionStatus {
		return errors.New("real operator provider action status is not closed")
	}
	if z.NoSecretPolicy != NoSecretPolicy {
		return errors.New("secret policy is not enforced")
	}
	if z.TenantSafetyMode != TenantSafetyMode {
		return errors.New("tenant safety mode is not enforced")
	}
	if z.AuditPolicy != AuditPolicy {
		return errors.New("audit policy is not enforced")
	}
	if len(z.SupportedCapabilities) < 7 {
		return errors.New("zirve capabilities are incomplete")
	}
	if len(z.SupportedAuthModes) < 3 {
		return errors.New("zirve auth modes are incomplete")
	}
	if len(z.SupportedDeliveryModes) < 3 {
		return errors.New("zirve delivery modes are incomplete")
	}
	if len(z.SupportedSyncDirections) < 2 {
		return errors.New("zirve sync directions are incomplete")
	}
	return nil
}

func (z ZirveProviderIdentity) HasCapability(capability CapabilityCode) bool {
	for _, item := range z.SupportedCapabilities {
		if item == capability {
			return true
		}
	}
	return false
}

func (z ZirveProviderIdentity) SupportsAuthMode(mode AuthMode) bool {
	for _, item := range z.SupportedAuthModes {
		if item == mode {
			return true
		}
	}
	return false
}

func (z ZirveProviderIdentity) SupportsDeliveryMode(mode DeliveryMode) bool {
	for _, item := range z.SupportedDeliveryModes {
		if item == mode {
			return true
		}
	}
	return false
}

func (z ZirveProviderIdentity) SupportsDirection(direction SyncDirection) bool {
	for _, item := range z.SupportedSyncDirections {
		if item == direction {
			return true
		}
	}
	return false
}

func (z ZirveProviderIdentity) CanUseRealProviderAPI() bool {
	return false
}

func (z ZirveProviderIdentity) CanDeliverRealFile() bool {
	return false
}

func (z ZirveProviderIdentity) CanWriteERP() bool {
	return false
}

func (z ZirveProviderIdentity) CanUseRealDeliveryChannel() bool {
	return false
}

func (z ZirveProviderIdentity) CanRunRealOperatorProviderAction() bool {
	return false
}

func (z ZirveProviderIdentity) DecideOperation(operationCode string) OperationDecision {
	operationCode = strings.TrimSpace(operationCode)
	if operationCode == "" {
		return OperationDecision{
			OperationCode: operationCode,
			Allowed:       false,
			Reason:        "operation code is required",
			RequiredGate:  HandoffGateStatus,
		}
	}

	switch operationCode {
	case "DRY_RUN_PROVIDER_IDENTITY",
		"DRY_RUN_EXPORT_PACKAGE_BUILD",
		"DRY_RUN_VALIDATION",
		"DRY_RUN_RETRY_DLQ_DECISION",
		"DRY_RUN_MANUAL_REVIEW_PREVIEW",
		"DRY_RUN_E2E_CHAIN":
		return OperationDecision{
			OperationCode: operationCode,
			Allowed:       true,
			Reason:        "dry-run foundation operation is allowed",
			RequiredGate:  "FOUNDATION_ONLY",
		}
	default:
		return OperationDecision{
			OperationCode: operationCode,
			Allowed:       false,
			Reason:        "real provider/API/file/ERP operation is closed until provider live module",
			RequiredGate:  HandoffGateStatus,
		}
	}
}

func (z ZirveProviderIdentity) Readiness() FoundationReadiness {
	return FoundationReadiness{
		ProviderID:                        z.ProviderID,
		ModuleCode:                        z.ModuleCode,
		FoundationReady:                   z.Validate() == nil,
		RealProviderAPIAllowed:            z.CanUseRealProviderAPI(),
		RealFileDeliveryAllowed:           z.CanDeliverRealFile(),
		RealERPWriteAllowed:               z.CanWriteERP(),
		RealDeliveryChannelAllowed:        z.CanUseRealDeliveryChannel(),
		RealOperatorProviderActionAllowed: z.CanRunRealOperatorProviderAction(),
		HandoffGateStatus:                 z.HandoffGateStatus,
		ProviderLiveModuleStatus:          z.ProviderLiveModuleStatus,
	}
}
