const rideDb = require('../config/rideDb');
const { createNotification } = require('./notificationService');

const rejectedRequestsByRider = new Map();

/* =========================
   HELPERS
========================= */
const mapDelivery = (row) => ({
  deliveryId: row.s_id,
  senderName: row.sender_name || '',
  senderPhone: row.sender_phone || '',
  receiverName: row.receiver_name || '',
  receiverPhone: row.receiver_phone || '',
  pickup: row.pickup_location || '',
  drop: row.drop_location || '',
  item: row.item_type || '',
  fee: Number(row.delivery_fee || 0),
  distance: Number(row.distance_km || 0),
  time: Number(row.estimated_minutes || 0),
  status: row.status || 'pending',
});

const getRejectedSet = (riderId) => {
  const key = String(riderId);

  if (!rejectedRequestsByRider.has(key)) {
    rejectedRequestsByRider.set(key, new Set());
  }

  return rejectedRequestsByRider.get(key);
};

const getRiderBasicInfo = async (riderId) => {
  const result = await rideDb.query(
    `
    SELECT user_id, first_name, last_name, phone, university_email
    FROM users
    WHERE user_id = $1
    LIMIT 1
  `,
    [riderId]
  );

  if (!result.rows.length) {
    throw new Error('Rider not found.');
  }

  return result.rows[0];
};

const getAdminIds = async () => {
  const result = await rideDb.query(
    `
    SELECT DISTINCT user_id
    FROM user_roles
    WHERE role = 'admin'
  `
  );

  return result.rows.map((row) => row.user_id).filter(Boolean);
};

const notifyAdmins = async ({ title, message, relatedId }) => {
  const adminIds = await getAdminIds();

  for (const adminId of adminIds) {
    await createNotification({
      userId: adminId,
      title,
      message,
      type: 'adminNotice',
      isImportant: true,
      targetRole: 'admin',
      relatedId,
    });
  }
};

const sendDeliveryAcceptedNotifications = async ({ delivery, rider }) => {
  const riderName =
    `${rider.first_name || ''} ${rider.last_name || ''}`.trim() || 'Rider';

  if (delivery.sender_id) {
    await createNotification({
      userId: delivery.sender_id,
      title: 'Delivery Request Accepted',
      message: `${riderName} accepted your send item delivery request.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: delivery.s_id,
    });
  }

  if (delivery.receiver_id) {
    await createNotification({
      userId: delivery.receiver_id,
      title: 'Incoming Delivery Accepted',
      message: `Your item delivery has been accepted by ${riderName}.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: delivery.s_id,
    });
  }

  await createNotification({
    userId: rider.user_id,
    title: 'Delivery Accepted',
    message: `You accepted the ${delivery.item_type} delivery request.`,
    type: 'sendItem',
    isImportant: false,
    targetRole: 'rider',
    relatedId: delivery.s_id,
  });

  await notifyAdmins({
    title: 'Delivery Request Accepted',
    message: `${riderName} accepted a send item delivery request.`,
    relatedId: delivery.s_id,
  });
};

const sendDeliveryDeliveredNotifications = async ({ delivery, rider }) => {
  const riderName =
    `${rider.first_name || ''} ${rider.last_name || ''}`.trim() || 'Rider';

  if (delivery.sender_id) {
    await createNotification({
      userId: delivery.sender_id,
      title: 'Delivery Completed',
      message: `Your ${delivery.item_type} has been delivered successfully.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: delivery.s_id,
    });
  }

  if (delivery.receiver_id) {
    await createNotification({
      userId: delivery.receiver_id,
      title: 'Item Received',
      message: `Your ${delivery.item_type} delivery has been completed by ${riderName}.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: delivery.s_id,
    });
  }

  await createNotification({
    userId: rider.user_id,
    title: 'Delivery Completed',
    message: `You marked the ${delivery.item_type} delivery as delivered.`,
    type: 'sendItem',
    isImportant: false,
    targetRole: 'rider',
    relatedId: delivery.s_id,
  });

  await notifyAdmins({
    title: 'Delivery Completed',
    message: `${riderName} completed a send item delivery.`,
    relatedId: delivery.s_id,
  });
};

/* =========================
   DASHBOARD
========================= */
const getDashboard = async ({ riderId }) => {
  const rejectedSet = getRejectedSet(riderId);

  const earningsRes = await rideDb.query(
    `
    SELECT
      SUM(
        CASE
          WHEN DATE(delivered_at) = CURRENT_DATE THEN delivery_fee
          ELSE 0
        END
      ) AS today,
      SUM(
        CASE
          WHEN DATE(delivered_at) >= date_trunc('week', CURRENT_DATE)
          THEN delivery_fee
          ELSE 0
        END
      ) AS week
    FROM send_items
    WHERE rider_id = $1
      AND status = 'delivered'
  `,
    [riderId]
  );

  const earnings = earningsRes.rows[0];

  const activeRes = await rideDb.query(
    `
    SELECT *
    FROM send_items
    WHERE rider_id = $1
      AND status IN ('accepted', 'on_the_way')
    ORDER BY accepted_at DESC NULLS LAST, created_at DESC
    LIMIT 1
  `,
    [riderId]
  );

  const requestsRes = await rideDb.query(
    `
    SELECT *
    FROM send_items
    WHERE status = 'pending'
      AND rider_id IS NULL
    ORDER BY created_at DESC
    LIMIT 20
  `
  );

  const filteredRequests = requestsRes.rows.filter(
    (row) => !rejectedSet.has(String(row.s_id))
  );

  return {
    todayDeliveryEarnings: Number(earnings.today || 0),
    weekDeliveryEarnings: Number(earnings.week || 0),
    activeDelivery: activeRes.rows[0] ? mapDelivery(activeRes.rows[0]) : null,
    deliveryRequests: filteredRequests.map(mapDelivery),
  };
};

