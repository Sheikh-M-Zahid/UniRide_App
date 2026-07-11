const crypto = require('crypto');

// Creates a consistent hash from the pickup and destination coordinates.
// ~111 m precision (3 decimal places) — enables reliable recognition of the same route across repeated trips.
const buildRouteHash = (pickupLat, pickupLng, destLat, destLng) => {
  const round = (n) => Number(n).toFixed(3);
  const raw = `${round(pickupLat)},${round(pickupLng)}|${round(destLat)},${round(destLng)}`;
  return crypto.createHash('md5').update(raw).digest('hex');
};

module.exports = { buildRouteHash };
