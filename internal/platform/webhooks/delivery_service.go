package webhooks

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"strings"
	"time"
)

type DeliverWebhookCommand struct {
	TenantID       string
	WebhookID      string
	SubscriptionID string
	EventID        string
	EventType      string
	TargetURL      string
	SecretRef      string
	Payload        map[string]any
	RequestedBy    string
	Signature      string
	SignedPayload  string
}

type DeliverWebhookResult struct {
	WebhookID      string
	SubscriptionID string
	EventID        string
	EventType      string
	TargetURL      string
	Signature      string
	Status         string
	AttemptNo      int
	DeliveryRef    string
}

type WebhookDeliveryStore interface {
	DeliverWebhook(ctx context.Context, cmd DeliverWebhookCommand) (DeliverWebhookResult, error)
}

type DeliverWebhookUsecase struct {
	store WebhookDeliveryStore
	nowFn func() time.Time
}

func NewDeliverWebhookUsecase(store WebhookDeliveryStore) *DeliverWebhookUsecase {
	return &DeliverWebhookUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *DeliverWebhookUsecase) Deliver(ctx context.Context, req DeliverWebhookRequest) (DeliverWebhookResponse, error) {
	if u == nil || u.store == nil {
		return DeliverWebhookResponse{}, errors.New("webhook delivery usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.WebhookID = strings.TrimSpace(req.WebhookID)
	req.SubscriptionID = strings.TrimSpace(req.SubscriptionID)
	req.EventID = strings.TrimSpace(req.EventID)
	req.EventType = strings.TrimSpace(req.EventType)
	req.TargetURL = strings.TrimSpace(req.TargetURL)
	req.SecretRef = strings.TrimSpace(req.SecretRef)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return DeliverWebhookResponse{}, err
	}

	signedPayload, err := stableJSON(req.Payload)
	if err != nil {
		return DeliverWebhookResponse{}, err
	}

	signature := signWebhookPayload(req.SecretRef, signedPayload)

	result, err := u.store.DeliverWebhook(ctx, DeliverWebhookCommand{
		TenantID:       req.TenantID,
		WebhookID:      req.WebhookID,
		SubscriptionID: req.SubscriptionID,
		EventID:        req.EventID,
		EventType:      req.EventType,
		TargetURL:      req.TargetURL,
		SecretRef:      req.SecretRef,
		Payload:        cloneMap(req.Payload),
		RequestedBy:    req.RequestedBy,
		Signature:      signature,
		SignedPayload:  signedPayload,
	})
	if err != nil {
		return DeliverWebhookResponse{}, err
	}

	resp := DeliverWebhookResponse{
		WebhookID:      firstNonEmpty(strings.TrimSpace(result.WebhookID), req.WebhookID),
		SubscriptionID: firstNonEmpty(strings.TrimSpace(result.SubscriptionID), req.SubscriptionID),
		EventID:        firstNonEmpty(strings.TrimSpace(result.EventID), req.EventID),
		EventType:      firstNonEmpty(strings.TrimSpace(result.EventType), req.EventType),
		TargetURL:      firstNonEmpty(strings.TrimSpace(result.TargetURL), req.TargetURL),
		Signature:      firstNonEmpty(strings.TrimSpace(result.Signature), signature),
		Status:         firstNonEmpty(strings.TrimSpace(result.Status), "sending"),
		AttemptNo:      firstNonZero(result.AttemptNo, 1),
		DeliveryRef:    strings.TrimSpace(result.DeliveryRef),
		RequestedBy:    req.RequestedBy,
		SignedAt:       u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return DeliverWebhookResponse{}, err
	}

	return resp, nil
}

func stableJSON(payload map[string]any) (string, error) {
	b, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

func signWebhookPayload(secretRef, payload string) string {
	mac := hmac.New(sha256.New, []byte(strings.TrimSpace(secretRef)))
	mac.Write([]byte(payload))
	return "sha256-" + hex.EncodeToString(mac.Sum(nil))
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}

func firstNonZero(values ...int) int {
	for _, v := range values {
		if v != 0 {
			return v
		}
	}
	return 0
}

func cloneMap(in map[string]any) map[string]any {
	if len(in) == 0 {
		return map[string]any{}
	}

	out := make(map[string]any, len(in))
	for k, v := range in {
		out[k] = v
	}

	return out
}
