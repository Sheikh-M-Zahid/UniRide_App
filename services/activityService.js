const rideDb = require('../config/rideDb');
const reserveService = require('./reserveService');

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

  let rideWhereClause = `WHERE r.rider_id = $1`;
  const rideValues = [userId];
  let rideIndex = 2;

  if (type !== 'all') {
    if (type === 'reserved') {
      rideWhereClause += ` AND r.status = $${rideIndex}`;
      rideValues.push('assigned');
      rideIndex++;
    } else if (type === 'completed' || type === 'cancelled') {
      rideWhereClause += ` AND r.status = $${rideIndex}`;
      rideValues.push(type);
      rideIndex++;
    } else if (type === 'send_item') {
      rideWhereClause += ` AND 1 = 0`;
    }
  }

  if (time === 'today') {
    rideWhereClause += ` AND DATE(r.created_at) = CURRENT_DATE`;
  } else if (time === 'this_week') {
    rideWhereClause += ` AND r.created_at >= DATE_TRUNC('week', CURRENT_DATE)`;
  } else if (time === 'this_month') {
    rideWhereClause += ` AND r.created_at >= DATE_TRUNC('month', CURRENT_DATE)`;
  }

  const rideSummaryQuery = `
    SELECT
      COUNT(*)::int AS total,
      COUNT(*) FILTER (WHERE r.status = 'completed')::int AS completed,
      COUNT(*) FILTER (WHERE r.status = 'cancelled')::int AS cancelled,
      COALESCE(SUM(CASE WHEN r.status = 'completed' THEN r.total_fare ELSE 0 END), 0) AS earnings
    FROM rides r
    ${rideWhereClause}
  `;

  const rideListQuery = `
    SELECT
      r.ride_id AS id,
      'ride' AS item_type,
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
      END AS status,
      r.created_at,
      NULL::float AS total_distance_km,
      NULL::int AS estimated_travel_minutes,
      NULL::text AS rider_name,
      NULL::text AS rider_phone,
      FALSE AS can_cancel
    FROM rides r
    ${rideWhereClause}
    ORDER BY r.created_at DESC
  `;

  const rideSummaryResult = await rideDb.query(rideSummaryQuery, rideValues);
  const rideActivitiesResult = await rideDb.query(rideListQuery, rideValues);

  const reserveData = await reserveService.getReserveActivityList({
    userId,
    type,
    time,
  });

  const rideSummaryRow = rideSummaryResult.rows[0] || {};
  const reserveSummary = reserveData.summary || {};

  const mergedActivities = [
    ...(rideActivitiesResult.rows || []).map((row) => ({
      id: row.id,
      item_type: row.item_type,
      title: row.title,
      name: row.name,
      phone: row.phone,
      pickup: row.pickup,
      destination: row.destination,
      time: row.time,
      fare: Number(row.fare || 0),
      date: row.date,
      status: row.status,
      created_at: row.created_at,
      totalDistanceKm: row.total_distance_km,
      estimatedTravelMinutes: row.estimated_travel_minutes,
      riderName: row.rider_name,
      riderPhone: row.rider_phone,
      canCancel: row.can_cancel === true,
    })),
    ...((reserveData.activities || []).map((row) => ({
      ...row,
      created_at: row.created_at,
    }))),
  ];

  mergedActivities.sort((a, b) => {
    return new Date(b.created_at) - new Date(a.created_at);
  });

  const paginatedActivities = mergedActivities.slice(offset, offset + limit);

  return {
    summary: {
      total: Number(rideSummaryRow.total || 0) + Number(reserveSummary.total || 0),
      completed: Number(rideSummaryRow.completed || 0) + Number(reserveSummary.completed || 0),
      cancelled: Number(rideSummaryRow.cancelled || 0) + Number(reserveSummary.cancelled || 0),
      earnings: Number(rideSummaryRow.earnings || 0) + Number(reserveSummary.earnings || 0),
    },
    activities: paginatedActivities,
    emptyState: paginatedActivities.length === 0 ? 'No activity found' : null,
  };
};

module.exports = {
  getMyActivity,
  getActivityDashboard,
};
