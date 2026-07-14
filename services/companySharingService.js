const rideDb = require('../config/rideDb');
const { createNotification } = require('./notificationService');
const { emitCoRideSeatUpdate } = require('../utils/coRideEmitter');
const coRideRecommendationService = require('./coRideRecommendationService');
const { computeRoute } = require('./googleMapsService');
const { safeDistanceKm } = require('../utils/geo');
const admin = require('../config/firebase');
const { emitCompanyChatMessage, isUserOnline } = require('../utils/companyChatRealtime');
const { isUserViewingSession } = require('../utils/coRideChatPresence');
const activeRideGuardService = require('./activeRideGuardService');
const safetyCheckService = require('./safetyCheckService');

// ── CoRide চ্যাট push notification (যদি রিসিভার সেই চ্যাট স্ক্রিনে না থাকে) ──
const sendChatPushNotification = async (recipientId, senderName, messageText, sessionId) => {
  try {
    const tokenResult = await rideDb.query(
      `SELECT fcm_token FROM users WHERE user_id = $1`,
      [recipientId]
    );
    const fcmToken = tokenResult.rows[0]?.fcm_token;
    if (!fcmToken) return;

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: senderName,
        body: messageText,
      },
      data: {
        type: 'co_ride_chat',
        sessionId: String(sessionId),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'uniride_channel',
          priority: 'high',
          defaultSound: true,
        },
      },
    });
  } catch (err) {
    console.error('CoRide chat FCM error:', err?.message);
  }
};

const NOTIFY_RADIUS_KM = 2;

const createSession = async (userId, payload) => {
  await activeRideGuardService.assertNoActiveRideConflict(userId);

  const {
    start_location,
    destination,
    status,
    trip_date,
    trip_time,
    vehicle_type,
    vehicle_number,
    total_seats,
    preferred_gender,
    fare_per_person,
    start_lat,
    start_lng,
    destination_lat,
    destination_lng,
  } = payload;

  // ── route polyline compute করো (lat/lng থাকলে) ──
  let routePolyline = null;
  let routeDistanceKm = null;
  let routeDurationMinutes = null;

  if (start_lat && start_lng && destination_lat && destination_lng) {
    try {
      const route = await computeRoute({
        originLat: start_lat,
        originLng: start_lng,
        destinationLat: destination_lat,
        destinationLng: destination_lng,
      });
      routePolyline = route.polyline;
      routeDistanceKm = route.distanceKm;
      routeDurationMinutes = route.durationMinutes;
    } catch (err) {
      console.error('CoRide route compute failed:', err.message);
    }
  }

  const result = await rideDb.query(
    `INSERT INTO company_sharing_sessions 
      (created_by, start_location, destination, status,
       trip_date, trip_time, vehicle_type, vehicle_number,
       total_seats, booked_seats, preferred_gender, fare_per_person,
       start_lat, start_lng, destination_lat, destination_lng,
       route_polyline, route_distance_km, route_duration_minutes)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,0,$10,$11,$12,$13,$14,$15,$16,$17,$18)
     RETURNING *`,
    [
      userId,
      start_location,
      destination,
      status || 'Active',
      trip_date || null,
      trip_time || null,
      vehicle_type || null,
      vehicle_number || null,
      total_seats || 2,
      preferred_gender || 'Any',
      fare_per_person || null,
      start_lat || null,
      start_lng || null,
      destination_lat || null,
      destination_lng || null,
      routePolyline,
      routeDistanceKm,
      routeDurationMinutes,
    ]
  );

  const session = result.rows[0];

  // // ── Radius-based notification (২ কিমি এর মধ্যে home_location থাকা user) ──
  // let userQuery = `
  //   SELECT user_id, first_name, last_name, gender, home_location_lat, home_location_lng
  //   FROM users
  //   WHERE user_id != $1
  // `;
  // const params = [userId];

  // if (preferred_gender && preferred_gender.toLowerCase() !== 'any') {
  //   userQuery += ` AND LOWER(gender) = LOWER($2)`;
  //   params.push(preferred_gender);
  // }

  // const users = await rideDb.query(userQuery, params);

  // const creatorResult = await rideDb.query(
  //   `SELECT first_name, last_name FROM users WHERE user_id = $1`,
  //   [userId]
  // );
  // const creator = creatorResult.rows[0];
  // const creatorName = `${creator.first_name} ${creator.last_name}`;

  // const nearbyUsers = (start_lat && start_lng)
  //   ? users.rows.filter((u) => {
  //       if (!u.home_location_lat || !u.home_location_lng) return true; // location অজানা হলে fallback হিসেবে পাঠাও
  //       const dist = safeDistanceKm(
  //         Number(start_lat), Number(start_lng),
  //         Number(u.home_location_lat), Number(u.home_location_lng)
  //       );
  //       return dist === null || dist <= NOTIFY_RADIUS_KM;
  //     })
  //   : users.rows;

  // for (const user of nearbyUsers) {
  //   await createNotification({
  //     userId: user.user_id,
  //     title: 'New CoRide Available!',
  //     message: `${creatorName} is looking for co-riders from ${start_location} to ${destination}. Fare: ৳${fare_per_person || 'N/A'} per person.`,
  //     type: 'co_ride',
  //     isImportant: false,
  //     targetRole: 'passenger',
  //     relatedId: String(session.session_id || session.id),
  //   });
  // }

  return session;
};

