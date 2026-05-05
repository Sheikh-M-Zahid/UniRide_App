const rideDb = require('../config/rideDb');
const reserveService = require('./reserveService');

// ==============================
// GET MY ACTIVITY
// ==============================
const getMyActivity = async (userId, sort = 'new') => {
  let order = 'DESC';
  if (sort === 'old') { order = 'ASC'; }

  const result = await rideDb.query(
    `SELECT r.ride_id, r.start_location, r.destination, r.total_fare, r.status, r.created_at
     FROM rides r
     WHERE r.rider_id = $1
     ORDER BY r.created_at ${order}`,
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

  // ১. রাইড রিকোয়েস্টের জন্য ফিল্টার (প্যাসেঞ্জার হিসেবে)
  let rideWhereClause = `WHERE rr.passenger_id = $1`;
  const rideValues = [userId];

  // টাইপ ফিল্টার লজিক
  if (type !== 'all') {
    if (type === 'reserved') {
      rideWhereClause += ` AND rr.status = 'accepted'`;
    } else if (type === 'completed') {
      rideWhereClause += ` AND rr.status = 'accepted' AND r.status = 'completed'`;
    } else if (type === 'cancelled') {
      rideWhereClause += ` AND rr.status = 'cancelled'`;
    } else if (type === 'send_item') {
      rideWhereClause += ` AND 1 = 0`; // রাইড কোয়েরিতে পার্সেল আসবে না
    }
  }

  // টাইম ফিল্টার লজিক
  if (time === 'today') {
    rideWhereClause += ` AND DATE(rr.created_at) = CURRENT_DATE`;
  } else if (time === 'this_week') {
    rideWhereClause += ` AND rr.created_at >= DATE_TRUNC('week', CURRENT_DATE)`;
  } else if (time === 'this_month') {
    rideWhereClause += ` AND rr.created_at >= DATE_TRUNC('month', CURRENT_DATE)`;
  }

  // ২. সামারি কোয়েরি (Alias 'r' এবং 'rr' সঠিকভাবে জয়েন করা হয়েছে)
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

  // ৩. রাইড লিস্ট কোয়েরি
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

  // ৪. সেন্ড আইটেম ডেটা (আপনার ডাটাবেজ কলাম s_id এবং drop_location অনুযায়ী)
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

  // ৫. রিজার্ভেশন ডেটা
  const reserveData = await reserveService.getReserveActivityList({
    userId,
    type,
    time,
  });

  const rideSummaryRow = rideSummaryResult.rows[0] || {};
  const reserveSummary = reserveData.summary || {};

  // CoRide activity (participant হিসেবে)
  const coRideParticipantResult = await rideDb.query(
    `SELECT
      css.session_id AS id,
      'coride' AS item_type,
      'CoRide' AS title,
      u.first_name || ' ' || u.last_name AS creator_name,
      css.start_location AS pickup,
      css.destination,
      css.fare_per_person AS fare,
      TO_CHAR(css.created_at, 'DD Mon YYYY') AS date,
      css.status,
      css.created_at,
      css.is_started,
      cp.confirmed,
      css.total_seats,
      css.booked_seats,
      css.session_id
     FROM company_participants cp
     JOIN company_sharing_sessions css ON cp.session_id = css.session_id
     JOIN users u ON css.created_by = u.user_id
     WHERE cp.user_id = $1 AND cp.confirmed = TRUE
     ${time === 'today' ? "AND DATE(css.created_at) = CURRENT_DATE" : ""}
     ${time === 'week' ? "AND css.created_at >= DATE_TRUNC('week', CURRENT_DATE)" : ""}
     ${time === 'month' ? "AND css.created_at >= DATE_TRUNC('month', CURRENT_DATE)" : ""}
     ORDER BY css.created_at DESC`,
    [userId]
  );
  
  // CoRide activity (creator হিসেবে)
  const coRideCreatorResult = await rideDb.query(
    `SELECT
      css.session_id AS id,
      'coride_creator' AS item_type,
      'CoRide (My Post)' AS title,
      NULL AS creator_name,
      css.start_location AS pickup,
      css.destination,
      css.fare_per_person AS fare,
      TO_CHAR(css.created_at, 'DD Mon YYYY') AS date,
      css.status,
      css.created_at,
      css.is_started,
      css.total_seats,
      css.booked_seats,
      css.session_id
     FROM company_sharing_sessions css
     WHERE css.created_by = $1
     ${time === 'today' ? "AND DATE(css.created_at) = CURRENT_DATE" : ""}
     ${time === 'week' ? "AND css.created_at >= DATE_TRUNC('week', CURRENT_DATE)" : ""}
     ${time === 'month' ? "AND css.created_at >= DATE_TRUNC('month', CURRENT_DATE)" : ""}
     ORDER BY css.created_at DESC`,
    [userId]
  );

  // ৬. সকল ডেটা মার্জ করা
  const mergedActivities = [
    ...(rideActivitiesResult.rows || []).map((row) => ({
      ...row,
      fare: Number(row.fare || 0),
      canCancel: row.can_cancel === true,
    })),
    ...(sendItemResult.rows || []).map((row) => ({
      ...row,
      fare: Number(row.fare || 0),
      canCancel: false,
    })),
    ...((reserveData.activities || []).map((row) => ({
      ...row,
      created_at: row.created_at,
    }))),
    ...(coRideParticipantResult.rows || []).map((row) => ({
      ...row,
      fare: Number(row.fare || 0),
      canCancel: false,
      item_type: 'coride',
    })),
    ...(coRideCreatorResult.rows || []).map((row) => ({
      ...row,
      fare: Number(row.fare || 0),
      canCancel: false,
      item_type: 'coride_creator',
    })),
  ];

  mergedActivities.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  const paginatedActivities = mergedActivities.slice(offset, offset + limit);

  return {
    summary: {
      total: Number(rideSummaryRow.total || 0) + Number(reserveSummary.total || 0) + (sendItemResult.rows?.length || 0),
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
