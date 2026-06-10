# Customer Register API Port 9036 Hard Fix Audit

## Kök sebep

Nginx route geçti fakat upstream kayıt API servisi 9036 portunda ayakta değildi.
Bu yüzden panel route'u 502 Bad Gateway dönüyordu.

## Yapılanlar

- customer-register-submit-api server.js sağlam/stable şekilde yeniden yazıldı.
- Systemd service gerçek node path ile yeniden yazıldı: /usr/bin/node
- 9036 portu doğrudan health ile doğrulandı.
- Panel üzerinden /customer-register/api/health doğrulandı.
- PASSWORD_MISMATCH gerçek hata testi yapıldı.
- Gerçek dosya yazma testi yapıldı, test kaydı temizlendi.
- /customer-register/react/ route'u canlı test edildi.

## Testler

- Direct health HTTP: 200
- Panel health HTTP: 200
- Password mismatch HTTP: 400
- Real write smoke HTTP: 201
- React register page HTTP: 200

## Backup

/root/pix2pi/pix2pi-SaaS/backups/customer-register-api-port-9036-hard-fix/20260518_184623

## Counts

PASS_COUNT=10
FAIL_COUNT=0
WARN_COUNT=0
