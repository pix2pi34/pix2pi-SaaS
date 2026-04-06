package domain

type GelirTablosuSatir struct {
	HesapKodu string
	HesapAdi  string
	Tutar     float64
	Tip       string
}

type GelirTablosu struct {
	GelirlerToplami float64
	GiderlerToplami float64
	NetSonuc        float64
	Satirlar        []GelirTablosuSatir
}
