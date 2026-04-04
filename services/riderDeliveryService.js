const rideDb = require('../config/rideDb');

/* =========================
   COMMON MAPPER
========================= */
const mapDelivery = (row) => ({
  deliveryId: row.s_id,
  senderName: row.sender_name,
  senderPhone: row.sender_phone,
  receiverName: row.receiver_name || '',
  receiverPhone: row.receiver_phone || '',
  pickup: row.pickup_location || '',
  drop: row.drop_location || '',
  item: row.item_type,
  fee: Number(row.delivery_fee || 0),
  distance: Number(row.distance_km || 0),
  time: row.estimated_minutes || 0,
  status: row.status,
});

/* =========================
   DASHBOARD
========================= */
const getDashboard = async ({ riderId }) => {
  const earningsRes = await rideDb.query(
    `
    SELECT
      SUM(CASE WHEN DATE(created_at) = CURRENT_DATE THEN delivery_fee ELSE 0 END) AS today,
      SUM(CASE 
            WHEN DATE(created_at) >= date_trunc('week', CURRENT_DATE)
            THEN delivery_fee ELSE 0 END) AS week
    FROM send_items
    WHERE rider_id = $1 AND status = 'delivered'
  `,
    [riderId]
  );

  const earnings = earningsRes.rows[0];

  const activeRes = await rideDb.query(
    `
    SELECT *
    FROM send_items
    WHERE rider_id = $1
      AND status IN ('accepted','on_the_way')
    ORDER BY created_at DESC
    LIMIT 1
  `,
    [riderId]
  );

  const requestsRes = await rideDb.query(
    `
    SELECT *
    FROM send_items
    WHERE status = 'pending'
    ORDER BY created_at DESC
    LIMIT 20
  `
  );

  return {
    todayDeliveryEarnings: Number(earnings.today || 0),
    weekDeliveryEarnings: Number(earnings.week || 0),
    activeDelivery: activeRes.rows[0]
      ? mapDelivery(activeRes.rows[0])
      : null,
    deliveryRequests: requestsRes.rows.map(mapDelivery),
  };
};

/* =========================
   ACCEPT REQUEST
========================= */
const acceptRequest = async ({ riderId, requestId, io }) => {
  const result = await rideDb.query(
    `
    UPDATE send_items
    SET rider_id = $1,
        rider_phone = (
          SELECT phone FROM users WHERE user_id = $1
        ),
        status = 'accepted',
        accepted_at = CURRENT_TIMESTAMP
    WHERE s_id = $2
      AND status = 'pending'
    RETURNING *
  `,
    [riderId, requestId]
  );

  if (!result.rows.length) {
    throw new Error('Request already taken or not found.');
  }

  const delivery = result.rows[0];
  const mapped = mapDelivery(delivery);

  /* 🔥 SOCKET EVENTS */

  if (io) {
    // remove from all riders
    io.emit('delivery:removed', { requestId });

    // update this rider dashboard
    io.to(`rider:${riderId}`).emit('delivery:accepted', mapped);
  }

  return mapped;
};

/* =========================
   REJECT REQUEST
========================= */
const rejectRequest = async (requestId, io) => {
  // no DB change (keep pending)

  if (io) {
    // remove only for this rider (optional)
    io.emit('delivery:reject-ui', { requestId });
  }

  return { requestId };
};

/* =========================
   MARK AS DELIVERED
========================= */
const markDelivered = async ({ riderId, id, io }) => {
  const result = await rideDb.query(
    `
    UPDATE send_items
    SET status = 'delivered',
        delivered_at = CURRENT_TIMESTAMP
    WHERE s_id = $1 AND rider_id = $2
    RETURNING *
  `,
    [id, riderId]
  );

  if (!result.rows.length) {
    throw new Error('Delivery not found or not yours.');
  }

  const delivery = result.rows[0];

  /* 🔥 SOCKET EVENTS */

  if (io) {
    // update active delivery panel
    io.to(`rider:${riderId}`).emit('delivery:updated', {
      deliveryId: id,
      status: 'delivered',
    });

    // 🔥 earnings refresh
    const earningsRes = await rideDb.query(
      `
      SELECT
        SUM(CASE WHEN DATE(created_at) = CURRENT_DATE THEN delivery_fee ELSE 0 END) AS today,
        SUM(CASE 
              WHEN DATE(created_at) >= date_trunc('week', CURRENT_DATE)
              THEN delivery_fee ELSE 0 END) AS week
      FROM send_items
      WHERE rider_id = $1 AND status = 'delivered'
    `,
      [riderId]
    );

    io.to(`rider:${riderId}`).emit('delivery:earnings-updated', {
      todayDeliveryEarnings: Number(earningsRes.rows[0].today || 0),
      weekDeliveryEarnings: Number(earningsRes.rows[0].week || 0),
    });
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