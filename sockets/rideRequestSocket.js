const rideRequestSocket = (io) => {
  io.on('connection', (socket) => {
    socket.on('join:rider-room', (userId) => {
      socket.join(`rider:${userId}`);
      console.log(`Socket ${socket.id} joined rider:${userId}`);
    });

    socket.on('join:user-room', (userId) => {
      socket.join(`user:${userId}`);
      console.log(`Socket ${socket.id} joined user:${userId}`);
    });

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });
};

module.exports = rideRequestSocket;