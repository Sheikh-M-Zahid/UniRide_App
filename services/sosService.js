const rideDb = require('../config/rideDb');
const crypto = require('crypto');

// ─────────────────────────────────────────────
// SOS token generate + store করা
// ─────────────────────────────────────────────
const generateSosToken = async ({ userId, sessionId, rideId, type }) => {
  const token = crypto.randomBytes(24).toString('hex');
  const expiresAt = new Date(Date.now() + 6 * 60 * 60 * 1000); // 6 ঘণ্টা valid

  await rideDb.query(
    `INSERT INTO sos_tokens (token, user_id, session_id, ride_id, type, expires_at)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (user_id, session_id) DO UPDATE
       SET token = EXCLUDED.token,
           expires_at = EXCLUDED.expires_at,
           created_at = CURRENT_TIMESTAMP`,
    [token, userId, sessionId || null, rideId || null, type, expiresAt]
  );

  return token;
};

// ─────────────────────────────────────────────
// CoRide SOS — Host চাপলে
// ─────────────────────────────────────────────
const triggerCoRideSosHost = async ({ userId, sessionId, baseUrl }) => {
  // Host এর তথ্য
  const hostRes = await rideDb.query(
    `SELECT u.first_name, u.last_name, u.emergency_phone
     FROM users u WHERE u.user_id = $1`,
    [userId]
  );
  if (!hostRes.rowCount) throw new Error('User not found');
  const host = hostRes.rows[0];

  if (!host.emergency_phone) throw new Error('No emergency contact found. Please add one in Security settings.');

  // Session তথ্য
  const sessionRes = await rideDb.query(
    `SELECT start_location, destination FROM company_sharing_sessions
     WHERE session_id = $1`,
    [sessionId]
  );
  if (!sessionRes.rowCount) throw new Error('Session not found');
  const session = sessionRes.rows[0];

  // Confirmed participants এর নাম
  const participantsRes = await rideDb.query(
    `SELECT u.first_name, u.last_name
     FROM company_participants cp
     JOIN users u ON cp.user_id = u.user_id
     WHERE cp.session_id = $1 AND cp.confirmed = TRUE`,
    [sessionId]
  );
  const participantNames = participantsRes.rows
    .map((p) => `${p.first_name} ${p.last_name}`)
    .join(', ') || 'None';

  // SOS token generate
  const token = await generateSosToken({ userId, sessionId, type: 'coride_host' });
  const trackingLink = `${baseUrl}/sos/track/${token}`;

  // SMS message
  const message =
    `🚨 SOS ALERT from ${host.first_name} ${host.last_name}!\n` +
    `Co-Riders: ${participantNames}\n` +
    `Destination: ${session.destination}\n` +
    `Live Location: ${trackingLink}`;

  await sendSms(host.emergency_phone, message);

  return { success: true, message: 'SOS sent to your emergency contact.' };
};

// ─────────────────────────────────────────────
// CoRide SOS — Participant চাপলে
// ─────────────────────────────────────────────
const triggerCoRideSosParticipant = async ({ userId, sessionId, baseUrl }) => {
  // Participant তথ্য
  const userRes = await rideDb.query(
    `SELECT u.first_name, u.last_name, u.emergency_phone
     FROM users u WHERE u.user_id = $1`,
    [userId]
  );
  if (!userRes.rowCount) throw new Error('User not found');
  const user = userRes.rows[0];

  if (!user.emergency_phone) throw new Error('No emergency contact found. Please add one in Security settings.');

  // Session + Host তথ্য
  const sessionRes = await rideDb.query(
    `SELECT css.start_location, css.destination,
            u.first_name AS host_first, u.last_name AS host_last
     FROM company_sharing_sessions css
     JOIN users u ON css.created_by = u.user_id
     WHERE css.session_id = $1`,
    [sessionId]
  );
  if (!sessionRes.rowCount) throw new Error('Session not found');
  const session = sessionRes.rows[0];

  // SOS token generate
  const token = await generateSosToken({ userId, sessionId, type: 'coride_participant' });
  const trackingLink = `${baseUrl}/sos/track/${token}`;

  // SMS message
  const message =
    `🚨 SOS ALERT from ${user.first_name} ${user.last_name}!\n` +
    `Co-Ride Host: ${session.host_first} ${session.host_last}\n` +
    `Destination: ${session.destination}\n` +
    `Live Location: ${trackingLink}`;

  await sendSms(user.emergency_phone, message);

  return { success: true, message: 'SOS sent to your emergency contact.' };
};

