package paymentadapter

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"
)

var (
	ErrPaymentWebhookInvalidDependency = errors.New("payment webhook invalid dependency")
	ErrPaymentWebhookInvalidRequest    = errors.New("payment webhook invalid request")
	ErrPaymentWebhookInvalidSignature  = errors.New("payment webhook invalid signature")
	ErrPaymentWebhookTimestampSkew     = errors.New("payment webhook timestamp skew")
	ErrPaymentWebhookProviderMismatch  = errors.New("payment webhook provider mismatch")
)

const defaultPaymentWebhookSkew = 5 * time.Minute

type PaymentWebhookIntakeRuntime struct {
	service       *PaymentService
	providerCode  string
	signingSecret []byte
	allowedSkew   time.Duration
	now           func() time.Time
}

type PaymentWebhookIntakeRequest struct {
	TenantID        string
	AttemptID       string
	ProviderCode    string
	CorrelationID   string
	RequestID       string
	SignatureHeader string
	RawPayload      []byte
	ReceivedAt      time.Time
}

type PaymentWebhookIntakeResult struct {
	Verified         bool
	ProviderCode     string
	Attempt          PaymentAttempt
	Decision         OperationContractDecision
	SignatureVersion string
	ReceivedAt       time.Time
}

type paymentWebhookSignatureParts struct {
	Timestamp time.Time
	Version   string
	Signature string
}

func NewPaymentWebhookIntakeRuntime(service *PaymentService, providerCode string, signingSecret string) (*PaymentWebhookIntakeRuntime, error) {
	if service == nil {
		return nil, fmt.Errorf("%w: payment service is required", ErrPaymentWebhookInvalidDependency)
	}
	if strings.TrimSpace(providerCode) == "" {
		return nil, fmt.Errorf("%w: provider code is required", ErrPaymentWebhookInvalidDependency)
	}
	if strings.TrimSpace(signingSecret) == "" {
		return nil, fmt.Errorf("%w: signing secret is required", ErrPaymentWebhookInvalidDependency)
	}

	return &PaymentWebhookIntakeRuntime{
		service:       service,
		providerCode:  strings.TrimSpace(providerCode),
		signingSecret: []byte(signingSecret),
		allowedSkew:   defaultPaymentWebhookSkew,
		now:           func() time.Time { return time.Now().UTC() },
	}, nil
}

func (r *PaymentWebhookIntakeRuntime) VerifyAndRecord(req PaymentWebhookIntakeRequest) (PaymentWebhookIntakeResult, error) {
	if err := r.validateRequest(req); err != nil {
		return PaymentWebhookIntakeResult{}, err
	}

	parts, err := parsePaymentWebhookSignatureHeader(req.SignatureHeader)
	if err != nil {
		return PaymentWebhookIntakeResult{}, err
	}
	if err := r.validateTimestamp(parts.Timestamp); err != nil {
		return PaymentWebhookIntakeResult{}, err
	}
	if !verifyPaymentWebhookSignature(r.signingSecret, parts.Timestamp, req.RawPayload, parts.Signature) {
		return PaymentWebhookIntakeResult{}, ErrPaymentWebhookInvalidSignature
	}

	result, err := r.service.VerifyWebhook(PaymentOperationRequest{
		AttemptID:             req.AttemptID,
		TenantID:              req.TenantID,
		CorrelationID:         req.CorrelationID,
		RequestID:             req.RequestID,
		ProviderTransactionID: "",
		WebhookSignature:      req.SignatureHeader,
		RawWebhookPayload:     req.RawPayload,
	})
	if err != nil {
		return PaymentWebhookIntakeResult{}, err
	}

	receivedAt := req.ReceivedAt
	if receivedAt.IsZero() {
		receivedAt = r.now().UTC()
	}

	return PaymentWebhookIntakeResult{
		Verified:         true,
		ProviderCode:     r.providerCode,
		Attempt:          result.Attempt,
		Decision:         result.Decision,
		SignatureVersion: parts.Version,
		ReceivedAt:       receivedAt,
	}, nil
}

func (r *PaymentWebhookIntakeRuntime) validateRequest(req PaymentWebhookIntakeRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return fmt.Errorf("%w: tenant id is required", ErrPaymentWebhookInvalidRequest)
	}
	if strings.TrimSpace(req.AttemptID) == "" {
		return fmt.Errorf("%w: attempt id is required", ErrPaymentWebhookInvalidRequest)
	}
	if strings.TrimSpace(req.ProviderCode) == "" {
		return fmt.Errorf("%w: provider code is required", ErrPaymentWebhookInvalidRequest)
	}
	if strings.TrimSpace(req.ProviderCode) != r.providerCode {
		return ErrPaymentWebhookProviderMismatch
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return fmt.Errorf("%w: correlation id is required", ErrPaymentWebhookInvalidRequest)
	}
	if strings.TrimSpace(req.SignatureHeader) == "" {
		return fmt.Errorf("%w: signature header is required", ErrPaymentWebhookInvalidRequest)
	}
	if len(req.RawPayload) == 0 {
		return fmt.Errorf("%w: raw webhook payload is required", ErrPaymentWebhookInvalidRequest)
	}
	return nil
}

func (r *PaymentWebhookIntakeRuntime) validateTimestamp(timestamp time.Time) error {
	now := r.now().UTC()
	diff := now.Sub(timestamp.UTC())
	if diff < 0 {
		diff = -diff
	}
	if diff > r.allowedSkew {
		return ErrPaymentWebhookTimestampSkew
	}
	return nil
}

func parsePaymentWebhookSignatureHeader(header string) (paymentWebhookSignatureParts, error) {
	parts := strings.Split(header, ",")
	values := map[string]string{}

	for _, part := range parts {
		keyValue := strings.SplitN(strings.TrimSpace(part), "=", 2)
		if len(keyValue) != 2 {
			continue
		}
		values[keyValue[0]] = keyValue[1]
	}

	timestampRaw := values["t"]
	signature := values["v1"]

	if strings.TrimSpace(timestampRaw) == "" || strings.TrimSpace(signature) == "" {
		return paymentWebhookSignatureParts{}, ErrPaymentWebhookInvalidSignature
	}

	unixTimestamp, err := strconv.ParseInt(timestampRaw, 10, 64)
	if err != nil {
		return paymentWebhookSignatureParts{}, ErrPaymentWebhookInvalidSignature
	}

	return paymentWebhookSignatureParts{
		Timestamp: time.Unix(unixTimestamp, 0).UTC(),
		Version:   "v1",
		Signature: signature,
	}, nil
}

func verifyPaymentWebhookSignature(secret []byte, timestamp time.Time, payload []byte, signature string) bool {
	expected := computePaymentWebhookSignature(secret, timestamp, payload)
	return hmac.Equal([]byte(expected), []byte(strings.TrimSpace(signature)))
}

func computePaymentWebhookSignature(secret []byte, timestamp time.Time, payload []byte) string {
	message := fmt.Sprintf("%d.%s", timestamp.Unix(), string(payload))
	mac := hmac.New(sha256.New, secret)
	_, _ = mac.Write([]byte(message))
	return hex.EncodeToString(mac.Sum(nil))
}

func BuildPaymentWebhookSignatureHeader(signingSecret string, timestamp time.Time, payload []byte) string {
	signature := computePaymentWebhookSignature([]byte(signingSecret), timestamp.UTC(), payload)
	return fmt.Sprintf("t=%d,v1=%s", timestamp.UTC().Unix(), signature)
}
