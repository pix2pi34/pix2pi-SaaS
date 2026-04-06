package tenancy

type ChainResolver struct {
	Resolvers []Resolver
}

func NewChain(resolvers ...Resolver) *ChainResolver {
	return &ChainResolver{Resolvers: resolvers}
}

func (r *ChainResolver) Resolve(tenantID string) (Decision, bool, error) {
	for _, res := range r.Resolvers {
		d, ok, err := res.Resolve(tenantID)
		if err != nil {
			return Decision{}, false, err
		}
		if ok {
			return d, true, nil
		}
	}
	return Decision{}, false, nil
}
