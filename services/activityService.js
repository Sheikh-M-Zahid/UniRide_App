const rideDb = require('../config/rideDb');

// ==============================
// GET MY ACTIVITY
// ==============================
const getMyActivity = async (userId, sort = 'new') => {
  let order = 'DESC';

  if (sort === 'old') {
    order = 'ASC';
  }

  const result = await rideDb.query(
    `
    SELECT 
      r.ride_id,
      r.start_location,
      r.destination,
      r.total_fare,
      r.status,
      r.created_at
    FROM rides r
    WHERE r.rider_id = $1
    ORDER BY r.created_at ${order}
    `,
    [userId]
  );

  return result.rows;
};

// ==============================
// ACTIVITY DASHBOARD
// ==============================
const getActivityDashboard = async ({
  userId,
  type = 'all',
  time = 'today',
  page = 1,
  limit = 20,
}) => {
  const offset = (page - 1) * limit;

  let whereClause = `WHERE r.rider_id = $1`;
  const values = [userId];
  let index = 2;

  // Filter by type
  if (type !== 'all') {
    if (type === 'reserved') {
      whereClause += ` AND r.status = $${index}`;
      values.push('assigned');
      index++;
    } else if (type === 'completed' || type === 'cancelled') {
      whereClause += ` AND r.status = $${index}`;
      values.push(type);
      index++;
    }
  }

  // Filter by time
  if (time === 'today') {
    whereClause += ` AND DATE(r.created_at) = CURRENT_DATE`;
  } else if (time === 'week') {
    whereClause += ` AND r.created_at >= NOW() - INTERVAL '7 days'`;
  } else if (time === 'month') {
    whereClause += ` AND r.created_at >= NOW() - INTERVAL '30 days'`;
  }

  const summaryQuery = `
    SELECT
      COUNT(*)::int AS total,
      COUNT(*) FILTER (WHERE r.status = 'completed')::int AS completed,
      COUNT(*) FILTER (WHERE r.status = 'cancelled')::int AS cancelled,
      COALESCE(SUM(CASE WHEN r.status = 'completed' THEN r.total_fare ELSE 0 END), 0) AS earnings
    FROM rides r
    ${whereClause}
  `;

  const listQuery = `
    SELECT
      r.ride_id,
      'Ride Activity' AS title,
      '' AS name,
      '' AS phone,
      r.start_location AS pickup,
      r.destination,
      COALESCE(r.travel_time, '') AS time,
      COALESCE(r.total_fare, 0) AS fare,
      TO_CHAR(r.created_at, 'DD Mon YYYY') AS date,
      CASE
        WHEN r.status = 'assigned' THEN 'reserved'
        ELSE r.status
      END AS status
    FROM rides r
    ${whereClause}
    ORDER BY r.created_at DESC
    LIMIT $${index} OFFSET $${index + 1}
  `;

  const summaryResult = await rideDb.query(summaryQuery, values);
  const activitiesResult = await rideDb.query(listQuery, [...values, limit, offset]);

  const summaryRow = summaryResult.rows[0] || {};

  return {
    summary: {
      total: Number(summaryRow.total || 0),
      completed: Number(summaryRow.completed || 0),
      cancelled: Number(summaryRow.cancelled || 0),
      earnings: Number(summaryRow.earnings || 0),
    },
    activities: activitiesResult.rows,
    emptyState:
      activitiesResult.rows.length === 0 ? 'No activity found' : null,
  };
};

module.exports = {
  getMyActivity,
  getActivityDashboard,
};
