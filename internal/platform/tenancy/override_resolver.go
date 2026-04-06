package tenancy

type OverrideResolver struct {
	// tenantID -> Decision
	Overrides map[string]Decision
}

func NewOverrideResolver(overrides map[string]Decision) *OverrideResolver {
	return &OverrideResolver{Overrides: overrides}
}

func (r *OverrideResolver) Resolve(tenantID string) (Decision, bool, error) {
	if r.Overrides == nil {
		return Decision{}, false, nil
	}
	d, ok := r.Overrides[tenantID]
	if !ok {
		return Decision{}, false, nil
	}
	return d, true, nil
}
