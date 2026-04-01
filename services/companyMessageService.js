const rideDb = require('../config/rideDb');

const checkUserInSession = async (sessionId, userId) => {
  const result = await rideDb.query(
    `
    SELECT 1 FROM company_sharing_sessions
    WHERE session_id = $1 AND created_by = $2

    UNION

    SELECT 1 FROM company_participants
    WHERE session_id = $1 AND user_id = $2
    `,
    [sessionId, userId]
  );

  if (result.rowCount === 0) {
    throw new Error('You are not part of this session');
  }
};

const getMessages = async (sessionId, userId) => {
  await checkUserInSession(sessionId, userId);

  const query = `
    SELECT
      c.chat_id,
      c.sender_id,
      u.first_name || ' ' || u.last_name AS sender_name,
      c.message_text,
      c.sent_at
    FROM company_chats c
    JOIN users u ON c.sender_id = u.user_id
    WHERE c.session_id = $1
    ORDER BY c.sent_at ASC
  `;

  const result = await rideDb.query(query, [sessionId]);

  return result.rows.map((msg) => ({
    chat_id: msg.chat_id,
    sender_id: msg.sender_id,
    sender_name: msg.sender_name,
    message_text: msg.message_text,
    sent_at: msg.sent_at,
    is_me: msg.sender_id === userId,
    status: 'sent'
  }));
};

const sendMessage = async (req, sessionId, userId) => {
  const io = req.app.get('io');

  await checkUserInSession(sessionId, userId);

  const { message_text } = req.body;

  if (!message_text || !message_text.trim()) {
    throw new Error('Message cannot be empty');
  }

  const query = `
    INSERT INTO company_chats (session_id, sender_id, message_text)
    VALUES ($1, $2, $3)
    RETURNING chat_id, sender_id, message_text, sent_at
  `;

  const result = await rideDb.query(query, [
    sessionId,
    userId,
    message_text.trim(),
  ]);

  const message = result.rows[0];

  // 🔥 Emit real-time message
  io.to(`company_session_${sessionId}`).emit('company_message_received', {
    chat_id: message.chat_id,
    sender_id: message.sender_id,
    message_text: message.message_text,
    sent_at: message.sent_at,
  });

  // 🔥 Also update chat list
  const participants = await rideDb.query(
    `SELECT user_id FROM company_participants WHERE session_id = $1`,
    [sessionId]
  );

  participants.rows.forEach((p) => {
    io.to(`user_${p.user_id}`).emit('company_chat_list_updated');
  });

  return {
    chat_id: message.chat_id,
    sender_id: message.sender_id,
    message_text: message.message_text,
    sent_at: message.sent_at,
    status: 'sent',
  };
};

module.exports = {
  getMessages,
  sendMessage,
};