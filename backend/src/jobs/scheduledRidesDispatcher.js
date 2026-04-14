const cron = require('node-cron');
const Ride = require('../models/Ride');
const User = require('../models/User');
const { notifyDriversNewRideRequest } = require('../services/notifyDriversNewRideRequest');

/**
 * Relance les courses planifiées dont l’heure approche (fenêtre 5 min)
 * si aucun chauffeur n’a encore été trouvé (statut requested).
 */
module.exports = function startScheduledRidesDispatcher(io) {
  if (!io) return;

  cron.schedule('* * * * *', async () => {
    try {
      const now = new Date();
      const windowEnd = new Date(now.getTime() + 5 * 60 * 1000);

      const rides = await Ride.find({
        scheduledFor: { $lte: windowEnd, $gte: now },
        status: 'requested',
      });

      if (!rides.length) return;

      console.log('⏰ Scheduler - courses planifiées à relancer:', rides.length);

      for (const ride of rides) {
        try {
          const passengerUser = await User.findById(ride.passenger);
          const { notified } = await notifyDriversNewRideRequest(io, ride, passengerUser);

          if (!notified) {
            console.log('⏰ Scheduler - aucun chauffeur à proximité pour', ride._id);
            continue;
          }

          ride.status = 'searching';
          await ride.save();
          console.log('⏰ Scheduler - notification envoyée, statut searching', ride._id.toString());
        } catch (err) {
          console.error('⏰ Scheduler - erreur sur une course planifiée:', err);
        }
      }
    } catch (error) {
      console.error('⏰ Scheduler - erreur globale:', error);
    }
  });
};
