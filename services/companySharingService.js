const rideDb = require('../config/rideDb');

// ==============================
// CREATE SESSION (merged version)
// ==============================
const createSession = async (payload, user = null) => {
  const userId = user?.userId || user?.user_id;

  if (!userId) {
    throw new Error('Unauthorized.');
  }

  const {
    pickup_location,
    destination_location,
    trip_date,
    trip_time,
    vehicle_type,
    vehicle_number,
    available_seats,
    preferred_gender,
    fare_per_person,
  } = payload;

  if (!pickup_location || !destination_location) {
    throw new Error('Pickup and destination are required.');
  }

  const seatCount = Number(available_seats);
  const fare = Number(fare_per_person);

  if (seatCount <= 0) {
    throw new Error('Seats must be greater than 0.');
  }

  if (fare <= 0) {
    throw new Error('Fare must be greater than 0.');
  }

  const result = await rideDb.query(
    `INSERT INTO company_sharing_sessions (
      created_by,
      start_location,
      destination,
      status,
      trip_date,
      trip_time,
      vehicle_type,
      vehicle_number,
      total_seats,
      preferred_gender,
      fare_per_person
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
    RETURNING *`,
    [
      userId,
      pickup_location,
      destination_location,
      'scheduled',
      trip_date,
      trip_time,
      vehicle_type,
      vehicle_number || null,
      seatCount,
      preferred_gender || 'Any',
      fare,
    ]
  );

  return result.rows[0];
};

// ==============================
// ACTIVE SESSIONS
// ==============================
const getActiveSessions = async (user = null, queryParams = {}) => {
  const { search } = queryParams;

  let query = `
    SELECT
      cs.session_id,
      u.first_name || ' ' || u.last_name AS creator_name,
      cs.start_location AS pickup_location,
      cs.destination AS destination_location,
      cs.trip_date,
      cs.trip_time,
      cs.vehicle_type,
      cs.total_seats - COUNT(cp.user_id) AS available_seats,
      COUNT(cp.user_id) AS joined_members,
      cs.fare_per_person
    FROM company_sharing_sessions cs
    LEFT JOIN company_participants cp ON cs.session_id = cp.session_id
    LEFT JOIN users u ON cs.created_by = u.user_id
    WHERE cs.status IN ('scheduled','active')
  `;

  const values = [];

  if (search) {
    query += `
      AND (
        LOWER(cs.start_location) LIKE LOWER($1)
        OR LOWER(cs.destination) LIKE LOWER($1)
      )
    `;
    values.push(`%${search}%`);
  }

  query += `
    GROUP BY cs.session_id, u.user_id
    HAVING (cs.total_seats - COUNT(cp.user_id)) > 0
    ORDER BY cs.trip_date ASC
  `;

  const result = await rideDb.query(query, values);
  return result.rows;
};

// ==============================
// HISTORY
// ==============================
const getHistory = async (user = null) => {
  const userId = user?.userId || user?.user_id;

  const result = await rideDb.query(
    `SELECT * FROM company_sharing_sessions
     WHERE created_by = $1
     ORDER BY trip_date DESC`,
    [userId]
  );

  return result.rows;
};

// ==============================
// JOIN SESSION
// ==============================
const joinSession = async (sessionId, userId) => {
  const existing = await rideDb.query(
    `SELECT id FROM company_participants WHERE session_id=$1 AND user_id=$2`,
    [sessionId, userId]
  );

  if (existing.rowCount > 0) {
    throw new Error('Already joined.');
  }

  const result = await rideDb.query(
    `INSERT INTO company_participants (session_id,user_id,confirmed)
     VALUES ($1,$2,false)
     RETURNING *`,
    [sessionId, userId]
  );

  return result.rows[0];
};

// ==============================
// LIST SESSIONS
// ==============================
const listSessions = async () => {
  const result = await rideDb.query(
    `SELECT cs.*, u.first_name, u.last_name
     FROM company_sharing_sessions cs
     JOIN users u ON cs.created_by=u.user_id
     ORDER BY cs.created_at DESC`
  );

  return result.rows;
};

// ==============================
// CHAT
// ==============================
const sendCompanyChatMessage = async (sessionId, senderId, message) => {
  const result = await rideDb.query(
    `INSERT INTO company_chats(session_id,sender_id,message_text)
     VALUES ($1,$2,$3)
     RETURNING *`,
    [sessionId, senderId, message]
  );

  return result.rows[0];
};

const fetchCompanyChatMessages = async (sessionId) => {
  const result = await rideDb.query(
    `SELECT cc.*, u.first_name, u.last_name
     FROM company_chats cc
     JOIN users u ON cc.sender_id=u.user_id
     WHERE cc.session_id=$1
     ORDER BY cc.sent_at ASC`,
    [sessionId]
  );

  return result.rows;
};

// ==============================
module.exports = {
  createSession,
  getActiveSessions,
  getHistory,
  joinSession,
  listSessions,
  sendCompanyChatMessage,
  fetchCompanyChatMessages,
};