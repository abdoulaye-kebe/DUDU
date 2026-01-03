import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { adminAPI } from '../services/api';
import StatCard from '../components/StatCard';
import DataTable from '../components/DataTable';
import { 
  XCircle, 
  User, 
  UserCheck, 
  Clock, 
  DollarSign,
  RefreshCw,
  Filter,
  Calendar,
  AlertTriangle,
  TrendingDown,
  Users,
  Car
} from 'lucide-react';

function CancelledRides() {
  const [rides, setRides] = useState([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    total: 0,
    byPassenger: 0,
    byDriver: 0,
    bySystem: 0,
    totalRefundAmount: 0
  });
  const [activeFilter, setActiveFilter] = useState('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [pagination, setPagination] = useState({});

  useEffect(() => {
    loadCancelledRides();
  }, [activeFilter, currentPage]);

  const loadCancelledRides = async () => {
    try {
      setLoading(true);
      const params = {
        page: currentPage,
        limit: 20
      };
      
      if (activeFilter !== 'all') {
        params.cancelledBy = activeFilter;
      }

      const response = await adminAPI.getCancelledRides(params);
      
      if (response.data.success) {
        setRides(response.data.data.cancelledRides || []);
        setStats(response.data.data.stats || {});
        setPagination(response.data.data.pagination || {});
      }
    } catch (error) {
      console.error('Erreur chargement courses annulées:', error);
      setRides([]);
    } finally {
      setLoading(false);
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
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getCancellationReasonLabel = (reason) => {
    const reasonMap = {
      passenger_cancelled: 'Client a annulé',
      driver_cancelled: 'Chauffeur a annulé',
      no_driver_found: 'Aucun chauffeur trouvé',
      payment_failed: 'Paiement échoué',
      system_error: 'Erreur système',
      weather: 'Conditions météo',
      emergency: 'Urgence'
    };
    return reasonMap[reason] || reason;
  };

  const getCancelledByBadge = (cancelledBy) => {
    const badgeMap = {
      passenger: { label: 'Client', class: 'badge-warning', icon: User },
      driver: { label: 'Chauffeur', class: 'badge-info', icon: Car },
      system: { label: 'Système', class: 'badge-danger', icon: AlertTriangle }
    };
    const config = badgeMap[cancelledBy] || { label: cancelledBy, class: 'badge-secondary', icon: XCircle };
    const Icon = config.icon;
    
    return (
      <span className={`badge ${config.class}`} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
        <Icon size={12} />
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
          color: 'var(--danger-600)',
          background: 'var(--danger-50)',
          padding: '4px 8px',
          borderRadius: 'var(--radius-sm)'
        }}>
          {value || 'N/A'}
        </span>
      )
    },
    {
      key: 'passenger',
      label: 'Client',
      render: (value) => (
        <div>
          <div style={{ fontWeight: 600 }}>{value?.name || 'N/A'}</div>
          <div style={{ fontSize: '12px', color: 'var(--gray-500)' }}>{value?.phone || ''}</div>
        </div>
      )
    },
    {
      key: 'driver',
      label: 'Chauffeur',
      render: (value) => (
        <div>
          <div style={{ fontWeight: 600 }}>{value?.name || 'Non assigné'}</div>
          <div style={{ fontSize: '12px', color: 'var(--gray-500)' }}>{value?.vehicle || ''}</div>
        </div>
      )
    },
    {
      key: 'cancellation',
      label: 'Annulé par',
      render: (value) => getCancelledByBadge(value?.cancelledBy)
    },
    {
      key: 'cancellation',
      label: 'Raison',
      render: (value) => (
        <span style={{ fontSize: '13px', color: 'var(--gray-600)' }}>
          {getCancellationReasonLabel(value?.reason)}
        </span>
      )
    },
    {
      key: 'pricing',
      label: 'Montant',
      render: (value) => (
        <span style={{ fontWeight: 600, color: 'var(--gray-900)' }}>
          {formatCurrency(value?.totalPrice || 0)}
        </span>
      )
    },
    {
      key: 'cancellation',
      label: 'Remboursement',
      render: (value) => (
        <div>
          <div style={{ fontWeight: 600, color: 'var(--success-600)' }}>
            {formatCurrency(value?.refundAmount || 0)}
          </div>
          <div style={{ fontSize: '11px', color: value?.refundProcessed ? 'var(--success-500)' : 'var(--warning-500)' }}>
            {value?.refundProcessed ? '✓ Traité' : '⏳ En attente'}
          </div>
        </div>
      )
    },
    {
      key: 'cancelledAt',
      label: 'Date annulation',
      render: (value) => (
        <span style={{ color: 'var(--gray-500)', fontSize: '13px' }}>
          {formatDate(value)}
        </span>
      )
    }
  ];

  const filteredRides = activeFilter === 'all' 
    ? rides 
    : rides.filter(r => r.cancellation?.cancelledBy === activeFilter);

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <div className="loading-text">Chargement de l'historique des annulations...</div>
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
            <h1 className="page-title">
              <XCircle size={32} style={{ marginRight: '12px', color: 'var(--danger-600)' }} />
              Courses Annulées
            </h1>
            <p className="page-subtitle">
              Historique complet des annulations avec détails et statistiques
            </p>
          </div>
          <div className="page-actions">
            <motion.button 
              className="btn btn-secondary"
              onClick={loadCancelledRides}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <RefreshCw size={18} />
              Actualiser
            </motion.button>
          </div>
        </div>
      </motion.div>

      {/* Stats Cards */}
      <div className="stats-grid" style={{ marginBottom: '2rem' }}>
        <StatCard
          title="Total Annulées"
          value={stats.total}
          icon={XCircle}
          trend={null}
          color="danger"
        />
        <StatCard
          title="Par Clients"
          value={stats.byPassenger}
          icon={Users}
          subtitle={`${stats.total > 0 ? Math.round((stats.byPassenger / stats.total) * 100) : 0}% du total`}
          color="warning"
        />
        <StatCard
          title="Par Chauffeurs"
          value={stats.byDriver}
          icon={Car}
          subtitle={`${stats.total > 0 ? Math.round((stats.byDriver / stats.total) * 100) : 0}% du total`}
          color="info"
        />
        <StatCard
          title="Remboursements"
          value={formatCurrency(stats.totalRefundAmount)}
          icon={DollarSign}
          subtitle="Montant total"
          color="success"
        />
      </div>

      {/* Filters */}
      <motion.div 
        className="filters-section"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
        style={{ marginBottom: '1.5rem' }}
      >
        <div className="filter-buttons">
          <button
            className={`filter-btn ${activeFilter === 'all' ? 'active' : ''}`}
            onClick={() => setActiveFilter('all')}
          >
            <Filter size={16} />
            Toutes ({stats.total})
          </button>
          <button
            className={`filter-btn ${activeFilter === 'passenger' ? 'active' : ''}`}
            onClick={() => setActiveFilter('passenger')}
          >
            <User size={16} />
            Clients ({stats.byPassenger})
          </button>
          <button
            className={`filter-btn ${activeFilter === 'driver' ? 'active' : ''}`}
            onClick={() => setActiveFilter('driver')}
          >
            <Car size={16} />
            Chauffeurs ({stats.byDriver})
          </button>
          <button
            className={`filter-btn ${activeFilter === 'system' ? 'active' : ''}`}
            onClick={() => setActiveFilter('system')}
          >
            <AlertTriangle size={16} />
            Système ({stats.bySystem})
          </button>
        </div>
      </motion.div>

      {/* Data Table */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
      >
        <DataTable
          columns={columns}
          data={filteredRides}
          emptyMessage="Aucune course annulée trouvée"
        />
      </motion.div>

      {/* Pagination */}
      {pagination.totalPages > 1 && (
        <div className="pagination" style={{ marginTop: '2rem', display: 'flex', justifyContent: 'center', gap: '10px' }}>
          <button
            className="btn btn-secondary"
            disabled={!pagination.hasPrev}
            onClick={() => setCurrentPage(currentPage - 1)}
          >
            Précédent
          </button>
          <span style={{ padding: '8px 16px', background: 'var(--gray-100)', borderRadius: 'var(--radius-md)' }}>
            Page {pagination.currentPage} sur {pagination.totalPages}
          </span>
          <button
            className="btn btn-secondary"
            disabled={!pagination.hasNext}
            onClick={() => setCurrentPage(currentPage + 1)}
          >
            Suivant
          </button>
        </div>
      )}
    </div>
  );
}

export default CancelledRides;
