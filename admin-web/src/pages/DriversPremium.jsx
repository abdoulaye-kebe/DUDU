import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import DriverApplicationCard from '../components/DriverApplicationCard';
import DataTable from '../components/DataTable';
import DetailModal from '../components/DetailModal';
import ChangePasswordModal from '../components/ChangePasswordModal';
import AddDriverModal from '../components/AddDriverModal';
import { API_BASE_URL } from '../config';
import { 
  UserCheck, 
  Clock, 
  CheckCircle, 
  XCircle,
  RefreshCw,
  Plus,
  Users,
  Car,
  Phone,
  AlertCircle,
  Key
} from 'lucide-react';

function DriversPremium({ navbarSearch = '' }) {
  const [pending, setPending] = useState([]);
  const [approved, setApproved] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState('pending');
  const [selectedDriver, setSelectedDriver] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isPasswordModalOpen, setIsPasswordModalOpen] = useState(false);
  const [driverForPasswordChange, setDriverForPasswordChange] = useState(null);
  const [addDriverOpen, setAddDriverOpen] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      setError('');

      const token = localStorage.getItem('admin_token');
      const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      };

      const [pendingRes, approvedRes] = await Promise.all([
        fetch(`${API_BASE_URL}/admin/driver-applications`, { headers }),
        fetch(`${API_BASE_URL}/admin/drivers?verificationStatus=approved&limit=200`, { headers })
      ]);

      const pendingJson = await pendingRes.json();
      const approvedJson = await approvedRes.json();

      const errs = [];
      if (!pendingRes.ok) {
        setPending([]);
        errs.push(pendingJson.message || `Erreur candidatures (${pendingRes.status})`);
      } else {
        setPending(pendingJson.applications || []);
      }

      if (!approvedRes.ok) {
        setApproved([]);
        errs.push(approvedJson.message || `Erreur liste chauffeurs (${approvedRes.status})`);
      } else {
        setApproved(approvedJson.drivers || []);
      }

      setError(errs.length ? errs.join(' — ') : '');
    } catch (err) {
      console.error('Erreur chargement chauffeurs:', err);
      setError(err.message || 'Impossible de charger les données');
    } finally {
      setLoading(false);
    }
  };

  const exportApprovedCsv = () => {
    const headers = ['Prénom', 'Nom', 'Téléphone', 'Email', 'Profil', 'Véhicule', 'Plaque', 'Niveau', 'Courses'];
    const rows = approved.map((d) => {
      const moto = d.vehicle?.category === 'moto';
      const profil = moto ? 'Livreur moto' : 'Chauffeur VTC';
      const veh = `${d.vehicle?.make || ''} ${d.vehicle?.model || ''}`.trim();
      const level =
        d.rideTypes?.women_only === true
          ? 'Femme'
          : d.serviceLevel === 'express'
            ? 'Comfort+'
            : 'Standard';
      return [
        d.firstName || '',
        d.lastName || '',
        d.phone || '',
        d.email || '',
        profil,
        veh,
        d.vehicle?.plateNumber || '',
        level,
        d.stats?.totalRides ?? 0
      ];
    });
    const esc = (c) => `"${String(c).replace(/"/g, '""')}"`;
    const csv = [headers, ...rows].map((line) => line.map(esc).join(',')).join('\n');
    const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `dudu-chauffeurs-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(a.href);
  };

  const approvedSearchText = (row) =>
    [
      row.firstName,
      row.lastName,
      row.phone,
      row.email,
      row.nationalId,
      row.vehicle?.make,
      row.vehicle?.model,
      row.vehicle?.plateNumber
    ]
      .filter(Boolean)
      .join(' ');

  const handleDecision = async (driverId, decision, validationData = null) => {
    // Si c'est un rejet, demander confirmation
    if (decision === 'rejected') {
      if (!window.confirm('Êtes-vous sûr de vouloir rejeter cette candidature ?')) return;
    }

    try {
      const payload = {
        status: decision,
        notes: validationData?.notes || ''
      };

      // Si approuvé, ajouter les données de validation
      if (decision === 'approved' && validationData) {
        payload.serviceLevel = validationData.serviceLevel;
        payload.womenOnlyOverride = !!validationData.womenOnly;
        payload.vehicleCondition = validationData.vehicleCondition;
        payload.vehicleInspected = validationData.vehicleInspected;
        payload.documentsVerified = validationData.documentsVerified;
      }

      const token = localStorage.getItem('admin_token');
      const response = await fetch(`${API_BASE_URL}/admin/drivers/${driverId}/verify`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(payload)
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.message || 'Erreur lors de la mise à jour');
      }

      await loadData();
      
      if (decision === 'approved') {
        const levelLabel = validationData?.serviceLevel === 'express' ? 'Comfort+' : 'Standard';
        const womenLabel = validationData?.womenOnly ? ' + Femme' : '';
        alert(`Chauffeur validé avec succès en tant que "${levelLabel}${womenLabel}"`);
      }
    } catch (err) {
      console.error('Erreur décision:', err);
      alert(err.message || 'Erreur lors de la mise à jour');
    }
  };

  const handleDeleteDriver = async (driver) => {
    const id = driver._id || driver.id;
    if (!id) return;
    const moto = driver.vehicle?.category === 'moto';
    const profil = moto ? 'ce livreur moto' : 'ce chauffeur';
    if (
      !window.confirm(
        `Supprimer définitivement le compte de ${profil} (${driver.firstName || ''} ${driver.lastName || ''}) ?\n\n` +
          'Les données associées peuvent empêcher la suppression (courses, paiements). Cette action est irréversible.'
      )
    ) {
      return;
    }
    try {
      const token = localStorage.getItem('admin_token');
      const response = await fetch(`${API_BASE_URL}/admin/drivers/${id}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      const data = await response.json().catch(() => ({}));
      if (!response.ok) {
        throw new Error(data.message || `Erreur ${response.status}`);
      }
      await loadData();
    } catch (err) {
      console.error('Erreur suppression chauffeur:', err);
      alert(err.message || 'Impossible de supprimer ce compte (références en base ou droits).');
    }
  };

  const approvedColumns = [
    {
      key: '_profile',
      label: 'Profil',
      render: (_, row) => {
        const moto = row.vehicle?.category === 'moto';
        return (
          <span
            className="badge badge-info"
            style={{
              background: moto ? '#0ea5e9' : '#00A651',
              color: '#fff',
              fontWeight: 600
            }}
          >
            {moto ? 'Livreur moto' : 'Chauffeur VTC'}
          </span>
        );
      }
    },
    {
      key: 'name',
      label: 'Chauffeur',
      render: (_, row) => (
        <div className="user-cell">
          <div className="user-cell-avatar">
            {row.firstName?.[0]}{row.lastName?.[0]}
          </div>
          <div className="user-cell-info">
            <span className="user-cell-name">{row.firstName} {row.lastName}</span>
            <span className="user-cell-email">{row.email || 'Email non renseigné'}</span>
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
          {value}
        </span>
      )
    },
    {
      key: 'vehicle',
      label: 'Véhicule',
      render: (value) => (
        <span style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Car size={14} style={{ color: 'var(--gray-400)' }} />
          {value?.make} {value?.model}
        </span>
      )
    },
    {
      key: 'serviceLevel',
      label: 'Niveau',
      render: (value, row) => {
        const isComfort = value === 'express';
        const womenOnly = row.rideTypes?.women_only === true;
        const label = womenOnly ? '👩 Femme' : (isComfort ? '✨ Comfort+' : 'Standard');
        const bg = womenOnly ? '#7C3AED' : (isComfort ? '#FF9800' : '#00A651');
        return (
          <span
            className={`badge ${isComfort ? 'badge-warning' : 'badge-info'}`}
            style={{
              background: bg,
              color: '#fff',
              fontWeight: 600
            }}
          >
            {label}
          </span>
        );
      }
    },
    {
      key: 'status',
      label: 'Statut',
      render: (value) => (
        <span className={`badge ${value === 'online' ? 'badge-success' : 'badge-secondary'}`}>
          <span className={`status-dot ${value === 'online' ? 'online' : 'offline'}`}></span>
          {value === 'online' ? 'En ligne' : 'Hors ligne'}
        </span>
      )
    },
    {
      key: 'stats',
      label: 'Courses',
      render: (value) => (
        <span style={{ fontWeight: 600, color: 'var(--primary-600)' }}>
          {value?.totalRides || 0}
        </span>
      )
    }
  ];

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <div className="loading-text">Chargement des chauffeurs...</div>
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
            <h1 className="page-title">Gestion des Chauffeurs</h1>
            <p className="page-subtitle">
              Inscription chauffeur (VTC) ou livreur (moto) depuis l’app Pro ; ici vous validez, ajoutez ou supprimez un compte.
            </p>
          </div>
          <div className="page-actions">
            <motion.button 
              className="btn btn-secondary"
              onClick={loadData}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <RefreshCw size={18} />
              Actualiser
            </motion.button>
            <motion.button 
              type="button"
              className="btn btn-primary"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => setAddDriverOpen(true)}
            >
              <Plus size={18} />
              Ajouter un chauffeur
            </motion.button>
          </div>
        </div>
      </motion.div>

      {/* Error Alert */}
      <AnimatePresence>
        {error && (
          <motion.div 
            className="card"
            style={{ 
              padding: '16px 24px', 
              marginBottom: '24px',
              background: '#fef2f2',
              borderColor: 'var(--accent-red)',
              display: 'flex',
              alignItems: 'center',
              gap: '12px'
            }}
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
          >
            <AlertCircle size={20} style={{ color: 'var(--accent-red)' }} />
            <span style={{ color: 'var(--accent-red)', fontWeight: 500 }}>{error}</span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Stats Overview */}
      <motion.div 
        className="stats-grid"
        style={{ marginBottom: '32px' }}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
      >
        <motion.div 
          className="card"
          style={{ padding: '24px', display: 'flex', alignItems: 'center', gap: '20px' }}
          whileHover={{ y: -2 }}
        >
          <div className="stat-icon-wrapper orange">
            <Clock />
          </div>
          <div>
            <div style={{ fontSize: '32px', fontWeight: 700, color: 'var(--gray-900)' }}>
              {pending.length}
            </div>
            <div style={{ fontSize: '14px', color: 'var(--gray-500)' }}>
              Demandes en attente
            </div>
          </div>
        </motion.div>

        <motion.div 
          className="card"
          style={{ padding: '24px', display: 'flex', alignItems: 'center', gap: '20px' }}
          whileHover={{ y: -2 }}
        >
          <div className="stat-icon-wrapper green">
            <CheckCircle />
          </div>
          <div>
            <div style={{ fontSize: '32px', fontWeight: 700, color: 'var(--gray-900)' }}>
              {approved.length}
            </div>
            <div style={{ fontSize: '14px', color: 'var(--gray-500)' }}>
              Chauffeurs approuvés
            </div>
          </div>
        </motion.div>

        <motion.div 
          className="card"
          style={{ padding: '24px', display: 'flex', alignItems: 'center', gap: '20px' }}
          whileHover={{ y: -2 }}
        >
          <div className="stat-icon-wrapper blue">
            <Users />
          </div>
          <div>
            <div style={{ fontSize: '32px', fontWeight: 700, color: 'var(--gray-900)' }}>
              {approved.filter(d => d.status === 'online').length}
            </div>
            <div style={{ fontSize: '14px', color: 'var(--gray-500)' }}>
              Actuellement en ligne
            </div>
          </div>
        </motion.div>
      </motion.div>

      {/* Tabs */}
      <motion.div 
        className="filters-bar"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.3 }}
      >
        <div className="filter-group">
          <button 
            className={`filter-btn ${activeTab === 'pending' ? 'active' : ''}`}
            onClick={() => setActiveTab('pending')}
          >
            <Clock size={16} />
            En attente ({pending.length})
          </button>
          <button 
            className={`filter-btn ${activeTab === 'approved' ? 'active' : ''}`}
            onClick={() => setActiveTab('approved')}
          >
            <CheckCircle size={16} />
            Approuvés ({approved.length})
          </button>
        </div>
      </motion.div>

      {/* Content */}
      <AnimatePresence mode="wait">
        {activeTab === 'pending' ? (
          <motion.div
            key="pending"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 20 }}
            transition={{ duration: 0.3 }}
          >
            {pending.length === 0 ? (
              <motion.div 
                className="card"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
              >
                <div className="empty-state">
                  <div className="empty-state-icon">
                    <Clock />
                  </div>
                  <div className="empty-state-title">Aucune demande en attente</div>
                  <div className="empty-state-text">
                    Les nouvelles candidatures apparaîtront ici dès qu'un chauffeur soumet ses informations depuis l'application.
                  </div>
                </div>
              </motion.div>
            ) : (
              <div className="application-grid">
                {pending.map((driver, index) => (
                  <DriverApplicationCard
                    key={driver._id}
                    driver={driver}
                    onApprove={(id, validationData) => handleDecision(id, 'approved', validationData)}
                    onReject={(id) => handleDecision(id, 'rejected')}
                    onDeleteRecord={(d) => handleDeleteDriver(d)}
                    delay={index * 0.1}
                  />
                ))}
              </div>
            )}
          </motion.div>
        ) : (
          <motion.div
            key="approved"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
          >
            <DataTable
              title="Chauffeurs Approuvés"
              icon={UserCheck}
              columns={approvedColumns}
              data={approved}
              emptyMessage="Aucun chauffeur approuvé"
              searchText={approvedSearchText}
              navbarSearch={navbarSearch}
              pageSize={12}
              onExport={exportApprovedCsv}
              onView={(driver) => {
                setSelectedDriver(driver);
                setIsModalOpen(true);
              }}
              onEdit={(driver) => {
                setDriverForPasswordChange(driver);
                setIsPasswordModalOpen(true);
              }}
              editLabel="Modifier mot de passe"
              editIcon={Key}
              onDelete={(driver) => handleDeleteDriver(driver)}
            />
          </motion.div>
        )}
      </AnimatePresence>

      {/* Detail Modal */}
      <DetailModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedDriver(null);
        }}
        data={selectedDriver}
        type="driver"
      />

      {/* Change Password Modal */}
      <ChangePasswordModal
        isOpen={isPasswordModalOpen}
        onClose={() => {
          setIsPasswordModalOpen(false);
          setDriverForPasswordChange(null);
        }}
        driver={driverForPasswordChange}
        onPasswordChanged={loadData}
      />

      <AddDriverModal
        isOpen={addDriverOpen}
        onClose={() => setAddDriverOpen(false)}
        onCreated={loadData}
      />
    </div>
  );
}

export default DriversPremium;
