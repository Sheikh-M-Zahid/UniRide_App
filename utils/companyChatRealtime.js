// CoRide চ্যাটের real-time socket emit ও অনলাইন-স্ট্যাটাস চেক করার জন্য
let io;

const setChatIo = (ioInstance) => {
  io = ioInstance;
};

const emitCompanyChatMessage = (sessionId, message) => {
  if (!io) return;
  io.to(`company_session_${sessionId}`).emit('company_message_received', message);
};

const isUserOnline = (userId) => {
  if (!io || !userId) return false;
  const room = io.sockets.adapter.rooms.get(`user_${userId}`);
  return !!(room && room.size > 0);
};

module.exports = {
  setChatIo,
  emitCompanyChatMessage,
  isUserOnline,
};
