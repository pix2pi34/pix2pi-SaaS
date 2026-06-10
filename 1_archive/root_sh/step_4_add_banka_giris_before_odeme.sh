#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

python3 - <<'PY'
from pathlib import Path
p = Path("cmd/erp/core/ufk/erp_ufk_main.go")
text = p.read_text()

needle = '''err = cariHesapService.CariHareketEkle(
		caridomain.CariHareket{
			HareketID:       "cari-borc-002",'''

insert = '''err = bankaService.BankaHareketEkle(
		bankadomain.BankaHareket{
			HareketID:       "banka-baslangic-001",
			HesapID:         "banka-merkez-001",
			HareketTip:      bankadomain.BankaHareketTipGiris,
			Tutar:           5000.00,
			BelgeNo:         "BANKA-BASLANGIC-0001",
			ReferansID:      "banka-baslangic-0001",
			Aciklama:        "baslangic banka bakiyesi",
			OlusturmaTarihi: time.Date(2026, 3, 12, 9, 15, 0, 0, time.UTC),
		},
	)
	if err != nil {
		panic(err)
	}

''' + needle

text = text.replace(needle, insert, 1)
text = text.replace(
    '"fmt"\n\t"time"\n\n\tbankaservice',
    '"fmt"\n\t"time"\n\n\tbankadomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/banka/domain"\n\tbankaservice'
)
p.write_text(text)
PY

echo "OK ✅ banka baslangic girisi eklendi"
