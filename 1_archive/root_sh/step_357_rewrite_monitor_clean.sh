#!/bin/bash
set -e

FILE="/opt/pix2pi/nginx/monitor.html"

echo "=== STEP 357 / CLEAN MONITOR REWRITE ==="

echo
echo "1. backup..."
cp "$FILE" "$FILE.bak_$(date +%Y%m%d_%H%M%S)"
echo "OK ✅ backup alindi"

echo
echo "2. monitor.html yeniden yaziliyor..."
cat <<'HTML' > "$FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi Monitor</title>
  <style>
    :root{
      --bg:#f6f7fb;
      --card:#ffffff;
      --border:#e5e7eb;
      --text:#111827;
      --muted:#6b7280;
      --ok:#166534;
      --ok-bg:#dcfce7;
      --critical:#991b1b;
      --critical-bg:#fef2f2;
      --planned:#475569;
      --planned-bg:#f8fafc;
      --shadow:0 8px 24px rgba(15,23,42,.06);
      --radius:16px;
    }
    *{box-sizing:border-box}
    body{
      margin:0;
      background:var(--bg);
      color:var(--text);
      font-family:system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Arial,sans-serif;
    }
    .container{
      max-width:1200px;
      margin:0 auto;
      padding:20px;
    }
    .page-title{
      font-size:28px;
      font-weight:700;
      margin:0 0 16px 0;
    }
    .card{
      background:var(--card);
      border:1px solid var(--border);
      border-radius:var(--radius);
      box-shadow:var(--shadow);
      padding:18px;
      margin-bottom:18px;
    }
    .section-title{
      font-size:22px;
      font-weight:700;
      margin:0 0 10px 0;
    }
    .subtext{
      color:var(--muted);
      font-size:14px;
      margin:0;
    }
    .banner{
      border-radius:12px;
      padding:12px 14px;
      font-size:15px;
      font-weight:700;
      margin-bottom:14px;
    }
    .banner.running{
      background:var(--ok-bg);
      color:var(--ok);
    }
    .banner.critical{
      background:var(--critical-bg);
      color:var(--critical);
    }
    .summary-grid{
      display:grid;
      grid-template-columns:repeat(4,minmax(0,1fr));
      gap:12px;
      margin-top:12px;
    }
    .summary-box{
      border:1px solid var(--border);
      border-radius:12px;
      padding:14px;
      background:#fff;
    }
    .summary-label{
      font-size:13px;
      color:var(--muted);
      margin-bottom:6px;
    }
    .summary-value{
      font-size:30px;
      font-weight:700;
      line-height:1;
    }
    .services-grid{
      display:grid;
      grid-template-columns:repeat(3,minmax(0,1fr));
      gap:14px;
      margin-top:14px;
    }
    .service-card{
      border:1px solid var(--border);
      border-radius:14px;
      padding:14px;
      background:#fff;
    }
    .service-head{
      display:flex;
      align-items:center;
      justify-content:space-between;
      gap:8px;
      margin-bottom:10px;
    }
    .service-name{
      font-size:16px;
      font-weight:700;
      word-break:break-word;
    }
    .pill{
      font-size:12px;
      font-weight:700;
      padding:5px 10px;
      border-radius:999px;
      white-space:nowrap;
    }
    .pill.running{
      background:var(--ok-bg);
      color:var(--ok);
    }
    .pill.stopped{
      background:var(--critical-bg);
      color:var(--critical);
    }
    .pill.planned{
      background:var(--planned-bg);
      color:var(--planned);
    }
    .service-meta{
      font-size:13px;
      color:var(--muted);
      line-height:1.65;
    }
    .links{
      margin:0;
      padding-left:18px;
    }
    .links li{
      margin:6px 0;
    }
    .links a{
      color:#2563eb;
      text-decoration:none;
    }
    .empty-box{
      border:1px dashed var(--border);
      border-radius:12px;
      padding:16px;
      color:var(--muted);
      background:#fff;
    }
    @media (max-width:900px){
      .summary-grid{grid-template-columns:repeat(2,minmax(0,1fr))}
      .services-grid{grid-template-columns:1fr}
    }
  </style>
