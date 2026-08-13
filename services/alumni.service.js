const pool = require('../config/rideDb');
const { sendAlumniRequestEmail } = require('../utils/alumniMailer');
const { createNotification } = require('./notificationService');

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

  // Alumni-এর user info বের করা — notification আর email পাঠানোর জন্য দরকার
  const alumniRow = await pool.query(
    `SELECT ap.user_id AS alumni_user_id, u.first_name AS alumni_first_name,
            u.last_name AS alumni_last_name, u.university_email AS alumni_email
     FROM alumni_profiles ap
     JOIN users u ON u.user_id = ap.user_id
     WHERE ap.alumni_id = $1 AND ap.verification_status = 'approved'`,
    [alumni_id]
  );

  if (!alumniRow.rows.length) {
    throw { status: 404, message: 'Alumni not found' };
  }

  const alumniInfo = alumniRow.rows[0];

  if (alumniInfo.alumni_user_id === requesterId) {
    throw { status: 400, message: 'You cannot send a request to yourself' };
  }

  const requesterRow = await pool.query(
    `SELECT first_name, last_name FROM users WHERE user_id = $1`,
    [requesterId]
  );
  const requesterName = requesterRow.rows.length
    ? `${requesterRow.rows[0].first_name || ''} ${requesterRow.rows[0].last_name || ''}`.trim()
    : 'A UniRide user';

  let insertResult;
  try {
    insertResult = await pool.query(
      `INSERT INTO alumni_contact_requests (alumni_id, requester_id, message)
       VALUES ($1,$2,$3)
       RETURNING request_id`,
      [alumni_id, requesterId, message || null]
    );
  } catch (err) {
    if (err.code === '23505') {
      throw { status: 409, message: 'You have already sent a request to this alumni' };
    }
    throw err;
  }

  // In-app notification — alumni এই ইউজারের নোটিফিকেশন লিস্টে দেখতে পাবে
  // target_role: 'general' রাখা হয়েছে যাতে user passenger/rider যেকোনো mode-এ থাকুক,
  // notification list-এ দেখা যায় (notificationService এর filter: target_role = role OR 'general')
  // createNotification() নিজেই socket push + FCM push + interaction log — সব করে দেয়
  await createNotification({
    userId: alumniInfo.alumni_user_id,
    title: 'New Connection Request',
    message: `${requesterName} wants to connect with you.`,
    type: 'alumni_request',
    isImportant: true,
    targetRole: 'general',
    relatedId: insertResult.rows[0].request_id,
  });

  // Email notification — app না খুললেও alumni জানতে পারবে
  try {
    await sendAlumniRequestEmail({
      toEmail: alumniInfo.alumni_email,
      alumniFirstName: alumniInfo.alumni_first_name,
      requesterName,
      requestMessage: message || '',
    });
  } catch (emailErr) {
    // ইমেইল ব্যর্থ হলেও request যেন আটকে না যায়
    console.error('Failed to send alumni request email:', emailErr.message);
  }

  return { success: true, message: 'Request sent' };
};

// REQUESTS — যেসব request এই alumni-এর প্রোফাইলে এসেছে, তার লিস্ট
exports.getRequests = async (req) => {
  const userId = req.user.userId;

  const alumniRow = await pool.query(
    `SELECT alumni_id FROM alumni_profiles WHERE user_id=$1 AND verification_status='approved'`,
    [userId]
  );

  if (!alumniRow.rows.length) {
    return { success: true, data: [] };
  }

  const alumniId = alumniRow.rows[0].alumni_id;

  const result = await pool.query(
    `SELECT
       acr.request_id, acr.message, acr.status, acr.phone_shared,
       acr.scheduled_time, acr.created_at,
       u.first_name, u.last_name, u.profile_picture,
       u.university_email,
       up.department AS requester_department
     FROM alumni_contact_requests acr
     JOIN users u ON u.user_id = acr.requester_id
     LEFT JOIN alumni_profiles up ON up.user_id = acr.requester_id
     WHERE acr.alumni_id = $1
     ORDER BY acr.created_at DESC`,
    [alumniId]
  );

  const rows = result.rows.map((row) => ({
    ...row,
    profile_picture: getImageUrl(req, row.profile_picture),
  }));

  return { success: true, data: rows };
};

// RESPOND
exports.respondRequest = async (req) => {
  const { requestId } = req.params;
  const { action, phone_shared, scheduled_time } = req.body;
  const userId = req.user.userId;

  if (!['accepted', 'rejected'].includes(action)) {
    throw { status: 400, message: 'Invalid action' };
  }

  // এই request টা আসলেই এই alumni-এর কাছে এসেছে কিনা যাচাই করা
  const reqRow = await pool.query(
    `SELECT acr.request_id, acr.alumni_id, acr.requester_id, acr.status,
            ap.user_id AS alumni_user_id,
            au.first_name AS alumni_first_name, au.last_name AS alumni_last_name
     FROM alumni_contact_requests acr
     JOIN alumni_profiles ap ON ap.alumni_id = acr.alumni_id
     JOIN users au ON au.user_id = ap.user_id
     WHERE acr.request_id = $1`,
    [requestId]
  );

  if (!reqRow.rows.length) {
    throw { status: 404, message: 'Request not found' };
  }

  const request = reqRow.rows[0];

  if (request.alumni_user_id !== userId) {
    throw { status: 403, message: 'Not allowed' };
  }

  if (request.status !== 'pending') {
    throw { status: 409, message: 'This request has already been responded to' };
  }

  await pool.query(
    `UPDATE alumni_contact_requests
     SET status=$1, phone_shared=$2, scheduled_time=$3, responded_at=CURRENT_TIMESTAMP
     WHERE request_id=$4`,
    [action, phone_shared === true, scheduled_time || null, requestId]
  );

  const alumniFullName =
    `${request.alumni_first_name || ''} ${request.alumni_last_name || ''}`.trim();

  if (action === 'accepted') {
    // schedule না দিলে সাথে সাথে chat window খুলে যাবে (২ ঘণ্টার জন্য)
    const chatScheduledAt = scheduled_time || new Date().toISOString();

    await pool.query(
      `INSERT INTO alumni_chat_sessions (request_id, alumni_id, requester_id, scheduled_at)
       VALUES ($1,$2,$3,$4)`,
      [requestId, request.alumni_id, request.requester_id, chatScheduledAt]
    );

    await createNotification({
      userId: request.requester_id,
      title: 'Connection Request Accepted',
      message: `${alumniFullName} accepted your request. You can now chat during the scheduled time.`,
      type: 'alumni_response',
      isImportant: true,
      targetRole: 'general',
      relatedId: requestId,
    });
  } else {
    await createNotification({
      userId: request.requester_id,
      title: 'Connection Request Declined',
      message: `${alumniFullName} declined your request.`,
      type: 'alumni_response',
      isImportant: false,
      targetRole: 'general',
      relatedId: requestId,
    });
  }

  return { success: true, message: `Request ${action}` };
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
