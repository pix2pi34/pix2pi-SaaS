package monitor

import (
	"errors"
	"fmt"
	"strings"
)

var (
	ErrScaleDecisionActionRequired        = errors.New("monitor: scale decision action required")
	ErrScaleDecisionReasonRequired        = errors.New("monitor: scale decision reason required")
	ErrScaleDecisionUnsupportedSignalType = errors.New("monitor: scale decision unsupported signal type")
)

const (
	ScaleActionObserveOnly      = "observe_only"
	ScaleActionServiceScale     = "service_scale"
	ScaleActionDatabaseSplit    = "database_split"
	ScaleActionEventBusUpgrade  = "event_bus_upgrade"
	ScaleActionReportingScale   = "reporting_scale"
	ScaleActionClusterTransition = "cluster_transition"
)

type ScaleLevelUpDecision struct {
	SignalType        string
	Severity          string
	MetricKey         string
	RecommendedAction string
	RequiresLevelUp   bool
	Reason            string
}

func (d ScaleLevelUpDecision) Validate() error {
	if strings.TrimSpace(d.SignalType) == "" {
		return ErrEarlyWarningSignalTypeRequired
	}
	if strings.TrimSpace(d.Severity) == "" {
		return ErrEarlyWarningSeverityRequired
	}
	if strings.TrimSpace(d.Reason) == "" {
		return ErrScaleDecisionReasonRequired
	}
	if d.RequiresLevelUp && strings.TrimSpace(d.RecommendedAction) == "" {
		return ErrScaleDecisionActionRequired
	}
	if !d.RequiresLevelUp && strings.TrimSpace(d.RecommendedAction) == "" {
		return ErrScaleDecisionActionRequired
	}

	return nil
}

func BuildScaleLevelUpDecision(
	signal EarlyWarningSignal,
) (ScaleLevelUpDecision, error) {
	if err := signal.Validate(); err != nil {
		return ScaleLevelUpDecision{}, err
	}

	decision := ScaleLevelUpDecision{
		SignalType: signal.SignalType,
		Severity:   signal.Severity,
		MetricKey:  signal.MetricKey,
	}

	switch signal.Severity {
	case EarlyWarningSeverityLow, EarlyWarningSeverityMedium:
		decision.RequiresLevelUp = false
		decision.RecommendedAction = ScaleActionObserveOnly
		decision.Reason = fmt.Sprintf("%s severity signal: continue observe", signal.Severity)

	case EarlyWarningSeverityHigh, EarlyWarningSeverityCritical:
		decision.RequiresLevelUp = true

		switch signal.SignalType {
		case SignalTypeServiceHealth:
			decision.RecommendedAction = ScaleActionServiceScale
			decision.Reason = "service health pressure requires service scale decision"

		case SignalTypeDatabasePressure:
			decision.RecommendedAction = ScaleActionDatabaseSplit
			decision.Reason = "database pressure requires db split decision"

		case SignalTypeEventBacklog:
			decision.RecommendedAction = ScaleActionEventBusUpgrade
			decision.Reason = "event backlog pressure requires event bus upgrade decision"

		case SignalTypeReportingLag:
			decision.RecommendedAction = ScaleActionReportingScale
			decision.Reason = "reporting pressure requires reporting scale decision"

		case SignalTypeInfraPressure:
			decision.RecommendedAction = ScaleActionClusterTransition
			decision.Reason = "infra pressure requires cluster transition decision"

		default:
			return ScaleLevelUpDecision{}, ErrScaleDecisionUnsupportedSignalType
		}

	default:
		return ScaleLevelUpDecision{}, ErrEarlyWarningSeverityRequired
	}

	if err := decision.Validate(); err != nil {
		return ScaleLevelUpDecision{}, err
	}

	return decision, nil
}
