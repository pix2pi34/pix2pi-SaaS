package serviceregistry

import (
	"testing"
	"time"
)

func TestHeartbeatRequestValidate_Success(t *testing.T) {
	req := HeartbeatRequest{
		ServiceKey:               "identity-api",
		InstanceKey:              "identity-api-01",
		Status:                   "healthy",
		Mode:                     "push",
		ResponseTimeMS:           25,
		HeartbeatIntervalSeconds: 30,
		Metadata: map[string]any{
			"cpu": "low",
		},
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestHeartbeatRequestValidate_InvalidMode(t *testing.T) {
	req := HeartbeatRequest{
		ServiceKey:               "identity-api",
		InstanceKey:              "identity-api-01",
		Status:                   "healthy",
		Mode:                     "wrong",
		ResponseTimeMS:           25,
		HeartbeatIntervalSeconds: 30,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestHeartbeatRequestValidate_InvalidStatus(t *testing.T) {
	req := HeartbeatRequest{
		ServiceKey:               "identity-api",
		InstanceKey:              "identity-api-01",
		Status:                   "green",
		Mode:                     "push",
		ResponseTimeMS:           25,
		HeartbeatIntervalSeconds: 30,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestHeartbeatRequestValidate_InvalidResponseTime(t *testing.T) {
	req := HeartbeatRequest{
		ServiceKey:               "identity-api",
		InstanceKey:              "identity-api-01",
		Status:                   "healthy",
		Mode:                     "push",
		ResponseTimeMS:           -1,
		HeartbeatIntervalSeconds: 30,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestHeartbeatRequestValidate_InvalidHeartbeatInterval(t *testing.T) {
	req := HeartbeatRequest{
		ServiceKey:               "identity-api",
		InstanceKey:              "identity-api-01",
		Status:                   "healthy",
		Mode:                     "push",
		ResponseTimeMS:           25,
		HeartbeatIntervalSeconds: 2,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestHeartbeatResponseValidate_Success(t *testing.T) {
	resp := HeartbeatResponse{
		ServiceKey:             "identity-api",
		InstanceKey:            "identity-api-01",
		Status:                 "healthy",
		HeartbeatAcceptedAt:    time.Date(2026, 4, 24, 15, 0, 0, 0, time.UTC),
		NextHeartbeatInSeconds: 30,
		HealthPullRequested:    false,
	}

	if err := resp.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestHeartbeatResponseValidate_InvalidAcceptedAt(t *testing.T) {
	resp := HeartbeatResponse{
		ServiceKey:             "identity-api",
		InstanceKey:            "identity-api-01",
		Status:                 "healthy",
		NextHeartbeatInSeconds: 30,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
