/**
 * Payload événement Socket `new-ride-request` (aligné mobile_dudu_pro / SocketService).
 */
function buildNewRideRequestPayload(ride, passengerLike = {}, extras = {}) {
  const id = passengerLike._id ?? passengerLike.id;
  const firstName = passengerLike.firstName || 'Client';
  const lastName = passengerLike.lastName || 'DUDU';

  const payload = {
    id: ride._id,
    rideId: ride.rideId,
    pickup: ride.pickup,
    destination: ride.destination,
    pricing: ride.pricing,
    rideType: ride.rideType || 'standard',
    distance: ride.distance,
    estimatedDuration: ride.estimatedDuration,
    passenger: {
      id,
      name: `${firstName} ${lastName}`.trim(),
      phone: passengerLike.phone,
    },
    requestedAt: ride.requestedAt,
    ...extras,
  };

  if (ride.scheduledFor) {
    payload.scheduledFor = ride.scheduledFor;
  }

  return payload;
}

module.exports = { buildNewRideRequestPayload };
