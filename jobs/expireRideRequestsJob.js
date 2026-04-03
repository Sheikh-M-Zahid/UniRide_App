const rideDb = require('../config/rideDb');

const expireRideRequestsJob = (io) => {
  setInterval(async () => {
    try {
      const { rows } = await rideDb.query(
        `UPDATE ride_requests
         SET status = 'expired',
             updated_at = CURRENT_TIMESTAMP
         WHERE status = 'pending'
           AND expires_at <= CURRENT_TIMESTAMP
         RETURNING request_id, rider_id, passenger_id`
      );

      rows.forEach((row) => {
        io.to(`rider:${row.rider_id}`).emit('ride-request:expired', {
          requestId: row.request_id,
        });

        io.to(`user:${row.passenger_id}`).emit('ride-request:expired', {
          requestId: row.request_id,
        });
      });
    } catch (error) {
      console.error('expireRideRequestsJob error:', error.message);
    }
  }, 10000);
};

module.exports = expireRideRequestsJob;