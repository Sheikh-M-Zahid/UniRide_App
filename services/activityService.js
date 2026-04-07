const rideDb = require('../config/rideDb');

const ALLOWED_TYPES = ['all', 'completed', 'cancelled', 'reserved', 'send_item'];
const ALLOWED_TIMES = ['today', 'this_week', 'this_month'];

const getDateRange = (time) => {
  const safeTime = ALLOWED_TIMES.includes(time) ? time : 'today';

  if (safeTime === 'this_month') {
    return {
      startExpr: `DATE_TRUNC('month', CURRENT_DATE)`,
      endExpr: `DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'`,
      safeTime,
    };
  }

  if (safeTime === 'this_week') {
    return {
      startExpr: `DATE_TRUNC('week', CURRENT_DATE)`,
      endExpr: `DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days'`,
      safeTime,
    };
  }

  return {
    startExpr: `CURRENT_DATE`,
    endExpr: `CURRENT_DATE + INTERVAL '1 day'`,
    safeTime: 'today',
  };
};

const formatActivityRow = (row) => ({
  id: row.activity_id,
  title: row.title || 'Activity',
  type: row.type || 'unknown',
  status: row.status || 'unknown',
  name: row.name || 'Unknown',
  phone: row.phone || 'N/A',
  pickup: row.pickup || 'Pickup unavailable',
  destination: row.destination || 'Destination unavailable',
  time: row.time || '--:--',
  fare: Number(row.fare || 0),
  date: row.date,
  createdAt: row.created_at,
});

