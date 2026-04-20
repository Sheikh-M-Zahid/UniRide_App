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

  let rideWhereClause = `WHERE rr.passenger_id = $1`;
  const rideValues = [userId];
  let rideIndex = 2;

  if (type !== 'all') {
    if (type === 'reserved') {
      rideWhereClause += ` AND rr.status = 'accepted'`; 
      } else if (type === 'completed') {
        rideWhereClause += ` AND rr.status = 'accepted' AND r.status = 'completed'`;
      } else if (type === 'cancelled') {
        rideWhereClause += ` AND rr.status = 'cancelled'`;
      }
    }

    // টাইম ফিল্টারগুলো r. এর জায়গায় rr. করুন
    if (time === 'today') {
      rideWhereClause += ` AND DATE(rr.created_at) = CURRENT_DATE`;
    } else if (time === 'this_week') {
      rideWhereClause += ` AND rr.created_at >= DATE_TRUNC('week', CURRENT_DATE)`;
    } else if (time === 'this_month') {
      rideWhereClause += ` AND rr.created_at >= DATE_TRUNC('month', CURRENT_DATE)`;
    }
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
      COUNT(*) FILTER (WHERE rr.status = 'cancelled')::int AS cancelled,
      COALESCE(SUM(CASE WHEN r.status = 'completed' THEN rr.estimated_fare ELSE 0 END), 0) AS earnings
    FROM ride_requests rr
    LEFT JOIN rides r ON rr.ride_id = r.ride_id
    ${rideWhereClause}
  `;

  const rideListQuery = `
    SELECT
      rr.request_id AS id,
      'ride' AS item_type,
      'Ride Activity' AS title,
      u.first_name || ' ' || u.last_name AS name,
      u.phone AS phone,
      rr.pickup_location AS pickup,
      rr.destination,
      COALESCE(rr.estimated_minutes::text, '0') AS time,
      COALESCE(rr.estimated_fare, 0) AS fare,
      TO_CHAR(rr.created_at, 'DD Mon YYYY') AS date,
      rr.status,
      rr.created_at,
      rr.distance_km AS total_distance_km,
      rr.estimated_minutes AS estimated_travel_minutes,
      u.first_name || ' ' || u.last_name AS rider_name,
      u.phone AS rider_phone,
      (rr.status = 'pending') AS can_cancel
    FROM ride_requests rr
    LEFT JOIN rides r ON rr.ride_id = r.ride_id
    LEFT JOIN users u ON rr.rider_id = u.user_id
    ${rideWhereClause}
    ORDER BY rr.created_at DESC
  `;

  const rideSummaryResult = await rideDb.query(rideSummaryQuery, rideValues);
  const rideActivitiesResult = await rideDb.query(rideListQuery, rideValues);

  const sendItemResult = await rideDb.query(
    `SELECT 
      s_id AS id, 'send_item' AS item_type, 'Parcel Delivery' AS title,
      receiver_name AS name, receiver_phone AS phone, pickup_location AS pickup,
      drop_location AS destination, estimated_minutes::text AS time,
      delivery_fee AS fare, TO_CHAR(created_at, 'DD Mon YYYY') AS date,
      status, created_at
     FROM send_items 
     WHERE (receiver_id = $1 OR rider_id = $1)
     ${time === 'today' ? "AND created_at >= CURRENT_DATE" : ""}
     ORDER BY created_at DESC`,
    [userId]
  );

  const reserveData = await reserveService.getReserveActivityList({
    userId,
    type,
    time,
  });

  const rideSummaryRow = rideSummaryResult.rows[0] || {};
  const reserveSummary = reserveData.summary || {};

  const mergedActivities = [
    // ১. সাধারণ রাইড এর ডাটা (Ride Requests)
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

    // ২. পার্সেল ডেলিভারি ডাটা (Send Items)
    ...(sendItemResult.rows || []).map((row) => ({
      id: row.id,
      item_type: 'send_item',
      title: row.title,
      name: row.name, // Receiver Name
      phone: row.phone, // Receiver Phone
      pickup: row.pickup,
      destination: row.destination,
      time: row.time,
      fare: Number(row.fare || 0),
      date: row.date,
      status: row.status,
      created_at: row.created_at,
      canCancel: false,
    })),

    // ৩. রিজার্ভ রাইড ডাটা (Reserves)
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
