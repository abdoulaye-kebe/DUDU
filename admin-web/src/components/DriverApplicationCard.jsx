import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Car, 
  FileText, 
  Settings2, 
  Phone, 
  Mail,
  Check,
  X,
  Calendar,
  Palette,
  Hash,
  Star,
  Zap,
  ClipboardCheck,
  MessageSquare,
  Trash2
} from 'lucide-react';

function DriverApplicationCard({ driver, onApprove, onReject, onDeleteRecord, delay = 0 }) {
  const [showValidationForm, setShowValidationForm] = useState(false);
  const [validationData, setValidationData] = useState({
    serviceLevel: 'standard',
    womenOnly: false,
    vehicleCondition: 'good',
    vehicleInspected: false,
    documentsVerified: false,
    notes: ''
  });

  const getInitials = (firstName, lastName) => {
    return `${firstName?.[0] || ''}${lastName?.[0] || ''}`.toUpperCase();
  };

  const handleApproveClick = () => {
    setShowValidationForm(true);
  };

  const handleConfirmApproval = () => {
    onApprove(driver._id, validationData);
    setShowValidationForm(false);
  };

  const handleCancelValidation = () => {
    setShowValidationForm(false);
    setValidationData({
      serviceLevel: 'standard',
      womenOnly: false,
      vehicleCondition: 'good',
      vehicleInspected: false,
      documentsVerified: false,
      notes: ''
    });
  };

  return (
    <motion.div 
      className="application-card"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay }}
      whileHover={{ y: -4 }}
    >
      {/* Header */}
      <div className="application-card-header">
        <div className="applicant-info">
          <motion.div 
            className="applicant-avatar"
            whileHover={{ scale: 1.1 }}
            transition={{ type: "spring", stiffness: 400 }}
          >
            {getInitials(driver.firstName, driver.lastName)}
          </motion.div>
          <div className="applicant-details">
            <h3>{driver.firstName} {driver.lastName}</h3>
            <div className="applicant-contact">
              <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Phone size={14} />
                {driver.phone}
              </span>
              {driver.email && (
                <span style={{ display: 'flex', alignItems: 'center', gap: '6px', marginTop: '2px' }}>
                  <Mail size={14} />
                  {driver.email}
                </span>
              )}
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6 }}>
          <span
            className="badge"
            style={{
              background: driver.vehicle?.category === 'moto' ? '#0ea5e9' : '#00A651',
              color: '#fff',
              fontWeight: 600
            }}
          >
            {driver.vehicle?.category === 'moto' ? 'Livreur moto' : 'Chauffeur VTC'}
          </span>
          <span className="badge badge-warning">En attente</span>
        </div>
      </div>

      {/* Body */}
      <div className="application-card-body">
        {/* Vehicle Info */}
        <div className="info-section">
          <div className="info-section-title">
            <Car />
            Véhicule
          </div>
          <div className="info-grid">
            <div className="info-item">
              <span className="info-label">Marque & Modèle</span>
              <span className="info-value">
                {driver.vehicle?.make} {driver.vehicle?.model}
              </span>
            </div>
            <div className="info-item">
              <span className="info-label">Année</span>
              <span className="info-value">{driver.vehicle?.year}</span>
            </div>
            <div className="info-item">
              <span className="info-label">Couleur</span>
              <span className="info-value" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Palette size={14} />
                {driver.vehicle?.color}
              </span>
            </div>
            <div className="info-item">
              <span className="info-label">Plaque</span>
              <span className="info-value" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Hash size={14} />
                {driver.vehicle?.plateNumber}
              </span>
            </div>
          </div>
        </div>

        {/* Documents */}
        <div className="info-section">
          <div className="info-section-title">
            <FileText />
            Documents
          </div>
          <div className="info-grid">
            <div className="info-item">
              <span className="info-label">N° Permis</span>
              <span className="info-value">{driver.driverLicense?.number}</span>
            </div>
            <div className="info-item">
              <span className="info-label">Expiration</span>
              <span className="info-value" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Calendar size={14} />
                {driver.driverLicense?.expiryDate?.slice(0, 10)}
              </span>
            </div>
          </div>
        </div>

        {/* Preferences */}
        <div className="info-section">
          <div className="info-section-title">
            <Settings2 />
            Préférences
          </div>
          <div className="info-grid">
            <div className="info-item">
              <span className="info-label">Distance max</span>
              <span className="info-value">{driver.preferences?.maxDistance || 10} km</span>
            </div>
            <div className="info-item">
              <span className="info-label">Prix minimum</span>
              <span className="info-value">{driver.preferences?.minPrice || 1000} FCFA</span>
            </div>
          </div>
        </div>
      </div>

      {/* Formulaire de validation */}
      <AnimatePresence>
        {showValidationForm && (
          <motion.div
            className="validation-form"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            style={{
              background: 'linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%)',
              padding: '20px',
              borderTop: '2px solid #00A651',
              borderRadius: '0 0 12px 12px'
            }}
          >
            <h4 style={{ 
              marginBottom: '16px', 
              color: '#00A651',
              display: 'flex',
              alignItems: 'center',
              gap: '8px'
            }}>
              <ClipboardCheck size={20} />
              Formulaire de validation
            </h4>

            {/* Niveau de service */}
            <div style={{ marginBottom: '16px' }}>
              <label style={{ 
                display: 'block', 
                marginBottom: '8px', 
                fontWeight: '600',
                color: '#333'
              }}>
                Niveau de service *
              </label>
              <div style={{ display: 'flex', gap: '12px' }}>
                <label style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '12px 20px',
                  border: validationData.serviceLevel === 'standard' ? '2px solid #00A651' : '2px solid #ddd',
                  borderRadius: '8px',
                  cursor: 'pointer',
                  background: validationData.serviceLevel === 'standard' ? '#e8f5e9' : '#fff',
                  flex: 1
                }}>
                  <input
                    type="radio"
                    name="serviceLevel"
                    value="standard"
                    checked={validationData.serviceLevel === 'standard'}
                    onChange={(e) => setValidationData({...validationData, serviceLevel: e.target.value})}
                    style={{ display: 'none' }}
                  />
                  <Car size={24} color={validationData.serviceLevel === 'standard' ? '#00A651' : '#666'} />
                  <div>
                    <div style={{ fontWeight: '600' }}>Standard</div>
                    <div style={{ fontSize: '12px', color: '#666' }}>Véhicule normal</div>
                  </div>
                </label>
                <label style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '12px 20px',
                  border: validationData.serviceLevel === 'express' ? '2px solid #FF9800' : '2px solid #ddd',
                  borderRadius: '8px',
                  cursor: 'pointer',
                  background: validationData.serviceLevel === 'express' ? '#fff3e0' : '#fff',
                  flex: 1
                }}>
                  <input
                    type="radio"
                    name="serviceLevel"
                    value="express"
                    checked={validationData.serviceLevel === 'express'}
                    onChange={(e) => setValidationData({...validationData, serviceLevel: e.target.value})}
                    style={{ display: 'none' }}
                  />
                  <Zap size={24} color={validationData.serviceLevel === 'express' ? '#FF9800' : '#666'} />
                  <div>
                    <div style={{ fontWeight: '600' }}>Comfort+</div>
                    <div style={{ fontSize: '12px', color: '#666' }}>Confort haut de gamme</div>
                  </div>
                </label>
              </div>
            </div>

            {/* Femme uniquement */}
            <div style={{ marginBottom: '16px' }}>
              <label style={{
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                cursor: 'pointer',
                userSelect: 'none'
              }}>
                <input
                  type="checkbox"
                  checked={validationData.womenOnly}
                  onChange={(e) => setValidationData({ ...validationData, womenOnly: e.target.checked })}
                />
                <span style={{ fontWeight: 600, color: '#333' }}>Femme uniquement (women_only)</span>
              </label>
              <div style={{ fontSize: '12px', color: '#666', marginTop: '6px' }}>
                Active le type de course "Femme" pour ce chauffeur.
              </div>
            </div>

            {/* État du véhicule */}
            <div style={{ marginBottom: '16px' }}>
              <label style={{ 
                display: 'block', 
                marginBottom: '8px', 
                fontWeight: '600',
                color: '#333'
              }}>
                État du véhicule
              </label>
              <select
                value={validationData.vehicleCondition}
                onChange={(e) => setValidationData({...validationData, vehicleCondition: e.target.value})}
                style={{
                  width: '100%',
                  padding: '10px 12px',
                  borderRadius: '8px',
                  border: '2px solid #ddd',
                  fontSize: '14px'
                }}
              >
                <option value="excellent">Excellent - Comme neuf</option>
                <option value="good">Bon - Bien entretenu</option>
                <option value="acceptable">Acceptable - Quelques défauts</option>
                <option value="rejected">Rejeté - Non conforme</option>
              </select>
            </div>

            {/* Checkboxes */}
            <div style={{ display: 'flex', gap: '20px', marginBottom: '16px' }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={validationData.vehicleInspected}
                  onChange={(e) => setValidationData({...validationData, vehicleInspected: e.target.checked})}
                  style={{ width: '18px', height: '18px' }}
                />
                <span>Véhicule inspecté physiquement</span>
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={validationData.documentsVerified}
                  onChange={(e) => setValidationData({...validationData, documentsVerified: e.target.checked})}
                  style={{ width: '18px', height: '18px' }}
                />
                <span>Documents vérifiés</span>
              </label>
            </div>

            {/* Notes */}
            <div style={{ marginBottom: '16px' }}>
              <label style={{ 
                display: 'flex', 
                alignItems: 'center',
                gap: '6px',
                marginBottom: '8px', 
                fontWeight: '600',
                color: '#333'
              }}>
                <MessageSquare size={16} />
                Notes (optionnel)
              </label>
              <textarea
                value={validationData.notes}
                onChange={(e) => setValidationData({...validationData, notes: e.target.value})}
                placeholder="Remarques sur le véhicule, le chauffeur..."
                style={{
                  width: '100%',
                  padding: '10px 12px',
                  borderRadius: '8px',
                  border: '2px solid #ddd',
                  fontSize: '14px',
                  minHeight: '80px',
                  resize: 'vertical'
                }}
              />
            </div>

            {/* Boutons de confirmation */}
            <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
              <motion.button
                className="btn"
                onClick={handleCancelValidation}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                style={{ background: '#6c757d', color: '#fff' }}
              >
                Annuler
              </motion.button>
              <motion.button
                className="btn btn-success"
                onClick={handleConfirmApproval}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <Check size={18} />
                Confirmer la validation
              </motion.button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Footer */}
      {!showValidationForm && (
        <div className="application-card-footer" style={{ flexWrap: 'wrap', gap: 8 }}>
          <motion.button 
            className="btn btn-danger"
            onClick={() => onReject(driver._id)}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <X size={18} />
            Refuser
          </motion.button>
          <motion.button 
            className="btn btn-success"
            onClick={handleApproveClick}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <Check size={18} />
            Valider
          </motion.button>
          {typeof onDeleteRecord === 'function' && (
            <motion.button
              type="button"
              className="btn"
              title="Supprimer définitivement le dossier (base de données)"
              onClick={() => onDeleteRecord(driver)}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              style={{
                background: '#fff',
                color: '#b91c1c',
                border: '2px solid #fecaca',
              }}
            >
              <Trash2 size={18} />
              Supprimer le compte
            </motion.button>
          )}
        </div>
      )}
    </motion.div>
  );
}

export default DriverApplicationCard;
