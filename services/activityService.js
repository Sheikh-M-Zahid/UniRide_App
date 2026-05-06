const rideDb = require('../config/rideDb');
const reserveService = require('./reserveService');

// ==============================
// GET MY ACTIVITY
// ==============================
const getMyActivity = async (userId, sort = 'new') => {
  const order = sort === 'old' ? 'ASC' : 'DESC';

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
// TIME FILTER HELPER
// ==============================
const buildTimeCondition = (time, tableAlias = '') => {
  const col = tableAlias ? `${tableAlias}.created_at` : 'created_at';

  // frontend থেকে আসতে পারে: 'today', 'week', 'month'
  // বা mapped: 'this_week' → 'week', 'this_month' → 'month'
  const normalized = time?.toLowerCase()?.replace('this_', '') || 'today';

  switch (normalized) {
    case 'week':
      return `AND ${col} >= DATE_TRUNC('week', CURRENT_DATE)`;
    case 'month':
      return `AND ${col} >= DATE_TRUNC('month', CURRENT_DATE)`;
    case 'today':
    default:
      return `AND DATE(${col}) = CURRENT_DATE`;
  }
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
  const timeCondition = buildTimeCondition(time);

  // ── ১. Ride requests (passenger হিসেবে) ──
  let rideWhereClause = `WHERE rr.passenger_id = $1`;

  if (type !== 'all') {
    if (type === 'reserved') {
      rideWhereClause += ` AND rr.status = 'accepted'`;
    } else if (type === 'completed') {
      rideWhereClause += ` AND rr.status = 'accepted' AND EXISTS (SELECT 1 FROM rides WHERE ride_id = rr.ride_id AND status = 'completed')`;
    } else if (type === 'cancelled') {
      rideWhereClause += ` AND rr.status = 'cancelled'`;
    } else if (type === 'send_item' || type === 'coride') {
      rideWhereClause += ` AND 1 = 0`;
    }
  }

  rideWhereClause += ` ${buildTimeCondition(time, 'rr')}`;

  // ── Summary ──
  const rideSummaryQuery = `
    SELECT
      COUNT(*)::int AS total,
      COUNT(*) FILTER (WHERE EXISTS (SELECT 1 FROM rides WHERE ride_id = rr.ride_id AND status = 'completed'))::int AS completed,
      COUNT(*) FILTER (WHERE rr.status = 'cancelled')::int AS cancelled,
      COALESCE(SUM(CASE WHEN EXISTS (SELECT 1 FROM rides WHERE ride_id = rr.ride_id AND status = 'completed') THEN rr.estimated_fare ELSE 0 END), 0) AS earnings
    FROM ride_requests rr
    ${rideWhereClause}
  `;

  // ── Ride list ──
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

  const rideSummaryResult = await rideDb.query(rideSummaryQuery, [userId]);
  const rideActivitiesResult = await rideDb.query(rideListQuery, [userId]);

  // ── ২. Send items ──
  const sendItemResult = await rideDb.query(
    `SELECT
       s_id AS id,
       'send_item' AS item_type,
       'Parcel Delivery' AS title,
       receiver_name AS name,
       receiver_phone AS phone,
       pickup_location AS pickup,
       drop_location AS destination,
       estimated_minutes::text AS time,
       delivery_fee AS fare,
       TO_CHAR(created_at, 'DD Mon YYYY') AS date,
       status,
       created_at
     FROM send_items
     WHERE (receiver_id = $1 OR rider_id = $1)
     ${buildTimeCondition(time)}
     ORDER BY created_at DESC`,
    [userId]
  );

  // ── ৩. Reserves ──
  const reserveData = await reserveService.getReserveActivityList({
    userId,
    type,
    time,
  });

  // ── ৪. CoRide — Participant হিসেবে ──
  const coRideParticipantResult = await rideDb.query(
    `SELECT
       css.session_id::text AS id,
       'coride' AS item_type,
       'CoRide' AS title,
       (u.first_name || ' ' || u.last_name) AS creator_name,
       css.start_location AS pickup,
       css.destination,
       COALESCE(css.fare_per_person, 0) AS fare,
       TO_CHAR(css.created_at, 'DD Mon YYYY') AS date,
       css.status,
       css.created_at,
       css.is_started,
       css.total_seats,
       COALESCE(css.booked_seats, 0) AS booked_seats,
       css.session_id::text AS session_id
     FROM company_participants cp
     JOIN company_sharing_sessions css ON cp.session_id = css.session_id
     JOIN users u ON css.created_by = u.user_id
     WHERE cp.user_id = $1
       AND cp.confirmed = TRUE
     ${buildTimeCondition(time, 'css')}
     ORDER BY css.created_at DESC`,
    [userId]
  );

  // ── ৫. CoRide — Creator হিসেবে ──
  const coRideCreatorResult = await rideDb.query(
    `SELECT
       css.session_id::text AS id,
       'coride_creator' AS item_type,
       'CoRide (My Post)' AS title,
       NULL AS creator_name,
       css.start_location AS pickup,
       css.destination,
       COALESCE(css.fare_per_person, 0) AS fare,
       TO_CHAR(css.created_at, 'DD Mon YYYY') AS date,
       css.status,
       css.created_at,
       css.is_started,
       css.total_seats,
       COALESCE(css.booked_seats, 0) AS booked_seats,
       css.session_id::text AS session_id
     FROM company_sharing_sessions css
     WHERE css.created_by = $1
     ${buildTimeCondition(time, 'css')}
     ORDER BY css.created_at DESC`,
    [userId]
  );

  // ── Summary merge ──
  const rideSummaryRow = rideSummaryResult.rows[0] || {};
  const reserveSummary = reserveData.summary || {};

  const coRideCount =
    coRideParticipantResult.rowCount + coRideCreatorResult.rowCount;

  // ── type filter এ coride ফিল্টার করা ──
  const shouldShowRide = type === 'all' || type === 'completed' || type === 'cancelled' || type === 'reserved';
  const shouldShowSendItem = type === 'all' || type === 'send_item';
  const shouldShowCoRide = type === 'all' || type === 'coride';
  const shouldShowReserve = type === 'all' || type === 'reserved';

  // ── সব মার্জ ──
  const mergedActivities = [
    ...(shouldShowRide ? (rideActivitiesResult.rows || []).map((row) => ({
      ...row,
      fare: Number(row.fare || 0),
      canCancel: row.can_cancel === true,
    })) : []),

    ...(shouldShowSendItem ? (sendItemResult.rows || []).map((row) => ({
      ...row,
      fare: Number(row.fare || 0),
      canCancel: false,
    })) : []),

    ...(shouldShowReserve ? ((reserveData.activities || []).map((row) => ({
      ...row,
      created_at: row.created_at,
    }))) : []),

    ...(shouldShowCoRide ? (coRideParticipantResult.rows || []).map((row) => ({
      ...row,
      fare: Number(row.fare || 0),
      canCancel: false,
      item_type: 'coride',
    })) : []),

    ...(shouldShowCoRide ? (coRideCreatorResult.rows || []).map((row) => ({
      ...row,
      fare: Number(row.fare || 0),
      canCancel: false,
      item_type: 'coride_creator',
    })) : []),
  ];

  // Date অনুযায়ী sort
  mergedActivities.sort(
    (a, b) => new Date(b.created_at) - new Date(a.created_at)
  );

  const paginatedActivities = mergedActivities.slice(offset, offset + limit);

  return {
    summary: {
      total:
        Number(rideSummaryRow.total || 0) +
        Number(reserveSummary.total || 0) +
        (sendItemResult.rows?.length || 0) +
        coRideCount,
      completed:
        Number(rideSummaryRow.completed || 0) +
        Number(reserveSummary.completed || 0),
      cancelled:
        Number(rideSummaryRow.cancelled || 0) +
        Number(reserveSummary.cancelled || 0),
      earnings:
        Number(rideSummaryRow.earnings || 0) +
        Number(reserveSummary.earnings || 0),
    },
    activities: paginatedActivities,
    emptyState:
      paginatedActivities.length === 0 ? 'No activity found' : null,
  };
};

module.exports = {
  getMyActivity,
  getActivityDashboard,
};
