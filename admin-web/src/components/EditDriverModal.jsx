import React, { useEffect, useState } from 'react';
import { API_BASE_URL } from '../config';
import { X, UserCog } from 'lucide-react';

function fromDriver(driver) {
  if (!driver) return null;
  const v = driver.vehicle || {};
  const dl = driver.driverLicense || {};
  const rt = driver.rideTypes || {};
  return {
    firstName: driver.firstName || '',
    lastName: driver.lastName || '',
    phone: driver.phone || '',
    email: driver.email || '',
    nationalId: driver.nationalId || '',
    gender: driver.gender || 'male',
    serviceLevel: driver.serviceLevel || 'standard',
    womenOnly: rt.women_only === true,
    vehicleMake: v.make || '',
    vehicleModel: v.model || '',
    vehicleYear: v.year != null ? String(v.year) : String(new Date().getFullYear()),
    vehicleColor: v.color || '',
    plateNumber: v.plateNumber || '',
    category: v.category === 'moto' ? 'moto' : 'car',
    licenseNumber: dl.number || '',
    licenseExpiry: dl.expiryDate ? String(dl.expiryDate).slice(0, 10) : '',
  };
}

function EditDriverModal({ isOpen, onClose, driver, onSaved }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [form, setForm] = useState(() => fromDriver(driver) || {});

  useEffect(() => {
    if (isOpen && driver) {
      setForm(fromDriver(driver) || {});
      setError('');
    }
  }, [isOpen, driver]);

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }));

  const handleClose = () => {
    setError('');
    onClose();
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!driver?._id && !driver?.id) return;
    setError('');
    setLoading(true);
    try {
      const id = driver._id || driver.id;
      const token = localStorage.getItem('admin_token');
      const vehicle = {
        make: form.vehicleMake.trim(),
        model: form.vehicleModel.trim(),
        year: parseInt(form.vehicleYear, 10),
        color: form.vehicleColor.trim(),
        plateNumber: form.plateNumber.trim().toUpperCase(),
        category: form.category,
        type: form.category === 'moto' ? 'moto_delivery' : 'sedan',
        capacity: form.category === 'moto' ? 1 : 4,
      };
      const body = {
        firstName: form.firstName.trim(),
        lastName: form.lastName.trim(),
        phone: form.phone.trim(),
        email: form.email.trim().toLowerCase(),
        nationalId: form.nationalId.trim(),
        gender: form.gender,
        serviceLevel: form.serviceLevel,
        vehicle,
        driverLicense: {
          number: form.licenseNumber.trim(),
          expiryDate: form.licenseExpiry,
          category: form.category === 'moto' ? 'A' : 'B',
        },
        rideTypes: {
          ...(driver.rideTypes || {}),
          women_only: !!form.womenOnly,
        },
      };

      const res = await fetch(`${API_BASE_URL}/admin/drivers/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(body),
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || 'Erreur lors de la mise à jour');
      }
      if (onSaved) onSaved();
      handleClose();
    } catch (err) {
      setError(err.message || 'Erreur');
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen || !driver) return null;

  return (
    <div className="modal-overlay" onClick={handleClose}>
      <div
        className="modal-content"
        onClick={(ev) => ev.stopPropagation()}
        style={{ maxWidth: 560, maxHeight: '92vh', overflow: 'auto' }}
      >
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div
              style={{
                width: 40,
                height: 40,
                borderRadius: 10,
                background: 'linear-gradient(135deg, var(--primary-500), var(--primary-600))',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <UserCog size={20} color="white" />
            </div>
            <div>
              <h2 className="modal-title">Modifier le chauffeur</h2>
              <p style={{ fontSize: 14, color: 'var(--gray-500)', marginTop: 4 }}>
                Mise à jour du profil et du véhicule (API PUT /admin/drivers/:id).
              </p>
            </div>
          </div>
          <button type="button" className="modal-close" onClick={handleClose} aria-label="Fermer">
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {error && (
              <div
                style={{
                  padding: '12px 16px',
                  background: '#fef2f2',
                  border: '1px solid var(--accent-red)',
                  borderRadius: 8,
                  color: 'var(--accent-red)',
                  marginBottom: 16,
                  fontSize: 14,
                }}
              >
                {error}
              </div>
            )}

            <div className="form-group">
              <label className="form-label">Type de véhicule</label>
              <select
                className="form-input"
                value={form.category}
                onChange={(e) => set('category', e.target.value)}
              >
                <option value="car">Voiture (VTC)</option>
                <option value="moto">Moto (livraison)</option>
              </select>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <div className="form-group">
                <label className="form-label">Prénom *</label>
                <input
                  className="form-input"
                  value={form.firstName}
                  onChange={(e) => set('firstName', e.target.value)}
                  required
                />
              </div>
              <div className="form-group">
                <label className="form-label">Nom *</label>
                <input
                  className="form-input"
                  value={form.lastName}
                  onChange={(e) => set('lastName', e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Téléphone *</label>
              <input
                className="form-input"
                value={form.phone}
                onChange={(e) => set('phone', e.target.value)}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">Email</label>
              <input
                className="form-input"
                type="email"
                value={form.email}
                onChange={(e) => set('email', e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">CNI</label>
              <input
                className="form-input"
                value={form.nationalId}
                onChange={(e) => set('nationalId', e.target.value)}
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <div className="form-group">
                <label className="form-label">Niveau de service</label>
                <select
                  className="form-input"
                  value={form.serviceLevel}
                  onChange={(e) => set('serviceLevel', e.target.value)}
                >
                  <option value="standard">Standard</option>
                  <option value="express">Comfort+ (express)</option>
                  <option value="luxe">Luxe</option>
                </select>
              </div>
              <div className="form-group" style={{ display: 'flex', alignItems: 'flex-end' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={!!form.womenOnly}
                    onChange={(e) => set('womenOnly', e.target.checked)}
                  />
                  <span>Course femmes uniquement</span>
                </label>
              </div>
            </div>

            <h4 style={{ margin: '16px 0 8px', fontSize: 15 }}>Véhicule</h4>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <div className="form-group">
                <label className="form-label">Marque *</label>
                <input
                  className="form-input"
                  value={form.vehicleMake}
                  onChange={(e) => set('vehicleMake', e.target.value)}
                  required
                />
              </div>
              <div className="form-group">
                <label className="form-label">Modèle *</label>
                <input
                  className="form-input"
                  value={form.vehicleModel}
                  onChange={(e) => set('vehicleModel', e.target.value)}
                  required
                />
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12 }}>
              <div className="form-group">
                <label className="form-label">Année</label>
                <input
                  className="form-input"
                  value={form.vehicleYear}
                  onChange={(e) => set('vehicleYear', e.target.value)}
                />
              </div>
              <div className="form-group">
                <label className="form-label">Couleur</label>
                <input
                  className="form-input"
                  value={form.vehicleColor}
                  onChange={(e) => set('vehicleColor', e.target.value)}
                />
              </div>
              <div className="form-group">
                <label className="form-label">Plaque *</label>
                <input
                  className="form-input"
                  value={form.plateNumber}
                  onChange={(e) => set('plateNumber', e.target.value)}
                  required
                />
              </div>
            </div>

            <h4 style={{ margin: '16px 0 8px', fontSize: 15 }}>Permis</h4>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <div className="form-group">
                <label className="form-label">N° permis</label>
                <input
                  className="form-input"
                  value={form.licenseNumber}
                  onChange={(e) => set('licenseNumber', e.target.value)}
                />
              </div>
              <div className="form-group">
                <label className="form-label">Expiration</label>
                <input
                  className="form-input"
                  type="date"
                  value={form.licenseExpiry}
                  onChange={(e) => set('licenseExpiry', e.target.value)}
                />
              </div>
            </div>
          </div>

          <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: 12, padding: 16 }}>
            <button type="button" className="btn btn-secondary" onClick={handleClose}>
              Annuler
            </button>
            <button type="submit" className="btn btn-primary" disabled={loading}>
              {loading ? 'Enregistrement…' : 'Enregistrer'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default EditDriverModal;
