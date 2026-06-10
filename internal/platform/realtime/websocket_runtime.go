package realtime

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"strings"
	"sync/atomic"
	"time"

	"github.com/gorilla/websocket"
)

const (
	DefaultTenantHeader = "X-Tenant-ID"

	MessageTypeWelcome = "welcome"
	MessageTypePing    = "ping"
	MessageTypePong    = "pong"
	MessageTypeError   = "error"
	MessageTypeEcho    = "echo"
)

var (
	ErrMissingTenant  = errors.New("missing tenant id")
	ErrMissingChannel = errors.New("missing websocket channel")
)

type WebSocketRuntimeConfig struct {
	TenantHeader        string
	RequireTenant       bool
	AllowAllOrigins     bool
	ReadLimitBytes      int64
	PongWaitSeconds     int
	WriteWaitSeconds    int
	PingIntervalSeconds int
}

func DefaultWebSocketRuntimeConfig() WebSocketRuntimeConfig {
	return WebSocketRuntimeConfig{
		TenantHeader:        DefaultTenantHeader,
		RequireTenant:       true,
		AllowAllOrigins:     false,
		ReadLimitBytes:      1024 * 1024,
		PongWaitSeconds:     60,
		WriteWaitSeconds:    10,
		PingIntervalSeconds: 30,
	}
}

type ConnectionContext struct {
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

type ClientMessage struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload,omitempty"`
}

type ServerMessage struct {
	Type      string      `json:"type"`
	TenantID  string      `json:"tenant_id"`
	Channel   string      `json:"channel"`
	Payload   interface{} `json:"payload,omitempty"`
	Timestamp string      `json:"timestamp"`
}

type WebSocketRuntime struct {
	config            WebSocketRuntimeConfig
	upgrader          websocket.Upgrader
	activeCount       atomic.Int64
	channelAuthorizer ChannelAuthorizer
	presenceRuntime   *PresenceRuntime
}

func NewWebSocketRuntime(config WebSocketRuntimeConfig) *WebSocketRuntime {
	if strings.TrimSpace(config.TenantHeader) == "" {
		config.TenantHeader = DefaultTenantHeader
	}
	if config.ReadLimitBytes <= 0 {
		config.ReadLimitBytes = 1024 * 1024
	}
	if config.PongWaitSeconds <= 0 {
		config.PongWaitSeconds = 60
	}
	if config.WriteWaitSeconds <= 0 {
		config.WriteWaitSeconds = 10
	}
	if config.PingIntervalSeconds <= 0 {
		config.PingIntervalSeconds = 30
	}

	runtime := &WebSocketRuntime{
		config:            config,
		channelAuthorizer: NewChannelAuthRuntime(DefaultChannelAuthRuntimeConfig()),
		presenceRuntime:   NewPresenceRuntime(),
	}
	runtime.upgrader = websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			if config.AllowAllOrigins {
				return true
			}
			origin := r.Header.Get("Origin")
			return origin == "" || strings.Contains(origin, r.Host)
		},
	}

	return runtime
}

func (r *WebSocketRuntime) ActiveConnectionCount() int64 {
	return r.activeCount.Load()
}

func (r *WebSocketRuntime) PresenceConnectionCount(tenantID string) int {
	if r.presenceRuntime == nil {
		return 0
	}
	return r.presenceRuntime.CountTenantConnections(tenantID)
}

