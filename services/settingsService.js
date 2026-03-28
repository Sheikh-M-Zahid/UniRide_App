const rideDb = require('../config/rideDb');

const getSettingsSummary = async (userId) => {
  const result = await rideDb.query(
    `SELECT 
        user_id,
        first_name,
        last_name,
        university_email,
        profile_picture,
        rating,
        account_status,
        activity_status,
        rider
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (result.rowCount === 0) {
    throw new Error('User account not found.');
  }

  const user = result.rows[0];

  // account check
  if (user.account_status !== 'Active') {
    throw new Error('Your account is not active.');
  }

  const fullName = `${user.first_name || ''} ${user.last_name || ''}`.trim();

  return {
    name: fullName,
    email: user.university_email,
    profile_picture: user.profile_picture,
    rating: user.rating,
    rider: user.rider || 'no',
  };
};

module.exports = {
  getSettingsSummary,
};