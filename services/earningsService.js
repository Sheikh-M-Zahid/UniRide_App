const rideDb = require('../config/rideDb');

const ALLOWED_RANGES = ['today', 'weekly', 'monthly'];

const getSummaryQuery = () => `
  WITH valid_transactions AS (
    SELECT
      t.user_id,
      t.amount,
      t.created_at
    FROM transactions t
    WHERE t.user_id = $1
      AND t.status = 'completed'
      AND (
  t.type IN ('ride_income', 'earning', 'rider_credit')
  OR (t.type = 'credit' AND t.method IN ('delivery', 'delivery_bonus'))
)
  ),
  fallback_completed_rides AS (
    SELECT
      r.rider_id,
      COUNT(*)::int AS completed_rides
    FROM rides r
    WHERE r.rider_id = $1
      AND r.status = 'completed'
    GROUP BY r.rider_id
  )
  SELECT
    COALESCE(u.rating, 5) AS rating,

    COALESCE(SUM(
      CASE
        WHEN vt.created_at >= CURRENT_DATE
         AND vt.created_at < CURRENT_DATE + INTERVAL '1 day'
        THEN vt.amount
        ELSE 0
      END
    ), 0)::numeric(10,2) AS today_earnings,

    COALESCE(SUM(
      CASE
        WHEN vt.created_at >= DATE_TRUNC('week', CURRENT_DATE)
         AND vt.created_at < DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days'
        THEN vt.amount
        ELSE 0
      END
    ), 0)::numeric(10,2) AS week_earnings,

    COALESCE(SUM(
      CASE
        WHEN vt.created_at >= DATE_TRUNC('month', CURRENT_DATE)
         AND vt.created_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
        THEN vt.amount
        ELSE 0
      END
    ), 0)::numeric(10,2) AS month_earnings,

    COALESCE(fcr.completed_rides, 0) AS completed_rides
  FROM users u
  LEFT JOIN valid_transactions vt
    ON vt.user_id = u.user_id
  LEFT JOIN fallback_completed_rides fcr
    ON fcr.rider_id = u.user_id
  WHERE u.user_id = $1
  GROUP BY u.user_id, u.rating, fcr.completed_rides;
`;

const getTodayChartQuery = () => `
  WITH hours AS (
    SELECT generate_series(0, 23) AS hour_num
  ),
  valid_transactions AS (
    SELECT
      EXTRACT(HOUR FROM t.created_at)::int AS hour_num,
      SUM(t.amount)::numeric(10,2) AS earning
    FROM transactions t
    WHERE t.user_id = $1
      AND t.status = 'completed'
      AND (
  t.type IN ('ride_income', 'earning', 'rider_credit')
  OR (t.type = 'credit' AND t.method IN ('delivery', 'delivery_bonus'))
)
      AND t.created_at >= CURRENT_DATE
      AND t.created_at < CURRENT_DATE + INTERVAL '1 day'
    GROUP BY EXTRACT(HOUR FROM t.created_at)
  )
  SELECT
    h.hour_num,
    COALESCE(vt.earning, 0)::numeric(10,2) AS earning
  FROM hours h
  LEFT JOIN valid_transactions vt
    ON vt.hour_num = h.hour_num
  ORDER BY h.hour_num ASC;
`;

const getWeeklyChartQuery = () => `
  WITH days AS (
    SELECT generate_series(
      CURRENT_DATE - INTERVAL '6 days',
      CURRENT_DATE,
      INTERVAL '1 day'
    )::date AS day_date
  ),
  valid_transactions AS (
    SELECT
      DATE(t.created_at) AS day_date,
      SUM(t.amount)::numeric(10,2) AS earning
    FROM transactions t
    WHERE t.user_id = $1
      AND t.status = 'completed'
      AND (
  t.type IN ('ride_income', 'earning', 'rider_credit')
  OR (t.type = 'credit' AND t.method IN ('delivery', 'delivery_bonus'))
)
      AND t.created_at >= CURRENT_DATE - INTERVAL '6 days'
      AND t.created_at < CURRENT_DATE + INTERVAL '1 day'
    GROUP BY DATE(t.created_at)
  )
  SELECT
    d.day_date,
    COALESCE(vt.earning, 0)::numeric(10,2) AS earning
  FROM days d
  LEFT JOIN valid_transactions vt
    ON vt.day_date = d.day_date
  ORDER BY d.day_date ASC;
`;

