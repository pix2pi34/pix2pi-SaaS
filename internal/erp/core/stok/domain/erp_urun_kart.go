package domain

type UrunKart struct {
	UrunID      string
	UrunKod     string
	UrunAdi     string
	Birim       string
	ParaBirimi  string
	KdvOrani    float64
	AlisFiyati  float64
	SatisFiyati float64
	Aktif       bool
}
