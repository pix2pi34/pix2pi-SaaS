type InfoPanelProps = {
  label: string
  title: string
  items: string[]
}

export function InfoPanel({ label, title, items }: InfoPanelProps) {
  return (
    <section className="surface side-info-card consistency-card">
      <p className="meta-label">{label}</p>
      <h3 className="section-title">{title}</h3>
      <ul className="info-list">
        {items.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
    </section>
  )
}
