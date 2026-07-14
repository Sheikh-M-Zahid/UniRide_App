const rideDb = require('../config/rideDb');
const ewuAdminDb = require('../config/ewuAdminDb');
const { safeDistanceKm } = require('../utils/geo');
const { computeRoute } = require('./googleMapsService');

const NEUTRAL = 0.5;
const normalizeGender = (g) => (g || '').toString().trim().toLowerCase();

const isGenderAllowed = (sessionPreferredGender, userGender) => {
  const pref = normalizeGender(sessionPreferredGender);
  if (!pref || pref === 'any') return true;
  return pref === normalizeGender(userGender);
};

const decodePolyline = (encoded) => {
  if (!encoded) return [];
  const points = [];
  let index = 0, lat = 0, lng = 0;
  while (index < encoded.length) {
    let b, shift = 0, result = 0;
    do { b = encoded.charCodeAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
    lat += (result & 1) ? ~(result >> 1) : (result >> 1);
    shift = 0; result = 0;
    do { b = encoded.charCodeAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
    lng += (result & 1) ? ~(result >> 1) : (result >> 1);
    points.push([lat / 1e5, lng / 1e5]);
  }
  return points;
};

const minDistanceToPolylineKm = (lat, lng, polylinePoints) => {
  if (!polylinePoints || !polylinePoints.length) return null;
  let min = Infinity;
  for (const [plat, plng] of polylinePoints) {
    const d = safeDistanceKm(lat, lng, plat, plng);
    if (d !== null && d < min) min = d;
  }
  return min === Infinity ? null : min;
};

const PROXIMITY_RADIUS_KM = 3;
const DEST_INCLUDE_RADIUS_KM = 1.5;
const DEST_PERFECT_MATCH_KM = 0.1;

const scoreProximity = (distKm) => {
  if (distKm == null) return 0;
  if (distKm >= PROXIMITY_RADIUS_KM) return 0;
  return 1 - distKm / PROXIMITY_RADIUS_KM;
};

const scoreDestinationMatch = (distKm) => {
  if (distKm == null) return 0;
  if (distKm <= DEST_PERFECT_MATCH_KM) return 1;
  if (distKm >= DEST_INCLUDE_RADIUS_KM) return 0;
  return 1 - (distKm - DEST_PERFECT_MATCH_KM) / (DEST_INCLUDE_RADIUS_KM - DEST_PERFECT_MATCH_KM);
};

const normalizeInverse = (values) => {
  const valid = values.filter((v) => v !== null && v !== undefined && !Number.isNaN(v));
  if (!valid.length) return values.map(() => NEUTRAL);
  const min = Math.min(...valid);
  const max = Math.max(...valid);
  if (max === min) return values.map((v) => (v === null || v === undefined ? NEUTRAL : 1));
  return values.map((v) => (v === null || v === undefined || Number.isNaN(v)) ? NEUTRAL : 1 - (v - min) / (max - min));
};

const getUserOccupation = async (universityEmail) => {
  if (!universityEmail) return null;
  const res = await ewuAdminDb.query(
    `SELECT occupation FROM ewu_users WHERE university_email = $1 LIMIT 1`, [universityEmail]
  );
  return res.rows[0]?.occupation || null;
};

const getFrequentPartners = async (userId) => {
  const res = await rideDb.query(
    `WITH my_sessions AS (
      SELECT session_id FROM company_sharing_sessions WHERE created_by = $1
      UNION
      SELECT session_id FROM company_participants WHERE user_id = $1
    )
    SELECT partner_id, COUNT(*)::int AS ride_count FROM (
      SELECT created_by AS partner_id FROM company_sharing_sessions
      WHERE session_id IN (SELECT session_id FROM my_sessions) AND created_by != $1
      UNION ALL
      SELECT user_id AS partner_id FROM company_participants
      WHERE session_id IN (SELECT session_id FROM my_sessions) AND user_id != $1
    ) partners GROUP BY partner_id ORDER BY ride_count DESC`,
    [userId]
  );
  const map = new Map();
  res.rows.forEach((row) => map.set(row.partner_id, row.ride_count));
  return map;
};

const scoreAndSortSessions = async ({ userId, userGender, userEmail, sessions }) => {
  const genderFiltered = sessions.filter((s) => isGenderAllowed(s.preferred_gender, userGender));
  const frequentPartners = await getFrequentPartners(userId);
  const myOccupation = await getUserOccupation(userEmail);
  const maxRideCount = Math.max(1, ...Array.from(frequentPartners.values(), (v) => v || 0), 0);

  const scored = await Promise.all(genderFiltered.map(async (session) => {
    const rideCount = frequentPartners.get(session.created_by) || 0;
    const frequentScore = rideCount > 0 ? rideCount / maxRideCount : 0;
    let occupationScore = NEUTRAL;
    if (myOccupation && session.university_email) {
      const creatorOccupation = await getUserOccupation(session.university_email);
      if (creatorOccupation) occupationScore = creatorOccupation === myOccupation ? 1 : 0.2;
    }
    const finalScore = Number((frequentScore * 0.6 + occupationScore * 0.4).toFixed(3));
    return { ...session, coRideScore: finalScore, isFrequentPartner: rideCount > 0 };
  }));

  scored.sort((a, b) => b.coRideScore - a.coRideScore);
  return scored;
};

const searchMatchingSessions = async ({
  userId, userGender, userEmail, pickupLat, pickupLng, destLat, destLng, sessions,
}) => {
  const genderFiltered = sessions.filter((s) => isGenderAllowed(s.preferred_gender, userGender));
  const corridorCandidates = [];

  for (const session of genderFiltered) {
    const polylinePoints = decodePolyline(session.route_polyline);

    let pickupDistanceKm = polylinePoints.length ? minDistanceToPolylineKm(pickupLat, pickupLng, polylinePoints) : null;
    if (pickupDistanceKm === null && session.start_lat && session.start_lng) {
      pickupDistanceKm = safeDistanceKm(pickupLat, pickupLng, Number(session.start_lat), Number(session.start_lng));
    }

    let destDistanceKm = polylinePoints.length ? minDistanceToPolylineKm(destLat, destLng, polylinePoints) : null;
    if (destDistanceKm === null && session.destination_lat && session.destination_lng) {
      destDistanceKm = safeDistanceKm(destLat, destLng, Number(session.destination_lat), Number(session.destination_lng));
    }

    if (pickupDistanceKm === null || pickupDistanceKm > PROXIMITY_RADIUS_KM) continue;
    if (destDistanceKm === null || destDistanceKm > DEST_INCLUDE_RADIUS_KM) continue;

    corridorCandidates.push({ session, pickupDistanceKm, destDistanceKm });
  }

  if (!corridorCandidates.length) return [];

  const trafficResults = await Promise.all(corridorCandidates.map(async ({ session }) => {
    if (!session.start_lat || !session.start_lng || !session.destination_lat || !session.destination_lng) return null;
    try {
      const route = await computeRoute({
        originLat: Number(session.start_lat), originLng: Number(session.start_lng),
        destinationLat: Number(session.destination_lat), destinationLng: Number(session.destination_lng),
      });
      const km = Math.max(route.distanceKm, 0.1);
      return route.durationMinutes / km;
    } catch (err) { return null; }
  }));
  const congestionScores = normalizeInverse(trafficResults);

  const fares = corridorCandidates.map((c) => {
    const f = Number(c.session.fare_per_person);
    return Number.isFinite(f) ? f : null;
  });
  const fareScores = normalizeInverse(fares);

  const frequentPartners = await getFrequentPartners(userId);
  const myOccupation = await getUserOccupation(userEmail);
  const maxRideCount = Math.max(1, ...Array.from(frequentPartners.values(), (v) => v || 0), 0);

  const results = await Promise.all(corridorCandidates.map(async ({ session, pickupDistanceKm, destDistanceKm }, i) => {
    const proximityScore = scoreProximity(pickupDistanceKm);
    const destinationScore = scoreDestinationMatch(destDistanceKm);
    const trafficScore = congestionScores[i];
    const fareScore = fareScores[i];
    const rideCount = frequentPartners.get(session.created_by) || 0;
    const frequentScore = rideCount > 0 ? rideCount / maxRideCount : 0;

    let occupationScore = NEUTRAL;
    if (myOccupation && session.university_email) {
      const creatorOccupation = await getUserOccupation(session.university_email);
      if (creatorOccupation) occupationScore = creatorOccupation === myOccupation ? 1 : 0.2;
    }

    const finalScore = Number((
      proximityScore * 0.35 +
      destinationScore * 0.3 +
      trafficScore * 0.2 +
      fareScore * 0.1 +
      (frequentScore * 0.6 + occupationScore * 0.4) * 0.05
    ).toFixed(4));

    return {
      ...session,
      coRideScore: finalScore,
      isFrequentPartner: rideCount > 0,
      pickupDistanceKm: pickupDistanceKm !== null ? Number(pickupDistanceKm.toFixed(2)) : null,
      destDistanceKm: destDistanceKm !== null ? Number(destDistanceKm.toFixed(2)) : null,
    };
  }));

  results.sort((a, b) => b.coRideScore - a.coRideScore);
  return results.map((r, idx) => ({ ...r, rank: idx + 1, isTopRecommendation: idx < 2 }));
};

module.exports = {
  isGenderAllowed, getFrequentPartners, getUserOccupation,
  scoreAndSortSessions, searchMatchingSessions,
};
