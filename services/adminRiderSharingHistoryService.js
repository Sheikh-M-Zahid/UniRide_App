const rideDb = require('../config/rideDb');

const normalizeStatusFilter = (status) => {
  if (!status) return 'all';

  const value = String(status).trim().toLowerCase();

  if (['all', 'scheduled', 'ongoing', 'completed', 'cancelled'].includes(value)) {
    return value;
  }

  return 'all';
};

const mapRawStatusToFrontendStatus = (rawStatus) => {
  const status = String(rawStatus || '').trim().toLowerCase();

  if (['assigned', 'active', 'scheduled', 'reserve', 'processing'].includes(status)) {
    return 'scheduled';
  }

  if (status === 'ongoing') {
    return 'ongoing';
  }

  if (status === 'completed') {
    return 'completed';
  }

  if (status === 'cancelled') {
    return 'cancelled';
  }

  return 'scheduled';
};

const buildProfileImageUrl = (req, storedPath) => {
  if (!storedPath) return null;

  if (storedPath.startsWith('http://') || storedPath.startsWith('https://')) {
    return storedPath;
  }

  const baseUrl = `${req.protocol}://${req.get('host')}`;
  return `${baseUrl}${storedPath}`;
};

const getRiderSharingHistory = async ({ search, status, page = 1, limit = 20, req }) => {
  const safePage = page > 0 ? page : 1;
  const safeLimit = limit > 0 && limit <= 100 ? limit : 20;
  const offset = (safePage - 1) * safeLimit;
  const normalizedStatus = normalizeStatusFilter(status);

  const params = [];
  let whereClause = '';

  if (search && search.trim()) {
    params.push(`%${search.trim()}%`);
    whereClause += `
      ${whereClause ? 'AND' : 'WHERE'}
      (
        (COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) ILIKE $${params.length}
        OR CAST(r.ride_id AS TEXT) ILIKE $${params.length}
        OR COALESCE(v.number_plate, '') ILIKE $${params.length}
      )
    `;
  }

  const listParams = [...params, safeLimit, offset];

  const baseQuery = `
    SELECT
      r.ride_id,
      r.rider_id,
      r.vehicle_id,
      r.start_location,
      r.destination,
      r.total_fare,
      r.available_seats,
      r.status,
      r.travel_date,
      r.travel_time,
      r.vehicle_type,
      r.created_at,
      u.first_name,
      u.last_name,
      u.phone,
      u.profile_picture,
      v.vehicle_type AS db_vehicle_type,
      v.number_plate,
      v.total_seats,
      COALESCE(pc.booked_seats, 0)::int AS booked_seats
    FROM rides r
    JOIN users u
      ON r.rider_id = u.user_id
    LEFT JOIN vehicles v
      ON r.vehicle_id = v.vehicle_id
    LEFT JOIN (
      SELECT
        ride_id,
        COUNT(*)::int AS booked_seats
      FROM ride_participants
      GROUP BY ride_id
    ) pc
      ON pc.ride_id = r.ride_id
    ${whereClause}
  `;

  const listQuery = `
    ${baseQuery}
    ORDER BY COALESCE(r.travel_date::timestamp, r.created_at) DESC, r.created_at DESC
    LIMIT $${listParams.length - 1}
    OFFSET $${listParams.length}
  `;

  const countQuery = `
    SELECT COUNT(*)::int AS total
    FROM rides r
    JOIN users u
      ON r.rider_id = u.user_id
    LEFT JOIN vehicles v
      ON r.vehicle_id = v.vehicle_id
    ${whereClause}
  `;

  const [listRes, countRes] = await Promise.all([
    rideDb.query(listQuery, listParams),
    rideDb.query(countQuery, params),
  ]);

  let items = listRes.rows.map((row) => {
    const rideStatus = mapRawStatusToFrontendStatus(row.status);

    // safest offered seats inference:
    // if vehicle.total_seats exists -> use that
    // else fallback to booked_seats + available_seats
    const offeredSeats =
      row.total_seats !== null && row.total_seats !== undefined
        ? Number(row.total_seats)
        : Number(row.booked_seats || 0) + Number(row.available_seats || 0);

    return {
      ride_id: row.ride_id,
      rider_name: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
      rider_phone: row.phone || '',
      rider_photo_url: buildProfileImageUrl(req, row.profile_picture),
      vehicle_type: row.vehicle_type || row.db_vehicle_type || '',
      vehicle_number: row.number_plate || '',
      pickup_location: row.start_location || '',
      destination_location: row.destination || '',
      departure_time: row.travel_time || null,
      ride_date: row.travel_date || null,
      offered_seats: offeredSeats,
      booked_seats: Number(row.booked_seats || 0),
      fare: Number(row.total_fare || 0),
      ride_status: rideStatus,
    };
  });

  if (normalizedStatus !== 'all') {
    items = items.filter((item) => item.ride_status === normalizedStatus);
  }

  const summary = {
    totalRides: items.length,
    completedCount: items.filter((item) => item.ride_status === 'completed').length,
    cancelledCount: items.filter((item) => item.ride_status === 'cancelled').length,
    scheduledCount: items.filter((item) => item.ride_status === 'scheduled').length,
    ongoingCount: items.filter((item) => item.ride_status === 'ongoing').length,
  };

  return {
    summary,
    items,
    pagination: {
      page: safePage,
      limit: safeLimit,
      total: normalizedStatus === 'all'
        ? Number(countRes.rows[0]?.total || 0)
        : items.length,
      hasMore: normalizedStatus === 'all'
        ? offset + listRes.rows.length < Number(countRes.rows[0]?.total || 0)
        : false,
    },
    filters: {
      search,
      status: normalizedStatus,
    },
  };
};

module.exports = {
  getRiderSharingHistory,
};