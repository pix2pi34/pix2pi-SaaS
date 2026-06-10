# Customer Email Normalize + Password Reset Fix Audit

## Hata sebebi

İlk script sadece exact e-posta aradı:
surucukursu58@gmail.com

Kayıt dosyasında e-posta plus-alias veya farklı formatta olduğu için eşleşme bulunmadı.

## Yapılan işlem

- surucukursu58 geçen kayıtlar bulundu.
- E-posta surucukursu58@gmail.com olarak normalize edildi.
- Login aktif edildi.
- Approval ACTIVE/APPROVED değerleri set edildi.
- Geçici şifre oluşturuldu.
- SHA256 hash alanları yazıldı.
- Prototype uyumluluğu için temporaryPassword alanı yazıldı.

## Giriş bilgisi

E-posta: surucukursu58@gmail.com
Geçici şifre: Pix2pi@2026

## Test

- target email verify: PASS
- password hash verify: PASS
- temporary password verify: PASS
- customer-login.html HTTP: 200

## Backup

/root/pix2pi/pix2pi-SaaS/backups/customer-email-normalize-password-reset-fix/20260518_081004

## Counts

PASS_COUNT=8
FAIL_COUNT=0
WARN_COUNT=0
