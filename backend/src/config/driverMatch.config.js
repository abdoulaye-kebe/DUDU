/**
 * Rayon de mise en relation chauffeur ↔ course (HTTP + Socket + notifications).
 * Surclassable via variables d'environnement (km).
 */
function parsePositiveKm(value, fallbackKm) {
  const v = parseFloat(value, 10);
  if (Number.isFinite(v) && v > 0) return v;
  return fallbackKm;
}

function getDriverMatchInitialRadiusKm() {
  return parsePositiveKm(process.env.DRIVER_MATCH_INITIAL_RADIUS_KM, 12);
}

function getDriverMatchExpandedRadiusKm() {
  const initial = getDriverMatchInitialRadiusKm();
  const fromEnv = parseFloat(process.env.DRIVER_MATCH_EXPANDED_RADIUS_KM || '', 10);
  if (Number.isFinite(fromEnv) && fromEnv > initial) return fromEnv;
  return Math.max(initial * 2, 25);
}

/** Mètres pour $near Mongo sur currentLocation des chauffeurs */
function getDriverNotifyMaxDistanceM() {
  return getDriverMatchInitialRadiusKm() * 1000;
}

module.exports = {
  getDriverMatchInitialRadiusKm,
  getDriverMatchExpandedRadiusKm,
  getDriverNotifyMaxDistanceM,
};
