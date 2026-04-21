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
  home_address: user.home_address || '',
  campus_address: user.campus_address || '',
  hostel_address: user.hostel_address || '',
};
};

const updateSavedPlaces = async (userId, payload) => {
  const { homeAddress, campusAddress, hostelAddress } = payload;

  if (
  homeAddress === undefined ||
  campusAddress === undefined ||
  hostelAddress === undefined
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
    homeAddress ? String(homeAddress).trim() : null,
    campusAddress ? String(campusAddress).trim() : null,
    hostelAddress ? String(hostelAddress).trim() : null,
    userId,
  ]
);

  return true;
};

module.exports = {
  getSavedPlaces,
  updateSavedPlaces,
};
