const { computeRoute } = require('./googleMapsService');
const { decodePolyline } = require('../utils/polyline');
const { haversineDistanceKm } = require('../utils/geo');

const CORRIDOR_BUFFER_KM = 1.2; // Maximum allowed distance of the pickup/destination from the route

// Finds the closest point on the route to the candidate point and returns its index
const nearestPointOnRoute = (routePoints, lat, lng) => {
  let minDist = Infinity;
  let nearestIndex = -1;

  routePoints.forEach((point, idx) => {
    const dist = haversineDistanceKm(lat, lng, point.lat, point.lng);
    if (dist < minDist) {
      minDist = dist;
      nearestIndex = idx;
    }
  });

  return { distanceKm: minDist, index: nearestIndex };
};

// If the session hasn't started yet, use the stored polyline; otherwise, fetch a fresh route from the current location to the destination
const getEffectiveRoute = async (session) => {
  const isLive = session.is_started === true && session.current_lat && session.current_lng;

  if (!isLive) {
    return session.route_polyline ? decodePolyline(session.route_polyline) : [];
  }

  try {
    const route = await computeRoute({
      originLat: Number(session.current_lat),
      originLng: Number(session.current_lng),
      destinationLat: Number(session.destination_lat),
      destinationLng: Number(session.destination_lng),
    });
    return decodePolyline(route.polyline);
  } catch (_) {
    return session.route_polyline ? decodePolyline(session.route_polyline) : [];
  }
};

// Checks whether the passenger's pickup and destination lie along the session's route
const matchPassengerToSession = async ({ session, pickupLat, pickupLng, destLat, destLng }) => {
  const routePoints = await getEffectiveRoute(session);
  if (!routePoints.length) return null;

  const pickupMatch = nearestPointOnRoute(routePoints, pickupLat, pickupLng);
  const destMatch = nearestPointOnRoute(routePoints, destLat, destLng);

  if (pickupMatch.distanceKm > CORRIDOR_BUFFER_KM) return null;
  if (destMatch.distanceKm > CORRIDOR_BUFFER_KM) return null;

  // direction check — destination অবশ্যই pickup-এর পরে (উল্টো দিকে না)
  if (destMatch.index < pickupMatch.index) return null;

  const proximityScore = Math.max(
    0,
    1 - (pickupMatch.distanceKm + destMatch.distanceKm) / (2 * CORRIDOR_BUFFER_KM)
  );

  return {
    pickupDistanceKm: Number(pickupMatch.distanceKm.toFixed(2)),
    destDistanceKm: Number(destMatch.distanceKm.toFixed(2)),
    proximityScore: Number(proximityScore.toFixed(3)),
  };
};

module.exports = {
  getEffectiveRoute,
  matchPassengerToSession,
};
