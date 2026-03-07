/**
 * Service Google Maps - Distance Matrix pour obtenir distance et durée réelles
 */
const axios = require('axios');

const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;
const BASE_URL = 'https://maps.googleapis.com/maps/api/distancematrix/json';

/**
 * Calcule la distance (km) et la durée (minutes) entre deux points via l'API Google Distance Matrix
 * @param {number} originLat - Latitude départ
 * @param {number} originLng - Longitude départ
 * @param {number} destLat - Latitude arrivée
 * @param {number} destLng - Longitude arrivée
 * @returns {Promise<{ distanceKm: number, durationMinutes: number }>}
 */
async function getDistanceAndDuration(originLat, originLng, destLat, destLng) {
  if (!GOOGLE_MAPS_API_KEY) {
    return null;
  }
  try {
    const origins = `${originLat},${originLng}`;
    const destinations = `${destLat},${destLng}`;
    const url = `${BASE_URL}?origins=${origins}&destinations=${destinations}&key=${GOOGLE_MAPS_API_KEY}&mode=driving`;
    const { data } = await axios.get(url, { timeout: 5000 });
    if (data.status !== 'OK' || !data.rows?.[0]?.elements?.[0]) {
      return null;
    }
    const el = data.rows[0].elements[0];
    if (el.status !== 'OK') {
      return null;
    }
    return {
      distanceKm: (el.distance?.value ?? 0) / 1000,
      durationMinutes: Math.round((el.duration?.value ?? 0) / 60)
    };
  } catch (err) {
    console.warn('Google Maps Distance Matrix error:', err.message);
    return null;
  }
}

module.exports = { getDistanceAndDuration };
