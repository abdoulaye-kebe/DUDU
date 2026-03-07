/**
 * Gestion du tracking en temps réel des courses
 * Permet de suivre la position des chauffeurs (voiture/moto) en direct
 */

class TrackingHandler {
  constructor(io) {
    this.io = io;
    this.activeRides = new Map(); // rideId -> {driverId, passengerId, vehicleType}
    this.driverLocations = new Map(); // driverId -> {lat, lng, heading, speed}
  }

  /**
   * Initialiser les événements de tracking
   */
  setupTracking(socket) {
    console.log(`📍 Tracking socket connecté: ${socket.id}`);

    // Chauffeur démarre une course
    socket.on('driver:start_ride', (data) => {
      this.handleRideStart(socket, data);
    });

    // Chauffeur met à jour sa position GPS
    socket.on('driver:update_location', (data) => {
      this.handleLocationUpdate(socket, data);
    });

    // Chauffeur arrive au point de pickup
    socket.on('driver:arrived_pickup', (data) => {
      this.handleArrivedPickup(socket, data);
    });

    // Chauffeur démarre le trajet
    socket.on('driver:start_trip', (data) => {
      this.handleStartTrip(socket, data);
    });

    // Chauffeur termine la course
    socket.on('driver:complete_ride', (data) => {
      this.handleRideComplete(socket, data);
    });

    // Passager demande position actuelle
    socket.on('passenger:request_location', (data) => {
      this.handleLocationRequest(socket, data);
    });

    // Déconnexion
    socket.on('disconnect', () => {
      this.handleDisconnect(socket);
    });
  }

  /**
   * Démarrage d'une course
   */
  handleRideStart(socket, data) {
    const { rideId, driverId, passengerId, vehicleType, driverName, vehicleInfo } = data;

    this.activeRides.set(rideId, {
      driverId,
      passengerId,
      vehicleType, // 'car' ou 'moto'
      driverName,
      vehicleInfo,
      status: 'going_to_pickup',
      startedAt: new Date(),
    });

    // Rejoindre la room de la course
    socket.join(`ride_${rideId}`);

    console.log(`🚗 Course démarrée: ${rideId} (${vehicleType})`);

    // Notifier le passager que le chauffeur arrive
    this.io.to(`user_${passengerId}`).emit('ride:driver_coming', {
      rideId,
      driverId,
      driverName,
      vehicleType,
      vehicleInfo,
      message: vehicleType === 'moto' 
        ? `🏍️ ${driverName} arrive pour récupérer votre colis`
        : `🚗 ${driverName} arrive pour vous prendre`,
    });
  }

  /**
   * Mise à jour position GPS du chauffeur
   */
  handleLocationUpdate(socket, data) {
    const { rideId, driverId, latitude, longitude, heading, speed } = data;

    // Mettre à jour la position du chauffeur
    this.driverLocations.set(driverId, {
      latitude,
      longitude,
      heading: heading || 0,
      speed: speed || 0,
      timestamp: Date.now(),
    });

    const ride = this.activeRides.get(rideId);
    if (!ride) {
      console.log(`⚠️ Course ${rideId} non trouvée`);
      return;
    }

    console.log(`📍 Position ${ride.vehicleType}: ${latitude.toFixed(6)}, ${longitude.toFixed(6)}`);

    // Émettre la position au passager en temps réel
    this.io.to(`user_${ride.passengerId}`).emit('ride:driver_location', {
      rideId,
      driverId,
      location: {
        latitude,
        longitude,
        heading,
        speed,
      },
      vehicleType: ride.vehicleType,
      timestamp: Date.now(),
    });

    // Émettre aussi à la room de la course (pour admin)
    this.io.to(`ride_${rideId}`).emit('ride:location_update', {
      rideId,
      driverId,
      location: { latitude, longitude, heading, speed },
      vehicleType: ride.vehicleType,
    });
  }

  /**
   * Chauffeur arrivé au pickup
   */
  handleArrivedPickup(socket, data) {
    const { rideId, driverId } = data;
    const ride = this.activeRides.get(rideId);
    
    if (ride) {
      ride.status = 'arrived_pickup';
      
      const message = ride.vehicleType === 'moto'
        ? '🏍️ Le livreur est arrivé pour récupérer votre colis'
        : '🚗 Votre chauffeur est arrivé';

      this.io.to(`user_${ride.passengerId}`).emit('ride:driver_arrived', {
        rideId,
        message,
        vehicleType: ride.vehicleType,
      });

      console.log(`✅ ${ride.vehicleType} arrivé au pickup: ${rideId}`);
    }
  }

