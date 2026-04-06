package tenancy

// DBResolver: ileride tenants tablosundan strategy okuyacak.
// Şimdilik "bulamadım" döner, zincir default'a düşer.
type DBResolver struct{}

func NewDBResolver() *DBResolver { return &DBResolver{} }

func (r *DBResolver) Resolve(tenantID string) (Decision, bool, error) {
	// TODO: control-plane DB'den tenants.storage_strategy oku
	return Decision{}, false, nil
}
