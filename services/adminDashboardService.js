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
  const adminPromise = rideDb.query(
    `
    SELECT
      u.user_id,
      TRIM(CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, ''))) AS name,
      u.university_email AS email,
      u.profile_picture
    FROM users u
    INNER JOIN user_roles ur
      ON ur.user_id = u.user_id
    WHERE u.user_id = $1
      AND ur.role = 'admin'
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

      (
        SELECT COUNT(*)::int
        FROM users
        WHERE account_status IS NULL OR account_status <> 'active'
      ) AS inactive_users,

      (
        SELECT COUNT(DISTINCT ra.rider_id)::int
        FROM rider_availability ra
        INNER JOIN vehicles v
          ON v.user_id = ra.rider_id
        WHERE ra.is_active = true
          AND v.verified = true
      ) AS active_riders,

      (
        SELECT COUNT(DISTINCT v.user_id)::int
        FROM vehicles v
        WHERE v.verified = true
      ) - (
        SELECT COUNT(DISTINCT ra.rider_id)::int
        FROM rider_availability ra
        INNER JOIN vehicles v
          ON v.user_id = ra.rider_id
        WHERE ra.is_active = true
          AND v.verified = true
      ) AS inactive_riders,

      (
        SELECT COUNT(*)::int
        FROM transactions
        WHERE status = 'pending'
      ) AS pending_payment_requests,

      (
        SELECT COUNT(*)::int
        FROM reports
        WHERE status = 'unsolved'
          AND COALESCE(is_spam, false) = false
      ) AS pending_reports
    `
  );

  const registeredUsersPromise = rideDb.query(
    `
    SELECT university_email
    FROM users
    WHERE university_email IS NOT NULL
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

  const [adminRes, rideStatsRes, registeredUsersRes, monthlyRideRes] = await Promise.all([
    adminPromise,
    rideStatsPromise,
    registeredUsersPromise,
    monthlyRidePromise,
  ]);

  if (!adminRes.rows.length) {
    throw new Error('Admin user not found or admin role is missing.');
  }

  const registeredEmails = registeredUsersRes.rows
    .map((row) => row.university_email)
    .filter(Boolean);

  let occupationRow = {
    student: 0,
    faculty: 0,
    staff: 0,
  };

  if (registeredEmails.length > 0) {
    const occupationStatsRes = await ewuAdminDb.query(
      `
      SELECT
        COUNT(*) FILTER (WHERE occupation = 'student')::int AS student,
        COUNT(*) FILTER (WHERE occupation = 'faculty')::int AS faculty,
        COUNT(*) FILTER (WHERE occupation = 'staff')::int AS staff
      FROM ewu_users
      WHERE status = TRUE
        AND university_email = ANY($1::text[])
      `,
      [registeredEmails]
    );

    occupationRow = occupationStatsRes.rows[0] || occupationRow;
  }

  const adminRow = adminRes.rows[0];
  const statsRow = rideStatsRes.rows[0];

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
      name: adminRow.name && adminRow.name.trim() ? adminRow.name.trim() : 'Admin',
      email: adminRow.email || '',
      profileImage: buildProfileImageUrl(req, adminRow.profile_picture || ''),
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
    pendingReports: Number(statsRow.pending_reports || 0),
  };
};

module.exports = {
  getDashboardSummary,
};
