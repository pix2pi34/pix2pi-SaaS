# FAZ 4D-15 — Release / Rollback / Backup Gate

## 1. Amaç

Bu adımın amacı, FAZ 4D final kapanışından önce release, rollback ve backup kapısını mühürlemektir.

Bu adım production release automation final değildir.

Bu adımın hedefi:
- kontrollü pilot release durumunu doğrulamak,
- public sayfa erişimini tekrar kontrol etmek,
- Nginx config sağlığını doğrulamak,
- 4D raporlarının PASS olduğunu kontrol etmek,
- public dosyaların yedeğini almak,
- Nginx config yedeğini almak,
- rollback ilkesini görünür yapmak,
- 4D-16 final closure adımına geçişi hazırlamaktır.

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
FAZ_4D_11_FINAL_STATUS=PASS ✅
FAZ_4D_11_SEAL_STATUS=SEALED ✅
FAZ_4D_12_FINAL_STATUS=PASS ✅
FAZ_4D_12_SEAL_STATUS=SEALED ✅
FAZ_4D_13_FINAL_STATUS=PASS ✅
FAZ_4D_13_SEAL_STATUS=SEALED ✅
FAZ_4D_14_FINAL_STATUS=PASS ✅
FAZ_4D_14_SEAL_STATUS=SEALED ✅
FAZ_4D_15_READY=YES ✅

## 3. Release / Rollback / Backup Kararları

| No | Karar | Açıklama | Durum |
|---:|---|---|---|
| 1 | Release kontrollü pilot kapsamındadır | Geniş public launch değildir | ACCEPTED |
| 2 | Public go-live sayfası doğrulanır | GET 200 ve içerik kontrolü yapılır | ACCEPTED |
| 3 | Nginx config testi zorunludur | nginx -t PASS olmalıdır | ACCEPTED |
| 4 | Public dosyalar yedeklenir | /var/www/pix2pi yedeği alınır | ACCEPTED |
| 5 | Nginx config yedeklenir | Aktif route configleri geri alınabilir olmalıdır | ACCEPTED |
| 6 | 4D raporları PASS olmalıdır | 4D-1 ile 4D-14 raporları PASS olmalıdır | ACCEPTED |
| 7 | Rollback yolu bilinmelidir | Public dosya ve Nginx config geri alınabilir olmalıdır | ACCEPTED |
| 8 | Marketplace production kapalı kalır | Release kapısı marketplace'i açmaz | ACCEPTED |
| 9 | Paraşüt production kapalı kalır | Release kapısı Paraşüt API'yi açmaz | ACCEPTED |
| 10 | Mobile PWA pilot kanıtı kalır | Native mobile veya full PWA production sayılmaz | ACCEPTED |
| 11 | No-go tetikleyicileri geçerlidir | Kritik hata varsa final closure verilmez | ACCEPTED |
| 12 | 4D-16 final closure bu gate'e bağlıdır | Bu gate PASS olmadan FAZ 4D kapanmaz | ACCEPTED |

## 4. Release Gate Minimum Kontrolleri

Minimum release gate kontrolleri:

- Nginx config PASS
- public URL GET 200
- public content match PASS
- 4D-1 report PASS
- 4D-2 report PASS
- 4D-3 report PASS
- 4D-4 report PASS
- 4D-5 report PASS
- 4D-6 report PASS
- 4D-7 report PASS
- 4D-8 report PASS
- 4D-9 report PASS
- 4D-10 report PASS
- 4D-11 report PASS
- 4D-12 report PASS
- 4D-13 report PASS
- 4D-14 report PASS
- public file backup exists
- nginx config backup exists

## 5. Rollback İlkesi

Rollback için minimum yol:

1. Public dosyalar backup dizininden geri alınabilir.
2. Nginx config backup dizininden geri alınabilir.
3. nginx -t ile config doğrulanır.
4. systemctl reload nginx ile route yenilenir.
5. Public URL tekrar GET ile doğrulanır.
6. Kritik hata varsa pilot genişletme durdurulur.
7. 4D-16 final closure verilmez.

## 6. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Tam CI/CD release pipeline yazılmaz.
- Blue/green deployment kurulmaz.
- Canary deployment kurulmaz.
- Kubernetes rollback yapılmaz.
- Tam DB restore drill yapılmaz.
- Tam disaster recovery final yapılmaz.
- Tam production release automation yapılmaz.

## 7. No-Go Kuralları

Aşağıdakilerden biri varsa 4D-16'ya geçilmez:

- Nginx config fail
- public URL 200 dönmüyor
- public content match fail
- 4D raporlarından biri FAIL
- backup dizini yok
- rollback dosyaları yok
- cross-tenant güvenlik riski
- auth bypass riski
- veri kaybı riski
- secret/credential sızıntısı

## 8. Oluşturulan Release Gate UI Dosyası

web/release-rollback-gate/index.html

Bu dosya:
- statik release/rollback/backup gate yüzeyidir,
- production CI/CD paneli değildir,
- rollback automation değildir,
- 4D-15 için karar kanıtıdır,
- 4D-16 final closure için son kapıdır.

## 9. Sonuç Alanı

FAZ_4D_15_RELEASE_ROLLBACK_BACKUP_GATE_STATUS=PENDING
FAZ_4D_15_FINAL_STATUS=PENDING
FAZ_4D_16_READY=NO

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
