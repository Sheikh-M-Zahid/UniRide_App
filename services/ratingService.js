const rideDb = require('../config/rideDb');

const validateRatingValue = (rating) => {
  const numericRating = Number(rating);

  if (!Number.isInteger(numericRating) || numericRating < 1 || numericRating > 5) {
    throw new Error('Rating must be an integer between 1 and 5.');
  }

  return numericRating;
};

const getRideWithValidation = async (rideId) => {
  const rideResult = await rideDb.query(
    `SELECT ride_id, rider_id, status
     FROM rides
     WHERE ride_id = $1`,
    [rideId]
  );

  if (rideResult.rowCount === 0) {
    throw new Error('Ride not found.');
  }

  const ride = rideResult.rows[0];

  if (ride.status !== 'completed') {
    throw new Error('Rating is allowed only after ride completion.');
  }

  return ride;
};

const isPassengerInRide = async (rideId, passengerId) => {
  const result = await rideDb.query(
    `SELECT 1
     FROM ride_participants
     WHERE ride_id = $1
       AND passenger_id = $2
     LIMIT 1`,
    [rideId, passengerId]
  );

  return result.rowCount > 0;
};

const hasUserRated = async ({ rideId, fromUserId, toUserId }) => {
  const passengerToRiderCheck = await rideDb.query(
    `SELECT 1
     FROM rider_ratings
     WHERE ride_id = $1
       AND passenger_id = $2
       AND rider_id = $3
     LIMIT 1`,
    [rideId, fromUserId, toUserId]
  );

  if (passengerToRiderCheck.rowCount > 0) {
    return true;
  }

  const riderToPassengerCheck = await rideDb.query(
    `SELECT 1
     FROM rider_given_ratings
     WHERE ride_id = $1
       AND rider_id = $2
       AND passenger_id = $3
     LIMIT 1`,
    [rideId, fromUserId, toUserId]
  );

  return riderToPassengerCheck.rowCount > 0;
};

const passengerRatesRider = async ({ rideId, passengerId, rating, note = null }) => {
  const numericRating = validateRatingValue(rating);
  const ride = await getRideWithValidation(rideId);

  if (ride.rider_id === passengerId) {
    throw new Error('Rider cannot rate themselves as passenger.');
  }

  const passengerExists = await isPassengerInRide(rideId, passengerId);

  if (!passengerExists) {
    throw new Error('You are not a participant of this ride.');
  }

  const alreadyRated = await hasUserRated({
    rideId,
    fromUserId: passengerId,
    toUserId: ride.rider_id,
  });

  if (alreadyRated) {
    throw new Error('You have already rated this user for this ride.');
  }

  try {
    const result = await rideDb.query(
      `INSERT INTO rider_ratings (
        ride_id,
        rider_id,
        passenger_id,
        rating,
        note
      )
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *`,
      [rideId, ride.rider_id, passengerId, numericRating, note]
    );

    return result.rows[0];
  } catch (error) {
    if (error.code === '23505') {
      throw new Error('You have already rated this user for this ride.');
    }
    throw error;
  }
};

const riderRatesParticipant = async ({ rideId, riderId, passengerId, rating, note = null }) => {
  const numericRating = validateRatingValue(rating);
  const ride = await getRideWithValidation(rideId);

  if (ride.rider_id !== riderId) {
    throw new Error('Only the ride rider can rate participants.');
  }

  if (riderId === passengerId) {
    throw new Error('You cannot rate yourself.');
  }

  const passengerExists = await isPassengerInRide(rideId, passengerId);

  if (!passengerExists) {
    throw new Error('Target user is not a participant of this ride.');
  }

  const alreadyRated = await hasUserRated({
    rideId,
    fromUserId: riderId,
    toUserId: passengerId,
  });

  if (alreadyRated) {
    throw new Error('You have already rated this user for this ride.');
  }

  try {
    const result = await rideDb.query(
      `INSERT INTO rider_given_ratings (
        ride_id,
        rider_id,
        passenger_id,
        rating,
        note
      )
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *`,
      [rideId, riderId, passengerId, numericRating, note]
    );

    return result.rows[0];
  } catch (error) {
    if (error.code === '23505') {
      throw new Error('You have already rated this user for this ride.');
    }
    throw error;
  }
};

const fetchRatingSummary = async (userId) => {
  const result = await rideDb.query(
    `SELECT
        user_id,
        first_name,
        last_name,
        rating,
        rating_count,
        rating_sum
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
  hasUserRated,
  passengerRatesRider,
  riderRatesParticipant,
  fetchRatingSummary,
};