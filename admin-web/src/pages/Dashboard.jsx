import { useState, useEffect } from 'react'
import '../styles/modern-dashboard.css'

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

      {/* Stats Cards - Design Moderne */}
      <div className="stats-grid">
        <div className="stat-card modern">
          <div className="stat-icon-wrapper green">
            <svg className="stat-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
          </div>
          <div className="stat-content">
            <div className="stat-value">{stats.totalRides.toLocaleString()}</div>
            <div className="stat-label">Courses totales</div>
            <div className="stat-trend positive">
              <svg className="trend-icon" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clipRule="evenodd" />
              </svg>
              <span>+12% ce mois</span>
            </div>
          </div>
        </div>

        <div className="stat-card modern">
          <div className="stat-icon-wrapper blue">
            <svg className="stat-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          </div>
          <div className="stat-content">
            <div className="stat-value">{stats.activeDrivers}</div>
            <div className="stat-label">Chauffeurs actifs</div>
            <div className="stat-trend positive">
              <svg className="trend-icon" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clipRule="evenodd" />
              </svg>
              <span>+8% ce mois</span>
            </div>
          </div>
        </div>

        <div className="stat-card modern">
          <div className="stat-icon-wrapper orange">
            <svg className="stat-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div className="stat-content">
            <div className="stat-value">{(stats.totalRevenue / 1000000).toFixed(1)}M</div>
            <div className="stat-label">Revenus (FCFA)</div>
            <div className="stat-trend positive">
              <svg className="trend-icon" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clipRule="evenodd" />
              </svg>
              <span>+15% ce mois</span>
            </div>
          </div>
        </div>

        <div className="stat-card modern">
          <div className="stat-icon-wrapper purple">
            <svg className="stat-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </div>
          <div className="stat-content">
            <div className="stat-value">{stats.activeRides}</div>
            <div className="stat-label">Courses en cours</div>
            <div className="stat-trend neutral">
              <span className="pulse-dot"></span>
              <span>En temps réel</span>
            </div>
          </div>
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

