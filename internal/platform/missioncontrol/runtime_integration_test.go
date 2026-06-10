package missioncontrol

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"
)

type mcServiceInstanceRecord struct {
	ServiceStatusCard
}

type mcIncidentRecord struct {
	IncidentID string
	TenantID   string
	ServiceID  string
	InstanceID string
	Status     string
	Summary    string
	UpdatedAt  time.Time
}

type mcTimelineEventRecord struct {
	TenantID string
	Item     IncidentTimelineItem
}

type missionControlRuntimeIntegrationStore struct {
	mu             sync.Mutex
	nowFn          func() time.Time
	actionSeq      int
	serviceRecords map[string]*mcServiceInstanceRecord
	incidents      map[string]*mcIncidentRecord
	timeline       []mcTimelineEventRecord
}

func newMissionControlRuntimeIntegrationStore() *missionControlRuntimeIntegrationStore {
	return &missionControlRuntimeIntegrationStore{
		nowFn: func() time.Time {
			return time.Now().UTC()
		},
		serviceRecords: make(map[string]*mcServiceInstanceRecord),
		incidents:      make(map[string]*mcIncidentRecord),
		timeline:       make([]mcTimelineEventRecord, 0),
	}
}

func (s *missionControlRuntimeIntegrationStore) seedServiceInstance(
	serviceID string,
	instanceID string,
	tenantID string,
	serviceKey string,
	displayName string,
	serviceKind string,
	visibilityScope string,
	instanceKey string,
	runtimeStatus string,
	host string,
	port int,
	version string,
	lastHeartbeatAt time.Time,
) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.serviceRecords[serviceID+"|"+instanceID] = &mcServiceInstanceRecord{
		ServiceStatusCard: ServiceStatusCard{
			ServiceID:       serviceID,
			InstanceID:      instanceID,
			TenantID:        tenantID,
			ServiceKey:      serviceKey,
			DisplayName:     displayName,
			ServiceKind:     serviceKind,
			VisibilityScope: visibilityScope,
			InstanceKey:     instanceKey,
			RuntimeStatus:   runtimeStatus,
			Host:            host,
			Port:            port,
			Version:         version,
			LastHeartbeatAt: lastHeartbeatAt.UTC(),
		},
	}
}

func (s *missionControlRuntimeIntegrationStore) seedIncident(
	incidentID string,
	tenantID string,
	serviceID string,
	instanceID string,
	status string,
	summary string,
	updatedAt time.Time,
) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.incidents[incidentID] = &mcIncidentRecord{
		IncidentID: incidentID,
		TenantID:   tenantID,
		ServiceID:  serviceID,
		InstanceID: instanceID,
		Status:     status,
		Summary:    summary,
		UpdatedAt:  updatedAt.UTC(),
	}
}

func (s *missionControlRuntimeIntegrationStore) ListRuntimeStatusCards(_ context.Context, req StatusPanelRequest) ([]ServiceStatusCard, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	items := make([]ServiceStatusCard, 0)
	tenantID := strings.TrimSpace(req.TenantID)
	keyLike := strings.TrimSpace(req.ServiceKeyLike)
	status := strings.TrimSpace(req.StatusFilter)

	for _, record := range s.serviceRecords {
		item := record.ServiceStatusCard

		visible := false
		if tenantID != "" && item.TenantID == tenantID {
			visible = true
		}
		if req.IncludeGlobal && item.VisibilityScope == "global" {
			visible = true
		}
		if !visible {
			continue
		}

		if keyLike != "" && !strings.HasPrefix(item.ServiceKey, keyLike) {
			continue
		}

		if status != "" && item.RuntimeStatus != status {
			continue
		}

		items = append(items, item)
	}

	sort.Slice(items, func(i, j int) bool {
		if items[i].RuntimeStatus == items[j].RuntimeStatus {
			if items[i].ServiceKey == items[j].ServiceKey {
				return items[i].InstanceKey < items[j].InstanceKey
			}
			return items[i].ServiceKey < items[j].ServiceKey
		}
		return items[i].RuntimeStatus < items[j].RuntimeStatus
	})

	if req.Limit > 0 && len(items) > req.Limit {
		items = items[:req.Limit]
	}

	return items, nil
}

