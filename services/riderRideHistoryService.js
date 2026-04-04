const rideDb = require('../config/rideDb');

const buildDateFilter = ({ range, month, year, values }) => {
  let clause = '';

  if (range === 'today') {
    clause += ` AND DATE(COALESCE(r.travel_date, r.created_at)) = CURRENT_DATE `;
  } else if (range === 'week') {
    clause += `
      AND DATE(COALESCE(r.travel_date, r.created_at))
          BETWEEN date_trunc('week', CURRENT_DATE)::date
          AND (date_trunc('week', CURRENT_DATE)::date + INTERVAL '6 days')
    `;
  } else if (range === 'month') {
    clause += `
      AND EXTRACT(MONTH FROM COALESCE(r.travel_date, r.created_at)) = EXTRACT(MONTH FROM CURRENT_DATE)
      AND EXTRACT(YEAR FROM COALESCE(r.travel_date, r.created_at)) = EXTRACT(YEAR FROM CURRENT_DATE)
    `;
  }

  if (month && year) {
    values.push(Number(month));
    values.push(Number(year));

    clause += `
      AND EXTRACT(MONTH FROM COALESCE(r.travel_date, r.created_at)) = $${values.length - 1}
      AND EXTRACT(YEAR FROM COALESCE(r.travel_date, r.created_at)) = $${values.length}
    `;
  }

  return clause;
};

const buildSearchFilter = ({ search, values }) => {
  if (!search || !search.trim()) return '';

  const trimmed = `%${search.trim()}%`;
  values.push(trimmed, trimmed);

  return `
    AND (
      CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, '')) ILIKE $${values.length - 1}
      OR COALESCE(u.phone, '') ILIKE $${values.length}
    )
  `;
};

const getRideHistory = async ({
  riderId,
  search,
  range,
  month,
  year,
  page = 1,
  limit = 20,
}) => {
  const safePage = page > 0 ? page : 1;
  const safeLimit = limit > 0 && limit <= 100 ? limit : 20;
  const offset = (safePage - 1) * safeLimit;

  const values = [riderId];

  const searchFilter = buildSearchFilter({ search, values });
  const dateFilter = buildDateFilter({ range, month, year, values });

  values.push(safeLimit, offset);

  const query = `
    SELECT
      COALESCE(r.travel_date::timestamp, r.created_at) AS pickup_date,
      u.first_name,
      u.last_name,
      u.phone,
      r.start_location AS pickup_location,
      r.destination,
      r.total_distance_km AS distance,
      rp.fare AS earning,
      r.ride_id,
      r.created_at
    FROM rides r
    INNER JOIN ride_participants rp
      ON rp.ride_id = r.ride_id
    INNER JOIN users u
      ON u.user_id = rp.passenger_id
    WHERE r.rider_id = $1
      AND r.status = 'completed'
      ${searchFilter}
      ${dateFilter}
    ORDER BY COALESCE(r.travel_date::timestamp, r.created_at) DESC, r.created_at DESC
    LIMIT $${values.length - 1}
    OFFSET $${values.length};
  `;

  const countValues = values.slice(0, values.length - 2);

  const countQuery = `
    SELECT COUNT(*)::int AS total
    FROM rides r
    INNER JOIN ride_participants rp
      ON rp.ride_id = r.ride_id
    INNER JOIN users u
      ON u.user_id = rp.passenger_id
    WHERE r.rider_id = $1
      AND r.status = 'completed'
      ${searchFilter}
      ${dateFilter};
  `;

  const [result, countResult] = await Promise.all([
    rideDb.query(query, values),
    rideDb.query(countQuery, countValues),
  ]);

  const items = result.rows.map((row) => ({
    pickupDate: row.pickup_date,
    passengerName: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
    phoneNumber: row.phone || '',
    pickupLocation: row.pickup_location || '',
    destination: row.destination || '',
    distance: Number(row.distance || 0),
    earning: Number(row.earning || 0),
  }));

  return {
    items,
    pagination: {
      page: safePage,
      limit: safeLimit,
      total: countResult.rows[0]?.total || 0,
      hasMore: offset + items.length < (countResult.rows[0]?.total || 0),
    },
    filters: {
      search,
      range,
      month,
      year,
    },
  };
};

module.exports = {
  getRideHistory,
};