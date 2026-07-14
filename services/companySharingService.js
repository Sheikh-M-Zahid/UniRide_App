const rideDb = require('../config/rideDb');
const { createNotification } = require('./notificationService');
const { emitCoRideSeatUpdate } = require('../utils/coRideEmitter');
const coRideRecommendationService = require('./coRideRecommendationService');
const { computeRoute } = require('./googleMapsService');
const { safeDistanceKm } = require('../utils/geo');

const NOTIFY_RADIUS_KM = 2;

const createSession = async (userId, payload) => {
  const {
    start_location,
    destination,
    status,
    trip_date,
    trip_time,
    vehicle_type,
    vehicle_number,
    total_seats,
    preferred_gender,
    fare_per_person,
    start_lat,
    start_lng,
    destination_lat,
    destination_lng,
  } = payload;

  // ── route polyline compute করো (lat/lng থাকলে) ──
  let routePolyline = null;
  let routeDistanceKm = null;
  let routeDurationMinutes = null;

  if (start_lat && start_lng && destination_lat && destination_lng) {
    try {
      const route = await computeRoute({
        originLat: start_lat,
        originLng: start_lng,
        destinationLat: destination_lat,
        destinationLng: destination_lng,
      });
      routePolyline = route.polyline;
      routeDistanceKm = route.distanceKm;
      routeDurationMinutes = route.durationMinutes;
    } catch (err) {
      console.error('CoRide route compute failed:', err.message);
    }
  }

  const result = await rideDb.query(
    `INSERT INTO company_sharing_sessions 
      (created_by, start_location, destination, status,
       trip_date, trip_time, vehicle_type, vehicle_number,
       total_seats, booked_seats, preferred_gender, fare_per_person,
       start_lat, start_lng, destination_lat, destination_lng,
       route_polyline, route_distance_km, route_duration_minutes)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,0,$10,$11,$12,$13,$14,$15,$16,$17,$18)
     RETURNING *`,
    [
      userId,
      start_location,
      destination,
      status || 'Active',
      trip_date || null,
      trip_time || null,
      vehicle_type || null,
      vehicle_number || null,
      total_seats || 2,
      preferred_gender || 'Any',
      fare_per_person || null,
      start_lat || null,
      start_lng || null,
      destination_lat || null,
      destination_lng || null,
      routePolyline,
      routeDistanceKm,
      routeDurationMinutes,
    ]
  );

  const session = result.rows[0];

  // ── Radius-based notification (২ কিমি এর মধ্যে home_location থাকা user) ──
  let userQuery = `
    SELECT user_id, first_name, last_name, gender, home_location_lat, home_location_lng
    FROM users
    WHERE user_id != $1
  `;
  const params = [userId];

  if (preferred_gender && preferred_gender.toLowerCase() !== 'any') {
    userQuery += ` AND LOWER(gender) = LOWER($2)`;
    params.push(preferred_gender);
  }

  const users = await rideDb.query(userQuery, params);

  const creatorResult = await rideDb.query(
    `SELECT first_name, last_name FROM users WHERE user_id = $1`,
    [userId]
  );
  const creator = creatorResult.rows[0];
  const creatorName = `${creator.first_name} ${creator.last_name}`;

  const nearbyUsers = (start_lat && start_lng)
    ? users.rows.filter((u) => {
        if (!u.home_location_lat || !u.home_location_lng) return true; // location অজানা হলে fallback হিসেবে পাঠাও
        const dist = safeDistanceKm(
          Number(start_lat), Number(start_lng),
          Number(u.home_location_lat), Number(u.home_location_lng)
        );
        return dist === null || dist <= NOTIFY_RADIUS_KM;
      })
    : users.rows;

  for (const user of nearbyUsers) {
    await createNotification({
      userId: user.user_id,
      title: 'New CoRide Available!',
      message: `${creatorName} is looking for co-riders from ${start_location} to ${destination}. Fare: ৳${fare_per_person || 'N/A'} per person.`,
      type: 'co_ride',
      isImportant: false,
      targetRole: 'passenger',
      relatedId: String(session.session_id || session.id),
    });
  }

  return session;
};

