const { getIO } = require('../config/socket');


//EMIT HELPERS
// New request → Rider der kache
const emitNewSendItemToRiders = (payload) => {
  const io = getIO();

// global riders room (optional)
  io.to('riders_global').emit('send_item:new_request', payload);

// specific rider
  if (payload?.rider_id) {
    io.to(`rider_${payload.rider_id}`).emit('send_item:new_request', payload);
  }
};

// Sender update
const emitSendItemToSender = (senderId, payload) => {
  const io = getIO();
  io.to(`user_${senderId}`).emit('send_item:sender_update', payload);
};

// Rider update
const emitSendItemToRider = (riderId, payload) => {
  const io = getIO();
  io.to(`rider_${riderId}`).emit('send_item:rider_update', payload);
};

// Receiver update (optional)
const emitSendItemToReceiver = (receiverId, payload) => {
  const io = getIO();
  io.to(`user_${receiverId}`).emit('send_item:receiver_update', payload);
};

// Request room update (real-time status)
const emitSendItemStatusUpdate = (itemId, payload) => {
  const io = getIO();
  io.to(`send_item_${itemId}`).emit('send_item:status_update', payload);
};

module.exports = {
  emitNewSendItemToRiders,
  emitSendItemToSender,
  emitSendItemToRider,
  emitSendItemToReceiver,
  emitSendItemStatusUpdate,
};
