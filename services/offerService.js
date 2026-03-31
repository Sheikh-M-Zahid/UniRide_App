const rideDb = require('../config/rideDb');

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
    VALUES ($1, $2, $3, $4, $5, $6, UPPER($7), $8)
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
      eligible_user,
      start_date,
      end_date,
      promo_code,
      conditions,
    ]
  );

  return result.rows[0];
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
};