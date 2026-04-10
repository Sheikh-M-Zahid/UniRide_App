const rideDb = require('../config/rideDb');

/* =========================
   HELPERS
========================= */
const normalizePromoCode = (promoCode) => String(promoCode).trim().toUpperCase();

const normalizeEligibleUser = (value) => {
  if (!value) return null;

  const normalized = String(value).trim().toLowerCase();

  if (normalized === 'rider') return 'Rider';
  if (normalized === 'passenger') return 'Passenger';
  if (normalized === 'both') return 'Both';

  return null;
};

const mapOffer = (row) => ({
  offerId: row.offer_id,
  name: row.offer_name,
  type: row.offer_type,
  reward: Number(row.reward_percentage || 0),
  target: row.eligible_user,
  start: row.start_date,
  end: row.end_date,
  promo: row.promo_code,
  condition: row.conditions,
  createdAt: row.created_at,
});

/* =========================
   ACTIVE OFFERS
========================= */
const getActiveOffers = async () => {
  const result = await rideDb.query(
    `SELECT
        offer_id,
        offer_name,
        offer_type,
        reward_percentage,
        eligible_user,
        promo_code,
        start_date,
        end_date,
        conditions,
        created_at
     FROM offers
     WHERE CURRENT_DATE BETWEEN start_date AND end_date
     ORDER BY created_at DESC`
  );

  return result.rows.map(mapOffer);
};

const getActiveOffersCount = async () => {
  const result = await rideDb.query(
    `SELECT COUNT(*)::int AS count
     FROM offers
     WHERE CURRENT_DATE BETWEEN start_date AND end_date`
  );

  return result.rows[0].count;
};

/* =========================
   VALIDATE PROMO
========================= */
const validatePromoCode = async (promoCode) => {
  const normalizedCode = normalizePromoCode(promoCode);

  const result = await rideDb.query(
    `SELECT
        offer_id,
        offer_name,
        offer_type,
        reward_percentage,
        eligible_user,
        promo_code,
        start_date,
        end_date,
        conditions,
        created_at
     FROM offers
     WHERE promo_code = $1
       AND CURRENT_DATE BETWEEN start_date AND end_date`,
    [normalizedCode]
  );

  if (result.rowCount === 0) {
    throw new Error('Invalid or expired promo code.');
  }

  return result.rows[0];
};

/* =========================
   PROMO USAGE CHECK
========================= */
const hasUserAlreadyUsedPromo = async ({ userId, promoCode }) => {
  const normalizedCode = normalizePromoCode(promoCode);

  const result = await rideDb.query(
    `SELECT 1
     FROM promo_usage
     WHERE user_id = $1
       AND promo_code = $2
     LIMIT 1`,
    [userId, normalizedCode]
  );

  return result.rows.length > 0;
};

/* =========================
   APPLY OFFER
   (Preview calculation only)
========================= */
const applyOffer = async ({ promoCode, fare, user }) => {
  const offer = await validatePromoCode(promoCode);

  const rewardPercentage = Number(offer.reward_percentage || 0);

  if (rewardPercentage <= 0 || rewardPercentage > 100) {
    throw new Error('Invalid reward percentage configured for this offer.');
  }

  const userRoleRaw =
    user?.selectedMode ||
    user?.role ||
    user?.userRole ||
    'Passenger';

  const userRoleNormalized = normalizeEligibleUser(userRoleRaw) || 'Passenger';

  if (
    offer.eligible_user !== 'Both' &&
    offer.eligible_user !== userRoleNormalized
  ) {
    throw new Error('Promo is not applicable for your role.');
  }

  const alreadyUsed = await hasUserAlreadyUsedPromo({
    userId: user.userId,
    promoCode: offer.promo_code,
  });

  if (alreadyUsed) {
    throw new Error('You have already used this promo code before.');
  }

  const originalFare = Number(fare);

  if (Number.isNaN(originalFare) || originalFare <= 0) {
    throw new Error('Fare must be a valid positive number.');
  }

  const discountAmount = Number(
    ((originalFare * rewardPercentage) / 100).toFixed(2)
  );

  const finalFare = Number(
    Math.max(originalFare - discountAmount, 0).toFixed(2)
  );

  return {
    promoCode: offer.promo_code,
    rewardPercentage,
    originalFare,
    discountAmount,
    finalFare,
    appliedDate: new Date().toISOString(),
    offerId: offer.offer_id,
  };
};