const getSessionById = async (sessionId) => {
  const result = await rideDb.query(
    `SELECT css.*, 
            u.first_name, u.last_name, u.phone
     FROM company_sharing_sessions css
     JOIN users u ON css.created_by = u.user_id
     WHERE css.session_id = $1`,
    [sessionId]
  );

  if (result.rowCount === 0) throw new Error('Session not found.');
  return result.rows[0];
};

const getMyActiveSession = async (userId) => {
  const result = await rideDb.query(
    `SELECT * FROM company_sharing_sessions
     WHERE created_by = $1 AND status = 'Active'
     ORDER BY created_at DESC
     LIMIT 1`,
    [userId]
  );

  return result.rows[0] || null;
};

const joinSession = async (sessionId, userId) => {
  // Already joined check
  const existing = await rideDb.query(
    `SELECT id FROM company_participants WHERE session_id = $1 AND user_id = $2`,
    [sessionId, userId]
  );
  if (existing.rowCount > 0) throw new Error('Already joined this session.');

  // Session block check
  const sessionResult = await rideDb.query(
    `SELECT * FROM company_sharing_sessions WHERE session_id = $1`,
    [sessionId]
  );
  if (sessionResult.rowCount === 0) throw new Error('Session not found.');

  const session = sessionResult.rows[0];
  const availableSeats = session.total_seats - session.booked_seats;
  if (availableSeats <= 0) throw new Error('No seats available.');

  // ── Gender safety check (নতুন) ──
  const joiningUserRes = await rideDb.query(
    `SELECT gender FROM users WHERE user_id = $1`,
    [userId]
  );
  const joiningUserGender = joiningUserRes.rows[0]?.gender;
  if (!coRideRecommendationService.isGenderAllowed(session.preferred_gender, joiningUserGender)) {
    throw new Error(`This CoRide is only open to ${session.preferred_gender} riders.`);
  }

  // Join
  const participant = await rideDb.query(
    `INSERT INTO company_participants (session_id, user_id, confirmed)
     VALUES ($1, $2, TRUE)
     RETURNING *`,
    [sessionId, userId]
  );

  // Seat decrement
  await rideDb.query(
    `UPDATE company_sharing_sessions
     SET booked_seats = booked_seats + 1
     WHERE session_id = $1`,
    [sessionId]
  );

  // Updated seat count emit (socket)
  const updatedSeats = availableSeats - 1;
  emitCoRideSeatUpdate(sessionId, updatedSeats);

  // Booker info fetch
  const bookerResult = await rideDb.query(
    `SELECT first_name, last_name, phone FROM users WHERE user_id = $1`,
    [userId]
  );
  const booker = bookerResult.rows[0];
  const bookerName = `${booker.first_name} ${booker.last_name}`;

  // Creator info fetch
  const creatorResult = await rideDb.query(
    `SELECT user_id, first_name, last_name, phone FROM users WHERE user_id = $1`,
    [session.created_by]
  );
  const creator = creatorResult.rows[0];
  const creatorName = `${creator.first_name} ${creator.last_name}`;

  // ── Creator-কে নোটিফিকেশন: booker এর নাম + ফোন
  await createNotification({
    userId: session.created_by,
    title: 'Someone Booked Your CoRide!',
    message: `${bookerName} has booked a seat. Phone: ${booker.phone || 'N/A'}`,
    type: 'co_ride',
    isImportant: true,
    targetRole: 'passenger',
    relatedId: String(sessionId),
  });

  // ── Booker-কে নোটিফিকেশন: creator এর নাম + ফোন
  await createNotification({
    userId: userId,
    title: 'CoRide Booking Confirmed!',
    message: `You booked a seat with ${creatorName}. Their phone: ${creator.phone || 'N/A'}. From: ${session.start_location} → ${session.destination}`,
    type: 'co_ride',
    isImportant: true,
    targetRole: 'passenger',
    relatedId: String(sessionId),
  });

  return participant.rows[0];
};

