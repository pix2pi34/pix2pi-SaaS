package tenantlifecycletests

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type TestStatus string

const (
	StatusReady       TestStatus = "READY"
	StatusPendingNext TestStatus = "PENDING_NEXT"
	StatusBlocked     TestStatus = "BLOCKED"
)

type LifecycleDomain string

const (
	DomainTenantShutdown LifecycleDomain = "TENANT_SHUTDOWN"
	DomainDataExport     LifecycleDomain = "DATA_EXPORT"
	DomainPlanChange     LifecycleDomain = "PLAN_CHANGE"
	DomainTenantFreeze   LifecycleDomain = "TENANT_FREEZE"
	DomainCrossFlow      LifecycleDomain = "CROSS_FLOW"
	DomainNextPriority   LifecycleDomain = "NEXT_PRIORITY"
)

type LifecycleTestCase struct {
	Key                       string
	Domain                    LifecycleDomain
	Title                     string
	Owner                     string
	Status                    TestStatus
	Required                  bool
	HasEvidence               bool
	HasCounterBasedAudit      bool
	RequiredFailCount         int
	OptionalWarnCount         int
	ProductionLiveEnabled     bool
	RealCustomerOpsEnabled    bool
	RequiresTenantID          bool
	RequiresAuditTrail        bool
	RequiresRollbackCoverage  bool
	RequiresConfigFixture     bool
	RequiresRuntimePackage    bool
	RequiresEvidenceFile      bool
	RequiresCrossFlowCoverage bool
	BlocksProductionLive      bool
	CoveredArtifacts          []string
	DeferredToCRMStageFlow    bool
	DeferredReason            string
}

