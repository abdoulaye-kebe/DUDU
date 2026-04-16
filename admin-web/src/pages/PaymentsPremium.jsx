import React, { useState, useEffect, useCallback } from 'react';
import { motion } from 'framer-motion';
import api from '../services/api';
import DataTable from '../components/DataTable';
import { CreditCard, RefreshCw, DollarSign } from 'lucide-react';

function PaymentsPremium({ navbarSearch = '' }) {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [summary, setSummary] = useState({ totalRevenue: 0 });

  const loadPayments = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      const { data } = await api.get('/admin/payments', { params: { limit: 200 } });
      if (data.success) {
        setPayments(data.data?.payments || []);
        setSummary({ totalRevenue: data.data?.summary?.totalRevenue || 0 });
      } else {
        setPayments([]);
      }
    } catch (e) {
      console.error(e);
      setError(e?.response?.data?.message || e.message || 'Erreur chargement');
      setPayments([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadPayments();
  }, [loadPayments]);

  const formatCurrency = (n) =>
    new Intl.NumberFormat('fr-FR').format(n || 0) + ' FCFA';

  const columns = [
    {
      key: 'paymentId',
      label: 'Réf.',
      render: (v) => <span style={{ fontFamily: 'monospace', fontSize: 13 }}>{v || '—'}</span>,
    },
    {
      key: 'type',
      label: 'Type',
      render: (v) => v || '—',
    },
    {
      key: 'amount',
      label: 'Montant',
      render: (v) => <strong>{formatCurrency(v)}</strong>,
    },
    {
      key: 'method',
      label: 'Méthode',
      render: (v) => v || '—',
    },
    {
      key: 'status',
      label: 'Statut',
      render: (v) => (
        <span className={`badge ${v === 'completed' ? 'badge-success' : 'badge-secondary'}`}>
          {v || '—'}
        </span>
      ),
    },
    {
      key: 'user',
      label: 'Client',
      render: (v) => v?.name || '—',
    },
    {
      key: 'driver',
      label: 'Chauffeur',
      render: (v) => v?.name || '—',
    },
    {
      key: 'ride',
      label: 'Course',
      render: (v) => v?.rideId || '—',
    },
  ];

  const searchText = (row) =>
    [
      row.paymentId,
      row.type,
      row.status,
      row.method,
      row.user?.name,
      row.driver?.name,
      row.ride?.rideId,
    ]
      .filter(Boolean)
      .join(' ');

  if (loading && payments.length === 0) {
    return (
      <div className="loading-container">
        <div className="loading-spinner" />
        <div className="loading-text">Chargement des paiements…</div>
      </div>
    );
  }

  return (
    <div>
      <motion.div className="page-header" initial={{ opacity: 0, y: -12 }} animate={{ opacity: 1, y: 0 }}>
        <div className="page-header-content">
          <div className="page-title-section">
            <h1 className="page-title">Paiements</h1>
            <p className="page-subtitle">Liste des transactions (API /admin/payments)</p>
          </div>
          <div className="page-actions">
            <motion.button
              type="button"
              className="btn btn-secondary"
              onClick={loadPayments}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <RefreshCw size={18} />
              Actualiser
            </motion.button>
          </div>
        </div>
      </motion.div>

      {error && (
        <div className="card" style={{ padding: 16, marginBottom: 16, background: '#fef2f2', color: '#b91c1c' }}>
          {error}
        </div>
      )}

      <div className="stats-grid" style={{ marginBottom: 24 }}>
        <div className="card" style={{ padding: 20, display: 'flex', alignItems: 'center', gap: 16 }}>
          <div className="stat-icon-wrapper green">
            <DollarSign />
          </div>
          <div>
            <div style={{ fontSize: 14, color: 'var(--gray-500)' }}>Revenus cumulés (paiements complétés)</div>
            <div style={{ fontSize: 24, fontWeight: 700 }}>{formatCurrency(summary.totalRevenue)}</div>
          </div>
        </div>
      </div>

      <DataTable
        title="Transactions"
        icon={CreditCard}
        columns={columns}
        data={payments}
        emptyMessage="Aucun paiement"
        searchText={searchText}
        navbarSearch={navbarSearch}
        pageSize={15}
        actions={false}
      />
    </div>
  );
}

export default PaymentsPremium;
