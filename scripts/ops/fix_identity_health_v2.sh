#!/usr/bin/env bash
set -euo pipefail

cd /root/pix2pi/pix2pi-SaaS

MAIN="cmd/identity-api/identity_main.go"
if [ ! -f "$MAIN" ]; then
  echo "HATA: $MAIN yok. cmd/identity-api içinde dosyaları gösteriyorum:"
  ls -lah cmd/identity-api || true
  exit 1
fi

echo "==> 1) Son yedek bulunuyor..."
LAST_BAK="$(ls -1t ${MAIN}.bak_* 2>/dev/null | head -n 1 || true)"
if [ -z "$LAST_BAK" ]; then
  echo "HATA: Yedek bulunamadı (${MAIN}.bak_* yok)."
  echo "Mevcut dosyada geri alma yapamayız; yedeği elle belirtmen gerekir."
  exit 1
fi
echo "OK ✅  last backup: $LAST_BAK"

echo "==> 2) Yedekten geri dönülüyor..."
cp -a "$LAST_BAK" "$MAIN"
echo "OK ✅  restored: $MAIN"

echo "==> 3) Public /health route ekleniyor (middleware'den ÖNCE)..."

# Eğer daha önce eklendiyse tekrar ekleme
if grep -q "PIX2PI_PUBLIC_HEALTH_BEFORE_MIDDLEWARE" "$MAIN"; then
  echo "OK ✅  already injected (skip)"
else
  TMP="$(mktemp)"
  awk '
    BEGIN { injected=0 }
    {
      print $0
      if (!injected && $0 ~ /app[[:space:]]*:=+[[:space:]]*fiber\.New\(/) {
        print ""
        print "    // PIX2PI_PUBLIC_HEALTH_BEFORE_MIDDLEWARE"
        print "    // Public health MUST be registered before JWT middleware"
        print "    app.Get(\"/health\", func(c *fiber.Ctx) error {"
        print "        return c.Status(200).JSON(fiber.Map{\"ok\": true, \"service\": \"identity\"})"
        print "    })"
        print ""
        injected=1
      }
    }
    END {
      if (!injected) {
        # app := fiber.New(...) bulunamazsa hata kodu için özel işaret
        exit 42
      }
    }
  ' "$MAIN" > "$TMP" || {
    RC=$?
    rm -f "$TMP"
    if [ "$RC" -eq 42 ]; then
      echo "HATA: app := fiber.New(...) satırı bulunamadı. Dosya yapısı farklı."
      exit 1
    fi
    echo "HATA: awk patch başarısız (rc=$RC)"
    exit 1
  }
  mv "$TMP" "$MAIN"
  echo "OK ✅  injected"
fi

echo "==> 4) gofmt..."
gofmt -w "$MAIN"
echo "OK ✅  gofmt"

echo "==> 5) Build..."
go build -o /usr/local/bin/pix2pi-identity ./cmd/identity-api
echo "OK ✅  build"

echo "==> 6) Restart service..."
systemctl restart pix2pi-identity
echo "OK ✅  restart"

echo "==> 7) Test..."
echo "--- curl -i http://localhost:9001/health ---"
curl -i http://localhost:9001/health | head -n 20
echo "OK ✅  curl done"
