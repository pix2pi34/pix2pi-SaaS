package loginsmoke

import "time"

type StepStatus struct {
	Step      string    `json:"step"`
	Name      string    `json:"name"`
	Status    string    `json:"status"`
	CheckedAt time.Time `json:"checked_at"`
}

type Report struct {
	Phase        string       `json:"phase"`
	Step         string       `json:"step"`
	Status       string       `json:"status"`
	PassCount    int          `json:"pass_count"`
	FailCount    int          `json:"fail_count"`
	CheckedSteps []StepStatus `json:"checked_steps"`
}

func BuildReport(now time.Time, statuses []StepStatus) Report {
	report := Report{
		Phase:        "FAZ 7-R",
		Step:         "317.9",
		Status:       "PASS",
		CheckedSteps: make([]StepStatus, 0, len(statuses)),
	}

	for _, status := range statuses {
		if status.CheckedAt.IsZero() {
			status.CheckedAt = now.UTC()
		}
		report.CheckedSteps = append(report.CheckedSteps, status)

		if status.Status == "PASS" {
			report.PassCount++
		} else {
			report.FailCount++
			report.Status = "FAIL"
		}
	}

	return report
}

func AllPass(report Report) bool {
	return report.Status == "PASS" && report.FailCount == 0 && report.PassCount == len(report.CheckedSteps)
}