func (s *missionControlRuntimeIntegrationStore) RequestRestartAction(_ context.Context, cmd RequestRestartActionCommand) (RequestRestartActionResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	incident, err := s.getIncidentLocked(cmd.TenantID, cmd.IncidentID, cmd.ServiceID)
	if err != nil {
		return RequestRestartActionResult{}, err
	}

	now := s.nowFn().UTC()
	actionID := s.nextActionIDLocked()

	s.timeline = append(s.timeline, mcTimelineEventRecord{
		TenantID: incident.TenantID,
		Item: IncidentTimelineItem{
			EventID:        actionID,
			IncidentID:     incident.IncidentID,
			ServiceID:      incident.ServiceID,
			EventType:      "action",
			ActionType:     "restart",
			ActionStatus:   "requested",
			IncidentStatus: "",
			ActorRef:       strings.TrimSpace(cmd.RequestedBy),
			Message:        strings.TrimSpace(cmd.RequestedReason),
			OccurredAt:     now,
		},
	})

	return RequestRestartActionResult{
		ActionID:     actionID,
		ActionStatus: "requested",
	}, nil
}

func (s *missionControlRuntimeIntegrationStore) RequestIsolationAction(_ context.Context, cmd RequestIsolationActionCommand) (RequestIsolationActionResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	incident, err := s.getIncidentLocked(cmd.TenantID, cmd.IncidentID, cmd.ServiceID)
	if err != nil {
		return RequestIsolationActionResult{}, err
	}

	now := s.nowFn().UTC()
	actionID := s.nextActionIDLocked()

	s.timeline = append(s.timeline, mcTimelineEventRecord{
		TenantID: incident.TenantID,
		Item: IncidentTimelineItem{
			EventID:        actionID,
			IncidentID:     incident.IncidentID,
			ServiceID:      incident.ServiceID,
			EventType:      "action",
			ActionType:     strings.TrimSpace(cmd.ActionType),
			ActionStatus:   "requested",
			IncidentStatus: "",
			ActorRef:       strings.TrimSpace(cmd.RequestedBy),
			Message:        strings.TrimSpace(cmd.RequestedReason),
			OccurredAt:     now,
		},
	})

	return RequestIsolationActionResult{
		ActionID:     actionID,
		ActionStatus: "requested",
	}, nil
}

func (s *missionControlRuntimeIntegrationStore) RequestMaintenanceAction(_ context.Context, cmd RequestMaintenanceActionCommand) (RequestMaintenanceActionResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	incident, err := s.getIncidentLocked(cmd.TenantID, cmd.IncidentID, cmd.ServiceID)
	if err != nil {
		return RequestMaintenanceActionResult{}, err
	}

	now := s.nowFn().UTC()
	actionID := s.nextActionIDLocked()

	s.timeline = append(s.timeline, mcTimelineEventRecord{
		TenantID: incident.TenantID,
		Item: IncidentTimelineItem{
			EventID:        actionID,
			IncidentID:     incident.IncidentID,
			ServiceID:      incident.ServiceID,
			EventType:      "action",
			ActionType:     strings.TrimSpace(cmd.ActionType),
			ActionStatus:   "requested",
			IncidentStatus: "",
			ActorRef:       strings.TrimSpace(cmd.RequestedBy),
			Message:        strings.TrimSpace(cmd.RequestedReason),
			OccurredAt:     now,
		},
	})

	return RequestMaintenanceActionResult{
		ActionID:     actionID,
		ActionStatus: "requested",
	}, nil
}

func (s *missionControlRuntimeIntegrationStore) RequestIncidentStateAction(_ context.Context, cmd RequestIncidentStateActionCommand) (RequestIncidentStateActionResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	incident, err := s.getIncidentLocked(cmd.TenantID, cmd.IncidentID, cmd.ServiceID)
	if err != nil {
		return RequestIncidentStateActionResult{}, err
	}

	now := s.nowFn().UTC()
	actionID := s.nextActionIDLocked()

	s.timeline = append(s.timeline, mcTimelineEventRecord{
		TenantID: incident.TenantID,
		Item: IncidentTimelineItem{
			EventID:        actionID,
			IncidentID:     incident.IncidentID,
			ServiceID:      incident.ServiceID,
			EventType:      "action",
			ActionType:     strings.TrimSpace(cmd.ActionType),
			ActionStatus:   "requested",
			IncidentStatus: "",
			ActorRef:       strings.TrimSpace(cmd.RequestedBy),
			Message:        strings.TrimSpace(cmd.ResponseNote),
			OccurredAt:     now,
		},
	})

	nextIncidentStatus := "open"
	switch strings.TrimSpace(cmd.ActionType) {
	case "acknowledge":
		nextIncidentStatus = "acknowledged"
	case "resolve":
		nextIncidentStatus = "resolved"
	default:
		nextIncidentStatus = incident.Status
	}

	if !cmd.DryRun {
		incident.Status = nextIncidentStatus
		incident.UpdatedAt = now

		s.timeline = append(s.timeline, mcTimelineEventRecord{
			TenantID: incident.TenantID,
			Item: IncidentTimelineItem{
				EventID:        actionID + "-state",
				IncidentID:     incident.IncidentID,
				ServiceID:      incident.ServiceID,
				EventType:      "state_change",
				ActionType:     "",
				ActionStatus:   "",
				IncidentStatus: nextIncidentStatus,
				ActorRef:       strings.TrimSpace(cmd.RequestedBy),
				Message:        strings.TrimSpace(cmd.ResponseNote),
				OccurredAt:     now.Add(time.Nanosecond),
			},
		})
	}

	return RequestIncidentStateActionResult{
		ActionID:       actionID,
		ActionStatus:   "requested",
		IncidentStatus: nextIncidentStatus,
	}, nil
}