const getMonthlyChartQuery = () => `
  WITH days AS (
    SELECT generate_series(
      DATE_TRUNC('month', CURRENT_DATE)::date,
      (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::date,
      INTERVAL '1 day'
    )::date AS day_date
  ),
  valid_transactions AS (
    SELECT
      DATE(t.created_at) AS day_date,
      SUM(t.amount)::numeric(10,2) AS earning
    FROM transactions t
    WHERE t.user_id = $1
      AND t.status = 'completed'
      AND (
  t.type IN ('ride_income', 'earning', 'rider_credit')
  OR (t.type = 'credit' AND t.method IN ('delivery', 'delivery_bonus'))
)
      AND t.created_at >= DATE_TRUNC('month', CURRENT_DATE)
      AND t.created_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    GROUP BY DATE(t.created_at)
  )
  SELECT
    d.day_date,
    COALESCE(vt.earning, 0)::numeric(10,2) AS earning
  FROM days d
  LEFT JOIN valid_transactions vt
    ON vt.day_date = d.day_date
  ORDER BY d.day_date ASC;
`;

const formatTodayChart = (rows) => {
  return rows.map((row) => ({
    label: `${String(row.hour_num).padStart(2, '0')}:00`,
    value: Number(row.earning || 0),
  }));
};

const formatWeeklyChart = (rows) => {
  return rows.map((row) => ({
    label: new Date(row.day_date).toLocaleDateString('en-US', { weekday: 'short' }),
    value: Number(row.earning || 0),
    fullDate: row.day_date,
  }));
};

const formatMonthlyChart = (rows) => {
  return rows.map((row) => ({
    label: String(new Date(row.day_date).getDate()),
    value: Number(row.earning || 0),
    fullDate: row.day_date,
  }));
};

const getFallbackSummaryFromRides = async (userId) => {
  const query = `
    SELECT
      COALESCE(SUM(
        CASE
          WHEN r.created_at >= CURRENT_DATE
           AND r.created_at < CURRENT_DATE + INTERVAL '1 day'
          THEN rp.fare
          ELSE 0
        END
      ), 0)::numeric(10,2) AS today_earnings,

      COALESCE(SUM(
        CASE
          WHEN r.created_at >= DATE_TRUNC('week', CURRENT_DATE)
           AND r.created_at < DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days'
          THEN rp.fare
          ELSE 0
        END
      ), 0)::numeric(10,2) AS week_earnings,

      COALESCE(SUM(
        CASE
          WHEN r.created_at >= DATE_TRUNC('month', CURRENT_DATE)
           AND r.created_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
          THEN rp.fare
          ELSE 0
        END
      ), 0)::numeric(10,2) AS month_earnings,

    COUNT(DISTINCT r.ride_id)::int AS completed_rides
    FROM rides r
    LEFT JOIN ride_participants rp
      ON rp.ride_id = r.ride_id
    WHERE r.rider_id = $1
      AND r.status = 'completed';
  `;

  const result = await rideDb.query(query, [userId]);
  return result.rows[0];
};

const getFallbackTodayChart = async (userId) => {
  const query = `
    WITH hours AS (
      SELECT generate_series(0, 23) AS hour_num
    ),
    fare_data AS (
      SELECT
        EXTRACT(HOUR FROM r.created_at)::int AS hour_num,
        SUM(rp.fare)::numeric(10,2) AS earning
      FROM rides r
      LEFT JOIN ride_participants rp
        ON rp.ride_id = r.ride_id
      WHERE r.rider_id = $1
        AND r.status = 'completed'
        AND r.created_at >= CURRENT_DATE
        AND r.created_at < CURRENT_DATE + INTERVAL '1 day'
      GROUP BY EXTRACT(HOUR FROM r.created_at)
    )
    SELECT
      h.hour_num,
      COALESCE(fd.earning, 0)::numeric(10,2) AS earning
    FROM hours h
    LEFT JOIN fare_data fd
      ON fd.hour_num = h.hour_num
    ORDER BY h.hour_num ASC;
  `;
  const result = await rideDb.query(query, [userId]);
  return result.rows;
};

const getFallbackWeeklyChart = async (userId) => {
  const query = `
    WITH days AS (
      SELECT generate_series(
        CURRENT_DATE - INTERVAL '6 days',
        CURRENT_DATE,
        INTERVAL '1 day'
      )::date AS day_date
    ),
    fare_data AS (
      SELECT
        DATE(r.created_at) AS day_date,
        SUM(rp.fare)::numeric(10,2) AS earning
      FROM rides r
      LEFT JOIN ride_participants rp
        ON rp.ride_id = r.ride_id
      WHERE r.rider_id = $1
        AND r.status = 'completed'
        AND r.created_at >= CURRENT_DATE - INTERVAL '6 days'
        AND r.created_at < CURRENT_DATE + INTERVAL '1 day'
      GROUP BY DATE(r.created_at)
    )
    SELECT
      d.day_date,
      COALESCE(fd.earning, 0)::numeric(10,2) AS earning
    FROM days d
    LEFT JOIN fare_data fd
      ON fd.day_date = d.day_date
    ORDER BY d.day_date ASC;
  `;
  const result = await rideDb.query(query, [userId]);
  return result.rows;
};

