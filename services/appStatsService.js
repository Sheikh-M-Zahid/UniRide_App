const rideDb = require('../config/rideDb');
const ewuAdminDb = require('../config/ewuAdminDb');

const getAppStats = async () => {

  
  //   CORE AGGREGATION QUERY
 
  const statsQuery = `
    WITH
    total_users_cte AS (
      SELECT COUNT(*) AS total_users FROM users
    ),

    total_riders_cte AS (
      SELECT COUNT(DISTINCT user_id) AS total_riders FROM vehicles
    ),

    ride_stats AS (
      SELECT
        COUNT(*) FILTER (WHERE status = 'completed') AS total_completed_rides,
        COUNT(*) FILTER (WHERE status = 'cancelled') AS total_cancelled_rides,
        COUNT(*) FILTER (WHERE gender_preference = 'male') AS male_preference_count,
        COUNT(*) FILTER (WHERE gender_preference = 'female') AS female_preference_count,
        COUNT(*) FILTER (WHERE gender_preference = 'any') AS no_preference_count
      FROM rides
    ),

    new_users AS (
      SELECT
        COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days') AS new_users_this_week,
        COUNT(*) FILTER (WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', NOW())) AS new_users_this_month
      FROM users
    ),

    active_users_today_cte AS (
      SELECT COUNT(DISTINCT user_id) AS active_users_today
      FROM (
        SELECT rider_id AS user_id
        FROM rides
        WHERE DATE(created_at) = CURRENT_DATE

        UNION

        SELECT passenger_id AS user_id
        FROM ride_participants
        WHERE DATE(created_at) = CURRENT_DATE
      ) active_users
    )

    SELECT
      tu.total_users,
      tr.total_riders,
      rs.total_completed_rides,
      rs.total_cancelled_rides,
      rs.male_preference_count,
      rs.female_preference_count,
      rs.no_preference_count,
      nu.new_users_this_week,
      nu.new_users_this_month,
      au.active_users_today
    FROM total_users_cte tu
    CROSS JOIN total_riders_cte tr
    CROSS JOIN ride_stats rs
    CROSS JOIN new_users nu
    CROSS JOIN active_users_today_cte au;
  `;

  const statsRes = await rideDb.query(statsQuery);
  const stats = statsRes.rows[0];


  //   OCCUPATION BREAKDOWN

  const occupationRes = await ewuAdminDb.query(`
    SELECT
      COUNT(*) FILTER (WHERE occupation = 'student') AS student_count,
      COUNT(*) FILTER (WHERE occupation = 'faculty') AS faculty_count,
      COUNT(*) FILTER (WHERE occupation = 'staff') AS staff_count
    FROM ewu_users
  `);

  const occupation = occupationRes.rows[0];


  //   FINAL RESPONSE
 
  return {
    total_users: Number(stats.total_users || 0),
    total_riders: Number(stats.total_riders || 0),
    total_passengers:
      Number(stats.total_users || 0) - Number(stats.total_riders || 0),

    total_completed_rides: Number(stats.total_completed_rides || 0),
    total_cancelled_rides: Number(stats.total_cancelled_rides || 0),

    active_users_today: Number(stats.active_users_today || 0),

    new_users_this_week: Number(stats.new_users_this_week || 0),
    new_users_this_month: Number(stats.new_users_this_month || 0),

    student_count: Number(occupation.student_count || 0),
    faculty_count: Number(occupation.faculty_count || 0),
    staff_count: Number(occupation.staff_count || 0),

    male_preference_count: Number(stats.male_preference_count || 0),
    female_preference_count: Number(stats.female_preference_count || 0),
    no_preference_count: Number(stats.no_preference_count || 0),
  };
};

module.exports = {
  getAppStats,
};