const getSessionById = async (sessionId) => {
  const result = await rideDb.query(
    `SELECT css.*, 
            u.first_name, u.last_name, u.phone
     FROM company_sharing_sessions css
     JOIN users u ON css.created_by = u.user_id
     WHERE css.session_id = $1`,
    [sessionId]
  );

  if (result.rowCount === 0) throw new Error('Session not found.');
  return result.rows[0];
};

const joinSession = async (sessionId, userId) => {
  await activeRideGuardService.assertNoActiveRideConflict(userId);

  // Already joined check
  const existing = await rideDb.query(
    `SELECT id FROM company_participants WHERE session_id = $1 AND user_id = $2`,
    [sessionId, userId]
  );
  if (existing.rowCount > 0) throw new Error('Already joined this session.');

  // Session block check
  const sessionResult = await rideDb.query(
    `SELECT * FROM company_sharing_sessions WHERE session_id = $1`,
    [sessionId]
  );
  if (sessionResult.rowCount === 0) throw new Error('Session not found.');

  const session = sessionResult.rows[0];
  const availableSeats = session.total_seats - session.booked_seats;
  if (availableSeats <= 0) throw new Error('No seats available.');

  // ── Gender safety check (নতুন) ──
  const joiningUserRes = await rideDb.query(
    `SELECT gender FROM users WHERE user_id = $1`,
    [userId]
  );
  const joiningUserGender = joiningUserRes.rows[0]?.gender;
  if (!coRideRecommendationService.isGenderAllowed(session.preferred_gender, joiningUserGender)) {
    throw new Error(`This CoRide is only open to ${session.preferred_gender} riders.`);
  }

  // Join
  const participant = await rideDb.query(
    `INSERT INTO company_participants (session_id, user_id, confirmed)
     VALUES ($1, $2, TRUE)
     RETURNING *`,
    [sessionId, userId]
  );

  // Seat decrement
  await rideDb.query(
    `UPDATE company_sharing_sessions
     SET booked_seats = booked_seats + 1
     WHERE session_id = $1`,
    [sessionId]
  );

  // Updated seat count emit (socket)
  const updatedSeats = availableSeats - 1;
  emitCoRideSeatUpdate(sessionId, updatedSeats);

  // Booker info fetch
  const bookerResult = await rideDb.query(
    `SELECT first_name, last_name, phone FROM users WHERE user_id = $1`,
    [userId]
  );
  const booker = bookerResult.rows[0];
  const bookerName = `${booker.first_name} ${booker.last_name}`;

  // Creator info fetch
  const creatorResult = await rideDb.query(
    `SELECT user_id, first_name, last_name, phone FROM users WHERE user_id = $1`,
    [session.created_by]
  );
  const creator = creatorResult.rows[0];
  const creatorName = `${creator.first_name} ${creator.last_name}`;

  // ── Creator-কে নোটিফিকেশন: booker এর নাম + ফোন
  await createNotification({
    userId: session.created_by,
    title: 'Someone Booked Your CoRide!',
    message: `${bookerName} has booked a seat. Phone: ${booker.phone || 'N/A'}`,
    type: 'co_ride',
    isImportant: true,
    targetRole: 'passenger',
    relatedId: String(sessionId),
  });

  // ── Booker-কে নোটিফিকেশন: creator এর নাম + ফোন
  await createNotification({
    userId: userId,
    title: 'CoRide Booking Confirmed!',
    message: `You booked a seat with ${creatorName}. Their phone: ${creator.phone || 'N/A'}. From: ${session.start_location} → ${session.destination}`,
    type: 'co_ride',
    isImportant: true,
    targetRole: 'passenger',
    relatedId: String(sessionId),
  });

  return participant.rows[0];
};

