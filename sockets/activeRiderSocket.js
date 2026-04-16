module.exports = (io, socket) => {
  socket.on('join_active_riders_room', () => {
    socket.join('active_riders_room');
  });

  socket.on('leave_active_riders_room', () => {
    socket.leave('active_riders_room');
  });
};
