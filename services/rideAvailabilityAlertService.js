const rideDb = require('../config/rideDb');

const isValidNumber = (value) =>
  typeof value === 'number' && !Number.isNaN(value);

const createAvailabilityAlert = async ({ userId, body }) => {
  const {
    pickupAddress,
    destinationAddress,
    pickupLat,
    pickupLng,
    destinationLat,
    destinationLng,
    genderPreference = 'Any',
    vehicleType = 'All',
    userType = 'All',
  } = body;

  if (
    !pickupAddress ||
    !destinationAddress ||
    !isValidNumber(pickupLat) ||
    !isValidNumber(pickupLng) ||
    !isValidNumber(destinationLat) ||
    !isValidNumber(destinationLng)
  ) {
    throw new Error('Pickup, destination, and valid coordinates are required.');
  }

  const result = await rideDb.query(
    `INSERT INTO ride_availability_alerts (
      user_id,
      pickup_address,
      destination_address,
      pickup_lat,
      pickup_lng,
      destination_lat,
      destination_lng,
      gender_preference,
      vehicle_type,
      user_type,
      is_active
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,TRUE)
    RETURNING *`,
    [
      userId,
      pickupAddress,
      destinationAddress,
      pickupLat,
      pickupLng,
      destinationLat,
      destinationLng,
      genderPreference,
      vehicleType,
      userType,
    ]
  );

  return result.rows[0];
};

const getMyAvailabilityAlerts = async (userId) => {
  const result = await rideDb.query(
    `SELECT *
     FROM ride_availability_alerts
     WHERE user_id = $1
     ORDER BY created_at DESC`,
    [userId]
  );

  return result.rows;
};

const deactivateAvailabilityAlert = async ({ userId, alertId }) => {
  const result = await rideDb.query(
    `UPDATE ride_availability_alerts
     SET is_active = FALSE
     WHERE alert_id = $1
       AND user_id = $2
     RETURNING *`,
    [alertId, userId]
  );

  if (!result.rows.length) {
    throw new Error('Alert not found or unauthorized.');
  }

  return result.rows[0];
};

module.exports = {
  createAvailabilityAlert,
  getMyAvailabilityAlerts,
  deactivateAvailabilityAlert,
};