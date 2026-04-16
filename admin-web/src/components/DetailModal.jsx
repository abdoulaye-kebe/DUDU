import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, User, Phone, Mail, Car, Calendar, MapPin, Star, Clock } from 'lucide-react';

function canAdminCancelRide(status) {
  if (!status) return false;
  return !['completed', 'cancelled', 'no_driver', 'expired'].includes(status);
}

function DetailModal({
  isOpen,
  onClose,
  data,
  type,
  onRideAdminCancel,
  rideAdminCancelLoading = false,
}) {
  if (!isOpen || !data) return null;

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: 'long',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('fr-FR').format(amount || 0) + ' FCFA';
  };

  const getInitials = (firstName, lastName, name) => {
    if (firstName && lastName) {
      return `${firstName[0]}${lastName[0]}`.toUpperCase();
    }
    if (name) {
      return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
    }
    return 'U';
  };

  const renderClientDetails = () => (
    <>
      <div className="modal-section">
        <h4 className="modal-section-title">
          <User size={18} />
          Informations Personnelles
        </h4>
        <div className="modal-grid">
          <div className="modal-field">
            <span className="modal-label">Nom complet</span>
            <span className="modal-value">
              {data.firstName && data.lastName 
                ? `${data.firstName} ${data.lastName}`
                : data.name || 'Non renseigné'}
            </span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Email</span>
            <span className="modal-value">{data.email || 'Non renseigné'}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Téléphone</span>
            <span className="modal-value">{data.phone || 'Non renseigné'}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Date d'inscription</span>
            <span className="modal-value">{formatDate(data.createdAt)}</span>
          </div>
        </div>
      </div>

      <div className="modal-section">
        <h4 className="modal-section-title">
          <Car size={18} />
          Statistiques
        </h4>
        <div className="modal-stats">
          <div className="modal-stat">
            <span className="modal-stat-value">{data.totalRides || 0}</span>
            <span className="modal-stat-label">Courses</span>
          </div>
          <div className="modal-stat">
            <span className="modal-stat-value">{formatCurrency(data.totalSpent)}</span>
            <span className="modal-stat-label">Total dépensé</span>
          </div>
          <div className="modal-stat">
            <span className="modal-stat-value">
              {data.averageRating ? data.averageRating.toFixed(1) : 'N/A'}
            </span>
            <span className="modal-stat-label">Note moyenne</span>
          </div>
        </div>
      </div>
    </>
  );

  const renderDriverDetails = () => (
    <>
      <div className="modal-section">
        <h4 className="modal-section-title">
          <User size={18} />
          Informations Personnelles
        </h4>
        <div className="modal-grid">
          <div className="modal-field">
            <span className="modal-label">Profil</span>
            <span className="modal-value">
              {data.vehicle?.category === 'moto' ? 'Livreur moto (livraison)' : 'Chauffeur VTC (voiture)'}
            </span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Nom complet</span>
            <span className="modal-value">{data.firstName} {data.lastName}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">CNI</span>
            <span className="modal-value">{data.nationalId || '—'}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Email</span>
            <span className="modal-value">{data.email || 'Non renseigné'}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Téléphone</span>
            <span className="modal-value">{data.phone}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Genre</span>
            <span className="modal-value">
              {data.gender === 'male' ? 'Homme' : data.gender === 'female' ? 'Femme' : 'Non spécifié'}
            </span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Vérification</span>
            <span className="modal-value">{data.verificationStatus || '—'}</span>
          </div>
        </div>
      </div>

      <div className="modal-section">
        <h4 className="modal-section-title">
          <Car size={18} />
          Véhicule
        </h4>
        <div className="modal-grid">
          <div className="modal-field">
            <span className="modal-label">Marque / Modèle</span>
            <span className="modal-value">{data.vehicle?.make} {data.vehicle?.model}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Année</span>
            <span className="modal-value">{data.vehicle?.year}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Couleur</span>
            <span className="modal-value">{data.vehicle?.color}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Plaque</span>
            <span className="modal-value">{data.vehicle?.plateNumber}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Permis</span>
            <span className="modal-value">
              {data.driverLicense?.number || '—'}
              {data.driverLicense?.expiryDate
                ? ` (exp. ${formatDate(data.driverLicense.expiryDate)})`
                : ''}
            </span>
          </div>
        </div>
      </div>

      <div className="modal-section">
        <h4 className="modal-section-title">
          <Star size={18} />
          Performance
        </h4>
        <div className="modal-stats">
          <div className="modal-stat">
            <span className="modal-stat-value">{data.stats?.totalRides || 0}</span>
            <span className="modal-stat-label">Courses</span>
          </div>
          <div className="modal-stat">
            <span className="modal-stat-value">{formatCurrency(data.earnings?.total)}</span>
            <span className="modal-stat-label">Gains totaux</span>
          </div>
          <div className="modal-stat">
            <span className="modal-stat-value">
              {data.rating ? data.rating.toFixed(1) : 'N/A'}
            </span>
            <span className="modal-stat-label">Note</span>
          </div>
        </div>
      </div>
    </>
  );

  const renderRideDetails = () => (
    <>
      <div className="modal-section">
        <h4 className="modal-section-title">
          <MapPin size={18} />
          Trajet
        </h4>
        <div className="modal-grid">
          <div className="modal-field full-width">
            <span className="modal-label">Départ</span>
            <span className="modal-value">{data.pickup?.address || 'Non renseigné'}</span>
          </div>
          <div className="modal-field full-width">
            <span className="modal-label">Destination</span>
            <span className="modal-value">{data.destination?.address || 'Non renseigné'}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Distance</span>
            <span className="modal-value">{data.distance ? `${data.distance.toFixed(1)} km` : 'N/A'}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Durée estimée</span>
            <span className="modal-value">{data.estimatedDuration ? `${data.estimatedDuration} min` : 'N/A'}</span>
          </div>
        </div>
      </div>

      <div className="modal-section">
        <h4 className="modal-section-title">
          <User size={18} />
          Participants
        </h4>
        <div className="modal-grid">
          <div className="modal-field">
            <span className="modal-label">Passager</span>
            <span className="modal-value">{data.passenger?.name || 'N/A'}</span>
          </div>
          <div className="modal-field">
            <span className="modal-label">Chauffeur</span>
            <span className="modal-value">{data.driver?.name || 'En attente'}</span>
          </div>
        </div>
      </div>

      <div className="modal-section">
        <h4 className="modal-section-title">
          <Clock size={18} />
          Détails
        </h4>
        <div className="modal-stats">
          <div className="modal-stat">
            <span className="modal-stat-value">{formatCurrency(data.pricing?.totalPrice)}</span>
            <span className="modal-stat-label">Prix total</span>
          </div>
          <div className="modal-stat">
            <span className="modal-stat-value">{data.rideType || 'Standard'}</span>
            <span className="modal-stat-label">Type</span>
          </div>
          <div className="modal-stat">
            <span className="modal-stat-value">{data.status || 'N/A'}</span>
            <span className="modal-stat-label">Statut</span>
          </div>
        </div>
      </div>
    </>
  );

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            className="modal-backdrop"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />

          {/* Modal */}
          <motion.div
            className="modal-container"
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ type: "spring", damping: 25, stiffness: 300 }}
          >
            {/* Header */}
            <div className="modal-header">
              <div className="modal-header-info">
                <div className="modal-avatar">
                  {getInitials(data.firstName, data.lastName, data.name)}
                </div>
                <div>
                  <h3 className="modal-title">
                    {data.firstName && data.lastName 
                      ? `${data.firstName} ${data.lastName}`
                      : data.name || data.rideId || 'Détails'}
                  </h3>
                  <p className="modal-subtitle">
                    {type === 'client' && 'Client DUDU'}
                    {type === 'driver' && 'Chauffeur DUDU Pro'}
                    {type === 'ride' && `Course ${data.rideId || ''}`}
                  </p>
                </div>
              </div>
              <motion.button
                className="modal-close"
                onClick={onClose}
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
              >
                <X size={20} />
              </motion.button>
            </div>

            {/* Body */}
            <div className="modal-body">
              {type === 'client' && renderClientDetails()}
              {type === 'driver' && renderDriverDetails()}
              {type === 'ride' && renderRideDetails()}
            </div>

            {/* Footer */}
            <div className="modal-footer">
              <motion.button
                className="btn btn-secondary"
                onClick={onClose}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                Fermer
              </motion.button>
              {type === 'ride' &&
                onRideAdminCancel &&
                data &&
                canAdminCancelRide(data.status) && (
                  <motion.button
                    type="button"
                    className="btn btn-primary"
                    style={{ background: 'var(--accent-red)', borderColor: 'var(--accent-red)' }}
                    disabled={rideAdminCancelLoading}
                    onClick={() => onRideAdminCancel(data)}
                    whileHover={{ scale: rideAdminCancelLoading ? 1 : 1.02 }}
                    whileTap={{ scale: rideAdminCancelLoading ? 1 : 0.98 }}
                  >
                    {rideAdminCancelLoading ? 'Annulation…' : 'Annuler la course'}
                  </motion.button>
                )}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}

export default DetailModal;
