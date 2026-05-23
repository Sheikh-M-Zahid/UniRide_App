const rideDb = require('../config/rideDb');

/**
 * Rider এর জন্য সব offer আনে।
 * eligible_user = 'rider' অথবা 'both' হলে দেখাবে।
 * Active + Expired দুটোই return করে।
 * Frontend এ active/expired badge দিয়ে আলাদা করা হয়।
 */
const getOffersForRider = async () => {
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

  return result.rows;
};

module.exports = {
  getOffersForRider,
};
