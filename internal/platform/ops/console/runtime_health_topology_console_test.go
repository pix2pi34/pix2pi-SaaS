package opsconsole

import (
	"testing"
	"time"
)

func newRuntimeHealthTopologyRuntimeForTest(t *testing.T) *RuntimeHealthTopologyConsoleRuntime {
	t.Helper()

	runtime := NewRuntimeHealthTopologyConsoleRuntime(DefaultRuntimeHealthTopologyConsoleConfig())
	now := time.Now().UTC().Format(time.RFC3339Nano)

	_, _, err := runtime.UpsertNode(RuntimeTopologyNode{
		TenantID:      "tenant_7",
		NodeID:        "api_gateway",
		Name:          "API Gateway",
		Kind:          RuntimeTopologyNodeKindGateway,
		Status:        RuntimeTopologyNodeStatusHealthy,
		Address:       "https://api.pix2pi.com.tr",
		Version:       "v1",
		Region:        "tr-istanbul",
		LastSeenAt:    now,
		CorrelationID: "corr-node-1",
		Metadata:      map[string]string{"port": "9010"},
	})
	if err != nil {
		t.Fatalf("upsert gateway node failed: %v", err)
	}

	_, _, err = runtime.UpsertNode(RuntimeTopologyNode{
		TenantID:   "tenant_7",
		NodeID:     "postgres_primary",
		Name:       "PostgreSQL Primary",
		Kind:       RuntimeTopologyNodeKindDatabase,
		Status:     RuntimeTopologyNodeStatusDegraded,
		Address:    "localhost:5433",
		Version:    "16",
		Region:     "tr-istanbul",
		LastSeenAt: now,
	})
	if err != nil {
		t.Fatalf("upsert database node failed: %v", err)
	}

	_, _, err = runtime.UpsertNode(RuntimeTopologyNode{
		TenantID:   "tenant_7",
		NodeID:     "worker_1",
		Name:       "Worker 1",
		Kind:       RuntimeTopologyNodeKindWorker,
		Status:     RuntimeTopologyNodeStatusDown,
		Address:    "worker-1",
		Region:     "tr-istanbul",
		LastSeenAt: now,
	})
	if err != nil {
		t.Fatalf("upsert worker node failed: %v", err)
	}

	_, _, err = runtime.UpsertEdge(RuntimeTopologyEdge{
		TenantID:     "tenant_7",
		EdgeID:       "edge_gateway_db",
		FromNodeID:   "api_gateway",
		ToNodeID:     "postgres_primary",
		Relation:     "SQL_READ_WRITE",
		Status:       RuntimeTopologyEdgeStatusDegraded,
		LatencyMS:    28,
		ErrorRatePct: 0.3,
	})
	if err != nil {
		t.Fatalf("upsert gateway-db edge failed: %v", err)
	}

	_, _, err = runtime.UpsertEdge(RuntimeTopologyEdge{
		TenantID:     "tenant_7",
		EdgeID:       "edge_gateway_worker",
		FromNodeID:   "api_gateway",
		ToNodeID:     "worker_1",
		Relation:     "JOB_DISPATCH",
		Status:       RuntimeTopologyEdgeStatusBroken,
		LatencyMS:    0,
		ErrorRatePct: 100,
	})
	if err != nil {
		t.Fatalf("upsert gateway-worker edge failed: %v", err)
	}

	return runtime
}

