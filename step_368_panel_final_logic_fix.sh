#!/bin/bash
set -e

echo "=== STEP 368 / PANEL FINAL LOGIC FIX ==="

PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"

echo
echo "1. backup aliniyor..."
cp "$PANEL_HTML" "${PANEL_HTML}.bak_step_368_$(date +%Y%m%d_%H%M%S)"
echo "OK ✅ backup alindi"

echo
echo "2. script block tamamen yeniden yaziliyor..."

python3 << 'PY'
from pathlib import Path
p = Path("/opt/pix2pi/nginx/panel_index.html")
html = p.read_text(encoding="utf-8")

import re

# eski script block varsa temizle
html = re.sub(r"<script>.*?</script>\s*</body>", "</body>", html, flags=re.S)

# planned alanı yoksa ekle
if 'id="plannedServices"' not in html:
    html = html.replace(
        '<h2>Planli Servisler</h2>',
        '<h2>Planli Servisler</h2>\n      <div id="plannedServices" class="service-grid" style="margin-top:14px"></div>'
    )

script = r'''
<script>
(function () {
  function esc(v) {
    return String(v ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function normalizeService(raw) {
    const svc = raw || {};
    const method = String(svc.method || "").toLowerCase();
    let status = String(svc.status || "").toUpperCase();

    // design servisler panelde planned kabul edilir
    if (method === "design") {
      status = "PLANNED";
    }

    return {
      name: svc.name || "-",
      status,
      method: svc.method || "-",
      detail: svc.detail || "-",
      response_ms: Number(svc.response_ms || 0),
      checked_at: svc.checked_at || "-",
      state: svc.state || {}
    };
  }

  function badgeClass(status) {
    if (status === "RUNNING") return "badge badge-running";
    if (status === "DEGRADED") return "badge badge-degraded";
    if (status === "PLANNED") return "badge badge-planned";
    return "badge badge-stopped";
  }

  function bannerMeta(globalStatus, running, stopped, degraded, planned) {
    const g = String(globalStatus || "").toUpperCase();

    if (g === "CRITICAL" || stopped > 0) {
      return {
        cls: "status-banner status-stopped",
        text: "Kritik: Bazi servisler ayakta degil"
      };
    }

    if (g === "DEGRADED" || degraded > 0) {
      return {
        cls: "status-banner status-degraded",
        text: "Uyari: Bazi servislerde performans / saglik sorunu var"
      };
    }

    if (running > 0) {
      return {
        cls: "status-banner status-running",
        text: "Sistem genel olarak calisiyor"
      };
    }

    if (planned > 0) {
      return {
        cls: "status-banner status-planned",
        text: "Sistemde planli ama aktif olmayan servisler var"
      };
    }

    return {
      cls: "status-banner status-stopped",
      text: "Servis verisi bulunamadi"
    };
  }

  function serviceCard(s) {
    return `
      <div class="service-card">
        <div style="display:flex;justify-content:space-between;align-items:center;gap:12px;margin-bottom:10px">
          <div style="font-weight:700">${esc(s.name)}</div>
          <div class="${badgeClass(s.status)}">${esc(s.status)}</div>
        </div>

        <div class="kv"><span>Kontrol</span><span>${esc(s.method)}</span></div>
        <div class="kv"><span>Detay</span><span>${esc(s.detail)}</span></div>
        <div class="kv"><span>Gecikme</span><span>${esc(s.response_ms)} ms</span></div>
        <div class="kv"><span>Kontrol zamani</span><span>${esc(s.checked_at)}</span></div>
      </div>
    `;
  }

  async function loadPanel() {
    try {
      const res = await fetch("/service-status.json", {
        cache: "no-store",
        headers: { "Accept": "application/json" }
      });

      if (!res.ok) {
        throw new Error("HTTP " + res.status);
      }

      const data = await res.json();
      const services = (data.services || []).map(normalizeService);

      const plannedServices = services.filter(s => s.status === "PLANNED");
      const liveServices = services.filter(s => s.status !== "PLANNED");

      const runningCount = services.filter(s => s.status === "RUNNING").length;
      const stoppedCount = services.filter(s => s.status === "STOPPED").length;
      const degradedCount = services.filter(s => s.status === "DEGRADED").length;
      const plannedCount = plannedServices.length;

      document.getElementById("runningCount").textContent = String(runningCount);
      document.getElementById("stoppedCount").textContent = String(stoppedCount);
      document.getElementById("degradedCount").textContent = String(degradedCount);
      document.getElementById("plannedCount").textContent = String(plannedCount);

      const updatedAtEl = document.getElementById("updatedAt");
      if (updatedAtEl) {
        updatedAtEl.textContent = data.updated_at || data.updatedAt || "-";
      }

      const banner = document.getElementById("overallBanner");
      if (banner) {
        const meta = bannerMeta(data.global_status, runningCount, stoppedCount, degradedCount, plannedCount);
        banner.className = meta.cls;
        banner.textContent = meta.text;
      }

      const liveRoot = document.getElementById("liveServices");
      if (liveRoot) {
        if (liveServices.length === 0) {
          liveRoot.innerHTML = '<div class="empty-box">Canli servis bulunamadi.</div>';
        } else {
          liveRoot.innerHTML = liveServices.map(serviceCard).join("");
        }
      }

      const plannedRoot = document.getElementById("plannedServices");
      if (plannedRoot) {
        if (plannedServices.length === 0) {
          plannedRoot.innerHTML = '<div class="empty-box">Planli servis yok.</div>';
        } else {
          plannedRoot.innerHTML = plannedServices.map(serviceCard).join("");
        }
      }

      const errorBox = document.getElementById("errorBox");
      if (errorBox) {
        errorBox.style.display = "none";
        errorBox.textContent = "";
      }

    } catch (err) {
      const banner = document.getElementById("overallBanner");
      if (banner) {
        banner.className = "status-banner status-degraded";
        banner.textContent = "Service monitor okunamadi";
      }

      const errorBox = document.getElementById("errorBox");
      if (errorBox) {
        errorBox.style.display = "block";
        errorBox.textContent = "Service monitor fetch hatasi: " + err.message;
      }

      const liveRoot = document.getElementById("liveServices");
      if (liveRoot) {
        liveRoot.innerHTML = '<div class="empty-box">Servis verisi alinamadi.</div>';
      }
    }
  }

  window.loadPanel = loadPanel;
  loadPanel();
  setInterval(loadPanel, 10000);
})();
</script>
</body>
'''

html = html.replace("</body>", script)
p.write_text(html, encoding="utf-8")
PY

echo "OK ✅ panel script yeniden yazildi"

echo
echo "3. html kontrol..."
grep -n 'id="plannedServices"' "$PANEL_HTML"
grep -n 'fetch("/service-status.json"' "$PANEL_HTML"
grep -n 'window.loadPanel = loadPanel' "$PANEL_HTML"
echo "OK ✅ html kontrol bitti"

echo
echo "4. nginx test..."
nginx -t
echo "OK ✅ nginx test"

echo
echo "5. reload..."
systemctl reload nginx
echo "OK ✅ reload"

echo
echo "6. public json test..."
curl -k -s https://panel.pix2pi.com.tr/service-status.json | jq '.services | length'
echo "OK ✅ public json test"

echo
echo "=== STEP 368 TAMAM ✅ ==="
