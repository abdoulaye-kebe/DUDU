import React, { useState, useEffect, useMemo } from 'react';
import { motion } from 'framer-motion';
import StatCard from '../components/StatCard';
import DataTable from '../components/DataTable';
import DetailModal from '../components/DetailModal';
import { API_BASE_URL } from '../config';
import { 
  Users, 
  UserPlus, 
  UserCheck, 
  Car,
  RefreshCw,
  Download,
  Phone,
  Mail,
  Calendar,
  Star,
} from 'lucide-react';

function ClientsPremium({ navbarSearch = '' }) {
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [stats, setStats] = useState({
    total: 0,
    newToday: 0,
    totalRides: 0
  });
  const [selectedClient, setSelectedClient] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [statusFilter, setStatusFilter] = useState('all');

  useEffect(() => {
    loadClients();
    loadStats();
  }, []);

  const loadClients = async () => {
    try {
      setLoading(true);
      setError('');
      const token = localStorage.getItem('admin_token');
      const response = await fetch(`${API_BASE_URL}/admin/users?limit=500`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      const json = await response.json();
      if (!response.ok) {
        throw new Error(json.message || `Erreur ${response.status}`);
      }
      const users = json.data?.users || json.users || [];
      setClients(users);
    } catch (err) {
      console.error('Erreur chargement clients:', err);
      setError(err.message || 'Impossible de charger les clients');
      setClients([]);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const token = localStorage.getItem('admin_token');
      const response = await fetch(`${API_BASE_URL}/admin/dashboard`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      const result = await response.json();
      if (result.success) {
        const data = result.data;
        const overview = data.overview || {};
        const today = data.today || {};
        setStats({
          total: overview.totalUsers || 0,
          newToday: today.users || 0,
          totalRides: overview.totalRides || 0
        });
      }
    } catch (error) {
      console.error('Erreur chargement stats:', error);
    }
  };

  const filteredByStatus = useMemo(() => {
    if (statusFilter === 'all') return clients;
    if (statusFilter === 'active') return clients.filter((c) => c.isActive !== false);
    return clients.filter((c) => c.isActive === false);
  }, [clients, statusFilter]);

  const toggleUserActive = async (client) => {
    const id = client.id || client._id;
    if (!id) return;
    const next = !client.isActive;
    if (!window.confirm(next ? 'Réactiver ce compte ?' : 'Désactiver ce compte ?')) return;
    try {
      const token = localStorage.getItem('admin_token');
      const res = await fetch(`${API_BASE_URL}/admin/users/${id}/status`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ isActive: next })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Erreur');
      await loadClients();
    } catch (e) {
      alert(e.message || 'Erreur');
    }
  };

  const exportClientsCsv = () => {
    const headers = ['Prénom', 'Nom', 'Téléphone', 'Email', 'Courses', 'Note', 'Actif', 'Inscription'];
    const rows = filteredByStatus.map((c) => [
      c.firstName || '',
      c.lastName || '',
      c.phone || '',
      c.email || '',
      c.totalRides ?? 0,
      c.averageRating != null ? Number(c.averageRating).toFixed(1) : '',
      c.isActive !== false ? 'oui' : 'non',
      c.createdAt ? new Date(c.createdAt).toLocaleDateString('fr-FR') : ''
    ]);
    const esc = (x) => `"${String(x).replace(/"/g, '""')}"`;
    const csv = [headers, ...rows].map((line) => line.map(esc).join(',')).join('\n');
    const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `dudu-clients-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(a.href);
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    });
  };

  const columns = [
    {
      key: 'name',
      label: 'Client',
      render: (_, row) => (
        <div className="user-cell">
          <div className="user-cell-avatar">
            {(row.firstName?.[0] || row.name?.[0] || 'U').toUpperCase()}
          </div>
          <div className="user-cell-info">
            <span className="user-cell-name">
              {row.firstName && row.lastName 
                ? `${row.firstName} ${row.lastName}`
                : row.name || 'Utilisateur'}
            </span>
            <span className="user-cell-email">
              {row.email || 'Email non renseigné'}
            </span>
          </div>
        </div>
      )
    },
    {
      key: 'phone',
      label: 'Téléphone',
      render: (value) => (
        <span style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Phone size={14} style={{ color: 'var(--gray-400)' }} />
          {value || 'N/A'}
        </span>
      )
    },
    {
      key: 'totalRides',
      label: 'Courses',
      render: (value) => (
        <span style={{ 
          display: 'flex', 
          alignItems: 'center', 
          gap: '8px',
          fontWeight: 600,
          color: 'var(--primary-600)'
        }}>
          <Car size={14} />
          {value || 0}
        </span>
      )
    },
    {
      key: 'averageRating',
      label: 'Note',
      render: (value) => (
        <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <Star size={14} style={{ color: '#f59e0b', fill: '#f59e0b' }} />
          {value ? value.toFixed(1) : 'N/A'}
        </span>
      )
    },
    {
      key: 'createdAt',
      label: 'Inscription',
      render: (value) => (
        <span style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--gray-500)' }}>
          <Calendar size={14} />
          {formatDate(value)}
        </span>
      )
    },
    {
      key: 'isActive',
      label: 'Statut',
      render: (value) => (
        <span className={`badge ${value !== false ? 'badge-success' : 'badge-danger'}`}>
          {value !== false ? 'Actif' : 'Inactif'}
        </span>
      )
    }
  ];

  const searchText = (row) =>
    [
      row.firstName,
      row.lastName,
      row.name,
      row.phone,
      row.email
    ]
      .filter(Boolean)
      .join(' ');

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <div className="loading-text">Chargement des clients...</div>
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
            <h1 className="page-title">Gestion des Clients</h1>
            <p className="page-subtitle">
              Vue d'ensemble des utilisateurs de l'application DUDU
            </p>
          </div>
          <div className="page-actions">
            <motion.button 
              type="button"
              className="btn btn-secondary"
              onClick={() => { loadClients(); loadStats(); }}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <RefreshCw size={18} />
              Actualiser
            </motion.button>
            <motion.button 
              type="button"
              className="btn btn-secondary"
              onClick={exportClientsCsv}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <Download size={18} />
              Exporter
            </motion.button>
          </div>
        </div>
      </motion.div>

      {error && (
        <div className="card" style={{ padding: '16px 24px', marginBottom: 24, background: '#fef2f2', borderColor: 'var(--accent-red)' }}>
          {error}
        </div>
      )}

      <div className="stats-grid">
        <StatCard 
          title="Total Clients"
          value={stats.total}
          icon={Users}
          color="green"
          delay={0}
        />
        <StatCard 
          title="Liste affichée"
          value={filteredByStatus.length}
          icon={UserCheck}
          color="blue"
          delay={0.1}
        />
        <StatCard 
          title="Nouveaux Aujourd'hui"
          value={stats.newToday}
          icon={UserPlus}
          color="purple"
          delay={0.2}
        />
        <StatCard 
          title="Courses Totales"
          value={stats.totalRides}
          icon={Car}
          color="orange"
          delay={0.3}
        />
      </div>

      <DataTable
        title="Liste des Clients"
        icon={Users}
        columns={columns}
        data={filteredByStatus}
        emptyMessage="Aucun client trouvé"
        filterSlot={(
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12, alignItems: 'center' }}>
            <span style={{ fontSize: 14, color: 'var(--gray-600)' }}>Filtrer par statut :</span>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              style={{
                padding: '10px 14px',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--gray-200)',
                fontSize: 14,
                minWidth: 180
              }}
            >
              <option value="all">Tous les comptes</option>
              <option value="active">Actifs uniquement</option>
              <option value="inactive">Inactifs uniquement</option>
            </select>
          </div>
        )}
        searchText={searchText}
        navbarSearch={navbarSearch}
        pageSize={12}
        onExport={exportClientsCsv}
        onView={(client) => {
          setSelectedClient(client);
          setIsModalOpen(true);
        }}
        onEdit={(client) => toggleUserActive(client)}
        editLabel="Activer / désactiver"
      />

      <DetailModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedClient(null);
        }}
        data={selectedClient}
        type="client"
      />
    </div>
  );
}

export default ClientsPremium;
