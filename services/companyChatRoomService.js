const rideDb = require('../config/rideDb');

const validateAccess = async (userId, sessionId) => {
  const query = `
    SELECT 1
    FROM company_sharing_sessions cs
    WHERE cs.session_id = $1
      AND (
        cs.created_by = $2
        OR EXISTS (
          SELECT 1 FROM company_participants cp
          WHERE cp.session_id = cs.session_id
            AND cp.user_id = $2
            AND cp.confirmed = TRUE
        )
      )
    LIMIT 1
  `;

  const result = await rideDb.query(query, [sessionId, userId]);

  if (!result.rowCount) {
    throw new Error('You are not allowed to access this chat.');
  }
};

const getMessages = async (userId, sessionId) => {
  await validateAccess(userId, sessionId);

  const query = `
    SELECT 
      c.chat_id,
      c.sender_id,
      c.message_text,
      c.sent_at,
      u.first_name || ' ' || u.last_name AS sender_name
    FROM company_chats c
    LEFT JOIN users u ON c.sender_id = u.user_id
    WHERE c.session_id = $1
    ORDER BY c.sent_at ASC
  `;

  const result = await rideDb.query(query, [sessionId]);

  return result.rows.map((row) => ({
    chat_id: row.chat_id,
    sender_id: row.sender_id,
    sender_name: row.sender_name,
    text: row.message_text,
    time: row.sent_at,
    is_mine: row.sender_id === userId,
  }));
};

const sendMessage = async (userId, sessionId, messageText, io) => {
  await validateAccess(userId, sessionId);

  const text = messageText?.trim();
  if (!text) throw new Error('Message cannot be empty');

  const insertQuery = `
    INSERT INTO company_chats (session_id, sender_id, message_text, sent_at)
    VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
    RETURNING chat_id, sender_id, message_text, sent_at
  `;

  const result = await rideDb.query(insertQuery, [
    sessionId,
    userId,
    text,
  ]);

  const msg = result.rows[0];

  const userQuery = `
    SELECT first_name || ' ' || last_name AS name
    FROM users
    WHERE user_id = $1
  `;
  const userRes = await rideDb.query(userQuery, [userId]);

  const finalMessage = {
    chat_id: msg.chat_id,
    sender_id: msg.sender_id,
    sender_name: userRes.rows[0]?.name || 'User',
    text: msg.message_text,
    time: msg.sent_at,
    is_mine: true,
  };

  // 🔥 EMIT to chat room
  io.to(`company_session_${sessionId}`).emit(
    'company_message_received',
    finalMessage
  );

  // 🔥 EMIT inbox update
  const participants = await rideDb.query(`
    SELECT user_id FROM company_participants
    WHERE session_id = $1 AND confirmed = TRUE
  `, [sessionId]);

  const creator = await rideDb.query(`
    SELECT created_by FROM company_sharing_sessions
    WHERE session_id = $1
  `, [sessionId]);

  const users = new Set(participants.rows.map(r => r.user_id));
  if (creator.rowCount) users.add(creator.rows[0].created_by);

  users.forEach(uid => {
    io.to(`user_${uid}`).emit('co_ride_chat_list_updated');
  });

  return finalMessage;
};

const markAsRead = async (userId, sessionId) => {
  await validateAccess(userId, sessionId);

  const query = `
    INSERT INTO company_chat_reads (session_id, user_id, last_read_at)
    VALUES ($1, $2, CURRENT_TIMESTAMP)
    ON CONFLICT (session_id, user_id)
    DO UPDATE SET last_read_at = CURRENT_TIMESTAMP
  `;

  await rideDb.query(query, [sessionId, userId]);
};

module.exports = {
  getMessages,
  sendMessage,
  markAsRead,
};
