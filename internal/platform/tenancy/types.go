package tenancy

type Strategy string

const (
	StrategySharedSchema Strategy = "shared_schema"
	StrategyDedicatedDB  Strategy = "dedicated_db"
)

type Decision struct {
	Strategy Strategy
	// Shared schema için
	Schema string
	// Dedicated DB için (ileride)
	DSN string
}

type Resolver interface {
	Resolve(tenantID string) (Decision, bool, error)
}
