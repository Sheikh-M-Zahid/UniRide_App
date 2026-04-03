const { getIO } = require('../config/socket');
const activeRideService = require('../services/activeRideService');

const emitActiveRideUpdate = async (userId) => {
  try {
    const io = getIO();
    const data = await activeRideService.getActiveRideDashboard(userId);

    io.to(`active_ride_room_${userId}`).emit('active_ride_updated', data);
  } catch (error) {
    console.error('emitActiveRideUpdate error:', error.message);
  }
};

module.exports = {
  emitActiveRideUpdate,
};