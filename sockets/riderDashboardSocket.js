const registerRiderDashboardSocket = (io) => {
  io.on('connection', (socket) => {
    socket.on('join:rider-dashboard', (userId) => {
      socket.join(`rider:${userId}`);
    });

    socket.on('disconnect', () => {
      console.log('Rider dashboard socket disconnected:', socket.id);
    });
  });
};

module.exports = registerRiderDashboardSocket;