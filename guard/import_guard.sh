set -euo pipefail
cd /root/pix2pi/pix2pi-SaaS

# ripgrep varsa onu kullan, yoksa grep ile fallback
if command -v rg >/dev/null 2>&1; then
  if rg -n --glob 'kernel/**/*.go' 'pix2pi-SaaS/services/' kernel >/dev/null 2>&1; then
    echo "HATA ❌ kernel içinde services import bulundu (anayasa ihlali)."
    rg -n --glob 'kernel/**/*.go' 'pix2pi-SaaS/services/' kernel || true
    exit 1
  fi
else
  if grep -RIn --include='*.go' 'pix2pi-SaaS/services/' kernel >/dev/null 2>&1; then
    echo "HATA ❌ kernel içinde services import bulundu (anayasa ihlali)."
    grep -RIn --include='*.go' 'pix2pi-SaaS/services/' kernel || true
    exit 1
  fi
fi

echo "OK ✅ import guard geçti (kernel -> services yok)"
