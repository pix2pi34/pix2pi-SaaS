package domain

type QuotaRecord struct {
	TenantID    string
	GunlukLimit int
	Kullanilan  int
}
