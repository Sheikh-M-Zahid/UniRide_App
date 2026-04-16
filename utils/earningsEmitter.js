const { getIO } = require('../config/socket');
const earningsService = require('../services/earningsService');

const emitEarningsUpdate = async (userId, range = 'today') => {
  try {
    const io = getIO();

    const data = await earningsService.getEarningsDashboard({
      userId,
      range,
    });

    io.to(`earnings_room_${userId}`).emit('earnings_updated', data);
  } catch (error) {
    console.error('emitEarningsUpdate error:', error.message);
  }
};

module.exports = {
  emitEarningsUpdate,
};