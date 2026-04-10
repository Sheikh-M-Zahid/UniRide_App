const rideDb = require('../config/rideDb');

const getFaqs = async () => {
  const query = `
    SELECT
      faq_id,
      question,
      answer,
      display_order
    FROM help_faqs
    WHERE is_active = TRUE
    ORDER BY display_order ASC, created_at ASC
  `;

  const result = await rideDb.query(query);

  return result.rows;
};

module.exports = {
  getFaqs,
};