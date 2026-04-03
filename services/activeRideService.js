const rideDb = require('../config/rideDb');

const ACTIVE_RIDE_STATUSES = ['requested', 'accepted', 'ongoing', 'active'];

const getActiveRideDashboard = async (userId) => {
  const riderResult = await rideDb.query(
    `
    SELECT
      u.user_id,
      COALESCE(u.is_online, false) AS is_active,
      u.account_status
    FROM users u
    WHERE u.user_id = $1
    LIMIT 1
    `,
    [userId]
  );

  if (riderResult.rowCount === 0) {
    throw new Error('Rider not found.');
  }

  const rider = riderResult.rows[0];

  if (String(rider.account_status).toLowerCase() !== 'active') {
    throw new Error('Your account is not active.');
  }

  const currentRideResult = await rideDb.query(
    `
    WITH prioritized_ride AS (
      SELECT
        r.id AS ride_id,
        r.rider_id,
        r.start_location,
        r.destination,
        r.total_fare,
        r.trip_time,
        r.created_at,
        r.status
      FROM rides r
      WHERE r.rider_id = $1
        AND r.status = ANY($2::text[])
      ORDER BY
        CASE
          WHEN r.status = 'ongoing' THEN 1
          WHEN r.status = 'accepted' THEN 2
          WHEN r.status = 'active' THEN 3
          WHEN r.status = 'requested' THEN 4
          ELSE 5
        END,
        r.created_at DESC
      LIMIT 1
    )
    SELECT
      pr.ride_id,
      pr.status AS ride_status,
      COALESCE(
        passenger.first_name || ' ' || passenger.last_name,
        'Passenger not assigned'
      ) AS passenger_name,
      pr.start_location AS pickup,
      pr.destination,
      COALESCE(pr.total_fare, 0) AS fare,
      COALESCE(pr.trip_time::text, TO_CHAR(pr.created_at, 'HH24:MI')) AS ride_time
    FROM prioritized_ride pr
    LEFT JOIN LATERAL (
      SELECT rp.user_id
      FROM ride_participants rp
      WHERE rp.ride_id = pr.ride_id
      ORDER BY rp.joined_at ASC NULLS LAST, rp.created_at ASC NULLS LAST
      LIMIT 1
    ) rp_first ON true
    LEFT JOIN users passenger
      ON passenger.user_id = rp_first.user_id
    `,
    [userId, ACTIVE_RIDE_STATUSES]
  );

  const currentRide = currentRideResult.rows[0] || null;

  return {
    isActive: Boolean(rider.is_active),
    rideStatus: currentRide?.ride_status || 'inactive',
    currentRide: currentRide
      ? {
          rideId: currentRide.ride_id,
          passenger: currentRide.passenger_name,
          pickup: currentRide.pickup || 'Pickup unavailable',
          destination: currentRide.destination || 'Destination unavailable',
          fare: Number(currentRide.fare || 0),
          time: currentRide.ride_time || '--:--',
        }
      : null,
  };
};

const toggleActiveRideStatus = async (userId, isActive) => {
  if (typeof isActive !== 'boolean') {
    throw new Error('isActive must be boolean.');
  }

  const riderResult = await rideDb.query(
    `
    SELECT
      user_id,
      account_status,
      COALESCE(is_online, false) AS is_online
    FROM users
    WHERE user_id = $1
    LIMIT 1
    `,
    [userId]
  );

  if (riderResult.rowCount === 0) {
    throw new Error('Rider not found.');
  }

  const rider = riderResult.rows[0];

  if (String(rider.account_status).toLowerCase() !== 'active') {
    throw new Error('Your account is not active.');
  }

  const blockingRideResult = await rideDb.query(
    `
    SELECT id, status
    FROM rides
    WHERE rider_id = $1
      AND status IN ('accepted', 'ongoing')
    LIMIT 1
    `,
    [userId]
  );

  if (!isActive && blockingRideResult.rowCount > 0) {
    throw new Error('You cannot go inactive while a ride is accepted or ongoing.');
  }

  await rideDb.query(
    `
    UPDATE users
    SET is_online = $1
    WHERE user_id = $2
    `,
    [isActive, userId]
  );

  return {
    isActive,
    rideStatus: isActive ? 'active' : 'inactive',
    message: isActive
      ? 'Rider is now active.'
      : 'Rider is now inactive.',
  };
};

module.exports = {
  getActiveRideDashboard,
  toggleActiveRideStatus,
};