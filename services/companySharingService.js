const rideDb = require('../config/rideDb');
const { createNotification } = require('./notificationService');
const { emitCoRideSeatUpdate } = require('../utils/coRideEmitter');

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
  } = payload;

  const result = await rideDb.query(
    `INSERT INTO company_sharing_sessions 
      (created_by, start_location, destination, status,
       trip_date, trip_time, vehicle_type, vehicle_number,
       total_seats, booked_seats, preferred_gender, fare_per_person)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,0,$10,$11)
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
    ]
  );

  const session = result.rows[0];

  // ── সব passenger-কে নোটিফিকেশন পাঠাও (preferred_gender filter সহ)
  let userQuery = `SELECT user_id, first_name, last_name, gender FROM users WHERE user_id != $1`;
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

  for (const user of users.rows) {
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

  // Session bilok check
  const sessionResult = await rideDb.query(
    `SELECT * FROM company_sharing_sessions WHERE session_id = $1`,
    [sessionId]
  );
  if (sessionResult.rowCount === 0) throw new Error('Session not found.');

  const session = sessionResult.rows[0];
  const availableSeats = session.total_seats - session.booked_seats;
  if (availableSeats <= 0) throw new Error('No seats available.');

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

const listSessions = async () => {
  const result = await rideDb.query(
    `SELECT css.*, u.first_name, u.last_name, u.university_email,
            (css.total_seats - css.booked_seats) AS available_seats
     FROM company_sharing_sessions css
     JOIN users u ON css.created_by = u.user_id
     WHERE css.status = 'Active'
     ORDER BY css.created_at DESC`
  );
  return result.rows;
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
  sendCompanyChatMessage,
  fetchCompanyChatMessages,
};
