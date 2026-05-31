const rideDb = require('../config/rideDb');
const {
  createNotification,
  createBulkNotifications,
} = require('./notificationService');
const { isRouteMatch } = require('../utils/routeMatcher');

// Route-match করা রাইডারদের খুঁজে বের করো
const getMatchingRiderIds = async (item) => {
  const activeRidesRes = await rideDb.query(
    `SELECT
        ride_id,
        rider_id,
        pickup_latitude,
        pickup_longitude,
        destination_latitude,
        destination_longitude,
        start_latitude,
        start_longitude
     FROM rides
     WHERE status IN ('active', 'assigned', 'ongoing')
     ORDER BY created_at DESC`
  );

  const matchingRiderIds = [];

  for (const ride of activeRidesRes.rows) {
    const riderStartLat = Number(ride.start_latitude ?? ride.pickup_latitude ?? 0);
    const riderStartLng = Number(ride.start_longitude ?? ride.pickup_longitude ?? 0);
    const riderDestLat = Number(ride.destination_latitude ?? 0);
    const riderDestLng = Number(ride.destination_longitude ?? 0);

    const matched = isRouteMatch({
      riderStartLat,
      riderStartLng,
      riderDestLat,
      riderDestLng,
      reqPickupLat: Number(item.pickup_lat),
      reqPickupLng: Number(item.pickup_lng),
      reqDestLat: Number(item.destination_lat),
      reqDestLng: Number(item.destination_lng),
    });

    if (matched && ride.rider_id) {
      matchingRiderIds.push(ride.rider_id);
    }
  }

  return [...new Set(matchingRiderIds)]; // duplicate বাদ দাও
};

// শুধু matching রাইডারদের socket emit করো
const emitToMatchingRiders = async (io, item, eventName, payload) => {
  if (!io) return;

  const matchingRiderIds = await getMatchingRiderIds(item);

  for (const riderId of matchingRiderIds) {
    io.to(`rider_${riderId}`).emit(eventName, payload);
    io.to(`user_${riderId}`).emit(eventName, payload);
  }
};

// ── SEND ITEM CREATED ──
// শুধু sender কে notify করো + matching রাইডারদের socket emit
const notifySendItemCreated = async (item, io) => {
  // Sender কে notify করো
  await createNotification({
    userId: item.sender_id,
    title: 'Send Item Request Submitted',
    message: `Your ${item.item_type} delivery request has been created successfully. We are finding a rider for you.`,
    type: 'sendItem',
    isImportant: false,
    targetRole: 'passenger',
    relatedId: item.s_id,
  });

  // Matching রাইডারদের socket দিয়ে জানাও (notification নয়, শুধু real-time event)
  if (io) {
    await emitToMatchingRiders(io, item, 'send_item:new_request', {
      s_id: item.s_id,
      item_type: item.item_type,
      item_weight: item.item_weight,
      pickup_location: item.pickup_location,
      drop_location: item.drop_location,
      delivery_fee: item.delivery_fee,
      sender_name: item.sender_name,
      sender_phone: item.sender_phone,
    });
  }
};

// ── SEND ITEM ACCEPTED ──
// শুধু sender কে notify করো
const notifySendItemAccepted = async (item) => {
  await createNotification({
    userId: item.sender_id,
    title: 'Rider Found for Your Delivery',
    message: `${item.rider_name || 'A rider'} has accepted your ${item.item_type} delivery request and will pick it up soon.`,
    type: 'sendItem',
    isImportant: true,
    targetRole: 'passenger',
    relatedId: item.s_id,
  });
};

// ── SEND ITEM PICKED UP ──
// শুধু sender কে notify করো
const notifySendItemPickedUp = async (item) => {
  await createNotification({
    userId: item.sender_id,
    title: 'Your Item Has Been Picked Up',
    message: `Your ${item.item_type} has been picked up by the rider and is now on the way to the receiver.`,
    type: 'sendItem',
    isImportant: true,
    targetRole: 'passenger',
    relatedId: item.s_id,
  });
};

// ── SEND ITEM DELIVERED ──
// শুধু sender কে notify করো
const notifySendItemDelivered = async (item) => {
  await createNotification({
    userId: item.sender_id,
    title: 'Item Delivered Successfully',
    message: `Your ${item.item_type} has been successfully delivered to the receiver.`,
    type: 'sendItem',
    isImportant: true,
    targetRole: 'passenger',
    relatedId: item.s_id,
  });
};

// ── SEND ITEM CANCELLED ──
const notifySendItemCancelled = async (item, cancelledByUserId = null) => {
  const payloads = [];

  if (item.sender_id && String(item.sender_id) !== String(cancelledByUserId)) {
    payloads.push({
      userId: item.sender_id,
      title: 'Send Item Cancelled',
      message: `The ${item.item_type} delivery request has been cancelled.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: item.s_id,
    });
  }

  if (item.rider_id && String(item.rider_id) !== String(cancelledByUserId)) {
    payloads.push({
      userId: item.rider_id,
      title: 'Send Item Job Cancelled',
      message: `The ${item.item_type} delivery request has been cancelled.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'rider',
      relatedId: item.s_id,
    });
  }

  if (payloads.length > 0) {
    await createBulkNotifications(payloads);
  }
};

module.exports = {
  notifySendItemCreated,
  notifySendItemAccepted,
  notifySendItemPickedUp,
  notifySendItemDelivered,
  notifySendItemCancelled,
  getMatchingRiderIds,
};
