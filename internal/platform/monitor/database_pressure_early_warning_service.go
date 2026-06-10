package monitor

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrDatabasePressureSourceRequired         = errors.New("monitor: database pressure source required")
	ErrDatabasePressureObservedAtRequired     = errors.New("monitor: database pressure observed at required")
	ErrDatabasePressureNegativeConnUsage      = errors.New("monitor: database connection usage cannot be negative")
	ErrDatabasePressureNegativeSlowQueryRatio = errors.New("monitor: database slow query ratio cannot be negative")
	ErrDatabasePressureNegativeWriteLatency   = errors.New("monitor: database write latency cannot be negative")
)

const (
	DatabasePressureMetricConnectionUsagePct = "db_connection_usage_pct"
	DatabasePressureMetricSlowQueryRatioPct  = "db_slow_query_ratio_pct"
	DatabasePressureMetricWriteLatencyMs     = "db_write_latency_ms"
)

type DatabasePressureSnapshot struct {
	Source            string
	ConnectionUsagePct float64
	SlowQueryRatioPct  float64
	WriteLatencyMs     float64
	ObservedAt         time.Time
}

func (s DatabasePressureSnapshot) Validate() error {
	if strings.TrimSpace(s.Source) == "" {
		return ErrDatabasePressureSourceRequired
	}
	if s.ObservedAt.IsZero() {
		return ErrDatabasePressureObservedAtRequired
	}
	if s.ConnectionUsagePct < 0 {
		return ErrDatabasePressureNegativeConnUsage
	}
	if s.SlowQueryRatioPct < 0 {
		return ErrDatabasePressureNegativeSlowQueryRatio
	}
	if s.WriteLatencyMs < 0 {
		return ErrDatabasePressureNegativeWriteLatency
	}

	return nil
}

type DatabasePressureThresholdProfile struct {
	ConnectionUsagePolicy EarlyWarningThresholdPolicy
	SlowQueryRatioPolicy  EarlyWarningThresholdPolicy
	WriteLatencyPolicy    EarlyWarningThresholdPolicy
}

func (p DatabasePressureThresholdProfile) Validate() error {
	if err := p.ConnectionUsagePolicy.Validate(); err != nil {
		return err
	}
	if err := p.SlowQueryRatioPolicy.Validate(); err != nil {
		return err
	}
	if err := p.WriteLatencyPolicy.Validate(); err != nil {
		return err
	}

	return nil
}

func DefaultDBConnectionUsageThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         DatabasePressureMetricConnectionUsagePct,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      70,
		MediumThreshold:   80,
		HighThreshold:     90,
		CriticalThreshold: 97,
	}
}

func DefaultDBSlowQueryRatioThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         DatabasePressureMetricSlowQueryRatioPct,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      2,
		MediumThreshold:   5,
		HighThreshold:     10,
		CriticalThreshold: 20,
	}
}

func DefaultDBWriteLatencyThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         DatabasePressureMetricWriteLatencyMs,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      50,
		MediumThreshold:   150,
		HighThreshold:     400,
		CriticalThreshold: 1000,
	}
}

func DefaultDatabasePressureThresholdProfile() DatabasePressureThresholdProfile {
	return DatabasePressureThresholdProfile{
		ConnectionUsagePolicy: DefaultDBConnectionUsageThresholdPolicy(),
		SlowQueryRatioPolicy:  DefaultDBSlowQueryRatioThresholdPolicy(),
		WriteLatencyPolicy:    DefaultDBWriteLatencyThresholdPolicy(),
	}
}

func EvaluateDatabasePressureEarlyWarnings(
	snapshot DatabasePressureSnapshot,
	profile DatabasePressureThresholdProfile,
) ([]EarlyWarningSignal, error) {
	if err := snapshot.Validate(); err != nil {
		return nil, err
	}
	if err := profile.Validate(); err != nil {
		return nil, err
	}

	signals := make([]EarlyWarningSignal, 0)

	connectionSignal, ok, err := buildDatabasePressureSignal(
		snapshot,
		profile.ConnectionUsagePolicy,
		snapshot.ConnectionUsagePct,
		"database connection usage pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, connectionSignal)
	}

	slowQuerySignal, ok, err := buildDatabasePressureSignal(
		snapshot,
		profile.SlowQueryRatioPolicy,
		snapshot.SlowQueryRatioPct,
		"database slow query ratio pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, slowQuerySignal)
	}

	writeLatencySignal, ok, err := buildDatabasePressureSignal(
		snapshot,
		profile.WriteLatencyPolicy,
		snapshot.WriteLatencyMs,
		"database write latency pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, writeLatencySignal)
	}

	return signals, nil
}

func buildDatabasePressureSignal(
	snapshot DatabasePressureSnapshot,
	policy EarlyWarningThresholdPolicy,
	value float64,
	message string,
) (EarlyWarningSignal, bool, error) {
	severity, matched, err := EvaluateEarlyWarningThreshold(policy, value)
	if err != nil {
		return EarlyWarningSignal{}, false, err
	}
	if !matched {
		return EarlyWarningSignal{}, false, nil
	}

	signal, err := NewEarlyWarningSignal(
		SignalTypeDatabasePressure,
		snapshot.Source,
		severity,
		policy.MetricKey,
		value,
		fmt.Sprintf("%s: %s", snapshot.Source, message),
		snapshot.ObservedAt,
	)
	if err != nil {
		return EarlyWarningSignal{}, false, err
	}

	return signal, true, nil
}
