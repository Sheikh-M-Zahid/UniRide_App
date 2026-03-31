const rideDb = require('../config/rideDb');

const getSavedPlaces = async (userId) => {
  const result = await rideDb.query(
    `SELECT
        user_id,
        home_address,
        campus_address,
        hostel_address,
        account_status
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (result.rowCount === 0) {
    throw new Error('User account not found.');
  }

  const user = result.rows[0];

  if (String(user.account_status).toLowerCase() !== 'active') {
    throw new Error('Your account is not active.');
  }

  return {
    home: user.home_address || '',
    campus: user.campus_address || '',
    hall: user.hostel_address || '',
  };
};

const updateSavedPlaces = async (userId, payload) => {
  const { home, campus, hall } = payload;

  if (
    home === undefined ||
    campus === undefined ||
    hall === undefined
  ) {
    throw new Error('Home, campus, and hall are required.');
  }

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

  await rideDb.query(
    `UPDATE users
     SET home_address = $1,
         campus_address = $2,
         hostel_address = $3
     WHERE user_id = $4`,
    [
      String(home).trim(),
      String(campus).trim(),
      String(hall).trim(),
      userId,
    ]
  );

  return true;
};

module.exports = {
  getSavedPlaces,
  updateSavedPlaces,
};