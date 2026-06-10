package serviceregistry

import "testing"

func TestRegisterServiceRequestValidate_Success(t *testing.T) {
	req := RegisterServiceRequest{
		ServiceKey:               "identity-api",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "tenant",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		OwnerTeam:                "identity",
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     9001,
		Version:                  "1.0.0",
		Status:                   "healthy",
		HeartbeatIntervalSeconds: 30,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestRegisterServiceRequestValidate_InvalidServiceKey(t *testing.T) {
	req := RegisterServiceRequest{
		ServiceKey:               "Identity API",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "tenant",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     9001,
		Status:                   "healthy",
		HeartbeatIntervalSeconds: 30,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi, ama hata donmedi")
	}
}

func TestRegisterServiceRequestValidate_InvalidVisibilityScope(t *testing.T) {
	req := RegisterServiceRequest{
		ServiceKey:               "identity-api",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "wrong",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     9001,
		Status:                   "healthy",
		HeartbeatIntervalSeconds: 30,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi, ama hata donmedi")
	}
}

func TestRegisterServiceRequestValidate_InvalidInstancePort(t *testing.T) {
	req := RegisterServiceRequest{
		ServiceKey:               "identity-api",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "tenant",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     70000,
		Status:                   "healthy",
		HeartbeatIntervalSeconds: 30,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi, ama hata donmedi")
	}
}

func TestRegisterServiceRequestValidate_InvalidHeartbeatInterval(t *testing.T) {
	req := RegisterServiceRequest{
		ServiceKey:               "identity-api",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "tenant",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     9001,
		Status:                   "healthy",
		HeartbeatIntervalSeconds: 2,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi, ama hata donmedi")
	}
}
