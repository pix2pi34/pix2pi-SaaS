import React from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

function App() {
  const params = new URLSearchParams(window.location.search);
  const role = params.get('role') || 'misafir';

  const logout = () => {
    window.location.href = '/customer-login/react/';
  };

  // Kasiyer ise sadece POS ekranı gösterilir, sol menü gizlenir.
  if (role === 'kasiyer') {
    return (
      <div className="pos-screen">
        <header className="pos-header">
          <h2>PiX2Pi POS (Satış Ekranı) - Kasiyer Aktif</h2>
          <button className="danger-btn" onClick={logout}>Vardiya Bitir (Çıkış)</button>
        </header>
        <div className="pos-content">
          <div className="barcode-scanner">Barkod Okutunuz...</div>
          <div className="cart-total">Toplam: 0.00 TL</div>
        </div>
      </div>
    );
  }

  // Diğer yetkililer için Dashboard (Yönetim Paneli) görünümü
  return (
    <div className="dashboard">
      <aside className="sidebar">
        <div className="logo">PIX2PI PANEL</div>
        <nav>
          <ul>
            <li className="active">Gösterge Paneli</li>
            {(role === 'holding_yonetim' || role === 'bolge_yonetim' || role === 'ilce_yonetim' || role === 'sube_yonetim' || role === 'patron') && <li>Şubeler / İşletmeler</li>}
            {(role === 'holding_yonetim' || role === 'muhasebe' || role === 'patron') && <li>Finans ve Muhasebe</li>}
            <li>Stok ve Depo</li>
            <li>Personel Yönetimi</li>
          </ul>
        </nav>
      </aside>
      <main className="main-content">
        <header className="topbar">
          <div className="user-info">Aktif Rol: <strong>{role.toUpperCase()}</strong></div>
          <button className="outline-btn" onClick={logout}>Güvenli Çıkış</button>
        </header>
        <div className="content-area">
          <h1>Sisteme Hoş Geldiniz</h1>
          <div className="widgets">
            <div className="widget">
              <h3>Günlük Ciro</h3>
              <p className="value">₺124,500</p>
            </div>
            <div className="widget">
              <h3>Aktif İşletmeler</h3>
              <p className="value">42</p>
            </div>
            <div className="widget">
              <h3>Sistem Durumu</h3>
              <p className="value success">Online</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

createRoot(document.getElementById("root")).render(<App />);