func (s *missionControlRuntimeIntegrationStore) ListIncidentTimeline(_ context.Context, cmd ListIncidentTimelineCommand) ([]IncidentTimelineItem, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	items := make([]IncidentTimelineItem, 0)
	targetTenantID := strings.TrimSpace(cmd.TenantID)

	for _, event := range s.timeline {
		if targetTenantID != "" && event.TenantID != targetTenantID {
			continue
		}

		if event.Item.IncidentID != strings.TrimSpace(cmd.IncidentID) {
			continue
		}

		if event.Item.ServiceID != strings.TrimSpace(cmd.ServiceID) {
			continue
		}

		include := false
		switch event.Item.EventType {
		case "action":
			include = cmd.IncludeActions
		case "state_change":
			include = cmd.IncludeStateChanges
		case "note":
			include = cmd.IncludeNotes
		default:
			include = false
		}

		if !include {
			continue
		}

		items = append(items, event.Item)
	}

	sort.Slice(items, func(i, j int) bool {
		return items[i].OccurredAt.After(items[j].OccurredAt)
	})

	if cmd.Limit > 0 && len(items) > cmd.Limit {
		items = items[:cmd.Limit]
	}

	return items, nil
}

func (s *missionControlRuntimeIntegrationStore) getIncidentLocked(tenantID, incidentID, serviceID string) (*mcIncidentRecord, error) {
	incident, ok := s.incidents[strings.TrimSpace(incidentID)]
	if !ok {
		return nil, fmt.Errorf("incident not found: %s", incidentID)
	}

	if strings.TrimSpace(serviceID) != incident.ServiceID {
		return nil, fmt.Errorf("incident service mismatch: %s", serviceID)
	}

	targetTenantID := strings.TrimSpace(tenantID)
	if targetTenantID != "" && incident.TenantID != targetTenantID {
		return nil, fmt.Errorf("incident tenant mismatch: %s", tenantID)
	}

	return incident, nil
}

func (s *missionControlRuntimeIntegrationStore) nextActionIDLocked() string {
	s.actionSeq++
	return fmt.Sprintf("act-%03d", s.actionSeq)
}

