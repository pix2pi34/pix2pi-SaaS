# FAZ 7-R / 330 — Kasiyer giriş ekranı

## Amaç

`pos.pix2pi.com.tr/login/` üzerinde kasiyer giriş yüzeyini kurar.

## Kapsam

330.1 Kasiyer login app shell  
330.2 Kasiyer kodu / PIN formu  
330.3 Tenant context göstergesi  
330.4 Cihaz / kasa register placeholder  
330.5 Auth endpoint contract  
330.6 Session storage contract  
330.7 Login validation contract  
330.8 Hata / lockout mesajları  
330.9 POS satış ekranına yönlendirme placeholder  
330.10 Offline login policy placeholder  
330.11 i18n-ready cashier login marker  
330.12 Kasiyer login smoke test  

## Teknik karar

Bu adım gerçek backend auth açmaz. POS cashier login UI, runtime adapter, tenant/session/device contract, validation contract ve smoke gate kurulur.

Backend endpoint sözleşmesi:

- Cashier login: `/api/pos/auth/cashier-login`
- Session verify: `/api/pos/auth/session`
- Tenant header: `X-Tenant-ID`
- Device header: `X-POS-Device-ID`

## Gate

PASS için:

- `/login/` HTTP 200 dönmeli.
- Runtime dosyası HTTP 200 dönmeli.
- Kasiyer kodu, PIN, tenant, cihaz, auth endpoint, session, validation, error/lockout, redirect, offline policy ve i18n marker'ları bulunmalı.
