package opsconsole

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func readRepoCheckpointFile(t *testing.T, relativePath string) string {
	t.Helper()

	wd, err := os.Getwd()
	if err != nil {
		t.Fatalf("get working directory failed: %v", err)
	}

	dir := wd
	for {
		goMod := filepath.Join(dir, "go.mod")
		if _, err := os.Stat(goMod); err == nil {
			data, readErr := os.ReadFile(filepath.Join(dir, relativePath))
			if readErr != nil {
				t.Fatalf("expected checkpoint %s readable from repo root %s: %v", relativePath, dir, readErr)
			}
			return string(data)
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}

	t.Fatalf("repo root with go.mod not found from %s", wd)
	return ""
}

func TestOpsConsoleFinalJobNotificationIncidentTopologyE2E(t *testing.T) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	jobRuntime := NewJobQueueWorkerMonitorConsoleRuntime(DefaultJobQueueWorkerMonitorConsoleConfig())
	notificationRuntime := NewNotificationWebhookMonitorConsoleRuntime(DefaultNotificationWebhookMonitorConsoleConfig())
	incidentRuntime := NewIncidentAuditCenterConsoleRuntime(DefaultIncidentAuditCenterConsoleConfig())
	topologyRuntime := NewRuntimeHealthTopologyConsoleRuntime(DefaultRuntimeHealthTopologyConsoleConfig())

	_, jobDecision, err := jobRuntime.UpsertJob(JobMonitorEntry{
		TenantID:      "tenant_7",
		JobID:         "job_webhook_delivery_1",
		JobType:       "WEBHOOK_DELIVERY",
		Queue:         "webhooks",
		Priority:      "HIGH",
		State:         JobMonitorStateQueued,
		Attempt:       1,
		CorrelationID: "corr-final-job",
		Metadata:      map[string]string{"delivery_id": "webhook_delivery_1"},
	})
	if err != nil {
		t.Fatalf("upsert job failed: %v", err)
	}
	if !jobDecision.Allowed {
		t.Fatalf("expected job upsert allowed, got reason=%s", jobDecision.Reason)
	}

	_, workerDecision, err := jobRuntime.UpsertWorker(WorkerMonitorEntry{
		TenantID:       "tenant_7",
		WorkerID:       "worker_webhook_1",
		Queue:          "webhooks",
		Status:         WorkerMonitorStatusActive,
		Concurrency:    4,
		ProcessedCount: 100,
		FailedCount:    2,
		HeartbeatAt:    now,
	})
	if err != nil {
		t.Fatalf("upsert worker failed: %v", err)
	}
	if !workerDecision.Allowed {
		t.Fatalf("expected worker upsert allowed, got reason=%s", workerDecision.Reason)
	}

	_, notificationDecision, err := notificationRuntime.UpsertDelivery(NotificationWebhookMonitorEntry{
		TenantID:       "tenant_7",
		DeliveryID:     "webhook_delivery_1",
		NotificationID: "notification_1",
		Channel:        NotificationMonitorChannelWebhook,
		Provider:       "HTTP",
		Destination:    "https://example.com/webhook",
		EventType:      "order.created",
		State:          NotificationMonitorStateRetryScheduled,
		Attempt:        2,
		RetryAt:        now,
		LastError:      "timeout",
		SignatureTrace: "sha256=trace",
		CorrelationID:  "corr-final-notification",
	})
	if err != nil {
		t.Fatalf("upsert notification failed: %v", err)
	}
	if !notificationDecision.Allowed {
		t.Fatalf("expected notification upsert allowed, got reason=%s", notificationDecision.Reason)
	}

	_, incidentDecision, err := incidentRuntime.UpsertIncident(IncidentCenterRecord{
		TenantID:      "tenant_7",
		IncidentID:    "incident_webhook_retry_1",
		Source:        "notification_webhook_monitor",
		Severity:      IncidentAuditSeverityWarning,
		Status:        IncidentStatusOpen,
		Title:         "Webhook retry scheduled",
		Message:       "Webhook delivery entered retry schedule",
		Owner:         "ops",
		CorrelationID: "corr-final-incident",
	})
	if err != nil {
		t.Fatalf("upsert incident failed: %v", err)
	}
	if !incidentDecision.Allowed {
		t.Fatalf("expected incident upsert allowed, got reason=%s", incidentDecision.Reason)
	}

	_, auditDecision, err := incidentRuntime.RecordAuditEvent(AuditCenterRecord{
		TenantID:      "tenant_7",
		AuditID:       "audit_final_1",
		ActorID:       "system",
		ActionType:    AuditActionSystemEvent,
		TargetType:    "WEBHOOK_DELIVERY",
		TargetID:      "webhook_delivery_1",
		Severity:      IncidentAuditSeverityInfo,
		Message:       "Webhook retry was observed by ops console final test",
		CorrelationID: "corr-final-audit",
	})
	if err != nil {
		t.Fatalf("record audit event failed: %v", err)
	}
	if !auditDecision.Allowed {
		t.Fatalf("expected audit event allowed, got reason=%s", auditDecision.Reason)
	}

	_, nodeDecision, err := topologyRuntime.UpsertNode(RuntimeTopologyNode{
		TenantID:   "tenant_7",
		NodeID:     "api_gateway",
		Name:       "API Gateway",
		Kind:       RuntimeTopologyNodeKindGateway,
		Status:     RuntimeTopologyNodeStatusHealthy,
		Address:    "https://api.pix2pi.com.tr",
		Version:    "v1",
		Region:     "tr-istanbul",
		LastSeenAt: now,
	})
	if err != nil {
		t.Fatalf("upsert gateway node failed: %v", err)
	}
	if !nodeDecision.Allowed {
		t.Fatalf("expected node upsert allowed, got reason=%s", nodeDecision.Reason)
	}

	_, nodeDecision, err = topologyRuntime.UpsertNode(RuntimeTopologyNode{
		TenantID:   "tenant_7",
		NodeID:     "worker_webhook_1",
		Name:       "Webhook Worker",
		Kind:       RuntimeTopologyNodeKindWorker,
		Status:     RuntimeTopologyNodeStatusHealthy,
		Address:    "worker-webhook-1",
		LastSeenAt: now,
	})
	if err != nil {
		t.Fatalf("upsert worker node failed: %v", err)
	}
	if !nodeDecision.Allowed {
		t.Fatalf("expected worker node upsert allowed, got reason=%s", nodeDecision.Reason)
	}

	_, edgeDecision, err := topologyRuntime.UpsertEdge(RuntimeTopologyEdge{
		TenantID:     "tenant_7",
		EdgeID:       "edge_gateway_worker",
		FromNodeID:   "api_gateway",
		ToNodeID:     "worker_webhook_1",
		Relation:     "JOB_DISPATCH",
		Status:       RuntimeTopologyEdgeStatusActive,
		LatencyMS:    12,
		ErrorRatePct: 0,
	})
	if err != nil {
		t.Fatalf("upsert edge failed: %v", err)
	}
	if !edgeDecision.Allowed {
		t.Fatalf("expected edge upsert allowed, got reason=%s", edgeDecision.Reason)
	}

	jobSnapshot, decision, err := jobRuntime.BuildSnapshot(JobQueueWorkerMonitorRequest{
		TenantID:          "tenant_7",
		ViewerTenantID:    "platform",
		QueueFilter:       "webhooks",
		IncludeWorkers:    true,
		IncludeFailedJobs: true,
	})
	if err != nil {
		t.Fatalf("build job snapshot failed: %v", err)
	}
	if !decision.Allowed || jobSnapshot.JobCount != 1 || jobSnapshot.WorkerCount != 1 {
		t.Fatalf("unexpected job snapshot allowed=%v job_count=%d worker_count=%d", decision.Allowed, jobSnapshot.JobCount, jobSnapshot.WorkerCount)
	}

	notificationSnapshot, notificationSnapshotDecision, err := notificationRuntime.BuildSnapshot(NotificationWebhookMonitorRequest{
		TenantID:           "tenant_7",
		ViewerTenantID:     "platform",
		ChannelFilter:      NotificationMonitorChannelWebhook,
		IncludeWebhookOnly: true,
		IncludeFailed:      true,
	})
	if err != nil {
		t.Fatalf("build notification snapshot failed: %v", err)
	}
	if !notificationSnapshotDecision.Allowed || notificationSnapshot.WebhookCount != 1 || notificationSnapshot.RetryScheduledCount != 1 {
		t.Fatalf("unexpected notification snapshot allowed=%v webhook_count=%d retry_count=%d", notificationSnapshotDecision.Allowed, notificationSnapshot.WebhookCount, notificationSnapshot.RetryScheduledCount)
	}

	incidentSnapshot, incidentSnapshotDecision, err := incidentRuntime.BuildSnapshot(IncidentAuditCenterRequest{
		TenantID:        "tenant_7",
		ViewerTenantID:  "platform",
		IncludeResolved: true,
		IncludeAudit:    true,
	})
	if err != nil {
		t.Fatalf("build incident snapshot failed: %v", err)
	}
	if !incidentSnapshotDecision.Allowed || incidentSnapshot.IncidentCount != 1 || incidentSnapshot.AuditCount != 1 {
		t.Fatalf("unexpected incident snapshot allowed=%v incident_count=%d audit_count=%d", incidentSnapshotDecision.Allowed, incidentSnapshot.IncidentCount, incidentSnapshot.AuditCount)
	}

	topologySnapshot, topologyDecision, err := topologyRuntime.BuildSnapshot(RuntimeHealthTopologyRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "platform",
		IncludeEdges:   true,
	})
	if err != nil {
		t.Fatalf("build topology snapshot failed: %v", err)
	}
	if !topologyDecision.Allowed || topologySnapshot.NodeCount != 2 || topologySnapshot.EdgeCount != 1 {
		t.Fatalf("unexpected topology snapshot allowed=%v node_count=%d edge_count=%d", topologyDecision.Allowed, topologySnapshot.NodeCount, topologySnapshot.EdgeCount)
	}
}