func TestMissionControlRuntimeIntegration_StatusPanelRestartTimelineFlow(t *testing.T) {
	store := newMissionControlRuntimeIntegrationStore()
	store.seedServiceInstance(
		"svc-1",
		"ins-1",
		"tenant-a",
		"identity-api",
		"Identity API",
		"api",
		"tenant",
		"identity-api-01",
		"healthy",
		"10.10.10.11",
		9001,
		"1.0.0",
		time.Date(2026, 4, 25, 1, 0, 0, 0, time.UTC),
	)
	store.seedIncident(
		"inc-1",
		"tenant-a",
		"svc-1",
		"ins-1",
		"open",
		"timeout artisi",
		time.Date(2026, 4, 25, 1, 0, 0, 0, time.UTC),
	)

	statusPanelUsecase := NewStatusPanelUsecase(store)
	restartUsecase := NewRestartActionUsecase(store)
	timelineUsecase := NewIncidentTimelineUsecase(store)

	panelResp, err := statusPanelUsecase.Get(context.Background(), StatusPanelRequest{
		TenantID:      "tenant-a",
		IncludeGlobal: false,
		Limit:         20,
	})
	if err != nil {
		t.Fatalf("status panel hatasi: %v", err)
	}

	if len(panelResp.Items) != 1 {
		t.Fatalf("beklenen 1 status panel kaydi, alinan: %d", len(panelResp.Items))
	}

	if panelResp.Items[0].RuntimeStatus != "healthy" {
		t.Fatalf("beklenen runtime_status healthy, alinan: %s", panelResp.Items[0].RuntimeStatus)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 1, 5, 0, 0, time.UTC)
	}

	restartResp, err := restartUsecase.Request(context.Background(), RestartActionRequest{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		RequestedBy:     "operator-a",
		RequestedReason: "timeout artisi",
		DryRun:          false,
	})
	if err != nil {
		t.Fatalf("restart action hatasi: %v", err)
	}

	if restartResp.ActionID == "" {
		t.Fatalf("restart action id bos dondu")
	}

	timelineResp, err := timelineUsecase.List(context.Background(), IncidentTimelineRequest{
		TenantID:            "tenant-a",
		IncidentID:          "inc-1",
		ServiceID:           "svc-1",
		IncludeActions:      true,
		IncludeStateChanges: false,
		IncludeNotes:        false,
		Limit:               20,
	})
	if err != nil {
		t.Fatalf("timeline hatasi: %v", err)
	}

	if timelineResp.Count != 1 {
		t.Fatalf("beklenen 1 timeline eventi, alinan: %d", timelineResp.Count)
	}

	if timelineResp.Items[0].ActionType != "restart" {
		t.Fatalf("beklenen action_type restart, alinan: %s", timelineResp.Items[0].ActionType)
	}

	if timelineResp.Items[0].ActorRef != "operator-a" {
		t.Fatalf("beklenen actor_ref operator-a, alinan: %s", timelineResp.Items[0].ActorRef)
	}
}

func TestMissionControlRuntimeIntegration_TenantIsolationAcrossStatusPanelAndActions(t *testing.T) {
	store := newMissionControlRuntimeIntegrationStore()

	store.seedServiceInstance(
		"svc-g",
		"ins-g",
		"",
		"gateway-public",
		"Gateway Public",
		"gateway",
		"global",
		"gateway-public-01",
		"healthy",
		"10.10.10.20",
		9010,
		"1.0.0",
		time.Date(2026, 4, 25, 2, 0, 0, 0, time.UTC),
	)
	store.seedServiceInstance(
		"svc-a",
		"ins-a",
		"tenant-a",
		"identity-api",
		"Identity API",
		"api",
		"tenant",
		"identity-api-01",
		"healthy",
		"10.10.10.11",
		9001,
		"1.0.0",
		time.Date(2026, 4, 25, 2, 0, 0, 0, time.UTC),
	)
	store.seedServiceInstance(
		"svc-b",
		"ins-b",
		"tenant-b",
		"erp-core",
		"ERP Core",
		"api",
		"tenant",
		"erp-core-01",
		"healthy",
		"10.10.10.12",
		9030,
		"1.0.0",
		time.Date(2026, 4, 25, 2, 0, 0, 0, time.UTC),
	)

	store.seedIncident("inc-a", "tenant-a", "svc-a", "ins-a", "open", "tenant-a issue", time.Date(2026, 4, 25, 2, 0, 0, 0, time.UTC))
	store.seedIncident("inc-b", "tenant-b", "svc-b", "ins-b", "open", "tenant-b issue", time.Date(2026, 4, 25, 2, 0, 0, 0, time.UTC))

	statusPanelUsecase := NewStatusPanelUsecase(store)
	restartUsecase := NewRestartActionUsecase(store)

	panelResp, err := statusPanelUsecase.Get(context.Background(), StatusPanelRequest{
		TenantID:      "tenant-a",
		IncludeGlobal: true,
		Limit:         20,
	})
	if err != nil {
		t.Fatalf("status panel hatasi: %v", err)
	}

	if len(panelResp.Items) != 2 {
		t.Fatalf("tenant-a icin beklenen 2 kayit, alinan: %d", len(panelResp.Items))
	}

	for _, item := range panelResp.Items {
		if item.ServiceID == "svc-b" {
			t.Fatalf("tenant-a tenant-b servisini gormemeli")
		}
	}

	_, err = restartUsecase.Request(context.Background(), RestartActionRequest{
		TenantID:        "tenant-a",
		IncidentID:      "inc-b",
		ServiceID:       "svc-b",
		InstanceID:      "ins-b",
		RequestedBy:     "operator-a",
		RequestedReason: "izinsiz istek",
		DryRun:          false,
	})
	if err == nil {
		t.Fatalf("tenant-a tenant-b incident'i uzerinde action cagrisi yapamamaliydi")
	}
}

