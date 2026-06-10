package paymentadapter

import (
	"errors"
	"fmt"
	"strings"
)

var ErrPaymentModuleClosureInvalidRequest = errors.New("payment module closure invalid request")

type PaymentModuleClosureStatus string

const (
	PaymentModuleClosurePass    PaymentModuleClosureStatus = "PASS"
	PaymentModuleClosureBlocked PaymentModuleClosureStatus = "BLOCKED"
)

type PaymentRealPaymentLiveStatus string

const (
	PaymentRealPaymentClosed PaymentRealPaymentLiveStatus = "CLOSED"
	PaymentRealPaymentOpen   PaymentRealPaymentLiveStatus = "OPEN"
)

type PaymentProviderHandoffStatus string

const (
	PaymentProviderHandoffReady    PaymentProviderHandoffStatus = "READY"
	PaymentProviderHandoffNotReady PaymentProviderHandoffStatus = "NOT_READY"
)

type PaymentClosureGate struct {
	Code        string
	Required    bool
	Passed      bool
	Description string
	Blocker     string
}

type PaymentModuleClosureRequest struct {
	ModuleCode string

	BillingCoreSeparated         bool
	ProviderContractReady        bool
	AttemptLifecycleReady        bool
	RepositoryContractReady      bool
	PostgresMigrationAuditPassed bool
	ServiceOrchestrationReady    bool
	WebhookIntakeReady           bool
	SimulationAdapterReady       bool
	SandboxE2EPassed             bool
	FailureRetryIdempotencyReady bool
	ObservabilityReady           bool
	AdminOpsReady                bool

	RealPaymentEnabled         bool
	ProductionProviderSelected bool
	LegalApprovalReady         bool
	FinanceTaxApprovalReady    bool
	SecurityApprovalReady      bool
	ProviderSecretPrepared     bool
	RollbackPlanReady          bool
}

type PaymentModuleClosureDecision struct {
	FinalStatus                      PaymentModuleClosureStatus
	RealPaymentLiveStatus            PaymentRealPaymentLiveStatus
	ProductionProviderHandoffStatus  PaymentProviderHandoffStatus
	PaymentProviderAdapterModuleSeal bool
	ReturnToFAZ7Main                 bool
	NextMainModuleCode               string
	RequiredGateCount                int
	PassedRequiredGateCount          int
	BlockerCount                     int
	Blockers                         []string
	Gates                            []PaymentClosureGate
}

type PaymentModuleClosureRuntime struct{}

func NewPaymentModuleClosureRuntime() *PaymentModuleClosureRuntime {
	return &PaymentModuleClosureRuntime{}
}