func TestOpsConsoleFinalCrossTenantDenySet(t *testing.T) {
	jobRuntime := NewJobQueueWorkerMonitorConsoleRuntime(DefaultJobQueueWorkerMonitorConsoleConfig())
	notificationRuntime := NewNotificationWebhookMonitorConsoleRuntime(DefaultNotificationWebhookMonitorConsoleConfig())
	incidentRuntime := NewIncidentAuditCenterConsoleRuntime(DefaultIncidentAuditCenterConsoleConfig())
	topologyRuntime := NewRuntimeHealthTopologyConsoleRuntime(DefaultRuntimeHealthTopologyConsoleConfig())

	_, jobDecision, err := jobRuntime.BuildSnapshot(JobQueueWorkerMonitorRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
	})
	if err != ErrJobMonitorCrossTenant {
		t.Fatalf("expected job cross tenant error, got %v", err)
	}
	if jobDecision.Reason != JobMonitorReasonCrossTenant {
		t.Fatalf("expected job cross tenant reason, got %s", jobDecision.Reason)
	}

	_, notificationDecision, err := notificationRuntime.BuildSnapshot(NotificationWebhookMonitorRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
	})
	if err != ErrNotificationMonitorCrossTenant {
		t.Fatalf("expected notification cross tenant error, got %v", err)
	}
	if notificationDecision.Reason != NotificationMonitorReasonCrossTenant {
		t.Fatalf("expected notification cross tenant reason, got %s", notificationDecision.Reason)
	}

	_, incidentDecision, err := incidentRuntime.BuildSnapshot(IncidentAuditCenterRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
	})
	if err != ErrIncidentAuditCrossTenant {
		t.Fatalf("expected incident cross tenant error, got %v", err)
	}
	if incidentDecision.Reason != IncidentAuditReasonCrossTenant {
		t.Fatalf("expected incident cross tenant reason, got %s", incidentDecision.Reason)
	}

	_, topologyDecision, err := topologyRuntime.BuildSnapshot(RuntimeHealthTopologyRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
	})
	if err != ErrRuntimeTopologyCrossTenant {
		t.Fatalf("expected topology cross tenant error, got %v", err)
	}
	if topologyDecision.Reason != RuntimeTopologyReasonCrossTenant {
		t.Fatalf("expected topology cross tenant reason, got %s", topologyDecision.Reason)
	}
}

