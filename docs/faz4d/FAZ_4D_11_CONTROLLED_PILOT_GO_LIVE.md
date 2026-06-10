# FAZ 4D-11 — Controlled Pilot Go-Live

## 1. Amaç

Bu adımın amacı, Pix2pi pilot kullanımını geniş public açılışa çevirmeden, kontrollü pilot açılış şartlarını mühürlemektir.

Bu adım full production launch değildir.

Bu adımın hedefi:
- kontrollü pilot açılış kararını sabitlemek,
- pilot kapsamını sınırlamak,
- hangi kullanıcı/tenant ile açılacağını belirlemek,
- no-go tetikleyicilerini tanımlamak,
- rollback şartlarını görünür yapmak,
- monitoring ve support adımlarına geçişi hazırlamaktır.

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
FAZ_4D_6_FINAL_STATUS=PASS ✅
FAZ_4D_6_SEAL_STATUS=SEALED ✅
FAZ_4D_7_FINAL_STATUS=PASS ✅
FAZ_4D_7_SEAL_STATUS=SEALED ✅
FAZ_4D_8_FINAL_STATUS=PASS ✅
FAZ_4D_8_SEAL_STATUS=SEALED ✅
FAZ_4D_9_FINAL_STATUS=PASS ✅
FAZ_4D_9_SEAL_STATUS=SEALED ✅
FAZ_4D_10_FINAL_STATUS=PASS ✅
FAZ_4D_10_SEAL_STATUS=SEALED ✅
FAZ_4D_11_READY=YES ✅

## 3. Controlled Pilot Go-Live Kararları

| No | Karar | Açıklama | Durum |
|---:|---|---|---|
| 1 | Go-live kontrollü pilot olarak açılır | Geniş public açılış yapılmaz | ACCEPTED |
| 2 | Pilot tenant sayısı sınırlı tutulur | İlk açılış az sayıda tenant ile yapılır | ACCEPTED |
| 3 | Pilot kullanıcı sayısı sınırlı tutulur | Yetkili pilot kullanıcılar dışında erişim açılmaz | ACCEPTED |
| 4 | Tenant isolation korunur | Cross-tenant veri sızıntısı no-go sebebidir | ACCEPTED |
| 5 | Business UI pilot yüzeyden başlar | Kullanıcı pilot business UI üzerinden yönlendirilir | ACCEPTED |
| 6 | Marketplace production kapalı kalır | Marketplace sadece discovery olarak kalır | ACCEPTED |
| 7 | Paraşüt production kapalı kalır | Paraşüt sadece discovery olarak kalır | ACCEPTED |
| 8 | Barkod opsiyonel kalır | Barkod yokluğu pilotu bloke etmez | ACCEPTED |
| 9 | Monitoring zorunlu sonraki adımdır | 4D-12 geçilmeden stabilizasyon kapanmaz | ACCEPTED |
| 10 | Support feedback loop zorunlu sonraki adımdır | 4D-13 geçilmeden pilot tamamlanmaz | ACCEPTED |
| 11 | Release/rollback gate zorunlu kapanış kapısıdır | 4D-15 geçilmeden faz final kapanmaz | ACCEPTED |
| 12 | Kritik hata olursa no-go uygulanır | Veri sızıntısı, auth bypass, DB bozulması pilotu durdurur | ACCEPTED |

## 4. Pilot Açılış Kapsamı

Controlled pilot kapsamında izin verilenler:

- sınırlı tenant ile kullanım,
- sınırlı pilot kullanıcı ile giriş,
- pilot business UI yüzeyinin açılması,
- oto yedek parça UI yüzeyinin gösterilmesi,
- ürün/stok/satış/ERP apply akışının kontrollü denenmesi,
- event/audit izlerinin takip edilmesi,
- marketplace discovery ekranının gösterilmesi,
- Paraşüt discovery ekranının gösterilmesi,
- barkod opsiyonel notunun gösterilmesi.

## 5. Pilot Açılış Kapsam Dışı

Controlled pilot kapsamında izin verilmeyenler:

- geniş public kullanıcı açılışı,
- production marketplace siparişi,
- production ödeme alma,
- production komisyon tahsilatı,
- production Paraşüt API çağrısı,
- canlı e-Fatura/e-Arşiv üretimi,
- gizli credential veya token yazılması,
- cross-tenant veri gösterimi,
- native mobil production yayını,
- rollback kapısı olmadan release genişletme.

## 6. No-Go Tetikleyicileri

Aşağıdaki durumlardan biri oluşursa pilot genişletilmez:

| No | No-Go Sebebi | Etki |
|---:|---|---|
| 1 | Cross-tenant veri sızıntısı | Pilot durdurulur |
| 2 | Auth bypass | Pilot durdurulur |
| 3 | Yetkisiz role erişimi | Pilot durdurulur |
| 4 | ERP apply yanlış tenant'a işler | Pilot durdurulur |
| 5 | Stok/satış verisi bozulur | Pilot durdurulur |
| 6 | DB migration veya veri kaybı riski oluşur | Pilot durdurulur |
| 7 | Secret/credential repo içine girer | Pilot durdurulur |
| 8 | Monitoring tamamen kör kalır | 4D-12 öncelikli düzeltme olur |
| 9 | Kullanıcı erişimi çalışmaz | 4D-5 geri kontrol edilir |
| 10 | Rollback yolu yoksa | 4D-15 geçilmeden genişleme yapılmaz |

## 7. Rollback İlkeleri

Bu adımda tam release/rollback automation yazılmaz.

Ancak pilot rollback ilkeleri şimdiden mühürlenir:

- son backup noktası bilinmelidir,
- değiştirilen UI/doküman/script dosyaları yedeklenmelidir,
- kullanıcı erişimi kapatılabilir olmalıdır,
- pilot tenant ayrı izlenmelidir,
- feature veya route genişletmesi geri alınabilir olmalıdır,
- kritik hatada pilot genişletme durdurulmalıdır,
- 4D-15 altında release/rollback/backup gate final PASS vermelidir.

## 8. Controlled Go-Live Minimum Checklist

Pilot açılış için minimum checklist:

- 4D-1 scope freeze PASS
- 4D-2 security/tenant isolation PASS
- 4D-3 business chain PASS
- 4D-4 ERP apply decisions PASS
- 4D-5 access/invite/reset PASS
- 4D-6 pilot business UI PASS
- 4D-7 auto parts UI PASS
- 4D-8 barcode optional PASS
- 4D-9 marketplace discovery PASS
- 4D-10 Paraşüt discovery PASS
- controlled pilot scope ACCEPTED
- no-go triggers ACCEPTED
- rollback principles ACCEPTED
- 4D-12 monitoring READY
- 4D-13 support feedback READY
- 4D-15 release/rollback/backup gate REQUIRED

## 9. Oluşturulan Go-Live UI Dosyası

web/pilot-go-live/index.html

Bu dosya:
- statik controlled pilot go-live yüzeyidir,
- production launch paneli değildir,
- kullanıcıya geniş public açılış yapmaz,
- sadece kontrollü pilot karar kanıtıdır,
- 4D-12 monitoring ve 4D-13 feedback adımları için temel oluşturur.

## 10. Sonuç Alanı

FAZ_4D_11_CONTROLLED_PILOT_GO_LIVE_STATUS=PENDING
FAZ_4D_11_FINAL_STATUS=PENDING
FAZ_4D_12_READY=NO

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
