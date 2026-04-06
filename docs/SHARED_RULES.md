# PIX2PI SHARED CONSTITUTION (Anzer Rules)

Shared sadece "agreement" içindir:
- shared/contracts (DTO, event schema, claims) ✅
- shared/errors ✅
- shared/telemetry (OTel wrapper) ✅

Shared'e ASLA:
- business logic (calculate price, select courier, apply discount) ❌
- repository / DB access ❌
- service layer / workflow ❌
- stateful global cache/vars ❌

Test:
"Bu kod karar veriyor mu?" -> Evet ise shared'e girmez.
