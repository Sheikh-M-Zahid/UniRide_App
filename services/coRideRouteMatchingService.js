const { computeRoute, computeRouteMatrix } = require('./googleMapsService');
const { decodePolyline } = require('../utils/polyline');
const { haversineDistanceKm } = require('../utils/geo');

const CORRIDOR_BUFFER_KM = 1.2; // Maximum allowed distance of the pickup/destination from the route

// Finds the closest point on the route to the candidate point and returns its index
// (this is a cheap straight-line pre-filter, NOT the final distance used for scoring)
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

// Real driving-distance (km) between a passenger point and a route vertex,
// following actual roads (bridges, one-ways, mapped ferries — all handled
// by Google's own routing). Returns null if the API call fails, so the
// caller can fall back to the straight-line distance instead of crashing.
const getRealRoadDistanceKm = async (fromLat, fromLng, toLat, toLng) => {
  try {
    const rows = await computeRouteMatrix({
      origin: { lat: fromLat, lng: fromLng },
      destinations: [{ lat: toLat, lng: toLng }],
      travelMode: 'DRIVE',
    });
    const row = Array.isArray(rows)
      ? rows.find((r) => r.destinationIndex === 0) || rows[0]
      : null;
    if (row && row.distanceKm !== null && row.distanceKm !== undefined) {
      return row.distanceKm;
    }
    return null;
  } catch (_) {
    return null;
  }
};

// Checks whether the passenger's pickup and destination lie along the session's route.
// Uses REAL road distance (not straight-line) for the actual corridor-buffer check —
// straight-line distance is only used as a cheap pre-filter to avoid wasting API
// calls on candidates that are obviously too far even in a straight line.
const matchPassengerToSession = async ({ session, pickupLat, pickupLng, destLat, destLng }) => {
  const routePoints = await getEffectiveRoute(session);
  if (!routePoints.length) return null;

  const pickupNearest = nearestPointOnRoute(routePoints, pickupLat, pickupLng);
  const destNearest = nearestPointOnRoute(routePoints, destLat, destLng);

  // Cheap early-reject: real road distance is never SHORTER than the
  // straight-line distance, so if the straight line already exceeds the
  // buffer, the real road distance will too — no API call needed.
  if (pickupNearest.distanceKm > CORRIDOR_BUFFER_KM) return null;
  if (destNearest.distanceKm > CORRIDOR_BUFFER_KM) return null;

  // direction check — destination অবশ্যই pickup-এর পরে (উল্টো দিকে না)
  if (destNearest.index < pickupNearest.index) return null;

  const pickupVertex = routePoints[pickupNearest.index];
  const destVertex = routePoints[destNearest.index];

  // Only now (candidate already looks promising) do we spend real API calls
  // to get the actual road distance, following real streets/bridges.
  const [pickupRoadKm, destRoadKm] = await Promise.all([
    getRealRoadDistanceKm(pickupLat, pickupLng, pickupVertex.lat, pickupVertex.lng),
    getRealRoadDistanceKm(destLat, destLng, destVertex.lat, destVertex.lng),
  ]);

  // If the API failed, gracefully fall back to the straight-line distance
  // rather than dropping the candidate entirely.
  const pickupDistanceKm = pickupRoadKm !== null ? pickupRoadKm : pickupNearest.distanceKm;
  const destDistanceKm = destRoadKm !== null ? destRoadKm : destNearest.distanceKm;

  // Re-check the buffer using the (usually larger) real road distance —
  // this is the check that actually matters.
  if (pickupDistanceKm > CORRIDOR_BUFFER_KM) return null;
  if (destDistanceKm > CORRIDOR_BUFFER_KM) return null;

  const proximityScore = Math.max(
    0,
    1 - (pickupDistanceKm + destDistanceKm) / (2 * CORRIDOR_BUFFER_KM)
  );

  return {
    pickupDistanceKm: Number(pickupDistanceKm.toFixed(2)),
    destDistanceKm: Number(destDistanceKm.toFixed(2)),
    proximityScore: Number(proximityScore.toFixed(3)),
  };
};

module.exports = {
  getEffectiveRoute,
  matchPassengerToSession,
};
