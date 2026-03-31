const rideDb = require('../config/rideDb');

const formatDisplayText = ({
  start_location,
  destination,
  fare,
  ride_status,
}) => {
  const fromText = start_location || 'Unknown';
  const toText = destination || 'Unknown';
  const fareText = fare !== null && fare !== undefined ? `BDT ${fare}` : 'BDT 0';
  const statusText = ride_status || 'unknown';

  return `${fromText} → ${toText} | Fare: ${fareText} | ${statusText}`;
};

const getRideHistory = async (userId) => {
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
        r.status AS ride_status,
        v.vehicle_type,
        r.created_at
     FROM ride_participants rp
     INNER JOIN rides r
       ON rp.ride_id = r.ride_id
     LEFT JOIN vehicles v
       ON r.vehicle_id = v.vehicle_id
     WHERE rp.passenger_id = $1
     ORDER BY r.created_at DESC`,
    [userId]
  );

  return result.rows.map((row) => ({
    ride_id: row.ride_id,
    start_location: row.start_location,
    destination: row.destination,
    fare: row.fare,
    ride_status: row.ride_status,
    vehicle_type: row.vehicle_type,
    created_at: row.created_at,
    display_text: formatDisplayText(row),
  }));
};

module.exports = {
  getRideHistory,
};