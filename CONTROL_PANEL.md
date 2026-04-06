# Pix2pi Control Panel (Sistem Yöneticisi Rehberi)

Bu doküman, sunucuyu yöneten kişinin "ne yapacağını" hızlıca görmesi içindir.

## 1) Hızlı Durum Kontrolü
- Servis ayakta mı?
  - `lsof -iTCP -sTCP:LISTEN -P | egrep ':(9001|9011)\b' || true`
- Identity log:
  - `tail -n 120 /tmp/identity.log || true`

## 2) Portlar
- Port listesi: `PORTS.md`
- Runtime env: `deploy/ports.env`

## 3) Identity Başlat / Durdur / Restart
Örnek (shell script varsa):
- `bash /tmp/STEP21_start_identity.sh`
- `bash /tmp/STEP18_restart_identity.sh`

Eğer manuel çalıştırman gerekirse:
- `pkill identity || true`
- `nohup go run cmd/identity-api/*.go > /tmp/identity.log 2>&1 &`

## 4) Dev Token
dev-token endpoint’i geliştirme içindir.
- Varsayılan: `127.0.0.1:9011`
- Dış dünyaya açma.

Token üretme örneği:
- `curl -s "http://127.0.0.1:9011/dev/token?tenant=1&role=admin&sub=1" | jq -r .token`

## 5) WhoAmI Testi
- `TOK=$(curl -s "http://127.0.0.1:9011/dev/token?tenant=1&role=admin&sub=1" | jq -r .token)`
- `curl -i -H "Authorization: Bearer $TOK" -H "X-Tenant-ID: 1" http://127.0.0.1:9001/whoami`

Beklenen:
- `HTTP/1.1 200 OK`
- body: `{"role":"admin","tenant_id":"1","user_id":"1"}`

## 6) Sık Hatalar
- 403 missing role:
  - JWT claim role okunmuyor ya da middleware locals set etmiyor.
- Port çakışması:
  - Aynı port iki process.
  - Çözüm: PORTS.md + deploy/ports.env kontrol et.
