const pool = require('../config/rideDb');

const getImageUrl = (req, filePath) => {
  if (!filePath) return null;
  if (filePath.startsWith('http')) return filePath;
  return `${req.protocol}://${req.get('host')}/${filePath}`;
};

// REGISTER
exports.registerAlumni = async (req) => {
  const userId = req.user.userId;

  const existing = await pool.query(
    'SELECT alumni_id, verification_status FROM alumni_profiles WHERE user_id = $1',
    [userId]
  );

  if (existing.rows.length > 0) {
    const st = existing.rows[0].verification_status;
    if (st === 'pending') throw { status: 409, message: 'Already under review' };
    if (st === 'approved') throw { status: 409, message: 'Already verified' };

    await pool.query('DELETE FROM alumni_profiles WHERE user_id = $1', [userId]);
  }

  const {
    degree_type,
    department,
    major_subject,
    graduation_year,
    current_workplace,
    current_position,
    lives_abroad,
    country,
    graduation_university,
    graduation_department,
    graduation_major,
    graduation_year_actual,
    masters_status,
    masters_university,
    masters_subject,
    masters_completion_year,
    works,
  } = req.body;

  // Required field checks
  if (!degree_type) throw { status: 400, message: 'degree_type required' };
  if (!department) throw { status: 400, message: 'department required' };
  if (!major_subject) throw { status: 400, message: 'major_subject required' };
  if (!graduation_year) throw { status: 400, message: 'graduation_year required' };

  if (!req.files?.alumni_card_photo || !req.files?.transcript_photo) {
    throw { status: 400, message: 'Images required' };
  }

  const alumniCard = req.files.alumni_card_photo[0].path;
  const transcript = req.files.transcript_photo[0].path;

  // lives_abroad আসে string হিসেবে ('true'/'false') multipart form থেকে
  const livesAbroadBool = lives_abroad === 'true' || lives_abroad === true;

  const insert = await pool.query(
    `INSERT INTO alumni_profiles (
       user_id, degree_type, department, major_subject, graduation_year,
       current_workplace, current_position, lives_abroad, country,
       alumni_card_photo, transcript_photo,
       graduation_university, graduation_department, graduation_major, graduation_year_actual,
       masters_status, masters_university, masters_subject, masters_completion_year
     )
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19)
     RETURNING alumni_id`,
    [
      userId,
      degree_type,
      department,
      major_subject,
      parseInt(graduation_year, 10),
      current_workplace || null,
      current_position || null,
      livesAbroadBool,
      country || 'Bangladesh',
      alumniCard,
      transcript,
      graduation_university || null,
      graduation_department || null,
      graduation_major || null,
      graduation_year_actual ? parseInt(graduation_year_actual, 10) : null,
      masters_status || null,
      masters_university || null,
      masters_subject || null,
      masters_completion_year ? parseInt(masters_completion_year, 10) : null,
    ]
  );

  const alumniId = insert.rows[0].alumni_id;

  // WORKS ইনসার্ট করা (যদি থাকে)
  if (works) {
    try {
      const worksArray = JSON.parse(works);
      if (Array.isArray(worksArray) && worksArray.length > 0) {
        for (let i = 0; i < worksArray.length; i++) {
          const w = worksArray[i];
          if (w.work_title) {
            await pool.query(
              `INSERT INTO alumni_works (alumni_id, work_title, work_link, display_order)
               VALUES ($1,$2,$3,$4)`,
              [alumniId, w.work_title, w.work_link || null, i]
            );
          }
        }
      }
    } catch (e) {
      // works parse ব্যর্থ হলেও রেজিস্ট্রেশন আটকাবে না
      console.error('Failed to parse/insert works:', e.message);
    }
  }

  return {
    success: true,
    message: 'Submitted successfully',
    data: { alumni_id: alumniId }
  };
};

// STATUS
exports.getMyStatus = async (req) => {
  const userId = req.user.userId;

  const result = await pool.query(
    `SELECT ap.*, u.first_name, u.last_name, u.profile_picture
     FROM alumni_profiles ap
     JOIN users u ON u.user_id = ap.user_id
     WHERE ap.user_id = $1`,
    [userId]
  );

  if (!result.rows.length) return { success: true, data: null };

  const row = result.rows[0];
  row.profile_picture = getImageUrl(req, row.profile_picture);

  return { success: true, data: row };
};

