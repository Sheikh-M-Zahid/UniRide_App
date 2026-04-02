module.exports = (io, socket) => {
  const userId = socket.user?.userId;

  socket.on('join_active_ride_room', () => {
    if (!userId) return;
    socket.join(`active_ride_room_${userId}`);
  });

  socket.on('leave_active_ride_room', () => {
    if (!userId) return;
    socket.leave(`active_ride_room_${userId}`);
  });
};