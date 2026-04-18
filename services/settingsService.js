const rideDb = require('../config/rideDb');

const getSettingsSummary = async (userId) => {
  const result = await rideDb.query(
    `SELECT 
        u.user_id,
        u.first_name,
        u.last_name,
        u.university_email,
        u.profile_picture,
        u.rating,
        u.account_status,
        u.activity_status,
        CASE
          WHEN EXISTS (
            SELECT 1
            FROM vehicles v
            WHERE v.user_id = u.user_id
          ) THEN 'yes'
          ELSE 'no'
        END AS rider
     FROM users u
     WHERE u.user_id = $1`,
    [userId]
  );

  if (result.rowCount === 0) {
    const err = new Error('User account not found.');
    err.statusCode = 404;
    throw err;
  }

  const user = result.rows[0];

  if ((user.account_status || '').toLowerCase() !== 'active') {
    const err = new Error('Your account is not active.');
    err.statusCode = 403;
    throw err;
  }

  const fullName =
      `${user.first_name || ''} ${user.last_name || ''}`.trim() || 'User Name';

  return {
    user_id: user.user_id,
    name: fullName,
    first_name: user.first_name || '',
    last_name: user.last_name || '',
    email: user.university_email || '',
    profile_picture: user.profile_picture || '',
    rating: Number(user.rating ?? 5),
    account_status: user.account_status || 'active',
    activity_status: user.activity_status || 'active',
    rider: user.rider || 'no',
  };
};

module.exports = {
  getSettingsSummary,
};
