package plugins

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"testing"
	"time"
)

type pluginRuntimeRecord struct {
	PluginKey                string
	TenantID                 string
	Version                  int
	RuntimeMode              string
	EntrypointRef            string
	PermissionProfile        string
	SandboxRequired          bool
	IsActive                 bool
	LifecycleStatus          string
	RuntimeEnabled           bool
	MinSupportedHostVersion  int
	MaxSupportedHostVersion  int
	UpdatedAt                time.Time
}

type pluginPermissionRecord struct {
	PluginKey         string
	TenantID          string
	PermissionProfile string
	Operation         string
	ResourceScope     string
	Permitted         bool
	DenialReason      string
	UpdatedAt         time.Time
}

type pluginSandboxRecord struct {
	PluginKey         string
	TenantID          string
	RuntimeMode       string
	PermissionProfile string
	SandboxID         string
	IsolationMode     string
	NetworkPolicy     string
	TenantScoped      bool
	Ready             bool
	DenialReason      string
	UpdatedAt         time.Time
}

type pluginRuntimeIntegrationStore struct {
	mu          sync.Mutex
	nowFn       func() time.Time
	plugins     map[string]*pluginRuntimeRecord
	permissions map[string]*pluginPermissionRecord
	sandboxes   map[string]*pluginSandboxRecord
}

func newPluginRuntimeIntegrationStore() *pluginRuntimeIntegrationStore {
	return &pluginRuntimeIntegrationStore{
		nowFn: func() time.Time {
			return time.Now().UTC()
		},
		plugins:     make(map[string]*pluginRuntimeRecord),
		permissions: make(map[string]*pluginPermissionRecord),
		sandboxes:   make(map[string]*pluginSandboxRecord),
	}
}

func pluginTenantKey(tenantID, pluginKey string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(pluginKey)
}

func pluginPermissionKey(tenantID, pluginKey, profile, operation, scope string) string {
	return strings.Join([]string{
		strings.TrimSpace(tenantID),
		strings.TrimSpace(pluginKey),
		strings.TrimSpace(profile),
		strings.TrimSpace(operation),
		strings.TrimSpace(scope),
	}, "::")
}

func pluginSandboxKey(tenantID, pluginKey, runtimeMode, profile string) string {
	return strings.Join([]string{
		strings.TrimSpace(tenantID),
		strings.TrimSpace(pluginKey),
		strings.TrimSpace(runtimeMode),
		strings.TrimSpace(profile),
	}, "::")
}

func (s *pluginRuntimeIntegrationStore) seedPlugin(rec pluginRuntimeRecord) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	rec.UpdatedAt = now
	s.plugins[pluginTenantKey(rec.TenantID, rec.PluginKey)] = &rec
}

func (s *pluginRuntimeIntegrationStore) seedPermission(rec pluginPermissionRecord) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	rec.UpdatedAt = now
	s.permissions[pluginPermissionKey(rec.TenantID, rec.PluginKey, rec.PermissionProfile, rec.Operation, rec.ResourceScope)] = &rec
}

func (s *pluginRuntimeIntegrationStore) seedSandbox(rec pluginSandboxRecord) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	rec.UpdatedAt = now
	s.sandboxes[pluginSandboxKey(rec.TenantID, rec.PluginKey, rec.RuntimeMode, rec.PermissionProfile)] = &rec
}

func (s *pluginRuntimeIntegrationStore) LoadPlugin(_ context.Context, cmd LoadPluginCommand) (LoadPluginResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	rec, ok := s.plugins[pluginTenantKey(cmd.TenantID, cmd.PluginKey)]
	if !ok || !rec.IsActive {
		return LoadPluginResult{
			PluginKey: strings.TrimSpace(cmd.PluginKey),
			Loaded:    false,
		}, nil
	}

	return LoadPluginResult{
		PluginKey:         rec.PluginKey,
		Version:           rec.Version,
		RuntimeMode:       rec.RuntimeMode,
		EntrypointRef:     rec.EntrypointRef,
		PermissionProfile: rec.PermissionProfile,
		SandboxRequired:   rec.SandboxRequired,
		Loaded:            true,
	}, nil
}

