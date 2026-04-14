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

const submitHelpRequest = async ({ userId, message }) => {
  const cleanMessage = String(message || '').trim();

  if (!cleanMessage) {
    throw new Error('Message is required.');
  }

  if (cleanMessage.length < 5) {
    throw new Error('Message must be at least 5 characters.');
  }

  const userRes = await rideDb.query(
    `
    SELECT university_email
    FROM users
    WHERE user_id = $1
    LIMIT 1
    `,
    [userId]
  );

  if (!userRes.rows.length) {
    throw new Error('User not found.');
  }

  const userEmail = userRes.rows[0].university_email;

  const result = await rideDb.query(
    `
    INSERT INTO reports (
      user_id,
      user_email,
      comment,
      status,
      is_spam,
      created_at
    )
    VALUES ($1, $2, $3, 'unsolved', FALSE, CURRENT_TIMESTAMP)
    RETURNING report_id, user_id, user_email, comment, status, is_spam, created_at
    `,
    [userId, userEmail, cleanMessage]
  );

  return result.rows[0];
};

module.exports = {
  getFaqs,
  submitHelpRequest,
};
