import { Navigate } from 'react-router-dom'
import { LoginCard } from '../components/LoginCard'
import { useAuth } from '../context/AuthContext'
import { ROUTE_PATHS } from '../../../app/router/RoutePaths'
import { DesignTokenPanel } from '../../../shared/design/components/DesignTokenPanel'
import { InfoPanel } from '../../../shared/design/components/InfoPanel'
import { PageHero } from '../../../shared/design/components/PageHero'

const nextLayers = ['8.9 Design Consistency Layer tamamlanmis olacak']

export function LoginPage() {
  const { status } = useAuth()

  if (status === 'signed_in') {
    return <Navigate to={ROUTE_PATHS.dashboard} replace />
  }

  return (
    <>
      <PageHero
        badge="aktif rota"
        title="LVL8.9 Design Consistency Layer baslatildi"
        description="Login ekrani ortak hero, bilgi karti ve token preview bilesenleri ile ayni gorsel dili kullanacak sekilde duzenlendi."
        stats={[
          { value: 'READY', label: 'page hero' },
          { value: 'READY', label: 'info panel' },
          { value: 'READY', label: 'token panel' },
        ]}
      />

      <section className="auth-layout">
        <div className="auth-main-column">
          <LoginCard />
        </div>

        <aside className="auth-side-column">
          <InfoPanel
            label="route akis ozeti"
            title="Login route aktif"
            items={[
              'Signed-out kullanici login rotasinda kalir',
              'Signed-in kullanici dashboard rotasina yonlenir',
              'Protected app alani auth guard arkasinda calisir',
              'Monitoring ve dashboard ayrik sayfa rotalarina tasindi',
            ]}
          />

          <InfoPanel
            label="katman durumu"
            title="Design consistency katmani"
            items={nextLayers}
          />

          <DesignTokenPanel />
        </aside>
      </section>
    </>
  )
}
