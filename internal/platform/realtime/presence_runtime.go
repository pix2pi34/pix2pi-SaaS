package realtime

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"strings"
	"sync"
	"time"
)

var (
	ErrPresenceMissingTenant     = errors.New("missing tenant id for presence")
	ErrPresenceMissingChannel    = errors.New("missing channel for presence")
	ErrPresenceMissingConnection = errors.New("missing connection id")
	ErrPresenceCrossTenant       = errors.New("cross-tenant presence access denied")
	ErrPresenceNotFound          = errors.New("presence connection not found")
)

const (
	PresenceStatusConnected    = "CONNECTED"
	PresenceStatusDisconnected = "DISCONNECTED"

	RealtimeTransportWebSocket = "websocket"
	RealtimeTransportSSE       = "sse"
)

type PresenceConnection struct {
	ConnectionID     string `json:"connection_id"`
	TenantID         string `json:"tenant_id"`
	Channel          string `json:"channel"`
	UserID           string `json:"user_id,omitempty"`
	Transport        string `json:"transport"`
	RemoteAddr       string `json:"remote_addr,omitempty"`
	Status           string `json:"status"`
	ConnectedAt      string `json:"connected_at"`
	LastSeenAt       string `json:"last_seen_at"`
	DisconnectedAt   string `json:"disconnected_at,omitempty"`
	DisconnectReason string `json:"disconnect_reason,omitempty"`
}

type PresenceConnectRequest struct {
	TenantID      string
	Channel       string
	UserID        string
	Transport     string
	RemoteAddr    string
	CorrelationID string
}

type PresenceRuntime struct {
	mu          sync.RWMutex
	connections map[string]PresenceConnection
}

func NewPresenceRuntime() *PresenceRuntime {
	return &PresenceRuntime{
		connections: make(map[string]PresenceConnection),
	}
}

func (r *PresenceRuntime) Connect(req PresenceConnectRequest) (PresenceConnection, error) {
	tenantID := strings.TrimSpace(req.TenantID)
	if tenantID == "" {
		return PresenceConnection{}, ErrPresenceMissingTenant
	}

	channel := strings.TrimSpace(req.Channel)
	if channel == "" {
		return PresenceConnection{}, ErrPresenceMissingChannel
	}

	connectionID := NewConnectionID()
	now := time.Now().UTC().Format(time.RFC3339Nano)

	conn := PresenceConnection{
		ConnectionID: connectionID,
		TenantID:     tenantID,
		Channel:      channel,
		UserID:       strings.TrimSpace(req.UserID),
		Transport:    strings.TrimSpace(req.Transport),
		RemoteAddr:   strings.TrimSpace(req.RemoteAddr),
		Status:       PresenceStatusConnected,
		ConnectedAt:  now,
		LastSeenAt:   now,
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	r.connections[connectionID] = conn
	return conn, nil
}

func (r *PresenceRuntime) Heartbeat(tenantID string, connectionID string) (PresenceConnection, error) {
	tenantID = strings.TrimSpace(tenantID)
	connectionID = strings.TrimSpace(connectionID)

	if tenantID == "" {
		return PresenceConnection{}, ErrPresenceMissingTenant
	}
	if connectionID == "" {
		return PresenceConnection{}, ErrPresenceMissingConnection
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	conn, ok := r.connections[connectionID]
	if !ok {
		return PresenceConnection{}, ErrPresenceNotFound
	}
	if conn.TenantID != tenantID {
		return PresenceConnection{}, ErrPresenceCrossTenant
	}

	conn.LastSeenAt = time.Now().UTC().Format(time.RFC3339Nano)
	conn.Status = PresenceStatusConnected
	r.connections[connectionID] = conn

	return conn, nil
}

func (r *PresenceRuntime) Disconnect(tenantID string, connectionID string, reason string) (PresenceConnection, error) {
	tenantID = strings.TrimSpace(tenantID)
	connectionID = strings.TrimSpace(connectionID)

	if tenantID == "" {
		return PresenceConnection{}, ErrPresenceMissingTenant
	}
	if connectionID == "" {
		return PresenceConnection{}, ErrPresenceMissingConnection
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	conn, ok := r.connections[connectionID]
	if !ok {
		return PresenceConnection{}, ErrPresenceNotFound
	}
	if conn.TenantID != tenantID {
		return PresenceConnection{}, ErrPresenceCrossTenant
	}

	now := time.Now().UTC().Format(time.RFC3339Nano)
	conn.Status = PresenceStatusDisconnected
	conn.LastSeenAt = now
	conn.DisconnectedAt = now
	conn.DisconnectReason = strings.TrimSpace(reason)

	delete(r.connections, connectionID)
	return conn, nil
}

func (r *PresenceRuntime) Get(tenantID string, connectionID string) (PresenceConnection, error) {
	tenantID = strings.TrimSpace(tenantID)
	connectionID = strings.TrimSpace(connectionID)

	if tenantID == "" {
		return PresenceConnection{}, ErrPresenceMissingTenant
	}
	if connectionID == "" {
		return PresenceConnection{}, ErrPresenceMissingConnection
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	conn, ok := r.connections[connectionID]
	if !ok {
		return PresenceConnection{}, ErrPresenceNotFound
	}
	if conn.TenantID != tenantID {
		return PresenceConnection{}, ErrPresenceCrossTenant
	}

	return conn, nil
}

func (r *PresenceRuntime) ListTenantConnections(tenantID string) []PresenceConnection {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return []PresenceConnection{}
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	result := make([]PresenceConnection, 0)
	for _, conn := range r.connections {
		if conn.TenantID == tenantID {
			result = append(result, conn)
		}
	}
	return result
}

func (r *PresenceRuntime) CountTenantConnections(tenantID string) int {
	return len(r.ListTenantConnections(tenantID))
}

func (r *PresenceRuntime) CountAllConnections() int {
	r.mu.RLock()
	defer r.mu.RUnlock()

	return len(r.connections)
}

func NewConnectionID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "conn_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return "conn_" + hex.EncodeToString(raw[:])
}
