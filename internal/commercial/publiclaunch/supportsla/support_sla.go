package supportsla

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type SLAStatus string

const (
	StatusReady    SLAStatus = "READY"
	StatusDraft    SLAStatus = "DRAFT"
	StatusDisabled SLAStatus = "DISABLED"
)

type Priority string

const (
	PriorityP0 Priority = "P0_CRITICAL"
	PriorityP1 Priority = "P1_HIGH"
	PriorityP2 Priority = "P2_NORMAL"
	PriorityP3 Priority = "P3_LOW"
)

type SLALevel struct {
	Key                 string
	Priority            Priority
	Title               string
	Status              SLAStatus
	Required            bool
	ResponseSLAHours    int
	ResolutionSLAHours  int
	EscalationSLAHours  int
	UpdateIntervalHours int
	TenantScoped        bool
	HasOpsOwner         bool
	HasBusinessOwner    bool
	HasEscalationRule   bool
	HasBreachPolicy     bool
	PublicVisible       bool
}

type SLAInput struct {
	Phase                  string
	Target                 string
	InternalSLAReady       bool
	ProductionSLAPublished bool
	RequiredPriorities     []Priority
	Levels                 []SLALevel
	RequireTenantScope     bool
	RequireOpsOwner        bool
	RequireBusinessOwner   bool
	RequireEscalationRule  bool
	RequireBreachPolicy    bool
	RequireUpdateInterval  bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type SLAReport struct {
	Status                 string
	InternalSLAReady       bool
	ProductionSLAPublished bool
	RequiredFailCount      int
	OptionalWarnCount      int
	PassCount              int
	Findings               []Finding
}

func Evaluate(input SLAInput) (SLAReport, error) {
	report := SLAReport{
		Status:                 "PASS",
		InternalSLAReady:       false,
		ProductionSLAPublished: false,
		Findings:               []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&report, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionSLAPublished {
		addFail(&report, "PRODUCTION_SLA_PUBLICATION_BLOCKED", "bu fazda production SLA public yayınlanamaz")
	}

	levelByPriority := map[Priority]SLALevel{}
	levelByKey := map[string]SLALevel{}

	for _, level := range input.Levels {
		key := strings.TrimSpace(level.Key)
		if key == "" {
			addFail(&report, "SLA_LEVEL_KEY_MISSING", "SLA level key boş olamaz")
			continue
		}

		if _, exists := levelByKey[key]; exists {
			addFail(&report, "SLA_LEVEL_DUPLICATE", fmt.Sprintf("SLA level duplicate: %s", key))
			continue
		}

		if _, exists := levelByPriority[level.Priority]; exists {
			addFail(&report, "SLA_PRIORITY_DUPLICATE", fmt.Sprintf("SLA priority duplicate: %s", level.Priority))
			continue
		}

		levelByKey[key] = level
		levelByPriority[level.Priority] = level

		if level.Required && level.Status != StatusReady {
			addFail(&report, "REQUIRED_SLA_NOT_READY", fmt.Sprintf("zorunlu SLA READY değil: %s", key))
		} else if level.Required {
			report.PassCount++
		}

		if level.Required && level.ResponseSLAHours <= 0 {
			addFail(&report, "RESPONSE_SLA_MISSING", fmt.Sprintf("response SLA eksik: %s", key))
		} else if level.Required {
			report.PassCount++
		}

		if level.Required && level.ResolutionSLAHours <= 0 {
			addFail(&report, "RESOLUTION_SLA_MISSING", fmt.Sprintf("resolution SLA eksik: %s", key))
		} else if level.Required {
			report.PassCount++
		}

		if level.Required && level.EscalationSLAHours <= 0 {
			addFail(&report, "ESCALATION_SLA_MISSING", fmt.Sprintf("escalation SLA eksik: %s", key))
		} else if level.Required {
			report.PassCount++
		}

		if input.RequireUpdateInterval && level.Required && level.UpdateIntervalHours <= 0 {
			addFail(&report, "UPDATE_INTERVAL_MISSING", fmt.Sprintf("customer update interval eksik: %s", key))
		} else if level.Required {
			report.PassCount++
		}

		if input.RequireTenantScope && level.Required && !level.TenantScoped {
			addFail(&report, "TENANT_SCOPE_REQUIRED", fmt.Sprintf("tenant scoped değil: %s", key))
		} else if level.Required {
			report.PassCount++
		}

		if input.RequireOpsOwner && level.Required && !level.HasOpsOwner {
			addFail(&report, "OPS_OWNER_REQUIRED", fmt.Sprintf("ops owner eksik: %s", key))
		} else if level.Required {
			report.PassCount++
		}

		if input.RequireBusinessOwner && level.Required && !level.HasBusinessOwner {
			addFail(&report, "BUSINESS_OWNER_REQUIRED", fmt.Sprintf("business owner eksik: %s", key))
		} else if level.Required {
			report.PassCount++
		}

		if input.RequireEscalationRule && level.Required && !level.HasEscalationRule {
			addFail(&report, "ESCALATION_RULE_REQUIRED", fmt.Sprintf("escalation rule eksik: %s", key))
		} else if level.Required {
			report.PassCount++
		}

		if input.RequireBreachPolicy && level.Required && !level.HasBreachPolicy {
			addFail(&report, "BREACH_POLICY_REQUIRED", fmt.Sprintf("breach policy eksik: %s", key))
		} else if level.Required {
			report.PassCount++
		}

		if level.PublicVisible {
			addFail(&report, "PUBLIC_VISIBLE_SLA_BLOCKED", fmt.Sprintf("bu fazda public visible SLA kapalı kalmalı: %s", key))
		}
	}

	for _, priority := range input.RequiredPriorities {
		level, exists := levelByPriority[priority]
		if !exists {
			addFail(&report, "REQUIRED_PRIORITY_MISSING", fmt.Sprintf("zorunlu priority SLA eksik: %s", priority))
			continue
		}
		if !level.Required {
			addFail(&report, "REQUIRED_PRIORITY_FLAG_FALSE", fmt.Sprintf("priority required=false: %s", priority))
			continue
		}
		report.PassCount++
	}

	if !isPriorityOrderValid(levelByPriority) {
		addFail(&report, "SLA_PRIORITY_ORDER_INVALID", "P0 SLA süreleri P1/P2/P3'ten daha sıkı olmalı")
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.InternalSLAReady = false
		report.ProductionSLAPublished = false
		return report, nil
	}

	report.Status = "PASS"
	report.InternalSLAReady = input.InternalSLAReady
	report.ProductionSLAPublished = false
	return report, nil
}

func RequiredPriorities(input SLAInput) []Priority {
	out := make([]Priority, 0, len(input.RequiredPriorities))
	out = append(out, input.RequiredPriorities...)
	sort.Slice(out, func(i, j int) bool {
		return priorityRank(out[i]) < priorityRank(out[j])
	})
	return out
}

func MustPass(report SLAReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("support SLA levels failed")
	}
	return nil
}

func addFail(report *SLAReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}

func isPriorityOrderValid(levels map[Priority]SLALevel) bool {
	p0, ok0 := levels[PriorityP0]
	p1, ok1 := levels[PriorityP1]
	p2, ok2 := levels[PriorityP2]
	p3, ok3 := levels[PriorityP3]
	if !(ok0 && ok1 && ok2 && ok3) {
		return false
	}

	return p0.ResponseSLAHours <= p1.ResponseSLAHours &&
		p1.ResponseSLAHours <= p2.ResponseSLAHours &&
		p2.ResponseSLAHours <= p3.ResponseSLAHours &&
		p0.ResolutionSLAHours <= p1.ResolutionSLAHours &&
		p1.ResolutionSLAHours <= p2.ResolutionSLAHours &&
		p2.ResolutionSLAHours <= p3.ResolutionSLAHours
}

func priorityRank(priority Priority) int {
	switch priority {
	case PriorityP0:
		return 0
	case PriorityP1:
		return 1
	case PriorityP2:
		return 2
	case PriorityP3:
		return 3
	default:
		return 99
	}
}