func (r *WebSocketRuntime) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	ctx, err := r.connectionContext(req)
	if err != nil {
		switch {
		case errors.Is(err, ErrMissingTenant):
			http.Error(w, err.Error(), http.StatusUnauthorized)
		case errors.Is(err, ErrMissingChannel):
			http.Error(w, err.Error(), http.StatusBadRequest)
		case errors.Is(err, ErrChannelAuthDenied):
			http.Error(w, err.Error(), http.StatusForbidden)
		default:
			http.Error(w, err.Error(), http.StatusBadRequest)
		}
		return
	}

	conn, err := r.upgrader.Upgrade(w, req, nil)
	if err != nil {
		log.Printf("websocket upgrade failed: %v", err)
		return
	}
	defer conn.Close()

	if r.presenceRuntime != nil {
		presence, err := r.presenceRuntime.Connect(PresenceConnectRequest{
			TenantID:      ctx.TenantID,
			Channel:       ctx.Channel,
			UserID:        ctx.UserID,
			Transport:     RealtimeTransportWebSocket,
			RemoteAddr:    ctx.RemoteAddr,
			CorrelationID: ctx.CorrelationID,
		})
		if err != nil {
			_ = r.writeMessage(conn, ctx, MessageTypeError, map[string]string{"error": err.Error()})
			return
		}
		ctx.ConnectionID = presence.ConnectionID
		ctx.PresenceStatus = presence.Status
		defer func() {
			_, _ = r.presenceRuntime.Disconnect(ctx.TenantID, ctx.ConnectionID, "websocket_closed")
		}()
	}

	r.activeCount.Add(1)
	defer r.activeCount.Add(-1)

	conn.SetReadLimit(r.config.ReadLimitBytes)

	if err := r.writeMessage(conn, ctx, MessageTypeWelcome, map[string]string{
		"status":          "connected",
		"auth_decision":   ctx.AuthDecision,
		"auth_reason":     ctx.AuthReason,
		"connection_id":   ctx.ConnectionID,
		"presence_status": ctx.PresenceStatus,
	}); err != nil {
		return
	}

	r.readLoop(req.Context(), conn, ctx)
}

func (r *WebSocketRuntime) connectionContext(req *http.Request) (ConnectionContext, error) {
	tenantID := strings.TrimSpace(req.Header.Get(r.config.TenantHeader))
	if r.config.RequireTenant && tenantID == "" {
		return ConnectionContext{}, ErrMissingTenant
	}

	channel := strings.TrimSpace(req.URL.Query().Get("channel"))
	if channel == "" {
		return ConnectionContext{}, ErrMissingChannel
	}

	ctx := ConnectionContext{
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
			Transport:     RealtimeTransportWebSocket,
			CorrelationID: ctx.CorrelationID,
			RemoteAddr:    ctx.RemoteAddr,
		})

		ctx.AuthDecision = decision.Decision
		ctx.AuthReason = decision.Reason

		if !decision.Allowed {
			return ConnectionContext{}, ErrChannelAuthDenied
		}
	}

	return ctx, nil
}

func (r *WebSocketRuntime) readLoop(ctx context.Context, conn *websocket.Conn, cctx ConnectionContext) {
	for {
		select {
		case <-ctx.Done():
			return
		default:
		}

		var msg ClientMessage
		if err := conn.ReadJSON(&msg); err != nil {
			return
		}

		if r.presenceRuntime != nil && cctx.ConnectionID != "" {
			_, _ = r.presenceRuntime.Heartbeat(cctx.TenantID, cctx.ConnectionID)
		}

		switch msg.Type {
		case MessageTypePing:
			_ = r.writeMessage(conn, cctx, MessageTypePong, map[string]string{"status": "ok", "connection_id": cctx.ConnectionID})
		default:
			_ = r.writeMessage(conn, cctx, MessageTypeEcho, map[string]interface{}{
				"type":          msg.Type,
				"payload":       msg.Payload,
				"connection_id": cctx.ConnectionID,
			})
		}
	}
}

func (r *WebSocketRuntime) writeMessage(conn *websocket.Conn, ctx ConnectionContext, msgType string, payload interface{}) error {
	deadline := time.Now().Add(time.Duration(r.config.WriteWaitSeconds) * time.Second)
	_ = conn.SetWriteDeadline(deadline)

	return conn.WriteJSON(ServerMessage{
		Type:      msgType,
		TenantID:  ctx.TenantID,
		Channel:   ctx.Channel,
		Payload:   payload,
		Timestamp: time.Now().UTC().Format(time.RFC3339Nano),
	})
}