func TestRuntimeHealthTopologyConsoleRuntimeBuildsSnapshot(t *testing.T) {
	runtime := newRuntimeHealthTopologyRuntimeForTest(t)

	snapshot, decision, err := runtime.BuildSnapshot(RuntimeHealthTopologyRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "platform",
		IncludeEdges:   true,
		CorrelationID:  "corr-topology-1",
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected snapshot allowed, got reason=%s", decision.Reason)
	}
	if !snapshot.OK {
		t.Fatal("expected snapshot OK")
	}
	if snapshot.NodeCount != 3 {
		t.Fatalf("expected node count 3, got %d", snapshot.NodeCount)
	}
	if snapshot.EdgeCount != 2 {
		t.Fatalf("expected edge count 2, got %d", snapshot.EdgeCount)
	}
	if snapshot.GatewayCount != 1 {
		t.Fatalf("expected gateway count 1, got %d", snapshot.GatewayCount)
	}
	if snapshot.DatabaseCount != 1 {
		t.Fatalf("expected database count 1, got %d", snapshot.DatabaseCount)
	}
	if snapshot.WorkerCount != 1 {
		t.Fatalf("expected worker count 1, got %d", snapshot.WorkerCount)
	}
	if snapshot.HealthyCount != 1 {
		t.Fatalf("expected healthy count 1, got %d", snapshot.HealthyCount)
	}
	if snapshot.DegradedCount != 1 {
		t.Fatalf("expected degraded count 1, got %d", snapshot.DegradedCount)
	}
	if snapshot.DownCount != 1 {
		t.Fatalf("expected down count 1, got %d", snapshot.DownCount)
	}
	if snapshot.DegradedEdgeCount != 1 {
		t.Fatalf("expected degraded edge count 1, got %d", snapshot.DegradedEdgeCount)
	}
	if snapshot.BrokenEdgeCount != 1 {
		t.Fatalf("expected broken edge count 1, got %d", snapshot.BrokenEdgeCount)
	}
}

func TestRuntimeHealthTopologyConsoleRuntimeKindFilter(t *testing.T) {
	runtime := newRuntimeHealthTopologyRuntimeForTest(t)

	snapshot, decision, err := runtime.BuildSnapshot(RuntimeHealthTopologyRequest{
		TenantID:     "tenant_7",
		KindFilter:   RuntimeTopologyNodeKindDatabase,
		IncludeEdges: true,
	})
	if err != nil {
		t.Fatalf("build kind filtered snapshot failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected snapshot allowed, got reason=%s", decision.Reason)
	}
	if snapshot.NodeCount != 1 {
		t.Fatalf("expected one database node, got %d", snapshot.NodeCount)
	}
	if snapshot.Nodes[0].Kind != RuntimeTopologyNodeKindDatabase {
		t.Fatalf("expected DATABASE, got %s", snapshot.Nodes[0].Kind)
	}
}

func TestRuntimeHealthTopologyConsoleRuntimeStatusFilter(t *testing.T) {
	runtime := newRuntimeHealthTopologyRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(RuntimeHealthTopologyRequest{
		TenantID:     "tenant_7",
		StatusFilter: RuntimeTopologyNodeStatusDown,
	})
	if err != nil {
		t.Fatalf("build status filtered snapshot failed: %v", err)
	}
	if snapshot.NodeCount != 1 {
		t.Fatalf("expected one down node, got %d", snapshot.NodeCount)
	}
	if snapshot.Nodes[0].Status != RuntimeTopologyNodeStatusDown {
		t.Fatalf("expected DOWN, got %s", snapshot.Nodes[0].Status)
	}
}

