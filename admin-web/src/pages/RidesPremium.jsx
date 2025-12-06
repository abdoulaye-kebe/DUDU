import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import axios from 'axios';
import { API_BASE_URL } from '../config';
import StatCard from '../components/StatCard';
import DataTable from '../components/DataTable';
import { 
  MapPin, 
  Car, 
  Clock, 
  CheckCircle,
  XCircle,
  RefreshCw,
  Filter,
  Calendar,
  DollarSign,
  Navigation,
  User,
  UserCheck,
  Activity
} from 'lucide-react';

function RidesPremium() {
  const [rides, setRides] = useState([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    total: 0,
    completed: 0,
    inProgress: 0,
    cancelled: 0,
    todayRevenue: 0
  });
  const [activeFilter, setActiveFilter] = useState('all');

  useEffect(() => {
    loadRides();
    loadStats();
  }, []);

  const loadRides = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_BASE_URL}/admin/dashboard`);
      if (response.data.success) {
        setRides(response.data.data.recentRides || []);
      }
    } catch (error) {
      console.error('Erreur chargement courses:', error);
      setRides([]);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/admin/dashboard`);
      if (response.data.success) {
        const data = response.data.data;
        const overview = data.overview || {};
        const today = data.today || {};
        const charts = data.charts || {};
        
        setStats({
          total: overview.totalRides || 0,
          completed: charts.ridesByStatus?.completed || 0,
          inProgress: charts.ridesByStatus?.in_progress || 0,
          cancelled: charts.ridesByStatus?.cancelled || 0,
          todayRevenue: today.revenue || 0
        });
      }
    } catch (error) {
      console.error('Erreur chargement stats:', error);
    }
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('fr-FR').format(amount) + ' FCFA';
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getStatusBadge = (status) => {
    const statusMap = {
      pending: { label: 'En attente', class: 'badge-warning', icon: Clock },
      accepted: { label: 'Acceptée', class: 'badge-info', icon: CheckCircle },
      driver_assigned: { label: 'Chauffeur assigné', class: 'badge-info', icon: UserCheck },
      in_progress: { label: 'En cours', class: 'badge-info', icon: Activity },
      completed: { label: 'Terminée', class: 'badge-success', icon: CheckCircle },
      cancelled: { label: 'Annulée', class: 'badge-danger', icon: XCircle }
    };
    const config = statusMap[status] || { label: status, class: 'badge-secondary', icon: Clock };
    const Icon = config.icon;
    
    return (
      <span className={`badge ${config.class}`} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
        <Icon size={12} />
        {config.label}
      </span>
    );
  };

  const getRideTypeBadge = (type) => {
    const typeMap = {
      standard: { label: 'Standard', color: 'var(--primary-600)' },
      express: { label: 'Express', color: 'var(--accent-orange)' },
      shared: { label: 'Partagé', color: 'var(--accent-purple)' },
      delivery: { label: 'Livraison', color: 'var(--accent-cyan)' }
    };
    const config = typeMap[type] || { label: type, color: 'var(--gray-500)' };
    
    return (
      <span style={{ 
        padding: '4px 10px',
        borderRadius: 'var(--radius-full)',
        fontSize: '12px',
        fontWeight: 600,
        background: `${config.color}15`,
        color: config.color
      }}>
        {config.label}
      </span>
    );
  };

  const columns = [
    {
      key: 'rideId',
      label: 'ID Course',
      render: (value) => (
        <span style={{ 
          fontFamily: 'monospace', 
          fontWeight: 600, 
          color: 'var(--primary-600)',
          background: 'var(--primary-50)',
          padding: '4px 8px',
          borderRadius: 'var(--radius-sm)'
        }}>
          {value || 'N/A'}
        </span>
      )
    },
    {
      key: 'passenger',
      label: 'Passager',
      render: (value) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <User size={16} style={{ color: 'var(--gray-400)' }} />
          <span>{value?.name || 'N/A'}</span>
        </div>
      )
    },
    {
      key: 'driver',
      label: 'Chauffeur',
      render: (value) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <UserCheck size={16} style={{ color: 'var(--gray-400)' }} />
          <span>{value?.name || 'En attente'}</span>
        </div>
      )
    },
    {
      key: 'rideType',
      label: 'Type',
      render: (value) => getRideTypeBadge(value)
    },
    {
      key: 'status',
      label: 'Statut',
      render: (value) => getStatusBadge(value)
    },
    {
      key: 'pricing',
      label: 'Prix',
      render: (value) => (
        <span style={{ fontWeight: 600, color: 'var(--gray-900)' }}>
          {formatCurrency(value?.totalPrice || 0)}
        </span>
      )
    },
    {
      key: 'createdAt',
      label: 'Date',
      render: (value) => (
        <span style={{ color: 'var(--gray-500)', fontSize: '13px' }}>
          {formatDate(value)}
        </span>
      )
    }
  ];

  const filteredRides = activeFilter === 'all' 
    ? rides 
    : rides.filter(r => r.status === activeFilter);

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <div className="loading-text">Chargement des courses...</div>
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
            <h1 className="page-title">Gestion des Courses</h1>
            <p className="page-subtitle">
              Suivi en temps réel de toutes les courses DUDU
            </p>
          </div>
          <div className="page-actions">
            <motion.button 
              className="btn btn-secondary"
              onClick={loadRides}
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
              Historique
            </motion.button>
          </div>
        </div>
      </motion.div>

      {/* Stats Grid */}
      <div className="stats-grid">
        <StatCard 
          title="Total Courses"
          value={stats.total}
          icon={Car}
          color="green"
          delay={0}
        />
        <StatCard 
          title="Terminées"
          value={stats.completed}
          icon={CheckCircle}
          trend="up"
          trendValue="95%"
          color="blue"
          delay={0.1}
        />
        <StatCard 
          title="En Cours"
          value={stats.inProgress}
          icon={Activity}
          color="purple"
          delay={0.2}
        />
        <StatCard 
          title="Revenus Aujourd'hui"
          value={formatCurrency(stats.todayRevenue)}
          icon={DollarSign}
          trend="up"
          trendValue="+15%"
          color="orange"
          delay={0.3}
        />
      </div>

      {/* Filters */}
      <motion.div 
        className="filters-bar"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.3 }}
      >
        <div className="filter-group">
          <button 
            className={`filter-btn ${activeFilter === 'all' ? 'active' : ''}`}
            onClick={() => setActiveFilter('all')}
          >
            Toutes ({rides.length})
          </button>
          <button 
            className={`filter-btn ${activeFilter === 'in_progress' ? 'active' : ''}`}
            onClick={() => setActiveFilter('in_progress')}
          >
            <Activity size={14} />
            En cours
          </button>
          <button 
            className={`filter-btn ${activeFilter === 'completed' ? 'active' : ''}`}
            onClick={() => setActiveFilter('completed')}
          >
            <CheckCircle size={14} />
            Terminées
          </button>
          <button 
            className={`filter-btn ${activeFilter === 'cancelled' ? 'active' : ''}`}
            onClick={() => setActiveFilter('cancelled')}
          >
            <XCircle size={14} />
            Annulées
          </button>
        </div>
      </motion.div>

      {/* Rides Table */}
      <DataTable
        title="Courses Récentes"
        icon={MapPin}
        columns={columns}
        data={filteredRides}
        emptyMessage="Aucune course trouvée"
        onView={(ride) => console.log('View ride:', ride)}
      />
    </div>
  );
}

export default RidesPremium;
