module.exports = (io) => {
  io.on('connection', (socket) => {
    socket.on('admin:vehicle-verifications:join', () => {
      socket.join('admin_vehicle_verifications');
    });

    socket.on('admin:vehicle-verifications:leave', () => {
      socket.leave('admin_vehicle_verifications');
    });
  });
};