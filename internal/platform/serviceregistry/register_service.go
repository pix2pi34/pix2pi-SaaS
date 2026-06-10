package serviceregistry

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type RegisterServiceStore interface {
	UpsertServiceInstance(ctx context.Context, cmd UpsertServiceInstanceCommand) (UpsertServiceInstanceResult, error)
}

type UpsertServiceInstanceCommand struct {
	TenantID                 string
	ServiceKey               string
	DisplayName              string
	ServiceKind              string
	VisibilityScope          string
	Protocol                 string
	BasePath                 string
	HealthPath               string
	DefaultPort              int
	OwnerTeam                string
	ServiceMetadata          map[string]any
	InstanceKey              string
	NodeName                 string
	Host                     string
	Port                     int
	Version                  string
	Status                   string
	HeartbeatIntervalSeconds int
	InstanceMetadata         map[string]any
}

type UpsertServiceInstanceResult struct {
	ServiceID   string
	InstanceID  string
	ServiceKey  string
	InstanceKey string
}

type RegisterServiceUsecase struct {
	store RegisterServiceStore
	nowFn func() time.Time
}

func NewRegisterServiceUsecase(store RegisterServiceStore) *RegisterServiceUsecase {
	return &RegisterServiceUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *RegisterServiceUsecase) Register(ctx context.Context, req RegisterServiceRequest) (RegisterServiceResponse, error) {
	if u == nil || u.store == nil {
		return RegisterServiceResponse{}, errors.New("register service usecase hazir degil")
	}

	if err := req.Validate(); err != nil {
		return RegisterServiceResponse{}, err
	}

	cmd := UpsertServiceInstanceCommand{
		TenantID:                 strings.TrimSpace(req.TenantID),
		ServiceKey:               strings.TrimSpace(req.ServiceKey),
		DisplayName:              strings.TrimSpace(req.DisplayName),
		ServiceKind:              strings.TrimSpace(req.ServiceKind),
		VisibilityScope:          strings.TrimSpace(req.VisibilityScope),
		Protocol:                 strings.TrimSpace(req.Protocol),
		BasePath:                 strings.TrimSpace(req.BasePath),
		HealthPath:               strings.TrimSpace(req.HealthPath),
		DefaultPort:              req.DefaultPort,
		OwnerTeam:                strings.TrimSpace(req.OwnerTeam),
		ServiceMetadata:          cloneMap(req.Metadata),
		InstanceKey:              strings.TrimSpace(req.InstanceKey),
		NodeName:                 strings.TrimSpace(req.NodeName),
		Host:                     strings.TrimSpace(req.Host),
		Port:                     req.Port,
		Version:                  strings.TrimSpace(req.Version),
		Status:                   strings.TrimSpace(req.Status),
		HeartbeatIntervalSeconds: req.HeartbeatIntervalSeconds,
		InstanceMetadata:         cloneMap(req.InstanceMetadata),
	}

	result, err := u.store.UpsertServiceInstance(ctx, cmd)
	if err != nil {
		return RegisterServiceResponse{}, err
	}

	serviceID := result.ServiceID
	if serviceID == "" {
		serviceID = uuid.NewString()
	}

	instanceID := result.InstanceID
	if instanceID == "" {
		instanceID = uuid.NewString()
	}

	serviceKey := result.ServiceKey
	if serviceKey == "" {
		serviceKey = cmd.ServiceKey
	}

	instanceKey := result.InstanceKey
	if instanceKey == "" {
		instanceKey = cmd.InstanceKey
	}

	return RegisterServiceResponse{
		ServiceID:    serviceID,
		InstanceID:   instanceID,
		ServiceKey:   serviceKey,
		InstanceKey:  instanceKey,
		RegisteredAt: u.nowFn().UTC(),
	}, nil
}

func cloneMap(in map[string]any) map[string]any {
	if len(in) == 0 {
		return map[string]any{}
	}

	out := make(map[string]any, len(in))
	for k, v := range in {
		out[k] = v
	}

	return out
}
