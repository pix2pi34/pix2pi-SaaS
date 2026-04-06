package domain

import "time"

type AlisFatura struct {
	FaturaID        string
	FaturaNo        string
	CariHesapID     string
	ParaBirimi      string
	AraToplam       float64
	KdvToplam       float64
	GenelToplam     float64
	OlusturmaTarihi time.Time
}
