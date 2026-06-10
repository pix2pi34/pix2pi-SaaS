export function UnauthorizedPage() {
  return (
    <div className="state-box card span-12">
      <div className="badge">401</div>
      <strong>Oturum acman gerekiyor</strong>
      <span className="small">Bu yuzeye erismek icin gecerli session lazim.</span>
    </div>
  );
}

