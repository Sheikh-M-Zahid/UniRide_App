const rideDb = require('../config/rideDb');
const ewuAdminDb = require('../config/ewuAdminDb');
const { matchPassengerToSession } = require('./coRideRouteMatchingService');
const { computeRoute } = require('./googleMapsService');

const NEUTRAL = 0.5;
const normalizeGender = (g) => (g || '').toString().trim().toLowerCase();

// ---- hard filter (unchanged) ----
const isGenderAllowed = (sessionPreferredGender, userGender) => {
  const pref = normalizeGender(sessionPreferredGender);
  if (!pref || pref === 'any') return true;
  return pref === normalizeGender(userGender);
};

// matchPassengerToSession() ইতিমধ্যে CORRIDOR_BUFFER_KM (1.2km) হার্ড-ফিল্টার এনফোর্স করে,
// তাই এখানে সেই একই ব্যান্ডের ভেতরে স্কোর curve বানানো হচ্ছে — সামঞ্জস্যপূর্ণ রাখার জন্য।
const CORRIDOR_BUFFER_KM = 1.2;
const DEST_PERFECT_MATCH_KM = 0.1; // ১০০ মিটার = "সরাসরি ওখানেই যাচ্ছে"

const scoreProximity = (distKm) => {
  if (distKm == null) return 0;
  if (distKm >= CORRIDOR_BUFFER_KM) return 0;
  return 1 - distKm / CORRIDOR_BUFFER_KM;
};

const scoreDestinationMatch = (distKm) => {
  if (distKm == null) return 0;
  if (distKm <= DEST_PERFECT_MATCH_KM) return 1;
  if (distKm >= CORRIDOR_BUFFER_KM) return 0;
  return 1 - (distKm - DEST_PERFECT_MATCH_KM) / (CORRIDOR_BUFFER_KM - DEST_PERFECT_MATCH_KM);
};

// একাধিক candidate-এর raw মান 0..1 এ নরমালাইজ করে, যেখানে কম raw মান বেশি স্কোর পায়
// (traffic congestion index এবং fare — দুটোতেই "কম ভালো")
const normalizeInverse = (values) => {
  const valid = values.filter((v) => v !== null && v !== undefined && !Number.isNaN(v));
  if (!valid.length) return values.map(() => NEUTRAL);

  const min = Math.min(...valid);
  const max = Math.max(...valid);

  if (max === min) return values.map((v) => (v === null || v === undefined ? NEUTRAL : 1));

  return values.map((v) =>
    v === null || v === undefined || Number.isNaN(v) ? NEUTRAL : 1 - (v - min) / (max - min)
  );
};

// লাইভ জ্যাম-ইনডেক্স: journey শুরু হয়ে থাকলে (is_started + current_lat/lng) current
// location থেকে destination পর্যন্ত ফ্রেশ TRAFFIC_AWARE রুট নেয়; নাহলে start_location
// থেকে destination পর্যন্ত। durationMinutes/distanceKm = মিনিট-প্রতি-কিমি (কম = কম জ্যাম)।
const getCongestionIndex = async (session) => {
  const isLive = session.is_started === true && session.current_lat && session.current_lng;
  const originLat = isLive ? Number(session.current_lat) : Number(session.start_lat);
  const originLng = isLive ? Number(session.current_lng) : Number(session.start_lng);

  if (!originLat || !originLng || !session.destination_lat || !session.destination_lng) {
    return null;
  }

  try {
    const route = await computeRoute({
      originLat,
      originLng,
      destinationLat: Number(session.destination_lat),
      destinationLng: Number(session.destination_lng),
    });
    const km = Math.max(route.distanceKm, 0.1);
    return route.durationMinutes / km;
  } catch (_) {
    return null; // Maps API ব্যর্থ হলে neutral score পড়ে (normalizeInverse হ্যান্ডেল করে)
  }
};

// ---- occupation / frequent-partner helpers (unchanged) ----
const getUserOccupation = async (universityEmail) => {
  if (!universityEmail) return null;
  const res = await ewuAdminDb.query(
    `SELECT occupation FROM ewu_users WHERE university_email = $1 LIMIT 1`,
    [universityEmail]
  );
  return res.rows[0]?.occupation || null;
};

const getFrequentPartners = async (userId) => {
  const res = await rideDb.query(
    `
    WITH my_sessions AS (
      SELECT session_id FROM company_sharing_sessions WHERE created_by = $1
      UNION
      SELECT session_id FROM company_participants WHERE user_id = $1
    )
    SELECT partner_id, COUNT(*)::int AS ride_count FROM (
      SELECT created_by AS partner_id
      FROM company_sharing_sessions
      WHERE session_id IN (SELECT session_id FROM my_sessions)
        AND created_by != $1
      UNION ALL
      SELECT user_id AS partner_id
      FROM company_participants
      WHERE session_id IN (SELECT session_id FROM my_sessions)
        AND user_id != $1
    ) partners
    GROUP BY partner_id
    ORDER BY ride_count DESC
    `,
    [userId]
  );

  const map = new Map();
  res.rows.forEach((row) => map.set(row.partner_id, row.ride_count));
  return map;
};

