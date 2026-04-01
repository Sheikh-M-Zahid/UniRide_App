const jwt = require('jsonwebtoken');
const rideDb = require('../config/rideDb');
const activeRiderSocket = require('./activeRiderSocket');
const activeRideSocket = require('./activeRideSocket');
const earningsSocket = require('./earningsSocket');
const { emitActiveRidersUpdate } = require('../utils/activeRiderEmitter');

const onlineRiders = new Map();

module.exports = (io) => {
  /* =========================
     SOCKET AUTH MIDDLEWARE
  ========================= */
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token;

      if (!token) {
        return next(new Error('Unauthorized'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      socket.user = {
        userId: decoded.userId || decoded.user_id || null,
        email: decoded.email || decoded.university_email || null,
        isAdmin: Boolean(decoded.isAdmin),
      };

      if (!socket.user.userId) {
        return next(new Error('Unauthorized'));
      }

      next();
    } catch (error) {
      return next(new Error('Unauthorized'));
    }
  });

  /* =========================
     SOCKET CONNECTION
  ========================= */
  io.on('connection', (socket) => {
    const userId = socket.user.userId;

    console.log('Socket connected:', userId);

    onlineRiders.set(userId, socket.id);

    /* =========================
       REGISTER FEATURE SOCKETS
    ========================= */
    activeRiderSocket(io, socket);
    activeRideSocket(io, socket);
    earningsSocket(io, socket);

    /* =========================
       LIVE LOCATION UPDATE
    ========================= */
    socket.on('send_location', async (data) => {
      try {
        const { lat, lng, address, location_name } = data || {};

        if (lat == null || lng == null) {
          return;
        }

        await rideDb.query(
          `
          INSERT INTO live_locations
            (user_id, latitude, longitude, address, location_name, updated_at)
          VALUES
            ($1, $2, $3, $4, $5, NOW())
          `,
          [userId, lat, lng, address || null, location_name || null]
        );

        io.to('active_riders_room').emit('location_update', {
          rider_id: userId,
          lat,
          lng,
          address: address || null,
          location_name: location_name || null,
        });

        await emitActiveRidersUpdate();
      } catch (error) {
        console.error('Location update error:', error.message);
      }
    });

    /* =========================
       OPTIONAL: MANUAL ONLINE STATUS
    ========================= */
    socket.on('set_online_status', async (data) => {
      try {
        if (typeof data?.is_online !== 'boolean') {
          return;
        }

        const isOnline = data.is_online;

        await rideDb.query(
          `UPDATE users SET is_online = $1 WHERE user_id = $2`,
          [isOnline, userId]
        );

        await emitActiveRidersUpdate();
      } catch (error) {
        console.error('Online status update error:', error.message);
      }
    });

    /* =========================
       DISCONNECT
    ========================= */
    socket.on('disconnect', async () => {
      console.log('Socket disconnected:', userId);

      onlineRiders.delete(userId);

      try {
        await rideDb.query(
          `UPDATE users SET is_online = false WHERE user_id = $1`,
          [userId]
        );
      } catch (error) {
        console.error('Offline update error:', error.message);
      }

      try {
        await emitActiveRidersUpdate();
      } catch (error) {
        console.error('Active rider emit error:', error.message);
      }
    });
  });
};