const cancelSession = async (sessionId, userId, { currentLat, currentLng } = {}) => {
  const sessionRes = await rideDb.query(
    `SELECT * FROM company_sharing_sessions WHERE session_id = $1`,
    [sessionId]
  );
  if (sessionRes.rowCount === 0) throw new Error('Session not found.');
  const session = sessionRes.rows[0];

  if (String(session.created_by) !== String(userId)) {
    throw new Error('Only the host can close this CoRide.');
  }
  if (session.status !== 'Active') {
    throw new Error('This CoRide is already closed.');
  }

  let newStatus;
  let needsSafetyCheck = false;

  if (!session.is_started) {
    newStatus = 'Cancelled';
  } else {
    let progress = null;
    if (
      currentLat != null && currentLng != null &&
      session.destination_lat && session.destination_lng && session.route_distance_km
    ) {
      const remainingKm = safeDistanceKm(
        Number(currentLat), Number(currentLng),
        Number(session.destination_lat), Number(session.destination_lng)
      );
      if (remainingKm !== null) {
        const traveledKm = Math.max(0, Number(session.route_distance_km) - remainingKm);
        progress = (traveledKm / Number(session.route_distance_km)) * 100;
      }
    }
    newStatus = (progress !== null && progress >= 50) ? 'Completed' : 'Cancelled';
    needsSafetyCheck = true;
  }

  const updated = await rideDb.query(
    `UPDATE company_sharing_sessions
     SET status = $1, closed_at = CURRENT_TIMESTAMP, closed_reason = $2,
         current_lat = COALESCE($3, current_lat), current_lng = COALESCE($4, current_lng)
     WHERE session_id = $5
     RETURNING *`,
    [
      newStatus,
      newStatus === 'Completed' ? 'manual_completed' : 'manual_cancelled',
      currentLat ?? null,
      currentLng ?? null,
      sessionId,
    ]
  );
  const finalSession = updated.rows[0];

  const participants = await rideDb.query(
    `SELECT user_id FROM company_participants WHERE session_id = $1 AND confirmed = TRUE`,
    [sessionId]
  );

  const statusLabelBn = newStatus === 'Completed' ? 'সম্পন্ন হয়েছে' : 'বাতিল হয়েছে';

  await createNotification({
    userId: session.created_by,
    title: `CoRide ${newStatus}`,
    message: `Your CoRide trip ${statusLabelBn}।`,
    type: 'co_ride',
    isImportant: true,
    targetRole: 'passenger',
    relatedId: String(sessionId),
  });

  for (const p of participants.rows) {
    await createNotification({
      userId: p.user_id,
      title: `CoRide ${newStatus}`,
      message: `Your CoRide trip ${statusLabelBn}।`,
      type: 'co_ride',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: String(sessionId),
    });
  }

  const { emitCoRideStatusChange } = require('../utils/coRideEmitter');
  emitCoRideStatusChange(sessionId, { status: newStatus });

  if (needsSafetyCheck) {
    await safetyCheckService.createSafetyCheck({
      sessionId, rideType: 'coride',
      recipientUserId: session.created_by, recipientRole: 'host',
    });
    for (const p of participants.rows) {
      await safetyCheckService.createSafetyCheck({
        sessionId, rideType: 'coride',
        recipientUserId: p.user_id, recipientRole: 'participant',
      });
    }
  }

  return finalSession;
};

const startSession = async (sessionId, userId) => {
  const result = await rideDb.query(
    `UPDATE company_sharing_sessions
     SET is_started = TRUE, started_at = NOW()
     WHERE session_id = $1 AND created_by = $2
     RETURNING *`,
    [sessionId, userId]
  );
  if (result.rowCount === 0) throw new Error('Session not found or unauthorized.');

  // Participants-দের notify করো
  const participants = await rideDb.query(
    `SELECT cp.user_id FROM company_participants cp WHERE cp.session_id = $1`,
    [sessionId]
  );

  const session = result.rows[0];
  for (const p of participants.rows) {
    await createNotification({
      userId: p.user_id,
      title: 'CoRide Started!',
      message: `Your co-rider has started the journey from ${session.start_location}. You can now track their live location.`,
      type: 'co_ride',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: String(sessionId),
    });
  }

  return result.rows[0];
};

