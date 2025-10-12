import { useState } from 'react'

function Drivers() {
  const [drivers, setDrivers] = useState([
    { id: 1, name: 'Mamadou Sall', phone: '+221 77 123 45 67', status: 'online', vehicle: 'Toyota Corolla', rating: 4.8, rides: 156 },
    { id: 2, name: 'Moussa Ndiaye', phone: '+221 77 234 56 78', status: 'offline', vehicle: 'Renault Symbol', rating: 4.6, rides: 132 },
    { id: 3, name: 'Cheikh Sy', phone: '+221 77 345 67 89', status: 'online', vehicle: 'Peugeot 301', rating: 4.9, rides: 203 },
    { id: 4, name: 'Abdou Diallo', phone: '+221 77 456 78 90', status: 'busy', vehicle: 'Honda Civic', rating: 4.7, rides: 178 },
  ])

  const [filter, setFilter] = useState('all')

  const filteredDrivers = drivers.filter(driver => {
    if (filter === 'all') return true
    return driver.status === filter
  })

  return (
    <div>
      <div className="page-header">
        <h1>Gestion des chauffeurs</h1>
        <p>Liste et statuts des chauffeurs DUDU Pro</p>
      </div>

      {/* Filters */}
      <div style={{ marginBottom: '20px', display: 'flex', gap: '10px' }}>
        <button 
          className={`btn ${filter === 'all' ? 'btn-primary' : ''}`}
          onClick={() => setFilter('all')}
        >
          Tous ({drivers.length})
        </button>
        <button 
          className={`btn ${filter === 'online' ? 'btn-primary' : ''}`}
          onClick={() => setFilter('online')}
        >
          En ligne ({drivers.filter(d => d.status === 'online').length})
        </button>
        <button 
          className={`btn ${filter === 'offline' ? 'btn-primary' : ''}`}
          onClick={() => setFilter('offline')}
        >
          Hors ligne ({drivers.filter(d => d.status === 'offline').length})
        </button>
      </div>

      {/* Drivers Table */}
      <div className="table-container">
        <div className="table-header">
          <h2>Liste des chauffeurs</h2>
          <button className="btn btn-primary">+ Nouveau chauffeur</button>
        </div>
        <table>
          <thead>
            <tr>
              <th>Nom</th>
              <th>Téléphone</th>
              <th>Véhicule</th>
              <th>Statut</th>
              <th>Note</th>
              <th>Courses</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredDrivers.map(driver => (
              <tr key={driver.id}>
                <td>
                  <strong>{driver.name}</strong>
                </td>
                <td>{driver.phone}</td>
                <td>{driver.vehicle}</td>
                <td>
                  <span className={`badge ${
                    driver.status === 'online' ? 'badge-success' :
                    driver.status === 'offline' ? 'badge-danger' :
                    'badge-warning'
                  }`}>
                    {driver.status === 'online' ? 'En ligne' :
                     driver.status === 'offline' ? 'Hors ligne' :
                     'Occupé'}
                  </span>
                </td>
                <td>⭐ {driver.rating}</td>
                <td>{driver.rides}</td>
                <td>
                  <button className="btn btn-primary" style={{ marginRight: '8px', padding: '6px 12px' }}>
                    Voir
                  </button>
                  <button className="btn btn-danger" style={{ padding: '6px 12px' }}>
                    Suspendre
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

export default Drivers

