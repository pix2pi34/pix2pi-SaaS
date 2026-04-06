package domain

type ReportRecord struct {
	TenantID      string
	ReportKey     string
	ToplamBorc    float64
	ToplamAlacak  float64
	NetBakiye     float64
	KayitSayisi   int
}
