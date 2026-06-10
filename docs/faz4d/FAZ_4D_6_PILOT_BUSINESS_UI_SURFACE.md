# FAZ 4D-6 — Pilot business UI surface

## 1. Amaç

Bu adımın amacı, pilot işletmenin göreceği ilk iş yüzeyini tanımlamak ve repo içinde temel bir pilot business UI dosyası oluşturmaktır.

Bu adım production panel finali değildir.

Bu adımın hedefi:
- pilot işletmeye ana iş zincirini görünür yapmak,
- erişim/tenant durumunu yüzeyde göstermek,
- cari/müşteri, ürün/stok, satış/sipariş, ERP apply ve raporlama alanlarını tek pilot yüzeyde toplamak,
- oto yedek parça özel UI akışına geçiş kapısını hazırlamak,
- mobile-ready PWA aşamasına uyumlu temel yüzey oluşturmaktır.

## 2. Giriş Şartı

FAZ_4D_1_FINAL_STATUS=PASS ✅
FAZ_4D_1_SEAL_STATUS=SEALED ✅
FAZ_4D_2_FINAL_STATUS=PASS ✅
FAZ_4D_2_SEAL_STATUS=SEALED ✅
FAZ_4D_3_FINAL_STATUS=PASS ✅
FAZ_4D_3_SEAL_STATUS=SEALED ✅
FAZ_4D_4_FINAL_STATUS=PASS ✅
FAZ_4D_4_SEAL_STATUS=SEALED ✅
FAZ_4D_5_FINAL_STATUS=PASS ✅
FAZ_4D_5_SEAL_STATUS=SEALED ✅
FAZ_4D_6_READY=YES ✅

## 3. Pilot UI Surface Kararları

| No | Karar | Açıklama | Durum |
|---:|---|---|---|
| 1 | Pilot dashboard tek yüzeyle başlar | Pilot kullanıcı dağınık menülerle başlamaz | ACCEPTED |
| 2 | Tenant/access durumu görünür olur | Kullanıcı hangi tenant bağlamında olduğunu görür | ACCEPTED |
| 3 | Cari / müşteri kartı görünür olur | İş zincirinin ilk halkası yüzeye çıkar | ACCEPTED |
| 4 | Ürün / stok kartı görünür olur | Ürün ve stok hareketi pilot yüzeyde yer alır | ACCEPTED |
| 5 | Satış / sipariş kartı görünür olur | Ticari hareket pilot yüzeyde başlatılır | ACCEPTED |
| 6 | ERP apply kartı görünür olur | Hareketin ERP core tarafına aktarımı görünür olur | ACCEPTED |
| 7 | Event / audit kartı görünür olur | İzlenebilirlik pilot yüzeye taşınır | ACCEPTED |
| 8 | Raporlama / izleme kartı görünür olur | Pilot işletme sonucu görebilir | ACCEPTED |
| 9 | Oto yedek parça kısayolu hazırlanır | 4D-7 için UI kapısı hazırlanır | ACCEPTED |
| 10 | Mobile-ready PWA uyumu korunur | Yüzey mobil ekrana uyumlu tasarlanır | ACCEPTED |

## 4. Oluşturulan UI Dosyası

Pilot UI dosyası:

web/pilot-business-ui/index.html

Bu dosya:
- statik pilot yüzeydir,
- production deploy değildir,
- API entegrasyonu henüz yapılmaz,
- 4D-6 için iş yüzeyi kanıtıdır,
- 4D-14 mobile-ready PWA adımına temel oluşturur.

## 5. Pilot UI Minimum Alanları

Pilot iş yüzeyinde şu alanlar bulunmalıdır:

- Pilot Business UI Surface başlığı
- Tenant / Access durumu
- Cari / Müşteri
- Ürün / Stok
- Satış / Sipariş
- ERP Apply
- Event / Audit
- Raporlama / İzleme
- Oto Yedek Parça
- Mobile-ready PWA notu

## 6. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- React/Vue/Next production panel yazılmaz.
- Tam API bağlantısı yapılmaz.
- Login ekranı yazılmaz.
- Password reset ekranı yazılmaz.
- Oto yedek parça detay ekranı tamamlanmaz.
- Native mobil uygulama yapılmaz.
- Production Nginx route deploy yapılmaz.

## 7. Risk Notları

| Risk | Kontrol |
|---|---|
| Pilot kullanıcı ne yapacağını göremez | Tek yüzeyli dashboard yaklaşımı |
| UI sadece görsel kalır | ERP apply, event ve raporlama kartları görünür tutulur |
| Tenant bağlamı unutulur | Tenant/access kartı zorunlu |
| Oto yedek parça akışı ayrı kalır | 4D-7 kısayolu hazırlanır |
| Mobil yüzey ihmal edilir | Mobile-ready PWA notu zorunlu |

## 8. Sonuç Alanı

FAZ_4D_6_PILOT_BUSINESS_UI_SURFACE_STATUS=PENDING
FAZ_4D_6_FINAL_STATUS=PENDING
FAZ_4D_7_READY=NO

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
