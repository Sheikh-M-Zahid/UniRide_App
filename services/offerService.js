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

const applyOffer = async (promoCode) => {
  if (!promoCode || !String(promoCode).trim()) {
    throw new Error('Promo code is required.');
  }

  const code = String(promoCode).trim().toUpperCase();

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
        end_date
     FROM offers
     WHERE UPPER(promo_code) = $1
       AND start_date <= CURRENT_DATE
       AND end_date >= CURRENT_DATE`,
    [code]
  );

  if (result.rowCount === 0) {
    throw new Error('Invalid or expired promo code.');
  }

  return result.rows[0];
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
    reward_percentage,
    eligible_user,
    start_date,
    end_date,
    promo_code,
    conditions,
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
      reward_percentage,
      eligible_user,
      start_date,
      end_date,
      promo_code,
      conditions
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING
      offer_id,
      offer_name,
      offer_type,
      reward_percentage,
      eligible_user,
      promo_code,
      conditions,
      start_date,
      end_date,
      created_at`,
    [
      offer_name,
      offer_type,
      reward_percentage,
      normalizedEligibleUser,
      start_date,
      end_date,
      normalizedPromoCode,
      conditions,
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
