import React, { useState } from 'react';
import { API_BASE_URL } from '../config';
import { X, UserPlus } from 'lucide-react';

const emptyForm = () => ({
  firstName: '',
  lastName: '',
  phone: '',
  email: '',
  password: '',
  nationalId: '',
  gender: 'male',
  dateOfBirth: '',
  licenseNumber: '',
  licenseExpiry: '',
  vehicleMake: '',
  vehicleModel: '',
  vehicleYear: String(new Date().getFullYear()),
  vehicleColor: '',
  plateNumber: '',
  category: 'car',
});

function AddDriverModal({ isOpen, onClose, onCreated }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [form, setForm] = useState(emptyForm);

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }));

  const handleClose = () => {
    setForm(emptyForm());
    setError('');
    onClose();
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
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
        password: form.password.trim() || undefined,
        nationalId: form.nationalId.trim(),
        gender: form.gender,
        dateOfBirth: form.dateOfBirth,
        address: { city: 'Dakar', region: 'Dakar', country: 'Sénégal' },
        driverLicense: {
          number: form.licenseNumber.trim(),
          expiryDate: form.licenseExpiry,
          category: form.category === 'moto' ? 'A' : 'B',
        },
        vehicle,
      };

      const res = await fetch(`${API_BASE_URL}/admin/drivers`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(body),
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || 'Erreur lors de la création');
      }
      if (onCreated) onCreated();
      handleClose();
    } catch (err) {
      setError(err.message || 'Erreur lors de la création');
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

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
              <UserPlus size={20} color="white" />
            </div>
            <div>
              <h2 className="modal-title">Ajouter un chauffeur</h2>
              <p style={{ fontSize: 14, color: 'var(--gray-500)', marginTop: 4 }}>
                Compte approuvé immédiatement (équipe interne)
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

            <p style={{ fontSize: 13, color: 'var(--gray-600)', marginBottom: 16 }}>
              Profil <strong>Voiture</strong> (VTC) ou <strong>Moto</strong> (livraison) — les types de course
              seront alignés automatiquement.
            </p>

            <div className="form-group">
              <label className="form-label">Type de profil</label>
              <select
                className="form-input"
                value={form.category}
                onChange={(e) => set('category', e.target.value)}
              >
                <option value="car">Chauffeur voiture (VTC)</option>
                <option value="moto">Livreur moto</option>
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
                placeholder="+221 77 … ou 77…"
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">Email *</label>
              <input
                className="form-input"
                type="email"
                value={form.email}
                onChange={(e) => set('email', e.target.value)}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">Mot de passe (optionnel)</label>
              <input
                className="form-input"
                type="password"
                value={form.password}
                onChange={(e) => set('password', e.target.value)}
                placeholder="Sinon généré automatiquement"
                minLength={6}
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <div className="form-group">
                <label className="form-label">CNI *</label>
                <input
                  className="form-input"
                  value={form.nationalId}
                  onChange={(e) => set('nationalId', e.target.value)}
                  required
                />
              </div>
              <div className="form-group">
                <label className="form-label">Genre *</label>
                <select
                  className="form-input"
                  value={form.gender}
                  onChange={(e) => set('gender', e.target.value)}
                >
                  <option value="male">Homme</option>
                  <option value="female">Femme</option>
                  <option value="other">Autre</option>
                </select>
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Date de naissance *</label>
              <input
                className="form-input"
                type="date"
                value={form.dateOfBirth}
                onChange={(e) => set('dateOfBirth', e.target.value)}
                required
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <div className="form-group">
                <label className="form-label">N° permis *</label>
                <input
                  className="form-input"
                  value={form.licenseNumber}
                  onChange={(e) => set('licenseNumber', e.target.value)}
                  required
                />
              </div>
              <div className="form-group">
                <label className="form-label">Expiration permis *</label>
                <input
                  className="form-input"
                  type="date"
                  value={form.licenseExpiry}
                  onChange={(e) => set('licenseExpiry', e.target.value)}
                  required
                />
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <div className="form-group">
                <label className="form-label">Marque véhicule *</label>
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
                <label className="form-label">Année *</label>
                <input
                  className="form-input"
                  type="number"
                  min={1990}
                  max={new Date().getFullYear() + 1}
                  value={form.vehicleYear}
                  onChange={(e) => set('vehicleYear', e.target.value)}
                  required
                />
              </div>
              <div className="form-group">
                <label className="form-label">Couleur *</label>
                <input
                  className="form-input"
                  value={form.vehicleColor}
                  onChange={(e) => set('vehicleColor', e.target.value)}
                  required
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
          </div>

          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" onClick={handleClose} disabled={loading}>
              Annuler
            </button>
            <button type="submit" className="btn btn-primary" disabled={loading}>
              {loading ? 'Création…' : 'Créer le compte'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default AddDriverModal;
