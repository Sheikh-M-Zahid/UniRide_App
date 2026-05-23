const rideDb = require('../config/rideDb');

const getServicesSummary = async () => {
  const result = await rideDb.query(
    `SELECT
        offer_name,
        offer_type,
        reward_percentage,
        conditions
     FROM offers
     WHERE end_date >= CURRENT_DATE
     ORDER BY reward_percentage DESC NULLS LAST
     LIMIT 1`
  );

  // No active offer
  if (result.rowCount === 0) {
    return {
      hasAdminOffer: false,
      offerTitle: '',
      offerSubtitle: '',
    };
  }

  const offer = result.rows[0];

  // Build subtitle dynamically
  let subtitle = '';

  if (offer.conditions && offer.conditions.length > 0) {
    subtitle = offer.conditions;
  } else if (offer.reward_percentage) {
    subtitle = `${offer.reward_percentage}% discount available`;
  } else if (offer.offer_type) {
    subtitle = `${offer.offer_type} special offer`;
  } else {
    subtitle = 'Limited time campus offer';
  }

  return {
    hasAdminOffer: true,
    offerTitle: offer.offer_name || 'Special Offer',
    offerSubtitle: subtitle,
  };
};

module.exports = {
  getServicesSummary,
};
