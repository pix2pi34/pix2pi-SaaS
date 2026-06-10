package monitor

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrInfraPressureSourceRequired       = errors.New("monitor: infra pressure source required")
	ErrInfraPressureObservedAtRequired   = errors.New("monitor: infra pressure observed at required")
	ErrInfraPressureNegativeCPUUsage     = errors.New("monitor: infra cpu usage cannot be negative")
	ErrInfraPressureNegativeMemoryUsage  = errors.New("monitor: infra memory usage cannot be negative")
	ErrInfraPressureNegativeDiskUsage    = errors.New("monitor: infra disk usage cannot be negative")
	ErrInfraPressureNegativeIOWait       = errors.New("monitor: infra io wait cannot be negative")
)

const (
	InfraPressureMetricCPUUsagePct    = "infra_cpu_usage_pct"
	InfraPressureMetricMemoryUsagePct = "infra_memory_usage_pct"
	InfraPressureMetricDiskUsagePct   = "infra_disk_usage_pct"
	InfraPressureMetricIOWaitPct      = "infra_io_wait_pct"
)

type InfraPressureSnapshot struct {
	Source         string
	CPUUsagePct    float64
	MemoryUsagePct float64
	DiskUsagePct   float64
	IOWaitPct      float64
	ObservedAt     time.Time
}

func (s InfraPressureSnapshot) Validate() error {
	if strings.TrimSpace(s.Source) == "" {
		return ErrInfraPressureSourceRequired
	}
	if s.ObservedAt.IsZero() {
		return ErrInfraPressureObservedAtRequired
	}
	if s.CPUUsagePct < 0 {
		return ErrInfraPressureNegativeCPUUsage
	}
	if s.MemoryUsagePct < 0 {
		return ErrInfraPressureNegativeMemoryUsage
	}
	if s.DiskUsagePct < 0 {
		return ErrInfraPressureNegativeDiskUsage
	}
	if s.IOWaitPct < 0 {
		return ErrInfraPressureNegativeIOWait
	}

	return nil
}

type InfraPressureThresholdProfile struct {
	CPUUsagePolicy    EarlyWarningThresholdPolicy
	MemoryUsagePolicy EarlyWarningThresholdPolicy
	DiskUsagePolicy   EarlyWarningThresholdPolicy
	IOWaitPolicy      EarlyWarningThresholdPolicy
}

func (p InfraPressureThresholdProfile) Validate() error {
	if err := p.CPUUsagePolicy.Validate(); err != nil {
		return err
	}
	if err := p.MemoryUsagePolicy.Validate(); err != nil {
		return err
	}
	if err := p.DiskUsagePolicy.Validate(); err != nil {
		return err
	}
	if err := p.IOWaitPolicy.Validate(); err != nil {
		return err
	}

	return nil
}

func DefaultInfraCPUUsageThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         InfraPressureMetricCPUUsagePct,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      60,
		MediumThreshold:   75,
		HighThreshold:     90,
		CriticalThreshold: 97,
	}
}

func DefaultInfraMemoryUsageThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         InfraPressureMetricMemoryUsagePct,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      65,
		MediumThreshold:   80,
		HighThreshold:     90,
		CriticalThreshold: 97,
	}
}

func DefaultInfraDiskUsageThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         InfraPressureMetricDiskUsagePct,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      70,
		MediumThreshold:   85,
		HighThreshold:     92,
		CriticalThreshold: 98,
	}
}

func DefaultInfraIOWaitThresholdPolicy() EarlyWarningThresholdPolicy {
	return EarlyWarningThresholdPolicy{
		MetricKey:         InfraPressureMetricIOWaitPct,
		Direction:         ThresholdDirectionHigherIsWorse,
		LowThreshold:      5,
		MediumThreshold:   10,
		HighThreshold:     20,
		CriticalThreshold: 35,
	}
}

func DefaultInfraPressureThresholdProfile() InfraPressureThresholdProfile {
	return InfraPressureThresholdProfile{
		CPUUsagePolicy:    DefaultInfraCPUUsageThresholdPolicy(),
		MemoryUsagePolicy: DefaultInfraMemoryUsageThresholdPolicy(),
		DiskUsagePolicy:   DefaultInfraDiskUsageThresholdPolicy(),
		IOWaitPolicy:      DefaultInfraIOWaitThresholdPolicy(),
	}
}

func EvaluateInfraPressureEarlyWarnings(
	snapshot InfraPressureSnapshot,
	profile InfraPressureThresholdProfile,
) ([]EarlyWarningSignal, error) {
	if err := snapshot.Validate(); err != nil {
		return nil, err
	}
	if err := profile.Validate(); err != nil {
		return nil, err
	}

	signals := make([]EarlyWarningSignal, 0)

	cpuSignal, ok, err := buildInfraPressureSignal(
		snapshot,
		profile.CPUUsagePolicy,
		snapshot.CPUUsagePct,
		"infra cpu pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, cpuSignal)
	}

	memorySignal, ok, err := buildInfraPressureSignal(
		snapshot,
		profile.MemoryUsagePolicy,
		snapshot.MemoryUsagePct,
		"infra memory pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, memorySignal)
	}

	diskSignal, ok, err := buildInfraPressureSignal(
		snapshot,
		profile.DiskUsagePolicy,
		snapshot.DiskUsagePct,
		"infra disk pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, diskSignal)
	}

	ioWaitSignal, ok, err := buildInfraPressureSignal(
		snapshot,
		profile.IOWaitPolicy,
		snapshot.IOWaitPct,
		"infra io wait pressure detected",
	)
	if err != nil {
		return nil, err
	}
	if ok {
		signals = append(signals, ioWaitSignal)
	}

	return signals, nil
}

func buildInfraPressureSignal(
	snapshot InfraPressureSnapshot,
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
		SignalTypeInfraPressure,
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
