const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Driver = require('../models/Driver');
const Ride = require('../models/Ride');

module.exports = (io) => {
  // Middleware d'authentification Socket.io
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');
      
      if (!token) {
        return next(new Error('Token d\'authentification requis'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.userId);
      
      if (!user || !user.isActive) {
        return next(new Error('Utilisateur non trouvé ou inactif'));
      }

      socket.userId = user._id;
      socket.user = user;
      next();
    } catch (error) {
      next(new Error('Token invalide'));
    }
  });

  io.on('connection', async (socket) => {
    console.log(`Utilisateur connecté: ${socket.userId}`);

    // Vérifier si c'est un chauffeur
    const driver = await Driver.findOne({ user: socket.userId });
    if (driver) {
      socket.driverId = driver._id;
      socket.driver = driver;
      
      // Rejoindre la room des chauffeurs
      socket.join('drivers');
      console.log(`Chauffeur connecté: ${driver._id}`);
    } else {
      // Rejoindre la room des passagers
      socket.join('passengers');
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
          'currentLocation': {
            $near: {
              $geometry: {
                type: 'Point',
                coordinates: [pickup.coordinates.longitude, pickup.coordinates.latitude]
              },
              $maxDistance: 2000 // 2km
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

        // Notifier les chauffeurs disponibles
        const rideData = {
          id: ride._id,
          rideId: ride.rideId,
          pickup,
          destination,
          pricing,
          rideType,
          passenger: {
            id: socket.user._id,
            name: `${socket.user.firstName} ${socket.user.lastName}`,
            phone: socket.user.phone
          },
          requestedAt: ride.requestedAt
        };

        // Envoyer à chaque chauffeur disponible
        availableDrivers.forEach(driver => {
          const distance = driver.calculateDistance(
            pickup.coordinates.latitude,
            pickup.coordinates.longitude
          );
          
          io.to(`driver_${driver._id}`).emit('new-ride-request', {
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
          return socket.emit('error', { message: 'Accès réservé aux chauffeurs' });
        }

        const { rideId } = data;
        
        const ride = await Ride.findById(rideId);
        if (!ride) {
          return socket.emit('error', { message: 'Course non trouvée' });
        }

        if (ride.status !== 'requested') {
          return socket.emit('error', { message: 'Cette course ne peut plus être acceptée' });
        }

        // Assigner la course au chauffeur
        ride.driver = socket.driverId;
        ride.status = 'accepted';
        ride.acceptedAt = new Date();
        await ride.save();

        // Mettre le chauffeur en mode occupé
        const driver = await Driver.findById(socket.driverId);
        driver.status = 'busy';
        driver.isAvailable = false;
        await driver.save();

        // Notifier le passager
        io.to(`passenger_${ride.passenger}`).emit('ride-accepted', {
          rideId: ride._id,
          driver: {
            id: driver._id,
            name: `${socket.user.firstName} ${socket.user.lastName}`,
            phone: socket.user.phone,
            vehicle: driver.vehicle
          },
          estimatedArrival: 5 // minutes
        });

        // Notifier les autres chauffeurs que la course n'est plus disponible
        socket.broadcast.to('drivers').emit('ride-no-longer-available', {
          rideId: ride._id
        });

        socket.emit('ride-accepted-success', {
          rideId: ride._id,
          passenger: {
            name: `${ride.passenger.firstName} ${ride.passenger.lastName}`,
            phone: ride.passenger.phone
          }
        });

      } catch (error) {
        console.error('Erreur acceptation course:', error);
        socket.emit('error', { message: 'Erreur lors de l\'acceptation de la course' });
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
        driver.status = 'online';
        driver.isAvailable = true;
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
          driver.status = 'online';
          driver.isAvailable = true;
          await driver.save();
        }

        // Notifier l'autre partie
        if (isPassenger) {
          io.to(`driver_${ride.driver}`).emit('ride-cancelled', {
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



