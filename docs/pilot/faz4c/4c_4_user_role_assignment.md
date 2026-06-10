# FAZ 4C — 4C-4 Real User / Role Assignment

## Blok

4C-4 — Real User / Role Assignment

## Amac

Bu blokta uzmanparcaci pilot tenant icin gercek pilot kullanici ve rol atamasi hazirlanacak ve kontrollu sekilde uygulanacak.

Ilk hedef:

- Tenant dogrulandi mi?
- Kullanici kimligi net mi?
- Rol kimligi net mi?
- Hangi tabloya yazilacak?
- DB apply oncesi precheck yapildi mi?
- Kullanici/rol kaydi kontrollu sekilde olusturuldu mu?

---

## 1. On kosul

4C-3 Real Pilot Tenant Setup kapanmis olmalidir.

Beklenen onceki durum:

4C_3_FINAL_STATUS=PASS
4C_3_REAL_PILOT_TENANT_SETUP_STATUS=PASS
4C_3_TENANT_BUSINESS_CODE=UZMANPARCACI
4C_3_TENANT_SCHEMA=tenant_uzmanparcaci
4C_4_READY=YES

---

## 2. Tenant bilgisi

TENANT_BUSINESS_CODE=UZMANPARCACI
TENANT_SLUG=uzmanparcaci
TENANT_SCHEMA=tenant_uzmanparcaci
TENANT_STATUS=active

---

## 3. Pilot kullanici kimligi

PILOT_USER_FULL_NAME=mert_omur
PILOT_USER_DISPLAY_NAME=mert omur
PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
PILOT_USER_PHONE=5377457536

Teknik karar:

- Kullanici gercek pilot kullanicidir.
- Test kullanicisi degildir.
- Tenant owner/admin yetkisiyle baslatilacaktir.
- Super admin yetkisi verilmeyecektir.

---

## 4. Pilot rol kimligi

PILOT_ROLE_CODE=PILOT_ADMIN
PILOT_ROLE_NAME=Pilot Admin
PILOT_ROLE_SCOPE=TENANT

Rol kapsam karari:

- Tenant icinde admin yetkisi
- Platform super admin degil
- Pazaryeri canli entegrasyon yetkisi yok
- e-Fatura/e-Arsiv canli yetkisi yok
- Banka/sanal POS canli yetkisi yok

---

## 5. 4C-4 icinde yapilacaklar

1. 4C-4A — User / Role Identity Plan Freeze
2. 4C-4B — Identity User / Role DB Precheck
3. 4C-4C — User / Role Apply Strategy Decision
4. 4C-4D — User / Role SQL Package / Dry Run Plan
5. 4C-4E — User / Role SQL Dry Run / ROLLBACK Verification
6. 4C-4F — User / Role Commit SQL Package / Apply Guard
7. 4C-4G — User / Role Apply Execution
8. 4C-4H — User / Role Verification / Access Smoke
9. 4C-4I — User / Role Assignment Final Closure

---

## 6. Scope guard

FAZ 4C kapsaminda bu kullaniciya acilmayacak yetkiler:

- Platform super admin
- Cross-tenant access
- Canli pazaryeri entegrasyonu
- Canli e-Fatura / e-Arsiv
- Canli banka / sanal POS
- Global admin
- Sistem config degistirme
- Tenant silme
- Tum tenantlari listeleme

---

## 7. 4C-4A status

4C_4A_USER_ROLE_IDENTITY_PLAN_STATUS=PASS
4C_4A_TENANT_BUSINESS_CODE=UZMANPARCACI
4C_4A_TENANT_SCHEMA=tenant_uzmanparcaci
4C_4A_PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
4C_4A_PILOT_USER_PHONE=5377457536
4C_4A_PILOT_ROLE_CODE=PILOT_ADMIN
4C_4A_USER_ROLE_SETUP_APPLY_STATUS=NOT_APPLIED
4C_4A_DB_WRITE_APPLIED=NO
4C_4B_READY=YES

---

## 8. Sonraki adim

Sonraki adim:

4C-4B — Identity User / Role DB Precheck

Bu adimda kullanici, rol ve tenant-user mapping tablolari kesfedilecek.
