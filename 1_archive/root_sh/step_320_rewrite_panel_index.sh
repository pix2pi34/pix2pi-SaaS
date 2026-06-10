#!/bin/bash
set -e

PANEL_FILE="/opt/pix2pi/nginx/panel_index.html"

cat <<'HTML' > "$PANEL_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Pix2pi Admin Panel</title>
  <style>
    :root{
      --bg:#f6f7fb;
      --card:#ffffff;
      --border:#e5e7eb;
      --text:#111827;
      --muted:#6b7280;
      --ok:#15803d;
      --warn:#b45309;
      --critical:#b91c1c;
      --planned:#475569;
      --running-bg:#ecfdf5;
      --stopped-bg:#fef2f2;
      --degraded-bg:#fff7ed;
      --planned-bg:#f8fafc;
      --shadow:0 8px 24px rgba(15,23,42,.06);
      --radius:16px;
    }

    *{box-sizing:border-box}
    body{
      margin:0;
      font-family:system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Arial,sans-serif;
      background:var(--bg);
      color:var(--text);
    }

    .container{
      max-width:1200px;
      margin:0 auto;
      padding:20px;
    }

    .page-title{
      font-size:32px;
      font-weight:800;
      margin:8px 0 20px 0;
      letter-spacing:-.02em;
    }

    .section{
      background:var(--card);
      border:1px solid var(--border);
      border-radius:var(--radius);
      padding:18px;
      margin-bottom:18px;
      box-shadow:var(--shadow);
    }

    .section h2{
      margin:0 0 12px 0;
      font-size:22px;
    }

    .muted{
      color:var(--muted);
      font-size:14px;
    }

    .summary-grid{
      display:grid;
      grid-template-columns:repeat(auto-fit,minmax(180px,1fr));
      gap:12px;
      margin-top:14px;
    }

    .summary-card{
      border:1px solid var(--border);
      border-radius:14px;
      padding:14px;
      background:#fff;
    }

    .summary-label{
      font-size:13px;
      color:var(--muted);
      margin-bottom:6px;
    }

    .summary-value{
      font-size:28px;
      font-weight:800;
      line-height:1.1;
    }

    .status-banner{
      border-radius:14px;
      padding:14px 16px;
      font-weight:700;
      border:1px solid var(--border);
      margin-top:8px;
    }

    .status-running{
      background:var(--running-bg);
      color:var(--ok);
    }

    .status-degraded{
      background:var(--degraded-bg);
      color:var(--warn);
    }

    .status-stopped{
      background:var(--stopped-bg);
      color:var(--critical);
    }

    .status-planned{
      background:var(--planned-bg);
      color:var(--planned);
    }

    .service-grid{
      display:grid;
      grid-template-columns:repeat(auto-fit,minmax(240px,1fr));
      gap:14px;
      margin-top:14px;
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
      font-size:17px;
      font-weight:800;
      word-break:break-word;
    }

    .badge{
      font-size:12px;
      font-weight:800;
      padding:6px 10px;
      border-radius:999px;
      border:1px solid transparent;
      white-space:nowrap;
    }

    .badge-running{
      color:var(--ok);
      background:var(--running-bg);
      border-color:#bbf7d0;
    }

    .badge-stopped{
      color:var(--critical);
      background:var(--stopped-bg);
      border-color:#fecaca;
    }

    .badge-degraded{
      color:var(--warn);
      background:var(--degraded-bg);
      border-color:#fed7aa;
    }

    .badge-planned{
      color:var(--planned);
      background:var(--planned-bg);
      border-color:#cbd5e1;
    }

    .detail-list{
      display:grid;
      gap:8px;
      font-size:14px;
    }

    .detail-row{
      display:flex;
      justify-content:space-between;
      gap:12px;
      border-top:1px dashed var(--border);
      padding-top:8px;
    }

    .detail-key{
      color:var(--muted);
      min-width:90px;
    }

    .detail-value{
      text-align:right;
      word-break:break-word;
      font-weight:600;
    }

    .link-list{
      margin:0;
      padding-left:18px;
      line-height:1.8;
    }

    .link-list a{
      color:#2563eb;
      text-decoration:none;
    }

    .empty-box{
      border:1px dashed var(--border);
      border-radius:14px;
      padding:16px;
      color:var(--muted);
      background:#fff;
    }

    .error-box{
      background:#fff7ed;
      color:#9a3412;
      border:1px solid #fdba74;
      border-radius:14px;
      padding:14px;
      margin-top:12px;
      display:none;
      white-space:pre-wrap;
    }

    .footer-note{
      margin-top:10px;
      color:var(--muted);
      font-size:13px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="page-title">Pix2pi Admin Panel</div>

    <div class="section">
      <h2>Genel Durum</h2>
      <div id="overallBanner" class="status-banner status-planned">Yukleniyor...</div>

      <div class="summary-grid">
        <div class="summary-card">
          <div class="summary-label">Calisan servis</div>
          <div class="summary-value" id="runningCount">0</div>
        </div>
        <div class="summary-card">
          <div class="summary-label">Duran servis</div>
          <div class="summary-value" id="stoppedCount">0</div>
        </div>
        <div class="summary-card">
          <div class="summary-label">Bozulmus servis</div>
          <div class="summary-value" id="degradedCount">0</div>
        </div>
        <div class="summary-card">
          <div class="summary-label">Planli servis</div>
          <div class="summary-value" id="plannedCount">0</div>
        </div>
      </div>

      <div class="footer-note">
        Otomatik yenileme: 10 saniye<br>
        Son guncelleme: <span id="updatedAt">-</span>
      </div>

      <div id="fetchError" class="error-box"></div>
    </div>

    <div class="section">
      <h2>Canli Servisler</h2>
      <div class="muted">Bu alan gercek watchdog verisi ile dolar.</div>
      <div id="liveServices" class="service-grid"></div>
    </div>

    <div class="section">
      <h2>Planli Servisler</h2>
      <div class="muted">Bu servisler mimaride var, ancak henuz aktif devreye alinmadi.</div>
      <div id="plannedServices" class="service-grid"></div>
    </div>

    <div class="section">
      <h2>Hizli Baglantilar</h2>
      <ul class="link-list">
        <li><a href="/health" target="_blank">Panel Health</a></li>
        <li><a href="/api/health" target="_blank">API Health</a></li>
        <li><a href="/internal/service-monitor" target="_blank">Service Monitor JSON</a></li>
        <li><a href="/internal/service-watchdog-health" target="_blank">Watchdog Health</a></li>
        <li><a href="https://server.pix2pi.com.tr/containers/" target="_blank">Server Monitor</a></li>
      </ul>
    </div>
  </div>

  <script>
    const PLANNED_SERVICES = [
      { name: "auth", detail: "Planli servis" },
      { name: "stock_service", detail: "Planli servis" }
    ];

    function escapeHtml(value) {
      return String(value ?? "")
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#039;");
    }

    function normalizeStatus(raw) {
      const val = String(raw || "").toUpperCase();

      if (val === "RUNNING") return "RUNNING";
      if (val === "STOPPED") return "STOPPED";
      if (val === "DEGRADED") return "DEGRADED";
      if (val === "PLANNED") return "PLANNED";

      return "STOPPED";
    }

    function statusBadgeClass(status) {
      if (status === "RUNNING") return "badge badge-running";
      if (status === "DEGRADED") return "badge badge-degraded";
      if (status === "PLANNED") return "badge badge-planned";
      return "badge badge-stopped";
    }

    function renderServiceCard(service) {
      const status = normalizeStatus(service.status);
      const method = service.method || "-";
      const detail = service.detail || "-";
      const checkedAt = service.checked_at || "-";
      const responseMs = service.response_ms ?? "-";

      return `
        <div class="service-card">
          <div class="service-head">
            <div class="service-name">${escapeHtml(service.name)}</div>
            <div class="${statusBadgeClass(status)}">${escapeHtml(status)}</div>
          </div>

          <div class="detail-list">
            <div class="detail-row">
              <div class="detail-key">Kontrol</div>
              <div class="detail-value">${escapeHtml(method)}</div>
            </div>
            <div class="detail-row">
              <div class="detail-key">Detay</div>
              <div class="detail-value">${escapeHtml(detail)}</div>
            </div>
            <div class="detail-row">
              <div class="detail-key">Gecikme</div>
              <div class="detail-value">${escapeHtml(responseMs)} ms</div>
            </div>
            <div class="detail-row">
              <div class="detail-key">Kontrol zamani</div>
              <div class="detail-value">${escapeHtml(checkedAt)}</div>
            </div>
          </div>
        </div>
      `;
    }

    function computeOverallStatus(services) {
      const running = services.filter(s => normalizeStatus(s.status) === "RUNNING").length;
      const stopped = services.filter(s => normalizeStatus(s.status) === "STOPPED").length;
      const degraded = services.filter(s => normalizeStatus(s.status) === "DEGRADED").length;

      if (stopped > 0) {
        return {
          text: "Kritik: Bazi servisler ayakta degil",
          cls: "status-banner status-stopped"
        };
      }

      if (degraded > 0) {
        return {
          text: "Uyari: Bazi servislerde bozulma var",
          cls: "status-banner status-degraded"
        };
      }

      if (running > 0) {
        return {
          text: "Sistem saglikli: Tum aktif servisler calisiyor",
          cls: "status-banner status-running"
        };
      }

      return {
        text: "Veri bekleniyor",
        cls: "status-banner status-planned"
      };
    }

    function renderPlannedCards() {
      const plannedRoot = document.getElementById("plannedServices");
      plannedRoot.innerHTML = PLANNED_SERVICES.map(item => renderServiceCard({
        name: item.name,
        status: "PLANNED",
        method: "design",
        detail: item.detail,
        checked_at: "-",
        response_ms: "-"
      })).join("");
    }

    async function loadMonitor() {
      const errorBox = document.getElementById("fetchError");
      errorBox.style.display = "none";
      errorBox.textContent = "";

      try {
        const response = await fetch("/internal/service-monitor", {
          method: "GET",
          cache: "no-store"
        });

        if (!response.ok) {
          throw new Error("HTTP " + response.status);
        }

        const data = await response.json();
        const services = Array.isArray(data.services) ? data.services : [];

        const liveRoot = document.getElementById("liveServices");
        if (services.length === 0) {
          liveRoot.innerHTML = `<div class="empty-box">Servis verisi gelmedi.</div>`;
        } else {
          liveRoot.innerHTML = services.map(renderServiceCard).join("");
        }

        const runningCount = services.filter(s => normalizeStatus(s.status) === "RUNNING").length;
        const stoppedCount = services.filter(s => normalizeStatus(s.status) === "STOPPED").length;
        const degradedCount = services.filter(s => normalizeStatus(s.status) === "DEGRADED").length;
        const plannedCount = PLANNED_SERVICES.length;

        document.getElementById("runningCount").textContent = String(runningCount);
        document.getElementById("stoppedCount").textContent = String(stoppedCount);
        document.getElementById("degradedCount").textContent = String(degradedCount);
        document.getElementById("plannedCount").textContent = String(plannedCount);
        document.getElementById("updatedAt").textContent = escapeHtml(data.updated_at || "-");

        const overall = computeOverallStatus(services);
        const banner = document.getElementById("overallBanner");
        banner.className = overall.cls;
        banner.textContent = overall.text;
      } catch (error) {
        document.getElementById("liveServices").innerHTML =
          `<div class="empty-box">Servis verisi alinamadi.</div>`;

        const banner = document.getElementById("overallBanner");
        banner.className = "status-banner status-degraded";
        banner.textContent = "Service monitor okunamadi";

        errorBox.style.display = "block";
        errorBox.textContent = "Service monitor fetch hatasi: " + error.message;

        document.getElementById("runningCount").textContent = "0";
        document.getElementById("stoppedCount").textContent = "0";
        document.getElementById("degradedCount").textContent = "0";
        document.getElementById("plannedCount").textContent = String(PLANNED_SERVICES.length);
      }
    }

    renderPlannedCards();
    loadMonitor();
    setInterval(loadMonitor, 10000);
  </script>
</body>
</html>
HTML

echo "OK ✅ panel_index.html tamamen yeniden yazildi"
