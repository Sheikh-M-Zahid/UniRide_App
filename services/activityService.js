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
      r.id AS ride_id,
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

  let query = `
    SELECT 
      r.id,
      r.start_location,
      r.destination,
      r.total_fare,
      r.status,
      r.created_at
    FROM rides r
    WHERE r.rider_id = $1
  `;

  const values = [userId];
  let index = 2;

  // Filter by type
  if (type !== 'all') {
    query += ` AND r.status = $${index}`;
    values.push(type);
    index++;
  }

  // Filter by time
  if (time === 'today') {
    query += ` AND DATE(r.created_at) = CURRENT_DATE`;
  } else if (time === 'week') {
    query += ` AND r.created_at >= NOW() - INTERVAL '7 days'`;
  } else if (time === 'month') {
    query += ` AND r.created_at >= NOW() - INTERVAL '30 days'`;
  }

  query += `
    ORDER BY r.created_at DESC
    LIMIT $${index} OFFSET $${index + 1}
  `;

  values.push(limit, offset);

  const result = await rideDb.query(query, values);

  return result.rows;
};

module.exports = {
  getMyActivity,
  getActivityDashboard,
};