const rideDb = require('../config/rideDb');

const passengerRatesRider = async (rideId, passengerId, rating) => {
  const rideResult = await rideDb.query(
    `SELECT rider_id FROM rides WHERE ride_id = $1`,
    [rideId]
  );

  if (rideResult.rowCount === 0) {
    throw new Error('Ride not found.');
  }

  const riderId = rideResult.rows[0].rider_id;

  const result = await rideDb.query(
    `INSERT INTO rider_ratings (ride_id, rider_id, passenger_id, rating)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [rideId, riderId, passengerId, rating]
  );

  return result.rows[0];
};

const riderRatesParticipants = async (rideId, riderId, rating) => {
  const result = await rideDb.query(
    `INSERT INTO rider_given_ratings (ride_id, rider_id, rating)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [rideId, riderId, rating]
  );

  return result.rows[0];
};

const fetchRatingSummary = async (userId) => {
  const result = await rideDb.query(
    `SELECT user_id, first_name, last_name, rating, rating_count, rating_sum
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (result.rowCount === 0) {
    throw new Error('User not found.');
  }

  return result.rows[0];
};

module.exports = {
  passengerRatesRider,
  riderRatesParticipants,
  fetchRatingSummary,
};