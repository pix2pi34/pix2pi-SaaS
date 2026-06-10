package monitor

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrReportingRuntimeSourceRequired         = errors.New("monitor: reporting runtime source required")
	ErrReportingRuntimeObservedAtRequired     = errors.New("monitor: reporting runtime observed at required")
	ErrReportingRuntimeNegativeProjectionLag  = errors.New("monitor: reporting runtime projection lag cannot be negative")
	ErrReportingRuntimeNegativeRebuildQueue   = errors.New("monitor: reporting runtime rebuild queue cannot be negative")
	ErrReportingRuntimeNegativeQueryLoad      = errors.New("monitor: reporting runtime query load cannot be negative")
)

type RuntimeReportingPressureInput struct {
	Source            string
	ProjectionLagSec  float64
	RebuildQueueDepth int
	QueryLoadPct      float64
	ObservedAt        time.Time
}

func (i RuntimeReportingPressureInput) Validate() error {
	if strings.TrimSpace(i.Source) == "" {
		return ErrReportingRuntimeSourceRequired
	}
	if i.ObservedAt.IsZero() {
		return ErrReportingRuntimeObservedAtRequired
	}
	if i.ProjectionLagSec < 0 {
		return ErrReportingRuntimeNegativeProjectionLag
	}
	if i.RebuildQueueDepth < 0 {
		return ErrReportingRuntimeNegativeRebuildQueue
	}
	if i.QueryLoadPct < 0 {
		return ErrReportingRuntimeNegativeQueryLoad
	}

	return nil
}

func BuildRuntimeReportingPressureSnapshot(
	input RuntimeReportingPressureInput,
) (ReportingPressureSnapshot, error) {
	if err := input.Validate(); err != nil {
		return ReportingPressureSnapshot{}, err
	}

	snapshot := ReportingPressureSnapshot{
		Source:            strings.TrimSpace(input.Source),
		ProjectionLagSec:  input.ProjectionLagSec,
		RebuildQueueDepth: input.RebuildQueueDepth,
		QueryLoadPct:      input.QueryLoadPct,
		ObservedAt:        input.ObservedAt,
	}

	if err := snapshot.Validate(); err != nil {
		return ReportingPressureSnapshot{}, err
	}

	return snapshot, nil
}

func EvaluateRuntimeReportingPressure(
	input RuntimeReportingPressureInput,
	profile ReportingPressureThresholdProfile,
) ([]EarlyWarningSignal, error) {
	snapshot, err := BuildRuntimeReportingPressureSnapshot(input)
	if err != nil {
		return nil, err
	}

	return EvaluateReportingPressureEarlyWarnings(snapshot, profile)
}
