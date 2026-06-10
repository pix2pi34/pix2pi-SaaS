package serviceregistry

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ListVisibleServicesRequest struct {
	TenantID          string `json:"tenant_id,omitempty"`
	IncludeGlobal     bool   `json:"include_global"`
	ServiceKeyPrefix  string `json:"service_key_prefix,omitempty"`
	InstanceStatus    string `json:"instance_status,omitempty"`
	Limit             int    `json:"limit"`
}

type VisibleServiceInstance struct {
	ServiceID         string    `json:"service_id"`
	InstanceID        string    `json:"instance_id"`
	TenantID          string    `json:"tenant_id,omitempty"`
	ServiceKey        string    `json:"service_key"`
	DisplayName       string    `json:"display_name"`
	ServiceKind       string    `json:"service_kind"`
	VisibilityScope   string    `json:"visibility_scope"`
	InstanceKey       string    `json:"instance_key"`
	InstanceStatus    string    `json:"instance_status"`
	Host              string    `json:"host"`
	Port              int       `json:"port"`
	Version           string    `json:"version,omitempty"`
	LastHeartbeatAt   time.Time `json:"last_heartbeat_at"`
}

type ListVisibleServicesResponse struct {
	Items []VisibleServiceInstance `json:"items"`
	Count int                      `json:"count"`
}

func (r ListVisibleServicesRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if r.Limit < 1 || r.Limit > 500 {
		errs = append(errs, ValidationError{
			Field:   "limit",
			Message: "1-500 araliginda olmali",
		})
	}

	if strings.TrimSpace(r.InstanceStatus) != "" && !containsValue(allowedInstanceStatuses, strings.TrimSpace(r.InstanceStatus)) {
		errs = append(errs, ValidationError{
			Field:   "instance_status",
			Message: "desteklenmeyen deger",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

type ListVisibleServicesCommand struct {
	TenantID         string
	IncludeGlobal    bool
	ServiceKeyPrefix string
	InstanceStatus   string
	Limit            int
}

type VisibilityStore interface {
	ListVisibleServiceInstances(ctx context.Context, cmd ListVisibleServicesCommand) ([]VisibleServiceInstance, error)
}

type VisibilityUsecase struct {
	store VisibilityStore
}

func NewVisibilityUsecase(store VisibilityStore) *VisibilityUsecase {
	return &VisibilityUsecase{
		store: store,
	}
}

func (u *VisibilityUsecase) List(ctx context.Context, req ListVisibleServicesRequest) (ListVisibleServicesResponse, error) {
	if u == nil || u.store == nil {
		return ListVisibleServicesResponse{}, errors.New("visibility usecase hazir degil")
	}

	if err := req.Validate(); err != nil {
		return ListVisibleServicesResponse{}, err
	}

	items, err := u.store.ListVisibleServiceInstances(ctx, ListVisibleServicesCommand{
		TenantID:         strings.TrimSpace(req.TenantID),
		IncludeGlobal:    req.IncludeGlobal,
		ServiceKeyPrefix: strings.TrimSpace(req.ServiceKeyPrefix),
		InstanceStatus:   strings.TrimSpace(req.InstanceStatus),
		Limit:            req.Limit,
	})
	if err != nil {
		return ListVisibleServicesResponse{}, err
	}

	return ListVisibleServicesResponse{
		Items: items,
		Count: len(items),
	}, nil
}
