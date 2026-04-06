package domain

type SatisFaturaSatir struct {
	SatirID       string
	UrunKod       string
	UrunAdi       string
	Miktar        float64
	BirimFiyat    float64
	IskontoOrani  float64
	BrutToplam    float64
	IskontoTutari float64
	NetToplam     float64
	KdvOrani      float64
	KdvTutari     float64
	GenelToplam   float64
}
