import React from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

const companies = [
  { name: "İstanbul Gıda A.Ş.", branches: 8, income: 1480000, expense: 920000 },
  { name: "Ankara Market A.Ş.", branches: 5, income: 870000, expense: 610000 },
  { name: "Bursa Dağıtım Ltd.", branches: 3, income: 540000, expense: 390000 }
];

function money(value) {
  return new Intl.NumberFormat("tr-TR", {
    style: "currency",
    currency: "TRY",
    maximumFractionDigits: 0
  }).format(value);
}

function App() {
  const income = companies.reduce((sum, item) => sum + item.income, 0);
  const expense = companies.reduce((sum, item) => sum + item.expense, 0);
  const net = income - expense;

  return (
    <main className="page">
      <section className="topbar">
        <div>
          <div className="logo">PIX2PI</div>
          <div className="badge">Patron Yetkisi Aktif</div>
        </div>
        <div className="user">
          <b>Mail kodu doğrulandı</b><br />
          Holding Patron / Tüm şirketler
        </div>
      </section>

      <section className="hero">
        <h1>Patron Yönetim Sayfası</h1>
        <p>Holding altındaki tüm A.Ş., şube ve operasyonların gelir-gider özeti.</p>
      </section>

      <section className="grid three">
        <div className="card metric"><span>Toplam Gelir</span><b>{money(income)}</b></div>
        <div className="card metric"><span>Toplam Gider</span><b>{money(expense)}</b></div>
        <div className="card metric"><span>Net Durum</span><b>{money(net)}</b></div>
      </section>

      <section className="grid two">
        <div className="card">
          <h2>Alt Şirketler</h2>
          {companies.map((company) => (
            <div className="company" key={company.name}>
              <b>{company.name}</b>
              <span>{company.branches} şube</span>
              <span>{money(company.income)}</span>
              <span>{money(company.expense)}</span>
            </div>
          ))}
        </div>

        <div className="card">
          <h2>Yetki Kapsamı</h2>
          <p>Rol: HOLDING_OWNER</p>
          <p>Kapsam: Tüm holding ve alt şirketler</p>
          <p>Remote erişim: Açık</p>
          <p>Kasiyer/POS local kullanıcıları bu ekrandan giriş yapamaz.</p>
          <button onClick={() => window.location.href = "/customer-login/react/"}>Çıkış</button>
        </div>
      </section>
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
