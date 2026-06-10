# FAZ 3 / STEP 14.1B — ERP Runtime Panel Contract

Tarih: 20260426_234205

## Amaç

Canlı Gateway üzerinde mühürlenen ERP Runtime endpoint'in panel/admin yüzeyinde nasıl kullanılacağını netleştirmek.

## Panel Hedefi

- Panel root: /opt/pix2pi/nginx
- Panel dosyası: /opt/pix2pi/nginx/panel_index.html
- Panel dosya sha256:
1632fbffdd48d93e9b195fc7a7dcccfb90a70a4f2ca7d01aafbaa7dc56b1f47a  /opt/pix2pi/nginx/panel_index.html

## Gateway Endpoint

POST /api/v1/erp/runtime/flows

## Zorunlu Header'lar

- Authorization: Bearer <JWT>
- X-Tenant-ID: tenant_7
- X-Request-ID: req-...

## Örnek Request Body

```json
{
  "tenant_id": "tenant_7",
  "request_id": "req-panel-runtime-001",
  "actor_id": "panel-admin-user",
  "actor_type": "user",
  "transaction_kind": "sales_invoice",
  "source": {
    "source_module": "sales",
    "source_document_type": "invoice",
    "source_document_id": "",
    "source_document_no": "PANEL-SALES-INV-001"
  },
  "money": {
    "total_amount": 120,
    "currency_code": "TRY",
    "exchange_rate": 1
  },
  "idempotency_key": "tenant_7:sales_invoice:PANEL-SALES-INV-001",
  "correlation_id": "corr-panel-runtime-001"
}
```

## Beklenen Başarılı Response

```json
{
  "ok": true,
  "tenant_id": "tenant_7",
  "request_id": "req-panel-runtime-001",
  "status": "completed",
  "step_count": 6
}
```

## Panelde Gösterilecek Alanlar

- Endpoint durumu
- Tenant ID
- Request ID
- Transaction kind
- Source document no
- Total amount
- Currency code
- Flow status
- Step count
- Response JSON
- Error JSON

## Panel UI İlk Versiyon Kararı

İlk versiyon basit admin smoke paneli olacak:

- Token input
- Tenant input
- Source document no input
- Amount input
- ERP Runtime Flow Başlat butonu
- Sonuç kartı
- Ham JSON response alanı

## Güvenlik Notu

Bu panel üretim seviyesinde public kullanıcı ekranı değildir. İlk aşamada admin/test panel yüzeyi olarak kullanılacaktır.

Token browser localStorage'a kalıcı yazılmayacak. İlk versiyonda manuel input kullanılacak.

## Sonraki Adım

FAZ 3 / STEP 14.2A — Panel UI ERP Runtime smoke section ekleme.