func (r *PaymentModuleClosureRuntime) Evaluate(req PaymentModuleClosureRequest) (PaymentModuleClosureDecision, error) {
	if strings.TrimSpace(req.ModuleCode) == "" {
		return PaymentModuleClosureDecision{}, fmt.Errorf("%w: module code is required", ErrPaymentModuleClosureInvalidRequest)
	}

	gates := []PaymentClosureGate{
		closureGate("module_code_7_5p", true, req.ModuleCode == "7-5P", "module code must be 7-5P"),
		closureGate("billing_core_separated", true, req.BillingCoreSeparated, "billing core must remain separated from payment provider adapter"),
		closureGate("provider_contract_ready", true, req.ProviderContractReady, "provider contract must be ready"),
		closureGate("attempt_lifecycle_ready", true, req.AttemptLifecycleReady, "payment attempt lifecycle must be ready"),
		closureGate("repository_contract_ready", true, req.RepositoryContractReady, "repository contract must be ready"),
		closureGate("postgres_migration_audit_passed", true, req.PostgresMigrationAuditPassed, "postgres migration real audit must pass"),
		closureGate("service_orchestration_ready", true, req.ServiceOrchestrationReady, "payment service orchestration must be ready"),
		closureGate("webhook_intake_ready", true, req.WebhookIntakeReady, "webhook intake runtime must be ready"),
		closureGate("simulation_adapter_ready", true, req.SimulationAdapterReady, "simulation adapter must be ready"),
		closureGate("sandbox_e2e_passed", true, req.SandboxE2EPassed, "sandbox e2e roundtrip must pass"),
		closureGate("failure_retry_idempotency_ready", true, req.FailureRetryIdempotencyReady, "failure retry idempotency hardening must be ready"),
		closureGate("observability_ready", true, req.ObservabilityReady, "observability and audit trail must be ready"),
		closureGate("admin_ops_ready", true, req.AdminOpsReady, "admin ops manual review must be ready"),
		closureGate("real_payment_disabled", true, !req.RealPaymentEnabled, "real payment must stay disabled at module closure"),
		closureGate("production_provider_selected", false, req.ProductionProviderSelected, "production provider should be selected before provider-specific module"),
		closureGate("legal_approval_ready", false, req.LegalApprovalReady, "legal approval is required before live payment"),
		closureGate("finance_tax_approval_ready", false, req.FinanceTaxApprovalReady, "finance and tax approval is required before live payment"),
		closureGate("security_approval_ready", false, req.SecurityApprovalReady, "security approval is required before live payment"),
		closureGate("provider_secret_prepared", false, req.ProviderSecretPrepared, "provider secret must be prepared before provider-specific module"),
		closureGate("rollback_plan_ready", false, req.RollbackPlanReady, "rollback plan must be ready before live payment"),
	}

	decision := PaymentModuleClosureDecision{
		FinalStatus:                      PaymentModuleClosurePass,
		RealPaymentLiveStatus:            PaymentRealPaymentClosed,
		ProductionProviderHandoffStatus:  PaymentProviderHandoffReady,
		PaymentProviderAdapterModuleSeal: true,
		ReturnToFAZ7Main:                 true,
		NextMainModuleCode:               "7-8",
		Gates:                            gates,
	}

	for _, gate := range gates {
		if gate.Required {
			decision.RequiredGateCount++
			if gate.Passed {
				decision.PassedRequiredGateCount++
			} else {
				decision.BlockerCount++
				decision.Blockers = append(decision.Blockers, gate.Blocker)
			}
		}
	}

	for _, gate := range gates {
		if !gate.Required && !gate.Passed {
			decision.ProductionProviderHandoffStatus = PaymentProviderHandoffNotReady
			break
		}
	}

	if decision.BlockerCount > 0 {
		decision.FinalStatus = PaymentModuleClosureBlocked
		decision.PaymentProviderAdapterModuleSeal = false
		decision.ReturnToFAZ7Main = false
	}

	return decision, nil
}

func closureGate(code string, required bool, passed bool, description string) PaymentClosureGate {
	blocker := ""
	if required && !passed {
		blocker = code + ": " + description
	}

	return PaymentClosureGate{
		Code:        code,
		Required:    required,
		Passed:      passed,
		Description: description,
		Blocker:     blocker,
	}
}

func PaymentModuleClosureRequiredGateCodes() []string {
	return []string{
		"module_code_7_5p",
		"billing_core_separated",
		"provider_contract_ready",
		"attempt_lifecycle_ready",
		"repository_contract_ready",
		"postgres_migration_audit_passed",
		"service_orchestration_ready",
		"webhook_intake_ready",
		"simulation_adapter_ready",
		"sandbox_e2e_passed",
		"failure_retry_idempotency_ready",
		"observability_ready",
		"admin_ops_ready",
		"real_payment_disabled",
	}
}

func PaymentModuleClosureProviderHandoffGateCodes() []string {
	return []string{
		"production_provider_selected",
		"legal_approval_ready",
		"finance_tax_approval_ready",
		"security_approval_ready",
		"provider_secret_prepared",
		"rollback_plan_ready",
	}
}
