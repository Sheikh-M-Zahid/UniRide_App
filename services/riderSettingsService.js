const rideDb = require('../config/rideDb');

const buildProfilePictureUrl = (req, storedPath) => {
  if (!storedPath) return null;

  if (storedPath.startsWith('http://') || storedPath.startsWith('https://')) {
    return storedPath;
  }

  const baseUrl = `${req.protocol}://${req.get('host')}`;
  return `${baseUrl}${storedPath}`;
};

const mapSettingsSummary = (row, req) => {
  const firstName = row.first_name || '';
  const lastName = row.last_name || '';

  return {
    userId: row.user_id,
    firstName,
    lastName,
    fullName: `${firstName} ${lastName}`.trim(),
    email: row.university_email,
    rating: Number(row.rating || 0),
    profilePicture: buildProfilePictureUrl(req, row.profile_picture),
  };
};

const getSettingsSummary = async ({ userId, req }) => {
  const query = `
    SELECT
      user_id,
      first_name,
      last_name,
      university_email,
      rating,
      profile_picture
    FROM users
    WHERE user_id = $1
    LIMIT 1
  `;

  const { rows } = await rideDb.query(query, [userId]);

  if (!rows.length) {
    throw new Error('User settings summary not found.');
  }

  return mapSettingsSummary(rows[0], req);
};

module.exports = {
  getSettingsSummary,
};