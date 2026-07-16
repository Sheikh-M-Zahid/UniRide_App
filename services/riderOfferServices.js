const rideDb = require('../config/rideDb');
const { sortOffersByUcb, logOffersShown } = require('../utils/banditUtils');

/**
 * Rider এর জন্য সব offer আনে।
 * eligible_user = 'rider' অথবা 'both' হলে দেখাবে।
 * Active + Expired দুটোই return করে।
 * Frontend এ active/expired badge দিয়ে আলাদা করা হয়।
 */
const getOffersForRider = async (userId = null) => {
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
     WHERE eligible_user IN ('rider', 'both')
     ORDER BY
        CASE WHEN end_date >= CURRENT_DATE THEN 0 ELSE 1 END,
        end_date DESC,
        created_at DESC`
  );

  // rider আলাদা arm_type ('promo_rider') — passenger থেকে আলাদা audience
  const sorted = await sortOffersByUcb(result.rows, 'promo_rider');

  logOffersShown(userId, sorted, 'promo_rider').catch((err) =>
    console.error('shown logging failed:', err.message)
  );

  return sorted;
};

module.exports = {
  getOffersForRider,
};
