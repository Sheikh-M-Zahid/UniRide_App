const registerRiderActiveRideSocket = (io) => {
  io.on('connection', (socket) => {
    socket.on('join:rider-room', (userId) => {
      socket.join(`rider:${userId}`);
    });

    socket.on('join:user-room', (userId) => {
      socket.join(`user:${userId}`);
    });

    socket.on('join:ride-room', (rideId) => {
      socket.join(`ride:${rideId}`);
    });

    socket.on('disconnect', () => {
      console.log('Socket disconnected:', socket.id);
    });
  });
};

module.exports = registerRiderActiveRideSocket;