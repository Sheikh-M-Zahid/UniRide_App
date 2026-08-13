// services/alumniProfile.service.js
// শুধু public alumni profile view এর জন্য — verification documents কখনোই এখান থেকে যাবে না
const pool = require('../config/rideDb');

const getImageUrl = (req, filePath) => {
  if (!filePath) return null;
  if (filePath.startsWith('http')) return filePath;
  return `${req.protocol}://${req.get('host')}/${filePath}`;
};

// alumni_card_photo, transcript_photo, rejection_reason, reviewed_by — এগুলো ইচ্ছাকৃতভাবে বাদ
const SAFE_ALUMNI_FIELDS = `
  ap.alumni_id, ap.user_id, ap.degree_type,
  ap.department, ap.major_subject, ap.graduation_year,
  ap.graduation_university, ap.graduation_department, ap.graduation_major, ap.graduation_year_actual,
  ap.masters_university, ap.masters_subject, ap.masters_completion_year, ap.masters_status,
  ap.current_workplace, ap.current_position,
  ap.lives_abroad, ap.country
`;

exports.getAlumniProfileById = async (req) => {
  const { alumniId } = req.params;

  const result = await pool.query(
    `SELECT ${SAFE_ALUMNI_FIELDS}, u.first_name, u.last_name, u.profile_picture
     FROM alumni_profiles ap
     JOIN users u ON u.user_id = ap.user_id
     WHERE ap.alumni_id = $1 AND ap.verification_status = 'approved'`,
    [alumniId]
  );

  if (!result.rows.length) {
    throw { status: 404, message: 'Alumni not found' };
  }

  const alumni = result.rows[0];
  alumni.profile_picture = getImageUrl(req, alumni.profile_picture);

  const worksResult = await pool.query(
    `SELECT work_id, work_title, work_link
     FROM alumni_works
     WHERE alumni_id = $1
     ORDER BY display_order ASC`,
    [alumniId]
  );
  alumni.works = worksResult.rows;

  return { success: true, data: alumni };
};