// ─────────────────────────────────────────────
// Regular Ride SOS — Rider চাপলে
// ─────────────────────────────────────────────
const triggerRiderSos = async ({ userId, rideId, baseUrl }) => {
  const riderRes = await rideDb.query(
    `SELECT u.first_name, u.last_name, u.emergency_phone
     FROM users u WHERE u.user_id = $1`,
    [userId]
  );
  if (!riderRes.rowCount) throw new Error('User not found');
  const rider = riderRes.rows[0];

  if (!rider.emergency_phone) throw new Error('No emergency contact found. Please add one in Security settings.');

  // Ride + Passenger তথ্য
  const rideRes = await rideDb.query(
    `SELECT r.destination, u.first_name AS pass_first, u.last_name AS pass_last
     FROM rides r
     JOIN ride_requests rr ON rr.ride_id = r.ride_id
     JOIN users u ON rr.passenger_id = u.user_id
     WHERE r.ride_id = $1 AND r.rider_id = $2
     LIMIT 1`,
    [rideId, userId]
  );

  const passengerName = rideRes.rowCount
    ? `${rideRes.rows[0].pass_first} ${rideRes.rows[0].pass_last}`
    : 'Unknown';
  const destination = rideRes.rowCount ? rideRes.rows[0].destination : 'Unknown';

  const token = await generateSosToken({ userId, rideId, type: 'rider' });
  const trackingLink = `${baseUrl}/sos/track/${token}`;

  const message =
    `🚨 SOS ALERT from Rider ${rider.first_name} ${rider.last_name}!\n` +
    `Passenger: ${passengerName}\n` +
    `Destination: ${destination}\n` +
    `Live Location: ${trackingLink}`;

  await sendSms(rider.emergency_phone, message);

  return { success: true, message: 'SOS sent to your emergency contact.' };
};

// ─────────────────────────────────────────────
// Regular Ride SOS — Passenger চাপলে
// ─────────────────────────────────────────────
const triggerPassengerSos = async ({ userId, rideId, baseUrl }) => {
  const passengerRes = await rideDb.query(
    `SELECT u.first_name, u.last_name, u.emergency_phone
     FROM users u WHERE u.user_id = $1`,
    [userId]
  );
  if (!passengerRes.rowCount) throw new Error('User not found');
  const passenger = passengerRes.rows[0];

  if (!passenger.emergency_phone) throw new Error('No emergency contact found. Please add one in Security settings.');

  // Ride + Rider + Vehicle তথ্য
  const rideRes = await rideDb.query(
    `SELECT r.destination,
            u.first_name AS rider_first, u.last_name AS rider_last,
            v.number_plate
     FROM ride_requests rr
     JOIN rides r ON rr.ride_id = r.ride_id
     JOIN users u ON r.rider_id = u.user_id
     LEFT JOIN vehicles v ON v.rider_id = r.rider_id AND v.is_active = TRUE
     WHERE rr.passenger_id = $1 AND rr.ride_id = $2
     LIMIT 1`,
    [userId, rideId]
  );

  const riderName = rideRes.rowCount
    ? `${rideRes.rows[0].rider_first} ${rideRes.rows[0].rider_last}`
    : 'Unknown';
  const destination = rideRes.rowCount ? rideRes.rows[0].destination : 'Unknown';
  const vehicleNumber = rideRes.rowCount
    ? (rideRes.rows[0].number_plate || 'N/A')
    : 'N/A';

  const token = await generateSosToken({ userId, rideId, type: 'passenger' });
  const trackingLink = `${baseUrl}/sos/track/${token}`;

  const message =
    `🚨 SOS ALERT from ${passenger.first_name} ${passenger.last_name}!\n` +
    `Rider: ${riderName}\n` +
    `Vehicle: ${vehicleNumber}\n` +
    `Destination: ${destination}\n` +
    `Live Location: ${trackingLink}`;

  await sendSms(passenger.emergency_phone, message);

  return { success: true, message: 'SOS sent to your emergency contact.' };
};

// ─────────────────────────────────────────────
// Token দিয়ে tracking info get করা (web link)
// ─────────────────────────────────────────────
const getSosTrackingInfo = async (token) => {
  const tokenRes = await rideDb.query(
    `SELECT st.*, u.first_name, u.last_name
     FROM sos_tokens st
     JOIN users u ON st.user_id = u.user_id
     WHERE st.token = $1 AND st.expires_at > CURRENT_TIMESTAMP`,
    [token]
  );

  if (!tokenRes.rowCount) throw new Error('Invalid or expired tracking link.');

  const row = tokenRes.rows[0];

  // Live location
  let lat = null;
  let lng = null;

  if (row.session_id) {
    const locRes = await rideDb.query(
      `SELECT current_lat, current_lng FROM company_sharing_sessions
       WHERE session_id = $1`,
      [row.session_id]
    );
    if (locRes.rowCount) {
      lat = locRes.rows[0].current_lat;
      lng = locRes.rows[0].current_lng;
    }
  }

  return {
    name: `${row.first_name} ${row.last_name}`,
    type: row.type,
    session_id: row.session_id,
    ride_id: row.ride_id,
    lat,
    lng,
    token: row.token,
  };
};

// ─────────────────────────────────────────────
// SMS sender (Twilio / local gateway)
// ─────────────────────────────────────────────
const sendSms = async (phone, message) => {
  // তোমার SMS gateway এখানে বসাও
  // Option 1: Twilio
  // const twilio = require('twilio')(process.env.TWILIO_SID, process.env.TWILIO_AUTH);
  // await twilio.messages.create({ body: message, from: process.env.TWILIO_FROM, to: phone });

  // Option 2: Bangladesh local gateway (e.g. SSL Wireless, Mimsms)
  // const axios = require('axios');
  // await axios.post(process.env.SMS_GATEWAY_URL, { phone, message, api_key: process.env.SMS_API_KEY });

  // এখন console log করছি — পরে replace করো
  console.log(`📱 SMS to ${phone}:\n${message}`);
};

module.exports = {
  triggerCoRideSosHost,
  triggerCoRideSosParticipant,
  triggerRiderSos,
  triggerPassengerSos,
  getSosTrackingInfo,
  generateSosToken,
};