  /**
   * Démarrage du trajet
   */
  handleStartTrip(socket, data) {
    const { rideId, driverId } = data;
    const ride = this.activeRides.get(rideId);
    
    if (ride) {
      ride.status = 'in_progress';
      
      const message = ride.vehicleType === 'moto'
        ? '🏍️ Livraison en cours vers le destinataire'
        : '🚗 Course en cours vers votre destination';

      this.io.to(`user_${ride.passengerId}`).emit('ride:trip_started', {
        rideId,
        message,
        vehicleType: ride.vehicleType,
      });

      console.log(`🏁 Trajet démarré (${ride.vehicleType}): ${rideId}`);
    }
  }

  /**
   * Course terminée
   */
  handleRideComplete(socket, data) {
    const { rideId, driverId } = data;
    const ride = this.activeRides.get(rideId);
    
    if (ride) {
      const message = ride.vehicleType === 'moto'
        ? '✅ Livraison terminée ! Votre colis a été remis'
        : '✅ Course terminée ! Merci d\'avoir utilisé DUDU';

      this.io.to(`user_${ride.passengerId}`).emit('ride:completed', {
        rideId,
        message,
        vehicleType: ride.vehicleType,
      });

      // Nettoyer
      this.activeRides.delete(rideId);
      this.driverLocations.delete(driverId);

      console.log(`🏁 Course terminée (${ride.vehicleType}): ${rideId}`);
    }
  }

  /**
   * Passager demande la position actuelle
   */
  handleLocationRequest(socket, data) {
    const { rideId } = data;
    const ride = this.activeRides.get(rideId);
    
    if (ride) {
      const location = this.driverLocations.get(ride.driverId);
      
      if (location) {
        socket.emit('ride:current_location', {
          rideId,
          location,
          vehicleType: ride.vehicleType,
        });
      }
    }
  }

  /**
   * Déconnexion
   */
  handleDisconnect(socket) {
    console.log(`📴 Socket déconnecté: ${socket.id}`);
  }

  /**
   * Obtenir toutes les courses actives (pour admin)
   */
  getActiveRides() {
    const rides = [];
    this.activeRides.forEach((ride, rideId) => {
      const location = this.driverLocations.get(ride.driverId);
      rides.push({
        rideId,
        ...ride,
        currentLocation: location || null,
      });
    });
    return rides;
  }

  /**
   * Simuler le déplacement d'un véhicule (pour tests)
   */
  simulateMovement(rideId, from, to, durationSeconds = 30) {
    const ride = this.activeRides.get(rideId);
    if (!ride) return;

    const steps = durationSeconds * 2; // 2 updates par seconde
    const latStep = (to.latitude - from.latitude) / steps;
    const lonStep = (to.longitude - from.longitude) / steps;
    
    let currentStep = 0;

    const interval = setInterval(() => {
      if (currentStep >= steps) {
        clearInterval(interval);
        return;
      }

      const currentLat = from.latitude + (latStep * currentStep);
      const currentLon = from.longitude + (lonStep * currentStep);
      
      // Calculer le heading (direction)
      const heading = this.calculateHeading(
        currentLat - latStep,
        currentLon - lonStep,
        currentLat,
        currentLon
      );

      this.handleLocationUpdate(null, {
        rideId,
        driverId: ride.driverId,
        latitude: currentLat,
        longitude: currentLon,
        heading,
        speed: 30, // 30 km/h
      });

      currentStep++;
    }, 500); // Toutes les 500ms
  }

  /**
   * Calculer le cap/heading entre deux points
   */
  calculateHeading(lat1, lon1, lat2, lon2) {
    const dLon = lon2 - lon1;
    const y = Math.sin(dLon) * Math.cos(lat2);
    const x = Math.cos(lat1) * Math.sin(lat2) - 
              Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);
    const heading = Math.atan2(y, x);
    return (heading * 180 / Math.PI + 360) % 360;
  }
}

module.exports = TrackingHandler;