type SuiteInput struct {
	Phase                          string
	Target                         string
	InternalLifecycleTestsReady    bool
	ProductionLifecycleLiveEnabled bool
	RealCustomerOpsOpen            bool
	RequiredTestKeys               []string
	RequiredDomains                []LifecycleDomain
	TestCases                      []LifecycleTestCase
	RequireEvidence                bool
	RequireCounterBasedAudit       bool
	RequireNoRequiredFail          bool
	RequireNoOptionalWarn          bool
	RequireTenantID                bool
	RequireAuditTrail              bool
	RequireRollbackCoverage        bool
	RequireConfigFixture           bool
	RequireRuntimePackage          bool
	RequireEvidenceFile            bool
	RequireCrossFlowCoverage       bool
	RequireProductionLiveBlock     bool
	AllowCRMStageDeferred          bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type SuiteReport struct {
	Status                         string
	InternalLifecycleTestsReady    bool
	ProductionLifecycleLiveEnabled bool
	RealCustomerOpsOpen            bool
	RequiredFailCount              int
	OptionalWarnCount              int
	PassCount                      int
	Findings                       []Finding
}

func Evaluate(input SuiteInput) (SuiteReport, error) {
	report := SuiteReport{
		Status:                         "PASS",
		InternalLifecycleTestsReady:    false,
		ProductionLifecycleLiveEnabled: false,
		RealCustomerOpsOpen:            false,
		Findings:                       []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionLifecycleLiveEnabled {
		addFail(&report, "PRODUCTION_LIFECYCLE_LIVE_BLOCKED", "bu fazda production tenant lifecycle live açılamaz")
	}

	if input.RealCustomerOpsOpen {
		addFail(&report, "REAL_CUSTOMER_OPS_BLOCKED", "bu fazda gerçek müşteri lifecycle operasyonu açılamaz")
	}

	testByKey := map[string]LifecycleTestCase{}
	domainCoverage := map[LifecycleDomain]bool{}

	for _, testCase := range input.TestCases {
		key := strings.TrimSpace(testCase.Key)
		if key == "" {
			addFail(&report, "TEST_CASE_KEY_MISSING", "tenant lifecycle test key boş olamaz")
			continue
		}

		if _, exists := testByKey[key]; exists {
			addFail(&report, "TEST_CASE_DUPLICATE", fmt.Sprintf("tenant lifecycle test duplicate: %s", key))
			continue
		}

		testByKey[key] = testCase
		domainCoverage[testCase.Domain] = true

		if testCase.Required && testCase.Status != StatusReady {
			if testCase.DeferredToCRMStageFlow && input.AllowCRMStageDeferred {
				report.PassCount++
			} else {
				addFail(&report, "REQUIRED_TEST_NOT_READY", fmt.Sprintf("required tenant lifecycle test READY değil: %s", key))
			}
		} else if testCase.Required {
			report.PassCount++
		}

		if input.RequireEvidence && testCase.Required && !testCase.HasEvidence {
			addFail(&report, "EVIDENCE_REQUIRED", fmt.Sprintf("evidence eksik: %s", key))
		} else if testCase.Required {
			report.PassCount++
		}

		if input.RequireCounterBasedAudit && testCase.Required && !testCase.HasCounterBasedAudit {
			addFail(&report, "COUNTER_BASED_AUDIT_REQUIRED", fmt.Sprintf("counter based audit eksik: %s", key))
		} else if testCase.Required {
			report.PassCount++
		}

		if input.RequireNoRequiredFail && testCase.Required && testCase.RequiredFailCount != 0 {
			addFail(&report, "REQUIRED_FAIL_MUST_BE_ZERO", fmt.Sprintf("required fail sıfır değil: %s", key))
		} else if testCase.Required {
			report.PassCount++
		}

		if input.RequireNoOptionalWarn && testCase.Required && testCase.OptionalWarnCount != 0 {
			addFail(&report, "OPTIONAL_WARN_MUST_BE_ZERO", fmt.Sprintf("optional warn sıfır değil: %s", key))
		} else if testCase.Required {
			report.PassCount++
		}

		if input.RequireTenantID && testCase.Required && !testCase.RequiresTenantID {
			addFail(&report, "TENANT_ID_REQUIRED", fmt.Sprintf("tenant_id coverage eksik: %s", key))
		} else if testCase.Required {
			report.PassCount++
		}

		if input.RequireAuditTrail && testCase.Required && !testCase.RequiresAuditTrail {
			addFail(&report, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail coverage eksik: %s", key))
		} else if testCase.Required {
			report.PassCount++
		}

		if input.RequireRollbackCoverage && testCase.Required && !testCase.RequiresRollbackCoverage {
			addFail(&report, "ROLLBACK_COVERAGE_REQUIRED", fmt.Sprintf("rollback coverage eksik: %s", key))
		} else if testCase.Required {
			report.PassCount++
		}

		if input.RequireConfigFixture && testCase.Required && !testCase.RequiresConfigFixture {
			addFail(&report, "CONFIG_FIXTURE_REQUIRED", fmt.Sprintf("config fixture coverage eksik: %s", key))
		} else if testCase.Required {
			report.PassCount++
		}

		if input.RequireRuntimePackage && testCase.Required && !testCase.RequiresRuntimePackage {
			addFail(&report, "RUNTIME_PACKAGE_REQUIRED", fmt.Sprintf("runtime package coverage eksik: %s", key))
		} else if testCase.Required {
			report.PassCount++
		}

		if input.RequireEvidenceFile && testCase.Required && !testCase.RequiresEvidenceFile {
			addFail(&report, "EVIDENCE_FILE_REQUIRED", fmt.Sprintf("evidence file coverage eksik: %s", key))
		} else if testCase.Required {
			report.PassCount++
		}

		if input.RequireCrossFlowCoverage && testCase.Required && !testCase.RequiresCrossFlowCoverage {
			addFail(&report, "CROSS_FLOW_COVERAGE_REQUIRED", fmt.Sprintf("cross flow coverage eksik: %s", key))
		} else if testCase.Required {
			report.PassCount++
		}

		if input.RequireProductionLiveBlock && testCase.Required && !testCase.BlocksProductionLive {
			addFail(&report, "PRODUCTION_LIVE_BLOCK_REQUIRED", fmt.Sprintf("production live block eksik: %s", key))
		} else if testCase.Required {
			report.PassCount++
		}

		if testCase.ProductionLiveEnabled {
			addFail(&report, "TEST_PRODUCTION_LIVE_ENABLED_BLOCKED", fmt.Sprintf("production live enabled açık olamaz: %s", key))
		}

		if testCase.RealCustomerOpsEnabled {
			addFail(&report, "TEST_REAL_CUSTOMER_OPS_ENABLED_BLOCKED", fmt.Sprintf("real customer ops enabled açık olamaz: %s", key))
		}

		if len(testCase.CoveredArtifacts) == 0 {
			addFail(&report, "COVERED_ARTIFACTS_REQUIRED", fmt.Sprintf("covered artifacts eksik: %s", key))
		}

		if testCase.DeferredToCRMStageFlow && strings.TrimSpace(testCase.DeferredReason) == "" {
			addFail(&report, "DEFERRED_REASON_REQUIRED", fmt.Sprintf("deferred reason eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredTestKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		testCase, exists := testByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_TEST_NOT_REGISTERED", fmt.Sprintf("required listesinde olup suite içinde yok: %s", requiredKey))
			continue
		}

		if !testCase.Required {
			addFail(&report, "REQUIRED_TEST_FLAG_FALSE", fmt.Sprintf("required listesinde ama test required=false: %s", requiredKey))
			continue
		}

		report.PassCount++
	}

	for _, domain := range input.RequiredDomains {
		if !domainCoverage[domain] {
			addFail(&report, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("tenant lifecycle test domain eksik: %s", domain))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		return report, nil
	}

	report.Status = "PASS"
	report.InternalLifecycleTestsReady = input.InternalLifecycleTestsReady
	report.ProductionLifecycleLiveEnabled = false
	report.RealCustomerOpsOpen = false
	return report, nil
}

func RequiredTestKeys(input SuiteInput) []string {
	keys := make([]string, 0, len(input.RequiredTestKeys))
	keys = append(keys, input.RequiredTestKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report SuiteReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("tenant lifecycle test suite failed")
	}
	return nil
}

func addFail(report *SuiteReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
