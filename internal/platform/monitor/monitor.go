package monitor

import (
	"net"
	"net/http"
	"time"
)

type ServiceCheck struct {
	Name      string `json:"name"`
	Port      int    `json:"port"`
	HealthURL string `json:"health_url"`
}

type ServiceStatus struct {
	Name       string `json:"name"`
	Status     string `json:"status"`
	Method     string `json:"method"`
	Detail      string `json:"detail"`
	CheckedAt  string `json:"checked_at"`
	ResponseMS int64  `json:"response_ms"`
}

type Checker struct {
	Client *http.Client
}

func NewChecker(timeout time.Duration) *Checker {
	return &Checker{
		Client: &http.Client{Timeout: timeout},
	}
}

func (c *Checker) Check(s ServiceCheck) ServiceStatus {
	now := time.Now().UTC().Format(time.RFC3339)

	if s.HealthURL != "" {
		start := time.Now()
		resp, err := c.Client.Get(s.HealthURL)
		elapsed := time.Since(start).Milliseconds()

		if err == nil && resp != nil {
			defer resp.Body.Close()
			if resp.StatusCode >= 200 && resp.StatusCode < 300 {
				return ServiceStatus{
					Name:       s.Name,
					Status:     "RUNNING",
					Method:     "health",
					Detail:     resp.Status,
					CheckedAt:  now,
					ResponseMS: elapsed,
				}
			}

			return ServiceStatus{
				Name:       s.Name,
				Status:     "STOPPED",
				Method:     "health",
				Detail:     resp.Status,
				CheckedAt:  now,
				ResponseMS: elapsed,
			}
		}
	}

	address := net.JoinHostPort("127.0.0.1", intToString(s.Port))
	start := time.Now()
	conn, err := net.DialTimeout("tcp", address, 1500*time.Millisecond)
	elapsed := time.Since(start).Milliseconds()

	if err == nil {
		_ = conn.Close()
		return ServiceStatus{
			Name:       s.Name,
			Status:     "RUNNING",
			Method:     "port",
			Detail:     address,
			CheckedAt:  now,
			ResponseMS: elapsed,
		}
	}

	return ServiceStatus{
		Name:       s.Name,
		Status:     "STOPPED",
		Method:     "port",
		Detail:     address,
		CheckedAt:  now,
		ResponseMS: elapsed,
	}
}

func intToString(v int) string {
	if v == 0 {
		return "0"
	}

	buf := [20]byte{}
	i := len(buf)
	n := v

	for n > 0 {
		i--
		buf[i] = byte('0' + n%10)
		n /= 10
	}

	return string(buf[i:])
}