const cancelSession = async (sessionId, userId) => {
  const result = await rideDb.query(
    `UPDATE company_sharing_sessions
     SET status = 'Cancelled'
     WHERE session_id = $1 AND created_by = $2
     RETURNING *`,
    [sessionId, userId]
  );
  if (result.rowCount === 0) throw new Error('Session not found or unauthorized.');
  return result.rows[0];
};

const startSession = async (sessionId, userId) => {
  const result = await rideDb.query(
    `UPDATE company_sharing_sessions
     SET is_started = TRUE, started_at = NOW()
     WHERE session_id = $1 AND created_by = $2
     RETURNING *`,
    [sessionId, userId]
  );
  if (result.rowCount === 0) throw new Error('Session not found or unauthorized.');

  // Participants-দের notify করো
  const participants = await rideDb.query(
    `SELECT cp.user_id FROM company_participants cp WHERE cp.session_id = $1`,
    [sessionId]
  );

  const session = result.rows[0];
  for (const p of participants.rows) {
    await createNotification({
      userId: p.user_id,
      title: 'CoRide Started!',
      message: `Your co-rider has started the journey from ${session.start_location}. You can now track their live location.`,
      type: 'co_ride',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: String(sessionId),
    });
  }

  return result.rows[0];
};

const updateLiveLocation = async (sessionId, userId, lat, lng) => {
  const result = await rideDb.query(
    `UPDATE company_sharing_sessions
     SET current_lat = $1, current_lng = $2
     WHERE session_id = $3 AND created_by = $4
     RETURNING session_id, current_lat, current_lng`,
    [lat, lng, sessionId, userId]
  );
  if (result.rowCount === 0) throw new Error('Unauthorized or not found.');

  // Socket emit
  const { emitCoRideLiveLocation } = require('../utils/coRideEmitter');
  emitCoRideLiveLocation(sessionId, { lat, lng });

  return result.rows[0];
};

const getLiveLocation = async (sessionId) => {
  const result = await rideDb.query(
    `SELECT current_lat, current_lng, is_started
     FROM company_sharing_sessions
     WHERE session_id = $1`,
    [sessionId]
  );
  if (result.rowCount === 0) throw new Error('Session not found.');
  return result.rows[0];
};

const listSessions = async (userId) => {
  const result = await rideDb.query(
    `SELECT css.*, u.first_name, u.last_name, u.university_email,
            (css.total_seats - css.booked_seats) AS available_seats
     FROM company_sharing_sessions css
     JOIN users u ON css.created_by = u.user_id
     WHERE css.status = 'Active'
     ORDER BY css.created_at DESC`
  );

  if (!userId) return result.rows;

  const userRes = await rideDb.query(
    `SELECT gender, university_email FROM users WHERE user_id = $1`,
    [userId]
  );
  const user = userRes.rows[0];
  if (!user) return result.rows;

  return coRideRecommendationService.scoreAndSortSessions({
    userId,
    userGender: user.gender,
    userEmail: user.university_email,
    sessions: result.rows,
  });
};

