let io;

const initSocket = (server) => {
  const socketIo = require('socket.io');

  io = socketIo(server, {
    cors: {
      origin: "*",
    },
  });

  return io;
};

const getIO = () => {
  if (!io) throw new Error("Socket.IO not initialized");
  return io;
};

module.exports = { initSocket, getIO };