package monitor

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrInfraRuntimeSourceRequired       = errors.New("monitor: infra runtime source required")
	ErrInfraRuntimeObservedAtRequired   = errors.New("monitor: infra runtime observed at required")
	ErrInfraRuntimeNegativeCPUUsage     = errors.New("monitor: infra runtime cpu usage cannot be negative")
	ErrInfraRuntimeNegativeMemoryUsage  = errors.New("monitor: infra runtime memory usage cannot be negative")
	ErrInfraRuntimeNegativeDiskUsage    = errors.New("monitor: infra runtime disk usage cannot be negative")
	ErrInfraRuntimeNegativeIOWait       = errors.New("monitor: infra runtime io wait cannot be negative")
)

type RuntimeInfraPressureInput struct {
	Source         string
	CPUUsagePct    float64
	MemoryUsagePct float64
	DiskUsagePct   float64
	IOWaitPct      float64
	ObservedAt     time.Time
}

func (i RuntimeInfraPressureInput) Validate() error {
	if strings.TrimSpace(i.Source) == "" {
		return ErrInfraRuntimeSourceRequired
	}
	if i.ObservedAt.IsZero() {
		return ErrInfraRuntimeObservedAtRequired
	}
	if i.CPUUsagePct < 0 {
		return ErrInfraRuntimeNegativeCPUUsage
	}
	if i.MemoryUsagePct < 0 {
		return ErrInfraRuntimeNegativeMemoryUsage
	}
	if i.DiskUsagePct < 0 {
		return ErrInfraRuntimeNegativeDiskUsage
	}
	if i.IOWaitPct < 0 {
		return ErrInfraRuntimeNegativeIOWait
	}

	return nil
}

func BuildRuntimeInfraPressureSnapshot(
	input RuntimeInfraPressureInput,
) (InfraPressureSnapshot, error) {
	if err := input.Validate(); err != nil {
		return InfraPressureSnapshot{}, err
	}

	snapshot := InfraPressureSnapshot{
		Source:         strings.TrimSpace(input.Source),
		CPUUsagePct:    input.CPUUsagePct,
		MemoryUsagePct: input.MemoryUsagePct,
		DiskUsagePct:   input.DiskUsagePct,
		IOWaitPct:      input.IOWaitPct,
		ObservedAt:     input.ObservedAt,
	}

	if err := snapshot.Validate(); err != nil {
		return InfraPressureSnapshot{}, err
	}

	return snapshot, nil
}

func EvaluateRuntimeInfraPressure(
	input RuntimeInfraPressureInput,
	profile InfraPressureThresholdProfile,
) ([]EarlyWarningSignal, error) {
	snapshot, err := BuildRuntimeInfraPressureSnapshot(input)
	if err != nil {
		return nil, err
	}

	return EvaluateInfraPressureEarlyWarnings(snapshot, profile)
}
