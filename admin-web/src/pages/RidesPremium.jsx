import React, { useState, useEffect, useCallback } from 'react';
import { motion } from 'framer-motion';
import api from '../services/api';
import StatCard from '../components/StatCard';
import DataTable from '../components/DataTable';
import DetailModal from '../components/DetailModal';
import { 
  MapPin, 
  Car, 
  Clock, 
  CheckCircle,
  XCircle,
  RefreshCw,
  Calendar,
  DollarSign,
  User,
  UserCheck,
  Activity
} from 'lucide-react';

function RidesPremium({ navbarSearch = '' }) {
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
  const [selectedRide, setSelectedRide] = useState(null);
  const [rideModalOpen, setRideModalOpen] = useState(false);
  const [rideCancelLoading, setRideCancelLoading] = useState(false);
  const [tabCounts, setTabCounts] = useState({ all: 0, in_progress: 0, completed: 0, cancelled: 0 });

  const loadStats = useCallback(async () => {
    try {
      const { data } = await api.get('/admin/dashboard');
      if (data.success) {
        const d = data.data;
        const overview = d.overview || {};
        const today = d.today || {};
        const charts = d.charts || {};
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
  }, []);

  const loadRides = useCallback(async () => {
    try {
      setLoading(true);
      const params = { limit: 200 };
      if (activeFilter !== 'all') {
        params.status = activeFilter;
      }
      const { data } = await api.get('/admin/rides', { params });
      if (data.success) {
        const list = data.data.rides || [];
        setRides(list);
        const st = data.data.stats;
        if (st) {
          setTabCounts({
            all: st.total ?? list.length,
            in_progress: st.inProgress ?? 0,
            completed: st.completed ?? 0,
            cancelled: st.cancelled ?? 0
          });
        }
      } else {
        setRides([]);
      }
    } catch (error) {
      console.error('Erreur chargement courses:', error);
      setRides([]);
    } finally {
      setLoading(false);
    }
  }, [activeFilter]);

  useEffect(() => {
    loadStats();
  }, [loadStats]);

  useEffect(() => {
    loadRides();
  }, [loadRides]);

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('fr-FR').format(amount || 0) + ' FCFA';
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
      arriving: { label: 'En route', class: 'badge-info', icon: UserCheck },
      arrived: { label: 'Arrivé', class: 'badge-info', icon: UserCheck },
      started: { label: 'En cours', class: 'badge-info', icon: Activity },
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
    const config = typeMap[type] || { label: type || '—', color: 'var(--gray-500)' };
    
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
      render: (value, row) => (
        <span style={{ color: 'var(--gray-500)', fontSize: '13px' }}>
          {formatDate(value || row.requestedAt || row.createdAt)}
        </span>
      )
    }
  ];

  const searchText = (row) =>
    [
      row.rideId,
      row.passenger?.name,
      row.passenger?.phone,
      row.driver?.name,
      row.driver?.phone,
      row.status,
      row.pickup?.address,
      row.destination?.address
    ]
      .filter(Boolean)
      .join(' ');

  const exportRidesCsv = () => {
    const headers = ['ID', 'Passager', 'Chauffeur', 'Type', 'Statut', 'Prix', 'Date'];
    const rows = rides.map((r) => [
      r.rideId || r.id || '',
      r.passenger?.name || '',
      r.driver?.name || '',
      r.rideType || '',
      r.status || '',
      r.pricing?.totalPrice ?? '',
      (r.createdAt || r.requestedAt)
        ? new Date(r.createdAt || r.requestedAt).toLocaleString('fr-FR')
        : ''
    ]);
    const esc = (x) => `"${String(x).replace(/"/g, '""')}"`;
    const csv = [headers, ...rows].map((line) => line.map(esc).join(',')).join('\n');
    const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `dudu-courses-${activeFilter}-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(a.href);
  };

  const scrollToTable = () => {
    const el = document.getElementById('rides-table-section');
    el?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  const handleAdminCancelRide = async (ride) => {
    const id = ride?.id || ride?._id;
    if (!id) return;
    const reason = window.prompt('Motif d’annulation (visible en base) :', 'Décision support');
    if (reason === null) return;
    setRideCancelLoading(true);
    try {
      await api.put(`/admin/rides/${id}/cancel`, {
        reason: reason.trim() || 'Annulation administrateur',
      });
      setRideModalOpen(false);
      setSelectedRide(null);
      await loadRides();
      await loadStats();
    } catch (e) {
      const msg = e?.response?.data?.message || e?.message || 'Erreur';
      alert(msg);
    } finally {
      setRideCancelLoading(false);
    }
  };

  if (loading && rides.length === 0) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <div className="loading-text">Chargement des courses...</div>
      </div>
    );
  }

  return (
    <div>
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
              Suivi des courses (API /admin/rides)
            </p>
          </div>
          <div className="page-actions">
            <motion.button 
              type="button"
              className="btn btn-secondary"
              onClick={() => { loadRides(); loadStats(); }}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <RefreshCw size={18} />
              Actualiser
            </motion.button>
            <motion.button 
              type="button"
              className="btn btn-primary"
              onClick={scrollToTable}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <Calendar size={18} />
              Voir le tableau
            </motion.button>
          </div>
        </div>
      </motion.div>

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
          trendValue="—"
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
          trendValue="—"
          color="orange"
          delay={0.3}
        />
      </div>

      <motion.div 
        className="filters-bar"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.3 }}
      >
        <div className="filter-group">
          <button 
            type="button"
            className={`filter-btn ${activeFilter === 'all' ? 'active' : ''}`}
            onClick={() => setActiveFilter('all')}
          >
            Toutes ({tabCounts.all})
          </button>
          <button 
            type="button"
            className={`filter-btn ${activeFilter === 'in_progress' ? 'active' : ''}`}
            onClick={() => setActiveFilter('in_progress')}
          >
            <Activity size={14} />
            En cours ({tabCounts.in_progress})
          </button>
          <button 
            type="button"
            className={`filter-btn ${activeFilter === 'completed' ? 'active' : ''}`}
            onClick={() => setActiveFilter('completed')}
          >
            <CheckCircle size={14} />
            Terminées ({tabCounts.completed})
          </button>
          <button 
            type="button"
            className={`filter-btn ${activeFilter === 'cancelled' ? 'active' : ''}`}
            onClick={() => setActiveFilter('cancelled')}
          >
            <XCircle size={14} />
            Annulées ({tabCounts.cancelled})
          </button>
        </div>
      </motion.div>

      <div id="rides-table-section">
        <DataTable
          title="Courses"
          icon={MapPin}
          columns={columns}
          data={rides}
          emptyMessage="Aucune course pour ce filtre"
          searchText={searchText}
          navbarSearch={navbarSearch}
          pageSize={15}
          onExport={exportRidesCsv}
          onView={(ride) => {
            setSelectedRide(ride);
            setRideModalOpen(true);
          }}
        />
      </div>

      <DetailModal
        isOpen={rideModalOpen}
        onClose={() => {
          setRideModalOpen(false);
          setSelectedRide(null);
        }}
        data={selectedRide}
        type="ride"
        onRideAdminCancel={handleAdminCancelRide}
        rideAdminCancelLoading={rideCancelLoading}
      />
    </div>
  );
}

export default RidesPremium;