const sendCompanyChatMessage = async (sessionId, senderId, message_text) => {
  const result = await rideDb.query(
    `INSERT INTO company_chats (session_id, sender_id, message_text)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [sessionId, senderId, message_text]
  );
  return result.rows[0];
};

const fetchCompanyChatMessages = async (sessionId) => {
  const result = await rideDb.query(
    `SELECT cc.*, u.first_name, u.last_name, u.university_email
     FROM company_chats cc
     JOIN users u ON cc.sender_id = u.user_id
     WHERE cc.session_id = $1
     ORDER BY cc.sent_at ASC`,
    [sessionId]
  );
  return result.rows;
};

const markCompanyChatAsRead = async (sessionId, userId) => {
  const upsertQuery = `
    INSERT INTO company_chat_reads (session_id, user_id, last_read_at)
    VALUES ($1, $2, CURRENT_TIMESTAMP)
    ON CONFLICT (session_id, user_id)
    DO UPDATE SET last_read_at = CURRENT_TIMESTAMP
  `;
  await rideDb.query(upsertQuery, [sessionId, userId]);
  return { success: true };
};

const removeParticipant = async (sessionId, creatorId, participantUserId) => {
  // Creator কিনা check
  const sessionRes = await rideDb.query(
    `SELECT created_by FROM company_sharing_sessions WHERE session_id = $1`,
    [sessionId]
  );
  if (sessionRes.rowCount === 0) throw new Error('Session not found.');
  if (String(sessionRes.rows[0].created_by) !== String(creatorId)) {
    throw new Error('Only the creator can remove participants.');
  }

  // Participant আছে কিনা check
  const partRes = await rideDb.query(
    `SELECT id FROM company_participants WHERE session_id = $1 AND user_id = $2`,
    [sessionId, participantUserId]
  );
  if (partRes.rowCount === 0) throw new Error('Participant not found.');

  // Remove
  await rideDb.query(
    `DELETE FROM company_participants WHERE session_id = $1 AND user_id = $2`,
    [sessionId, participantUserId]
  );

  // Seat ফিরিয়ে দাও
  await rideDb.query(
    `UPDATE company_sharing_sessions SET booked_seats = booked_seats - 1 WHERE session_id = $1`,
    [sessionId]
  );

  // Removed user কে notification
  await createNotification({
    userId: participantUserId,
    title: 'Removed from CoRide',
    message: 'You have been removed from a CoRide session by the creator.',
    type: 'co_ride',
    isImportant: true,
    targetRole: 'passenger',
    relatedId: String(sessionId),
  });

  return { success: true };
};

const getSessionWithParticipants = async (sessionId, userId) => {
  const sessionRes = await rideDb.query(
    `SELECT css.*, u.first_name, u.last_name, u.phone
     FROM company_sharing_sessions css
     JOIN users u ON css.created_by = u.user_id
     WHERE css.session_id = $1`,
    [sessionId]
  );
  if (sessionRes.rowCount === 0) throw new Error('Session not found.');

  const session = sessionRes.rows[0];

  const participantsRes = await rideDb.query(
    `SELECT cp.user_id, cp.id as participant_id,
            u.first_name, u.last_name, u.profile_picture
     FROM company_participants cp
     JOIN users u ON cp.user_id = u.user_id
     WHERE cp.session_id = $1 AND cp.confirmed = TRUE`,
    [sessionId]
  );

  return {
    ...session,
    confirmed_participants: participantsRes.rows,
    is_creator: String(session.created_by) === String(userId),
  };
};


// ── Passenger search: gender/corridor/frequent-partner সব মিলিয়ে matching sessions ──
const searchSessions = async (userId, { pickupLat, pickupLng, destLat, destLng }) => {
  const userRes = await rideDb.query(
    `SELECT gender, university_email FROM users WHERE user_id = $1`,
    [userId]
  );
  const user = userRes.rows[0];
  if (!user) throw new Error('User not found.');

  const sessionsRes = await rideDb.query(
    `SELECT css.*, u.first_name, u.last_name, u.university_email,
            (css.total_seats - css.booked_seats) AS available_seats
     FROM company_sharing_sessions css
     JOIN users u ON css.created_by = u.user_id
     WHERE css.status = 'Active'
       AND css.created_by != $1
       AND (css.total_seats - css.booked_seats) > 0
     ORDER BY css.created_at DESC`,
    [userId]
  );

  return coRideRecommendationService.searchMatchingSessions({
    userId,
    userGender: user.gender,
    userEmail: user.university_email,
    pickupLat, pickupLng, destLat, destLng,
    sessions: sessionsRes.rows,
  });
};

module.exports = {
  createSession,
  getSessionById,
  getMyActiveSession,
  joinSession,
  cancelSession,
  startSession,
  updateLiveLocation,
  getLiveLocation,
  listSessions,
  searchSessions,
  sendCompanyChatMessage,
  fetchCompanyChatMessages,
  markCompanyChatAsRead,
  removeParticipant,
  getSessionWithParticipants,
};
