import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { API_BASE_URL } from '../config';

const API_URL = API_BASE_URL;

function Clients() {
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    total: 0,
    active: 0,
    newToday: 0,
    totalRides: 0
  });

  useEffect(() => {
    loadClients();
    loadStats();
  }, []);

  const loadClients = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_URL}/admin/users`);
      console.log('Réponse API clients:', response.data); // Debug
      // L'API retourne response.data.data.users
      const users = response.data.data?.users || response.data.users || [];
      setClients(users);
      console.log('Clients chargés:', users.length); // Debug
    } catch (error) {
      console.error('Erreur chargement clients:', error);
      setClients([]);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const response = await axios.get(`${API_URL}/admin/dashboard`);
      if (response.data.success) {
        const data = response.data.data;
        const overview = data.overview || {};
        const today = data.today || {};
        
        setStats({
          total: overview.totalUsers || 0,
          active: clients.filter(c => c.isActive).length,
          newToday: today.users || 0,
          totalRides: overview.totalRides || 0
        });
      }
    } catch (error) {
      console.error('Erreur chargement stats:', error);
    }
  };

  if (loading) {
    return <div style={{ padding: '40px', textAlign: 'center' }}>Chargement...</div>;
  }

  return (
    <div>
      <div style={{ marginBottom: '30px' }}>
        <h1 style={{ margin: 0, marginBottom: '5px', fontSize: '32px', color: '#333' }}>
          Gestion des Clients
        </h1>
        <p style={{ margin: 0, color: '#666', fontSize: '16px' }}>
          Vue d'ensemble des utilisateurs de l'application
        </p>
      </div>

      {/* Statistiques */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
        gap: '20px',
        marginBottom: '30px'
      }}>
        <div style={{
          background: 'white',
          padding: '24px',
          borderRadius: '12px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
        }}>
          <div style={{ fontSize: '32px', marginBottom: '10px' }}>👥</div>
          <div style={{ fontSize: '36px', fontWeight: 'bold', color: '#333', marginBottom: '8px' }}>
            {stats.total}
          </div>
          <div style={{ fontSize: '14px', color: '#666', textTransform: 'uppercase' }}>
            Total Clients
          </div>
        </div>

        <div style={{
          background: 'white',
          padding: '24px',
          borderRadius: '12px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
        }}>
          <div style={{ fontSize: '32px', marginBottom: '10px' }}>✅</div>
          <div style={{ fontSize: '36px', fontWeight: 'bold', color: '#0d5d36', marginBottom: '8px' }}>
            {stats.active}
          </div>
          <div style={{ fontSize: '14px', color: '#666', textTransform: 'uppercase' }}>
            Clients Actifs
          </div>
        </div>

        <div style={{
          background: 'white',
          padding: '24px',
          borderRadius: '12px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
        }}>
          <div style={{ fontSize: '32px', marginBottom: '10px' }}>🆕</div>
          <div style={{ fontSize: '36px', fontWeight: 'bold', color: '#10b981', marginBottom: '8px' }}>
            {stats.newToday}
          </div>
          <div style={{ fontSize: '14px', color: '#666', textTransform: 'uppercase' }}>
            Nouveaux Aujourd'hui
          </div>
        </div>

        <div style={{
          background: 'white',
          padding: '24px',
          borderRadius: '12px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
        }}>
          <div style={{ fontSize: '32px', marginBottom: '10px' }}></div>
          <div style={{ fontSize: '36px', fontWeight: 'bold', color: '#333', marginBottom: '8px' }}>
            {stats.totalRides}
          </div>
          <div style={{ fontSize: '14px', color: '#666', textTransform: 'uppercase' }}>
            Courses Totales
          </div>
        </div>
      </div>

      {/* Liste des clients */}
      <div style={{
        background: 'white',
        borderRadius: '12px',
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        overflow: 'hidden'
      }}>
        <div style={{
          padding: '20px',
          borderBottom: '1px solid #eee',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}>
          <h2 style={{ margin: 0, fontSize: '20px', color: '#333' }}>Liste des Clients</h2>
          <input
            type="text"
            placeholder="Rechercher un client..."
            style={{
              padding: '10px 15px',
              borderRadius: '8px',
              border: '1px solid #ddd',
              fontSize: '14px',
              width: '300px'
            }}
          />
        </div>

        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead style={{ background: '#f9f9f9' }}>
            <tr>
              <th style={{ padding: '16px', textAlign: 'left', fontWeight: '600', color: '#666', fontSize: '14px' }}>
                NOM
              </th>
              <th style={{ padding: '16px', textAlign: 'left', fontWeight: '600', color: '#666', fontSize: '14px' }}>
                TÉLÉPHONE
              </th>
              <th style={{ padding: '16px', textAlign: 'left', fontWeight: '600', color: '#666', fontSize: '14px' }}>
                EMAIL
              </th>
              <th style={{ padding: '16px', textAlign: 'left', fontWeight: '600', color: '#666', fontSize: '14px' }}>
                COURSES
              </th>
              <th style={{ padding: '16px', textAlign: 'left', fontWeight: '600', color: '#666', fontSize: '14px' }}>
                INSCRIPTION
              </th>
              <th style={{ padding: '16px', textAlign: 'left', fontWeight: '600', color: '#666', fontSize: '14px' }}>
                STATUT
              </th>
              <th style={{ padding: '16px', textAlign: 'left', fontWeight: '600', color: '#666', fontSize: '14px' }}>
                ACTIONS
              </th>
            </tr>
          </thead>
          <tbody>
            {clients.length === 0 ? (
              <tr>
                <td colSpan="7" style={{ padding: '40px', textAlign: 'center', color: '#999' }}>
                  Aucun client trouvé
                </td>
              </tr>
            ) : (
              clients.map(client => (
                <tr key={client._id || client.id} style={{ borderBottom: '1px solid #eee' }}>
                  <td style={{ padding: '16px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                      <div style={{
                        width: '40px',
                        height: '40px',
                        borderRadius: '50%',
                        background: '#0d5d36',
                        color: 'white',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontWeight: 'bold'
                      }}>
                        {(client.firstName?.[0] || client.name?.[0] || 'U').toUpperCase()}
                      </div>
                      <div>
                        <div style={{ fontWeight: '600' }}>
                          {client.firstName && client.lastName 
                            ? `${client.firstName} ${client.lastName}`
                            : client.name || 'Utilisateur'}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td style={{ padding: '16px' }}>{client.phone || 'N/A'}</td>
                  <td style={{ padding: '16px' }}>{client.email || 'N/A'}</td>
                  <td style={{ padding: '16px' }}>
                    <span style={{ fontWeight: '600', color: '#0d5d36' }}>
                      {client.totalRides || 0}
                    </span>
                  </td>
                  <td style={{ padding: '16px' }}>
                    {client.createdAt 
                      ? new Date(client.createdAt).toLocaleDateString('fr-FR')
                      : 'N/A'}
                  </td>
                  <td style={{ padding: '16px' }}>
                    <span style={{
                      padding: '5px 12px',
                      borderRadius: '20px',
                      fontSize: '12px',
                      fontWeight: '600',
                      background: client.isActive ? '#d4edda' : '#f8d7da',
                      color: client.isActive ? '#155724' : '#721c24'
                    }}>
                      {client.isActive ? 'Actif' : 'Inactif'}
                    </span>
                  </td>
                  <td style={{ padding: '16px' }}>
                    <button
                      style={{
                        padding: '6px 12px',
                        backgroundColor: '#0d5d36',
                        color: 'white',
                        border: 'none',
                        borderRadius: '6px',
                        cursor: 'pointer',
                        fontSize: '14px',
                        marginRight: '5px'
                      }}
                    >
                      Voir détails
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default Clients;
