const cron = require('node-cron');
const rideDb = require('../config/rideDb');
const { createNotification } = require('./notificationService');
const { emitCoRideStatusChange } = require('../utils/coRideEmitter');

const REMINDER_GAP_MINUTES = 5;
const AUTO_CLOSE_GAP_MINUTES = 10;
const HOURS_BEFORE_FIRST_REMINDER = 2;

const parseScheduledAt = (tripDate, tripTime) => {
  if (!tripDate) return null;
  const dateObj = new Date(tripDate);
  if (Number.isNaN(dateObj.getTime())) return null;
  const dateStr = dateObj.toISOString().split('T')[0];
  if (!tripTime) return new Date(`${dateStr}T00:00:00`);
  const match = tripTime.trim().match(/^(\d{1,2}):(\d{2})\s*(AM|PM)?$/i);
  if (!match) return new Date(`${dateStr}T00:00:00`);
  let hour = parseInt(match[1], 10);
  const minute = parseInt(match[2], 10);
  const period = match[3]?.toUpperCase();
  if (period === 'PM' && hour !== 12) hour += 12;
  if (period === 'AM' && hour === 12) hour = 0;
  return new Date(`${dateStr}T${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}:00`);
};

const sendReminder = async (session, reminderNumber) => {
  const column = reminderNumber === 1 ? 'reminder_1_sent_at' : 'reminder_2_sent_at';
  await rideDb.query(
    `UPDATE company_sharing_sessions SET ${column} = CURRENT_TIMESTAMP WHERE session_id = $1`,
    [session.session_id]
  );
  await createNotification({
    userId: session.created_by,
    title: 'CoRide has not started yet.',
    message: `Your CoRide (${session.start_location} → ${session.destination}) has passed its scheduled start time but has not started yet. Please start the ride or cancel it.`,
    type: 'co_ride',
    isImportant: true,
    targetRole: 'general',
    relatedId: String(session.session_id),
  });
};

const autoCloseSession = async (session) => {
  await rideDb.query(
    `UPDATE company_sharing_sessions
     SET status = 'Cancelled', closed_at = CURRENT_TIMESTAMP, closed_reason = 'auto_expired'
     WHERE session_id = $1`,
    [session.session_id]
  );

  await createNotification({
    userId: session.created_by,
    title: 'Your CoRide has been automatically canceled.',
    message: 'Your CoRide was automatically closed because it was not started within 2 hours after the scheduled start time. Please create a new CoRide to begin your journey.',
    type: 'co_ride',
    isImportant: true,
    targetRole: 'general',
    relatedId: String(session.session_id),
  });

  const participants = await rideDb.query(
    `SELECT user_id FROM company_participants WHERE session_id = $1 AND confirmed = TRUE`,
    [session.session_id]
  );
  for (const p of participants.rows) {
    await createNotification({
      userId: p.user_id,
      title: 'Your CoRide has been canceled.',
      message: 'This CoRide has been automatically canceled because the host did not start the ride at the scheduled time.',
      type: 'co_ride',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: String(session.session_id),
    });
  }

  emitCoRideStatusChange(session.session_id, { status: 'Cancelled', reason: 'auto_expired' });
};

const runExpiryCheck = async () => {
  const res = await rideDb.query(
    `SELECT * FROM company_sharing_sessions
     WHERE status = 'Active' AND (is_started IS NULL OR is_started = FALSE)`
  );
  const now = new Date();

  for (const session of res.rows) {
    const scheduledAt = parseScheduledAt(session.trip_date, session.trip_time);
    if (!scheduledAt) continue;
    const minutesPastSchedule = (now - scheduledAt) / 60000;
    if (minutesPastSchedule < HOURS_BEFORE_FIRST_REMINDER * 60) continue;

    if (!session.reminder_1_sent_at) { await sendReminder(session, 1); continue; }

    if (!session.reminder_2_sent_at) {
      const minutesSinceReminder1 = (now - new Date(session.reminder_1_sent_at)) / 60000;
      if (minutesSinceReminder1 >= REMINDER_GAP_MINUTES) await sendReminder(session, 2);
      continue;
    }

    const minutesSinceReminder2 = (now - new Date(session.reminder_2_sent_at)) / 60000;
    if (minutesSinceReminder2 >= AUTO_CLOSE_GAP_MINUTES) await autoCloseSession(session);
  }
};

const startCron = () => {
  cron.schedule('*/2 * * * *', () => {
    runExpiryCheck().catch((err) => console.error('CoRide expiry cron error:', err.message));
  });
  console.log('CoRide expiry cron scheduled (every 2 minutes).');
};

module.exports = { startCron, runExpiryCheck };