func TestMissionControlRuntimeIntegration_IncidentLifecycleTimelineFlow(t *testing.T) {
	store := newMissionControlRuntimeIntegrationStore()

	store.seedServiceInstance(
		"svc-1",
		"ins-1",
		"tenant-a",
		"identity-api",
		"Identity API",
		"api",
		"tenant",
		"identity-api-01",
		"degraded",
		"10.10.10.11",
		9001,
		"1.0.0",
		time.Date(2026, 4, 25, 3, 0, 0, 0, time.UTC),
	)
	store.seedIncident(
		"inc-1",
		"tenant-a",
		"svc-1",
		"ins-1",
		"open",
		"latency spike",
		time.Date(2026, 4, 25, 3, 0, 0, 0, time.UTC),
	)

	ackUsecase := NewIncidentStateActionUsecase(store)
	maintenanceUsecase := NewMaintenanceActionUsecase(store)
	isolationUsecase := NewIsolationActionUsecase(store)
	resolveUsecase := NewIncidentStateActionUsecase(store)
	timelineUsecase := NewIncidentTimelineUsecase(store)

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 3, 1, 0, 0, time.UTC)
	}
	if _, err := ackUsecase.Request(context.Background(), IncidentStateActionRequest{
		TenantID:     "tenant-a",
		IncidentID:   "inc-1",
		ServiceID:    "svc-1",
		ActionType:   "acknowledge",
		RequestedBy:  "operator-a",
		ResponseNote: "ilk inceleme alindi",
		DryRun:       false,
	}); err != nil {
		t.Fatalf("acknowledge hatasi: %v", err)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 3, 2, 0, 0, time.UTC)
	}
	if _, err := maintenanceUsecase.Request(context.Background(), MaintenanceActionRequest{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		ActionType:      "maintenance_on",
		RequestedBy:     "operator-a",
		RequestedReason: "planned mitigation",
		DryRun:          false,
	}); err != nil {
		t.Fatalf("maintenance hatasi: %v", err)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 3, 3, 0, 0, time.UTC)
	}
	if _, err := isolationUsecase.Request(context.Background(), IsolationActionRequest{
		TenantID:        "tenant-a",
		IncidentID:      "inc-1",
		ServiceID:       "svc-1",
		InstanceID:      "ins-1",
		ActionType:      "quarantine",
		RequestedBy:     "operator-a",
		RequestedReason: "risk azaltma",
		DryRun:          false,
	}); err != nil {
		t.Fatalf("isolation hatasi: %v", err)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 3, 4, 0, 0, time.UTC)
	}
	if _, err := resolveUsecase.Request(context.Background(), IncidentStateActionRequest{
		TenantID:     "tenant-a",
		IncidentID:   "inc-1",
		ServiceID:    "svc-1",
		ActionType:   "resolve",
		RequestedBy:  "operator-a",
		ResponseNote: "problem giderildi",
		DryRun:       false,
	}); err != nil {
		t.Fatalf("resolve hatasi: %v", err)
	}

	timelineResp, err := timelineUsecase.List(context.Background(), IncidentTimelineRequest{
		TenantID:            "tenant-a",
		IncidentID:          "inc-1",
		ServiceID:           "svc-1",
		IncludeActions:      true,
		IncludeStateChanges: true,
		IncludeNotes:        false,
		Limit:               50,
	})
	if err != nil {
		t.Fatalf("timeline hatasi: %v", err)
	}

	if timelineResp.Count != 6 {
		t.Fatalf("beklenen 6 timeline eventi, alinan: %d", timelineResp.Count)
	}

	if timelineResp.Items[0].EventType != "state_change" {
		t.Fatalf("beklenen en son event state_change, alinan: %s", timelineResp.Items[0].EventType)
	}

	if timelineResp.Items[0].IncidentStatus != "resolved" {
		t.Fatalf("beklenen en son incident_status resolved, alinan: %s", timelineResp.Items[0].IncidentStatus)
	}

	foundMaintenance := false
	foundQuarantine := false
	for _, item := range timelineResp.Items {
		if item.ActionType == "maintenance_on" {
			foundMaintenance = true
		}
		if item.ActionType == "quarantine" {
			foundQuarantine = true
		}
	}

	if !foundMaintenance {
		t.Fatalf("maintenance_on eventi timeline icinde bulunamadi")
	}

	if !foundQuarantine {
		t.Fatalf("quarantine eventi timeline icinde bulunamadi")
	}
}
