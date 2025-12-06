import React from 'react';
import { motion } from 'framer-motion';
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
  Hash
} from 'lucide-react';

function DriverApplicationCard({ driver, onApprove, onReject, delay = 0 }) {
  const getInitials = (firstName, lastName) => {
    return `${firstName?.[0] || ''}${lastName?.[0] || ''}`.toUpperCase();
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
        <span className="badge badge-warning">En attente</span>
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

      {/* Footer */}
      <div className="application-card-footer">
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
          onClick={() => onApprove(driver._id)}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          <Check size={18} />
          Valider
        </motion.button>
      </div>
    </motion.div>
  );
}

export default DriverApplicationCard;
