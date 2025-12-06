import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import axios from 'axios';
import { API_BASE_URL } from '../config';
import StatCard from '../components/StatCard';
import DataTable from '../components/DataTable';
import { 
  Users, 
  UserCheck, 
  Car, 
  DollarSign,
  TrendingUp,
  Activity,
  Clock,
  MapPin,
  RefreshCw,
  Calendar,
  ArrowUpRight,
  Zap
} from 'lucide-react';

function DashboardPremium() {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalDrivers: 0,
    totalRides: 0,
    todayRevenue: 0,
    monthlyRevenue: 0,
    activeDrivers: 0,
    ongoingRides: 0,
    todayUsers: 0,
    todayDrivers: 0,
    todayRides: 0
  });
  const [loading, setLoading] = useState(true);
  const [recentRides, setRecentRides] = useState([]);
  const [topDrivers, setTopDrivers] = useState([]);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_BASE_URL}/admin/dashboard`);
      
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
          ongoingRides: charts.ridesByStatus?.in_progress || 0,
          todayUsers: today.users || 0,
          todayDrivers: today.drivers || 0,
          todayRides: today.rides || 0
        });

        setRecentRides(data.recentRides || []);
        setTopDrivers(data.topDrivers || []);
      }
    } catch (error) {
      console.error('Erreur chargement dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('fr-FR').format(amount) + ' FCFA';
  };

  const rideColumns = [
    { 
      key: 'rideId', 
      label: 'ID Course',
      render: (value) => (
        <span style={{ fontFamily: 'monospace', fontWeight: 600, color: 'var(--primary-600)' }}>
          {value || 'N/A'}
        </span>
      )
    },
    { 
      key: 'passenger', 
      label: 'Passager',
      render: (value) => value?.name || 'N/A'
    },
    { 
      key: 'driver', 
      label: 'Chauffeur',
      render: (value) => value?.name || 'En attente'
    },
    { 
      key: 'status', 
      label: 'Statut',
      render: (value) => {
        const statusMap = {
          pending: { label: 'En attente', class: 'badge-warning' },
          accepted: { label: 'Acceptée', class: 'badge-info' },
          in_progress: { label: 'En cours', class: 'badge-info' },
          completed: { label: 'Terminée', class: 'badge-success' },
          cancelled: { label: 'Annulée', class: 'badge-danger' }
        };
        const status = statusMap[value] || { label: value, class: 'badge-secondary' };
        return <span className={`badge ${status.class}`}>{status.label}</span>;
      }
    },
    { 
      key: 'pricing', 
      label: 'Prix',
      render: (value) => (
        <span style={{ fontWeight: 600 }}>
          {formatCurrency(value?.totalPrice || 0)}
        </span>
      )
    }
  ];

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <div className="loading-text">Chargement du tableau de bord...</div>
      </div>
    );
  }

  return (
    <div>
      {/* Page Header */}
      <motion.div 
        className="page-header"
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
      >
        <div className="page-header-content">
          <div className="page-title-section">
            <h1 className="page-title">Tableau de bord</h1>
            <p className="page-subtitle">
              Vue d'ensemble de la plateforme DUDU • Mis à jour en temps réel
            </p>
          </div>
          <div className="page-actions">
            <motion.button 
              className="btn btn-secondary"
              onClick={loadDashboardData}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <RefreshCw size={18} />
              Actualiser
            </motion.button>
            <motion.button 
              className="btn btn-primary"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <Calendar size={18} />
              Rapport du jour
            </motion.button>
          </div>
        </div>
      </motion.div>

      {/* Stats Grid */}
      <div className="stats-grid">
        <StatCard 
          title="Total Clients"
          value={stats.totalUsers}
          icon={Users}
          trend="up"
          trendValue={`+${stats.todayUsers} aujourd'hui`}
          color="green"
          delay={0}
        />
        <StatCard 
          title="Chauffeurs Actifs"
          value={stats.totalDrivers}
          icon={UserCheck}
          trend="up"
          trendValue={`${stats.activeDrivers} en ligne`}
          color="blue"
          delay={0.1}
        />
        <StatCard 
          title="Courses Totales"
          value={stats.totalRides}
          icon={Car}
          trend="up"
          trendValue={`+${stats.todayRides} aujourd'hui`}
          color="purple"
          delay={0.2}
        />
        <StatCard 
          title="Revenus du Mois"
          value={formatCurrency(stats.monthlyRevenue)}
          icon={DollarSign}
          trend="up"
          trendValue={formatCurrency(stats.todayRevenue) + " aujourd'hui"}
          color="orange"
          delay={0.3}
        />
      </div>

      {/* Quick Stats Row */}
      <motion.div 
        className="stats-grid" 
        style={{ marginBottom: '32px' }}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.4 }}
      >
        <motion.div 
          className="card"
          style={{ padding: '24px', display: 'flex', alignItems: 'center', gap: '20px' }}
          whileHover={{ y: -2 }}
        >
          <div className="stat-icon-wrapper cyan">
            <Activity />
          </div>
          <div>
            <div style={{ fontSize: '28px', fontWeight: 700, color: 'var(--gray-900)' }}>
              {stats.ongoingRides}
            </div>
            <div style={{ fontSize: '14px', color: 'var(--gray-500)' }}>
              Courses en cours
            </div>
          </div>
          <div style={{ marginLeft: 'auto' }}>
            <span className="badge badge-info" style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
              <Zap size={14} />
              Live
            </span>
          </div>
        </motion.div>

        <motion.div 
          className="card"
          style={{ padding: '24px', display: 'flex', alignItems: 'center', gap: '20px' }}
          whileHover={{ y: -2 }}
        >
          <div className="stat-icon-wrapper green">
            <TrendingUp />
          </div>
          <div>
            <div style={{ fontSize: '28px', fontWeight: 700, color: 'var(--gray-900)' }}>
              {stats.activeDrivers}
            </div>
            <div style={{ fontSize: '14px', color: 'var(--gray-500)' }}>
              Chauffeurs en ligne
            </div>
          </div>
          <div style={{ marginLeft: 'auto' }}>
            <span className="badge badge-success" style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
              <span className="status-dot online"></span>
              Actifs
            </span>
          </div>
        </motion.div>
      </motion.div>

      {/* Recent Rides Table */}
      <div className="section">
        <DataTable 
          title="Courses Récentes"
          icon={MapPin}
          columns={rideColumns}
          data={recentRides}
          emptyMessage="Aucune course récente"
          onView={(ride) => console.log('View ride:', ride)}
        />
      </div>

      {/* Top Drivers */}
      {topDrivers.length > 0 && (
        <motion.div 
          className="section"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
        >
          <div className="section-header">
            <div className="section-title">
              <UserCheck />
              Top Chauffeurs
            </div>
          </div>
          <div className="stats-grid">
            {topDrivers.map((driver, index) => (
              <motion.div 
                key={driver.id || index}
                className="card"
                style={{ padding: '24px' }}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.6 + index * 0.1 }}
                whileHover={{ y: -4 }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '16px' }}>
                  <div style={{
                    width: '48px',
                    height: '48px',
                    borderRadius: 'var(--radius-lg)',
                    background: 'linear-gradient(135deg, var(--primary-600) 0%, var(--primary-400) 100%)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'white',
                    fontWeight: 700,
                    fontSize: '18px'
                  }}>
                    #{index + 1}
                  </div>
                  <div>
                    <div style={{ fontWeight: 600, color: 'var(--gray-900)' }}>
                      {driver.name}
                    </div>
                    <div style={{ fontSize: '13px', color: 'var(--gray-500)' }}>
                      {driver.vehicle}
                    </div>
                  </div>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <div>
                    <div style={{ fontSize: '24px', fontWeight: 700, color: 'var(--primary-600)' }}>
                      {driver.totalRides}
                    </div>
                    <div style={{ fontSize: '12px', color: 'var(--gray-500)' }}>Courses</div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '24px', fontWeight: 700, color: 'var(--gray-900)' }}>
                      {formatCurrency(driver.totalEarnings || 0)}
                    </div>
                    <div style={{ fontSize: '12px', color: 'var(--gray-500)' }}>Gains</div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>
      )}
    </div>
  );
}

export default DashboardPremium;
