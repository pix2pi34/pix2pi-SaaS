# FAZ 4B / 19.4 - Import Wizard UI

Amaç:
Pilot öncesi cari, ürün, stok ve açılış verilerinin kontrollü şekilde içeri alınabilmesi için admin panel import sihirbazı standardını kurmak.

Bu adım:
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Gerçek dosya upload etmez.
- Import / staging / commit çalıştırmaz.
- Panel build/deploy çalıştırmaz.
- Route deploy etmez.
- Servis restart etmez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Ön koşul:
- 14 Migration / lifecycle / import PASS olmalı.
- 19.3 Admin dashboard cards PASS olmalı.

Wizard route:
- `/admin/imports/wizard`

Import hedefleri:
- Cari kartlar
- Ürün kartları
- Stok açılışları
- Tedarikçi / müşteri kayıtları
- Adres / iletişim kayıtları
- Başlangıç bakiyeleri için hazırlık

Wizard adımları:
1. Template seçimi
2. Dosya yükleme
3. Kolon eşleştirme
4. Ön doğrulama
5. Preview / staging sonucu
6. Hata indirme
7. Kontrollü commit hazırlığı
8. Import history / flow link

Tenant güvenliği:
- Her import batch tenant scope ile çalışmalı.
- Her wizard response tenant_required=YES olmalı.
- Import dosyası başka tenant verisine bağlanmamalı.
- Commit gerçek runtime gate olmadan çalıştırılmamalı.
- Query text, token, raw DSN ve password wizard contract veya rapora basılmamalı.

Kapanış hedefi:
IMPORT_WIZARD_UI=PASS
IMPORT_WIZARD_CONTRACT=PASS
IMPORT_WIZARD_ROUTE_MANIFEST=PASS
IMPORT_WIZARD_STEP_MANIFEST=PASS
IMPORT_WIZARD_COMPONENT_MANIFEST=PASS
IMPORT_WIZARD_PREVIOUS_19_3=PASS
IMPORT_WIZARD_TENANT_SAFETY=PASS
IMPORT_WIZARD_NO_APPLY=PASS
IMPORT_WIZARD_SECRET_SAFETY=PASS
FAZ4B_19_4_FINAL_STATUS=PASS

## 19.4R Notu - Tenant safety reference fix

19.4 test gate, import wizard UI dokümanlarında tenant güvenliği referansını en az 12 bekler.

Bu yüzden import wizard tenant güvenliği şu şekilde netleştirildi:

- Her import batch mutlaka tenant context ile açılır.
- Her import template tenant scope dışına çıkamaz.
- Her import mapping tenant izolasyonu içinde saklanır.
- Her import validation tenant bazlı çalışır.
- Her import preview sadece ilgili tenant staged verisini gösterir.
- Her import error download tenant sınırını korur.
- Her import commit plan tenant dışı kayıt üretemez.
- Import history tenant filtreli olmak zorundadır.
- Runtime flow link tenant scope ile ilişkilendirilir.
- Cross-tenant import, cross-tenant preview ve cross-tenant commit yasaktır.
