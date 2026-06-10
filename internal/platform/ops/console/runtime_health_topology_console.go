package opsconsole

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	RuntimeTopologyNodeKindService  = "SERVICE"
	RuntimeTopologyNodeKindGateway  = "GATEWAY"
	RuntimeTopologyNodeKindDatabase = "DATABASE"
	RuntimeTopologyNodeKindQueue    = "QUEUE"
	RuntimeTopologyNodeKindCache    = "CACHE"
	RuntimeTopologyNodeKindWorker   = "WORKER"

	RuntimeTopologyNodeStatusHealthy  = "HEALTHY"
	RuntimeTopologyNodeStatusDegraded = "DEGRADED"
	RuntimeTopologyNodeStatusDown     = "DOWN"
	RuntimeTopologyNodeStatusUnknown  = "UNKNOWN"

	RuntimeTopologyEdgeStatusActive   = "ACTIVE"
	RuntimeTopologyEdgeStatusDegraded = "DEGRADED"
	RuntimeTopologyEdgeStatusBroken   = "BROKEN"

	RuntimeTopologyDecisionAllow = "ALLOW"
	RuntimeTopologyDecisionDeny  = "DENY"

	RuntimeTopologyReasonAllowed           = "RUNTIME_TOPOLOGY_ALLOWED"
	RuntimeTopologyReasonMissingTenant     = "RUNTIME_TOPOLOGY_MISSING_TENANT"
	RuntimeTopologyReasonCrossTenant       = "RUNTIME_TOPOLOGY_CROSS_TENANT_DENIED"
	RuntimeTopologyReasonMissingNodeID     = "RUNTIME_TOPOLOGY_MISSING_NODE_ID"
	RuntimeTopologyReasonMissingNodeName   = "RUNTIME_TOPOLOGY_MISSING_NODE_NAME"
	RuntimeTopologyReasonInvalidNodeKind   = "RUNTIME_TOPOLOGY_INVALID_NODE_KIND"
	RuntimeTopologyReasonInvalidNodeStatus = "RUNTIME_TOPOLOGY_INVALID_NODE_STATUS"
	RuntimeTopologyReasonMissingEdgeID     = "RUNTIME_TOPOLOGY_MISSING_EDGE_ID"
	RuntimeTopologyReasonMissingEdgeNode   = "RUNTIME_TOPOLOGY_MISSING_EDGE_NODE"
	RuntimeTopologyReasonMissingRelation   = "RUNTIME_TOPOLOGY_MISSING_RELATION"
	RuntimeTopologyReasonInvalidEdgeStatus = "RUNTIME_TOPOLOGY_INVALID_EDGE_STATUS"
)

var (
	ErrRuntimeTopologyMissingTenant     = errors.New("missing runtime topology tenant id")
	ErrRuntimeTopologyCrossTenant       = errors.New("cross-tenant runtime topology access denied")
	ErrRuntimeTopologyMissingNodeID     = errors.New("missing runtime topology node id")
	ErrRuntimeTopologyMissingNodeName   = errors.New("missing runtime topology node name")
	ErrRuntimeTopologyInvalidNodeKind   = errors.New("invalid runtime topology node kind")
	ErrRuntimeTopologyInvalidNodeStatus = errors.New("invalid runtime topology node status")
	ErrRuntimeTopologyMissingEdgeID     = errors.New("missing runtime topology edge id")
	ErrRuntimeTopologyMissingEdgeNode   = errors.New("missing runtime topology edge node")
	ErrRuntimeTopologyMissingRelation   = errors.New("missing runtime topology relation")
	ErrRuntimeTopologyInvalidEdgeStatus = errors.New("invalid runtime topology edge status")
)

type RuntimeHealthTopologyConsoleConfig struct {
	RequireTenant       bool     `json:"require_tenant"`
	AllowPlatformViewer bool     `json:"allow_platform_viewer"`
	MaxVisibleNodes     int      `json:"max_visible_nodes"`
	MaxVisibleEdges     int      `json:"max_visible_edges"`
	NodeStaleSeconds    int      `json:"node_stale_seconds"`
	AllowedNodeKinds    []string `json:"allowed_node_kinds"`
	AllowedNodeStatuses []string `json:"allowed_node_statuses"`
	AllowedEdgeStatuses []string `json:"allowed_edge_statuses"`
}

