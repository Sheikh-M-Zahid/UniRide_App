const rideDb = require('../config/rideDb');

const getChatList = async (userId) => {
  const query = `
    WITH user_sessions AS (
      SELECT
        cs.session_id,
        cs.start_location,
        cs.destination,
        cs.created_by
      FROM company_sharing_sessions cs
      WHERE cs.created_by = $1

      UNION

      SELECT
        cs.session_id,
        cs.start_location,
        cs.destination,
        cs.created_by
      FROM company_sharing_sessions cs
      JOIN company_participants cp
        ON cs.session_id = cp.session_id
      WHERE cp.user_id = $1
        AND cp.confirmed = TRUE
    ),
    latest_messages AS (
      SELECT DISTINCT ON (cc.session_id)
        cc.session_id,
        cc.message_text,
        cc.sent_at
      FROM company_chats cc
      ORDER BY cc.session_id, cc.sent_at DESC
    ),
    unread_counts AS (
      SELECT
        us.session_id,
        COUNT(cc.chat_id)::int AS unread_count
      FROM user_sessions us
      LEFT JOIN company_chat_reads ccr
        ON ccr.session_id = us.session_id
       AND ccr.user_id = $1
      LEFT JOIN company_chats cc
        ON cc.session_id = us.session_id
       AND cc.sender_id <> $1
       AND cc.sent_at > COALESCE(ccr.last_read_at, '1970-01-01'::timestamp)
      GROUP BY us.session_id
    )
    SELECT
      us.session_id,
      us.start_location,
      us.destination,
      lm.message_text AS last_message,
      lm.sent_at AS last_message_time,
      COALESCE(uc.unread_count, 0) AS unread_count,
      u.first_name || ' ' || u.last_name AS creator_name,
      u.profile_picture AS creator_photo
    FROM user_sessions us
    LEFT JOIN latest_messages lm
      ON us.session_id = lm.session_id
    LEFT JOIN unread_counts uc
      ON us.session_id = uc.session_id
    LEFT JOIN users u
      ON us.created_by = u.user_id
    ORDER BY lm.sent_at DESC NULLS LAST, us.session_id DESC
  `;

  const result = await rideDb.query(query, [userId]);

  return result.rows.map((row) => ({
    session_id: row.session_id,
    title: `${row.start_location} → ${row.destination}`,
    subtitle: `Creator: ${row.creator_name || 'Unknown'}`,
    last_message: row.last_message || '',
    last_message_time: row.last_message_time,
    unread_count: Number(row.unread_count || 0),
    creator_photo: row.creator_photo || '',
    post: {
      session_id: row.session_id,
      pickup_location: row.start_location,
      destination_location: row.destination,
      creator_name: row.creator_name || 'Unknown',
      creator_photo: row.creator_photo || '',
    },
  }));
};

const markAsRead = async (userId, sessionId) => {
  const accessQuery = `
    SELECT 1
    FROM company_sharing_sessions cs
    WHERE cs.session_id = $1
      AND (
        cs.created_by = $2
        OR EXISTS (
          SELECT 1
          FROM company_participants cp
          WHERE cp.session_id = cs.session_id
            AND cp.user_id = $2
            AND cp.confirmed = TRUE
        )
      )
    LIMIT 1
  `;

  const accessResult = await rideDb.query(accessQuery, [sessionId, userId]);

  if (!accessResult.rowCount) {
    throw new Error('You are not allowed to access this chat');
  }

  const upsertQuery = `
    INSERT INTO company_chat_reads (session_id, user_id, last_read_at)
    VALUES ($1, $2, CURRENT_TIMESTAMP)
    ON CONFLICT (session_id, user_id)
    DO UPDATE SET last_read_at = EXCLUDED.last_read_at
  `;

  await rideDb.query(upsertQuery, [sessionId, userId]);
};

module.exports = {
  getChatList,
  markAsRead,
};