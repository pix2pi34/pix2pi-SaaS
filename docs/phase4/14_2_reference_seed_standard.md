# FAZ 4B / 14.2 - Reference Data / Seed Standardı

Amaç:
Pilot öncesi sistemde kullanılacak referans verilerin seed standardını tanımlamak.

Bu adım:
- DB seed apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- Migration oluşturmaz.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Sadece seed standardı, manifest, scope ve güvenlik kurallarını üretir.
- Raw DSN, password, token veya query text rapora basmaz.

Seed scope ayrımı:
1. GLOBAL_REFERENCE
   - Tüm tenantlar için ortak referans veridir.
   - Örnek: TDHP hesap planı, KDV oranları, belge tipleri, para birimleri.

2. TENANT_DEFAULT
   - Yeni tenant oluşturulurken varsayılan atanabilecek veridir.
   - Örnek: varsayılan birimler, varsayılan ürün kategorileri, varsayılan stok lokasyonu.

3. TENANT_SPECIFIC
   - Sadece ilgili tenant için import/onboarding sırasında oluşur.
   - Örnek: pilot müşterinin kendi cari listesi, ürün listesi, açılış stokları.

Seed standartları:
1. Her seed domain manifestte kayıtlı olmalı.
2. Her seed domain scope içermeli.
3. Her seed domain idempotency strategy içermeli.
4. Her seed domain rollback strategy içermeli.
5. Her seed domain tenant safety kuralı içermeli.
6. Seed apply ayrı gate olmadan çalıştırılmamalı.
7. Seed scriptleri raw secret veya query text basmamalı.
8. Seed dosyaları tekrar çalıştırılabilir olmalı.
9. Tenant-specific seedler tenant_id/tenant_uuid olmadan apply edilememeli.
10. 14.2 yalnızca standardı kapatır; gerçek seed apply sonraki apply gate adımına bırakılır.

Kapanış hedefi:
REFERENCE_SEED_STANDARD=PASS
REFERENCE_SEED_MANIFEST_STATUS=PASS
REFERENCE_SEED_SCOPE_STATUS=PASS
REFERENCE_SEED_IDEMPOTENCY_STATUS=PASS
REFERENCE_SEED_ROLLBACK_STATUS=PASS
REFERENCE_SEED_TENANT_SAFETY_STATUS=PASS
DB_MUTATION=NO
SEED_APPLY_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_14_2_FINAL_STATUS=PASS
