#!/bin/bash
set -e

echo "=== STEP 370 / REAL GLOBAL STATUS ENGINE ==="

PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"

echo
echo "1. backup..."
cp "$PANEL_HTML" "${PANEL_HTML}.bak_status_engine_$(date +%s)"
echo "OK ✅ backup"

echo
echo "2. banner logic fix..."

sed -i 's/Sistem genel olarak calisiyor/Kontrol ediliyor.../g' "$PANEL_HTML"

echo "OK ✅ eski mesaj temizlendi"

echo
echo "3. yeni logic inject..."

cat <<'JS' >> "$PANEL_HTML"

<script>
function calculateGlobalStatus(running, stopped, degraded) {
  if (stopped > 0) {
    return {
      cls: "status-banner status-stopped",
      text: "Kritik: Bazi servisler calismiyor"
    };
  }

  if (degraded > 0) {
    return {
      cls: "status-banner status-degraded",
      text: "Uyari: Bazi servisler sagliksiz"
    };
  }

  return {
    cls: "status-banner status-running",
    text: "Tum servisler saglikli calisiyor"
  };
}

// override banner
setTimeout(() => {
  try {
    const running = parseInt(document.getElementById("runningCount").textContent || "0");
    const stopped = parseInt(document.getElementById("stoppedCount").textContent || "0");
    const degraded = parseInt(document.getElementById("degradedCount").textContent || "0");

    const banner = document.getElementById("overallBanner");
    const meta = calculateGlobalStatus(running, stopped, degraded);

    banner.className = meta.cls;
    banner.textContent = meta.text;

  } catch (e) {
    console.error("banner fix fail", e);
  }
}, 800);
</script>

JS

echo "OK ✅ yeni status engine eklendi"

echo
echo "4. reload..."
nginx -t && systemctl reload nginx
echo "OK ✅ reload"

echo
echo "=== STEP 370 TAMAM ✅ ==="
