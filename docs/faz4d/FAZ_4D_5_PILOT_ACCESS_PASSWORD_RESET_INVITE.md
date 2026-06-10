# FAZ 4D-5 — Pilot access / password reset / invite

## 1. Amaç

Bu adımın amacı, pilot kullanıcının sisteme güvenli ve kontrollü şekilde erişebilmesi için erişim, davet, şifre sıfırlama, tenant bağlama ve rol bağlama kararlarını mühürlemektir.

Bu adım pilot erişim kapısıdır.

## 2. Giriş Şartı

FAZ_4D_1_FINAL_STATUS=PASS ✅
FAZ_4D_1_SEAL_STATUS=SEALED ✅
FAZ_4D_2_FINAL_STATUS=PASS ✅
FAZ_4D_2_SEAL_STATUS=SEALED ✅
FAZ_4D_3_FINAL_STATUS=PASS ✅
FAZ_4D_3_SEAL_STATUS=SEALED ✅
FAZ_4D_4_FINAL_STATUS=PASS ✅
FAZ_4D_4_SEAL_STATUS=SEALED ✅
FAZ_4D_5_READY=YES ✅

## 3. Pilot Access Kararları

| No | Karar | Açıklama | Durum |
|---:|---|---|---|
| 1 | Pilot kullanıcı tenant'a bağlı olmalı | Kullanıcı hiçbir zaman tenant bağlamı olmadan pilot yüzeye girmemeli | ACCEPTED |
| 2 | Pilot kullanıcı role bağlı olmalı | Kullanıcı yetkisiz modül veya tenant görmemeli | ACCEPTED |
| 3 | Davet akışı kayıt altına alınmalı | Invite işlemi audit/log ile izlenebilir olmalı | ACCEPTED |
| 4 | Şifre sıfırlama desteklenmeli | Pilot kullanıcı şifre unutursa kontrollü reset yapılabilmeli | ACCEPTED |
| 5 | Login sonrası token üretimi doğrulanmalı | Access JWT veya Authorization katmanına bağlanmalı | ACCEPTED |
| 6 | Password reset token süreli olmalı | Reset linki veya token süresiz olmamalı | ACCEPTED |
| 7 | Invite token süreli olmalı | Davet linki veya token süresiz olmamalı | ACCEPTED |
| 8 | İlk girişte minimum güvenlik kontrolü olmalı | Kullanıcı/tenant/role doğrulanmalı | ACCEPTED |
| 9 | Erişim audit izi oluşmalı | Login, invite, reset gibi kritik hareketler izlenebilir olmalı | ACCEPTED |
| 10 | Pilot erişim production IAM final değildir | Bu adım pilot kapısıdır, IAM final sonraki güvenlik fazlarında derinleşir | ACCEPTED |

## 4. Pilot Minimum Access Akışı

Pilot için minimum erişim akışı:

1. Admin veya sistem pilot kullanıcıyı tanımlar.
2. Pilot kullanıcı tenant ile ilişkilendirilir.
3. Pilot kullanıcı role ile ilişkilendirilir.
4. Pilot kullanıcıya davet veya ilk erişim bilgisi verilir.
5. Kullanıcı login olur.
6. Sistem token üretir.
7. Token içinde tenant/role bağlamı korunur.
8. Şifre unutulursa reset akışı çalışır.
9. Kritik erişim hareketleri audit/log izine düşer.
10. Kullanıcı pilot business UI surface'e yönlendirilir.

## 5. Zorunlu Güvenlik Notları

- Pilot kullanıcı başka tenant verisini göremez.
- Pilot kullanıcı super-admin yetkisiyle başlatılmaz.
- Pilot kullanıcı default admin rolüyle açılmaz.
- Şifre reset tokenı süresiz olmamalıdır.
- Invite tokenı süresiz olmamalıdır.
- Reset ve invite akışı audit/log ile izlenmelidir.
- Login sonrası tenant context kontrol edilmelidir.
- Role kontrolü olmadan pilot UI açılmamalıdır.

## 6. Pilot Kabul Kriterleri

4D-5 şu şartlarla PASS alır:

- 4D-4 raporu PASS olmalı.
- Master plan içinde 4D-5 IN_PROGRESS olmalı.
- Pilot access dokümanı var olmalı.
- Tenant bağlı erişim kararı ACCEPTED olmalı.
- Role bağlı erişim kararı ACCEPTED olmalı.
- Invite kararı ACCEPTED olmalı.
- Password reset kararı ACCEPTED olmalı.
- JWT/Authorization kararı ACCEPTED olmalı.
- Audit/log kararı ACCEPTED olmalı.
- Repo içinde auth/access kanıtları aranmalı.
- Rapor dosyası üretilmeli.
- 4D-6'ya geçiş izni oluşmalı.

## 7. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Tam IAM production final yapılmaz.
- Tam user management UI yazılmaz.
- Tam e-posta sağlayıcı production entegrasyonu yapılmaz.
- Tam SMS OTP veya MFA final yapılmaz.
- Tam permission matrix final yapılmaz.
- Tam super-admin paneli yapılmaz.

## 8. Risk Notları

| Risk | Kontrol |
|---|---|
| Kullanıcı tenant olmadan girer | Tenant bağlı erişim zorunlu |
| Kullanıcı rol olmadan girer | Role bağlı erişim zorunlu |
| Reset tokenı süresiz kalır | Süreli token kararı zorunlu |
| Invite tokenı süresiz kalır | Süreli invite kararı zorunlu |
| Pilot kullanıcı fazla yetki alır | Default super-admin yasak |
| Login var ama audit yok | Erişim audit izi zorunlu |

## 9. Sonuç Alanı

FAZ_4D_5_PILOT_ACCESS_PASSWORD_RESET_INVITE_STATUS=PENDING
FAZ_4D_5_FINAL_STATUS=PENDING
FAZ_4D_6_READY=NO

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
