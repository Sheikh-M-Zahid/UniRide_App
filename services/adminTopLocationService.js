const rideDb = require('../config/rideDb');

/* =========================
   HELPER
========================= */
const formatItem = (row, subText) => ({
  location_name: row.location,
  count: Number(row.count),
  sub_text: subText,
});

/* =========================
   MAIN SERVICE
========================= */
const getTopLocationStats = async () => {
  const [
    pickupRes,
    destinationRes,
    demandRes,
    riderRes,
  ] = await Promise.all([

    /* =========================
       TOP PICKUP
    ========================= */
    rideDb.query(`
      SELECT start_location AS location, COUNT(*) AS count
      FROM rides
      WHERE start_location IS NOT NULL
      GROUP BY start_location
      ORDER BY count DESC
      LIMIT 5
    `),

    /* =========================
       TOP DESTINATION
    ========================= */
    rideDb.query(`
      SELECT destination AS location, COUNT(*) AS count
      FROM rides
      WHERE destination IS NOT NULL
      GROUP BY destination
      ORDER BY count DESC
      LIMIT 5
    `),

    /* =========================
       HIGH DEMAND (BEST LOGIC)
    ========================= */
    rideDb.query(`
      SELECT start_location AS location, COUNT(*) AS count
      FROM rides
      WHERE created_at >= NOW() - INTERVAL '7 days'
      GROUP BY start_location
      ORDER BY count DESC
      LIMIT 5
    `),

    /* =========================
       RIDER AVAILABILITY
    ========================= */
    rideDb.query(`
      SELECT location_name AS location, COUNT(*) AS count
      FROM (
        SELECT DISTINCT ON (user_id)
          user_id,
          latitude,
          longitude,
          CONCAT(ROUND(latitude::numeric, 3), ',', ROUND(longitude::numeric, 3)) AS location_name,
          updated_at
        FROM live_locations
        ORDER BY user_id, updated_at DESC
      ) latest_locations
      GROUP BY location_name
      ORDER BY count DESC
      LIMIT 5
    `),
  ]);

  return {
    top_pickup_points: pickupRes.rows.map((row) =>
      formatItem(row, 'Most selected pickup point')
    ),

    top_destination_points: destinationRes.rows.map((row) =>
      formatItem(row, 'Top drop-off point')
    ),

    high_demand_locations: demandRes.rows.map((row) =>
      formatItem(row, 'High ride creation in last 7 days')
    ),

    high_rider_availability_locations: riderRes.rows.map((row) =>
      formatItem(row, 'Most riders currently active here')
    ),
  };
};

module.exports = {
  getTopLocationStats,
};