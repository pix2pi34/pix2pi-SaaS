package monitor

import (
	"errors"
	"fmt"
	"strings"
	"time"

	securityservice "github.com/divrigili/pix2pi-SaaS/internal/platform/security/service"
)

var (
	ErrObservabilityBridgeSignalsRequired = errors.New("monitor: observability bridge signals required")
)

const (
	ObservabilityAlarmKindSecurityAlarm = "security_alarm"
)

func BuildObservabilityAlarmFromSecuritySignal(
	signal securityservice.SecurityAlarmSignal,
	observedAt time.Time,
) (ObservabilityAlarmRecord, error) {
	if err := signal.Validate(); err != nil {
		return ObservabilityAlarmRecord{}, err
	}
	if observedAt.IsZero() {
		return ObservabilityAlarmRecord{}, ErrObservabilityAlarmObservedAtRequired
	}

	record := ObservabilityAlarmRecord{
		Kind:       ObservabilityAlarmKindSecurityAlarm,
		SignalType: strings.TrimSpace(signal.EventType),
		Source:     buildSecurityAlarmSource(signal),
		Severity:   strings.TrimSpace(signal.Severity),
		MetricKey:  strings.TrimSpace(signal.Escalation),
		Message: fmt.Sprintf(
			"security alarm category=%s escalation=%s alert=%t ticket=%t",
			strings.TrimSpace(signal.Category),
			strings.TrimSpace(signal.Escalation),
			signal.ShouldAlert,
			signal.ShouldCreateTicket,
		),
		ObservedAt: observedAt,
	}

	if err := record.Validate(); err != nil {
		return ObservabilityAlarmRecord{}, err
	}

	return record, nil
}

func EmitObservabilityAlarmFromSecuritySignal(
	sink ObservabilityAlarmSink,
	signal securityservice.SecurityAlarmSignal,
	observedAt time.Time,
) error {
	if sink == nil {
		return ErrObservabilityAlarmSinkRequired
	}

	record, err := BuildObservabilityAlarmFromSecuritySignal(signal, observedAt)
	if err != nil {
		return err
	}

	return sink.PublishObservabilityAlarm(record)
}

func EmitOpsAndSecurityObservabilityAlarms(
	sink ObservabilityAlarmSink,
	opsSignals []EarlyWarningSignal,
	securitySignals []securityservice.SecurityAlarmSignal,
	observedAt time.Time,
) error {
	if sink == nil {
		return ErrObservabilityAlarmSinkRequired
	}
	if len(opsSignals) == 0 && len(securitySignals) == 0 {
		return ErrObservabilityBridgeSignalsRequired
	}

	for _, signal := range opsSignals {
		if err := EmitObservabilityAlarmFromEarlyWarning(sink, signal); err != nil {
			return err
		}
	}

	for _, signal := range securitySignals {
		if err := EmitObservabilityAlarmFromSecuritySignal(sink, signal, observedAt); err != nil {
			return err
		}
	}

	return nil
}

func buildSecurityAlarmSource(signal securityservice.SecurityAlarmSignal) string {
	category := strings.TrimSpace(signal.Category)
	if category == "" {
		return "security"
	}

	return "security." + category
}
