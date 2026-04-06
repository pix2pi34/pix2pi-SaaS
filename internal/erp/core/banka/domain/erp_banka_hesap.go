package domain

type BankaHesap struct {
	HesapID    string
	Kod        string
	BankaAdi   string
	SubeAdi    string
	Iban       string
	SwiftKodu  string
	ParaBirimi string
	Aktif      bool
}
