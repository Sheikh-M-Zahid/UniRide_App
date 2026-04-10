const rideDb = require('../config/rideDb');
const ewuAdminDb = require('../config/ewuAdminDb');

const normalizeStatusFilter = (status) => {
  if (!status) return 'all';

  const value = String(status).trim().toLowerCase();

  if (['all', 'scheduled', 'ongoing', 'completed', 'cancelled'].includes(value)) {
    return value;
  }

  return 'all';
};

const normalizeSafetyFilter = (safety) => {
  if (!safety) return 'all';

  const value = String(safety).trim().toLowerCase();

  if (['all', 'safe', 'flagged'].includes(value)) {
    return value;
  }

  return 'all';
};

const mapRawStatusToFrontendStatus = (rawStatus) => {
  const status = String(rawStatus || '').trim().toLowerCase();

  if (['scheduled', 'active', 'assigned', 'processing'].includes(status)) {
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

const mapOccupationToCreatorType = (occupation) => {
  if (!occupation) return 'User';

  const value = String(occupation).trim().toLowerCase();

  if (value === 'student') return 'Student';
  if (value === 'faculty') return 'Faculty';
  if (value === 'staff') return 'Staff';

  return 'User';
};

const getSharingCaringHistory = async ({ search, status, safety, page = 1, limit = 20, req }) => {
  const safePage = page > 0 ? page : 1;
  const safeLimit = limit > 0 && limit <= 100 ? limit : 20;
  const offset = (safePage - 1) * safeLimit;

  const normalizedStatus = normalizeStatusFilter(status);
  const normalizedSafety = normalizeSafetyFilter(safety);

  const params = [];
  let whereClause = '';

  if (search && search.trim()) {
    params.push(`%${search.trim()}%`);
    whereClause += `
      ${whereClause ? 'AND' : 'WHERE'}
      (
        (COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) ILIKE $${params.length}
        OR CAST(cs.session_id AS TEXT) ILIKE $${params.length}
        OR COALESCE(cs.start_location, '') ILIKE $${params.length}
        OR COALESCE(cs.destination, '') ILIKE $${params.length}
      )
    `;
  }

  const listParams = [...params, safeLimit, offset];

  const baseQuery = `
    SELECT
      cs.session_id,
      cs.created_by,
      cs.start_location,
      cs.destination,
      cs.trip_date,
      cs.trip_time,
      cs.vehicle_type,
      cs.total_seats,
      cs.total_cost,
      cs.per_seat_cost,
      cs.status,
      cs.has_safety_flag,
      cs.safety_note,
      cs.created_at,
      u.first_name,
      u.last_name,
      u.phone,
      u.university_email,
      u.profile_picture,
      COALESCE(cp.joined_members, 0)::int AS joined_members
    FROM company_sharing_sessions cs
    JOIN users u
      ON cs.created_by = u.user_id
    LEFT JOIN (
      SELECT
        session_id,
        COUNT(*)::int AS joined_members
      FROM company_participants
      GROUP BY session_id
    ) cp
      ON cp.session_id = cs.session_id
    ${whereClause}
  `;

  const listQuery = `
    ${baseQuery}
    ORDER BY COALESCE(cs.trip_date::timestamp, cs.created_at) DESC, cs.created_at DESC
    LIMIT $${listParams.length - 1}
    OFFSET $${listParams.length}
  `;

  const countQuery = `
    SELECT COUNT(*)::int AS total
    FROM company_sharing_sessions cs
    JOIN users u
      ON cs.created_by = u.user_id
    ${whereClause}
  `;

  const [listRes, countRes] = await Promise.all([
    rideDb.query(listQuery, listParams),
    rideDb.query(countQuery, params),
  ]);

  const creatorEmails = [
    ...new Set(
      listRes.rows
        .map((row) => row.university_email)
        .filter(Boolean)
    ),
  ];

  let creatorTypeMap = new Map();

  if (creatorEmails.length > 0) {
    const occRes = await ewuAdminDb.query(
      `SELECT university_email, occupation
       FROM ewu_users
       WHERE university_email = ANY($1::text[])`,
      [creatorEmails]
    );

    creatorTypeMap = new Map(
      occRes.rows.map((row) => [row.university_email, row.occupation])
    );
  }

  let items = listRes.rows.map((row) => {
    const tripStatus = mapRawStatusToFrontendStatus(row.status);
    const creatorOccupation = creatorTypeMap.get(row.university_email) || null;

    return {
      trip_id: row.session_id,
      creator_name: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
      creator_type: mapOccupationToCreatorType(creatorOccupation),
      creator_phone: row.phone || '',
      creator_photo_url: buildProfileImageUrl(req, row.profile_picture),
      vehicle_type: row.vehicle_type || '',
      pickup_location: row.start_location || '',
      destination_location: row.destination || '',
      trip_date: row.trip_date || null,
      trip_time: row.trip_time || null,
      total_seats: Number(row.total_seats || 0),
      joined_members: Number(row.joined_members || 0),
      total_cost: Number(row.total_cost || 0),
      per_seat_cost: Number(row.per_seat_cost || 0),
      trip_status: tripStatus,
      has_safety_flag: Boolean(row.has_safety_flag),
      safety_note: row.safety_note || '',
    };
  });

  if (normalizedStatus !== 'all') {
    items = items.filter((item) => item.trip_status === normalizedStatus);
  }

  if (normalizedSafety !== 'all') {
    items = items.filter((item) =>
      normalizedSafety === 'flagged'
        ? item.has_safety_flag === true
        : item.has_safety_flag === false
    );
  }

  return {
    items,
    pagination: {
      page: safePage,
      limit: safeLimit,
      total: normalizedStatus === 'all' && normalizedSafety === 'all'
        ? Number(countRes.rows[0]?.total || 0)
        : items.length,
      hasMore: normalizedStatus === 'all' && normalizedSafety === 'all'
        ? offset + listRes.rows.length < Number(countRes.rows[0]?.total || 0)
        : false,
    },
    filters: {
      search,
      status: normalizedStatus,
      safety: normalizedSafety,
    },
  };
};

module.exports = {
  getSharingCaringHistory,
};