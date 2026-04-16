const rideDb = require('../config/rideDb');

const buildProfilePictureUrl = (req, storedPath) => {
  if (!storedPath) return null;

  // already full url হলে direct return
  if (storedPath.startsWith('http://') || storedPath.startsWith('https://')) {
    return storedPath;
  }

  const baseUrl = `${req.protocol}://${req.get('host')}`;
  return `${baseUrl}${storedPath}`;
};

const mapProfile = (row, req) => {
  const firstName = row.first_name || '';
  const lastName = row.last_name || '';

  return {
    userId: row.user_id,
    firstName,
    lastName,
    fullName: `${firstName} ${lastName}`.trim(),
    rating: Number(row.rating || 0),
    profilePicture: buildProfilePictureUrl(req, row.profile_picture),
  };
};

const getProfile = async ({ userId, req }) => {
  const query = `
    SELECT
      user_id,
      first_name,
      last_name,
      rating,
      profile_picture
    FROM users
    WHERE user_id = $1
    LIMIT 1
  `;

  const { rows } = await rideDb.query(query, [userId]);

  if (!rows.length) {
    throw new Error('User profile not found.');
  }

  return mapProfile(rows[0], req);
};

const uploadProfileImage = async ({ userId, file, req }) => {
  const storedPath = `/uploads/profiles/${file.filename}`;

  const query = `
    UPDATE users
    SET profile_picture = $1
    WHERE user_id = $2
    RETURNING
      user_id,
      first_name,
      last_name,
      rating,
      profile_picture
  `;

  const { rows } = await rideDb.query(query, [storedPath, userId]);

  if (!rows.length) {
    throw new Error('Failed to update profile image.');
  }

  return mapProfile(rows[0], req);
};

module.exports = {
  getProfile,
  uploadProfileImage,
};
