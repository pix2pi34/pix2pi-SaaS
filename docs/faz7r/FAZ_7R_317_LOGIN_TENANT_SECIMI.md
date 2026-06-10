# FAZ 7-R / 317 — Login / tenant seçimi

## Amaç

Bu adım `panel.pix2pi.com.tr` müşteri kullanım yüzeyi için login ve tenant seçim altyapısını kurar.

## Kapsam

317.1 Login ekranı  
317.2 JWT login bağlantısı  
317.3 Tenant selection screen  
317.4 Multi-tenant user destek  
317.5 Remember tenant preference  
317.6 Session timeout davranışı  
317.7 Login error messages  
317.8 Unauthorized / forbidden ekranları  
317.9 Login smoke test  

## Teknik karar

Bu adımda panel frontend auth yüzeyi hazırlanır.

- Login formu `/login/`
- Tenant seçimi `/tenant-select/`
- Unauthorized ekranı `/unauthorized/`
- Forbidden ekranı `/forbidden/`
- Session timeout ekranı `/session-timeout/`
- Auth runtime adapter: `/assets/auth/auth-runtime.js`

JWT backend endpoint bağlantısı frontend runtime içinde standartlaştırılır:

- Login endpoint: `/api/auth/login`
- Tenant list endpoint: `/api/auth/tenants`
- Token storage key: `pix2pi.panel.jwt`
- Tenant preference key: `pix2pi.panel.tenant.preference`

Backend gerçek login API davranışı sonraki backend entegrasyon adımlarında bağlanabilir; bu adım panel tarafındaki sözleşmeyi, ekranları ve smoke gate'i kurar.

## Gate

PASS için:

- Login screen bulunmalı
- JWT login adapter bulunmalı
- Tenant selection screen bulunmalı
- Multi-tenant user destek marker'ları bulunmalı
- Remember tenant preference marker'ları bulunmalı
- Session timeout davranışı bulunmalı
- Login error messages bulunmalı
- Unauthorized / forbidden ekranları bulunmalı
- Panel route üzerinden smoke test HTTP 200 dönmeli