func TestOpsConsoleFinalHTMLCheckpointsExist(t *testing.T) {
	files := map[string][]string{
		"web/ops-console/job-worker-monitor/index.html": {
			"Job Queue / Worker Monitor",
			"Tenant:",
			"Queued Jobs",
			"Workers",
		},
		"web/ops-console/notification-webhook-monitor/index.html": {
			"Notification / Webhook Monitor",
			"Tenant:",
			"Delivery Stream",
			"Webhook Detail",
		},
		"web/ops-console/incident-audit-center/index.html": {
			"Incident / Audit Center",
			"Tenant:",
			"Incidents",
			"Audit Stream",
		},
		"web/ops-console/runtime-health-topology/index.html": {
			"Runtime Health / Topology",
			"Tenant:",
			"Topology Map",
			"Topology Edges",
		},
	}

	for file, markers := range files {
		text := readRepoCheckpointFile(t, file)
		for _, marker := range markers {
			if !strings.Contains(text, marker) {
				t.Fatalf("expected marker %q in %s", marker, file)
			}
		}
	}
}

func TestOpsConsoleFinalConfigAndDocsCheckpointsExist(t *testing.T) {
	files := map[string][]string{
		"configs/faz2/ops_console/job_queue_worker_monitor_screen.v1.json": {
			"job_queue_worker_monitor",
			"tenant_required",
		},
		"configs/faz2/ops_console/notification_webhook_monitor_screen.v1.json": {
			"notification_webhook_monitor",
			"cross_tenant_viewer_denied",
		},
		"configs/faz2/ops_console/incident_audit_center.v1.json": {
			"incident_audit_center",
			"audit_visibility_toggle",
		},
		"configs/faz2/ops_console/runtime_health_topology_view.v1.json": {
			"runtime_health_topology_view",
			"node_stale_detection",
		},
		"docs/faz2/ops_console/FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN.md": {
			"responsive",
			"Tenant",
		},
		"docs/faz2/ops_console/FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN.md": {
			"responsive",
			"Webhook",
		},
		"docs/faz2/ops_console/FAZ_2_8_6_INCIDENT_AUDIT_CENTER.md": {
			"responsive",
			"Audit",
		},
		"docs/faz2/ops_console/FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW.md": {
			"responsive",
			"Topology",
		},
	}

	for file, markers := range files {
		text := readRepoCheckpointFile(t, file)
		for _, marker := range markers {
			if !strings.Contains(text, marker) {
				t.Fatalf("expected marker %q in %s", marker, file)
			}
		}
	}
}
