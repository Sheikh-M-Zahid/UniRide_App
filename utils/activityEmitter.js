const { getIO } = require('../config/socket');
const activityService = require('../services/activityService');

const emitActivityUpdate = async (userId, type = 'all', time = 'today') => {
  try {
    const io = getIO();
    const data = await activityService.getActivityDashboard({
      userId,
      type,
      time,
      page: 1,
      limit: 20,
    });

    io.to(`activity_room_${userId}`).emit('activity_updated', data);
  } catch (error) {
    console.error('emitActivityUpdate error:', error.message);
  }
};

module.exports = {
  emitActivityUpdate,
};