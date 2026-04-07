const rideDb = require('../config/rideDb');

/* =========================
   LOCATION HELPER
========================= */
const getLocation = (user) => {
  return (
    user.campus_address ||
    user.hostel_address ||
    user.home_address ||
    'N/A'
  );
};

/* =========================
   FETCH RIDERS
========================= */
const getAllRiders = async (query) => {
  const {
    search = '',
    filter = 'all',
  } = query;

  let conditions = [];
  let values = [];

  // search
  if (search) {
    values.push(`%${search}%`);
    conditions.push(`
      (
        u.first_name ILIKE $${values.length}
        OR u.last_name ILIKE $${values.length}
        OR u.phone ILIKE $${values.length}
      )
    `);
  }

  // filter
  if (filter === 'due') {
    conditions.push(`u.due_balance > 0`);
  }

  if (filter === 'active') {
    conditions.push(`u.account_status = 'active'`);
  }

  if (filter === 'suspended') {
    conditions.push(`u.account_status = 'suspended'`);
  }

  if (filter === 'recent') {
    conditions.push(`u.created_at >= NOW() - INTERVAL '7 days'`);
  }

  const whereClause = conditions.length ? `AND ${conditions.join(' AND ')}` : '';

  const result = await rideDb.query(
    `
    SELECT
      u.user_id,
      u.first_name,
      u.last_name,
      u.phone,
      u.home_address,
      u.hostel_address,
      u.campus_address,
      u.due_balance,
      u.account_status,
      u.created_at
    FROM users u
    WHERE EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.user_id = u.user_id
    )
    ${whereClause}
    ORDER BY u.created_at DESC
    `
  );

  return result.rows.map((u) => ({
    id: u.user_id, // ✅ UUID safe
    name: `${u.first_name || ''} ${u.last_name || ''}`.trim(),
    phone: u.phone,
    location: getLocation(u),
    status: u.account_status,
    due: Number(u.due_balance || 0),
    joined_at: u.created_at,
  }));
};

/* =========================
   UPDATE STATUS
========================= */
const updateRiderStatus = async ({ userId, status }) => {
  const allowed = ['active', 'suspended'];

  if (!allowed.includes(status)) {
    throw new Error('Invalid status');
  }

  // ensure rider exists
  const riderCheck = await rideDb.query(
    `
    SELECT u.user_id
    FROM users u
    WHERE u.user_id = $1
      AND EXISTS (
        SELECT 1 FROM vehicles v
        WHERE v.user_id = u.user_id
      )
    `,
    [userId]
  );

  if (!riderCheck.rows.length) {
    throw new Error('Rider not found');
  }

  await rideDb.query(
    `
    UPDATE users
    SET account_status = $1
    WHERE user_id = $2
    `,
    [status, userId]
  );

  return {
    userId,
    status,
  };
};

module.exports = {
  getAllRiders,
  updateRiderStatus,
};