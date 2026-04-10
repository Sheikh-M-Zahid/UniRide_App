const rideDb = require('../config/rideDb');
const ewuAdminDb = require('../config/ewuAdminDb');

const normalizeFilter = (filter) => {
  if (!filter) return 'all';

  const value = String(filter).trim().toLowerCase();

  if (['all', 'student', 'faculty', 'staff'].includes(value)) {
    return value;
  }

  return 'all';
};

const getLocation = (row) => {
  return (
    row.campus_address ||
    row.hostel_address ||
    row.home_address ||
    'N/A'
  );
};

const mapOccupation = (occupation) => {
  if (!occupation) return 'User';

  const value = String(occupation).trim().toLowerCase();

  if (value === 'student') return 'Student';
  if (value === 'faculty') return 'Faculty';
  if (value === 'staff') return 'Staff';

  return 'User';
};

const getAllPassengers = async ({ search, filter, page = 1, limit = 20 }) => {
  const safePage = page > 0 ? page : 1;
  const safeLimit = limit > 0 && limit <= 100 ? limit : 20;
  const offset = (safePage - 1) * safeLimit;
  const normalizedFilter = normalizeFilter(filter);

  const params = [];
  let whereClause = '';

  if (search && search.trim()) {
    params.push(`%${search.trim()}%`);
    whereClause += `
      ${whereClause ? 'AND' : 'WHERE'}
      (
        COALESCE(u.first_name, '') ILIKE $${params.length}
        OR COALESCE(u.last_name, '') ILIKE $${params.length}
        OR (COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) ILIKE $${params.length}
      )
    `;
  }

  const listParams = [...params, safeLimit, offset];

  const listQuery = `
    SELECT
      u.user_id,
      u.first_name,
      u.last_name,
      u.phone,
      u.university_email,
      u.home_address,
      u.hostel_address,
      u.campus_address,
      u.created_at,
      EXISTS (
        SELECT 1
        FROM vehicles v
        WHERE v.user_id = u.user_id
      ) AS is_rider
    FROM users u
    ${whereClause}
    ORDER BY u.created_at DESC
    LIMIT $${listParams.length - 1}
    OFFSET $${listParams.length}
  `;

  const countQuery = `
    SELECT COUNT(*)::int AS total
    FROM users u
    ${whereClause}
  `;

  const [listRes, countRes] = await Promise.all([
    rideDb.query(listQuery, listParams),
    rideDb.query(countQuery, params),
  ]);

  const emails = [
    ...new Set(
      listRes.rows
        .map((row) => row.university_email)
        .filter(Boolean)
    ),
  ];

  let occupationMap = new Map();

  if (emails.length > 0) {
    const occupationRes = await ewuAdminDb.query(
      `SELECT university_email, occupation
       FROM ewu_users
       WHERE university_email = ANY($1::text[])`,
      [emails]
    );

    occupationMap = new Map(
      occupationRes.rows.map((row) => [
        row.university_email,
        row.occupation,
      ])
    );
  }

  let passengers = listRes.rows.map((row) => {
    const occupation = occupationMap.get(row.university_email) || null;

    return {
      id: row.user_id, // UUID safe
      name: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
      phone: row.phone || '',
      email: row.university_email || '',
      location: getLocation(row),
      user_type: mapOccupation(occupation),
      is_rider: Boolean(row.is_rider),
      joined_at: row.created_at,
    };
  });

  if (normalizedFilter !== 'all') {
    passengers = passengers.filter(
      (item) => item.user_type.toLowerCase() === normalizedFilter
    );
  }

  return {
    items: passengers,
    pagination: {
      page: safePage,
      limit: safeLimit,
      total: normalizedFilter === 'all'
        ? Number(countRes.rows[0]?.total || 0)
        : passengers.length,
      hasMore: normalizedFilter === 'all'
        ? offset + passengers.length < Number(countRes.rows[0]?.total || 0)
        : false,
    },
    filters: {
      search,
      filter: normalizedFilter,
    },
  };
};

module.exports = {
  getAllPassengers,
};