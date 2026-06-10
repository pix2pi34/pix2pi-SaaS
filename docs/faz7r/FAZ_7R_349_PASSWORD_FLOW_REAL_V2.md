# FAZ 7-R / 349 — Kullanıcı Şifre / Giriş Akışı Real V2

## Kapsam

Bu iş 349 ana başlığının alt işlerini gerçek runtime mantığıyla kapatır.

- 349.1 İlk şifre oluşturma
- 349.2 Şifre sıfırlama
- 349.3 Login sonrası tenant seçimi handoff
- 349.4 Session validation
- 349.5 Password flow testleri

## Gerçek uygulama

- Şifre policy kontrolü
- Salt + hash ile parola saklama kontratı
- Plain text parola yasağı
- Reset token üretme / consume etme
- Login sonrası session üretme
- Login sonrası `/tenant-select/` yönlendirme kontratı
- Tenant membership guard
- Audit event kontratı
- Unit test suite
- Live panel ekranı

## Kapanış politikası

- Sadece ekran görünümü ile kapanış yapılamaz.
- Runtime kapalı bırakılarak final verilemez.
- Eksik kapsam başarılı kapanış sayılmaz.
- Şifre oluşturma, reset, login, tenant handoff, session validation ve test suite birlikte geçmelidir.
