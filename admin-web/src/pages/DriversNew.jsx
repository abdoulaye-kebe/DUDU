import React, { useState, useEffect } from 'react';
import axios from 'axios';

const API_URL = 'http://localhost:3000/api/v1';

function DriversNew() {
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddForm, setShowAddForm] = useState(false);
  const [filter, setFilter] = useState('all');
  
  // Formulaire nouveau chauffeur
  const [formData, setFormData] = useState({
    // Informations personnelles
    firstName: '',
    lastName: '',
    phone: '',
    email: '',
    password: '', // Mot de passe simple
    dateOfBirth: '',
    gender: 'male',
    nationalId: '',
    
    // Adresse
    street: '',
    city: 'Dakar',
    region: 'Dakar',
    
    // Permis
    licenseNumber: '',
    licenseExpiry: '',
    licenseCategory: 'B',
    
    // Véhicule
    vehicleMake: '',
    vehicleModel: '',
    vehicleYear: new Date().getFullYear(),
    vehicleColor: '',
    vehiclePlate: '',
    vehicleType: 'sedan',
    vehicleCapacity: 4,
    hasAC: false,
    
    // Types de courses
    standard: true,
    express: false,
    shared: false,
    womenOnly: false,
    
    // Préférences
    maxDistance: 10,
    minPrice: 1000,
    
    // Abonnement (optionnel)
    subscriptionPlan: '', // '', 'daily', 'weekly', 'monthly'
  });

  useEffect(() => {
    loadDrivers();
  }, []);

  const loadDrivers = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_URL}/admin/drivers`);
      setDrivers(response.data.drivers || []);
    } catch (error) {
      console.error('Erreur chargement chauffeurs:', error);
      setDrivers([]);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Validation du mot de passe
    if (!formData.password || formData.password.length < 6) {
      alert('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }
    
    try {
      const driverData = {
        firstName: formData.firstName,
        lastName: formData.lastName,
        phone: formData.phone,
        email: formData.email,
        password: formData.password,
        dateOfBirth: formData.dateOfBirth,
        gender: formData.gender,
        nationalId: formData.nationalId,
        address: {
          street: formData.street,
          city: formData.city,
          region: formData.region,
          country: 'Sénégal'
        },
        driverLicense: {
          number: formData.licenseNumber,
          expiryDate: formData.licenseExpiry,
          category: formData.licenseCategory
        },
        vehicle: {
          make: formData.vehicleMake,
          model: formData.vehicleModel,
          year: parseInt(formData.vehicleYear),
          color: formData.vehicleColor,
          plateNumber: formData.vehiclePlate.toUpperCase(),
          category: 'car',
          type: formData.vehicleType,
          capacity: parseInt(formData.vehicleCapacity),
          hasAirConditioning: formData.hasAC
        },
        rideTypes: {
          standard: formData.standard,
          express: formData.express,
          shared: formData.shared,
          womenOnly: formData.womenOnly
        },
        preferences: {
          maxDistance: parseInt(formData.maxDistance),
          minPrice: parseInt(formData.minPrice),
          acceptsShared: formData.shared
        }
      };

      // Ajouter l'abonnement si sélectionné
      if (formData.subscriptionPlan) {
        driverData.subscription = {
          plan: formData.subscriptionPlan,
          isActive: true,
          startDate: new Date(),
          endDate: new Date(Date.now() + (
            formData.subscriptionPlan === 'daily' ? 1 * 24 * 60 * 60 * 1000 :
            formData.subscriptionPlan === 'weekly' ? 7 * 24 * 60 * 60 * 1000 :
            30 * 24 * 60 * 60 * 1000
          ))
        };
      }

      await axios.post(`${API_URL}/admin/drivers`, driverData);
      alert('Chauffeur ajouté avec succès !');
      setShowAddForm(false);
      loadDrivers();
      
      // Reset form
      setFormData({
        firstName: '', lastName: '', phone: '', email: '', password: '',
        dateOfBirth: '', gender: 'male', nationalId: '',
        street: '', city: 'Dakar', region: 'Dakar',
        licenseNumber: '', licenseExpiry: '', licenseCategory: 'B',
        vehicleMake: '', vehicleModel: '', vehicleYear: new Date().getFullYear(),
        vehicleColor: '', vehiclePlate: '', vehicleType: 'sedan',
        vehicleCapacity: 4, hasAC: false,
        standard: true, express: false, shared: false, womenOnly: false,
        maxDistance: 10, minPrice: 1000
      });
    } catch (error) {
      console.error('Erreur ajout chauffeur:', error);
      alert('Erreur lors de l\'ajout du chauffeur: ' + (error.response?.data?.message || error.message));
    }
  };

  const handleDelete = async (driverId) => {
    if (!window.confirm('Êtes-vous sûr de vouloir supprimer ce chauffeur ?')) {
      return;
    }
    
    try {
      await axios.delete(`${API_URL}/admin/drivers/${driverId}`);
      alert('Chauffeur supprimé avec succès !');
      loadDrivers();
    } catch (error) {
      console.error('Erreur suppression:', error);
      alert('Erreur lors de la suppression');
    }
  };

  const [selectedDriver, setSelectedDriver] = useState(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);

  const handleViewDetails = (driver) => {
    setSelectedDriver(driver);
    setShowDetailsModal(true);
  };

  const handleEdit = (driver) => {
    setSelectedDriver(driver);
    setFormData({
      firstName: driver.firstName || '',
      lastName: driver.lastName || '',
      phone: driver.phone || '',
      email: driver.email || '',
      password: '',
      dateOfBirth: driver.dateOfBirth ? driver.dateOfBirth.split('T')[0] : '',
      gender: driver.gender || 'male',
      nationalId: driver.nationalId || '',
      street: driver.address?.street || '',
      city: driver.address?.city || 'Dakar',
      region: driver.address?.region || 'Dakar',
      licenseNumber: driver.driverLicense?.number || '',
      licenseExpiry: driver.driverLicense?.expiryDate ? driver.driverLicense.expiryDate.split('T')[0] : '',
      licenseCategory: driver.driverLicense?.category || 'B',
      vehicleMake: driver.vehicle?.make || '',
      vehicleModel: driver.vehicle?.model || '',
      vehicleYear: driver.vehicle?.year || new Date().getFullYear(),
      vehicleColor: driver.vehicle?.color || '',
      vehiclePlate: driver.vehicle?.plateNumber || '',
      vehicleType: driver.vehicle?.type || 'sedan',
      vehicleCapacity: driver.vehicle?.capacity || 4,
      hasAC: driver.vehicle?.hasAirConditioning || false,
      standard: driver.rideTypes?.standard || true,
      express: driver.rideTypes?.express || false,
      shared: driver.rideTypes?.shared || false,
      womenOnly: driver.rideTypes?.womenOnly || false,
      maxDistance: driver.preferences?.maxDistance || 10,
      minPrice: driver.preferences?.minPrice || 1000,
      subscriptionPlan: driver.subscription?.plan || ''
    });
    setShowEditModal(true);
  };

  const handleUpdate = async (e) => {
    e.preventDefault();
    
    try {
      const updateData = {
        firstName: formData.firstName,
        lastName: formData.lastName,
        phone: formData.phone,
        email: formData.email,
        dateOfBirth: formData.dateOfBirth,
        gender: formData.gender,
        nationalId: formData.nationalId,
        address: {
          street: formData.street,
          city: formData.city,
          region: formData.region,
          country: 'Sénégal'
        },
        driverLicense: {
          number: formData.licenseNumber,
          expiryDate: formData.licenseExpiry,
          category: formData.licenseCategory
        },
        vehicle: {
          make: formData.vehicleMake,
          model: formData.vehicleModel,
          year: parseInt(formData.vehicleYear),
          color: formData.vehicleColor,
          plateNumber: formData.vehiclePlate.toUpperCase(),
          category: 'car',
          type: formData.vehicleType,
          capacity: parseInt(formData.vehicleCapacity),
          hasAirConditioning: formData.hasAC
        },
        rideTypes: {
          standard: formData.standard,
          express: formData.express,
          shared: formData.shared,
          womenOnly: formData.womenOnly
        },
        preferences: {
          maxDistance: parseInt(formData.maxDistance),
          minPrice: parseInt(formData.minPrice),
          acceptsShared: formData.shared
        }
      };

      // Ajouter le mot de passe seulement s'il est fourni
      if (formData.password && formData.password.length >= 6) {
        updateData.password = formData.password;
      }

      await axios.put(`${API_URL}/admin/drivers/${selectedDriver._id}`, updateData);
      alert('Chauffeur modifié avec succès !');
      setShowEditModal(false);
      setSelectedDriver(null);
      loadDrivers();
    } catch (error) {
      console.error('Erreur modification chauffeur:', error);
      alert('Erreur lors de la modification: ' + (error.response?.data?.message || error.message));
    }
  };

  const filteredDrivers = drivers.filter(driver => {
    if (filter === 'all') return true;
    return driver.status === filter;
  });

  if (loading) {
    return <div style={{ padding: '40px', textAlign: 'center' }}>Chargement...</div>;
  }

  return (
    <div style={{ padding: '20px' }}>
      <div style={{ marginBottom: '30px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ margin: 0, marginBottom: '5px' }}>Gestion des Chauffeurs</h1>
          <p style={{ margin: 0, color: '#666' }}>Gérez les chauffeurs DUDU Pro</p>
        </div>
        <button 
          onClick={() => setShowAddForm(!showAddForm)}
          style={{
            padding: '12px 24px',
            backgroundColor: '#0d5d36',
            color: 'white',
            border: 'none',
            borderRadius: '8px',
            cursor: 'pointer',
            fontSize: '16px',
            fontWeight: '600'
          }}
        >
          {showAddForm ? '✕ Annuler' : '+ Ajouter un chauffeur'}
        </button>
      </div>

      {/* Formulaire d'ajout */}
      {showAddForm && (
        <div style={{
          backgroundColor: 'white',
          padding: '30px',
          borderRadius: '12px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
          marginBottom: '30px'
        }}>
          <h2 style={{ marginTop: 0 }}>Nouveau Chauffeur</h2>
          <form onSubmit={handleSubmit}>
            {/* Informations personnelles */}
            <div style={{ marginBottom: '30px' }}>
              <h3 style={{ color: '#0d5d36', borderBottom: '2px solid #0d5d36', paddingBottom: '10px' }}>
                Informations Personnelles
              </h3>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px', marginTop: '15px' }}>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Prénom *</label>
                  <input
                    type="text"
                    name="firstName"
                    value={formData.firstName}
                    onChange={handleInputChange}
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Nom *</label>
                  <input
                    type="text"
                    name="lastName"
                    value={formData.lastName}
                    onChange={handleInputChange}
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Téléphone *</label>
                  <input
                    type="tel"
                    name="phone"
                    value={formData.phone}
                    onChange={handleInputChange}
                    placeholder="+221 77 123 45 67"
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Email *</label>
                  <input
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleInputChange}
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Mot de passe *</label>
                  <input
                    type="password"
                    name="password"
                    value={formData.password}
                    onChange={handleInputChange}
                    placeholder="Entrez un mot de passe (min. 6 caractères)"
                    required
                    minLength="6"
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                  <small style={{ color: '#666', fontSize: '12px' }}>
                    Le chauffeur pourra modifier son mot de passe depuis l'application mobile
                  </small>
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Date de naissance *</label>
                  <input
                    type="date"
                    name="dateOfBirth"
                    value={formData.dateOfBirth}
                    onChange={handleInputChange}
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Genre *</label>
                  <select
                    name="gender"
                    value={formData.gender}
                    onChange={handleInputChange}
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  >
                    <option value="male">Homme</option>
                    <option value="female">Femme</option>
                    <option value="other">Autre</option>
                  </select>
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>CNI *</label>
                  <input
                    type="text"
                    name="nationalId"
                    value={formData.nationalId}
                    onChange={handleInputChange}
                    placeholder="1234567890123"
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
              </div>
            </div>

            {/* Adresse */}
            <div style={{ marginBottom: '30px' }}>
              <h3 style={{ color: '#0d5d36', borderBottom: '2px solid #0d5d36', paddingBottom: '10px' }}>
                📍 Adresse du Chauffeur
              </h3>
              <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr', gap: '15px', marginTop: '15px' }}>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Rue / Quartier</label>
                  <input
                    type="text"
                    name="street"
                    value={formData.street}
                    onChange={handleInputChange}
                    placeholder="Ex: Cité Keur Gorgui, Rue 123"
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Ville *</label>
                  <select
                    name="city"
                    value={formData.city}
                    onChange={handleInputChange}
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  >
                    <option value="Dakar">Dakar</option>
                    <option value="Pikine">Pikine</option>
                    <option value="Guédiawaye">Guédiawaye</option>
                    <option value="Rufisque">Rufisque</option>
                    <option value="Thiès">Thiès</option>
                    <option value="Saint-Louis">Saint-Louis</option>
                    <option value="Kaolack">Kaolack</option>
                    <option value="Ziguinchor">Ziguinchor</option>
                    <option value="Mbour">Mbour</option>
                    <option value="Louga">Louga</option>
                  </select>
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Région *</label>
                  <select
                    name="region"
                    value={formData.region}
                    onChange={handleInputChange}
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  >
                    <option value="Dakar">Dakar</option>
                    <option value="Thiès">Thiès</option>
                    <option value="Saint-Louis">Saint-Louis</option>
                    <option value="Diourbel">Diourbel</option>
                    <option value="Kaolack">Kaolack</option>
                    <option value="Fatick">Fatick</option>
                    <option value="Louga">Louga</option>
                    <option value="Matam">Matam</option>
                    <option value="Tambacounda">Tambacounda</option>
                    <option value="Kolda">Kolda</option>
                    <option value="Ziguinchor">Ziguinchor</option>
                    <option value="Kédougou">Kédougou</option>
                    <option value="Sédhiou">Sédhiou</option>
                    <option value="Kaffrine">Kaffrine</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Permis de conduire */}
            <div style={{ marginBottom: '30px' }}>
              <h3 style={{ color: '#0d5d36', borderBottom: '2px solid #0d5d36', paddingBottom: '10px' }}>
                Permis de Conduire
              </h3>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '15px', marginTop: '15px' }}>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Numéro *</label>
                  <input
                    type="text"
                    name="licenseNumber"
                    value={formData.licenseNumber}
                    onChange={handleInputChange}
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Date d'expiration *</label>
                  <input
                    type="date"
                    name="licenseExpiry"
                    value={formData.licenseExpiry}
                    onChange={handleInputChange}
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Catégorie *</label>
                  <select
                    name="licenseCategory"
                    value={formData.licenseCategory}
                    onChange={handleInputChange}
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  >
                    <option value="A">A (Moto)</option>
                    <option value="B">B (Voiture)</option>
                    <option value="C">C (Poids lourd)</option>
                    <option value="D">D (Transport en commun)</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Véhicule */}
            <div style={{ marginBottom: '30px' }}>
              <h3 style={{ color: '#0d5d36', borderBottom: '2px solid #0d5d36', paddingBottom: '10px' }}>
                Véhicule
              </h3>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '15px', marginTop: '15px' }}>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Marque *</label>
                  <input
                    type="text"
                    name="vehicleMake"
                    value={formData.vehicleMake}
                    onChange={handleInputChange}
                    placeholder="Toyota, Peugeot..."
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Modèle *</label>
                  <input
                    type="text"
                    name="vehicleModel"
                    value={formData.vehicleModel}
                    onChange={handleInputChange}
                    placeholder="Corolla, 208..."
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Année *</label>
                  <input
                    type="number"
                    name="vehicleYear"
                    value={formData.vehicleYear}
                    onChange={handleInputChange}
                    min="1990"
                    max={new Date().getFullYear() + 1}
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Couleur *</label>
                  <input
                    type="text"
                    name="vehicleColor"
                    value={formData.vehicleColor}
                    onChange={handleInputChange}
                    placeholder="Blanc, Noir..."
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Plaque *</label>
                  <input
                    type="text"
                    name="vehiclePlate"
                    value={formData.vehiclePlate}
                    onChange={handleInputChange}
                    placeholder="DK-1234-AB"
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd', textTransform: 'uppercase' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Type *</label>
                  <select
                    name="vehicleType"
                    value={formData.vehicleType}
                    onChange={handleInputChange}
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  >
                    <option value="sedan">Berline</option>
                    <option value="suv">SUV</option>
                    <option value="minivan">Minivan</option>
                  </select>
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Capacité *</label>
                  <input
                    type="number"
                    name="vehicleCapacity"
                    value={formData.vehicleCapacity}
                    onChange={handleInputChange}
                    min="1"
                    max="8"
                    required
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div style={{ display: 'flex', alignItems: 'center', paddingTop: '30px' }}>
                  <input
                    type="checkbox"
                    name="hasAC"
                    checked={formData.hasAC}
                    onChange={handleInputChange}
                    id="hasAC"
                    style={{ marginRight: '10px', width: '20px', height: '20px' }}
                  />
                  <label htmlFor="hasAC" style={{ fontWeight: '600', cursor: 'pointer' }}>Climatisation</label>
                </div>
              </div>
            </div>

            {/* Types de courses */}
            <div style={{ marginBottom: '30px' }}>
              <h3 style={{ color: '#0d5d36', borderBottom: '2px solid #0d5d36', paddingBottom: '10px' }}>
                Types de Courses Acceptées
              </h3>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: '15px', marginTop: '15px' }}>
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <input
                    type="checkbox"
                    name="standard"
                    checked={formData.standard}
                    onChange={handleInputChange}
                    id="standard"
                    style={{ marginRight: '10px', width: '20px', height: '20px' }}
                  />
                  <label htmlFor="standard" style={{ fontWeight: '600', cursor: 'pointer' }}>Standard</label>
                </div>
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <input
                    type="checkbox"
                    name="express"
                    checked={formData.express}
                    onChange={handleInputChange}
                    id="express"
                    style={{ marginRight: '10px', width: '20px', height: '20px' }}
                  />
                  <label htmlFor="express" style={{ fontWeight: '600', cursor: 'pointer' }}>Express</label>
                </div>
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <input
                    type="checkbox"
                    name="shared"
                    checked={formData.shared}
                    onChange={handleInputChange}
                    id="shared"
                    style={{ marginRight: '10px', width: '20px', height: '20px' }}
                  />
                  <label htmlFor="shared" style={{ fontWeight: '600', cursor: 'pointer' }}>Covoiturage</label>
                </div>
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <input
                    type="checkbox"
                    name="womenOnly"
                    checked={formData.womenOnly}
                    onChange={handleInputChange}
                    id="womenOnly"
                    style={{ marginRight: '10px', width: '20px', height: '20px' }}
                  />
                  <label htmlFor="womenOnly" style={{ fontWeight: '600', cursor: 'pointer' }}>Femmes uniquement</label>
                </div>
              </div>
            </div>

            {/* Préférences */}
            <div style={{ marginBottom: '30px' }}>
              <h3 style={{ color: '#0d5d36', borderBottom: '2px solid #0d5d36', paddingBottom: '10px' }}>
                Préférences
              </h3>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px', marginTop: '15px' }}>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Distance max (km)</label>
                  <input
                    type="number"
                    name="maxDistance"
                    value={formData.maxDistance}
                    onChange={handleInputChange}
                    min="1"
                    max="50"
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Prix minimum (FCFA)</label>
                  <input
                    type="number"
                    name="minPrice"
                    value={formData.minPrice}
                    onChange={handleInputChange}
                    min="500"
                    step="100"
                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                  />
                </div>
              </div>
            </div>

            {/* Abonnement */}
            <div style={{ marginBottom: '30px' }}>
              <h3 style={{ color: '#0d5d36', borderBottom: '2px solid #0d5d36', paddingBottom: '10px' }}>
                💳 Abonnement
              </h3>
              <div style={{ marginTop: '15px' }}>
                <label style={{ display: 'block', marginBottom: '10px', fontWeight: '600' }}>
                  Choisir un plan d'abonnement (optionnel)
                </label>
                <div style={{ marginBottom: '15px' }}>
                  <button
                    type="button"
                    onClick={() => setFormData(prev => ({ ...prev, subscriptionPlan: '' }))}
                    style={{
                      padding: '12px 20px',
                      border: `2px solid ${formData.subscriptionPlan === '' ? '#0d5d36' : '#ddd'}`,
                      borderRadius: '8px',
                      background: formData.subscriptionPlan === '' ? '#f0fdf4' : 'white',
                      cursor: 'pointer',
                      fontWeight: '600',
                      color: formData.subscriptionPlan === '' ? '#0d5d36' : '#666'
                    }}
                  >
                    ⚪ Aucun abonnement (le chauffeur choisira plus tard)
                  </button>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '15px' }}>
                  {/* Plan Journalier */}
                  <div
                    onClick={() => setFormData(prev => ({ ...prev, subscriptionPlan: 'daily' }))}
                    style={{
                      padding: '20px',
                      border: `3px solid ${formData.subscriptionPlan === 'daily' ? '#0d5d36' : '#ddd'}`,
                      borderRadius: '12px',
                      cursor: 'pointer',
                      transition: 'all 0.3s',
                      background: formData.subscriptionPlan === 'daily' ? '#f0fdf4' : 'white'
                    }}
                  >
                    <div style={{ fontSize: '32px', marginBottom: '10px', textAlign: 'center' }}>📅</div>
                    <div style={{ textAlign: 'center', fontWeight: 'bold', fontSize: '18px', marginBottom: '5px' }}>
                      Journalier
                    </div>
                    <div style={{ textAlign: 'center', fontSize: '24px', fontWeight: 'bold', color: '#0d5d36', marginBottom: '5px' }}>
                      1 000 FCFA
                    </div>
                    <div style={{ textAlign: 'center', fontSize: '12px', color: '#666' }}>
                      Courses illimitées / jour
                    </div>
                  </div>

                  {/* Plan Hebdomadaire */}
                  <div
                    onClick={() => setFormData(prev => ({ ...prev, subscriptionPlan: 'weekly' }))}
                    style={{
                      padding: '20px',
                      border: `3px solid ${formData.subscriptionPlan === 'weekly' ? '#0d5d36' : '#ddd'}`,
                      borderRadius: '12px',
                      cursor: 'pointer',
                      transition: 'all 0.3s',
                      background: formData.subscriptionPlan === 'weekly' ? '#f0fdf4' : 'white',
                      position: 'relative'
                    }}
                  >
                    <div style={{
                      position: 'absolute',
                      top: '-10px',
                      right: '10px',
                      background: '#10b981',
                      color: 'white',
                      padding: '4px 12px',
                      borderRadius: '20px',
                      fontSize: '10px',
                      fontWeight: 'bold'
                    }}>
                      POPULAIRE
                    </div>
                    <div style={{ fontSize: '32px', marginBottom: '10px', textAlign: 'center' }}>📆</div>
                    <div style={{ textAlign: 'center', fontWeight: 'bold', fontSize: '18px', marginBottom: '5px' }}>
                      Hebdomadaire
                    </div>
                    <div style={{ textAlign: 'center', fontSize: '24px', fontWeight: 'bold', color: '#0d5d36', marginBottom: '5px' }}>
                      5 000 FCFA
                    </div>
                    <div style={{ textAlign: 'center', fontSize: '12px', color: '#666' }}>
                      Courses illimitées / semaine
                    </div>
                    <div style={{ textAlign: 'center', fontSize: '11px', color: '#10b981', marginTop: '5px', fontWeight: '600' }}>
                      Économisez 2 000 FCFA
                    </div>
                  </div>

                  {/* Plan Mensuel */}
                  <div
                    onClick={() => setFormData(prev => ({ ...prev, subscriptionPlan: 'monthly' }))}
                    style={{
                      padding: '20px',
                      border: `3px solid ${formData.subscriptionPlan === 'monthly' ? '#0d5d36' : '#ddd'}`,
                      borderRadius: '12px',
                      cursor: 'pointer',
                      transition: 'all 0.3s',
                      background: formData.subscriptionPlan === 'monthly' ? '#f0fdf4' : 'white',
                      position: 'relative'
                    }}
                  >
                    <div style={{
                      position: 'absolute',
                      top: '-10px',
                      right: '10px',
                      background: '#fbbf24',
                      color: 'white',
                      padding: '4px 12px',
                      borderRadius: '20px',
                      fontSize: '10px',
                      fontWeight: 'bold'
                    }}>
                      MEILLEUR PRIX
                    </div>
                    <div style={{ fontSize: '32px', marginBottom: '10px', textAlign: 'center' }}>🗓️</div>
                    <div style={{ textAlign: 'center', fontWeight: 'bold', fontSize: '18px', marginBottom: '5px' }}>
                      Mensuel
                    </div>
                    <div style={{ textAlign: 'center', fontSize: '24px', fontWeight: 'bold', color: '#0d5d36', marginBottom: '5px' }}>
                      21 000 FCFA
                    </div>
                    <div style={{ textAlign: 'center', fontSize: '12px', color: '#666' }}>
                      Courses illimitées / mois
                    </div>
                    <div style={{ textAlign: 'center', fontSize: '11px', color: '#fbbf24', marginTop: '5px', fontWeight: '600' }}>
                      Économisez 9 000 FCFA
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Boutons */}
            <div style={{ display: 'flex', gap: '15px', justifyContent: 'flex-end' }}>
              <button
                type="button"
                onClick={() => setShowAddForm(false)}
                style={{
                  padding: '12px 30px',
                  backgroundColor: '#ddd',
                  color: '#333',
                  border: 'none',
                  borderRadius: '8px',
                  cursor: 'pointer',
                  fontSize: '16px',
                  fontWeight: '600'
                }}
              >
                Annuler
              </button>
              <button
                type="submit"
                style={{
                  padding: '12px 30px',
                  backgroundColor: '#0d5d36',
                  color: 'white',
                  border: 'none',
                  borderRadius: '8px',
                  cursor: 'pointer',
                  fontSize: '16px',
                  fontWeight: '600'
                }}
              >
                Ajouter le chauffeur
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Filtres */}
      <div style={{ marginBottom: '20px', display: 'flex', gap: '10px' }}>
        <button 
          onClick={() => setFilter('all')}
          style={{
            padding: '10px 20px',
            backgroundColor: filter === 'all' ? '#0d5d36' : 'white',
            color: filter === 'all' ? 'white' : '#333',
            border: '1px solid #ddd',
            borderRadius: '6px',
            cursor: 'pointer'
          }}
        >
          Tous ({drivers.length})
        </button>
        <button 
          onClick={() => setFilter('online')}
          style={{
            padding: '10px 20px',
            backgroundColor: filter === 'online' ? '#0d5d36' : 'white',
            color: filter === 'online' ? 'white' : '#333',
            border: '1px solid #ddd',
            borderRadius: '6px',
            cursor: 'pointer'
          }}
        >
          En ligne ({drivers.filter(d => d.status === 'online').length})
        </button>
        <button 
          onClick={() => setFilter('offline')}
          style={{
            padding: '10px 20px',
            backgroundColor: filter === 'offline' ? '#0d5d36' : 'white',
            color: filter === 'offline' ? 'white' : '#333',
            border: '1px solid #ddd',
            borderRadius: '6px',
            cursor: 'pointer'
          }}
        >
          Hors ligne ({drivers.filter(d => d.status === 'offline').length})
        </button>
      </div>

      {/* Liste des chauffeurs */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '12px',
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        overflow: 'hidden'
      }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead style={{ backgroundColor: '#f5f5f5' }}>
            <tr>
              <th style={{ padding: '15px', textAlign: 'left', fontWeight: '600' }}>Nom</th>
              <th style={{ padding: '15px', textAlign: 'left', fontWeight: '600' }}>Téléphone</th>
              <th style={{ padding: '15px', textAlign: 'left', fontWeight: '600' }}>Véhicule</th>
              <th style={{ padding: '15px', textAlign: 'left', fontWeight: '600' }}>Note</th>
              <th style={{ padding: '15px', textAlign: 'left', fontWeight: '600' }}>Courses</th>
              <th style={{ padding: '15px', textAlign: 'left', fontWeight: '600' }}>Statut</th>
              <th style={{ padding: '15px', textAlign: 'left', fontWeight: '600' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredDrivers.length === 0 ? (
              <tr>
                <td colSpan="7" style={{ padding: '40px', textAlign: 'center', color: '#999' }}>
                  Aucun chauffeur trouvé
                </td>
              </tr>
            ) : (
              filteredDrivers.map(driver => (
                <tr key={driver._id || driver.id} style={{ borderBottom: '1px solid #eee' }}>
                  <td style={{ padding: '15px' }}>
                    {driver.firstName} {driver.lastName}
                  </td>
                  <td style={{ padding: '15px' }}>{driver.phone}</td>
                  <td style={{ padding: '15px' }}>
                    {driver.vehicle?.make} {driver.vehicle?.model}
                  </td>
                  <td style={{ padding: '15px' }}>
                    ⭐ {driver.stats?.averageRating?.toFixed(1) || 'N/A'}
                  </td>
                  <td style={{ padding: '15px' }}>
                    {driver.stats?.totalRides || 0}
                  </td>
                  <td style={{ padding: '15px' }}>
                    <span style={{
                      padding: '5px 12px',
                      borderRadius: '20px',
                      fontSize: '12px',
                      fontWeight: '600',
                      backgroundColor: driver.status === 'online' ? '#d4edda' : '#f8d7da',
                      color: driver.status === 'online' ? '#155724' : '#721c24'
                    }}>
                      {driver.status === 'online' ? 'En ligne' : 'Hors ligne'}
                    </span>
                  </td>
                  <td style={{ padding: '15px' }}>
                    <button
                      onClick={() => handleViewDetails(driver)}
                      style={{
                        padding: '6px 12px',
                        backgroundColor: '#0d5d36',
                        color: 'white',
                        border: 'none',
                        borderRadius: '6px',
                        cursor: 'pointer',
                        fontSize: '14px',
                        marginRight: '5px'
                      }}
                    >
                      👁️
                    </button>
                    <button
                      onClick={() => handleEdit(driver)}
                      style={{
                        padding: '6px 12px',
                        backgroundColor: '#f59e0b',
                        color: 'white',
                        border: 'none',
                        borderRadius: '6px',
                        cursor: 'pointer',
                        fontSize: '14px',
                        marginRight: '5px'
                      }}
                    >
                      ✏️
                    </button>
                    <button
                      onClick={() => handleDelete(driver._id)}
                      style={{
                        padding: '6px 12px',
                        backgroundColor: '#dc2626',
                        color: 'white',
                        border: 'none',
                        borderRadius: '6px',
                        cursor: 'pointer',
                        fontSize: '14px'
                      }}
                    >
                      🗑️
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Modale Détails */}
      {showDetailsModal && selectedDriver && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0,0,0,0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000
        }}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '30px',
            maxWidth: '600px',
            maxHeight: '80vh',
            overflow: 'auto',
            width: '90%'
          }}>
            <h2 style={{ marginTop: 0 }}>Détails du Chauffeur</h2>
            
            <div style={{ marginBottom: '20px' }}>
              <h3 style={{ color: '#0d5d36', marginBottom: '10px' }}>Informations Personnelles</h3>
              <p><strong>Nom:</strong> {selectedDriver.firstName} {selectedDriver.lastName}</p>
              <p><strong>Téléphone:</strong> {selectedDriver.phone}</p>
              <p><strong>Email:</strong> {selectedDriver.email}</p>
              <p><strong>Genre:</strong> {selectedDriver.gender === 'male' ? 'Homme' : 'Femme'}</p>
              <p><strong>CNI:</strong> {selectedDriver.nationalId}</p>
              <p><strong>📍 Adresse:</strong> {selectedDriver.address?.street ? `${selectedDriver.address.street}, ` : ''}{selectedDriver.address?.city}, {selectedDriver.address?.region}</p>
            </div>

            <div style={{ marginBottom: '20px' }}>
              <h3 style={{ color: '#0d5d36', marginBottom: '10px' }}>Véhicule</h3>
              <p><strong>Marque:</strong> {selectedDriver.vehicle?.make}</p>
              <p><strong>Modèle:</strong> {selectedDriver.vehicle?.model}</p>
              <p><strong>Année:</strong> {selectedDriver.vehicle?.year}</p>
              <p><strong>Couleur:</strong> {selectedDriver.vehicle?.color}</p>
              <p><strong>Plaque:</strong> {selectedDriver.vehicle?.plateNumber}</p>
              <p><strong>Capacité:</strong> {selectedDriver.vehicle?.capacity} places</p>
              <p><strong>Climatisation:</strong> {selectedDriver.vehicle?.hasAirConditioning ? 'Oui' : 'Non'}</p>
            </div>

            <div style={{ marginBottom: '20px' }}>
              <h3 style={{ color: '#0d5d36', marginBottom: '10px' }}>Statistiques</h3>
              <p><strong>Total Courses:</strong> {selectedDriver.stats?.totalRides || 0}</p>
              <p><strong>Note Moyenne:</strong> ⭐ {selectedDriver.stats?.averageRating?.toFixed(1) || 'N/A'}</p>
              <p><strong>Statut:</strong> {selectedDriver.status}</p>
            </div>

            <button
              onClick={() => setShowDetailsModal(false)}
              style={{
                padding: '12px 24px',
                backgroundColor: '#0d5d36',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                cursor: 'pointer',
                fontSize: '16px',
                width: '100%'
              }}
            >
              Fermer
            </button>
          </div>
        </div>
      )}

      {/* Modale Édition */}
      {showEditModal && selectedDriver && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0,0,0,0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000,
          overflow: 'auto'
        }}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '12px',
            padding: '30px',
            maxWidth: '800px',
            maxHeight: '90vh',
            overflow: 'auto',
            width: '90%',
            margin: '20px'
          }}>
            <h2 style={{ marginTop: 0 }}>Modifier le Chauffeur</h2>
            <form onSubmit={handleUpdate}>
              {/* Réutiliser le même formulaire que pour l'ajout */}
              <div style={{ marginBottom: '20px' }}>
                <h3 style={{ color: '#0d5d36' }}>Informations Personnelles</h3>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' }}>
                  <div>
                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Prénom *</label>
                    <input
                      type="text"
                      name="firstName"
                      value={formData.firstName}
                      onChange={handleInputChange}
                      required
                      style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Nom *</label>
                    <input
                      type="text"
                      name="lastName"
                      value={formData.lastName}
                      onChange={handleInputChange}
                      required
                      style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Téléphone *</label>
                    <input
                      type="tel"
                      name="phone"
                      value={formData.phone}
                      onChange={handleInputChange}
                      required
                      style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Email *</label>
                    <input
                      type="email"
                      name="email"
                      value={formData.email}
                      onChange={handleInputChange}
                      required
                      style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', marginBottom: '5px', fontWeight: '600' }}>Nouveau mot de passe</label>
                    <input
                      type="password"
                      name="password"
                      value={formData.password}
                      onChange={handleInputChange}
                      placeholder="Laisser vide pour ne pas changer"
                      minLength="6"
                      style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #ddd' }}
                    />
                    <small style={{ color: '#666', fontSize: '12px' }}>
                      Laisser vide pour conserver le mot de passe actuel
                    </small>
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '15px', justifyContent: 'flex-end', marginTop: '20px' }}>
                <button
                  type="button"
                  onClick={() => {
                    setShowEditModal(false);
                    setSelectedDriver(null);
                  }}
                  style={{
                    padding: '12px 30px',
                    backgroundColor: '#ddd',
                    color: '#333',
                    border: 'none',
                    borderRadius: '8px',
                    cursor: 'pointer',
                    fontSize: '16px',
                    fontWeight: '600'
                  }}
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  style={{
                    padding: '12px 30px',
                    backgroundColor: '#0d5d36',
                    color: 'white',
                    border: 'none',
                    borderRadius: '8px',
                    cursor: 'pointer',
                    fontSize: '16px',
                    fontWeight: '600'
                  }}
                >
                  Enregistrer
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default DriversNew;
