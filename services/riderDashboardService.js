const rideDb = require('../config/rideDb');

const formatCurrency = (value) => Number(value || 0);

const getRiderDashboard = async ({ riderId }) => {
  const onlineStatusQuery = `
    SELECT is_active
    FROM rider_availability
    WHERE rider_id = $1
    LIMIT 1
  `;

  const todayEarningsQuery = `
    SELECT COALESCE(SUM(amount), 0) AS today_earnings
    FROM transactions
    WHERE user_id = $1
      AND type = 'credit'
      AND status = 'completed'
      AND DATE(created_at) = CURRENT_DATE
  `;

  // If you do not yet have notifications table, keep fallback 0 for now.
  // Later replace with real query.
  const unreadNotificationsQuery = `
    SELECT COUNT(*)::int AS unread_count
    FROM notifications
    WHERE user_id = $1
      AND is_read = FALSE
  `;

  const activeRideQuery = `
    SELECT
      u.first_name,
      u.last_name,
      rr.pickup_location,
      rr.destination,
      rr.estimated_fare,
      r.status
    FROM ride_requests rr
    INNER JOIN users u
      ON u.user_id = rr.passenger_id
    INNER JOIN rides r
      ON r.ride_id = rr.ride_id
    WHERE rr.rider_id = $1
      AND rr.status = 'accepted'
      AND r.status IN ('assigned', 'ongoing')
    ORDER BY rr.confirmed_at DESC
    LIMIT 1
  `;

  const upcomingReservedRideQuery = `
  SELECT
    res.pickup_location,
    res.destination_location,
    res.travel_date,
    res.travel_time
  FROM reserves res
  INNER JOIN reserve_rider_matches rrm
    ON rrm.reserve_id = res.reserve_id
  WHERE rrm.rider_id = $1
    AND rrm.is_selected = TRUE
    AND res.status IN ('confirmed', 'ongoing')
    AND res.travel_date >= CURRENT_DATE
  ORDER BY res.travel_date ASC, res.travel_time ASC
  LIMIT 1
`;

  const [
    onlineStatusResult,
    todayEarningsResult,
    unreadNotificationsResult,
    activeRideResult,
    upcomingReservedRideResult,
  ] = await Promise.all([
    rideDb.query(onlineStatusQuery, [riderId]),
    rideDb.query(todayEarningsQuery, [riderId]),
    rideDb.query(unreadNotificationsQuery, [riderId]),
    rideDb.query(activeRideQuery, [riderId]),
    rideDb.query(upcomingReservedRideQuery, [riderId]),
  ]);

  const isOnline = onlineStatusResult.rows[0]?.is_active || false;
  const todayEarnings = formatCurrency(
    todayEarningsResult.rows[0]?.today_earnings
  );
  const unreadNotifications =
    unreadNotificationsResult.rows[0]?.unread_count || 0;

  let activeRide = null;
  if (activeRideResult.rows.length > 0) {
    const row = activeRideResult.rows[0];
    activeRide = {
      passenger: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
      pickup: row.pickup_location,
      destination: row.destination,
      fare: formatCurrency(row.estimated_fare),
      status: row.status,
    };
  }

  let upcomingReservedRide = null;
  if (upcomingReservedRideResult.rows.length > 0) {
  const row = upcomingReservedRideResult.rows[0];
  upcomingReservedRide = {
    date: row.travel_date instanceof Date
      ? row.travel_date.toISOString().split('T')[0]
      : row.travel_date,
    time: row.travel_time,
    pickup: row.pickup_location,
    destination: row.destination_location,
  };
}

  return {
    isOnline,
    todayEarnings,
    unreadNotifications,
    activeRide,
    upcomingReservedRide,
    active_ride: activeRide,
    upcoming_reserved_ride: upcomingReservedRide,
  };
};

const updateRiderStatus = async ({ riderId, isOnline }) => {
  const query = `
    INSERT INTO rider_availability (rider_id, is_active)
    VALUES ($1, $2)
    ON CONFLICT (rider_id)
    DO UPDATE SET is_active = EXCLUDED.is_active
    RETURNING rider_id, is_active
  `;

  const { rows } = await rideDb.query(query, [riderId, isOnline]);

  return {
    riderId: rows[0].rider_id,
    isOnline: rows[0].is_active,
  };
};

module.exports = {
  getRiderDashboard,
  updateRiderStatus,
};
