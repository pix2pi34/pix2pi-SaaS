package monitor

import "errors"

var (
	ErrScaleLevelUpMatrixSignalsRequired = errors.New("monitor: scale level-up matrix signals required")
)

type ScaleLevelUpMatrixResult struct {
	RequiresLevelUp   bool
	HighestSeverity   string
	RecommendedActions []string
	Decisions         []ScaleLevelUpDecision
}

func (r ScaleLevelUpMatrixResult) Validate() error {
	if len(r.Decisions) == 0 {
		return ErrScaleLevelUpMatrixSignalsRequired
	}
	if r.HighestSeverity == "" {
		return ErrEarlyWarningSeverityRequired
	}
	if len(r.RecommendedActions) == 0 {
		return ErrScaleDecisionActionRequired
	}
	return nil
}

func BuildScaleLevelUpMatrix(
	signals []EarlyWarningSignal,
) (ScaleLevelUpMatrixResult, error) {
	if len(signals) == 0 {
		return ScaleLevelUpMatrixResult{}, ErrScaleLevelUpMatrixSignalsRequired
	}

	decisions := make([]ScaleLevelUpDecision, 0, len(signals))
	actionSet := make(map[string]struct{})
	actions := make([]string, 0)
	requiresLevelUp := false
	highestSeverity := ""

	for _, signal := range signals {
		decision, err := BuildScaleLevelUpDecision(signal)
		if err != nil {
			return ScaleLevelUpMatrixResult{}, err
		}

		decisions = append(decisions, decision)

		if decision.RequiresLevelUp {
			requiresLevelUp = true
		}

		if severityRank(decision.Severity) > severityRank(highestSeverity) {
			highestSeverity = decision.Severity
		}

		if _, ok := actionSet[decision.RecommendedAction]; !ok {
			actionSet[decision.RecommendedAction] = struct{}{}
			actions = append(actions, decision.RecommendedAction)
		}
	}

	result := ScaleLevelUpMatrixResult{
		RequiresLevelUp:    requiresLevelUp,
		HighestSeverity:    highestSeverity,
		RecommendedActions: actions,
		Decisions:          decisions,
	}

	if err := result.Validate(); err != nil {
		return ScaleLevelUpMatrixResult{}, err
	}

	return result, nil
}

func severityRank(severity string) int {
	switch severity {
	case EarlyWarningSeverityLow:
		return 1
	case EarlyWarningSeverityMedium:
		return 2
	case EarlyWarningSeverityHigh:
		return 3
	case EarlyWarningSeverityCritical:
		return 4
	default:
		return 0
	}
}
