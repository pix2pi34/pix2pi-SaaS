# LVL12 Realtime + Workflow Foundation

## Kapsam
Bu paket su maddeleri acar:
- 12.5.1 realtime core
- 12.5.2 WebSocket
- 12.5.3 SSE
- 12.5.4 tenant-safe channel ayrimi
- 12.5.5 realtime testleri
- 12.6.1 workflow engine
- 12.6.2 workflow tanim modeli
- 12.6.3 manual step / approval
- 12.6.4 retry / compensation
- 12.6.5 workflow observability
- 12.6.6 workflow testleri

## Bu pakette ne var
- realtime / workflow env example
- realtime catalog
- workflow catalog
- rules template
- render script
- smoke script
- generated rules
- generated realtime summary
- generated workflow summary

## Mantik
Ilk asamada:
- realtime core ve channel standartlarini katalogluyoruz
- workflow engine ve approval / compensation mantigini sabitliyoruz
- tenant-safe channel / timeout / retry / observability ayarlarini generated output olarak uretiyoruz
- smoke ile ciktinin dogrulugunu kontrol ediyoruz

## Sonraki paket
- 12.7 plugin / app platform
- 12.8 public API / developer layer
