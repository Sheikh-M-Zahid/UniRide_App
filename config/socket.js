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

  // JWT auth for socket connection
  io.use((socket, next) => {
    try {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        return next(new Error('Unauthorized: No token'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      socket.user = {
        userId: decoded.userId || decoded.user_id,
        email: decoded.email || decoded.university_email || null,
      };

      next();
    } catch (error) {
      next(new Error('Unauthorized: Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.user.userId;

    console.log(`🟢 User connected: ${userId}`);

    // store current online user socket
    onlineUsers.set(String(userId), socket.id);

    // user personal room
    socket.join(`user_${userId}`);
    socket.join(`rider_${userId}`);
    socket.join(`user:${userId}`);

    /* =========================
       REQUEST / RIDE ROOMS
    ========================= */

    socket.on('join_request_room', (requestId) => {
      if (!requestId) return;
      socket.join(`request_${requestId}`);
      console.log(`📌 User ${userId} joined request room request_${requestId}`);
    });

    socket.on('leave_request_room', (requestId) => {
      if (!requestId) return;
      socket.leave(`request_${requestId}`);
      console.log(`📌 User ${userId} left request room request_${requestId}`);
    });

    socket.on('join_rider_room', (riderId) => {
      if (!riderId) return;
      socket.join(`rider_${riderId}`);
      console.log(`🚗 User ${userId} joined rider room rider_${riderId}`);
    });

    socket.on('leave_rider_room', (riderId) => {
      if (!riderId) return;
      socket.leave(`rider_${riderId}`);
      console.log(`🚗 User ${userId} left rider room rider_${riderId}`);
    });

    socket.on('join_user_room', (targetUserId) => {
      if (!targetUserId) return;
      socket.join(`user_${targetUserId}`);
      console.log(`👤 User ${userId} joined user room user_${targetUserId}`);
    });

    socket.on('leave_user_room', (targetUserId) => {
      if (!targetUserId) return;
      socket.leave(`user_${targetUserId}`);
      console.log(`👤 User ${userId} left user room user_${targetUserId}`);
    });

    socket.on('disconnect', () => {
      console.log(`🔴 User disconnected: ${userId}`);
      onlineUsers.delete(String(userId));
    });
  });

  return io;
};

/* =========================
   REAL-TIME NOTIFICATION
========================= */
const emitNotification = (userId, data) => {
  if (!io) return;

  const socketId = onlineUsers.get(String(userId));

  if (socketId) {
    io.to(socketId).emit('notification:new', data);
  }

  // also emit to user room for multi-device safety
  io.to(`user_${userId}`).emit('notification:new', data);
};

/* =========================
   OPTIONAL HELPERS
========================= */
const isUserOnline = (userId) => {
  return onlineUsers.has(String(userId));
};

const getUserSocketId = (userId) => {
  return onlineUsers.get(String(userId)) || null;
};

const getIO = () => {
  if (!io) {
    throw new Error('Socket.IO not initialized');
  }

  return io;
};

module.exports = {
  initSocket,
  getIO,
  emitNotification,
  isUserOnline,
  getUserSocketId,
};
