const jwt = require('jsonwebtoken');
const {
  registerUserSocket,
  removeUserSocket,
} = require('../utils/notificationEmitter');

const attachNotificationSocket = (io) => {
  io.on('connection', (socket) => {
    try {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        return;
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      const userId = decoded.userId || decoded.user_id;

      if (!userId) {
        return;
      }

      socket.userId = String(userId);

      registerUserSocket(socket.userId, socket.id);
      socket.join(`user_${socket.userId}`);

      socket.on('disconnect', () => {
        removeUserSocket(socket.userId, socket.id);
      });
    } catch (error) {
      // silent fail
    }
  });
};

module.exports = attachNotificationSocket;