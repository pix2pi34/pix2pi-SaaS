package tenancy

type DefaultResolver struct{}

func NewDefaultResolver() *DefaultResolver { return &DefaultResolver{} }

func (r *DefaultResolver) Resolve(tenantID string) (Decision, bool, error) {
	// Default: shared schema (tenant_<id>)
	return Decision{
		Strategy: StrategySharedSchema,
		Schema:   "tenant_" + tenantID,
	}, true, nil
}