// Used by listSessions (general feed, not the corridor search)
const scoreAndSortSessions = async ({ userId, userGender, userEmail, sessions }) => {
  const genderFiltered = sessions.filter((s) => isGenderAllowed(s.preferred_gender, userGender));

  const frequentPartners = await getFrequentPartners(userId);
  const myOccupation = await getUserOccupation(userEmail);
  const maxRideCount = Math.max(1, ...Array.from(frequentPartners.values(), (v) => v || 0), 0);

  const scored = await Promise.all(
    genderFiltered.map(async (session) => {
      const rideCount = frequentPartners.get(session.created_by) || 0;
      const frequentScore = rideCount > 0 ? rideCount / maxRideCount : 0;

      let occupationScore = NEUTRAL;
      if (myOccupation && session.university_email) {
        const creatorOccupation = await getUserOccupation(session.university_email);
        if (creatorOccupation) {
          occupationScore = creatorOccupation === myOccupation ? 1 : 0.2;
        }
      }

      const finalScore = Number((frequentScore * 0.6 + occupationScore * 0.4).toFixed(3));

      return { ...session, coRideScore: finalScore, isFrequentPartner: rideCount > 0 };
    })
  );

  scored.sort((a, b) => b.coRideScore - a.coRideScore);
  return scored;
};

// ---- MAIN: passenger search ranking ----
// অগ্রাধিকার: proximity (pickup) > destination match > traffic > fare
const searchMatchingSessions = async ({
  userId,
  userGender,
  userEmail,
  pickupLat,
  pickupLng,
  destLat,
  destLng,
  sessions,
}) => {
  const genderFiltered = sessions.filter((s) => isGenderAllowed(s.preferred_gender, userGender));

  // Step 1 & 2: করিডোর ম্যাচ (proximity + direction + live-route — matchPassengerToSession-এ হ্যান্ডেল হয়)
  const corridorCandidates = [];
  for (const session of genderFiltered) {
    const match = await matchPassengerToSession({ session, pickupLat, pickupLng, destLat, destLng });
    if (!match) continue; // করিডোরের বাইরে বা ভুল দিকে হলে বাদ
    corridorCandidates.push({ session, ...match });
  }

  if (!corridorCandidates.length) return [];

  // Step 3: জ্যাম-ইনডেক্স (fresh, traffic-aware)
  const trafficResults = await Promise.all(
    corridorCandidates.map(({ session }) => getCongestionIndex(session))
  );
  const congestionScores = normalizeInverse(trafficResults);

  // Step 4: ভাড়া (কম = ভালো)
  const fares = corridorCandidates.map((c) => {
    const f = Number(c.session.fare_per_person);
    return Number.isFinite(f) ? f : null;
  });
  const fareScores = normalizeInverse(fares);

  // Soft tie-breakers (ছোট ওজন)
  const frequentPartners = await getFrequentPartners(userId);
  const myOccupation = await getUserOccupation(userEmail);
  const maxRideCount = Math.max(1, ...Array.from(frequentPartners.values(), (v) => v || 0), 0);

  const results = await Promise.all(
    corridorCandidates.map(async ({ session, pickupDistanceKm, destDistanceKm }, i) => {
      const proximityScore = scoreProximity(pickupDistanceKm);
      const destinationScore = scoreDestinationMatch(destDistanceKm);
      const trafficScore = congestionScores[i];
      const fareScore = fareScores[i];

      const rideCount = frequentPartners.get(session.created_by) || 0;
      const frequentScore = rideCount > 0 ? rideCount / maxRideCount : 0;

      let occupationScore = NEUTRAL;
      if (myOccupation && session.university_email) {
        const creatorOccupation = await getUserOccupation(session.university_email);
        if (creatorOccupation) {
          occupationScore = creatorOccupation === myOccupation ? 1 : 0.2;
        }
      }

      // অগ্রাধিকার-ভিত্তিক ওজনযুক্ত composite score
      const finalScore = Number(
        (
          proximityScore * 0.35 +
          destinationScore * 0.3 +
          trafficScore * 0.2 +
          fareScore * 0.1 +
          (frequentScore * 0.6 + occupationScore * 0.4) * 0.05
        ).toFixed(4)
      );

      return {
        ...session,
        coRideScore: finalScore,
        isFrequentPartner: rideCount > 0,
        pickupDistanceKm,
        destDistanceKm,
      };
    })
  );

  results.sort((a, b) => b.coRideScore - a.coRideScore);

  return results.map((r, idx) => ({
    ...r,
    rank: idx + 1,
    isTopRecommendation: idx < 2, // সেরা ১-২ টা হাইলাইট করার জন্য
  }));
};

module.exports = {
  isGenderAllowed,
  getFrequentPartners,
  getUserOccupation,
  scoreAndSortSessions,
  searchMatchingSessions,
};
