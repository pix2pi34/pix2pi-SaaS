#!/bin/bash
set -e

MONITOR_FILE="/opt/pix2pi/nginx/monitor.html"
BACKUP_FILE="${MONITOR_FILE}.bak_$(date +%Y%m%d_%H%M%S)"

echo "=== STEP 353 / MONITOR V2 REWRITE ==="

echo
echo "1. backup aliniyor..."
cp "$MONITOR_FILE" "$BACKUP_FILE"
echo "OK ✅ backup alindi: $BACKUP_FILE"

echo
echo "2. monitor.html yeniden yaziliyor..."
cat <<'HTML' > "$MONITOR_FILE"
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
      --running:#15803d;
      --running-bg:#ecfdf5;
      --stopped:#b91c1c;
      --stopped-bg:#fef2f2;
      --planned:#475569;
      --planned-bg:#f8fafc;
      --degraded:#b45309;
      --degraded-bg:#fff7ed;
      --critical:#991b1b;
      --critical-bg:#fef2f2;
      --ok:#166534;
      --ok-bg:#dcfce7;
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
    }

    .service-card{
      border:1px solid var(--border);
      border-radius:14px;
      background:#fff;
      padding:14px;
    }

    .service-head{
      display:flex;
      justify-content:space-between;
      align-items:center;
      gap:10px;
      margin-bottom:12px;
    }

    .service-name{
      font-size:18px;
      font-weight:700;
      line-height:1.2;
      word-break:break-word;
    }

    .badge{
      display:inline-flex;
      align-items:center;
      justify-content:center;
      min-width:88px;
      padding:6px 10px;
      border-radius:999px;
      font-size:12px;
      font-weight:700;
      border:1px solid transparent;
      white-space:nowrap;
    }

    .badge.running{
      color:var(--running);
      background:var(--running-bg);
      border-color:#bbf7d0;
    }

    .badge.stopped{
      color:var(--stopped);
      background:var(--stopped-bg);
      border-color:#fecaca;
    }

    .badge.planned{
      color:var(--planned);
      background:var(--planned-bg);
      border-color:#cbd5e1;
    }

    .badge.degraded{
      color:var(--degraded);
      background:var(--degraded-bg);
      border-color:#fed7aa;
    }

    .service-table{
      display:grid;
      grid-template-columns:110px 1fr;
      row-gap:8px;
      column-gap:10px;
      font-size:14px;
    }

    .k{
      color:var(--muted);
    }

    .v{
      font-weight:600;
      word-break:break-word;
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

    .links a:hover{
      text-decoration:underline;
    }

    .loading{
      color:var(--muted);
      font-size:14px;
    }

    @media (max-width: 960px){
      .services-grid{
        grid-template-columns:repeat(2,minmax(0,1fr));
      }

      .summary-grid{
        grid-template-columns:repeat(2,minmax(0,1fr));
      }
    }

    @media (max-width: 640px){
      .container{
        padding:14px;
      }

      .page-title{
        font-size:24px;
      }

      .section-title{
        font-size:20px;
      }

      .services-grid,
      .summary-grid{
        grid-template-columns:1fr;
      }

      .service-table{
        grid-template-columns:90px 1fr;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <h1 class="page-title">Pix2pi Monitor</h1>

    <section class="card">
      <h2 class="section-title">Genel Durum</h2>
      <div id="globalBanner" class="banner critical">Yukleniyor...</div>

      <div class="summary-grid">
        <div class="summary-box">
          <div class="summary-label">Calisan servis</div>
          <div id="countRunning" class="summary-value">0</div>
        </div>
        <div class="summary-box">
          <div class="summary-label">Duran servis</div>
          <div id="countStopped" class="summary-value">0</div>
        </div>
        <div class="summary-box">
          <div class="summary-label">Bozulmus servis</div>
          <div id="countDegraded" class="summary-value">0</div>
        </div>
        <div class="summary-box">
          <div class="summary-label">Planli servis</div>
          <div id="countPlanned" class="summary-value">0</div>
        </div>
      </div>

      <p id="metaLine" class="subtext" style="margin-top:12px;">Son guncelleme: -</p>
    </section>

    <section class="card">
      <h2 class="section-title">Canli Servisler</h2>
      <p class="subtext">Bu alan watchdog /status verisi ile dolar.</p>
      <div id="servicesGrid" class="services-grid" style="margin-top:14px;">
        <div class="loading">Veri bekleniyor...</div>
      </div>
    </section>

    <section class="card">
      <h2 class="section-title">Hizli Baglantilar</h2>
      <ul class="links">
        <li><a href="/health" target="_blank" rel="noopener">Panel Health</a></li>
        <li><a href="/api/health" target="_blank" rel="noopener">API Health</a></li>
        <li><a href="/internal/service-monitor" target="_blank" rel="noopener">Service Monitor JSON</a></li>
        <li><a href="/internal/service-watchdog-health" target="_blank" rel="noopener">Watchdog Health</a></li>
        <li><a href="/monitor" target="_blank" rel="noopener">Monitor</a></li>
      </ul>
    </section>
  </div>

  <script>
    function escapeHtml(value) {
      return String(value ?? "")
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#039;");
    }

    function badgeClass(status) {
      const s = String(status || "").toUpperCase();
      if (s === "RUNNING") return "running";
      if (s === "DEGRADED") return "degraded";
      if (s === "PLANNED") return "planned";
      return "stopped";
    }

    function renderGlobal(globalStatus) {
      const banner = document.getElementById("globalBanner");
      const s = String(globalStatus || "UNKNOWN").toUpperCase();

      if (s === "RUNNING") {
        banner.className = "banner running";
        banner.textContent = "Sistem saglikli calisiyor";
        return;
      }

      if (s === "DEGRADED") {
        banner.className = "banner critical";
        banner.textContent = "Dikkat: Sistem kismen bozulmus durumda";
        return;
      }

      if (s === "CRITICAL") {
        banner.className = "banner critical";
        banner.textContent = "Kritik: Bazi servisler ayakta degil";
        return;
      }

      banner.className = "banner critical";
      banner.textContent = "Durum alinamadi";
    }

    function renderCounts(services) {
      let running = 0;
      let stopped = 0;
      let degraded = 0;
      let planned = 0;

      for (const svc of services) {
        const s = String(svc.status || "").toUpperCase();
        if (s === "RUNNING") running++;
        else if (s === "DEGRADED") degraded++;
        else if (s === "PLANNED") planned++;
        else stopped++;
      }

      document.getElementById("countRunning").textContent = String(running);
      document.getElementById("countStopped").textContent = String(stopped);
      document.getElementById("countDegraded").textContent = String(degraded);
      document.getElementById("countPlanned").textContent = String(planned);
    }

    function renderServices(services) {
      const grid = document.getElementById("servicesGrid");

      if (!Array.isArray(services) || services.length === 0) {
        grid.innerHTML = '<div class="loading">Servis verisi bulunamadi.</div>';
        return;
      }

      grid.innerHTML = services.map((svc) => {
        const name = escapeHtml(svc.name || "-");
        const status = String(svc.status || "UNKNOWN").toUpperCase();
        const method = escapeHtml(svc.method || "-");
        const detail = escapeHtml(svc.detail || "-");
        const checkedAt = escapeHtml(svc.checked_at || "-");
        const responseMS = Number.isFinite(Number(svc.response_ms)) ? `${svc.response_ms} ms` : "-";

        return `
          <article class="service-card">
            <div class="service-head">
              <div class="service-name">${name}</div>
              <span class="badge ${badgeClass(status)}">${escapeHtml(status)}</span>
            </div>

            <div class="service-table">
              <div class="k">Kontrol</div>
              <div class="v">${method}</div>

              <div class="k">Detay</div>
              <div class="v">${detail}</div>

              <div class="k">Gecikme</div>
              <div class="v">${responseMS}</div>

              <div class="k">Kontrol zamani</div>
              <div class="v">${checkedAt}</div>
            </div>
          </article>
        `;
      }).join("");
    }

    async function loadStatus() {
      try {
        const response = await fetch("/internal/service-monitor", {
          method: "GET",
          cache: "no-store"
        });

        if (!response.ok) {
          throw new Error("status fetch failed");
        }

        const data = await response.json();

        renderGlobal(data.global_status || "CRITICAL");
        renderCounts(data.services || []);
        renderServices(data.services || []);

        document.getElementById("metaLine").textContent =
          `Son guncelleme: ${data.updated_at || "-"}`;
      } catch (error) {
        renderGlobal("CRITICAL");
        document.getElementById("servicesGrid").innerHTML =
          '<div class="loading">Veri alinamadi.</div>';
        document.getElementById("metaLine").textContent =
          "Son guncelleme: veri alinamadi";
      }
    }

    loadStatus();
    setInterval(loadStatus, 10000);
  </script>
</body>
</html>
HTML

chmod 644 "$MONITOR_FILE"
echo "OK ✅ monitor.html yeniden yazildi"

echo
echo "3. local html test..."
test -f "$MONITOR_FILE"
echo "OK ✅ dosya mevcut"

echo
echo "4. local endpoint test..."
curl -s http://127.0.0.1:8090/status > /tmp/pix2pi_monitor_status_test.json
test -s /tmp/pix2pi_monitor_status_test.json
echo "OK ✅ status json alindi"

echo
echo "5. local page header test..."
curl -k -I https://127.0.0.1/monitor || true

echo
echo "OK ✅ step 353 tamam"
