const rideDb = require('../config/rideDb');
const { createBulkNotifications } = require('./notificationService');

const getActiveOffers = async () => {
  const result = await rideDb.query(
    `SELECT
        offer_id,
        offer_name,
        offer_type,
        reward_percentage,
        eligible_user,
        promo_code,
        conditions,
        start_date,
        end_date,
        created_at
     FROM offers
     WHERE start_date <= CURRENT_DATE
       AND end_date >= CURRENT_DATE
     ORDER BY created_at DESC`
  );

  return result.rows;
};

const applyOffer = async (promoCode, userId, currentFare = null, rideType = 'ride') => {
  if (!promoCode || !String(promoCode).trim()) {
    throw new Error('Promo code is required.');
  }

  const code = String(promoCode).trim().toUpperCase();

  // ১. অফার খোঁজো
  const result = await rideDb.query(
    `SELECT * FROM offers
     WHERE UPPER(promo_code) = $1
       AND start_date <= CURRENT_DATE
       AND end_date >= CURRENT_DATE`,
    [code]
  );

  if (result.rowCount === 0) {
    throw new Error('Invalid or expired promo code.');
  }

  const offer = result.rows[0];

  // ২. eligible_ride_type চেক
  if (offer.eligible_ride_type !== 'both' && offer.eligible_ride_type !== rideType) {
    throw new Error(`This offer is only valid for ${offer.eligible_ride_type}.`);
  }

  // ৩. condition চেক
  if (offer.condition_type === 'new_user_only') {
    const rideCountRes = await rideDb.query(
      `SELECT COUNT(*) FROM ride_participants WHERE passenger_id = $1`,
      [userId]
    );
    if (parseInt(rideCountRes.rows[0].count) > 0) {
      throw new Error('This offer is for new users only.');
    }
  }

  if (offer.condition_type === 'min_rides_per_month') {
    const rideCountRes = await rideDb.query(
      `SELECT COUNT(*) FROM ride_participants rp
       JOIN rides r ON rp.ride_id = r.ride_id
       WHERE rp.passenger_id = $1
         AND r.created_at >= date_trunc('month', CURRENT_DATE)`,
      [userId]
    );
    if (parseInt(rideCountRes.rows[0].count) < offer.condition_value) {
      throw new Error(
        `You need at least ${offer.condition_value} rides this month to use this offer.`
      );
    }
  }

  if (offer.condition_type === 'min_items_per_month') {
    const itemCountRes = await rideDb.query(
      `SELECT COUNT(*) FROM send_items
       WHERE sender_id = $1
         AND status = 'delivered'
         AND created_at >= date_trunc('month', CURRENT_DATE)`,
      [userId]
    );
    if (parseInt(itemCountRes.rows[0].count) < offer.condition_value) {
      throw new Error(
        `You need at least ${offer.condition_value} delivered items this month.`
      );
    }
  }

  if (offer.condition_type === 'min_fare_amount' && currentFare !== null) {
    if (currentFare < offer.condition_value) {
      throw new Error(`Minimum fare ৳${offer.condition_value} required for this offer.`);
    }
  }

  // ৪. usage_limit চেক
  if (offer.usage_limit_type === 'once_per_user') {
    const usedRes = await rideDb.query(
      `SELECT 1 FROM promo_usage WHERE user_id = $1 AND offer_id = $2 LIMIT 1`,
      [userId, offer.offer_id]
    );
    if (usedRes.rowCount > 0) {
      throw new Error('You have already used this offer.');
    }
  }

  if (offer.usage_limit_type === 'once_per_day') {
    const usedTodayRes = await rideDb.query(
      `SELECT 1 FROM promo_usage
       WHERE user_id = $1 AND offer_id = $2 AND used_date = CURRENT_DATE LIMIT 1`,
      [userId, offer.offer_id]
    );
    if (usedTodayRes.rowCount > 0) {
      throw new Error('You have already used this offer today.');
    }
  }

  // ৫. bonus offer — max_total_uses চেক
  if (offer.offer_category === 'bonus' && offer.max_total_uses !== null) {
    const totalUsedRes = await rideDb.query(
      `SELECT COUNT(*) FROM promo_usage WHERE offer_id = $1`,
      [offer.offer_id]
    );
    if (parseInt(totalUsedRes.rows[0].count) >= offer.max_total_uses) {
      throw new Error('This offer has reached its maximum redemption limit.');
    }
  }

  return offer;
};

