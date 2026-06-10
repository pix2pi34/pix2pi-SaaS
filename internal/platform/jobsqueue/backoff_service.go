package jobsqueue

import (
	"context"
	"errors"
	"math"
	"strings"
	"time"
)

type CalculateJobBackoffUsecase struct {
	nowFn func() time.Time
}

func NewCalculateJobBackoffUsecase() *CalculateJobBackoffUsecase {
	return &CalculateJobBackoffUsecase{
		nowFn: time.Now,
	}
}

func (u *CalculateJobBackoffUsecase) Calculate(_ context.Context, req CalculateJobBackoffRequest) (CalculateJobBackoffResponse, error) {
	if u == nil {
		return CalculateJobBackoffResponse{}, errors.New("calculate backoff usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.JobID = strings.TrimSpace(req.JobID)
	req.Strategy = strings.TrimSpace(req.Strategy)
	req.LastErrorCode = strings.TrimSpace(req.LastErrorCode)

	if err := req.Validate(); err != nil {
		return CalculateJobBackoffResponse{}, err
	}

	calculatedAt := u.nowFn().UTC()

	delaySeconds := calculateBackoffDelaySeconds(
		req.Strategy,
		req.AttemptNo,
		req.BaseDelaySeconds,
		req.MaxDelaySeconds,
	)

	delaySeconds = applyDeterministicJitter(
		delaySeconds,
		req.JitterPercent,
		req.AttemptNo,
		req.JobID,
		req.LastErrorCode,
		req.MaxDelaySeconds,
	)

	retryAt := calculatedAt.Add(time.Duration(delaySeconds) * time.Second)

	resp := CalculateJobBackoffResponse{
		JobID:               req.JobID,
		Strategy:            req.Strategy,
		AttemptNo:           req.AttemptNo,
		BaseDelaySeconds:    req.BaseDelaySeconds,
		MaxDelaySeconds:     req.MaxDelaySeconds,
		JitterPercent:       req.JitterPercent,
		PlannedDelaySeconds: delaySeconds,
		RetryAt:             retryAt,
		CalculatedAt:        calculatedAt,
	}

	if err := resp.Validate(); err != nil {
		return CalculateJobBackoffResponse{}, err
	}

	return resp, nil
}

func calculateBackoffDelaySeconds(strategy string, attemptNo int, baseDelaySeconds int, maxDelaySeconds int) int {
	delay := baseDelaySeconds

	switch strings.TrimSpace(strategy) {
	case "fixed":
		delay = baseDelaySeconds
	case "linear":
		delay = baseDelaySeconds * attemptNo
	case "exponential":
		power := math.Pow(2, float64(attemptNo-1))
		delay = int(float64(baseDelaySeconds) * power)
	default:
		delay = baseDelaySeconds
	}

	if delay < 1 {
		delay = 1
	}

	if delay > maxDelaySeconds {
		delay = maxDelaySeconds
	}

	return delay
}

func applyDeterministicJitter(delaySeconds int, jitterPercent int, attemptNo int, jobID string, lastErrorCode string, maxDelaySeconds int) int {
	if jitterPercent <= 0 {
		return delaySeconds
	}

	seed := deterministicSeed(jobID, lastErrorCode, attemptNo)
	spread := int(math.Round(float64(delaySeconds*jitterPercent) / 100.0))
	if spread < 1 {
		spread = 1
	}

	offset := seed%(spread*2+1) - spread
	finalDelay := delaySeconds + offset

	if finalDelay < 1 {
		finalDelay = 1
	}

	if finalDelay > maxDelaySeconds {
		finalDelay = maxDelaySeconds
	}

	return finalDelay
}

func deterministicSeed(jobID string, lastErrorCode string, attemptNo int) int {
	text := jobID + "|" + lastErrorCode
	total := 0
	for _, ch := range text {
		total += int(ch)
	}
	total += attemptNo * 97
	if total < 0 {
		return -total
	}
	return total
}
