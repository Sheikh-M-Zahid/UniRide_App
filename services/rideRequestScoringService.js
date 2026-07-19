// services/rideRequestScoringService.js
const rideDb = require('../config/rideDb');
const { decodePolyline } = require('../utils/polyline');
const { nearestPointOnRoute, cumulativeDistanceKm } = require('../utils/routeCorridor');
const { safeDistanceKm } = require('../utils/geo');

// rideService.js এর searchRides()-এ যে corridor buffer ব্যবহার হয় সেটার সাথে সামঞ্জস্যপূর্ণ রাখা হয়েছে
const CORRIDOR_BUFFER_KM = 0.3;
const MAX_REASONABLE_DETOUR_KM = 3;

const scoreDestinationProximity = (destDistanceKm) => {
  if (destDistanceKm == null) return 0.5; // route polyline না থাকলে neutral
  if (destDistanceKm >= CORRIDOR_BUFFER_KM) return 0;
  return 1 - destDistanceKm / CORRIDOR_BUFFER_KM;
};

const scorePickupProximity = (pickupDistanceKm) => {
  if (pickupDistanceKm == null) return 0.5;
  const capped = Math.min(pickupDistanceKm, 2);
  return Math.max(0, 1 - capped / 2);
};

const scoreDetour = (extraKm) => {
  if (extraKm == null) return 0.5;
  if (extraKm <= 0) return 1;
  if (extraKm >= MAX_REASONABLE_DETOUR_KM) return 0;
  return 1 - extraKm / MAX_REASONABLE_DETOUR_KM;
};

// এই rider-এর সাথে এই passenger আগে কতবার গিয়েছে — trusted/frequent passenger সনাক্ত করতে
const getTrustScore = async (riderId, passengerId) => {
  const res = await rideDb.query(
    `SELECT COUNT(*)::int AS cnt
     FROM rides r
     JOIN ride_participants rp ON rp.ride_id = r.ride_id
     WHERE r.rider_id = $1
       AND rp.passenger_id = $2
       AND rp.confirmed = TRUE`,
    [riderId, passengerId]
  );
  const count = res.rows[0]?.cnt || 0;
  return { rideCount: count, score: Math.min(1, count / 5) };
};

// Route polyline-এর উপর candidate-এর pickup ও destination projection করে
// আনুমানিক অতিরিক্ত দূরত্ব বের করে (real-time Google Directions কল না করেই — সস্তা, দ্রুত)
const estimateDetourKm = (routePoints, pickupLat, pickupLng, destLat, destLng) => {
  if (!routePoints.length) return null;

  const pickupMatch = nearestPointOnRoute(routePoints, pickupLat, pickupLng);
  const destMatch = nearestPointOnRoute(routePoints, destLat, destLng);

  if (destMatch.index < pickupMatch.index) {
    return MAX_REASONABLE_DETOUR_KM; // route-এর উল্টো দিকে — ভারী penalty
  }

  return cumulativeDistanceKm(routePoints, pickupMatch.index, destMatch.index);
};

// একটা pending request-কে score করে — ride = rider-এর active ride row, request = ride_requests row
const scoreRequest = async ({ ride, request }) => {
  const routePoints = ride.route_polyline ? decodePolyline(ride.route_polyline) : [];

  const pickupDistanceKm = safeDistanceKm(
    Number(ride.pickup_latitude ?? ride.start_latitude ?? 0),
    Number(ride.pickup_longitude ?? ride.start_longitude ?? 0),
    Number(request.pickup_latitude ?? 0),
    Number(request.pickup_longitude ?? 0)
  );

  let destDistanceKm = null;
  let detourKm = null;

  if (routePoints.length) {
    const destMatch = nearestPointOnRoute(
      routePoints,
      Number(request.destination_latitude ?? 0),
      Number(request.destination_longitude ?? 0)
    );
    destDistanceKm = destMatch.distanceKm;

    detourKm = estimateDetourKm(
      routePoints,
      Number(request.pickup_latitude ?? 0),
      Number(request.pickup_longitude ?? 0),
      Number(request.destination_latitude ?? 0),
      Number(request.destination_longitude ?? 0)
    );
  }

  const trust = await getTrustScore(ride.rider_id, request.passenger_id);

  const destScore = scoreDestinationProximity(destDistanceKm);
  const pickupScore = scorePickupProximity(pickupDistanceKm);
  const detourScore = scoreDetour(detourKm);

  const finalScore = Number(
    (
      destScore * 0.35 +
      detourScore * 0.25 +
      pickupScore * 0.15 +
      trust.score * 0.15 +
      0.5 * 0.10 // context_score — আপাতত neutral, পরে rush-hour/weather যোগ করা যাবে
    ).toFixed(4)
  );

  let tier = null;
  if (finalScore >= 0.75) tier = 'best';
  else if (finalScore >= 0.55) tier = 'good';

  return {
    score: finalScore,
    tier, // 'best' | 'good' | null
    destDistanceKm: destDistanceKm != null ? Number(destDistanceKm.toFixed(2)) : null,
    pickupDistanceKm: pickupDistanceKm != null ? Number(pickupDistanceKm.toFixed(2)) : null,
    detourKm: detourKm != null ? Number(detourKm.toFixed(2)) : null,
    isFrequentPassenger: trust.rideCount > 0,
    frequentRideCount: trust.rideCount,
  };
};

module.exports = { scoreRequest };
