# PIX2PI SAAS KERNEL CONSTITUTION v1.0

- Kernel domain bilmez (commerce/lojistik/ödeme yok).
- Identity ≠ Customer.
- Tenant isolation kutsal: tenant_id zorunlu.
- Kernel stateless.
- Behavior config/policy ile değişir.
- Backward compatibility kırılmaz (v1 yaşar, v2 eklenir).
- Kernel event yayınlar, iş yapmaz.
- Single point of failure yasak.
- DB schema değişimi expand→migrate→contract.
- Hata normaldir: healthz, graceful degradation, read-only.
