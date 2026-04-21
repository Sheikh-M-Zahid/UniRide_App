const rideDb = require('../config/rideDb');
const { safeDistanceKm } = require('../utils/geo');

const AUTO_COMPLETE_DISTANCE_METERS = 80;
const AUTO_COMPLETE_RIDE_STATUSES = ['active', 'assigned', 'accepted', 'ongoing'];

const getLatestTrackableRide = async ({ client, userId, rideId = null }) => {
  const db = client || rideDb;

  if (rideId) {
    const result = await db.query(
      `
      SELECT
        ride_id,
        rider_id,
        status,
        destination,
        destination_latitude,
        destination_longitude
      FROM rides
      WHERE ride_id = $1
        AND rider_id = $2
        AND status = ANY($3::text[])
      LIMIT 1
      `,
      [rideId, userId, AUTO_COMPLETE_RIDE_STATUSES]
    );

    return result.rows[0] || null;
  }

  const result = await db.query(
    `
    SELECT
      ride_id,
      rider_id,
      status,
      destination,
      destination_latitude,
      destination_longitude
    FROM rides
    WHERE rider_id = $1
      AND status = ANY($2::text[])
    ORDER BY created_at DESC
    LIMIT 1
    `,
    [userId, AUTO_COMPLETE_RIDE_STATUSES]
  );

  return result.rows[0] || null;
};

const autoCompleteRideIfReachedDestination = async ({
  userId,
  rideId = null,
  latitude,
  longitude,
}) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const ride = await getLatestTrackableRide({
      client,
      userId,
      rideId,
    });

    if (!ride) {
      await client.query('COMMIT');
      return {
        checked: false,
        autoCompleted: false,
        rideId: null,
        reason: 'No active ride found.',
      };
    }

    const destinationLat = Number(ride.destination_latitude);
    const destinationLng = Number(ride.destination_longitude);

    if (Number.isNaN(destinationLat) || Number.isNaN(destinationLng)) {
      await client.query('COMMIT');
      return {
        checked: true,
        autoCompleted: false,
        rideId: ride.ride_id,
        reason: 'Destination coordinates are missing.',
      };
    }

    const distanceKm = safeDistanceKm(
      Number(latitude),
      Number(longitude),
      destinationLat,
      destinationLng
    );

    if (distanceKm === null) {
      await client.query('COMMIT');
      return {
        checked: true,
        autoCompleted: false,
        rideId: ride.ride_id,
        reason: 'Invalid coordinates.',
      };
    }

    const distanceMeters = Math.round(distanceKm * 1000);

    if (distanceMeters > AUTO_COMPLETE_DISTANCE_METERS) {
      await client.query('COMMIT');
      return {
        checked: true,
        autoCompleted: false,
        rideId: ride.ride_id,
        distanceToDestinationMeters: distanceMeters,
        thresholdMeters: AUTO_COMPLETE_DISTANCE_METERS,
        rideStatus: ride.status,
      };
    }

    const rideUpdateRes = await client.query(
      `
      UPDATE rides
      SET
        status = 'completed',
        completed_at = CURRENT_TIMESTAMP
      WHERE ride_id = $1
        AND rider_id = $2
      RETURNING ride_id, status, completed_at, destination
      `,
      [ride.ride_id, userId]
    );

    await client.query(
      `
      UPDATE rider_availability
      SET
        is_active = FALSE,
        last_deactivated_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
      WHERE rider_id = $1
      `,
      [userId]
    );

    await client.query('COMMIT');

    const completedRide = rideUpdateRes.rows[0];

    return {
      checked: true,
      autoCompleted: true,
      rideId: completedRide.ride_id,
      rideStatus: completedRide.status,
      completedAt: completedRide.completed_at,
      destination: completedRide.destination,
      distanceToDestinationMeters: distanceMeters,
      thresholdMeters: AUTO_COMPLETE_DISTANCE_METERS,
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  AUTO_COMPLETE_DISTANCE_METERS,
  AUTO_COMPLETE_RIDE_STATUSES,
  autoCompleteRideIfReachedDestination,
};