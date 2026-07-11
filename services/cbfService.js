const rideDb = require('../config/rideDb');
const { buildRouteHash } = require('../utils/routeHash');
const { classifyTimeSlot } = require('../utils/timeSlot');

const NEUTRAL_SCORE = 0.5;

// Retrieve the user's profile from the user_preferences table.
// If the profile is incomplete, fill in the missing fields using the user's ride history.
const buildUserProfile = async (userId) => {
  if (!userId) return null;

  const storedRes = await rideDb.query(
    `SELECT * FROM user_preferences WHERE user_id = $1`,
    [userId]
  );
  const stored = storedRes.rows[0] || null;

  const historyRes = await rideDb.query(
    `SELECT
        r.vehicle_type,
        rp.fare,
        r.travel_time,
        r.pickup_latitude,
        r.pickup_longitude,
        r.destination_latitude,
        r.destination_longitude
     FROM ride_participants rp
     JOIN rides r ON rp.ride_id = r.ride_id
     WHERE rp.passenger_id = $1
       AND rp.confirmed = TRUE
     ORDER BY rp.created_at DESC
     LIMIT 30`,
    [userId]
  );
  const history = historyRes.rows;

  if (!stored && !history.length) {
    return null; // Completely new user (cold start) — a neutral score will be assigned.
  }

  // ── vehicle preference ──
  let preferredVehicles = [];
  if (stored?.preferred_vehicles) {
    try { preferredVehicles = JSON.parse(stored.preferred_vehicles); } catch (_) {}
  }
  if (!preferredVehicles.length && history.length) {
    const counts = {};
    history.forEach((h) => {
      const v = String(h.vehicle_type || '').toLowerCase();
      if (v) counts[v] = (counts[v] || 0) + 1;
    });
    preferredVehicles = Object.keys(counts).sort((a, b) => counts[b] - counts[a]);
  }

  // ── fare range ──
  let fareMin = stored ? Number(stored.avg_fare_range_min) : null;
  let fareMax = stored ? Number(stored.avg_fare_range_max) : null;
  if ((fareMin == null || fareMax == null || Number.isNaN(fareMin)) && history.length) {
    const fares = history.map((h) => Number(h.fare || 0)).filter((f) => f > 0);
    if (fares.length) {
      const avg = fares.reduce((a, b) => a + b, 0) / fares.length;
      fareMin = avg * 0.7;
      fareMax = avg * 1.3;
    }
  }

  // ── time slot preference ──
  let preferredTimeSlots = [];
  if (stored?.preferred_time_slots) {
    try { preferredTimeSlots = JSON.parse(stored.preferred_time_slots); } catch (_) {}
  }
  if (!preferredTimeSlots.length && history.length) {
    const counts = {};
    history.forEach((h) => {
      const slot = classifyTimeSlot(h.travel_time);
      counts[slot] = (counts[slot] || 0) + 1;
    });
    preferredTimeSlots = Object.keys(counts).sort((a, b) => counts[b] - counts[a]);
  }

  // ── frequent routes ──
  let frequentRoutes = [];
  if (stored?.frequent_routes) {
    try { frequentRoutes = JSON.parse(stored.frequent_routes); } catch (_) {}
  }
  if (!frequentRoutes.length && history.length) {
    const hashes = history
      .filter((h) => h.pickup_latitude && h.destination_latitude)
      .map((h) =>
        buildRouteHash(h.pickup_latitude, h.pickup_longitude, h.destination_latitude, h.destination_longitude)
      );
    frequentRoutes = [...new Set(hashes)];
  }

  return { preferredVehicles, fareMin, fareMax, preferredTimeSlots, frequentRoutes };
};

// Match a ride against the user's profile and assign a compatibility score between 0 and 1.
const scoreRide = (profile, ride) => {
  if (!profile) return NEUTRAL_SCORE;

  const vehicleType = String(ride.vehicle_type || '').toLowerCase();
  const vehicleScore = profile.preferredVehicles.length
    ? (profile.preferredVehicles.includes(vehicleType) ? 1 : 0.3)
    : NEUTRAL_SCORE;

  let fareScore = NEUTRAL_SCORE;
  if (profile.fareMin != null && profile.fareMax != null && !Number.isNaN(profile.fareMin)) {
    const fare = Number(ride.estimatedFare || 0);
    if (fare >= profile.fareMin && fare <= profile.fareMax) {
      fareScore = 1;
    } else {
      const mid = (profile.fareMin + profile.fareMax) / 2;
      const span = (profile.fareMax - profile.fareMin) / 2 || mid || 1;
      const diff = Math.abs(fare - mid) / span;
      fareScore = Math.max(0, 1 - diff * 0.5);
    }
  }

  const timeSlot = classifyTimeSlot(ride.travel_time);
  const timeScore = profile.preferredTimeSlots.length
    ? (profile.preferredTimeSlots.includes(timeSlot) ? 1 : 0.4)
    : NEUTRAL_SCORE;

  const routeScore = ride._routeHash && profile.frequentRoutes.includes(ride._routeHash)
    ? 1
    : (profile.frequentRoutes.length ? 0.4 : NEUTRAL_SCORE);

  return Number((vehicleScore * 0.3 + fareScore * 0.3 + timeScore * 0.2 + routeScore * 0.2).toFixed(3));
};