const updateLiveLocation = async (sessionId, userId, lat, lng) => {
  const result = await rideDb.query(
    `UPDATE company_sharing_sessions
     SET current_lat = $1, current_lng = $2
     WHERE session_id = $3 AND created_by = $4
     RETURNING session_id, current_lat, current_lng`,
    [lat, lng, sessionId, userId]
  );
  if (result.rowCount === 0) throw new Error('Unauthorized or not found.');

  // Socket emit
  const { emitCoRideLiveLocation } = require('../utils/coRideEmitter');
  emitCoRideLiveLocation(sessionId, { lat, lng });

  return result.rows[0];
};

const getLiveLocation = async (sessionId) => {
  const result = await rideDb.query(
    `SELECT current_lat, current_lng, is_started
     FROM company_sharing_sessions
     WHERE session_id = $1`,
    [sessionId]
  );
  if (result.rowCount === 0) throw new Error('Session not found.');
  const session = result.rows[0];
  return {
    ...session,
    is_active: session.status === 'Active',
    can_track_live: session.status === 'Active' && session.is_started === true,
  };
};

const getMyActiveSession = async (userId) => {
  const result = await rideDb.query(
    `SELECT css.*, u.first_name, u.last_name, u.university_email,
            (css.total_seats - css.booked_seats) AS available_seats
     FROM company_sharing_sessions css
     JOIN users u ON css.created_by = u.user_id
     WHERE css.status = 'Active'
     ORDER BY css.created_at DESC`
  );

  if (!userId) return result.rows;

  const userRes = await rideDb.query(
    `SELECT gender, university_email FROM users WHERE user_id = $1`,
    [userId]
  );
  const user = userRes.rows[0];
  if (!user) return result.rows;

  return coRideRecommendationService.scoreAndSortSessions({
    userId,
    userGender: user.gender,
    userEmail: user.university_email,
    sessions: result.rows,
  });
};

