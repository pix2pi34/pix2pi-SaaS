package supportopstests

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type CaseStatus string

const (
	StatusReady    CaseStatus = "READY"
	StatusDraft    CaseStatus = "DRAFT"
	StatusDisabled CaseStatus = "DISABLED"
)

type TestDomain string

const (
	DomainSLA           TestDomain = "SLA"
	DomainChannel       TestDomain = "CHANNEL"
	DomainTemplate      TestDomain = "TEMPLATE"
	DomainEscalation    TestDomain = "ESCALATION"
	DomainIncident      TestDomain = "INCIDENT"
	DomainEndToEnd      TestDomain = "END_TO_END"
	DomainNegativeGuard TestDomain = "NEGATIVE_GUARD"
)

type SupportOpsTestCase struct {
	Key                            string
	Domain                         TestDomain
	Title                          string
	Owner                          string
	Status                         CaseStatus
	Required                       bool
	HasPositivePath                bool
	HasNegativePath                bool
	HasTenantIsolationCheck        bool
	HasCorrelationIDCheck          bool
	HasAuditEvidenceCheck          bool
	HasCounterBasedResult          bool
	HasSLAAssertion                bool
	HasChannelAssertion            bool
	HasTemplateAssertion           bool
	HasEscalationAssertion         bool
	HasIncidentAssertion           bool
	BlocksPublicSupport            bool
	BlocksRealCustomerNotification bool
	BlocksProductionAutoAction     bool
	ExpectedRequiredFail           int
	ExpectedOptionalWarn           int
}

