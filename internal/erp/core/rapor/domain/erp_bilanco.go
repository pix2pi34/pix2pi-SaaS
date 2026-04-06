package domain

type BilancoSatir struct {
	HesapKodu string
	HesapAdi  string
	Tutar     float64
	Tip       string
}

type Bilanco struct {
	AktifToplam float64
	PasifToplam float64
	Satirlar    []BilancoSatir
}
