package tenantopening

import (
	"context"
	"sync"
)

type MemoryRepository struct {
	mu          sync.RWMutex
	Business    map[string]BusinessOnboardingRecord
	Configs     map[string]TenantConfigRecord
	Branches    map[string]BranchRecord
	Registers   map[string]RegisterRecord
	Roles       map[string]UserRoleAssignment
	AuditEvents []AuditEvent
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{
		Business:  map[string]BusinessOnboardingRecord{},
		Configs:   map[string]TenantConfigRecord{},
		Branches:  map[string]BranchRecord{},
		Registers: map[string]RegisterRecord{},
		Roles:     map[string]UserRoleAssignment{},
	}
}

func (r *MemoryRepository) SaveBusinessOnboarding(ctx context.Context, record BusinessOnboardingRecord) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.Business[record.TenantID] = record
	return nil
}

func (r *MemoryRepository) SaveTenantConfig(ctx context.Context, record TenantConfigRecord) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.Configs[record.TenantID] = record
	return nil
}

func (r *MemoryRepository) SaveBranch(ctx context.Context, record BranchRecord) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.Branches[record.BranchID] = record
	return nil
}

func (r *MemoryRepository) SaveRegister(ctx context.Context, record RegisterRecord) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.Registers[record.RegisterID] = record
	return nil
}

func (r *MemoryRepository) AssignUserRole(ctx context.Context, record UserRoleAssignment) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.Roles[record.TenantID+":"+record.UserID+":"+record.RoleCode] = record
	return nil
}

func (r *MemoryRepository) RecordAudit(ctx context.Context, event AuditEvent) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.AuditEvents = append(r.AuditEvents, event)
	return nil
}
