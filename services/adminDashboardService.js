const rideDb = require('../config/rideDb');
const ewuAdminDb = require('../config/ewuAdminDb');

const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

const buildProfileImageUrl = (req, storedPath) => {
  if (!storedPath) return null;

  if (storedPath.startsWith('http://') || storedPath.startsWith('https://')) {
    return storedPath;
  }

  const baseUrl = `${req.protocol}://${req.get('host')}`;
  return `${baseUrl}${storedPath}`;
};

const getDashboardSummary = async ({ adminId, req }) => {
  const adminPromise = ewuAdminDb.query(
    `
    SELECT
      id,
      name,
      email
    FROM admins
    WHERE id = $1
    LIMIT 1
    `,
    [adminId]
  );

  const rideStatsPromise = rideDb.query(
    `
    SELECT
      (SELECT COUNT(*)::int FROM rides) AS total_ride,
      (SELECT COUNT(*)::int FROM users) AS total_user,
      (SELECT COUNT(*)::int FROM users WHERE account_status = 'active') AS active_users,
      (SELECT COUNT(*)::int FROM users WHERE account_status <> 'active' OR account_status IS NULL) AS inactive_users,
      (
        SELECT COUNT(*)::int
        FROM rider_availability
        WHERE is_active = true
      ) AS active_riders,
      (
        SELECT COUNT(*)::int
        FROM users u
        WHERE EXISTS (
          SELECT 1
          FROM vehicles v
          WHERE v.user_id = u.user_id
        )
      ) - (
        SELECT COUNT(*)::int
        FROM rider_availability
        WHERE is_active = true
      ) AS inactive_riders,
      (
        SELECT COUNT(*)::int
        FROM transactions
        WHERE status = 'pending'
      ) AS pending_payment_requests
    `
  );

  const occupationStatsPromise = ewuAdminDb.query(
    `
    SELECT
      COUNT(*) FILTER (WHERE occupation = 'student')::int AS student,
      COUNT(*) FILTER (WHERE occupation = 'faculty')::int AS faculty,
      COUNT(*) FILTER (WHERE occupation = 'staff')::int AS staff
    FROM ewu_users
    WHERE status = TRUE
    `
  );

  const monthlyRidePromise = rideDb.query(
    `
    WITH month_series AS (
      SELECT generate_series(
        date_trunc('month', CURRENT_DATE) - INTERVAL '4 months',
        date_trunc('month', CURRENT_DATE),
        INTERVAL '1 month'
      )::date AS month_start
    ),
    ride_counts AS (
      SELECT
        date_trunc('month', COALESCE(travel_date::timestamp, created_at))::date AS month_start,
        COUNT(*)::int AS ride_count
      FROM rides
      GROUP BY 1
    )
    SELECT
      ms.month_start,
      COALESCE(rc.ride_count, 0) AS ride_count
    FROM month_series ms
    LEFT JOIN ride_counts rc
      ON rc.month_start = ms.month_start
    ORDER BY ms.month_start ASC
    `
  );

  const [adminRes, rideStatsRes, occupationStatsRes, monthlyRideRes] = await Promise.all([
    adminPromise,
    rideStatsPromise,
    occupationStatsPromise,
    monthlyRidePromise,
  ]);

  if (!adminRes.rows.length) {
    throw new Error('Admin not found.');
  }

  const adminRow = adminRes.rows[0];
  const statsRow = rideStatsRes.rows[0];
  const occupationRow = occupationStatsRes.rows[0];

  const activeRiders = Math.max(Number(statsRow.active_riders || 0), 0);
  const inactiveRiders = Math.max(Number(statsRow.inactive_riders || 0), 0);
  const activeUsers = Math.max(Number(statsRow.active_users || 0), 0);
  const inactiveUsers = Math.max(Number(statsRow.inactive_users || 0), 0);

  const last5MonthsRide = monthlyRideRes.rows.map((row) => {
    const date = new Date(row.month_start);
    return {
      month: `${monthNames[date.getUTCMonth()]} ${String(date.getUTCFullYear()).slice(-2)}`,
      count: Number(row.ride_count || 0),
    };
  });

  return {
    admin: {
      name: adminRow.name,
      email: adminRow.email,
      profileImage: buildProfileImageUrl(req, adminRow.profile_image || ''),
    },
    stats: {
      totalRide: Number(statsRow.total_ride || 0),
      totalUser: Number(statsRow.total_user || 0),
      student: Number(occupationRow.student || 0),
      faculty: Number(occupationRow.faculty || 0),
      staff: Number(occupationRow.staff || 0),
    },
    activeRidersChart: {
      active: activeRiders,
      inactive: inactiveRiders,
    },
    activeUsersChart: {
      active: activeUsers,
      inactive: inactiveUsers,
    },
    last5MonthsRide,
    pendingPaymentRequests: Number(statsRow.pending_payment_requests || 0),
  };
};

module.exports = {
  getDashboardSummary,
};