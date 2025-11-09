import React, { useEffect, useState } from 'react';
import axios from 'axios';

const API_URL = 'http://213.154.90.11/api/v1';

function DriversNew() {
  const [pending, setPending] = useState([]);
  const [approved, setApproved] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const loadData = async () => {
    try {
      setLoading(true);
      setError('');

      const [pendingRes, approvedRes] = await Promise.all([
        axios.get(`${API_URL}/admin/driver-applications`),
        axios.get(`${API_URL}/admin/drivers`, { params: { verificationStatus: 'approved', limit: 20 } })
      ]);

      setPending(pendingRes.data.applications || []);
      setApproved(approvedRes.data.drivers || []);
    } catch (err) {
      console.error('Erreur chargement chauffeurs:', err);
      setError(err.response?.data?.message || 'Impossible de charger les données chauffeurs');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleDecision = async (driverId, decision) => {
    const confirmMessage =
      decision === 'approved'
        ? 'Confirmer l\'approbation de cette candidature ?'
        : 'Êtes-vous sûr de vouloir rejeter cette candidature ?';

    if (!window.confirm(confirmMessage)) {
      return;
    }

    try {
      await axios.put(`${API_URL}/admin/drivers/${driverId}/verify`, {
        status: decision,
        notes: ''
      });
      await loadData();
    } catch (err) {
      console.error('Erreur décision candidature:', err);
      alert(err.response?.data?.message || 'Erreur lors de la mise à jour');
    }
  };

  const renderPendingCard = (driver) => (
    <div key={driver._id} className="card" style={{ marginBottom: 20 }}>
      <div className="card-header">
        <div>
          <h3 style={{ margin: 0 }}>
            {driver.firstName} {driver.lastName}
          </h3>
          <p style={{ margin: 0, color: '#555' }}>{driver.phone} · {driver.email || 'Email non renseigné'}</p>
        </div>
        <span className="badge badge-warning">En attente</span>
      </div>

      <div className="card-body">
        <div className="info-grid">
                <div>
            <h4>Véhicule</h4>
            <p>
              {driver.vehicle?.make} {driver.vehicle?.model} · {driver.vehicle?.year}<br />
              Couleur : {driver.vehicle?.color} · Plaque : {driver.vehicle?.plateNumber}
            </p>
                </div>
                <div>
            <h4>Documents</h4>
            <p>
              Permis n° {driver.driverLicense?.number}<br />
              Expire le {driver.driverLicense?.expiryDate?.slice(0, 10) || 'N/A'}
            </p>
                </div>
                <div>
            <h4>Préférences</h4>
            <p>
              Distance max : {driver.preferences?.maxDistance || 10} km<br />
              Prix min : {driver.preferences?.minPrice || 1000} FCFA
            </p>
                </div>
              </div>
            </div>

      <div className="card-actions">
        <button className="btn btn-danger" onClick={() => handleDecision(driver._id, 'rejected')}>
          Refuser
        </button>
        <button className="btn btn-primary" onClick={() => handleDecision(driver._id, 'approved')}>
          Valider la candidature
        </button>
                </div>
              </div>
  );

  return (
    <div className="page">
      <div className="page-header">
                <div>
          <h1>Gestion des chauffeurs</h1>
          <p>Validez les inscriptions des chauffeurs DUDU Pro</p>
                </div>
        <button className="btn btn-outline" onClick={loadData}>
          🔄 Rafraîchir
        </button>
            </div>

      {error && (
        <div className="alert alert-error" style={{ marginBottom: 20 }}>
          {error}
                </div>
      )}

      {loading ? (
        <div className="card">
          <p>Chargement des données...</p>
                </div>
      ) : (
        <>
          <section>
            <div className="section-header">
              <h2>Demandes d'inscription ({pending.length})</h2>
              <p>Les chauffeurs restent inactifs tant que vous n'avez pas validé leur dossier.</p>
            </div>

            {pending.length === 0 ? (
              <div className="card empty-state">
                <h3>Aucune demande en attente</h3>
                <p>Les candidatures apparaîtront ici dès qu'un chauffeur soumet ses informations depuis l'application.</p>
              </div>
            ) : (
              pending.map(renderPendingCard)
            )}
          </section>

          <section style={{ marginTop: 40 }}>
            <div className="section-header">
              <h2>Chauffeurs approuvés ({approved.length})</h2>
              <p>Liste des chauffeurs déjà validés et prêts à conduire.</p>
            </div>

            <div className="card">
              <table>
                <thead>
                  <tr>
                    <th>Nom</th>
                    <th>Téléphone</th>
                    <th>Véhicule</th>
                    <th>Statut</th>
                    <th>Courses</th>
            </tr>
          </thead>
          <tbody>
                  {approved.length === 0 ? (
              <tr>
                      <td colSpan={5} style={{ textAlign: 'center', padding: 20, color: '#777' }}>
                        Aucun chauffeur validé pour le moment.
                </td>
              </tr>
            ) : (
                    approved.map(driver => (
                      <tr key={driver._id}>
                        <td>{driver.firstName} {driver.lastName}</td>
                        <td>{driver.phone}</td>
                        <td>{driver.vehicle?.make} {driver.vehicle?.model}</td>
                        <td>
                          <span className={`badge ${driver.status === 'online' ? 'badge-success' : 'badge-secondary'}`}>
                      {driver.status === 'online' ? 'En ligne' : 'Hors ligne'}
                    </span>
                  </td>
                        <td>{driver.stats?.totalRides || 0}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
          </section>
        </>
      )}
    </div>
  );
}

export default DriversNew;


