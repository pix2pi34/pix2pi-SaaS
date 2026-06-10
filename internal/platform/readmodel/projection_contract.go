package readmodel

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

var (
	ErrEmptyProjectionTableName   = errors.New("readmodel: empty projection table name")
	ErrEmptyTenantColumn          = errors.New("readmodel: empty tenant column")
	ErrEmptyVersionColumn         = errors.New("readmodel: empty version column")
	ErrEmptyUpdatedAtColumn       = errors.New("readmodel: empty updated_at column")
	ErrEmptyPrimaryKeyColumns     = errors.New("readmodel: empty primary key columns")
	ErrDuplicateProjectionSchema  = errors.New("readmodel: duplicate projection schema")
	ErrUnknownProjectionSchema    = errors.New("readmodel: unknown projection schema")
	ErrDuplicatePrimaryKeyColumn  = errors.New("readmodel: duplicate primary key column")
)

type ProjectionSchema struct {
	Name              string
	TableName         string
	TenantColumn      string
	PrimaryKeyColumns []string
	VersionColumn     string
	UpdatedAtColumn   string
	SupportsRebuild   bool
	Description       string
}

func (s ProjectionSchema) Validate() error {
	if strings.TrimSpace(s.Name) == "" {
		return ErrEmptyProjectionName
	}
	if strings.TrimSpace(s.TableName) == "" {
		return ErrEmptyProjectionTableName
	}
	if strings.TrimSpace(s.TenantColumn) == "" {
		return ErrEmptyTenantColumn
	}
	if strings.TrimSpace(s.VersionColumn) == "" {
		return ErrEmptyVersionColumn
	}
	if strings.TrimSpace(s.UpdatedAtColumn) == "" {
		return ErrEmptyUpdatedAtColumn
	}
	if len(s.PrimaryKeyColumns) == 0 {
		return ErrEmptyPrimaryKeyColumns
	}

	if err := validateKeyPart(s.Name); err != nil {
		return fmt.Errorf("name: %w", err)
	}
	if err := validateKeyPart(s.TableName); err != nil {
		return fmt.Errorf("table name: %w", err)
	}
	if err := validateKeyPart(s.TenantColumn); err != nil {
		return fmt.Errorf("tenant column: %w", err)
	}
	if err := validateKeyPart(s.VersionColumn); err != nil {
		return fmt.Errorf("version column: %w", err)
	}
	if err := validateKeyPart(s.UpdatedAtColumn); err != nil {
		return fmt.Errorf("updated_at column: %w", err)
	}

	seen := make(map[string]struct{})
	for _, col := range s.PrimaryKeyColumns {
		if strings.TrimSpace(col) == "" {
			return ErrEmptyPrimaryKeyColumns
		}
		if err := validateKeyPart(col); err != nil {
			return fmt.Errorf("primary key column: %w", err)
		}
		if _, exists := seen[col]; exists {
			return ErrDuplicatePrimaryKeyColumn
		}
		seen[col] = struct{}{}
	}

	return nil
}

type ProjectionContractRegistry struct {
	items map[string]ProjectionSchema
}

func NewProjectionContractRegistry() *ProjectionContractRegistry {
	return &ProjectionContractRegistry{
		items: make(map[string]ProjectionSchema),
	}
}

func (r *ProjectionContractRegistry) Register(schema ProjectionSchema) error {
	if r == nil {
		return ErrNilHandlerRegistry
	}
	if err := schema.Validate(); err != nil {
		return err
	}
	if _, exists := r.items[schema.Name]; exists {
		return ErrDuplicateProjectionSchema
	}

	normalized := schema
	normalized.PrimaryKeyColumns = append([]string(nil), schema.PrimaryKeyColumns...)
	sort.Strings(normalized.PrimaryKeyColumns)

	r.items[schema.Name] = normalized
	return nil
}

func (r *ProjectionContractRegistry) MustRegister(schema ProjectionSchema) {
	if err := r.Register(schema); err != nil {
		panic(err)
	}
}

func (r *ProjectionContractRegistry) Get(name string) (ProjectionSchema, bool) {
	if r == nil {
		return ProjectionSchema{}, false
	}
	item, ok := r.items[name]
	return item, ok
}

func (r *ProjectionContractRegistry) List() []ProjectionSchema {
	if r == nil {
		return nil
	}

	result := make([]ProjectionSchema, 0, len(r.items))
	for _, item := range r.items {
		result = append(result, item)
	}

	sort.Slice(result, func(i, j int) bool {
		return result[i].Name < result[j].Name
	})

	return result
}

func (r *ProjectionContractRegistry) MustGet(name string) ProjectionSchema {
	item, ok := r.Get(name)
	if !ok {
		panic(fmt.Errorf("%w: %s", ErrUnknownProjectionSchema, name))
	}
	return item
}

func DefaultProjectionContracts() *ProjectionContractRegistry {
	registry := NewProjectionContractRegistry()

	registry.MustRegister(ProjectionSchema{
		Name:              "sales_summary",
		TableName:         "rm_sales_summary",
		TenantColumn:      "tenant_id",
		PrimaryKeyColumns: []string{"tenant_id", "sale_id"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "satis ozeti projection kontrati",
	})

	registry.MustRegister(ProjectionSchema{
		Name:              "dashboard_kpi",
		TableName:         "rm_dashboard_kpi",
		TenantColumn:      "tenant_id",
		PrimaryKeyColumns: []string{"tenant_id", "metric_key"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "dashboard kpi projection kontrati",
	})

	registry.MustRegister(ProjectionSchema{
		Name:              "sales_reports",
		TableName:         "rm_sales_reports",
		TenantColumn:      "tenant_id",
		PrimaryKeyColumns: []string{"tenant_id", "report_key"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   true,
		Description:       "raporlama projection kontrati",
	})

	return registry
}
