# FAZ 1-2.3 RLS Base Policy Set

## Kapsam

- Tenant bazlı RLS policy
- Kritik tablolar için RLS
- DB session tenant context
- RLS bypass testleri
- Cross-tenant DB testleri

## FIX V3B Notu

Bu fazda app/runtime DB rolü `pix2pi` üzerinden BYPASSRLS kaldırıldı. RLS verify rolü de BYPASSRLS sahibi değildir.

`set_tenant_context('')` çağrısının hata vermesi güvenlik açısından doğru davranıştır. Boş tenant context kabul edilmez.

## Test Alanları

- Tüm tenant_id tablolarında RLS enabled
- Tüm tenant_id tablolarında RLS forced
- Tenant isolation allow/enforce policy kapsamı
- app_security DB session tenant context helper seti
- pix2pi rolü NOBYPASSRLS
- verify role BYPASSRLS sahibi değil
- empty tenant context rejection
- same-tenant visibility
- cross-tenant invisibility
- rollback cleanup

## Final

FAZ 1-2.3 RLS Base Policy Set; RLS bypass ve cross-tenant DB suite ile doğrulanır.
