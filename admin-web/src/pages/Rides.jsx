import { useState } from 'react'

function Rides() {
  const [rides, setRides] = useState([
    {
      id: 'DUDU12345',
      passenger: 'Fatou Diop',
      driver: 'Mamadou Sall',
      pickup: 'Almadies',
      destination: 'Plateau',
      type: 'standard',
      status: 'completed',
      price: 3500,
      date: '2024-10-12 14:30',
    },
    {
      id: 'DUDU12346',
      passenger: 'Abdou Kane',
      driver: 'Moussa Ndiaye',
      pickup: 'Point E',
      destination: 'Yoff',
      type: 'express',
      status: 'in_progress',
      price: 2800,
      date: '2024-10-12 15:45',
    },
    {
      id: 'DUDU12347',
      passenger: 'Aissatou Fall',
      driver: 'Cheikh Sy',
      pickup: 'Parcelles',
      destination: 'Médina',
      type: 'delivery',
      status: 'completed',
      price: 1500,
      date: '2024-10-12 12:15',
    },
  ])

  return (
    <div>
      <div className="page-header">
        <h1>Gestion des courses</h1>
        <p>Toutes les courses en temps réel</p>
      </div>

      {/* Rides Table */}
      <div className="table-container">
        <div className="table-header">
          <h2>Liste des courses</h2>
          <div style={{ display: 'flex', gap: '10px' }}>
            <button className="btn btn-primary">🔄 Actualiser</button>
            <button className="btn btn-primary">📊 Exporter</button>
          </div>
        </div>
        <table>
          <thead>
            <tr>
              <th>ID Course</th>
              <th>Passager</th>
              <th>Chauffeur</th>
              <th>Trajet</th>
              <th>Type</th>
              <th>Statut</th>
              <th>Prix</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            {rides.map(ride => (
              <tr key={ride.id}>
                <td><strong>{ride.id}</strong></td>
                <td>{ride.passenger}</td>
                <td>{ride.driver}</td>
                <td>
                  <div>{ride.pickup} → {ride.destination}</div>
                </td>
                <td>
                  <span className="badge badge-info">
                    {ride.type === 'standard' ? '🚗 Standard' :
                     ride.type === 'express' ? '⚡ Express' :
                     ride.type === 'delivery' ? '📦 Livraison' :
                     ride.type}
                  </span>
                </td>
                <td>
                  <span className={`badge ${
                    ride.status === 'completed' ? 'badge-success' :
                    ride.status === 'in_progress' ? 'badge-info' :
                    ride.status === 'cancelled' ? 'badge-danger' :
                    'badge-warning'
                  }`}>
                    {ride.status === 'completed' ? 'Terminée' :
                     ride.status === 'in_progress' ? 'En cours' :
                     ride.status === 'cancelled' ? 'Annulée' :
                     'En attente'}
                  </span>
                </td>
                <td><strong>{ride.price.toLocaleString()} FCFA</strong></td>
                <td>{ride.date}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

export default Rides