</head>
<body>
  <div class="container">
    <h1 class="page-title">Pix2pi Monitor</h1>

    <div class="card">
      <h2 class="section-title">Genel Durum</h2>
      <div id="overallBanner" class="banner critical">Kritik: Veri bekleniyor</div>

      <div class="summary-grid">
        <div class="summary-box">
          <div class="summary-label">Calisan servis</div>
          <div id="runningCount" class="summary-value">0</div>
        </div>
        <div class="summary-box">
          <div class="summary-label">Duran servis</div>
          <div id="stoppedCount" class="summary-value">0</div>
        </div>
        <div class="summary-box">
          <div class="summary-label">Bozulmus servis</div>
          <div id="degradedCount" class="summary-value">0</div>
        </div>
        <div class="summary-box">
          <div class="summary-label">Planli servis</div>
          <div id="plannedCount" class="summary-value">0</div>
        </div>
      </div>

      <p class="subtext" style="margin-top:14px;">Son guncelleme: <span id="updatedAt">veri alinmadi</span></p>
    </div>

    <div class="card">
      <h2 class="section-title">Canli Servisler</h2>
      <p class="subtext">Bu alan watchdog /status verisi ile dolar.</p>
      <div id="liveServices" class="services-grid"></div>
    </div>

    <div class="card">
      <h2 class="section-title">Hizli Baglantilar</h2>
      <ul class="links">
        <li><a href="/health">Panel Health</a></li>
        <li><a href="/api/health">API Health</a></li>
        <li><a href="/internal/service-monitor">Service Monitor JSON</a></li>
        <li><a href="http://127.0.0.1:8090/health">Watchdog Health</a></li>
        <li><a href="/monitor">Monitor</a></li>
      </ul>
    </div>
  </div>

  <script>
    function escapeHtml(v) {
      return String(v ?? "")
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#39;");
    }

    function normalizeStatus(v) {
      const s = String(v || "").toUpperCase();
      if (s === "RUNNING") return "RUNNING";
      if (s === "DEGRADED") return "DEGRADED";
      if (s === "PLANNED") return "PLANNED";
      return "STOPPED";
    }

    function pillClass(status) {
      if (status === "RUNNING") return "running";
      if (status === "PLANNED") return "planned";
      return "stopped";
    }

    function computeBanner(services) {
      const running = services.filter(s => normalizeStatus(s.status) === "RUNNING").length;
      const degraded = services.filter(s => normalizeStatus(s.status) === "DEGRADED").length;
      const stopped = services.filter(s => normalizeStatus(s.status) === "STOPPED").length;

      if (stopped > 0 || degraded > 0) {
        return {
          cls: "banner critical",
          text: "Kritik: Bazi servisler ayakta degil"
        };
      }

      if (running > 0) {
        return {
          cls: "banner running",
          text: "Sistem calisiyor"
        };
      }

      return {
        cls: "banner critical",
        text: "Kritik: Veri bekleniyor"
      };
    }

    function renderServices(services) {
      const box = document.getElementById("liveServices");
      if (!services.length) {
        box.innerHTML = '<div class="empty-box">Veri alinmadi.</div>';
        return;
      }

      box.innerHTML = services.map(s => {
        const st = normalizeStatus(s.status);
        return `
          <div class="service-card">
            <div class="service-head">
              <div class="service-name">${escapeHtml(s.name)}</div>
              <div class="pill ${pillClass(st)}">${escapeHtml(st)}</div>
            </div>
            <div class="service-meta">
              Kontrol: ${escapeHtml(s.method || "-")}<br>
              Detay: ${escapeHtml(s.detail || "-")}<br>
              Gecikme: ${escapeHtml(String(s.response_ms ?? 0))} ms<br>
              Kontrol zamani: ${escapeHtml(s.checked_at || "-")}
            </div>
          </div>
        `;
      }).join("");
    }

    async function loadMonitor() {
      try {
        const res = await fetch("http://127.0.0.1:8090/status");
        const data = await res.json();

        const services = Array.isArray(data.services) ? data.services : [];

        const running = services.filter(s => normalizeStatus(s.status) === "RUNNING").length;
        const stopped = services.filter(s => normalizeStatus(s.status) === "STOPPED").length;
        const degraded = services.filter(s => normalizeStatus(s.status) === "DEGRADED").length;
        const planned = services.filter(s => normalizeStatus(s.status) === "PLANNED").length;

        document.getElementById("runningCount").textContent = String(running);
        document.getElementById("stoppedCount").textContent = String(stopped);
        document.getElementById("degradedCount").textContent = String(degraded);
        document.getElementById("plannedCount").textContent = String(planned);
        document.getElementById("updatedAt").textContent = data.updated_at || "-";

        const banner = computeBanner(services);
        const bannerBox = document.getElementById("overallBanner");
        bannerBox.className = banner.cls;
        bannerBox.textContent = banner.text;

        renderServices(services);
      } catch (err) {
        document.getElementById("runningCount").textContent = "0";
        document.getElementById("stoppedCount").textContent = "0";
        document.getElementById("degradedCount").textContent = "0";
        document.getElementById("plannedCount").textContent = "0";
        document.getElementById("updatedAt").textContent = "veri alinmadi";
        document.getElementById("liveServices").innerHTML =
          '<div class="empty-box">Veri alinmadi.</div>';

        const bannerBox = document.getElementById("overallBanner");
        bannerBox.className = "banner critical";
        bannerBox.textContent = "Kritik: Bazi servisler ayakta degil";
      }
    }

    loadMonitor();
    setInterval(loadMonitor, 10000);
  </script>
</body>
</html>
HTML

echo "OK ✅ monitor.html yazildi"

echo
echo "3. local test..."
grep -n 'id="liveServices"' "$FILE"
grep -n 'fetch("http://127.0.0.1:8090/status")' "$FILE"
echo "OK ✅ html kontrol bitti"

echo
echo "4. nginx test..."
nginx -t
echo "OK ✅ nginx test"

echo
echo "5. reload..."
systemctl reload nginx
echo "OK ✅ nginx reload"

echo
echo "6. local monitor test..."
curl -k -I https://127.0.0.1/monitor || true

echo
echo "OK ✅ step 357 tamam"
