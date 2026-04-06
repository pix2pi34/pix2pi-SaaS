package platform

import "time"

type RetryPolicy struct {
	MaxAttempts int
	BaseDelay   time.Duration
	BackoffRate float64
}

func (p RetryPolicy) DelayFor(attempt int) time.Duration {
	if attempt <= 1 {
		return p.BaseDelay
	}

	delay := float64(p.BaseDelay)
	for i := 1; i < attempt; i++ {
		delay = delay * p.BackoffRate
	}

	return time.Duration(delay)
}

func (p RetryPolicy) CanRetry(attempt int) bool {
	return attempt < p.MaxAttempts
}
