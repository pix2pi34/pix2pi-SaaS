#!/usr/bin/env bash
set -euo pipefail

cd /root/pix2pi/pix2pi-SaaS

echo "==> 1) Identity main dosyası aranıyor..."

MAIN=""
for f in \
  cmd/identity-api/identity_api_main.go \
  cmd/identity-api/identity_main.go \
  cmd/identity-api/main.go \
  cmd/identity-api/identity-api_main.go
do
  if [ -f "$f" ]; then
    MAIN="$f"
    break
  fi
done

if [ -z "$MAIN" ]; then
  echo "HATA: cmd/identity-api altında main dosyası bulamadım."
  ls -lah cmd/identity-api || true
  exit 1
fi

echo "OK ✅  main file: $MAIN"

echo "==> 2) Yedek alınıyor..."
TS="$(date +%Y%m%d_%H%M%S)"
cp -a "$MAIN" "$MAIN.bak_$TS"
echo "OK ✅  backup: $MAIN.bak_$TS"

echo "==> 3) Public /health route ekleniyor (middleware'den ÖNCE)..."

# Şunları yapıyoruz:
# - app := fiber.New(...) satırından hemen sonra public /health route ekle
# - Eğer zaten ekliyse tekrar ekleme
# - Eğer app.Use(auth.JWTMiddleware...) varsa, onu public /health'in ALTINA (yani sonrasına) bırakacağız (dokunmuyoruz),
#   çünkü /health route middleware'den önce tanımlanınca zaten public olur.

perl -0777 -i -pe '
  my $txt = $_;

  # Zaten public health blok varsa dokunma
  if ($txt =~ /PIX2PI_PUBLIC_HEALTH_BEFORE_MIDDLEWARE/s) {
    $_ = $txt;
    next;
  }

  # app := fiber.New(...) satırını yakala ve hemen altına public health ekle
  $txt =~ s{
    (app\s*:=\s*fiber\.New\([^;]*\)\s*\n)
  }{
    $1 .
    "\n" .
    "    // PIX2PI_PUBLIC_HEALTH_BEFORE_MIDDLEWARE\n" .
    "    // Public health MUST be registered before JWT middleware\n" .
    "    app.Get(\"/health\", func(c *fiber.Ctx) error {\\n" .
    "        return c.Status(200).JSON(fiber.Map{\"ok\": true, \"service\": \"identity\"})\\n" .
    "    })\\n" .
    "\n"
  }sex or die "HATA: app := fiber.New(...) bulunamadı / patch uygulanamadı.\n";

  $_ = $txt;
' "$MAIN"

echo "OK ✅  public /health injected"

echo "==> 4) gofmt..."
gofmt -w "$MAIN"
echo "OK ✅  gofmt"

echo "==> 5) Build..."
go build -o /usr/local/bin/pix2pi-identity ./cmd/identity-api
echo "OK ✅  build"

echo "==> 6) Restart service..."
systemctl restart pix2pi-identity
echo "OK ✅  systemctl restart pix2pi-identity"

echo "==> 7) Test /health..."
set +e
OUT="$(curl -sS -i http://localhost:9001/health | head -n 5)"
RC=$?
set -e

echo "---- /health response (first lines) ----"
echo "$OUT"
echo "---------------------------------------"

if [ $RC -ne 0 ]; then
  echo "HATA: curl başarısız (RC=$RC)"
  exit 1
fi

echo "OK ✅  /health reachable"