func DefaultRuntimeHealthTopologyConsoleConfig() RuntimeHealthTopologyConsoleConfig {
	return RuntimeHealthTopologyConsoleConfig{
		RequireTenant:       true,
		AllowPlatformViewer: true,
		MaxVisibleNodes:     100,
		MaxVisibleEdges:     200,
		NodeStaleSeconds:    120,
		AllowedNodeKinds: []string{
			RuntimeTopologyNodeKindService,
			RuntimeTopologyNodeKindGateway,
			RuntimeTopologyNodeKindDatabase,
			RuntimeTopologyNodeKindQueue,
			RuntimeTopologyNodeKindCache,
			RuntimeTopologyNodeKindWorker,
		},
		AllowedNodeStatuses: []string{
			RuntimeTopologyNodeStatusHealthy,
			RuntimeTopologyNodeStatusDegraded,
			RuntimeTopologyNodeStatusDown,
			RuntimeTopologyNodeStatusUnknown,
		},
		AllowedEdgeStatuses: []string{
			RuntimeTopologyEdgeStatusActive,
			RuntimeTopologyEdgeStatusDegraded,
			RuntimeTopologyEdgeStatusBroken,
		},
	}
}

type RuntimeTopologyNode struct {
	TenantID      string            `json:"tenant_id"`
	NodeID        string            `json:"node_id"`
	Name          string            `json:"name"`
	Kind          string            `json:"kind"`
	Status        string            `json:"status"`
	Address       string            `json:"address,omitempty"`
	Version       string            `json:"version,omitempty"`
	Region        string            `json:"region,omitempty"`
	LastSeenAt    string            `json:"last_seen_at"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	Metadata      map[string]string `json:"metadata,omitempty"`
	UpdatedAt     string            `json:"updated_at"`
}

type RuntimeTopologyEdge struct {
	TenantID      string            `json:"tenant_id"`
	EdgeID        string            `json:"edge_id"`
	FromNodeID    string            `json:"from_node_id"`
	ToNodeID      string            `json:"to_node_id"`
	Relation      string            `json:"relation"`
	Status        string            `json:"status"`
	LatencyMS     int               `json:"latency_ms"`
	ErrorRatePct  float64           `json:"error_rate_pct"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	Metadata      map[string]string `json:"metadata,omitempty"`
	UpdatedAt     string            `json:"updated_at"`
}

type RuntimeHealthTopologyRequest struct {
	TenantID       string `json:"tenant_id"`
	ViewerTenantID string `json:"viewer_tenant_id,omitempty"`
	KindFilter     string `json:"kind_filter,omitempty"`
	StatusFilter   string `json:"status_filter,omitempty"`
	IncludeEdges   bool   `json:"include_edges"`
	CorrelationID  string `json:"correlation_id,omitempty"`
}

type RuntimeHealthTopologyDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	ViewerTenantID string `json:"viewer_tenant_id,omitempty"`
	KindFilter     string `json:"kind_filter,omitempty"`
	StatusFilter   string `json:"status_filter,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type RuntimeHealthTopologySnapshot struct {
	OK                bool                  `json:"ok"`
	TenantID          string                `json:"tenant_id"`
	ViewerTenantID    string                `json:"viewer_tenant_id"`
	KindFilter        string                `json:"kind_filter,omitempty"`
	StatusFilter      string                `json:"status_filter,omitempty"`
	NodeCount         int                   `json:"node_count"`
	EdgeCount         int                   `json:"edge_count"`
	ServiceCount      int                   `json:"service_count"`
	GatewayCount      int                   `json:"gateway_count"`
	DatabaseCount     int                   `json:"database_count"`
	QueueCount        int                   `json:"queue_count"`
	CacheCount        int                   `json:"cache_count"`
	WorkerCount       int                   `json:"worker_count"`
	HealthyCount      int                   `json:"healthy_count"`
	DegradedCount     int                   `json:"degraded_count"`
	DownCount         int                   `json:"down_count"`
	UnknownCount      int                   `json:"unknown_count"`
	ActiveEdgeCount   int                   `json:"active_edge_count"`
	DegradedEdgeCount int                   `json:"degraded_edge_count"`
	BrokenEdgeCount   int                   `json:"broken_edge_count"`
	Nodes             []RuntimeTopologyNode `json:"nodes"`
	Edges             []RuntimeTopologyEdge `json:"edges"`
	CorrelationID     string                `json:"correlation_id,omitempty"`
	GeneratedAt       string                `json:"generated_at"`
}

type RuntimeHealthTopologyConsoleRuntime struct {
	config RuntimeHealthTopologyConsoleConfig
	mu     sync.RWMutex
	nodes  map[string]RuntimeTopologyNode
	edges  map[string]RuntimeTopologyEdge
}

func NewRuntimeHealthTopologyConsoleRuntime(config RuntimeHealthTopologyConsoleConfig) *RuntimeHealthTopologyConsoleRuntime {
	defaults := DefaultRuntimeHealthTopologyConsoleConfig()

	if config.MaxVisibleNodes <= 0 {
		config.MaxVisibleNodes = defaults.MaxVisibleNodes
	}
	if config.MaxVisibleEdges <= 0 {
		config.MaxVisibleEdges = defaults.MaxVisibleEdges
	}
	if config.NodeStaleSeconds <= 0 {
		config.NodeStaleSeconds = defaults.NodeStaleSeconds
	}
	if len(config.AllowedNodeKinds) == 0 {
		config.AllowedNodeKinds = defaults.AllowedNodeKinds
	}
	if len(config.AllowedNodeStatuses) == 0 {
		config.AllowedNodeStatuses = defaults.AllowedNodeStatuses
	}
	if len(config.AllowedEdgeStatuses) == 0 {
		config.AllowedEdgeStatuses = defaults.AllowedEdgeStatuses
	}

	return &RuntimeHealthTopologyConsoleRuntime{
		config: config,
		nodes:  make(map[string]RuntimeTopologyNode),
		edges:  make(map[string]RuntimeTopologyEdge),
	}
}

func (r *RuntimeHealthTopologyConsoleRuntime) UpsertNode(entry RuntimeTopologyNode) (RuntimeTopologyNode, RuntimeHealthTopologyDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	entry.TenantID = strings.TrimSpace(entry.TenantID)
	entry.NodeID = strings.TrimSpace(entry.NodeID)
	entry.Name = strings.TrimSpace(entry.Name)
	entry.Kind = normalizeOpsConsoleValue(entry.Kind)
	entry.Status = normalizeOpsConsoleValue(entry.Status)

	decision := RuntimeHealthTopologyDecision{
		Decision:  RuntimeTopologyDecisionDeny,
		Allowed:   false,
		TenantID:  entry.TenantID,
		Reason:    RuntimeTopologyReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && entry.TenantID == "" {
		decision.Reason = RuntimeTopologyReasonMissingTenant
		return RuntimeTopologyNode{}, decision, ErrRuntimeTopologyMissingTenant
	}
	if entry.NodeID == "" {
		decision.Reason = RuntimeTopologyReasonMissingNodeID
		return RuntimeTopologyNode{}, decision, ErrRuntimeTopologyMissingNodeID
	}
	if entry.Name == "" {
		decision.Reason = RuntimeTopologyReasonMissingNodeName
		return RuntimeTopologyNode{}, decision, ErrRuntimeTopologyMissingNodeName
	}
	if entry.Kind == "" || !r.nodeKindAllowed(entry.Kind) {
		decision.Reason = RuntimeTopologyReasonInvalidNodeKind
		return RuntimeTopologyNode{}, decision, ErrRuntimeTopologyInvalidNodeKind
	}
	if entry.Status == "" || !r.nodeStatusAllowed(entry.Status) {
		decision.Reason = RuntimeTopologyReasonInvalidNodeStatus
		return RuntimeTopologyNode{}, decision, ErrRuntimeTopologyInvalidNodeStatus
	}

	if entry.LastSeenAt == "" {
		entry.LastSeenAt = now
	}
	entry.UpdatedAt = now
	entry.Metadata = cloneOpsConsoleMap(entry.Metadata)

	r.mu.Lock()
	r.nodes[runtimeTopologyNodeKey(entry.TenantID, entry.NodeID)] = entry
	r.mu.Unlock()

	decision.Decision = RuntimeTopologyDecisionAllow
	decision.Allowed = true
	decision.Reason = RuntimeTopologyReasonAllowed

	return entry, decision, nil
}

func (r *RuntimeHealthTopologyConsoleRuntime) UpsertEdge(entry RuntimeTopologyEdge) (RuntimeTopologyEdge, RuntimeHealthTopologyDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	entry.TenantID = strings.TrimSpace(entry.TenantID)
	entry.EdgeID = strings.TrimSpace(entry.EdgeID)
	entry.FromNodeID = strings.TrimSpace(entry.FromNodeID)
	entry.ToNodeID = strings.TrimSpace(entry.ToNodeID)
	entry.Relation = strings.TrimSpace(entry.Relation)
	entry.Status = normalizeOpsConsoleValue(entry.Status)

	decision := RuntimeHealthTopologyDecision{
		Decision:  RuntimeTopologyDecisionDeny,
		Allowed:   false,
		TenantID:  entry.TenantID,
		Reason:    RuntimeTopologyReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && entry.TenantID == "" {
		decision.Reason = RuntimeTopologyReasonMissingTenant
		return RuntimeTopologyEdge{}, decision, ErrRuntimeTopologyMissingTenant
	}
	if entry.EdgeID == "" {
		decision.Reason = RuntimeTopologyReasonMissingEdgeID
		return RuntimeTopologyEdge{}, decision, ErrRuntimeTopologyMissingEdgeID
	}
	if entry.FromNodeID == "" || entry.ToNodeID == "" {
		decision.Reason = RuntimeTopologyReasonMissingEdgeNode
		return RuntimeTopologyEdge{}, decision, ErrRuntimeTopologyMissingEdgeNode
	}
	if entry.Relation == "" {
		decision.Reason = RuntimeTopologyReasonMissingRelation
		return RuntimeTopologyEdge{}, decision, ErrRuntimeTopologyMissingRelation
	}
	if entry.Status == "" || !r.edgeStatusAllowed(entry.Status) {
		decision.Reason = RuntimeTopologyReasonInvalidEdgeStatus
		return RuntimeTopologyEdge{}, decision, ErrRuntimeTopologyInvalidEdgeStatus
	}

	entry.UpdatedAt = now
	entry.Metadata = cloneOpsConsoleMap(entry.Metadata)

	r.mu.Lock()
	r.edges[runtimeTopologyEdgeKey(entry.TenantID, entry.EdgeID)] = entry
	r.mu.Unlock()

	decision.Decision = RuntimeTopologyDecisionAllow
	decision.Allowed = true
	decision.Reason = RuntimeTopologyReasonAllowed

	return entry, decision, nil
}

func (r *RuntimeHealthTopologyConsoleRuntime) BuildSnapshot(req RuntimeHealthTopologyRequest) (RuntimeHealthTopologySnapshot, RuntimeHealthTopologyDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	viewerTenantID := strings.TrimSpace(req.ViewerTenantID)
	kindFilter := normalizeOpsConsoleValue(req.KindFilter)
	statusFilter := normalizeOpsConsoleValue(req.StatusFilter)

	if viewerTenantID == "" {
		viewerTenantID = tenantID
	}

	decision := RuntimeHealthTopologyDecision{
		Decision:       RuntimeTopologyDecisionDeny,
		Allowed:        false,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		KindFilter:     kindFilter,
		StatusFilter:   statusFilter,
		Reason:         RuntimeTopologyReasonAllowed,
		CheckedAt:      now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = RuntimeTopologyReasonMissingTenant
		return RuntimeHealthTopologySnapshot{}, decision, ErrRuntimeTopologyMissingTenant
	}
	if viewerTenantID != tenantID && !(r.config.AllowPlatformViewer && viewerTenantID == "platform") {
		decision.Reason = RuntimeTopologyReasonCrossTenant
		return RuntimeHealthTopologySnapshot{}, decision, ErrRuntimeTopologyCrossTenant
	}
	if kindFilter != "" && !r.nodeKindAllowed(kindFilter) {
		decision.Reason = RuntimeTopologyReasonInvalidNodeKind
		return RuntimeHealthTopologySnapshot{}, decision, ErrRuntimeTopologyInvalidNodeKind
	}
	if statusFilter != "" && !r.nodeStatusAllowed(statusFilter) {
		decision.Reason = RuntimeTopologyReasonInvalidNodeStatus
		return RuntimeHealthTopologySnapshot{}, decision, ErrRuntimeTopologyInvalidNodeStatus
	}

	snapshot := RuntimeHealthTopologySnapshot{
		OK:             true,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		KindFilter:     kindFilter,
		StatusFilter:   statusFilter,
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		GeneratedAt:    now,
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	visibleNodeIDs := map[string]bool{}

	for _, node := range r.nodes {
		if node.TenantID != tenantID {
			continue
		}

		nodeForSnapshot := node
		nodeForSnapshot.Status = r.effectiveNodeStatus(node)

		if kindFilter != "" && nodeForSnapshot.Kind != kindFilter {
			continue
		}
		if statusFilter != "" && nodeForSnapshot.Status != statusFilter {
			continue
		}
		if snapshot.NodeCount >= r.config.MaxVisibleNodes {
			continue
		}

		snapshot.Nodes = append(snapshot.Nodes, nodeForSnapshot)
		snapshot.NodeCount++
		visibleNodeIDs[nodeForSnapshot.NodeID] = true

		switch nodeForSnapshot.Kind {
		case RuntimeTopologyNodeKindService:
			snapshot.ServiceCount++
		case RuntimeTopologyNodeKindGateway:
			snapshot.GatewayCount++
		case RuntimeTopologyNodeKindDatabase:
			snapshot.DatabaseCount++
		case RuntimeTopologyNodeKindQueue:
			snapshot.QueueCount++
		case RuntimeTopologyNodeKindCache:
			snapshot.CacheCount++
		case RuntimeTopologyNodeKindWorker:
			snapshot.WorkerCount++
		}

		switch nodeForSnapshot.Status {
		case RuntimeTopologyNodeStatusHealthy:
			snapshot.HealthyCount++
		case RuntimeTopologyNodeStatusDegraded:
			snapshot.DegradedCount++
		case RuntimeTopologyNodeStatusDown:
			snapshot.DownCount++
		case RuntimeTopologyNodeStatusUnknown:
			snapshot.UnknownCount++
		}
	}

	if req.IncludeEdges {
		for _, edge := range r.edges {
			if edge.TenantID != tenantID {
				continue
			}
			if !visibleNodeIDs[edge.FromNodeID] && !visibleNodeIDs[edge.ToNodeID] {
				continue
			}
			if snapshot.EdgeCount >= r.config.MaxVisibleEdges {
				continue
			}

			snapshot.Edges = append(snapshot.Edges, edge)
			snapshot.EdgeCount++

			switch edge.Status {
			case RuntimeTopologyEdgeStatusActive:
				snapshot.ActiveEdgeCount++
			case RuntimeTopologyEdgeStatusDegraded:
				snapshot.DegradedEdgeCount++
			case RuntimeTopologyEdgeStatusBroken:
				snapshot.BrokenEdgeCount++
			}
		}
	}

	decision.Decision = RuntimeTopologyDecisionAllow
	decision.Allowed = true
	decision.Reason = RuntimeTopologyReasonAllowed

	return snapshot, decision, nil
}

func (r *RuntimeHealthTopologyConsoleRuntime) effectiveNodeStatus(node RuntimeTopologyNode) string {
	if node.Status == RuntimeTopologyNodeStatusDown || node.Status == RuntimeTopologyNodeStatusUnknown {
		return node.Status
	}
	if isTopologyNodeStale(node.LastSeenAt, r.config.NodeStaleSeconds) {
		return RuntimeTopologyNodeStatusDegraded
	}
	return node.Status
}

func (r *RuntimeHealthTopologyConsoleRuntime) nodeKindAllowed(kind string) bool {
	kind = normalizeOpsConsoleValue(kind)
	for _, allowed := range r.config.AllowedNodeKinds {
		if normalizeOpsConsoleValue(allowed) == kind {
			return true
		}
	}
	return false
}

func (r *RuntimeHealthTopologyConsoleRuntime) nodeStatusAllowed(status string) bool {
	status = normalizeOpsConsoleValue(status)
	for _, allowed := range r.config.AllowedNodeStatuses {
		if normalizeOpsConsoleValue(allowed) == status {
			return true
		}
	}
	return false
}

func (r *RuntimeHealthTopologyConsoleRuntime) edgeStatusAllowed(status string) bool {
	status = normalizeOpsConsoleValue(status)
	for _, allowed := range r.config.AllowedEdgeStatuses {
		if normalizeOpsConsoleValue(allowed) == status {
			return true
		}
	}
	return false
}

func isTopologyNodeStale(lastSeenAt string, staleSeconds int) bool {
	if strings.TrimSpace(lastSeenAt) == "" {
		return true
	}
	parsed, err := time.Parse(time.RFC3339Nano, strings.TrimSpace(lastSeenAt))
	if err != nil {
		return true
	}
	if staleSeconds <= 0 {
		staleSeconds = 120
	}
	return time.Since(parsed.UTC()) > time.Duration(staleSeconds)*time.Second
}

func runtimeTopologyNodeKey(tenantID string, nodeID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(nodeID)
}

func runtimeTopologyEdgeKey(tenantID string, edgeID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(edgeID)
}
