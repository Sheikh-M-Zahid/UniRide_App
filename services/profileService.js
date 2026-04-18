const rideDb = require('../config/rideDb');

/* =========================
   PROFILE COMPLETION
========================= */
const calculateProfileCompletion = (user) => {
  let completion = 0;

  if (user.first_name && user.last_name) completion += 15;
  if (user.profile_picture) completion += 20;
  if (user.gender) completion += 10;
  if (user.emergency_phone) completion += 15;
  if (user.university_email) completion += 15;
  if (user.date_of_birth) completion += 15;
  if (user.recovery_phone) completion += 10;

  return completion;
};

/* =========================
   GET PROFILE
========================= */
const getMyProfile = async (userId) => {
  const result = await rideDb.query(
    `SELECT
        user_id,
        first_name,
        last_name,
        university_email,
        phone,
        recovery_phone,
        emergency_phone,
        gender,
        date_of_birth,
        profile_picture,
        rating,
        rating_count,
        profile_completed_at
     FROM users
     WHERE user_id = $1
     LIMIT 1`,
    [userId]
  );

  if (!result.rows.length) {
    throw new Error('User not found.');
  }

  const user = result.rows[0];

  const profileCompletion = calculateProfileCompletion(user);

  return {
    userId: user.user_id,
    firstName: user.first_name,
    lastName: user.last_name,
    fullName: `${user.first_name || ''} ${user.last_name || ''}`.trim(),
    rating: Number(user.rating || 0),
    ratingCount: Number(user.rating_count || 0),
    profilePicture: user.profile_picture || null,
    gender: user.gender,
    emergencyContactNumber: user.emergency_phone,
    universityEmail: user.university_email,
    dateOfBirth: user.date_of_birth,
    secondaryPhoneNumber: user.recovery_phone,
    profileCompletion,
    profileCompletedAt: user.profile_completed_at,
  };
};

/* =========================
   UPDATE PROFILE IMAGE
========================= */
const updateProfileImage = async (userId, filePath) => {
  const result = await rideDb.query(
    `UPDATE users
     SET profile_picture = $2,
         updated_at = CURRENT_TIMESTAMP
     WHERE user_id = $1
     RETURNING user_id, profile_picture`,
    [userId, filePath]
  );

  return {
    userId: result.rows[0].user_id,
    profilePicture: result.rows[0].profile_picture,
  };
};

module.exports = {
  getMyProfile,
  updateProfileImage,
};