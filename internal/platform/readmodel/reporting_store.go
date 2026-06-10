package readmodel

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

var (
	ErrNilProjectionContractRegistry = errors.New("readmodel: nil projection contract registry")
	ErrEmptyReportingDBDriver        = errors.New("readmodel: empty reporting db driver")
	ErrEmptyReportingDBHost          = errors.New("readmodel: empty reporting db host")
	ErrInvalidReportingDBPort        = errors.New("readmodel: invalid reporting db port")
	ErrEmptyReportingDBUser          = errors.New("readmodel: empty reporting db user")
	ErrEmptyReportingDBName          = errors.New("readmodel: empty reporting db name")
	ErrEmptyReportingDBSchema        = errors.New("readmodel: empty reporting db schema")
	ErrUnsupportedReportingDBDriver  = errors.New("readmodel: unsupported reporting db driver")
)

const (
	ReportingDriverPostgres = "postgres"
	ReportingDriverPGX      = "pgx"
)

type ReportingDBConfig struct {
	Driver   string
	Host     string
	Port     int
	User     string
	Password string
	DBName   string
	Schema   string
	SSLMode  string
}

func (c ReportingDBConfig) Validate() error {
	if strings.TrimSpace(c.Driver) == "" {
		return ErrEmptyReportingDBDriver
	}
	if strings.TrimSpace(c.Host) == "" {
		return ErrEmptyReportingDBHost
	}
	if c.Port <= 0 {
		return ErrInvalidReportingDBPort
	}
	if strings.TrimSpace(c.User) == "" {
		return ErrEmptyReportingDBUser
	}
	if strings.TrimSpace(c.DBName) == "" {
		return ErrEmptyReportingDBName
	}
	if strings.TrimSpace(c.Schema) == "" {
		return ErrEmptyReportingDBSchema
	}

	switch c.Driver {
	case ReportingDriverPostgres, ReportingDriverPGX:
	default:
		return ErrUnsupportedReportingDBDriver
	}

	if err := validateKeyPart(c.Driver); err != nil {
		return fmt.Errorf("driver: %w", err)
	}
	if err := validateKeyPart(c.Host); err != nil {
		return fmt.Errorf("host: %w", err)
	}
	if err := validateKeyPart(c.User); err != nil {
		return fmt.Errorf("user: %w", err)
	}
	if err := validateKeyPart(c.DBName); err != nil {
		return fmt.Errorf("db name: %w", err)
	}
	if err := validateKeyPart(c.Schema); err != nil {
		return fmt.Errorf("schema: %w", err)
	}

	sslMode := c.SSLMode
	if sslMode == "" {
		sslMode = "disable"
	}
	if err := validateKeyPart(sslMode); err != nil {
		return fmt.Errorf("sslmode: %w", err)
	}

	return nil
}

func (c ReportingDBConfig) DSN() (string, error) {
	if err := c.Validate(); err != nil {
		return "", err
	}

	sslMode := c.SSLMode
	if sslMode == "" {
		sslMode = "disable"
	}

	return fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s search_path=%s",
		c.Host,
		c.Port,
		c.User,
		c.Password,
		c.DBName,
		sslMode,
		c.Schema,
	), nil
}

type ProjectionRepositoryDescriptor struct {
	Name              string
	TableName         string
	FullTableName     string
	TenantColumn      string
	PrimaryKeyColumns []string
	VersionColumn     string
	UpdatedAtColumn   string
	SupportsRebuild   bool
}

func (d ProjectionRepositoryDescriptor) TenantQueryTarget() (TenantQueryTarget, error) {
	target := TenantQueryTarget{
		ProjectionName: d.Name,
		TableName:      d.TableName,
		FullTableName:  d.FullTableName,
		TenantColumn:   d.TenantColumn,
	}

	if err := target.Validate(); err != nil {
		return TenantQueryTarget{}, err
	}

	return target, nil
}

func (d ProjectionRepositoryDescriptor) TenantAccessPlan(
	tenantID string,
) (TenantQueryAccessPlan, error) {
	target, err := d.TenantQueryTarget()
	if err != nil {
		return TenantQueryAccessPlan{}, err
	}

	return BuildTenantQueryAccessPlan(tenantID, target)
}

type ReportingStore struct {
	config      ReportingDBConfig
	projections *ProjectionContractRegistry
}

func NewReportingStore(config ReportingDBConfig, projections *ProjectionContractRegistry) (*ReportingStore, error) {
	if projections == nil {
		return nil, ErrNilProjectionContractRegistry
	}
	if err := config.Validate(); err != nil {
		return nil, err
	}

	return &ReportingStore{
		config:      config,
		projections: projections,
	}, nil
}

func (s *ReportingStore) Ready() bool {
	return s != nil && s.projections != nil
}

func (s *ReportingStore) Config() ReportingDBConfig {
	if s == nil {
		return ReportingDBConfig{}
	}
	return s.config
}

func (s *ReportingStore) DSN() (string, error) {
	if s == nil {
		return "", ErrInvalidReportingDBPort
	}
	return s.config.DSN()
}

func (s *ReportingStore) ResolveProjectionDescriptor(name string) (ProjectionRepositoryDescriptor, error) {
	if s == nil {
		return ProjectionRepositoryDescriptor{}, ErrNilProjectionContractRegistry
	}

	schema, ok := s.projections.Get(name)
	if !ok {
		return ProjectionRepositoryDescriptor{}, fmt.Errorf("%w: %s", ErrUnknownProjectionSchema, name)
	}

	return ProjectionRepositoryDescriptor{
		Name:              schema.Name,
		TableName:         schema.TableName,
		FullTableName:     s.config.Schema + "." + schema.TableName,
		TenantColumn:      schema.TenantColumn,
		PrimaryKeyColumns: append([]string(nil), schema.PrimaryKeyColumns...),
		VersionColumn:     schema.VersionColumn,
		UpdatedAtColumn:   schema.UpdatedAtColumn,
		SupportsRebuild:   schema.SupportsRebuild,
	}, nil
}

func (s *ReportingStore) ListProjectionDescriptors() ([]ProjectionRepositoryDescriptor, error) {
	if s == nil {
		return nil, ErrNilProjectionContractRegistry
	}

	items := s.projections.List()
	result := make([]ProjectionRepositoryDescriptor, 0, len(items))

	for _, item := range items {
		desc, err := s.ResolveProjectionDescriptor(item.Name)
		if err != nil {
			return nil, err
		}
		result = append(result, desc)
	}

	sort.Slice(result, func(i, j int) bool {
		return result[i].Name < result[j].Name
	})

	return result, nil
}
