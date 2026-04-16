let io;
const onlineUsers = new Map();

const setNotificationIo = (ioInstance) => {
  io = ioInstance;
};

const registerUserSocket = (userId, socketId) => {
  onlineUsers.set(userId, socketId);
};

const removeUserSocket = (socketId) => {
  for (const [userId, id] of onlineUsers.entries()) {
    if (id === socketId) {
      onlineUsers.delete(userId);
      break;
    }
  }
};

const emitNotification = (userId, notification) => {
  const socketId = onlineUsers.get(userId);

  if (socketId && io) {
    io.to(socketId).emit('notification:new', notification);
  }
};

module.exports = {
  setNotificationIo,
  registerUserSocket,
  removeUserSocket,
  emitNotification,
};