func (s *pluginRuntimeIntegrationStore) ApplyPluginLifecycle(_ context.Context, cmd ApplyPluginLifecycleCommand) (ApplyPluginLifecycleResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	rec, ok := s.plugins[pluginTenantKey(cmd.TenantID, cmd.PluginKey)]
	if !ok {
		return ApplyPluginLifecycleResult{}, fmt.Errorf("plugin not found: %s", cmd.PluginKey)
	}

	switch strings.TrimSpace(cmd.ActionType) {
	case "activate", "resume":
		rec.LifecycleStatus = "active"
		rec.RuntimeEnabled = true
		rec.IsActive = true
	case "deactivate":
		rec.LifecycleStatus = "inactive"
		rec.RuntimeEnabled = false
		rec.IsActive = false
	case "suspend":
		rec.LifecycleStatus = "suspended"
		rec.RuntimeEnabled = false
	default:
		return ApplyPluginLifecycleResult{}, fmt.Errorf("unsupported lifecycle action: %s", cmd.ActionType)
	}

	rec.UpdatedAt = s.nowFn().UTC()

	return ApplyPluginLifecycleResult{
		PluginKey:       rec.PluginKey,
		ActionType:      strings.TrimSpace(cmd.ActionType),
		LifecycleStatus: rec.LifecycleStatus,
		RuntimeEnabled:  rec.RuntimeEnabled,
		Applied:         true,
	}, nil
}

func (s *pluginRuntimeIntegrationStore) EvaluatePermission(_ context.Context, cmd EvaluatePluginPermissionCommand) (EvaluatePluginPermissionResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	key := pluginPermissionKey(cmd.TenantID, cmd.PluginKey, cmd.PermissionProfile, cmd.Operation, cmd.ResourceScope)
	rec, ok := s.permissions[key]
	if !ok {
		return EvaluatePluginPermissionResult{}, nil
	}

	return EvaluatePluginPermissionResult{
		PluginKey:         rec.PluginKey,
		PermissionProfile: rec.PermissionProfile,
		Operation:         rec.Operation,
		ResourceScope:     rec.ResourceScope,
		Permitted:         rec.Permitted,
		DenialReason:      rec.DenialReason,
	}, nil
}

func (s *pluginRuntimeIntegrationStore) EnsureTenantSandbox(_ context.Context, cmd EnsurePluginSandboxCommand) (EnsurePluginSandboxResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	key := pluginSandboxKey(cmd.TenantID, cmd.PluginKey, cmd.RuntimeMode, cmd.PermissionProfile)
	rec, ok := s.sandboxes[key]
	if !ok {
		return EnsurePluginSandboxResult{}, nil
	}

	return EnsurePluginSandboxResult{
		PluginKey:         rec.PluginKey,
		RuntimeMode:       rec.RuntimeMode,
		PermissionProfile: rec.PermissionProfile,
		SandboxID:         rec.SandboxID,
		IsolationMode:     rec.IsolationMode,
		NetworkPolicy:     rec.NetworkPolicy,
		TenantScoped:      rec.TenantScoped,
		Ready:             rec.Ready,
		DenialReason:      rec.DenialReason,
	}, nil
}

func (s *pluginRuntimeIntegrationStore) CheckVersionCompatibility(_ context.Context, cmd CheckPluginVersionCompatibilityCommand) (CheckPluginVersionCompatibilityResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	rec, ok := s.plugins[pluginTenantKey(cmd.TenantID, cmd.PluginKey)]
	if !ok {
		return CheckPluginVersionCompatibilityResult{}, fmt.Errorf("plugin not found: %s", cmd.PluginKey)
	}

	status, compatible, reason := evaluatePluginCompatibilityRange(
		cmd.HostAPIVersion,
		rec.MinSupportedHostVersion,
		rec.MaxSupportedHostVersion,
	)

	return CheckPluginVersionCompatibilityResult{
		PluginKey:               rec.PluginKey,
		PluginVersion:           rec.Version,
		RuntimeMode:             rec.RuntimeMode,
		HostAPIVersion:          cmd.HostAPIVersion,
		MinSupportedHostVersion: rec.MinSupportedHostVersion,
		MaxSupportedHostVersion: rec.MaxSupportedHostVersion,
		CompatibilityStatus:     status,
		Compatible:              compatible,
		Reason:                  reason,
	}, nil
}

