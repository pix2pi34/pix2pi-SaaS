package domain

const (
	CariTipMusteri   = "musteri"
	CariTipTedarikci = "tedarikci"
)

type CariHesap struct {
	HesapID      string
	TenantID     string
	TenantUUID   string
	CariTip      string
	Kod          string
	Unvan        string
	ParaBirimi   string
	VergiNo      string
	VergiDairesi string
	MersisNo     string
	Adres        string
	Telefon      string
	Email        string
	AcikBakiye   float64
}
