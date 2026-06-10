package monitor

import (
	"testing"
	"time"
)

func testRuntimeEventBacklogInput() RuntimeEventBacklogInput {
	return RuntimeEventBacklogInput{
		Source:         "nats-jetstream",
		BacklogDepth:   20,
		RetryCount:     1,
		ProcessedCount: 200,
		DLQDepth:       0,
		ObservedAt:     time.Now(),
	}
}

func TestRuntimeEventBacklogInput_Validate_Success(t *testing.T) {
	input := testRuntimeEventBacklogInput()

	if err := input.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestRuntimeEventBacklogInput_Validate_MissingSource(t *testing.T) {
	input := testRuntimeEventBacklogInput()
	input.Source = ""

	err := input.Validate()
	if err == nil {
		t.Fatal("expected missing source error")
	}
	if err != ErrEventBacklogRuntimeSourceRequired {
		t.Fatalf("expected ErrEventBacklogRuntimeSourceRequired, got %v", err)
	}
}

func TestRuntimeEventBacklogInput_Validate_NegativeDepth(t *testing.T) {
	input := testRuntimeEventBacklogInput()
	input.BacklogDepth = -1

	err := input.Validate()
	if err == nil {
		t.Fatal("expected negative depth error")
	}
	if err != ErrEventBacklogRuntimeNegativeDepth {
		t.Fatalf("expected ErrEventBacklogRuntimeNegativeDepth, got %v", err)
	}
}

func TestRuntimeEventBacklogInput_Validate_NegativeRetryCount(t *testing.T) {
	input := testRuntimeEventBacklogInput()
	input.RetryCount = -1

	err := input.Validate()
	if err == nil {
		t.Fatal("expected negative retry count error")
	}
	if err != ErrEventBacklogRuntimeNegativeRetryCount {
		t.Fatalf("expected ErrEventBacklogRuntimeNegativeRetryCount, got %v", err)
	}
}

func TestBuildRuntimeEventBacklogSnapshot_Success(t *testing.T) {
	input := testRuntimeEventBacklogInput()

	snapshot, err := BuildRuntimeEventBacklogSnapshot(input)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if snapshot.Source != "nats-jetstream" {
		t.Fatalf("expected nats-jetstream, got %s", snapshot.Source)
	}
	if snapshot.BacklogDepth != 20 {
		t.Fatalf("expected 20, got %d", snapshot.BacklogDepth)
	}
	if snapshot.RetryRatioPct != 0.5 {
		t.Fatalf("expected 0.5, got %v", snapshot.RetryRatioPct)
	}
}

func TestBuildRuntimeEventBacklogSnapshot_FailClosedRetryRatio(t *testing.T) {
	input := testRuntimeEventBacklogInput()
	input.ProcessedCount = 0
	input.RetryCount = 3

	snapshot, err := BuildRuntimeEventBacklogSnapshot(input)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if snapshot.RetryRatioPct != 100 {
		t.Fatalf("expected 100, got %v", snapshot.RetryRatioPct)
	}
}

func TestEvaluateRuntimeEventBacklog_NoSignal(t *testing.T) {
	signals, err := EvaluateRuntimeEventBacklog(
		testRuntimeEventBacklogInput(),
		DefaultEventBacklogThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(signals) != 0 {
		t.Fatalf("expected 0 signals, got %d", len(signals))
	}
}

func TestEvaluateRuntimeEventBacklog_BacklogHigh(t *testing.T) {
	input := testRuntimeEventBacklogInput()
	input.BacklogDepth = 2500

	signals, err := EvaluateRuntimeEventBacklog(
		input,
		DefaultEventBacklogThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 1 {
		t.Fatalf("expected 1 signal, got %d", len(signals))
	}
	if signals[0].MetricKey != EventBacklogMetricDepth {
		t.Fatalf("expected %s, got %s", EventBacklogMetricDepth, signals[0].MetricKey)
	}
	if signals[0].Severity != EarlyWarningSeverityHigh {
		t.Fatalf("expected %s, got %s", EarlyWarningSeverityHigh, signals[0].Severity)
	}
}

func TestEvaluateRuntimeEventBacklog_MultipleSignals(t *testing.T) {
	input := testRuntimeEventBacklogInput()
	input.BacklogDepth = 12000
	input.RetryCount = 30
	input.ProcessedCount = 100
	input.DLQDepth = 250

	signals, err := EvaluateRuntimeEventBacklog(
		input,
		DefaultEventBacklogThresholdProfile(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(signals) != 3 {
		t.Fatalf("expected 3 signals, got %d", len(signals))
	}
}
