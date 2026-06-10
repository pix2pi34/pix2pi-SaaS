package readmodel

import (
	"context"
	"errors"
	"fmt"
	"strings"
)

var (
	ErrNilRebuildCoordinator         = errors.New("readmodel: nil rebuild coordinator")
	ErrNilRebuildTracker             = errors.New("readmodel: nil rebuild tracker")
	ErrInvalidRebuildMode            = errors.New("readmodel: invalid rebuild mode")
	ErrProjectionRebuildNotSupported = errors.New("readmodel: projection rebuild not supported")
	ErrEmptyReplayFromEventID        = errors.New("readmodel: empty replay from event id")
	ErrInvalidRebuildState           = errors.New("readmodel: invalid rebuild state")
)

type RebuildMode string

const (
	RebuildModeTruncateReplay RebuildMode = "truncate_replay"
	RebuildModeReplayFromEvent RebuildMode = "replay_from_event"
)

type RebuildState string

const (
	RebuildStatePlanned   RebuildState = "planned"
	RebuildStateRunning   RebuildState = "running"
	RebuildStateCompleted RebuildState = "completed"
	RebuildStateFailed    RebuildState = "failed"
)

type ProjectionRebuildRequest struct {
	TenantID          string
	Projection        string
	Mode              RebuildMode
	ReplayFromEventID string
	Reason            string
}

func (r ProjectionRebuildRequest) Validate() error {
	if strings.TrimSpace(r.TenantID) == "" {
		return ErrEmptyTenantID
	}
	if strings.TrimSpace(r.Projection) == "" {
		return ErrEmptyProjectionName
	}
	if err := validateKeyPart(r.TenantID); err != nil {
		return fmt.Errorf("tenant id: %w", err)
	}
	if err := validateKeyPart(r.Projection); err != nil {
		return fmt.Errorf("projection: %w", err)
	}

	switch r.Mode {
	case RebuildModeTruncateReplay:
	case RebuildModeReplayFromEvent:
		if strings.TrimSpace(r.ReplayFromEventID) == "" {
			return ErrEmptyReplayFromEventID
		}
		if err := validateKeyPart(r.ReplayFromEventID); err != nil {
			return fmt.Errorf("replay from event id: %w", err)
		}
	default:
		return ErrInvalidRebuildMode
	}

	return nil
}

type ProjectionRebuildPlan struct {
	TenantID             string
	Projection           string
	TableName            string
	FullTableName        string
	Mode                 RebuildMode
	ReplayFromEventID    string
	TruncateBeforeReplay bool
	RequiresReplay       bool
	SupportsRebuild      bool
}

type RebuildTracker interface {
	Mark(ctx context.Context, plan ProjectionRebuildPlan, state RebuildState, detail string) error
}

type ProjectionRebuildCoordinator struct {
	store   *ReportingStore
	tracker RebuildTracker
}

func NewProjectionRebuildCoordinator(store *ReportingStore, tracker RebuildTracker) (*ProjectionRebuildCoordinator, error) {
	if store == nil {
		return nil, ErrNilProjectionContractRegistry
	}
	if tracker == nil {
		return nil, ErrNilRebuildTracker
	}

	return &ProjectionRebuildCoordinator{
		store:   store,
		tracker: tracker,
	}, nil
}

func (c *ProjectionRebuildCoordinator) Plan(req ProjectionRebuildRequest) (ProjectionRebuildPlan, error) {
	if c == nil {
		return ProjectionRebuildPlan{}, ErrNilRebuildCoordinator
	}
	if err := req.Validate(); err != nil {
		return ProjectionRebuildPlan{}, err
	}

	desc, err := c.store.ResolveProjectionDescriptor(req.Projection)
	if err != nil {
		return ProjectionRebuildPlan{}, err
	}
	if !desc.SupportsRebuild {
		return ProjectionRebuildPlan{}, fmt.Errorf("%w: %s", ErrProjectionRebuildNotSupported, req.Projection)
	}

	plan := ProjectionRebuildPlan{
		TenantID:          req.TenantID,
		Projection:        req.Projection,
		TableName:         desc.TableName,
		FullTableName:     desc.FullTableName,
		Mode:              req.Mode,
		ReplayFromEventID: req.ReplayFromEventID,
		SupportsRebuild:   desc.SupportsRebuild,
		RequiresReplay:    true,
	}

	switch req.Mode {
	case RebuildModeTruncateReplay:
		plan.TruncateBeforeReplay = true
	case RebuildModeReplayFromEvent:
		plan.TruncateBeforeReplay = false
	default:
		return ProjectionRebuildPlan{}, ErrInvalidRebuildMode
	}

	return plan, nil
}

func (c *ProjectionRebuildCoordinator) MarkPlanned(ctx context.Context, plan ProjectionRebuildPlan, detail string) error {
	return c.mark(ctx, plan, RebuildStatePlanned, detail)
}

func (c *ProjectionRebuildCoordinator) MarkRunning(ctx context.Context, plan ProjectionRebuildPlan, detail string) error {
	return c.mark(ctx, plan, RebuildStateRunning, detail)
}

func (c *ProjectionRebuildCoordinator) MarkCompleted(ctx context.Context, plan ProjectionRebuildPlan, detail string) error {
	return c.mark(ctx, plan, RebuildStateCompleted, detail)
}

func (c *ProjectionRebuildCoordinator) MarkFailed(ctx context.Context, plan ProjectionRebuildPlan, detail string) error {
	return c.mark(ctx, plan, RebuildStateFailed, detail)
}

func (c *ProjectionRebuildCoordinator) mark(ctx context.Context, plan ProjectionRebuildPlan, state RebuildState, detail string) error {
	if c == nil {
		return ErrNilRebuildCoordinator
	}

	switch state {
	case RebuildStatePlanned, RebuildStateRunning, RebuildStateCompleted, RebuildStateFailed:
	default:
		return ErrInvalidRebuildState
	}

	return c.tracker.Mark(ctx, plan, state, detail)
}
