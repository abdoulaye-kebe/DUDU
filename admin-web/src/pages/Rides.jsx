import { useState, useEffect, useCallback } from 'react';
import api from '../services/api';

/**
 * Page « Courses » pour l’ancienne App.jsx (non utilisée par défaut — voir AppPremium).
 * Données réelles via GET /admin/rides.
 */
function Rides() {
  const [rides, setRides] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      const { data } = await api.get('/admin/rides', { params: { limit: 100 } });
      if (data.success) {
        setRides(data.data?.rides || []);
      } else {
        setRides([]);
      }
    } catch (e) {
      setError(e?.response?.data?.message || e.message || 'Erreur');
      setRides([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <div>
      <div className="page-header">
        <h1>Gestion des courses</h1>
        <p>Liste API /admin/rides</p>
      </div>

      {error && (
        <div className="card" style={{ padding: 16, marginBottom: 16, color: '#b91c1c' }}>
          {error}
        </div>
      )}

      <div className="table-container">
        <div className="table-header">
          <h2>Liste des courses</h2>
          <div style={{ display: 'flex', gap: '10px' }}>
            <button type="button" className="btn btn-primary" onClick={load} disabled={loading}>
              {loading ? '…' : 'Actualiser'}
            </button>
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
            {rides.map((ride) => (
              <tr key={ride.id || ride.rideId}>
                <td><strong>{ride.rideId || ride.id}</strong></td>
                <td>{ride.passenger?.name || '—'}</td>
                <td>{ride.driver?.name || '—'}</td>
                <td>
                  <div>{ride.pickup?.address || '—'} → {ride.destination?.address || '—'}</div>
                </td>
                <td>
                  <span className="badge badge-info">{ride.rideType || '—'}</span>
                </td>
                <td>
                  <span className={`badge ${
                    ride.status === 'completed' ? 'badge-success' :
                    ride.status === 'cancelled' ? 'badge-danger' :
                    'badge-warning'
                  }`}>
                    {ride.status || '—'}
                  </span>
                </td>
                <td><strong>{(ride.pricing?.totalPrice ?? 0).toLocaleString()} FCFA</strong></td>
                <td>{ride.createdAt ? new Date(ride.createdAt).toLocaleString('fr-FR') : '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {!loading && rides.length === 0 && !error && (
          <p style={{ padding: 16 }}>Aucune course.</p>
        )}
      </div>
    </div>
  );
}

export default Rides;
