const rideDb = require('../config/rideDb');

const ALLOWED_FILTERS = [
  'all_active',
  'location_wise',
  'longest_active',
  'recently_activated',
];

const buildOrderBy = (filter) => {
  switch (filter) {
    case 'location_wise':
      return `ORDER BY rider_name ASC`;
    case 'longest_active':
      return `ORDER BY active_since ASC NULLS LAST`;
    case 'recently_activated':
      return `ORDER BY active_since DESC NULLS LAST`;
    case 'all_active':
    default:
      return `ORDER BY rider_name ASC`;
  }
};

const getActiveRiders = async ({
  search = '',
  filter = 'all_active',
  location = '',
  page = 1,
  limit = 20,
}) => {
  const safeFilter = ALLOWED_FILTERS.includes(filter) ? filter : 'all_active';
  const safeLimit = Number.isFinite(limit) && limit > 0 ? Math.min(limit, 100) : 20;
  const safePage = Number.isFinite(page) && page > 0 ? page : 1;
  const offset = (safePage - 1) * safeLimit;

  const params = [];
  let whereClause = `WHERE 1=1`;

  if (search.trim()) {
    params.push(`%${search.trim()}%`);
    whereClause += `
      AND (
        rd.rider_name ILIKE $${params.length}
        OR COALESCE(rd.phone, '') ILIKE $${params.length}
      )
    `;
  }

  const baseCTE = `
    WITH active_rides AS (
      SELECT DISTINCT ON (r.rider_id)
        r.ride_id AS active_ride_id,
        r.rider_id,
        r.created_at AS active_since
      FROM rides r
      WHERE r.status = 'active'
      ORDER BY r.rider_id, r.created_at ASC
    ),
    latest_locations AS (
      SELECT DISTINCT ON (ll.user_id)
        ll.user_id,
        ll.latitude,
        ll.longitude,
        ll.updated_at
      FROM live_locations ll
      ORDER BY ll.user_id, ll.updated_at DESC
    ),
    today_ride_counts AS (
      SELECT
        r.rider_id,
        COUNT(*)::int AS today_ride
      FROM rides r
      WHERE DATE(r.created_at) = CURRENT_DATE
      GROUP BY r.rider_id
    ),
    today_earnings AS (
      SELECT
        t.user_id,
        COALESCE(SUM(
          CASE
            WHEN t.type IN ('ride_income', 'earning', 'rider_credit')
            THEN t.amount
            ELSE 0
          END
        ), 0)::numeric(10,2) AS earning
      FROM transactions t
      WHERE DATE(t.created_at) = CURRENT_DATE
        AND t.status = 'completed'
      GROUP BY t.user_id
    ),
    rider_vehicle AS (
      SELECT DISTINCT ON (v.user_id)
        v.user_id,
        CONCAT(
          UPPER(LEFT(COALESCE(v.vehicle_type, ''), 1)),
          LOWER(SUBSTRING(COALESCE(v.vehicle_type, '') FROM 2)),
          CASE
            WHEN v.company IS NOT NULL OR v.model IS NOT NULL
            THEN ' - ' || TRIM(COALESCE(v.company, '') || ' ' || COALESCE(v.model, ''))
            ELSE ''
          END
        ) AS vehicle_name
      FROM vehicles v
      ORDER BY v.user_id, v.created_at DESC NULLS LAST
    ),
    rd AS (
      SELECT
        u.user_id,
        TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS rider_name,
        u.phone,
        CASE
          WHEN ll.latitude IS NOT NULL AND ll.longitude IS NOT NULL
          THEN ROUND(ll.latitude::numeric, 4)::text || ', ' || ROUND(ll.longitude::numeric, 4)::text
          ELSE 'Location unavailable'
        END AS active_location,
        ar.active_since,
        COALESCE(rv.vehicle_name, 'Vehicle unavailable') AS vehicle,
        COALESCE(trc.today_ride, 0) AS today_ride,
        COALESCE(te.earning, 0) AS earning,
        ar.active_ride_id
      FROM users u
      INNER JOIN active_rides ar ON ar.rider_id = u.user_id
      LEFT JOIN latest_locations ll ON ll.user_id = u.user_id
      LEFT JOIN today_ride_counts trc ON trc.rider_id = u.user_id
      LEFT JOIN today_earnings te ON te.user_id = u.user_id
      LEFT JOIN rider_vehicle rv ON rv.user_id = u.user_id
      WHERE u.account_status = 'active'
    )
  `;

  const statsQuery = `
    ${baseCTE}
    SELECT
      COUNT(*)::int AS total_active_riders,
      COALESCE(
        ROUND(AVG(EXTRACT(EPOCH FROM (NOW() - active_since)) / 60))::int,
        0
      ) AS avg_active_minutes,
      COUNT(*) FILTER (WHERE DATE(active_since) = CURRENT_DATE)::int AS today_active_riders
    FROM rd
    ${whereClause};
  `;

  const orderByClause = buildOrderBy(safeFilter);

  const listParams = [...params];
  listParams.push(safeLimit);
  listParams.push(offset);

  const listQuery = `
    ${baseCTE}
    SELECT
      user_id,
      rider_name AS name,
      phone,
      active_location AS location,
      active_since,
      vehicle,
      today_ride,
      earning
    FROM rd
    ${whereClause}
    ${orderByClause}
    LIMIT $${listParams.length - 1}
    OFFSET $${listParams.length};
  `;

  const countQuery = `
    ${baseCTE}
    SELECT COUNT(*)::int AS total_rows
    FROM rd
    ${whereClause};
  `;

  const [statsResult, listResult, countResult] = await Promise.all([
    rideDb.query(statsQuery, params),
    rideDb.query(listQuery, listParams),
    rideDb.query(countQuery, params),
  ]);

  const statsRow = statsResult.rows[0] || {
    total_active_riders: 0,
    avg_active_minutes: 0,
    today_active_riders: 0,
  };

  const totalRows = countResult.rows[0]?.total_rows || 0;

  const riders = listResult.rows.map((row) => ({
    user_id: row.user_id,
    name: row.name || 'Unknown Rider',
    phone: row.phone || 'N/A',
    location: row.location || 'Location unavailable',
    activeSince: row.active_since,
    vehicle: row.vehicle || 'Vehicle unavailable',
    todayRide: Number(row.today_ride || 0),
    earning: Number(row.earning || 0),
  }));

  return {
    stats: {
      totalActiveRiders: Number(statsRow.total_active_riders || 0),
      avgActiveTime: Number(statsRow.avg_active_minutes || 0),
      todayActiveRiders: Number(statsRow.today_active_riders || 0),
    },
    filters: {
      search,
      filter: safeFilter,
      location,
      page: safePage,
      limit: safeLimit,
      totalRows: Number(totalRows),
      totalPages: Math.ceil(Number(totalRows) / safeLimit),
    },
    riders,
  };
};

module.exports = {
  getActiveRiders,
};
