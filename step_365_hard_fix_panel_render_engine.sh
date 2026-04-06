#!/bin/bash
set -e

echo "=== STEP 365 / HARD FIX PANEL RENDER ENGINE ==="

PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"

echo
echo "1. backup..."
cp "$PANEL_HTML" "${PANEL_HTML}.bak_render_fix_$(date +%s)"
echo "OK ✅ backup"

echo
echo "2. render engine override inject..."

cat <<'JS' >> "$PANEL_HTML"

<script>
async function loadServicesSafe() {
  try {
    const res = await fetch("/service-status.json", { cache: "no-store" });
    const text = await res.text();

    // JSON safety parse
    let data;
    try {
      data = JSON.parse(text);
    } catch (e) {
      console.error("JSON PARSE FAIL", text);
      return;
    }

    if (!data.services) {
      console.error("NO SERVICES FIELD", data);
      return;
    }

    const services = data.services;

    // normalize
    const normalize = (s) => (s || "").toUpperCase();

    const running = services.filter(s => normalize(s.status) === "RUNNING").length;
    const stopped = services.filter(s => normalize(s.status) === "STOPPED").length;
    const degraded = services.filter(s => normalize(s.status) === "DEGRADED").length;

    // set counts
    document.getElementById("runningCount").textContent = running;
    document.getElementById("stoppedCount").textContent = stopped;
    document.getElementById("degradedCount").textContent = degraded;
    document.getElementById("plannedCount").textContent = "0";

    // render cards
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

  } catch (err) {
    console.error("LOAD FAIL", err);
  }
}

// force run
setTimeout(loadServicesSafe, 300);
setInterval(loadServicesSafe, 5000);
</script>

JS

echo "OK ✅ render engine inject"

echo
echo "3. reload nginx..."
nginx -t && systemctl reload nginx
echo "OK ✅ nginx reload"

echo
echo "=== STEP 365 TAMAM ✅ ==="
