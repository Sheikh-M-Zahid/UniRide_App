const rideDb = require('../config/rideDb');

const createSession = async (userId, payload) => {
  const {
    start_location,
    destination,
    status,
    trip_date = null,
    trip_time = null,
    vehicle_type = null,
    vehicle_number = null,
    total_seats = null,
    preferred_gender = null,
    fare_per_person = null,
  } = payload;

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
      start_location,
      destination,
      status || 'Active',
      trip_date,
      trip_time,
      vehicle_type,
      vehicle_number,
      total_seats,
      preferred_gender,
      fare_per_person,
    ]
  );

  return result.rows[0];
};

const joinSession = async (sessionId, userId) => {
  const existing = await rideDb.query(
    `SELECT id FROM company_participants WHERE session_id = $1 AND user_id = $2`,
    [sessionId, userId]
  );

  if (existing.rowCount > 0) {
    throw new Error('Already joined this session.');
  }

  const result = await rideDb.query(
    `INSERT INTO company_participants (session_id, user_id, confirmed)
     VALUES ($1, $2, FALSE)
     RETURNING *`,
    [sessionId, userId]
  );

  return result.rows[0];
};

const listSessions = async () => {
  const result = await rideDb.query(
    `SELECT css.*, u.first_name, u.last_name, u.university_email
     FROM company_sharing_sessions css
     JOIN users u ON css.created_by = u.user_id
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
  joinSession,
  listSessions,
  sendCompanyChatMessage,
  fetchCompanyChatMessages,
};
