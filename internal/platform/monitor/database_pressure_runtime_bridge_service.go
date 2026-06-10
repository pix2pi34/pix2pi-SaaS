package monitor

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrDatabaseRuntimeSourceRequired      = errors.New("monitor: database runtime source required")
	ErrDatabaseRuntimeObservedAtRequired  = errors.New("monitor: database runtime observed at required")
	ErrDatabaseRuntimeMaxConnectionsInvalid = errors.New("monitor: database runtime max connections invalid")
	ErrDatabaseRuntimeActiveConnectionsInvalid = errors.New("monitor: database runtime active connections invalid")
	ErrDatabaseRuntimeNegativeSlowQueryRatio = errors.New("monitor: database runtime slow query ratio cannot be negative")
	ErrDatabaseRuntimeNegativeWriteLatency = errors.New("monitor: database runtime write latency cannot be negative")
)

type RuntimeDatabasePressureInput struct {
	Source            string
	MaxConnections    int
	ActiveConnections int
	SlowQueryRatioPct float64
	WriteLatencyMs    float64
	ObservedAt        time.Time
}

func (i RuntimeDatabasePressureInput) Validate() error {
	if strings.TrimSpace(i.Source) == "" {
		return ErrDatabaseRuntimeSourceRequired
	}
	if i.ObservedAt.IsZero() {
		return ErrDatabaseRuntimeObservedAtRequired
	}
	if i.MaxConnections <= 0 {
		return ErrDatabaseRuntimeMaxConnectionsInvalid
	}
	if i.ActiveConnections < 0 || i.ActiveConnections > i.MaxConnections {
		return ErrDatabaseRuntimeActiveConnectionsInvalid
	}
	if i.SlowQueryRatioPct < 0 {
		return ErrDatabaseRuntimeNegativeSlowQueryRatio
	}
	if i.WriteLatencyMs < 0 {
		return ErrDatabaseRuntimeNegativeWriteLatency
	}

	return nil
}

func BuildRuntimeDatabasePressureSnapshot(
	input RuntimeDatabasePressureInput,
) (DatabasePressureSnapshot, error) {
	if err := input.Validate(); err != nil {
		return DatabasePressureSnapshot{}, err
	}

	connectionUsagePct := (float64(input.ActiveConnections) / float64(input.MaxConnections)) * 100

	snapshot := DatabasePressureSnapshot{
		Source:             strings.TrimSpace(input.Source),
		ConnectionUsagePct: connectionUsagePct,
		SlowQueryRatioPct:  input.SlowQueryRatioPct,
		WriteLatencyMs:     input.WriteLatencyMs,
		ObservedAt:         input.ObservedAt,
	}

	if err := snapshot.Validate(); err != nil {
		return DatabasePressureSnapshot{}, err
	}

	return snapshot, nil
}

func EvaluateRuntimeDatabasePressure(
	input RuntimeDatabasePressureInput,
	profile DatabasePressureThresholdProfile,
) ([]EarlyWarningSignal, error) {
	snapshot, err := BuildRuntimeDatabasePressureSnapshot(input)
	if err != nil {
		return nil, err
	}

	return EvaluateDatabasePressureEarlyWarnings(snapshot, profile)
}
