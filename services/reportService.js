const rideDb = require('../config/rideDb');

const submitReport = async (userId, user_email, comment) => {
  const result = await rideDb.query(
    `INSERT INTO reports (user_id, user_email, comment)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [userId, user_email, comment]
  );

  return result.rows[0];
};

const listMyReports = async (userId) => {
  const result = await rideDb.query(
    `SELECT * FROM reports WHERE user_id = $1 ORDER BY created_at DESC`,
    [userId]
  );

  return result.rows;
};

const listAllReports = async () => {
  const result = await rideDb.query(
    `SELECT * FROM reports ORDER BY created_at DESC`
  );

  return result.rows;
};

const markReportSolved = async (reportId) => {
  const result = await rideDb.query(
    `UPDATE reports
     SET status = 'solved'
     WHERE report_id = $1
     RETURNING *`,
    [reportId]
  );

  if (result.rowCount === 0) {
    throw new Error('Report not found.');
  }

  return result.rows[0];
};

module.exports = {
  submitReport,
  listMyReports,
  listAllReports,
  markReportSolved,
};