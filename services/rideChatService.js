const rideDb = require('../config/rideDb');

const sendMessage = async (rideId, senderId, message_text) => {
  const result = await rideDb.query(
    `INSERT INTO ride_chats (ride_id, sender_id, message_text)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [rideId, senderId, message_text]
  );

  return result.rows[0];
};

const getChatMessagesByRide = async (rideId) => {
  const result = await rideDb.query(
    `SELECT rc.*, u.first_name, u.last_name, u.university_email
     FROM ride_chats rc
     JOIN users u ON rc.sender_id = u.user_id
     WHERE rc.ride_id = $1
     ORDER BY rc.sent_at ASC`,
    [rideId]
  );

  return result.rows;
};

module.exports = {
  sendMessage,
  getChatMessagesByRide,
};