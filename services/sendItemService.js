const rideDb = require('../config/rideDb');
const {
  calculateDeliveryFee,
  canCancelSendItem,
  canAcceptSendItem,
  canPickupSendItem,
  canDeliverSendItem,
  validateReceiverEmailInput,
} = require('../utils/sendItemHelpers');

const getUserBasicInfo = async (userId) => {
  const result = await rideDb.query(
    `SELECT user_id, first_name, last_name, university_email, phone
     FROM users
     WHERE user_id = $1
     LIMIT 1`,
    [userId]
  );

  if (result.rowCount === 0) {
    throw new Error('User not found.');
  }

  return result.rows[0];
};

const validateReceiver = async (receiverEmail) => {
  const normalizedEmail = validateReceiverEmailInput(receiverEmail);

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
    delivery_fee,
  } = payload;

  if (
    !receiver_email ||
    !item_type ||
    !item_weight ||
    !sender_name ||
    !sender_phone ||
    !pickup_location ||
    !destination_location
  ) {
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
      sender_id,
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
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NULL, NULL, $10, 'pending')
    RETURNING *`,
    [
      userId,
      finalReceiverId,
      finalReceiverEmail,
      item_type,
      item_weight || null,
      sender_name,
      sender_phone,
      pickup_location,
      destination_location,
      finalDeliveryFee,
    ]
  );

  return result.rows[0];
};

const getAvailableSendItemRequests = async () => {
  const result = await rideDb.query(
    `SELECT
        s_id,
        item_type,
        item_weight,
        pickup_location,
        drop_location,
        delivery_fee,
        status,
        created_at
     FROM send_items
     WHERE LOWER(status) = 'pending'
       AND rider_id IS NULL
     ORDER BY created_at DESC`
  );

  return result.rows;
};

const getMySentItems = async (userId) => {
  const result = await rideDb.query(
    `SELECT
        s.s_id,
        s.receiver_id,
        s.receiver_email,
        s.item_type,
        s.item_weight,
        s.sender_name,
        s.sender_phone,
        s.pickup_location,
        s.drop_location,
        s.rider_id,
        s.rider_phone,
        s.delivery_fee,
        LOWER(s.status) AS status,
        s.created_at,
        u.first_name AS rider_first_name,
        u.last_name AS rider_last_name,
        u.phone AS rider_user_phone
     FROM send_items s
     LEFT JOIN users u ON s.rider_id = u.user_id
     WHERE s.sender_id = $1
     ORDER BY s.created_at DESC`,
    [userId]
  );

  return result.rows.map((item) => ({
    ...item,
    rider_name: item.rider_id
      ? `${item.rider_first_name || ''} ${item.rider_last_name || ''}`.trim() || 'Rider'
      : null,
    rider_phone: item.rider_phone || item.rider_user_phone || null,
  }));
};

const getMyRiderSendItems = async (userId) => {
  const result = await rideDb.query(
    `SELECT
        s_id,
        sender_id,
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
        LOWER(status) AS status,
        created_at
     FROM send_items
     WHERE rider_id = $1
     ORDER BY created_at DESC`,
    [userId]
  );

  return result.rows;
};

const getSenderItemDetails = async (sId, userId) => {
  const result = await rideDb.query(
    `SELECT
        s.*,
        u.first_name AS rider_first_name,
        u.last_name AS rider_last_name,
        u.phone AS rider_user_phone,
        u.university_email AS rider_email
     FROM send_items s
     LEFT JOIN users u ON s.rider_id = u.user_id
     WHERE s.s_id = $1
       AND s.sender_id = $2
     LIMIT 1`,
    [sId, userId]
  );

  if (result.rowCount === 0) {
    throw new Error('Send item request not found.');
  }

  const item = result.rows[0];

  return {
    ...item,
    status: String(item.status || '').toLowerCase(),
    rider_name: item.rider_id
      ? `${item.rider_first_name || ''} ${item.rider_last_name || ''}`.trim() || 'Rider'
      : null,
    rider_phone: item.rider_phone || item.rider_user_phone || null,
    rider_email: item.rider_email || null,
  };
};

const getRiderItemDetails = async (sId, riderId) => {
  const result = await rideDb.query(
    `SELECT *
     FROM send_items
     WHERE s_id = $1
       AND rider_id = $2
     LIMIT 1`,
    [sId, riderId]
  );

  if (result.rowCount === 0) {
    throw new Error('Send item request not found.');
  }

  const item = result.rows[0];
  const normalizedStatus = String(item.status || '').toLowerCase();

  const baseData = {
    s_id: item.s_id,
    item_type: item.item_type,
    item_weight: item.item_weight,
    pickup_location: item.pickup_location,
    drop_location: item.drop_location,
    delivery_fee: item.delivery_fee,
    status: normalizedStatus,
    sender_name: item.sender_name,
    sender_phone: item.sender_phone,
  };

  if (normalizedStatus === 'picked_up' || normalizedStatus === 'delivered') {
    return {
      ...baseData,
      receiver_id: item.receiver_id,
      receiver_email: item.receiver_email,
    };
  }

  return baseData;
};

const acceptItemRequest = async (sId, riderId) => {
  const existing = await rideDb.query(
    `SELECT *
     FROM send_items
     WHERE s_id = $1
     LIMIT 1`,
    [sId]
  );

  if (existing.rowCount === 0) {
    throw new Error('Send item request not found.');
  }

  const item = existing.rows[0];

  if (!canAcceptSendItem(item.status)) {
    throw new Error('Only pending requests can be accepted.');
  }

  if (item.rider_id) {
    throw new Error('This request is already accepted by another rider.');
  }

  const rider = await getUserBasicInfo(riderId);

  const updated = await rideDb.query(
    `UPDATE send_items
     SET rider_id = $1,
         rider_phone = $2,
         status = 'accepted'
     WHERE s_id = $3
     RETURNING *`,
    [riderId, rider.phone || null, sId]
  );

  const acceptedItem = updated.rows[0];

  return {
    s_id: acceptedItem.s_id,
    status: 'accepted',
    sender_name: acceptedItem.sender_name,
    sender_phone: acceptedItem.sender_phone,
    pickup_location: acceptedItem.pickup_location,
    item_type: acceptedItem.item_type,
    item_weight: acceptedItem.item_weight,
    delivery_fee: acceptedItem.delivery_fee,
    rider_phone: acceptedItem.rider_phone,
  };
};

const pickupItemRequest = async (sId, riderId) => {
  const existing = await rideDb.query(
    `SELECT *
     FROM send_items
     WHERE s_id = $1
       AND rider_id = $2
     LIMIT 1`,
    [sId, riderId]
  );

  if (existing.rowCount === 0) {
    throw new Error('Send item request not found or unauthorized.');
  }

  const item = existing.rows[0];

  if (!canPickupSendItem(item.status)) {
    throw new Error('Only accepted requests can be marked as picked up.');
  }

  const updated = await rideDb.query(
    `UPDATE send_items
     SET status = 'picked_up'
     WHERE s_id = $1
       AND rider_id = $2
     RETURNING *`,
    [sId, riderId]
  );

  const pickedItem = updated.rows[0];

  return {
    s_id: pickedItem.s_id,
    status: 'picked_up',
    receiver_id: pickedItem.receiver_id,
    receiver_email: pickedItem.receiver_email,
    drop_location: pickedItem.drop_location,
    item_type: pickedItem.item_type,
    item_weight: pickedItem.item_weight,
  };
};

const deliverItemRequest = async (sId, riderId) => {
  const existing = await rideDb.query(
    `SELECT *
     FROM send_items
     WHERE s_id = $1
       AND rider_id = $2
     LIMIT 1`,
    [sId, riderId]
  );

  if (existing.rowCount === 0) {
    throw new Error('Send item request not found or unauthorized.');
  }

  const item = existing.rows[0];

  if (!canDeliverSendItem(item.status)) {
    throw new Error('Only picked up requests can be marked as delivered.');
  }

  const updated = await rideDb.query(
    `UPDATE send_items
     SET status = 'delivered'
     WHERE s_id = $1
       AND rider_id = $2
     RETURNING *`,
    [sId, riderId]
  );

  return updated.rows[0];
};

const cancelItemRequest = async (sId, userId) => {
  const existing = await rideDb.query(
    `SELECT *
     FROM send_items
     WHERE s_id = $1
     LIMIT 1`,
    [sId]
  );

  if (existing.rowCount === 0) {
    throw new Error('Send item request not found.');
  }

  const item = existing.rows[0];
  const isSender = String(item.sender_id) === String(userId);
  const isAssignedRider = item.rider_id && String(item.rider_id) === String(userId);

  if (!isSender && !isAssignedRider) {
    throw new Error('Unauthorized to cancel this request.');
  }

  if (!canCancelSendItem(item.status)) {
    throw new Error('This request cannot be cancelled now.');
  }

  const updated = await rideDb.query(
    `UPDATE send_items
     SET status = 'cancelled'
     WHERE s_id = $1
     RETURNING *`,
    [sId]
  );

  return updated.rows[0];
};

module.exports = {
  validateReceiver,
  createSendItemRequest,
  getAvailableSendItemRequests,
  getMySentItems,
  getMyRiderSendItems,
  getSenderItemDetails,
  getRiderItemDetails,
  acceptItemRequest,
  pickupItemRequest,
  deliverItemRequest,
  cancelItemRequest,
};