/* =========================
   CONFIRM PROMO USAGE
   (Call this after successful ride completion)
========================= */
const confirmPromoUsage = async ({ userId, offerId, promoCode }) => {
  const normalizedCode = normalizePromoCode(promoCode);

  try {
    const result = await rideDb.query(
      `INSERT INTO promo_usage (
         user_id,
         offer_id,
         promo_code
       )
       VALUES ($1, $2, $3)
       RETURNING *`,
      [userId, offerId, normalizedCode]
    );

    return result.rows[0];
  } catch (error) {
    if (error.code === '23505') {
      throw new Error('This promo code has already been used by this user.');
    }
    throw error;
  }
};

/* =========================
   CONFIRM PROMO USAGE WITH CLIENT
   (Use inside ride complete transaction)
========================= */
const confirmPromoUsageWithClient = async ({ client, userId, offerId, promoCode }) => {
  const normalizedCode = normalizePromoCode(promoCode);

  try {
    const result = await client.query(
      `INSERT INTO promo_usage (
         user_id,
         offer_id,
         promo_code
       )
       VALUES ($1, $2, $3)
       RETURNING *`,
      [userId, offerId, normalizedCode]
    );

    return result.rows[0];
  } catch (error) {
    if (error.code === '23505') {
      throw new Error('This promo code has already been used by this user.');
    }
    throw error;
  }
};

/* =========================
   CREATE OFFER
========================= */
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

  if (
    !offer_name ||
    !offer_type ||
    reward_percentage === undefined ||
    !eligible_user ||
    !start_date ||
    !end_date ||
    !promo_code ||
    !conditions
  ) {
    throw new Error('All offer fields are required.');
  }

  const reward = Number(reward_percentage);

  if (Number.isNaN(reward) || reward <= 0 || reward > 100) {
    throw new Error('Reward percentage must be a valid number between 1 and 100.');
  }

  const normalizedEligibleUser = normalizeEligibleUser(eligible_user);

  if (!normalizedEligibleUser) {
    throw new Error('Eligible user must be Rider, Passenger, or Both.');
  }

  const startDate = new Date(start_date);
  const endDate = new Date(end_date);

  if (Number.isNaN(startDate.getTime()) || Number.isNaN(endDate.getTime())) {
    throw new Error('Invalid start date or end date.');
  }

  if (endDate < startDate) {
    throw new Error('End date cannot be before start date.');
  }

  const normalizedPromoCode = normalizePromoCode(promo_code);

  const existing = await rideDb.query(
    `SELECT 1 FROM offers WHERE promo_code = $1`,
    [normalizedPromoCode]
  );

  if (existing.rows.length) {
    throw new Error('Promo code already exists.');
  }

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
      start_date,
      end_date,
      promo_code,
      conditions,
      created_at`,
    [
      offer_name.trim(),
      offer_type.trim(),
      reward,
      normalizedEligibleUser,
      start_date,
      end_date,
      normalizedPromoCode,
      conditions.trim(),
    ]
  );

  return mapOffer(result.rows[0]);
};

/* =========================
   LIST ALL OFFERS
========================= */
const listOffers = async () => {
  const result = await rideDb.query(
    `SELECT
        offer_id,
        offer_name,
        offer_type,
        reward_percentage,
        eligible_user,
        promo_code,
        start_date,
        end_date,
        conditions,
        created_at
     FROM offers
     ORDER BY created_at DESC`
  );

  return result.rows.map(mapOffer);
};

module.exports = {
  getActiveOffers,
  getActiveOffersCount,
  validatePromoCode,
  hasUserAlreadyUsedPromo,
  applyOffer,
  confirmPromoUsage,
  confirmPromoUsageWithClient,
  createOffer,
  listOffers,
};