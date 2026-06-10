package integrationruntime

type ProviderModuleHandoffGateInput struct {
	RuntimeCodeReady               bool
	ConfigReady                    bool
	DocsReady                      bool
	TestsReady                     bool
	RealImplementationAuditReady   bool
	RealPaymentLiveEnabled         bool
	ProviderSpecificModuleRequired bool
}

type ProviderModuleHandoffGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateProviderModuleHandoffGate(input ProviderModuleHandoffGateInput) ProviderModuleHandoffGateResult {
	blockers := []string{}

	if !input.RuntimeCodeReady {
		blockers = append(blockers, "runtime_code_not_ready")
	}
	if !input.ConfigReady {
		blockers = append(blockers, "config_not_ready")
	}
	if !input.DocsReady {
		blockers = append(blockers, "docs_not_ready")
	}
	if !input.TestsReady {
		blockers = append(blockers, "tests_not_ready")
	}
	if !input.RealImplementationAuditReady {
		blockers = append(blockers, "real_implementation_audit_not_ready")
	}
	if input.RealPaymentLiveEnabled {
		blockers = append(blockers, "real_payment_live_must_remain_closed")
	}
	if !input.ProviderSpecificModuleRequired {
		blockers = append(blockers, "provider_specific_module_required")
	}

	if len(blockers) > 0 {
		return ProviderModuleHandoffGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ProviderModuleHandoffGateResult{
		Ready:    true,
		Decision: "READY_FOR_PROVIDER_MODULE",
		Blockers: []string{},
	}
}
