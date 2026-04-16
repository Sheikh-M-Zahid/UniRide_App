const rideDb = require('../config/rideDb');


//   FETCH ALL REPORTS

const getAllReports = async () => {
  const result = await rideDb.query(`
    SELECT
      r.report_id,
      r.user_id,
      r.user_email,
      r.comment,
      r.status,
      r.is_spam,
      r.created_at,
      u.first_name,
      u.last_name,
      CASE
        WHEN EXISTS (
          SELECT 1
          FROM vehicles v
          WHERE v.user_id = r.user_id
        ) THEN 'Rider'
        ELSE 'Passenger'
      END AS role
    FROM reports r
    LEFT JOIN users u
      ON r.user_id = u.user_id
    WHERE r.is_spam = FALSE
    ORDER BY r.created_at DESC
  `);

  const reports = result.rows.map((row) => ({
    id: row.report_id,
    name: `${row.first_name || ''} ${row.last_name || ''}`.trim() || row.user_email,
    role: row.role,
    message: row.comment,
    status: row.status,
    isRead: row.status === 'solved',
    createdAt: row.created_at,
  }));

  const unsolvedCount = reports.filter((r) => r.status === 'unsolved').length;
  const solvedCount = reports.filter((r) => r.status === 'solved').length;

  return {
    reports,
    summary: {
      unsolvedCount,
      solvedCount,
    },
  };
};


//   CREATE NOTIFICATION

const createSolvedNotification = async ({ userId, reportId }) => {
  await rideDb.query(
    `
    INSERT INTO notifications (
      user_id,
      title,
      message,
      type,
      is_read,
      related_id,
      created_at
    )
    VALUES ($1, $2, $3, $4, FALSE, $5, CURRENT_TIMESTAMP)
    `,
    [
      userId,
      'Report Solved',
      'Your report has been reviewed and marked as solved.',
      'report_update',
      reportId,
    ]
  );
};


//   MARK AS SOLVED

const markAsSolved = async (reportId) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const check = await client.query(
      `
      SELECT
        report_id,
        user_id,
        status,
        comment
      FROM reports
      WHERE report_id = $1
      FOR UPDATE
      `,
      [reportId]
    );

    if (!check.rows.length) {
      throw new Error('Report not found.');
    }

    const report = check.rows[0];

    if (report.status === 'solved') {
      throw new Error('Report already solved.');
    }

    const updated = await client.query(
      `
      UPDATE reports
      SET status = 'solved'
      WHERE report_id = $1
      RETURNING *
      `,
      [reportId]
    );

    await client.query(
      `
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        related_id,
        created_at
      )
      VALUES ($1, $2, $3, $4, FALSE, $5, CURRENT_TIMESTAMP)
      `,
      [
        report.user_id,
        'Report Solved',
        'Your report has been reviewed and marked as solved.',
        'report_update',
        report.report_id,
      ]
    );

    await client.query('COMMIT');

    return updated.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  getAllReports,
  markAsSolved,
  createSolvedNotification,
};