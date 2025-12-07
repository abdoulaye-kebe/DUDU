const cron = require('node-cron');
const Ride = require('../models/Ride');
const Driver = require('../models/Driver');
const User = require('../models/User');

// Même logique de distance que dans routes/rides.js
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

module.exports = function startScheduledRidesDispatcher(io) {
  if (!io) return;

  // Toutes les minutes
  cron.schedule('* * * * *', async () => {
    try {
      const now = new Date();
      // Fenêtre de 5 minutes à partir de maintenant
      const windowEnd = new Date(now.getTime() + 5 * 60 * 1000);

      const rides = await Ride.find({
        scheduledFor: { $lte: windowEnd, $gte: now },
        status: 'requested',
      });

      if (!rides.length) return;

      console.log('⏰ Scheduler - courses planifiées à dispatcher:', rides.length);

      for (const ride of rides) {
        try {
          const pickup = ride.pickup.coordinates;
          const rideType = ride.rideType || 'standard';
          const customPrice = ride.pricing?.customPrice || ride.pricing?.totalPrice || 0;

          // Rayon de recherche similaire à la route prix libre
          const SEARCH_RADIUS = {
            standard: 5000,
            express: 7000,
            shared: 5000,
            women_only: 5000,
          };
          const searchRadius = SEARCH_RADIUS[rideType] || 3000;

          const driverQuery = {
            status: 'online',
            isAvailable: true,
            'subscription.isActive': true,
            'subscription.endDate': { $gt: new Date() },
            [`rideTypes.${rideType}`]: true,
            'preferences.minPrice': { $lte: customPrice },
            'location.latitude': { $exists: true, $ne: null },
            'location.longitude': { $exists: true, $ne: null },
          };

          // Filtre spécial femmes uniquement
          if (rideType === 'women_only') {
            const femaleUsers = await User.find({ gender: 'female' }).select('_id');
            const femaleUserIds = femaleUsers.map((u) => u._id);
            driverQuery.user = { $in: femaleUserIds };
          }

          const allDrivers = await Driver.find(driverQuery)
            .populate('user', 'firstName lastName gender')
            .limit(50);

          let availableDrivers = allDrivers.filter((driver) => {
            if (!driver.location || !driver.location.latitude || !driver.location.longitude) {
              return false;
            }

            const distance = calculateDistance(
              pickup.latitude,
              pickup.longitude,
              driver.location.latitude,
              driver.location.longitude,
            );

            const inRadius = distance <= searchRadius / 1000;
            return inRadius;
          }).slice(0, 20);

          if (!availableDrivers.length) {
            console.log('⏰ Scheduler - aucun chauffeur trouvé pour la course planifiée', ride._id);
            continue;
          }

          const passengerUser = await User.findById(ride.passenger);
          const firstName = passengerUser?.firstName || 'Client';
          const lastName = passengerUser?.lastName || 'DUDU';
          const passengerName = `${firstName} ${lastName}`;
          const passengerPhone = passengerUser?.phone || null;

          console.log('⏰ Scheduler - notification chauffeurs planifiés:', {
            rideId: ride._id.toString(),
            drivers: availableDrivers.map((d) => d._id.toString()),
          });

          availableDrivers.forEach((driver) => {
            io.to(`driver_${driver._id}`).emit('new-ride-request', {
              rideId: ride._id,
              pickup: ride.pickup.address,
              destination: ride.destination.address,
              distance: ride.distance,
              rideType,
              customPrice,
              estimatedDuration: ride.estimatedDuration,
              passengerName,
              passengerPhone,
              scheduledFor: ride.scheduledFor,
            });
          });

          // Marquer la course comme "searching" pour éviter de la redispatcher
          ride.status = 'searching';
          await ride.save();
        } catch (err) {
          console.error('⏰ Scheduler - erreur sur une course planifiée:', err);
        }
      }
    } catch (error) {
      console.error('⏰ Scheduler - erreur globale:', error);
    }
  });
};