// Update the passenger's preferences after a ride is completed
// using a running blend (incremental averaging) approach.
const updateUserPreferencesFromRide = async ({
  userId, vehicleType, fare, travelTime, pickupLat, pickupLng, destLat, destLng,
}) => {
  if (!userId) return;

  const existingRes = await rideDb.query(`SELECT * FROM user_preferences WHERE user_id = $1`, [userId]);
  const existing = existingRes.rows[0] || null;

  let preferredVehicles = [];
  try { preferredVehicles = existing?.preferred_vehicles ? JSON.parse(existing.preferred_vehicles) : []; } catch (_) {}
  const vType = String(vehicleType || '').toLowerCase();
  if (vType) {
    preferredVehicles = [vType, ...preferredVehicles.filter((v) => v !== vType)].slice(0, 3);
  }

  const currentMin = existing ? Number(existing.avg_fare_range_min) : null;
  const currentMax = existing ? Number(existing.avg_fare_range_max) : null;
  const fareNum = Number(fare || 0);
  let newMin = currentMin;
  let newMax = currentMax;
  if (fareNum > 0) {
    if (currentMin == null || currentMax == null || Number.isNaN(currentMin)) {
      newMin = fareNum * 0.7;
      newMax = fareNum * 1.3;
    } else {
      const currentMid = (currentMin + currentMax) / 2;
      const blendedMid = currentMid * 0.8 + fareNum * 0.2; // নতুন ride এর প্রভাব ২০%
      newMin = blendedMid * 0.7;
      newMax = blendedMid * 1.3;
    }
  }

  let preferredTimeSlots = [];
  try { preferredTimeSlots = existing?.preferred_time_slots ? JSON.parse(existing.preferred_time_slots) : []; } catch (_) {}
  const slot = classifyTimeSlot(travelTime);
  if (slot) {
    preferredTimeSlots = [slot, ...preferredTimeSlots.filter((s) => s !== slot)].slice(0, 3);
  }

  let frequentRoutes = [];
  try { frequentRoutes = existing?.frequent_routes ? JSON.parse(existing.frequent_routes) : []; } catch (_) {}
  if (pickupLat && destLat) {
    const hash = buildRouteHash(pickupLat, pickupLng, destLat, destLng);
    frequentRoutes = [hash, ...frequentRoutes.filter((h) => h !== hash)].slice(0, 5);
  }

  await rideDb.query(
    `INSERT INTO user_preferences (
        user_id, preferred_vehicles, avg_fare_range_min, avg_fare_range_max,
        preferred_time_slots, frequent_routes, updated_at
     )
     VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
     ON CONFLICT (user_id)
     DO UPDATE SET
        preferred_vehicles = EXCLUDED.preferred_vehicles,
        avg_fare_range_min = EXCLUDED.avg_fare_range_min,
        avg_fare_range_max = EXCLUDED.avg_fare_range_max,
        preferred_time_slots = EXCLUDED.preferred_time_slots,
        frequent_routes = EXCLUDED.frequent_routes,
        updated_at = CURRENT_TIMESTAMP`,
    [userId, JSON.stringify(preferredVehicles), newMin, newMax, JSON.stringify(preferredTimeSlots), JSON.stringify(frequentRoutes)]
  );
};

// Attach a CBF (Content-Based Filtering) score to each ride in the searchRides list,
// then sort the rides in descending order based on their CBF scores.
const scoreAndSortRides = async ({ passengerId, rides, pickupLat, pickupLng, destLat, destLng }) => {
  const profile = await buildUserProfile(passengerId);
  const routeHash = (pickupLat && destLat) ? buildRouteHash(pickupLat, pickupLng, destLat, destLng) : null;

  const scored = rides.map((ride) => {
    const cbfScore = scoreRide(profile, { ...ride, _routeHash: routeHash });
    return { ...ride, cbfScore };
  });

  scored.sort((a, b) => b.cbfScore - a.cbfScore);
  return scored;
};

module.exports = {
  buildUserProfile,
  scoreRide,
  updateUserPreferencesFromRide,
  scoreAndSortRides,
};
