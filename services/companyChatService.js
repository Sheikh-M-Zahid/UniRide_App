const rideDb = require('../config/rideDb');

const getChatList = async (userId) => {

  const query = `
    WITH user_sessions AS (
      SELECT cs.session_id, cs.start_location, cs.destination, cs.created_by
      FROM company_sharing_sessions cs
      WHERE cs.created_by = $1

      UNION

      SELECT cs.session_id, cs.start_location, cs.destination, cs.created_by
      FROM company_sharing_sessions cs
      JOIN company_participants cp
        ON cs.session_id = cp.session_id
      WHERE cp.user_id = $1
    ),

    latest_messages AS (
      SELECT DISTINCT ON (session_id)
        session_id,
        message_text,
        sent_at
      FROM company_chats
      ORDER BY session_id, sent_at DESC
    )

    SELECT
      us.session_id,
      us.start_location,
      us.destination,
      lm.message_text,
      lm.sent_at,
      u.first_name || ' ' || u.last_name AS creator_name,
      u.profile_picture AS creator_photo
    FROM user_sessions us
    LEFT JOIN latest_messages lm
      ON us.session_id = lm.session_id
    LEFT JOIN users u
      ON us.created_by = u.user_id
    ORDER BY lm.sent_at DESC NULLS LAST
  `;

  const result = await rideDb.query(query, [userId]);

  return result.rows.map((row) => ({
    session_id: row.session_id,
    display_name: `${row.start_location} → ${row.destination}`,
    last_message: row.message_text || '',
    last_message_time: row.sent_at,
    creator_name: row.creator_name,
    creator_photo: row.creator_photo || '',
  }));
};

module.exports = {
  getChatList,
};