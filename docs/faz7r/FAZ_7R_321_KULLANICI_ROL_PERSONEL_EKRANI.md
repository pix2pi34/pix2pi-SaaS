# FAZ 7-R / 321 — Kullanıcı / rol / personel ekranı

## Amaç

`panel.pix2pi.com.tr/users/` üzerinde merchant tenant için kullanıcı, rol ve personel yönetim yüzeyini kurar.

## Kapsam

321.1 User/personel app shell  
321.2 Kullanıcı listesi  
321.3 Kullanıcı davet formu  
321.4 Rol atama yüzeyi  
321.5 Personel profil kartı  
321.6 Permission matrix preview  
321.7 Tenant scoped user guard  
321.8 Aktif / pasif / askıya alma davranışı  
321.9 i18n-ready text marker  
321.10 Users smoke test  

## Teknik karar

Bu adım gerçek backend mutation açmaz. Frontend user/role/personel sözleşmesini, runtime adapter'ını, tenant scoped header contract'ını ve smoke gate'i kurar.

Backend endpoint sözleşmesi:

- User list: `/api/panel/users`
- Invite: `/api/panel/users/invite`
- Role assign: `/api/panel/users/assign-role`
- Status update: `/api/panel/users/status`
- Tenant header: `X-Tenant-ID`
- JWT: `Authorization: Bearer <token>`

## Gate

PASS için:

- `/users/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- User list, invite, role, permission matrix, tenant guard ve status marker'ları bulunmalı.
