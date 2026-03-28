const rideDb = require('../config/rideDb');
const offerService = require('./offerService');

const getPassengerSummary = async (userId) => {
  // 1. Get user
  const userResult = await rideDb.query(
    `SELECT user_id, university_email, first_name, last_name,
            account_status, rider
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (userResult.rowCount === 0) {
    throw new Error('User not found.');
  }

  const user = userResult.rows[0];

  if (user.account_status !== 'Active') {
    throw new Error('Your account is not active.');
  }

  // 2. Offers
  const offers = await offerService.getActiveOffers();
  const offerCount = offers.length;

  // 3. Notifications (using offers)
  const notifications = offers.map((offer) => ({
    type: 'offer',
    title: 'New offer available',
    message: `${offer.offer_name} is now active`,
    offer_id: offer.offer_id,
  }));

  return {
    user,
    offerCount,
    notificationCount: notifications.length,
  };
};

const getNotifications = async () => {
  const offers = await offerService.getActiveOffers();

  return offers.map((offer) => ({
    type: 'offer',
    title: 'New offer available',
    message: `${offer.offer_name} is now active`,
    offer_id: offer.offer_id,
  }));
};

module.exports = {
  getPassengerSummary,
  getNotifications,
};