/* =========================
   ACCEPT REQUEST
========================= */
const acceptRequest = async ({ riderId, requestId, io }) => {
  const rider = await getRiderBasicInfo(riderId);

  const result = await rideDb.query(
    `
    UPDATE send_items
    SET rider_id = $1,
        rider_phone = $2,
        status = 'accepted',
        accepted_at = CURRENT_TIMESTAMP
    WHERE s_id = $3
      AND status = 'pending'
      AND rider_id IS NULL
    RETURNING *
  `,
    [riderId, rider.phone || null, requestId]
  );

  if (!result.rows.length) {
    throw new Error('Request already taken or not found.');
  }

  const delivery = result.rows[0];
  const mapped = mapDelivery(delivery);

  const rejectedSet = getRejectedSet(riderId);
  rejectedSet.delete(String(requestId));

  await sendDeliveryAcceptedNotifications({ delivery, rider });

  if (io) {
    io.emit('delivery:removed', { requestId: String(requestId) });
    io.to(`rider:${riderId}`).emit('delivery:accepted', mapped);

    if (delivery.sender_id) {
      io.to(`user_${delivery.sender_id}`).emit('delivery:status-changed', {
        deliveryId: delivery.s_id,
        status: 'accepted',
      });
    }

    if (delivery.receiver_id) {
      io.to(`user_${delivery.receiver_id}`).emit('delivery:status-changed', {
        deliveryId: delivery.s_id,
        status: 'accepted',
      });
    }
  }

  return mapped;
};

/* =========================
   REJECT REQUEST
========================= */
const rejectRequest = async ({ riderId, requestId, io }) => {
  const checkRes = await rideDb.query(
    `
    SELECT s_id
    FROM send_items
    WHERE s_id = $1
      AND status = 'pending'
      AND rider_id IS NULL
    LIMIT 1
  `,
    [requestId]
  );

  if (!checkRes.rows.length) {
    throw new Error('Request not found or already taken.');
  }

  const rejectedSet = getRejectedSet(riderId);
  rejectedSet.add(String(requestId));

  if (io) {
    io.to(`rider:${riderId}`).emit('delivery:reject-ui', { requestId: String(requestId) });
  }

  return { requestId: String(requestId), hiddenForRider: true };
};

/* =========================
   MARK AS DELIVERED
========================= */
const markDelivered = async ({ riderId, id, io }) => {
  const rider = await getRiderBasicInfo(riderId);

  const result = await rideDb.query(
    `
    UPDATE send_items
    SET status = 'delivered',
        delivered_at = CURRENT_TIMESTAMP
    WHERE s_id = $1
      AND rider_id = $2
      AND status IN ('accepted', 'on_the_way')
    RETURNING *
  `,
    [id, riderId]
  );

  if (!result.rows.length) {
    throw new Error('Delivery not found or not yours.');
  }

  const delivery = result.rows[0];

  await sendDeliveryDeliveredNotifications({ delivery, rider });

  if (io) {
    io.to(`rider:${riderId}`).emit('delivery:updated', {
      deliveryId: id,
      status: 'delivered',
    });

    const earningsRes = await rideDb.query(
      `
      SELECT
        SUM(
          CASE
            WHEN DATE(delivered_at) = CURRENT_DATE THEN delivery_fee
            ELSE 0
          END
        ) AS today,
        SUM(
          CASE
            WHEN DATE(delivered_at) >= date_trunc('week', CURRENT_DATE)
            THEN delivery_fee
            ELSE 0
          END
        ) AS week
      FROM send_items
      WHERE rider_id = $1
        AND status = 'delivered'
    `,
      [riderId]
    );

    io.to(`rider:${riderId}`).emit('delivery:earnings-updated', {
      todayDeliveryEarnings: Number(earningsRes.rows[0].today || 0),
      weekDeliveryEarnings: Number(earningsRes.rows[0].week || 0),
    });

    if (delivery.sender_id) {
      io.to(`user_${delivery.sender_id}`).emit('delivery:status-changed', {
        deliveryId: delivery.s_id,
        status: 'delivered',
      });
    }

    if (delivery.receiver_id) {
      io.to(`user_${delivery.receiver_id}`).emit('delivery:status-changed', {
        deliveryId: delivery.s_id,
        status: 'delivered',
      });
    }
  }

  return {
    deliveryId: id,
    status: 'delivered',
  };
};

module.exports = {
  getDashboard,
  acceptRequest,
  rejectRequest,
  markDelivered,
};