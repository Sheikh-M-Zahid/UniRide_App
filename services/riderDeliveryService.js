const rideDb = require('../config/rideDb');

const {
  sendPickupEmail,
  sendDeliveryCompletedEmailToSender,
  sendDeliveryCompletedEmailToReceiver,
} = require('./emailService');

const { createNotification } = require('./notificationService');

const rejectedRequestsByRider = new Map();

/* =========================
   HELPERS
========================= */
const mapDelivery = (row) => ({
  deliveryId: row.s_id,
  id: row.s_id,
  senderName: row.sender_name || '',
  senderPhone: row.sender_phone || '',
  receiverName: (`${row.receiver_first_name || ''} ${row.receiver_last_name || ''}`).trim()
    || row.receiver_name
    || row.receiver_email
    || 'Receiver',
  receiverPhone: row.receiver_user_phone || row.receiver_phone || '',
  receiverEmail: row.receiver_email || '',
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
      SUM(CASE WHEN DATE(delivered_at) = CURRENT_DATE THEN delivery_fee ELSE 0 END) AS today,
      SUM(CASE WHEN DATE(delivered_at) >= date_trunc('week', CURRENT_DATE) THEN delivery_fee ELSE 0 END) AS week
    FROM send_items
    WHERE rider_id = $1
      AND status = 'delivered'
  `,
    [riderId]
  );

  const earnings = earningsRes.rows[0];

  const activeRes = await rideDb.query(
    `SELECT s.*,
            u.first_name AS receiver_first_name,
            u.last_name  AS receiver_last_name,
            u.phone      AS receiver_user_phone
     FROM send_items s
     LEFT JOIN users u ON s.receiver_id = u.user_id
     WHERE s.rider_id = $1
       AND s.status IN ('accepted', 'picked_up', 'on_the_way')
     ORDER BY s.accepted_at DESC NULLS LAST, s.created_at DESC
     LIMIT 1`,
    [riderId]
  );

  const requestsRes = await rideDb.query(
    `SELECT s.*,
            u.first_name AS receiver_first_name,
            u.last_name  AS receiver_last_name,
            u.phone      AS receiver_user_phone
     FROM send_items s
     LEFT JOIN users u ON s.receiver_id = u.user_id
     WHERE s.status = 'pending'
       AND s.rider_id IS NULL
     ORDER BY s.created_at DESC
     LIMIT 20`
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

  // Sender কে email পাঠাও
  try {
    const { sendRiderAcceptedEmailToSender } = require('./emailService');
    const senderRes = await rideDb.query(
      `SELECT university_email, first_name, last_name FROM users WHERE user_id = $1 LIMIT 1`,
      [delivery.sender_id]
    );
    if (senderRes.rows.length) {
      const sender = senderRes.rows[0];
      const senderName = `${sender.first_name || ''} ${sender.last_name || ''}`.trim() || 'Sender';
      const riderName = `${rider.first_name || ''} ${rider.last_name || ''}`.trim() || 'Rider';
      await sendRiderAcceptedEmailToSender({
        senderEmail: sender.university_email,
        senderName,
        riderName,
        riderPhone: rider.phone || 'N/A',
        itemType: delivery.item_type || 'Item',
        pickupLocation: delivery.pickup_location || '',
        dropLocation: delivery.drop_location || '',
        deliveryFee: delivery.delivery_fee || 0,
      });
    }
  } catch (emailErr) {
    console.error('Rider accepted email error:', emailErr.message);
  }

  if (io) {
    io.emit('delivery:removed', { requestId: String(requestId) });

    // ✅ FIX
    io.to(`rider_${riderId}`).emit('delivery:accepted', mapped);

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
    // ✅ FIX
    io.to(`rider_${riderId}`).emit('delivery:reject-ui', {
      requestId: String(requestId),
    });
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
      AND status IN ('accepted', 'picked_up')
    RETURNING *
  `,
    [id, riderId]
  );

  if (!result.rows.length) {
    throw new Error('Delivery not found or not yours.');
  }

  const delivery = result.rows[0];

  await sendDeliveryDeliveredNotifications({ delivery, rider });

  // Rider earning transaction + ৳5 wallet bonus
  try {
    const deliveryFee = Number(delivery.delivery_fee || 0);
    const bonusAmount = 5;
    const referenceId = `delivery_earn_${delivery.s_id}`;
    const bonusReferenceId = `delivery_bonus_${delivery.s_id}`;

    // Delivery fee earning record
    await rideDb.query(
      `INSERT INTO transactions
       (user_id, amount, type, method, reference_id, status)
       VALUES ($1, $2, 'credit', 'delivery', $3, 'completed')
       ON CONFLICT (reference_id) DO NOTHING`,
      [riderId, deliveryFee, referenceId]
    );

    // ৳5 bonus wallet credit + due_balance কমাও
    await rideDb.query(
      `INSERT INTO transactions
       (user_id, amount, type, method, reference_id, status)
       VALUES ($1, $2, 'credit', 'delivery_bonus', $3, 'completed')
       ON CONFLICT (reference_id) DO NOTHING`,
      [riderId, bonusAmount, bonusReferenceId]
    );

    await rideDb.query(
      `UPDATE users
       SET due_balance = GREATEST(due_balance - $1, 0)
       WHERE user_id = $2`,
      [bonusAmount, riderId]
    );

  } catch (earnErr) {
    console.error('Earning record error:', earnErr.message);
  }

   // Send delivery completed emails
  try {
    const rideDb2 = require('../config/rideDb');

    // Get sender email
    if (delivery.sender_id) {
      const senderRes = await rideDb2.query(
        `SELECT university_email, first_name, last_name FROM users WHERE user_id = $1 LIMIT 1`,
        [delivery.sender_id]
      );
      if (senderRes.rows.length) {
        const sender = senderRes.rows[0];
        const senderName = `${sender.first_name || ''} ${sender.last_name || ''}`.trim() || 'Sender';
        const receiverName = delivery.receiver_name || delivery.receiver_email || 'Receiver';
        await sendDeliveryCompletedEmailToSender({
          senderEmail: sender.university_email,
          senderName,
          receiverName,
          itemType: delivery.item_type || 'Item',
        });
      }
    }

    // Send email to receiver
    if (delivery.receiver_email) {
      await sendDeliveryCompletedEmailToReceiver({
        receiverEmail: delivery.receiver_email,
        itemType: delivery.item_type || 'Item',
      });
    }
  } catch (emailErr) {
    console.error('Delivery completed email error:', emailErr.message);
  }

  if (io) {
    // ✅ FIX
    io.to(`rider_${riderId}`).emit('delivery:updated', {
      deliveryId: id,
      status: 'delivered',
    });

    const earningsRes = await rideDb.query(
      `
      SELECT
        SUM(CASE WHEN DATE(delivered_at) = CURRENT_DATE THEN delivery_fee ELSE 0 END) AS today,
        SUM(CASE WHEN DATE(delivered_at) >= date_trunc('week', CURRENT_DATE) THEN delivery_fee ELSE 0 END) AS week
      FROM send_items
      WHERE rider_id = $1
        AND status = 'delivered'
    `,
      [riderId]
    );

    io.to(`rider_${riderId}`).emit('delivery:earnings-updated', {
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

/* =========================
   MARK AS PICKED UP
========================= */
const markPickedUp = async ({ riderId, id, io }) => {
  const rider = await getRiderBasicInfo(riderId);

  const result = await rideDb.query(
    `
    UPDATE send_items
    SET status = 'picked_up'
    WHERE s_id = $1
      AND rider_id = $2
      AND status = 'accepted'
    RETURNING *
  `,
    [id, riderId]
  );

if (!result.rows.length) {
    throw new Error('Delivery not found or not yours.');
  }

  const delivery = result.rows[0];

  // Send pickup email to receiver
  try {
    if (delivery.receiver_email) {
      const riderName = `${rider.first_name || ''} ${rider.last_name || ''}`.trim() || 'Rider';
      const trackingUrl = `${process.env.BASE_URL}/api/track/send-item/${delivery.s_id}`;

      await sendPickupEmail({
        receiverEmail: delivery.receiver_email,
        senderName: delivery.sender_name || 'Sender',
        itemType: delivery.item_type || 'Item',
        riderName,
        riderPhone: rider.phone || 'N/A',
        pickedUpAt: new Date(),
        trackingUrl,
      });
    }
  } catch (emailErr) {
    console.error('Pickup email error:', emailErr.message);
  }

  if (delivery.sender_id) {
    await createNotification({
      userId: delivery.sender_id,
      title: 'Item Picked Up',
      message: `Your ${delivery.item_type} has been picked up by the rider.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: delivery.s_id,
    });
  }

  if (delivery.receiver_id) {
    await createNotification({
      userId: delivery.receiver_id,
      title: 'Item On The Way',
      message: `Your incoming ${delivery.item_type} is now on the way.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: delivery.s_id,
    });
  }

  await createNotification({
    userId: rider.user_id,
    title: 'Pickup Confirmed',
    message: `You picked up the ${delivery.item_type}. Deliver it to the receiver now.`,
    type: 'sendItem',
    isImportant: false,
    targetRole: 'rider',
    relatedId: delivery.s_id,
  });

  if (io) {
    io.to(`rider_${riderId}`).emit('delivery:updated', {
      deliveryId: id,
      status: 'picked_up',
    });

    if (delivery.sender_id) {
      io.to(`user_${delivery.sender_id}`).emit('delivery:status-changed', {
        deliveryId: delivery.s_id,
        status: 'picked_up',
      });
    }

    if (delivery.receiver_id) {
      io.to(`user_${delivery.receiver_id}`).emit('delivery:status-changed', {
        deliveryId: delivery.s_id,
        status: 'picked_up',
      });
    }
  }

  return {
    deliveryId: id,
    status: 'picked_up',
  };
};


module.exports = {
  getDashboard,
  acceptRequest,
  rejectRequest,
  markDelivered,
  markPickedUp,
};