func TestRuntimeHealthTopologyConsoleRuntimeDetectsStaleNode(t *testing.T) {
	config := DefaultRuntimeHealthTopologyConsoleConfig()
	config.NodeStaleSeconds = 1
	runtime := NewRuntimeHealthTopologyConsoleRuntime(config)

	_, _, err := runtime.UpsertNode(RuntimeTopologyNode{
		TenantID:   "tenant_7",
		NodeID:     "service_stale",
		Name:       "Stale Service",
		Kind:       RuntimeTopologyNodeKindService,
		Status:     RuntimeTopologyNodeStatusHealthy,
		LastSeenAt: time.Now().UTC().Add(-5 * time.Minute).Format(time.RFC3339Nano),
	})
	if err != nil {
		t.Fatalf("upsert stale node failed: %v", err)
	}

	snapshot, _, err := runtime.BuildSnapshot(RuntimeHealthTopologyRequest{
		TenantID: "tenant_7",
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if snapshot.DegradedCount != 1 {
		t.Fatalf("expected stale node to count degraded, got %d", snapshot.DegradedCount)
	}
	if snapshot.Nodes[0].Status != RuntimeTopologyNodeStatusDegraded {
		t.Fatalf("expected stale node status DEGRADED, got %s", snapshot.Nodes[0].Status)
	}
}

func TestRuntimeHealthTopologyConsoleRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewRuntimeHealthTopologyConsoleRuntime(DefaultRuntimeHealthTopologyConsoleConfig())

	_, decision, err := runtime.BuildSnapshot(RuntimeHealthTopologyRequest{})
	if err != ErrRuntimeTopologyMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != RuntimeTopologyReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestRuntimeHealthTopologyConsoleRuntimeRejectsCrossTenantViewer(t *testing.T) {
	runtime := newRuntimeHealthTopologyRuntimeForTest(t)

	_, decision, err := runtime.BuildSnapshot(RuntimeHealthTopologyRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
	})
	if err != ErrRuntimeTopologyCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != RuntimeTopologyReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestRuntimeHealthTopologyConsoleRuntimeRejectsInvalidNodeKind(t *testing.T) {
	runtime := NewRuntimeHealthTopologyConsoleRuntime(DefaultRuntimeHealthTopologyConsoleConfig())

	_, decision, err := runtime.UpsertNode(RuntimeTopologyNode{
		TenantID:   "tenant_7",
		NodeID:     "node_1",
		Name:       "Bad Node",
		Kind:       "SATELLITE",
		Status:     RuntimeTopologyNodeStatusHealthy,
		LastSeenAt: time.Now().UTC().Format(time.RFC3339Nano),
	})
	if err != ErrRuntimeTopologyInvalidNodeKind {
		t.Fatalf("expected invalid node kind error, got %v", err)
	}
	if decision.Reason != RuntimeTopologyReasonInvalidNodeKind {
		t.Fatalf("expected invalid node kind reason, got %s", decision.Reason)
	}
}

func TestRuntimeHealthTopologyConsoleRuntimeRejectsInvalidNodeStatus(t *testing.T) {
	runtime := NewRuntimeHealthTopologyConsoleRuntime(DefaultRuntimeHealthTopologyConsoleConfig())

	_, decision, err := runtime.UpsertNode(RuntimeTopologyNode{
		TenantID:   "tenant_7",
		NodeID:     "node_1",
		Name:       "Bad Node",
		Kind:       RuntimeTopologyNodeKindService,
		Status:     "BROKEN",
		LastSeenAt: time.Now().UTC().Format(time.RFC3339Nano),
	})
	if err != ErrRuntimeTopologyInvalidNodeStatus {
		t.Fatalf("expected invalid node status error, got %v", err)
	}
	if decision.Reason != RuntimeTopologyReasonInvalidNodeStatus {
		t.Fatalf("expected invalid node status reason, got %s", decision.Reason)
	}
}

func TestRuntimeHealthTopologyConsoleRuntimeRejectsInvalidEdgeStatus(t *testing.T) {
	runtime := NewRuntimeHealthTopologyConsoleRuntime(DefaultRuntimeHealthTopologyConsoleConfig())

	_, decision, err := runtime.UpsertEdge(RuntimeTopologyEdge{
		TenantID:   "tenant_7",
		EdgeID:     "edge_1",
		FromNodeID: "a",
		ToNodeID:   "b",
		Relation:   "HTTP",
		Status:     "UNKNOWN_BAD",
	})
	if err != ErrRuntimeTopologyInvalidEdgeStatus {
		t.Fatalf("expected invalid edge status error, got %v", err)
	}
	if decision.Reason != RuntimeTopologyReasonInvalidEdgeStatus {
		t.Fatalf("expected invalid edge status reason, got %s", decision.Reason)
	}
}

func TestRuntimeHealthTopologyConsoleRuntimeRejectsMissingEdgeNode(t *testing.T) {
	runtime := NewRuntimeHealthTopologyConsoleRuntime(DefaultRuntimeHealthTopologyConsoleConfig())

	_, decision, err := runtime.UpsertEdge(RuntimeTopologyEdge{
		TenantID: "tenant_7",
		EdgeID:   "edge_1",
		Relation: "HTTP",
		Status:   RuntimeTopologyEdgeStatusActive,
	})
	if err != ErrRuntimeTopologyMissingEdgeNode {
		t.Fatalf("expected missing edge node error, got %v", err)
	}
	if decision.Reason != RuntimeTopologyReasonMissingEdgeNode {
		t.Fatalf("expected missing edge node reason, got %s", decision.Reason)
	}
}
