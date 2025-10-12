import { useState, useEffect } from 'react'

function Dashboard() {
  const [stats, setStats] = useState({
    totalRides: 1247,
    activeDrivers: 156,
    totalRevenue: 3420000,
    activeRides: 23,
  })

  const [recentRides, setRecentRides] = useState([
    { id: 1, passenger: 'Fatou Diop', driver: 'Mamadou Sall', status: 'completed', price: 3500 },
    { id: 2, passenger: 'Abdou Kane', driver: 'Moussa Ndiaye', status: 'in_progress', price: 2800 },
    { id: 3, passenger: 'Aissatou Fall', driver: 'Cheikh Sy', status: 'completed', price: 4200 },
  ])

  return (
    <div>
      <div className="page-header">
        <h1>Tableau de bord</h1>
        <p>Vue d'ensemble de la plateforme DUDU</p>
      </div>

      {/* Stats Cards */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-card-header">
            <div className="stat-card-icon">🚗</div>
          </div>
          <div className="stat-card-value">{stats.totalRides.toLocaleString()}</div>
          <div className="stat-card-label">Courses totales</div>
          <div className="stat-card-trend trend-up">↑ +12% ce mois</div>
        </div>

        <div className="stat-card">
          <div className="stat-card-header">
            <div className="stat-card-icon">🚕</div>
          </div>
          <div className="stat-card-value">{stats.activeDrivers}</div>
          <div className="stat-card-label">Chauffeurs actifs</div>
          <div className="stat-card-trend trend-up">↑ +8% ce mois</div>
        </div>

        <div className="stat-card">
          <div className="stat-card-header">
            <div className="stat-card-icon">💰</div>
          </div>
          <div className="stat-card-value">{(stats.totalRevenue / 1000000).toFixed(1)}M</div>
          <div className="stat-card-label">Revenus (FCFA)</div>
          <div className="stat-card-trend trend-up">↑ +15% ce mois</div>
        </div>

        <div className="stat-card">
          <div className="stat-card-header">
            <div className="stat-card-icon">⚡</div>
          </div>
          <div className="stat-card-value">{stats.activeRides}</div>
          <div className="stat-card-label">Courses en cours</div>
          <div className="stat-card-trend">En temps réel</div>
        </div>
      </div>

      {/* Recent Rides */}
      <div className="table-container">
        <div className="table-header">
          <h2>Courses récentes</h2>
          <button className="btn btn-primary">Voir tout</button>
        </div>
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Passager</th>
              <th>Chauffeur</th>
              <th>Statut</th>
              <th>Prix</th>
            </tr>
          </thead>
          <tbody>
            {recentRides.map(ride => (
              <tr key={ride.id}>
                <td>#{ride.id}</td>
                <td>{ride.passenger}</td>
                <td>{ride.driver}</td>
                <td>
                  <span className={`badge ${
                    ride.status === 'completed' ? 'badge-success' :
                    ride.status === 'in_progress' ? 'badge-info' :
                    'badge-warning'
                  }`}>
                    {ride.status === 'completed' ? 'Terminée' :
                     ride.status === 'in_progress' ? 'En cours' :
                     'En attente'}
                  </span>
                </td>
                <td>{ride.price.toLocaleString()} FCFA</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

export default Dashboard

