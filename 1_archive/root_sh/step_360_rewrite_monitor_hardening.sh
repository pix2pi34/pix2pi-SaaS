#!/bin/bash
set -e

echo "=== STEP 360 / HARDEN MONITOR REWRITE ==="

MONITOR_FILE="/opt/pix2pi/nginx/monitor.html"
BACKUP_FILE="/opt/pix2pi/nginx/monitor.html.bak_$(date +%Y%m%d_%H%M%S)"

echo
echo "1. backup aliniyor..."
if [ -f "$MONITOR_FILE" ]; then
  cp "$MONITOR_FILE" "$BACKUP_FILE"
  echo "OK ✅ backup: $BACKUP_FILE"
else
  echo "OK ✅ eski monitor yok, yeni dosya yazilacak"
fi

echo
echo "2. monitor.html yeniden yaziliyor..."
cat <<'HTML' > "$MONITOR_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
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

      --warn:#92400e;
      --warn-bg:#fef3c7;

      --danger:#991b1b;
      --danger-bg:#fef2f2;

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
      max-width:1280px;
      margin:0 auto;
      padding:20px;
    }

    h1{
      margin:0 0 16px 0;
      font-size:32px;
      line-height:1.1;
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
      margin:0 0 10px 0;
      font-size:24px;
      font-weight:700;
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
      border:1px solid transparent;
    }

    .banner.running{
      color:var(--ok);
      background:var(--ok-bg);
      border-color:#bbf7d0;
    }

    .banner.degraded{
      color:var(--warn);
      background:var(--warn-bg);
      border-color:#fde68a;
    }

    .banner.critical{
      color:var(--danger);
      background:var(--danger-bg);
      border-color:#fecaca;
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
      font-size:32px;
      font-weight:800;
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
      padding:14px;
      background:#fff;
      min-height:170px;
    }

    .service-head{
      display:flex;
      align-items:center;
      justify-content:space-between;
      gap:10px;
      margin-bottom:10px;
    }

    .service-name{
      font-size:18px;
      font-weight:700;
      word-break:break-word;
    }

    .badge{
      border-radius:999px;
      padding:4px 10px;
      font-size:11px;
      font-weight:800;
      border:1px solid transparent;
      white-space:nowrap;
    }

    .badge.running{
      color:var(--ok);
      background:var(--ok-bg);
      border-color:#bbf7d0;
    }

    .badge.degraded{
      color:var(--warn);
      background:var(--warn-bg);
      border-color:#fde68a;
    }

    .badge.stopped{
      color:var(--danger);
      background:var(--danger-bg);
      border-color:#fecaca;
    }

    .badge.planned{
      color:var(--planned);
      background:var(--planned-bg);
      border-color:#cbd5e1;
    }

    .kv{
      display:grid;
      grid-template-columns:100px 1fr;
      gap:8px 10px;
      font-size:13px;
      margin-top:8px;
    }

    .k{
      color:var(--muted);
    }

    .v{
      word-break:break-word;
    }

    .empty-box, .error-box{
      border:1px dashed var(--border);
      border-radius:12px;
      padding:16px;
      color:var(--muted);
      background:#fff;
    }

    .error-box{
      display:none;
      margin-top:12px;
      color:var(--danger);
      border-color:#fecaca;
      background:var(--danger-bg);
    }

    .links{
      margin:0;
      padding-left:18px;
      line-height:1.9;
    }

    @media (max-width: 1100px){
      .services-grid{grid-template-columns:repeat(2,minmax(0,1fr))}
    }

    @media (max-width: 700px){
      .summary-grid{grid-template-columns:repeat(2,minmax(0,1fr))}
      .services-grid{grid-template-columns:1fr}
      .kv{grid-template-columns:92px 1fr}
      h1{font-size:28px}
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Pix2pi Monitor</h1>

    <div class="card">
      <div class="section-title">Genel Durum</div>
      <div id="overallBanner" class="banner degraded">Veri okunuyor...</div>

      <div class="summary-grid">
        <div class="summary-box">
          <div class="summary-label">Calisan servis</div>
          <div id="runningCount" class="summary-value">-</div>
        </div>
        <div class="summary-box">
          <div class="summary-label">Duran servis</div>
          <div id="stoppedCount" class="summary-value">-</div>
        </div>
        <div class="summary-box">
          <div class="summary-label">Bozulmus servis</div>
          <div id="degradedCount" class="summary-value">-</div>
        </div>
        <div class="summary-box">
          <div class="summary-label">Planli servis</div>
          <div id="plannedCount" class="summary-value">-</div>
        </div>
      </div>

      <p class="subtext" style="margin-top:12px">Son guncelleme: <span id="updatedAt">-</span></p>
      <div id="errorBox" class="error-box"></div>
    </div>

    <div class="card">
      <div class="section-title">Canli Servisler</div>
      <p class="subtext">Bu alan watchdog /status verisi ile dolar.</p>
      <div id="liveServices" class="services-grid" style="margin-top:14px"></div>
    </div>

    <div class="card">
      <div class="section-title">Hizli Baglantilar</div>
      <ul class="links">
        <li><a href="/health">Panel Health</a></li>
        <li><a href="/api/health">API Health</a></li>
        <li><a href="/status">Service Monitor JSON</a></li>
        <li><a href="/watchdog-health">Watchdog Health</a></li>
        <li><a href="/monitor">Monitor</a></li>
      </ul>
    </div>
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

    function normalizeStatus(status) {
      const s = String(status || "").trim().toUpperCase();
      if (s === "RUNNING") return "RUNNING";
      if (s === "DEGRADED" || s === "FLAPPING") return "DEGRADED";
      if (s === "PLANNED") return "PLANNED";
      if (s === "STOPPED") return "STOPPED";
      return "STOPPED";
    }

    function badgeClass(status) {
      const s = normalizeStatus(status);
      if (s === "RUNNING") return "running";
      if (s === "DEGRADED") return "degraded";
      if (s === "PLANNED") return "planned";
      return "stopped";
    }

    function computeOverallStatus(services, globalStatus) {
      const g = String(globalStatus || "").trim().toUpperCase();
      if (g === "CRITICAL" || g === "STOPPED") {
        return { cls: "critical", text: "Kritik: Bazi servisler ayakta degil" };
      }
      if (g === "DEGRADED" || g === "FLAPPING") {
        return { cls: "degraded", text: "Uyari: Sistem kismen bozulmus durumda" };
      }

      const normalized = services.map(s => normalizeStatus(s.status));
      if (normalized.some(s => s === "STOPPED")) {
        return { cls: "critical", text: "Kritik: Bazi servisler ayakta degil" };
      }
      if (normalized.some(s => s === "DEGRADED")) {
        return { cls: "degraded", text: "Uyari: Bazi servislerde bozulma var" };
      }
      return { cls: "running", text: "Tum aktif servisler saglikli calisiyor" };
    }

    function renderServiceCard(service) {
      const status = normalizeStatus(service.status);
      const method = escapeHtml(service.method || "-");
      const detail = escapeHtml(service.detail || "-");
      const checkedAt = escapeHtml(service.checked_at || "-");
      const responseMS = Number(service.response_ms || 0);

      return `
        <div class="service-card">
          <div class="service-head">
            <div class="service-name">${escapeHtml(service.name || "-")}</div>
            <div class="badge ${badgeClass(status)}">${escapeHtml(status)}</div>
          </div>

          <div class="kv">
            <div class="k">Kontrol</div><div class="v">${method}</div>
            <div class="k">Detay</div><div class="v">${detail}</div>
            <div class="k">Gecikme</div><div class="v">${responseMS} ms</div>
            <div class="k">Kontrol zamani</div><div class="v">${checkedAt}</div>
          </div>
        </div>
      `;
    }

    async function loadMonitor() {
      const liveBox = document.getElementById("liveServices");
      const errorBox = document.getElementById("errorBox");

      try {
        errorBox.style.display = "none";
        errorBox.textContent = "";

        const res = await fetch("/status", {
          method: "GET",
          headers: { "Accept": "application/json" },
          cache: "no-store"
        });

        if (!res.ok) {
          throw new Error("HTTP " + res.status);
        }

        const data = await res.json();
        const services = Array.isArray(data.services) ? data.services : [];
        const globalStatus = data.global_status || "";

        const runningCount  = services.filter(s => normalizeStatus(s.status) === "RUNNING").length;
        const stoppedCount  = services.filter(s => normalizeStatus(s.status) === "STOPPED").length;
        const degradedCount = services.filter(s => normalizeStatus(s.status) === "DEGRADED").length;
        const plannedCount  = services.filter(s => normalizeStatus(s.status) === "PLANNED").length;

        document.getElementById("runningCount").textContent  = String(runningCount);
        document.getElementById("stoppedCount").textContent  = String(stoppedCount);
        document.getElementById("degradedCount").textContent = String(degradedCount);
        document.getElementById("plannedCount").textContent  = String(plannedCount);
        document.getElementById("updatedAt").textContent     = escapeHtml(data.updated_at || "-");

        const overall = computeOverallStatus(services, globalStatus);
        const banner = document.getElementById("overallBanner");
        banner.className = "banner " + overall.cls;
        banner.textContent = overall.text;

        if (services.length === 0) {
          liveBox.innerHTML = '<div class="empty-box">Servis verisi gelmedi.</div>';
        } else {
          liveBox.innerHTML = services.map(renderServiceCard).join("");
        }
      } catch (err) {
        document.getElementById("runningCount").textContent  = "0";
        document.getElementById("stoppedCount").textContent  = "0";
        document.getElementById("degradedCount").textContent = "0";
        document.getElementById("plannedCount").textContent  = "0";
        document.getElementById("updatedAt").textContent     = "-";

        const banner = document.getElementById("overallBanner");
        banner.className = "banner critical";
        banner.textContent = "Service monitor okunamadi";

        liveBox.innerHTML = '<div class="empty-box">Veri alinamadi.</div>';
        errorBox.style.display = "block";
        errorBox.textContent = "Service monitor fetch hatasi: " + err.message;
      }
    }

    loadMonitor();
    setInterval(loadMonitor, 10000);
  </script>
</body>
</html>
HTML
echo "OK ✅ monitor yazildi"

echo
echo "3. local html kontrol..."
grep -n 'id="liveServices"' "$MONITOR_FILE"
grep -n 'fetch("/status"' "$MONITOR_FILE"
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
curl -k -I https://127.0.0.1/monitor
echo "OK ✅ local monitor test"

echo
echo "7. json test..."
curl -s http://127.0.0.1:8090/status | jq '.services | length'
echo "OK ✅ json test"

echo
echo "OK ✅ step 360 tamam"
