# FAZ 4C — Gercek Pilot Execution / Runtime Completion

## 4C-1 — Pilot Execution Master Plan / Scope Freeze

### 4C-1.1 — Pilot isletme secimi

Durum: SEKTOR_SECILDI
Pilot sektor: OTO YEDEK PARCA
Pilot secim karari: OTO_YEDEK_PARCA_PROFILE_SELECTED
Scope freeze durumu: PARTIAL_FREEZE

---

## 1. Amac

Bu adimin amaci Pix2pi gercek pilot uygulamasi icin ilk pilot profilini sabitlemektir.

Ilk pilot sektor olarak:

**OTO YEDEK PARCA**

secilmistir.

Bu secim Pix2pi icin stratejik olarak dogrudur. Cunku oto yedek parca isletmesi:

1. Stok takibini zorlar.
2. Urun karti kalitesini test eder.
3. Cari satis/alacak akisini test eder.
4. Parca arama ihtiyacini ortaya cikarir.
5. Esdeger parca mantigini ileride dogurur.
6. ERP ve POS hattini gercek is uzerinden test ettirir.

---

## 2. Pilot profil karari

4C-1.1 icin secilen pilot profil:

- Sektor: Oto yedek parca
- Is modeli: Stoklu perakende / toptan karisik satis
- Sube sayisi: Ilk pilot icin 1 sube tercih edilir
- Kullanici sayisi: 1-5
- Gunluk tahmini islem: 20-300 arasi
- Stok kalemi: 100-5000 arasi kabul edilebilir
- Cari ihtiyaci: Var
- POS ihtiyaci: Var veya yakin vadede olacak
- ERP ihtiyaci: Urun, stok, cari, satis, rapor
- Muhasebe entegrasyonu: Ilk pilotta zorunlu degil
- E-belge entegrasyonu: Ilk pilotta zorunlu degil

---

## 3. Neden oto yedek parca?

Oto yedek parca pilotu Pix2pi icin normal market pilotuna gore daha degerlidir.

Cunku bu sektorde:

1. Bir urun birden fazla araca uyabilir.
2. Bir parcanin OEM kodu olabilir.
3. Bir parcanin esdegerleri olabilir.
4. Stokta olmayan parca icin alternatif onerme ihtiyaci dogar.
5. Cari musteri ve tedarikci iliskisi onemlidir.
6. Kasa satisi ile cari satis birlikte gorulebilir.
7. Stok hareketleri kritik hale gelir.
8. Yanlis urun / yanlis stok ciddi operasyonel hata uretir.

Bu yuzden ilk pilot, Pix2pi'nin gercek ticaret motorunu daha iyi test eder.

---

## 4. Ilk pilotta dahil olan kapsam

Oto yedek parca pilotunda 4C kapsaminda dahil olanlar:

1. Pilot tenant kurulumu
2. Gercek isletme bilgileri
3. Gercek kullanici ve rol atamalari
4. Cari kart acilisi
5. Tedarikci / musteri ayrimi
6. Urun karti acilisi
7. Stok karti acilisi
8. Baslangic stok girisi veya import hazirligi
9. Satis akisi
10. Stoktan dusme kontrolu
11. Cari hareket kontrolu
12. Basit rapor / kontrol listesi
13. UAT geri bildirim kaydi
14. Bug / blocker listesi
15. Tenant izolasyon final pilot kontrolu
16. Business chain final validation
17. Go / No-Go karari

---

## 5. Ilk pilotta kapsam disi kalanlar

Ilk oto yedek parca pilotunda kapsam disi kalacaklar:

1. Tam TECDOC benzeri arac-parca motoru
2. Canli OEM veritabani entegrasyonu
3. Canli e-Fatura / e-Arsiv zorunlulugu
4. Banka / sanal POS canli tahsilat entegrasyonu
5. Muhasebe programlarina canli export
6. Cok subeli operasyon
7. Gelismis depo / raf / lokasyon yonetimi
8. Marketplace / aggregator akisi
9. Mobil uygulama final deneyimi
10. Ozel musteriye gore mimari kirma

Not:
Parca uyumlulugu konusu ileride ayri modul olarak ele alinacak.
Ilk pilotta bu konu sadece veri alanlari ve ihtiyac notu seviyesinde tutulacak.

---

## 6. Oto yedek parca icin minimum veri alanlari

Ilk pilotta urun/stok tarafinda su alanlar yeterli kabul edilir:

| Alan | Durum | Not |
|------|-------|-----|
| urun_adi | Zorunlu | Parca adi |
| stok_kodu | Zorunlu | Isletme ic kodu |
| barkod | Opsiyonel | Varsa alinir |
| marka | Opsiyonel | Parca markasi |
| kategori | Opsiyonel | Filtre, fren, motor vb. |
| alis_fiyati | Opsiyonel | Ilk pilotta gerekirse |
| satis_fiyati | Zorunlu | Satis testi icin |
| kdv_orani | Zorunlu | Finansal test icin |
| stok_miktari | Zorunlu | Stok dusme testi icin |
| minimum_stok | Opsiyonel | Alarm icin ileride |
| arac_uyum_notu | Opsiyonel | Ilk pilotta serbest not |
| oem_kodu | Opsiyonel | Ilk pilotta varsa |
| esdeger_kod | Opsiyonel | Ilk pilotta varsa |

---

## 7. Oto yedek parca pilot riskleri

