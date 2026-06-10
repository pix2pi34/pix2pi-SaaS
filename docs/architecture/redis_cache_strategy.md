# Redis Cache Strategy

## Amac
Pix2pi platformunda tenant-aware, kontrollu ve temizlenebilir cache standardi olusturmak.

## Temel anahtar formati
tenant:<tenant_id>:<entity>:<key>

## Zorunlu alanlar
- tenant_id
- entity
- key

## TTL standardi
- Varsayilan TTL env uzerinden gelir:
  - REDIS_DEFAULT_TTL_SECONDS
- TTL verilmezse servis default TTL uygular.
- Kalici kayit sadece SetKalici() ile yazilir.

## Entity mantigi
Entity, cache bolgesini ifade eder.

Ornekler:
- product
- order
- customer
- gateway_rate_limit
- policy_cache

## Temizleme kurallari

### Tek key temizleme
Delete(tenantID, entity, key)

### Pattern bazli temizleme
DeleteByPattern(tenantID, entity, keyPattern)

Ornek:
DeleteByPattern("t1", "product", "*")

### Entity namespace temizleme
DeleteEntityNamespace(tenantID, entity)

Ornek:
DeleteEntityNamespace("t1", "product")

## Rate limit standardi
Gateway rate limit sayaclari Redis uzerinde tutulur.

Entity:
gateway_rate_limit

Sayac artirma:
IncrWithTTLOnFirst()

## Policy cache standardi
Policy cache hibrit calisir:
- L1 = process memory
- L2 = Redis

Redis entity:
policy_cache

Tenant:
platform

## Kullanim kurallari
- Tenant ayrimi olmayan cache yazilmamali.
- Entity belirtilmeden cache yazilmamali.
- Buyuk capli temizleme islemleri entity bazli yapilmali.
- Kalici kayit istisna olmali.
- Pattern temizleme kontrollu entity alaninda yapilmali.

## Sonuc
Redis cache katmani:
- tenant-aware
- TTL kontrollu
- entity bazli
- pattern invalidation destekli
- gateway ve policy cache ile uyumlu
hale getirilmistir.