// UPDATE
exports.updateProfile = async (req) => {
  const userId = req.user.userId;

  const check = await pool.query(
    `SELECT alumni_id FROM alumni_profiles
     WHERE user_id=$1 AND verification_status='approved'`,
    [userId]
  );

  if (!check.rows.length) throw { status: 403, message: 'Not allowed' };

  const alumniId = check.rows[0].alumni_id;

  await pool.query(
    `UPDATE alumni_profiles SET current_workplace=$1, current_position=$2 WHERE alumni_id=$3`,
    [req.body.current_workplace || null, req.body.current_position || null, alumniId]
  );

  return { success: true, message: 'Updated' };
};

// LIST
exports.getAlumniList = async (req) => {
  const result = await pool.query(
    `SELECT
       ap.alumni_id, ap.degree_type,
       ap.department, ap.major_subject, ap.graduation_year,
       ap.current_workplace, ap.current_position,
       ap.lives_abroad, ap.country,
       u.first_name, u.last_name, u.profile_picture
     FROM alumni_profiles ap
     JOIN users u ON u.user_id = ap.user_id
     WHERE ap.verification_status='approved'`
  );

  const rows = result.rows.map((row) => ({
    ...row,
    profile_picture: getImageUrl(req, row.profile_picture),
  }));

  return { success: true, data: rows };
};

// DEPARTMENTS
exports.getDepartments = async () => {
  const result = await pool.query(
    `SELECT DISTINCT department FROM alumni_profiles WHERE department IS NOT NULL`
  );
  return { success: true, data: result.rows.map(r => r.department) };
};

// CONTACT REQUEST
exports.sendContactRequest = async (req) => {
  const { alumni_id, message } = req.body;
  const requesterId = req.user.userId;

  if (!alumni_id) throw { status: 400, message: 'alumni_id required' };

  await pool.query(
    `INSERT INTO alumni_contact_requests (alumni_id, requester_id, message)
     VALUES ($1,$2,$3)`,
    [alumni_id, requesterId, message || null]
  );

  return { success: true, message: 'Request sent' };
};

// REQUESTS
exports.getRequests = async (req) => {
  const userId = req.user.userId;

  const result = await pool.query(
    `SELECT * FROM alumni_contact_requests WHERE requester_id=$1`,
    [userId]
  );

  return { success: true, data: result.rows };
};

// RESPOND
exports.respondRequest = async (req) => {
  const { requestId } = req.params;
  const { action } = req.body;

  await pool.query(
    `UPDATE alumni_contact_requests SET status=$1 WHERE request_id=$2`,
    [action, requestId]
  );

  return { success: true, message: 'Updated' };
};

// CHAT
exports.getMessages = async (req) => {
  const { sessionId } = req.params;

  const result = await pool.query(
    `SELECT * FROM alumni_chat_messages WHERE session_id=$1`,
    [sessionId]
  );

  return { success: true, data: result.rows };
};

exports.getMyChats = async (req) => {
  const userId = req.user.userId;

  const result = await pool.query(
    `SELECT * FROM alumni_chat_sessions WHERE requester_id=$1`,
    [userId]
  );

  return { success: true, data: result.rows };
};

// ADMIN
exports.getPending = async () => {
  const result = await pool.query(
    `SELECT * FROM alumni_profiles WHERE verification_status='pending'`
  );
  return { success: true, data: result.rows };
};

exports.getPendingCount = async () => {
  const result = await pool.query(
    `SELECT COUNT(*) FROM alumni_profiles WHERE verification_status='pending'`
  );
  return { success: true, data: result.rows[0] };
};

exports.reviewAlumni = async (req) => {
  const { alumniId } = req.params;
  const { action } = req.body;

  await pool.query(
    `UPDATE alumni_profiles SET verification_status=$1 WHERE alumni_id=$2`,
    [action, alumniId]
  );

  return { success: true, message: `Alumni ${action}` };
};