const getFallbackMonthlyChart = async (userId) => {
  const query = `
    WITH days AS (
      SELECT generate_series(
        DATE_TRUNC('month', CURRENT_DATE)::date,
        (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::date,
        INTERVAL '1 day'
      )::date AS day_date
    ),
    fare_data AS (
      SELECT
        DATE(r.created_at) AS day_date,
        SUM(rp.fare)::numeric(10,2) AS earning
      FROM rides r
      LEFT JOIN ride_participants rp
        ON rp.ride_id = r.ride_id
      WHERE r.rider_id = $1
        AND r.status = 'completed'
        AND r.created_at >= DATE_TRUNC('month', CURRENT_DATE)
        AND r.created_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
      GROUP BY DATE(r.created_at)
    )
    SELECT
      d.day_date,
      COALESCE(fd.earning, 0)::numeric(10,2) AS earning
    FROM days d
    LEFT JOIN fare_data fd
      ON fd.day_date = d.day_date
    ORDER BY d.day_date ASC;
  `;
  const result = await rideDb.query(query, [userId]);
  return result.rows;
};

const getChartData = async (userId, range) => {
  if (range === 'weekly') {
    const txResult = await rideDb.query(getWeeklyChartQuery(), [userId]);
    const hasTx = txResult.rows.some((row) => Number(row.earning) > 0);

    if (hasTx) return formatWeeklyChart(txResult.rows);

    const fallbackRows = await getFallbackWeeklyChart(userId);
    return formatWeeklyChart(fallbackRows);
  }

  if (range === 'monthly') {
    const txResult = await rideDb.query(getMonthlyChartQuery(), [userId]);
    const hasTx = txResult.rows.some((row) => Number(row.earning) > 0);

    if (hasTx) return formatMonthlyChart(txResult.rows);

    const fallbackRows = await getFallbackMonthlyChart(userId);
    return formatMonthlyChart(fallbackRows);
  }

  const txResult = await rideDb.query(getTodayChartQuery(), [userId]);
  const hasTx = txResult.rows.some((row) => Number(row.earning) > 0);

  if (hasTx) return formatTodayChart(txResult.rows);

  const fallbackRows = await getFallbackTodayChart(userId);
  return formatTodayChart(fallbackRows);
};

const getEarningsDashboard = async ({ userId, range = 'today' }) => {
  const safeRange = ALLOWED_RANGES.includes(range) ? range : 'today';

  const summaryResult = await rideDb.query(getSummaryQuery(), [userId]);

  let summary = summaryResult.rows[0];

  if (!summary) {
    const userResult = await rideDb.query(
      `SELECT COALESCE(rating, 5) AS rating FROM users WHERE user_id = $1`,
      [userId]
    );

    const fallback = await getFallbackSummaryFromRides(userId);

    summary = {
      rating: userResult.rows[0]?.rating || 5,
      today_earnings: fallback?.today_earnings || 0,
      week_earnings: fallback?.week_earnings || 0,
      month_earnings: fallback?.month_earnings || 0,
      completed_rides: fallback?.completed_rides || 0,
    };
  } else {
    const txValues =
      Number(summary.today_earnings || 0) +
      Number(summary.week_earnings || 0) +
      Number(summary.month_earnings || 0);

    if (txValues === 0) {
      const fallback = await getFallbackSummaryFromRides(userId);

      summary.today_earnings = fallback?.today_earnings || 0;
      summary.week_earnings = fallback?.week_earnings || 0;
      summary.month_earnings = fallback?.month_earnings || 0;
      summary.completed_rides = fallback?.completed_rides || summary.completed_rides || 0;
    }
  }

  const chartData = await getChartData(userId, safeRange);

  return {
    rating: Number(summary.rating || 5),
    summary: {
      todayEarnings: Number(summary.today_earnings || 0),
      weekEarnings: Number(summary.week_earnings || 0),
      monthEarnings: Number(summary.month_earnings || 0),
      completedRides: Number(summary.completed_rides || 0),
    },
    chart: {
      selectedRange: safeRange,
      data: chartData,
    },
  };
};

module.exports = {
  getEarningsDashboard,
};
