const riderMapSocket = (io) => {
  io.on('connection', (socket) => {
    socket.on('join:rider', (userId) => {
      socket.join(`rider:${userId}`);
    });

    socket.on('disconnect', () => {
      console.log('Socket disconnected:', socket.id);
    });
  });
};

module.exports = riderMapSocket;