| Risk | Seviye | Onlem |
|------|--------|-------|
| Parca uyumlulugu karmasasi | Yuksek | Ilk pilotta not alani seviyesinde tutulacak |
| Urun kartlari eksik/duzensiz | Yuksek | Baslangic veri sablonu hazirlanacak |
| Stok sayimi hatali olabilir | Orta | Ilk stok importu kontrollu yapilacak |
| Cari/veresiye satis karisik olabilir | Orta | Basit cari akisi ile baslanacak |
| Kullanici ERP disiplinine alisik olmayabilir | Orta | UAT adimlari sade tutulacak |
| Ozel istekler kapsami sisirebilir | Yuksek | Scope disi liste kabul ettirilecek |

---

## 8. Pilot aday tablosu

| No | Isletme adi | Sektor | Sube | Kullanici | Gunluk islem | Stok kalemi | POS ihtiyaci | Cari ihtiyaci | Risk | Karar |
|---:|-------------|--------|------|-----------|--------------|-------------|-------------|---------------|------|-------|
| 1 | PENDING | Oto yedek parca | PENDING | PENDING | PENDING | PENDING | PENDING | VAR | ORTA/YUKSEK | ANA_ADAY |
| 2 | PENDING | Oto yedek parca | PENDING | PENDING | PENDING | PENDING | PENDING | VAR | ORTA | YEDEK_ADAY |
| 3 | PENDING | Oto yedek parca | PENDING | PENDING | PENDING | PENDING | PENDING | VAR | ORTA | YEDEK_ADAY |

---

## 9. Secilecek pilot icin doldurulacak alanlar

Pilot isletme adi:
[ PENDING ]

Yetkili kisi:
[ PENDING ]

Telefon / iletisim:
[ PENDING ]

Sektor:
[ OTO YEDEK PARCA ]

Kullanici sayisi:
[ PENDING ]

Sube sayisi:
[ PENDING ]

Gunluk tahmini islem:
[ PENDING ]

Stok kalemi:
[ PENDING ]

Cari sayisi:
[ PENDING ]

Ilk pilotta kullanilacak moduller:
[ Cari, Urun, Stok, Satis, Rapor, UAT ]

Kapsam disi kabul edildi mi:
[ PENDING ]

UAT sorumlusu:
[ PENDING ]

Go / No-Go karar yetkilisi:
[ PENDING ]

---

## 10. 4C-1.1B exit gate

4C-1.1B kapanis karari:

- 4C_1_1_SELECTED_SECTOR=OTO_YEDEK_PARCA
- 4C_1_1_PROFILE_FREEZE_STATUS=PASS
- 4C_1_1_BUSINESS_NAME_STATUS=PENDING
- 4C_1_1_SCOPE_FREEZE_STATUS=PARTIAL
- 4C_1_1_NEXT_STEP_READY=YES

Sonraki adim:
4C-1.1C — Gercek pilot isletme bilgilerini doldurma

---

## 11. Pazaryeri entegrasyonu kapsam karari

Karar:
Pazaryeri entegrasyonu FAZ 4C icinde canli entegrasyon olarak yapilmayacak.

FAZ 4C icinde sadece pazaryeri entegrasyonu icin discovery ve gelecek faz hazirligi yapilacak.

---

### 11.1 FAZ 4C icinde dahil olan hazirliklar

FAZ 4C icinde sadece su hazirliklar yapilabilir:

1. Satis kanali ihtiyacinin not edilmesi
2. Siparis kaynagi alan ihtiyacinin not edilmesi
3. Pazaryeri kaynakli stok/fiyat/siparis/iade ihtiyacinin analiz edilmesi
4. Oto yedek parca isletmesinin pazaryeri kullanim durumunun sorulmasi
5. Gelecek faz icin entegrasyon backlog maddelerinin ayrilmasi

---

### 11.2 FAZ 4C icinde kapsam disi kalanlar

FAZ 4C icinde asagidakiler yapilmayacak:

1. Trendyol canli API entegrasyonu
2. Hepsiburada canli API entegrasyonu
3. N11 canli API entegrasyonu
4. Amazon canli API entegrasyonu
5. Pazaryeri siparis cekme runtime'i
6. Pazaryeri stok senkron runtime'i
7. Pazaryeri fiyat senkron runtime'i
8. Pazaryeri iade runtime'i
9. Kargo entegrasyonu
10. Pazaryeri komisyon muhasebesi
11. Pix2pi kendi pazaryeri / aggregator canli modulu

---

### 11.3 Gelecek faz karari

Pazaryeri entegrasyonu ayri bir faz olarak ele alinacak.

Onerilen gelecek faz adi:

FAZ 4D — Channel / Marketplace Integrations

Bu fazda ele alinacak ana basliklar:

1. External sales channel model
2. Marketplace credential vault
3. Product listing mapping
4. Stock sync
5. Price sync
6. Order import
7. Return / cancellation flow
8. Cargo status flow
9. Commission accounting
10. Marketplace webhook engine
11. Marketplace error queue
12. Marketplace replay / retry
13. Tenant-based integration isolation

---

### 11.4 Scope guard status

4C_MARKETPLACE_LIVE_INTEGRATION=NO
4C_MARKETPLACE_DISCOVERY_ONLY=YES
4C_MARKETPLACE_SCOPE_GUARD=PASS
FUTURE_MARKETPLACE_PHASE=FAZ_4D_CHANNEL_MARKETPLACE_INTEGRATIONS