func (s *pluginRuntimeIntegrationStore) snapshotPlugin(tenantID, pluginKey string) (pluginRuntimeRecord, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()

	rec, ok := s.plugins[pluginTenantKey(tenantID, pluginKey)]
	if !ok {
		return pluginRuntimeRecord{}, false
	}

	out := *rec
	return out, true
}

func TestPluginRuntimeIntegration_LoadLifecyclePermissionSandboxCompatibilityFlow(t *testing.T) {
	store := newPluginRuntimeIntegrationStore()

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 5, 0, 0, 0, time.UTC)
	}

	store.seedPlugin(pluginRuntimeRecord{
		PluginKey:               "erp.logo_export",
		TenantID:                "tenant-a",
		Version:                 4,
		RuntimeMode:             "wasm",
		EntrypointRef:           "logo_export_v4",
		PermissionProfile:       "tenant_ops",
		SandboxRequired:         true,
		IsActive:                true,
		LifecycleStatus:         "inactive",
		RuntimeEnabled:          false,
		MinSupportedHostVersion: 3,
		MaxSupportedHostVersion: 5,
	})

	store.seedPermission(pluginPermissionRecord{
		PluginKey:         "erp.logo_export",
		TenantID:          "tenant-a",
		PermissionProfile: "tenant_ops",
		Operation:         "write",
		ResourceScope:     "tenant_runtime",
		Permitted:         true,
		DenialReason:      "",
	})

	store.seedSandbox(pluginSandboxRecord{
		PluginKey:         "erp.logo_export",
		TenantID:          "tenant-a",
		RuntimeMode:       "wasm",
		PermissionProfile: "tenant_ops",
		SandboxID:         "erp.logo_export_sandbox",
		IsolationMode:     "tenant_process",
		NetworkPolicy:     "disabled",
		TenantScoped:      true,
		Ready:             true,
		DenialReason:      "",
	})

	loadUsecase := NewLoadPluginUsecase(store)
	lifecycleUsecase := NewApplyPluginLifecycleUsecase(store)
	permissionUsecase := NewEvaluatePluginPermissionUsecase(store)
	sandboxUsecase := NewEnsurePluginSandboxUsecase(store)
	versionUsecase := NewCheckPluginVersionCompatibilityUsecase(store)

	loadUsecase.nowFn = store.nowFn
	lifecycleUsecase.nowFn = store.nowFn
	permissionUsecase.nowFn = store.nowFn
	sandboxUsecase.nowFn = store.nowFn
	versionUsecase.nowFn = store.nowFn

	loadResp, err := loadUsecase.Load(context.Background(), LoadPluginRequest{
		TenantID:    "tenant-a",
		PluginKey:   "erp.logo_export",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("plugin load hatasi: %v", err)
	}

	if !loadResp.Loaded {
		t.Fatalf("plugin yuklenmeliydi")
	}

	lifecycleResp, err := lifecycleUsecase.Apply(context.Background(), ApplyPluginLifecycleRequest{
		TenantID:    "tenant-a",
		PluginKey:   "erp.logo_export",
		ActionType:  "activate",
		RequestedBy: "worker-01",
		Reason:      "canliya aliniyor",
	})
	if err != nil {
		t.Fatalf("lifecycle hatasi: %v", err)
	}

	if lifecycleResp.LifecycleStatus != "active" || !lifecycleResp.RuntimeEnabled {
		t.Fatalf("plugin active hale gelmeliydi")
	}

	permissionResp, err := permissionUsecase.Evaluate(context.Background(), EvaluatePluginPermissionRequest{
		TenantID:          "tenant-a",
		PluginKey:         "erp.logo_export",
		PermissionProfile: "tenant_ops",
		Operation:         "write",
		ResourceScope:     "tenant_runtime",
		RequestedBy:       "worker-01",
	})
	if err != nil {
		t.Fatalf("permission evaluate hatasi: %v", err)
	}

	if !permissionResp.Permitted {
		t.Fatalf("permission izinli olmaliydi")
	}

	sandboxResp, err := sandboxUsecase.Ensure(context.Background(), EnsurePluginSandboxRequest{
		TenantID:          "tenant-a",
		PluginKey:         "erp.logo_export",
		RuntimeMode:       "wasm",
		PermissionProfile: "tenant_ops",
		RequestedBy:       "worker-01",
	})
	if err != nil {
		t.Fatalf("sandbox ensure hatasi: %v", err)
	}

	if !sandboxResp.Ready || !sandboxResp.TenantScoped {
		t.Fatalf("sandbox hazir ve tenant scoped olmaliydi")
	}

	versionResp, err := versionUsecase.Check(context.Background(), CheckPluginVersionCompatibilityRequest{
		TenantID:       "tenant-a",
		PluginKey:      "erp.logo_export",
		PluginVersion:  4,
		RuntimeMode:    "wasm",
		HostAPIVersion: 4,
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("version compatibility hatasi: %v", err)
	}

	if !versionResp.Compatible || versionResp.CompatibilityStatus != "compatible" {
		t.Fatalf("version compatible olmaliydi")
	}

	pluginSnapshot, ok := store.snapshotPlugin("tenant-a", "erp.logo_export")
	if !ok {
		t.Fatalf("plugin snapshot bulunamadi")
	}

	if pluginSnapshot.LifecycleStatus != "active" || !pluginSnapshot.RuntimeEnabled {
		t.Fatalf("plugin snapshot active/runtime_enabled bekleniyordu")
	}
}

func TestPluginRuntimeIntegration_DeniedPermissionAndBlockedCompatibilityFlow(t *testing.T) {
	store := newPluginRuntimeIntegrationStore()

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 5, 30, 0, 0, time.UTC)
	}

	store.seedPlugin(pluginRuntimeRecord{
		PluginKey:               "crm.sync_agent",
		TenantID:                "tenant-a",
		Version:                 4,
		RuntimeMode:             "native",
		EntrypointRef:           "crm_sync_agent",
		PermissionProfile:       "read_only",
		SandboxRequired:         true,
		IsActive:                true,
		LifecycleStatus:         "active",
		RuntimeEnabled:          true,
		MinSupportedHostVersion: 4,
		MaxSupportedHostVersion: 4,
	})

	store.seedPermission(pluginPermissionRecord{
		PluginKey:         "crm.sync_agent",
		TenantID:          "tenant-a",
		PermissionProfile: "read_only",
		Operation:         "write",
		ResourceScope:     "tenant_data",
		Permitted:         false,
		DenialReason:      "read_only profili sadece tenant_data read izni verir",
	})

	loadUsecase := NewLoadPluginUsecase(store)
	permissionUsecase := NewEvaluatePluginPermissionUsecase(store)
	sandboxUsecase := NewEnsurePluginSandboxUsecase(store)
	versionUsecase := NewCheckPluginVersionCompatibilityUsecase(store)

	loadUsecase.nowFn = store.nowFn
	permissionUsecase.nowFn = store.nowFn
	sandboxUsecase.nowFn = store.nowFn
	versionUsecase.nowFn = store.nowFn

	loadResp, err := loadUsecase.Load(context.Background(), LoadPluginRequest{
		TenantID:    "tenant-a",
		PluginKey:   "crm.sync_agent",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("plugin load hatasi: %v", err)
	}

	if !loadResp.Loaded {
		t.Fatalf("plugin yuklenmeliydi")
	}

	permissionResp, err := permissionUsecase.Evaluate(context.Background(), EvaluatePluginPermissionRequest{
		TenantID:          "tenant-a",
		PluginKey:         "crm.sync_agent",
		PermissionProfile: "read_only",
		Operation:         "write",
		ResourceScope:     "tenant_data",
		RequestedBy:       "worker-01",
	})
	if err != nil {
		t.Fatalf("permission evaluate hatasi: %v", err)
	}

	if permissionResp.Permitted || permissionResp.DenialReason == "" {
		t.Fatalf("permission reddedilmeli ve denial_reason dolu olmaliydi")
	}

	sandboxResp, err := sandboxUsecase.Ensure(context.Background(), EnsurePluginSandboxRequest{
		TenantID:          "tenant-a",
		PluginKey:         "crm.sync_agent",
		RuntimeMode:       "native",
		PermissionProfile: "system_ops",
		RequestedBy:       "worker-01",
	})
	if err != nil {
		t.Fatalf("sandbox ensure hatasi: %v", err)
	}

	if sandboxResp.Ready {
		t.Fatalf("sandbox hazir olmamaliydi")
	}

	versionResp, err := versionUsecase.Check(context.Background(), CheckPluginVersionCompatibilityRequest{
		TenantID:       "tenant-a",
		PluginKey:      "crm.sync_agent",
		PluginVersion:  4,
		RuntimeMode:    "native",
		HostAPIVersion: 6,
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("version compatibility hatasi: %v", err)
	}

	if versionResp.Compatible || versionResp.CompatibilityStatus != "blocked" {
		t.Fatalf("compatibility blocked olmaliydi")
	}
}

func TestPluginRuntimeIntegration_TenantIsolationFlow(t *testing.T) {
	store := newPluginRuntimeIntegrationStore()

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 6, 0, 0, 0, time.UTC)
	}

	store.seedPlugin(pluginRuntimeRecord{
		PluginKey:               "erp.logo_export",
		TenantID:                "tenant-a",
		Version:                 2,
		RuntimeMode:             "wasm",
		EntrypointRef:           "logo_export_v2",
		PermissionProfile:       "tenant_ops",
		SandboxRequired:         true,
		IsActive:                true,
		LifecycleStatus:         "inactive",
		RuntimeEnabled:          false,
		MinSupportedHostVersion: 1,
		MaxSupportedHostVersion: 3,
	})

	store.seedPlugin(pluginRuntimeRecord{
		PluginKey:               "erp.logo_export",
		TenantID:                "tenant-b",
		Version:                 3,
		RuntimeMode:             "http_bridge",
		EntrypointRef:           "logo_export_bridge_v3",
		PermissionProfile:       "tenant_ops",
		SandboxRequired:         true,
		IsActive:                true,
		LifecycleStatus:         "inactive",
		RuntimeEnabled:          false,
		MinSupportedHostVersion: 1,
		MaxSupportedHostVersion: 5,
	})

	store.seedPermission(pluginPermissionRecord{
		PluginKey:         "erp.logo_export",
		TenantID:          "tenant-b",
		PermissionProfile: "tenant_ops",
		Operation:         "execute",
		ResourceScope:     "tenant_runtime",
		Permitted:         true,
		DenialReason:      "",
	})

	store.seedSandbox(pluginSandboxRecord{
		PluginKey:         "erp.logo_export",
		TenantID:          "tenant-b",
		RuntimeMode:       "http_bridge",
		PermissionProfile: "tenant_ops",
		SandboxID:         "tenant_b_logo_export_sandbox",
		IsolationMode:     "tenant_namespace",
		NetworkPolicy:     "tenant_egress_only",
		TenantScoped:      true,
		Ready:             true,
		DenialReason:      "",
	})

	loadUsecase := NewLoadPluginUsecase(store)
	lifecycleUsecase := NewApplyPluginLifecycleUsecase(store)
	permissionUsecase := NewEvaluatePluginPermissionUsecase(store)
	sandboxUsecase := NewEnsurePluginSandboxUsecase(store)
	versionUsecase := NewCheckPluginVersionCompatibilityUsecase(store)

	loadUsecase.nowFn = store.nowFn
	lifecycleUsecase.nowFn = store.nowFn
	permissionUsecase.nowFn = store.nowFn
	sandboxUsecase.nowFn = store.nowFn
	versionUsecase.nowFn = store.nowFn

	tenantALoad, err := loadUsecase.Load(context.Background(), LoadPluginRequest{
		TenantID:    "tenant-a",
		PluginKey:   "erp.logo_export",
		RequestedBy: "worker-a",
	})
	if err != nil {
		t.Fatalf("tenant-a load hatasi: %v", err)
	}

	tenantBLoad, err := loadUsecase.Load(context.Background(), LoadPluginRequest{
		TenantID:    "tenant-b",
		PluginKey:   "erp.logo_export",
		RequestedBy: "worker-b",
	})
	if err != nil {
		t.Fatalf("tenant-b load hatasi: %v", err)
	}

	if tenantALoad.Version == tenantBLoad.Version {
		t.Fatalf("tenant bazli farkli plugin versiyonlari bekleniyordu")
	}

	_, err = lifecycleUsecase.Apply(context.Background(), ApplyPluginLifecycleRequest{
		TenantID:    "tenant-b",
		PluginKey:   "erp.logo_export",
		ActionType:  "activate",
		RequestedBy: "worker-b",
		Reason:      "tenant-b aktivasyonu",
	})
	if err != nil {
		t.Fatalf("tenant-b lifecycle hatasi: %v", err)
	}

	tenantBPermission, err := permissionUsecase.Evaluate(context.Background(), EvaluatePluginPermissionRequest{
		TenantID:          "tenant-b",
		PluginKey:         "erp.logo_export",
		PermissionProfile: "tenant_ops",
		Operation:         "execute",
		ResourceScope:     "tenant_runtime",
		RequestedBy:       "worker-b",
	})
	if err != nil {
		t.Fatalf("tenant-b permission hatasi: %v", err)
	}

	if !tenantBPermission.Permitted {
		t.Fatalf("tenant-b permission izinli olmaliydi")
	}

	tenantBSandbox, err := sandboxUsecase.Ensure(context.Background(), EnsurePluginSandboxRequest{
		TenantID:          "tenant-b",
		PluginKey:         "erp.logo_export",
		RuntimeMode:       "http_bridge",
		PermissionProfile: "tenant_ops",
		RequestedBy:       "worker-b",
	})
	if err != nil {
		t.Fatalf("tenant-b sandbox hatasi: %v", err)
	}

	if !tenantBSandbox.Ready || tenantBSandbox.IsolationMode != "tenant_namespace" {
		t.Fatalf("tenant-b sandbox beklenen gibi degil")
	}

	tenantAVersion, err := versionUsecase.Check(context.Background(), CheckPluginVersionCompatibilityRequest{
		TenantID:       "tenant-a",
		PluginKey:      "erp.logo_export",
		PluginVersion:  2,
		RuntimeMode:    "wasm",
		HostAPIVersion: 3,
		RequestedBy:    "worker-a",
	})
	if err != nil {
		t.Fatalf("tenant-a version hatasi: %v", err)
	}

	tenantBVersion, err := versionUsecase.Check(context.Background(), CheckPluginVersionCompatibilityRequest{
		TenantID:       "tenant-b",
		PluginKey:      "erp.logo_export",
		PluginVersion:  3,
		RuntimeMode:    "http_bridge",
		HostAPIVersion: 4,
		RequestedBy:    "worker-b",
	})
	if err != nil {
		t.Fatalf("tenant-b version hatasi: %v", err)
	}

	if !tenantAVersion.Compatible || !tenantBVersion.Compatible {
		t.Fatalf("iki tenant icin de compatible bekleniyordu")
	}

	tenantASnapshot, ok := store.snapshotPlugin("tenant-a", "erp.logo_export")
	if !ok {
		t.Fatalf("tenant-a plugin snapshot bulunamadi")
	}

	tenantBSnapshot, ok := store.snapshotPlugin("tenant-b", "erp.logo_export")
	if !ok {
		t.Fatalf("tenant-b plugin snapshot bulunamadi")
	}

	if tenantASnapshot.RuntimeEnabled {
		t.Fatalf("tenant-a plugin durumu etkilenmemeliydi")
	}

	if !tenantBSnapshot.RuntimeEnabled || tenantBSnapshot.LifecycleStatus != "active" {
		t.Fatalf("tenant-b plugin active/runtime_enabled olmaliydi")
	}
}
