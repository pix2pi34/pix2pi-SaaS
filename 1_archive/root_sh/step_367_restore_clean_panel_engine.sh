#!/bin/bash
set -e

echo "=== STEP 367 / RESTORE CLEAN PANEL ENGINE ==="

PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"

echo
echo "1. backup..."
cp "$PANEL_HTML" "${PANEL_HTML}.bak_restore_$(date +%s)"
echo "OK ✅ backup"

echo
echo "2. eski script block temizleniyor..."

# tüm eski scriptleri kaldır
sed -i '/<script>/,/<\/script>/d' "$PANEL_HTML"

echo "OK ✅ eski script temizlendi"

echo
echo "3. yeni temiz engine ekleniyor..."

cat <<'JS' >> "$PANEL_HTML"

<script>
async function renderPanel() {
  try {
    const res = await fetch("/service-status.json", { cache: "no-store" });
    const data = await res.json();

    const services = data.services || [];

    const normalize = (s) => (s || "").toUpperCase();

    const running = services.filter(s => normalize(s.status) === "RUNNING").length;
    const stopped = services.filter(s => normalize(s.status) === "STOPPED").length;
    const degraded = services.filter(s => normalize(s.status) === "DEGRADED").length;

    document.getElementById("runningCount").textContent = running;
    document.getElementById("stoppedCount").textContent = stopped;
    document.getElementById("degradedCount").textContent = degraded;
    document.getElementById("plannedCount").textContent = "0";

    const root = document.getElementById("liveServices");
    root.innerHTML = "";

    services.forEach(s => {
      const el = document.createElement("div");
      el.className = "service-card";

      el.innerHTML = `
        <b>${s.name}</b><br>
        status: ${s.status}<br>
        method: ${s.method}<br>
        detail: ${s.detail}
      `;

      root.appendChild(el);
    });

  } catch (e) {
    console.error("panel error", e);
  }
}

setTimeout(renderPanel, 300);
setInterval(renderPanel, 5000);
</script>

JS

echo "OK ✅ yeni engine yazildi"

echo
echo "4. nginx reload..."
nginx -t && systemctl reload nginx
echo "OK ✅ reload"

echo
echo "=== STEP 367 TAMAM ✅ ==="