const getActivityDashboard = async ({
  userId,
  type = 'all',
  time = 'today',
  page = 1,
  limit = 20,
}) => {
  const safeType = ALLOWED_TYPES.includes(type) ? type : 'all';
  const { startExpr, endExpr, safeTime } = getDateRange(time);
  const safePage = Number.isFinite(page) && page > 0 ? page : 1;
  const safeLimit = Number.isFinite(limit) && limit > 0 ? Math.min(limit, 100) : 20;
  const offset = (safePage - 1) * safeLimit;

  const params = [userId];
  let typeWhere = '';

  if (safeType === 'completed') {
    typeWhere = `WHERE merged.type = 'completed'`;
  } else if (safeType === 'cancelled') {
    typeWhere = `WHERE merged.type = 'cancelled'`;
  } else if (safeType === 'reserved') {
    typeWhere = `WHERE merged.type = 'reserved'`;
  } else if (safeType === 'send_item') {
    typeWhere = `WHERE merged.type = 'send_item'`;
  }

  const baseCTE = `
    WITH ride_activity AS (
      SELECT
        r.id::text AS activity_id,
        CASE
          WHEN r.status = 'completed' THEN 'Ride Completed'
          WHEN r.status = 'cancelled' THEN 'Ride Cancelled'
          WHEN r.status IN ('scheduled', 'reserved')
               OR (
                 r.trip_date IS NOT NULL
                 AND r.trip_date > CURRENT_DATE
               )
          THEN 'Reserved Ride'
          ELSE 'Ride Activity'
        END AS title,
        CASE
          WHEN r.status = 'completed' THEN 'completed'
          WHEN r.status = 'cancelled' THEN 'cancelled'
          WHEN r.status IN ('scheduled', 'reserved')
               OR (
                 r.trip_date IS NOT NULL
                 AND r.trip_date > CURRENT_DATE
               )
          THEN 'reserved'
          ELSE 'other'
        END AS type,
        r.status,
        COALESCE(
          passenger.first_name || ' ' || passenger.last_name,
          'Passenger not assigned'
        ) AS name,
        COALESCE(passenger.phone, 'N/A') AS phone,
        COALESCE(r.start_location, 'Pickup unavailable') AS pickup,
        COALESCE(r.destination, 'Destination unavailable') AS destination,
        COALESCE(r.trip_time::text, TO_CHAR(r.created_at, 'HH24:MI')) AS time,
        COALESCE(rp.fare, r.total_fare, 0) AS fare,
        DATE(COALESCE(r.trip_date::timestamp, r.created_at)) AS date,
        COALESCE(r.trip_date::timestamp, r.created_at) AS created_at
      FROM rides r
      LEFT JOIN LATERAL (
        SELECT
          rp.user_id,
          rp.fare
        FROM ride_participants rp
        WHERE rp.ride_id = r.id
        ORDER BY rp.created_at ASC NULLS LAST
        LIMIT 1
      ) rp ON true
      LEFT JOIN users passenger
        ON passenger.user_id = rp.user_id
      WHERE r.rider_id = $1
        AND COALESCE(r.trip_date::timestamp, r.created_at) >= ${startExpr}
        AND COALESCE(r.trip_date::timestamp, r.created_at) < ${endExpr}
        AND (
          r.status IN ('completed', 'cancelled', 'scheduled', 'reserved')
          OR (
            r.trip_date IS NOT NULL
            AND r.trip_date > CURRENT_DATE
          )
        )
    ),
    send_item_activity AS (
      SELECT
        si.send_item_id::text AS activity_id,
        'Send Item Delivery' AS title,
        'send_item' AS type,
        COALESCE(si.status, 'unknown') AS status,
        COALESCE(receiver.first_name || ' ' || receiver.last_name, 'Receiver') AS name,
        COALESCE(receiver.phone, 'N/A') AS phone,
        COALESCE(si.pickup_location, 'Pickup unavailable') AS pickup,
        COALESCE(si.delivery_location, si.destination, 'Destination unavailable') AS destination,
        TO_CHAR(si.created_at, 'HH24:MI') AS time,
        COALESCE(si.delivery_fee, 0) AS fare,
        DATE(si.created_at) AS date,
        si.created_at
      FROM send_items si
      LEFT JOIN users receiver
        ON receiver.user_id = si.receiver_id
      WHERE si.rider_id = $1
        AND si.created_at >= ${startExpr}
        AND si.created_at < ${endExpr}
    ),
    merged AS (
      SELECT * FROM ride_activity
      UNION ALL
      SELECT * FROM send_item_activity
    )
  `;

  const summaryQuery = `
    ${baseCTE}
    SELECT
      COUNT(*)::int AS total,
      COUNT(*) FILTER (WHERE merged.type = 'completed')::int AS completed,
      COUNT(*) FILTER (WHERE merged.type = 'cancelled')::int AS cancelled,
      COALESCE(
        SUM(
          CASE
            WHEN merged.type IN ('completed', 'send_item')
            THEN merged.fare
            ELSE 0
          END
        ),
        0
      )::numeric(10,2) AS earnings
    FROM merged
    ${typeWhere};
  `;

  const listParams = [...params, safeLimit, offset];

  const listQuery = `
    ${baseCTE}
    SELECT
      merged.activity_id,
      merged.title,
      merged.type,
      merged.status,
      merged.name,
      merged.phone,
      merged.pickup,
      merged.destination,
      merged.time,
      merged.fare,
      merged.date,
      merged.created_at
    FROM merged
    ${typeWhere}
    ORDER BY merged.created_at DESC
    LIMIT $2 OFFSET $3;
  `;

  const countQuery = `
    ${baseCTE}
    SELECT COUNT(*)::int AS total_rows
    FROM merged
    ${typeWhere};
  `;

  const earningsQuery = `
    SELECT
      COALESCE(SUM(t.amount), 0)::numeric(10,2) AS earnings
    FROM transactions t
    WHERE t.user_id = $1
      AND t.status = 'completed'
      AND t.created_at >= ${startExpr}
      AND t.created_at < ${endExpr}
      AND t.type IN ('ride_income', 'earning', 'rider_credit', 'delivery_income');
  `;

  const [summaryResult, listResult, countResult, earningsResult] = await Promise.all([
    rideDb.query(summaryQuery, params),
    rideDb.query(listQuery, listParams),
    rideDb.query(countQuery, params),
    rideDb.query(earningsQuery, params),
  ]);

  const summary = summaryResult.rows[0] || {
    total: 0,
    completed: 0,
    cancelled: 0,
    earnings: 0,
  };

  const transactionEarnings = Number(earningsResult.rows[0]?.earnings || 0);
  const mergedFareEarnings = Number(summary.earnings || 0);

  const activities = listResult.rows.map(formatActivityRow);
  const totalRows = Number(countResult.rows[0]?.total_rows || 0);

  return {
    summary: {
      total: Number(summary.total || 0),
      completed: Number(summary.completed || 0),
      cancelled: Number(summary.cancelled || 0),
      earnings: transactionEarnings > 0 ? transactionEarnings : mergedFareEarnings,
    },
    filters: {
      type: safeType,
      time: safeTime,
      page: safePage,
      limit: safeLimit,
      totalRows,
      totalPages: Math.ceil(totalRows / safeLimit),
    },
    activities,
    emptyState: activities.length === 0 ? 'No activity found' : null,
  };
};

module.exports = {
  getActivityDashboard,
};