const getActiveOffersCount = async () => {
  const result = await rideDb.query(
    `SELECT COUNT(*)::int AS count
     FROM offers
     WHERE start_date <= CURRENT_DATE
       AND end_date >= CURRENT_DATE`
  );

  return result.rows[0].count;
};

const getRecentOffers = async () => {
  const result = await rideDb.query(
    `SELECT
        offer_name,
        offer_type,
        reward_percentage,
        eligible_user,
        start_date,
        end_date,
        promo_code,
        conditions
     FROM offers
     WHERE end_date >= (CURRENT_DATE - INTERVAL '30 days')
     ORDER BY
        CASE WHEN end_date >= CURRENT_DATE THEN 0 ELSE 1 END,
        end_date ASC`
  );
  return result.rows;
};

const createOffer = async (payload) => {
  const {
    offer_name,
    offer_type,
    offer_category = 'normal',
    reward_percentage,
    eligible_user,
    start_date,
    end_date,
    promo_code,
    conditions,
    usage_limit_type = 'once_per_user',
    condition_type = 'none',
    condition_value = null,
    eligible_ride_type = 'both',
    max_total_uses = null,
  } = payload;

  const normalizedEligibleUser = String(eligible_user || '')
    .trim()
    .toLowerCase();

  const normalizedPromoCode = String(promo_code || '')
    .trim()
    .toUpperCase();

  const result = await rideDb.query(
      `INSERT INTO offers (
        offer_name,
        offer_type,
        offer_category,
        reward_percentage,
        eligible_user,
        start_date,
        end_date,
        promo_code,
        conditions,
        usage_limit_type,
        condition_type,
        condition_value,
        eligible_ride_type,
        max_total_uses
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
      RETURNING
        offer_id,
        offer_name,
        offer_type,
        offer_category,
        reward_percentage,
        eligible_user,
        promo_code,
        conditions,
        usage_limit_type,
        condition_type,
        condition_value,
        eligible_ride_type,
        max_total_uses,
        start_date,
        end_date,
        created_at`,
      [
        offer_name,
        offer_type,
        offer_category,
        reward_percentage,
        normalizedEligibleUser,
        start_date,
        end_date,
        normalizedPromoCode,
        conditions,
        usage_limit_type,
        condition_type,
        condition_value,
        eligible_ride_type,
        offer_category === 'bonus' ? max_total_uses : null,
      ]
    );

  const createdOffer = result.rows[0];

  let usersQuery = '';
  let usersParams = [];

  if (normalizedEligibleUser === 'both') {
    usersQuery = `
      SELECT user_id, selected_mode
      FROM users
      WHERE account_status = 'active'
        AND selected_mode IN ('passenger', 'rider')
    `;
  } else if (normalizedEligibleUser === 'passenger') {
    usersQuery = `
      SELECT user_id, selected_mode
      FROM users
      WHERE account_status = 'active'
        AND selected_mode = 'passenger'
    `;
  } else if (normalizedEligibleUser === 'rider') {
    usersQuery = `
      SELECT user_id, selected_mode
      FROM users
      WHERE account_status = 'active'
        AND selected_mode = 'rider'
    `;
  }

  if (usersQuery) {
    const usersResult = await rideDb.query(usersQuery, usersParams);

    if (usersResult.rows.length > 0) {
      const notifications = usersResult.rows.map((user) => ({
        userId: user.user_id,
        title: `New Offer: ${createdOffer.offer_name}`,
        message:
          `Offer Name: ${createdOffer.offer_name}\n` +
          `Promo Code: ${createdOffer.promo_code}\n` +
          `Discount: ${createdOffer.reward_percentage}%\n` +
          `Valid From: ${createdOffer.start_date}\n` +
          `Valid Until: ${createdOffer.end_date}\n` +
          `Condition: ${createdOffer.conditions || 'N/A'}\n` +
          `Note: This offer can be used only once.`,
        type: 'offer',
        isImportant: true,
        targetRole: normalizedEligibleUser === 'both'
          ? (user.selected_mode || 'general')
          : normalizedEligibleUser,
        relatedId: createdOffer.offer_id,
      }));

      await createBulkNotifications(notifications);
    }
  }

  return createdOffer;
};

const listOffers = async () => {
  const result = await rideDb.query(
    `SELECT
        offer_id,
        offer_name,
        offer_type,
        reward_percentage,
        eligible_user,
        promo_code,
        conditions,
        start_date,
        end_date,
        created_at
     FROM offers
     ORDER BY created_at DESC`
  );

  return result.rows;
};

module.exports = {
  getActiveOffers,
  applyOffer,
  getActiveOffersCount,
  createOffer,
  listOffers,
  getRecentOffers,
};
