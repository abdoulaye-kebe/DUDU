const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Driver = require('../models/Driver');
const Ride = require('../models/Ride');
const {
  ACTIVE_RIDE_STATUSES,
  driverCanAcceptNewDelivery,
} = require('../utils/deliveryDriverRules');
const { getDriverNotifyMaxDistanceM } = require('../config/driverMatch.config');
const { buildNewRideRequestPayload } = require('../utils/buildNewRideRequestPayload');

module.exports = (io) => {
  // Middleware d'authentification Socket.io
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');
      
      if (!token) {
        return next(new Error('Token d\'authentification requis'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      if (decoded.type === 'driver') {
        const driver = await Driver.findById(decoded.id);

        // En phase de tests, on assouplit la condition: on vérifie seulement que le chauffeur existe
        if (!driver) {
          return next(new Error('Chauffeur non trouvé'));
        }

        socket.userType = 'driver';
        socket.driverId = driver._id.toString();
        socket.driver = driver;
        socket.user = driver;
        socket.userId = driver.user ? driver.user.toString() : null;
        next();
      } else {
        const user = await User.findById(decoded.userId);
        
        if (!user || !user.isActive) {
          return next(new Error('Utilisateur non trouvé ou inactif'));
        }

        socket.userType = 'passenger';
        socket.userId = user._id.toString();
        socket.user = user;
        next();
      }
    } catch (error) {
      next(new Error('Token invalide'));
    }
  });

  io.on('connection', async (socket) => {
    console.log(`Socket connecté: type=${socket.userType} id=${socket.userType === 'driver' ? socket.driverId : socket.userId}`);

    if (socket.userType === 'driver') {
      socket.join('drivers');
      socket.join(`driver_${socket.driverId}`);
      console.log(`Chauffeur connecté: ${socket.driverId}`);
    } else {
      socket.join('passengers');
      if (socket.userId) {
        socket.join(`passenger_${socket.userId}`);
      }
      console.log(`Passager connecté: ${socket.userId}`);
    }

    // Gestion de la localisation du chauffeur
    socket.on('update-location', async (data) => {
      try {
        if (!socket.driver) {
          return socket.emit('error', { message: 'Accès réservé aux chauffeurs' });
        }

        const { latitude, longitude, address } = data;
        
        // Mettre à jour la localisation dans la base de données
        const driver = await Driver.findById(socket.driverId);
        if (driver) {
          driver.updateLocation(latitude, longitude, address);
          await driver.save();
          socket.driver = driver;

          // Diffuser la position aux passagers à proximité
          socket.broadcast.to('passengers').emit('driver-location-updated', {
            driverId: driver._id,
            location: driver.currentLocation
          });
        }

        socket.emit('location-updated', { success: true });
      } catch (error) {
        console.error('Erreur mise à jour localisation:', error);
        socket.emit('error', { message: 'Erreur lors de la mise à jour de la localisation' });
      }
    });

    // Gestion du statut du chauffeur
    socket.on('update-status', async (data) => {
      try {
        if (!socket.driver) {
          return socket.emit('error', { message: 'Accès réservé aux chauffeurs' });
        }

        const { status, isAvailable } = data;
        
        const driver = await Driver.findById(socket.driverId);
        if (driver) {
          driver.status = status;
          if (isAvailable !== undefined) {
            driver.isAvailable = isAvailable;
          }
          await driver.save();
          socket.driver = driver;

          // Notifier les passagers du changement de statut
          socket.broadcast.to('passengers').emit('driver-status-updated', {
            driverId: driver._id,
            status: driver.status,
            isAvailable: driver.isAvailable
          });
        }

        socket.emit('status-updated', { success: true });
      } catch (error) {
        console.error('Erreur mise à jour statut:', error);
        socket.emit('error', { message: 'Erreur lors de la mise à jour du statut' });
      }
    });

    // Demande de course
    socket.on('request-ride', async (data) => {
      try {
        const { pickup, destination, pricing, rideType = 'standard' } = data;

        // Créer la course
        const ride = new Ride({
          passenger: socket.userId,
          pickup,
          destination,
          pricing,
          rideType,
          status: 'requested'
        });

        await ride.save();

        // Trouver les chauffeurs disponibles à proximité
        const availableDrivers = await Driver.find({
          status: 'online',
          isAvailable: true,
          'subscription.isActive': true,
          'currentLocation.coordinates': { $exists: true },
          currentLocation: {
            $near: {
              $geometry: {
                type: 'Point',
                coordinates: [pickup.coordinates.longitude, pickup.coordinates.latitude]
              },
              $maxDistance: getDriverNotifyMaxDistanceM(),
            }
          }
        });

        if (availableDrivers.length === 0) {
          ride.status = 'no_driver';
          await ride.save();
          
          socket.emit('ride-request-failed', {
            rideId: ride._id,
            reason: 'Aucun chauffeur disponible dans la zone'
          });
          return;
        }

        const rideData = buildNewRideRequestPayload(ride, socket.user);

        // Envoyer à chaque chauffeur disponible
        availableDrivers.forEach(driver => {
          const distance = driver.calculateDistance(
            pickup.coordinates.latitude,
            pickup.coordinates.longitude
          );
          const roomId = `driver_${driver._id.toString()}`;

          io.to(roomId).emit('new-ride-request', {
            ...rideData,
            driverDistance: distance
          });
        });

        // Confirmer au passager
        socket.emit('ride-request-sent', {
          rideId: ride._id,
          availableDrivers: availableDrivers.length
        });

        // Programmer l'expiration de la demande (3 minutes)
        setTimeout(async () => {
          const updatedRide = await Ride.findById(ride._id);
          if (updatedRide && updatedRide.status === 'requested') {
            updatedRide.status = 'expired';
            await updatedRide.save();
            
            socket.emit('ride-request-expired', {
              rideId: updatedRide._id
            });
          }
        }, 3 * 60 * 1000); // 3 minutes

      } catch (error) {
        console.error('Erreur demande de course:', error);
        socket.emit('error', { message: 'Erreur lors de la demande de course' });
      }
    });

    // Accepter une course (chauffeur)
    socket.on('accept-ride', async (data) => {
      try {
        if (!socket.driver) {
          console.log('❌ accept-ride refusé: socket sans driver');
          return socket.emit('error', { message: 'Accès réservé aux chauffeurs' });
        }

        const { rideId } = data;
        console.log('📨 Event accept-ride reçu', { rideId, driverId: socket.driverId });
        
        const ride = await Ride.findById(rideId);
        if (!ride) {
          console.log('❌ accept-ride: course introuvable', { rideId });
          return socket.emit('accept-ride-rejected', {
            rideId,
            message: 'Course non trouvée',
          });
        }

        if (ride.status !== 'requested' && ride.status !== 'searching') {
          console.log('❌ accept-ride: statut invalide', { rideId, status: ride.status });
          return socket.emit('accept-ride-rejected', {
            rideId,
            message: 'Cette course ne peut plus être acceptée',
          });
        }

        let activeDeliveryCount = 0;
        if (ride.rideType === 'delivery') {
          const acceptCheck = await driverCanAcceptNewDelivery(socket.driverId, ride);
          if (!acceptCheck.ok) {
            console.log('❌ accept-ride: règle livraison', {
              rideId,
              driverId: socket.driverId,
              code: acceptCheck.code,
            });
            return socket.emit('accept-ride-rejected', {
              rideId,
              message: acceptCheck.message,
              code: acceptCheck.code,
            });
          }
          activeDeliveryCount = await Ride.countDocuments({
            driver: socket.driverId,
            rideType: 'delivery',
            status: { $in: ACTIVE_RIDE_STATUSES },
          });
        }

        // Assigner la course au chauffeur
        ride.driver = socket.driverId;
        ride.status = 'accepted';
        ride.acceptedAt = new Date();
        await ride.save();

        console.log('✅ Course acceptée via socket', { rideId: ride._id.toString(), driverId: socket.driverId });

        // Mettre le chauffeur en mode occupé
        const driver = await Driver.findById(socket.driverId);
        if (ride.rideType === 'delivery') {
          const nextActiveCount = activeDeliveryCount + 1;
          driver.status = 'online';
          driver.isAvailable = nextActiveCount < 2;
        } else {
          driver.status = 'busy';
          driver.isAvailable = false;
        }
        await driver.save();

        const passenger = await User.findById(ride.passenger);

        // Préparer les informations du chauffeur
        const driverInfo = {
          id: driver._id,
          name: `${socket.user.firstName} ${socket.user.lastName}`,
          phone: socket.user.phone,
          photo: driver.photo || null,
          rating: driver.stats?.averageRating || 0,
          totalRides: driver.stats?.completedRides || 0,
          vehicle: {
            type: driver.vehicle?.type || 'car',
            brand: driver.vehicle?.brand || '',
            model: driver.vehicle?.model || '',
            color: driver.vehicle?.color || '',
            plate: driver.vehicle?.licensePlate || '',
            year: driver.vehicle?.year || null
          }
        };

        // Notifier le passager
        const passengerRoom = `passenger_${ride.passenger.toString()}`;
        const notificationData = {
          rideId: ride._id,
          driver: driverInfo,
          estimatedArrival: 5, // minutes
          isScheduled: !!ride.scheduledFor,
          scheduledFor: ride.scheduledFor || null,
          pickup: ride.pickup,
          destination: ride.destination,
          pricing: ride.pricing,
          rideType: ride.rideType
        };

        io.to(passengerRoom).emit('ride-accepted', notificationData);
        
        console.log('📢 Notification envoyée au client:', {
          passengerId: ride.passenger.toString(),
          isScheduled: !!ride.scheduledFor,
          scheduledFor: ride.scheduledFor
        });

        // Notifier les autres chauffeurs que la course n'est plus disponible
        socket.broadcast.to('drivers').emit('ride-no-longer-available', {
          rideId: ride._id
        });

        socket.emit('ride-accepted-success', {
          rideId: ride._id,
          passenger: passenger ? {
            name: `${passenger.firstName} ${passenger.lastName}`,
            phone: passenger.phone
          } : null
        });

      } catch (error) {
        console.error('Erreur acceptation course:', error);
        socket.emit('error', { message: 'Erreur lors de l\'acceptation de la course' });
      }
    });

    // Refus d'une demande par le chauffeur (notifie le client pour qu'il sache qu'un chauffeur a décliné)
    socket.on('refuse-ride', async (data) => {
      try {
        if (!socket.driver) {
          return socket.emit('error', { message: 'Accès réservé aux chauffeurs' });
        }

        const { rideId } = data || {};
        if (!rideId) {
          return socket.emit('error', { message: 'rideId requis' });
        }

        const ride = await Ride.findById(rideId);
        if (!ride) {
          return socket.emit('error', { message: 'Course non trouvée' });
        }

        if (ride.status !== 'requested') {
          return socket.emit('error', { message: 'Cette course ne peut plus être refusée' });
        }

        const driverId = socket.driverId.toString();
        const already = (ride.refusedBy || []).some(
          (r) => r.driver && r.driver.toString() === driverId
        );
        if (!already) {
          ride.refusedBy = ride.refusedBy || [];
          ride.refusedBy.push({
            driver: socket.driverId,
            reason: 'declined',
            refusedAt: new Date()
          });
          await ride.save();
        }

        const passengerRoom = `passenger_${ride.passenger.toString()}`;
        io.to(passengerRoom).emit('ride-refused-by-driver', {
          rideId: ride._id,
          message: 'Un chauffeur a refusé cette demande. Nous continuons à chercher un autre chauffeur.'
        });

        socket.emit('ride-refused-ok', { rideId: ride._id });
      } catch (error) {
        console.error('Erreur refuse-ride:', error);
        socket.emit('error', { message: 'Erreur lors du refus de la course' });
      }
    });

    // Signaler l'arrivée du chauffeur
    socket.on('driver-arrived', async (data) => {
      try {
        if (!socket.driver) {
          return socket.emit('error', { message: 'Accès réservé aux chauffeurs' });
        }

        const { rideId } = data;
        
        const ride = await Ride.findById(rideId);
        if (!ride || ride.driver.toString() !== socket.driverId.toString()) {
          return socket.emit('error', { message: 'Course non trouvée ou non assignée' });
        }

        ride.status = 'arrived';
        ride.arrivedAt = new Date();
        await ride.save();

        // Notifier le passager
        io.to(`passenger_${ride.passenger}`).emit('driver-arrived', {
          rideId: ride._id,
          arrivedAt: ride.arrivedAt
        });

        socket.emit('arrival-confirmed', { rideId: ride._id });

      } catch (error) {
        console.error('Erreur signalisation arrivée:', error);
        socket.emit('error', { message: 'Erreur lors de la signalisation d\'arrivée' });
      }
    });

    // Commencer la course
    socket.on('start-ride', async (data) => {
      try {
        if (!socket.driver) {
          return socket.emit('error', { message: 'Accès réservé aux chauffeurs' });
        }

        const { rideId } = data;
        
        const ride = await Ride.findById(rideId);
        if (!ride || ride.driver.toString() !== socket.driverId.toString()) {
          return socket.emit('error', { message: 'Course non trouvée ou non assignée' });
        }

        ride.status = 'started';
        ride.startedAt = new Date();
        await ride.save();

        // Notifier le passager
        io.to(`passenger_${ride.passenger}`).emit('ride-started', {
          rideId: ride._id,
          startedAt: ride.startedAt
        });

        socket.emit('ride-started-confirmed', { rideId: ride._id });

      } catch (error) {
        console.error('Erreur démarrage course:', error);
        socket.emit('error', { message: 'Erreur lors du démarrage de la course' });
      }
    });

    // Terminer la course
    socket.on('complete-ride', async (data) => {
      try {
        if (!socket.driver) {
          return socket.emit('error', { message: 'Accès réservé aux chauffeurs' });
        }

        const { rideId, actualDuration, actualDistance } = data;
        
        const ride = await Ride.findById(rideId);
        if (!ride || ride.driver.toString() !== socket.driverId.toString()) {
          return socket.emit('error', { message: 'Course non trouvée ou non assignée' });
        }

        ride.status = 'completed';
        ride.completedAt = new Date();
        if (actualDuration) ride.actualDuration = actualDuration;
        if (actualDistance) ride.distance = actualDistance;
        await ride.save();

        // Mettre à jour les statistiques
        const driver = await Driver.findById(socket.driverId);
        driver.stats.totalRides += 1;
        driver.stats.completedRides += 1;
        driver.stats.totalEarnings += ride.pricing.totalPrice;
        driver.earnings.today += ride.pricing.totalPrice;

        if (ride.rideType === 'delivery') {
          const remainingActive = await Ride.countDocuments({
            driver: driver._id,
            rideType: 'delivery',
            status: { $in: ACTIVE_RIDE_STATUSES }
          });
          driver.status = 'online';
          driver.isAvailable = remainingActive < 2;
        } else {
          driver.status = 'online';
          driver.isAvailable = true;
        }
        await driver.save();

        // Notifier le passager
        io.to(`passenger_${ride.passenger}`).emit('ride-completed', {
          rideId: ride._id,
          completedAt: ride.completedAt,
          pricing: ride.pricing
        });

        socket.emit('ride-completed-confirmed', { 
          rideId: ride._id,
          earnings: ride.pricing.totalPrice
        });

      } catch (error) {
        console.error('Erreur finalisation course:', error);
        socket.emit('error', { message: 'Erreur lors de la finalisation de la course' });
      }
    });

    // Annuler une course
    socket.on('cancel-ride', async (data) => {
      try {
        const { rideId, reason } = data;
        
        const ride = await Ride.findById(rideId);
        if (!ride) {
          return socket.emit('error', { message: 'Course non trouvée' });
        }

        // Vérifier les permissions
        const isPassenger = ride.passenger.toString() === socket.userId.toString();
        const isDriver = ride.driver && ride.driver.toString() === socket.driverId?.toString();

        if (!isPassenger && !isDriver) {
          return socket.emit('error', { message: 'Accès non autorisé' });
        }

        if (!ride.canBeCancelled()) {
          return socket.emit('error', { message: 'Cette course ne peut plus être annulée' });
        }

        const cancelledBy = isPassenger ? 'passenger' : 'driver';
        const cancellationReason = isPassenger ? 'passenger_cancelled' : 'driver_cancelled';

        ride.status = 'cancelled';
        ride.cancelledAt = new Date();
        ride.cancellation = {
          reason: cancellationReason,
          cancelledBy,
          refundAmount: ride.pricing.totalPrice
        };
        await ride.save();

        // Si c'est le chauffeur qui annule, le remettre en ligne
        if (isDriver) {
          const driver = await Driver.findById(socket.driverId);
          if (ride.rideType === 'delivery') {
            const remainingActive = await Ride.countDocuments({
              driver: driver._id,
              rideType: 'delivery',
              status: { $in: ACTIVE_RIDE_STATUSES }
            });
            driver.status = 'online';
            driver.isAvailable = remainingActive < 2;
          } else {
            driver.status = 'online';
            driver.isAvailable = true;
          }
          await driver.save();
        }

        // Notifier l'autre partie
        if (isPassenger) {
          const driverRoom = `driver_${ride.driver.toString()}`;
          io.to(driverRoom).emit('ride-cancelled', {
            rideId: ride._id,
            cancelledBy: 'passenger',
            reason
          });
        } else {
          io.to(`passenger_${ride.passenger}`).emit('ride-cancelled', {
            rideId: ride._id,
            cancelledBy: 'driver',
            reason
          });
        }

        socket.emit('ride-cancelled-confirmed', { rideId: ride._id });

      } catch (error) {
        console.error('Erreur annulation course:', error);
        socket.emit('error', { message: 'Erreur lors de l\'annulation de la course' });
      }
    });

    // Suivi de course en temps réel
    socket.on('track-ride', async (data) => {
      try {
        const { rideId } = data;
        
        const ride = await Ride.findById(rideId);
        if (!ride) {
          return socket.emit('error', { message: 'Course non trouvée' });
        }

        // Vérifier les permissions
        const isPassenger = ride.passenger.toString() === socket.userId.toString();
        const isDriver = ride.driver && ride.driver.toString() === socket.driverId?.toString();

        if (!isPassenger && !isDriver) {
          return socket.emit('error', { message: 'Accès non autorisé' });
        }

        // Rejoindre la room de suivi de cette course
        socket.join(`ride_${rideId}`);

        socket.emit('ride-tracking-started', {
          rideId: ride._id,
          status: ride.status,
          pickup: ride.pickup,
          destination: ride.destination
        });

      } catch (error) {
        console.error('Erreur suivi course:', error);
        socket.emit('error', { message: 'Erreur lors du suivi de la course' });
      }
    });

    // Mettre à jour la position pendant la course
    socket.on('update-ride-location', async (data) => {
      try {
        if (!socket.driver) {
          return socket.emit('error', { message: 'Accès réservé aux chauffeurs' });
        }

        const { rideId, latitude, longitude, speed, heading } = data;
        
        const ride = await Ride.findById(rideId);
        if (!ride || ride.driver.toString() !== socket.driverId.toString()) {
          return socket.emit('error', { message: 'Course non trouvée ou non assignée' });
        }

        // Ajouter le point de suivi
        ride.addTrackingPoint(latitude, longitude, speed, heading);
        await ride.save();

        // Diffuser la position aux passagers qui suivent cette course
        io.to(`ride_${rideId}`).emit('ride-location-updated', {
          rideId: ride._id,
          location: {
            latitude,
            longitude,
            speed,
            heading,
            timestamp: new Date()
          }
        });

      } catch (error) {
        console.error('Erreur mise à jour position course:', error);
        socket.emit('error', { message: 'Erreur lors de la mise à jour de la position' });
      }
    });

    // Recevoir position GPS du chauffeur en temps réel (toutes les 3 secondes)
    socket.on('driver-location-update', async (data) => {
      try {
        if (!socket.driver) {
          return socket.emit('error', { message: 'Accès réservé aux chauffeurs' });
        }

        const { rideId, latitude, longitude, speed, heading, timestamp } = data;
        
        // Vérifier que la course existe et est assignée à ce chauffeur
        const ride = await Ride.findById(rideId);
        if (!ride || ride.driver.toString() !== socket.driverId.toString()) {
          return;
        }

        // Diffuser la position au client en temps réel
        io.to(`passenger_${ride.passenger}`).emit('driver-location', {
          rideId: ride._id,
          latitude,
          longitude,
          speed,
          heading,
          timestamp: timestamp || new Date().toISOString()
        });

        // Aussi diffuser dans la room de suivi de la course
        io.to(`ride_${rideId}`).emit('driver-location', {
          rideId: ride._id,
          latitude,
          longitude,
          speed,
          heading,
          timestamp: timestamp || new Date().toISOString()
        });

      } catch (error) {
        console.error('Erreur réception position chauffeur:', error);
      }
    });

    // --- Signalisation WebRTC pour appels VOIP (base) ---
    // Offre d'appel (WebRTC offer)
    socket.on('call-offer', async (data) => {
      try {
        const { rideId, sdp } = data || {};
        if (!rideId || !sdp) return;

        const ride = await Ride.findById(rideId);
        if (!ride) return;

        let targetRoom = null;
        if (socket.userType === 'passenger' && ride.driver) {
          targetRoom = `driver_${ride.driver.toString()}`;
        } else if (socket.userType === 'driver') {
          targetRoom = `passenger_${ride.passenger.toString()}`;
        }
        if (!targetRoom) return;

        io.to(targetRoom).emit('call-offer', {
          rideId: ride._id.toString(),
          sdp,
          fromType: socket.userType,
          fromId: socket.userType === 'driver' ? socket.driverId : socket.userId,
        });
      } catch (error) {
        console.error('Erreur call-offer:', error);
      }
    });

    // Réponse à l'appel (WebRTC answer)
    socket.on('call-answer', async (data) => {
      try {
        const { rideId, sdp } = data || {};
        if (!rideId || !sdp) return;

        const ride = await Ride.findById(rideId);
        if (!ride) return;

        let targetRoom = null;
        if (socket.userType === 'passenger' && ride.driver) {
          targetRoom = `driver_${ride.driver.toString()}`;
        } else if (socket.userType === 'driver') {
          targetRoom = `passenger_${ride.passenger.toString()}`;
        }
        if (!targetRoom) return;

        io.to(targetRoom).emit('call-answer', {
          rideId: ride._id.toString(),
          sdp,
          fromType: socket.userType,
          fromId: socket.userType === 'driver' ? socket.driverId : socket.userId,
        });
      } catch (error) {
        console.error('Erreur call-answer:', error);
      }
    });

    // Échange de ICE candidates
    socket.on('ice-candidate', async (data) => {
      try {
        const { rideId, candidate } = data || {};
        if (!rideId || !candidate) return;

        const ride = await Ride.findById(rideId);
        if (!ride) return;

        let targetRoom = null;
        if (socket.userType === 'passenger' && ride.driver) {
          targetRoom = `driver_${ride.driver.toString()}`;
        } else if (socket.userType === 'driver') {
          targetRoom = `passenger_${ride.passenger.toString()}`;
        }
        if (!targetRoom) return;

        io.to(targetRoom).emit('ice-candidate', {
          rideId: ride._id.toString(),
          candidate,
          fromType: socket.userType,
          fromId: socket.userType === 'driver' ? socket.driverId : socket.userId,
        });
      } catch (error) {
        console.error('Erreur ice-candidate:', error);
      }
    });

    // Fin d'appel
    socket.on('call-end', async (data) => {
      try {
        const { rideId, reason } = data || {};
        if (!rideId) return;

        const ride = await Ride.findById(rideId);
        if (!ride) return;

        let targetRoom = null;
        if (socket.userType === 'passenger' && ride.driver) {
          targetRoom = `driver_${ride.driver.toString()}`;
        } else if (socket.userType === 'driver') {
          targetRoom = `passenger_${ride.passenger.toString()}`;
        }
        if (!targetRoom) return;

        io.to(targetRoom).emit('call-end', {
          rideId: ride._id.toString(),
          reason: reason || 'ended',
          fromType: socket.userType,
          fromId: socket.userType === 'driver' ? socket.driverId : socket.userId,
        });
      } catch (error) {
        console.error('Erreur call-end:', error);
      }
    });

    // Déconnexion
    socket.on('disconnect', async () => {
      console.log(`Utilisateur déconnecté: ${socket.userId}`);

      // Si c'est un chauffeur, le mettre hors ligne
      if (socket.driver) {
        try {
          const driver = await Driver.findById(socket.driverId);
          if (driver) {
            driver.status = 'offline';
            driver.isAvailable = false;
            await driver.save();

            // Notifier les passagers
            socket.broadcast.to('passengers').emit('driver-offline', {
              driverId: driver._id
            });
          }
        } catch (error) {
          console.error('Erreur lors de la déconnexion du chauffeur:', error);
        }
      }
    });
  });

  return io;
};



