<script setup>
const companies = [
  { name: "İstanbul Gıda A.Ş.", branches: 8, income: 1480000, expense: 920000 },
  { name: "Ankara Market A.Ş.", branches: 5, income: 870000, expense: 610000 },
  { name: "Bursa Dağıtım Ltd.", branches: 3, income: 540000, expense: 390000 }
];

const income = companies.reduce((sum, item) => sum + item.income, 0);
const expense = companies.reduce((sum, item) => sum + item.expense, 0);
const net = income - expense;

function money(value) {
  return new Intl.NumberFormat("tr-TR", {
    style: "currency",
    currency: "TRY",
    maximumFractionDigits: 0
  }).format(value);
}
</script>

<template>
  <main class="page">
    <section class="topbar">
      <div>
        <div class="logo">PIX2PI</div>
        <div class="badge">Patron Yetkisi Aktif</div>
      </div>
      <div class="user">
        <b>Mail kodu doğrulandı</b><br />
        Holding Patron / Tüm şirketler
      </div>
    </section>

    <section class="hero">
      <h1>Patron Yönetim Sayfası</h1>
      <p>Holding altındaki tüm A.Ş., şube ve operasyonların gelir-gider özeti.</p>
    </section>

    <section class="grid three">
      <div class="card metric"><span>Toplam Gelir</span><b>{{ money(income) }}</b></div>
      <div class="card metric"><span>Toplam Gider</span><b>{{ money(expense) }}</b></div>
      <div class="card metric"><span>Net Durum</span><b>{{ money(net) }}</b></div>
    </section>

    <section class="grid two">
      <div class="card">
        <h2>Alt Şirketler</h2>
        <div class="company" v-for="company in companies" :key="company.name">
          <b>{{ company.name }}</b>
          <span>{{ company.branches }} şube</span>
          <span>{{ money(company.income) }}</span>
          <span>{{ money(company.expense) }}</span>
        </div>
      </div>

      <div class="card">
        <h2>Yetki Kapsamı</h2>
        <p>Rol: HOLDING_OWNER</p>
        <p>Kapsam: Tüm holding ve alt şirketler</p>
        <p>Remote erişim: Açık</p>
        <p>Kasiyer/POS local kullanıcıları bu ekrandan giriş yapamaz.</p>
        <button @click="window.location.href = '/customer-login/vue3/'">Çıkış</button>
      </div>
    </section>
  </main>
</template>
