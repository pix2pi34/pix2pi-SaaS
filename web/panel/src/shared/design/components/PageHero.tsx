type HeroStat = {
  value: string
  label: string
}

type PageHeroProps = {
  badge: string
  title: string
  description: string
  stats: HeroStat[]
}

export function PageHero({
  badge,
  title,
  description,
  stats,
}: PageHeroProps) {
  return (
    <section className="surface surface-hero page-hero-surface">
      <div className="page-hero-copy">
        <span className="chip chip-active">{badge}</span>
        <h2 className="page-title">{title}</h2>
        <p className="page-text">{description}</p>
      </div>

      <div className="hero-stats">
        {stats.map((stat) => (
          <div key={`${stat.value}-${stat.label}`} className="stat-box">
            <strong>{stat.value}</strong>
            <span>{stat.label}</span>
          </div>
        ))}
      </div>
    </section>
  )
}
