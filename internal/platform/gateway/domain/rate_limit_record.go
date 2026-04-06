package domain

type RateLimitRecord struct {
	TenantID      string
	DakikaLimiti  int
	Kullanilan    int
}
