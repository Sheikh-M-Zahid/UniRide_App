module.exports = (io, socket) => {
  const userId = socket.user?.userId;

  socket.on('join_activity_room', () => {
    if (!userId) return;
    socket.join(`activity_room_${userId}`);
  });

  socket.on('leave_activity_room', () => {
    if (!userId) return;
    socket.leave(`activity_room_${userId}`);
  });
};