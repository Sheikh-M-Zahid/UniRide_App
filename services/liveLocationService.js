const rideDb = require('../config/rideDb');

const updateLiveLocation = async (userId, rideId, latitude, longitude) => {
  const existing = await rideDb.query(
    `SELECT location_id FROM live_locations WHERE user_id = $1 AND ride_id = $2`,
    [userId, rideId]
  );

  if (existing.rowCount > 0) {
    const updated = await rideDb.query(
      `UPDATE live_locations
       SET latitude = $1, longitude = $2, updated_at = CURRENT_TIMESTAMP
       WHERE user_id = $3 AND ride_id = $4
       RETURNING *`,
      [latitude, longitude, userId, rideId]
    );

    return updated.rows[0];
  }

  const inserted = await rideDb.query(
    `INSERT INTO live_locations (user_id, ride_id, latitude, longitude)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [userId, rideId, latitude, longitude]
  );

  return inserted.rows[0];
};

const getRideLiveLocations = async (rideId) => {
  const result = await rideDb.query(
    `SELECT ll.*, u.first_name, u.last_name, u.university_email
     FROM live_locations ll
     JOIN users u ON ll.user_id = u.user_id
     WHERE ll.ride_id = $1
     ORDER BY ll.updated_at DESC`,
    [rideId]
  );

  return result.rows;
};

module.exports = {
  updateLiveLocation,
  getRideLiveLocations,
};