const rideDb = require('../config/rideDb');
const { isValidUniversityEmail } = require('../utils/validators');

const calculateDeliveryFee = (weight) => {
  const w = Number(weight);

  if (!w || w <= 0) return 40;
  if (w <= 1) return 40;
  if (w <= 3) return 60;
  if (w <= 5) return 80;
  return 100;
};

const validateReceiver = async (receiverEmail) => {
  if (!receiverEmail || !String(receiverEmail).trim()) {
    throw new Error('Receiver email is required.');
  }

  const normalizedEmail = String(receiverEmail).trim().toLowerCase();

  if (!isValidUniversityEmail(normalizedEmail)) {
    throw new Error('Enter a valid university email.');
  }

  const result = await rideDb.query(
    `SELECT user_id, first_name, last_name, university_email
     FROM users
     WHERE university_email = $1
     LIMIT 1`,
    [normalizedEmail]
  );

  if (result.rowCount === 0) {
    throw new Error('Receiver not found.');
  }

  const user = result.rows[0];
  const fullName = `${user.first_name || ''} ${user.last_name || ''}`.trim();

  return {
    receiver_id: user.user_id,
    receiver_email: user.university_email,
    name: fullName || 'User',
  };
};

const createSendItemRequest = async (userId, payload) => {
  const {
    receiver_id,
    receiver_email,
    item_type,
    item_weight,
    sender_name,
    sender_phone,
    pickup_location,
    destination_location,
    rider_id,
    rider_phone,
    delivery_fee,
  } = payload;

  if (!receiver_email || !item_type || !sender_name || !sender_phone) {
    throw new Error('Required fields are missing.');
  }

  const validatedReceiver = await validateReceiver(receiver_email);

  const finalReceiverId = receiver_id || validatedReceiver.receiver_id;
  const finalReceiverEmail = validatedReceiver.receiver_email;
  const finalDeliveryFee =
    delivery_fee !== undefined && delivery_fee !== null
      ? Number(delivery_fee)
      : calculateDeliveryFee(item_weight);

  const result = await rideDb.query(
    `INSERT INTO send_items (
      receiver_id,
      receiver_email,
      item_type,
      item_weight,
      sender_name,
      sender_phone,
      pickup_location,
      drop_location,
      rider_id,
      rider_phone,
      delivery_fee,
      status
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'pending')
    RETURNING *`,
    [
      finalReceiverId,
      finalReceiverEmail,
      item_type,
      item_weight || null,
      sender_name,
      sender_phone,
      pickup_location || null,
      destination_location || null,
      rider_id || null,
      rider_phone || null,
      finalDeliveryFee,
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

const updateSendItemStatus = async (sId, userId, status) => {
  const result = await rideDb.query(
    `UPDATE send_items
     SET status = $1
     WHERE s_id = $2
       AND (receiver_id = $3 OR rider_id = $3)
     RETURNING *`,
    [status, sId, userId]
  );

  if (result.rowCount === 0) {
    throw new Error('Send item request not found or unauthorized.');
  }

  return result.rows[0];
};

module.exports = {
  validateReceiver,
  createSendItemRequest,
  listSendItemRequests,
  updateSendItemStatus,
};
