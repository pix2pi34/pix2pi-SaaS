#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "=== PATCH GLOBAL HEALTH ENGINE ==="

cat <<'GOEOF' >> cmd/service-watchdog/service_watchdog_main.go

type GlobalStatus struct {
	SystemStatus     string   `json:"system_status"`
	HealthScore      int      `json:"health_score"`
	RiskLevel        string   `json:"risk_level"`
	CriticalServices []string `json:"critical_services"`
	DegradedServices []string `json:"degraded_services"`
	FlappingServices []string `json:"flapping_services"`
}

func calculateGlobalStatus(services []ServiceStatus) GlobalStatus {
	score := 0

	criticalList := []string{"api_gateway","identity","nats","redis"}

	var criticalDown []string
	var degraded []string
	var flapping []string

	for _, s := range services {

		switch s.Status {
		case "RUNNING":
			score += 10
		case "DEGRADED":
			score += 5
			degraded = append(degraded, s.Name)
		case "FLAPPING":
			score += 2
			flapping = append(flapping, s.Name)
		case "STOPPED":
			score -= 20
		}

		for _, c := range criticalList {
			if s.Name == c && s.Status == "STOPPED" {
				criticalDown = append(criticalDown, s.Name)
			}
		}
	}

	risk := "LOW"
	if score < 50 {
		risk = "HIGH"
	} else if score < 80 {
		risk = "MEDIUM"
	}

	system := "HEALTHY"
	if len(criticalDown) > 0 || risk == "HIGH" {
		system = "CRITICAL"
	} else if risk == "MEDIUM" {
		system = "WARNING"
	}

	return GlobalStatus{
		SystemStatus:     system,
		HealthScore:      score,
		RiskLevel:        risk,
		CriticalServices: criticalDown,
		DegradedServices: degraded,
		FlappingServices: flapping,
	}
}
GOEOF

echo "OK ✅ global health engine eklendi"