const sendCompanyChatMessage = async (sessionId, senderId, message_text) => {
  const result = await rideDb.query(
    `INSERT INTO company_chats (session_id, sender_id, message_text)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [sessionId, senderId, message_text]
  );

  const message = result.rows[0];

  const userRes = await rideDb.query(
    `SELECT first_name, last_name FROM users WHERE user_id = $1`,
    [senderId]
  );
  const senderName = userRes.rows[0]
    ? `${userRes.rows[0].first_name} ${userRes.rows[0].last_name}`
    : 'User';

  // ── প্রাপক খুঁজে বের করো: creator + confirmed participants, নিজেকে বাদ দিয়ে ──
  const recipientsRes = await rideDb.query(
    `SELECT created_by AS user_id FROM company_sharing_sessions WHERE session_id = $1
     UNION
     SELECT user_id FROM company_participants WHERE session_id = $1 AND confirmed = TRUE`,
    [sessionId]
  );
  const recipients = recipientsRes.rows
    .map((r) => r.user_id)
    .filter((id) => String(id) !== String(senderId));

  // ── কেউ অনলাইনে থাকলে সাথে সাথে delivered_at সেট করো ──
  const anyoneOnline = recipients.some((id) => isUserOnline(id));
  let deliveredAt = null;

  if (anyoneOnline) {
    const updateRes = await rideDb.query(
      `UPDATE company_chats SET delivered_at = CURRENT_TIMESTAMP
       WHERE chat_id = $1
       RETURNING delivered_at`,
      [message.chat_id]
    );
    deliveredAt = updateRes.rows[0]?.delivered_at || null;
  }

  // ── Real-time socket emit (যারা চ্যাট স্ক্রিনে আছে তারা সাথে সাথে দেখবে) ──
  emitCompanyChatMessage(sessionId, {
    chat_id: message.chat_id,
    session_id: sessionId,
    sender_id: message.sender_id,
    sender_name: senderName,
    message_text: message.message_text,
    sent_at: message.sent_at,
  });

  // ── Push notification: শুধু যারা এই মুহূর্তে এই চ্যাট স্ক্রিনে নাই তাদের কাছে ──
  for (const recipientId of recipients) {
    if (!isUserViewingSession(sessionId, recipientId)) {
      await sendChatPushNotification(recipientId, senderName, message_text, sessionId);
    }
  }

  return {
    ...message,
    sender_name: senderName,
    is_mine: true,
    status: deliveredAt ? 'delivered' : 'sent',
  };
};

const fetchCompanyChatMessages = async (sessionId, userId) => {
  const result = await rideDb.query(
    `SELECT cc.*, u.first_name, u.last_name, u.university_email
     FROM company_chats cc
     JOIN users u ON cc.sender_id = u.user_id
     WHERE cc.session_id = $1
     ORDER BY cc.sent_at ASC`,
    [sessionId]
  );

  // অন্য participant-দের মধ্যে সবচেয়ে পুরনো last_read_at বের করো
  // (সবাই মেসেজটা দেখেছে কিনা সেটা যাচাই করার জন্য)
  const readsRes = await rideDb.query(
    `SELECT MIN(last_read_at) AS min_last_read
     FROM company_chat_reads
     WHERE session_id = $1 AND user_id != $2`,
    [sessionId, userId]
  );
  const othersMinLastRead = readsRes.rows[0]?.min_last_read || null;

  return result.rows.map((row) => {
    const isMine = String(row.sender_id) === String(userId);
    let status = null;
    let statusTime = null;

    if (isMine) {
      if (othersMinLastRead && new Date(row.sent_at) <= new Date(othersMinLastRead)) {
        status = 'seen';
        statusTime = othersMinLastRead;
      } else if (row.delivered_at) {
        status = 'delivered';
      } else {
        status = 'sent';
      }
    }

    return {
      ...row,
      sender_name: `${row.first_name} ${row.last_name}`,
      is_mine: isMine,
      status,
      status_time: statusTime,
    };
  });
};

const markCompanyChatAsRead = async (sessionId, userId) => {
  const upsertQuery = `
    INSERT INTO company_chat_reads (session_id, user_id, last_read_at)
    VALUES ($1, $2, CURRENT_TIMESTAMP)
    ON CONFLICT (session_id, user_id)
    DO UPDATE SET last_read_at = CURRENT_TIMESTAMP
  `;
  await rideDb.query(upsertQuery, [sessionId, userId]);
  return { success: true };
};

// ── Confirmed participant নিজে জার্নি-শুরুর-আগে CoRide ছেড়ে দিতে পারবে ──
const leaveSession = async (sessionId, userId) => {
  const sessionRes = await rideDb.query(
    `SELECT * FROM company_sharing_sessions WHERE session_id = $1`,
    [sessionId]
  );
  if (sessionRes.rowCount === 0) throw new Error('Session not found.');
  const session = sessionRes.rows[0];

  if (session.status !== 'Active') {
    throw new Error('This CoRide is already closed.');
  }
  if (session.is_started) {
    throw new Error('Journey has already started — you can no longer leave this CoRide.');
  }

  const partRes = await rideDb.query(
    `SELECT id FROM company_participants WHERE session_id = $1 AND user_id = $2 AND confirmed = TRUE`,
    [sessionId, userId]
  );
  if (partRes.rowCount === 0) throw new Error('You are not part of this CoRide.');

  await rideDb.query(
    `DELETE FROM company_participants WHERE session_id = $1 AND user_id = $2`,
    [sessionId, userId]
  );

  await rideDb.query(
    `UPDATE company_sharing_sessions SET booked_seats = GREATEST(booked_seats - 1, 0) WHERE session_id = $1`,
    [sessionId]
  );

  const updatedSeats = (session.total_seats || 0) - Math.max((session.booked_seats || 1) - 1, 0);
  emitCoRideSeatUpdate(sessionId, updatedSeats);

  const leavingUserRes = await rideDb.query(
    `SELECT first_name, last_name FROM users WHERE user_id = $1`,
    [userId]
  );
  const leavingUserName = leavingUserRes.rows[0]
    ? `${leavingUserRes.rows[0].first_name} ${leavingUserRes.rows[0].last_name}`
    : 'A passenger';

  await createNotification({
    userId: session.created_by,
    title: 'A passenger has left the CoRide.ে',
    message: `${leavingUserName} A passenger left your CoRide before the journey started.`,
    type: 'co_ride',
    isImportant: false,
    targetRole: 'passenger',
    relatedId: String(sessionId),
  });

  return { success: true };
};

const removeParticipant = async (sessionId, creatorId, participantUserId) => {

const removeParticipant = async (sessionId, creatorId, participantUserId) => {
  // Creator কিনা check
  const sessionRes = await rideDb.query(
    `SELECT created_by FROM company_sharing_sessions WHERE session_id = $1`,
    [sessionId]
  );
  if (sessionRes.rowCount === 0) throw new Error('Session not found.');
  if (String(sessionRes.rows[0].created_by) !== String(creatorId)) {
    throw new Error('Only the creator can remove participants.');
  }

  // Participant আছে কিনা check
  const partRes = await rideDb.query(
    `SELECT id FROM company_participants WHERE session_id = $1 AND user_id = $2`,
    [sessionId, participantUserId]
  );
  if (partRes.rowCount === 0) throw new Error('Participant not found.');

  // Remove
  await rideDb.query(
    `DELETE FROM company_participants WHERE session_id = $1 AND user_id = $2`,
    [sessionId, participantUserId]
  );

  // Seat ফিরিয়ে দাও
  await rideDb.query(
    `UPDATE company_sharing_sessions SET booked_seats = booked_seats - 1 WHERE session_id = $1`,
    [sessionId]
  );

  // Removed user কে notification
  await createNotification({
    userId: participantUserId,
    title: 'Removed from CoRide',
    message: 'You have been removed from a CoRide session by the creator.',
    type: 'co_ride',
    isImportant: true,
    targetRole: 'passenger',
    relatedId: String(sessionId),
  });

  return { success: true };
};

const getSessionWithParticipants = async (sessionId, userId) => {
  const sessionRes = await rideDb.query(
    `SELECT css.*, u.first_name, u.last_name, u.phone
     FROM company_sharing_sessions css
     JOIN users u ON css.created_by = u.user_id
     WHERE css.session_id = $1`,
    [sessionId]
  );
  if (sessionRes.rowCount === 0) throw new Error('Session not found.');

  const session = sessionRes.rows[0];

  const participantsRes = await rideDb.query(
    `SELECT cp.user_id, cp.id as participant_id,
            u.first_name, u.last_name, u.profile_picture
     FROM company_participants cp
     JOIN users u ON cp.user_id = u.user_id
     WHERE cp.session_id = $1 AND cp.confirmed = TRUE`,
    [sessionId]
  );

  return {
    ...session,
    confirmed_participants: participantsRes.rows,
    is_creator: String(session.created_by) === String(userId),
    is_active: session.status === 'Active',
    can_track_live: session.status === 'Active' && session.is_started === true,
  };
};


// ── Passenger search: gender/corridor/frequent-partner সব মিলিয়ে matching sessions ──
const searchSessions = async (userId, { pickupLat, pickupLng, destLat, destLng }) => {
  const userRes = await rideDb.query(
    `SELECT gender, university_email FROM users WHERE user_id = $1`,
    [userId]
  );
  const user = userRes.rows[0];
  if (!user) throw new Error('User not found.');

  const sessionsRes = await rideDb.query(
    `SELECT css.*, u.first_name, u.last_name, u.university_email,
            (css.total_seats - css.booked_seats) AS available_seats
     FROM company_sharing_sessions css
     JOIN users u ON css.created_by = u.user_id
     WHERE css.status = 'Active'
       AND css.created_by != $1
       AND (css.total_seats - css.booked_seats) > 0
     ORDER BY css.created_at DESC`,
    [userId]
  );

  const ranked = await coRideRecommendationService.searchMatchingSessions({
    userId,
    userGender: user.gender,
    userEmail: user.university_email,
    pickupLat, pickupLng, destLat, destLng,
    sessions: sessionsRes.rows,
  });

  const activeCommitment = await activeRideGuardService.getActiveCommitment(userId);

  return ranked.map((s) => ({
    ...s,
    bookable: !activeCommitment,
    hasActiveRide: !!activeCommitment,
  }));
};

module.exports = {
  createSession,
  getSessionById,
  getMyActiveSession,
  joinSession,
  cancelSession,
  startSession,
  updateLiveLocation,
  getLiveLocation,
  listSessions: getMyActiveSession,
  searchSessions,
  sendCompanyChatMessage,
  fetchCompanyChatMessages,
  markCompanyChatAsRead,
  removeParticipant,
  getSessionWithParticipants,
  leaveSession,
};
