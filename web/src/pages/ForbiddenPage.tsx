export function ForbiddenPage() {
  return (
    <div className="state-box card span-12">
      <div className="badge">403</div>
      <strong>Bu ekrana yetkin yok</strong>
      <span className="small">Role-aware menu ve guard bu ekranda devreye giriyor.</span>
    </div>
  );
}

