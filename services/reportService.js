const rideDb = require('../config/rideDb');

const submitReport = async (userId, userEmail, comment) => {
  if (!comment || !String(comment).trim()) {
    throw new Error('Comment is required.');
  }

  const trimmedComment = String(comment).trim();

  if (trimmedComment.length < 5) {
    throw new Error('Comment must be at least 5 characters.');
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

  if (String(userResult.rows[0].account_status).toLowerCase() !== 'active') {
    throw new Error('Your account is not active.');
  }

  const result = await rideDb.query(
    `INSERT INTO reports (
      user_id,
      user_email,
      comment,
      status,
      is_spam
    )
    VALUES ($1, $2, $3, $4, $5)
    RETURNING report_id, user_id, user_email, comment, status, is_spam, created_at`,
    [
      userId,
      userEmail || userResult.rows[0].university_email,
      trimmedComment,
      'unsolved',
      false,
    ]
  );

  return result.rows[0];
};

const getMyReports = async (userId) => {
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

const listAllReports = async () => {
  const result = await rideDb.query(
    `SELECT
        report_id,
        user_id,
        user_email,
        comment,
        status,
        is_spam,
        created_at
     FROM reports
     ORDER BY created_at DESC`
  );

  return result.rows;
};

const markReportSolved = async (reportId) => {
  const result = await rideDb.query(
    `UPDATE reports
     SET status = 'solved'
     WHERE report_id = $1
     RETURNING report_id, user_id, user_email, comment, status, is_spam, created_at`,
    [reportId]
  );

  if (result.rowCount === 0) {
    throw new Error('Report not found.');
  }

  return result.rows[0];
};

module.exports = {
  submitReport,
  getMyReports,
  listAllReports,
  markReportSolved,
};