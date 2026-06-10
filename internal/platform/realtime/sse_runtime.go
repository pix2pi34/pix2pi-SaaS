package realtime

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"sync/atomic"
	"time"
)

const (
	SSEEventTypeWelcome   = "welcome"
	SSEEventTypeHeartbeat = "heartbeat"
	SSEEventTypeError     = "error"
)

var (
	ErrSSEMissingTenant  = errors.New("missing tenant id")
	ErrSSEMissingChannel = errors.New("missing sse channel")
)

type SSERuntimeConfig struct {
	TenantHeader             string
	RequireTenant            bool
	HeartbeatIntervalSeconds int
	AllowCORS                bool
}

func DefaultSSERuntimeConfig() SSERuntimeConfig {
	return SSERuntimeConfig{
		TenantHeader:             DefaultTenantHeader,
		RequireTenant:            true,
		HeartbeatIntervalSeconds: 15,
		AllowCORS:                false,
	}
}

type SSEConnectionContext struct {
	TenantID       string `json:"tenant_id"`
	Channel        string `json:"channel"`
	UserID         string `json:"user_id,omitempty"`
	RemoteAddr     string `json:"remote_addr,omitempty"`
	ConnectedAt    string `json:"connected_at"`
	CorrelationID  string `json:"correlation_id,omitempty"`
	AuthDecision   string `json:"auth_decision,omitempty"`
	AuthReason     string `json:"auth_reason,omitempty"`
	ConnectionID   string `json:"connection_id,omitempty"`
	PresenceStatus string `json:"presence_status,omitempty"`
}

type SSEServerEvent struct {
	Type      string      `json:"type"`
	TenantID  string      `json:"tenant_id"`
	Channel   string      `json:"channel"`
	Payload   interface{} `json:"payload,omitempty"`
	Timestamp string      `json:"timestamp"`
}

type SSERuntime struct {
	config            SSERuntimeConfig
	activeCount       atomic.Int64
	channelAuthorizer ChannelAuthorizer
	presenceRuntime   *PresenceRuntime
}

func NewSSERuntime(config SSERuntimeConfig) *SSERuntime {
	if strings.TrimSpace(config.TenantHeader) == "" {
		config.TenantHeader = DefaultTenantHeader
	}
	if config.HeartbeatIntervalSeconds <= 0 {
		config.HeartbeatIntervalSeconds = 15
	}

	return &SSERuntime{
		config:            config,
		channelAuthorizer: NewChannelAuthRuntime(DefaultChannelAuthRuntimeConfig()),
		presenceRuntime:   NewPresenceRuntime(),
	}
}

func (r *SSERuntime) ActiveConnectionCount() int64 {
	return r.activeCount.Load()
}

func (r *SSERuntime) PresenceConnectionCount(tenantID string) int {
	if r.presenceRuntime == nil {
		return 0
	}
	return r.presenceRuntime.CountTenantConnections(tenantID)
}

