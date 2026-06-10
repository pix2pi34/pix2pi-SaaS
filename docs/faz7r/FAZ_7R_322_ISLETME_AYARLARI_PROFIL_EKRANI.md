# FAZ 7-R / 322 — İşletme ayarları / profil ekranı

## Amaç

`panel.pix2pi.com.tr/settings/` üzerinde merchant tenant için işletme profil ve ayar yönetim yüzeyini kurar.

## Kapsam

322.1 Business settings app shell  
322.2 İşletme profil kartı  
322.3 Ticari / vergi bilgileri ayarı  
322.4 Adres / iletişim ayarı  
322.5 Tenant default language ayarı  
322.6 Marka / logo placeholder  
322.7 POS / ERP / Marketplace görünürlük ayarları  
322.8 Bildirim tercihleri  
322.9 Tenant scoped settings guard  
322.10 Settings validation / draft save contract  
322.11 i18n-ready settings markers  
322.12 Settings smoke test  

## Teknik karar

Bu adım gerçek backend mutation açmaz. Frontend ayar yüzeyi, runtime adapter, tenant scoped header contract, validation contract ve smoke gate kurulur.

Backend endpoint sözleşmesi:

- Settings read: `/api/panel/settings/business`
- Settings save: `/api/panel/settings/business/save`
- Tenant header: `X-Tenant-ID`
- JWT: `Authorization: Bearer <token>`

## Gate

PASS için:

- `/settings/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Profile, tax, address, language, branding, module visibility, notification, tenant guard ve validation marker'ları bulunmalı.
