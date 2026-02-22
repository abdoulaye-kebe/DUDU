import { useState, useEffect } from 'react';
import axios from '../utils/axios';
import { API_BASE_URL } from '../config';

const API_URL = API_BASE_URL;

function DashboardNew() {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalDrivers: 0,
    totalRides: 0,
    todayRevenue: 0,
    monthlyRevenue: 0,
    activeDrivers: 0,
    ongoingRides: 0
  });

  const [loading, setLoading] = useState(true);
  const [recentActivity, setRecentActivity] = useState([]);
  const [topDrivers, setTopDrivers] = useState([]);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_URL}/admin/dashboard`);
      
      if (response.data.success) {
        const data = response.data.data;
        const overview = data.overview || {};
        const today = data.today || {};
        const monthly = data.monthly || {};
        const charts = data.charts || {};
        
        setStats({
          totalUsers: overview.totalUsers || 0,
          totalDrivers: overview.totalDrivers || 0,
          totalRides: overview.totalRides || 0,
          todayRevenue: today.revenue || 0,
          monthlyRevenue: monthly.revenue || 0,
          activeDrivers: charts.driversByStatus?.online || 0,
          ongoingRides: charts.ridesByStatus?.in_progress || 0
        });
      }
      
      // Charger les top chauffeurs
      const driversResponse = await axios.get(`${API_URL}/admin/drivers?limit=3`);
      if (driversResponse.data.success) {
        setTopDrivers(driversResponse.data.drivers || []);
      }
      
      // Charger l'activité récente (à implémenter dans le backend)
      // Pour l'instant, on laisse vide
      setRecentActivity([]);
      
    } catch (error) {
      console.error('Erreur chargement dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div style={{ padding: '40px', textAlign: 'center' }}>
        <div style={{ fontSize: '48px', marginBottom: '20px' }}></div>
        <div style={{ fontSize: '18px', color: '#666' }}>Chargement du tableau de bord...</div>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div style={{ marginBottom: '30px' }}>
        <h1 style={{ margin: 0, marginBottom: '5px', fontSize: '32px', color: '#333' }}>
          Tableau de Bord DUDU
        </h1>
        <p style={{ margin: 0, color: '#666', fontSize: '16px' }}>
          Vue d'ensemble de la plateforme en temps réel
        </p>
      </div>

      {/* Stats Grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
        gap: '20px',
        marginBottom: '30px'
      }}>
        {/* Total Clients */}
        <div style={{
          background: 'white',
          padding: '24px',
          borderRadius: '12px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
          transition: 'transform 0.2s',
          cursor: 'pointer'
        }}
        onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-5px)'}
        onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <div style={{ fontSize: '32px' }}>👥</div>
            <div style={{ fontSize: '12px', color: '#10b981', fontWeight: '600' }}>+12%</div>
          </div>
          <div style={{ fontSize: '36px', fontWeight: 'bold', color: '#333', marginBottom: '8px' }}>
            {stats.totalUsers.toLocaleString()}
          </div>
          <div style={{ fontSize: '14px', color: '#666', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
            Total Clients
          </div>
        </div>

        {/* Total Chauffeurs */}
        <div style={{
          background: 'white',
          padding: '24px',
          borderRadius: '12px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
          transition: 'transform 0.2s',
          cursor: 'pointer'
        }}
        onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-5px)'}
        onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <div style={{ fontSize: '32px' }}>🚕</div>
            <div style={{ fontSize: '12px', color: '#10b981', fontWeight: '600' }}>+8%</div>
          </div>
          <div style={{ fontSize: '36px', fontWeight: 'bold', color: '#0d5d36', marginBottom: '8px' }}>
            {stats.totalDrivers.toLocaleString()}
          </div>
          <div style={{ fontSize: '14px', color: '#666', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
            Total Chauffeurs
          </div>
          <div style={{ fontSize: '12px', color: '#10b981', marginTop: '8px' }}>
            {stats.activeDrivers} en ligne
          </div>
        </div>

        {/* Total Courses */}
        <div style={{
          background: 'white',
          padding: '24px',
          borderRadius: '12px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
          transition: 'transform 0.2s',
          cursor: 'pointer'
        }}
        onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-5px)'}
        onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <div style={{ fontSize: '32px' }}></div>
            <div style={{ fontSize: '12px', color: '#10b981', fontWeight: '600' }}>+15%</div>
          </div>
          <div style={{ fontSize: '36px', fontWeight: 'bold', color: '#333', marginBottom: '8px' }}>
            {stats.totalRides.toLocaleString()}
          </div>
          <div style={{ fontSize: '14px', color: '#666', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
            Courses Totales
          </div>
          <div style={{ fontSize: '12px', color: '#ff9800', marginTop: '8px' }}>
            {stats.ongoingRides} en cours
          </div>
        </div>

        {/* Revenus du Jour */}
        <div style={{
          background: 'white',
          padding: '24px',
          borderRadius: '12px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
          transition: 'transform 0.2s',
          cursor: 'pointer'
        }}
        onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-5px)'}
        onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <div style={{ fontSize: '32px' }}>💰</div>
            <div style={{ fontSize: '12px', color: '#10b981', fontWeight: '600' }}>Aujourd'hui</div>
          </div>
          <div style={{ fontSize: '36px', fontWeight: 'bold', color: '#10b981', marginBottom: '8px' }}>
            {(stats.todayRevenue / 1000).toFixed(0)}K
          </div>
          <div style={{ fontSize: '14px', color: '#666', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
            Revenus (FCFA)
          </div>
          <div style={{ fontSize: '12px', color: '#666', marginTop: '8px' }}>
            Mois: {(stats.monthlyRevenue / 1000000).toFixed(2)}M FCFA
          </div>
        </div>
      </div>

      {/* Graphiques et Tendances */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: '2fr 1fr',
        gap: '20px',
        marginBottom: '30px'
      }}>
        {/* Graphique des courses */}
        <div style={{
          background: 'white',
          padding: '24px',
          borderRadius: '12px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
        }}>
          <h2 style={{ margin: 0, marginBottom: '20px', fontSize: '20px', color: '#333' }}>
            📈 Évolution des Courses
          </h2>
          <div style={{
            height: '300px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: '#f9f9f9',
            borderRadius: '8px',
            color: '#666'
          }}>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '48px', marginBottom: '10px' }}>📊</div>
              <div>Graphique des tendances</div>
              <div style={{ fontSize: '12px', marginTop: '5px' }}>
                (À implémenter avec Recharts)
              </div>
            </div>
          </div>
        </div>

        {/* Top Chauffeurs */}
        <div style={{
          background: 'white',
          padding: '24px',
          borderRadius: '12px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
        }}>
          <h2 style={{ margin: 0, marginBottom: '20px', fontSize: '20px', color: '#333' }}>
            🏆 Top Chauffeurs
          </h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
            {topDrivers.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '20px', color: '#999' }}>
                Aucun chauffeur pour le moment
              </div>
            ) : (
              topDrivers.map((driver, index) => (
              <div key={index} style={{
                display: 'flex',
                alignItems: 'center',
                gap: '15px',
                padding: '12px',
                background: '#f9f9f9',
                borderRadius: '8px'
              }}>
                <div style={{
                  width: '40px',
                  height: '40px',
                  borderRadius: '50%',
                  background: index === 0 ? '#ffd700' : index === 1 ? '#c0c0c0' : '#cd7f32',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: 'bold',
                  color: 'white'
                }}>
                  {index + 1}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: '600', marginBottom: '4px' }}>
                    {driver.firstName} {driver.lastName}
                  </div>
                  <div style={{ fontSize: '12px', color: '#666' }}>
                    {driver.stats?.totalRides || 0} courses • ⭐ {driver.stats?.averageRating?.toFixed(1) || 'N/A'}
                  </div>
                </div>
              </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Activité Récente */}
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
          <h2 style={{ margin: 0, fontSize: '20px', color: '#333' }}>
            🕐 Activité Récente
          </h2>
          <button style={{
            padding: '8px 16px',
            background: '#0d5d36',
            color: 'white',
            border: 'none',
            borderRadius: '6px',
            cursor: 'pointer',
            fontSize: '14px'
          }}>
            Voir tout
          </button>
        </div>

        <div style={{ padding: '20px' }}>
          {recentActivity.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '40px', color: '#999' }}>
              Aucune activité récente
            </div>
          ) : (
            recentActivity.map((activity, index) => (
            <div key={index} style={{
              display: 'flex',
              alignItems: 'center',
              gap: '15px',
              padding: '15px',
              borderBottom: index < 4 ? '1px solid #eee' : 'none'
            }}>
              <div style={{ fontSize: '24px' }}>{activity.icon}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: '500', marginBottom: '4px' }}>{activity.text}</div>
                <div style={{ fontSize: '12px', color: '#999' }}>{activity.time}</div>
              </div>
            </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}

export default DashboardNew;