type TestSuiteInput struct {
	Phase                                string
	Target                               string
	InternalSupportOpsTestsReady         bool
	ProductionSupportOpsEnabled          bool
	RealCustomerNotificationEnabled      bool
	RequiredCaseKeys                     []string
	RequiredDomains                      []TestDomain
	Cases                                []SupportOpsTestCase
	RequirePositivePath                  bool
	RequireNegativePath                  bool
	RequireTenantIsolationCheck          bool
	RequireCorrelationIDCheck            bool
	RequireAuditEvidenceCheck            bool
	RequireCounterBasedResult            bool
	RequirePublicSupportBlock            bool
	RequireRealCustomerNotificationBlock bool
	RequireProductionAutoActionBlock     bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type TestSuiteReport struct {
	Status                          string
	InternalSupportOpsTestsReady    bool
	ProductionSupportOpsEnabled     bool
	RealCustomerNotificationEnabled bool
	RequiredFailCount               int
	OptionalWarnCount               int
	PassCount                       int
	Findings                        []Finding
}

func Evaluate(input TestSuiteInput) (TestSuiteReport, error) {
	report := TestSuiteReport{
		Status:                          "PASS",
		InternalSupportOpsTestsReady:    false,
		ProductionSupportOpsEnabled:     false,
		RealCustomerNotificationEnabled: false,
		Findings:                        []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionSupportOpsEnabled {
		addFail(&report, "PRODUCTION_SUPPORT_OPS_BLOCKED", "bu fazda production support ops enabled olamaz")
	}

	if input.RealCustomerNotificationEnabled {
		addFail(&report, "REAL_CUSTOMER_NOTIFICATION_BLOCKED", "bu fazda gerçek müşteri notification enabled olamaz")
	}

	caseByKey := map[string]SupportOpsTestCase{}
	domainCoverage := map[TestDomain]bool{}

	for _, tc := range input.Cases {
		key := strings.TrimSpace(tc.Key)
		if key == "" {
			addFail(&report, "TEST_CASE_KEY_MISSING", "test case key boş olamaz")
			continue
		}

		if _, exists := caseByKey[key]; exists {
			addFail(&report, "TEST_CASE_DUPLICATE", fmt.Sprintf("test case duplicate: %s", key))
			continue
		}

		caseByKey[key] = tc
		domainCoverage[tc.Domain] = true

		if tc.Required && tc.Status != StatusReady {
			addFail(&report, "REQUIRED_TEST_CASE_NOT_READY", fmt.Sprintf("zorunlu test case READY değil: %s", key))
		} else if tc.Required {
			report.PassCount++
		}

		if input.RequirePositivePath && tc.Required && !tc.HasPositivePath {
			addFail(&report, "POSITIVE_PATH_REQUIRED", fmt.Sprintf("positive path eksik: %s", key))
		} else if tc.Required {
			report.PassCount++
		}

		if input.RequireNegativePath && tc.Required && !tc.HasNegativePath {
			addFail(&report, "NEGATIVE_PATH_REQUIRED", fmt.Sprintf("negative path eksik: %s", key))
		} else if tc.Required {
			report.PassCount++
		}

		if input.RequireTenantIsolationCheck && tc.Required && !tc.HasTenantIsolationCheck {
			addFail(&report, "TENANT_ISOLATION_CHECK_REQUIRED", fmt.Sprintf("tenant isolation check eksik: %s", key))
		} else if tc.Required {
			report.PassCount++
		}

		if input.RequireCorrelationIDCheck && tc.Required && !tc.HasCorrelationIDCheck {
			addFail(&report, "CORRELATION_ID_CHECK_REQUIRED", fmt.Sprintf("correlation id check eksik: %s", key))
		} else if tc.Required {
			report.PassCount++
		}

		if input.RequireAuditEvidenceCheck && tc.Required && !tc.HasAuditEvidenceCheck {
			addFail(&report, "AUDIT_EVIDENCE_CHECK_REQUIRED", fmt.Sprintf("audit evidence check eksik: %s", key))
		} else if tc.Required {
			report.PassCount++
		}

		if input.RequireCounterBasedResult && tc.Required && !tc.HasCounterBasedResult {
			addFail(&report, "COUNTER_BASED_RESULT_REQUIRED", fmt.Sprintf("counter based result eksik: %s", key))
		} else if tc.Required {
			report.PassCount++
		}

		if input.RequirePublicSupportBlock && tc.Required && !tc.BlocksPublicSupport {
			addFail(&report, "PUBLIC_SUPPORT_BLOCK_REQUIRED", fmt.Sprintf("public support block eksik: %s", key))
		} else if tc.Required {
			report.PassCount++
		}

		if input.RequireRealCustomerNotificationBlock && tc.Required && !tc.BlocksRealCustomerNotification {
			addFail(&report, "REAL_CUSTOMER_NOTIFICATION_BLOCK_REQUIRED", fmt.Sprintf("real customer notification block eksik: %s", key))
		} else if tc.Required {
			report.PassCount++
		}

		if input.RequireProductionAutoActionBlock && tc.Required && !tc.BlocksProductionAutoAction {
			addFail(&report, "PRODUCTION_AUTO_ACTION_BLOCK_REQUIRED", fmt.Sprintf("production auto action block eksik: %s", key))
		} else if tc.Required {
			report.PassCount++
		}

		if tc.ExpectedRequiredFail != 0 {
			addFail(&report, "EXPECTED_REQUIRED_FAIL_MUST_BE_ZERO", fmt.Sprintf("expected required fail zero olmalı: %s", key))
		}

		if tc.ExpectedOptionalWarn != 0 {
			addFail(&report, "EXPECTED_OPTIONAL_WARN_MUST_BE_ZERO", fmt.Sprintf("expected optional warn zero olmalı: %s", key))
		}

		if !hasDomainAssertion(tc) {
			addFail(&report, "DOMAIN_ASSERTION_REQUIRED", fmt.Sprintf("domain assertion eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredCaseKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		tc, exists := caseByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_TEST_CASE_NOT_REGISTERED", fmt.Sprintf("required listesinde olup suite içinde yok: %s", requiredKey))
			continue
		}

		if !tc.Required {
			addFail(&report, "REQUIRED_TEST_CASE_FLAG_FALSE", fmt.Sprintf("required listesinde ama test case required=false: %s", requiredKey))
			continue
		}

		report.PassCount++
	}

	for _, domain := range input.RequiredDomains {
		if !domainCoverage[domain] {
			addFail(&report, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("support ops test domain eksik: %s", domain))
			continue
		}
		report.PassCount++
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalSupportOpsTestsReady = false
		report.ProductionSupportOpsEnabled = false
		report.RealCustomerNotificationEnabled = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalSupportOpsTestsReady = input.InternalSupportOpsTestsReady
	report.ProductionSupportOpsEnabled = false
	report.RealCustomerNotificationEnabled = false
	return report, nil
}

func RequiredCaseKeys(input TestSuiteInput) []string {
	keys := make([]string, 0, len(input.RequiredCaseKeys))
	keys = append(keys, input.RequiredCaseKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(report TestSuiteReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("support ops test suite failed")
	}
	return nil
}

func addFail(report *TestSuiteReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}

func hasDomainAssertion(tc SupportOpsTestCase) bool {
	switch tc.Domain {
	case DomainSLA:
		return tc.HasSLAAssertion
	case DomainChannel:
		return tc.HasChannelAssertion
	case DomainTemplate:
		return tc.HasTemplateAssertion
	case DomainEscalation:
		return tc.HasEscalationAssertion
	case DomainIncident:
		return tc.HasIncidentAssertion
	case DomainEndToEnd:
		return tc.HasSLAAssertion && tc.HasChannelAssertion && tc.HasTemplateAssertion && tc.HasEscalationAssertion && tc.HasIncidentAssertion
	case DomainNegativeGuard:
		return tc.HasNegativePath && tc.BlocksPublicSupport && tc.BlocksRealCustomerNotification && tc.BlocksProductionAutoAction
	default:
		return false
	}
}
