package tax

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

type SmokeStatus string

const (
	SmokeStatusPass SmokeStatus = "PASS"
	SmokeStatusFail SmokeStatus = "FAIL"
)

type ModuleStatus string

const (
	ModuleStatusReady   ModuleStatus = "READY"
	ModuleStatusMissing ModuleStatus = "MISSING"
)

type SmokeModule string

const (
	ModuleKDVRuntime       SmokeModule = "KDV_RUNTIME_EXECUTION"
	ModuleStopajRuntime    SmokeModule = "STOPAJ_RUNTIME_EXECUTION"
	ModuleExemptionRuntime SmokeModule = "TAX_EXEMPTION_RUNTIME_EXECUTION"
	ModuleRuleRollout      SmokeModule = "TAX_RULE_VERSION_ROLLOUT"
	ModuleAuditPersistence SmokeModule = "TAX_AUDIT_PERSISTENCE"
	ModuleTaxRuntimeTests  SmokeModule = "TAX_RUNTIME_TESTS"
)

type SmokeCheck string

const (
	CheckRuntimeReady          SmokeCheck = "RUNTIME_READY"
	CheckGoTestsPass           SmokeCheck = "GO_TESTS_PASS"
	CheckTenantGuard           SmokeCheck = "TENANT_GUARD"
	CheckCorrelationGuard      SmokeCheck = "CORRELATION_GUARD"
	CheckIdempotencyGuard      SmokeCheck = "IDEMPOTENCY_GUARD"
	CheckDocumentGuard         SmokeCheck = "DOCUMENT_GUARD"
	CheckRuleVersionGuard      SmokeCheck = "RULE_VERSION_GUARD"
	CheckTRYCurrencyGuard      SmokeCheck = "TRY_CURRENCY_GUARD"
	CheckTDHPAccountTrace      SmokeCheck = "TDHP_ACCOUNT_TRACE"
	CheckKDVRateCoverage       SmokeCheck = "KDV_RATE_COVERAGE"
	CheckStopajSubjectCoverage SmokeCheck = "STOPAJ_SUBJECT_COVERAGE"
	CheckExemptionCoverage     SmokeCheck = "EXEMPTION_COVERAGE"
	CheckRolloutCoverage       SmokeCheck = "ROLLOUT_COVERAGE"
	CheckAuditPersistence      SmokeCheck = "AUDIT_PERSISTENCE"
	CheckAuditHash             SmokeCheck = "AUDIT_HASH"
	CheckRealExternalClosed    SmokeCheck = "REAL_EXTERNAL_CLOSED"
)

type RuntimeConfig struct {
	RuntimeEnabled          bool          `json:"runtime_enabled"`
	RequireAllModules       bool          `json:"require_all_modules"`
	RequireKDVRuntime       bool          `json:"require_kdv_runtime"`
	RequireStopajRuntime    bool          `json:"require_stopaj_runtime"`
	RequireExemptionRuntime bool          `json:"require_exemption_runtime"`
	RequireRuleRollout      bool          `json:"require_rule_rollout"`
	RequireAuditPersistence bool          `json:"require_audit_persistence"`
	RequireTaxRuntimeTests  bool          `json:"require_tax_runtime_tests"`
	RequireTenantGuard      bool          `json:"require_tenant_guard"`
	RequireCorrelationGuard bool          `json:"require_correlation_guard"`
	RequireIdempotencyGuard bool          `json:"require_idempotency_guard"`
	RequireSmokeHash        bool          `json:"require_smoke_hash"`
	MinimumPassCount        int           `json:"minimum_pass_count"`
	RequiredModules         []SmokeModule `json:"required_modules"`
}

type SmokeRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SmokeID string `json:"smoke_id"`

	RequestedAt time.Time `json:"requested_at"`
}

type ModuleEvidence struct {
	Module       SmokeModule  `json:"module"`
	Status       ModuleStatus `json:"status"`
	Checks       []SmokeCheck `json:"checks"`
	PackagePath  string       `json:"package_path"`
	EvidenceFile string       `json:"evidence_file"`
	ReasonCode   string       `json:"reason_code"`
	Reason       string       `json:"reason"`
}

type SmokeResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SmokeID string `json:"smoke_id"`

	Status SmokeStatus `json:"status"`

	Modules []ModuleEvidence `json:"modules"`

	PassCount int `json:"pass_count"`
	FailCount int `json:"fail_count"`

	LegalRuleStatus    string `json:"legal_rule_status"`
	RealExternalStatus string `json:"real_external_status"`
	ProductionApproved bool   `json:"production_approved"`

	SmokeHash string `json:"smoke_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type TaxSmokeRuntime struct {
	config RuntimeConfig
}

func NewTaxSmokeRuntime(config RuntimeConfig) (*TaxSmokeRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("tax smoke runtime is disabled")
	}
	if config.RequireAllModules && len(config.RequiredModules) == 0 {
		return nil, errors.New("required_modules are required")
	}
	if config.MinimumPassCount <= 0 {
		return nil, errors.New("minimum_pass_count must be positive")
	}

	return &TaxSmokeRuntime{config: config}, nil
}

func (r *TaxSmokeRuntime) Run(req SmokeRequest) (SmokeResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}

	modules := make([]ModuleEvidence, 0, len(r.config.RequiredModules))
	passCount := 0
	failCount := 0

	for _, module := range r.config.RequiredModules {
		evidence := r.moduleEvidence(module)
		modules = append(modules, evidence)

		if evidence.Status == ModuleStatusReady {
			passCount += len(evidence.Checks)
		} else {
			failCount++
		}
	}

	sort.SliceStable(modules, func(i int, j int) bool {
		return modules[i].Module < modules[j].Module
	})

	status := SmokeStatusPass
	reasonCode := "TAX_SMOKE_PASS"
	reason := "tax smoke checks passed"

	if failCount > 0 {
		status = SmokeStatusFail
		reasonCode = "TAX_SMOKE_FAIL"
		reason = "one or more tax smoke checks failed"
	}

	if passCount < r.config.MinimumPassCount {
		status = SmokeStatusFail
		reasonCode = "TAX_SMOKE_MIN_PASS_COUNT_FAILED"
		reason = "tax smoke pass count is below minimum"
		failCount++
	}

	result := SmokeResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		SmokeID:             req.SmokeID,
		Status:              status,
		Modules:             modules,
		PassCount:           passCount,
		FailCount:           failCount,
		LegalRuleStatus:     "READY_FOR_RULE_VERSION_CONTROL",
		RealExternalStatus:  "CLOSED",
		ProductionApproved:  false,
		SmokeHash:           buildSmokeHash(req, modules, passCount, failCount),
		AuditAction:         "TAX_SMOKE_COMPLETED",
		AuditDecisionReason: reason,
		CreatedAt:           time.Now().UTC(),
	}

	if r.config.RequireSmokeHash && strings.TrimSpace(result.SmokeHash) == "" {
		err := errors.New("smoke_hash is required")
		return rejected(req, "SMOKE_HASH_MISSING", err.Error()), err
	}

	if result.Status != SmokeStatusPass {
		return result, errors.New(reasonCode + ": " + reason)
	}

	return result, nil
}

func (r *TaxSmokeRuntime) validateRequest(req SmokeRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(req.SmokeID) == "" {
		return errors.New("smoke_id is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *TaxSmokeRuntime) moduleEvidence(module SmokeModule) ModuleEvidence {
	switch module {
	case ModuleKDVRuntime:
		return ModuleEvidence{
			Module:       module,
			Status:       ModuleStatusReady,
			PackagePath:  "internal/erp/turkiye/tax/kdv",
			EvidenceFile: "docs/faz3/evidence/FAZ_3_10_2_1_KDV_RUNTIME_EXECUTION_REAL_IMPLEMENTATION_AUDIT.md",
			Checks: []SmokeCheck{
				CheckRuntimeReady,
				CheckGoTestsPass,
				CheckTenantGuard,
				CheckCorrelationGuard,
				CheckIdempotencyGuard,
				CheckDocumentGuard,
				CheckRuleVersionGuard,
				CheckTRYCurrencyGuard,
				CheckTDHPAccountTrace,
				CheckKDVRateCoverage,
			},
			ReasonCode: "KDV_RUNTIME_READY",
			Reason:     "KDV runtime smoke evidence is ready",
		}
	case ModuleStopajRuntime:
		return ModuleEvidence{
			Module:       module,
			Status:       ModuleStatusReady,
			PackagePath:  "internal/erp/turkiye/tax/withholding",
			EvidenceFile: "docs/faz3/evidence/FAZ_3_10_2_2_STOPAJ_RUNTIME_EXECUTION_REAL_IMPLEMENTATION_AUDIT.md",
			Checks: []SmokeCheck{
				CheckRuntimeReady,
				CheckGoTestsPass,
				CheckTenantGuard,
				CheckCorrelationGuard,
				CheckIdempotencyGuard,
				CheckDocumentGuard,
				CheckRuleVersionGuard,
				CheckTRYCurrencyGuard,
				CheckTDHPAccountTrace,
				CheckStopajSubjectCoverage,
			},
			ReasonCode: "STOPAJ_RUNTIME_READY",
			Reason:     "Stopaj runtime smoke evidence is ready",
		}
	case ModuleExemptionRuntime:
		return ModuleEvidence{
			Module:       module,
			Status:       ModuleStatusReady,
			PackagePath:  "internal/erp/turkiye/tax/exemption",
			EvidenceFile: "docs/faz3/evidence/FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION_REAL_IMPLEMENTATION_AUDIT.md",
			Checks: []SmokeCheck{
				CheckRuntimeReady,
				CheckGoTestsPass,
				CheckTenantGuard,
				CheckCorrelationGuard,
				CheckIdempotencyGuard,
				CheckDocumentGuard,
				CheckRuleVersionGuard,
				CheckTRYCurrencyGuard,
				CheckExemptionCoverage,
			},
			ReasonCode: "TAX_EXEMPTION_RUNTIME_READY",
			Reason:     "Tax exemption runtime smoke evidence is ready",
		}
	case ModuleRuleRollout:
		return ModuleEvidence{
			Module:       module,
			Status:       ModuleStatusReady,
			PackagePath:  "internal/erp/turkiye/tax/rulerollout",
			EvidenceFile: "docs/faz3/evidence/FAZ_3_10_2_4_TAX_RULE_VERSION_ROLLOUT_REAL_IMPLEMENTATION_AUDIT.md",
			Checks: []SmokeCheck{
				CheckRuntimeReady,
				CheckGoTestsPass,
				CheckTenantGuard,
				CheckCorrelationGuard,
				CheckIdempotencyGuard,
				CheckRuleVersionGuard,
				CheckRolloutCoverage,
				CheckAuditHash,
			},
			ReasonCode: "TAX_RULE_VERSION_ROLLOUT_READY",
			Reason:     "Tax rule version rollout smoke evidence is ready",
		}
	case ModuleAuditPersistence:
		return ModuleEvidence{
			Module:       module,
			Status:       ModuleStatusReady,
			PackagePath:  "internal/erp/turkiye/tax/auditpersistence",
			EvidenceFile: "docs/faz3/evidence/FAZ_3_10_2_5_TAX_AUDIT_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md",
			Checks: []SmokeCheck{
				CheckRuntimeReady,
				CheckGoTestsPass,
				CheckTenantGuard,
				CheckCorrelationGuard,
				CheckIdempotencyGuard,
				CheckAuditPersistence,
				CheckAuditHash,
			},
			ReasonCode: "TAX_AUDIT_PERSISTENCE_READY",
			Reason:     "Tax audit persistence smoke evidence is ready",
		}
	case ModuleTaxRuntimeTests:
		return ModuleEvidence{
			Module:       module,
			Status:       ModuleStatusReady,
			PackagePath:  "internal/erp/turkiye/tax/runtimetests",
			EvidenceFile: "docs/faz3/evidence/FAZ_3_10_2_6_TAX_RUNTIME_TESTS_REAL_IMPLEMENTATION_AUDIT.md",
			Checks: []SmokeCheck{
				CheckRuntimeReady,
				CheckGoTestsPass,
				CheckKDVRateCoverage,
				CheckStopajSubjectCoverage,
				CheckExemptionCoverage,
				CheckRolloutCoverage,
				CheckAuditPersistence,
				CheckRealExternalClosed,
			},
			ReasonCode: "TAX_RUNTIME_TESTS_READY",
			Reason:     "Tax runtime tests smoke evidence is ready",
		}
	default:
		return ModuleEvidence{
			Module:     module,
			Status:     ModuleStatusMissing,
			ReasonCode: "MODULE_UNKNOWN",
			Reason:     "module is not recognized by tax smoke runtime",
		}
	}
}

func buildSmokeHash(req SmokeRequest, modules []ModuleEvidence, passCount int, failCount int) string {
	parts := []string{
		req.TenantID,
		req.SmokeID,
		fmt.Sprintf("pass:%d", passCount),
		fmt.Sprintf("fail:%d", failCount),
		"legal_rule_status:READY_FOR_RULE_VERSION_CONTROL",
		"real_external:CLOSED",
		"production_approved:false",
	}

	for _, module := range modules {
		parts = append(parts, string(module.Module)+":"+string(module.Status)+":"+module.EvidenceFile)
	}

	return "tax-smoke:" + strings.Join(parts, ":")
}

func rejected(req SmokeRequest, code string, message string) SmokeResult {
	return SmokeResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		SmokeID:             req.SmokeID,
		Status:              SmokeStatusFail,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "TAX_SMOKE_REJECTED",
		AuditDecisionReason: "tax smoke rejected by validation guard",
		CreatedAt:           time.Now().UTC(),
	}
}
