package domain

type AlisFaturaSatir struct {
	SatirID       string
	UrunID        string
	UrunKod       string
	UrunAdi       string
	Miktar        float64
	BirimFiyat    float64
	KdvOrani      float64
	SatirToplam   float64
	KdvTutari     float64
	GenelToplam   float64
}
