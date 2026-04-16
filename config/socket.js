let io;

// online users map: userId -> socketId
const onlineUsers = new Map();

const initSocket = (server) => {
  const { Server } = require('socket.io');
  const jwt = require('jsonwebtoken');

  io = new Server(server, {
    cors: {
      origin: '*',
    },
  });

  // 🔐 socket auth (JWT)
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token;

      if (!token) {
        return next(new Error('Unauthorized: No token'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      socket.user = {
        userId: decoded.userId || decoded.user_id,
        email: decoded.email,
      };

      next();
    } catch (err) {
      next(new Error('Unauthorized: Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.user.userId;

    console.log(`🟢 User connected: ${userId}`);

    // save online user
    onlineUsers.set(userId, socket.id);

    // 🔴 disconnect
    socket.on('disconnect', () => {
      console.log(`🔴 User disconnected: ${userId}`);
      onlineUsers.delete(userId);
    });
  });

  return io;
};

// 🔥 emit notification
const emitNotification = (userId, data) => {
  if (!io) return;

  const socketId = onlineUsers.get(userId);

  if (socketId) {
    io.to(socketId).emit('notification:new', data);
  }
};

// optional: general emit
const getIO = () => {
  if (!io) throw new Error('Socket.IO not initialized');
  return io;
};

module.exports = {
  initSocket,
  getIO,
  emitNotification,
};