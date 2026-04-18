let io;

// userId -> Set(socketId)
const onlineUsers = new Map();

/* =========================
   INIT
========================= */
const setNotificationIo = (ioInstance) => {
  io = ioInstance;
};

/* =========================
   USER SOCKET REGISTRY
========================= */
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

/* =========================
   HELPERS
========================= */
const isUserOnline = (userId) => {
  const normalizedUserId = String(userId);
  const userSockets = onlineUsers.get(normalizedUserId);

  return !!(userSockets && userSockets.size > 0);
};

const getOnlineUserSocketIds = (userId) => {
  const normalizedUserId = String(userId);
  const userSockets = onlineUsers.get(normalizedUserId);

  return userSockets ? Array.from(userSockets) : [];
};

/* =========================
   EMIT NOTIFICATION
========================= */
const emitNotification = (userId, notification) => {
  if (!io || !userId || !notification) return;

  const normalizedUserId = String(userId);

  // room emit only
  io.to(`user_${normalizedUserId}`).emit('notification:new', notification);
};

module.exports = {
  setNotificationIo,
  registerUserSocket,
  removeUserSocket,
  isUserOnline,
  getOnlineUserSocketIds,
  emitNotification,
};