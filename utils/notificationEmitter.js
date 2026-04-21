let io;

const onlineUsers = new Map();

const setNotificationIo = (ioInstance) => {
  io = ioInstance;
};

const registerUserSocket = (userId, socketId) => {
  if (!userId || !socketId) return;

  const normalizedUserId = String(userId);

  if (!onlineUsers.has(normalizedUserId)) {
    onlineUsers.set(normalizedUserId, new Set());
  }

  onlineUsers.get(normalizedUserId).add(socketId);
};

const removeUserSocket = (userId, socketId) => {
  if (!userId || !socketId) return;

  const normalizedUserId = String(userId);
  const userSockets = onlineUsers.get(normalizedUserId);

  if (!userSockets) return;

  userSockets.delete(socketId);

  if (userSockets.size === 0) {
    onlineUsers.delete(normalizedUserId);
  }
};

const emitNotification = (userId, notification) => {
  if (!io || !userId || !notification) return;

  const normalizedUserId = String(userId);

  io.to(`user_${normalizedUserId}`).emit('notification:new', notification);
};

module.exports = {
  setNotificationIo,
  registerUserSocket,
  removeUserSocket,
  emitNotification,
};