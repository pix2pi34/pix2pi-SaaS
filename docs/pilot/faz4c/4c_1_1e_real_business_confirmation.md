# FAZ 4C — 4C-1.1E Real Business Confirmation

## Blok

4C-1.1E — Gercek pilot isletme bilgileri confirmation

## Durum

4C_1_1E_CONFIRMATION_DOC_STATUS=CREATED
4C_1_1E_REAL_BUSINESS_VALUES_STATUS=PENDING
4C_1_1E_SCOPE_ACCEPTANCE_STATUS=PENDING
4C_1_1E_NEXT_STEP_READY=NO

---

## 1. Secilen pilot profili

Pilot sektor:
OTO YEDEK PARCA

Pilot profil status:
PASS

Pazaryeri entegrasyonu:
FAZ 4D'ye ayrildi

FAZ 4C pazaryeri status:
DISCOVERY_ONLY

---

## 2. Gercek isletme bilgileri

Bu alanlar gercek pilot isletme belirlendiginde doldurulacak.

Pilot isletme adi:
[ PENDING ]

Yetkili kisi:
[ PENDING ]

Yetkili telefon:
[ PENDING ]

Yetkili email:
[ PENDING ]

Adres:
[ PENDING ]

Il:
[ PENDING ]

Ilce:
[ PENDING ]

Vergi no:
[ PENDING ]

Vergi dairesi:
[ PENDING ]

---

## 3. Operasyon bilgileri

Sube sayisi:
[ PENDING ]

Kullanici sayisi:
[ PENDING ]

Gunluk tahmini satis/islem:
[ PENDING ]

Tahmini stok kalemi:
[ PENDING ]

Tahmini cari sayisi:
[ PENDING ]

Tahmini tedarikci sayisi:
[ PENDING ]

Mevcut kullandigi program:
[ PENDING ]

Excel urun/stok verisi var mi:
[ PENDING ]

---

## 4. Oto yedek parca ozel bilgiler

OEM kodu kullaniyor mu:
[ PENDING ]

Esdeger parca mantigi var mi:
[ PENDING ]

Ayni parca birden fazla araca uyuyor mu:
[ PENDING ]

Arac marka/model bazli arama ihtiyaci var mi:
[ PENDING ]

Barkod kullaniyor mu:
[ PENDING ]

Raf/lokasyon takibi var mi:
[ PENDING ]

---

## 5. FAZ 4C kapsam kabul alanlari

Asagidaki kararlar pilot isletmeye net anlatilacak.

Canli pazaryeri entegrasyonu FAZ 4C disi kabul edildi mi:
[ PENDING ]

Canli e-Fatura/e-Arsiv zorunlu degil kabul edildi mi:
[ PENDING ]

Canli banka/sanal POS entegrasyonu FAZ 4C disi kabul edildi mi:
[ PENDING ]

Ilk pilotun urun/stok/cari/satis/UAT odakli oldugu kabul edildi mi:
[ PENDING ]

Ozel isteklerin bugun icin scope disi tutulacagi kabul edildi mi:
[ PENDING ]

---

## 6. UAT ve karar yetkilileri

UAT geri bildirim sorumlusu:
[ PENDING ]

Go / No-Go karar yetkilisi:
[ PENDING ]

Pix2pi teknik takip sorumlusu:
[ PENDING ]

Pilot baslangic hedef tarihi:
[ PENDING ]

Pilot hedef kapanis tarihi:
[ PENDING ]

---

## 7. Eksik bilgi kontrol listesi

4C-1.1E tam PASS olmasi icin su bilgiler doldurulmalidir:

- Pilot isletme adi
- Yetkili kisi
- Yetkili telefon
- Sube sayisi
- Kullanici sayisi
- Tahmini stok kalemi
- Tahmini cari sayisi
- Mevcut kullandigi program
- Scope kabul alanlari
- UAT sorumlusu
- Go / No-Go karar yetkilisi

---

## 8. Exit gate

Gercek bilgiler doldurulmadan bu adim PASS olmaz.

Mevcut karar:

4C_1_1E_CONFIRMATION_DOC_STATUS=PASS
4C_1_1E_REAL_BUSINESS_VALUES_STATUS=PENDING
4C_1_1E_SCOPE_ACCEPTANCE_STATUS=PENDING
4C_1_1E_NEXT_STEP_READY=NO

Gercek bilgiler doldurulduktan sonraki hedef karar:

4C_1_1E_REAL_BUSINESS_VALUES_STATUS=PASS
4C_1_1E_SCOPE_ACCEPTANCE_STATUS=PASS
4C_1_1E_NEXT_STEP_READY=YES

Sonraki adim:
4C-1.1F — 4C-1.1 Final Closure / Pilot Business Selected
