const rideDb = require('../config/rideDb');

const createSendItemRequest = async (userId, payload) => {
  const {
    receiver_id,
    receiver_email,
    item_type,
    item_weight,
    sender_name,
    sender_phone,
    rider_id,
    rider_phone,
    delivery_fee,
  } = payload;

  const result = await rideDb.query(
    `INSERT INTO send_items (
      receiver_id, receiver_email, item_type, item_weight, sender_name,
      sender_phone, rider_id, rider_phone, delivery_fee, status
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'Pending')
    RETURNING *`,
    [
      receiver_id || userId,
      receiver_email,
      item_type,
      item_weight,
      sender_name,
      sender_phone,
      rider_id,
      rider_phone,
      delivery_fee,
    ]
  );

  return result.rows[0];
};

const listSendItemRequests = async (userId) => {
  const result = await rideDb.query(
    `SELECT *
     FROM send_items
     WHERE receiver_id = $1 OR rider_id = $1
     ORDER BY created_at DESC`,
    [userId]
  );

  return result.rows;
};

const updateSendItemStatus = async (s_id, userId, status) => {
  const result = await rideDb.query(
    `UPDATE send_items
     SET status = $1
     WHERE s_id = $2 AND (receiver_id = $3 OR rider_id = $3)
     RETURNING *`,
    [status, s_id, userId]
  );

  if (result.rowCount === 0) {
    throw new Error('Send item request not found or unauthorized.');
  }

  return result.rows[0];
};

module.exports = {
  createSendItemRequest,
  listSendItemRequests,
  updateSendItemStatus,
};