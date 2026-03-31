const rideDb = require('../config/rideDb');

const formatDisplayText = ({
  start_location,
  destination,
  fare,
  ride_status,
}) => {
  const from = start_location || 'Unknown';
  const to = destination || 'Unknown';
  const fareText = fare ? `BDT ${fare}` : 'BDT 0';
  const status = ride_status || 'active';

  return `${from} → ${to} | Fare: ${fareText} | ${status}`;
};

const getUpcomingReserve = async (userId) => {
  const userResult = await rideDb.query(
    `SELECT user_id, account_status
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (userResult.rowCount === 0) {
    throw new Error('User account not found.');
  }

  const user = userResult.rows[0];

  if (String(user.account_status).toLowerCase() !== 'active') {
    throw new Error('Your account is not active.');
  }

  const result = await rideDb.query(
    `SELECT
        r.ride_id,
        r.start_location,
        r.destination,
        rp.fare,
        rp.confirmed,
        r.status AS ride_status,
        r.created_at
     FROM ride_participants rp
     INNER JOIN rides r
       ON rp.ride_id = r.ride_id
     WHERE rp.passenger_id = $1
       AND r.status IN ('active', 'processing', 'reserve')
     ORDER BY r.created_at DESC`,
    [userId]
  );

  return result.rows.map((row) => ({
    ride_id: row.ride_id,
    start_location: row.start_location,
    destination: row.destination,
    fare: row.fare,
    confirmed: row.confirmed,
    ride_status: row.ride_status,
    created_at: row.created_at,
    display_text: formatDisplayText(row),
  }));
};

module.exports = {
  getUpcomingReserve,
};
