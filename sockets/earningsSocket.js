module.exports = (io, socket) => {
  const userId = socket.user?.userId;

  socket.on('join_earnings_room', () => {
    if (!userId) return;
    socket.join(`earnings_room_${userId}`);
  });

  socket.on('leave_earnings_room', () => {
    if (!userId) return;
    socket.leave(`earnings_room_${userId}`);
  });
};