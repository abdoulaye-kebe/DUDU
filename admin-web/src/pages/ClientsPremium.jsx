import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import axios from 'axios';
import { API_BASE_URL } from '../config';
import StatCard from '../components/StatCard';
import DataTable from '../components/DataTable';
import DetailModal from '../components/DetailModal';
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
  TrendingUp
} from 'lucide-react';

function ClientsPremium() {
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    total: 0,
    active: 0,
    newToday: 0,
    totalRides: 0
  });
  const [selectedClient, setSelectedClient] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    loadClients();
    loadStats();
  }, []);

  const loadClients = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_BASE_URL}/admin/users`);
      const users = response.data.data?.users || response.data.users || [];
      setClients(users);
    } catch (error) {
      console.error('Erreur chargement clients:', error);
      setClients([]);
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
        <span className={`badge ${value ? 'badge-success' : 'badge-danger'}`}>
          {value ? 'Actif' : 'Inactif'}
        </span>
      )
    }
  ];

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
      {/* Page Header */}
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
              className="btn btn-secondary"
              onClick={loadClients}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <RefreshCw size={18} />
              Actualiser
            </motion.button>
            <motion.button 
              className="btn btn-secondary"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <Download size={18} />
              Exporter
            </motion.button>
          </div>
        </div>
      </motion.div>

      {/* Stats Grid */}
      <div className="stats-grid">
        <StatCard 
          title="Total Clients"
          value={stats.total}
          icon={Users}
          color="green"
          delay={0}
        />
        <StatCard 
          title="Clients Actifs"
          value={clients.filter(c => c.isActive !== false).length}
          icon={UserCheck}
          trend="up"
          trendValue="98%"
          color="blue"
          delay={0.1}
        />
        <StatCard 
          title="Nouveaux Aujourd'hui"
          value={stats.newToday}
          icon={UserPlus}
          trend="up"
          trendValue="+12%"
          color="purple"
          delay={0.2}
        />
        <StatCard 
          title="Courses Totales"
          value={stats.totalRides}
          icon={Car}
          trend="up"
          trendValue="+8%"
          color="orange"
          delay={0.3}
        />
      </div>

      {/* Clients Table */}
      <DataTable
        title="Liste des Clients"
        icon={Users}
        columns={columns}
        data={clients}
        emptyMessage="Aucun client trouvé"
        onView={(client) => {
          setSelectedClient(client);
          setIsModalOpen(true);
        }}
        onEdit={(client) => console.log('Edit client:', client)}
      />

      {/* Detail Modal */}
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
