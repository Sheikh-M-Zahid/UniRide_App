const rideDb = require('../config/rideDb');
const ewuAdminDb = require('../config/ewuAdminDb');
const { matchPassengerToSession } = require('./coRideRouteMatchingService');

const NEUTRAL = 0.5;

const normalizeGender = (g) => (g || '').toString().trim().toLowerCase();

// Hard filter — must never be violated
const isGenderAllowed = (sessionPreferredGender, userGender) => {
  const pref = normalizeGender(sessionPreferredGender);
  if (!pref || pref === 'any') return true;
  return pref === normalizeGender(userGender);
};

const getUserOccupation = async (universityEmail) => {
  if (!universityEmail) return null;
  const res = await ewuAdminDb.query(
    `SELECT occupation FROM ewu_users WHERE university_email = $1 LIMIT 1`,
    [universityEmail]
  );
  return res.rows[0]?.occupation || null;
};

// Users that the target user has previously shared a CoRide with (as the creator or a co-participant)
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

// Score all sessions and sort them in descending order (with the gender hard filter applied)
const scoreAndSortSessions = async ({ userId, userGender, userEmail, sessions }) => {
  const genderFiltered = sessions.filter((s) =>
    isGenderAllowed(s.preferred_gender, userGender)
  );

  const frequentPartners = await getFrequentPartners(userId);
  const myOccupation = await getUserOccupation(userEmail);
  const maxRideCount = Math.max(1, ...Array.from(frequentPartners.values(), (v) => v || 0), 0);

  const scored = await Promise.all(
    genderFiltered.map(async (session) => {
      const creatorId = session.created_by;

      //1. Highest priority: frequent co-rider
      const rideCount = frequentPartners.get(creatorId) || 0;
      const frequentScore = rideCount > 0 ? rideCount / maxRideCount : 0;

      //২. occupation match (student-student / faculty-faculty)
      let occupationScore = NEUTRAL;
      if (myOccupation && session.university_email) {
        const creatorOccupation = await getUserOccupation(session.university_email);
        if (creatorOccupation) {
          occupationScore = creatorOccupation === myOccupation ? 1 : 0.2;
        }
      }

      const finalScore = Number(
        (frequentScore * 0.6 + occupationScore * 0.4).toFixed(3)
      );

      return {
        ...session,
        coRideScore: finalScore,
        isFrequentPartner: rideCount > 0,
      };
    })
  );

  scored.sort((a, b) => b.coRideScore - a.coRideScore);
  return scored;
};

// Passenger search: ranked list based on gender, route corridor, occupation, and frequent partners
const searchMatchingSessions = async ({
  userId, userGender, userEmail,
  pickupLat, pickupLng, destLat, destLng,
  sessions,
}) => {
  const genderFiltered = sessions.filter((s) =>
    isGenderAllowed(s.preferred_gender, userGender)
  );

  const frequentPartners = await getFrequentPartners(userId);
  const myOccupation = await getUserOccupation(userEmail);
  const maxRideCount = Math.max(1, ...Array.from(frequentPartners.values(), (v) => v || 0), 0);

  const results = [];

  for (const session of genderFiltered) {
    const corridorMatch = await matchPassengerToSession({
      session, pickupLat, pickupLng, destLat, destLng,
    });
    if (!corridorMatch) continue; // route-এ না পড়লে বাদ

    const rideCount = frequentPartners.get(session.created_by) || 0;
    const frequentScore = rideCount > 0 ? rideCount / maxRideCount : 0;

    let occupationScore = NEUTRAL;
    if (myOccupation && session.university_email) {
      const creatorOccupation = await getUserOccupation(session.university_email);
      if (creatorOccupation) {
        occupationScore = creatorOccupation === myOccupation ? 1 : 0.2;
      }
    }

    const finalScore = Number(
      (
        corridorMatch.proximityScore * 0.4 +
        frequentScore * 0.35 +
        occupationScore * 0.25
      ).toFixed(3)
    );

    results.push({
      ...session,
      coRideScore: finalScore,
      isFrequentPartner: rideCount > 0,
      pickupDistanceKm: corridorMatch.pickupDistanceKm,
      destDistanceKm: corridorMatch.destDistanceKm,
    });
  }

  results.sort((a, b) => b.coRideScore - a.coRideScore);
  return results;
};

module.exports = {
  isGenderAllowed,
  getFrequentPartners,
  getUserOccupation,
  scoreAndSortSessions,
  searchMatchingSessions,
};