func (r *SSERuntime) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	ctx, err := r.connectionContext(req)
	if err != nil {
		switch {
		case errors.Is(err, ErrSSEMissingTenant):
			http.Error(w, err.Error(), http.StatusUnauthorized)
		case errors.Is(err, ErrSSEMissingChannel):
			http.Error(w, err.Error(), http.StatusBadRequest)
		case errors.Is(err, ErrChannelAuthDenied):
			http.Error(w, err.Error(), http.StatusForbidden)
		default:
			http.Error(w, err.Error(), http.StatusBadRequest)
		}
		return
	}

	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming unsupported", http.StatusInternalServerError)
		return
	}

	if r.presenceRuntime != nil {
		presence, err := r.presenceRuntime.Connect(PresenceConnectRequest{
			TenantID:      ctx.TenantID,
			Channel:       ctx.Channel,
			UserID:        ctx.UserID,
			Transport:     RealtimeTransportSSE,
			RemoteAddr:    ctx.RemoteAddr,
			CorrelationID: ctx.CorrelationID,
		})
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		ctx.ConnectionID = presence.ConnectionID
		ctx.PresenceStatus = presence.Status
		defer func() {
			_, _ = r.presenceRuntime.Disconnect(ctx.TenantID, ctx.ConnectionID, "sse_closed")
		}()
	}

	r.applyHeaders(w)

	r.activeCount.Add(1)
	defer r.activeCount.Add(-1)

	if err := r.writeEvent(w, flusher, ctx, SSEEventTypeWelcome, map[string]string{
		"status":          "connected",
		"auth_decision":   ctx.AuthDecision,
		"auth_reason":     ctx.AuthReason,
		"connection_id":   ctx.ConnectionID,
		"presence_status": ctx.PresenceStatus,
	}); err != nil {
		return
	}

	heartbeat := time.NewTicker(time.Duration(r.config.HeartbeatIntervalSeconds) * time.Second)
	defer heartbeat.Stop()

	for {
		select {
		case <-req.Context().Done():
			return
		case <-heartbeat.C:
			if r.presenceRuntime != nil && ctx.ConnectionID != "" {
				_, _ = r.presenceRuntime.Heartbeat(ctx.TenantID, ctx.ConnectionID)
			}
			if err := r.writeEvent(w, flusher, ctx, SSEEventTypeHeartbeat, map[string]string{
				"status":        "alive",
				"connection_id": ctx.ConnectionID,
			}); err != nil {
				return
			}
		}
	}
}

func (r *SSERuntime) applyHeaders(w http.ResponseWriter) {
	headers := w.Header()
	headers.Set("Content-Type", "text/event-stream; charset=utf-8")
	headers.Set("Cache-Control", "no-cache, no-transform")
	headers.Set("Connection", "keep-alive")
	headers.Set("X-Accel-Buffering", "no")

	if r.config.AllowCORS {
		headers.Set("Access-Control-Allow-Origin", "*")
	}
}

func (r *SSERuntime) connectionContext(req *http.Request) (SSEConnectionContext, error) {
	tenantID := strings.TrimSpace(req.Header.Get(r.config.TenantHeader))
	if r.config.RequireTenant && tenantID == "" {
		return SSEConnectionContext{}, ErrSSEMissingTenant
	}

	channel := strings.TrimSpace(req.URL.Query().Get("channel"))
	if channel == "" {
		return SSEConnectionContext{}, ErrSSEMissingChannel
	}

	ctx := SSEConnectionContext{
		TenantID:      tenantID,
		Channel:       channel,
		UserID:        strings.TrimSpace(req.URL.Query().Get("user_id")),
		RemoteAddr:    req.RemoteAddr,
		ConnectedAt:   time.Now().UTC().Format(time.RFC3339Nano),
		CorrelationID: strings.TrimSpace(req.Header.Get("X-Correlation-ID")),
	}

	if r.channelAuthorizer != nil {
		decision := r.channelAuthorizer.AuthorizeChannel(ChannelAuthRequest{
			TenantID:      ctx.TenantID,
			Channel:       ctx.Channel,
			UserID:        ctx.UserID,
			Transport:     RealtimeTransportSSE,
			CorrelationID: ctx.CorrelationID,
			RemoteAddr:    ctx.RemoteAddr,
		})

		ctx.AuthDecision = decision.Decision
		ctx.AuthReason = decision.Reason

		if !decision.Allowed {
			return SSEConnectionContext{}, ErrChannelAuthDenied
		}
	}

	return ctx, nil
}

func (r *SSERuntime) writeEvent(w http.ResponseWriter, flusher http.Flusher, ctx SSEConnectionContext, eventType string, payload interface{}) error {
	body := SSEServerEvent{
		Type:      eventType,
		TenantID:  ctx.TenantID,
		Channel:   ctx.Channel,
		Payload:   payload,
		Timestamp: time.Now().UTC().Format(time.RFC3339Nano),
	}

	raw, err := json.Marshal(body)
	if err != nil {
		return err
	}

	if _, err := fmt.Fprintf(w, "event: %s\n", eventType); err != nil {
		return err
	}
	if _, err := fmt.Fprintf(w, "data: %s\n\n", raw); err != nil {
		return err
	}

	flusher.Flush()
	return nil
}
