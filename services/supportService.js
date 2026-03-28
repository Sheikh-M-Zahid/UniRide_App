const rideDb = require('../config/rideDb');

const submitHelpRequest = async (userId, userEmail, message) => {
  if (!message || !String(message).trim()) {
    throw new Error('Message is required.');
  }

  const trimmedMessage = String(message).trim();

  if (trimmedMessage.length < 5) {
    throw new Error('Message must be at least 5 characters.');
  }

  const userResult = await rideDb.query(
    `SELECT user_id, university_email, account_status
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (userResult.rowCount === 0) {
    throw new Error('User account not found.');
  }

  const user = userResult.rows[0];

  if (String(user.account_status).toLowerCase() !== 'active') {
    throw new Error('Your account is not active.');
  }

  await rideDb.query(
    `INSERT INTO reports (
      user_id,
      user_email,
      comment,
      status,
      is_spam
    )
    VALUES ($1, $2, $3, $4, $5)`,
    [
      userId,
      userEmail || user.university_email,
      trimmedMessage,
      'unsolved',
      false,
    ]
  );

  return true;
};

const getMyRequests = async (userId) => {
  const userResult = await rideDb.query(
    `SELECT user_id, account_status
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (userResult.rowCount === 0) {
    throw new Error('User account not found.');
  }

  const user = userResult.rows[0];

  if (String(user.account_status).toLowerCase() !== 'active') {
    throw new Error('Your account is not active.');
  }

  const result = await rideDb.query(
    `SELECT
        report_id,
        comment,
        status,
        is_spam,
        created_at
     FROM reports
     WHERE user_id = $1
     ORDER BY created_at DESC`,
    [userId]
  );

  return result.rows;
};

module.exports = {
  submitHelpRequest,
  getMyRequests,
};